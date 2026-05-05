# Phase 24: Tenant-Safe Webhook Replay with Audit Context - Research

**Researched:** 2026-05-01
**Domain:** Phoenix LiveView operator mutations over tenant-scoped webhook and ledger data. [VERIFIED: mix.lock] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Replay target shape
- **D-24-01:** The canonical replay unit is a single `mailglass_webhook_events` row, not a `mailglass_deliveries` row and not a normalized `mailglass_events` child row.
- **D-24-02:** The operator delivery screen may expose replay as a convenience entrypoint, but it must resolve to one exact raw webhook row before any replay occurs.
- **D-24-03:** If a selected delivery has exactly one replayable raw webhook row, the UI may preselect it. If it has multiple replayable rows, the operator must choose one explicitly. If it has none, replay is unavailable and the UI must say why.
- **D-24-04:** Do not ship “replay latest,” “replay all for this delivery,” or any broader batch/window replay surface in Phase 24. Those are separate incident-recovery capabilities with materially higher blast radius.

### Replay UX
- **D-24-05:** Replay should be initiated from the selected-delivery detail experience, not from the master list.
- **D-24-06:** Use a server-rendered LiveView modal for replay confirmation. Do not use a browser `confirm()` and do not navigate to a separate replay page in Phase 24.
- **D-24-07:** The modal must show the exact replay target context before confirmation: provider, webhook timestamp, provider event id, and the delivery linkage if present.
- **D-24-08:** Replay result UX should stay in place on the same LiveView: transient flash plus durable audit/result visibility in the detail pane. Operators should inspect, confirm, get the result, and continue without leaving context.

### Auth and tenant safety
- **D-24-09:** Replay is a `:destructive_action` through the existing `MailglassAdmin.Auth` seam.
- **D-24-10:** Recent-auth is required only when `recent_auth_at` is missing or stale. Do not force a fresh step-up for every replay click.
- **D-24-11:** The replay authorization check must happen at action time in the LiveView event handler or server-side replay command path, not only at mount time.
- **D-24-12:** Replay commands must require `tenant_id`, `webhook_event_id`, and actor context. Delivery id may be passed as contextual metadata, but it is not the replay identity.
- **D-24-13:** Tenant scope must be enforced before target lookup, before audit writes, and before replay execution. No unscoped replay lookup path is acceptable.

### Audit durability and visibility
- **D-24-14:** Durable replay audit facts belong in the append-only `mailglass_events` ledger, not as the primary source of truth on mutable `mailglass_webhook_events` fields.
- **D-24-15:** Phase 24 should emit explicit replay audit events for at least:
  - replay requested
  - replay succeeded
  - replay failed
- **D-24-16:** Replay audit metadata must capture enough operator context to answer “who replayed what, when, and with what outcome?” without consulting transient UI state.
- **D-24-17:** Replay audit facts should appear both inline in the selected delivery’s timeline when relevant and in a dedicated replay-history view or filtered read model. Flash alone is insufficient.
- **D-24-18:** If convenience summary fields are later added to `mailglass_webhook_events`, they are secondary cached projections only, never the audit source of truth.

### Scope and safety boundaries
- **D-24-19:** Phase 24 replay is delivery-layer recovery, not domain-state rebuild. Replaying a webhook means re-running the verified ingest path for one stored inbound request, with existing idempotency and verification boundaries still intact.
- **D-24-20:** Do not expose partial replay of normalized child events from one raw provider request unless a later phase proves that semantic split is safe.
- **D-24-21:** Duplicate/no-op outcomes are valid and should be surfaced clearly to operators. Manual replay must not imply that downstream side effects definitely changed.
- **D-24-22:** Broader “replay all failures,” time-window replays, or rebuild/backfill flows remain deferred until there is explicit product intent, throttling strategy, and stronger incident-ops design.

### Decision posture for downstream agents
- **D-24-23:** Downstream planning and execution should remain decisive by default: research tradeoffs, choose the coherent default, and avoid escalating routine local choices back to the user.
- **D-24-24:** Escalate only if a choice would materially change:
  - tenant trust boundaries
  - replay retention or raw-payload lifecycle policy
  - public admin/router/auth contract
  - long-term maintainer burden through new replay modes or background infrastructure
  - user-visible safety semantics that would surprise operators

