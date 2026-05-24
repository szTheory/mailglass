# Phase 48: Inbound Admin LiveView - Research

**Researched:** 2026-05-24
**Domain:** Phoenix LiveView observability surface (cross-package optional consumer) + matcher reflection
**Confidence:** HIGH (entire technical surface verified by codebase grep + file reads; all 13 CONTEXT decisions confirmed against source with line numbers)

## Summary

Phase 48 ships `MailglassAdmin.InboundLive` — a structural clone of the shipped `OperatorLive`
master/detail shell — reaching `mailglass_inbound` through a **runtime-gated optional dependency**
(no compile edge, no Boundary edge). The technical architecture is LOCKED by 13 decisions in
`48-CONTEXT.md` (D-48-01..13), all of which this research independently re-verified against source.
There is exactly **one genuinely novel surface**: the routing-trace matcher reflection (D-48-06),
which exposes the private per-clause matcher predicates from `MailglassInbound.Router.Matcher` via a
new `@moduledoc false` `explain/2` so the rendered "why didn't this match" verdict is computed from
the same predicates that real routing uses (single source of truth, zero divergence).

This research does **not** re-litigate the locked decisions. Its job is threefold per the objective:
(1) define the **Validation Architecture** (the Nyquist VALIDATION.md driver) covering the six
structural invariants; (2) confirm/sharpen the routing-trace reflection shape (predicate shapes,
Route fields, `matches_route?/2` decomposition); (3) surface the landmines not already in CONTEXT.md.

**Primary recommendation:** Clone `OperatorLive` mechanics verbatim into `MailglassAdmin.InboundLive`
+ `MailglassAdmin.Inbound.*` sibling components; build the inbound read-model as `@moduledoc false`
`MailglassInbound.Internal.Operator.*` (tenant-required-or-empty, `Tenancy.scope/2` on every query);
add `Router.Matcher.explain/2` reusing the existing `defp` predicates; gate the entire surface behind
a new `MailglassAdmin.OptionalDeps.MailglassInbound.available?/0`. **Three landmines the planner MUST
respect, none currently in CONTEXT.md:** (a) replay on a `:no_match` record always fails by design;
(b) `suppression_flagged` (IOPS-05) does not exist on any schema yet — Phase 49 work, so the detail
header must read it defensively; (c) the admin test suite migrates only the *core* repo — inbound
tables must be added to the admin test bootstrap or InboundLive tests cannot insert fixtures.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Inbound list/detail rendering | Frontend Server (LiveView) | — | `MailglassAdmin.InboundLive` clones `OperatorLive`; server-rendered, URL-as-state |
| Tenant-scoped inbound queries | API/Data (owning package) | — | Data access lives in `mailglass_inbound` (`Internal.Operator.*`), NOT in admin (D-48-04) |
| Tenant gate (read + replay) | API/Data + Frontend Server | — | Read-model is tenant-required-or-empty; admin gates record-ownership BEFORE the un-scoped `Internal.Replay.replay/2` (D-48-05) |
| Routing-trace verdict | API/Data (owning package) | Frontend Server (render) | Verdict computed by `Router.Matcher.explain/2` (reflection); LiveView only renders the structured result (D-48-06) |
| Replay execution | API/Data (owning package) | — | `Internal.Replay.replay/2` → `Execution.execute(source: :replay)`; append-only |
| Capability gates (`:replay_inbound`, `:reveal_raw`) | Frontend Server (auth seam) | — | Ride existing `MailglassAdmin.Auth.authorize/3` `atom()` action type (D-48-09); no new auth tier |
| Live updates | Frontend Server (PubSub consumer) | — | `InboundLive` subscribes to `Mailglass.PubSub`; inbound side already broadcasts (Phase 45) |
| Optional-dep gating | Frontend Server (compile + runtime) | — | `OptionalDeps.MailglassInbound` gateway; surface no-ops when inbound absent (D-48-03) |

## Standard Stack

This phase introduces **zero new external packages**. Every capability is built from libraries
already in `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs`. The only new dependency edge
is the sibling package `mailglass_inbound` itself, added as `optional: true`.

### Core (already present, reused)
| Library | Version (verified in mix.exs) | Purpose | Why Standard |
|---------|-------------------------------|---------|--------------|
| `phoenix_live_view` | `~> 1.1` | The master/detail surface | Already the admin's LiveView engine; clone OperatorLive |
| `phoenix` | `~> 1.8` | Router macro, PubSub | Hosts `mailglass_operator_routes/2` |
| `boundary` | `~> 0.10` (runtime: false) | Architecture enforcement | Decl stays UNCHANGED (D-48-02) |
| `nimble_options` | `~> 1.1` | Macro opt validation | Validates the new `:inbound_router` opt on the operator macro |
| `mailglass_inbound` | `~> 0.2` (NEW, `optional: true`, floating) | Inbound data + reflection + replay | The sibling consumer edge (D-48-01) |

### Supporting (test-env only, already present)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `lazy_html` | `>= 0.1.0` (only: :test) | LiveViewTest DOM traversal | InboundLive LiveView tests |
| `floki` | `~> 0.38` | HTML assertions | Render assertions |
| `ecto_sql` | (via inbound path dep) | Inbound TestRepo migrations in admin suite | Wave 0 test infra |

### Alternatives Considered (all rejected by locked decisions — listed for completeness)
| Instead of | Could Use | Tradeoff (why rejected) |
|------------|-----------|-------------------------|
| `optional: true` floating dep | Non-optional `==` linked pin | Breaks no-optional-deps CI lane + writes unsatisfiable `== 1.2.0` into a 0.2.x package (D-48-01) |
| Runtime `apply/3` gateway | Add `MailglassInbound` to Boundary `deps:` | Absent app in `deps:` emits `unknown_dep`, breaks `--no-optional-deps` lane (D-48-02) |
| `Internal.Operator.*` read-model | Public `MailglassInbound.Operator.*` API | Expands inbound's 0.x stable contract prematurely (D-48-04) |
| `Matcher.explain/2` reflection | Re-implement matcher in the view | Silent divergence risk — the exact bug UI-SPEC forbids (D-48-06) |

**Installation:** No `npm`/`mix hex` installs. The dependency change is a mix.exs edit only:
```elixir
# mailglass_admin/mix.exs deps/0 — add a plain floating entry:
{:mailglass_inbound, "~> 0.2", optional: true},
# plus a local-dev helper mirroring mailglass_dep/0 but FLOATING (never ==):
defp mailglass_inbound_dep do
  if System.get_env("MIX_PUBLISH") == "true" do
    {:mailglass_inbound, "~> 0.2", optional: true}
  else
    {:mailglass_inbound, path: "../mailglass_inbound", optional: true}
  end
end
```

## Package Legitimacy Audit

> No external packages are installed in this phase. The only new dependency edge is the
> first-party sibling package `mailglass_inbound`, already published to Hex by the project
> maintainer (v0.1.0; v0.2.0 ships at Phase 50.5). Slopcheck / registry verification is N/A
> for a first-party sibling. The `floating-vs-pinned` and release-please interaction is the
> real risk surface here, covered in detail under Common Pitfalls.

