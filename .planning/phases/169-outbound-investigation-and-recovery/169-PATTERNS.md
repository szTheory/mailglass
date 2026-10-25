# Phase 169: Outbound Investigation and Recovery - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 14 likely implementation/test files  
**Analogs found:** 14 / 14

Scope is inferred from CONTEXT D-01–26, RESEARCH architecture/code examples, and UI-SPEC. Every named analog below was checked with `git ls-files`; no ignored runtime mirror paths are used. No root `AGENTS.md` or project skill directories with `SKILL.md` files were found.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | controller / LiveView | request-response, event-driven | same file | exact |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component | request-response | same file | exact |
| `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` | utility / presenter | transform | same file | exact |
| `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` | component | request-response | same file | exact |
| `mailglass_admin/lib/mailglass_admin/components.ex` | component | transform / request-response | same file | exact |
| `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | controller / config | request-response | same file; `mailglass_admin/e2e/flows.spec.js` for hook behavior | role-match |
| `lib/mailglass/operator/deliveries.ex` | service / read model | CRUD (read) | same file | exact |
| `lib/mailglass/operator/timeline.ex` | service / read model | CRUD (read) | same file | exact |
| `lib/mailglass/operator/support_summary.ex` | service / read model | batch/aggregate read | same file | exact |
| `lib/mailglass/operator/suppressions.ex` | service / read model | CRUD (read) | same file; `lib/mailglass/suppression.ex` for removal rules | exact |
| `lib/mailglass/operator/replay_targets.ex` | service / read model | request-response | same file | exact |
| `lib/mailglass/operator/replay_history.ex` | service / read model | CRUD (read) | same module used by `operator_live.ex` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs`, `test/mailglass/operator/{deliveries,timeline,support_summary,suppressions,replay_targets}_test.exs` | test | request-response | same test files | exact |
| `mailglass_admin/e2e/flows.spec.js`, `mailglass_admin/test/support/operator_browser_server.ex` | test / fixture | request-response | same browser harness | exact |

Some source seams are explicitly named in CONTEXT but are conditional on implementation scope: `mailglass_admin/lib/mailglass_admin/operator/timeline.ex`, `support_cards.ex`, `suppression_card.ex`, `detail_header.ex`, `quick_view.ex`, `filters_form.ex`, `mailglass_admin/assets/css/app.css`, and `lib/mailglass/webhook/replay.ex`. Reuse their existing composition and behavior if touched; do not expand scope solely because they are listed here.

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (LiveView, request-response / event-driven)

**Analog:** same file; tracked.

**URL-owned state** (`handle_params/3`, lines 113–180): normalize filters and support IDs first, derive selected Account and URL-requested delivery identity, then assign state and read/render the selected surface. Keep same-view transitions URL-backed so `handle_params` is the source of truth. The current implementation assigns `delivery_id` from params, but `assign_delivery_state/5` searches only page entries (lines 1134–1138); preserve the requested ID separately and use the core exact Account+ID read when adding independent selection.

```elixir
{filter_params, filter_errors} = normalize_filter_params_with_errors(params)
support_state = normalize_support_state(params)
delivery_id = blank_to_nil(params["delivery_id"])
full? = params["full"] == "1" and not is_nil(delivery_id)
...
|> assign_delivery_state(filter_params, delivery_id, full?, support_focus?(support_state))
```

**Read-state seam** (lines 1134–1167, 1169–1198): currently loads list and evidence as separate helper calls, but collapses read failure in overview into `nil`. Follow this decomposition while introducing explicit per-panel outcomes; keep unrelated panels assigned when one call fails. `ReplayTargets` currently has an explicit `{:ok, targets}` / `{:error, ...}` mapping in `load_replay_targets/2` (lines 1105–1127).

**Replay action and auth** (lines 427–477): current order selects cached target, invokes `DestructiveAction.authorize/5`, then calls `Replay.execute/1`; preserve host action-time auth and selected Account context. Phase decision requires replacing cached-target trust with same-ID re-resolution and review-fact comparison before that authorization, plus consumed/open-review guard.

**Support selection** (lines 1525–1559): normalize exact `support_event_id` / `support_webhook_event_id` separately from focus category and serialize them into URL params. Keep these IDs stable through refresh and resolve them by selected Account; do not replace with moving latest/oldest examples.

### `lib/mailglass/operator/deliveries.ex` (read model, request-response)

**Analog:** same file; tracked.

**Account-scoped query pattern** (`list_recent_deliveries_page/2`, around lines 48–100): normalize filters, require tenant ID, add explicit `delivery.tenant_id == ^tenant_id`, apply optional filters, call `Tenancy.scope(tenant_id)`, project allowlisted columns, and return deterministic page metadata. Preserve the public list/page return contract. Add exact-selection as a narrow, separately scoped internal read rather than broadening list semantics.

```elixir
Delivery
|> where([delivery], delivery.tenant_id == ^tenant_id)
|> maybe_filter_provider(normalized[:provider])
|> maybe_filter_event(normalized[:event] || normalized[:last_event_type])
|> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
|> Tenancy.scope(tenant_id)
```

### `lib/mailglass/operator/timeline.ex` (read model, request-response)

**Analog:** same file; tracked.

**Bounded history pattern** (lines 10–40): require Account and delivery IDs, constrain by both IDs, order by `(occurred_at, inserted_at, id)`, select an explicit projection, apply a capped limit, then tenancy scope. UI-SPEC calls for `limit: 101` as overflow sentinel while rendering the first 100. Exact selected-event lookup should use the same Account predicate/projection style and must not imply that absence from the 100-row slice means not found.

