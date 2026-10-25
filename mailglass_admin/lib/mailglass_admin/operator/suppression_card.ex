defmodule MailglassAdmin.Operator.SuppressionCard do
  @moduledoc """
  Read-only view of one current Account-local suppression match.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:suppression_state, :map, default: nil)
  attr(:read_state, :atom, default: :ready)

  def suppression_card(assigns) do
    assigns =
      assign(
        assigns,
        :has_match?,
        is_map(assigns.suppression_state) and map_size(assigns.suppression_state) > 0
      )

    ~H"""
    <Components.card
      padding={:lg}
      data-testid="operator-suppression-card"
      data-group-card="operator-suppression-card"
    >
      <div class="mb-md flex flex-wrap items-center justify-between gap-sm">
        <div class="flex flex-wrap items-center gap-xs">
          <h3 class="text-body font-bold text-base-content">Current suppression</h3>
          <Components.field_help
            id="delivery-suppression-scope"
            label="suppression scope"
            text="This shows one current Mailglass match for this account. Other configured stores and provider restrictions are not checked. Address and domain rules can apply across streams."
          />
        </div>
        <span class="badge badge-outline">{headline(@suppression_state, @read_state)}</span>
      </div>

      <p
        :if={@read_state == :unavailable}
        role="status"
        data-testid="operator-suppression-unavailable"
        class="mb-md text-body text-secondary"
      >
        The current Mailglass suppression read is unavailable. Other Delivery details and recorded Events remain visible.
        <span :if={@has_match?}>
          The match below is the last retrieved record and may be out of date.
        </span>
      </p>

      <%= if @has_match? do %>
        <dl class="grid gap-md sm:grid-cols-2 [&_dd]:break-words">
          <div>
            <dt class="text-label font-bold text-secondary">Address or domain</dt>
            <dd class="mt-xs break-all text-body text-base-content">
              {value(@suppression_state, :address)}
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold text-secondary">Scope</dt>
            <dd class="mt-xs text-body text-base-content">
              {scope_label(Map.get(@suppression_state, :scope))}
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold text-secondary">Reason</dt>
            <dd class="mt-xs text-body text-base-content">{value(@suppression_state, :reason)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold text-secondary">Source</dt>
            <dd class="mt-xs break-words text-body text-base-content">
              {value(@suppression_state, :source)}
            </dd>
          </div>
          <div :if={Map.get(@suppression_state, :scope) == :address_stream}>
            <dt class="text-label font-bold text-secondary">Stream</dt>
            <dd class="mt-xs text-body text-base-content">{value(@suppression_state, :stream)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold text-secondary">Expires at</dt>
            <dd class="mt-xs break-words text-body text-base-content">
              <Components.timestamp
                :if={match?(%DateTime{}, Map.get(@suppression_state, :expires_at))}
                at={@suppression_state.expires_at}
              />
              <span :if={not match?(%DateTime{}, Map.get(@suppression_state, :expires_at))}>
                Unavailable
              </span>
            </dd>
          </div>
          <div class="sm:col-span-2">
            <dt class="text-label font-bold text-secondary">Public removal command</dt>
            <dd class="mt-xs text-body text-secondary">{removal_copy(@suppression_state)}</dd>
          </div>
        </dl>
      <% else %>
        <%= if @read_state == :ready do %>
          <p class="text-body text-secondary" data-testid="operator-suppression-empty">
            No current Mailglass suppression matches this delivery.
          </p>
        <% end %>
      <% end %>

      <button
        type="button"
        phx-click="retry_suppression"
        class="btn btn-ghost mt-md min-h-11"
        data-testid="operator-suppression-refresh"
      >
        {if @read_state == :unavailable, do: "Retry suppression read", else: "Refresh suppression"}
      </button>
    </Components.card>
    """
  end

  defp headline(_state, :unavailable), do: "Unavailable"

  defp headline(state, _read_state) when is_map(state) and map_size(state) > 0,
    do: "Current Mailglass match"

  defp headline(_, _read_state), do: "No current Mailglass match"

  defp value(state, key) do
    case Map.get(state, key) do
      value when is_atom(value) -> label(value)
      value when is_binary(value) and value != "" -> value
      _ -> "Unavailable"
    end
  end

  defp scope_label(:address), do: "Address · Account-local"
  defp scope_label(:domain), do: "Domain · Account-local"
  defp scope_label(:address_stream), do: "Address + stream · Account-local"
  defp scope_label(_), do: "Unavailable"

  defp removal_copy(%{removal_policy: :blocked, reason: reason}) do
    "The public Mailglass removal command blocks #{label(reason)} records."
  end

  defp removal_copy(%{removal_policy: :supported, reason: reason}) do
    "The public Mailglass removal command permits #{label(reason)} records."
  end

  defp removal_copy(_), do: "Unavailable"

  defp label(nil), do: "Unavailable"

  defp label(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