| Package | Registry | Disposition |
|---------|----------|-------------|
| `mailglass_inbound` | Hex (first-party, szTheory/mailglass) | Approved — sibling package, not third-party |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IADM-01 | `InboundLive` master/detail, URL-param filters, tenant-required gate | Clone `OperatorLive` (`operator_live.ex`); tenant gate mirrors `load_deliveries/1:338`. Read-model = new `Internal.Operator.*` mirroring `Operator.Deliveries.list_recent_deliveries/2`. Filter outcomes from `ExecutionRun.__outcomes__/0`. |
| IADM-02 | Detail: canonical `%InboundMessage{}`, raw `InboundEvidence`, matched mailbox + outcome, timeline of runs | Schemas verified: `InboundRecord` (canonical), `InboundEvidence` (`raw_payload`/`raw_mime` `redact: true`), `ExecutionRun` (the timeline rows, table `mailglass_inbound_replay_runs`). IOPS-05 `suppression_flagged` surfaced READ-ONLY — **see Pitfall 4 (field does not exist yet).** |
| IADM-03 | Replay modal, confirmation-gated, tenant-bound, no ambiguous-multi case | `Internal.Replay.replay/2` is the seam; outbound `ReplayModal` collapses (no `replay_targets` status branching). Tenant gate via new inbound `DestructiveAction` sibling (D-48-10). **See Pitfall 1 (`:no_match` replay always fails).** |
| IADM-04 | Routing-trace card: matcher diff vs `__mailglass_inbound_routes__/0` | The novel surface. New `Router.Matcher.explain/2` reuses `matches_matcher?/2` + `matches_headers?/2`. Route has 4 fields; matcher has 3 kinds. Full shape in "Routing-Trace Reflection" section. |
| IADM-05 | Live updates via `MailglassAdmin.PubSub.Topics` from TELE-07 | Inbound broadcasts `{:inbound_record_inserted, record_id, %{provider:, record_type:}}` on `Mailglass.PubSub` @ `"mailglass:inbound:" <> tenant_id` (verified in `ingress/plug.ex:519-528`). Admin adds matching builder + subscribe; **payload is record_id only → re-fetch tenant-scoped.** |
| IADM-06 | Composed brand-voice error copy | All copy strings locked in UI-SPEC Copywriting Contract. Replay error reasons map from `Internal.Replay`'s structured `{:error, ...}` tuples (`:not_found`, `{:replay_mailbox_missing, ...}`). |
| IADM-07 | Reachable from nav, gated by existing `MailglassAdmin.Auth` | Mount in the operator `live_session` (D-48-12) with `Operator.Mount` hook; `available?/0` additionally gates. Nav link added. No new auth surface. |
| IOPS-05 (read-only) | `suppression_flagged` surfaced in detail header | **Field does not exist on any schema (grep-confirmed zero occurrences).** Phase 49 persists it. Detail header must read defensively. See Pitfall 4. |

## Architecture Patterns

### System Architecture Diagram

```
                         ADOPTER ROUTER (host app)
                                  │
              mailglass_operator_routes "/mail",
                auth: MyAuth,
                inbound_router: MyApp.InboundRouter   ◄── NEW opt (D-48-07)
                                  │
                                  ▼
        ┌──────────── operator live_session (Operator.Mount → Auth gate) ──────────┐
        │   live "/"          → OperatorLive          (existing, untouched)         │
        │   live "/inbound"   → InboundLive           (NEW, gated by available?/0)  │
        └───────────────────────────────────┬──────────────────────────────────────┘
                                             │
                  ┌──────────────────────────┼───────────────────────────────┐
                  │                           │                               │
            (read-model)                 (reflection)                    (replay)
                  ▼                           ▼                               ▼
   OptionalDeps.MailglassInbound      Router.Matcher.explain/2     Internal.Replay.replay/2
   .available?/0 + apply/3            (NEW @moduledoc false)        (existing; NOT tenant-scoped)
                  │                           │                               │
                  ▼                           │                  admin gates record-ownership
   MailglassInbound.Internal.Operator.*       │                  to active tenant FIRST (D-48-05)
   (NEW @moduledoc false)                      │                               │
   Tenancy.scope/2 on EVERY query              │                               ▼
   tenant-required-or-empty                    │                  Execution.execute(source: :replay)
                  │                            │                  → appends ExecutionRow (append-only)
                  ▼                            ▼
            MailglassInbound.Repo (host-repo facade: all/2, one/3, get/3)
                  │
                  ▼
            Postgres: mailglass_inbound_records / _evidence / _replay_runs

   LIVE UPDATES (IADM-05):
   ingress/plug.ex  ──broadcast {:inbound_record_inserted, id, meta}──►  Mailglass.PubSub
                       topic "mailglass:inbound:<tenant_id>"                    │
                                                                               ▼
   InboundLive.mount → subscribe via MailglassAdmin.PubSub.Topics.inbound_record_inserted/1
   handle_info({:inbound_record_inserted, id, _}) → re-fetch record TENANT-SCOPED → prepend to list
   (must NOT steal selection or reset filters)
```

### Recommended Module Structure
```
mailglass_admin/lib/mailglass_admin/
├── inbound_live.ex                    # NEW — clone of operator_live.ex shell
├── inbound/                           # NEW — sibling components (D-48-13)
│   ├── records_list.ex               # clone deliveries_list.ex
│   ├── detail_header.ex              # clone detail_header.ex (+ suppression_flagged defensive read)
│   ├── timeline.ex                   # clone timeline.ex (ExecutionRun rows, source badge)
│   ├── replay_modal.ex              # clone replay_modal.ex (SIMPLIFIED — no target branching)
│   ├── filters_form.ex              # clone filters_form.ex (provider/outcome/window/search)
│   ├── routing_trace.ex             # NET-NEW — the novel card
│   ├── evidence_card.ex             # NET-NEW chrome reuse — redacted-by-default
│   └── destructive_action.ex        # NEW sibling (inbound-shaped context; D-48-10)
├── optional_deps/
│   └── mailglass_inbound.ex          # NEW — Code.ensure_loaded? gateway (clone phoenix_live_reload.ex)
├── components.ex                      # PROMOTE mask_recipient/1 to public helper (D-48-13)
├── pub_sub/topics.ex                 # ADD inbound_record_inserted/1 builder
└── router.ex                         # ADD :inbound_router opt + live "/inbound" route

mailglass_inbound/lib/mailglass_inbound/
├── router/matcher.ex                 # ADD explain/2 (reuses existing defp predicates)
└── internal/operator/               # NEW @moduledoc false read-model
    ├── records.ex                    # mirror Mailglass.Operator.Deliveries (tenant-required)
    ├── timeline.ex                   # ExecutionRun rows for a record
    └── detail.ex                     # canonical record + evidence + matched mailbox/outcome
```

