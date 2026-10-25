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

  Status is always rendered via `Components.status_badge/1`. Recipients identify
  the delivery and open its details. Long values use per-field classes from
  the deliveries table (truncate+title for IDs, whitespace-nowrap for timestamps).
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Accounts

  attr(:heading, :string, default: "Deliveries")
  attr(:deliveries, :list, required: true)
  attr(:account_labels, :map, default: %{})

  attr(:page_meta, :map,
    default: %{total_count: 0, total_pages: 0, has_previous?: false, has_next?: false}
  )

  attr(:previous_page_path, :string, default: nil)
  attr(:next_page_path, :string, default: nil)
  attr(:selected_delivery, :map, default: nil)
  attr(:filters_active?, :boolean, default: false)
  # The operator list is always scoped to one account, so the Account column repeats
  # a constant value — callers pass `false` to reclaim that width for the record data.
  attr(:show_account?, :boolean, default: true)

  # :empty | :error | :permission_denied | :stale | nil
  # nil means "normal flow": render deliveries or the legacy empty branches
  attr(:data_state, :atom, default: nil)
  attr(:retry_event, :string, default: "retry_deliveries")

  def deliveries_list(assigns) do
    ~H"""
    <Components.collection_header
      title={@heading}
      count={Map.get(@page_meta, :total_count, 0)}
      count_label={result_count_label(@page_meta)}
      count_testid="operator-result-count"
    />
    <div class="min-w-0 overflow-hidden rounded-box border border-base-300 bg-base-200">
    <Components.data_state
      :if={@data_state == :stale}
      kind={:stale}
      title="This view may be out of date."
      body="The latest read was unavailable. Showing the last results loaded for this Account."
    />
    <%= cond do %>
      <% @data_state == :error -> %>
        <Components.data_state
          kind={:error}
          title="This view could not be updated."
          body="Refresh to try again. If it continues, contact your Mailglass host administrator."
        />
        <button type="button" phx-click={@retry_event} class="btn btn-ghost min-h-11 mx-auto block">
          Retry deliveries
        </button>
      <% @data_state == :permission_denied -> %>
        <Components.data_state
          kind={:permission_denied}
          title="Access restricted"
          body="You do not have access to this account's mail operations. Ask an administrator to grant access."
        />
      <% @deliveries == [] and @page_meta.total_count > 0 -> %>
        <Components.data_state
          kind={:empty}
          title="No deliveries on this page"
          body="Move to an available page to inspect the current results."
        />
      <% @data_state == :empty or
        (@data_state in [nil, :ready] and @deliveries == []) -> %>
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
            title="No deliveries in this time window"
            body="No deliveries have been recorded for this Account during the selected time window."
            data-testid-override="operator-empty-truly"
          />
          <div
            data-testid="operator-empty-truly"
            style="display:none"
          />
        <% end %>
      <% true -> %>
        <div class="operator-deliveries-layout">
          <%!-- The list switches based on available content width, including the shared sidebar. --%>
          <div
            class="operator-deliveries-table overflow-x-auto"
            data-testid="operator-deliveries-table"
            role="region"
            aria-label="Delivery records"
            tabindex="0"
          >
            <table class="table w-full table-fixed">
              <thead>
                <tr>
                  <th scope="col" class="text-label font-bold text-secondary">Recipient / Subject</th>
                  <th scope="col" class="text-label font-bold text-secondary w-40">Outcome</th>
                  <th :if={@show_account?} scope="col" class="text-label font-bold text-secondary w-40">Account</th>
                  <th scope="col" class="text-label font-bold text-secondary w-32">Provider</th>
                  <th scope="col" class="text-label font-bold text-secondary w-52">Updated</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={delivery <- @deliveries}
                  data-testid="operator-delivery-row"
                  data-selected={
                    if selected?(@selected_delivery, delivery), do: "true", else: "false"
                  }
                  phx-click="select_delivery"
                  phx-keydown="select_delivery"
                  phx-key="Enter"
                  phx-value-id={delivery.id}
                  phx-value-focus-return-id={row_id(:desktop, delivery.id)}
                  tabindex="0"
                  class={[
                    "transition-colors",
                    row_classes(@selected_delivery, delivery)
                  ]}
                >
                  <td class="min-w-0 text-body text-base-content">
                    <button id={row_id(:desktop, delivery.id)} type="button" phx-click="select_delivery" phx-value-id={delivery.id}
                      phx-value-focus-return-id={row_id(:desktop, delivery.id)}
                      aria-label={"Open delivery for #{delivery.recipient}"}
                      aria-current={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
                      aria-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
                      class="mg-focus-ring flex min-h-11 w-full min-w-0 flex-col items-start justify-center text-left hover:text-primary"
                      title={delivery.recipient}>
                      <span class="min-w-0 w-full truncate block">{delivery.recipient}</span>
                      <span class="min-w-0 w-full truncate text-label text-secondary" title={subject(delivery)}>{subject(delivery)}</span>
                    </button>
                  </td>
                  <td class="text-body text-base-content">
                    <Components.outcome_badge id={"delivery-outcome-table-#{delivery.id}"} status={Components.delivery_display_status(delivery)} context={:delivery} />
                    <p :if={different_event?(delivery)} class="text-label text-secondary">Latest: {event_label(delivery.last_event_type)}</p>
                  </td>
                  <td :if={@show_account?} class="min-w-0 text-body text-base-content">
                    <span
                      class="min-w-0 truncate block"
                      title={Accounts.title(delivery.tenant_id, @account_labels)}
                    >
                      {Accounts.label(delivery.tenant_id, @account_labels)}
                    </span>
                  </td>
                  <td class="text-body text-base-content">
                    <span class="mono min-w-0 truncate block" title={delivery.provider}>
                      {String.upcase(delivery.provider || "unknown")}
                    </span>
                  </td>
                  <td class="text-label text-secondary">
                    <Components.timestamp at={delivery.last_event_at} class="whitespace-nowrap" />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <%!-- Cards remain readable until the list's own content area reaches 768px. --%>
          <div data-testid="operator-deliveries-cards" class="operator-deliveries-cards">
            <ul
              data-testid="operator-deliveries-list"
              class="divide-y divide-base-300"
            >
              <li :for={delivery <- @deliveries} class="px-4 py-4">
                <button
                  id={row_id(:mobile, delivery.id)}
                  data-testid="operator-delivery-row"
                  data-selected={
                    if selected?(@selected_delivery, delivery), do: "true", else: "false"
                  }
                  type="button"
                  phx-click="select_delivery"
                  phx-value-id={delivery.id}
                  phx-value-focus-return-id={row_id(:mobile, delivery.id)}
                  aria-current={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
                  aria-selected={
                    if selected?(@selected_delivery, delivery), do: "true", else: "false"
                  }
                  class={[
                    "mg-focus-ring-inset flex min-h-11 w-full flex-col gap-sm text-left transition-colors",
                    row_classes(@selected_delivery, delivery)
                  ]}
                >
                  <p class="min-w-0 break-words text-body text-base-content" title={delivery.recipient}>
                    {delivery.recipient}
                  </p>
                  <p class="min-w-0 break-words text-label text-secondary" title={subject(delivery)}>{subject(delivery)}</p>
                </button>
                  <div>
                    <Components.outcome_badge id={"delivery-outcome-card-#{delivery.id}"} status={Components.delivery_display_status(delivery)} context={:delivery} />
                  </div>

                  <%!-- Keep the exact stable ID visible and copyable without hover. --%>
                  <div class="min-w-0">
                    <span class="text-label font-bold uppercase text-secondary">ID</span>
                    <p
                      class="mono min-w-0 break-all text-label text-secondary"
                      title={delivery.id}
                    >
                      {delivery.id}
                    </p>
                  </div>

                  <div class="flex flex-wrap items-start gap-md text-label text-secondary">
                    <div :if={different_event?(delivery)}>
                      <span class="font-bold uppercase">Latest event</span>
                      <p class="text-body text-base-content">
                        {event_label(delivery.last_event_type)}
                      </p>
                    </div>
                    <%!-- Account --%>
                    <div :if={@show_account?} class="min-w-0">
                      <span class="font-bold uppercase">Account</span>
                      <p
                        class="min-w-0 break-words"
                        title={Accounts.title(delivery.tenant_id, @account_labels)}
                      >
                        {Accounts.label(delivery.tenant_id, @account_labels)}
                      </p>
                    </div>

                    <%!-- Provider --%>
                    <div>
                      <span class="font-bold uppercase">Provider</span>
                      <p class="mono min-w-0 break-all" title={delivery.provider}>
                        {String.upcase(delivery.provider || "unknown")}
                      </p>
                    </div>

                  </div>

                <div class="flex items-center gap-sm mt-sm text-label text-secondary">
                  <span>Updated</span>
                  <Components.timestamp at={delivery.last_event_at} class="whitespace-nowrap" />
                </div>
              </li>
            </ul>
          </div>
        </div>
    <% end %>
    <.pagination_controls
      page_meta={@page_meta}
      previous_page_path={@previous_page_path}
      next_page_path={@next_page_path}
    />
    </div>
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

  defp result_count_label(%{total_count: 1}), do: "1 delivery"

  defp result_count_label(%{total_count: count}) when is_integer(count),
    do: "#{count} deliveries"

  defp result_count_label(_page_meta), do: "0 deliveries"

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_selected_delivery, _delivery), do: false

  defp event_label(nil), do: "Unavailable"
  defp event_label(:unknown), do: "Unknown"

  defp event_label(event) when is_atom(event),
    do: event |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp row_id(:desktop, id), do: "operator-delivery-desktop-#{id}"
  defp row_id(:mobile, id), do: "operator-delivery-mobile-#{id}"

  defp row_classes(%{id: id}, %{id: id}),
    do: "border-l-4 border-primary bg-base-100 text-base-content"

  defp row_classes(_selected_delivery, _delivery),
    do: "border-l-4 border-transparent bg-base-200 text-base-content hover:bg-base-100"

  defp subject(record) do
    case Map.get(record, :subject) do
      nil -> "Subject not recorded"
      "" -> "(No subject)"
      value -> value
    end
  end

  defp different_event?(delivery) do
    event = Map.get(delivery, :last_event_type)
    not is_nil(event) and event != Components.delivery_display_status(delivery)
  end
end
