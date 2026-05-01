# Phase 24: Tenant-Safe Webhook Replay with Audit Context - Research

**Researched:** 2026-05-01
**Domain:** Phoenix LiveView operator actions over append-only audit data and webhook ingest reuse. [VERIFIED: mix.lock] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex]
**Confidence:** MEDIUM

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
| REPLAY-01 | Operator can trigger webhook replay for a targeted event or delivery from the admin surface. | Delivery-first LiveView entry, webhook-row-first resolver, server-rendered modal, and a canonical replay command are the minimum viable shape. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] |
| REPLAY-02 | Replay records durable audit context for who triggered it, what was replayed, and when. | The durable source of truth should be new append-only ledger events plus a read model for inline history. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |
| REPLAY-03 | Replay respects tenant scoping and existing idempotency and verification boundaries. | The command must require `tenant_id`, `webhook_event_id`, and actor context, must authorize at action time, and must reuse existing normalization/projection/idempotency steps instead of inventing a second semantic pipeline. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
</phase_requirements>

## Summary

Phase 24 fits the current Phoenix LiveView and Ecto/Postgres stack cleanly, but planning has to account for two structural gaps in the current data model: stored webhook rows keep decoded JSON payloads rather than the original signed request bytes, and there is no durable delivery-to-raw-webhook link today. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] [VERIFIED: lib/mailglass/events/event.ex]

The first gap means Phase 24 cannot literally re-run provider signature verification from persisted rows without adding new storage, because `Mailglass.Webhook.Ingest.parse_raw_payload/1` stores decoded JSON or a `_raw` fallback map, while provider verification APIs take the original raw request body. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/provider.ex] [VERIFIED: lib/mailglass/webhook/plug.ex] The second gap means the delivery detail screen cannot reliably infer a single raw webhook row by primary key today, and SendGrid is the sharpest case because the raw webhook row is keyed by a body hash while child normalized events use per-element `provider_event_id` values. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [VERIFIED: test/mailglass/webhook/providers/sendgrid_test.exs]

The planning default should therefore be: keep the operator UX on the existing delivery detail LiveView, add a tenant-scoped replay-target resolver/read model, and introduce one canonical `Mailglass.Webhook.Replay` command that authorizes at action time, treats a stored `mailglass_webhook_events` row as already-verified evidence, reuses provider normalization plus the existing event/projector/suppression machinery, and appends explicit replay audit facts before and after execution. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: lib/mailglass/webhook/plug.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

**Primary recommendation:** Plan Phase 24 around a synchronous LiveView-triggered replay command plus a new durable replay-target/read-model seam; do not add new infrastructure unless profiling later shows that one-row replay is too slow for operator use. [VERIFIED: lib/mailglass/webhook/plug.ex] [VERIFIED: lib/mailglass/optional_deps/oban.ex] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Replay CTA, modal state, and result visibility | Frontend Server (SSR) | API / Backend | The operator surface is already a LiveView that owns URL-backed detail state and server-side events. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] |
| Action-time authorization and recent-auth freshness | Frontend Server (SSR) | API / Backend | LiveView handlers must re-check sensitive actions server-side, and `MailglassAdmin.Auth` already normalizes `:destructive_action` decisions. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Tenant-scoped replay target lookup | API / Backend | Database / Storage | The command boundary must require `tenant_id` and query `mailglass_webhook_events` through `Mailglass.Tenancy.scope/2` before any side effect. [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |
| Reuse of normalization, event append, projector, and suppression steps | API / Backend | Database / Storage | The current webhook pipeline composes these as one transactional path and is the seam worth extracting from, not replacing. [VERIFIED: lib/mailglass/webhook/ingest.ex] |
| Durable replay audit facts and replay history | Database / Storage | API / Backend | The ledger is append-only by design, and timeline/history views should project from ledger facts rather than mutable webhook row fields. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: CLAUDE.md] |

## Project Constraints (from CLAUDE.md)

