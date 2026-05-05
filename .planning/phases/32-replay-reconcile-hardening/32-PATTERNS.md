# Phase 32: Replay & Reconcile Hardening - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 11 code/test files plus 1 documentation surface
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | controller | request-response | `mailglass_admin/lib/mailglass_admin/operator_live.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | component | transform | `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component | request-response | `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` | component | transform | `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` | utility | transform | `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | partial-match |
| `lib/mailglass/webhook/reconciler.ex` | service | batch | `lib/mailglass/webhook/reconciler.ex` | exact |
| `lib/mix/tasks/mailglass.reconcile.ex` | utility | batch | `lib/mix/tasks/mailglass.reconcile.ex` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | test | request-response | `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | exact |
| `test/mailglass/operator/timeline_test.exs` | test | transform | `test/mailglass/operator/timeline_test.exs` | exact |
| `test/mailglass/webhook/reconciler_test.exs` | test | batch | `test/mailglass/webhook/reconciler_test.exs` | exact |
| `test/mix/tasks/mailglass_reconcile_test.exs` | test | batch | `test/mix/tasks/mailglass.suppressions.resync_test.exs` | role-match |

**Documentation surface outside planner role taxonomy:** `guides/webhook-troubleshooting.md` should be updated alongside the CLI fallback contract. Copy tone and checklist structure from the existing guide itself.

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (controller, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`

**Imports + module wiring** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:12-27`):
```elixir
use Phoenix.LiveView

alias Mailglass.Operator.{Deliveries, ReplayHistory, ReplayTargets, Suppressions}
alias Mailglass.Webhook.Replay
alias MailglassAdmin.Auth
alias Mailglass.Operator.Timeline, as: OperatorTimelineData
alias MailglassAdmin.Components
alias MailglassAdmin.Operator.{
  DeliveriesList,
  DetailHeader,
  FiltersForm,
  ReplayModal,
  SuppressionCard
}
alias MailglassAdmin.Operator.Timeline, as: OperatorTimeline
```

**Resolve -> authorize -> execute sequence** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:119-153`):
```elixir
with %{selected_delivery: %{id: delivery_id, tenant_id: tenant_id} = delivery} <- socket.assigns,
     {:ok, target} <- selected_replay_target(socket.assigns.replay_targets, socket.assigns.replay_selected_target_id),
     {:ok, socket} <- authorize_replay(socket, delivery, target),
     {:ok, result} <-
       Replay.execute(%{
         tenant_id: tenant_id,
         delivery_id: delivery_id,
         webhook_event_id: target.webhook_event_id,
         actor: socket.assigns.operator_actor
       }) do
  {:noreply,
   socket
   |> assign_delivery_state(socket.assigns.filter_params, delivery_id)
   |> close_replay_modal()
   |> put_flash(:info, replay_success_message(result.status))}
else
  {:error, {:auth, message}} ->
    {:noreply, put_flash(socket, :error, message)}

  {:error, reason} ->
    {:noreply,
     socket
     |> assign_delivery_state(socket.assigns.filter_params, socket.assigns.selected_delivery.id)
     |> put_flash(:error, replay_failure_message(reason))}
end
```

**Target-selection guard pattern** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:404-418`):
```elixir
defp selected_replay_target(%{status: :exact, candidate: candidate}, _selected_target_id),
  do: {:ok, candidate}

defp selected_replay_target(%{status: :ambiguous, candidates: _candidates}, nil),
  do: {:error, :target_required}

defp selected_replay_target(%{status: :ambiguous, candidates: candidates}, selected_target_id) do
  case Enum.find(candidates, &(&1.webhook_event_id == selected_target_id)) do
    nil -> {:error, :target_required}
    candidate -> {:ok, candidate}
  end
end
```

