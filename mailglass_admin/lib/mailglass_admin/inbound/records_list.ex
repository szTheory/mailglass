defmodule MailglassAdmin.Inbound.RecordsList do
  @moduledoc """
  Recent inbound records list with dual table+card presentation.

  Renders a semantic `<table>` at >=768px and a `<ul>` of card buttons at <768px,
  both driven from the same `@records` assign with identical selection semantics,
  result-count, and pagination.

  Sibling of `MailglassAdmin.Operator.DeliveriesList` (clone, not a
  refactor). Rows render the envelope recipient, the record id in mono,
  an outcome badge via `Components.status_badge/1` (normalized through
  `normalize_inbound_outcome/1`), and a meta line mailbox · account · provider · received_at.

  Data-state branches render distinct `Components.data_state/1` kinds when
  there is no row data to show. Optional-package and database-read failures stay
  separate from successful empty results:

    * `:empty` — no records (no-data / filtered / page-boundary distinction preserved)
    * `:error` — data unavailable
    * `:permission_denied` — access restricted
    * `:stale` — data may be out of date
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Accounts

  attr(:records, :list, required: true)
  attr(:heading, :string, default: nil)
  attr(:account_labels, :map, default: %{})
  # Single-account operator surface: the Account column repeats a constant, so callers
  # pass `false` to reclaim that width for the record data.
  attr(:show_account?, :boolean, default: true)

  attr(:page_meta, :map,
    default: %{total_count: 0, total_pages: 0, has_previous?: false, has_next?: false}
  )

  attr(:previous_page_path, :string, default: nil)
  attr(:next_page_path, :string, default: nil)
  attr(:selected_record, :map, default: nil)

  attr(:empty_state, :atom,
    values: [:no_tenant, :truly_empty, :filtered, :out_of_range],
    default: :filtered
  )

  # :empty | :error | :permission_denied | :stale | nil
  # nil means "normal flow": render records or the legacy empty branches
  attr(:data_state, :atom, default: nil)
  attr(:first_page_path, :string, default: nil)

  def records_list(assigns) do
    ~H"""
    <Components.collection_header
      :if={@heading || is_nil(@data_state)}
      title={@heading}
      count={if(is_nil(@data_state), do: Map.get(@page_meta, :total_count, 0))}
      count_label={if(is_nil(@data_state), do: result_count_label(@page_meta))}
      count_testid="inbound-result-count"
      data-testid="inbound-collection-header"
    />
    <div class="min-w-0 overflow-hidden rounded-box border border-base-300 bg-base-200">
      <%= cond do %>
        <% @data_state == :error -> %>
          <Components.data_state
            kind={:error}
            title="Record data unavailable"
            body="Record data could not be loaded. Refresh the page or adjust the filters, then try again."
          />
        <% @data_state == :package_unavailable -> %>
          <div data-testid="inbound-package-unavailable">
            <Components.data_state
              kind={:error}
              title="Inbound support is unavailable"
              body="The optional inbound package is not available in this deployment. Inbound records and counts are not being shown."
            />
          </div>
        <% @data_state == :read_unavailable -> %>
          <div data-testid="inbound-read-unavailable">
            <Components.data_state
              kind={:error}
              title="Inbound records unavailable"
              body="Inbound records could not be loaded. Refresh the page or adjust the filters, then try again."
            />
          </div>
        <% @data_state == :permission_denied -> %>
          <Components.data_state
            kind={:permission_denied}
            title="Access restricted"
            body="You do not have access to this account's inbound routing. Ask an administrator to grant access."
          />
        <% @data_state == :stale -> %>
          <Components.data_state
            kind={:stale}
            title="This view may be out of date."
            body="Refresh the view to check for updates."
          />
        <% @data_state == :empty or (@data_state == nil and @records == []) -> %>
          <%!-- :no_tenant retains its original selector copy; :truly_empty and :filtered use UI-SPEC "No messages" copy --%>
          <%= if @empty_state == :no_tenant do %>
            <Components.data_state
              kind={:empty}
              title="Choose an Account"
              body="Select an Account to see scoped operator data."
            />
            <div data-testid="inbound-empty-no-tenant" style="display:none" />
          <% else %>
            <Components.data_state
              kind={:empty}
              title={
                if @empty_state == :out_of_range, do: "No messages on this page", else: "No messages"
              }
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
              <%= if @empty_state == :out_of_range and is_binary(@first_page_path) do %>
                <div data-testid="inbound-empty-out-of-range" style="display:none" />
                <.link
                  patch={@first_page_path}
                  data-testid="inbound-page-reset"
                  class="btn btn-ghost min-h-11 mx-auto block"
                >
                  Go to page 1
                </.link>
              <% else %>
                <div data-testid="inbound-empty-truly" style="display:none" />
              <% end %>
            <% end %>
          <% end %>
        <% true -> %>
          <%!-- Desktop table (>=768px) --%>
          <div
            class="hidden md:block overflow-x-auto"
            data-testid="inbound-records-table"
            role="region"
            aria-label="Inbound records"
            tabindex="0"
          >
            <table class={[
              "mg-inbound-records-table table w-full table-fixed",
              @show_account? && "mg-inbound-records-table-all-accounts"
            ]}>
              <thead>
                <tr>
                  <th scope="col" class="text-label font-bold text-secondary">
                    Recipient / Subject
                  </th>
                  <th scope="col" class="text-label font-bold text-secondary w-40">
                    Outcome
                  </th>
                  <th scope="col" class="text-label font-bold text-secondary w-52">Mailbox</th>
                  <th
                    :if={@show_account?}
                    scope="col"
                    class="text-label font-bold text-secondary w-40"
                  >
                    Account
                  </th>
                  <th scope="col" class="text-label font-bold text-secondary w-32">
                    Provider
                  </th>
                  <th scope="col" class="text-label font-bold text-secondary w-52">
                    Received
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={record <- @records}
                  data-testid="inbound-record-row"
                  data-selected={if selected?(@selected_record, record), do: "true", else: "false"}
                  class={[
                    "min-h-11 transition-colors",
                    row_classes(@selected_record, record)
                  ]}
                >
                  <td class="min-w-0 text-body text-base-content">
                    <button
                      type="button"
                      id={"inbound-record-open-desktop-#{record.id}"}
                      data-testid="inbound-record-open"
                      phx-click="select_inbound"
                      phx-value-id={record.id}
                      phx-value-surface="desktop"
                      aria-current={if selected?(@selected_record, record), do: "true", else: "false"}
                      aria-label={"Open inbound message #{record.id}"}
                      title={Map.get(record, :envelope_recipient) || "Unavailable"}
                      class="mg-focus-ring flex min-h-11 w-full min-w-0 flex-col items-start justify-center rounded-xs text-left"
                    >
                      <span class="min-w-0 w-full truncate">
                        {Map.get(record, :envelope_recipient) || "Unavailable"}
                      </span>
                      <span
                        class="min-w-0 w-full truncate text-label text-secondary"
                        title={subject(record)}
                      >
                        {subject(record)}
                      </span>
                    </button>
                  </td>
                  <td class="text-body text-base-content">
                    <span data-testid={"inbound-outcome-#{record_outcome(record)}"}>
                      <Components.outcome_badge
                        id={"inbound-outcome-table-#{record.id}"}
                        status={Components.normalize_inbound_outcome(record_outcome(record))}
                        context={:inbound}
                      />
                    </span>
                  </td>
                  <td class="min-w-0 text-body text-base-content">
                    <Components.mailbox_identity
                      record={record}
                      id={"inbound-mailbox-table-#{record.id}"}
                    />
                  </td>
                  <td :if={@show_account?} class="min-w-0 text-body text-base-content">
                    <span
                      class="min-w-0 truncate block"
                      title={Accounts.title(Map.get(record, :tenant_id, ""), @account_labels)}
                    >
                      {Accounts.label(Map.get(record, :tenant_id, ""), @account_labels)}
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
                  <td class="mg-inbound-received text-label text-secondary">
                    <Components.timestamp
                      at={Map.get(record, :received_at)}
                      class="block whitespace-normal [overflow-wrap:anywhere]"
                    />
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
                <div class={[
                  "flex min-h-11 w-full flex-col gap-sm px-md py-md transition-colors",
                  row_classes(@selected_record, record)
                ]}>
                  <button
                    id={"inbound-record-open-mobile-#{record.id}"}
                    data-testid="inbound-record-row"
                    data-selected={if selected?(@selected_record, record), do: "true", else: "false"}
                    type="button"
                    phx-click="select_inbound"
                    phx-value-id={record.id}
                    phx-value-surface="mobile"
                    aria-current={if selected?(@selected_record, record), do: "true", else: "false"}
                    class="mg-focus-ring-inset flex min-h-11 w-full flex-col gap-sm text-left"
                  >
                    <%!-- Envelope recipient --%>
                    <div class="min-w-0">
                      <span class="text-label font-bold text-secondary">Recipient</span>
                      <p
                        class="min-w-0 truncate text-body text-base-content"
                        title={Map.get(record, :envelope_recipient) || "Unavailable"}
                      >
                        {Map.get(record, :envelope_recipient) || "Unavailable"}
                      </p>
                    </div>

                    <p class="min-w-0 break-words text-label text-secondary" title={subject(record)}>
                      {subject(record)}
                    </p>
                  </button>
                  <%!-- Outcome --%>
                  <div>
                    <span data-testid={"inbound-outcome-#{record_outcome(record)}"}>
                      <Components.outcome_badge
                        id={"inbound-outcome-card-#{record.id}"}
                        status={Components.normalize_inbound_outcome(record_outcome(record))}
                        context={:inbound}
                      />
                    </span>
                  </div>

                  <%!-- Record ID with truncate+title --%>
                  <div class="min-w-0">
                    <span class="text-label font-bold text-secondary">ID</span>
                    <p
                      class="mono min-w-0 truncate text-label text-secondary"
                      title={Map.get(record, :id, "")}
                    >
                      {Map.get(record, :id, "")}
                    </p>
                  </div>

                  <div class="flex flex-wrap items-start gap-md text-label text-secondary">
                    <%!-- Account --%>
                    <div :if={@show_account?} class="min-w-0">
                      <span class="font-bold">Account</span>
                      <p
                        class="min-w-0 truncate"
                        title={Accounts.title(Map.get(record, :tenant_id, ""), @account_labels)}
                      >
                        {Accounts.label(Map.get(record, :tenant_id, ""), @account_labels)}
                      </p>
                    </div>

                    <%!-- Provider --%>
                    <div>
                      <span class="font-bold">Provider</span>
                      <p
                        class="mono min-w-0 truncate"
                        title={String.upcase(Map.get(record, :provider, nil) || "unknown")}
                      >
                        {String.upcase(Map.get(record, :provider, nil) || "unknown")}
                      </p>
                    </div>
                  </div>

                  <%!-- Metadata controls stay separate from opening the message. --%>
                  <div class="flex flex-wrap items-start gap-md text-label text-secondary">
                    <div class="min-w-0">
                      <span class="font-bold">Mailbox</span>
                      <p>
                        <Components.mailbox_identity
                          record={record}
                          id={"inbound-mailbox-card-#{record.id}"}
                        />
                      </p>
                    </div>
                    <div>
                      <span class="font-bold">Received</span>
                      <p class="mg-inbound-received">
                        <Components.timestamp
                          at={Map.get(record, :received_at)}
                          class="block whitespace-normal [overflow-wrap:anywhere]"
                        />
                      </p>
                    </div>
                  </div>
                </div>
              </li>
            </ul>
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
      data-testid="inbound-pagination"
      aria-label="Inbound records pagination"
      class="flex items-center justify-between gap-sm border-t border-base-300 px-md py-sm text-body"
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

  defp result_count_label(%{total_count: 1}), do: "1 message"

  defp result_count_label(%{total_count: count}) when is_integer(count),
    do: "#{count} messages"

  defp result_count_label(_page_meta), do: "0 messages"

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_selected_record, _record), do: false

  defp empty_body(:no_tenant),
    do: "Select an Account to see scoped operator data."

  defp empty_body(:truly_empty),
    do: "No messages have been received yet."

  defp empty_body(:filtered), do: "No messages match the current filters."

  defp empty_body(:out_of_range),
    do: "This page is outside the current results. Return to page 1 to see matching records."

  defp row_classes(%{id: id}, %{id: id}),
    do: "border-l-4 border-primary bg-base-100 text-base-content"

  defp row_classes(_selected_record, _record),
    do: "border-l-4 border-transparent bg-base-200 text-base-content hover:bg-base-100"

  # The list projection (Records.list_records/2) does not carry an outcome, so it
  # is read defensively — an absent key renders the neutral outline badge.
  defp record_outcome(record), do: Map.get(record, :outcome)

  defp subject(record) do
    case Map.get(record, :subject) do
      nil -> "Subject not recorded"
      "" -> "(No subject)"
      value -> value
    end
  end
end