### the agent's Discretion
- Exact freshness window length for stale recent-auth, as long as it is enforced server-side and documented clearly.
- Exact replay audit event names, as long as they are explicit, append-only, and easy to query.
- Exact placement of the replay CTA within the detail pane, as long as it does not appear in the master list and the confirmation flow remains contextual and low-surprise.
- Exact replay-history presentation shape, as long as it is backed by append-only ledger facts rather than mutable “last replay” fields.

### Deferred Ideas (OUT OF SCOPE)
- Replay all failed webhook deliveries for a tenant/provider/time window.
- Delivery-wide or batch replay with throttling/backpressure controls.
- General backfill/rebuild tooling for projections or domain state beyond webhook delivery recovery.
- Mutable summary fields on webhook rows as a primary replay audit mechanism.
- Partial replay of normalized child events from a shared raw provider payload.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPLAY-01 | Operator can trigger webhook replay for a targeted event or delivery from the admin surface. [VERIFIED: .planning/REQUIREMENTS.md] | Use a delivery-detail CTA that resolves to one tenant-scoped `mailglass_webhook_events` row, then confirms via a LiveView modal before executing a single replay command. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] |
| REPLAY-02 | Replay records durable audit context for who triggered it, what was replayed, and when. [VERIFIED: .planning/REQUIREMENTS.md] | Write append-only replay audit facts to `mailglass_events` and render them through the existing timeline plus a replay-history read model. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] |
| REPLAY-03 | Replay respects tenant scoping and existing idempotency and verification boundaries. [VERIFIED: .planning/REQUIREMENTS.md] | Require `tenant_id`, `webhook_event_id`, and actor context; authorize at action time; reuse normalization and projector logic without bypassing duplicate and reconciliation rules. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
</phase_requirements>

## Summary

Phase 24 should ship as a synchronous, server-driven replay flow centered on one canonical command in core mailglass, with the admin UI acting only as a delivery-first entrypoint and confirmation surface. That recommendation fits the current codebase because the operator UI is already a URL-backed LiveView detail view, the auth seam already distinguishes `:destructive_action`, the ledger is already the durable audit source, and Oban is not available in the current runtime. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/optional_deps/oban.ex] [VERIFIED: shell:elixir -e 'IO.puts(Code.ensure_loaded?(Oban.Worker))']

The critical planning insight is that replay cannot simply call `Mailglass.Webhook.Ingest.ingest_multi/3` with the stored row unchanged. The current ingest path performs a pre-insert duplicate check and uses the unique `(provider, provider_event_id)` index on `mailglass_webhook_events`, so the unchanged raw row is intentionally treated as a structural duplicate and becomes a no-op. Phase 24 therefore needs a replay-specific entrypoint that reuses provider normalization, delivery matching, projector updates, suppression hooks, and ledger idempotency rules without attempting to re-receive the original webhook as a new inbound row. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs]

The second planning constraint is that raw webhook rows are not keyed by `delivery_id`, and some providers batch multiple logical events in one request. A selected delivery therefore needs a tenant-scoped resolver that maps the delivery to zero, one, or many raw webhook rows and surfaces the exact target before replay. SendGrid-style batch payloads make this especially important because replaying one exact raw row may legitimately re-run sibling events from the same provider request; Phase 24 must surface that risk instead of hiding it. [VERIFIED: lib/mailglass/operator/timeline.ex] [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

**Primary recommendation:** Add a tenant-scoped `Mailglass.Operator.WebhookReplays.replay/1` command that resolves one stored webhook row, re-normalizes its stored payload through the provider module, appends replay audit events to `mailglass_events`, and updates the existing operator detail view in place. [VERIFIED: lib/mailglass/webhook/provider.ex] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Replay CTA + confirmation modal | Frontend Server (SSR) | Browser / Client | The interaction is a LiveView modal with server events, not a JS-only widget. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Recent-auth and destructive authorization | Frontend Server (SSR) | API / Backend | LiveView mount can gate page access, but sensitive actions must be re-authorized in `handle_event/3` or the command path. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/mount.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Tenant-scoped replay target resolution | API / Backend | Database / Storage | The UI starts from a delivery, but the real identity is a raw webhook row that must be looked up through tenant-scoped queries. [VERIFIED: lib/mailglass/operator/deliveries.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: lib/mailglass/tenancy.ex] |
| Replay execution | API / Backend | Database / Storage | Re-normalizing stored raw payloads and updating projections is business logic over persistent data. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/provider.ex] |
| Durable audit trail | Database / Storage | API / Backend | The append-only `mailglass_events` ledger is already the durable truth store for operator-visible history. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex] |
| Inline timeline and replay-history rendering | Frontend Server (SSR) | API / Backend | Existing operator timeline rendering can display new replay event types once the read model exposes them. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/timeline.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] |