**Action-time auth seam** (`mailglass_admin/lib/mailglass_admin/operator_live.ex:420-435`):
```elixir
case Auth.authorize(adapter, :destructive_action, %{
       actor: socket.assigns.operator_actor,
       delivery: delivery,
       replay_target: target
     }) do
  {:ok, %{actor: actor, assigns: extra_assigns}} ->
    {:ok, assign_extra_assigns(assign(socket, :operator_actor, actor), extra_assigns)}

  {:error, _reason, details} ->
    {:error, {:auth, Map.get(details, :message, "Replay is not authorized.")}}
end
```

**Planner note:** keep the Phase 32 helper/facade on this exact server-side seam. Do not move freshness checks into mount or modal-open state.

---

### `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` (component, transform)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`

**Component attr + render pattern** (`mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:6-16`, `57-74`):
```elixir
use Phoenix.Component

attr :delivery, :map, required: true
attr :replay_targets, :map, default: nil
attr :latest_replay, :map, default: nil
```

```heex
<div class="mt-6 flex flex-wrap items-start justify-between gap-4 border-t border-base-300 pt-4">
  <div class="space-y-1">
    <h3 class="text-sm font-bold uppercase tracking-[0.08em] text-secondary">Webhook replay</h3>
    <p class="text-sm text-base-content">{replay_hint(@replay_targets)}</p>
    <p :if={@latest_replay} class="text-xs text-secondary">
      Last replay: {latest_replay_label(@latest_replay)} at {format_datetime(@latest_replay.occurred_at)}
    </p>
  </div>
```

**Current replay availability mapping to replace/extract** (`mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:99-126`):
```elixir
defp replay_hint(%{status: :exact}), do: "One exact webhook target is ready for confirmation."

defp replay_hint(%{status: :ambiguous, candidates: _candidates}) do
  "Multiple webhook targets match this delivery. Choose one in the confirmation modal."
end

defp latest_replay_label(%{type: :webhook_replay_failed}), do: "failed"

defp latest_replay_label(%{type: :webhook_replay_succeeded, outcome: "noop"}),
  do: "converged with no new work"

defp latest_replay_label(%{type: :webhook_replay_succeeded}), do: "succeeded"
defp latest_replay_label(%{type: :webhook_replay_requested}), do: "requested"
```

**Planner note:** this is the strongest analog for the new presenter module. Move copy-only mapping out of components; keep the component thin and pass presenter-level labels in.

---

### `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` (component, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`

**Modal state split by replay availability** (`mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:34-80`):
```elixir
<%= case @replay_targets do %>
  <% %{status: :exact, candidate: candidate} -> %>
    ...
  <% %{status: :ambiguous, candidates: candidates} -> %>
    ...
  <% %{status: :unavailable, reason: reason} -> %>
    <div class="rounded-box border border-warning bg-warning/10 p-4 text-sm text-base-content">
      <p class="font-bold">Replay unavailable</p>
      <p class="mt-1">{unavailable_copy(reason)}</p>
    </div>
<% end %>
```

**Choice-required pattern** (`mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:43-65`):
```heex
<p class="text-sm text-base-content">
  Choose one webhook target. The operator UI will not guess across multiple replayable webhook rows.
</p>

<form id="operator-replay-targets" phx-change="choose_replay_target" class="space-y-3">
  <%= for candidate <- candidates do %>
    <label class="block cursor-pointer">
      <input
        type="radio"
        name="webhook_event_id"
        value={candidate.webhook_event_id}
        checked={candidate.webhook_event_id == @selected_target_id}
        class="sr-only"
      />
```

**Confirm-button gating** (`mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:130-146`):
```elixir
defp confirm_enabled?(%{status: :exact}, _selected_target_id), do: true

defp confirm_enabled?(%{status: :ambiguous}, selected_target_id),
  do: is_binary(selected_target_id) and selected_target_id != ""

defp unavailable_copy(:missing_replay_linkage),
  do: "Historical rows without exact webhook linkage cannot be replayed safely."
```