### Pattern 1: Optional-Dep Gateway (clone `phoenix_live_reload.ex` exactly)
**What:** Wrap the entire gateway module in `if Code.ensure_loaded?(MailglassInbound) do ... end`,
declare `@compile {:no_warn_undefined, [...]}`, expose `available?/0`, route ALL inbound calls
through `apply/3`.
**When to use:** Every inbound access from admin (read-model, reflection, replay).
**Example:**
```elixir
# Source: mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex (verified)
if Code.ensure_loaded?(MailglassInbound) do
  defmodule MailglassAdmin.OptionalDeps.MailglassInbound do
    @compile {:no_warn_undefined,
              [MailglassInbound, MailglassInbound.Internal.Operator.Records,
               MailglassInbound.Router.Matcher, MailglassInbound.Internal.Replay]}
    @spec available?() :: boolean()
    def available?, do: true   # mere existence implies loaded; callers still Code.ensure_loaded?(__MODULE__)
  end
end
```
**Note:** Because the module is conditionally compiled, `InboundLive`/router/nav must guard via
`Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)` (NOT a bare module reference).
Mirror core's Oban gate (`lib/mailglass.ex:55-60`) for the call-site pattern.

### Pattern 2: Tenant-required-or-empty read-model (mirror `Operator.Deliveries`)
**What:** A `defp` head that returns `[]` for a blank tenant, plus `Tenancy.scope/2` piped before
`Repo.all`. Two layers: the LiveView's `load_*(%{"tenant_id" => ""}) -> []` head, AND the read-model's
`fetch_tenant_id!` raising on a blank tenant.
**Example:**
```elixir
# Source: lib/mailglass/operator/deliveries.ex:18-50 + operator_live.ex:338 (both verified)
# In InboundLive (mirrors operator_live.ex:338):
defp load_inbound_records(%{"tenant_id" => ""}), do: []
defp load_inbound_records(filter_params), do: apply(gateway, :list_records, [...])

# In MailglassInbound.Internal.Operator.Records (mirrors deliveries.ex:48):
query
|> where([r], r.tenant_id == ^tenant_id)
|> ...
|> Tenancy.scope(tenant_id)   # ◄── the load-bearing line; inbound has ZERO Tenancy.scope today
|> Repo.all()
```

### Pattern 3: Live-update re-fetch (payload is PII-free, id-only)
**What:** The broadcast carries `{:inbound_record_inserted, record_id, %{provider:, record_type:}}` —
**not** the full record (PII discipline). `handle_info/2` must re-fetch the record TENANT-SCOPED, then
prepend to the list without disturbing selection/filters.
**Example:**
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:519-528 (verified)
def handle_info({:inbound_record_inserted, record_id, _meta}, socket) do
  case tenant_scoped_fetch(socket.assigns.filter_params["tenant_id"], record_id) do
    nil    -> {:noreply, socket}                       # other tenant / filtered out
    record -> {:noreply, prepend_without_stealing_selection(socket, record)}
  end
end
```

### Anti-Patterns to Avoid
- **Querying inbound Ecto schemas directly from admin:** breaks "data access in the owning package"
  and puts tenancy in the wrong tier (D-48-04). Always go through `Internal.Operator.*`.
- **Re-implementing matcher semantics in the routing-trace view:** silent divergence (D-48-06).
- **Calling `Internal.Replay.replay/2` before verifying record ownership:** cross-tenant replay via
  guessed UUID (D-48-05). `replay/2` loads by id only — it does NOT tenant-scope.
- **Adding `MailglassInbound` to the Boundary `deps:` list:** `unknown_dep` error (D-48-02).
- **A `==` pin on the inbound dep:** unsatisfiable cross-line pin + release-please breakage (D-48-01).
- **Bare `MailglassInbound.*` reference outside the gateway:** breaks `--no-optional-deps` lane.
- **Literal PubSub topic string at a call site:** LINT-06 violation; always go through the builder.

## Routing-Trace Reflection (D-48-06 — the one novel surface, SHARPENED)

This is the only place the phase invents new behavior. The reflection must be a thin function over the
**existing** predicates so the rendered verdict equals real matcher behavior.

### Verified data model (from source)

**`MailglassInbound.Router.Route` — exactly 4 fields** (`router/route.ex:14`):
```elixir
defstruct [:mailbox, :recipient, :subject, headers: []]
# @type t :: %{mailbox: module(), recipient: matcher()|nil, subject: matcher()|nil, headers: [{String.t(), matcher()}]}
# @type matcher :: String.t() | Regex.t()    (nil also valid for recipient/subject = wildcard)
```

**`MailglassInbound.Router.Matcher` decomposition** (`router/matcher.ex:31-48`, verified):
```elixir
def matches_route?(%Route{} = route, %InboundMessage{} = message) do        # public, l.31
  matches_matcher?(route.recipient, message.envelope_recipient) and          # AND across 3 dims
    matches_matcher?(route.subject, message.subject) and
    matches_headers?(route.headers, message.headers)
end

defp matches_headers?(headers, normalized_headers) do                        # defp, l.37
  Enum.all?(headers, fn {name, matcher} ->                                   # AND across all header clauses
    normalized_headers |> Map.get(name, []) |> Enum.any?(&matches_matcher?(matcher, &1))
  end)
end

defp matches_matcher?(nil, _value), do: true                                 # defp, l.45 — wildcard PASS
defp matches_matcher?(_matcher, nil), do: false                             #         l.46 — nil actual FAILS
defp matches_matcher?(%Regex{} = m, v) when is_binary(v), do: Regex.match?(m, v)  # l.47 — regex
defp matches_matcher?(m, v) when is_binary(m) and is_binary(v), do: m == v   # l.48 — exact string equality
```

### Three matcher kinds (finite, verified)
1. `nil` → wildcard, always passes (`any` in the UI).
2. `String.t()` → exact string equality.
3. `%Regex{}` → `Regex.match?/2` (rendered as `~r/…/` in the UI).
Plus the **`_matcher, nil` fall-through**: when the message has no value for a dimension (nil subject,
or a header absent → `Map.get(name, []) = []` → `Enum.any?` over `[]` is `false`), the clause FAILS
unless the matcher is `nil` (wildcard).

### Recommended `explain/2` shape (Claude's discretion per CONTEXT — this is the recommendation)
Add to `MailglassInbound.Router.Matcher` (keeps it co-located with the predicates it reuses):
```elixir
@doc false
@spec explain(Route.t(), InboundMessage.t()) :: [clause_verdict()]
# clause_verdict ::
#   {:recipient, expected :: matcher()|nil, actual :: String.t()|nil, pass? :: boolean()}
# | {:subject,   expected, actual, pass?}
# | {:header, name :: String.t(), expected, actual :: [String.t()], pass?}
def explain(%Route{} = route, %InboundMessage{} = message) do
  [
    {:recipient, route.recipient, message.envelope_recipient,
       matches_matcher?(route.recipient, message.envelope_recipient)},
    {:subject, route.subject, message.subject,
       matches_matcher?(route.subject, message.subject)}
    | Enum.map(route.headers, fn {name, matcher} ->
        actual = Map.get(message.headers, name, [])
        {:header, name, matcher, actual, Enum.any?(actual, &matches_matcher?(matcher, &1))}
      end)
  ]
