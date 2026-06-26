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
    DeliveriesList,
    DetailHeader,
    DestructiveAction,
    FiltersForm,
    RepairState,
    ReplayModal,
    SupportCards,
    SuppressionCard
  }

  alias MailglassAdmin.Operator.Tenants, as: TenantSelector
  alias MailglassAdmin.Operator.Timeline, as: OperatorTimeline
  alias Phoenix.LiveView.JS

  @status_values [:queued, :sent, :dispatched, :failed, :suppressed]
  @event_values Mailglass.Outbound.Delivery.__event_types__()
  @default_window_hours 168
  @status_filter_error "Status was not applied. Choose a listed status."
  @event_filter_error "Event was not applied. Choose a listed event."
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
      |> assign(:tenant_options, [])
      |> assign(:tenant_state, :none)
      |> assign(:selected_tenant_id, nil)
      |> assign(:status_values, @status_values)
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

  @impl true
  def handle_params(params, uri, socket) do
    {filter_params, filter_errors} = normalize_filter_params_with_errors(params)
    support_state = normalize_support_state(params)
    view = params["view"]
    delivery_id = blank_to_nil(params["delivery_id"])
    tenant_options = TenantSelector.list_tenants(socket.assigns.operator_actor, [])
    selected_tenant_id = blank_to_nil(filter_params["tenant_id"])

    tenant_state =
      tenant_state(selected_tenant_id, tenant_options, Map.has_key?(params, "tenant_id"))

    socket =
      socket
      |> assign(:base_path, URI.parse(uri).path || "/operator")
      |> assign(:page_uri, uri)
      |> assign(:dark_chrome, MailglassAdmin.Operator.Shell.dark_chrome?(params, socket.assigns.theme_cookie))
      |> assign(:theme_choice, MailglassAdmin.Operator.Shell.theme_choice(params, socket.assigns.theme_cookie))
      |> assign(:filter_params, filter_params)
      |> assign(:filter_form, to_form(filter_params, as: :filters))
      |> assign(:filter_errors, filter_errors)
      |> assign(:support_state, support_state)
      |> assign(:tenant_options, tenant_options)
      |> assign(:tenant_state, tenant_state)
      |> assign(:selected_tenant_id, selected_tenant_id)

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
         |> assign_delivery_state(filter_params, delivery_id)
         |> close_replay_modal()}

      true ->
        {:noreply,
         socket
         |> assign_overview_state(filter_params)
         |> close_replay_modal()}
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

      {:noreply, push_patch(socket, to: path)}
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
           socket.assigns.dark_chrome
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
     |> assign(:filter_errors, filter_errors)}
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

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         build_path(
           socket.assigns.base_path,
           %{"tenant_id" => socket.assigns.selected_tenant_id || ""},
           nil,
           socket.assigns.dark_chrome
         )
     )}
  end

  def handle_event("open_support_exemplar", params, socket) do
    support_state = support_state_from_event(params)

    delivery_id =
      blank_to_nil(params["delivery_id"]) ||
        get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)])

    {:noreply,
     push_patch(socket,
       to:
         build_path(
           socket.assigns.base_path,
           socket.assigns.filter_params,
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
       |> assign_delivery_state(socket.assigns.filter_params, delivery_id)
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
           get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)])
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
        deliveries_path: paths.deliveries,
        inbound_path: Map.get(assigns, :inbound_path, paths.inbound),
        inbound_available?: MailglassAdmin.Operator.Shell.inbound_available?()
      )

    ~H"""
    <MailglassAdmin.Operator.Shell.shell
      active={:deliveries}
      deliveries_path={@deliveries_path}
      inbound_path={@inbound_path}
      inbound_available?={@inbound_available?}
      dark_chrome={@dark_chrome}
      theme_choice={@theme_choice}
      tenant={blank_to_nil(@filter_params["tenant_id"])}
      title={if @view == :overview, do: "Operator overview", else: "Deliveries"}
      subtitle={
        if @view == :overview,
          do:
            "A task-oriented overview of your email delivery health. Navigate to Deliveries to inspect individual sends.",
          else:
            "Prove what happened to a message — inspect its event timeline, suppression state, and replay history."
      }
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
          <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />

          <%= if blank_to_nil(@filter_params["tenant_id"]) do %>
            <div data-testid="operator-overview-health" class="grid gap-md">
              <h2 class="text-heading font-bold text-base-content">Health</h2>
              <div class="grid gap-md sm:grid-cols-2 lg:grid-cols-4">
                <Components.stat_card
                  label="Recent failures"
                  value={support_metric_count(@support_summary, :failed_ingest)}
                  state={support_metric_state(@support_summary, :failed_ingest)}
                  severity={support_metric_severity(@support_summary, :failed_ingest, :error)}
                  severity_label={support_metric_severity_label(@support_summary, :failed_ingest)}
                  data-testid="operator-overview-health-failures"
                />
                <Components.stat_card
                  label="Orphan backlog"
                  value={support_metric_count(@support_summary, :orphan_backlog)}
                  state={support_metric_state(@support_summary, :orphan_backlog)}
                  severity={support_metric_severity(@support_summary, :orphan_backlog, :warning)}
                  severity_label={support_metric_severity_label(@support_summary, :orphan_backlog)}
                  data-testid="operator-overview-health-orphans"
                />
                <Components.stat_card
                  label="Active suppressions"
                  value={@suppression_count}
                  state={count_state(@suppression_count)}
                  severity={suppression_severity(@suppression_count)}
                  severity_label={suppression_severity_label(@suppression_count)}
                  data-testid="operator-overview-health-suppressions"
                />
                <Components.stat_card
                  label="Overall status"
                  value={all_clear_value(@support_summary)}
                  state={all_clear_state(@support_summary)}
                  severity={all_clear_severity(@support_summary)}
                  severity_label={all_clear_label(@support_summary)}
                  data-testid="operator-overview-health-allclear"
                />
              </div>
            </div>

            <div data-testid="operator-overview-nav" class="grid gap-md">
              <h2 class="text-heading font-bold text-base-content">Navigate</h2>
              <div class="card bg-base-200 border border-base-300 rounded-box p-md flex flex-col gap-sm">
                <div class="text-body font-bold text-base-content">View Deliveries</div>
                <div class="text-body text-secondary">
                  Search and audit outbound sends, inspect event timelines, and replay webhooks.
                </div>
                <div>
                  <.link
                    patch={
                      build_path(
                        @base_path,
                        Map.put(@filter_params, "view", "deliveries"),
                        nil,
                        @dark_chrome
                      )
                    }
                    class="btn btn-primary btn-sm min-h-11"
                  >
                    View Deliveries
                  </.link>
                </div>
              </div>
              <div class="card bg-base-200 border border-base-300 rounded-box p-md flex flex-col gap-sm">
                <div class="text-body font-bold text-base-content">View Inbound</div>
                <div class="text-body text-secondary">Inspect inbound routing and outcomes.</div>
                <div>
                  <.link navigate={@inbound_path} class="btn btn-primary btn-sm min-h-11">
                    View Inbound
                  </.link>
                </div>
              </div>
            </div>
          <% else %>
            <div
              data-testid="operator-overview-no-tenant"
              class="card bg-base-200 border border-base-300 rounded-box p-md flex flex-col gap-sm"
            >
              <div class="text-body font-bold text-base-content">Select a tenant to begin</div>
              <div class="text-body text-secondary">
                Choose a tenant to inspect its Deliveries and inbound routing. Tenant scope stays
                in the URL so refreshes and shared links keep the same view.
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
                status_values={@status_values}
                event_values={@event_values}
                window_options={@window_options}
                errors={@filter_errors}
              />

              <div class="flex flex-wrap gap-2">
                <button type="submit" class="btn btn-primary min-h-11 px-5">Open delivery</button>
                <button type="button" phx-click="clear_filters" class="btn btn-ghost min-h-11 px-5">
                  Clear filters
                </button>
              </div>
            </.form>
          </div>
        </section>

        <section
          data-testid="operator-master-detail"
          class={[
            "mt-6 grid gap-lg",
            if(@selected_delivery,
              do: "md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]",
              else: "grid-cols-1"
            )
          ]}
        >
          <aside
            data-testid="operator-deliveries-list-card"
            class={[
              "card min-w-0 rounded-box border border-base-300 bg-base-200 p-0 md:block",
              @selected_delivery && "max-md:hidden"
            ]}
          >
            <div class="border-b border-base-300 px-4 py-3">
              <h2 class="text-label uppercase font-bold text-secondary">
                Recent deliveries
              </h2>
            </div>
            <DeliveriesList.deliveries_list
              deliveries={@deliveries}
              page_meta={@deliveries_page_meta}
              previous_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :previous)}
              next_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :next)}
              selected_delivery={@selected_delivery}
              filters_active?={filters_active?(@filter_params)}
            />
          </aside>

          <section
            data-testid="operator-detail-column"
            class={[
              "min-w-0 space-y-4",
              is_nil(@selected_delivery) && "order-first md:order-none"
            ]}
          >
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
              <% is_nil(@selected_delivery) -> %>
                <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
                <div
                  data-testid="operator-empty-detail"
                  class="card hidden rounded-box border border-base-300 bg-base-200 p-6 md:block"
                >
                  <h2 class="text-body font-bold text-base-content">
                    Select a delivery to inspect its event timeline and suppression state.
                  </h2>
                  <p class="mt-2 text-body text-secondary">
                    The timeline shows provider lifecycle facts (dispatched, delivered, bounced).
                    Replay history is recorded separately — replaying a webhook does not create
                    new provider truth.
                  </p>
                </div>
              <% true -> %>
                <div
                  id={"delivery-detail-#{@selected_delivery.id}"}
                  data-region
                  class="motion-reveal space-y-4"
                  phx-remove={
                    JS.hide(
                      time: 150,
                      transition: {"ease-out duration-150", "opacity-100", "opacity-0 translate-y-1"}
                    )
                  }
                >
                  <.link
                    patch={build_path(@base_path, @filter_params, nil, @dark_chrome)}
                    data-testid="operator-detail-back"
                    class="mg-focus-ring btn btn-ghost !h-11 min-h-11 md:hidden"
                  >
                    Back to deliveries
                  </.link>
                  <DetailHeader.detail_header
                    delivery={@selected_delivery}
                    replay_targets={@replay_targets}
                    latest_replay={latest_replay(@replay_history)}
                  />
                  <SupportCards.support_cards
                    support_summary={@support_summary}
                    support_state={@support_state}
                    suppression_count={@suppression_count}
                  />
                  <OperatorTimeline.timeline
                    timeline_events={@timeline_events}
                    highlight_event_id={@support_state.event_id}
                  />
                  <SuppressionCard.suppression_card suppression_state={@suppression_state} />
                </div>
            <% end %>
          </section>
        </section>

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
    </MailglassAdmin.Operator.Shell.shell>
    """
  end

  defp default_filter_params do
    %{
      "tenant_id" => "",
      "provider" => "",
      "status" => "",
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

    {status, status_error} =
      normalize_enum_filter(params, "status", @status_values, @status_filter_error)

    {event, event_error} =
      normalize_enum_filter(params, "event", @event_values, @event_filter_error)

    {window_hours, window_error} = normalize_window_filter(params, defaults)

    filter_params = %{
      "tenant_id" => normalize_string(Map.get(params, "tenant_id", defaults["tenant_id"])),
      "provider" => normalize_string(Map.get(params, "provider", defaults["provider"])),
      "status" => status,
      "event" => event,
      "window_hours" => window_hours,
      "page" => normalize_page(params, defaults)
    }

    {filter_params,
     filter_error_map([
       {"status", status_error},
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
        status: cast_enum(filter_params["status"], @status_values),
        event: cast_enum(filter_params["event"], @event_values),
        window_hours:
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours,
        page: parse_positive_integer(filter_params["page"]) || 1,
        per_page: 5
      },
      []
    )
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

  defp assign_delivery_state(socket, filter_params, selected_delivery_id) do
    deliveries_page = load_deliveries_page(filter_params)
    deliveries = deliveries_page.entries
    selected_delivery = find_selected_delivery(deliveries, selected_delivery_id)
    replay_targets = load_replay_targets(filter_params, selected_delivery)
    replay_history = load_replay_history(filter_params, selected_delivery)

    socket
    |> assign(:view, :deliveries)
    |> assign(:deliveries, deliveries)
    |> assign(:deliveries_page_meta, page_meta_without_entries(deliveries_page))
    |> assign(:selected_delivery, selected_delivery)
    |> assign(:timeline_events, load_timeline(filter_params, selected_delivery))
    |> assign(:suppression_state, load_suppression(filter_params, selected_delivery))
    |> assign(:support_summary, load_support_summary(filter_params, selected_delivery))
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
    |> assign(:support_summary, support_summary)
    |> assign(:suppression_count, suppression_count)
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

  defp build_path(
         base_path,
         filter_params,
         delivery_id,
         dark_chrome,
         support_state \\ default_support_state()
       ) do
    params =
      filter_params
      |> Map.merge(%{"delivery_id" => delivery_id})
      |> Map.merge(support_state_to_params(support_state))
      |> maybe_put_theme(dark_chrome)
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

  defp build_path_with_view(base_path, filter_params, dark_chrome) do
    filter_params_with_view = Map.put(filter_params, "view", "deliveries")
    build_path(base_path, filter_params_with_view, nil, dark_chrome)
  end

  defp pagination_path(base_path, filter_params, dark_chrome, direction) do
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

    build_path(base_path, filter_params, nil, dark_chrome)
  end

  defp maybe_put_theme(params, true), do: Map.put(params, "theme", "dark")
  defp maybe_put_theme(params, false), do: params

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
      per_page: 5,
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

  defp load_support_summary(_filter_params, nil), do: nil

  defp load_support_summary(filter_params, _selected_delivery) do
    apply(support_summary_module(), :summarize_tenant, [
      %{
        tenant_id: filter_params["tenant_id"],
        window_hours: parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
      }
    ])
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

  defp all_clear_state(nil), do: :unavailable
  defp all_clear_state(_summary), do: :ready

  defp all_clear_label(nil), do: "Unavailable"

  defp all_clear_label(summary) do
    if all_clear?(summary), do: "All clear", else: "Needs attention"
  end

  # Short, fits-the-display-slot status token. The descriptive phrasing
  # ("All clear" / "Needs attention") rides in the severity_label below it,
  # so the big value never truncates the way a full sentence did. A nil
  # summary returns no value: all_clear_state/1 reports :unavailable, so
  # stat_card renders its own canonical placeholder rather than a hand-rolled
  # dash (STATCARD-GATE: overview cards never inline bare-dash placeholders).
  defp all_clear_value(nil), do: nil

  defp all_clear_value(summary) do
    if all_clear?(summary), do: "Clear", else: "Attention"
  end

  defp all_clear_severity(nil), do: :neutral
  defp all_clear_severity(summary), do: if(all_clear?(summary), do: :success, else: :warning)

  defp all_clear?(summary) do
    summary.failed_ingest.count == 0 and summary.orphan_backlog.count == 0
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
