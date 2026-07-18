defmodule MailglassAdmin.OperatorLive do
  @moduledoc """
  Read-only operator dashboard for recent deliveries, timeline history,
  and suppression visibility.

  The screen keeps filter and selection state in URL params so refresh,
  back/forward navigation, and copied links preserve the current
  operator context. All data access stays behind the core operator read
  model modules.
  """

  use Phoenix.LiveView

  alias Mailglass.Operator.{Deliveries, ReplayHistory, ReplayTargets, Suppressions}
  alias Mailglass.Webhook.Replay
  alias Mailglass.Operator.Timeline, as: OperatorTimelineData
  alias MailglassAdmin.Components

  alias MailglassAdmin.Operator.{
    Accounts,
    DeliveriesList,
    DetailHeader,
    DestructiveAction,
    FiltersForm,
    QuickView,
    RepairState,
    ReplayModal,
    SupportCards,
    SuppressionCard
  }

  alias MailglassAdmin.Operator.Tenants, as: TenantSelector
  alias MailglassAdmin.Operator.Timeline, as: OperatorTimeline
  alias Phoenix.LiveView.JS

  @event_values Mailglass.Outbound.Delivery.__event_types__()
  @default_window_hours 168
  @deliveries_per_page 20
  @event_filter_error "Status was not applied. Choose a listed status."
  @window_filter_error "Time window was not applied. Choose a positive listed time window."
  @window_options [
    {"Last 24 hours", "24"},
    {"Last 7 days", "168"},
    {"Last 30 days", "720"}
  ]

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: send(self(), :canonicalize_tenant)

    socket =
      socket
      |> assign_new(:operator_actor, fn -> nil end)
      |> assign_new(:operator_auth, fn -> %{status: :unknown, recent_auth?: false} end)
      |> assign(:view, :overview)
      |> assign(:full_detail?, false)
      |> assign(:deliveries, [])
      |> assign(:deliveries_page_meta, empty_page_meta())
      |> assign(:selected_delivery, nil)
      |> assign(:timeline_events, [])
      |> assign(:suppression_state, nil)
      |> assign(:suppression_count, nil)
      |> assign(:support_summary, nil)
      |> assign(:support_state, default_support_state())
      |> assign(:detail_error, nil)
      |> assign(:replay_targets, nil)
      |> assign(:replay_history, [])
      |> assign(:replay_modal_open?, false)
      |> assign(:replay_selected_target_id, nil)
      |> assign(:recent_auth_at, get_in(socket.assigns, [:operator_actor, :recent_auth_at]))
      |> assign(:base_path, "/operator")
      |> assign(:page_uri, "/operator")
      |> assign(:dark_chrome, false)
      |> assign(:theme_choice, :system)
      |> assign(:theme_cookie, theme_cookie_value(session))
      |> assign(:preview_path, navigation_path(session, :preview_path))
      |> assign(:account_labels, session_account_labels(session))
      |> assign(:tenant_options, [])
      |> assign(:tenant_state, :none)
      |> assign(:selected_tenant_id, nil)
      |> assign(:provider_options, [])
      |> assign(:event_values, @event_values)
      |> assign(:window_options, @window_options)
      |> assign(:filter_params, default_filter_params())
      |> assign(:filter_form, to_form(default_filter_params(), as: :filters))
      |> assign(:filter_errors, %{})
      |> assign(:page_title, "mailglass — Operator")

    {:ok, socket}
  end

  # Persisted theme cookie value, surfaced into the LiveView via the router's
  # operator session callback (`__operator_session__` → "admin_chrome_theme_cookie").
  # The shell resolves theme from this when the URL carries no explicit ?theme=.
  defp theme_cookie_value(session) when is_map(session),
    do: Map.get(session, "admin_chrome_theme_cookie")

  defp theme_cookie_value(_session), do: nil

  defp navigation_path(%{"navigation" => navigation}, key) when is_map(navigation) do
    blank_to_nil(Map.get(navigation, key) || Map.get(navigation, Atom.to_string(key)))
  end

  defp navigation_path(_session, _key), do: nil

  defp session_account_labels(session) when is_map(session),
    do: Accounts.normalize_labels(Map.get(session, "account_labels"))

  defp session_account_labels(_session), do: %{}

  @impl true
  def handle_params(params, uri, socket) do
    if redirect_path = MailglassAdmin.Theme.legacy_query_redirect_path(params, uri) do
      {:noreply, redirect(socket, to: redirect_path)}
    else
      {filter_params, filter_errors} = normalize_filter_params_with_errors(params)
      support_state = normalize_support_state(params)
      view = params["view"]
      delivery_id = blank_to_nil(params["delivery_id"])
      full? = params["full"] == "1" and not is_nil(delivery_id)

      tenant_options =
        TenantSelector.list_tenants(socket.assigns.operator_actor,
          account_labels: socket.assigns.account_labels
        )

      selected_tenant_id = blank_to_nil(filter_params["tenant_id"])
      theme_choice = MailglassAdmin.Operator.Shell.theme_choice(%{}, socket.assigns.theme_cookie)

      tenant_state =
        tenant_state(selected_tenant_id, tenant_options, Map.has_key?(params, "tenant_id"))

      provider_options = load_provider_options(filter_params)

      socket =
        socket
        |> assign(:base_path, URI.parse(uri).path || "/operator")
        |> assign(:page_uri, uri)
        |> assign(:dark_chrome, theme_choice == :dark)
        |> assign(:theme_choice, theme_choice)
        |> assign(:filter_params, filter_params)
        |> assign(:filter_form, to_form(filter_params, as: :filters))
        |> assign(:filter_errors, filter_errors)
        |> assign(:support_state, support_state)
        |> assign(:tenant_options, tenant_options)
        |> assign(:tenant_state, tenant_state)
        |> assign(:selected_tenant_id, selected_tenant_id)
        |> assign(:provider_options, provider_options)

      if connected?(socket) and tenant_state == :auto_select do
        send(self(), :canonicalize_tenant)
      end

      cond do
        tenant_state == :auto_select ->
          {:noreply, clear_surface_state(socket) |> close_replay_modal()}

        tenant_state in [:select_required, :none] ->
          {:noreply, clear_surface_state(socket) |> close_replay_modal()}

        view == "deliveries" or not is_nil(delivery_id) ->
          {:noreply,
           socket
           |> assign_delivery_state(filter_params, delivery_id, full?, support_focus?(support_state))
           |> close_replay_modal()}

        true ->
          {:noreply,
           socket
           |> assign_overview_state(filter_params)
           |> close_replay_modal()}
      end
    end
  end

  @impl true
  def handle_info(:canonicalize_tenant, %{assigns: %{tenant_state: :auto_select}} = socket) do
    [tenant] = socket.assigns.tenant_options

    {:noreply,
     push_patch(socket,
       to: MailglassAdmin.Operator.Shell.tenant_switch_path(socket.assigns.page_uri, tenant.id)
     )}
  end

  def handle_info(:canonicalize_tenant, socket), do: {:noreply, socket}

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    {normalized, filter_errors} = normalize_filter_params_with_errors(filters)

    if map_size(filter_errors) == 0 do
      path =
        if socket.assigns[:view] == :deliveries do
          build_path_with_view(socket.assigns.base_path, normalized, socket.assigns.dark_chrome)
        else
          build_path(socket.assigns.base_path, normalized, nil, socket.assigns.dark_chrome)
        end

      # Applying filters that don't change the location is a no-op: push_patch to the
      # current URL would still re-run handle_params and re-render (reloading the list
      # and re-localizing timestamps) for no reason — the visible "flicker on Apply".
      if same_location?(socket.assigns.page_uri, path) do
        {:noreply, socket}
      else
        {:noreply, push_patch(socket, to: path)}
      end
    else
      {:noreply,
       socket
       |> assign(:filter_form, to_form(normalized, as: :filters))
       |> assign(:filter_errors, filter_errors)}
    end
  end

  def handle_event("toggle_theme", _params, socket) do
    {:noreply,
     redirect(socket,
       to:
         MailglassAdmin.Operator.Shell.toggle_theme_path(
           socket.assigns.page_uri,
           socket.assigns.theme_choice == :dark
         )
     )}
  end

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    {:noreply,
     redirect(socket,
       to: MailglassAdmin.Operator.Shell.set_theme_path(socket.assigns.page_uri, theme)
     )}
  end

  def handle_event("validate_filters", %{"filters" => filters}, socket) do
    {normalized, filter_errors} = normalize_filter_params_with_errors(filters)

    {:noreply,
     socket
     |> assign(:filter_form, to_form(normalized, as: :filters))
     |> assign(:filter_errors, filter_errors)
     |> assign(:provider_options, load_provider_options(normalized))}
  end

  def handle_event("select_delivery", %{"id" => delivery_id}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         build_path(
           socket.assigns.base_path,
           socket.assigns.filter_params,
           delivery_id,
           socket.assigns.dark_chrome
         )
     )}
  end

  # Close the Quick view / Full detail — drop delivery_id (+ full + support-focus),
  # returning to the deliveries LIST (view=deliveries, not the overview). Used by the
  # Escape key; the ✕ and scrim are `<.link patch>`s that target the same list path.
  def handle_event("close_detail", _params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         build_path_with_view(
           socket.assigns.base_path,
           socket.assigns.filter_params,
           socket.assigns.dark_chrome
         )
     )}
  end

  # Prev/next through the loaded page (the `‹ ›` buttons). Preserves the current
  # tier (quick view vs full detail) so flipping works at both.
  def handle_event("nav_record", %{"dir" => dir}, socket) do
    navigate_record(socket, dir)
  end

  # Keyboard mirror of the `‹ ›` buttons + Enter/Escape. Bound only while the Quick
  # view is open (see `keyboard?`), so it cannot hijack typing in the filters (which
  # are inert behind the scrim). Unknown keys are no-ops.
  def handle_event("detail_key", %{"key" => key}, socket) do
    case key do
      k when k in ["ArrowUp", "ArrowLeft", "k"] ->
        navigate_record(socket, "prev")

      k when k in ["ArrowDown", "ArrowRight", "j"] ->
        navigate_record(socket, "next")

      "Enter" ->
        case socket.assigns.selected_delivery do
          %{id: id} ->
            {:noreply,
             push_patch(socket,
               to:
                 detail_path(
                   socket.assigns.base_path,
                   socket.assigns.filter_params,
                   id,
                   socket.assigns.dark_chrome,
                   true
                 )
             )}

          _ ->
            {:noreply, socket}
        end

      "Escape" ->
        {:noreply,
         push_patch(socket,
           to:
             build_path_with_view(
               socket.assigns.base_path,
               socket.assigns.filter_params,
               socket.assigns.dark_chrome
             )
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("clear_filters", _params, socket) do
    filter_params = %{
      "tenant_id" => socket.assigns.selected_tenant_id || "",
      "view" => "deliveries"
    }

    {:noreply,
     push_patch(socket,
       to: build_path(socket.assigns.base_path, filter_params, nil, socket.assigns.dark_chrome)
     )}
  end

  def handle_event("open_support_exemplar", params, socket) do
    support_state = support_state_from_event(params)

    delivery_id =
      blank_to_nil(params["delivery_id"]) ||
        get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)])

    # Support cards render in Full detail; keep the operator there when drilling into
    # an exemplar from a selected delivery (otherwise the drill-down would drop to the
    # Quick view, which does not show the cards).
    filter_params =
      if socket.assigns.full_detail? and not is_nil(delivery_id),
        do: Map.put(socket.assigns.filter_params, "full", "1"),
        else: socket.assigns.filter_params

    {:noreply,
     push_patch(socket,
       to:
         build_path(
           socket.assigns.base_path,
           filter_params,
           delivery_id,
           socket.assigns.dark_chrome,
           support_state
         )
     )}
  end

  def handle_event("open_replay", _params, socket) do
    {:noreply,
     socket
     |> assign(:replay_modal_open?, true)
     |> assign(
       :replay_selected_target_id,
       default_replay_target_id(socket.assigns.replay_targets)
     )}
  end

  def handle_event("close_replay", _params, socket) do
    {:noreply, close_replay_modal(socket)}
  end

  def handle_event("choose_replay_target", %{"webhook_event_id" => webhook_event_id}, socket) do
    {:noreply, assign(socket, :replay_selected_target_id, blank_to_nil(webhook_event_id))}
  end

  def handle_event(
        "choose_replay_target",
        %{"replay" => %{"webhook_event_id" => webhook_event_id}},
        socket
      ) do
    {:noreply, assign(socket, :replay_selected_target_id, blank_to_nil(webhook_event_id))}
  end

  def handle_event("confirm_replay", _params, socket) do
    with %{id: delivery_id, tenant_id: tenant_id} = delivery <-
           socket.assigns.selected_delivery || {:error, :no_selected_delivery},
         {:ok, target} <-
           selected_replay_target(
             socket.assigns.replay_targets,
             socket.assigns.replay_selected_target_id
           ),
         {:ok, socket} <-
           DestructiveAction.authorize(
             socket,
             socket.assigns.operator_auth[:adapter],
             delivery,
             target
           ),
         {:ok, result} <-
           Replay.execute(%{
             tenant_id: tenant_id,
             delivery_id: delivery_id,
             webhook_event_id: target.webhook_event_id,
             actor: socket.assigns.operator_actor
           }) do
      {:noreply,
       socket
       |> assign_delivery_state(socket.assigns.filter_params, delivery_id, true, false)
       |> close_replay_modal()
       |> put_flash(:info, RepairState.flash_success(result.status))}
    else
      {:error, :no_selected_delivery} ->
        {:noreply, put_flash(socket, :error, "Select a delivery before replaying a webhook.")}

      {:error, :unavailable} ->
        {:noreply, put_flash(socket, :error, "Replay is unavailable for this delivery.")}

      {:error, :target_required} ->
        {:noreply, put_flash(socket, :error, "Choose one webhook target before confirming replay.")}

      {:error, {:auth, message}} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign_delivery_state(
           socket.assigns.filter_params,
           get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)]),
           true,
           false
         )
         |> put_flash(:error, RepairState.flash_failure(reason))}
    end
  end

  @impl true
  def render(assigns) do
    paths =
      MailglassAdmin.Operator.Shell.surface_paths(
        assigns.base_path,
        :deliveries,
        assigns.dark_chrome,
        blank_to_nil(assigns.filter_params["tenant_id"])
      )

    assigns =
      assign(assigns,
        preview_path: assigns.preview_path,
        overview_path: paths.overview,
        deliveries_path: paths.deliveries,
        inbound_path: Map.get(assigns, :inbound_path, paths.inbound),
        inbound_available?: MailglassAdmin.Operator.Shell.inbound_available?()
      )

    ~H"""
    <MailglassAdmin.Operator.Shell.shell
      active={@view}
      preview_path={@preview_path}
      overview_path={@overview_path}
      deliveries_path={@deliveries_path}
      inbound_path={@inbound_path}
      inbound_available?={@inbound_available?}
      dark_chrome={@dark_chrome}
      theme_choice={@theme_choice}
      title={if @view == :overview, do: "Email health", else: "Deliveries"}
      subtitle={page_subtitle(@view)}
      flash={@flash}
    >
      <%= if @tenant_state in [:select_required, :none] do %>
        <MailglassAdmin.Operator.Shell.tenant_selector
          state={@tenant_state}
          tenant_options={@tenant_options}
          current_uri={@page_uri}
        />
      <% else %>
        <%= if @view == :overview do %>
          <div data-testid="operator-overview" class="grid gap-lg">
            <%= if blank_to_nil(@filter_params["tenant_id"]) do %>
              <div data-testid="operator-overview-health" class="grid gap-md">
                <div class="grid gap-md sm:grid-cols-3">
                  <.link
                    patch={
                      build_path(
                        @base_path,
                        @filter_params
                        |> Map.put("view", "deliveries")
                        |> Map.put("event", "failed"),
                        nil,
                        @dark_chrome
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View recent failures in Deliveries"
                    data-testid="operator-overview-health-failures-link"
                  >
                    <Components.stat_card
                      label="Recent failures"
                      value={support_metric_count(@support_summary, :failed_ingest)}
                      state={support_metric_state(@support_summary, :failed_ingest)}
                      severity={support_metric_severity(@support_summary, :failed_ingest, :warning)}
                      severity_label={support_metric_severity_label(@support_summary, :failed_ingest)}
                      hint="Mailglass could not process these provider events in the last 24 hours. Open Deliveries to find the affected message and retry or replay from evidence."
                      data-testid="operator-overview-health-failures"
                    />
                  </.link>
                  <.link
                    patch={
                      unmatched_events_path(
                        @base_path,
                        @filter_params,
                        @dark_chrome,
                        @support_summary
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View unmatched webhook evidence in Deliveries"
                    data-testid="operator-overview-health-orphans-link"
                  >
                    <Components.stat_card
                      label="Unmatched webhooks"
                      value={support_metric_count(@support_summary, :orphan_backlog)}
                      state={support_metric_state(@support_summary, :orphan_backlog)}
                      severity={support_metric_severity(@support_summary, :orphan_backlog, :warning)}
                      severity_label={
                        support_metric_severity_label(@support_summary, :orphan_backlog)
                      }
                      hint="Provider webhooks Mailglass received but has not linked to a delivery. Check whether the webhook arrived before the send was recorded, or whether provider IDs changed."
                      data-testid="operator-overview-health-orphans"
                    />
                  </.link>
                  <.link
                    patch={
                      build_path(
                        @base_path,
                        @filter_params
                        |> Map.put("view", "deliveries")
                        |> Map.put("event", "suppressed"),
                        nil,
                        @dark_chrome
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View active suppressions in Deliveries"
                    data-testid="operator-overview-health-suppressions-link"
                  >
                    <Components.stat_card
                      label="Active suppressions"
                      value={@suppression_count}
                      state={count_state(@suppression_count)}
                      severity={suppression_severity(@suppression_count)}
                      severity_label={suppression_severity_label(@suppression_count)}
                      hint="Recipients currently blocked from sends. Open suppressed Deliveries to confirm the reason before removing a suppression."
                      data-testid="operator-overview-health-suppressions"
                    />
                  </.link>
                </div>
              </div>

              <p
                :if={
                  @support_summary && all_clear?(@support_summary) &&
                    @suppression_count in [0, nil]
                }
                class="text-body text-secondary"
              >
                Email delivery is healthy — nothing needs your attention right now.
              </p>

              <div
                :if={
                  @support_summary && all_clear?(@support_summary) &&
                    @suppression_count in [0, nil]
                }
                data-testid="operator-overview-orientation"
              >
                <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
              </div>
            <% else %>
              <div
                data-testid="operator-overview-no-tenant"
                class="card bg-base-200 border border-base-300 rounded-box p-md flex flex-col gap-sm"
              >
                <div class="text-body font-bold text-base-content">Choose an account to begin</div>
                <div class="text-body text-secondary">
                  Pick the customer account whose email activity you want to inspect. Mailglass keeps
                  that account boundary in the URL as <code class="mono">tenant_id</code> so refreshes
                  and shared links stay scoped.
                </div>
                <div>
                  <.link navigate={@deliveries_path} class="btn btn-primary btn-sm min-h-11">
                    Go to Deliveries
                  </.link>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <%= cond do %>
            <% @deliveries == [] and not filters_active?(@filter_params) and @filter_errors == %{} -> %>
              <%!-- Genuine no-data: a single calm pane only — operator-empty-truly + orientation strip.
                  The filters toolbar, the Open-delivery CTA, and the entire master-detail grid (and
                  therefore the "Select a delivery…" helper nested inside it) are all withheld.
                  An in-progress invalid filter submission (@filter_errors non-empty) is NOT genuine
                  no-data — the toolbar stays so the operator sees the recovery copy and Clear-filters. --%>
              <div class="space-y-lg">
                <section
                  data-testid="operator-deliveries-empty-pane"
                  class="card min-w-0 rounded-box border border-base-300 bg-base-200 p-0"
                >
                  <DeliveriesList.deliveries_list
                    deliveries={[]}
                    page_meta={@deliveries_page_meta}
                    previous_page_path={
                      pagination_path(@base_path, @filter_params, @dark_chrome, :previous)
                    }
                    next_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :next)}
                    filters_active?={false}
                  />
                </section>
                <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
              </div>
            <% true -> %>
              <%= if @full_detail? and (@selected_delivery || @detail_error) do %>
                <%!-- FULL DETAIL: the complete record on its own, full width (list hidden).
                    Reached from the Quick view's "Open full detail" or a &full=1 deep link. --%>
                <div data-testid="operator-detail-column" class="space-y-4">
                  <.link
                    patch={
                      build_path(
                        @base_path,
                        @filter_params,
                        @selected_delivery && @selected_delivery.id,
                        @dark_chrome
                      )
                    }
                    data-testid="operator-detail-back"
                    class="mg-focus-ring btn btn-ghost !h-11 min-h-11"
                  >
                    <span aria-hidden="true" class="mr-xs">←</span> Back to deliveries
                  </.link>

                  <%= cond do %>
                    <% @detail_error -> %>
                      <div
                        data-testid="operator-detail-error"
                        class="card rounded-box border border-error bg-base-100 p-6"
                      >
                        <div class="flex items-center gap-2">
                          <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
                          <h2 class="text-body font-bold text-base-content">
                            Delivery data could not be loaded. Refresh the page or adjust the filters, then try again.
                          </h2>
                        </div>
                      </div>
                    <% true -> %>
                      <div
                        id={"delivery-detail-#{@selected_delivery.id}"}
                        data-region
                        class="motion-reveal space-y-4"
                      >
                        <DetailHeader.detail_header
                          delivery={@selected_delivery}
                          replay_targets={@replay_targets}
                          latest_replay={latest_replay(@replay_history)}
                          account_labels={@account_labels}
                        />
                        <%!-- Event timeline leads: it is the record-specific "what happened"
                            evidence the operator came to read. Suppression state (also
                            record-specific) follows; the account-level support cards trail. --%>
                        <OperatorTimeline.timeline
                          timeline_events={@timeline_events}
                          highlight_event_id={@support_state.event_id}
                        />
                        <SuppressionCard.suppression_card suppression_state={@suppression_state} />
                        <SupportCards.support_cards
                          support_summary={@support_summary}
                          support_state={@support_state}
                          suppression_count={@suppression_count}
                        />
                      </div>
                  <% end %>
                </div>
              <% else %>
                <%!-- LIST PAGE: filters + optional support-focus evidence + full-width list.
                    The Quick view overlay (below) sits on top when a record is focused. --%>
                <section
                  data-testid="operator-filters"
                  class="card rounded-box border border-base-300 bg-base-200 p-4 md:p-5"
                >
                  <button
                    type="button"
                    phx-click={JS.toggle(to: "#operator-filter-panel")}
                    data-testid="operator-filters-toggle"
                    class="btn btn-ghost !h-11 min-h-11 md:hidden"
                  >
                    Filters <span aria-hidden="true">v</span>
                  </button>

                  <div id="operator-filter-panel" class="hidden md:block">
                    <.form
                      for={@filter_form}
                      id="operator-filters"
                      phx-change="validate_filters"
                      phx-submit="apply_filters"
                      class="mt-4 grid gap-md md:mt-0"
                    >
                      <FiltersForm.fields
                        form={@filter_form}
                        account_options={
                          Accounts.field_options(
                            @tenant_options,
                            @filter_params["tenant_id"],
                            @account_labels
                          )
                        }
                        provider_options={@provider_options}
                        event_values={@event_values}
                        window_options={@window_options}
                        errors={@filter_errors}
                      />

                      <div class="flex flex-wrap gap-2">
                        <button type="submit" class="btn btn-primary min-h-11 px-5">
                          Apply filters
                        </button>
                        <button
                          type="button"
                          phx-click="clear_filters"
                          class="btn btn-ghost min-h-11 px-5"
                        >
                          Clear filters
                        </button>
                      </div>
                    </.form>
                  </div>
                </section>

                <div
                  :if={support_focus?(@support_state) and is_nil(@selected_delivery)}
                  data-testid="operator-support-focus-detail"
                  class="mt-6 motion-reveal space-y-4"
                >
                  <div class="rounded-box border border-base-300 bg-base-200 p-md">
                    <h2 class="text-body font-bold text-base-content">
                      {support_focus_title(@support_state)}
                    </h2>
                    <p class="mt-xs text-body text-secondary">{support_focus_body(@support_state)}</p>
                  </div>
                  <SupportCards.support_cards
                    support_summary={@support_summary}
                    support_state={@support_state}
                    suppression_count={@suppression_count}
                  />
                </div>

                <section data-testid="operator-master-detail" class="mt-6">
                  <aside
                    data-testid="operator-deliveries-list-card"
                    class="card min-w-0 rounded-box border border-base-300 bg-base-200 p-0"
                  >
                    <div class="border-b border-base-300 px-4 py-3">
                      <h2 class="text-label uppercase font-bold text-secondary">Recent deliveries</h2>
                    </div>
                    <DeliveriesList.deliveries_list
                      deliveries={@deliveries}
                      page_meta={@deliveries_page_meta}
                      account_labels={@account_labels}
                      show_account?={false}
                      previous_page_path={
                        pagination_path(@base_path, @filter_params, @dark_chrome, :previous)
                      }
                      next_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :next)}
                      selected_delivery={@selected_delivery}
                      filters_active?={filters_active?(@filter_params)}
                    />
                  </aside>
                </section>
              <% end %>

              <%!-- Quick view (peek) overlay: a record is focused and we are NOT in Full detail. --%>
              <QuickView.quick_view
                :if={not @full_detail? and (@selected_delivery != nil or @detail_error != nil)}
                delivery={@selected_delivery}
                detail_error={@detail_error}
                account_labels={@account_labels}
                full_path={
                  detail_path(
                    @base_path,
                    @filter_params,
                    @selected_delivery && @selected_delivery.id,
                    @dark_chrome,
                    true
                  )
                }
                close_path={build_path_with_view(@base_path, @filter_params, @dark_chrome)}
                previous_path={
                  neighbor_path("prev", @deliveries, @selected_delivery, @base_path, @filter_params, @dark_chrome, false)
                }
                next_path={
                  neighbor_path("next", @deliveries, @selected_delivery, @base_path, @filter_params, @dark_chrome, false)
                }
                position={record_position(@deliveries, @selected_delivery, @deliveries_page_meta)}
                keyboard?={not @replay_modal_open?}
              />

              <%!-- Focus trap: phx-mounted moves focus into the modal on open; phx-remove returns focus to trigger on close --%>
              <span
                :if={@replay_modal_open?}
                phx-mounted={JS.focus_first(to: "#operator-replay-modal")}
                phx-remove={JS.focus(to: "#replay-open-btn")}
              />
              <ReplayModal.replay_modal
                open?={@replay_modal_open?}
                delivery={@selected_delivery}
                replay_targets={@replay_targets}
                selected_target_id={@replay_selected_target_id}
              />
          <% end %>
        <% end %>
      <% end %>
    </MailglassAdmin.Operator.Shell.shell>
    """
  end

  defp default_filter_params do
    %{
      "tenant_id" => "",
      "provider" => "",
      "event" => "",
      "window_hours" => Integer.to_string(@default_window_hours),
      "page" => "1"
    }
  end

  defp tenant_state(nil, [], _tenant_param_present?), do: :none
  defp tenant_state(nil, [_tenant], false), do: :auto_select
  defp tenant_state(nil, _tenants, _tenant_param_present?), do: :select_required
  defp tenant_state(_selected_tenant_id, _tenants, _tenant_param_present?), do: :selected

  defp clear_surface_state(socket) do
    socket
    |> assign(:view, :overview)
    |> assign(:full_detail?, false)
    |> assign(:deliveries, [])
    |> assign(:deliveries_page_meta, empty_page_meta())
    |> assign(:selected_delivery, nil)
    |> assign(:timeline_events, [])
    |> assign(:suppression_state, nil)
    |> assign(:support_summary, nil)
    |> assign(:suppression_count, nil)
    |> assign(:detail_error, nil)
    |> assign(:replay_targets, nil)
    |> assign(:replay_history, [])
    |> assign(:replay_selected_target_id, nil)
  end

  defp filters_active?(filter_params) do
    Map.drop(filter_params, ["tenant_id", "window_hours", "page"]) !=
      Map.drop(default_filter_params(), ["tenant_id", "window_hours", "page"])
  end

  defp normalize_filter_params_with_errors(params) do
    defaults = default_filter_params()

    {event, event_error} =
      normalize_enum_filter(params, "event", @event_values, @event_filter_error)

    {window_hours, window_error} = normalize_window_filter(params, defaults)

    filter_params = %{
      "tenant_id" => normalize_string(Map.get(params, "tenant_id", defaults["tenant_id"])),
      "provider" => normalize_string(Map.get(params, "provider", defaults["provider"])),
      "event" => event,
      "window_hours" => window_hours,
      "page" => normalize_page(params, defaults)
    }

    {filter_params,
     filter_error_map([
       {"event", event_error},
       {"window_hours", window_error}
     ])}
  end

  defp load_deliveries_page(%{"tenant_id" => ""}), do: empty_page_meta()

  defp load_deliveries_page(filter_params) do
    Deliveries.list_recent_deliveries_page(
      %{
        tenant_id: filter_params["tenant_id"],
        provider: blank_to_nil(filter_params["provider"]),
        event: cast_enum(filter_params["event"], @event_values),
        window_hours:
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours,
        page: parse_positive_integer(filter_params["page"]) || 1,
        per_page: @deliveries_per_page
      },
      []
    )
  end

  defp load_provider_options(filter_params) do
    selected_provider = blank_to_nil(filter_params["provider"])

    case blank_to_nil(filter_params["tenant_id"]) do
      nil ->
        []

      tenant_id ->
        providers =
          Deliveries.list_providers(%{
            tenant_id: tenant_id,
            window_hours:
              parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
          })

        providers =
          if selected_provider && selected_provider not in providers do
            [selected_provider | providers]
          else
            providers
          end

        providers
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort_by(&String.downcase/1)
        |> Enum.map(&{provider_label(&1), &1})
    end
  end

  defp provider_label("sendgrid"), do: "SendGrid"
  defp provider_label("postmark"), do: "Postmark"
  defp provider_label("mailgun"), do: "Mailgun"
  defp provider_label("ses"), do: "SES"

  defp provider_label(provider) when is_binary(provider) do
    provider
    |> String.replace(["_", "-"], " ")
    |> String.split(" ", trim: true)
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp load_timeline(_filter_params, nil), do: []

  defp load_timeline(filter_params, delivery) do
    OperatorTimelineData.list_delivery_events(
      %{
        tenant_id: filter_params["tenant_id"],
        delivery_id: delivery.id
      },
      []
    )
  end

  defp load_suppression(_filter_params, nil), do: nil

  defp load_suppression(filter_params, delivery) do
    Suppressions.get_delivery_suppression_state(
      %{
        tenant_id: filter_params["tenant_id"],
        recipient: delivery.recipient,
        stream: delivery.stream
      },
      []
    )
  end

  defp find_selected_delivery(_deliveries, nil), do: nil

  defp find_selected_delivery(deliveries, delivery_id),
    do: Enum.find(deliveries, &(&1.id == delivery_id))

  defp detail_error_for(nil, _selected_delivery), do: nil
  defp detail_error_for(_delivery_id, nil), do: :not_found
  defp detail_error_for(_delivery_id, _selected_delivery), do: nil

  defp load_replay_targets(_filter_params, nil), do: nil

  defp load_replay_targets(filter_params, delivery) do
    case ReplayTargets.list_delivery_targets(%{
           tenant_id: filter_params["tenant_id"],
           delivery_id: delivery.id
         }) do
      {:ok, targets} ->
        targets

      {:error, _reason} ->
        %{status: :unavailable, reason: :missing_replay_linkage, candidates: []}
    end
  end

  defp load_replay_history(_filter_params, nil), do: []

  defp load_replay_history(filter_params, delivery) do
    ReplayHistory.list_delivery_replay_history(%{
      tenant_id: filter_params["tenant_id"],
      delivery_id: delivery.id
    })
  end

  # Two-tier load: the Quick view (peek) renders purely from the list-row projection
  # already in `deliveries`, so flipping records fires NO extra queries. The heavy
  # evidence — event timeline, suppression state, replay targets/history — loads only
  # in Full detail (`full?`). `support_summary` is loaded for Full detail and for a
  # support-focus drill-down (both render SupportCards); the Quick view skips it.
  defp assign_delivery_state(socket, filter_params, selected_delivery_id, full?, support_focus?) do
    deliveries_page = load_deliveries_page(filter_params)
    deliveries = deliveries_page.entries
    selected_delivery = find_selected_delivery(deliveries, selected_delivery_id)

    replay_targets = if full?, do: load_replay_targets(filter_params, selected_delivery), else: nil
    replay_history = if full?, do: load_replay_history(filter_params, selected_delivery), else: []
    timeline = if full?, do: load_timeline(filter_params, selected_delivery), else: []
    suppression = if full?, do: load_suppression(filter_params, selected_delivery), else: nil

    support_summary =
      if full? or support_focus?,
        do: load_support_summary(filter_params, selected_delivery),
        else: nil

    socket
    |> assign(:view, :deliveries)
    |> assign(:full_detail?, full?)
    |> assign(:deliveries, deliveries)
    |> assign(:deliveries_page_meta, page_meta_without_entries(deliveries_page))
    |> assign(:selected_delivery, selected_delivery)
    |> assign(:timeline_events, timeline)
    |> assign(:suppression_state, suppression)
    |> assign(:support_summary, support_summary)
    |> assign(:detail_error, detail_error_for(selected_delivery_id, selected_delivery))
    |> assign(:replay_targets, replay_targets)
    |> assign(:replay_history, replay_history)
    |> assign(
      :replay_selected_target_id,
      preserve_replay_selection(replay_targets, socket.assigns[:replay_selected_target_id])
    )
  end

  defp assign_overview_state(socket, filter_params) do
    tenant_id = blank_to_nil(filter_params["tenant_id"])

    support_summary =
      if tenant_id do
        try do
          apply(support_summary_module(), :summarize_tenant, [
            %{
              tenant_id: tenant_id,
              window_hours:
                parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
            }
          ])
        rescue
          _ -> nil
        end
      else
        nil
      end

    suppression_count =
      if tenant_id do
        try do
          apply(suppression_count_module(), :count_active_suppressions, [tenant_id])
        rescue
          _ -> nil
        end
      else
        nil
      end

    paths =
      MailglassAdmin.Operator.Shell.surface_paths(
        socket.assigns.base_path,
        :deliveries,
        socket.assigns.dark_chrome,
        blank_to_nil(socket.assigns.filter_params["tenant_id"])
      )

    socket
    |> assign(:view, :overview)
    |> assign(:full_detail?, false)
    |> assign(:support_summary, support_summary)
    |> assign(:suppression_count, suppression_count)
    |> assign(:overview_path, paths.overview)
    |> assign(:inbound_path, paths.inbound)
    |> assign(:deliveries, [])
    |> assign(:deliveries_page_meta, empty_page_meta())
    |> assign(:selected_delivery, nil)
    |> assign(:timeline_events, [])
    |> assign(:suppression_state, nil)
    |> assign(:detail_error, nil)
    |> assign(:replay_targets, nil)
    |> assign(:replay_history, [])
    |> assign(:replay_selected_target_id, nil)
  end

  defp close_replay_modal(socket) do
    socket
    |> assign(:replay_modal_open?, false)
    |> assign(:replay_selected_target_id, default_replay_target_id(socket.assigns.replay_targets))
  end

  defp preserve_replay_selection(
         %{status: :ambiguous, candidates: candidates},
         selected_target_id
       )
       when is_binary(selected_target_id) do
    if Enum.any?(candidates, &(&1.webhook_event_id == selected_target_id)) do
      selected_target_id
    else
      nil
    end
  end

  defp preserve_replay_selection(replay_targets, _selected_target_id),
    do: default_replay_target_id(replay_targets)

  defp default_replay_target_id(%{status: :exact, candidate: candidate}),
    do: candidate.webhook_event_id

  defp default_replay_target_id(_replay_targets), do: nil

  defp selected_replay_target(nil, _selected_target_id), do: {:error, :unavailable}

  defp selected_replay_target(%{status: :unavailable}, _selected_target_id),
    do: {:error, :unavailable}

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

  defp latest_replay([]), do: nil
  defp latest_replay(replay_history), do: List.last(replay_history)

  defp health_metric_link_class do
    "group block rounded-box mg-focus-ring transition-transform ease-out duration-(--duration-fast) hover:-translate-y-px"
  end

  defp build_path(
         base_path,
         filter_params,
         delivery_id,
         _dark_chrome,
         support_state \\ default_support_state()
       ) do
    params =
      filter_params
      |> Map.merge(%{"delivery_id" => delivery_id})
      |> Map.merge(support_state_to_params(support_state))
      |> Enum.reject(fn
        {"page", "1"} -> true
        {_key, value} -> is_nil(blank_to_nil(value))
      end)
      |> Map.new()

    case URI.encode_query(params) do
      "" -> base_path
      query -> base_path <> "?" <> query
    end
  end

  # Full-detail path = the record's URL plus `full=1`, merged into the params map (not
  # appended) so it sorts with the other keys. build_path drops a nil id (and page=1);
  # we only add `full` when there is an id to attach it to.
  defp detail_path(base_path, filter_params, delivery_id, dark_chrome, full?) do
    filter_params =
      if full? and not is_nil(delivery_id),
        do: Map.put(filter_params, "full", "1"),
        else: filter_params

    build_path(base_path, filter_params, delivery_id, dark_chrome)
  end

  # Prev/next id within the loaded page, relative to the current selection. Returns nil
  # at the page edges (no wrap) and when there is no selection.
  defp neighbor_id(deliveries, %{id: id}, dir) do
    count = length(deliveries)

    case Enum.find_index(deliveries, &(&1.id == id)) do
      nil ->
        nil

      index ->
        case neighbor_index(index, dir, count) do
          nil -> nil
          neighbor -> deliveries |> Enum.at(neighbor) |> record_id()
        end
    end
  end

  defp neighbor_id(_deliveries, _selected, _dir), do: nil

  defp neighbor_index(index, "prev", _count) when index > 0, do: index - 1
  defp neighbor_index(index, "next", count) when index < count - 1, do: index + 1
  defp neighbor_index(_index, _dir, _count), do: nil

  defp record_id(%{id: id}), do: id
  defp record_id(_record), do: nil

  defp neighbor_path(dir, deliveries, selected_delivery, base_path, filter_params, dark_chrome, full?) do
    case neighbor_id(deliveries, selected_delivery, dir) do
      nil -> nil
      id -> detail_path(base_path, filter_params, id, dark_chrome, full?)
    end
  end

  # "N of M" position across the whole result set (page offset + local index).
  defp record_position(deliveries, %{id: id}, page_meta) do
    with index when is_integer(index) <- Enum.find_index(deliveries, &(&1.id == id)),
         total when is_integer(total) <- Map.get(page_meta, :total_count) do
      page = Map.get(page_meta, :page, 1)
      per_page = Map.get(page_meta, :per_page, @deliveries_per_page)
      %{index: (page - 1) * per_page + index + 1, total: total}
    else
      _ -> nil
    end
  end

  defp record_position(_deliveries, _selected, _page_meta), do: nil

  defp navigate_record(socket, dir) do
    case neighbor_id(socket.assigns.deliveries, socket.assigns.selected_delivery, dir) do
      nil ->
        {:noreply, socket}

      id ->
        {:noreply,
         push_patch(socket,
           to:
             detail_path(
               socket.assigns.base_path,
               socket.assigns.filter_params,
               id,
               socket.assigns.dark_chrome,
               socket.assigns.full_detail?
             )
         )}
    end
  end

  # True when a target path points at the same location as the current URL — same path
  # and same query params (order-independent). Used to skip needless re-renders.
  defp same_location?(current_uri, target_path) do
    current = URI.parse(current_uri)
    target = URI.parse(target_path)

    (current.path || "/") == (target.path || "/") and
      URI.decode_query(current.query || "") == URI.decode_query(target.query || "")
  end

  defp build_path_with_view(base_path, filter_params, _dark_chrome) do
    filter_params_with_view = Map.put(filter_params, "view", "deliveries")
    build_path(base_path, filter_params_with_view, nil, false)
  end

  defp unmatched_events_path(base_path, filter_params, dark_chrome, support_summary) do
    support_state = %{
      focus: :orphan_backlog,
      event_id: orphan_backlog_event_id(support_summary),
      webhook_event_id: nil
    }

    build_path(
      base_path,
      Map.put(filter_params, "view", "deliveries"),
      nil,
      dark_chrome,
      support_state
    )
  end

  defp orphan_backlog_event_id(%{orphan_backlog: %{oldest: %{event_id: event_id}}})
       when is_binary(event_id),
       do: event_id

  defp orphan_backlog_event_id(_support_summary), do: nil

  defp pagination_path(base_path, filter_params, _dark_chrome, direction) do
    page = parse_positive_integer(filter_params["page"]) || 1

    next_page =
      case direction do
        :previous -> max(page - 1, 1)
        :next -> page + 1
      end

    filter_params =
      filter_params
      |> Map.put("page", Integer.to_string(next_page))
      |> Map.put("view", "deliveries")

    build_path(base_path, filter_params, nil, false)
  end

  defp cast_enum("", _allowed), do: nil

  defp cast_enum(value, allowed) when is_binary(value) do
    enum = String.to_existing_atom(value)

    if enum in allowed, do: enum, else: nil
  rescue
    ArgumentError -> nil
  end

  defp parse_positive_integer(value) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp parse_positive_integer(_value), do: nil

  defp normalize_page(params, defaults) do
    params
    |> Map.get("page", defaults["page"])
    |> parse_positive_integer()
    |> case do
      nil -> defaults["page"]
      page -> Integer.to_string(page)
    end
  end

  defp empty_page_meta do
    %{
      entries: [],
      total_count: 0,
      page: 1,
      per_page: @deliveries_per_page,
      total_pages: 0,
      has_previous?: false,
      has_next?: false
    }
  end

  defp page_meta_without_entries(page) when is_map(page), do: Map.delete(page, :entries)

  defp normalize_enum_filter(params, field, allowed, message) do
    value = normalize_string(Map.get(params, field, ""))

    cond do
      value == "" -> {"", nil}
      enum_string_allowed?(value, allowed) -> {value, nil}
      true -> {"", message}
    end
  end

  defp enum_string_allowed?(value, allowed) do
    Enum.any?(allowed, &(Atom.to_string(&1) == value))
  end

  defp normalize_window_filter(params, defaults) do
    raw_value = Map.get(params, "window_hours", defaults["window_hours"])
    raw_string = normalize_string(raw_value)

    case parse_positive_integer(raw_value) do
      integer when is_integer(integer) ->
        {Integer.to_string(integer), nil}

      nil when raw_string == "" ->
        {Integer.to_string(@default_window_hours), nil}

      nil ->
        {Integer.to_string(@default_window_hours), @window_filter_error}
    end
  end

  defp filter_error_map(entries) do
    entries
    |> Enum.reject(fn {_field, error} -> is_nil(error) end)
    |> Map.new()
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(_value), do: ""

  defp default_support_state do
    %{focus: nil, event_id: nil, webhook_event_id: nil}
  end

  defp normalize_support_state(params) do
    %{
      focus: normalize_support_focus(params["support_focus"]),
      event_id: blank_to_nil(params["support_event_id"]),
      webhook_event_id: blank_to_nil(params["support_webhook_event_id"])
    }
  end

  defp normalize_support_focus("failed_ingest"), do: :failed_ingest
  defp normalize_support_focus("orphan_backlog"), do: :orphan_backlog
  defp normalize_support_focus("replay_outcomes"), do: :replay_outcomes
  defp normalize_support_focus("reconcile_facts"), do: :reconcile_facts
  defp normalize_support_focus(_value), do: nil

  defp support_state_from_event(params) do
    %{
      focus: normalize_support_focus(params["focus"]),
      event_id: blank_to_nil(params["event_id"]),
      webhook_event_id: blank_to_nil(params["webhook_event_id"])
    }
  end

  defp support_state_to_params(%{
         focus: focus,
         event_id: event_id,
         webhook_event_id: webhook_event_id
       }) do
    %{
      "support_focus" => support_focus_param(focus),
      "support_event_id" => event_id,
      "support_webhook_event_id" => webhook_event_id
    }
  end

  defp support_focus_param(nil), do: nil
  defp support_focus_param(focus), do: Atom.to_string(focus)

  defp page_subtitle(:overview),
    do: "Check recent failures, unmatched webhooks, and active suppressions for this account."

  defp page_subtitle(:deliveries),
    do:
      "Prove what happened to a message — inspect its event timeline, suppression state, and replay history."

  defp load_support_summary(filter_params, _selected_delivery) do
    case blank_to_nil(filter_params["tenant_id"]) do
      nil ->
        nil

      tenant_id ->
        apply(support_summary_module(), :summarize_tenant, [
          %{
            tenant_id: tenant_id,
            window_hours:
              parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
          }
        ])
    end
  end

  defp support_summary_module, do: :"Elixir.Mailglass.Operator.SupportSummary"
  defp suppression_count_module, do: :"Elixir.Mailglass.Operator.Suppressions"

  defp support_metric_count(nil, _metric), do: nil

  defp support_metric_count(summary, metric) do
    summary
    |> Map.get(metric, %{})
    |> Map.get(:count)
    |> normalize_stat_count()
  end

  defp support_metric_state(summary, metric),
    do: count_state(support_metric_count(summary, metric))

  defp support_metric_severity(summary, metric, attention_severity) do
    case support_metric_count(summary, metric) do
      count when is_integer(count) and count > 0 -> attention_severity
      count when is_integer(count) -> :success
      _count -> :neutral
    end
  end

  defp support_metric_severity_label(summary, metric) do
    case support_metric_count(summary, metric) do
      count when is_integer(count) and count > 0 -> "Needs attention"
      count when is_integer(count) -> "All clear"
      _count -> "Unavailable"
    end
  end

  defp count_state(count) when is_integer(count), do: :ready
  defp count_state(_count), do: :unavailable

  defp suppression_severity(count) when is_integer(count), do: :info
  defp suppression_severity(_count), do: :neutral

  defp suppression_severity_label(count) when is_integer(count), do: "Tracked"
  defp suppression_severity_label(_count), do: "Unavailable"

  defp normalize_stat_count(count) when is_integer(count), do: count
  defp normalize_stat_count(_count), do: nil

  defp all_clear?(summary) do
    summary.failed_ingest.count == 0 and summary.orphan_backlog.count == 0
  end

  defp support_focus?(%{focus: focus}), do: not is_nil(focus)
  defp support_focus?(_support_state), do: false

  defp support_focus_title(%{focus: :orphan_backlog}), do: "Unmatched webhook evidence"
  defp support_focus_title(%{focus: :failed_ingest}), do: "Failure evidence"
  defp support_focus_title(%{focus: :replay_outcomes}), do: "Replay evidence"
  defp support_focus_title(%{focus: :reconcile_facts}), do: "Reconcile evidence"
  defp support_focus_title(_support_state), do: "Support evidence"

  defp support_focus_body(%{focus: :orphan_backlog}),
    do:
      "Review provider webhooks Mailglass received but has not linked to a delivery. These can arrive before the send record is visible, or with provider identifiers that need reconciliation."

  defp support_focus_body(%{focus: :failed_ingest}),
    do: "Review provider events Mailglass could not process in the current support window."

  defp support_focus_body(%{focus: :replay_outcomes}),
    do: "Review the latest replay outcome and its recorded audit trail."

  defp support_focus_body(%{focus: :reconcile_facts}),
    do: "Review reconciliation facts that explain how unmatched provider events were linked."

  defp support_focus_body(_support_state),
    do: "Review account-scoped support facts from the current support window."

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