- Use pluggable behaviours and narrow seams instead of magic; `MailglassAdmin.Auth` and `Mailglass.Tenancy` are the right extension points for this phase. [VERIFIED: CLAUDE.md]
- Keep `mailglass_events` append-only; no plan may treat mutable `mailglass_webhook_events` fields as the primary audit truth. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/events/event.ex]
- Keep multi-tenancy first-class; every replay plan must require and enforce `tenant_id`. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/tenancy.ex]
- Do not put PII into telemetry or logs; replay audit metadata can carry actor IDs and webhook IDs, but not payload excerpts or recipient content. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/webhook/telemetry.ex]
- Optional background infrastructure must route through `Mailglass.OptionalDeps.*`; do not plan a hard dependency on Oban for a single-row replay default. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/optional_deps/oban.ex]
- Avoid updating `mailglass_admin/priv/static/` unless the built bundle is committed; this phase should not need frontend bundling if it stays HEEx/LiveView-only. [VERIFIED: CLAUDE.md] [VERIFIED: mailglass_admin/mix.exs] [ASSUMED]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.5 [VERIFIED: mix.lock] | Router, LiveView runtime, session-backed operator surface. [VERIFIED: mailglass_admin/mix.exs] | The existing admin package already mounts operator flows through Phoenix router macros and LiveView sessions. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] |
| Phoenix LiveView | 1.1.28 [VERIFIED: mix.lock] | In-place modal, flash, and action-time server event handling. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] | Official guidance keeps authorization server-side and treats `handle_event/3` as a sensitive boundary. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Ecto / Ecto SQL | 3.13.5 / 3.13.5 [VERIFIED: mix.lock] | Tenant-scoped queries, transactional replay command, read-model queries. [VERIFIED: lib/mailglass/operator/deliveries.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] | The current webhook ingest and operator read models already rely on `Ecto.Multi`, `where`, `select`, and transaction boundaries. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] |
| Postgrex / Postgres | 0.22.0 / local client 14.17 [VERIFIED: mix.lock] [VERIFIED: psql --version] | Append-only ledger writes, webhook row storage, and tenant-scoped lookup. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] | The immutable-ledger trigger and replay-safe unique indexes are already in Postgres, so the phase should stay data-local instead of introducing another store. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/migrations/postgres/v02.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | 2.21.1 [VERIFIED: mix.lock] | Optional background replay execution or deduped queued retries. [VERIFIED: lib/mailglass/optional_deps/oban.ex] | Use only if later implementation proves that synchronous one-row replay is too slow or needs out-of-band retries. [VERIFIED: lib/mailglass/optional_deps/oban.ex] [ASSUMED] |
| NimbleOptions | 1.1.1 [VERIFIED: mix.lock] | Option validation for any new replay module/config seam. [VERIFIED: mix.exs] | Use if Phase 24 introduces a public replay behaviour or read-model options surface. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LiveView modal in `OperatorLive` | Separate replay page or client-side dialog | A separate route or browser `confirm()` would break the locked “stay in context” UX and duplicate state handling already present in the detail pane. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] |
| Synchronous replay command | Oban-backed replay job | Oban adds optional-dep and queue-state complexity that the current one-row operator action does not obviously need. [VERIFIED: lib/mailglass/optional_deps/oban.ex] [ASSUMED] |
| Ledger-backed replay audit events | Mutable `last_replayed_*` fields on `mailglass_webhook_events` | Mutable summary fields can exist later, but the project’s append-only audit rules make them an invalid primary truth store. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: CLAUDE.md] |

**Installation:**
```bash
# No new Hex dependencies are recommended for the default Phase 24 path.
mix deps.get
```
[VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs]

## Architecture Patterns

### System Architecture Diagram

Recommended flow for Phase 24. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/events.ex]

```text
Operator selects delivery in LiveView
        |
        v
Detail header CTA opens replay modal
        |
        v
LiveView handle_event("confirm_replay")
        |
        +--> MailglassAdmin.Auth.authorize(:destructive_action, ...)
        |         |
        |         +--> stale/unauthorized -> flash + modal stays contextual
        |
        v
Replay target resolver (tenant_id + delivery_id -> exact webhook row or explicit "none/many")
        |
        v
Mailglass.Webhook.Replay.execute(tenant_id, webhook_event_id, actor, delivery_id?)
        |
        +--> append ledger event: replay requested
        |
        +--> load stored webhook row under tenant scope
        |
        +--> normalize through provider module from stored payload
        |
        +--> reuse extracted event/projector/suppression multi steps
        |
        +--> append ledger event: replay succeeded | replay failed
        |
        v
Refresh delivery timeline + replay history pane + flash result
```

