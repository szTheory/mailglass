# Phase 24: tenant-safe-webhook-replay-with-audit-context - Pattern Map

**Mapped:** 2026-05-01  
**Files analyzed:** 13  
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | component | event-driven | `mailglass_admin/lib/mailglass_admin/operator_live.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | component | request-response | `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` | component | request-response | `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component | event-driven | `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex` | role-match |
| `lib/mailglass/operator/replay_targets.ex` | service | request-response | `lib/mailglass/operator/suppressions.ex` | role-match |
| `lib/mailglass/operator/replay_history.ex` | service | CRUD | `lib/mailglass/operator/timeline.ex` | exact |
| `lib/mailglass/webhook/replay.ex` | service | request-response | `lib/mailglass/webhook/ingest.ex` | role-match |
| `lib/mailglass/webhook/ingest.ex` | service | request-response | `lib/mailglass/webhook/ingest.ex` | exact |
| `lib/mailglass/events/event.ex` | model | CRUD | `lib/mailglass/events/event.ex` | exact |
| `test/mailglass/operator/replay_targets_test.exs` | test | request-response | `test/mailglass/operator/suppressions_test.exs` | role-match |
| `test/mailglass/webhook/replay_test.exs` | test | request-response | `test/mailglass/webhook/ingest_test.exs` | role-match |
| `test/mailglass/operator/timeline_test.exs` | test | CRUD | `test/mailglass/operator/timeline_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | test | event-driven | `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | exact |

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (component, event-driven)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`

**Imports and assign shape** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:11-28`)
```elixir
alias Mailglass.Operator.{Deliveries, Suppressions}
alias Mailglass.Operator.Timeline, as: OperatorTimelineData
alias MailglassAdmin.Components
alias MailglassAdmin.Operator.{DeliveriesList, DetailHeader, FiltersForm, SuppressionCard}
alias MailglassAdmin.Operator.Timeline, as: OperatorTimeline

@impl true
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign_new(:operator_actor, fn -> nil end)
   |> assign_new(:operator_auth, fn -> %{status: :unknown, recent_auth?: false} end)
   |> assign(:deliveries, [])
   |> assign(:selected_delivery, nil)
```

**URL-backed detail loading** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:51-67,215-247`)
```elixir
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)
  deliveries = load_deliveries(filter_params)
  selected_delivery_id = blank_to_nil(params["delivery_id"])
  selected_delivery = find_selected_delivery(deliveries, selected_delivery_id)
  detail_error = detail_error_for(selected_delivery_id, selected_delivery)
  timeline_events = load_timeline(filter_params, selected_delivery)
  suppression_state = load_suppression(filter_params, selected_delivery)

  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator")
   |> assign(:deliveries, deliveries)
   |> assign(:selected_delivery, selected_delivery)
   |> assign(:timeline_events, timeline_events)
   |> assign(:suppression_state, suppression_state)}
end
```

**LiveView event wiring pattern** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:73-94`)
```elixir
def handle_event("apply_filters", %{"filters" => filters}, socket) do
  normalized = normalize_filter_params(filters)

  {:noreply,
   push_patch(socket,
     to: build_path(socket.assigns.base_path, normalized, nil)
   )}
end

def handle_event("select_delivery", %{"id" => delivery_id}, socket) do
  {:noreply,
   push_patch(socket,
     to: build_path(socket.assigns.base_path, socket.assigns.filter_params, delivery_id)
   )}
end
```

**Apply to Phase 24:** keep replay state in assigns and drive replay from a server `handle_event/3`; continue to load all operator data through core read-model modules, not direct Repo calls in the LiveView.

---

### `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` (component, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`

