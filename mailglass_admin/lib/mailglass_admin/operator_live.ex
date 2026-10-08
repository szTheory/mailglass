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

  alias Mailglass.Operator.{
    Deliveries,
    ReplayHistory,
    ReplayTargets,
    SupportSummary,
    Suppressions
  }

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
    ReplayAction,
    ReplayModal,
    SupportCards,
    SuppressionCard
  }

  alias MailglassAdmin.Operator.Tenants, as: TenantSelector
  alias MailglassAdmin.Operator.Timeline, as: OperatorTimeline
  alias Phoenix.LiveView.JS

  @event_values Mailglass.Outbound.Delivery.__event_types__()
  @default_window_hours 168
  # A million hours is roughly 114 years, leaving DateTime and PostgreSQL
  # timestamp arithmetic comfortably inside their supported ranges.
  @max_window_hours 1_000_000
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
      |> assign_new(:operator_read_fault, fn -> nil end)
      |> assign(:view, :overview)
      |> assign(:full_detail?, false)
      |> assign(:deliveries, [])
      |> assign(:deliveries_page_meta, empty_page_meta())
      |> assign(:deliveries_read_state, :ready)
      |> assign(:deliveries_loaded_for, nil)
      |> assign(:selected_delivery, nil)
      |> assign(:requested_delivery_id, nil)
      |> assign(:quick_view_focus_return_id, nil)
      |> assign(:timeline_events, [])
      |> assign(:timeline_state, :ready)
      |> assign(:selected_timeline_event, nil)
      |> assign(:suppression_state, nil)
      |> assign(:suppression_read_state, :ready)
      |> assign(:suppression_count, nil)
      |> assign(:support_summary, nil)
      |> assign(:support_state, default_support_state())
      |> assign(:support_exact_evidence, default_support_exact_evidence())
      |> assign(:health_panel_states, default_health_panel_states())
      |> assign(:health_observed_at, nil)
      |> assign(:health_window, nil)
      |> assign(:health_loaded_for, nil)
      |> assign(:detail_error, nil)
      |> assign(:replay_targets, nil)
      |> assign(:replay_history, [])
      |> assign(:replay_history_read_state, :ready)
      |> assign(:replay_command_feedback, nil)
      |> assign(:replay_modal_open?, false)
      |> assign(:replay_selected_target_id, nil)
      |> assign(:replay_review_snapshot, nil)
      |> assign(:replay_review_id, nil)
      |> assign(:replay_review_consumed?, false)
      |> assign(:replay_pending?, false)
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
      |> assign(:events_topic, nil)
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
        |> assign(:filter_form, to_form(filter_draft_params(params, filter_params), as: :filters))
        |> assign(:filter_errors, filter_errors)
        |> assign(:support_state, support_state)
        |> assign(:tenant_options, tenant_options)
        |> assign(:tenant_state, tenant_state)
        |> assign(:selected_tenant_id, selected_tenant_id)
        |> assign(:provider_options, provider_options)
        |> sync_event_subscription(selected_tenant_id, tenant_state)

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
           |> assign_delivery_state(
             filter_params,
             delivery_id,
             full?,
             support_focus?(support_state)
           )
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

  def handle_info(
        {:delivery_updated, _delivery_id, _event_type, metadata},
        %{assigns: %{selected_tenant_id: tenant_id}} = socket
      )
      when is_binary(tenant_id) and is_map(metadata) do
    if matching_tenant?(metadata, tenant_id) do
      {:noreply, refresh_visible_state(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:delivery_updated, _delivery_id, _event_type, _metadata}, socket),
    do: {:noreply, socket}

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
       |> assign(:filter_form, to_form(filter_draft_params(filters, normalized), as: :filters))
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
     |> assign(:filter_form, to_form(filter_draft_params(filters, normalized), as: :filters))
     |> assign(:filter_errors, filter_errors)
     |> assign(:provider_options, load_provider_options(normalized))}
  end

  def handle_event("select_delivery", %{"id" => delivery_id} = params, socket) do
    select_delivery(socket, delivery_id, params)
  end

  def handle_event("select_delivery", %{"delivery-id" => delivery_id} = params, socket) do
    select_delivery(socket, delivery_id, params)
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
    replay_targets =
      load_replay_targets(
        socket.assigns.filter_params,
        socket.assigns.selected_delivery,
        socket.assigns[:operator_read_fault]
      )

    selected_target_id = default_replay_target_id(replay_targets)
    review_id = Ecto.UUID.generate()

    {:noreply,
     socket
     |> assign(:replay_targets, replay_targets)
     |> assign(:replay_modal_open?, true)
     |> assign(:replay_command_feedback, nil)
     |> assign(:replay_selected_target_id, selected_target_id)
     |> assign(:replay_review_snapshot, replay_review_snapshot(socket, replay_targets))
     |> assign(:replay_review_id, review_id)
     |> assign(:replay_review_consumed?, false)
     |> assign(:replay_pending?, false)}
  end

  def handle_event("close_replay", _params, socket) do
    {:noreply, close_replay_modal(socket)}
  end

  def handle_event("retry_deliveries", _params, socket) do
    {:noreply,
     assign_delivery_state(
       socket,
       socket.assigns.filter_params,
       selected_delivery_id(socket),
       socket.assigns.full_detail?,
       support_focus?(socket.assigns.support_state)
     )}
  end

  def handle_event("retry_details", _params, socket) do
    {:noreply,
     assign_delivery_state(
       socket,
       socket.assigns.filter_params,
       get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)]) ||
         socket.assigns[:requested_delivery_id],
       socket.assigns.full_detail?,
       support_focus?(socket.assigns.support_state)
     )}
  end

  def handle_event("retry_timeline", _params, socket) do
    {:noreply,
     assign_delivery_state(
       socket,
       socket.assigns.filter_params,
       get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)]) ||
         socket.assigns[:requested_delivery_id],
       socket.assigns.full_detail?,
       support_focus?(socket.assigns.support_state)
     )}
  end

  def handle_event("retry_replay_evidence", _params, socket) do
    case load_replay_history(
           socket.assigns.filter_params,
           socket.assigns.selected_delivery,
           socket.assigns[:operator_read_fault],
           socket.assigns.replay_history
         ) do
      {history, :ready} ->
        {:noreply,
         socket
         |> assign(:replay_history, history)
         |> assign(:replay_history_read_state, :ready)}

      {history, state} ->
        {:noreply,
         socket
         |> assign(:replay_history, history)
         |> assign(:replay_history_read_state, state)}
    end
  end

  def handle_event("retry_suppression", _params, socket) do
    case read_suppression(
           socket.assigns.filter_params,
           socket.assigns.selected_delivery,
           socket.assigns[:operator_read_fault]
         ) do
      {:ok, suppression} ->
        {:noreply,
         socket
         |> assign(:suppression_state, suppression)
         |> assign(:suppression_read_state, :ready)}

      {:error, :unavailable} ->
        {:noreply, assign(socket, :suppression_read_state, :unavailable)}
    end
  end

  def handle_event("retry_health", _params, socket) do
    {:noreply, assign_overview_state(socket, socket.assigns.filter_params)}
  end

  def handle_event("choose_replay_target", %{"webhook_event_id" => webhook_event_id}, socket) do
    {:noreply, select_frozen_replay_target(socket, webhook_event_id)}
  end

  def handle_event(
        "choose_replay_target",
        %{"replay" => %{"webhook_event_id" => webhook_event_id}},
        socket
      ) do
    {:noreply, select_frozen_replay_target(socket, webhook_event_id)}
  end

  def handle_event(
        "confirm_replay",
        %{"review" => review_id},
        %{
          assigns: %{
            replay_modal_open?: true,
            replay_review_consumed?: false,
            replay_review_id: review_id
          }
        } = socket
      ) do
    socket =
      socket
      |> assign(:replay_review_consumed?, true)
      |> assign(:replay_pending?, true)
      |> assign(:replay_command_feedback, nil)

    with %{id: delivery_id, tenant_id: tenant_id} <-
         socket.assigns.selected_delivery || {:error, :no_selected_delivery},
         %{} = delivery <-
           read_confirmation_delivery(socket, tenant_id, delivery_id),
         {:ok, fresh_targets} <- read_confirmation_targets(socket, tenant_id, delivery_id),
         {:ok, target} <-
           resolve_reviewed_replay_target(
             socket.assigns.replay_review_snapshot,
             tenant_id,
             delivery_id,
             fresh_targets,
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
       |> clear_flash()
       |> assign(:replay_command_feedback, RepairState.command_feedback(result))
       |> assign_delivery_state(socket.assigns.filter_params, delivery_id, true, false)
       |> close_replay_modal()}
    else
      {:error, :no_selected_delivery} ->
        {:noreply, put_flash(socket, :error, "Select a delivery before replaying a webhook.")}

      {:error, :unavailable} ->
        {:noreply,
         socket
         |> assign(:replay_pending?, false)
         |> put_flash(
           :info,
           "Replay is unavailable for this delivery. Review it again before retrying."
         )}

      {:error, :read_unavailable} ->
        {:noreply,
         socket
         |> assign(:replay_pending?, false)
         |> assign(:replay_review_consumed?, false)
         |> put_flash(
           :info,
           "Current records could not be refreshed. The exact reviewed request is retained."
         )}

      {:error, :review_changed} ->
        {:noreply,
         socket
         |> assign(:replay_pending?, false)
         |> put_flash(
           :info,
           "This webhook request changed or is no longer eligible. Review the current request before replaying."
         )}

      {:error, :target_required} ->
        {:noreply,
         socket
         |> assign(:replay_pending?, false)
         |> put_flash(:info, "Choose one webhook target before confirming replay.")}

      {:error, {:auth, message}} ->
        {:noreply,
         socket
         |> assign(:replay_pending?, false)
         |> put_flash(:info, RepairState.authorization_feedback(message))}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign_delivery_state(
           socket.assigns.filter_params,
           get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)]),
           true,
           false
         )
         |> assign(:replay_pending?, false)
         |> put_flash(:error, RepairState.flash_failure(reason))}
    end
  end

  def handle_event("confirm_replay", _params, %{assigns: %{selected_delivery: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Select a delivery before replaying a webhook.")}
  end

  def handle_event("confirm_replay", _params, socket), do: {:noreply, socket}

  defp select_delivery(socket, delivery_id, params) do
    allowed_focus_ids = [
      "operator-delivery-desktop-#{delivery_id}",
      "operator-delivery-mobile-#{delivery_id}"
    ]

    requested_focus_id = params["focus_return_id"] || params["focus-return-id"]

    focus_return_id =
      if requested_focus_id in allowed_focus_ids,
        do: requested_focus_id,
        else: nil

    socket = assign(socket, :quick_view_focus_return_id, focus_return_id)

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
      selected_tenant_id={@selected_tenant_id}
      tenant_options={@tenant_options}
      account_labels={@account_labels}
      page_uri={@page_uri}
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
                <div class="flex flex-wrap items-center justify-between gap-sm text-label text-secondary">
                  <p data-testid="operator-health-window">{health_window_copy(@health_window)}</p>
                  <p data-testid="operator-health-last-checked">
                    {health_checked_copy(@health_observed_at)}
                  </p>
                  <button type="button" phx-click="retry_health" class="btn btn-ghost min-h-11">
                    Retry observations
                  </button>
                </div>
                <div class="grid gap-md md:grid-cols-2">
                  <.link
                    patch={
                      support_evidence_path(
                        @base_path,
                        @filter_params,
                        @dark_chrome,
                        :failed_ingest,
                        @support_summary
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View recent failures in Deliveries"
                    data-testid="operator-overview-health-failures-link"
                  >
                    <Components.stat_card
                      label="Failed webhook attempts"
                      value={health_metric_count(@support_summary, :failed_ingest)}
                      state={
                        health_metric_state(@support_summary, :failed_ingest, @health_panel_states)
                      }
                      severity={health_metric_severity(@support_summary, :failed_ingest, :warning)}
                      severity_label={
                        health_metric_severity_label(
                          @support_summary,
                          :failed_ingest,
                          @health_panel_states
                        )
                      }
                      hint="Failed and dead webhook rows received during the selected Account observation window. This counts processing attempts, not failed Deliveries."
                      data-testid="operator-overview-health-failures"
                    />
                  </.link>
                  <.link
                    patch={
                      support_evidence_path(
                        @base_path,
                        @filter_params,
                        @dark_chrome,
                        :orphan_backlog,
                        @support_summary
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View unmatched webhook evidence in Deliveries"
                    data-testid="operator-overview-health-orphans-link"
                  >
                    <Components.stat_card
                      label="Unmatched Events"
                      value={health_metric_count(@support_summary, :orphan_backlog)}
                      state={
                        health_metric_state(@support_summary, :orphan_backlog, @health_panel_states)
                      }
                      severity={health_metric_severity(@support_summary, :orphan_backlog, :warning)}
                      severity_label={
                        health_metric_severity_label(
                          @support_summary,
                          :orphan_backlog,
                          @health_panel_states
                        )
                      }
                      hint="Unresolved Event records in the selected Account observation window. A shown oldest Event is one example, not the complete population."
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
                    aria-label="View historical suppressed Delivery Events in Deliveries"
                    data-testid="operator-overview-health-suppressions-link"
                  >
                    <Components.stat_card
                      label="Active suppression records"
                      value={@suppression_count}
                      state={
                        panel_value_state(
                          @health_panel_states,
                          :active_suppressions,
                          @suppression_count
                        )
                      }
                      severity={suppression_severity(@suppression_count)}
                      severity_label={
                        suppression_severity_label(
                          @suppression_count,
                          @health_panel_states
                        )
                      }
                      hint="Account-wide active Mailglass suppression records at check time, independent of the observation window. This is not a recipient count; the link opens historical suppressed Delivery Events, a separate population."
                      data-testid="operator-overview-health-suppressions"
                    />
                  </.link>
                  <.link
                    patch={
                      support_evidence_path(
                        @base_path,
                        @filter_params,
                        @dark_chrome,
                        :replay_outcomes,
                        @support_summary
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View replay audit evidence"
                    data-testid="operator-overview-health-replay-link"
                  >
                    <Components.stat_card
                      label="Replay audit facts"
                      value={health_metric_count(@support_summary, :replay_outcomes)}
                      state={
                        health_metric_state(@support_summary, :replay_outcomes, @health_panel_states)
                      }
                      severity={health_metric_severity(@support_summary, :replay_outcomes, :info)}
                      severity_label={
                        health_metric_severity_label(
                          @support_summary,
                          :replay_outcomes,
                          @health_panel_states
                        )
                      }
                      hint="Recorded replay audit outcomes during the selected observation window. These facts do not establish Delivery outcome."
                      data-testid="operator-overview-health-replay"
                    />
                  </.link>
                  <.link
                    patch={
                      support_evidence_path(
                        @base_path,
                        @filter_params,
                        @dark_chrome,
                        :reconcile_facts,
                        @support_summary
                      )
                    }
                    class={health_metric_link_class()}
                    aria-label="View reconciliation audit evidence"
                    data-testid="operator-overview-health-reconcile-link"
                  >
                    <Components.stat_card
                      label="Reconciliation audit facts"
                      value={health_metric_count(@support_summary, :reconcile_facts)}
                      state={
                        health_metric_state(@support_summary, :reconcile_facts, @health_panel_states)
                      }
                      severity={health_metric_severity(@support_summary, :reconcile_facts, :info)}
                      severity_label={
                        health_metric_severity_label(
                          @support_summary,
                          :reconcile_facts,
                          @health_panel_states
                        )
                      }
                      hint="Recorded reconciliation audit Events during the selected observation window. This is separate from unresolved Events."
                      data-testid="operator-overview-health-reconcile"
                    />
                  </.link>
                </div>
              </div>
              <p
                :if={health_partial?(@health_panel_states)}
                role="status"
                data-testid="operator-health-partial"
                class="rounded-box border border-warning bg-base-200 p-sm text-body text-secondary"
              >
                Some evidence is unavailable. Available observations remain visible; an unavailable read does not mean that no records exist.
              </p>
              <p
                :for={{panel, state} <- @health_panel_states}
                :if={state.status == :stale}
                role="status"
                data-testid={"operator-health-stale-#{panel}"}
                class="text-label text-secondary"
              >
                Showing the last retrieved {health_panel_name(panel)} from {health_checked_copy(
                  state.checked_at
                )}.
              </p>
              <p
                :for={{panel, state} <- @health_panel_states}
                :if={state.status == :unavailable}
                role="status"
                data-testid={"operator-health-unavailable-#{panel}"}
                class="text-label text-error"
              >
                These {health_panel_name(panel)} could not be loaded. Other available sections remain visible.
              </p>
            <% else %>
              <div
                data-testid="operator-overview-no-tenant"
                class="card bg-base-200 border border-base-300 rounded-box p-md flex flex-col gap-sm"
              >
                <div class="text-body font-bold text-base-content">Choose an Account</div>
                <div class="text-body text-secondary">
                  Select an Account to see scoped operator data. Mailglass keeps that account boundary
                  in the URL as <code class="mono">tenant_id</code> so refreshes and shared links stay
                  scoped.
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
            <% @deliveries == [] and @deliveries_read_state == :ready and
                is_nil(@requested_delivery_id) and @deliveries_page_meta.total_count == 0 and
                not filters_active?(@filter_params) and @filter_errors == %{} -> %>
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
                    patch={build_path_with_view(@base_path, @filter_params, @dark_chrome)}
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
                            {detail_error_copy(@detail_error)}
                          </h2>
                        </div>
                        <button
                          :if={@detail_error == :unavailable}
                          type="button"
                          phx-click="retry_details"
                          class="btn btn-ghost min-h-11 mt-md"
                        >
                          Retry details
                        </button>
                      </div>
                    <% true -> %>
                      <div
                        id={"delivery-detail-#{@selected_delivery.id}"}
                        data-region
                        class="motion-reveal space-y-4"
                      >
                        <DetailHeader.detail_header
                          delivery={@selected_delivery}
                          account_labels={@account_labels}
                        />
                        <%!-- Event timeline leads: it is the record-specific "what happened"
                            evidence the operator came to read. Suppression state (also
                            record-specific) follows; the account-level support cards trail. --%>
                        <OperatorTimeline.timeline
                          timeline_events={@timeline_events}
                          highlight_event_id={@support_state.event_id}
                          read_state={@timeline_state}
                          selected_event={@selected_timeline_event}
                        />
                        <SuppressionCard.suppression_card
                          suppression_state={@suppression_state}
                          read_state={@suppression_read_state}
                        />
                        <SupportCards.support_cards
                          support_summary={@support_summary}
                          support_state={@support_state}
                          suppression_count={@suppression_count}
                          exact_support_evidence={@support_exact_evidence}
                          exact_delivery_path={
                            exact_support_delivery_path(
                              @base_path,
                              @filter_params,
                              @dark_chrome,
                              @support_exact_evidence,
                              @support_state
                            )
                          }
                        />
                        <ReplayAction.replay_action
                          replay_targets={@replay_targets}
                          latest_replay={latest_replay(@replay_history)}
                          replay_history_read_state={@replay_history_read_state}
                          replay_command_feedback={@replay_command_feedback}
                        />
                      </div>
                  <% end %>
                </div>
              <% else %>
                <%!-- LIST PAGE: delivery collection first, with filters/supporting evidence secondary.
                    The Quick view overlay (below) sits on top when a record is focused. --%>
                <section data-testid="operator-master-detail" class="mt-6">
                  <aside
                    data-testid="operator-deliveries-list-card"
                    class="card min-w-0 rounded-box border border-base-300 bg-base-200 p-0"
                  >
                    <div class="border-b border-base-300 px-4 py-3">
                      <h2 class="text-heading font-bold text-base-content">Recent deliveries</h2>
                    </div>
                    <DeliveriesList.deliveries_list
                      deliveries={@deliveries}
                      page_meta={@deliveries_page_meta}
                      account_labels={@account_labels}
                      show_account?={false}
                      previous_page_path={
                        pagination_path(@base_path, @filter_params, @dark_chrome, :previous)
                      }
                      next_page_path={
                        pagination_path(@base_path, @filter_params, @dark_chrome, :next)
                      }
                      selected_delivery={@selected_delivery}
                      data_state={@deliveries_read_state}
                      filters_active?={filters_active?(@filter_params)}
                    />
                  </aside>
                </section>

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
                      <input
                        id="filters_tenant_id"
                        type="hidden"
                        name={@filter_form[:tenant_id].name}
                        value={@filter_form[:tenant_id].value}
                      />
                      <FiltersForm.fields
                        form={@filter_form}
                        provider_options={@provider_options}
                        event_values={@event_values}
                        window_options={@window_options}
                        errors={@filter_errors}
                      />

                      <div class="flex flex-wrap gap-2">
                        <button
                          type="submit"
                          phx-disable-with="Applying filters…"
                          class="btn btn-primary min-h-11 w-40 px-5"
                        >
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
                  id="operator-support-focus-detail"
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
                    exact_support_evidence={@support_exact_evidence}
                    exact_delivery_path={
                      exact_support_delivery_path(
                        @base_path,
                        @filter_params,
                        @dark_chrome,
                        @support_exact_evidence,
                        @support_state
                      )
                    }
                  />
                </div>
              <% end %>

              <%!-- Quick view (peek) overlay: a record is focused and we are NOT in Full detail. --%>
              <span
                :if={not @full_detail? and (@selected_delivery != nil or @detail_error != nil)}
                data-testid="operator-quick-view-focus-return"
                data-focus-return-id={@quick_view_focus_return_id}
                phx-mounted={JS.focus(to: "#operator-quick-view-close")}
                phx-remove={
                  if @quick_view_focus_return_id,
                    do: JS.focus(to: "##{@quick_view_focus_return_id}"),
                    else: %JS{}
                }
              />
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
                  neighbor_path(
                    "prev",
                    @deliveries,
                    @selected_delivery,
                    @base_path,
                    @filter_params,
                    @dark_chrome,
                    false
                  )
                }
                next_path={
                  neighbor_path(
                    "next",
                    @deliveries,
                    @selected_delivery,
                    @base_path,
                    @filter_params,
                    @dark_chrome,
                    false
                  )
                }
                position={record_position(@deliveries, @selected_delivery, @deliveries_page_meta)}
                keyboard?={not @replay_modal_open?}
                focus_return_id={@quick_view_focus_return_id}
              />

              <%!-- Focus trap: phx-mounted moves focus into the modal on open; phx-remove returns focus to trigger on close --%>
              <span
                :if={@replay_modal_open?}
                phx-mounted={JS.focus(to: "#operator-replay-close")}
                phx-remove={JS.focus(to: "#replay-open-btn")}
              />
              <ReplayModal.replay_modal
                open?={@replay_modal_open?}
                delivery={@selected_delivery}
                replay_targets={@replay_targets}
                selected_target_id={@replay_selected_target_id}
                review_id={@replay_review_id}
                account_label={Accounts.label(@selected_tenant_id, @account_labels)}
                pending?={@replay_pending?}
                consumed?={@replay_review_consumed?}
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

  defp sync_event_subscription(socket, selected_tenant_id, tenant_state) do
    desired_topic =
      if connected?(socket) and tenant_state == :selected and is_binary(selected_tenant_id) do
        Mailglass.PubSub.Topics.events(selected_tenant_id)
      end

    current_topic = socket.assigns.events_topic

    if current_topic == desired_topic do
      socket
    else
      if current_topic, do: Phoenix.PubSub.unsubscribe(Mailglass.PubSub, current_topic)
      if desired_topic, do: Phoenix.PubSub.subscribe(Mailglass.PubSub, desired_topic)
      assign(socket, :events_topic, desired_topic)
    end
  end

  defp matching_tenant?(metadata, tenant_id) do
    case Map.get(metadata, :tenant_id) || Map.get(metadata, "tenant_id") do
      nil -> true
      ^tenant_id -> true
      _foreign_tenant -> false
    end
  end

  defp refresh_visible_state(%{assigns: %{view: :deliveries}} = socket) do
    socket
    |> assign(:provider_options, load_provider_options(socket.assigns.filter_params))
    |> assign_delivery_state(
      socket.assigns.filter_params,
      selected_delivery_id(socket),
      socket.assigns.full_detail?,
      support_focus?(socket.assigns.support_state)
    )
  end

  defp refresh_visible_state(socket) do
    socket
    |> assign(:provider_options, load_provider_options(socket.assigns.filter_params))
    |> assign_overview_state(socket.assigns.filter_params)
  end

  defp selected_delivery_id(%{assigns: %{selected_delivery: %{id: id}}}), do: id
  defp selected_delivery_id(%{assigns: %{requested_delivery_id: id}}) when is_binary(id), do: id
  defp selected_delivery_id(_socket), do: nil

  defp clear_surface_state(socket) do
    socket
    |> assign(:view, :overview)
    |> assign(:full_detail?, false)
    |> assign(:deliveries, [])
    |> assign(:deliveries_page_meta, empty_page_meta())
    |> assign(:deliveries_read_state, :ready)
    |> assign(:selected_delivery, nil)
    |> assign(:requested_delivery_id, nil)
    |> assign(:timeline_events, [])
    |> assign(:timeline_state, :ready)
    |> assign(:selected_timeline_event, nil)
    |> assign(:suppression_state, nil)
    |> assign(:suppression_read_state, :ready)
    |> assign(:support_summary, nil)
    |> assign(:health_panel_states, default_health_panel_states())
    |> assign(:health_observed_at, nil)
    |> assign(:health_window, nil)
    |> assign(:health_loaded_for, nil)
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

  defp filter_draft_params(params, normalized) do
    Enum.reduce(["event", "window_hours"], normalized, fn key, draft ->
      if Map.has_key?(params, key),
        do: Map.put(draft, key, normalize_string(Map.get(params, key))),
        else: draft
    end)
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
          try do
            Deliveries.list_providers(%{
              tenant_id: tenant_id,
              window_hours:
                parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
            })
          rescue
            error ->
              if transient_read_error?(error), do: [], else: reraise(error, __STACKTRACE__)
          end

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

  defp load_timeline(_filter_params, nil, _read_fault), do: {[], :ready}

  defp load_timeline(filter_params, delivery, read_fault) do
    run_read_fault(read_fault, :delivery_timeline)

    events =
      OperatorTimelineData.list_delivery_events(
        %{
          tenant_id: filter_params["tenant_id"],
          delivery_id: delivery.id
        },
        limit: 101
      )

    {Enum.map(events, &safe_timeline_event/1), :ready}
  rescue
    error ->
      if transient_read_error?(error),
        do: {[], :unavailable},
        else: reraise(error, __STACKTRACE__)
  end

  defp safe_timeline_event(event) do
    safe_metadata =
      Map.take(event.metadata || %{}, [
        "provider",
        :provider,
        "source",
        :source,
        "provider_event_id",
        :provider_event_id,
        "provider_occurred_at",
        :provider_occurred_at,
        "outcome",
        :outcome,
        "reconciled_provider",
        :reconciled_provider,
        "reconciled_provider_event_id",
        :reconciled_provider_event_id,
        "reconciled_from_event_id",
        :reconciled_from_event_id
      ])

    event
    |> Map.put(:metadata, safe_metadata)
    |> Map.put(
      :provider_occurred_at,
      Map.get(safe_metadata, "provider_occurred_at") ||
        Map.get(safe_metadata, :provider_occurred_at)
    )
  end

  defp load_selected_timeline_event(_filter_params, nil, _support_state, _read_fault), do: nil

  defp load_selected_timeline_event(filter_params, delivery, support_state, read_fault) do
    event_id = support_state.event_id

    if is_binary(event_id) do
      try do
        run_read_fault(read_fault, :selected_delivery_event)

        event =
          OperatorTimelineData.get_delivery_event(
            filter_params["tenant_id"],
            delivery.id,
            event_id
          )

        %{id: event_id, event: event, status: if(event, do: :ready, else: :not_found)}
      rescue
        error ->
          if transient_read_error?(error) do
            %{id: event_id, event: nil, status: :unavailable}
          else
            reraise(error, __STACKTRACE__)
          end
      end
    else
      nil
    end
  end

  defp read_suppression(_filter_params, nil, _read_fault), do: {:ok, nil}

  defp read_suppression(filter_params, delivery, read_fault) do
    run_read_fault(read_fault, :delivery_suppression)

    {:ok,
     Suppressions.get_delivery_suppression_state(
       %{
         tenant_id: filter_params["tenant_id"],
         recipient: delivery.recipient,
         stream: delivery.stream
       },
       []
     )}
  rescue
    error ->
      if transient_read_error?(error),
        do: {:error, :unavailable},
        else: reraise(error, __STACKTRACE__)
  end

  defp find_selected_delivery(_deliveries, nil), do: nil

  defp find_selected_delivery(deliveries, delivery_id),
    do: Enum.find(deliveries, &(&1.id == delivery_id))

  defp detail_error_for(nil, _selected_delivery), do: nil

  defp detail_error_for(delivery_id, nil) do
    case Ecto.UUID.cast(delivery_id) do
      {:ok, _} -> :not_found
      :error -> :invalid_id
    end
  end

  defp detail_error_for(_delivery_id, _selected_delivery), do: nil

  defp detail_error_copy(:invalid_id),
    do: "This delivery link is invalid. Return to deliveries and open a listed record."

  defp detail_error_copy(:not_found),
    do: "This delivery is not available in the selected Account. Return to deliveries to continue."

  defp detail_error_copy(:unavailable),
    do:
      "Delivery details are temporarily unavailable. Retry the scoped read or return to deliveries."

  defp detail_error_copy(_),
    do: "Delivery details are unavailable. Return to deliveries to continue."

  defp load_replay_targets(_filter_params, nil, _read_fault), do: nil

  defp load_replay_targets(filter_params, delivery, read_fault) do
    run_read_fault(read_fault, :replay_targets)

    case ReplayTargets.list_delivery_targets(%{
           tenant_id: filter_params["tenant_id"],
           delivery_id: delivery.id
         }) do
      {:ok, targets} ->
        targets

      {:error, _reason} ->
        %{status: :unavailable, reason: :missing_replay_linkage, candidates: []}
    end
  rescue
    error ->
      if transient_read_error?(error) do
        %{status: :unavailable, reason: :read_unavailable, candidates: []}
      else
        reraise(error, __STACKTRACE__)
      end
  end

  defp load_replay_history(_filter_params, nil, _read_fault, _prior_history),
    do: {[], :ready}

  defp load_replay_history(filter_params, delivery, read_fault, prior_history) do
    run_read_fault(read_fault, :replay_history)

    history =
      ReplayHistory.list_delivery_replay_history(%{
        tenant_id: filter_params["tenant_id"],
        delivery_id: delivery.id
      })

    {history, :ready}
  rescue
    error ->
      if transient_read_error?(error) do
        {prior_history, if(prior_history == [], do: :unavailable, else: :stale)}
      else
        reraise(error, __STACKTRACE__)
      end
  end

  # Two-tier load: the Quick view (peek) renders purely from the list-row projection
  # already in `deliveries`, so flipping records fires NO extra queries. The heavy
  # evidence — event timeline, suppression state, replay targets/history — loads only
  # in Full detail (`full?`). `support_summary` is loaded for Full detail and for a
  # support-focus drill-down (both render SupportCards); the Quick view skips it.
  defp assign_delivery_state(socket, filter_params, selected_delivery_id, full?, support_focus?) do
    query_key = delivery_query_key(filter_params)
    prior_delivery = socket.assigns[:selected_delivery]

    replay_command_feedback =
      if prior_delivery && prior_delivery.id == selected_delivery_id &&
           prior_delivery.tenant_id == filter_params["tenant_id"],
         do: socket.assigns[:replay_command_feedback],
         else: nil

    prior_replay_history =
      if prior_delivery && prior_delivery.id == selected_delivery_id &&
           prior_delivery.tenant_id == filter_params["tenant_id"],
         do: socket.assigns.replay_history,
         else: []

    {deliveries, page_meta, deliveries_read_state} =
      case read_deliveries_page(filter_params, socket.assigns[:operator_read_fault]) do
        {:ok, deliveries_page} ->
          {deliveries_page.entries, page_meta_without_entries(deliveries_page), :ready}

        {:error, :unavailable}
        when socket.assigns.deliveries != [] and socket.assigns.deliveries_loaded_for == query_key ->
          {socket.assigns.deliveries, socket.assigns.deliveries_page_meta, :stale}

        {:error, :unavailable} ->
          {[], page_meta_without_entries(empty_page_meta()), :error}
      end

    {selected_delivery, detail_error} =
      resolve_selected_delivery(
        deliveries,
        filter_params,
        selected_delivery_id,
        socket.assigns[:operator_read_fault]
      )

    replay_targets =
      if full?,
        do:
          load_replay_targets(
            filter_params,
            selected_delivery,
            socket.assigns[:operator_read_fault]
          ),
        else: nil

    {replay_history, replay_history_read_state} =
      if full?,
        do:
          load_replay_history(
            filter_params,
            selected_delivery,
            socket.assigns[:operator_read_fault],
            prior_replay_history
          ),
        else: {[], :ready}

    {timeline, timeline_state} =
      if full?,
        do: load_timeline(filter_params, selected_delivery, socket.assigns[:operator_read_fault]),
        else: {[], :ready}

    selected_timeline_event =
      if full?,
        do:
          load_selected_timeline_event(
            filter_params,
            selected_delivery,
            socket.assigns.support_state,
            socket.assigns[:operator_read_fault]
          ),
        else: nil

    previous_suppression =
      if get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)]) ==
           selected_delivery_id do
        socket.assigns[:suppression_state]
      end

    {suppression, suppression_read_state} =
      if full? do
        case read_suppression(
               filter_params,
               selected_delivery,
               socket.assigns[:operator_read_fault]
             ) do
          {:ok, state} -> {state, :ready}
          {:error, :unavailable} -> {previous_suppression, :unavailable}
        end
      else
        {nil, :ready}
      end

    {support_summary, health_panel_states, suppression_count, health_observed_at, health_window} =
      if full? or support_focus? do
        load_health_observations(socket, filter_params)
      else
        {nil, default_health_panel_states(), nil, nil, nil}
      end

    socket
    |> assign(:view, :deliveries)
    |> assign(:full_detail?, full?)
    |> assign(:deliveries, deliveries)
    |> assign(:deliveries_page_meta, page_meta)
    |> assign(:deliveries_read_state, deliveries_read_state)
    |> assign(
      :deliveries_loaded_for,
      if(deliveries_read_state == :ready,
        do: query_key,
        else: socket.assigns[:deliveries_loaded_for]
      )
    )
    |> assign(:selected_delivery, selected_delivery)
    |> assign(:requested_delivery_id, selected_delivery_id)
    |> assign(:timeline_events, timeline)
    |> assign(:timeline_state, timeline_state)
    |> assign(:selected_timeline_event, selected_timeline_event)
    |> assign(:suppression_state, suppression)
    |> assign(:suppression_read_state, suppression_read_state)
    |> assign(:support_summary, support_summary)
    |> assign(:suppression_count, suppression_count)
    |> assign(:health_panel_states, health_panel_states)
    |> assign(:health_observed_at, health_observed_at)
    |> assign(:health_window, health_window)
    |> assign(:health_loaded_for, health_observation_cache_key(filter_params))
    |> assign(:detail_error, detail_error)
    |> assign(:replay_targets, replay_targets)
    |> assign(:replay_history, replay_history)
    |> assign(:replay_history_read_state, replay_history_read_state)
    |> assign(:replay_command_feedback, replay_command_feedback)
    |> assign(
      :replay_selected_target_id,
      preserve_replay_selection(replay_targets, socket.assigns[:replay_selected_target_id])
    )
    |> assign(
      :support_exact_evidence,
      load_support_exact_evidence(socket, filter_params, socket.assigns.support_state)
    )
  end

  defp read_deliveries_page(filter_params, read_fault) do
    run_read_fault(read_fault, :deliveries)
    {:ok, load_deliveries_page(filter_params)}
  rescue
    error ->
      if transient_read_error?(error),
        do: {:error, :unavailable},
        else: reraise(error, __STACKTRACE__)
  end

  defp resolve_selected_delivery(_deliveries, _filter_params, nil, _read_fault),
    do: {nil, nil}

  defp resolve_selected_delivery(deliveries, filter_params, delivery_id, read_fault) do
    case find_selected_delivery(deliveries, delivery_id) do
      %{} = delivery ->
        {delivery, nil}

      nil ->
        case load_exact_delivery(filter_params, delivery_id, read_fault) do
          {:ok, %{} = delivery} -> {delivery, nil}
          {:ok, nil} -> {nil, detail_error_for(delivery_id, nil)}
          {:error, :unavailable} -> {nil, :unavailable}
        end
    end
  end

  defp load_exact_delivery(_filter_params, nil, _read_fault), do: {:ok, nil}

  defp load_exact_delivery(filter_params, delivery_id, read_fault) do
    tenant_id = blank_to_nil(filter_params["tenant_id"])

    if tenant_id do
      try do
        run_read_fault(read_fault, :exact_delivery)
        {:ok, Deliveries.get_delivery(%{tenant_id: tenant_id, delivery_id: delivery_id}, [])}
      rescue
        error ->
          if transient_read_error?(error),
            do: {:error, :unavailable},
            else: reraise(error, __STACKTRACE__)
      end
    else
      {:ok, nil}
    end
  end

  defp read_confirmation_delivery(socket, tenant_id, delivery_id) do
    run_read_fault(socket.assigns[:operator_read_fault], :selected_delivery)

    Deliveries.get_delivery(%{tenant_id: tenant_id, delivery_id: delivery_id}, []) ||
      {:error, :unavailable}
  rescue
    error ->
      if transient_read_error?(error),
        do: {:error, :read_unavailable},
        else: reraise(error, __STACKTRACE__)
  end

  defp read_confirmation_targets(socket, tenant_id, delivery_id) do
    run_read_fault(socket.assigns[:operator_read_fault], :replay_targets)

    ReplayTargets.list_delivery_targets(%{tenant_id: tenant_id, delivery_id: delivery_id})
  rescue
    error ->
      if transient_read_error?(error),
        do: {:error, :read_unavailable},
        else: reraise(error, __STACKTRACE__)
  end

  defp run_read_fault(callback, operation) when is_function(callback, 1),
    do: callback.(operation)

  defp run_read_fault(_callback, _operation), do: :ok

  defp transient_read_error?(%DBConnection.ConnectionError{}), do: true

  defp transient_read_error?(%Postgrex.Error{postgres: %{code: code}})
       when code in [
              :query_canceled,
              :admin_shutdown,
              :connection_exception,
              "57014",
              "57P01"
            ],
       do: true

  defp transient_read_error?(%Postgrex.Error{postgres: %{code: code}}) when is_binary(code),
    do: String.starts_with?(code, "08")

  defp transient_read_error?(_error), do: false

  defp delivery_query_key(filter_params),
    do: Map.take(filter_params, ["tenant_id", "provider", "event", "window_hours", "page"])

  defp assign_overview_state(socket, filter_params) do
    {support_summary, health_panel_states, suppression_count, observed_at, health_window} =
      load_health_observations(socket, filter_params)

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
    |> assign(:health_panel_states, health_panel_states)
    |> assign(:health_observed_at, observed_at)
    |> assign(:health_window, health_window)
    |> assign(:health_loaded_for, health_observation_cache_key(filter_params))
    |> assign(:overview_path, paths.overview)
    |> assign(:inbound_path, paths.inbound)
    |> assign(:deliveries, [])
    |> assign(:deliveries_page_meta, empty_page_meta())
    |> assign(:selected_delivery, nil)
    |> assign(:timeline_events, [])
    |> assign(:suppression_state, nil)
    |> assign(:suppression_read_state, :ready)
    |> assign(:detail_error, nil)
    |> assign(:replay_targets, nil)
    |> assign(:replay_history, [])
    |> assign(:replay_selected_target_id, nil)
  end

  defp load_health_observations(socket, filter_params) do
    tenant_id = blank_to_nil(filter_params["tenant_id"])
    window_hours = parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
    cache_key = health_observation_cache_key(filter_params)

    if is_nil(tenant_id) do
      {nil, default_health_panel_states(), nil, nil, nil}
    else
      same_scope? = socket.assigns[:health_loaded_for] == cache_key
      prior_summary = if same_scope?, do: socket.assigns[:support_summary], else: nil

      prior_states =
        if same_scope?,
          do: socket.assigns[:health_panel_states],
          else: default_health_panel_states()

      prior_count = if same_scope?, do: socket.assigns[:suppression_count], else: nil
      as_of = DateTime.utc_now()
      window = %{tenant_id: tenant_id, window_hours: window_hours, as_of: as_of}

      {failed, failed_state} =
        read_health_panel(
          socket.assigns[:operator_read_fault],
          :failed_ingest,
          fn ->
            SupportSummary.read_failed_ingest(window)
          end,
          prior_summary && prior_summary[:failed_ingest],
          prior_states[:failed_ingest],
          &is_map/1,
          as_of
        )

      {orphan, orphan_state} =
        read_health_panel(
          socket.assigns[:operator_read_fault],
          :orphan_backlog,
          fn ->
            SupportSummary.read_orphan_backlog(window)
          end,
          prior_summary && prior_summary[:orphan_backlog],
          prior_states[:orphan_backlog],
          &is_map/1,
          as_of
        )

      {replay, replay_state} =
        read_health_panel(
          socket.assigns[:operator_read_fault],
          :replay_outcomes,
          fn ->
            SupportSummary.read_replay_outcomes(window)
          end,
          prior_summary && prior_summary[:replay_outcomes],
          prior_states[:replay_outcomes],
          &is_map/1,
          as_of
        )

      {reconcile, reconcile_state} =
        read_health_panel(
          socket.assigns[:operator_read_fault],
          :reconcile_facts,
          fn ->
            SupportSummary.read_reconcile_facts(window)
          end,
          prior_summary && prior_summary[:reconcile_facts],
          prior_states[:reconcile_facts],
          &is_map/1,
          as_of
        )

      {suppression_count, suppression_state} =
        read_health_panel(
          socket.assigns[:operator_read_fault],
          :active_suppressions,
          fn ->
            Suppressions.count_active_suppressions(tenant_id)
          end,
          prior_count,
          prior_states[:active_suppressions],
          &is_integer/1,
          as_of
        )

      summary = %{
        failed_ingest: failed || %{count: nil, latest: nil},
        orphan_backlog: orphan || %{count: nil, oldest: nil, oldest_age_seconds: nil},
        replay_outcomes: replay || %{counts: %{failed: nil, noop: nil, replayed: nil}, latest: nil},
        reconcile_facts:
          reconcile ||
            %{
              reconciled_count: nil,
              still_unmatched_count: nil,
              latest_reconciled: nil,
              oldest_unmatched: nil
            }
      }

      states = %{
        failed_ingest: failed_state,
        orphan_backlog: orphan_state,
        replay_outcomes: replay_state,
        reconcile_facts: reconcile_state,
        active_suppressions: suppression_state
      }

      any_current_read? = Enum.any?(Map.values(states), &(&1.status == :ready))

      observed_at =
        if any_current_read?, do: as_of, else: prior_observed_at(socket, same_scope?)

      displayed_window =
        if any_current_read?,
          do: %{started_at: DateTime.add(as_of, -window_hours, :hour), ended_at: as_of},
          else: socket.assigns[:health_window]

      {summary, states, suppression_count, observed_at, displayed_window}
    end
  end

  defp read_health_panel(read_fault, operation, read_fun, prior_value, prior_state, value?, as_of) do
    try do
      run_read_fault(read_fault, operation)
      value = read_fun.()

      if not value?.(value),
        do: raise(ArgumentError, "invalid result for operator read #{operation}")

      {value, %{status: :ready, checked_at: as_of}}
    rescue
      error ->
        if transient_read_error?(error) do
          if (not is_nil(prior_value) and prior_state) && prior_state.status in [:ready, :stale] do
            {prior_value, %{status: :stale, checked_at: prior_state.checked_at}}
          else
            {nil, %{status: :unavailable, checked_at: nil}}
          end
        else
          reraise(error, __STACKTRACE__)
        end
    end
  end

  defp prior_observed_at(socket, true), do: socket.assigns[:health_observed_at]
  defp prior_observed_at(_socket, _same_scope?), do: nil

  defp health_observation_cache_key(filter_params) do
    case blank_to_nil(filter_params["tenant_id"]) do
      nil -> nil
      tenant_id ->
        window_hours =
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours

        {tenant_id, window_hours}
    end
  end

  defp default_health_panel_states do
    Map.new(
      [:failed_ingest, :orphan_backlog, :replay_outcomes, :reconcile_facts, :active_suppressions],
      fn key ->
        {key, %{status: :unavailable, checked_at: nil}}
      end
    )
  end

  defp close_replay_modal(socket) do
    socket
    |> assign(:replay_modal_open?, false)
    |> assign(:replay_selected_target_id, default_replay_target_id(socket.assigns.replay_targets))
    |> assign(:replay_review_snapshot, nil)
    |> assign(:replay_review_id, nil)
    |> assign(:replay_review_consumed?, false)
    |> assign(:replay_pending?, false)
  end

  defp replay_review_snapshot(socket, %{status: status, candidates: candidates})
       when status in [:exact, :ambiguous] do
    case socket.assigns.selected_delivery do
      %{id: delivery_id, tenant_id: tenant_id} ->
        %{tenant_id: tenant_id, delivery_id: delivery_id, status: status, candidates: candidates}

      _ ->
        nil
    end
  end

  defp replay_review_snapshot(_socket, _targets), do: nil

  defp select_frozen_replay_target(socket, value) do
    target_id = blank_to_nil(value)
    snapshot = socket.assigns[:replay_review_snapshot]

    if snapshot && Enum.any?(snapshot.candidates, &(&1.webhook_event_id == target_id)) do
      assign(socket, :replay_selected_target_id, target_id)
    else
      assign(socket, :replay_selected_target_id, nil)
    end
  end

  defp resolve_reviewed_replay_target(
         %{tenant_id: tenant_id, delivery_id: delivery_id, candidates: candidates},
         tenant_id,
         delivery_id,
         %{candidates: fresh_candidates},
         selected_target_id
       ) do
    selected = Enum.find(candidates, &(&1.webhook_event_id == selected_target_id))

    if candidates == fresh_candidates && selected,
      do: {:ok, selected},
      else: {:error, :review_changed}
  end

  defp resolve_reviewed_replay_target(_snapshot, _tenant_id, _delivery_id, _targets, _selected),
    do: {:error, :review_changed}

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

  defp neighbor_path(
         dir,
         deliveries,
         selected_delivery,
         base_path,
         filter_params,
         dark_chrome,
         full?
       ) do
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

  defp exact_support_delivery_path(base_path, filter_params, dark_chrome, evidence, support_state) do
    case get_in(evidence || %{}, [:record, :delivery_id]) do
      delivery_id when is_binary(delivery_id) ->
        build_path(
          base_path,
          filter_params |> Map.put("view", "deliveries") |> Map.put("full", "1"),
          delivery_id,
          dark_chrome,
          support_state
        )

      _ ->
        nil
    end
  end

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
      integer when is_integer(integer) and integer <= @max_window_hours ->
        {Integer.to_string(integer), nil}

      _ when raw_string == "" and not is_map_key(params, "window_hours") ->
        {Integer.to_string(@default_window_hours), nil}

      _ ->
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

  defp default_support_exact_evidence do
    %{tenant_id: nil, focus: nil, id: nil, status: :none, record: nil, checked_at: nil}
  end

  defp load_support_exact_evidence(socket, filter_params, support_state) do
    tenant_id = blank_to_nil(filter_params["tenant_id"])

    {focus, id, operation, read} =
      case support_state do
        %{focus: :failed_ingest, webhook_event_id: id} when is_binary(id) ->
          {:failed_ingest, id, :exact_failed_ingest,
           fn ->
             SupportSummary.get_webhook_event(tenant_id, id)
           end}

        %{focus: :orphan_backlog, event_id: id} when is_binary(id) ->
          {:orphan_backlog, id, :exact_unmatched_event,
           fn ->
             SupportSummary.get_unmatched_event(tenant_id, id)
           end}

        _ ->
          {nil, nil, nil, nil}
      end

    if is_nil(tenant_id) or is_nil(id) do
      default_support_exact_evidence()
    else
      prior = socket.assigns[:support_exact_evidence]
      same_request? =
        prior && prior.tenant_id == tenant_id && prior.focus == focus && prior.id == id

      try do
        run_read_fault(socket.assigns[:operator_read_fault], operation)
        record = read.()

        %{
          tenant_id: tenant_id,
          focus: focus,
          id: id,
          status: if(is_map(record), do: :ready, else: :not_found),
          record: record,
          checked_at: DateTime.utc_now()
        }
      rescue
        error ->
          if transient_read_error?(error) do
            if same_request? && prior.status in [:ready, :stale] && is_map(prior.record) do
              %{prior | status: :stale}
            else
              %{
                tenant_id: tenant_id,
                focus: focus,
                id: id,
                status: :unavailable,
                record: nil,
                checked_at: nil
              }
            end
          else
            reraise(error, __STACKTRACE__)
          end
      end
    end
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
    do:
      "Review failed webhook attempts, unmatched Events, replay and reconciliation records, and active suppression records for this Account."

  defp page_subtitle(:deliveries),
    do:
      "Prove what happened to a message — inspect its event timeline, suppression state, and replay history."

  defp health_metric_count(nil, _metric), do: nil

  defp health_metric_count(summary, :replay_outcomes) do
    counts = get_in(summary, [:replay_outcomes, :counts])

    case counts do
      %{failed: failed, noop: noop, replayed: replayed}
      when is_integer(failed) and is_integer(noop) and is_integer(replayed) ->
        failed + noop + replayed

      _ ->
        nil
    end
  end

  defp health_metric_count(summary, :reconcile_facts),
    do: summary |> get_in([:reconcile_facts, :reconciled_count]) |> normalize_stat_count()

  defp health_metric_count(summary, metric) do
    summary
    |> Map.get(metric, %{})
    |> Map.get(:count)
    |> normalize_stat_count()
  end

  defp health_metric_state(summary, metric, panel_states) do
    value = health_metric_count(summary, metric)
    panel_value_state(panel_states, metric, value)
  end

  defp panel_value_state(panel_states, panel, value) do
    case get_in(panel_states, [panel, :status]) do
      :unavailable -> :unavailable
      _ when is_integer(value) -> :ready
      _ -> :unavailable
    end
  end

  defp health_metric_severity(summary, metric, attention_severity) do
    case health_metric_count(summary, metric) do
      count when is_integer(count) and count > 0 -> attention_severity
      count when is_integer(count) -> :neutral
      _count -> :neutral
    end
  end

  defp health_metric_severity_label(summary, metric, panel_states) do
    if get_in(panel_states, [metric, :status]) == :stale do
      "Last retrieved"
    else
      case health_metric_count(summary, metric) do
        count when is_integer(count) and count > 0 -> "Needs attention"
        count when is_integer(count) and count == 0 -> "No matching evidence"
        count when is_integer(count) -> "Observed"
        _count -> "Unavailable"
      end
    end
  end

  defp suppression_severity(count) when is_integer(count), do: :info
  defp suppression_severity(_count), do: :neutral

  defp suppression_severity_label(count, panel_states) do
    cond do
      get_in(panel_states, [:active_suppressions, :status]) == :stale -> "Last retrieved"
      is_integer(count) -> "Tracked"
      true -> "Unavailable"
    end
  end

  defp normalize_stat_count(count) when is_integer(count), do: count
  defp normalize_stat_count(_count), do: nil

  defp health_window_copy(%{
         started_at: %DateTime{} = started_at,
         ended_at: %DateTime{} = ended_at
       }) do
    hours = div(DateTime.diff(ended_at, started_at, :second), 3_600)
    start_copy = started_at |> DateTime.to_naive() |> NaiveDateTime.to_iso8601()
    end_copy = ended_at |> DateTime.to_naive() |> NaiveDateTime.to_iso8601()

    "Observed from #{start_copy} to #{end_copy} UTC (#{hours} hours)"
  end

  defp health_window_copy(_window), do: "Observation interval unavailable"

  defp health_checked_copy(%DateTime{} = at),
    do: "Last checked #{DateTime.to_iso8601(DateTime.truncate(at, :second))} UTC"

  defp health_checked_copy(_at), do: "Last checked: Unavailable"

  defp health_partial?(states) do
    values = Map.values(states || %{})

    Enum.any?(values, &(&1.status in [:unavailable, :stale])) and
      Enum.any?(values, &(&1.status in [:ready, :stale]))
  end

  defp health_panel_name(:failed_ingest), do: "failed webhook evidence"
  defp health_panel_name(:orphan_backlog), do: "unmatched Event evidence"
  defp health_panel_name(:replay_outcomes), do: "replay audit evidence"
  defp health_panel_name(:reconcile_facts), do: "reconciliation evidence"
  defp health_panel_name(:active_suppressions), do: "active suppression records"

  defp support_evidence_path(base_path, filter_params, dark_chrome, :orphan_backlog, summary) do
    unmatched_events_path(base_path, filter_params, dark_chrome, summary)
  end

  defp support_evidence_path(base_path, filter_params, dark_chrome, :failed_ingest, summary) do
    state = %{
      focus: :failed_ingest,
      event_id: nil,
      webhook_event_id: get_in(summary || %{}, [:failed_ingest, :latest, :webhook_event_id])
    }

    build_path(base_path, Map.put(filter_params, "view", "deliveries"), nil, dark_chrome, state)
  end

  defp support_evidence_path(base_path, filter_params, dark_chrome, focus, summary) do
    event_id =
      case focus do
        :replay_outcomes ->
          get_in(summary || %{}, [:replay_outcomes, :latest, :event_id])

        :reconcile_facts ->
          get_in(summary || %{}, [:reconcile_facts, :latest_reconciled, :event_id])

        _ ->
          nil
      end

    state = %{focus: focus, event_id: event_id, webhook_event_id: nil}
    build_path(base_path, Map.put(filter_params, "view", "deliveries"), nil, dark_chrome, state)
  end

  defp support_focus?(%{focus: focus}), do: not is_nil(focus)
  defp support_focus?(_support_state), do: false

  defp support_focus_title(%{focus: :orphan_backlog, event_id: id}) when is_binary(id),
    do: "Exact Account Event"

  defp support_focus_title(%{focus: :failed_ingest, webhook_event_id: id}) when is_binary(id),
    do: "Exact Account webhook"

  defp support_focus_title(%{focus: :orphan_backlog}), do: "Unmatched webhook evidence"
  defp support_focus_title(%{focus: :failed_ingest}), do: "Failure evidence"
  defp support_focus_title(%{focus: :replay_outcomes}), do: "Replay evidence"
  defp support_focus_title(%{focus: :reconcile_facts}), do: "Reconcile evidence"
  defp support_focus_title(_support_state), do: "Support evidence"

  defp support_focus_body(%{focus: :orphan_backlog, event_id: id}) when is_binary(id),
    do:
      "The requested Account Event is retained below. Its current Delivery relationship may mean it is no longer part of the unmatched population."

  defp support_focus_body(%{focus: :failed_ingest, webhook_event_id: id}) when is_binary(id),
    do:
      "The requested Account webhook row is retained below with its current stored status, which may differ from the failed-attempt population that linked here."

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
