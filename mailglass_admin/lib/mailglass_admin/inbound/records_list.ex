defmodule MailglassAdmin.Inbound.RecordsList do
  @moduledoc """
  Recent inbound records list with semantic selected-row treatment.

  Sibling of `MailglassAdmin.Operator.DeliveriesList` (the design contract — clone, not a
  refactor). Rows render the masked envelope recipient via the one promoted
  `MailglassAdmin.Components.mask_recipient/1` definition, the record id in mono,
  an outcome badge, and a meta line `tenant · PROVIDER · matched-mailbox-or-"no
  match" · received_at`.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :records, :list, required: true
  attr :selected_record, :map, default: nil

  def records_list(assigns) do
    ~H"""
    <%= if @records == [] do %>
      <div class="flex min-h-64 flex-col items-center justify-center gap-3 p-6 text-center">
        <Components.icon name="hero-inbox-stack" class="h-8 w-8 text-secondary" />
        <div class="space-y-1">
          <h3 class="text-base font-bold text-base-content">No inbound records</h3>
          <p class="text-sm text-secondary">
            No inbound records match these filters. Clear the filters or wait for the next inbound message.
          </p>
        </div>
      </div>
    <% else %>
      <ul data-testid="inbound-records-list" class="divide-y divide-base-300">
        <%= for record <- @records do %>
          <li>
            <button
              data-testid="inbound-record-row"
              data-selected={if selected?(@selected_record, record), do: "true", else: "false"}
              type="button"
              phx-click="select_inbound"
              phx-value-id={record.id}
              aria-current={if selected?(@selected_record, record), do: "true", else: "false"}
              aria-selected={if selected?(@selected_record, record), do: "true", else: "false"}
              class={[
                "flex min-h-11 w-full flex-col gap-3 px-4 py-4 text-left transition-colors",
                row_classes(@selected_record, record)
              ]}
            >
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <p class="truncate text-sm font-bold text-base-content">
                    {Components.mask_recipient(record.envelope_recipient)}
                  </p>
                  <p class="mono mt-1 text-xs text-secondary">{record.id}</p>
                </div>
                <Components.status_badge status={Components.normalize_inbound_outcome(record_outcome(record))} size={:sm} />
              </div>

              <div class="flex flex-wrap items-center gap-2 text-xs text-secondary">
                <span>{record.tenant_id}</span>
                <span>&middot;</span>
                <span>{String.upcase(record.provider || "unknown")}</span>
                <span>&middot;</span>
                <span>{matched_mailbox_label(record)}</span>
                <span>&middot;</span>
                <span class="mono">{format_datetime(record.received_at)}</span>
              </div>
            </button>
          </li>
        <% end %>
      </ul>
    <% end %>
    """
  end

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_selected_record, _record), do: false

  defp row_classes(%{id: id}, %{id: id}),
    do: "border-l-4 border-primary bg-base-100 text-base-content"

  defp row_classes(_selected_record, _record),
    do: "border-l-4 border-transparent bg-base-200 text-base-content hover:bg-base-100"

  # The list projection (Records.list_records/2) does not carry an outcome, so it
  # is read defensively — an absent key renders the neutral outline badge.
  defp record_outcome(record), do: Map.get(record, :outcome)

  defp matched_mailbox_label(record) do
    case Map.get(record, :mailbox) do
      mailbox when is_binary(mailbox) and mailbox != "" -> mailbox
      _ -> "no match"
    end
  end

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