**Header card structure** (`mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:8-56`)
```elixir
attr :delivery, :map, required: true

def detail_header(assigns) do
  ~H"""
  <article data-testid="operator-detail-header" class="card rounded-box border border-base-300 bg-base-200 p-6">
    <div class="flex flex-wrap items-start justify-between gap-4">
      <div class="space-y-2">
        <div class="flex flex-wrap items-center gap-2">
          <h2 class="text-xl font-bold text-base-content">{@delivery.recipient}</h2>
          <span class={["badge", badge_class(@delivery.status)]}>
            {label(@delivery.status)}
          </span>
```

**Formatting helpers** (`mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:58-75`)
```elixir
defp badge_class(status) when status in [:delivered, :sent, :dispatched], do: "badge-success"
defp badge_class(:deferred), do: "badge-warning"
defp badge_class(status) when status in [:failed, :bounced, :complained], do: "badge-error"

defp format_datetime(nil), do: "Pending"
defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
```

**Apply to Phase 24:** add the replay CTA and latest replay result badge here; keep it as a pure component receiving already-computed state from `OperatorLive`.

---

### `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` (component, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/timeline.ex`

**Chronological timeline rendering** (`mailglass_admin/lib/mailglass_admin/operator/timeline.ex:10-43`)
```elixir
def timeline(assigns) do
  ~H"""
  <article data-testid="operator-timeline" class="card rounded-box border border-base-300 bg-base-200 p-6">
    <div class="mb-4 flex items-center justify-between gap-3">
      <h3 class="text-base font-bold text-base-content">Event timeline</h3>
      <span class="text-xs text-secondary">Chronological order</span>
    </div>

    <%= if @timeline_events == [] do %>
      <p class="text-sm text-secondary">
        No delivery events have been recorded for this item yet.
      </p>
    <% else %>
```

**Metadata summary pattern** (`mailglass_admin/lib/mailglass_admin/operator/timeline.ex:59-74`)
```elixir
defp metadata_summary(metadata) when is_map(metadata) do
  provider = Map.get(metadata, "provider") || Map.get(metadata, :provider)
  source = Map.get(metadata, "source") || Map.get(metadata, :source)

  [provider, source]
  |> Enum.reject(&(&1 in [nil, ""]))
  |> case do
    [] -> "mailglass ledger"
    values -> Enum.join(values, " · ")
  end
end
```

**Apply to Phase 24:** extend this renderer for replay audit rows instead of creating a second event renderer; replay-specific copy should still derive from event `type` and `metadata`.

---

