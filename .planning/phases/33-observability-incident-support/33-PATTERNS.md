# Phase 33: Observability & Incident Support - Pattern Map

**Mapped:** 2026-05-05
**Focus:** delivery-centric support cues, replay/reconcile wording, telemetry-safe observability, operator-facing tests

## Reusable Assets

| Asset | Role | Why reuse it for Phase 33 |
|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | LiveView shell + data loader | Canonical operator surface. URL-backed filter state, selected-delivery detail loading, flash handling, and component composition already exist. |
| `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | delivery support card | Current summary card for delivery identity, provider facts, and replay availability copy. Safest place for support-oriented header cues. |
| `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` | audit/event renderer | Already separates lifecycle facts from replay audit facts and renders metadata summaries chronologically. |
| `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` | wording/presenter seam | Shared labels for replay availability, outcomes, effects, and operator flash copy. Extend this before inventing new support copy elsewhere. |
| `mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex` | action-time auth seam | Canonical seam for any support-sensitive manual action. Phase 33 support cues should stay read-only unless routed through this seam. |
| `lib/mailglass/operator/deliveries.ex` | read model | Tenant-scoped delivery list backing the support entrypoint. |
| `lib/mailglass/operator/timeline.ex` | read model | Append-only delivery timeline source for support evidence. |
| `lib/mailglass/operator/replay_history.ex` | read model | Exact replay audit history source. Reuse for replay outcome summaries instead of recomputing from raw events. |
| `lib/mailglass/webhook/telemetry.ex` | webhook telemetry contract | Canonical whitelist-safe observability surface for webhook ingest, orphan, duplicate, and reconcile signals. |
| `lib/mailglass/telemetry.ex` | global telemetry policy | Naming convention, allowed metadata posture, and logger attachment pattern. |
| `lib/mailglass/webhook/reconciler.ex` | reconcile/backlog engine | Canonical backlog semantics: grace window, append-only `:reconciled` fact, telemetry counters, logger warnings. |
| `lib/mix/tasks/mailglass.reconcile.ex` | operator CLI fallback | Honest maintenance fallback for adopters without Oban; safest support docs seam for “run reconcile now”. |

## Established Patterns

### 1. Operator support cards stay delivery-centric and URL-backed

**Source:** [operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:65), [operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:386)

- Keep selection and filters in params via `handle_params/3` + `push_patch`, not ephemeral state.
- Load all detail-side support data from read models inside `assign_delivery_state/3`.
- Render support cards only when `@selected_delivery` exists; otherwise show honest empty/error states.

```elixir
# mailglass_admin/lib/mailglass_admin/operator_live.ex:65-75
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)

  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator")
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))
   |> assign_delivery_state(filter_params, blank_to_nil(params["delivery_id"]))
   |> close_replay_modal()}
end
```

```elixir
# mailglass_admin/lib/mailglass_admin/operator_live.ex:386-403
defp assign_delivery_state(socket, filter_params, selected_delivery_id) do
  deliveries = load_deliveries(filter_params)
  selected_delivery = find_selected_delivery(deliveries, selected_delivery_id)
  replay_targets = load_replay_targets(filter_params, selected_delivery)
  replay_history = load_replay_history(filter_params, selected_delivery)

  socket
  |> assign(:deliveries, deliveries)
  |> assign(:selected_delivery, selected_delivery)
  |> assign(:timeline_events, load_timeline(filter_params, selected_delivery))
  |> assign(:suppression_state, load_suppression(filter_params, selected_delivery))
  |> assign(:detail_error, detail_error_for(selected_delivery_id, selected_delivery))
  |> assign(:replay_targets, replay_targets)
  |> assign(:replay_history, replay_history)
end
```

**Planner reuse:** add new support indicators as additional read-only assigns loaded beside `:timeline_events`, `:suppression_state`, and `:replay_history`, not as a separate dashboard LiveView.

### 2. Support header copy should summarize durable facts, then expose exact repair status

**Source:** [detail_header.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:16), [repair_state.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:34)

- Header cards use `dl` facts and a short action/status strip.
- Replay/support wording is delegated to `RepairState`, not inlined.
- “Last replay” is a durable audit summary, not inferred transient UI state.

```elixir
# mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:31-55
<dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
  <div>
    <dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
    <dd class="mt-1 text-base-content">{@delivery.tenant_id}</dd>
  </div>
  <div>
    <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider</dt>
    <dd class="mt-1 text-base-content">{String.upcase(@delivery.provider || "unknown")}</dd>
  </div>
  <div>
    <dt class="text-xs font-bold uppercase tracking-[0.08em]">Latest event</dt>
    <dd class="mt-1 text-base-content">{label(@delivery.last_event_type)}</dd>
  </div>
