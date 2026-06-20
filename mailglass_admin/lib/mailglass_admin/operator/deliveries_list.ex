defmodule MailglassAdmin.Operator.DeliveriesList do
  @moduledoc """
  Recent deliveries list with dual table+card presentation.

  Renders a semantic `<table>` at >=768px and a `<ul>` of card buttons at <768px,
  both driven from the same `@deliveries` assign with identical selection semantics,
  result-count, and pagination.

  Data-state branches render four distinct `Components.data_state/1` kinds when
  there is no row data to show. The four branches are:

    * `:empty` — no records (no-data / filtered distinction preserved)
    * `:error` — data unavailable
    * `:permission_denied` — access restricted
    * `:stale` — data may be out of date

  Status is always rendered via `Components.status_badge/1`. Recipients are always
  masked via `Components.mask_recipient/1`. Long values use per-field classes from
  the deliveries table (truncate+title for IDs, whitespace-nowrap for timestamps).
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:deliveries, :list, required: true)

  attr(:page_meta, :map,
    default: %{total_count: 0, total_pages: 0, has_previous?: false, has_next?: false}
  )

  attr(:previous_page_path, :string, default: nil)
  attr(:next_page_path, :string, default: nil)
  attr(:selected_delivery, :map, default: nil)
  attr(:filters_active?, :boolean, default: false)

  # :empty | :error | :permission_denied | :stale | nil
  # nil means "normal flow": render deliveries or the legacy empty branches
  attr(:data_state, :atom, default: nil)

  def deliveries_list(assigns) do
    ~H"""
    <div
      data-testid="operator-result-count"
      class="border-b border-base-300 px-4 py-3 text-body text-secondary"
    >
      {result_count_label(@page_meta)}
    </div>
    <%= cond do %>
      <% @data_state == :error -> %>
        <Components.data_state
          kind={:error}
          title="Delivery data unavailable"
          body="Delivery data could not be loaded. Refresh the page or adjust the filters, then try again."
        />
      <% @data_state == :permission_denied -> %>
        <Components.data_state
          kind={:permission_denied}
          title="Access restricted"
          body="You do not have access to this tenant's mail operations. Ask an administrator to grant access."
        />
      <% @data_state == :stale -> %>
        <Components.data_state
          kind={:stale}
          title="Data may be out of date"
          body="Showing Deliveries as of 14:32. Refresh to load the latest."
        />
      <% @data_state == :empty or (@data_state == nil and @deliveries == []) -> %>
        <%= if @filters_active? do %>
          <Components.data_state
            kind={:empty}
            title="No deliveries"
            body="No deliveries match the current filters."
            data-testid-override="operator-empty-filtered"
          />
          <div
            data-testid="operator-empty-filtered"
            style="display:none"
          />
          <button
            type="button"
            phx-click="clear_filters"
            data-testid="operator-empty-reset"
            class="btn btn-ghost min-h-11 mx-auto block"
          >
            Clear filters
          </button>
        <% else %>
          <Components.data_state
            kind={:empty}
            title="No deliveries"
            body="No deliveries have been recorded yet."
            data-testid-override="operator-empty-truly"
          />
          <div
            data-testid="operator-empty-truly"
            style="display:none"
          />
        <% end %>
      <% true -> %>
        <%!-- Desktop table (>=768px) --%>
        <div class="hidden md:block overflow-x-auto" data-testid="operator-deliveries-table">
          <table class="table w-full table-fixed">
            <thead>
              <tr>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-32">Status</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary">Recipient</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-32">Tenant</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-24">Provider</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-28">Event</th>
                <th scope="col" class="text-label font-bold uppercase text-secondary w-44">Last event</th>
              </tr>
            </thead>
            <tbody>
              <tr
                :for={delivery <- @deliveries}
                data-testid="operator-delivery-row"
                data-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
                phx-click="select_delivery"
                phx-value-id={delivery.id}
                aria-current={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
                aria-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
                class={[
                  "mg-focus-ring-inset min-h-11 cursor-pointer transition-colors",
                  row_classes(@selected_delivery, delivery)
                ]}
              >
                <td class="text-body text-base-content">
                  <Components.status_badge status={delivery.status} size={:sm} />
                </td>
                <td class="min-w-0 text-body text-base-content">
                  <span
                    class="min-w-0 truncate block"
                    title={Components.mask_recipient(delivery.recipient)}
                  >
                    {Components.mask_recipient(delivery.recipient)}
                  </span>
                </td>
                <td class="min-w-0 text-body text-base-content">
                  <span class="min-w-0 truncate block" title={delivery.tenant_id}>
                    {delivery.tenant_id}
                  </span>
                </td>
                <td class="text-body text-base-content">
                  <span class="mono min-w-0 truncate block" title={delivery.provider}>
                    {String.upcase(delivery.provider || "unknown")}
                  </span>
                </td>
                <td class="text-body text-base-content">
                  {label(delivery.last_event_type)}
                </td>
                <td class="text-label text-secondary">
                  <span
                    class="mono whitespace-nowrap"
                    title={format_datetime(delivery.last_event_at)}
                  >
                    {format_datetime(delivery.last_event_at)}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <%!-- Mobile cards (<768px) — operator-deliveries-list kept for legacy consumers; Plan 04 migrates --%>
        <div data-testid="operator-deliveries-cards" class="md:hidden">
        <ul
          data-testid="operator-deliveries-list"
          class="divide-y divide-base-300"
        >
          <li :for={delivery <- @deliveries}>
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
              <%!-- Status badge first/prominent --%>
              <div>
                <Components.status_badge status={delivery.status} size={:sm} />
              </div>

              <%!-- Recipient (masked) --%>
              <div class="min-w-0">
                <span class="text-label font-bold uppercase text-secondary">Recipient</span>
                <p
                  class="min-w-0 truncate text-body text-base-content"
                  title={Components.mask_recipient(delivery.recipient)}
                >
                  {Components.mask_recipient(delivery.recipient)}
                </p>
              </div>

              <%!-- Delivery ID with truncate+title --%>
              <div class="min-w-0">
                <span class="text-label font-bold uppercase text-secondary">ID</span>
                <p
                  class="mono min-w-0 truncate text-label text-secondary"
                  title={delivery.id}
                >
                  {delivery.id}
                </p>
              </div>

              <div class="flex flex-wrap items-start gap-md text-label text-secondary">
                <%!-- Tenant --%>
                <div class="min-w-0">
                  <span class="font-bold uppercase">Tenant</span>
                  <p class="min-w-0 truncate" title={delivery.tenant_id}>
                    {delivery.tenant_id}
                  </p>
                </div>

                <%!-- Provider --%>
                <div>
                  <span class="font-bold uppercase">Provider</span>
                  <p class="mono min-w-0 truncate" title={delivery.provider}>
                    {String.upcase(delivery.provider || "unknown")}
                  </p>
                </div>

                <%!-- Event --%>
                <div>
                  <span class="font-bold uppercase">Event</span>
                  <p>{label(delivery.last_event_type)}</p>
                </div>

                <%!-- Timestamp --%>
                <div>
                  <span class="font-bold uppercase">Last event</span>
                  <p
                    class="mono whitespace-nowrap"
                    title={format_datetime(delivery.last_event_at)}
                  >
                    {format_datetime(delivery.last_event_at)}
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
      data-testid="operator-pagination"
      aria-label="Deliveries pagination"
      class="flex items-center justify-between gap-sm border-t border-base-300 px-4 py-3 text-body"
    >
      <.pagination_link
        enabled?={Map.get(@page_meta, :has_previous?, false)}
        path={@previous_page_path}
        testid="operator-pagination-prev"
      >
        Previous
      </.pagination_link>

      <span class="text-label text-secondary">
        Page {Map.get(@page_meta, :page, 1)} of {Map.get(@page_meta, :total_pages, 1)}
      </span>

      <.pagination_link
        enabled?={Map.get(@page_meta, :has_next?, false)}
        path={@next_page_path}
        testid="operator-pagination-next"
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

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