**Planner note:** if Phase 32 introduces shared wording, replace `unavailable_copy/1` and the modal headline text through the presenter, not by adding more inline case branches.

---

### `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` (component, transform)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/timeline.ex`

**Replay audit visual distinction** (`mailglass_admin/lib/mailglass_admin/operator/timeline.ex:33-45`, `103-115`):
```heex
<p class="text-sm font-bold text-base-content">{label(event.type)}</p>
<span :if={replay_event?(event.type)} class="badge badge-outline badge-error">
  Replay audit
</span>
<p class="text-xs text-secondary">{metadata_summary(event.metadata)}</p>
```

```elixir
defp replay_event?(type),
  do: type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed]

defp event_dot_class(:webhook_replay_failed), do: "bg-error"
defp event_dot_class(type) when type in [:webhook_replay_requested, :webhook_replay_succeeded], do: "bg-warning"
defp event_dot_class(_type), do: "bg-primary"
```

**Replay metadata summary mapping** (`mailglass_admin/lib/mailglass_admin/operator/timeline.ex:86-111`):
```elixir
defp replay_metadata_summary(metadata) do
  provider = Map.get(metadata, "provider")
  actor_id = Map.get(metadata, "actor_id")
  outcome = replay_outcome_label(Map.get(metadata, "outcome"))
  failure_reason = Map.get(metadata, "failure_reason")

  [provider && String.upcase(provider), actor_id, outcome, failure_reason]
  |> Enum.reject(&(&1 in [nil, ""]))
  |> case do
    [] -> "Replay audit"
    values -> Enum.join(values, " · ")
  end
end
```

**Planner note:** Phase 32’s “presenter-level wording” should feed this component. Keep the “Replay audit” badge and distinct color treatment.

---

### `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` (utility, transform)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`

**Copy to centralize from header + timeline + modal:**
- Availability mapping from `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:99-106`
- Latest replay outcome mapping from `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:108-115`
- Unavailable reason mapping from `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:117-126`
- Replay outcome label mapping from `mailglass_admin/lib/mailglass_admin/operator/timeline.ex:108-111`

**Best starting excerpt** (`mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:99-115`):
```elixir
defp replay_hint(%{status: :exact}), do: "One exact webhook target is ready for confirmation."

defp replay_hint(%{status: :ambiguous, candidates: _candidates}) do
  "Multiple webhook targets match this delivery. Choose one in the confirmation modal."
end

defp latest_replay_label(%{type: :webhook_replay_failed}), do: "failed"

defp latest_replay_label(%{type: :webhook_replay_succeeded, outcome: "noop"}),
  do: "converged with no new work"

defp latest_replay_label(%{type: :webhook_replay_succeeded}), do: "succeeded"
defp latest_replay_label(%{type: :webhook_replay_requested}), do: "requested"
```

**Planner note:** shape this as a pure mapping module. Inputs should stay raw domain facts (`:exact`, `:ambiguous`, `:unavailable`, audit event type, `"noop"`, `"replayed"`). Outputs should be stable operator labels such as `ready`, `choice required`, `unavailable`, `requested`, `completed`, `failed`, `new work`, `no change`.

---

### `lib/mailglass/webhook/reconciler.ex` (service, batch)

**Analog:** `lib/mailglass/webhook/reconciler.ex`

**Optional-dependency gating** (`lib/mailglass/webhook/reconciler.ex:1-2`, `268-280`):
```elixir
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Reconciler do
```

```elixir
defmodule Mailglass.Webhook.Reconciler do
  @spec available?() :: false
  def available?, do: false
end
```

**Single canonical reconcile function** (`lib/mailglass/webhook/reconciler.ex:102-156`):
```elixir
@spec reconcile(String.t() | nil, pos_integer()) ::
        {:ok, %{scanned: non_neg_integer(), linked: non_neg_integer()}}
def reconcile(tenant_id \\ nil, limit \\ @batch_limit)
    when (is_nil(tenant_id) or is_binary(tenant_id)) and is_integer(limit) and limit > 0 do
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
```