</dl>
```

```elixir
# mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:59-75
<div class="mt-6 flex flex-wrap items-start justify-between gap-4 border-t border-base-300 pt-4">
  <div class="space-y-1">
    <h3 class="text-sm font-bold uppercase tracking-[0.08em] text-secondary">Webhook replay</h3>
    <p class="text-sm text-base-content">{RepairState.availability_hint(@replay_targets)}</p>
    <p :if={@latest_replay} class="text-xs text-secondary">
      Last replay: {RepairState.latest_replay_summary(@latest_replay)} at {format_datetime(@latest_replay.occurred_at)}
    </p>
  </div>
</div>
```

**Planner reuse:** new support cards should follow this shape: exact fact labels, durable audit summary, and presenter-owned wording.

### 3. Timeline and audit facts keep lifecycle, replay, and reconcile distinct

**Source:** [timeline.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/timeline.ex:25), [repair_state.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:14), [reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:161)

- Timeline order is chronological ascending, not “latest first”.
- Replay facts get explicit labels and badges.
- Outcome wording is fixed to `requested`, `completed`, `failed`; effect wording is `new work` / `no change`.
- Reconcile writes a distinct append-only `:reconciled` event with provenance fields; do not flatten reconcile into replay.

```elixir
# mailglass_admin/lib/mailglass_admin/operator/timeline.ex:35-44
<div class="flex flex-wrap items-center gap-2">
  <p class="text-sm font-bold text-base-content">{event_label(event.type)}</p>
  <span :if={replay_event?(event.type)} class="badge badge-outline badge-error">
    Replay audit
  </span>
</div>
<p class="text-xs text-secondary">{metadata_summary(event.metadata)}</p>
<p :if={event.reject_reason} class="text-sm text-secondary">
  Reason: {label(event.reject_reason)}
</p>
```

```elixir
# mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:17-32
def outcome_label(:webhook_replay_requested), do: "requested"
def outcome_label(:webhook_replay_succeeded), do: "completed"
def outcome_label(:webhook_replay_failed), do: "failed"

def effect_label(:replayed), do: "new work"
def effect_label(:noop), do: "no change"
```

```elixir
# lib/mailglass/webhook/reconciler.ex:161-170
reconciled_attrs = %{
  type: :reconciled,
  delivery_id: delivery.id,
  tenant_id: orphan.tenant_id,
  metadata: %{
    "reconciled_from_event_id" => orphan.id,
    "reconciled_provider" => extract_provider(orphan),
    "reconciled_provider_event_id" => extract_provider_event_id(orphan)
  },
  idempotency_key: "reconciled:" <> to_string(orphan.id),
  occurred_at: Clock.utc_now()
}
```

**Planner reuse:** Phase 33 support cues should explicitly bucket evidence into provider lifecycle facts, replay audit facts, and reconcile facts using those existing nouns and labels.

### 4. Read models are tenant-scoped, narrow, and projection-friendly

**Source:** [deliveries.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/deliveries.ex:17), [timeline.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/timeline.ex:16), [replay_history.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/replay_history.ex:15)

- Read models require `tenant_id`.
- They select only the fields the operator UI needs.
- Replay history extracts operator-facing audit fields from JSON metadata in SQL instead of post-processing the whole event payload.

```elixir
# lib/mailglass/operator/deliveries.ex:23-49
Delivery
|> where([delivery], delivery.tenant_id == ^tenant_id)
|> maybe_filter_provider(normalized[:provider])
|> maybe_filter_status(normalized[:status])
|> maybe_filter_event(normalized[:event] || normalized[:last_event_type])
|> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
|> order_by([delivery], desc: delivery.last_event_at, desc: delivery.inserted_at, desc: delivery.id)
|> select([delivery], %{id: delivery.id, tenant_id: delivery.tenant_id, ...})
|> Tenancy.scope(tenant_id)
|> Repo.all()
```

```elixir
# lib/mailglass/operator/replay_history.ex:21-40
Event
|> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
|> where([event], event.type in ^@replay_types)
|> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
|> select([event], %{
  actor_id: fragment("?->>'actor_id'", event.metadata),
  webhook_event_id: fragment("?->>'webhook_event_id'", event.metadata),
  provider: fragment("?->>'provider'", event.metadata),
  outcome: fragment("?->>'outcome'", event.metadata),
  failure_reason: fragment("?->>'failure_reason'", event.metadata),
  metadata: event.metadata
})
```

**Planner reuse:** if Phase 33 needs new support cues, prefer adding narrow read-model queries or metadata projections here rather than parsing raw payloads in LiveView.

### 5. Telemetry additions must go through named helper modules and obey the whitelist

**Source:** [webhook/telemetry.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/telemetry.ex:12), [webhook/telemetry.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/telemetry.ex:51), [telemetry.ex](/Users/jon/projects/mailglass/lib/mailglass/telemetry.ex:25)

- Event naming stays `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]`.
- Webhook-specific emits live in `Mailglass.Webhook.Telemetry`, not scattered call sites.
- Stop metadata is counts/statuses/IDs only. No PII and no raw payload/body.
- When stop metadata depends on runtime outcome, use the local `span_with_enrichment/3` pattern.

```elixir
# lib/mailglass/webhook/telemetry.ex:16-21
| `[:mailglass, :webhook, :ingest, :start | :stop | :exception]` | full span | `provider, tenant_id, status, event_count, duplicate, failure_reason, delivery_id_matched` |
| `[:mailglass, :webhook, :signature, :verify, :start | :stop | :exception]` | full span | `provider, status, failure_reason` |
| `[:mailglass, :webhook, :normalize, :stop]` | single emit | `provider, event_type, mapped` |
| `[:mailglass, :webhook, :orphan, :stop]` | single emit | `provider, event_type, tenant_id, age_seconds` |
| `[:mailglass, :webhook, :duplicate, :stop]` | single emit | `provider, event_type` |
| `[:mailglass, :webhook, :reconcile, :start | :stop | :exception]` | full span | `tenant_id, scanned_count, linked_count, remaining_orphan_count, status` |
```

```elixir
# lib/mailglass/webhook/telemetry.ex:53-59
**NEVER include in any metadata map:**

  * `:ip`, `:remote_ip`, `:user_agent`
  * `:to`, `:from`, `:subject`, `:body`, `:html_body`, `:headers`,
    `:recipient`, `:email`
  * `:raw_payload`, `:raw_body`
