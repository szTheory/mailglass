# Phase 12: Auto-Suppression + Soft-Bounce Escalation - Research

**Researched:** 2026-04-28 [VERIFIED: date(2026-04-28)]
**Domain:** Webhook-driven suppression projection, async soft-bounce escalation, and tenant-scoped suppression repair in mailglass [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
**Confidence:** HIGH for insertion seams, tenant/telemetry constraints, and existing code analogs; MEDIUM for the final worker/layout split because that is still planner discretion [VERIFIED: repo audit]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-12-01:** Auto-suppression uses a **mixed scope model** by event type, not a one-size-fits-all address block. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-02:** `:unsubscribed` projects to `scope: :address_stream` using the originating delivery's `stream`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-03:** `:complained` projects to `scope: :address`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-04:** hard `:bounced` projects to `scope: :address`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-05:** Domain-wide auto-suppression is explicitly out of scope for Phase 12. Domain scope remains available only for manual/operator policy rows. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-06:** mailglass should not mirror provider-specific unsubscribe group/category semantics. Normalize to mailglass stream semantics only. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-07:** Keep event taxonomy and suppression reasons as separate closed sets with an explicit translation layer:
  - `:complained -> :complaint`
  - `:unsubscribed -> :unsubscribe`
  - hard `:bounced -> :hard_bounce` [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-08:** The roadmap/requirements wording around `reason: :complained` is incorrect relative to the current schema and must be corrected during planning/implementation. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-09:** Auto-suppression logic must centralize this translation in one place. No scattered ad hoc mappings. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-10:** Count only `:deferred` events toward soft-bounce escalation. Do **not** reinterpret hard `:bounced` events as soft. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-11:** The default escalation policy remains `{count: 5, window_days: 7, action: :hard_suppress}`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-12:** Support only a **narrow** config escape hatch in v0.2:
  - `:hard_suppress`
  - `{:suppress_for, days: pos_integer()}` [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-13:** Do not add arbitrary callbacks, custom modules, or policy DSLs in this phase. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-14:** Soft-bounce escalation runs asynchronously via Oban only. No synchronous evaluation inside the webhook request cycle. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-15:** Escalation rows must be distinguishable from true hard-bounce rows via source and/or metadata so later removal policy can treat them differently without ambiguity. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-16:** `:complaint` suppressions are non-removable through the generic public API/operator tooling. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-17:** `:unsubscribe` suppressions are also non-removable through the generic public API/operator tooling. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-18:** `:hard_bounce`, soft-bounce escalation rows, `:manual`, and operator-authored `:policy` rows are removable. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-19:** Removal must be explicit and auditable. No silent delete paths. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-20:** A future fresh-consent or resubscribe flow is distinct from generic suppression removal and is out of scope for this phase. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-21:** `mix mailglass.suppressions.resync` requires `--tenant-id`. This is mandatory and non-negotiable. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-22:** The task should use concise default output, with optional `--dry-run` and `--verbose`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-23:** `--dry-run` must reuse the exact same candidate-selection path as apply mode and report `would_insert`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-24:** Do not add `--quiet` in this phase. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-25:** The task must stamp tenant context explicitly and scope all reads/writes through `Tenancy.scope/2`. Do not rely on ambient `Tenancy.current/0`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-26:** Default scan window remains last 90 days, with `--from` / `--to` ISO-8601 overrides. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-27:** Default to agent discretion for routine implementation choices in this phase. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-28:** Downstream agents should only escalate to the user when a decision would materially alter:
  - public API shape
  - compliance semantics
  - persistence invariants
  - tenant isolation guarantees
  - user-visible behavior that violates least surprise [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **D-12-29:** If multiple implementation approaches satisfy the locked decisions above, prefer the most idiomatic Elixir/Ecto/Phoenix approach with the smallest surface area and clearest operator UX. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

### Claude's Discretion
- Exact Oban worker naming, queue name, and internal module layout [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Exact telemetry metadata keys, as long as they remain whitelist-safe and non-PII [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- The precise storage shape used to mark soft-bounce escalation rows, as long as they remain distinguishable from true hard-bounce rows [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- The exact formatting of `mix mailglass.suppressions.resync` default and verbose output [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Whether the narrow soft-bounce config escape hatch lands as one config key or a small validated keyword subtree [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Fresh-consent / resubscribe workflow for previously unsubscribed recipients [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Provider-specific unsubscribe-group/category mirroring [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Domain-wide automatic suppressions [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Arbitrary suppression policy callbacks or a generalized rules DSL [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Richer support/admin UX for suppression management beyond concise Mix-task/operator flows [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- Project-wide GSD methodology codification of the "decisive by default, escalate only on high-impact surprises" preference if later desired outside this phase [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUPP-01 | Extend `Mailglass.Webhook.Ingest.ingest_multi/3` with `Multi.run {:auto_suppress, idx}` after each `{:projector_apply, idx}`; event row remains first; `on_conflict: :nothing`; trigger on `:bounced`, `:complained`, `:unsubscribed`. [VERIFIED: .planning/REQUIREMENTS.md:66] | Exact insertion point, replay constraints, reason translation, and event metadata gaps are documented below. [VERIFIED: lib/mailglass/webhook/ingest.ex:262][VERIFIED: lib/mailglass/suppression/entry.ex:35] |
| SUPP-02 | Add Oban-backed soft-bounce escalation on repeated `:deferred` events with default `{5, 7, :hard_suppress}`; no sync evaluation; optional-dep gate; covering index migration. [VERIFIED: .planning/REQUIREMENTS.md:67] | Existing Oban gateway, worker conventions, tenancy middleware, and reconciler-style public helper pattern are documented below. [VERIFIED: lib/mailglass/optional_deps/oban.ex:1][VERIFIED: lib/mailglass/webhook/reconciler.ex:55][CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| SUPP-03 | Add `mix mailglass.suppressions.resync` with required `--tenant-id`, tenant-scoped reads/writes, idempotency, 90-day default, and ISO-8601 overrides. [VERIFIED: .planning/REQUIREMENTS.md:68] | Existing Mix-task UX analogs, strict validation style, and tenancy rules are documented below. [VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:19][VERIFIED: lib/mix/tasks/mailglass.gen.unsubscribe.ex:15][VERIFIED: lib/mailglass/tenancy.ex:231] |
| SUPP-04 | Tighten `Mailglass.Suppression.check_before_send/1` to return structured suppression detail and emit `:auto_added` / `:pre_send_blocked` telemetry with whitelisted metadata. [VERIFIED: .planning/REQUIREMENTS.md:69] | Current preflight order, error surface, and telemetry constraints are documented below. [VERIFIED: lib/mailglass/outbound.ex:285][VERIFIED: lib/mailglass/suppression.ex:35][VERIFIED: test/mailglass/credo/no_pii_in_telemetry_meta_test.exs:9] |
| SUPP-05 | Make complaint suppressions permanent with DB enforcement and removal rejection. [VERIFIED: .planning/REQUIREMENTS.md:70] | Current schema reason set, missing `remove/2` surface, and DB-level invariant needs are documented below. [VERIFIED: lib/mailglass/suppression/entry.ex:37][VERIFIED: codebase grep: no public `Mailglass.Suppression.remove/2` currently exists] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep webhook ingest event-first and append-only; do not add any path that can create a suppression row without the corresponding durable event row. [VERIFIED: CLAUDE.md][VERIFIED: .planning/STATE.md]
- Do not put PII in telemetry or structured error context; address, subject, headers, bodies, and recipient email are all forbidden in telemetry metadata. [VERIFIED: CLAUDE.md][VERIFIED: test/mailglass/credo/no_pii_in_telemetry_meta_test.exs:9]
- Treat multi-tenancy as non-optional; every query and write in this phase must carry `tenant_id` and use `Mailglass.Tenancy.scope/2` or an explicit audited bypass. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/tenancy.ex:231][VERIFIED: test/mailglass/credo/no_unscoped_tenant_query_in_lib_test.exs:11]
- Optional dependencies must route through `Mailglass.OptionalDeps.*`; Phase 12 must not reference bare `Oban.*` outside the gateway or conditionally compiled worker modules. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/optional_deps/oban.ex:1]
- Errors remain a public API contract; any new pre-send suppression or removal error path must stay structured, not string-matched. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/error.ex][VERIFIED: lib/mailglass/errors/suppressed_error.ex]

## Summary

Phase 12 fits the existing architecture cleanly if planning treats it as an extension of three already-proven seams: the flat webhook `Ecto.Multi`, the Ecto-backed suppression store, and the Oban optional-dep pattern used for outbound/reconciliation workers. The exact webhook insertion point is after `{:projector_apply, idx}` in `Mailglass.Webhook.Ingest.update_projections_for_each/2`; adding auto-suppression earlier would violate the event-first invariant that Phase 4 and the roadmap both call out explicitly. [VERIFIED: lib/mailglass/webhook/ingest.ex:262][VERIFIED: .planning/REQUIREMENTS.md:66][VERIFIED: .planning/STATE.md]

The main planning risk is not the new `Multi.run` itself; it is data availability. Current normalized webhook events preserve provider identity and delivery lookup ids, but they do not preserve recipient email, and `:unsubscribed` needs the originating delivery stream for `:address_stream` scope. That means auto-suppression can be computed cheaply only when the event has a matched delivery or when Phase 12 expands provider metadata / join strategy enough to recover recipient+stream safely. The planner should treat that as Wave 0, not as a late test fix. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex:177][VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex:225][VERIFIED: lib/mailglass/webhook/ingest.ex:281][VERIFIED: lib/mailglass/outbound/delivery.ex:53][VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

The other hard edges are replay semantics and tenant isolation. `Mailglass.SuppressionStore.Ecto.record/2` upserts mutable fields on conflict, which is useful for manual/admin writes but wrong for webhook replay convergence; the roadmap is correct that auto-suppression should use `repo.insert(..., on_conflict: :nothing)` instead of `record/2`. Likewise, the future resync task cannot copy `mix mailglass.reconcile` exactly because Phase 12 forbids cross-tenant scans and requires `--tenant-id`; it can copy the strict parsing, concise shell output, and shared-code-path pattern. [VERIFIED: lib/mailglass/suppression_store/ecto.ex:97][VERIFIED: lib/mailglass/suppression_store.ex:21][VERIFIED: .planning/REQUIREMENTS.md:66][VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:19][VERIFIED: lib/mix/tasks/mailglass.gen.unsubscribe.ex:15]

**Primary recommendation:** Plan Phase 12 as six repo-scoped slices: metadata/read-model prep, `AutoSuppress` projection in webhook ingest, Oban `Escalation` worker, tenant-required `suppressions.resync` task, pre-send/detail+telemetry tightening, and permanence/removal invariants. [VERIFIED: .planning/ROADMAP.md:138][VERIFIED: repo seam audit]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook auto-suppression insert | API / Backend [VERIFIED: lib/mailglass/webhook/ingest.ex:178] | Database / Storage [VERIFIED: lib/mailglass/suppression/entry.ex:52] | The decision belongs in the existing ingest transaction; the DB enforces uniqueness and permanence invariants. [VERIFIED: lib/mailglass/webhook/ingest.ex:212][VERIFIED: lib/mailglass/suppression_store/ecto.ex:118] |
| Soft-bounce escalation | API / Backend [VERIFIED: .planning/REQUIREMENTS.md:67] | Database / Storage [VERIFIED: lib/mailglass/events/event.ex:90] | Counting `:deferred` events is application logic; durable inserts and query indexes live in Postgres. [VERIFIED: test/mailglass/webhook/providers/postmark_test.exs:195][VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex:266] |
| Background execution | API / Backend [VERIFIED: lib/mailglass/optional_deps/oban.ex:1] | Database / Storage [CITED: https://hexdocs.pm/oban/Oban.Worker.html] | Oban workers are the repo’s durable async pattern, and jobs are inserted transactionally through Oban/Ecto. [VERIFIED: lib/mailglass/outbound/worker.ex][VERIFIED: lib/mailglass/webhook/reconciler.ex:55] |
| Resync operator UX | API / Backend [VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:1] | Database / Storage [VERIFIED: lib/mailglass/tenancy.ex:231] | The Mix task is an operator entry point, but all candidate selection and writes are tenant-scoped DB operations. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] |
| Pre-send suppression enforcement | API / Backend [VERIFIED: lib/mailglass/outbound.ex:285] | Database / Storage [VERIFIED: lib/mailglass/suppression_store/ecto.ex:33] | Outbound preflight owns the deny/allow decision; suppression rows remain the source of truth. [VERIFIED: lib/mailglass/suppression.ex:35] |
| Complaint permanence | Database / Storage [VERIFIED: .planning/REQUIREMENTS.md:70] | API / Backend [VERIFIED: lib/mailglass/suppression/entry.ex:37] | The strongest guarantee is a DB constraint; API-level rejection is a second fence. [VERIFIED: .planning/ROADMAP.md:143] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto.Multi` | project uses `ecto ~> 3.13` [VERIFIED: mix.exs] | Extend the existing flat webhook transaction with one `Multi.run` per event. [VERIFIED: lib/mailglass/webhook/ingest.ex:262] | This repo already treats a single flat `Multi` as the load-bearing write model for webhook ingest and unsubscribe lifecycle work. [VERIFIED: lib/mailglass/webhook/ingest.ex:178][VERIFIED: lib/mailglass/compliance/unsubscribe_controller.ex:97] |
| `Mailglass.SuppressionStore.Ecto` | repo-local default store [VERIFIED: lib/mailglass/suppression.ex:67] | Read suppression state and define row semantics/invariants. [VERIFIED: lib/mailglass/suppression_store/ecto.ex:33] | It already encodes scope matching, expiry filtering, and unique conflict shape for suppressions. [VERIFIED: lib/mailglass/suppression_store/ecto.ex:36] |
| `Oban.Worker` | project declares `oban ~> 2.21` [VERIFIED: mix.exs][CITED: https://hexdocs.pm/oban/Oban.Worker.html] | Run soft-bounce escalation asynchronously with durable retries and unique job semantics. [VERIFIED: .planning/REQUIREMENTS.md:67] | Existing outbound and webhook workers already follow the repo’s conditional-compile and public-helper conventions. [VERIFIED: lib/mailglass/outbound/worker.ex][VERIFIED: lib/mailglass/webhook/reconciler.ex:55] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mailglass.OptionalDeps.Oban` | repo-local gateway [VERIFIED: lib/mailglass/optional_deps/oban.ex:1] | Gate all Oban interaction and preserve `--no-optional-deps` compilation. [VERIFIED: CLAUDE.md] | Use for enqueue paths and compile guards whenever Phase 12 touches background jobs. [VERIFIED: lib/mailglass/optional_deps/oban.ex:48] |
| `Mailglass.Oban.TenancyMiddleware` | repo-local conditional module [VERIFIED: lib/mailglass/optional_deps/oban.ex:87] | Serialize `mailglass_tenant_id` into job args and restore tenant scope in `perform/1`. [VERIFIED: lib/mailglass/optional_deps/oban.ex:134] | Use when the worker logic needs `Tenancy.current/0` rather than an explicit tenant arg threaded to every function. [VERIFIED: lib/mailglass/outbound/worker.ex:20] |
| `OptionParser` + `Mix.shell()` | stdlib [VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:45] | Match existing operator-task validation and output tone. [VERIFIED: lib/mix/tasks/mailglass.gen.unsubscribe.ex:28] | Use for `mix mailglass.suppressions.resync` CLI parsing, `--dry-run`, `--verbose`, and fail-loud UX. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct `repo.insert(..., on_conflict: :nothing)` for auto rows [VERIFIED: .planning/REQUIREMENTS.md:66] | `Mailglass.SuppressionStore.Ecto.record/2` [VERIFIED: lib/mailglass/suppression_store/ecto.ex:97] | `record/2` replaces `reason/source/expires_at/metadata` on conflict, which is good for manual re-adds but wrong for webhook replay convergence. [VERIFIED: lib/mailglass/suppression_store.ex:21] |
| Oban worker for escalation [VERIFIED: .planning/REQUIREMENTS.md:67] | Synchronous counting inside `ingest_multi/3` [VERIFIED: lib/mailglass/webhook/ingest.ex:141] | Sync counting adds query latency to the webhook request path and violates a locked phase decision. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] |
| Tenant-required resync task [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] | Global sweep with optional `--tenant-id` like `mix mailglass.reconcile` [VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:21] | Phase 12 explicitly forbids ambient/global operator repair because suppression data is tenant-sensitive. [VERIFIED: .planning/REQUIREMENTS.md:68] |

**Installation:** No new package is required beyond the existing optional `{:oban, "~> 2.21"}` dependency already declared in `mix.exs`. [VERIFIED: mix.exs]

**Version verification:** The current repo declares `ecto ~> 3.13` and optional `oban ~> 2.21`; current official Oban docs are published for v2.21.1. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/unique_jobs.html]

## Architecture Patterns

### System Architecture Diagram

```text
Verified webhook request
  -> Mailglass.Webhook.Plug
  -> Mailglass.Webhook.Provider.normalize/2
  -> Mailglass.Webhook.Ingest.build_multi/4
     -> Events.append_multi(:event_N)             # event row first
     -> {:projector_categorize, N}
        -> matched delivery? ---- no ---> orphan path only
        -> yes
     -> {:projector_apply, N}
     -> {:auto_suppress, N}                       # Phase 12 insertion point
        -> type=:complained? ---- yes ---> address suppression
        -> type=:unsubscribed? -- yes ---> address_stream suppression
        -> type=:bounced hard? --- yes ---> address suppression
        -> type=:deferred? ------- yes ---> enqueue escalation job only
     -> :flip_status
  -> post-commit telemetry + broadcasts

Deferred-event job
  -> Oban worker perform/1
  -> tenant restore
  -> query mailglass_events within sliding window
  -> threshold met?
     -> no  -> exit
     -> yes -> insert distinguishable suppression row

Operator repair
  -> mix mailglass.suppressions.resync --tenant-id ...
  -> same candidate-selection path as runtime projection
  -> dry-run counts OR insert missing rows
```
[VERIFIED: lib/mailglass/webhook/ingest.ex:178][VERIFIED: lib/mailglass/outbound/worker.ex][VERIFIED: lib/mailglass/webhook/reconciler.ex:79][VERIFIED: .planning/REQUIREMENTS.md:66]

### Recommended Project Structure

```text
lib/
├── mailglass/suppression/auto_suppress.ex        # event->suppression translation + insert helpers
├── mailglass/suppression/escalation.ex           # Oban worker + deferred-count helper
├── mailglass/webhook/ingest.ex                   # add Multi.run {:auto_suppress, idx}
├── mailglass/suppression.ex                      # tighten pre-send result + telemetry facade
└── mix/tasks/mailglass.suppressions.resync.ex    # tenant-required repair task

test/
├── mailglass/suppression/auto_suppress_test.exs
├── mailglass/suppression/escalation_test.exs
├── mix/tasks/mailglass.suppressions.resync_test.exs
└── mailglass/suppression_test.exs                # extend pre-send detail assertions
```
[ASSUMED]

### Pattern 1: Extend the Flat Webhook Multi, Don’t Fork It

**What:** Add one `Multi.run {:auto_suppress, idx}` step after `{:projector_apply, idx}` and before final status flip so suppression rows live in the same transaction as the event append. [VERIFIED: .planning/REQUIREMENTS.md:66][VERIFIED: lib/mailglass/webhook/ingest.ex:269]

**When to use:** Any event-driven suppression projection that depends on the just-inserted event row and may need matched-delivery context. [VERIFIED: lib/mailglass/webhook/ingest.ex:275]

**Example:**
```elixir
# Source: lib/mailglass/webhook/ingest.ex
multi
|> Events.append_multi(event_step_name(idx), fn _changes -> attrs end)
|> Multi.run({:projector_categorize, idx}, fn _repo, changes -> ... end)
|> Multi.run({:projector_apply, idx}, fn repo, changes -> ... end)
# Phase 12 seam:
|> Multi.run({:auto_suppress, idx}, fn repo, changes -> ... end)
```
[VERIFIED: lib/mailglass/webhook/ingest.ex:240][VERIFIED: lib/mailglass/webhook/ingest.ex:274]

### Pattern 2: Centralize Event->Reason Translation in One Helper

**What:** Keep `Event.type` and suppression `Entry.reason` as separate closed sets and translate through a single helper such as `suppression_attrs_for_event/2`. `:complained` must become `:complaint`; `:unsubscribed` must become `:unsubscribe`; hard `:bounced` must become `:hard_bounce`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md][VERIFIED: lib/mailglass/suppression/entry.ex:37]

**When to use:** Webhook projection, resync repair, and escalation insertion should all call the same translator to avoid atom drift. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

**Example:**
```elixir
# Source intent: Phase 12 context + current Entry reason set
case event.type do
  :complained -> %{reason: :complaint, scope: :address}
  :unsubscribed -> %{reason: :unsubscribe, scope: :address_stream}
  :bounced -> %{reason: :hard_bounce, scope: :address}
end
```
[VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md][VERIFIED: lib/mailglass/suppression/entry.ex:37]

### Pattern 3: Follow the Existing Oban Worker Convention Exactly

**What:** A Phase 12 escalation worker should mirror `Mailglass.Webhook.Reconciler` and `Mailglass.Outbound.Worker`: conditional compile under `if Code.ensure_loaded?(Oban.Worker)`, `use Oban.Worker` with explicit queue/unique options, a small `perform/1`, and a public helper that the Mix task or tests can call directly. [VERIFIED: lib/mailglass/webhook/reconciler.ex:1][VERIFIED: lib/mailglass/outbound/worker.ex:1][CITED: https://hexdocs.pm/oban/Oban.Worker.html]

**When to use:** Soft-bounce escalation and any repair path that needs the same query/insert logic without manually constructing Oban jobs. [VERIFIED: .planning/REQUIREMENTS.md:67]

**Example:**
```elixir
# Source: lib/mailglass/webhook/reconciler.ex
use Oban.Worker, queue: :mailglass_reconcile, unique: [period: 60]

@impl Oban.Worker
def perform(%Oban.Job{args: args}) do
  {:ok, _metrics} = reconcile(Map.get(args, "tenant_id"), Map.get(args, "limit", 1000))
  :ok
end
```
[VERIFIED: lib/mailglass/webhook/reconciler.ex:55][VERIFIED: lib/mailglass/webhook/reconciler.ex:79]

### Anti-Patterns to Avoid

- **Using `SuppressionStore.record/2` for webhook auto-inserts:** It upserts mutable fields on conflict and can silently rewrite replayed rows. Use direct insert with `on_conflict: :nothing` for runtime auto-projection. [VERIFIED: lib/mailglass/suppression_store/ecto.ex:118][VERIFIED: .planning/REQUIREMENTS.md:66]
- **Counting soft bounces in the webhook request path:** The ingest transaction already performs duplicate checks, event writes, projector work, and status flips; adding sliding-window counts there violates D-12-14 and creates a latency hotspot. [VERIFIED: lib/mailglass/webhook/ingest.ex:141][VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **Relying on ambient tenancy in resync or workers:** `Tenancy.current/0` can default; Phase 12 locked decisions require explicit tenant stamping and scoped queries. [VERIFIED: lib/mailglass/tenancy.ex:148][VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- **Leaking recipient addresses into telemetry for debugging:** This repo already has lint/test coverage against PII keys in telemetry metadata, and Phase 12 adds new suppression events that must stay on that whitelist. [VERIFIED: CLAUDE.md][VERIFIED: test/mailglass/credo/no_pii_in_telemetry_meta_test.exs:9]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Replay-safe runtime suppression dedupe | Custom SELECT-then-INSERT logic [VERIFIED: .planning/REQUIREMENTS.md:66] | `repo.insert(changeset, on_conflict: :nothing, conflict_target: ...)` inside the existing `Multi.run` [VERIFIED: lib/mailglass/webhook/ingest.ex:212] | The repo already relies on structural no-op semantics for webhook/event replay; adding an app-level race window would weaken that guarantee. [VERIFIED: test/mailglass/properties/webhook_idempotency_convergence_test.exs:15] |
| Async tenant restoration | Manual `Process.put/2` in every worker [VERIFIED: lib/mailglass/tenancy.ex:148] | `Mailglass.Oban.TenancyMiddleware.wrap_perform/2` or explicit `tenant_id` arg threading [VERIFIED: lib/mailglass/optional_deps/oban.ex:143] | The middleware already defines the supported cross-job contract and restores prior tenant state safely. [VERIFIED: lib/mailglass/optional_deps/oban.ex:134] |
| CLI parsing/output conventions | One-off task UX [VERIFIED: user scope] | Reuse the `OptionParser` + `Mix.raise`/`Mix.shell().info` style from existing Mix tasks [VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:44][VERIFIED: lib/mix/tasks/mailglass.gen.unsubscribe.ex:138] | The repo’s operator tasks are intentionally strict, concise, and fail-loud. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] |
| Telemetry spans for repair/background work | Raw `:telemetry.execute/3` everywhere [VERIFIED: lib/mailglass/suppression.ex:80] | Existing wrapper helpers and the webhook telemetry style [VERIFIED: lib/mailglass/webhook/reconciler.ex:110][VERIFIED: lib/mailglass/telemetry.ex:141] | The wrappers standardize start/stop/exception events and keep metadata small. [VERIFIED: CLAUDE.md] |

**Key insight:** The repo already contains the exact structural patterns this phase needs; Phase 12 should compose them, not invent parallel abstractions. [VERIFIED: repo seam audit]

## Common Pitfalls

### Pitfall 1: Planning Auto-Suppression Without Recipient/Stream Readback

**What goes wrong:** The planner assumes every normalized webhook event already contains enough data to write a suppression row. [VERIFIED: user scope]

**Why it happens:** Current provider normalizers only preserve provider ids and event kind in `Event.metadata`; they do not preserve recipient email, and unsubscribes need `delivery.stream` for `:address_stream`. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex:185][VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex:233]

**How to avoid:** Make Wave 0 decide whether Phase 12 reads address/stream from a matched `Delivery`, expands normalized metadata, or both; use the same strategy in runtime projection and resync. [VERIFIED: lib/mailglass/webhook/ingest.ex:291][VERIFIED: lib/mailglass/outbound/delivery.ex:53]

**Warning signs:** Planner slices mention only a new `Multi.run` and tests, but no new join/helper for address+stream recovery. [VERIFIED: repo audit]

### Pitfall 2: Reusing `SuppressionStore.record/2` for Replay-Driven Inserts

**What goes wrong:** Replayed webhooks overwrite `reason`, `source`, `expires_at`, or `metadata` on an existing suppression row instead of behaving as a structural no-op. [VERIFIED: lib/mailglass/suppression_store/ecto.ex:118]

**Why it happens:** `record/2` is intentionally an upsert API for manual/admin re-adds. [VERIFIED: lib/mailglass/suppression_store.ex:21]

**How to avoid:** Runtime auto-suppression should insert directly with conflict-ignore semantics; reserve `record/2` for operator/authored flows where replacement is desired. [VERIFIED: .planning/REQUIREMENTS.md:66]

**Warning signs:** Planner references `Mailglass.SuppressionStore.record/2` in SUPP-01 or SUPP-03. [VERIFIED: repo audit]

### Pitfall 3: Treating All `:bounced` Events as Hard Bounces

**What goes wrong:** Phase 12 suppresses every bounce immediately and breaks the soft-bounce policy. [VERIFIED: user scope]

**Why it happens:** The event taxonomy carries both `:bounced` and `:deferred`; Postmark TypeCode 2/32 and SendGrid `event=deferred` already map to `:deferred`, while hard bounce variants map separately. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex:209][VERIFIED: test/mailglass/webhook/providers/postmark_test.exs:195][VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex:266]

**How to avoid:** Key escalation only on `event.type == :deferred`; translate hard suppression only from hard `:bounced` events. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

**Warning signs:** Any helper branches on `reject_reason == :bounced` without checking `event.type`. [VERIFIED: repo audit]

### Pitfall 4: Building a Cross-Tenant Repair Tool by Accident

**What goes wrong:** `mix mailglass.suppressions.resync` scans all tenants or relies on process-default tenancy, creating a cross-tenant data leak path. [VERIFIED: .planning/REQUIREMENTS.md:68]

**Why it happens:** `mix mailglass.reconcile` currently allows a nil tenant and global sweep because orphan reconciliation is designed differently. [VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:21]

**How to avoid:** Make `--tenant-id` mandatory, validate it before app start, stamp it explicitly, and scope every query with `Tenancy.scope/2`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md][VERIFIED: lib/mailglass/tenancy.ex:231]

**Warning signs:** Planner uses `tenant_id \\ nil`, mentions “all tenants,” or copies `Mailglass.Webhook.Reconciler.reconcile/2` too literally. [VERIFIED: repo audit]

### Pitfall 5: Breaking Telemetry Whitelists While Improving Errors

**What goes wrong:** Phase 12 adds detailed suppression errors and then mirrors those same fields into telemetry metadata. [VERIFIED: user scope]

**Why it happens:** The current `Suppression.check_before_send/1` telemetry is intentionally small, while the roadmap asks for richer error detail. [VERIFIED: lib/mailglass/suppression.ex:45][VERIFIED: .planning/REQUIREMENTS.md:69]

**How to avoid:** Put detailed `reason/source/expires_at` in the returned error detail or row lookup result, not in emitted telemetry metadata. [VERIFIED: CLAUDE.md]

**Warning signs:** New events include `:address`, `:email`, `:recipient`, or copied `detail` maps in telemetry metadata. [VERIFIED: test/mailglass/credo/no_pii_in_telemetry_meta_test.exs:9]

## Code Examples

Verified patterns from official repo sources:

### Existing Flat-Multi Classify/Apply Shape

```elixir
# Source: lib/mailglass/webhook/ingest.ex
Multi.run(acc, {:projector_categorize, idx}, fn _repo, changes ->
  inserted_event = Map.get(changes, event_step_name(idx))

  cond do
    is_nil(inserted_event) -> {:ok, :no_event_row}
    is_nil(inserted_event.delivery_id) -> {:ok, :orphan_skipped}
    true -> {:ok, {:matched, delivery, inserted_event}}
  end
end)
|> Multi.run({:projector_apply, idx}, fn repo, changes ->
  ...
end)
```
[VERIFIED: lib/mailglass/webhook/ingest.ex:274]

### Existing Worker + Public Helper Convention

```elixir
# Source: lib/mailglass/webhook/reconciler.ex
use Oban.Worker, queue: :mailglass_reconcile, unique: [period: 60]

@impl Oban.Worker
def perform(%Oban.Job{args: args}) do
  {:ok, _metrics} = reconcile(Map.get(args, "tenant_id"), Map.get(args, "limit", @batch_limit))
  :ok
end

def reconcile(tenant_id \\ nil, limit \\ @batch_limit) do
  WebhookTelemetry.reconcile_span(%{tenant_id: tenant_id}, fn ->
    ...
  end)
end
```
[VERIFIED: lib/mailglass/webhook/reconciler.ex:55][VERIFIED: lib/mailglass/webhook/reconciler.ex:79]

### Existing Strict Mix-Task Output Style

```elixir
# Source: lib/mix/tasks/mailglass.reconcile.ex
{opts, _rest, _invalid} =
  OptionParser.parse(argv, strict: [tenant_id: :string, batch_size: :integer])

Mix.Task.run("app.start")

Mix.shell().info("Reconcile complete: scanned=#{scanned} linked=#{linked}")
```
[VERIFIED: lib/mix/tasks/mailglass.reconcile.ex:44]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual-only suppression rows via store APIs [VERIFIED: lib/mailglass/suppression_store.ex:21] | Planned runtime projection from webhook events plus repair tooling. [VERIFIED: .planning/ROADMAP.md:41][VERIFIED: .planning/ROADMAP.md:138] | Targeted for Phase 12. [VERIFIED: .planning/ROADMAP.md:125] | Planner must add event-driven writes without weakening replay guarantees. [VERIFIED: .planning/REQUIREMENTS.md:66] |
| Webhook ingest stops at event append + projector + status flip. [VERIFIED: lib/mailglass/webhook/ingest.ex:17] | Phase 12 adds suppression-related follow-on work inside the same event-first transaction. [VERIFIED: .planning/ROADMAP.md:138] | Planned now. [VERIFIED: .planning/STATE.md] | The new step belongs in `ingest.ex`, not in a separate post-commit pipeline. [VERIFIED: lib/mailglass/webhook/ingest.ex:269] |
| Background workers used for outbound delivery and orphan reconciliation only. [VERIFIED: lib/mailglass/outbound/worker.ex][VERIFIED: lib/mailglass/webhook/reconciler.ex] | Phase 12 extends the same pattern to deferred-event escalation. [VERIFIED: .planning/ROADMAP.md:140] | Planned now. [VERIFIED: .planning/ROADMAP.md:140] | Reuse queue/unique/tenancy patterns instead of inventing a new async abstraction. [VERIFIED: repo seam audit] |

**Deprecated/outdated:**
- Roadmap/requirements references to suppression reason `:complained` are stale relative to the actual `Mailglass.Suppression.Entry` enum, which already uses `:complaint`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md][VERIFIED: .planning/REQUIREMENTS.md:70][VERIFIED: lib/mailglass/suppression/entry.ex:37]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Splitting Phase 12 helpers into `lib/mailglass/suppression/auto_suppress.ex` and `lib/mailglass/suppression/escalation.ex` is the cleanest fit for repo layout. [ASSUMED] | Architecture Patterns | Low; the planner can relocate modules without changing behavior, but plan/task naming may need adjustment. |
| A2 | A dedicated `test/mix/tasks/mailglass.suppressions.resync_test.exs` file is preferable to folding all task assertions into another Mix-task test file. [ASSUMED] | Recommended Project Structure | Low; only affects test organization. |

## Open Questions

1. **How should orphan complaint/unsubscribe events recover recipient address and stream for suppression projection?**
   What we know: current provider normalizers persist provider ids and event kind, but not recipient email; `:unsubscribed` specifically needs `delivery.stream`. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex:185][VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex:233][VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
   What's unclear: whether runtime projection should depend only on matched deliveries, expand normalized metadata, or defer orphan suppression until reconciliation/resync. [VERIFIED: lib/mailglass/webhook/ingest.ex:281]
   Recommendation: resolve this in Wave 0 because it changes both runtime insertion logic and resync parity. [VERIFIED: repo seam audit]

2. **Does Phase 12 need to create a new public/manual removal API surface?**
   What we know: roadmap/requirements reference `Mailglass.Suppression.remove/2`, but the current repo does not expose that function. [VERIFIED: .planning/REQUIREMENTS.md:70][VERIFIED: codebase grep: no public `Mailglass.Suppression.remove/2` currently exists]
   What's unclear: whether the planner should include a public API addition now or scope removal rejection only through lower-level/operator paths this phase. [VERIFIED: user scope]
   Recommendation: treat this as a concrete plan item, not a footnote, because it affects public API shape and test coverage. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All Phase 12 tests/tasks [VERIFIED: environment probe] | ✓ [VERIFIED: environment probe] | 1.19.5 [VERIFIED: environment probe] | — |
| `elixir` / OTP | All library code and tests [VERIFIED: environment probe] | ✓ [VERIFIED: environment probe] | Elixir 1.19.5 / OTP 28 [VERIFIED: environment probe] | — |
| Optional `oban` dependency | SUPP-02 runtime worker path [VERIFIED: .planning/REQUIREMENTS.md:67] | Declared in repo [VERIFIED: mix.exs] | `~> 2.21` declared; official docs current at v2.21.1 [VERIFIED: mix.exs][CITED: https://hexdocs.pm/oban/Oban.Worker.html] | Runtime without Oban must remain compile-safe; background escalation itself has no non-Oban fallback because D-12-14 forbids synchronous evaluation. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] |

**Missing dependencies with no fallback:**
- None for planning. Runtime async escalation still depends on adopters actually including/configuring Oban. [VERIFIED: lib/mailglass/optional_deps/oban.ex:45][VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]

**Missing dependencies with fallback:**
- None inside the repo for planning; the only fallback pattern already in place is compile-safe optional-dep gating, not an alternate execution path for SUPP-02. [VERIFIED: lib/mailglass/optional_deps/oban.ex:51]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + ExUnitProperties [VERIFIED: test/mailglass/properties/webhook_idempotency_convergence_test.exs:37] |
| Config file | `test/test_helper.exs` and project `mix test` aliases; no standalone `pytest`-style config file. [VERIFIED: repo audit] |
| Quick run command | `mix test test/mailglass/suppression_test.exs test/mailglass/webhook/ingest_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors` [VERIFIED: repo structure] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUPP-01 | Webhook replay-safe auto-suppression after projector step | integration + property | `mix test test/mailglass/suppression/auto_suppress_test.exs test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` | ❌ Wave 0 |
| SUPP-02 | Async soft-bounce escalation on repeated `:deferred` events | worker/integration | `mix test test/mailglass/suppression/escalation_test.exs --warnings-as-errors` | ❌ Wave 0 |
| SUPP-03 | Tenant-required resync task with dry-run/apply parity | mix-task/integration | `mix test test/mix/tasks/mailglass.suppressions.resync_test.exs --warnings-as-errors` | ❌ Wave 0 |
| SUPP-04 | Pre-send structured suppression detail + whitelist-safe telemetry | unit/integration | `mix test test/mailglass/suppression_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ existing analogs, needs expansion |
| SUPP-05 | Complaint permanence + removal rejection | unit/integration | `mix test test/mailglass/suppression/entry_test.exs test/mailglass/suppression_test.exs --warnings-as-errors` | ✅ existing analogs, needs expansion |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/suppression_test.exs test/mailglass/webhook/ingest_test.exs --warnings-as-errors` [VERIFIED: repo structure]
- **Per wave merge:** `mix test test/mailglass/webhook test/mailglass/suppression* test/mix/tasks --warnings-as-errors` [VERIFIED: repo structure]
- **Phase gate:** `mix test --warnings-as-errors` plus a replay/property pass for webhook convergence before `/gsd-verify-work`. [VERIFIED: test/mailglass/properties/webhook_idempotency_convergence_test.exs:94]

### Wave 0 Gaps

- [ ] `test/mailglass/suppression/auto_suppress_test.exs` — exact `Multi.run {:auto_suppress, idx}` ordering, mapping, and conflict-no-op coverage for SUPP-01. [VERIFIED: .planning/REQUIREMENTS.md:66]
- [ ] `test/mailglass/suppression/escalation_test.exs` — deferred-count threshold, unique job behavior, tenant restoration, and distinguishable metadata for SUPP-02. [VERIFIED: .planning/REQUIREMENTS.md:67]
- [ ] `test/mix/tasks/mailglass.suppressions.resync_test.exs` — `--tenant-id` required, `--dry-run` parity, `--verbose` formatting, and ISO-8601 parsing for SUPP-03. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md]
- [ ] Existing webhook provider fixtures/tests need new assertions for the metadata fields Phase 12 will rely on, or the planner must explicitly add those fields first. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex:185][VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex:233]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | — |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | yes [VERIFIED: .planning/REQUIREMENTS.md:68] | `Mailglass.Tenancy.scope/2` on every read/write plus required `--tenant-id` for operator repair. [VERIFIED: lib/mailglass/tenancy.ex:231] |
| V5 Input Validation | yes [VERIFIED: phase scope] | `Ecto.Changeset` enum validation for suppression rows and strict `OptionParser`/`Mix.raise` CLI validation for resync. [VERIFIED: lib/mailglass/suppression/entry.ex:80][VERIFIED: lib/mix/tasks/mailglass.gen.unsubscribe.ex:138] |
| V6 Cryptography | no direct new cryptography in this phase [VERIFIED: phase scope] | Reuse existing Oban/Postgres, not custom crypto. [VERIFIED: repo audit] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant suppression repair inserts | Information Disclosure / Tampering | Require `--tenant-id`, stamp it explicitly, and scope all queries with `Tenancy.scope/2`. [VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md][VERIFIED: lib/mailglass/tenancy.ex:231] |
| Replay of complaint/bounce webhooks mutates prior suppression rows | Tampering | Use conflict-ignore runtime insert semantics instead of upsert semantics. [VERIFIED: lib/mailglass/suppression_store/ecto.ex:118][VERIFIED: .planning/REQUIREMENTS.md:66] |
| Telemetry/log leakage of recipient email during suppression debugging | Information Disclosure | Keep suppression detail out of telemetry metadata; rely on the existing PII telemetry guardrails and tests. [VERIFIED: CLAUDE.md][VERIFIED: test/mailglass/credo/no_pii_in_telemetry_meta_test.exs:9] |
| Synchronous deferred counting under webhook bursts | Denial of Service | Keep escalation asynchronous in Oban and preserve the existing bounded ingest transaction. [VERIFIED: lib/mailglass/webhook/ingest.ex:145][VERIFIED: .planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md` - locked decisions, discretion, and deferred scope. [VERIFIED: repo read]
- `.planning/ROADMAP.md` - Phase 12 goal, plan list, and success framing. [VERIFIED: repo read]
- `.planning/REQUIREMENTS.md` - `SUPP-01` through `SUPP-05`. [VERIFIED: repo read]
- `.planning/STATE.md` - Phase 12 correction notes, especially event-first Multi ordering and soft-bounce mapping concern. [VERIFIED: repo read]
- `lib/mailglass/webhook/ingest.ex` - exact insertion seam and transaction shape. [VERIFIED: repo read]
- `lib/mailglass/webhook/providers/postmark.ex` and `lib/mailglass/webhook/providers/sendgrid.ex` - current normalized event payload shape and deferred/bounce mapping. [VERIFIED: repo read]
- `lib/mailglass/suppression.ex`, `lib/mailglass/suppression/entry.ex`, `lib/mailglass/suppression_store/ecto.ex` - pre-send facade, reason enum, and conflict semantics. [VERIFIED: repo read]
- `lib/mailglass/optional_deps/oban.ex`, `lib/mailglass/webhook/reconciler.ex`, `lib/mailglass/outbound/worker.ex` - async worker conventions and optional-dep gate. [VERIFIED: repo read]
- `lib/mix/tasks/mailglass.reconcile.ex`, `lib/mix/tasks/mailglass.gen.unsubscribe.ex` - operator UX analogs. [VERIFIED: repo read]
- `test/mailglass/webhook/ingest_test.exs`, `test/mailglass/webhook/reconciler_test.exs`, `test/mailglass/suppression_test.exs`, `test/mailglass/suppression_store/ecto_test.exs`, `test/mailglass/properties/webhook_idempotency_convergence_test.exs` - concrete test analogs. [VERIFIED: repo read]

### Secondary (MEDIUM confidence)
- `https://hexdocs.pm/oban/Oban.Worker.html` - official worker defaults, `perform/1` contract, and args string-key behavior. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- `https://hexdocs.pm/oban/unique_jobs.html` - official uniqueness semantics and the recommendation to specify `period`. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

### Tertiary (LOW confidence)
- None. All substantive planning claims above were verified against repo code/docs or cited from official Oban docs. [VERIFIED: research audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 12 stays on existing repo primitives; only Oban behavior details needed external confirmation. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- Architecture: HIGH - The repo exposes the exact transaction, worker, and task seams the phase must extend. [VERIFIED: lib/mailglass/webhook/ingest.ex][VERIFIED: lib/mailglass/webhook/reconciler.ex][VERIFIED: lib/mix/tasks/mailglass.reconcile.ex]
- Pitfalls: HIGH - Risks are directly visible in current code and locked decisions, especially metadata gaps, upsert-vs-no-op semantics, and tenant-scoping constraints. [VERIFIED: repo seam audit]

**Research date:** 2026-04-28 [VERIFIED: date(2026-04-28)]
**Valid until:** 2026-05-28 for repo seams; re-check Oban docs if queue/unique behavior becomes a design hinge. [VERIFIED: repo seam stability][CITED: https://hexdocs.pm/oban/Oban.Worker.html]