## Project Constraints (from CLAUDE.md)

- Use Phoenix, LiveView, Ecto, and Postgres only; this repo is Phoenix-first and Postgres-only. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Keep multi-tenancy first-class; every replay path must require and preserve `tenant_id`. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/tenancy.ex]
- Treat `mailglass_events` as append-only; never UPDATE or DELETE replay audit facts. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/repo.ex]
- Do not place PII in telemetry or invent a second mutable audit source. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/telemetry.ex] [VERIFIED: lib/mailglass/events.ex]
- Prefer pluggable behaviours and existing seams over hard-coding adopter auth assumptions. [VERIFIED: CLAUDE.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]
- Keep the operator UI server-rendered and mobile-safe; no custom JS workflow is required for this phase. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | 1.1.28 [VERIFIED: mix.lock] | Delivery-detail CTA, modal confirmation, and in-place result refresh. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] | The existing operator surface is already a LiveView, and LiveView security guidance explicitly expects mount-time checks plus action-time authorization. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Ecto / Ecto SQL | 3.13.5 [VERIFIED: mix.lock] | Tenant-scoped resolver queries and replay transaction composition. [VERIFIED: lib/mailglass/operator/deliveries.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] | `Ecto.Multi` gives ordered, atomic operation composition with unique step names and result inspection. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| mailglass ledger + webhook modules | 0.3.2 [VERIFIED: mix.exs] | Existing append-only audit writer, provider normalization, delivery projector, and webhook storage. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/webhook/provider.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] | Reusing these modules avoids building a second replay semantics path. [VERIFIED: lib/mailglass/webhook/ingest.ex] |
| PostgreSQL | 14.17 locally available [VERIFIED: shell:psql --version] | Source-of-truth persistence, unique constraints, and append-only trigger enforcement. [VERIFIED: lib/mailglass/repo.ex] | The project explicitly depends on Postgres-only features such as JSONB, triggers, and partial unique indexes. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/PROJECT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | 2.21.1 in `mix.lock`; unavailable in current runtime [VERIFIED: mix.lock] [VERIFIED: shell:elixir -e 'IO.puts(Code.ensure_loaded?(Oban.Worker))'] | Future async execution or deduped operator jobs. [VERIFIED: lib/mailglass/optional_deps/oban.ex] | Only if Phase 24 later chooses a queued replay path; do not make core replay depend on it now. [VERIFIED: lib/mailglass/optional_deps/oban.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| MailglassAdmin.Auth | repo seam [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] | Actor normalization and `:destructive_action` authorization. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] | Use on every replay attempt, not just on mount. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Synchronous replay command | Oban-backed replay worker | Better durability for long-running work, but current runtime has no Oban and the phase requires in-place operator feedback. [VERIFIED: shell:elixir -e 'IO.puts(Code.ensure_loaded?(Oban.Worker))'] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |
| Ledger-backed audit facts | Mutable `mailglass_webhook_events` summary fields | Simpler writes, but it violates the locked source-of-truth rule and weakens audit history. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: lib/mailglass/events/event.ex] |
| Replay-specific command that reuses sub-steps | Direct `Webhook.Ingest.ingest_multi/3` call on stored row | Direct reuse becomes a duplicate no-op because `(provider, provider_event_id)` uniqueness is intentional. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs] |

**Installation:**
```bash
# No new dependencies are required for the recommended Phase 24 path.
```

