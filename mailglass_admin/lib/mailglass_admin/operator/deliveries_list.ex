defmodule MailglassAdmin.Operator.DeliveriesList do
  @moduledoc """
  Recent deliveries list with semantic selected-row treatment.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :deliveries, :list, required: true
  attr :selected_delivery, :map, default: nil

  def deliveries_list(assigns) do
    ~H"""
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
                "flex min-h-11 w-full flex-col gap-3 px-4 py-4 text-left transition-colors",
                row_classes(@selected_delivery, delivery)
              ]}
            >
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <p class="truncate text-sm font-bold text-base-content">
                    {mask_recipient(delivery.recipient)}
                  </p>
                  <p class="mono mt-1 text-xs text-secondary">{delivery.id}</p>
                </div>
                <span class={["badge badge-sm", badge_class(delivery.status)]}>
                  {label(delivery.status)}
                </span>
              </div>

              <div class="flex flex-wrap items-center gap-2 text-xs text-secondary">
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

  defp badge_class(status) when status in [:delivered, :sent, :dispatched], do: "badge-success"
  defp badge_class(:deferred), do: "badge-warning"
  defp badge_class(status) when status in [:failed, :bounced, :complained], do: "badge-error"
  defp badge_class(:suppressed), do: "badge-warning"
  defp badge_class(_status), do: "badge-outline"

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_datetime(nil), do: "Pending"
  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp mask_recipient(nil), do: "Unavailable"

  defp mask_recipient(recipient) when is_binary(recipient) do
    case String.split(recipient, "@", parts: 2) do
      [local, domain] -> mask_email(local, domain)
      _ -> mask_value(recipient)
    end
  end

  defp mask_email(local, domain) do
    case String.split(domain, ".", parts: 2) do
      [label, suffix] -> mask_value(local) <> "@" <> mask_value(label) <> "." <> suffix
      _ -> mask_value(local) <> "@" <> mask_value(domain)
    end
  end

  defp mask_value(value) do
    value
    |> String.graphemes()
    |> case do
      [] -> ""
      [first | rest] -> first <> String.duplicate("*", length(rest))
    end
  end
end
