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

  attr(:records, :list, required: true)

  attr(:page_meta, :map,
    default: %{total_count: 0, total_pages: 0, has_previous?: false, has_next?: false}
  )

  attr(:previous_page_path, :string, default: nil)
  attr(:next_page_path, :string, default: nil)
  attr(:selected_record, :map, default: nil)

  attr(:empty_state, :atom,
    values: [:no_tenant, :truly_empty, :filtered],
    default: :filtered
  )

  def records_list(assigns) do
    ~H"""
    <div
      data-testid="inbound-result-count"
      class="border-b border-base-300 px-4 py-3 text-body text-secondary"
    >
      {result_count_label(@page_meta)}
    </div>
    <%= if @records == [] do %>
      <div class="flex min-h-64 flex-col items-center justify-center gap-sm p-6 text-center">
        <Components.icon name="hero-inbox-stack" class="h-8 w-8 text-secondary" />
        <div class="space-y-1">
          <h3 class="text-body font-bold text-base-content">{empty_heading(@empty_state)}</h3>
          <p class="text-body text-secondary">{empty_body(@empty_state)}</p>
        </div>
        <button
          :if={@empty_state == :filtered}
          type="button"
          phx-click="clear_filters"
          class="btn btn-ghost min-h-11"
        >
          Clear filters
        </button>
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
                "flex min-h-11 w-full flex-col gap-sm px-4 py-4 text-left transition-colors",
                row_classes(@selected_record, record)
              ]}
            >
              <div class="flex items-start justify-between gap-sm">
                <div class="min-w-0">
                  <p class="truncate text-body font-bold text-base-content">
                    {Components.mask_recipient(record.envelope_recipient)}
                  </p>
                  <p class="mono mt-1 text-label text-secondary">{record.id}</p>
                </div>
                <Components.status_badge
                  status={Components.normalize_inbound_outcome(record_outcome(record))}
                  size={:sm}
                />
              </div>

              <div class="flex flex-wrap items-center gap-2 text-label text-secondary">
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
    <.pagination_controls
      page_meta={@page_meta}
      previous_page_path={@previous_page_path}
      next_page_path={@next_page_path}
    />
    """
  end

  attr(:page_meta, :map, required: true)
  attr(:previous_page_path, :string, default: nil)
  attr(:next_page_path, :string, default: nil)

  defp pagination_controls(assigns) do
    ~H"""
    <nav
      :if={Map.get(@page_meta, :total_pages, 0) > 1}
      data-testid="inbound-pagination"
      aria-label="Inbound records pagination"
      class="flex items-center justify-between gap-sm border-t border-base-300 px-4 py-3 text-body"
    >
      <.pagination_link
        enabled?={Map.get(@page_meta, :has_previous?, false)}
        path={@previous_page_path}
        testid="inbound-pagination-prev"
      >
        Previous
      </.pagination_link>

      <span class="text-label text-secondary">
        Page {Map.get(@page_meta, :page, 1)} of {Map.get(@page_meta, :total_pages, 1)}
      </span>

      <.pagination_link
        enabled?={Map.get(@page_meta, :has_next?, false)}
        path={@next_page_path}
        testid="inbound-pagination-next"
      >
        Next
      </.pagination_link>
    </nav>
    """
  end

  attr(:enabled?, :boolean, required: true)
  attr(:path, :string, default: nil)
  attr(:testid, :string, required: true)
  slot(:inner_block, required: true)

  defp pagination_link(assigns) do
    ~H"""
    <.link
      :if={@enabled? and is_binary(@path)}
      patch={@path}
      data-testid={@testid}
      class="btn btn-ghost min-h-11 px-md"
    >
      {render_slot(@inner_block)}
    </.link>
    <span
      :if={!@enabled? or !is_binary(@path)}
      data-testid={"#{@testid}-disabled"}
      aria-disabled="true"
      class="btn btn-ghost min-h-11 px-md opacity-60"
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp result_count_label(%{total_count: 1}), do: "1 result"

  defp result_count_label(%{total_count: count}) when is_integer(count),
    do: "#{count} results"

  defp result_count_label(_page_meta), do: "0 results"

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_selected_record, _record), do: false

  defp empty_heading(:no_tenant), do: "Select a tenant"
  defp empty_heading(:truly_empty), do: "No InboundMessages yet"
  defp empty_heading(:filtered), do: "No InboundMessages match these filters"

  defp empty_body(:no_tenant),
    do:
      "Choose a tenant to inspect its deliveries and inbound routing. Tenant scope stays " <>
        "in the URL so refreshes and shared links keep the same view."

  defp empty_body(:truly_empty),
    do: "InboundMessages appear here once this tenant receives its first message."

  defp empty_body(:filtered), do: "Adjust the filters or wait for the next inbound message."

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