**Append-only reconcile write pattern** (`lib/mailglass/webhook/reconciler.ex:176-224`):
```elixir
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

multi =
  Multi.new()
  |> Events.append_multi(:reconciled_event, reconciled_attrs)
  |> Multi.update(:projection, fn _changes ->
    Projector.update_projections(delivery, orphan)
  end)
```

**Planner note:** keep Phase 32 fallback fixes here or behind a shared pure function. Do not split reconcile semantics across worker-only and CLI-only code paths.

---

### `lib/mix/tasks/mailglass.reconcile.ex` (utility, batch)

**Analog:** `lib/mix/tasks/mailglass.reconcile.ex`

**Task option parsing + app boot** (`lib/mix/tasks/mailglass.reconcile.ex:43-54`):
```elixir
def run(argv) do
  {opts, _rest, _invalid} =
    OptionParser.parse(argv,
      strict: [tenant_id: :string, batch_size: :integer]
    )

  Mix.Task.run("app.start")

  tenant_id = opts[:tenant_id]
  batch_size = opts[:batch_size] || 1000
```

**Current fallback mismatch seam** (`lib/mix/tasks/mailglass.reconcile.ex:55-70`):
```elixir
if Mailglass.Webhook.Reconciler.available?() do
  {:ok, %{scanned: scanned, linked: linked}} =
    Mailglass.Webhook.Reconciler.reconcile(tenant_id, batch_size)

  Mix.shell().info(
    "Reconcile complete: scanned=#{scanned} linked=#{linked}" <>
      if(tenant_id, do: " tenant=#{tenant_id}", else: "")
  )
else
  Mix.shell().error(
    "Mailglass.Webhook.Reconciler is not compiled (Oban not available). " <>
      "Add {:oban, \"~> 2.21\"} to your deps to enable reconciliation."
  )

  exit({:shutdown, 1})
end
```

**Planner note:** this is the file that must align with docs/warnings/tests. Either the task becomes the Oban-less fallback, or every promise saying it is must be removed. Research strongly points to making the task honor the fallback.

---

### `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (test, request-response)

**Analog:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`

**LiveView test harness + tenant/session helpers** (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:1-13`, `357-369`):
```elixir
use MailglassAdmin.LiveViewCase, async: false

import Ecto.Query

alias Mailglass.Events.Event
alias Mailglass.IdempotencyKey
alias Mailglass.Outbound.Delivery
alias MailglassAdmin.TestRepo
alias Mailglass.Webhook.WebhookEvent
```

```elixir
defp operator_conn(conn, session \\ %{}) do
  now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  Plug.Test.init_test_session(conn, %{
    "current_user_id" => "operator-1",
    "tenant_id" => @tenant_id,
    "auth_method" => "password",
    "recent_auth_at" => now
  })
```

**Current stale-auth / no-audit lock** (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:282-301`):
```elixir
test "returns a stale-auth error without performing replay", %{conn: conn} do
  stale = DateTime.utc_now() |> DateTime.add(-1_800, :second) |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  conn = operator_conn(conn, %{"recent_auth_at" => stale})
  {delivery, webhook_event} = insert_exact_replay_fixture!("msg-stale-ui", 601)

  ...

  assert html =~ "Recent authentication is required."
  assert replay_audit_rows_for(webhook_event.id) == []
end
```

**Current wording assertions to update** (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:303-350`):
```elixir
assert html =~ "Replay completed and produced new work."
assert html =~ "Webhook replay requested"
assert html =~ "Webhook replay succeeded"
assert html =~ "Last replay: succeeded"
```

```elixir
assert html =~ "Replay converged without new downstream work."
assert html =~ "No new work"
assert html =~ "Last replay: converged with no new work"
```

**Planner note:** extend this file rather than starting a separate component test file. It already covers exact-target, ambiguity, unavailable, stale-auth, replay success, and replay noop.