```

```elixir
# lib/mailglass/telemetry.ex:27-32
**Whitelisted keys:** `:tenant_id, :mailable, :provider, :status,
:message_id, :delivery_id, :event_id, :latency_ms, :recipient_count,
:bytes, :retry_count`.

**Forbidden (PII):** `:to, :from, :body, :html_body, :subject, :headers,
:recipient, :email`.
```

**Planner reuse:** any new support cue based on telemetry should either consume existing webhook events or add a named helper in `Mailglass.Webhook.Telemetry`; do not add ad hoc `:telemetry.execute/3` calls directly in UI code.

### 6. Reconcile/backlog support follows one canonical sweep story

**Source:** [reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:87), [mix/tasks/mailglass.reconcile.ex](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.reconcile.ex:41)

- `reconcile/2` is the single application-layer sweep used by both Oban and the CLI.
- Backlog semantics are counts-based: `scanned`, `linked`, `remaining_orphan_count`.
- Non-match is not failure; it stays unmatched for a later sweep.
- Manual support docs should point to `mix mailglass.reconcile` as the fallback, not invent a new admin-side repair control.

```elixir
# lib/mailglass/webhook/reconciler.ex:99-142
WebhookTelemetry.reconcile_span(
  %{tenant_id: tenant_id},
  fn ->
    orphans =
      EventsReconciler.find_orphans(
        tenant_id: tenant_id,
        limit: limit,
        max_age_minutes: @max_age_minutes
      )
      |> Enum.filter(&past_grace?/1)

    {linked, _failed} =
      Enum.reduce(orphans, {0, 0}, fn orphan, {ok, err} ->
        case attempt_reconcile(orphan) do
          {:ok, _} -> {ok + 1, err}
          {:error, :no_match} -> {ok, err}
          {:error, reason} -> ...
        end
      end)
```

```elixir
# lib/mix/tasks/mailglass.reconcile.ex:52-69
reconciler = reconciler_module()

{:ok, %{scanned: scanned, linked: linked}} =
  reconciler.reconcile(tenant_id, batch_size)

still_unmatched = max(scanned - linked, 0)

Mix.shell().info(
  "Reconcile complete: scanned=#{scanned} linked=#{linked} still_unmatched=#{still_unmatched}" <>
    if(tenant_id, do: " tenant=#{tenant_id}", else: "") <>
    " " <> scheduler_note
)
```

**Planner reuse:** summary cues like orphan count, still-unmatched, and reconcile-linked outcomes should derive from this canonical sweep language.

## Integration Seams

### Safest seams for Phase 33 UI work

- [mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:227)
  Use the detail column below `DetailHeader` and before/after `Timeline` for new read-only support cards.
- [mailglass_admin/lib/mailglass_admin/operator/detail_header.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:59)
  Best seam for selected-delivery support identity and latest support summary.
- [mailglass_admin/lib/mailglass_admin/operator/repair_state.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:34)
  Best seam for consistent copy around replay, “no change”, “new work”, and future reconcile-support labels.
- [mailglass_admin/lib/mailglass_admin/operator/timeline.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/timeline.ex:66)
  Best seam for distinguishing support event categories without changing the underlying read model contract.

### Safest seams for support data

- [lib/mailglass/operator/replay_history.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/replay_history.ex:21)
  First choice for replay outcome cards and exemplar rows.
- [lib/mailglass/operator/timeline.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/timeline.ex:23)
  First choice for durable audit evidence shown on a delivery.
- [lib/mailglass/operator/deliveries.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/deliveries.ex:23)
  First choice for expanding list/detail summary facts without changing event storage semantics.
- [lib/mailglass/webhook/reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:101)
  Canonical seam for backlog/reconcile counters and exact reconcile semantics.
- [lib/mailglass/webhook/telemetry.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/telemetry.ex:82)
  Canonical seam for any new support-facing telemetry helper.

### Do not use as primary seam

- Raw webhook payload fields in UI code. Existing patterns favor read models and projected metadata, not payload inspection in LiveView.
- New mutable “incident state” storage. Existing seams are append-only events, telemetry, and read-only projections.
- New destructive UI actions. Current support posture keeps manual repair limited to exact replay via [destructive_action.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex:15).

## Testing Hooks

### LiveView operator tests to copy

**Source:** [operator_live_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:16)

- Mount with `operator_conn/2` and tenant-scoped params.
- Assert `data-testid` markers and exact support copy.
- Exercise selection through button clicks and URL patch assertions.
- For replay/support actions, assert both UI text and durable database side effects.

```elixir
# mailglass_admin/test/mailglass_admin/operator_live_test.exs:128-160
{:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

view
|> element("button[phx-value-id='#{delivery.id}']")
|> render_click()

assert_patch(view, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id, "window_hours" => "168"}))