end
```
**Critical reuse rule:** `explain/2` calls the SAME `matches_matcher?/2` clauses (now reachable
because they live in the same module). Do NOT copy the equality/regex logic. The overall route verdict
the card shows is `Enum.all?(verdicts, &elem(&1, -1))`, which must equal `matches_route?/2` for the
same route+message — this equivalence is the highest-signal property test (see Validation Architecture).

**Header "actual" is a LIST.** `InboundMessage.headers` is `%{name => [String.t()]}` (verified in
`inbound_message.ex:52`). A missing header renders as `[]`; the UI shows "no such header" copy
(UI-SPEC). The masking rule applies to the recipient actual (`mask_recipient/1`); subject/header
actuals are rendered verbatim mono.

### Where routes come from at render time
`InboundLive` has NO ambient way to know the adopter's router — there is no
`Application.get_env(:mailglass_inbound, :router|:routes)` (grep-confirmed; routes are supplied
per-request to the ingress plug via opts, resolved in `persist.ex` via
`opts[:router].__mailglass_inbound_routes__()`). So D-48-07 threads an explicit `:inbound_router`
(or `:inbound_routes`) option on `mailglass_operator_routes/2`, into the session/assigns alongside
`:auth`. The card calls `inbound_router.__mailglass_inbound_routes__()` then `explain/2` per route.
Without the option the card renders an empty route list (document in Phase 50 guide).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Matcher pass/fail logic in the view | A re-implementation of recipient/subject/header equality | `Router.Matcher.explain/2` reusing `matches_matcher?/2` | Silent divergence from real routing — the bug UI-SPEC forbids |
| Tenant scoping in admin | A `where tenant_id` in admin queries | `MailglassInbound.Internal.Operator.*` + `Tenancy.scope/2` | Tenancy belongs in the owning package (D-48-04) |
| Cross-package availability check | Ad-hoc `function_exported?` scattered at call sites | One `OptionalDeps.MailglassInbound` gateway | Single auditable seam; `--no-optional-deps` safety |
| PII masking | A second mask function in inbound components | Promote `mask_recipient/1` to `Components` (one definition) | One audited PII-masking definition (D-48-13) |
| Replay execution + append | Manual `ExecutionRun` insert from admin | `Internal.Replay.replay/2` → `Execution.execute(source: :replay)` | Append-only contract already implemented |
| New auth surface for capabilities | A new plug/behaviour for `:replay_inbound`/`:reveal_raw` | Existing `Auth.authorize/3` `atom()` action type | `auth.ex:33` already accepts arbitrary atoms (D-48-09) |
| Topic string construction | Literal `"mailglass:inbound:" <> id` at call sites | `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1` | LINT-06; must match inbound's builder string exactly |

**Key insight:** Almost nothing in this phase is net-new logic. It is a *plumbing* phase — clone the
shipped outbound observability surface, reuse the inbound package's existing replay/matcher internals,
and add exactly one reflection function. Every "build" temptation has a shipped precedent to reuse.

## Runtime State Inventory

> This is not a rename/migration phase, but it DOES introduce two adopter-visible config surfaces and
> consumes a live PubSub stream. Inventory below for completeness.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None new. Reads existing `mailglass_inbound_records` / `_evidence` / `_replay_runs` (ExecutionRun maps to the `_replay_runs` table). Replay APPENDS an `ExecutionRun` row — no new schema, no migration. | None — pure consumer + append via existing seam |
| Live service config | PubSub topic `"mailglass:inbound:<tenant_id>"` on `Mailglass.PubSub` — inbound side already broadcasts (Phase 45, verified `ingress/plug.ex`). Admin adds the consumer builder + subscribe. | Add `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1` producing the identical string |
| OS-registered state | None. | None |
| Secrets/env vars | None new. | None |
| Build artifacts | `mailglass_admin/priv/static/` CSS bundle: the inbound surface reuses existing daisyUI/heroicons primitives (UI-SPEC confirms zero new tokens), so `mix mailglass_admin.assets.build` should produce no bundle diff — BUT the merge gate runs `git diff --exit-code priv/static/`. Verify no drift after any class additions. | Run `mailglass_admin.assets.build`; commit bundle if any class change pulls new utilities |
| Adopter-visible config (NEW) | (1) optional install line `{:mailglass_inbound, "~> 0.2", optional: true}`; (2) `:inbound_router` mount option on `mailglass_operator_routes/2`. | Document both in Phase 50 install + routing-debug guides (out of THIS phase's scope, but note in plan) |

## Common Pitfalls

### Pitfall 1: Replay on a `:no_match` record ALWAYS fails (by design) — NOT in CONTEXT.md
**What goes wrong:** The UI-SPEC shows the routing-trace card AND a Replay button on `:no_match`
records. An operator looking at "why didn't this match?" naturally clicks Replay. But
`Internal.Replay.replay/2` resolves the mailbox from prior execution history
(`resolve_mailbox/2`, `internal/replay.ex:50-67`): it looks for the latest *matched* fresh run, and if
the latest fresh run was `:no_match` it returns `{:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}`.
A `:no_match` record has, by definition, no matched mailbox — so replay can never succeed for it.
**Why it happens:** Replay re-runs an *existing* routing decision; there is nothing to re-run when
routing produced no match. This is correct behavior, not a bug.
**How to avoid:** The planner must decide the UX: either (a) hide/disable the Replay button when the
displayed outcome is `:no_match` (cleanest — replay is meaningless there), or (b) allow the click and
surface the composed copy `Replay blocked: mailbox module not found.` (UI-SPEC IADM-06 verbatim maps
`{:replay_mailbox_missing, ...}` to this). Recommendation: disable on `:no_match` AND map the error
defensively (race: a record could gain a matched run between render and click). The error→copy mapping
is the load-bearing test (see Validation Architecture).
**Warning signs:** A test that replays a `:no_match` record and expects success will be permanently red.

### Pitfall 2: `suppression_flagged` (IOPS-05) does not exist on any schema yet — NOT in CONTEXT.md
**What goes wrong:** UI-SPEC + REQUIREMENTS say to surface `suppression_flagged` in the detail header
(read-only). But grep confirms ZERO occurrences of `suppression_flagged` in the inbound lib, and
neither `InboundRecord` nor `InboundMessage` has a `suppression_flagged` OR a `metadata` field. IOPS-05
*persistence* is explicitly Phase 49 (REQUIREMENTS.md). Pattern-matching `record.suppression_flagged`
will raise `KeyError`.
**Why it happens:** Phase 48 is a pure consumer that ships before the field exists.
**How to avoid:** The detail header must read the flag defensively — `Map.get(record, :suppression_flagged, false)`
(struct access via `Map.get`, never `record.suppression_flagged`). Render the IOPS-05 copy only when
truthy. Because the field is always absent in Phase 48, the indicator will simply never render until
Phase 49 — which is the correct staged behavior. The planner should treat the suppression indicator as
forward-compatible scaffolding, not a fully-wired feature this phase.
**Warning signs:** `KeyError: key :suppression_flagged not found` in detail-header tests.

### Pitfall 3: Admin test suite migrates ONLY the core repo — inbound tables are absent
**What goes wrong:** `mailglass_admin/test/test_helper.exs` migrates from `:code.priv_dir(:mailglass)`
and starts `MailglassAdmin.TestRepo` (`otp_app: :mailglass`). It runs NO inbound migrations and sets
NO `config :mailglass_inbound, :repo`. InboundLive tests that insert inbound fixtures will fail —
either `MailglassInbound.Repo` raises ("requires config :mailglass_inbound, :repo") or the inbound
tables don't exist in the test DB.
**Why it happens:** Inbound was never a dep of admin before this phase (grep-confirmed). The admin test
bootstrap predates any inbound table.
**How to avoid (Wave 0 test infra):**
1. Add `config :mailglass_inbound, :repo, MailglassAdmin.TestRepo` to `mailglass_admin/config/test.exs`
   (point the inbound facade at the admin test repo).
2. In `mailglass_admin/test/test_helper.exs`, ALSO run the inbound migrations against the same DB:
   `Path.join(:code.priv_dir(:mailglass_inbound), "repo/migrations")` (mirror the existing
   `with_repo` block; same pool-override dance — `DBConnection.ConnectionPool` during migration, then
   restore `Sandbox`).
3. The floating path dep `{:mailglass_inbound, path: "../mailglass_inbound", optional: true}` makes the
   inbound modules + `MailglassInbound.Fixtures` (ships in `lib/`) available in the admin test env.
**Alternative:** Build a thin gateway-stub in admin tests and assert against the gateway boundary — but
the routing-trace + replay invariants need REAL matcher/replay behavior, so the real inbound repo is
strongly preferred. `MailglassInbound.Fixtures.build_inbound_message/1` defaults a `tenant_id` (good
for tenant-isolation tests).
**Warning signs:** `RuntimeError: mailglass_inbound requires config :mailglass_inbound, :repo` or
`relation "mailglass_inbound_records" does not exist` in InboundLive tests.

### Pitfall 4: release-please sed-pin must NOT touch the inbound dep
**What goes wrong:** The publish-time sync step (`release-please.yml:119-179`) loops over a `PINS`
array `("mailglass_admin/mix.exs:mailglass" "mailglass_inbound/mix.exs:mailglass")` and runs
`sed -i -E "s/\{:mailglass, \"== X.Y.Z\"\}/.../"` against each. The regex is anchored on the literal
atom `mailglass` immediately followed by `, "== `. A floating `{:mailglass_inbound, "~> 0.2", optional: true}`
entry is **structurally invisible** to it: `mailglass_inbound` has `_inbound` between `mailglass` and
the comma, and `~> 0.2` is not the `== X.Y.Z` shape. Confirmed by reading the workflow. **The danger
is only if someone later "fixes" the inbound dep to a `==` pin** — then the regex `{:mailglass, "== ...`
still would NOT match `{:mailglass_inbound, "== ...` (the comma anchor saves it), but a `==` pin would
itself write an unsatisfiable `== 1.2.0` (core's linked version) into a package on the 0.2.x line.
**Why it happens:** `mailglass`+`mailglass_admin` are linked-versioned at the 1.x line; `mailglass_inbound`
tracks its own 0.x line and is deliberately excluded from the linked group.
**How to avoid:** Keep the inbound dep FLOATING (`"~> 0.2"`) and OUT of the `PINS` array (D-48-01).
There is also a REL-05 exit-1 guard: if the sed anchor matches zero lines in a PINS path it fails the
build — so do not accidentally change `mailglass_admin`'s OWN `{:mailglass, "== X.Y.Z"}` shape while
editing `deps/0`. Add the inbound dep as a *separate* line; leave `mailglass_dep/0` untouched.
**Warning signs:** Phase 50.5 Hex publish fails with an unsatisfiable version constraint; or the
release-please sync step exits 1 ("sed anchor regex matched zero lines").

### Pitfall 5: Boundary `unknown_dep` if inbound is added to `deps:`
**What goes wrong:** Listing `MailglassInbound` in `use Boundary, deps: [...]` when the app is absent
(the `--no-optional-deps` lane strips it) makes `Boundary.get/2` return `nil`, emitting an `unknown_dep`
error that breaks `mix compile --no-optional-deps --warnings-as-errors` (mandatory CI lane). Boundary
0.10.4 has no per-dep "may be absent" option.
**How to avoid:** Leave `mailglass_admin.ex:45-47` (`use Boundary, deps: [Mailglass], exports: [Router]`)
UNCHANGED (D-48-02). NOT listing the dep means calls are unrestricted by Boundary — route them through
the runtime `apply/3` gateway instead. This is the same posture as the existing PhoenixLiveReload gate.
**Warning signs:** `unknown_dep` Boundary error; `--no-optional-deps` lane red.

### Pitfall 6: Live-update payload is id-only — never assume the full record
**What goes wrong:** Treating the broadcast message as if it carries the record (e.g. prepending
`payload.record` to the list) — it doesn't. The payload is `{:inbound_record_inserted, record_id,
%{provider:, record_type:}}`, PII-free by contract (verified `ingress/plug.ex:525`).
**How to avoid:** `handle_info/2` must re-fetch the record TENANT-SCOPED by id through the read-model.
A record for another tenant (the topic is per-tenant so this is rare) or one filtered out by the
current filters should be dropped. Prepend only; never steal selection or reset filters (D-48-11).
**Warning signs:** `KeyError`/`nil` on the payload; cross-tenant or filtered records appearing.

### Pitfall 7: ExecutionRun vs ReplayRun schema confusion (both map to `mailglass_inbound_replay_runs`)
**What goes wrong:** There are TWO schemas — `ExecutionRun` and `ReplayRun` — and BOTH declare
`schema "mailglass_inbound_replay_runs"`. The timeline (IADM-02) is built from **`ExecutionRun`** rows
(it has the `source :: :fresh | :replay` field and `outcome :: :no_match | :accept | ...`).
`ReplayRun` is a narrower legacy/parallel schema (`:accept|:ignore|:reject|:bounce|:failed`, no
`:no_match`, requires a `replay_id` + `mailbox`). `Internal.Replay.replay/2` and `Execution.execute`
both write via `InboundRecords.insert_execution_run` (ExecutionRun). `ExecutionRun.__outcomes__/0` is
the canonical filter set for the outcome filter.
**How to avoid:** Build the timeline and the outcome filter from **`ExecutionRun`** (`source` badge
Fresh/Replay, `outcome`, `outcome_reason`, `executed_at`). Do not read `ReplayRun` for the timeline.
**Warning signs:** Missing `:no_match` rows in the timeline; an outcome filter that lacks `no_match`.

## Code Examples

### Mirror the operator master/detail handle_params/push_patch URL-state (clone)
```elixir
# Source: mailglass_admin/lib/mailglass_admin/operator_live.ex:68-117 (verified)
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)
  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator/inbound")
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))
   |> assign_inbound_state(filter_params, blank_to_nil(params["inbound_id"]))}