---

### `test/mailglass/operator/timeline_test.exs` (test, transform)

**Analog:** `test/mailglass/operator/timeline_test.exs`

**Read-model fixture style** (`test/mailglass/operator/timeline_test.exs:4-7`, `116-184`):
```elixir
alias Mailglass.Events
alias Mailglass.Generators
alias Mailglass.Operator.{ReplayHistory, Timeline}
```

```elixir
{:ok, _requested} =
  Events.append(%{
    tenant_id: "tenant-a",
    delivery_id: selected.id,
    type: :webhook_replay_requested,
    occurred_at: DateTime.add(DateTime.utc_now(), -120, :second),
    metadata: %{
      "actor_id" => "operator-1",
      "provider" => "postmark",
      "webhook_event_id" => "webhook-1",
      "webhook_provider_event_id" => "provider-1"
    }
  })
```

**Planner note:** if presenter logic remains pure and independent of LiveView, this is the right lightweight place to assert ordered facts and extracted replay metadata.

---

### `test/mailglass/webhook/reconciler_test.exs` (test, batch)

**Analog:** `test/mailglass/webhook/reconciler_test.exs`

**Optional-dep skip pattern** (`test/mailglass/webhook/reconciler_test.exs:41-52`):
```elixir
setup do
  on_exit(fn -> Tenancy.clear() end)

  if Reconciler.available?() do
    :ok
  else
    {:skip, "Oban not available; Mailglass.Webhook.Reconciler not compiled"}
  end
end
```

**Append-only/idempotent assertions** (`test/mailglass/webhook/reconciler_test.exs:55-118`):
```elixir
{:ok, %{scanned: scanned, linked: linked}} =
  Reconciler.reconcile("test-tenant", 100)

assert scanned >= 1
assert linked >= 1

reconciled_events =
  Repo.all(from(e in Event, where: e.type == :reconciled))

assert length(reconciled_events) == 1
...
assert reconciled.idempotency_key == "reconciled:" <> orphan.id
```

**Telemetry whitelist assertions** (`test/mailglass/webhook/reconciler_test.exs:175-214`):
```elixir
assert Map.has_key?(meta, :tenant_id)
assert Map.has_key?(meta, :scanned_count)
assert Map.has_key?(meta, :linked_count)
assert Map.has_key?(meta, :remaining_orphan_count)
assert Map.has_key?(meta, :status)

refute Map.has_key?(meta, :raw_payload)
refute Map.has_key?(meta, :recipient)
refute Map.has_key?(meta, :email)
```

**Planner note:** keep this file focused on application semantics, not mix-task UX. Put CLI fallback assertions in a separate task test.

---

### `test/mix/tasks/mailglass_reconcile_test.exs` (test, batch)

**Analog:** `test/mix/tasks/mailglass.suppressions.resync_test.exs`

**Task test structure** (`test/mix/tasks/mailglass.suppressions.resync_test.exs:1-10`, `87-130`):
```elixir
use Mailglass.DataCase, async: false

import ExUnit.CaptureIO
```

```elixir
test "dry-run reports counts without writing rows" do
  output =
    capture_io(fn ->
      Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id, "--dry-run"])
    end)

  assert output =~ "tenant=#{@tenant_id}"
  assert output =~ "scanned=1"
end
```

**Fixture pattern to copy** (`test/mix/tasks/mailglass.suppressions.resync_test.exs:133-186`):
```elixir
defp insert_delivery!(attrs) do
  attrs
  |> Enum.into(%{
    tenant_id: @tenant_id,
    ...
  })
  |> Delivery.changeset()
  |> TestRepo.insert!()
end
```

**Planner note:** build the new reconcile task test like this one: seed data, run the Mix task through `capture_io/1`, assert shell output and durable DB effects, then add one branch for the Oban-less fallback contract.

## Shared Patterns

### Authentication