### Recommended Project Structure

The repo already separates admin UI from core read/write seams, so Phase 24 should add replay in the same split rather than mixing Repo queries into LiveView handlers. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/operator/deliveries.ex]

```text
lib/
├── mailglass/
│   ├── operator/
│   │   ├── replay_targets.ex      # delivery -> exact raw webhook row resolution
│   │   └── replay_history.ex      # ledger-backed replay history read model
│   └── webhook/
│       └── replay.ex              # canonical replay command and extracted reuse path
mailglass_admin/lib/mailglass_admin/
├── operator/
│   ├── detail_header.ex           # replay CTA + result badge area
│   ├── replay_modal.ex            # server-rendered confirmation modal
│   └── timeline.ex                # timeline rendering for replay audit rows
└── operator_live.ex               # modal state + action-time handler wiring
test/
├── mailglass/operator/            # replay target/history read-model tests
├── mailglass/webhook/             # replay command tests
└── mailglass_admin/               # LiveView replay UX/auth tests
```

### Pattern 1: Delivery-First UI, Webhook-Row-First Command

**What:** Keep the CTA on the selected delivery detail screen, but require the server to resolve that screen context to one exact `mailglass_webhook_events` row before confirmation. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

**When to use:** Use for every replay entrypoint in Phase 24, including the preselected-one-row path. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

**Example:**
```elixir
# Source: local pattern from mailglass_admin/lib/mailglass_admin/operator_live.ex
def handle_event("confirm_replay", %{"webhook_event_id" => id}, socket) do
  context = %{
    actor: socket.assigns.operator_actor,
    tenant_id: socket.assigns.filter_params["tenant_id"],
    delivery_id: socket.assigns.selected_delivery.id
  }

  case MailglassAdmin.Auth.authorize(socket.assigns.operator_auth.adapter, :destructive_action, context) do
    {:ok, %{actor: actor}} ->
      Mailglass.Webhook.Replay.execute(%{
        tenant_id: context.tenant_id,
        webhook_event_id: id,
        actor: actor,
        delivery_id: context.delivery_id
      })

    {:error, _reason, details} ->
      {:noreply, Phoenix.LiveView.put_flash(socket, :error, details.message)}
  end
end
```

### Pattern 2: Extract the Reusable Ingest Core, Do Not Re-Invoke `ingest_multi/3` Blindly

**What:** Reuse provider normalization plus the event append/projector/auto-suppress portion of webhook ingest, but do not call `Mailglass.Webhook.Ingest.ingest_multi/3` unchanged for manual replay. [VERIFIED: lib/mailglass/webhook/ingest.ex]

**When to use:** Use when the replay command needs the same normalized-event semantics but must not write a second raw webhook row or depend on the original signed bytes. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/provider.ex]

**Example:**
```elixir
# Source: local pattern from lib/mailglass/webhook/ingest.ex
multi =
  Ecto.Multi.new()
  |> Mailglass.Events.append_multi(:replay_requested, requested_attrs)
  |> Mailglass.Webhook.Ingest.append_events_for_each(events, provider, tenant_id)
  |> Mailglass.Webhook.Ingest.update_projections_for_each(events)
```
[ASSUMED]

### Pattern 3: Ledger-Backed Replay History Read Model

**What:** Render replay history by querying `mailglass_events` for replay-specific event types and metadata rather than reading mutable webhook row flags. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/operator/timeline.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

**When to use:** Use for the detail pane timeline and any dedicated replay-history subsection or filter. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

**Example:**
```elixir
# Source: local pattern from lib/mailglass/operator/timeline.ex
Event
|> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
|> where([event], event.type in ^[:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed])
|> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
```
[ASSUMED]

### Anti-Patterns to Avoid