end
```

### Capability gate via existing auth seam (no new auth surface)
```elixir
# Source: mailglass_admin/lib/mailglass_admin/auth.ex:33 + operator/destructive_action.ex (verified)
# NEW inbound sibling (D-48-10) — inbound-shaped context, never the outbound :delivery key:
def authorize(%Socket{} = socket, adapter, inbound_record) when is_atom(adapter) do
  case Auth.authorize(adapter, :replay_inbound, %{
         actor: socket.assigns.operator_actor,
         inbound_record: inbound_record          # ◄── inbound key, NOT :delivery
       }) do
    {:ok, %{actor: actor, assigns: extra}} -> {:ok, assign(socket, :operator_actor, actor)}
    {:error, _reason, details} -> {:error, {:auth, Map.get(details, :message, "Replay blocked: this action is not authorized for the current operator.")}}
  end
end
```

### Admin-side topic builder (must match inbound's string EXACTLY)
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex:33-34 (verified — match this)
# Add to MailglassAdmin.PubSub.Topics:
@spec inbound_record_inserted(String.t()) :: String.t()
def inbound_record_inserted(tenant_id) when is_binary(tenant_id),
  do: "mailglass:inbound:" <> tenant_id      # IDENTICAL string; LINT-06 passes (no literal at call site)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| LiveViewTest via floki | `lazy_html` DOM traversal | phoenix_live_view 1.1 | Already in admin deps (`only: :test`); use it for InboundLive tests |
| (no inbound admin) | Optional runtime-gated sibling consumer | This phase | First cross-sibling optional dep edge in admin |

**Deprecated/outdated:** None relevant. The stack (Phoenix 1.8 / LiveView 1.1 / daisyUI 5 / Tailwind v4,
zero Node) is the project's locked current state.

## Validation Architecture

> nyquist_validation is `true` in `.planning/config.json` (`workflow.nyquist_validation`). This section
> drives VALIDATION.md. Six structural invariants per the objective, each with test layer + highest-signal
> assertion.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18) + Phoenix.LiveViewTest (lazy_html DOM) |
| Config file | `mailglass_admin/config/test.exs` (needs the inbound-repo addition — Wave 0) |
| Test case template | `MailglassAdmin.LiveViewCase` (synthetic adopter endpoint, sandbox checkout, `Tenancy.put_current("test-tenant")`) |
| Reflection unit tests | `mailglass_inbound` suite (`Router.Matcher.explain/2` lives there) |
| Quick run command (admin) | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` |
| Quick run command (inbound reflection) | `cd mailglass_inbound && mix test test/mailglass_inbound/router/matcher_test.exs --seed 0` |
| Full admin gate | `cd mailglass_admin && mix verify.preview` (compile --no-optional-deps + test + assets.build + bundle-drift) |
| No-optional-deps lane | `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` (MUST pass with inbound stripped) |

