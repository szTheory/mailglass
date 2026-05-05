# Phase 32: Replay & Reconcile Hardening - Research

**Researched:** 2026-05-05
**Domain:** Phoenix LiveView operator actions, tenant-safe webhook replay, and background reconciliation hardening
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Recent authorization policy
- **D-32-01:** Keep recent-auth enforcement adopter-owned and action-time enforced through the existing `MailglassAdmin.Auth.authorize/2` `:destructive_action` seam. Do not move freshness enforcement to mount time, modal-open time, or router-only checks.
- **D-32-02:** Replay and any new manual repair action introduced in this phase must follow one server-side sequence: resolve the exact tenant-safe target, call `:destructive_action` authorization with full context, then execute the command.
- **D-32-03:** Do not introduce new public action atoms such as `:replay_webhook` or `:reconcile_delivery` in Phase 32. The current seam is sufficient and keeps the public auth contract small.
- **D-32-04:** Document a 15-minute recent-auth example window for adopters, but keep the actual threshold adopter-configurable through their auth implementation.
- **D-32-05:** Auth-denied or stale-auth attempts should fail before replay/reconcile work begins. Do not emit replay requested/failed audit rows for authorization denials unless a later phase intentionally introduces a separate denied-attempt audit semantic.

### Reconcile surface and operator entrypoints
- **D-32-06:** Keep replay as the only operator-facing manual repair action in the current delivery-detail UI.
- **D-32-07:** Do not add a per-delivery `Reconcile` CTA beside `Replay webhook` in Phase 32. Current reconciliation semantics are orphan-scan based, not exact selected-delivery based, and a delivery-level button would imply false precision.
- **D-32-08:** Reconciliation remains background-first and maintenance-oriented in this phase: Oban cron where available, with a CLI/maintenance fallback.
- **D-32-09:** If a future manual reconcile action becomes necessary, it should live in a separate tenant-scoped maintenance surface, not in the current delivery header and not with a global/nil-tenant default.
- **D-32-10:** Phase 32 should harden and clarify the existing manual reconcile fallback surface rather than broaden it into a new operator workflow product.

### Ambiguity and exact-target handling
- **D-32-11:** Never guess across multiple replayable raw webhook rows. Ambiguity is a precondition state, not a failure state.
- **D-32-12:** Keep the operator-visible availability model separate from command outcomes:
  - `:ready`
  - `:choice_required`
  - `:unavailable`
- **D-32-13:** Replay remains exact-target only. A delivery can be a convenience entrypoint, but execution still requires one concrete webhook identity.
- **D-32-14:** Reconcile must not gain pseudo-exact delivery semantics unless a later phase introduces a true delivery-to-orphan target identity with clear tenant-safe guarantees.
- **D-32-15:** Reason-specific unavailable states should stay explicit and low-claiming, for example historical linkage gaps, multiple candidates, or no linked webhook events yet.

### Operator outcome language and audit semantics
- **D-32-16:** Standardize operator-facing repair language around two layers:
  - availability: `ready`, `choice required`, `unavailable`
  - action outcome: `requested`, `completed`, `failed`
- **D-32-17:** Completed repair actions must separately express material effect:
  - replay: `new work` or `no change`
  - reconcile: `linked` or `still unmatched`
- **D-32-18:** Prefer `completed` over `succeeded` in operator copy. `Succeeded` overclaims when replay is a no-op.
- **D-32-19:** Operator copy must describe what mailglass observed, not what the operator hoped happened. Avoid verbs like `fixed`, `restored`, or `reprocessed successfully` when the durable result could be a no-op.
- **D-32-20:** Raw ledger event atoms such as `:webhook_replay_succeeded` remain internal audit facts. The UI should render stable presenter-level wording rather than exposing those atoms directly.
- **D-32-21:** Replay/reconcile audit events must remain visually distinct from provider lifecycle events in timelines and summaries.

### Recommendation-first project posture for this phase
- **D-32-22:** Downstream agents should research broadly, synthesize one cohesive recommendation set, and avoid escalating routine tradeoffs back to the user.
- **D-32-23:** Escalate only when a decision would materially change:
  - public auth/router/session contract
  - tenant trust boundaries
  - replay/reconcile audit retention semantics
  - operator-visible safety semantics in a surprising way
  - long-term maintainer burden through new repair modes or new maintenance surfaces
- **D-32-24:** This recommendation-first posture should be applied earlier, not later, in Phase 32 research and planning. Default to coherent recommendations unless the choice is genuinely high-impact.