- **Replay by `delivery_id` alone:** The phase decisions lock replay identity to a raw webhook row, so a delivery-only command would guess across multiple webhook candidates. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]
- **Mount-time auth only:** LiveView security guidance and the existing auth seam both require server-side checks at action time for destructive operations. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- **Calling `Mailglass.Webhook.Ingest.ingest_multi/3` with the same raw row and expecting work to happen:** its first write path is protected by `UNIQUE(provider, provider_event_id)`, so duplicate replays are structural no-ops. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs]
- **Treating decoded `raw_payload` as if it were the original signed request bytes:** current persistence preserves the JSON value, not the original signed body. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/provider.ex]
- **Inferring SendGrid raw-webhook identity from child `provider_event_id` equality:** SendGrid raw rows are keyed by body hash, while normalized events get per-element IDs. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex] [VERIFIED: test/mailglass/webhook/providers/sendgrid_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recent-auth freshness | Ad hoc time comparisons scattered across LiveView handlers | `MailglassAdmin.Auth.authorize/3` with `:destructive_action` | The seam already normalizes `recent_auth_at` and exposes `:stale_auth` as a first-class result. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| Tenant scoping | Manual `where tenant_id = ...` duplicated in UI code | `Mailglass.Tenancy.scope/2` and `Mailglass.Tenancy.with_tenant/2` | The repo already relies on these helpers to keep current-tenant context and scoped queries consistent. [VERIFIED: lib/mailglass/tenancy.ex] |
| Audit durability | Mutable `last_replayed_*` fields as truth | `Mailglass.Events.append/1` / `append_multi/3` | The ledger is append-only, trigger-protected, and already used for operator timeline history. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex] |
| Replay dedupe for queued work | Custom replay queue bookkeeping | Oban unique jobs, if async is added later | Oban already exists as the project’s optional dedupe primitive. [VERIFIED: lib/mailglass/optional_deps/oban.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Delivery-to-webhook lookup | Inline JSONB scans from LiveView | A core replay-target read model | The current admin LiveView delegates all data access to core operator modules; replay should follow the same seam. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/operator/deliveries.ex] |

**Key insight:** The repo already has strong primitives for auth, tenancy, append-only audit, and event projection; the planning work is mostly about adding the missing identity/read-model seams, not inventing a new replay subsystem. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex]

## Common Pitfalls

### Pitfall 1: Exact-Raw-Body Assumption

**What goes wrong:** The plan promises “re-run verification” from persisted webhook rows, but the stored row no longer contains the exact signed request bytes. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/provider.ex]
**Why it happens:** `parse_raw_payload/1` stores a decoded JSON structure or a fallback `_raw` map for non-JSON input, while provider verifiers accept the original raw body string. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/provider.ex]
**How to avoid:** Treat persisted webhook rows as already-verified evidence for Phase 24 and reuse post-verification normalization/ingest semantics instead of claiming cryptographic re-verification. [VERIFIED: lib/mailglass/webhook/plug.ex] [VERIFIED: lib/mailglass/webhook/provider.ex] [ASSUMED]
**Warning signs:** A proposed replay API takes only `webhook_event.raw_payload` but still calls `verify!/3`. [VERIFIED: lib/mailglass/webhook/provider.ex]

### Pitfall 2: Missing Delivery-to-Raw-Webhook Identity

**What goes wrong:** The detail screen cannot tell the operator which raw webhook row is replayable, or it guesses wrong for multi-event providers. [VERIFIED: lib/mailglass/operator/timeline.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex]
**Why it happens:** `mailglass_events` has no `webhook_event_id`, `mailglass_webhook_events` has no `delivery_id`, and SendGrid uses different identities for raw rows and child events. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex]
**How to avoid:** Reserve explicit Phase 24 work for a durable replay-target resolver or cached link model before building the modal UX. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [ASSUMED]
**Warning signs:** The plan relies on `delivery_id` alone or on equality between timeline `provider_event_id` and raw webhook `provider_event_id` for every provider. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: lib/mailglass/webhook/ingest.ex]

### Pitfall 3: False-Success Replay Semantics

**What goes wrong:** Operators click replay, see “success,” but no domain state changed because the underlying write path hit duplicate/idempotent no-op rules. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs]
**Why it happens:** The existing ingest path explicitly treats duplicate webhook writes as safe no-ops. [VERIFIED: lib/mailglass/webhook/ingest.ex]
**How to avoid:** Make result states explicit in the UI and audit metadata: at minimum `requested`, `succeeded`, `failed`, and a visible duplicate/no-op outcome summary. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [ASSUMED]
**Warning signs:** Flash text says “replayed successfully” without mentioning duplicate/no-op, matched delivery count, or appended audit outcome. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md]

### Pitfall 4: Replay Audit Types Touch a Closed Contract

