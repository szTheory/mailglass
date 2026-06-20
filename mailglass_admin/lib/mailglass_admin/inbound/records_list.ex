defmodule MailglassAdmin.Inbound.RecordsList do
  @moduledoc """
  Recent inbound records list with dual table+card presentation.

  Renders a semantic `<table>` at >=768px and a `<ul>` of card buttons at <768px,
  both driven from the same `@records` assign with identical selection semantics,
  result-count, and pagination.

  Sibling of `MailglassAdmin.Operator.DeliveriesList` (clone, not a
  refactor). Rows render the masked envelope recipient via the one promoted
  `MailglassAdmin.Components.mask_recipient/1` definition, the record id in mono,
  an outcome badge via `Components.status_badge/1` (normalized through
  `normalize_inbound_outcome/1`), and a meta line mailbox · tenant · provider · received_at.

  Data-state branches render four distinct `Components.data_state/1` kinds when
  there is no row data to show. The four branches are:

    * `:empty` — no records (no-data / filtered / no-tenant distinction preserved)
    * `:error` — data unavailable
    * `:permission_denied` — access restricted
    * `:stale` — data may be out of date
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

  # :empty | :error | :permission_denied | :stale | nil
  # nil means "normal flow": render records or the legacy empty branches
  attr(:data_state, :atom, default: nil)

  def records_list(assigns) do
    ~H"""
    <div
      data-testid="inbound-result-count"
      class="border-b border-base-300 px-4 py-3 text-body text-secondary"
    >
      {result_count_label(@page_meta)}
    </div>
    <%= cond do %>
      <% @data_state == :error -> %>
        <Components.data_state
          kind={:error}
          title="Record data unavailable"
          body="Record data could not be loaded. Refresh the page or adjust the filters, then try again."
        />
      <% @data_state == :permission_denied -> %>
        <Components.data_state
          kind={:permission_denied}
          title="Access restricted"
          body="You do not have access to this tenant's inbound routing. Ask an administrator to grant access."
        />
      <% @data_state == :stale -> %>
        <Components.data_state
          kind={:stale}
          title="Data may be out of date"
          body="Showing InboundMessages as of 14:32. Refresh to load the latest."
        />
      <% @data_state == :empty or (@data_state == nil and @records == []) -> %>
        <%!-- :no_tenant retains its original selector copy; :truly_empty and :filtered use UI-SPEC "No records" copy --%>
        <%= if @empty_state == :no_tenant do %>
          <Components.data_state
            kind={:empty}
            title="Select a tenant"
            body="Choose a tenant to inspect its deliveries and inbound routing. Tenant scope stays in the URL so refreshes and shared links keep the same view."
          />
          <div data-testid="inbound-empty-no-tenant" style="display:none" />
        <% else %>
          <Components.data_state
            kind={:empty}
            title="No records"
            body={empty_body(@empty_state)}
          />
          <%= if @empty_state == :filtered do %>
            <div data-testid="inbound-empty-filtered" style="display:none" />
            <button
              type="button"
              phx-click="clear_filters"
              data-testid="inbound-empty-reset"
              class="btn btn-ghost min-h-11 mx-auto block"
            >
              Clear filters
            </button>
          <% else %>
            <div data-testid="inbound-empty-truly" style="display:none" />
          <% end %>
        <% end %>
      <% true -> %>
        <%!-- Desktop table (>=768px) --%>
        <div class="hidden md:block overflow-x-auto" data-testid="inbound-records-table">
          <table class="table w-full table-fixed">
            <thead>
              <tr>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-32">Outcome</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary">Recipient</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary">Mailbox</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-32">Tenant</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-24">Provider</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-44">Received</th>
              </tr>
            </thead>
            <tbody>
              <tr
                :for={record <- @records}
                data-testid="inbound-record-row"
                data-selected={if selected?(@selected_record, record), do: "true", else: "false"}
                phx-click="select_inbound"
                phx-value-id={record.id}
                aria-current={if selected?(@selected_record, record), do: "true", else: "false"}
                aria-selected={if selected?(@selected_record, record), do: "true", else: "false"}
                class={[
                  "mg-focus-ring-inset min-h-11 cursor-pointer transition-colors",
                  row_classes(@selected_record, record)
                ]}
              >
                <td class="text-body text-base-content">
                  <span data-testid={"inbound-outcome-#{record_outcome(record)}"}>
                    <Components.status_badge
                      status={Components.normalize_inbound_outcome(record_outcome(record))}
                      size={:sm}
                    />
                  </span>
                </td>
                <td class="min-w-0 text-body text-base-content">
                  <span
                    class="min-w-0 truncate block"
                    title={Components.mask_recipient(Map.get(record, :envelope_recipient))}
                  >
                    {Components.mask_recipient(Map.get(record, :envelope_recipient))}
                  </span>
                </td>
                <td class="min-w-0 text-body text-base-content">
                  <span
                    class="min-w-0 truncate block"
                    title={matched_mailbox_label(record)}
                  >
                    {matched_mailbox_label(record)}
                  </span>
                </td>
                <td class="min-w-0 text-body text-base-content">
                  <span class="min-w-0 truncate block" title={Map.get(record, :tenant_id, "")}>
                    {Map.get(record, :tenant_id, "")}
                  </span>
                </td>
                <td class="text-body text-base-content">
                  <span
                    class="mono min-w-0 truncate block"
                    title={String.upcase(Map.get(record, :provider, nil) || "unknown")}
                  >
                    {String.upcase(Map.get(record, :provider, nil) || "unknown")}
                  </span>
                </td>
                <td class="text-label text-secondary">
                  <span
                    class="mono whitespace-nowrap"
                    title={format_datetime(Map.get(record, :received_at))}
                  >
                    {format_datetime(Map.get(record, :received_at))}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <%!-- Mobile cards (<768px) — inbound-records-list kept for legacy consumers; Plan 04 migrates --%>
        <div data-testid="inbound-records-cards" class="md:hidden">
          <ul
            data-testid="inbound-records-list"
            class="divide-y divide-base-300"
          >
            <li :for={record <- @records}>
              <button
                data-testid="inbound-record-row"
                data-selected={if selected?(@selected_record, record), do: "true", else: "false"}
                type="button"
                phx-click="select_inbound"
                phx-value-id={record.id}
                aria-current={if selected?(@selected_record, record), do: "true", else: "false"}
                aria-selected={if selected?(@selected_record, record), do: "true", else: "false"}
                class={[
                  "mg-focus-ring-inset flex min-h-11 w-full flex-col gap-sm px-4 py-4 text-left transition-colors",
                  row_classes(@selected_record, record)
                ]}
              >
                <%!-- Outcome badge first/prominent --%>
                <div>
                  <span data-testid={"inbound-outcome-#{record_outcome(record)}"}>
                    <Components.status_badge
                      status={Components.normalize_inbound_outcome(record_outcome(record))}
                      size={:sm}
                    />
                  </span>
                </div>

                <%!-- Envelope recipient (masked) --%>
                <div class="min-w-0">
                  <span class="text-label font-bold uppercase text-secondary">Recipient</span>
                  <p
                    class="min-w-0 truncate text-body text-base-content"
                    title={Components.mask_recipient(Map.get(record, :envelope_recipient))}
                  >
                    {Components.mask_recipient(Map.get(record, :envelope_recipient))}
                  </p>
                </div>

                <%!-- Record ID with truncate+title --%>
                <div class="min-w-0">
                  <span class="text-label font-bold uppercase text-secondary">ID</span>
                  <p
                    class="mono min-w-0 truncate text-label text-secondary"
                    title={Map.get(record, :id, "")}
                  >
                    {Map.get(record, :id, "")}
                  </p>
                </div>

                <div class="flex flex-wrap items-start gap-md text-label text-secondary">
                  <%!-- Mailbox --%>
                  <div class="min-w-0">
                    <span class="font-bold uppercase">Mailbox</span>
                    <p
                      class="min-w-0 truncate"
                      title={matched_mailbox_label(record)}
                    >
                      {matched_mailbox_label(record)}
                    </p>
                  </div>

                  <%!-- Tenant --%>
                  <div class="min-w-0">
                    <span class="font-bold uppercase">Tenant</span>
                    <p class="min-w-0 truncate" title={Map.get(record, :tenant_id, "")}>
                      {Map.get(record, :tenant_id, "")}
                    </p>
                  </div>

                  <%!-- Provider --%>
                  <div>
                    <span class="font-bold uppercase">Provider</span>
                    <p
                      class="mono min-w-0 truncate"
                      title={String.upcase(Map.get(record, :provider, nil) || "unknown")}
                    >
                      {String.upcase(Map.get(record, :provider, nil) || "unknown")}
                    </p>
                  </div>

                  <%!-- Received timestamp --%>
                  <div>
                    <span class="font-bold uppercase">Received</span>
                    <p
                      class="mono whitespace-nowrap"
                      title={format_datetime(Map.get(record, :received_at))}
                    >
                      {format_datetime(Map.get(record, :received_at))}
                    </p>
                  </div>
                </div>
              </button>
            </li>
          </ul>
        </div>
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

  defp empty_body(:no_tenant),
    do:
      "Choose a tenant to inspect its deliveries and inbound routing. Tenant scope stays " <>
        "in the URL so refreshes and shared links keep the same view."

  defp empty_body(:truly_empty),
    do: "No records have been recorded yet."

  defp empty_body(:filtered), do: "No records match the current filters."

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