### The Six Invariants → Test Map

| # | Invariant | Layer | Highest-signal assertion | Automated command |
|---|-----------|-------|--------------------------|-------------------|
| V1 | **Tenant-required-or-empty** (read-model) | LiveView + unit | (a) `live(conn, "/inbound")` with blank tenant renders the empty-state copy, asserts `[]`, leaks NO other-tenant record id/recipient. (b) Read-model unit: blank tenant → `[]`; tenant A query never returns tenant B rows (insert both, assert isolation). | `mix test .../inbound_live_test.exs` + `cd mailglass_inbound && mix test .../internal/operator/records_test.exs --seed 0` |
| V2 | **Append-only replay** | integration | Replay a *matched* record → a NEW `ExecutionRun` with `source: :replay` appended; the pre-existing fresh run row is byte-identical after (count grows by 1, no UPDATE). | `cd mailglass_inbound && mix test .../internal/replay_test.exs --seed 0` (exists) + admin integration that drives the modal |
| V3 | **Routing-trace reflection correctness** (the load-bearing novelty) | unit (property) | `Enum.all?(explain(route, msg), &last_elem) == matches_route?(route, msg)` for ALL route×message combos — assert the rendered overall verdict EQUALS real matcher behavior. Property test over the 3 matcher kinds × {present, absent, nil} actuals × header AND-semantics. Plus example-based: a regex route, an exact route, a wildcard route, a missing-header route. | `cd mailglass_inbound && mix test .../router/matcher_test.exs --seed 0` (StreamData already a test dep) |
| V4 | **Optional-dep gating compiles clean** | compile | `mix compile --no-optional-deps --warnings-as-errors` green with inbound stripped: InboundLive body / `/inbound` route / nav link all no-op; gateway module elided; NO bare `MailglassInbound.*` reference escapes the `apply/3` seam. | `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` |
| V5 | **PII redaction defaults** | LiveView + voice | (a) Evidence card default-renders the redacted placeholder copy; `raw_payload`/`raw_mime` bytes ABSENT from HTML until `:reveal_raw` granted. (b) Recipient masked by default (`mask_recipient/1`); raw recipient ABSENT from list + detail + routing-trace actual. (c) No PII in any telemetry the LiveView emits. | `mix test .../inbound_live_test.exs` (assert `refute html =~ raw_recipient`, `assert html =~ masked`) |
| V6 | **Capability-gate seams** | LiveView | `:replay_inbound` denied → composed brand-voice flash, no `ExecutionRun` appended. `:reveal_raw` denied → redacted placeholder stays + denial copy. Both ride `Auth.authorize/3` `atom()` action; NO new auth module exists (assert module list unchanged). | `mix test .../inbound_live_test.exs` with a stub `Auth` returning `{:error, :unauthorized, ...}` |

### Supporting invariants (also assert)
- **V7 Live-update prepend without selection theft:** broadcast `{:inbound_record_inserted, id, meta}`
  → list prepends the (tenant-scoped re-fetched) record; current selection + filter params UNCHANGED.
  Layer: LiveView. `Phoenix.PubSub.broadcast(Mailglass.PubSub, topic, ...)` then `render(view)` assert.
- **V8 Topic-string parity:** `MailglassAdmin.PubSub.Topics.inbound_record_inserted(t) ==
  MailglassInbound.PubSub.Topics.inbound_record_inserted(t)` for any tenant. Layer: unit. Cheap, catches
  drift if either builder changes.
- **V9 LINT-06:** both topic builders pass `Mailglass.Credo.PrefixedPubSubTopics` (no literal topic
  strings at call sites). Layer: credo. `mix credo --strict`.