### `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` (component, event-driven)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex`  
**Secondary analog:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`

**Component/card styling pattern** (`mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:10-44`)
```elixir
def suppression_card(assigns) do
  ~H"""
  <article data-testid="operator-suppression-card" class="card rounded-box border border-base-300 bg-base-200 p-6">
    <div class="mb-4 flex items-center justify-between gap-3">
      <h3 class="text-base font-bold text-base-content">Suppression state</h3>
      <span class="badge badge-outline">
        {headline(@suppression_state)}
      </span>
    </div>
```

**Conditional detail/empty-state pattern** (`mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:20-44`)
```elixir
<%= if @suppression_state do %>
  <div class="space-y-3 text-sm">
    ...
  </div>
<% else %>
  <p class="text-sm text-secondary">
    No active suppression entry matches this delivery.
  </p>
<% end %>
```

**Apply to Phase 24:** there is no existing modal/dialog analog in `mailglass_admin`. Copy the current operator card/component conventions, then let `OperatorLive` decide whether the modal is open and which exact replay target it presents.

---

### `lib/mailglass/operator/replay_targets.ex` (service, request-response)

**Analog:** `lib/mailglass/operator/suppressions.ex`

**Normalize/fetch/scope/project pattern** (`lib/mailglass/operator/suppressions.ex:18-52`)
```elixir
def get_delivery_suppression_state(context, _opts \\ []) do
  normalized = normalize_context(context)
  tenant_id = fetch_tenant_id!(normalized)
  recipient = fetch_recipient(normalized)
  stream = fetch_stream(normalized)
  recipient_domain = extract_domain(recipient)
  now = Clock.utc_now()

  Entry
  |> where([entry], entry.tenant_id == ^tenant_id)
  |> where([entry], is_nil(entry.expires_at) or entry.expires_at > ^now)
  |> where_matches(recipient, recipient_domain, stream)
  |> limit(1)
  |> Tenancy.scope(tenant_id)
  |> Repo.one()
  |> project_state()
end
```

**Projection helper pattern** (`lib/mailglass/operator/suppressions.ex:94-118`)
```elixir
defp project_state(nil), do: nil

defp project_state(%Entry{} = entry) do
  reversibility = reversibility_for(entry.reason)

  %{
    id: entry.id,
    tenant_id: entry.tenant_id,
    address: entry.address,
    scope: entry.scope,
    reason: entry.reason,
    source: entry.source,
    reversibility: reversibility
  }
end
```

**Apply to Phase 24:** use this exact shape for `tenant_id` normalization and projection. `ReplayTargets` should return explicit states for `:none`, `:one`, and `:many` candidates rather than leaking raw query ambiguity into LiveView.

---

### `lib/mailglass/operator/replay_history.ex` (service, CRUD)

**Analog:** `lib/mailglass/operator/timeline.ex`

**Tenant-scoped ledger query** (`lib/mailglass/operator/timeline.ex:17-39`)
```elixir
def list_delivery_events(filters, opts \\ []) do
  normalized = normalize_filters(filters)
  tenant_id = fetch_tenant_id!(normalized)
  delivery_id = fetch_delivery_id!(normalized)
  limit = limit_from(normalized, opts)

  Event
  |> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
  |> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
  |> limit(^limit)
  |> select([event], %{
    id: event.id,
    tenant_id: event.tenant_id,
    delivery_id: event.delivery_id,
    type: event.type,
    occurred_at: event.occurred_at,
    metadata: event.metadata
  })
  |> Tenancy.scope(tenant_id)
  |> Repo.all()
end
```

**Apply to Phase 24:** keep replay history as a ledger read model over `Mailglass.Events.Event`; add a `where type in ^[:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed]` filter instead of inventing mutable replay columns.

---

### `lib/mailglass/webhook/replay.ex` (service, request-response)

**Analog:** `lib/mailglass/webhook/ingest.ex`

**Tenant precondition + transaction envelope** (`lib/mailglass/webhook/ingest.ex:121-176`)
```elixir
def ingest_multi(provider, raw_body, events)
    when provider in [:postmark, :sendgrid, :mailgun, :ses, :resend] and is_binary(raw_body) and
           is_list(events) do
  tenant_id = Tenancy.tenant_id!()

  result =
    Repo.transact(fn ->
      _ = Repo.query!("SET LOCAL statement_timeout = '2s'", [])
      _ = Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

      multi = build_multi(provider, raw_body, events, tenant_id)

      case Repo.multi(multi) do
        {:ok, changes} -> {:ok, finalize_changes(changes, events)}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end)
```

**Flat `Ecto.Multi` composition** (`lib/mailglass/webhook/ingest.ex:181-229`)
```elixir
duplicate_check_step
|> Multi.insert(
  :webhook_event,
  WebhookEvent.changeset(webhook_event_attrs),
  on_conflict: :nothing,
  conflict_target: [:provider, :provider_event_id],
  returning: true
)
|> append_events_for_each(events, provider, tenant_id)
|> update_projections_for_each(events)
|> Multi.update_all(
  :flip_status,
  &flip_status_query(&1, provider_str),
  set: [status: :succeeded, processed_at: Clock.utc_now()]
)
```

**Delivery resolution and duplicate/no-op semantics** (`lib/mailglass/webhook/ingest.ex:427-448,454-493`)
```elixir
defp resolve_delivery_id(provider, %Event{metadata: meta}) when is_map(meta) do
  message_id =
    meta["sg_message_id"] || meta["message_id"] ||
      Map.get(meta, :sg_message_id) || Map.get(meta, :message_id)

  case message_id do
    id when is_binary(id) and id != "" ->
      query =
        from(d in Delivery,
          where: d.provider == ^Atom.to_string(provider) and d.provider_message_id == ^id,
          select: d.id,
          limit: 1
        )

      Repo.one(Tenancy.scope(query))

    _ ->
      nil
  end
end

duplicate? = Map.get(changes, :duplicate_check, false) == true
%{
  webhook_event: webhook_event,
  duplicate: duplicate?,
  events_with_deliveries: events_with_deliveries,
  orphan_event_count: orphan_event_count
}
```

**Apply to Phase 24:** make `Replay.execute/1` another transaction-wrapped command with flat `Ecto.Multi` steps. Reuse post-verification normalization/projection semantics from ingest, but do not call `ingest_multi/3` unchanged or try to re-verify from stored decoded payloads.

---

### `lib/mailglass/webhook/ingest.ex` (service, request-response)

**Analog:** `lib/mailglass/webhook/ingest.ex`

**Replay-safe raw webhook identity** (`lib/mailglass/webhook/ingest.ex:345-385`)
```elixir
defp derive_webhook_provider_event_id(:sendgrid, raw_body, _events) when is_binary(raw_body) do
  :crypto.hash(:sha256, raw_body)
  |> Base.encode16(case: :lower)
  |> binary_part(0, 32)
end

defp derive_webhook_provider_event_id(:postmark, _raw_body, [first | _]) do
  extract_event_provider_id(first) || ""
end
```

**Persisted payload caveat** (`lib/mailglass/webhook/ingest.ex:415-420`)
```elixir
defp parse_raw_payload(raw_body) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, payload} when is_map(payload) -> payload
    {:ok, payload} when is_list(payload) -> %{"_batch" => payload}
    _ -> %{"_raw" => raw_body}
  end
end
```

**Apply to Phase 24:** if replay extracts shared helpers from ingest, keep provider-specific identity and duplicate semantics untouched. The replay command should treat stored webhook rows as already-verified evidence and should reuse normalized-event handling, not the raw-body verification edge.

---

### `lib/mailglass/events/event.ex` (model, CRUD)

**Analog:** `lib/mailglass/events/event.ex`

**Closed event-type contract** (`lib/mailglass/events/event.ex:33-60`)
```elixir
@anymail_event_types [
  :queued,
  :sent,
  :rejected,
  :failed,
  :bounced,
  :deferred,
  :delivered,
  :autoresponded,
  :opened,
  :clicked,
  :complained,
  :unsubscribed,
  :subscribed,
  :unknown
]

@mailglass_internal_types [:dispatched, :suppressed, :reconciled]
@event_types @anymail_event_types ++ @mailglass_internal_types
```

**Schema and changeset** (`lib/mailglass/events/event.ex:83-123`)
```elixir
schema "mailglass_events" do
  field(:tenant_id, :string)
  field(:delivery_id, :binary_id)
  field(:type, Ecto.Enum, values: @event_types)
  field(:occurred_at, :utc_datetime_usec)
  field(:idempotency_key, :string)
  field(:reject_reason, Ecto.Enum, values: @reject_reasons)
  field(:normalized_payload, :map, default: %{})
  field(:metadata, :map, default: %{})
end

def changeset(attrs) when is_map(attrs) do
  %__MODULE__{}
  |> cast(attrs, @cast)
  |> validate_required(@required)
end

def __types__, do: @event_types
```

**Apply to Phase 24:** replay audit types are a contract change. Add the new internal replay atoms here, not as free-form strings in metadata.

---

### `test/mailglass/operator/replay_targets_test.exs` (test, request-response)

**Analog:** `test/mailglass/operator/suppressions_test.exs`

**Read-model test structure** (`test/mailglass/operator/suppressions_test.exs:9-33,96-110`)
```elixir
describe "get_delivery_suppression_state/2" do
  test "surfaces reason, scope, and source for matching suppression context" do
    insert_entry(%{
      tenant_id: "tenant-a",
      address: "streamed@example.com",
      scope: :address_stream,
      stream: :transactional,
      reason: :manual,
      source: "ops:review"
    })

    state =
      Suppressions.get_delivery_suppression_state(
        %{tenant_id: "tenant-a", recipient: "streamed@example.com", stream: :transactional},
        []
      )
```

**Apply to Phase 24:** use the same `DataCase` shape and assert both positive projection and foreign-tenant exclusion. Add explicit tests for zero candidates, one candidate, and multi-candidate ambiguity.

---

### `test/mailglass/webhook/replay_test.exs` (test, request-response)

**Analog:** `test/mailglass/webhook/ingest_test.exs`

**Integration-test setup** (`test/mailglass/webhook/ingest_test.exs:23-41`)
```elixir
use Mailglass.WebhookCase, async: false

alias Mailglass.{Repo, Tenancy, TestRepo}
alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
alias Mailglass.Webhook.{Ingest, WebhookEvent}

setup do
  TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
  TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
  TestRepo.query!("TRUNCATE TABLE mailglass_deliveries CASCADE", [])

  on_exit(fn -> Tenancy.clear() end)
  :ok
end
```

**Behavior-focused assertions** (`test/mailglass/webhook/ingest_test.exs:133-166`)
```elixir
describe "ingest_multi/3 duplicate replay (UNIQUE collision)" do
  test "second call returns duplicate: true; no second webhook_event row inserted" do
    assert {:ok, first} = Ingest.ingest_multi(:postmark, ~s({"x":1}), events)
    assert first.duplicate == false

    assert {:ok, second} = Ingest.ingest_multi(:postmark, ~s({"x":1}), events)
    assert second.duplicate == true

    assert TestRepo.aggregate(WebhookEvent, :count) == 1
    assert TestRepo.aggregate(Event, :count) == 1
  end
end
```

**Apply to Phase 24:** mirror this style for replay command tests: seed a stored webhook row, execute the replay command under tenant scope, then assert audit rows plus duplicate/no-op outcomes.

---

### `test/mailglass/operator/timeline_test.exs` (test, CRUD)

**Analog:** `test/mailglass/operator/timeline_test.exs`

**Append-ledger then query read model** (`test/mailglass/operator/timeline_test.exs:9-42,46-68,72-97`)
```elixir
{:ok, _queued} =
  Events.append(%{
    tenant_id: "tenant-a",
    delivery_id: selected.id,
    type: :queued,
    occurred_at: DateTime.add(DateTime.utc_now(), -120, :second),
    metadata: %{"provider" => "postmark"}
  })

rows = Timeline.list_delivery_events(%{tenant_id: "tenant-a", delivery_id: selected.id}, [])

assert Enum.map(rows, & &1.type) == [:queued, :delivered]
assert Enum.all?(rows, &(&1.delivery_id == selected.id))
```

**Apply to Phase 24:** expand this file rather than inventing a new generic timeline test. Add replay audit rows to the same chronological assertions.

---

### `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (test, event-driven)

**Analog:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`

**LiveView interaction pattern** (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:34-71,87-153`)
```elixir
{:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

view
|> form("#operator-filters",
  filters: %{
    "tenant_id" => @tenant_id,
    "provider" => "postmark",
    "status" => "sent",
    "event" => "delivered",
    "window_hours" => "168"
  }
)
|> render_submit()

view
|> element("button[phx-value-id='#{delivery.id}']")
|> render_click()
```

**Current non-replay assertion to replace** (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:148-150`)
```elixir
refute html =~ "Replay"
refute html =~ "Remove suppression"
refute html =~ "recent-auth"
```

**Apply to Phase 24:** extend this file for replay CTA visibility, modal rendering, stale-auth failure, explicit target selection, and durable result visibility in-place.

## Shared Patterns

### Action-Time Authorization
**Source:** `mailglass_admin/lib/mailglass_admin/auth.ex:26-59`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex:18-37`, `mailglass_admin/test/support/endpoint_case.ex:73-105`  
**Apply to:** `operator_live.ex`, `webhook/replay.ex`, replay-related LiveView tests

```elixir
case Auth.authorize(opts[:auth], :operator_access, auth_context) do
  {:ok, %{actor: actor, assigns: extra_assigns}} ->
    socket
    |> assign(:operator_actor, actor)
    |> assign(:operator_auth, %{status: :authorized, adapter: opts[:auth], recent_auth?: not is_nil(actor[:recent_auth_at])})

def authorize(:destructive_action, %{actor: %{recent_auth_at: nil}}) do
  {:error, :stale_auth, %{message: "Recent authentication is required."}}
end
```

Planner note: replay authorization must be re-checked at action time with `:destructive_action`; mount-time authorization alone is insufficient.

### Tenant Scoping
**Source:** `lib/mailglass/tenancy.ex:171-245`, `lib/mailglass/operator/deliveries.ex:18-45`, `lib/mailglass/operator/timeline.ex:17-39`  
**Apply to:** `replay_targets.ex`, `replay_history.ex`, `webhook/replay.ex`

```elixir
def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
  prior = Process.get(@process_dict_key)
  put_current(tenant_id)
  try do
    fun.()
  after
    ...
  end
end

def tenant_id! do
  case Process.get(@process_dict_key) do
    nil -> raise Mailglass.TenancyError.new(:unstamped)
    tenant_id when is_binary(tenant_id) -> tenant_id
  end
end

|> Tenancy.scope(tenant_id)
|> Repo.all()
```

Planner note: tenant scope is enforced both by explicit `tenant_id` filters and by `Tenancy.scope/2`. Keep both.

### Append-Only Audit Writes
**Source:** `lib/mailglass/events.ex:92-101,132-152,189-216`, `lib/mailglass/events/event.ex:83-123`  
**Apply to:** `webhook/replay.ex`, `replay_history.ex`, replay tests

```elixir
{:ok, event} =
  Mailglass.Events.append(%{
    tenant_id: tenant_id,
    delivery_id: delivery_id,
    type: :reconciled,
    metadata: %{"reconciled_from_event_id" => orphan.id},
    idempotency_key: "reconciled:" <> to_string(orphan.id)
  })

Events.append_multi(multi, :queued, fn %{delivery: d} ->
  %{type: :queued, delivery_id: d.id}
end)
```

Planner note: replay requested/succeeded/failed should be separate ledger facts, not mutable summary fields on `mailglass_webhook_events`.

### Operator Read-Model Boundary
**Source:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:51-67,215-247`, `lib/mailglass/operator/suppressions.ex:18-52`  
**Apply to:** `operator_live.ex`, `replay_targets.ex`, `replay_history.ex`

```elixir
deliveries = load_deliveries(filter_params)
timeline_events = load_timeline(filter_params, selected_delivery)
suppression_state = load_suppression(filter_params, selected_delivery)
```

Planner note: keep LiveView free of ad hoc query logic; add new core read-model modules and call them from `OperatorLive`.

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component | event-driven | `mailglass_admin` has no existing modal/dialog component. Follow card/component conventions from `suppression_card.ex` and let `OperatorLive` own open/close state. |
| `lib/mailglass/webhook/replay.ex` | service | request-response | Existing webhook code covers ingest, not manual operator-triggered replay. Reuse the transaction/Multi composition from `ingest.ex`, but the replay command itself is a new seam. |

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin`, `mailglass_admin/test/mailglass_admin`, `lib/mailglass`, `test/mailglass`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-01
