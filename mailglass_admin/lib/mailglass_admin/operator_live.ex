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

  alias MailglassAdmin.Operator.Timeline, as: OperatorTimeline

  @status_values [:queued, :sent, :dispatched, :failed, :suppressed]
  @event_values Mailglass.Outbound.Delivery.__event_types__()
  @default_window_hours 168
  @window_options [
    {"Last 24 hours", "24"},
    {"Last 7 days", "168"},
    {"Last 30 days", "720"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_new(:operator_actor, fn -> nil end)
     |> assign_new(:operator_auth, fn -> %{status: :unknown, recent_auth?: false} end)
     |> assign(:deliveries, [])
     |> assign(:selected_delivery, nil)
     |> assign(:timeline_events, [])
     |> assign(:suppression_state, nil)
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
     |> assign(:status_values, @status_values)
     |> assign(:event_values, @event_values)
     |> assign(:window_options, @window_options)
     |> assign(:filter_params, default_filter_params())
     |> assign(:filter_form, to_form(default_filter_params(), as: :filters))
     |> assign(:page_title, "mailglass — Operator")}
  end

  @impl true
  def handle_params(params, uri, socket) do
    filter_params = normalize_filter_params(params)
    support_state = normalize_support_state(params)

    {:noreply,
     socket
     |> assign(:base_path, URI.parse(uri).path || "/operator")
     |> assign(:page_uri, uri)
     |> assign(:dark_chrome, MailglassAdmin.Operator.Shell.dark_chrome?(params))
     |> assign(:filter_params, filter_params)
     |> assign(:filter_form, to_form(filter_params, as: :filters))
     |> assign(:support_state, support_state)
     |> assign_delivery_state(filter_params, blank_to_nil(params["delivery_id"]))
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
     push_patch(socket, to: socket.assigns.base_path <> theme_query(socket.assigns.dark_chrome))}
  end

  def handle_event("open_support_exemplar", params, socket) do
    support_state = support_state_from_event(params)
    delivery_id = blank_to_nil(params["delivery_id"]) || socket.assigns.selected_delivery.id

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
    with %{selected_delivery: %{id: delivery_id, tenant_id: tenant_id} = delivery} <-
           socket.assigns,
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
        {:noreply,
         put_flash(socket, :error, "Choose one webhook target before confirming replay.")}

      {:error, {:auth, message}} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign_delivery_state(
           socket.assigns.filter_params,
           socket.assigns.selected_delivery.id
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
      active={:deliveries}
      deliveries_path={@deliveries_path}
      inbound_path={@inbound_path}
      inbound_available?={@inbound_available?}
      dark_chrome={@dark_chrome}
      tenant={blank_to_nil(@filter_params["tenant_id"])}
      title="Deliveries"
      subtitle="Prove what happened to a message — inspect its event timeline, suppression state, and replay history."
      flash={@flash}
    >
      <div :if={is_nil(@selected_delivery)} class="mb-lg">
        <.orientation_strip />
      </div>

      <section class="card rounded-box border border-base-300 bg-base-200 p-4 md:p-5">
        <.form
          for={@filter_form}
          id="operator-filters"
          phx-change="validate_filters"
          phx-submit="apply_filters"
          class="grid gap-3"
        >
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
            <FiltersForm.fields
              form={@filter_form}
              status_values={@status_values}
              event_values={@event_values}
              window_options={@window_options}
            />
          </div>

          <div class="flex flex-wrap gap-2">
            <button type="submit" class="btn btn-primary min-h-11 px-5">Open delivery</button>
            <button type="button" phx-click="clear_filters" class="btn btn-ghost min-h-11 px-5">
              Clear filters
            </button>
          </div>
        </.form>
      </section>

      <section
        data-testid="operator-master-detail"
        class="mt-6 grid gap-6 lg:grid-cols-[minmax(22rem,28rem)_1fr]"
      >
        <aside
          data-testid="operator-deliveries-list-card"
          class="card rounded-box border border-base-300 bg-base-200 p-0"
        >
          <div class="border-b border-base-300 px-4 py-3">
            <h2 class="text-sm font-bold uppercase tracking-[0.08em] text-secondary">
              Recent deliveries
            </h2>
          </div>
          <DeliveriesList.deliveries_list
            deliveries={@deliveries}
            selected_delivery={@selected_delivery}
          />
        </aside>

        <section data-testid="operator-detail-column" class="space-y-4">
          <%= cond do %>
            <% @detail_error -> %>
              <div
                data-testid="operator-detail-error"
                class="card rounded-box border border-error bg-base-100 p-6"
              >
                <div class="flex items-center gap-2">
                  <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
                  <h2 class="text-base font-bold text-base-content">
                    Delivery data could not be loaded. Refresh the page or adjust the filters, then try again.
                  </h2>
                </div>
              </div>
            <% is_nil(@selected_delivery) -> %>
              <div
                data-testid="operator-empty-detail"
                class="card rounded-box border border-base-300 bg-base-200 p-6"
              >
                <h2 class="text-base font-bold text-base-content">
                  Select a delivery to inspect its event timeline and suppression state.
                </h2>
                <p class="mt-2 text-sm text-secondary">
                  The timeline shows provider lifecycle facts (dispatched, delivered, bounced).
                  Replay history is recorded separately — replaying a webhook does not create
                  new provider truth.
                </p>
              </div>
            <% true -> %>
              <div class="motion-reveal space-y-4">
                <DetailHeader.detail_header
                  delivery={@selected_delivery}
                  replay_targets={@replay_targets}
                  latest_replay={latest_replay(@replay_history)}
                />
                <SupportCards.support_cards
                  support_summary={@support_summary}
                  support_state={@support_state}
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

      <ReplayModal.replay_modal
        open?={@replay_modal_open?}
        delivery={@selected_delivery}
        replay_targets={@replay_targets}
        selected_target_id={@replay_selected_target_id}
      />
    </MailglassAdmin.Operator.Shell.shell>
    """
  end

  defp orientation_strip(assigns) do
    ~H"""
    <div
      class="rounded-box border border-base-300 bg-base-200 p-md"
      data-testid="operator-orientation"
    >
      <div class="flex items-start gap-sm">
        <Components.icon name="hero-lifebuoy" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
        <div class="min-w-0">
          <h2 class="text-body font-bold text-base-content">Start from the customer symptom</h2>
          <ul class="mt-2 grid gap-1 text-sm text-secondary">
            <li>
              <span class="font-bold text-base-content">Email never arrived?</span>
              Filter by tenant, then open the delivery to read its timeline.
            </li>
            <li>
              <span class="font-bold text-base-content">Replay changed nothing?</span>
              Check whether the outcome was <span class="mono">new work</span>
              or <span class="mono">no change</span>
              on the selected delivery.
            </li>
            <li>
              <span class="font-bold text-base-content">Address keeps getting blocked?</span>
              Open the delivery and review its suppression state.
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp default_filter_params do
    %{
      "tenant_id" => "",
      "provider" => "",
      "status" => "",
      "event" => "",
      "window_hours" => Integer.to_string(@default_window_hours)
    }
  end

  defp normalize_filter_params(params) do
    defaults = default_filter_params()

    %{
      "tenant_id" => normalize_string(Map.get(params, "tenant_id", defaults["tenant_id"])),
      "provider" => normalize_string(Map.get(params, "provider", defaults["provider"])),
      "status" => normalize_string(Map.get(params, "status", defaults["status"])),
      "event" => normalize_string(Map.get(params, "event", defaults["event"])),
      "window_hours" =>
        normalize_window(Map.get(params, "window_hours", defaults["window_hours"]))
    }
  end

  defp load_deliveries(%{"tenant_id" => ""}), do: []

  defp load_deliveries(filter_params) do
    Deliveries.list_recent_deliveries(
      %{
        tenant_id: filter_params["tenant_id"],
        provider: blank_to_nil(filter_params["provider"]),
        status: cast_enum(filter_params["status"], @status_values),
        event: cast_enum(filter_params["event"], @event_values),
        window_hours:
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
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
    deliveries = load_deliveries(filter_params)
    selected_delivery = find_selected_delivery(deliveries, selected_delivery_id)
    replay_targets = load_replay_targets(filter_params, selected_delivery)
    replay_history = load_replay_history(filter_params, selected_delivery)

    socket
    |> assign(:deliveries, deliveries)
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

  defp normalize_window(value) do
    value
    |> parse_positive_integer()
    |> Kernel.||(@default_window_hours)
    |> Integer.to_string()
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
        window_hours:
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
      }
    ])
  end

  defp support_summary_module, do: :"Elixir.Mailglass.Operator.SupportSummary"

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