**What goes wrong:** The implementation adds replay event names casually and misses the places where the closed event-type set is documented and tested. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: docs/api_stability.md]
**Why it happens:** `Mailglass.Events.Event.type` is a closed enum with helper reflectors and documentation cross-checks. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: docs/api_stability.md]
**How to avoid:** Plan replay event-type additions as a contract change that updates schema enum usage, read models, docs, and tests together. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: docs/api_stability.md] [ASSUMED]
**Warning signs:** The plan mentions replay audit rows but never updates `Mailglass.Events.Event.__types__/0`, `docs/api_stability.md`, or timeline rendering. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: docs/api_stability.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/timeline.ex]

## Code Examples

Verified patterns from current sources:

### Action-Time Sensitive Authorization
```elixir
# Source: mailglass_admin/lib/mailglass_admin/auth.ex
case Auth.authorize(module, :destructive_action, context) do
  {:ok, %{actor: actor, assigns: extra_assigns}} -> {:ok, actor, extra_assigns}
  {:error, :stale_auth, details} -> {:error, details}
  {:error, :unauthorized, details} -> {:error, details}
end
```
[VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]

### Append-Only Event Write
```elixir
# Source: lib/mailglass/events.ex
{:ok, event} =
  Mailglass.Events.append(%{
    tenant_id: tenant_id,
    delivery_id: delivery_id,
    type: :reconciled,
    metadata: %{"reconciled_from_event_id" => orphan.id},
    idempotency_key: "reconciled:" <> to_string(orphan.id)
  })
```
[VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/webhook/reconciler.ex]

### Tenant-Scoped Delivery Timeline Query
```elixir
# Source: lib/mailglass/operator/timeline.ex
Event
|> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
|> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
|> Tenancy.scope(tenant_id)
|> Repo.all()
```
[VERIFIED: lib/mailglass/operator/timeline.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mount-only LiveView gating for sensitive actions | Mount plus action-time authorization for sensitive events | LiveView security guidance is current in the official security model; the repo already added a reusable auth seam in Phase 23. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] [VERIFIED: .planning/phases/23-production-admin-mount-and-step-up-auth/23-02-SUMMARY.md] | Phase 24 should call `:destructive_action` inside the replay handler, not just rely on `on_mount`. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| Mutable admin audit columns | Append-only ledger facts plus read models | This repo locked append-only `mailglass_events` and protected it with an immutability trigger before Phase 24. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/events/event.ex] | Replay history should be rendered from ledger events and only optionally mirrored onto mutable tables later. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |
| Broad redelivery or “replay all” controls | Exact target selection per delivery detail context | Current operator tooling guidance from GitHub and Stripe is delivery/event-targeted rather than blanket semantic reprocessing. [CITED: https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks] [CITED: https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB] | Phase 24 should expose one exact raw webhook row, not batch/window replay. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |

**Deprecated/outdated:**
- Blindly trusting client-side confirmation for privileged actions is outdated for LiveView-sensitive flows; the server must enforce authorization in `handle_event/3`. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- Reverse-engineering replayability from the current timeline alone is insufficient for SendGrid batch rows because the stored identities differ. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 24 should stay synchronous unless profiling shows operator-visible latency or retry needs. [ASSUMED] | Summary / Standard Stack | The planner may under-scope queueing, dedupe, or background execution work. |
| A2 | Replay audit should use new internal `Mailglass.Events.Event.type` atoms such as `:webhook_replay_requested`, `:webhook_replay_succeeded`, and `:webhook_replay_failed`. [ASSUMED] | Architecture Patterns / Common Pitfalls | If the maintainer prefers metadata-only audit rows, docs and enum changes will differ materially. |

## Open Questions

1. **How much historical replayability is required on day one?**
   What we know: the current schema has no durable delivery-to-raw-webhook link, and SendGrid batching makes inference especially lossy. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex]
   What's unclear: whether Phase 24 must support old rows already stored under the current schema or only rows ingested after the new resolver/link seam lands. [ASSUMED]
   Recommendation: plan for explicit “replay unavailable” states on unresolved historical rows unless the user explicitly wants a backfill/migration slice in this phase. [ASSUMED]