- **V10 Brand voice (IADM-06):** rendered HTML for every error/empty/blocked state matches the locked
  UI-SPEC copy; no "Oops/Whoops/Something went wrong." Layer: voice test (greps rendered HTML).
- **V11 Replay-on-`:no_match` blocked (Pitfall 1):** replaying a `:no_match` record surfaces
  `Replay blocked: mailbox module not found.` (maps `{:replay_mailbox_missing, ...}`); no run appended.

### Sampling Rate
- **Per task commit:** the relevant quick-run file (`inbound_live_test.exs` for admin tasks;
  `matcher_test.exs --seed 0` for the reflection task).
- **Per wave merge:** `cd mailglass_admin && mix verify.preview` (full admin gate incl. the
  no-optional-deps lane + bundle-drift) AND `cd mailglass_inbound && mix test --seed 0`.
- **Phase gate:** both suites green + `mix credo --strict` (LINT-06) before `/gsd-verify-work`.

### Wave 0 Gaps (test infrastructure that must land before implementation tests can pass)
- [ ] `mailglass_admin/config/test.exs` — add `config :mailglass_inbound, :repo, MailglassAdmin.TestRepo`
- [ ] `mailglass_admin/test/test_helper.exs` — run inbound migrations against the admin test DB
      (`:code.priv_dir(:mailglass_inbound)/repo/migrations`; same pool-override dance)
- [ ] `mailglass_admin/mix.exs` deps/0 — floating `{:mailglass_inbound, ..., optional: true}` so inbound
      modules + `MailglassInbound.Fixtures` are available in `:test` (also unblocks all of the above)
- [ ] Admin inbound fixtures helper (or reuse `MailglassInbound.Fixtures` + `InboundRecords.insert_*`)
      to seed `InboundRecord` + `InboundEvidence` + `ExecutionRun` rows (matched, no_match, replay)
- [ ] `mailglass_inbound/test/mailglass_inbound/router/matcher_test.exs` — add `explain/2` property +
      example tests (StreamData already a test dep)
- [ ] Synthetic adopter router (`endpoint_case.ex`) — add `inbound_router:` opt to the
      `mailglass_operator_routes` invocation so the routing-trace card has routes to render

## Security Domain

> `security_enforcement` is not set to `false` in config → enabled. This is a trust-boundary-sensitive
> phase (operator surface, tenant isolation, PII, replay mutation).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Optional-dep gateway + Boundary posture keep the trust boundary explicit |
| V2 Authentication | yes (consumed) | Mount in operator `live_session` → `Operator.Mount` → adopter `Auth.authorize(:operator_access)`. NO new auth (D-48-12) |
| V4 Access Control | **yes (primary)** | Tenant-required-or-empty read-model (V1 invariant); record-ownership gate BEFORE un-scoped `Replay.replay/2` (D-48-05); capability gates `:replay_inbound`/`:reveal_raw` |
| V5 Input Validation | yes | URL filter params normalized/cast (clone `normalize_filter_params`); outcome filter cast against `ExecutionRun.__outcomes__/0` allow-list |
| V7 Error Handling | yes | Replay errors mapped to composed copy; no raw `{:error, reason}` or changeset (PII) leaked to HTML (mirror `ingress/plug.ex` PII-safe egress) |
| V8 Data Protection | **yes (primary)** | `raw_payload`/`raw_mime` `redact: true` → default-redacted evidence card; `mask_recipient/1` by default; no PII in LiveView telemetry |
| V6 Cryptography | no | No crypto in this phase |

### Known Threat Patterns for {Phoenix LiveView operator surface + cross-tenant data}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant read via crafted `tenant_id`/`inbound_id` URL param | Information Disclosure | Tenant-required-or-empty read-model + `Tenancy.scope/2` on every query; re-fetch tenant-scoped on live update |
| Cross-tenant replay via guessed record UUID | Tampering / Elevation | Admin verifies record belongs to active tenant BEFORE calling un-scoped `Replay.replay/2` (D-48-05) — the load-bearing gate |
| Raw provider payload (PII) exposure | Information Disclosure | Evidence card default-redacted; `:reveal_raw` capability gate; schema `redact: true` |
| Recipient/sender PII in list/detail/trace | Information Disclosure | `mask_recipient/1` (one promoted definition); routing-trace "actual" recipient masked |
| Auth bypass by mounting in wrong live_session | Elevation | Mount in operator session (Auth gate), NOT dev-preview session (D-48-12); `available?/0` additional gate |
| Mutation (replay) without re-auth | Tampering | Capability gate via `Auth.authorize(:replay_inbound)`; adopter may require recent-auth (stale-auth path) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mailglass_inbound` v0.2.0 will exist on Hex by Phase 50.5 publish (the `"~> 0.2"` floating constraint) | Standard Stack | LOW — controlled by the same maintainer; floating constraint + path dep in dev means no runtime risk this phase. Verify the version bump lands before the Phase 50.5 publish. |
| A2 | Recommended `explain/2` clause-tuple shape (`{:recipient/:subject, expected, actual, pass?}` + `{:header, name, expected, actual, pass?}`) | Routing-Trace Reflection | LOW — CONTEXT D-48-06 explicitly leaves the exact shape to Claude's discretion; the constraint that matters (reuse `matches_matcher?/2`) is locked and met. Planner may pick a `Router.Trace` module instead. |
| A3 | Cleanest test-infra fix is pointing `:mailglass_inbound, :repo` at `MailglassAdmin.TestRepo` + migrating inbound tables into the admin DB | Pitfall 3 / Wave 0 | MEDIUM — alternative is a stubbed gateway, but real matcher/replay behavior is needed for V2/V3. If the two repos must stay separate DBs, the bootstrap needs a second repo start. Verify during Wave 0. |
| A4 | Recommendation to DISABLE the Replay button on `:no_match` (vs. allow-then-block) | Pitfall 1 | LOW — both behaviors are valid; the error→copy mapping is required either way. UX choice for the planner. |
| A5 | The suppression indicator is forward-compatible scaffolding that never renders until Phase 49 | Pitfall 2 | LOW — confirmed the field is absent; defensive read is mandatory regardless of UX choice. |

## Open Questions

1. **Should the routing-trace card show ALL declared routes, or only routes that "nearly" matched?**
   - What we know: UI-SPEC says "one bordered sub-card per route tried (in declared order)" — i.e. all
     routes from `__mailglass_inbound_routes__/0`.
   - What's unclear: with many routes this could be a long card. UI-SPEC does not cap it.
   - Recommendation: render all (UI-SPEC contract); revisit pagination only if a real adopter has >~10
     routes. Out of scope to optimize now.

2. **Does the inbound read-model need a separate "matched mailbox" lookup, or does it come from the
   latest `ExecutionRun`?**
   - What we know: `ExecutionRun.mailbox` carries the matched mailbox string; the latest fresh run's
     mailbox+outcome is the detail header's "matched mailbox + execution result."
   - What's unclear: whether to show the latest run or the latest *matched* run when a later replay
     changed the outcome.
   - Recommendation: detail header shows the canonical record + the latest fresh run's mailbox/outcome
     (mirrors `Replay.resolve_mailbox` which prefers the latest matched fresh run); the timeline shows
     ALL runs. Planner confirms during component design.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | ~> 1.18 | — |
| PostgreSQL | Inbound read-model + tests | ✓ (project standard) | — | — (tests need it) |
| `mailglass_inbound` (path dep, dev/test) | InboundLive | ✓ (sibling in repo) | 0.1.0 local | — |
| Node toolchain | NONE | N/A | — | Phase is zero-Node (UI-SPEC); `mix mailglass_admin.assets.build` only |

**Missing dependencies with no fallback:** None — all in-repo.
**Missing dependencies with fallback:** None.

## Project Constraints (from CLAUDE.md)

- **Telemetry never carries PII** (no `:to`/`:from`/`:body`/`:subject`/`:recipient`/`:email`). Any
  telemetry the LiveView emits must follow this; the live-update payload is already PII-free (id only).
- **Append-only `mailglass_inbound` tables** — replay APPENDS an `ExecutionRun`; never UPDATE/DELETE.
- **Optional deps gated through a single `*.OptionalDeps.*` module** with `Code.ensure_loaded?` +
  `available?/0` + `apply/3` + `@compile {:no_warn_undefined, ...}`. The `--no-optional-deps
  --warnings-as-errors` lane is mandatory.
- **`name: __MODULE__` singletons banned** in library code — the `:inbound_router` opt threads the
  router per-request, no global singleton (D-48-07 aligns).
- **Don't write `mailglass_admin/priv/static/` without committing the rebuilt bundle** (CI runs
  `git diff --exit-code`). Run `mix mailglass_admin.assets.build` if any class change pulls new
  utilities (UI-SPEC says zero new tokens — expect no diff, but verify).
- **Don't pattern-match errors by message string** — match the struct/tuple. Replay errors are
  structured tuples (`:not_found`, `{:replay_mailbox_missing, %{reason: ...}}`).
- **PubSub topics must be `mailglass:`-prefixed and built through the typed builder** (LINT-06).
- **Brand voice** in all error/empty copy (IADM-06; UI-SPEC Copywriting Contract is authoritative).
- **Validate Credo by running it** (`mix credo --strict` + `mix test test/mailglass/credo/`), not grep
  proofs — relevant if a tenant-scope Credo check is added (deferred this phase).

## Sources

### Primary (HIGH confidence — all read directly from source this session)
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` — `matches_route?/2` (l.31, public),
  `matches_matcher?/2` (l.45-48), `matches_headers?/2` (l.37) — the reflection reuse target