html = render(view)
assert html =~ "Event timeline"
assert html =~ ~s(data-testid="operator-detail-header")
assert html =~ ~s(data-testid="operator-timeline")
assert html =~ "Webhook replay"
```

```elixir
# mailglass_admin/test/mailglass_admin/operator_live_test.exs:344-368
view
|> element("[data-testid='operator-replay-confirm']")
|> render_click()

html = render(view)

assert html =~ "Replay completed with new work."
assert html =~ "Webhook replay requested"
assert html =~ "Webhook replay completed"
assert html =~ "Last replay: completed · new work"
```

### Read-model tests to copy

**Source:** [timeline_test.exs](/Users/jon/projects/mailglass/test/mailglass/operator/timeline_test.exs:8)

- Build fixtures with real `Events.append/1`.
- Assert tenant scoping, delivery scoping, and chronological ordering.
- Keep replay audit rows distinct and assert exact summary language.

```elixir
# test/mailglass/operator/timeline_test.exs:141-145
rows = Timeline.list_delivery_events(%{tenant_id: "tenant-a", delivery_id: delivery.id}, [])

assert Enum.map(rows, & &1.type) == [:webhook_replay_requested, :webhook_replay_succeeded]
assert Enum.map(rows, &replay_summary_for(&1)) == ["requested", "completed · no change"]
assert Enum.all?(rows, &Map.has_key?(&1.metadata, "webhook_event_id"))
```

### Replay/reconcile durability tests to copy

**Source:** [replay_test.exs](/Users/jon/projects/mailglass/test/mailglass/webhook/replay_test.exs:11)

- Assert durable audit rows, not just returned status tuples.
- Check `requested_audit_event_id`, `actor_id`, `webhook_event_id`, and `outcome` fields explicitly.
- Keep separate coverage for `:replayed`, `:noop`, tenant mismatch, and failure paths.

```elixir
# test/mailglass/webhook/replay_test.exs:52-61
[requested] = replay_events_for(webhook_event.id, :webhook_replay_requested)
[succeeded] = replay_events_for(webhook_event.id, :webhook_replay_succeeded)

assert requested.metadata["actor_id"] == "operator-1"
assert requested.metadata["webhook_event_id"] == webhook_event.id
assert succeeded.metadata["actor_id"] == "operator-1"
assert succeeded.metadata["outcome"] == "replayed"
assert succeeded.metadata["requested_audit_event_id"] == requested.id
```

## Phase 33 Guidance Summary

- Start from the selected delivery, not a fleet dashboard.
- Reuse `RepairState` for operator wording before adding new copy.
- Keep replay, reconcile, and provider lifecycle as distinct evidence streams.
- Add support cues through read models and telemetry helpers, not raw payload access.
- Respect the telemetry whitelist structurally: counts, statuses, IDs, latencies only; never PII or payload content.