### the agent's Discretion
- Exact internal presenter module names for repair-state copy and mapping.
- Exact wording for availability and effect labels, as long as the semantics above remain intact.
- Exact helper/facade placement for the shared destructive-action authorization sequence.
- Exact docs/test locations used to clarify the reconcile fallback path and stale-auth expectations.

### Deferred Ideas (OUT OF SCOPE)
- A tenant-scoped maintenance UI for manual reconciliation or orphan sweeps.
- Global or cross-tenant human-triggered reconcile surfaces.
- New public auth action atoms for each operator repair action.
- Bulk replay, time-window replay, or generalized backfill/rebuild workflows.
- Library-owned reauthentication UI/redirect flows.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- `mailglass` is Phoenix-first, Postgres-only, multi-tenant-first, and uses an append-only `mailglass_events` ledger; Phase 32 should preserve those invariants rather than introduce side channels or mutable repair state. [VERIFIED: CLAUDE.md]
- Destructive operator actions should continue to rely on adopter-owned auth and server-side enforcement; the repo already treats auth/session behavior as app-owned contract, not library-owned product surface. [VERIFIED: CLAUDE.md]
- Telemetry and audit surfaces must stay PII-free; this matters directly for replay/reconcile outcomes, failure metadata, and any new docs/examples added in this phase. [VERIFIED: CLAUDE.md]
- Optional dependencies must remain gated cleanly; Oban-backed behavior cannot become a hard compile/runtime requirement for the core library. [VERIFIED: CLAUDE.md]
- Public surfaces should stay narrow and unsurprising; Phase 32 should harden existing seams, not broaden into a new maintenance console or auth API. [VERIFIED: CLAUDE.md]
- Library code must not hand-roll global singletons or hidden runtime state; reconcile hardening should keep using explicit functions, optional-dep checks, and durable database facts. [VERIFIED: CLAUDE.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAT-01 | Operator can replay or reconcile webhook-driven delivery state with explicit tenant-safe authorization, auditable outcomes, and clear failure handling. | Use the existing `resolve target -> authorize(:destructive_action) -> execute` replay path, preserve exact-target replay semantics, keep reconcile background/CLI scoped, unify operator wording through presenter mapping, and add tests for stale-auth/no-audit, no-guess ambiguity, append-only reconcile, and the current Oban-less reconcile fallback mismatch. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
</phase_requirements>

## Summary

Phase 32 should be planned as a hardening phase on top of existing seams, not as a new workflow product. The repo already has the core mechanics needed: mount-time operator access auth, action-time `:destructive_action` auth for replay, exact-target replay target resolution, append-only replay audit facts, a replay history read model, and a background reconcile worker plus mix task entrypoint. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

The main planning work is to make those seams consistent and low-surprise. The biggest concrete repo-level risk is a contract mismatch around reconcile fallback: app warnings and docs tell adopters to run `mix mailglass.reconcile` without Oban, but the current task exits non-zero when Oban is absent because the worker stub only exposes `available?/0 == false`. That mismatch should be treated as first-class Phase 32 scope because it directly affects the promised operator recovery path. [VERIFIED: codebase grep]

Replay UX also needs a presenter layer rather than more core replay semantics. Current domain data already distinguishes exact, ambiguous, and unavailable target states, and replay results already distinguish `:replayed` from `:noop`; the remaining gap is operator wording that cleanly separates availability, action outcome, and material effect without exposing raw audit atoms or overclaiming with words like `succeeded`. [VERIFIED: codebase grep]

**Primary recommendation:** Keep the existing replay and reconcile architecture, add one shared repair-state presenter/auth-sequence helper, fix the Oban-less reconcile fallback contract, and expand tests around auth denial, ambiguity, wording, and reconcile maintenance behavior. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Operator page access auth | Frontend Server (LiveView) | Adopter Auth Module | Page access is enforced through `on_mount`, matching LiveView guidance for per-view authorization. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Replay target resolution | API / Backend | Database / Storage | Exact target lookup is a tenant-scoped read model over deliveries, events, and raw webhook rows; it should stay server-owned and database-backed. [VERIFIED: codebase grep] |
| Destructive replay authorization | Frontend Server (LiveView) | Adopter Auth Module | Sensitive action authorization belongs in `handle_event` before command execution, not in hidden UI state or client-side affordances. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Replay execution and audit writes | API / Backend | Database / Storage | `Mailglass.Webhook.Replay.execute/1` performs target fetch, normalized replay, projection updates, and append-only audit writes inside the core service layer. [VERIFIED: codebase grep] |
| Reconcile sweep scheduling | API / Backend | Optional Worker Runtime | Reconcile is a maintenance job driven by Oban when present and by a CLI/scheduler fallback otherwise. [VERIFIED: codebase grep] |
| Operator wording and timeline presentation | Frontend Server (LiveView) | API / Backend | The core services emit durable facts; the LiveView/admin layer should map them into stable operator vocabulary. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | `1.1.30` stable; `1.2.0-rc.2` prerelease also exists. [VERIFIED: hex.pm API, 2026-05-05] | Operator page mount auth and action-time replay authorization. [VERIFIED: codebase grep] | The official security model explicitly expects auth on `mount` and authorization again in `handle_event`, which matches this phase's locked action-time auth posture. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Phoenix | `1.8.6`. [VERIFIED: hex.pm API, 2026-05-05] | Router/live session boundaries and session-backed LiveView entrypoints. [VERIFIED: codebase grep] | The operator/admin surface already lives on Phoenix router macros and LiveView sessions; no new framework layer is needed. [VERIFIED: codebase grep] |
| Ecto | `3.13.6`. [VERIFIED: hex.pm API, 2026-05-05] | Tenant-scoped replay/reconcile queries and append-only transaction composition. [VERIFIED: codebase grep] | Replay and reconcile are already implemented as query-first, transaction-safe service functions over Ecto and should stay there. [VERIFIED: codebase grep] |
| Ecto SQL | `3.13.5`. [VERIFIED: hex.pm API, 2026-05-05] | Database transaction orchestration and migration-backed append-only guarantees. [VERIFIED: codebase grep] | This phase depends on preserving SQL-backed audit semantics rather than replacing them with in-memory or UI-only state. [VERIFIED: codebase grep] |
| Oban | `2.22.1` latest; repo currently locks `2.21.1`. [VERIFIED: hex.pm API, 2026-05-05] [VERIFIED: codebase grep] | Background reconcile cron where adopters include Oban. [VERIFIED: codebase grep] | Oban remains the standard background path, but its unique jobs feature only controls insertion-time duplication and does not guarantee single execution by itself. [CITED: https://hexdocs.pm/oban/unique_jobs.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Plug | `1.19.1` latest; repo currently targets `~> 1.18`. [VERIFIED: hex.pm API, 2026-05-05] [VERIFIED: codebase grep] | Session, browser pipeline, and LiveView connection setup for operator actions. [VERIFIED: codebase grep] | Use existing Plug/Phoenix session flow; do not invent separate replay-session state. [VERIFIED: codebase grep] |
| Swoosh | `1.25.1` latest; repo currently targets `~> 1.25`. [VERIFIED: hex.pm API, 2026-05-05] [VERIFIED: codebase grep] | Upstream outbound email layer beneath delivery state. [VERIFIED: codebase grep] | Relevant only as context; Phase 32 should not move replay/reconcile into transport-layer abstractions. [VERIFIED: codebase grep] |
| ExUnit + Phoenix.LiveViewTest | Bundled with Elixir / provided by current Phoenix stack. [VERIFIED: codebase grep] | Regression coverage for operator flows, replay service behavior, and reconcile maintenance semantics. [VERIFIED: codebase grep] | Existing replay/reconcile and LiveView tests already lock the highest-value behavior and should be extended, not replaced. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `:destructive_action` auth seam | New public atoms like `:replay_webhook` or `:reconcile_delivery` | Rejected by locked decision; it widens the public auth contract without adding meaningful safety for this phase. [VERIFIED: codebase grep] |
| Background/CLI reconcile only | Per-delivery reconcile CTA | Rejected by locked decision; current reconcile works on orphan scans, not exact selected-delivery identity, so a button would imply false precision. [VERIFIED: codebase grep] |
| Exact replay target resolution | Heuristic or batch replay selection | Rejected by locked decision and inconsistent with GitHub/Stripe-style explicit redelivery models. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB] |

**Installation:**
```bash
mix deps.get
```

No new dependency additions are recommended for Phase 32; the required stack is already present in `mix.exs`, `mailglass_admin/mix.exs`, and `mix.lock`. [VERIFIED: codebase grep]

**Version verification:** The repo currently uses Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Oban `2.21.1`, Plug `1.19.1`, and Swoosh `1.25.0` in `mix.lock`, while current registry releases on 2026-05-05 are Phoenix `1.8.6`, Phoenix LiveView stable `1.1.30` (`1.2.0-rc.2` prerelease), Oban `2.22.1`, Ecto `3.13.6`, Ecto SQL `3.13.5`, Plug `1.19.1`, and Swoosh `1.25.1`. [VERIFIED: codebase grep] [VERIFIED: hex.pm API, 2026-05-05]

## Architecture Patterns

### System Architecture Diagram

```text
Operator selects delivery in LiveView
  ->
Tenant-scoped read models load:
  deliveries + timeline + replay_targets + replay_history
  ->
If replay opened:
  replay_targets classify delivery as exact | ambiguous | unavailable
  ->
If exact target chosen:
  LiveView handle_event("confirm_replay")
  ->
  MailglassAdmin.Auth.authorize(:destructive_action, %{actor, delivery, replay_target})
    -> denied/stale_auth => stop with no replay audit rows
    -> authorized => continue
  ->
  Mailglass.Webhook.Replay.execute(%{tenant_id, delivery_id, webhook_event_id, actor})
    ->
    fetch raw webhook row tenant-safely
    -> append :webhook_replay_requested
    -> normalize raw payload
    -> append provider lifecycle events idempotently
    -> update projections / suppression side effects
    -> append :webhook_replay_succeeded or :webhook_replay_failed
  ->
Refresh replay_history + timeline
  ->
Presenter maps durable facts to operator wording

Background reconcile path
  ->
Oban cron (if present) OR maintenance CLI
  ->
Mailglass.Webhook.Reconciler.reconcile(tenant_id, limit)
  ->
find orphan events
  -> match delivery by provider + provider_message_id
  -> append :reconciled audit event
  -> update delivery projection
  -> emit telemetry / maintenance outcome
```
[VERIFIED: codebase grep]

### Recommended Project Structure

```text
mailglass_admin/lib/mailglass_admin/operator/
├── mount.ex            # mount-time operator access auth
├── replay_modal.ex     # repair intent UI and exact-target choice flow
├── detail_header.ex    # presenter-level repair availability/effect wording
└── timeline.ex         # operator timeline rendering, audit/event distinction

lib/mailglass/operator/
├── replay_targets.ex   # delivery -> exact/ambiguous/unavailable target resolution
├── replay_history.ex   # durable replay audit read model
└── timeline.ex         # delivery timeline read model

lib/mailglass/webhook/
├── replay.ex           # canonical replay command + audit writes
└── reconciler.ex       # maintenance reconcile worker / fallback seam
```
[VERIFIED: codebase grep]

### Pattern 1: Resolve, Authorize, Execute

**What:** One server-side sequence for manual repair actions: resolve the exact tenant-safe target, authorize `:destructive_action` with full context, then execute the command. [VERIFIED: codebase grep]

**When to use:** Any operator-triggered replay or future destructive maintenance action that acts on delivery/webhook state. [VERIFIED: 32-CONTEXT.md]

**Example:**
```elixir
# Source: local repo pattern in mailglass_admin/lib/mailglass_admin/operator_live.ex
with {:ok, target} <- selected_replay_target(replay_targets, selected_target_id),
     {:ok, socket} <- authorize_replay(socket, delivery, target),
     {:ok, result} <- Replay.execute(%{
       tenant_id: delivery.tenant_id,
       delivery_id: delivery.id,
       webhook_event_id: target.webhook_event_id,
       actor: socket.assigns.operator_actor
     }) do
  {:noreply, refresh_assigns(socket, result)}
end
```
[VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

### Pattern 2: Domain Facts First, Presenter Copy Second

**What:** Keep core replay/reconcile services emitting durable facts (`:exact`, `:ambiguous`, `:unavailable`, `:replayed`, `:noop`, audit event atoms), then map those facts into operator-safe copy in one presenter layer. [VERIFIED: codebase grep]

**When to use:** Any header, modal, timeline, or flash copy that describes repair availability, outcome, or effect. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: recommended Phase 32 presenter pattern
availability_label =
  case replay_targets.status do
    :exact -> "ready"
    :ambiguous -> "choice required"
    :unavailable -> "unavailable"
  end
```
[VERIFIED: codebase grep]

### Pattern 3: One Canonical Reconcile Function, Multiple Entry Paths

**What:** Keep reconcile semantics in one application function and let worker/CLI entrypoints call that same function rather than split maintenance behavior across duplicated code paths. [VERIFIED: codebase grep]

**When to use:** Oban cron execution, manual maintenance CLI, and future internal maintenance automation. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: local repo pattern in lib/mailglass/webhook/reconciler.ex
def perform(%Oban.Job{args: args}) do
  {:ok, _metrics} = reconcile(Map.get(args, "tenant_id"), Map.get(args, "limit", 1000))
  :ok
end
```
[VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Authorize on modal open or mount only:** LiveView docs require server-side authorization for actions, and this phase explicitly locks recent-auth to action time. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] [VERIFIED: 32-CONTEXT.md]
- **Guess across multiple raw webhook rows:** Current `ReplayTargets` already classifies multiple matches as ambiguity; converting that into implicit selection would violate the phase boundary. [VERIFIED: codebase grep]
- **Treat raw audit atoms as final UI copy:** Current `:webhook_replay_succeeded` is a ledger fact, not an operator-facing claim about effect. [VERIFIED: 32-CONTEXT.md] [VERIFIED: codebase grep]
- **Use Oban uniqueness as concurrency control:** Oban documents that uniqueness applies when inserting jobs, not when jobs execute concurrently. [CITED: https://hexdocs.pm/oban/unique_jobs.html]
- **Add a per-delivery reconcile button to the detail header:** Current reconcile works by orphan scan and delivery matching, not by an exact selected-delivery command identity. [VERIFIED: codebase grep] [VERIFIED: 32-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recent-auth UX contract | Library-owned reauth flow or custom session freshness logic | Existing adopter-owned `MailglassAdmin.Auth.authorize/2` with `:destructive_action` | The auth contract is intentionally adopter-owned and already normalizes `:unauthorized` / `:stale_auth` results. [VERIFIED: codebase grep] |
| Duplicate maintenance dedupe | Ad hoc locks or in-memory mutexes | Oban worker uniqueness where Oban is present, plus idempotency keys on appended events | The repo already relies on database idempotency for reconcile and replay safety; hidden runtime locks add state without improving correctness. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Repair audit status fields | Mutable delivery-level repair status columns | Append-only `mailglass_events` facts plus replay/reconcile read models | The ledger is the durable truth, and replay history already reads the needed audit facts without mutable repair state. [VERIFIED: codebase grep] |
| Ambiguity resolution heuristics | “Pick latest webhook” or “pick matching provider event automatically” | Explicit `choice required` state and operator selection | GitHub/Stripe-style repair flows are exact-delivery or exact-event oriented; guessing hides risk instead of removing it. [CITED: https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB] [VERIFIED: codebase grep] |

**Key insight:** This phase is mostly about contract clarity, not new machinery; the repo already has the machinery, and hand-rolled additions would primarily widen support burden or erode trust semantics. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Conflating Availability, Outcome, and Effect

**What goes wrong:** UI text collapses “can I act?”, “did the action finish?”, and “did anything change?” into one label such as `succeeded`. [VERIFIED: codebase grep]

**Why it happens:** Current domain/service facts (`:exact`, `:ambiguous`, `:replayed`, `:noop`) are close to UX needs but not identical to operator-facing language. [VERIFIED: codebase grep]

**How to avoid:** Introduce one presenter mapping layer that outputs `ready | choice required | unavailable`, `requested | completed | failed`, and effect labels like `new work | no change`. [VERIFIED: 32-CONTEXT.md]

**Warning signs:** Header copy still says `Last replay: succeeded`, or timeline copy makes a no-op replay look like a fix. [VERIFIED: codebase grep]

### Pitfall 2: Promise a Manual Reconcile Fallback That Doesn't Actually Work

**What goes wrong:** Docs and boot warnings point operators to `mix mailglass.reconcile` without Oban, but the task currently errors when Oban is absent. [VERIFIED: codebase grep]

**Why it happens:** The worker stub returns `available?/0 == false`, and the mix task treats that as a hard failure rather than a fallback code path. [VERIFIED: codebase grep]

**How to avoid:** Plan one coherent fallback contract and make warnings, docs, task behavior, and tests all tell the same story. [VERIFIED: codebase grep]

**Warning signs:** Warning text says “run the task manually” while CLI output says “Add `{:oban, "~> 2.21"}` to your deps to enable reconciliation.” [VERIFIED: codebase grep]

### Pitfall 3: Hiding the Replay Button Instead of Explaining Unavailability

**What goes wrong:** Operators lose context about why replay cannot happen for a historical or ambiguous row. [VERIFIED: codebase grep]

**Why it happens:** It is tempting to treat unavailable replay as a permission problem or to remove the affordance entirely. [VERIFIED: codebase grep]

**How to avoid:** Keep the entrypoint contextual, but make the modal/header state explicit about why replay is unavailable or requires a choice. [VERIFIED: codebase grep]

**Warning signs:** No path exists to learn whether the blocker is historical linkage, no linked events yet, or multiple safe candidates. [VERIFIED: codebase grep]

### Pitfall 4: Assuming Oban Uniqueness Prevents Concurrent Execution

**What goes wrong:** A plan relies on `unique: [period: 60]` alone to guarantee singleton reconcile execution semantics. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

**Why it happens:** Oban’s unique-jobs feature sounds like a global lock, but the docs say it only affects insertion-time duplication. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

**How to avoid:** Treat uniqueness as enqueue dedupe only, and keep database idempotency keys as the real correctness boundary. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/unique_jobs.html]

**Warning signs:** Planning text equates “unique job” with “cannot run twice” or drops idempotency assertions from tests. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

## Code Examples

Verified patterns from official sources and current repo seams:

### LiveView Authorization at Mount and Event Time
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/security-model.html
def mount(_params, _session, socket) do
  {:ok, socket}
end

def handle_event("delete_project", %{"project_id" => project_id}, socket) do
  Project.delete!(socket.assigns.current_user, project_id)
  {:noreply, socket}
end
```
[CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

### Current Replay Command Audit Pattern
```elixir
# Source: local repo pattern in lib/mailglass/webhook/replay.ex
%{
  tenant_id: params.tenant_id,
  delivery_id: params.delivery_id,
  type: :webhook_replay_succeeded,
  occurred_at: Clock.utc_now(),
  metadata: %{
    "requested_audit_event_id" => requested_audit_event_id,
    "outcome" => Atom.to_string(outcome.status),
    "new_event_count" => outcome.new_event_count
  }
}
```
[VERIFIED: codebase grep]

### Oban Uniqueness as Insert-Time Dedupe
```elixir
# Source: https://hexdocs.pm/oban/unique_jobs.html
use Oban.Worker,
  unique: [
    period: {2, :minutes},
    fields: [:worker, :args],
    keys: [:document_id]
  ]
```
[CITED: https://hexdocs.pm/oban/unique_jobs.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hide a dangerous button and trust the client not to call it | Authorize destructive actions on the server in `handle_event` as well as page access on `mount` | Current LiveView guidance; confirmed in docs as of Phoenix LiveView `1.1.30` on 2026-05-05. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | Matches Phase 32’s recent-auth and action-time auth decisions. [VERIFIED: 32-CONTEXT.md] |
| Treat replay as generic “reprocess failed webhooks” | Replay one exact stored webhook identity and keep idempotency/no-op semantics explicit | Current repo already does exact-target replay; Stripe’s manual recovery docs likewise focus on explicit undelivered events. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB] | Supports tenant-safe operator repair without hidden guessing. [VERIFIED: codebase grep] |
| Put every recovery action beside every delivery | Separate exact replay from maintenance reconciliation | Current repo and locked decisions keep replay operator-facing and reconcile maintenance-oriented. [VERIFIED: codebase grep] [VERIFIED: 32-CONTEXT.md] | Prevents a misleading per-delivery reconcile contract. [VERIFIED: 32-CONTEXT.md] |

**Deprecated/outdated:**

- `Last replay: succeeded` as the top-level operator label is outdated for this phase because it overclaims no-op outcomes; presenter copy should move to `completed` plus effect wording. [VERIFIED: codebase grep] [VERIFIED: 32-CONTEXT.md]
- “Without Oban, run `mix mailglass.reconcile`” is outdated unless the mix task itself honors that fallback; right now the docs and CLI contract disagree. [VERIFIED: codebase grep]

## Assumptions Log

All claims in this research were verified or cited — no user confirmation is required before planning.

## Open Questions

1. **Should the Oban-less reconcile fallback be implemented in the mix task itself or by moving pure reconcile logic out of the Oban-gated worker module?**
   - What we know: The current worker is conditionally compiled behind `Code.ensure_loaded?(Oban.Worker)`, the warning/docs promise a manual fallback, and the task currently exits when Oban is absent. [VERIFIED: codebase grep]
   - What's unclear: Which implementation shape minimizes conditional-compilation complexity while preserving the optional-dependency contract. [VERIFIED: codebase grep]
   - Recommendation: Decide this during planning, but treat “warnings/docs/task/tests all agree” as the non-negotiable output and keep the resulting reconcile function pure and reusable. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core build/test workflow | ✓ | OTP 28 / Elixir runtime available via `elixir --version`. [VERIFIED: shell command] | — |
| Mix | Core build/test workflow | ✓ | Available via `mix --version`. [VERIFIED: shell command] | — |
| PostgreSQL | Replay/reconcile tests and runtime persistence | ✓ | `pg_isready` reports `accepting connections` on `localhost:5432`. [VERIFIED: shell command] | — |
| Oban dependency in repo | Background reconcile path | ✓ | `2.21.1` in `mix.lock`; current latest is `2.22.1`. [VERIFIED: codebase grep] [VERIFIED: hex.pm API, 2026-05-05] | CLI/manual maintenance path is intended fallback, but contract is currently inconsistent and should be fixed in this phase. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:**

- None found for planning or targeted verification. [VERIFIED: shell command]

**Missing dependencies with fallback:**

- No external scheduler was audited here; reconcile scheduling falls back conceptually to system cron, but the current Oban-less CLI contract is inconsistent and requires Phase 32 hardening before that fallback is trustworthy. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest on the current Phoenix LiveView stack. [VERIFIED: codebase grep] |
| Config file | [`config/test.exs`](/Users/jon/projects/mailglass/config/test.exs:1) and [`mailglass_admin/config/test.exs`](/Users/jon/projects/mailglass/mailglass_admin/config/test.exs:1). [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs test/mailglass/operator/timeline_test.exs` and `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs`. Both passed on 2026-05-05. [VERIFIED: shell command] |
| Full suite command | `mix test` and `cd mailglass_admin && mix test`. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAT-01 | Replay refuses stale-auth / denied actions before replay audit rows are written | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs` | ✅ [VERIFIED: codebase grep] |
| MAT-01 | Replay target resolution distinguishes exact, ambiguous, and unavailable cases | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs` | ✅ [VERIFIED: codebase grep] |
| MAT-01 | Replay writes requested/succeeded/failed durable audit facts and distinguishes `:replayed` vs `:noop` | Core integration | `mix test test/mailglass/webhook/replay_test.exs` | ✅ [VERIFIED: codebase grep] |
| MAT-01 | Reconcile appends `:reconciled` facts and remains idempotent | Core integration | `mix test test/mailglass/webhook/reconciler_test.exs` | ✅ [VERIFIED: codebase grep] |
| MAT-01 | Reconcile fallback contract without Oban matches docs/warnings/task behavior | Mix task / optional-dep regression | `mix test test/mix/tasks/mailglass_reconcile_test.exs` | ❌ Wave 0 [VERIFIED: codebase grep] |
| MAT-01 | Operator presenter copy separates availability, outcome, and effect without exposing raw atoms | LiveView integration / component test | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs` | ⚠ Partial; wording behavior exists but the new vocabulary contract is not fully locked yet. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the replay/reconcile focused tests in both projects. [VERIFIED: codebase grep]
- **Per wave merge:** Run `mix test` and `cd mailglass_admin && mix test`. [VERIFIED: codebase grep]
- **Phase gate:** Full suite green plus explicit pass on any new mix-task fallback tests before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `test/mix/tasks/mailglass_reconcile_test.exs` — lock the intended Oban-present and Oban-absent fallback semantics so docs, warnings, and CLI cannot drift again. [VERIFIED: codebase grep]
- [ ] Expand `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — lock `ready | choice required | unavailable` and `completed + effect` wording at the UI boundary. [VERIFIED: codebase grep]
- [ ] Add focused assertion coverage for timeline/header presenter mapping so raw atoms like `:webhook_replay_succeeded` never leak as final operator wording. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Adopter-owned `MailglassAdmin.Auth.authorize/2` session actor and recent-auth context. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Phoenix session + LiveView mount/session flow; sensitive actions re-check in `handle_event`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V4 Access Control | yes | Tenant-safe target lookup plus action-time `:destructive_action` authorization before replay execution. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Required `tenant_id`, `delivery_id`, and `webhook_event_id` guards in replay/replay-target paths; exact candidate selection instead of heuristic input expansion. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase 32 does not introduce new cryptographic primitives; it only consumes existing auth/session timestamps and append-only audit facts. [VERIFIED: codebase grep] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant replay of another tenant’s webhook row | Elevation of Privilege | Resolve target via tenant-scoped queries and fail `:webhook_event_not_found` on tenant mismatch before audit or replay work begins. [VERIFIED: codebase grep] |
| Stale-auth destructive action | Spoofing / Elevation of Privilege | Action-time `:destructive_action` authorization with `recent_auth_at` semantics; deny before command execution. [VERIFIED: codebase grep] |
| Ambiguous replay target guessed automatically | Tampering | Preserve ambiguity as a precondition state requiring explicit choice or unavailability. [VERIFIED: codebase grep] |
| Replay/reconcile logs leaking recipient or payload data | Information Disclosure | Keep telemetry/audit metadata PII-free and use existing whitelist conventions. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep] |
| Duplicate reconcile side effects | Tampering / Repudiation | Keep append-only idempotency keys such as `reconciled:<orphan_id>` and do not rely on worker scheduling alone. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |

## Sources

### Primary (HIGH confidence)

- Local repo seams and tests:
  - [`mailglass_admin/lib/mailglass_admin/auth.ex`](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/auth.ex:1)
  - [`mailglass_admin/lib/mailglass_admin/operator/mount.ex`](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/mount.ex:1)
  - [`mailglass_admin/lib/mailglass_admin/operator_live.ex`](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:1)
  - [`mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:1)
  - [`mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:1)
  - [`mailglass_admin/lib/mailglass_admin/operator/timeline.ex`](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/timeline.ex:1)
  - [`lib/mailglass/webhook/replay.ex`](/Users/jon/projects/mailglass/lib/mailglass/webhook/replay.ex:1)
  - [`lib/mailglass/operator/replay_targets.ex`](/Users/jon/projects/mailglass/lib/mailglass/operator/replay_targets.ex:1)
  - [`lib/mailglass/operator/replay_history.ex`](/Users/jon/projects/mailglass/lib/mailglass/operator/replay_history.ex:1)
  - [`lib/mailglass/operator/timeline.ex`](/Users/jon/projects/mailglass/lib/mailglass/operator/timeline.ex:1)
  - [`lib/mailglass/webhook/reconciler.ex`](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:1)
  - [`lib/mailglass/events/reconciler.ex`](/Users/jon/projects/mailglass/lib/mailglass/events/reconciler.ex:1)
  - [`lib/mix/tasks/mailglass.reconcile.ex`](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.reconcile.ex:1)
  - [`lib/mailglass/application.ex`](/Users/jon/projects/mailglass/lib/mailglass/application.ex:1)
  - [`guides/webhook-troubleshooting.md`](/Users/jon/projects/mailglass/guides/webhook-troubleshooting.md:1)
  - [`test/mailglass/webhook/replay_test.exs`](/Users/jon/projects/mailglass/test/mailglass/webhook/replay_test.exs:1)
  - [`test/mailglass/webhook/reconciler_test.exs`](/Users/jon/projects/mailglass/test/mailglass/webhook/reconciler_test.exs:1)
  - [`test/mailglass/operator/timeline_test.exs`](/Users/jon/projects/mailglass/test/mailglass/operator/timeline_test.exs:1)
  - [`mailglass_admin/test/mailglass_admin/operator_live_test.exs`](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:1)
  - [`mailglass_admin/test/support/endpoint_case.ex`](/Users/jon/projects/mailglass/mailglass_admin/test/support/endpoint_case.ex:1)
- Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
- Oban unique jobs guide: https://hexdocs.pm/oban/unique_jobs.html
- Hex package registry API for Phoenix, Phoenix LiveView, Oban, Ecto, Ecto SQL, Plug, Swoosh, Tailwind, and Floki: https://hex.pm/api/packages/

### Secondary (MEDIUM confidence)

- GitHub sudo mode: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode
- Stripe manual processing of undelivered webhooks: https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB
- Shopify webhook troubleshooting and delivery metrics: https://shopify.dev/docs/apps/build/webhooks/troubleshooting-webhooks

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current repo versions and current registry releases were both verified directly, and the stack recommendation does not depend on unverified ecosystem folklore. [VERIFIED: codebase grep] [VERIFIED: hex.pm API, 2026-05-05]
- Architecture: HIGH - the replay/reconcile execution paths, auth seams, and current test coverage were inspected directly in the repo. [VERIFIED: codebase grep]
- Pitfalls: HIGH - the most important risks are concrete repo mismatches or direct consequences of official LiveView/Oban behavior. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] [CITED: https://hexdocs.pm/oban/unique_jobs.html]

**Research date:** 2026-05-05
**Valid until:** 2026-06-04
