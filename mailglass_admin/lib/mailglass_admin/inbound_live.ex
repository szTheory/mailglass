defmodule MailglassAdmin.InboundLive do
  @moduledoc """
  Read-only operator dashboard for recent inbound records, execution lineage,
  and routing reflection (IADM-01/02/07).

  Sibling of `MailglassAdmin.OperatorLive` (clone, not a refactor). The
  screen keeps filter and selection state in URL params so refresh, back/forward
  navigation, and copied links preserve the current operator context.

  All inbound data access crosses a runtime `apply/3` edge through
  `MailglassAdmin.OptionalDeps.MailglassInbound`. This module never
  references the optional inbound modules directly, so the `--no-optional-deps`
  compile lane stays green: when `mailglass_inbound` is absent the gateway module is
  elided, `gateway_available?/0` returns `false`, and every data call degrades to the
  empty surface.

  Tenant-required-or-empty: a blank/missing tenant renders the empty state
  and never leaks another tenant's record id or recipient. The read-model enforces
  the tenant where-clause + `Tenancy.scope/2`; this LiveView adds the
  `load_inbound_records(%{"tenant_id" => ""})` short-circuit head as defense in depth.
  Tenant-scoped operator actions must never widen visibility outside the current tenant.
  """

  use Phoenix.LiveView

  alias MailglassAdmin.Components
  alias MailglassAdmin.Inbound.DestructiveAction
  alias MailglassAdmin.Inbound.DetailHeader
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassAdmin.Inbound.FiltersForm
  alias MailglassAdmin.Inbound.Overview
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.Inbound.ReplayModal
  alias MailglassAdmin.Inbound.RoutingTrace
  alias MailglassAdmin.Inbound.Timeline
  alias Phoenix.LiveView.JS

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
  @zero_summary %{
    total: 0,
    outcomes: %{
      no_match: 0,
      accept: 0,
      ignore: 0,
      reject: 0,
      bounce: 0,
      failed: 0
    },
    unclassified: 0,
    no_match_rate: 0.0
  }

  @impl true
  def mount(_params, session, socket) do
    # The declared inbound router module is surfaced in the operator
    # session (router.ex __operator_session__) as an atom, never cookie-sourced.
    # The routing-trace card reflects its routes via the runtime gateway.
    inbound_router = session_inbound_router(session)
    tenant_id = session_tenant_id(session)

    # Live updates (IADM-05): subscribe on the CONNECTED mount only, to
    # the per-tenant inbound stream via the builder (never a literal — LINT-06 /
    # V9). The producer is `mailglass_inbound`; the payload is id-only and PII-free
    # (Pitfall 6), so handle_info re-fetches tenant-scoped before prepending.
    if connected?(socket) and is_binary(tenant_id) and tenant_id != "" do
      Phoenix.PubSub.subscribe(
        Mailglass.PubSub,
        MailglassAdmin.PubSub.Topics.inbound_record_inserted(tenant_id)
      )
    end

    {:ok,
     socket
     |> assign_new(:operator_actor, fn -> nil end)
     |> assign_new(:operator_auth, fn -> %{status: :unknown, recent_auth?: false} end)
     |> assign(:records, [])
     |> assign(:inbound_summary, @zero_summary)
     |> assign(:empty_state, :no_tenant)
     |> assign(:selected_record, nil)
     |> assign(:detail, nil)
     |> assign(:runs, [])
     |> assign(:routing_trace, [])
     |> assign(:reveal_state, :redacted)
     |> assign(:inbound_router, inbound_router)
     |> assign(:detail_error, nil)
     |> assign(:replay_modal_open?, false)
     |> assign(:base_path, "/inbound")
     |> assign(:page_uri, "/inbound")
     |> assign(:dark_chrome, false)
     |> assign(:outcome_values, @outcome_values)
     |> assign(:window_options, @window_options)
     |> assign(:filter_params, default_filter_params())
     |> assign(:filter_form, to_form(default_filter_params(), as: :filters))
     |> assign(:page_title, "mailglass — Inbound")}
  end

  defp session_inbound_router(session) when is_map(session),
    do: Map.get(session, "inbound_router")

  defp session_inbound_router(_session), do: nil

  defp session_tenant_id(session) when is_map(session), do: Map.get(session, "tenant_id")
  defp session_tenant_id(_session), do: nil

  @impl true
  def handle_params(params, uri, socket) do
    filter_params = normalize_filter_params(params)

    {:noreply,
     socket
     |> assign(:base_path, URI.parse(uri).path || "/inbound")
     |> assign(:page_uri, uri)
     |> assign(:dark_chrome, MailglassAdmin.Operator.Shell.dark_chrome?(params))
     |> assign(:filter_params, filter_params)
     |> assign(:filter_form, to_form(filter_params, as: :filters))
     |> assign_inbound_state(filter_params, blank_to_nil(params["inbound_id"]))
     |> close_replay_modal()}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    normalized = normalize_filter_params(filters)

    {:noreply,
     push_patch(socket,
       to: build_path(socket.assigns.base_path, normalized, nil, socket.assigns.dark_chrome)
     )}
  end

  def handle_event("toggle_theme", _params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         MailglassAdmin.Operator.Shell.toggle_theme_path(
           socket.assigns.page_uri,
           socket.assigns.dark_chrome
         )
     )}
  end

  def handle_event("validate_filters", %{"filters" => filters}, socket) do
    {:noreply,
     assign(socket, :filter_form, to_form(normalize_filter_params(filters), as: :filters))}
  end

  def handle_event("select_inbound", %{"id" => inbound_id}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         build_path(
           socket.assigns.base_path,
           socket.assigns.filter_params,
           inbound_id,
           socket.assigns.dark_chrome
         )
     )}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     push_patch(socket, to: socket.assigns.base_path <> theme_query(socket.assigns.dark_chrome))}
  end

  def handle_event("open_replay", _params, socket) do
    {:noreply, assign(socket, :replay_modal_open?, true)}
  end

  def handle_event("close_replay", _params, socket) do
    {:noreply, close_replay_modal(socket)}
  end

  # Evidence reveal (IADM-02) — capability-gated by the :reveal_raw atom over the
  # SAME Auth.authorize/3 seam as replay (no new auth surface, -09). On grant
  # the evidence card renders the raw payload read-only; on denial the redacted
  # placeholder stays and a brand-voice line explains the gate.
  def handle_event("reveal_raw", _params, socket) do
    {:noreply, assign(socket, :reveal_state, authorize_reveal(socket))}
  end

  # Replay confirm flow (IADM-03). Simplified clone of OperatorLive's confirm_replay
  # (no multi-target branch, -08). The gate order is load-bearing:
  #
  #   1. TENANT gate (-05): rejects a guessed foreign-tenant id BEFORE the
  #      gateway replay call. `Internal.Replay.replay/2` is now itself tenant-scoped
  #      (T-49-17) — this admin-side check stays as defense-in-depth, no longer the
  #      sole cross-tenant defense.
  #   2. CAPABILITY gate (V6): `:replay_inbound` over the existing Auth seam.
  #   3. REPLAY: structured errors mapped to UI-SPEC copy by matching the
  #      STRUCT/tuple, never the message string (CLAUDE.md rule 7). A :no_match
  #      record can never replay (V11 / Pitfall 1) — the button is disabled AND the
  #      tuple is mapped here for the render→click race.
  def handle_event("confirm_replay", _params, socket) do
    with {:ok, record} <- selected_replayable_record(socket),
         :ok <- verify_tenant(record, socket.assigns.filter_params),
         {:ok, socket} <-
           DestructiveAction.authorize(
             socket,
             socket.assigns.operator_auth[:adapter],
             record
           ),
         {:ok, _result} <- replay_record(record) do
      {:noreply,
       socket
       |> assign_inbound_state(socket.assigns.filter_params, record.id)
       |> close_replay_modal()
       |> put_flash(
         :info,
         "Replay recorded. A new replay run was appended to this InboundMessage's timeline."
       )}
    else
      {:error, :no_selection} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."
         )}

      {:error, :cross_tenant} ->
        {:noreply,
         socket
         |> close_replay_modal()
         |> put_flash(
           :error,
           "Replay blocked: this action is not authorized for the current operator."
         )}

      {:error, {:auth, message}} ->
        {:noreply,
         socket
         |> close_replay_modal()
         |> put_flash(:error, message)}

      {:error, reason} ->
        {:noreply,
         socket
         |> close_replay_modal()
         |> put_flash(:error, replay_error_copy(reason))}
    end
  end

  # Live update (IADM-05 / -11, Pitfall 6): the broadcast payload is id-only.
  # Re-fetch the record TENANT-SCOPED through the gateway; if it resolves to nil
  # (foreign tenant or filtered out) drop it; otherwise PREPEND to the list WITHOUT
  # stealing the current selection or resetting filters.
  @impl true
  def handle_info({:inbound_record_inserted, record_id, _meta}, socket) do
    {:noreply, prepend_live_record(socket, record_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    paths =
      MailglassAdmin.Operator.Shell.surface_paths(
        assigns.base_path,
        :inbound,
        assigns.dark_chrome
      )

    assigns =
      assign(assigns,
        deliveries_path: paths.deliveries,
        inbound_path: paths.inbound,
        inbound_available?: MailglassAdmin.Operator.Shell.inbound_available?()
      )

    ~H"""
    <MailglassAdmin.Operator.Shell.shell
      active={:inbound}
      deliveries_path={@deliveries_path}
      inbound_path={@inbound_path}
      inbound_available?={@inbound_available?}
      dark_chrome={@dark_chrome}
      tenant={blank_to_nil(@filter_params["tenant_id"])}
      title="Inbound records"
      subtitle="See why an InboundMessage routed the way it did — execution timeline, routing trace, and raw evidence."
      flash={@flash}
    >
      <section
        data-testid="inbound-filters"
        class="card rounded-box border border-base-300 bg-base-200 p-4 md:p-5"
      >
        <button
          type="button"
          phx-click={JS.toggle(to: "#inbound-filter-panel")}
          data-testid="inbound-filters-toggle"
          class="btn btn-ghost !h-11 min-h-11 md:hidden"
        >
          Filters <span aria-hidden="true">v</span>
        </button>

        <div id="inbound-filter-panel" class="hidden md:block">
          <.form
            for={@filter_form}
            id="inbound-filters"
            phx-change="validate_filters"
            phx-submit="apply_filters"
            class="mt-4 grid gap-sm md:mt-0"
          >
            <div class="grid gap-sm md:grid-cols-2 xl:grid-cols-5">
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
        </div>
      </section>

      <section
        data-testid="inbound-master-detail"
        class="mt-6 grid gap-lg md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]"
      >
        <div class={["space-y-4", @selected_record && "max-md:hidden"]}>
          <Overview.overview summary={@inbound_summary} />

          <aside
            data-testid="inbound-records-list-card"
            class={[
              "card rounded-box border border-base-300 bg-base-200 p-0 md:block",
              @selected_record && "max-md:hidden"
            ]}
          >
            <div class="border-b border-base-300 px-4 py-3">
              <h2 class="text-label uppercase font-bold text-secondary">
                Recent InboundMessages
              </h2>
            </div>
            <RecordsList.records_list
              records={@records}
              selected_record={@selected_record}
              empty_state={@empty_state}
            />
          </aside>
        </div>

        <section
          data-testid="inbound-detail-column"
          class={[
            "space-y-4",
            is_nil(@selected_record) && "order-first md:order-none"
          ]}
        >
          <%= cond do %>
            <% @detail_error -> %>
              <div
                data-testid="inbound-detail-error"
                class="card rounded-box border border-error bg-base-100 p-6"
              >
                <div class="flex items-center gap-2">
                  <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
                  <h2 class="text-body font-bold text-base-content">
                    InboundMessage not loaded: selected record is outside the current tenant or active filters. Refresh the page or adjust the filters, then try again.
                  </h2>
                </div>
              </div>
            <% is_nil(@detail) -> %>
              <MailglassAdmin.Operator.Shell.orientation_strip surface={:inbound} />
              <div
                data-testid="inbound-empty-detail"
                class="card rounded-box border border-base-300 bg-base-200 p-6"
              >
                <h2 class="text-body font-bold text-base-content">
                  Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence.
                </h2>
              </div>
            <% true -> %>
              <div
                id={"inbound-detail-#{@detail.record.id}"}
                class="motion-reveal space-y-4"
                phx-remove={JS.hide(time: 150, transition: {"ease-out duration-150", "opacity-100", "opacity-0 translate-y-1"})}
              >
                <.link
                  patch={build_path(@base_path, @filter_params, nil, @dark_chrome)}
                  data-testid="inbound-detail-back"
                  class="btn btn-ghost !h-11 min-h-11 md:hidden"
                >
                  Back to inbound records
                </.link>
                <DetailHeader.detail_header detail={@detail} />
                <Timeline.timeline runs={@runs} />
                <RoutingTrace.routing_trace
                  :if={@detail[:outcome] == :no_match}
                  trace={@routing_trace}
                />
                <EvidenceCard.evidence_card
                  evidence={@detail[:evidence]}
                  reveal_state={@reveal_state}
                />
              </div>
          <% end %>
        </section>
      </section>

      <%!-- Focus-management parity with the operator modal: phx-mounted moves focus into the modal on open; phx-remove returns focus to the trigger on close. Not a focus trap — pure LiveView JS. --%>
      <span
        :if={@replay_modal_open?}
        phx-mounted={JS.focus_first(to: "#inbound-replay-modal")}
        phx-remove={JS.focus(to: "#inbound-replay-open-btn")}
      />
      <ReplayModal.replay_modal open?={@replay_modal_open?} record={selected_record_struct(@detail)} />
    </MailglassAdmin.Operator.Shell.shell>
    """
  end

  # ---------------------------------------------------------------------------
  # State aggregation — list + selected record + timeline + detail in one pass
  # through the runtime gateway (apply/3). No bare optional-inbound reference.
  # ---------------------------------------------------------------------------

  defp assign_inbound_state(socket, filter_params, selected_inbound_id) do
    records = load_inbound_records(filter_params)
    detail = load_selected_detail(filter_params, selected_inbound_id)
    runs = load_selected_timeline(filter_params, selected_inbound_id, detail)
    {detail, runs} = filter_selected_detail(detail, runs, filter_params)

    selected_record =
      find_selected_record(records, selected_inbound_id) || list_projection_from_detail(detail)

    socket
    |> assign(:records, records)
    |> assign(:inbound_summary, load_inbound_summary(filter_params))
    |> assign(:empty_state, empty_state_for(filter_params, records))
    |> assign(:selected_record, selected_record)
    |> assign(:detail, detail)
    |> assign(:runs, runs)
    |> assign(:routing_trace, routing_trace_for(socket.assigns.inbound_router, detail))
    # Selecting (or re-selecting) a record collapses the evidence card back to
    # redacted — reveal is a per-view capability action, never sticky across
    # selections.
    |> assign(:reveal_state, :redacted)
    |> assign(:detail_error, detail_error_for(selected_inbound_id, detail))
  end

  # Routing-trace data (IADM-04) — ONLY for a :no_match record. Reflected from the
  # adopter's declared inbound router via the runtime gateway (-06); the view
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

  # ---------------------------------------------------------------------------
  # Replay confirm flow (IADM-03) — tenant gate + capability gate + structured
  # error → UI-SPEC copy.
  # ---------------------------------------------------------------------------

  # The replayable record is the loaded detail's canonical struct (tenant-resolved
  # by the read-model). A selected id that did NOT resolve to a detail (a foreign
  # tenant's id, or a deleted/forged id) surfaces as a `detail_error` — confirming
  # replay against it is blocked as not-authorized (the tenant gate -05 fired
  # at the read-model BEFORE replay/2). A confirm with no selection at all is a
  # no-selection no-op.
  defp selected_replayable_record(%{assigns: %{detail: %{record: record}}}), do: {:ok, record}

  defp selected_replayable_record(%{assigns: %{detail_error: error}}) when not is_nil(error),
    do: {:error, :cross_tenant}

  defp selected_replayable_record(_socket), do: {:error, :no_selection}

  # -05 cross-tenant gate: the active tenant comes from filter_params; the
  # record's tenant_id must match it. (The detail read-model already tenant-scopes
  # the load; this is belt-and-suspenders directly before the un-scoped replay/2.)
  defp verify_tenant(%{tenant_id: tenant_id}, %{"tenant_id" => active})
       when is_binary(tenant_id) and tenant_id == active and active != "",
       do: :ok

  defp verify_tenant(_record, _filter_params), do: {:error, :cross_tenant}

  # `record` is already tenant-resolved (read-model load) AND verify_tenant/2 has
  # confirmed record.tenant_id == active tenant. Thread that tenant_id into the
  # tenant-scoped replay/2 (T-49-17): the admin gate is now backed by a replay seam
  # that refuses cross-tenant ids by construction, not just by this caller's check.
  defp replay_record(%{id: record_id, tenant_id: tenant_id}) do
    if gateway_available?() do
      apply(@gateway, :replay, [record_id, [tenant_id: tenant_id]])
    else
      {:error, :unavailable}
    end
  end

  # Map the structured replay errors to UI-SPEC copy by matching the tuple/struct,
  # never the message string (CLAUDE.md rule 7).
  defp replay_error_copy({:replay_mailbox_missing, _details}),
    do: "Replay blocked: mailbox module not found."

  defp replay_error_copy(:not_found),
    do:
      "InboundMessage not loaded: selected record is outside the current tenant or active filters. Refresh the page or adjust the filters, then try again."

  defp replay_error_copy(:unavailable),
    do: "Replay blocked: the inbound package is not available."

  defp replay_error_copy(_reason),
    do:
      "InboundMessage not loaded: selected record is outside the current tenant or active filters. Refresh the page or adjust the filters, then try again."

  defp empty_state_for(%{"tenant_id" => tenant_id}, _records) when tenant_id in [nil, ""],
    do: :no_tenant

  defp empty_state_for(filter_params, []) do
    cond do
      filters_active?(filter_params) -> :filtered
      tenant_has_inbound_history?(filter_params) -> :filtered
      true -> :truly_empty
    end
  end

  defp empty_state_for(_filter_params, _records), do: :filtered

  defp filters_active?(filter_params) do
    Enum.any?(["provider", "search", "outcome"], fn key ->
      not is_nil(blank_to_nil(Map.get(filter_params, key)))
    end) or
      non_default_window?(Map.get(filter_params, "window_hours")) or
      non_default_window?(Map.get(filter_params, "recent_window_hours"))
  end

  defp non_default_window?(nil), do: false
  defp non_default_window?(""), do: false

  defp non_default_window?(value) do
    parse_positive_integer(value) != @default_window_hours
  end

  defp tenant_has_inbound_history?(filter_params) do
    filter_params
    |> tenant_history_params()
    |> load_inbound_records()
    |> Enum.any?()
  end

  defp tenant_history_params(filter_params) do
    %{
      "tenant_id" => filter_params["tenant_id"],
      "provider" => "",
      "outcome" => "",
      "window_hours" => Integer.to_string(@default_window_hours * 5200),
      "search" => ""
    }
  end

  # ---------------------------------------------------------------------------
  # Live-update prepend (IADM-05) — tenant-scoped re-fetch, no selection/filter theft.
  # ---------------------------------------------------------------------------

  defp prepend_live_record(socket, record_id) do
    filter_params = socket.assigns.filter_params

    case fetch_live_record(filter_params, record_id) do
      nil ->
        socket

      record ->
        records = socket.assigns.records

        if Enum.any?(records, &(&1.id == record.id)) do
          socket
        else
          assign(socket, :records, [record | records])
        end
    end
  end

  # Re-fetch the inserted record tenant-scoped. Reuses the list read-model and
  # picks the matching id so the projection shape matches the existing list rows
  # (and a foreign-tenant / filtered-out id resolves to nil).
  defp fetch_live_record(%{"tenant_id" => ""}, _record_id), do: nil

  defp fetch_live_record(filter_params, record_id) do
    filter_params
    |> load_inbound_records()
    |> Enum.find(&(&1.id == record_id))
  end

  # Tenant-required-or-empty (-04) — the load-bearing security head BEFORE any
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
            parse_positive_integer(filter_params["window_hours"]) || @default_window_hours,
          search: blank_to_nil(filter_params["search"])
        },
        []
      ])
    else
      []
    end
  end

  defp load_inbound_summary(%{"tenant_id" => tenant_id})
       when tenant_id in [nil, ""],
       do: @zero_summary

  defp load_inbound_summary(filter_params) do
    if gateway_available?() do
      summary_filters = %{
        tenant_id: filter_params["tenant_id"],
        provider: blank_to_nil(filter_params["provider"]),
        window_hours:
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours,
        search: blank_to_nil(filter_params["search"])
      }

      apply(@gateway, :summary, [summary_filters, []])
    else
      @zero_summary
    end
  end

  defp load_detail(%{"tenant_id" => ""}, _selected_inbound_id), do: nil
  defp load_detail(_filter_params, nil), do: nil

  defp load_detail(filter_params, selected_inbound_id) do
    if valid_uuid?(selected_inbound_id) and gateway_available?() do
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
    if valid_uuid?(selected_inbound_id) and gateway_available?() do
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

  defp load_selected_detail(_filter_params, nil), do: nil

  defp load_selected_detail(filter_params, selected_inbound_id),
    do: load_detail(filter_params, selected_inbound_id)

  defp load_selected_timeline(_filter_params, nil, _detail), do: []
  defp load_selected_timeline(_filter_params, _selected_inbound_id, nil), do: []

  defp load_selected_timeline(filter_params, selected_inbound_id, _detail),
    do: load_timeline(filter_params, selected_inbound_id)

  defp filter_selected_detail(nil, _runs, _filter_params), do: {nil, []}

  defp filter_selected_detail(detail, runs, filter_params) do
    if detail_matches_active_filters?(detail, runs, filter_params) do
      {detail, runs}
    else
      {nil, []}
    end
  end

  defp detail_matches_active_filters?(%{record: record}, runs, filter_params) do
    detail_matches_provider?(record, filter_params) and
      detail_matches_search?(record, filter_params) and
      detail_matches_window?(record, filter_params) and
      detail_matches_outcome?(runs, filter_params)
  end

  defp detail_matches_provider?(record, filter_params) do
    case blank_to_nil(Map.get(filter_params, "provider")) do
      nil -> true
      provider -> Map.get(record, :provider) == provider
    end
  end

  defp detail_matches_search?(record, filter_params) do
    case blank_to_nil(Map.get(filter_params, "search")) do
      nil ->
        true

      search ->
        needle = String.downcase(search)

        [
          Map.get(record, :subject),
          Map.get(record, :envelope_recipient),
          Map.get(record, :provider_message_id)
        ]
        |> Enum.any?(&case_insensitive_contains?(&1, needle))
    end
  end

  defp detail_matches_window?(record, filter_params) do
    window_hours =
      parse_positive_integer(Map.get(filter_params, "window_hours")) || @default_window_hours

    since = DateTime.add(DateTime.utc_now(), -window_hours, :hour)

    case Map.get(record, :received_at) do
      %DateTime{} = received_at -> DateTime.compare(received_at, since) != :lt
      _received_at -> false
    end
  end

  defp detail_matches_outcome?(runs, filter_params) do
    case cast_enum(Map.get(filter_params, "outcome"), @outcome_values) do
      nil -> true
      outcome -> Enum.any?(runs, &(&1.outcome == outcome))
    end
  end

  defp case_insensitive_contains?(value, needle) when is_binary(value) do
    value
    |> String.downcase()
    |> String.contains?(needle)
  end

  defp case_insensitive_contains?(_value, _needle), do: false

  defp list_projection_from_detail(nil), do: nil

  defp list_projection_from_detail(%{record: record} = detail) do
    %{
      id: Map.get(record, :id),
      tenant_id: Map.get(record, :tenant_id),
      provider: Map.get(record, :provider),
      provider_message_id: Map.get(record, :provider_message_id),
      message_id: Map.get(record, :message_id),
      envelope_recipient: Map.get(record, :envelope_recipient),
      subject: Map.get(record, :subject),
      received_at: Map.get(record, :received_at),
      inserted_at: Map.get(record, :inserted_at),
      suppression_flagged: Map.get(record, :suppression_flagged),
      outcome: Map.get(detail, :outcome),
      mailbox: Map.get(detail, :mailbox)
    }
  end

  defp valid_uuid?(value) when is_binary(value) do
    match?({:ok, _uuid}, Ecto.UUID.cast(value))
  end

  defp valid_uuid?(_value), do: false

  # A selected id with no resolvable detail (wrong tenant, deleted, never existed)
  # surfaces the bordered detail-error band rather than a silent blank pane.
  defp detail_error_for(nil, _detail), do: nil
  defp detail_error_for(_inbound_id, nil), do: :not_found
  defp detail_error_for(_inbound_id, _detail), do: nil

  defp selected_record_struct(nil), do: nil
  defp selected_record_struct(%{record: record}), do: record

  defp gateway_available? do
    inbound_gateway_enabled?() and Code.ensure_loaded?(@gateway) and @gateway.available?()
  end

  defp inbound_gateway_enabled? do
    Application.get_env(:mailglass_admin, :inbound_gateway_available?, true)
  end

  # Rides the existing Auth.authorize/3 atom() action type with :reveal_raw — no
  # new auth module/plug/behaviour (-09). Returns :revealed on grant, :denied
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
      "window_hours" => normalize_window(Map.get(params, "window_hours", defaults["window_hours"])),
      "search" => normalize_string(Map.get(params, "search", defaults["search"]))
    }
  end

  defp close_replay_modal(socket), do: assign(socket, :replay_modal_open?, false)

  defp build_path(base_path, filter_params, inbound_id, dark_chrome) do
    params =
      filter_params
      |> Map.put("inbound_id", inbound_id)
      |> maybe_put_theme(dark_chrome)
      |> Enum.reject(fn {_key, value} -> is_nil(blank_to_nil(value)) end)
      |> Map.new()

    case URI.encode_query(params) do
      "" -> base_path
      query -> base_path <> "?" <> query
    end
  end

  defp maybe_put_theme(params, true), do: Map.put(params, "theme", "dark")
  defp maybe_put_theme(params, false), do: params

  defp theme_query(true), do: "?theme=dark"
  defp theme_query(false), do: ""

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
