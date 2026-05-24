defmodule MailglassAdmin.InboundLive do
  @moduledoc """
  Read-only operator dashboard for recent inbound records, execution lineage,
  and routing reflection (IADM-01/02/07).

  Sibling of `MailglassAdmin.OperatorLive` (D-48-13 — clone, not a refactor). The
  screen keeps filter and selection state in URL params so refresh, back/forward
  navigation, and copied links preserve the current operator context.

  All inbound data access crosses a RUNTIME `apply/3` edge through
  `MailglassAdmin.OptionalDeps.MailglassInbound` (D-48-02/03). This module never
  references the optional inbound modules directly, so the `--no-optional-deps`
  compile lane stays green: when `mailglass_inbound` is absent the gateway module is
  elided, `gateway_available?/0` returns `false`, and every data call degrades to the
  empty surface.

  Tenant-required-or-empty (D-48-04): a blank/missing tenant renders the empty state
  and never leaks another tenant's record id or recipient. The read-model enforces
  the tenant where-clause + `Tenancy.scope/2`; this LiveView adds the
  `load_inbound_records(%{"tenant_id" => ""})` short-circuit head as defense in depth.
  """

  use Phoenix.LiveView

  alias MailglassAdmin.Components
  alias MailglassAdmin.Inbound.DetailHeader
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassAdmin.Inbound.FiltersForm
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.Inbound.ReplayModal
  alias MailglassAdmin.Inbound.RoutingTrace
  alias MailglassAdmin.Inbound.Timeline

  @gateway MailglassAdmin.OptionalDeps.MailglassInbound

  # The closed outcome allow-list. Hard-coded here (and asserted against the
  # read-model in the inbound test) so the LiveView has no compile-time reference
  # to MailglassInbound — keeping the --no-optional-deps lane clean.
  @outcome_values [:no_match, :accept, :ignore, :reject, :bounce, :failed]
  @default_window_hours 168
  @window_options [
    {"Last 24 hours", "24"},
    {"Last 7 days", "168"},
    {"Last 30 days", "720"}
  ]

  @impl true
  def mount(_params, session, socket) do
    # D-48-07: the declared inbound router module is surfaced in the operator
    # session (router.ex __operator_session__) as an atom, never cookie-sourced.
    # The routing-trace card reflects its routes via the runtime gateway.
    inbound_router = session_inbound_router(session)

    {:ok,
     socket
     |> assign_new(:operator_actor, fn -> nil end)
     |> assign_new(:operator_auth, fn -> %{status: :unknown, recent_auth?: false} end)
     |> assign(:records, [])
     |> assign(:selected_record, nil)
     |> assign(:detail, nil)
     |> assign(:runs, [])
     |> assign(:routing_trace, [])
     |> assign(:reveal_state, :redacted)
     |> assign(:inbound_router, inbound_router)
     |> assign(:detail_error, nil)
     |> assign(:replay_modal_open?, false)
     |> assign(:base_path, "/inbound")
     |> assign(:outcome_values, @outcome_values)
     |> assign(:window_options, @window_options)
     |> assign(:filter_params, default_filter_params())
     |> assign(:filter_form, to_form(default_filter_params(), as: :filters))
     |> assign(:page_title, "mailglass — Inbound")}
  end

  defp session_inbound_router(session) when is_map(session),
    do: Map.get(session, "inbound_router")

  defp session_inbound_router(_session), do: nil

  @impl true
  def handle_params(params, uri, socket) do
    filter_params = normalize_filter_params(params)

    {:noreply,
     socket
     |> assign(:base_path, URI.parse(uri).path || "/inbound")
     |> assign(:filter_params, filter_params)
     |> assign(:filter_form, to_form(filter_params, as: :filters))
     |> assign_inbound_state(filter_params, blank_to_nil(params["inbound_id"]))
     |> close_replay_modal()}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    normalized = normalize_filter_params(filters)

    {:noreply,
     push_patch(socket, to: build_path(socket.assigns.base_path, normalized, nil))}
  end

  def handle_event("validate_filters", %{"filters" => filters}, socket) do
    {:noreply,
     assign(socket, :filter_form, to_form(normalize_filter_params(filters), as: :filters))}
  end

  def handle_event("select_inbound", %{"id" => inbound_id}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_path(socket.assigns.base_path, socket.assigns.filter_params, inbound_id)
     )}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.base_path)}
  end

  def handle_event("open_replay", _params, socket) do
    {:noreply, assign(socket, :replay_modal_open?, true)}
  end

  def handle_event("close_replay", _params, socket) do
    {:noreply, close_replay_modal(socket)}
  end

  # Evidence reveal (IADM-02) — capability-gated by the :reveal_raw atom over the
  # SAME Auth.authorize/3 seam as replay (no new auth surface, D-48-09). On grant
  # the evidence card renders the raw payload read-only; on denial the redacted
  # placeholder stays and a brand-voice line explains the gate.
  def handle_event("reveal_raw", _params, socket) do
    {:noreply, assign(socket, :reveal_state, authorize_reveal(socket))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-theme="mailglass-light" class="min-h-screen bg-base-100">
      <main class="mx-auto max-w-7xl px-4 py-6 md:px-6 md:py-8">
        <header class="mb-6 flex flex-col gap-2">
          <h1 class="text-xl font-bold text-base-content tracking-tight">Inbound records</h1>
          <p class="text-sm text-secondary">
            Browse tenant-scoped inbound mail, inspect its execution timeline, and review routing outcomes.
          </p>
        </header>

        <div class="space-y-3">
          <div
            :if={Phoenix.Flash.get(@flash, :info)}
            class="rounded-box border border-success bg-success/10 px-4 py-3 text-sm text-base-content"
          >
            {Phoenix.Flash.get(@flash, :info)}
          </div>
          <div
            :if={Phoenix.Flash.get(@flash, :error)}
            class="rounded-box border border-error bg-error/10 px-4 py-3 text-sm text-base-content"
          >
            {Phoenix.Flash.get(@flash, :error)}
          </div>
        </div>

        <section class="card rounded-box border border-base-300 bg-base-200 p-4 md:p-5">
          <.form
            for={@filter_form}
            id="inbound-filters"
            phx-change="validate_filters"
            phx-submit="apply_filters"
            class="grid gap-3"
          >
            <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
              <FiltersForm.fields
                form={@filter_form}
                outcome_values={@outcome_values}
                window_options={@window_options}
              />
            </div>

            <div class="flex flex-wrap gap-2">
              <button type="submit" class="btn btn-primary min-h-11 px-5">Open record</button>
              <button type="button" phx-click="clear_filters" class="btn btn-ghost min-h-11 px-5">
                Clear filters
              </button>
            </div>
          </.form>
        </section>

        <section
          data-testid="inbound-master-detail"
          class="mt-6 grid gap-6 lg:grid-cols-[minmax(22rem,28rem)_1fr]"
        >
          <aside
            data-testid="inbound-records-list-card"
            class="card rounded-box border border-base-300 bg-base-200 p-0"
          >
            <div class="border-b border-base-300 px-4 py-3">
              <h2 class="text-sm font-bold uppercase tracking-[0.08em] text-secondary">
                Recent inbound records
              </h2>
            </div>
            <RecordsList.records_list records={@records} selected_record={@selected_record} />
          </aside>

          <section data-testid="inbound-detail-column" class="space-y-4">
            <%= cond do %>
              <% @detail_error -> %>
                <div
                  data-testid="inbound-detail-error"
                  class="card rounded-box border border-error bg-base-100 p-6"
                >
                  <div class="flex items-center gap-2">
                    <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
                    <h2 class="text-base font-bold text-base-content">
                      Inbound data could not be loaded. Refresh the page or adjust the filters, then try again.
                    </h2>
                  </div>
                </div>

              <% is_nil(@detail) -> %>
                <div
                  data-testid="inbound-empty-detail"
                  class="card rounded-box border border-base-300 bg-base-200 p-6"
                >
                  <h2 class="text-base font-bold text-base-content">
                    Select an inbound record to inspect its routing, execution timeline, and raw source.
                  </h2>
                </div>

              <% true -> %>
                <DetailHeader.detail_header detail={@detail} />
                <Timeline.timeline runs={@runs} />
                <RoutingTrace.routing_trace
                  :if={@detail[:outcome] == :no_match}
                  trace={@routing_trace}
                />
                <EvidenceCard.evidence_card evidence={@detail[:evidence]} reveal_state={@reveal_state} />
            <% end %>
          </section>
        </section>
      </main>

      <ReplayModal.replay_modal open?={@replay_modal_open?} record={selected_record_struct(@detail)} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # State aggregation — list + selected record + timeline + detail in one pass
  # through the runtime gateway (apply/3). No bare optional-inbound reference.
  # ---------------------------------------------------------------------------

  defp assign_inbound_state(socket, filter_params, selected_inbound_id) do
    records = load_inbound_records(filter_params)
    selected_record = find_selected_record(records, selected_inbound_id)
    detail = load_detail(filter_params, selected_inbound_id)

    socket
    |> assign(:records, records)
    |> assign(:selected_record, selected_record)
    |> assign(:detail, detail)
    |> assign(:runs, load_timeline(filter_params, selected_inbound_id))
    |> assign(:routing_trace, routing_trace_for(socket.assigns.inbound_router, detail))
    # Selecting (or re-selecting) a record collapses the evidence card back to
    # redacted — reveal is a per-view capability action, never sticky across
    # selections.
    |> assign(:reveal_state, :redacted)
    |> assign(:detail_error, detail_error_for(selected_inbound_id, detail))
  end

  # Routing-trace data (IADM-04) — ONLY for a :no_match record. Reflected from the
  # adopter's declared inbound router via the runtime gateway (D-48-06); the view
  # never re-implements match semantics. Any other outcome (or no detail) yields
  # [] so the card is omitted entirely.
  defp routing_trace_for(_inbound_router, nil), do: []

  defp routing_trace_for(inbound_router, %{outcome: :no_match, record: record}) do
    if gateway_available?() do
      apply(@gateway, :explain_routes, [inbound_router, record])
    else
      []
    end
  end

  defp routing_trace_for(_inbound_router, _detail), do: []

  # Tenant-required-or-empty (D-48-04) — the load-bearing security head BEFORE any
  # data call. A blank tenant yields [] without touching the gateway.
  defp load_inbound_records(%{"tenant_id" => ""}), do: []

  defp load_inbound_records(filter_params) do
    if gateway_available?() do
      apply(@gateway, :list_records, [
        %{
          tenant_id: filter_params["tenant_id"],
          provider: blank_to_nil(filter_params["provider"]),
          outcome: cast_enum(filter_params["outcome"], @outcome_values),
          window_hours:
            parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
        },
        []
      ])
    else
      []
    end
  end

  defp load_detail(%{"tenant_id" => ""}, _selected_inbound_id), do: nil
  defp load_detail(_filter_params, nil), do: nil

  defp load_detail(filter_params, selected_inbound_id) do
    if gateway_available?() do
      apply(@gateway, :detail, [
        %{tenant_id: filter_params["tenant_id"], inbound_record_id: selected_inbound_id},
        []
      ])
    else
      nil
    end
  end

  defp load_timeline(%{"tenant_id" => ""}, _selected_inbound_id), do: []
  defp load_timeline(_filter_params, nil), do: []

  defp load_timeline(filter_params, selected_inbound_id) do
    if gateway_available?() do
      apply(@gateway, :timeline, [
        %{tenant_id: filter_params["tenant_id"], inbound_record_id: selected_inbound_id},
        []
      ])
    else
      []
    end
  end

  defp find_selected_record(_records, nil), do: nil
  defp find_selected_record(records, inbound_id), do: Enum.find(records, &(&1.id == inbound_id))

  # A selected id with no resolvable detail (wrong tenant, deleted, never existed)
  # surfaces the bordered detail-error band rather than a silent blank pane.
  defp detail_error_for(nil, _detail), do: nil
  defp detail_error_for(_inbound_id, nil), do: :not_found
  defp detail_error_for(_inbound_id, _detail), do: nil

  defp selected_record_struct(nil), do: nil
  defp selected_record_struct(%{record: record}), do: record

  defp gateway_available? do
    Code.ensure_loaded?(@gateway) and @gateway.available?()
  end

  # Rides the existing Auth.authorize/3 atom() action type with :reveal_raw — no
  # new auth module/plug/behaviour (D-48-09). Returns :revealed on grant, :denied
  # otherwise. The adapter arrives from the operator Mount hook.
  defp authorize_reveal(socket) do
    adapter = socket.assigns.operator_auth[:adapter]

    if is_atom(adapter) and not is_nil(adapter) do
      case MailglassAdmin.Auth.authorize(adapter, :reveal_raw, %{
             actor: socket.assigns.operator_actor
           }) do
        {:ok, _result} -> :revealed
        {:error, _reason, _details} -> :denied
      end
    else
      :denied
    end
  end

  # ---------------------------------------------------------------------------
  # URL <-> filter param plumbing (cloned from OperatorLive).
  # ---------------------------------------------------------------------------

  defp default_filter_params do
    %{
      "tenant_id" => "",
      "provider" => "",
      "outcome" => "",
      "window_hours" => Integer.to_string(@default_window_hours),
      "search" => ""
    }
  end

  defp normalize_filter_params(params) do
    defaults = default_filter_params()

    %{
      "tenant_id" => normalize_string(Map.get(params, "tenant_id", defaults["tenant_id"])),
      "provider" => normalize_string(Map.get(params, "provider", defaults["provider"])),
      "outcome" => normalize_string(Map.get(params, "outcome", defaults["outcome"])),
      "window_hours" =>
        normalize_window(Map.get(params, "window_hours", defaults["window_hours"])),
      "search" => normalize_string(Map.get(params, "search", defaults["search"]))
    }
  end

  defp close_replay_modal(socket), do: assign(socket, :replay_modal_open?, false)

  defp build_path(base_path, filter_params, inbound_id) do
    params =
      filter_params
      |> Map.put("inbound_id", inbound_id)
      |> Enum.reject(fn {_key, value} -> is_nil(blank_to_nil(value)) end)
      |> Map.new()

    case URI.encode_query(params) do
      "" -> base_path
      query -> base_path <> "?" <> query
    end
  end

  # V5 input-validation allow-list: an outcome outside the closed set casts to nil
  # (the filter is dropped) and never reaches SQL.
  defp cast_enum("", _allowed), do: nil

  defp cast_enum(value, allowed) when is_binary(value) do
    enum = String.to_existing_atom(value)
    if enum in allowed, do: enum, else: nil
  rescue
    ArgumentError -> nil
  end

  defp cast_enum(_value, _allowed), do: nil

  defp parse_positive_integer(value) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp parse_positive_integer(_value), do: nil

  defp normalize_window(value) do
    value
    |> parse_positive_integer()
    |> Kernel.||(@default_window_hours)
    |> Integer.to_string()
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(_value), do: ""

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