```elixir
Event
|> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
|> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
|> limit(^limit)
|> select([event], %{id: event.id, tenant_id: event.tenant_id, delivery_id: event.delivery_id, type: event.type})
|> Tenancy.scope(tenant_id)
|> Repo.all()
```

### `lib/mailglass/operator/support_summary.ex` (read model, batch/aggregate)

**Analog:** same file; tracked.

Each support population has its own query and projection: failed webhook rows by `received_at`, unresolved orphan events by event time, and replay/reconcile audit facts by explicit event types. Counts and exemplars are independently scoped through `Tenancy.scope(tenant_id)`. Preserve population semantics and expose exact selected reads separately from exemplar fields; Admin should turn read errors into per-panel states rather than a whole-summary nil.

```elixir
from(webhook_event in WebhookEvent,
  where: webhook_event.tenant_id == ^tenant_id,
  where: webhook_event.status in ^@failed_ingest_statuses,
  where: webhook_event.received_at >= ^window_started_at
)
```

### `lib/mailglass/operator/suppressions.ex` and `lib/mailglass/suppression.ex` (read model / command rules)

**Analogs:** both tracked. `Suppressions.get_delivery_suppression_state/2` selects one current matching Ecto record, scoped to Account, unexpired, ordered address+stream → address → domain and recency (lines 18–52). `Mailglass.Suppression.remove/2` is authoritative for public removal policy (around lines 98–131): complaint/unsubscribe are rejected, while policy is removable. Keep “no matching record” distinct from query failure and do not imply the Ecto record read represents configured provider/store policy.

### `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` and `repair_state.ex` (component / presenter)

**Analogs:** same tracked files.

The modal already has zero/one/many target render branches, radio selection for ambiguity, explicit candidate identity/provider/time/linkage, focus sentinels and `phx-disable-with` pending feedback (`replay_modal.ex:1–130`). Extend these interfaces for frozen review identity and accurate consequences. Current copy says “Mailbox routing” and one candidate confirms without an explicit selected ID; correct copy and bind confirmation to the actual reviewed ID. `RepairState` centralizes availability/outcome/effect labels and fallback copy; use it for consistent status wording, updating “requested” semantics to avoid treating requested as completed.

```elixir
<div id="operator-replay-modal" role="dialog" aria-modal="true"
     aria-labelledby="replay-modal-title" phx-hook="ModalFocusTrap">
...
<button id="operator-replay-confirm" phx-click={JS.push("confirm_replay")}
        phx-disable-with="Replaying…">
  Confirm replay
</button>
```

### `mailglass_admin/lib/mailglass_admin/components.ex`, `operator/deliveries_list.ex`, `controllers/assets.ex` (shared UI / assets)

**Analogs:** same tracked files.

Use shared component APIs for `data_state`, stat cards, status and timestamp/copy controls; source accepts state tags such as `:ready`, `:empty`, `:loading`, `:unavailable` (`components.ex:428–515`). Keep semantic native table/card behavior in `DeliveriesList`; use explicit links/buttons rather than ARIA grid. `controllers/assets.ex` is the integration point for existing JS hooks; do not add a parallel focus/copy system. `mailglass_admin/e2e/flows.spec.js:321–331, 835–848` demonstrates existing deep-link missing-ID and dialog focus/pending browser assertions. Browser harness fixture is tracked at `mailglass_admin/test/support/operator_browser_server.ex`.

## Shared Patterns

### Account scope and public query contracts

**Sources:** `lib/mailglass/operator/{deliveries,timeline,support_summary,suppressions,replay_targets}.ex`  
**Apply to:** every core read and exact event/webhook/delivery lookup. Require selected Account ID, retain explicit tenant predicate plus `Tenancy.scope(tenant_id)`, use narrow projections, and do not use activity-derived Account options as authorization.

### URL selection and read outcomes

**Source:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`  
**Apply to:** list/detail/support navigation and all panel reads. URL is canonical; selected object IDs remain independent of list membership. Distinguish zero/empty/unavailable/stale/partial states and preserve other panel results on an individual failure.

### Replay review

**Sources:** `operator_live.ex`, `operator/replay_modal.ex`, `operator/repair_state.ex`, `lib/mailglass/webhook/replay.ex`  
**Apply to:** replay review and submission. Freeze the chosen webhook ID and reviewed facts; re-read that same candidate in the selected Account and revalidate eligibility/membership before invoking existing host action-time authorization. Never fall through to a replacement target. Keep request/audit status separate from normalized-row effects and delivery outcome.

### Existing test/fixture patterns

**Sources:** `test/mailglass/operator/*_test.exs`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `operator/replay_modal_test.exs`, `mailglass_admin/e2e/flows.spec.js`, `mailglass_admin/test/support/operator_browser_server.ex`  
**Apply to:** coverage added during execution. Core tests establish scoped query boundaries and fixtures; LiveView tests cover URL/filter/read/error/auth/replay behavior; Playwright exercises viewport, focus and pending interaction against its isolated operator fixture. These are reference locations only; no tests were run in this mapping.

## No Analog Found

None among the likely files. New internal exact-read helpers (Delivery by Account+ID, exact Event, exact WebhookEvent) have no known exact helper signature, but should copy the query conventions from the core read models above and remain internal unless API stability review permits otherwise.

## Metadata

**Analog search scope:** `lib/mailglass/operator/`, `lib/mailglass/webhook/`, `lib/mailglass/suppression.ex`, `mailglass_admin/lib/mailglass_admin/`, `test/mailglass/operator/`, `mailglass_admin/test/mailglass_admin/`, `mailglass_admin/e2e/`, and browser support fixtures.  
**Pattern extraction date:** 2026-10-07