- `mailglass_inbound/lib/mailglass_inbound/router/route.ex` — 4-field Route struct (l.14)
- `mailglass_inbound/lib/mailglass_inbound/router.ex` — `__mailglass_inbound_routes__/0` (l.64-72)
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` — `replay/2` (l.13-28, NOT tenant-scoped;
  `resolve_mailbox/2` l.50-67 = the `:no_match` replay-blocked behavior)
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/{inbound_record,inbound_evidence,execution_run,replay_run}.ex`
  — schemas; `redact: true` on raw_payload/raw_mime; `ExecutionRun.__outcomes__/0`; both Run schemas
  map to `mailglass_inbound_replay_runs`; NO `suppression_flagged`/`metadata` field anywhere
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` — `headers :: %{name => [String.t()]}` (l.52)
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — broadcast site (l.519-528), PII-free payload
- `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex` — `inbound_record_inserted/1` string (l.33-34)
- `mailglass_inbound/lib/mailglass_inbound/repo.ex` — host-repo facade (all/2, one/3, get/3); raises if unset
- `mailglass_inbound/config/test.exs` + `test_helper.exs` + `mix.exs` — inbound test repo + migrations + deps
- `lib/mailglass/operator/deliveries.ex` — tenant-required + `Tenancy.scope/2` + projection (l.18-50)
- `lib/mailglass/tenancy.ex` — `scope/2` (l.270-273); grep-confirmed ZERO inbound usage
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — master/detail shell; `load_deliveries/1` (l.338)
- `mailglass_admin/lib/mailglass_admin/operator/{deliveries_list,timeline,replay_modal,destructive_action,mount}.ex`
  — clone targets; `mask_recipient/1` (deliveries_list.ex:98-121)
- `mailglass_admin/lib/mailglass_admin/auth.ex` — `authorize/3` `atom()` action type (l.33, 55)
- `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` — gateway pattern
- `lib/mailglass/optional_deps/gen_smtp.ex` — `available?/0` gateway shape
- `mailglass_admin/lib/mailglass_admin.ex` — Boundary decl (l.45-47, leave unchanged)
- `mailglass_admin/lib/mailglass_admin/router.ex` — operator macro (l.236-254); `@compile no_warn_undefined` (l.87)
- `mailglass_admin/mix.exs` — `deps/0`, `mailglass_dep/0` MIX_PUBLISH branch (l.126-132), elixirc_options (l.69-71)
- `.github/workflows/release-please.yml` — PINS array + sed pin (l.119-179); REL-05 exit-1 guard (l.157)
- `credo_checks/prefixed_pub_sub_topics.ex` — LINT-06 (only flags LITERAL topic strings)
- `mailglass_admin/test/{test_helper.exs,config/test.exs,support/live_view_case.ex,support/test_repo.ex,support/endpoint_case.ex}`
  — admin test bootstrap (migrates ONLY core repo); synthetic adopter router
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — LiveView test pattern to mirror
- `mailglass_inbound/lib/mailglass_inbound/fixtures.ex` — code-built fixtures (ship in lib/; default tenant_id)
- `.planning/REQUIREMENTS.md` — IADM-01..07 + IOPS-05 wording
- `.planning/phases/48-inbound-admin-liveview/{48-CONTEXT.md,48-UI-SPEC.md}` — locked decisions + approved contract

### Secondary / Tertiary
- None — every claim is sourced from in-repo files read this session. No WebSearch was needed; this is
  an internal-architecture phase with no external-library uncertainty.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new external packages; every reused library verified present in mix.exs.
- Architecture / locked decisions: HIGH — all 13 CONTEXT decisions independently re-verified against
  source with line numbers; the routing-trace reflection shape confirmed from the actual `defp` predicates.
- Pitfalls: HIGH — each pitfall confirmed by direct grep/read (replay-on-no_match from `resolve_mailbox`;
  suppression_flagged absence from zero-occurrence grep; test-infra gap from the admin test_helper; sed
  regex from the actual workflow; Boundary behavior from CONTEXT's traced analysis).
- Validation architecture: HIGH — invariants map directly to verified seams; commands match existing
  aliases (`verify.preview`) and the known inbound-suite flake mitigation (`--seed 0`).

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 (30 days — stable internal architecture; the only time-sensitivity is the
`mailglass_inbound` 0.2.0 version bump landing before Phase 50.5)