**Version verification:** Current repo-locked versions are `phoenix_live_view 1.1.28`, `ecto_sql 3.13.5`, `oban 2.21.1`, and `postgrex 0.22.0`. [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram
```text
Operator selects delivery in LiveView
  -> LiveView resolves tenant-scoped replay targets for that delivery
    -> zero targets: render "replay unavailable" reason
    -> one target: preselect exact webhook row
    -> many targets: operator chooses exact webhook row
  -> operator confirms in LiveView modal
    -> action-time Auth.authorize(:destructive_action, context)
      -> denied/stale: halt with flash and no replay
      -> allowed:
         -> core replay command loads webhook row by tenant_id + webhook_event_id
         -> provider module re-normalizes stored raw payload
         -> replay multi appends "requested" audit event
         -> projector / suppression / reconciliation-aware replay steps run
         -> replay multi appends "succeeded" or "failed" audit event
         -> LiveView refreshes detail timeline + replay history
```

### Recommended Project Structure
```text
lib/
├── mailglass/operator/webhook_replays.ex      # canonical replay command + target resolver
├── mailglass/operator/replay_history.ex       # tenant-scoped read model for replay audit events
└── mailglass/webhook/replay.ex                # optional lower-level replay helpers if command needs separation

mailglass_admin/lib/mailglass_admin/operator/
├── replay_modal.ex                            # server-rendered modal component
└── detail_header.ex                           # replay CTA and latest replay summary
```

### Pattern 1: Canonical Replay Command
**What:** One core command owns lookup, auth context requirements, provider re-normalization, audit writes, and result shape. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
**When to use:** Every admin-triggered replay in Phase 24. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: local pattern derived from lib/mailglass/webhook/ingest.ex and lib/mailglass/events.ex
def replay(%{tenant_id: tenant_id, webhook_event_id: id, actor: actor} = attrs) do
  with {:ok, target} <- fetch_target(tenant_id, id),
       {:ok, events} <- renormalize(target),
       {:ok, result} <- persist_replay(target, events, actor, attrs) do
    {:ok, result}
  end
end
```

### Pattern 2: Delivery-First UI, Webhook-First Identity
**What:** Resolve replay candidates from the selected delivery, but execute only against one raw webhook row. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
**When to use:** Operator detail pane and replay modal target display. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/detail_header.ex]
**Example:**
```elixir
# Source: local pattern derived from lib/mailglass/operator/timeline.ex and lib/mailglass/webhook/webhook_event.ex
def list_replay_targets(%{tenant_id: tenant_id, delivery_id: delivery_id}) do
  # Join delivery-linked ledger events to webhook rows by provider/provider_event_id.
  # Return distinct webhook rows plus display context for the modal.
end
```

### Pattern 3: Append Audit Before and After Replay
**What:** Emit `replay_requested` before attempting replay, then emit `replay_succeeded` or `replay_failed` after the result is known. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
**When to use:** Every replay attempt, including no-op and duplicate outcomes. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
**Example:**
```elixir
# Source: local pattern derived from lib/mailglass/events.ex
Mailglass.Events.append(%{
  tenant_id: tenant_id,
  delivery_id: delivery_id,
  type: :replay_requested,
  metadata: %{"webhook_event_id" => webhook_event_id, "actor_subject_id" => actor.subject_id}
})
```

### Anti-Patterns to Avoid
- **Direct `Ingest.ingest_multi/3` replay:** The unchanged stored row is currently treated as a duplicate and will not perform useful work. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs]
- **Mount-only authorization:** LiveView docs explicitly require action-time authorization for sensitive events. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- **Replay by delivery id alone:** Delivery id is contextual metadata, not replay identity. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
- **Flash-only result visibility:** The phase requires durable timeline and history visibility. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sensitive-action auth | Ad hoc session checks in multiple handlers | `MailglassAdmin.Auth.authorize/3` with `:destructive_action` | The seam already normalizes actors and stale-auth outcomes. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| Replay audit trail | Mutable status columns on webhook rows | `Mailglass.Events.append/1` and timeline read models | The ledger is already append-only and operator-visible. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] |
| Async dedupe | Custom replay lock table | Oban unique jobs, if async is later adopted | Oban already documents uniqueness and conflict detection; no need for custom queue semantics. [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Confirmation UX | Browser `confirm()` or a separate replay page | LiveView modal in the current detail view | The UI contract is already server-rendered and contextual. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |

**Key insight:** The phase is mostly about composing existing seams correctly, not inventing new infrastructure. The risky part is identity resolution and audit correctness, not button rendering. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex]

## Common Pitfalls

### Pitfall 1: Replay Becomes a Duplicate No-Op
**What goes wrong:** The operator clicks replay, but the system treats the work as a duplicate and nothing meaningful re-runs. [VERIFIED: test/mailglass/webhook/ingest_test.exs]
**Why it happens:** `Webhook.Ingest` pre-checks duplicates and writes `mailglass_webhook_events` with `on_conflict: :nothing` on `(provider, provider_event_id)`. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex]
**How to avoid:** Build a replay-specific path that reuses normalization and persistence sub-steps without trying to re-receive the same webhook row. [VERIFIED: lib/mailglass/webhook/provider.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex]
**Warning signs:** A replay result reports `duplicate: true` or no new audit facts appear. [VERIFIED: test/mailglass/webhook/ingest_test.exs]

### Pitfall 2: Selected Delivery Does Not Uniquely Identify a Raw Webhook
**What goes wrong:** The UI assumes one delivery equals one raw webhook row and replays the wrong target or hides ambiguity. [VERIFIED: lib/mailglass/webhook/webhook_event.ex]
**Why it happens:** `mailglass_webhook_events` stores raw requests without `delivery_id`, and provider batches can normalize into multiple logical events. [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex]
**How to avoid:** Add a tenant-scoped target resolver and make the operator pick one exact row when multiple candidates exist. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
**Warning signs:** Replay UI only knows `delivery_id`, or the chosen raw row references multiple provider events. [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex]

### Pitfall 3: Auth Happens at Mount but Not at Replay Time
**What goes wrong:** A user who was authorized to view the screen can still trigger replay after auth has gone stale. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
**Why it happens:** Hiding the button or relying on `on_mount` is not sufficient for LiveView mutations. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
**How to avoid:** Call `MailglassAdmin.Auth.authorize/3` for `:destructive_action` inside the replay event handler or the command path. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]
**Warning signs:** Replay code path reads `socket.assigns.operator_actor` but never re-authorizes. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]

### Pitfall 4: Audit Exists Only in Flash
**What goes wrong:** Operators can no longer answer who replayed what after the page refreshes. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
**Why it happens:** UI feedback is implemented, but no durable ledger events or read model are added. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]
**How to avoid:** Append replay ledger events and render them through timeline/history reads. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/operator/timeline.ex]
**Warning signs:** Replay success is only visible as a flash message. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

### Pitfall 5: Validation Lane Looks Healthy but Admin Tests Are Not Hermetic
**What goes wrong:** Phase-local tests pass inconsistently or fail on uniqueness collisions unrelated to replay logic. [VERIFIED: shell:mix test test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors]
**Why it happens:** The current `operator_live_test.exs` helper inserts suppressions directly and the isolated lane hit `mailglass_suppressions_tenant_address_scope_idx`. [VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs] [VERIFIED: shell:mix test test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors]
**How to avoid:** Treat replay-admin test hermeticity as a Wave 0 concern and add explicit cleanup or unique fixture values before layering replay cases on top. [VERIFIED: mailglass_admin/test/support/live_view_case.ex]
**Warning signs:** Standalone admin LiveView lane fails with a suppression uniqueness error before replay tests exist. [VERIFIED: shell:mix test test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors]

## Code Examples

Verified patterns from official sources and existing code:

### Action-Time Authorization in LiveView
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/security-model.html
def handle_event("replay_webhook", %{"webhook_event_id" => id}, socket) do
  case MailglassAdmin.Auth.authorize(socket.assigns.operator_auth.adapter, :destructive_action, %{
         actor: socket.assigns.operator_actor,
         params: %{"webhook_event_id" => id}
       }) do
    {:ok, _} -> {:noreply, begin_replay(socket, id)}
    {:error, _reason, _details} -> {:noreply, deny_replay(socket)}
  end
end
```

### Ordered Transaction Composition
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.run(:target, fn _repo, _changes -> fetch_target(tenant_id, webhook_event_id) end)
|> Ecto.Multi.run(:requested_audit, fn _repo, %{target: target} -> append_requested(target, actor) end)
|> Ecto.Multi.run(:replay, fn _repo, %{target: target} -> execute_replay(target, actor) end)
|> Repo.transact()
```

### Optional Async Dedupe if Phase 24 Later Queues Replay
```elixir
# Source: https://hexdocs.pm/oban/unique_jobs.html
use Oban.Worker,
  queue: :mailglass_operator,
  unique: [period: 300, fields: [:worker, :args], keys: [:webhook_event_id]]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mount-only LiveView gating | Mount-time access checks plus action-time authorization | Current LiveView security guidance. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | Sensitive replay actions must re-authorize on every execution path. |
| Mutable status fields as audit history | Append-only ledger facts plus read models | Already established in mailglass core. [VERIFIED: lib/mailglass/events/event.ex] | Replay history should be queryable and immutable. |
| “Redeliver failed deliveries” as a broad incident tool | Exact-target redelivery of one delivery/request with idempotency awareness | Current provider/operator docs. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks] [CITED: https://docs.stripe.com/webhooks/process-undelivered-events] | Phase 24 should stay narrow and explicit about what one replay actually targets. |

**Deprecated/outdated:**
- Replay from the master list or via browser `confirm()` is out of contract for this phase. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
- Treating a flash message as sufficient replay evidence is out of contract for this phase. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited in this session.

## Open Questions

1. **What stale-auth window should `:destructive_action` enforce for replay?**
   - What we know: Phase 24 allows discretion on the exact freshness window, but requires server-side enforcement and clear operator behavior. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
   - What's unclear: The repo does not yet define one duration for replay-specific stale auth. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]
   - Recommendation: Pick one explicit window in planning, document it in tests and README, and keep it centralized in the auth adapter contract rather than the LiveView. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]

