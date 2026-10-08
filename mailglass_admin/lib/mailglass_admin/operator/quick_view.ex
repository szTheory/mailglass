defmodule MailglassAdmin.Operator.QuickView do
  @moduledoc """
  In-context "Quick view" of one delivery — the peek layer of the operator
  inspection flow ("what happened, at a glance").

  A URL-driven overlay (`?delivery_id=` with no `full`): a right slide-over pane on
  desktop, a bottom sheet on mobile (positioning in the shared app stylesheet
  via `.mg-detail-panel`). Renders entirely from the list-row projection
  already loaded in `@deliveries`, so flipping records with the `‹ ›` controls (and,
  in Stage C, the keyboard) fires no new queries. The heavy evidence — full event
  timeline, suppression state, replay history — lives one step deeper in Full detail
  (`&full=1`), reached via "Open full detail".

  Cloned from `MailglassAdmin.Operator.ReplayModal`'s zero-hook overlay skeleton
  (scrim + `role="dialog"` panel, `phx-window-keydown` Escape, `JS.hide` exit,
  focus-trap sentinels), differing in that it is URL-driven and edge-anchored.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Accounts
  alias Phoenix.LiveView.JS

  attr(:delivery, :map, default: nil)
  attr(:detail_error, :atom, default: nil)
  attr(:account_labels, :map, default: %{})
  attr(:full_path, :string, required: true)
  attr(:close_path, :string, required: true)
  attr(:previous_path, :string, default: nil)
  attr(:next_path, :string, default: nil)
  attr(:position, :map, default: nil)
  attr(:keyboard?, :boolean, default: true)
  attr(:focus_return_id, :string, default: nil)

  def quick_view(assigns) do
    ~H"""
    <div id="operator-quick-view-overlay" class="mg-detail-overlay">
      <.link
        patch={@close_path}
        aria-hidden="true"
        tabindex="-1"
        data-testid="operator-quick-view-scrim"
        class="motion-tab-swap mg-layer-overlay-scrim mg-overlay-scrim mg-overscroll-contain fixed inset-0 block"
      ></.link>
      <div
        id="operator-quick-view"
        data-testid="operator-quick-view"
        role="dialog"
        aria-modal="true"
        aria-labelledby="operator-quick-view-title"
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
          <h2 id="operator-quick-view-title" class="text-label font-bold uppercase text-secondary">
            Delivery quick view
          </h2>
          <div class="flex items-center gap-xs">
            <.nav_button dir="prev" path={@previous_path} label="Previous delivery">‹</.nav_button>
            <span :if={@position} aria-live="polite" class="mono px-xs text-label text-secondary">
              {@position.index} of {@position.total}
            </span>
            <.nav_button dir="next" path={@next_path} label="Next delivery">›</.nav_button>
            <.link
              id="operator-quick-view-close"
              patch={@close_path}
              data-testid="operator-detail-back"
              aria-label="Close quick view"
              class="mg-focus-ring btn btn-ghost min-h-11 min-w-11 ml-xs"
            >
              <Components.icon name="hero-x-circle" class="h-5 w-5" />
            </.link>
          </div>
        </div>

        <%= cond do %>
          <% @detail_error -> %>
            <div data-testid="operator-quick-view-error" class="mt-md flex items-start gap-sm">
              <Components.icon
                name="hero-exclamation-circle"
                class="mt-xs h-5 w-5 shrink-0 text-error"
              />
              <p class="text-body text-base-content">
                {detail_error_copy(@detail_error)}
              </p>
              <button
                :if={@detail_error == :unavailable}
                type="button"
                phx-click="retry_details"
                class="btn btn-ghost min-h-11"
              >
                Retry details
              </button>
            </div>
          <% @delivery -> %>
            <div class="mt-md space-y-md">
              <div class="flex flex-wrap items-center gap-sm">
                <h3 class="text-heading font-bold text-base-content">
                  {Components.mask_recipient(@delivery.recipient)}
                </h3>
                <Components.status_badge status={Components.delivery_display_status(@delivery)} />
              </div>

              <p class="text-body text-secondary">
                Latest recorded event:
                <span class="text-base-content">{event_label(@delivery.last_event_type)}</span>
                · <Components.timestamp at={@delivery.last_event_at} />
              </p>

              <dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">
                <div>
                  <dt class="text-label font-bold uppercase">Account</dt>
                  <dd
                    class="mt-xs text-base-content"
                    title={Accounts.title(@delivery.tenant_id, @account_labels)}
                  >
                    {Accounts.label(@delivery.tenant_id, @account_labels)}
                  </dd>
                </div>
                <div>
                  <dt class="text-label font-bold uppercase">Provider</dt>
                  <dd class="mt-xs text-base-content">
                    {provider_label(@delivery.provider)}
                  </dd>
                </div>
                <div class="sm:col-span-2">
                  <dt class="text-label font-bold uppercase">Delivery ID</dt>
                  <dd class="mono mt-xs break-all text-base-content" title={@delivery.id}>
                    {@delivery.id}
                  </dd>
                </div>
              </dl>
            </div>
        <% end %>

        <div :if={@delivery} class="mt-lg border-t border-base-300 pt-md">
          <.link
            patch={@full_path}
            data-testid="operator-quick-view-full"
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
    <span
      aria-disabled="true"
      aria-label={@label}
      class="btn btn-ghost btn-sm opacity-40"
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp nav_button(assigns) do
    ~H"""
    <.link
      patch={@path}
      data-testid={"operator-quick-view-#{@dir}"}
      aria-label={@label}
      class="mg-focus-ring btn btn-ghost btn-sm"
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp event_label(nil), do: "Unavailable"

  defp event_label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp provider_label(nil), do: "Unavailable"
  defp provider_label(value), do: String.upcase(value)

  defp detail_error_copy(:invalid_id),
    do: "This delivery link is invalid. Return to deliveries and open a listed record."

  defp detail_error_copy(:not_found),
    do:
      "This delivery is not available in the selected Account. Return to deliveries to continue."

  defp detail_error_copy(:unavailable),
    do:
      "Delivery details are temporarily unavailable. Retry the scoped read or return to deliveries."

  defp detail_error_copy(_),
    do: "Delivery details are unavailable. Return to deliveries to continue."
end
