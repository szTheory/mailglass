# Phase 158: Architecture Simplification Patterns

**Scope:** ARCH-01 through ARCH-06. This maps core/inbound ownership and preserves adopter-facing APIs. Admin/operator UI is explicitly out of scope.

## Current graph and cycle risks

| Concern | Exact evidence | Planning implication |
|---|---|---|
| Core is a broad root boundary | `lib/mailglass.ex` exports Config, Repo, Outbound, Webhook, Events, PubSub, and operator modules from one `Boundary` root. | Introduce sub-boundaries by responsibility, but do not make root exports a promise of public API; its module documentation already makes that distinction. |
| Outbound is already a useful sub-boundary | `lib/mailglass/outbound.ex` has `use Boundary, deps: [Mailglass]` and public `deliver/2` delegates. | Keep `Mailglass.Outbound` stable; split its private orchestration into internal collaborators without moving public functions or return shapes. |
| Inbound is independently released but path-depends on core locally | `mailglass_inbound/mix.exs` has `mailglass_dep/0`: published `{:mailglass, "~> 2.0"}`, local `path: ".."`. | Core must never compile-reference `MailglassInbound.*`; inbound may consume a small explicitly-versioned core surface. Add a static graph check that rejects reverse references and SCCs. |
| Existing cross-package leakage | `mailglass_inbound/lib/mailglass_inbound/execution.ex` aliases `Mailglass.Tenancy` and constructs `Mailglass.SendError`; inbound Plug uses core errors, tenancy, PubSub and rate-limit error structs; `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` reaches core SES cache. | Inventory every cross-package `Mailglass.*` reference; replace only runtime production dependencies with named core ports. Keep test helpers separate from production ports. |
| Optional-dependency cycle pressure | `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` references `Mailglass.Oban.TenancyMiddleware`; inbound’s `mix.exs` suppresses it under no-optional-deps. | A core-owned Oban integration port should expose the minimum middleware/job context contract, or inbound should own a sibling-local middleware adapter. Do not solve with additional `no_warn_undefined` entries. |

### Compile-cycle guard

Use the package boundary already expressed by independent `mix.exs` files as the enforcement unit:

1. Build a compile-time dependency extractor over `lib/**/*.ex` and `mailglass_inbound/lib/**/*.ex` (aliases, remote calls, structs, `use`, behaviours, and compile attributes).
2. Fail if core references `MailglassInbound` in production sources.
3. Fail if strongly connected components cross `{core, inbound}`; allow only documented inbound → exported core port edges.
4. Exercise both `mix compile --no-optional-deps --warnings-as-errors` commands, because optional-module gates currently mask some edges.

## Runtime configuration: additive value, compatible facades

### Existing analogs

| Pattern | Exact files | Preserve / improve |
|---|---|---|
| Core validates a full NimbleOptions schema at boot | `lib/mailglass/config.ex` (`validate_at_boot!/0`, `validated_config/0`) and `lib/mailglass/application.ex` | Build `%Mailglass.Runtime{}` from this validated result once. Keep `Mailglass.Config` functions as compatibility accessors delegating to the runtime. |
| Core only caches schema today | `lib/mailglass/config.ex` (`schema/0`, `warm_schema/0`) | Replace the isolated schema cache with one immutable runtime cache, retaining cold-start/self-heal behavior only if supported by the runtime constructor. |
| Inbound separately owns app env and schema cache | `mailglass_inbound/lib/mailglass_inbound/config.ex` (`validated/0`, `validate_at_boot!/0`, `schema/0`) | Do not merge app environments. Let inbound create its own package runtime which embeds or receives only a narrow core runtime capability. |
| Boot validation entry points | `lib/mailglass/application.ex`; `mailglass_inbound/lib/mailglass_inbound/application.ex` | Both should call one package-local runtime bootstrap before children start; neither application should query the sibling’s app env. |

### Recommended `%Mailglass.Runtime{}` seam

Create a core value object with opaque construction:

```elixir
%Mailglass.Runtime{
  repo: module() | nil,
  schema: String.t(),
  adapters: %{optional(String.t() | atom()) => {module(), keyword()}},
  tenancy: module() | nil,
  clock: module(),
  async: %{runner: module() | atom()},
  webhook: %{...},
  tracking: %{...},
  compliance: %{...}
}
```

`Mailglass.Runtime.load!/0` is the only `Application.get_all_env(:mailglass)`/NimbleOptions validation owner. `Mailglass.Config` retains its public functions (`schema/0`, adapter/registry lookups, webhook and compliance accessors) as delegates over `Runtime.current/0`; no adopter configuration key or current return shape changes. Keep runtime data package-private/opaque so inbound cannot reach into unrelated core fields.

Inbound should use `MailglassInbound.Runtime` (or preserve `MailglassInbound.Config` as its façade) with its own validated `:mailglass_inbound` value. The shared schema identifier validator is a legitimate core capability because it is pure and already used by inbound: `Mailglass.Identifier.validate!/2`.

## Capability-port analogs and recommended ports

Existing behaviour/gateway shapes show the preferred narrow seam:

| Existing analog | File | Phase 158 mapping |
|---|---|---|
| Delivery provider adapter behaviour | `lib/mailglass/adapter.ex` | Define capability behaviours at the consumer boundary; return domain values/errors, not root modules or config maps. |
| Async adapter selection | `lib/mailglass/outbound/async_adapter.ex` and `lib/mailglass/optional_deps/*.ex` | Core owns outbound dispatch capability; inbound owns its own optional-dependency gateway (`mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`) rather than importing core implementation modules. |
| S3 fetch port | `mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex` | This is the template for inbound-owned external I/O: behaviour, fake, optional real adapter, and package-local config. |
| Webhook provider behaviour | `lib/mailglass/webhook/provider.ex` | Provider crypto/normalization remains core webhook-owned; the Plug must depend on a pipeline/port, not individual provider modules. |
| Inbound ingress provider behaviour | `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` | Preserve the mixed-arity transition only behind the ingress pipeline; do not spread provider branching into persistence/execution. |

Recommended sibling integration ports:

1. **Core runtime port:** schema validation, tenancy scoping, typed core errors, and PubSub topic/broadcast capability—not `Mailglass.Config`’s entire implementation or app env.
2. **Persistence port:** inbound keeps `MailglassInbound.Repo` and inbound schemas; it may accept core tenancy/schema values but must not depend on core `Repo` façade internals.
3. **Async/Oban port:** move only the common job tenancy context behind a small behaviour/value boundary. Keep each package’s worker and optional-dep gate local.
4. **PubSub port:** use `Mailglass.PubSub`/`Mailglass.PubSub.Topics` as the declared shared integration surface; centralize safe broadcast logic there rather than copying `Outbound.Projector.safe_broadcast/2` into inbound Plug.

## Stable façade mappings

| Requirement | Keep stable | Move behind it | Exact starting files |
|---|---|---|---|
| ARCH-04 Outbound | `Mailglass.Outbound.send/2`, `deliver/2`, `deliver!/2`, `deliver_later/2`, `deliver_many/2`, `dispatch_by_id/1` return contracts | preflight, persistence Multi construction, dispatch, registry resolution | `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/delivery.ex`, `lib/mailglass/outbound/projector.ex`, `lib/mailglass/outbound/async_adapter.ex` |
| ARCH-04 Config | `Mailglass.Config` keys/accessors and boot failure semantics | raw app-env reading, NimbleOptions validation, cache lifecycle | `lib/mailglass/config.ex`, `lib/mailglass/application.ex` |
| ARCH-05 core webhook Plug | `Mailglass.Webhook.Plug.init/1` and `call/2`; current 200/401/422/500 policy and post-commit broadcast semantics | request extraction, config resolution, verification, tenant resolution, normalization, ingest, outcome-to-response policy | `lib/mailglass/webhook/plug.ex`, `lib/mailglass/webhook/ingest.ex`, `lib/mailglass/webhook/provider.ex`, `lib/mailglass/webhook/telemetry.ex` |
| ARCH-05 inbound Plug | `MailglassInbound.Ingress.Plug.init/1` and `call/2`; provider response contract | request construction, verification, tenant, normalization, persist, execution, broadcast response stages | `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`, `ingress/request.ex`, `ingress/verified_request.ex`, `ingress/persist.ex`, `execution.ex` |

### Plug pipeline boundary

Both existing plugs are orchestration-heavy, but already expose durable phase boundaries. Extract an internal pipeline that returns a closed outcome value; leave the public Plug as an adapter that converts `Plug.Conn` to request input and outcome to response.

Core ordering to preserve: cached raw body → signature verification → tenant resolution → provider normalization → `Ingest.ingest_multi/3` → post-commit broadcast → response. Inbound ordering to preserve: request construction → verify (including SES verified S3 path) → tenant resolution → normalize → persist → optional execution → post-commit broadcast → response. Never move verification after tenancy or make broadcasts transactional.

## Shared logic ownership without package collapse

| Duplicated/related behavior | Owner recommendation | Constraint |
|---|---|---|
| Configuration validation mechanics | each package owns its schema; core owns only reusable pure primitives | `MailglassInbound.Config` explicitly must not read core app env. |
| Schema identifier validation | core (`Mailglass.Identifier`) | already a valid inbound use; preserve typed core error semantics. |
| Optional dependency gateways | package that owns the feature | inbound’s `OptionalDeps.ExAwsS3` and core’s optional gateways must remain separate; do not make inbound depend on core S3 implementation. |
| Safe PubSub broadcast | core shared PubSub capability | extract from `Outbound.Projector` only if it can be PII-free and free of outbound projection semantics. |
| HTTP ingress pipeline mechanics | package-local pipeline abstraction | core webhooks and inbound mail ingress have materially different persistence and SES/S3 paths; share value/port contracts, not a mega pipeline. |
| Retention batching | package-local pruners with shared pure SQL/batch helpers only if no schema-domain leak | core webhook events and inbound FK child-first retention have different invariants. |

## Sequencing recommendation

1. Establish graph inventory and cycle gate first (ARCH-01); classify every live cross-package edge as allowed port, test-only, or removal target.
2. Introduce core `Runtime` plus Config delegation and compatibility tests (ARCH-02/04) before changing consumers.
3. Establish sibling capability ports and remove implementation imports (ARCH-03/06), keeping package-local optional dependency ownership.
4. Extract core and inbound internal Plug pipelines under their unchanged `Plug` façades (ARCH-05), then replace direct cross-context calls with the named ports.

## Out of scope

No admin/operator UI, LiveView, dashboard, operator query, or styling changes are part of this phase. `lib/mailglass/operator/**`, `mailglass_admin/**`, and inbound operator UI should be treated only as dependency consumers when validating public façades.