2. **How should the UI warn when one raw webhook row links to sibling deliveries?**
   - What we know: SendGrid normalization supports multi-event request batches, and Phase 24 forbids partial child-event replay. [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
   - What's unclear: The exact operator copy for “this raw request may affect more than the selected delivery” is not yet locked. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/detail_header.ex]
   - Recommendation: Keep the command behavior unchanged, but surface a concise warning in the confirmation modal whenever the resolved raw row links to more than one delivery. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Core implementation and tests | ✓ [VERIFIED: shell:mix --version] | 1.19.5 / Mix 1.19.5 [VERIFIED: shell:mix --version] | — |
| PostgreSQL | Repo-backed replay, ledger writes, tests | ✓ [VERIFIED: shell:pg_isready] | 14.17 locally [VERIFIED: shell:psql --version] | — |
| Oban runtime | Optional queued replay path only | ✗ [VERIFIED: shell:elixir -e 'IO.puts(Code.ensure_loaded?(Oban.Worker))'] | — | Use synchronous replay path in Phase 24. [VERIFIED: lib/mailglass/optional_deps/oban.ex] |
| Node / npm | Context7 CLI lookup only, not implementation | ✓ [VERIFIED: shell:node --version] [VERIFIED: shell:npm --version] | Node 22.14.0 / npm 11.1.0 [VERIFIED: shell:node --version] [VERIFIED: shell:npm --version] | Web docs were also available. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: shell:mix --version] [VERIFIED: shell:pg_isready]