2. **Should the replay-target resolver be a read model only, or should ingest start writing a durable link for future rows?**
   What we know: today the admin layer delegates data access to core operator modules, and no webhook-to-delivery relation exists. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: lib/mailglass/operator/deliveries.ex] [VERIFIED: lib/mailglass/events/event.ex]
   What's unclear: whether maintainers prefer a cached relation/projection table, a `webhook_event_id` on future event rows, or a best-effort query-only resolver. [ASSUMED]
   Recommendation: plan for a durable future-write link plus a best-effort fallback resolver for pre-existing data; that gives operators predictable behavior without forcing a full backfill into Phase 24. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core and admin test/compile lanes | ✓ [VERIFIED: elixir --version] | 1.19.5 [VERIFIED: elixir --version] | — |
| Mix | Test aliases and package tasks | ✓ [VERIFIED: mix --version] | 1.19.5 [VERIFIED: mix --version] | — |
| PostgreSQL | Operator/read-model and webhook replay tests | ✓ [VERIFIED: pg_isready] | client 14.17 [VERIFIED: psql --version] | — |
| `mailglass_admin` test config | LiveView/admin verification lane | ✓ [VERIFIED: mailglass_admin/config/test.exs] | present [VERIFIED: mailglass_admin/config/test.exs] | — |
| Oban optional dep | Only if later plans choose queued replay | ✓ [VERIFIED: mix.lock] | 2.21.1 [VERIFIED: mix.lock] | Stay synchronous. [ASSUMED] |

**Missing dependencies with no fallback:**
- None found in this workspace for planning or verification. [VERIFIED: pg_isready] [VERIFIED: mix --version]

**Missing dependencies with fallback:**
- None for the default synchronous path. [VERIFIED: lib/mailglass/optional_deps/oban.ex]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5, split across the root app and the sibling `mailglass_admin` package. [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs] [VERIFIED: mix --version] |
| Config file | none dedicated; test support lives in `test/support/` and `mailglass_admin/test/support/`. [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs] |
| Quick run command | `mix test test/mailglass/operator/timeline_test.exs test/mailglass/webhook/ingest_test.exs --warnings-as-errors` from repo root. [VERIFIED: test/mailglass/operator/timeline_test.exs] [VERIFIED: test/mailglass/webhook/ingest_test.exs] [VERIFIED: command output 2026-05-01] |
| Full suite command | `mix test --warnings-as-errors` from repo root, plus `mix test --warnings-as-errors` inside `mailglass_admin/` for sibling-package coverage. [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs] [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPLAY-01 | Delivery detail screen surfaces replay CTA, target selection rules, and in-place modal/result UX. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] | LiveView | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ existing file for expansion [VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs] |
| REPLAY-02 | Replay writes durable audit facts visible in timeline/history. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mailglass/events.ex] | unit + integration | `mix test test/mailglass/operator/timeline_test.exs test/mailglass/webhook/replay_test.exs --warnings-as-errors` | ❌ `test/mailglass/webhook/replay_test.exs` is a Wave 0 gap [VERIFIED: test/mailglass/operator/timeline_test.exs] [ASSUMED] |
| REPLAY-03 | Replay enforces tenant scope, action-time auth, and safe no-op/duplicate semantics. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] | unit + integration | `mix test test/mailglass/webhook/ingest_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/auth_test.exs --warnings-as-errors` | ✅ files exist [VERIFIED: test/mailglass/webhook/ingest_test.exs] [VERIFIED: mailglass_admin/test/mailglass_admin/auth_test.exs] |

### Sampling Rate

- **Per task commit:** Run the narrow core or admin lane that matches the edited seam. [VERIFIED: command output 2026-05-01]
- **Per wave merge:** Run the root replay-core lane and the `mailglass_admin/` LiveView lane together. [VERIFIED: command output 2026-05-01]
- **Phase gate:** Both packages’ relevant tests should pass before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps

- [ ] `test/mailglass/webhook/replay_test.exs` — canonical replay command coverage for tenant scope, duplicate/no-op outcome, and audit events. [ASSUMED]
- [ ] `test/mailglass/operator/replay_targets_test.exs` — delivery-to-raw-webhook resolver coverage, especially SendGrid ambiguity cases. [ASSUMED]
- [ ] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` expansions — modal rendering, stale-auth branch, and durable replay result visibility. [VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs]
- [ ] `test/mailglass/operator/timeline_test.exs` expansions — replay audit rows appear in chronological order and remain tenant-scoped. [VERIFIED: test/mailglass/operator/timeline_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] | Adopter-owned auth via `MailglassAdmin.Auth.authorize/3`. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| V3 Session Management | yes [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] | Operator session whitelist plus normalized `recent_auth_at`. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| V4 Access Control | yes [VERIFIED: lib/mailglass/tenancy.ex] | Tenant-scoped queries and action-time `:destructive_action` checks. [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] |
| V5 Input Validation | yes [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: lib/mailglass/events/event.ex] | Ecto changesets and explicit param normalization in LiveView. [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] |
| V6 Cryptography | partial [VERIFIED: lib/mailglass/webhook/provider.ex] | Phase 24 should reuse existing verified-provider boundaries and not introduce new crypto. [VERIFIED: lib/mailglass/webhook/provider.ex] [ASSUMED] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant replay by guessed webhook UUID | Elevation of Privilege | Require `tenant_id`, scope before lookup, and never expose an unscoped command. [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] [VERIFIED: lib/mailglass/tenancy.ex] |
| Stale privileged session replay | Elevation of Privilege | Re-check `:destructive_action` in the LiveView event handler or command path. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Audit repudiation | Repudiation | Append replay-requested/succeeded/failed facts to `mailglass_events`; do not rely on flash or mutable row fields. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: .planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md] |
| PII leakage in replay status or telemetry | Information Disclosure | Keep metadata to actor IDs, webhook IDs, tenant IDs, and outcome atoms; never log payload bodies or recipients. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/webhook/telemetry.ex] |
| Duplicate background replay execution | Denial of Service / Integrity | If async is introduced later, use Oban uniqueness instead of custom dedupe state. [VERIFIED: lib/mailglass/optional_deps/oban.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html] |

## Sources

### Primary (HIGH confidence)

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - current operator detail UX, LiveView state model, and likely replay UI seam. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]
- `mailglass_admin/lib/mailglass_admin/auth.ex` - existing `:destructive_action` auth contract. [VERIFIED: mailglass_admin/lib/mailglass_admin/auth.ex]
- `lib/mailglass/webhook/ingest.ex` - current webhook ingest semantics, duplicate handling, and raw payload storage behavior. [VERIFIED: lib/mailglass/webhook/ingest.ex]
- `lib/mailglass/webhook/provider.ex` - verification and normalization contracts. [VERIFIED: lib/mailglass/webhook/provider.ex]
- `lib/mailglass/events.ex` and `lib/mailglass/events/event.ex` - append-only audit primitives and closed event-type contract. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/events/event.ex]
- `lib/mailglass/tenancy.ex` - tenant scoping and tenant-context helpers. [VERIFIED: lib/mailglass/tenancy.ex]
- `mix.lock`, `mix.exs`, `mailglass_admin/mix.exs`, and passing test commands from 2026-05-01 - dependency and verification facts. [VERIFIED: mix.lock] [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/mix.exs] [VERIFIED: command output 2026-05-01]

### Secondary (MEDIUM confidence)

- Phoenix LiveView security model - confirms server-side event authorization expectations for sensitive actions. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- GitHub webhook redelivery docs - supports exact-delivery replay UX precedent. [CITED: https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks]
- Stripe “process undelivered events” docs - supports idempotent targeted recovery semantics rather than blanket semantic rebuilds. [CITED: https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB]
- Oban unique jobs docs - supports dedupe if the planner later chooses async replay. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

### Tertiary (LOW confidence)

- None. [VERIFIED: web research 2026-05-01]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended libraries and versions are already locked in the repo and confirmed locally. [VERIFIED: mix.lock] [VERIFIED: mix deps]
- Architecture: MEDIUM - the repo seams are clear, but the phase still needs a new delivery-to-raw-webhook identity strategy and a decision about how much historical replayability to guarantee. [VERIFIED: lib/mailglass/events/event.ex] [VERIFIED: lib/mailglass/webhook/webhook_event.ex] [ASSUMED]
- Pitfalls: HIGH - the sharp edges are directly visible in current code and tests. [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: test/mailglass/webhook/ingest_test.exs] [VERIFIED: lib/mailglass/webhook/providers/sendgrid.ex]

**Research date:** 2026-05-01
**Valid until:** 2026-05-31
