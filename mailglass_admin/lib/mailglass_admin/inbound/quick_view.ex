defmodule MailglassAdmin.Inbound.QuickView do
  @moduledoc """
  In-context "Quick view" of one InboundMessage — the peek layer of the inbound
  inspection flow ("what happened, at a glance").

  Sibling of `MailglassAdmin.Operator.QuickView`. A URL-driven overlay
  (`?inbound_id=` with no `full`): a right slide-over on desktop, a bottom sheet on
  mobile. The exact selected Account-scoped record may be outside the current list
  page or filters. The heavy evidence — execution timeline, routing trace, raw
  evidence — lives in Full detail (`&full=1`), reached via "Open full detail".
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Accounts
  alias Phoenix.LiveView.JS

  attr(:record, :map, default: nil)
  attr(:detail_error, :atom, default: nil)
  attr(:outside_results?, :boolean, default: false)
  attr(:account_labels, :map, default: %{})
  attr(:full_path, :string, required: true)
  attr(:close_path, :string, required: true)
  attr(:previous_path, :string, default: nil)
  attr(:next_path, :string, default: nil)
  attr(:position, :map, default: nil)
  attr(:keyboard?, :boolean, default: true)

  def quick_view(assigns) do
    ~H"""
    <div id="inbound-quick-view-overlay" class="mg-detail-overlay">
      <.link
        patch={@close_path}
        aria-hidden="true"
        tabindex="-1"
        data-testid="inbound-quick-view-scrim"
        class="motion-tab-swap mg-layer-overlay-scrim mg-overlay-scrim mg-overscroll-contain fixed inset-0 block"
      ></.link>
      <div
        id="inbound-quick-view"
        data-testid="inbound-quick-view"
        role="dialog"
        aria-modal="true"
        aria-labelledby="inbound-quick-view-title"
        phx-hook="ModalFocusTrap"
        phx-window-keydown={if @keyboard?, do: "detail_key", else: nil}
        class="mg-detail-panel motion-overlay mg-layer-overlay-panel border-l border-base-300 bg-base-100 p-lg shadow-overlay"
        phx-remove={
          JS.hide(
            time: 150,
            transition: {"ease-out duration-150", "opacity-100", "opacity-0 translate-y-1"}
          )
        }
      >
        <span tabindex="0" aria-hidden="true" data-focus-trap="start"></span>

        <div class="flex items-center justify-between gap-sm border-b border-base-300 pb-sm">
          <h2 id="inbound-quick-view-title" class="text-heading font-bold text-base-content">
            Quick view
          </h2>
          <div class="flex items-center gap-xs">
            <.nav_button dir="prev" path={@previous_path} label="Previous inbound record">‹</.nav_button>
            <span :if={@position} aria-live="polite" class="mono px-xs text-label text-secondary">
              {@position.index} of {@position.total}
            </span>
            <.nav_button dir="next" path={@next_path} label="Next inbound record">›</.nav_button>
            <.link
              id="inbound-quick-view-close"
              patch={@close_path}
              data-testid="inbound-detail-back"
              aria-label="Close quick view"
              class="mg-focus-ring btn btn-ghost min-h-11 min-w-11 ml-xs"
            >
              <Components.icon name="hero-x-circle" class="h-5 w-5" />
            </.link>
          </div>
        </div>

        <%= cond do %>
          <% @detail_error -> %>
            <div data-testid="inbound-quick-view-error" class="mt-md flex items-start gap-sm">
              <Components.icon
                name="hero-exclamation-circle"
                class="mt-xs h-5 w-5 shrink-0 text-error"
              />
              <p class="text-body text-base-content">
                {detail_error_copy(@detail_error)}
              </p>
            </div>
          <% @record -> %>
            <div class="mt-md space-y-md">
              <p
                :if={@outside_results?}
                data-testid="inbound-selection-outside-results"
                class="text-label text-secondary"
              >
                This inbound message is outside your current results.
              </p>
              <div class="flex flex-wrap items-center gap-sm">
                <h3 class="text-heading font-bold text-base-content">{subject(@record)}</h3>
                <Components.status_badge status={
                  Components.normalize_inbound_outcome(Map.get(@record, :outcome))
                } />
              </div>

              <p class="text-body text-secondary">
                Received: <Components.timestamp at={Map.get(@record, :received_at)} />
              </p>

              <dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">
                <div>
                  <dt class="text-label font-bold uppercase">Recipient</dt>
                  <dd class="mt-xs truncate text-base-content">
                    {Components.mask_recipient(Map.get(@record, :envelope_recipient))}
                  </dd>
                </div>
                <div>
                  <dt class="text-label font-bold uppercase">Provider</dt>
                  <dd class="mt-xs text-base-content">
                    {String.upcase(Map.get(@record, :provider) || "unknown")}
                  </dd>
                </div>
                <div :if={present?(Map.get(@record, :mailbox))}>
                  <dt class="text-label font-bold uppercase">Mailbox</dt>
                  <dd class="mt-xs text-base-content">{Map.get(@record, :mailbox)}</dd>
                </div>
                <div>
                  <dt class="text-label font-bold uppercase">Account</dt>
                  <dd
                    class="mt-xs text-base-content"
                    title={Accounts.title(Map.get(@record, :tenant_id), @account_labels)}
                  >
                    {Accounts.label(Map.get(@record, :tenant_id), @account_labels)}
                  </dd>
                </div>
                <div class="sm:col-span-2">
                  <dt class="text-label font-bold uppercase">Record ID</dt>
                  <dd class="mono mt-xs truncate text-base-content" title={Map.get(@record, :id)}>
                    {Map.get(@record, :id)}
                  </dd>
                </div>
              </dl>
            </div>
        <% end %>

        <div :if={@record} class="mt-lg border-t border-base-300 pt-md">
          <.link
            patch={@full_path}
            data-testid="inbound-quick-view-full"
            class="mg-focus-ring btn btn-primary min-h-11 px-md"
          >
            Open full detail <span aria-hidden="true" class="ml-xs">→</span>
          </.link>
        </div>

        <span tabindex="0" aria-hidden="true" data-focus-trap="end"></span>
      </div>
    </div>
    """
  end

  attr(:dir, :string, required: true)
  attr(:path, :string, default: nil)
  attr(:label, :string, required: true)
  slot(:inner_block, required: true)

  defp nav_button(%{path: nil} = assigns) do
    ~H"""
    <button
      type="button"
      disabled
      aria-label={@label}
      data-testid={"inbound-quick-view-#{@dir}"}
      class="btn btn-ghost min-h-11 min-w-11 cursor-not-allowed opacity-40"
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp nav_button(assigns) do
    ~H"""
    <.link
      patch={@path}
      data-testid={"inbound-quick-view-#{@dir}"}
      aria-label={@label}
      class="mg-focus-ring btn btn-ghost min-h-11 min-w-11"
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp subject(record) do
    case Map.get(record, :subject) do
      value when is_binary(value) and value != "" -> value
      _ -> "(no subject)"
    end
  end

  defp present?(value), do: value not in [nil, ""]

  defp detail_error_copy(:package_unavailable),
    do: "Inbound support is unavailable. The selected record could not be checked."

  defp detail_error_copy(:read_unavailable),
    do:
      "This record could not be checked because inbound data is temporarily unavailable. Refresh the page or try again shortly."

  defp detail_error_copy(_reason),
    do:
      "This inbound message could not be loaded in the selected Account. Check the record ID and try again."
end