**Sources:** `mailglass_admin/lib/mailglass_admin/auth.ex:23-35`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex:17-42`, `mailglass_admin/test/support/endpoint_case.ex:91-106`

**Apply to:** `operator_live.ex`, any new shared destructive-action helper, and LiveView tests

```elixir
@callback authorize(action(), context :: map()) :: result()

@spec authorize(module(), action(), map()) :: {:ok, %{actor: actor(), assigns: map()}} | failure()
def authorize(module, action, context) when is_atom(module) do
  ...
  module
  |> apply(:authorize, [action, context])
  |> normalize_result()
end
```

```elixir
case Auth.authorize(opts[:auth], :operator_access, auth_context) do
  {:ok, %{actor: actor, assigns: extra_assigns}} ->
    ...
  {:error, reason, details} ->
    {:halt, deny(socket, reason, details, opts)}
end
```

```elixir
def authorize(:destructive_action, %{actor: %{recent_auth_at: nil}}) do
  {:error, :stale_auth, %{message: "Recent authentication is required."}}
end
```

### Tenant-Scoped Read Models

**Sources:** `lib/mailglass/operator/replay_targets.ex:15-30`, `lib/mailglass/operator/replay_history.ex:15-41`, `lib/mailglass/operator/timeline.ex:16-39`

**Apply to:** replay availability lookup, replay history refresh, and any new read-only repair presenter inputs

```elixir
case fetch_delivery(tenant_id, delivery_id) do
  nil ->
    {:error, :delivery_not_found}

  %Delivery{} = delivery ->
    events = fetch_delivery_events(tenant_id, delivery_id)
    candidates = resolve_candidates(tenant_id, delivery, events)
    {:ok, outcome(delivery, events, candidates)}
end
```

### Audit and Error Handling

**Source:** `lib/mailglass/webhook/replay.ex:39-60`, `63-98`, `139-170`

**Apply to:** replay hardening paths and any shared repair action helper

```elixir
with {:ok, params} <- normalize_params(attrs),
     {:ok, webhook_event} <- fetch_target(params.tenant_id, params.webhook_event_id),
     {:ok, requested_audit} <- append_requested_audit(params, webhook_event) do
  ...
else
  {:error, :webhook_event_not_found} = err ->
    err

  {:error, reason} = err ->
    maybe_append_failed_audit(attrs, reason)
    err
end
```

### Optional Dependency Fallback

**Sources:** `lib/mailglass/webhook/reconciler.ex:69-77`, `268-280`, `lib/mix/tasks/mailglass.reconcile.ex:55-70`

**Apply to:** reconcile fallback contract, CLI behavior, and tests

```elixir
@spec available?() :: true
def available?, do: true
```

```elixir
@spec available?() :: false
def available?, do: false
```

### Test Harness Patterns

**Sources:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs:357-369`, `test/mix/tasks/mailglass.suppressions.resync_test.exs:94-129`

**Apply to:** stale-auth/no-audit regression tests and the new reconcile Mix task regression

```elixir
Plug.Test.init_test_session(conn, %{
  "current_user_id" => "operator-1",
  "tenant_id" => @tenant_id,
  "auth_method" => "password",
  "recent_auth_at" => now
})
```

```elixir
output =
  capture_io(fn ->
    Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id, "--dry-run"])
  end)
```

## No Analog Found

None in code. The only gap is taxonomy-related: documentation files are outside the planner role list, but `guides/webhook-troubleshooting.md` already provides the structural analog for the Phase 32 doc update.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/operator*`, `mailglass_admin/lib/mailglass_admin/auth.ex`, `lib/mailglass/operator/*`, `lib/mailglass/webhook/*`, `lib/mix/tasks/*`, `mailglass_admin/test/*`, `test/mailglass/operator/*`, `test/mailglass/webhook/*`, `test/mix/tasks/*`, `guides/*`

**Files scanned:** 18

**Pattern extraction date:** 2026-05-05
