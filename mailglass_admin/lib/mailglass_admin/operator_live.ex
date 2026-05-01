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

  alias Mailglass.Operator.{Deliveries, Suppressions, Timeline}
  alias MailglassAdmin.Components

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
            class="grid gap-3 md:grid-cols-2 xl:grid-cols-5"
          >
            <label class="form-control">
              <span class="mb-1 text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                Tenant
              </span>
              <input
                type="text"
                name={@filter_form[:tenant_id].name}
                value={@filter_form[:tenant_id].value}
                class="input input-bordered min-h-11 w-full"
                placeholder="tenant-123"
              />
            </label>

            <label class="form-control">
              <span class="mb-1 text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                Provider
              </span>
              <input
                type="text"
                name={@filter_form[:provider].name}
                value={@filter_form[:provider].value}
                class="input input-bordered min-h-11 w-full"
                placeholder="postmark"
              />
            </label>

            <label class="form-control">
              <span class="mb-1 text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                Status
              </span>
              <select
                name={@filter_form[:status].name}
                class="select select-bordered min-h-11 w-full"
              >
                <option value="">Any status</option>
                <%= for status <- @status_values do %>
                  <option value={Atom.to_string(status)} selected={@filter_form[:status].value == Atom.to_string(status)}>
                    {status_label(status)}
                  </option>
                <% end %>
              </select>
            </label>

            <label class="form-control">
              <span class="mb-1 text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                Event
              </span>
              <select
                name={@filter_form[:event].name}
                class="select select-bordered min-h-11 w-full"
              >
                <option value="">Any event</option>
                <%= for event <- @event_values do %>
                  <option value={Atom.to_string(event)} selected={@filter_form[:event].value == Atom.to_string(event)}>
                    {event_label(event)}
                  </option>
                <% end %>
              </select>
            </label>

            <label class="form-control">
              <span class="mb-1 text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                Window
              </span>
              <div class="flex gap-2">
                <select
                  name={@filter_form[:window_hours].name}
                  class="select select-bordered min-h-11 flex-1"
                >
                  <%= for {label, value} <- @window_options do %>
                    <option value={value} selected={@filter_form[:window_hours].value == value}>
                      {label}
                    </option>
                  <% end %>
                </select>
                <button type="submit" class="btn btn-primary min-h-11 px-5">Open delivery</button>
              </div>
            </label>
          </.form>
        </section>

        <section class="mt-6 grid gap-6 lg:grid-cols-[minmax(22rem,28rem)_1fr]">
          <aside class="card rounded-box border border-base-300 bg-base-200 p-0">
            <div class="border-b border-base-300 px-4 py-3">
              <h2 class="text-sm font-bold uppercase tracking-[0.08em] text-secondary">
                Recent deliveries
              </h2>
            </div>

            <%= if @deliveries == [] do %>
              <div class="flex min-h-64 flex-col items-center justify-center gap-3 p-6 text-center">
                <Components.icon name="hero-inbox-stack" class="h-8 w-8 text-secondary" />
                <div class="space-y-1">
                  <h3 class="text-base font-bold text-base-content">No recent deliveries</h3>
                  <p class="text-sm text-secondary">
                    No recent deliveries match these filters. Clear the filters or wait for the next send.
                  </p>
                </div>
              </div>
            <% else %>
              <ul class="divide-y divide-base-300">
                <%= for delivery <- @deliveries do %>
                  <li>
                    <button
                      type="button"
                      phx-click="select_delivery"
                      phx-value-id={delivery.id}
                      aria-current={if @selected_delivery && @selected_delivery.id == delivery.id, do: "true", else: "false"}
                      class={[
                        "flex min-h-11 w-full flex-col gap-3 px-4 py-4 text-left transition-colors",
                        delivery_row_classes(@selected_delivery, delivery)
                      ]}
                    >
                      <div class="flex items-start justify-between gap-3">
                        <div class="min-w-0">
                          <p class="truncate text-sm font-bold text-base-content">{delivery.recipient}</p>
                          <p class="mono mt-1 text-xs text-secondary">{delivery.id}</p>
                        </div>
                        <span class={["badge badge-sm", badge_class(delivery.status)]}>
                          {status_label(delivery.status)}
                        </span>
                      </div>

                      <div class="flex flex-wrap items-center gap-2 text-xs text-secondary">
                        <span>{String.upcase(delivery.provider || "unknown")}</span>
                        <span>&middot;</span>
                        <span>{event_label(delivery.last_event_type)}</span>
                        <span>&middot;</span>
                        <span class="mono">{format_datetime(delivery.last_event_at)}</span>
                      </div>
                    </button>
                  </li>
                <% end %>
              </ul>
            <% end %>
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
                <article class="card rounded-box border border-base-300 bg-base-200 p-6">
                  <div class="flex flex-wrap items-start justify-between gap-4">
                    <div class="space-y-2">
                      <div class="flex flex-wrap items-center gap-2">
                        <h2 class="text-xl font-bold text-base-content">{@selected_delivery.recipient}</h2>
                        <span class={["badge", badge_class(@selected_delivery.status)]}>
                          {status_label(@selected_delivery.status)}
                        </span>
                      </div>
                      <p class="mono text-xs text-secondary">{@selected_delivery.id}</p>
                    </div>

                    <dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
                      <div>
                        <dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
                        <dd class="mt-1 text-base-content">{@selected_delivery.tenant_id}</dd>
                      </div>
                      <div>
                        <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider</dt>
                        <dd class="mt-1 text-base-content">{String.upcase(@selected_delivery.provider || "unknown")}</dd>
                      </div>
                      <div>
                        <dt class="text-xs font-bold uppercase tracking-[0.08em]">Latest event</dt>
                        <dd class="mt-1 text-base-content">{event_label(@selected_delivery.last_event_type)}</dd>
                      </div>
                      <div>
                        <dt class="text-xs font-bold uppercase tracking-[0.08em]">Updated</dt>
                        <dd class="mono mt-1 text-base-content">{format_datetime(@selected_delivery.last_event_at)}</dd>
                      </div>
                    </dl>
                  </div>
                </article>

                <article class="card rounded-box border border-base-300 bg-base-200 p-6">
                  <div class="mb-4 flex items-center justify-between gap-3">
                    <h3 class="text-base font-bold text-base-content">Event timeline</h3>
                    <span class="text-xs text-secondary">Chronological order</span>
                  </div>

                  <%= if @timeline_events == [] do %>
                    <p class="text-sm text-secondary">
                      No delivery events have been recorded for this item yet.
                    </p>
                  <% else %>
                    <ol class="space-y-4">
                      <%= for event <- @timeline_events do %>
                        <li class="flex gap-3">
                          <div class="mt-1 flex flex-col items-center">
                            <span class="h-3 w-3 rounded-full bg-primary"></span>
                            <span class="mt-2 h-full w-px bg-base-300"></span>
                          </div>
                          <div class="min-w-0 flex-1 rounded-box border border-base-300 bg-base-100 p-4">
                            <div class="flex flex-wrap items-start justify-between gap-3">
                              <div>
                                <p class="text-sm font-bold text-base-content">{event_label(event.type)}</p>
                                <p :if={event.reject_reason} class="mt-1 text-sm text-secondary">
                                  {reject_reason_label(event.reject_reason)}
                                </p>
                              </div>
                              <p class="mono text-xs text-secondary">{format_datetime(event.occurred_at)}</p>
                            </div>
                          </div>
                        </li>
                      <% end %>
                    </ol>
                  <% end %>
                </article>

                <article class="card rounded-box border border-base-300 bg-base-200 p-6">
                  <div class="mb-4 flex items-center justify-between gap-3">
                    <h3 class="text-base font-bold text-base-content">Suppression state</h3>
                    <span class="badge badge-outline">
                      {suppression_state_label(@suppression_state)}
                    </span>
                  </div>

                  <%= if @suppression_state do %>
                    <div class="space-y-3 text-sm">
                      <div class="grid gap-3 sm:grid-cols-2">
                        <div>
                          <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">Scope</p>
                          <p class="mt-1 text-base-content">{scope_label(@suppression_state.scope)}</p>
                        </div>
                        <div>
                          <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">Reason</p>
                          <p class="mt-1 text-base-content">{reason_label(@suppression_state.reason)}</p>
                        </div>
                      </div>
                      <p class="text-secondary">{@suppression_state.reversibility_copy}</p>
                    </div>
                  <% else %>
                    <p class="text-sm text-secondary">
                      No active suppression entry matches this delivery.
                    </p>
                  <% end %>
                </article>
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
    Timeline.list_delivery_events(
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
        recipient: delivery.recipient
      },
      []
    )
  end

  defp find_selected_delivery(deliveries, nil), do: nil
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

  defp delivery_row_classes(%{id: id}, %{id: id}),
    do: "border-l-4 border-primary bg-base-100 text-base-content"

  defp delivery_row_classes(_selected_delivery, _delivery),
    do: "border-l-4 border-transparent bg-base-200 text-base-content hover:bg-base-100"

  defp badge_class(status) when status in [:delivered, :sent, :dispatched], do: "badge-success"
  defp badge_class(:deferred), do: "badge-warning"
  defp badge_class(status) when status in [:failed, :bounced, :complained], do: "badge-error"
  defp badge_class(:suppressed), do: "badge-warning"
  defp badge_class(_status), do: "badge-outline"

  defp status_label(nil), do: "Unknown"
  defp status_label(status), do: status |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp event_label(nil), do: "Unknown event"
  defp event_label(event), do: status_label(event)

  defp reject_reason_label(reason), do: "Reason: " <> status_label(reason)

  defp suppression_state_label(nil), do: "No suppression"
  defp suppression_state_label(%{reversibility: :immutable}), do: "Immutable by policy"
  defp suppression_state_label(%{reversibility: :reversible}), do: "Reversible in a later phase"

  defp scope_label(scope), do: status_label(scope)
  defp reason_label(reason), do: status_label(reason)

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
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
