# Phase 158: Simplify Architecture Without Breaking Adopters - Research

**Researched:** 2026-08-17  
**Domain:** Elixir/Phoenix package boundaries, runtime configuration, compatibility-preserving refactoring  
**Confidence:** HIGH for repository seams; MEDIUM for compiler/runtime guidance

## User Constraints

No Phase 158 `CONTEXT.md` exists. The following constraints are copied from the active milestone/requirements and are binding.

### Locked Decisions

- All changes are additive-only; public v2 APIs are not removed or renamed. [VERIFIED: `.planning/REQUIREMENTS.md`]
- Core, admin, and inbound remain independently released packages; do not collapse them. [VERIFIED: `.planning/REQUIREMENTS.md`]
- Admin/operator UI behavior, styling, navigation, and visual polish are out of scope. [VERIFIED: `.planning/REQUIREMENTS.md`]
- New providers and ownership domains (notification policy, auth, billing, support, mobile, SRE) are out of scope. [VERIFIED: `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Internal module names, port/behaviour names, and the exact split of façade collaborators may follow existing project conventions, provided public return shapes and entry points remain unchanged. [ASSUMED]

### Deferred Ideas (OUT OF SCOPE)

- Admin/operator UI changes; CI gate consolidation beyond the cycle proof required by ARCH-01; release certification; package consolidation; and arbitrary line-count refactors. [VERIFIED: `.planning/REQUIREMENTS.md`]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| ARCH-01 | Core and inbound have zero compile-connected cycles, enforced in CI. | Current core `xref` reports one 5-file compile-connected cycle; use `mix xref graph --format cycles --label compile-connected` plus a cross-package edge guard. [VERIFIED: local command; CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| ARCH-02 | Runtime configuration is validated once into additive `%Mailglass.Runtime{}` while application-env façades remain compatible. | Core already validates a full schema at boot but caches only schema; introduce an opaque runtime value and keep `Mailglass.Config` as delegating compatibility façade. [VERIFIED: `lib/mailglass/config.ex`; `lib/mailglass/application.ex`] |
| ARCH-03 | Narrow APIs and explicit sibling integration ports replace broad root implementation dependencies. | Inventory live inbound-to-core production edges and designate small runtime, tenancy, error, PubSub, and optional-job ports. [VERIFIED: `158-PATTERNS.md`; repository grep] |
| ARCH-04 | Stable Outbound and Config façades retain public contracts while responsibilities move behind them. | `Outbound` is a 1,300+ line public façade with orchestration/persistence/dispatch/registry work; move collaborators behind it without changing verbs or result shapes. [VERIFIED: `lib/mailglass/outbound.ex`] |
| ARCH-05 | Inbound Plug retains Plug contract while work moves behind explicit pipeline. | Preserve `init/1`/`call/2` and status policy; extract request, verification, tenant, persistence, execution, broadcast, and response outcome stages. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`; `158-PATTERNS.md`] |
| ARCH-06 | Shared business logic has one owner without collapsing packages. | Keep feature-specific optional gateways and persistence local; put only genuine cross-package primitives behind core-owned ports. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`; `158-PATTERNS.md`] |

## Summary

Phase 158 is an internal ownership refactor with strict adopter compatibility, not a product expansion. The immediate measurable defect is real: core currently has one compile-connected strongly connected component across `Adapters.Fake`, `Config`, `Events`, `Repo`, and `SuppressionStore.Ecto`; inbound currently has none. [VERIFIED: `mix xref graph --format cycles --label compile-connected` run 2026-08-17] The current root `Boundary` exports a broad cross-domain surface, while inbound is separately released and depends on the core package. [VERIFIED: `lib/mailglass.ex`; `mailglass_inbound/mix.exs`]

The safe route is to introduce an additive, opaque `%Mailglass.Runtime{}` as the only core application-env validation owner; turn `Mailglass.Config` into a compatibility façade over it; and split implementation orchestration behind existing `Outbound` and Plug entry points. Core must not compile-reference inbound. Inbound may call only declared, narrow core capabilities—not root implementation modules or direct sibling app environment. [VERIFIED: `158-PATTERNS.md`; CITED: https://hexdocs.pm/elixir/config-and-distribution.html]

**Primary recommendation:** Establish executable graph/compatibility contracts first, then introduce Runtime and façade delegation, replace broad sibling dependencies with explicit ports, and finally extract each Plug into a package-local outcome pipeline.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Runtime configuration validation/cache | API / Backend | — | Each OTP application owns validation of its application environment at boot. [CITED: https://hexdocs.pm/elixir/config-and-distribution.html] |
| Core/inbound integration contract | API / Backend | Package boundary | Inbound is a released sibling that consumes core; reverse core-to-inbound production references violate dependency direction. [VERIFIED: `mailglass_inbound/mix.exs`; `158-PATTERNS.md`] |
| Delivery orchestration | API / Backend | Database / Storage | The public Outbound façade coordinates preflight, persistence, and dispatch while database modules retain durable writes. [VERIFIED: `lib/mailglass/outbound.ex`] |
| Inbound HTTP adaptation | API / Backend | External provider | Public Plug owns `Plug.Conn` input and HTTP response; internal pipeline owns domain outcomes. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`] |
| Shared PubSub/tenancy primitives | API / Backend | — | Core already supplies the shared PubSub name/topics and tenancy helpers used by inbound. [VERIFIED: inbound production source grep] |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Elixir/Mix `xref` | local 1.19.5 | detect compile-connected cycles | Official `xref` supports cycle output filtered to compile-connected edges. [VERIFIED: local `mix --version`; CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| `boundary` | existing `~> 0.10` | compile-time module boundary enforcement | Already registered as a core compiler and used by root/Outbound/Events boundaries. [VERIFIED: `mix.exs`; `lib/mailglass.ex`; `lib/mailglass/outbound.ex`] |
| NimbleOptions | existing `~> 1.1` | validate application configuration | Both packages already validate configuration through it. [VERIFIED: `mix.exs`; `mailglass_inbound/mix.exs`; config modules] |
| ExUnit | bundled | façade, graph, and pipeline contract tests | Existing core and inbound test infrastructure. [VERIFIED: `test/test_helper.exs`; `mailglass_inbound/test/test_helper.exs`] |

### Supporting

| Library/tool | Version | Purpose | When to Use |
|---|---:|---|---|
| Ecto/PostgreSQL | existing `~> 3.13` / local PostgreSQL 14.17 | preserve persistence boundaries and prefix behavior | Internal collaborators must use existing Repo façades or explicit step-level prefix options. [VERIFIED: `mix.exs`; local `psql --version`; `lib/mailglass/repo.ex`] |
| Phoenix PubSub / Plug | existing | retain post-commit broadcast and Plug contract | Keep at current package façade edges; do not introduce UI work. [VERIFIED: `lib/mailglass/application.ex`; inbound Plug] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Opaque Runtime + Config delegates | Rewrite all callers to a new public runtime API | Rejected: it turns an internal ownership improvement into an adopter migration and conflicts with additive-only v2 compatibility. [VERIFIED: requirements; ASSUMED: migration cost] |
| Explicit narrow ports | Let inbound consume broad `Mailglass.*` implementations | Rejected: broad imports conceal ownership and make independently released packages coupled. [VERIFIED: `158-PATTERNS.md`] |
| Package-local ingress pipelines | One shared mega ingress pipeline | Rejected: inbound SES/S3/persistence and core webhook ingest have different domain invariants; share only genuinely generic port/value logic. [VERIFIED: `158-PATTERNS.md`] |

**Installation:** none. Use the existing toolchain and dependencies. [VERIFIED: `mix.exs`; `mailglass_inbound/mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
Host `config :mailglass`                 Host `config :mailglass_inbound`
          |                                            |
          v                                            v
 Runtime.load!/boot cache                         Inbound Runtime.load!/boot cache
          |                                            |
          v                                            v
 Mailglass.Config (stable façade)                Inbound Config (stable façade)
          |                                            |
          +-- declared core ports <--------------------+
          |     (tenancy, typed errors, PubSub,
          |      schema validator, job context)
          v
 Mailglass.Outbound (stable public façade)
          -> preflight port -> persistence port -> dispatch port -> delivery result

 Plug.Conn -> MailglassInbound.Ingress.Plug (stable `init/1`, `call/2`)
          -> request -> verify -> tenant -> normalize -> persist -> execute/broadcast
          -> closed outcome -> existing HTTP response policy
```

### Pattern 1: Runtime value behind a compatible façade

**What:** `Mailglass.Runtime.load!/0` reads and validates core app env once, stores immutable validated data, and exposes only necessary accessors. `Mailglass.Config` preserves current functions and delegates to that value.

**When to use:** all core runtime paths that currently duplicate `Application.get_env` or revalidate the full schema. Do not absorb inbound configuration into core. [VERIFIED: direct app-env reads in `lib/` and `mailglass_inbound/lib/`]

```elixir
# Internal ownership; illustrative target shape.
defmodule Mailglass.Runtime do
  defstruct [:repo, :schema, :adapters, :tenancy, :clock, :tracking, :compliance]

  def load! do
    :mailglass |> Application.get_all_env() |> Mailglass.Config.validate_runtime!()
  end
end

# Existing public function remains.
def schema, do: Mailglass.Runtime.current!().schema
```

The exact constructor/accessor visibility is an internal decision; preserve current `Mailglass.Config` return values and boot-failure semantics. [ASSUMED]

### Pattern 2: Narrow consumer-defined sibling port

**What:** Define a small behaviour/value interface around a capability (for example safe PubSub broadcast or job tenancy context), rather than accepting a root module or entire configuration map.

**When to use:** every inbound production reference to core that is not a simple pure shared primitive. Preserve package-local optional-dependency gateways. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`; `158-PATTERNS.md`]

```elixir
# Example port: only the operation inbound needs.
@callback broadcast(topic :: binary(), event :: tuple()) :: :ok | {:error, term()}

# Inbound injects/uses the port; it never reaches into Outbound.Projector.
case pubsub.broadcast(topic, event) do
  :ok -> :ok
  {:error, _} -> :ok # retain existing best-effort post-commit semantics
end
```

### Pattern 3: Thin public Plug, closed internal outcome

**What:** Keep `init/1` and `call/2` at the public boundary. Convert `Plug.Conn` to a request, invoke a package-local pipeline, and map a closed outcome to the existing status/body contract.

**When to use:** both core webhook and inbound ingress façades. Verification must remain before tenancy; broadcasts remain post-commit and best effort. [VERIFIED: `158-PATTERNS.md`; current inbound Plug]

```elixir
def call(conn, opts) do
  conn
  |> Request.from_conn!(opts)
  |> Pipeline.run(opts)
  |> Response.apply(conn)
end
```

### Anti-Patterns to Avoid

- **Replacing a stable façade:** do not rename/remove `Mailglass.Config`, `Mailglass.Outbound` verbs, or inbound `Plug.init/1`/`call/2`; compatibility tests must run before and after extraction. [VERIFIED: requirements; public stability tests]
- **Core importing inbound:** local path development does not justify reverse production dependency; core must remain usable without inbound. [VERIFIED: `mailglass_inbound/mix.exs`; `158-PATTERNS.md`]
- **Config access by scattered application-env reads:** this defeats ARCH-02 and can make boot validation disagree with runtime behavior. [VERIFIED: current direct-read inventory; ASSUMED: disagreement risk]
- **Copying cross-package implementation:** duplicated safe-broadcast, optional-dependency, or job middleware logic should become a small owned primitive/port only when semantics are truly shared. [VERIFIED: `158-PATTERNS.md`]
- **Transaction or ordering drift during extraction:** do not make provider verification follow tenant lookup, make broadcast transactional, or put provider I/O inside durable DB transactions. [VERIFIED: `lib/mailglass/outbound.ex`; `158-PATTERNS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Compile-cycle analysis | Regex-only cycle detector | Mix `xref` cycle output plus a focused package-edge contract | `xref` understands compiler dependency labels; a small contract covers the released-package direction. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| Module-boundary enforcement | New custom permission framework | Existing `Boundary` compiler and explicit package seams | Boundary already runs in core compilation and supports declared dependencies. [VERIFIED: `mix.exs`; CITED: https://hexdocs.pm/boundary/Boundary.html] |
| Configuration parsing | Parallel bespoke config maps | Current NimbleOptions schemas feeding a single Runtime value | Existing validation/default rules are adopter behavior and should have one owner. [VERIFIED: config modules] |
| HTTP Plug replacement | New public routing API | Existing Plug façade with internal pipeline collaborators | Keeps caller wiring, body reader, status semantics, and docs stable. [VERIFIED: inbound docs/stability tests] |

**Key insight:** Phase 158 succeeds when each existing boundary becomes easier to reason about without requiring an adopter to discover that a refactor happened.

## Public Compatibility Constraints

| Surface | Must remain compatible | Evidence / required proof |
|---|---|---|
| Core config | Existing keys, `Mailglass.Config` accessors, defaults, validation/raise semantics, schema opt-out | `test/mailglass/config_test.exs` plus new Runtime-vs-Config parity tests. [VERIFIED: `lib/mailglass/config.ex`; ASSUMED: target test file] |
| Outbound | `send/2`, `deliver/2`, `deliver!/2`, `deliver_later/2`, `deliver_many/2`, `deliver_many!/2`, `dispatch_by_id/1`, return structs/statuses | Existing outbound/stability contracts and focused route/persistence tests. [VERIFIED: `lib/mailglass/outbound.ex`; `test/mailglass/outbound_test.exs`] |
| Inbound ingress | `Plug.init/1`, `Plug.call/2`, configured provider options, accepted response policies | Existing ingress provider tests plus contract tests using a real Plug.Conn. [VERIFIED: inbound Plug; inbound test tree] |
| Router/Mailbox/Inbound value objects | public DSL/callback/value modules | Existing inbound stability contract test. [VERIFIED: `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs`] |
| Package release shape | Core remains independent; inbound keeps published `{:mailglass, "~> 2.0"}` constraint and no reverse dependency | compile from each package, no-optional-deps build, package-edge static test. [VERIFIED: `mailglass_inbound/mix.exs`] |

## Common Pitfalls

### Pitfall 1: Cycle guard measures the wrong graph

**What goes wrong:** a check greps aliases or only compiles root, missing macro/struct/compile attribute edges or inbound’s optional-dependency path.  
**How to avoid:** run `mix xref graph --format cycles --label compile-connected` in both package roots and add a production-source package-edge contract; test a synthetic/fixture violation so the guard is non-vacuous. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html; VERIFIED: existing independent Mix projects]

### Pitfall 2: Runtime cache changes test override behavior

**What goes wrong:** tests and generated-host scenarios mutate `Application` env, but a process-global Runtime cache continues returning a prior value.  
**How to avoid:** provide the same explicit invalidation/test seam currently used for schema `:persistent_term`, make bootstrap atomic, and add mutation/restore parity tests. [VERIFIED: `test/support/sandbox_ownership.ex`; current Config schema cache]

### Pitfall 3: “Narrow port” leaks the whole root under another name

**What goes wrong:** a port accepts `Mailglass.Config`, a generic config map, or `Mailglass.Outbound.Projector`, so inbound still depends on unrelated implementation.  
**How to avoid:** name one capability per port, expose domain input/output only, and reject imports of non-port core implementation namespaces in inbound production code. [VERIFIED: `158-PATTERNS.md`; ASSUMED: exact namespace policy]

### Pitfall 4: Pipeline extraction changes acknowledgement semantics

**What goes wrong:** an internal stage raises/returns a new shape and the façade maps it to a different 2xx/401/422/500 behavior, or broadcasts before commit.  
**How to avoid:** characterize current response/status/broadcast order before moving code; pipeline outcomes must be closed and response mapping remains in the public Plug. [VERIFIED: current inbound Plug; `158-PATTERNS.md`]

### Pitfall 5: Sharing by merging packages

**What goes wrong:** a cleanup moves inbound-specific S3/Oban behavior into core, increases optional dependency coupling, and breaks no-optional-deps compilation.  
**How to avoid:** retain package-local optional gateways and workers; centralize only pure primitives or explicit feature-neutral ports. [VERIFIED: package optional-dependency modules; `158-PATTERNS.md`]

## Likely Plan Decomposition

1. **Graph inventory and fail-closed architecture contract (ARCH-01).** Capture the current `xref` cycle baseline, remove the real core cycle by breaking the Config/default-implementation chain, add core/inbound no-cycle commands, and add a static production package-edge test with negative control.
2. **Core Runtime and Config compatibility façade (ARCH-02, ARCH-04).** Add `%Mailglass.Runtime{}`/bootstrap/cache, migrate validated core readers to it, retain every Config accessor and test invalid config/cold cache/app-env override parity.
3. **Outbound ownership split (ARCH-03, ARCH-04).** Leave public verbs in `Outbound`; extract preflight, route/registry resolution, persistence composition, and dispatch into private collaborators with characterization tests around all six delivery shapes.
4. **Sibling ports and shared-logic ownership (ARCH-03, ARCH-06).** Classify every inbound production core reference; retain pure core helpers, establish narrow PubSub/job/runtime/tenancy ports, keep optional dependencies package-local, and forbid implementation leakage.
5. **Core/inbound Plug pipeline extraction (ARCH-05).** Extract package-local pipelines with closed outcomes; preserve exact HTTP policy, verify-before-tenant ordering, persistence-before-acknowledgement, and post-commit best-effort broadcast proof.
6. **Integration gate and compatibility evidence (ARCH-01..06).** Run no-optional-deps compiles, `xref`, root/inbound suites, stability/public-seam contracts, generated-host smoke already owned by the milestone, and scope guard that makes no UI edits. [VERIFIED: existing test/project surfaces; ASSUMED: final plan grouping]

## Code Examples

### CI-safe xref gate

```bash
# Fail only when a compile-connected SCC is present.
mix xref graph --format cycles --label compile-connected
(cd mailglass_inbound && mix xref graph --format cycles --label compile-connected)
```

`xref` identifies strongly connected components and can filter to compile-connected relationships; implementation should wrap this in a command/test that exits non-zero on any output. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html]

### Characterization test shape for façade extraction

```elixir
test "Config façade stays equivalent to Runtime" do
  runtime = Mailglass.Runtime.load!()
  assert Mailglass.Config.schema() == runtime.schema
  assert Mailglass.Config.default_adapter() == runtime.default_adapter
end

test "inbound Plug keeps the existing success policy" do
  conn = post(conn(:post, "/inbound", signed_payload), "/")
  assert MailglassInbound.Ingress.Plug.call(conn, provider: :postmark).status == 200
end
```

These examples prescribe contract tests, not new public APIs. Existing stability tests remain the source of public inventory. [VERIFIED: core/inbound stability contract tests; ASSUMED: exact fixture names]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Root Boundary exports broad implementation surface | Responsibility-specific boundaries plus explicit ports | Ownership and allowed dependencies become reviewable and enforceable. [VERIFIED: `lib/mailglass.ex`; CITED: https://hexdocs.pm/boundary/Boundary.html] |
| Schema-only config cache plus many direct app-env reads | One validated immutable runtime value with façade delegates | Boot validation and runtime reads have a single source of truth. [VERIFIED: Config/direct-read inventory; ASSUMED: target implementation] |
| Orchestration-heavy public modules | Thin stable façades over internal collaborators/outcome pipelines | Internal refactors can proceed without altering adopter entry points. [VERIFIED: `lib/mailglass/outbound.ex`; inbound Plug] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The runtime cache should retain an explicit invalidation seam for test application-env overrides. | Common Pitfalls | Tests may need a different but equally explicit cache lifecycle. |
| A2 | A final plan can group Outbound internal extraction separately from Plug extraction. | Likely Plan Decomposition | Dependency ordering may require splitting or combining tasks after implementation reconnaissance. |
| A3 | Exact port namespace/naming is discretionary. | Architecture Patterns | Naming changes only; public compatibility constraints still apply. |

## Open Questions

1. **Which core-to-inbound references, if any, exist only in test/tooling rather than production?**
   - What we know: inbound has several production core references, while root Mix tasks also generate inbound code. [VERIFIED: repository grep]
   - Recommendation: classify by `lib/` versus `test/`/Mix-task source before enforcing the reverse-edge rule; do not accidentally reject generators or tests that intentionally mention public inbound names. [ASSUMED]
2. **Should the graph guard be a Mix task or an ExUnit script contract?**
   - What we know: existing CI contracts live in `test/scripts/`, while `xref` is a Mix command. [VERIFIED: `test/scripts`; Mix docs]
   - Recommendation: use a small checked-in script/Mix alias invoked by CI and exercise it through an ExUnit negative-control test. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/Mix | compile/xref/tests | ✓ | 1.19.5 / OTP 28 | — |
| PostgreSQL | existing integration suites | ✓ | 14.17; local port ready | existing test configuration |
| Node | repository scripts where already required | ✓ | 22.14.0 | not required for core Phase 158 proof |

**Missing dependencies with no fallback:** none. [VERIFIED: local probes]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit in independent core and inbound Mix projects. [VERIFIED: test helpers] |
| Core quick run | `mix test test/mailglass/outbound_test.exs test/mailglass/stability_contract_test.exs test/reference_host/public_seams_contract_test.exs --warnings-as-errors` |
| Inbound quick run | `cd mailglass_inbound && mix test test/mailglass_inbound/stability_contract_test.exs test/mailglass_inbound/config_schema_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` |
| Graph check | `mix xref graph --format cycles --label compile-connected` in both package roots |
| Full suite | `mix ci` and `cd mailglass_inbound && mix ci` [VERIFIED: both `mix.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| ARCH-01 | zero SCCs and no forbidden core→inbound production edge | command + contract | both xref commands plus graph contract | ❌ Wave 0 |
| ARCH-02 | Runtime and Config parity, invalid config and cache-reset behavior | unit | focused Config/Runtime tests | ❌ Wave 0 |
| ARCH-03 | only declared sibling ports in inbound production source | static contract + integration | inbound compile/no-optional-deps + port contract | ❌ Wave 0 |
| ARCH-04 | existing Outbound/Config public surface and return shapes | unit/contract | existing stability + outbound tests | ✅ |
| ARCH-05 | public Plug status/order/broadcast policy unchanged | integration | existing inbound Plug tests plus pipeline outcomes | ✅ / extend |
| ARCH-06 | shared primitive has a single owner without package merge | static contract + compile | both project compiles/no-optional-deps | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** both `xref` commands and the focused package test subset.
- **Per wave merge:** `mix compile --no-optional-deps --warnings-as-errors` in root and inbound plus the relevant stability tests.
- **Phase gate:** `mix ci`, `cd mailglass_inbound && mix ci`, public-seams/stability contracts, and zero admin/operator UI diff.

### Wave 0 Gaps

- [ ] Architecture graph/package-edge contract with a non-vacuous negative fixture.
- [ ] Runtime/Config compatibility and cache lifecycle tests.
- [ ] Inbound/core port inventory contract distinguishing production sources from test/generator sources.
- [ ] Pipeline characterization tests for response/status/broadcast ordering before moving code.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Preserve verify-before-tenant ordering in both ingress pipelines. [VERIFIED: `158-PATTERNS.md`] |
| V3 Session Management | no | No session behavior is in Phase 158 scope. [VERIFIED: phase requirements] |
| V4 Access Control | yes | Preserve tenant scoping behind declared core capability, not a direct env/Repo shortcut. [VERIFIED: inbound production sources] |
| V5 Input Validation | yes | Runtime config remains NimbleOptions-validated at boot; provider request validation stays in existing provider paths. [VERIFIED: config/Plug sources] |
| V6 Cryptography | yes | Do not move or reimplement signature verification; pipelines only relocate orchestration. [VERIFIED: inbound Plug/provider sources] |

### Known Threat Patterns for This Refactor

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Pipeline reorder verifies after tenant/database work | Spoofing / DoS | Characterize and retain verify-before-tenant order. [VERIFIED: current Plug documentation] |
| Runtime cache serves stale overridden config | Tampering / reliability | Explicit cache invalidation/bootstrap contract and tests. [ASSUMED] |
| Broad sibling dependency bypasses a narrow security capability | Elevation of privilege | Permit only named core ports and reject reverse implementation imports. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- Repository live source: `lib/mailglass.ex`, `lib/mailglass/config.ex`, `lib/mailglass/outbound.ex`, `lib/mailglass/application.ex`, `lib/mailglass/repo.ex`, and inbound Config/Plug/Execution/OptionalDeps modules.
- [Phase 158 pattern map](158-PATTERNS.md) - codebase-specific boundaries, edges, façade preservation, and sequencing.
- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` - scope and compatibility locks.
- Phase 155–157 research/context artifacts - prior migration, execution, inbound pipeline, and bounded-lifecycle constraints.

### Secondary (MEDIUM confidence)

- [Mix xref documentation](https://hexdocs.pm/mix/Mix.Tasks.Xref.html) - compile-connected cycles and graph commands.
- [Elixir configuration and distribution](https://hexdocs.pm/elixir/config-and-distribution.html) - application environment and runtime configuration.

### Tertiary (LOW confidence)

- [Boundary documentation](https://hexdocs.pm/boundary/Boundary.html) - compiler boundary enforcement; corroborated by existing local Boundary use.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing dependencies/toolchain and local commands verified.
- Architecture: HIGH — exact current cycle, package dependency, façades, and implementation seams inspected.
- Pitfalls: HIGH for observed source/order/cache patterns; MEDIUM where the target extraction mechanics are prospective.

**Research date:** 2026-08-17  
**Valid until:** 2026-09-16 for repository seams; re-run `xref` and source inventory immediately before implementation.