**Missing dependencies with fallback:**
- Oban runtime is not available here; do not make replay background execution a Phase 24 prerequisite. [VERIFIED: shell:elixir -e 'IO.puts(Code.ensure_loaded?(Oban.Worker))'] [VERIFIED: lib/mailglass/optional_deps/oban.ex]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Mix projects (`mailglass` and `mailglass_admin`). [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs] |
| Config file | none; test setup is driven by `test/test_helper.exs` and `mailglass_admin/test/test_helper.exs`. [VERIFIED: test/test_helper.exs] [VERIFIED: mailglass_admin/test/test_helper.exs] |
| Quick run command | `mix test test/mailglass/operator/timeline_test.exs test/mailglass/webhook/ingest_test.exs --warnings-as-errors` [VERIFIED: shell:mix test test/mailglass/operator/timeline_test.exs --warnings-as-errors] [VERIFIED: shell:mix test test/mailglass/webhook/ingest_test.exs --warnings-as-errors] |
| Full suite command | `mix test --warnings-as-errors` plus `cd mailglass_admin && mix test --warnings-as-errors` [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPLAY-01 | Delivery-detail replay CTA resolves an exact webhook row and confirms in place | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_replay_live_test.exs --warnings-as-errors` | ❌ Wave 0 |
| REPLAY-02 | Replay writes durable requested/succeeded/failed audit events and renders them in history | Core integration | `mix test test/mailglass/operator/webhook_replays_test.exs --warnings-as-errors` | ❌ Wave 0 |
| REPLAY-03 | Replay enforces tenant scope, action-time auth, and no-op/duplicate safety | Core + LiveView integration | `mix test test/mailglass/operator/webhook_replays_test.exs test/mailglass_admin/operator_replay_live_test.exs --warnings-as-errors` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/mailglass/operator/timeline_test.exs test/mailglass/webhook/ingest_test.exs --warnings-as-errors`
- **Per wave merge:** `mix test --warnings-as-errors` and `cd mailglass_admin && mix test --warnings-as-errors`
- **Phase gate:** Both project suites green, including the replay-specific admin lane

### Wave 0 Gaps
- [ ] `test/mailglass/operator/webhook_replays_test.exs` — covers canonical replay command, resolver ambiguity, audit events, duplicate/no-op outcomes.
- [ ] `mailglass_admin/test/mailglass_admin/operator_replay_live_test.exs` — covers modal, action-time auth, and same-view result visibility.
- [ ] Hermetic admin fixture cleanup — the standalone admin lane currently fails with `mailglass_suppressions_tenant_address_scope_idx` and should be stabilized before replay assertions are layered on top. [VERIFIED: shell:mix test test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Adopter-owned auth module through `MailglassAdmin.Auth`. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| V3 Session Management | yes | `recent_auth_at` normalization and stale-auth enforcement at action time. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [CITED: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode] |
| V4 Access Control | yes | Tenant-scoped lookup plus action-time authorization on replay. [VERIFIED: lib/mailglass/tenancy.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V5 Input Validation | yes | Normalize and validate `tenant_id`, `webhook_event_id`, and modal parameters server-side. [VERIFIED: lib/mailglass/operator/deliveries.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] |
| V6 Cryptography | no new crypto | Replay should reuse existing verified storage and provider normalizers rather than adding new signature logic. [VERIFIED: lib/mailglass/webhook/provider.ex] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant replay by guessed id | Elevation of Privilege | Require `tenant_id` before lookup and scope all resolver queries through `Tenancy.scope/2`. [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: lib/mailglass/operator/deliveries.ex] |
| Stale session reusing replay button | Spoofing / Elevation of Privilege | Re-authorize `:destructive_action` at replay time using normalized actor context. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Audit evidence overwritten or deleted | Repudiation | Append replay facts to `mailglass_events`; never mutate them in place. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/repo.ex] |
| Over-broad replay from batched provider request | Tampering | Show exact raw target context and warn when a raw row links to multiple deliveries. [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |
| Duplicate operator clicks or queued retries | Denial of Service / Tampering | Surface duplicate/no-op outcomes clearly and rely on existing idempotency rules; if async is later added, use Oban uniqueness. [VERIFIED: test/mailglass/webhook/ingest_test.exs] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |

## Sources

### Primary (HIGH confidence)
- `mailglass_admin/lib/mailglass_admin/auth.ex` - auth seam and actor normalization. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - current operator interaction model and phase-adjacent seams. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]
- `lib/mailglass/webhook/ingest.ex` - duplicate behavior, projector flow, and replay constraints. [VERIFIED: lib/mailglass/webhook/ingest.ex]
- `lib/mailglass/webhook/webhook_event.ex` - raw webhook identity and unique constraint. [VERIFIED: lib/mailglass/webhook/webhook_event.ex]
- `lib/mailglass/events.ex` and `lib/mailglass/events/event.ex` - append-only audit writer and ledger schema. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex]
- `https://hexdocs.pm/phoenix_live_view/security-model.html` - LiveView action-time authorization expectations. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transaction composition semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Secondary (MEDIUM confidence)
- `https://docs.github.com/en/enterprise-cloud%40latest/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks` - exact-target redelivery precedent. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks]
- `https://docs.stripe.com/webhooks/process-undelivered-events` - idempotency-aware manual recovery guidance. [CITED: https://docs.stripe.com/webhooks/process-undelivered-events]
- `https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode` - recent-auth/sudo-mode precedent. [CITED: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode]
- `https://hexdocs.pm/oban/unique_jobs.html` - dedupe guidance for any later async path. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase can reuse existing repo seams and locked dependency versions. [VERIFIED: mix.lock] [VERIFIED: mix.exs]
- Architecture: HIGH - the main traps are directly observable in current code and tests. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs]
- Pitfalls: HIGH - duplicate no-op behavior, batched payload breadth, and action-time auth requirements are all verified. [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

**Research date:** 2026-05-01
**Valid until:** 2026-05-31
