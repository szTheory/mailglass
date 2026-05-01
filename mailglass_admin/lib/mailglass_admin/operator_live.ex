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

  alias Mailglass.Operator.{Deliveries, Suppressions}
  alias Mailglass.Operator.Timeline, as: OperatorTimelineData
  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.{DeliveriesList, DetailHeader, FiltersForm, SuppressionCard}
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
     |> assign(:deliveries, [])
     |> assign(:selected_delivery, nil)
     |> assign(:timeline_events, [])
     |> assign(:suppression_state, nil)
     |> assign(:detail_error, nil)
     |> assign(:base_path, "/operator")
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
     |> assign(:suppression_state, suppression_state)
     |> assign(:detail_error, detail_error)
     |> assign(:filter_params, filter_params)
     |> assign(:filter_form, to_form(filter_params, as: :filters))}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    normalized = normalize_filter_params(filters)

    {:noreply,
     push_patch(socket,
       to: build_path(socket.assigns.base_path, normalized, nil)
     )}
  end

  def handle_event("validate_filters", %{"filters" => filters}, socket) do
    {:noreply, assign(socket, :filter_form, to_form(normalize_filter_params(filters), as: :filters))}
  end

  def handle_event("select_delivery", %{"id" => delivery_id}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_path(socket.assigns.base_path, socket.assigns.filter_params, delivery_id)
     )}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.base_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-theme="mailglass-light" class="min-h-screen bg-base-100">
      <main class="mx-auto max-w-7xl px-4 py-6 md:px-6 md:py-8">
        <header class="mb-6 flex flex-col gap-2">
          <h1 class="text-xl font-bold text-base-content tracking-tight">Operator deliveries</h1>
          <p class="text-sm text-secondary">
            Browse tenant-scoped deliveries, inspect their event timeline, and review suppression state.
          </p>
        </header>

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

        <section class="mt-6 grid gap-6 lg:grid-cols-[minmax(22rem,28rem)_1fr]">
          <aside class="card rounded-box border border-base-300 bg-base-200 p-0">
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

          <section class="space-y-4">
            <%= cond do %>
              <% @detail_error -> %>
                <div class="card rounded-box border border-error bg-base-100 p-6">
                  <div class="flex items-center gap-2">
                    <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
                    <h2 class="text-base font-bold text-base-content">
                      Delivery data could not be loaded. Refresh the page or adjust the filters, then try again.
                    </h2>
                  </div>
                </div>

              <% is_nil(@selected_delivery) -> %>
                <div class="card rounded-box border border-base-300 bg-base-200 p-6">
                  <h2 class="text-base font-bold text-base-content">
                    Select a delivery to inspect its event timeline and suppression state.
                  </h2>
                </div>

              <% true -> %>
                <DetailHeader.detail_header delivery={@selected_delivery} />
                <OperatorTimeline.timeline timeline_events={@timeline_events} />
                <SuppressionCard.suppression_card suppression_state={@suppression_state} />
            <% end %>
          </section>
        </section>
      </main>
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
      "window_hours" => normalize_window(Map.get(params, "window_hours", defaults["window_hours"]))
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
        window_hours: parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
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
  defp find_selected_delivery(deliveries, delivery_id), do: Enum.find(deliveries, &(&1.id == delivery_id))

  defp detail_error_for(nil, _selected_delivery), do: nil
  defp detail_error_for(_delivery_id, nil), do: :not_found
  defp detail_error_for(_delivery_id, _selected_delivery), do: nil

  defp build_path(base_path, filter_params, delivery_id) do
    params =
      filter_params
      |> Map.merge(%{"delivery_id" => delivery_id})
      |> Enum.reject(fn {_key, value} -> is_nil(blank_to_nil(value)) end)
      |> Map.new()

    case URI.encode_query(params) do
      "" -> base_path
      query -> base_path <> "?" <> query
    end
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
