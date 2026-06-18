defmodule MailglassAdmin.Operator.DeliveriesList do
  @moduledoc """
  Recent deliveries list with semantic selected-row treatment.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :deliveries, :list, required: true
  attr :selected_delivery, :map, default: nil
  attr :filters_active?, :boolean, default: false

  def deliveries_list(assigns) do
    ~H"""
    <%= if @deliveries == [] do %>
      <div
        data-testid={if @filters_active?, do: "operator-empty-filtered", else: "operator-empty-truly"}
        class="flex min-h-64 flex-col items-center justify-center gap-sm p-6 text-center"
      >
        <Components.icon name="hero-inbox-stack" class="h-8 w-8 text-secondary" />
        <div class="space-y-1">
          <%= if @filters_active? do %>
            <h3 class="text-body font-bold text-base-content">No Deliveries match your filters</h3>
            <p class="text-body text-secondary">
              Adjust the filters or wait for the next send.
            </p>
          <% else %>
            <h3 class="text-body font-bold text-base-content">No Deliveries yet</h3>
            <p class="text-body text-secondary">
              Deliveries appear here once your application sends its first Message.
            </p>
          <% end %>
        </div>
        <button
          :if={@filters_active?}
          type="button"
          phx-click="clear_filters"
          data-testid="operator-empty-reset"
          class="btn btn-ghost min-h-11"
        >
          Clear filters
        </button>
      </div>
    <% else %>
      <ul data-testid="operator-deliveries-list" class="divide-y divide-base-300">
        <%= for delivery <- @deliveries do %>
          <li>
            <button
              data-testid="operator-delivery-row"
              data-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
              type="button"
              phx-click="select_delivery"
              phx-value-id={delivery.id}
              aria-current={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
              aria-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
              class={[
                "mg-focus-ring-inset flex min-h-11 w-full flex-col gap-sm px-4 py-4 text-left transition-colors",
                row_classes(@selected_delivery, delivery)
              ]}
            >
              <div class="flex items-start justify-between gap-sm">
                <div class="min-w-0">
                  <p class="truncate text-body font-bold text-base-content">
                    {Components.mask_recipient(delivery.recipient)}
                  </p>
                  <p class="mono mt-1 text-label text-secondary">{delivery.id}</p>
                </div>
                <Components.status_badge status={delivery.status} size={:sm} />
              </div>

              <div class="flex flex-wrap items-center gap-2 text-label text-secondary">
                <span>{delivery.tenant_id}</span>
                <span>&middot;</span>
                <span>{String.upcase(delivery.provider || "unknown")}</span>
                <span>&middot;</span>
                <span>{label(delivery.last_event_type)}</span>
                <span>&middot;</span>
                <span class="mono">{format_datetime(delivery.last_event_at)}</span>
              </div>
            </button>
          </li>
        <% end %>
      </ul>
    <% end %>
    """
  end

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_selected_delivery, _delivery), do: false

  defp row_classes(%{id: id}, %{id: id}),
    do: "border-l-4 border-primary bg-base-100 text-base-content"

  defp row_classes(_selected_delivery, _delivery),
    do: "border-l-4 border-transparent bg-base-200 text-base-content hover:bg-base-100"

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_datetime(nil), do: "Pending"
  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
