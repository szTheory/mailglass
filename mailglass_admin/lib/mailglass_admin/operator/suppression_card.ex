defmodule MailglassAdmin.Operator.SuppressionCard do
  @moduledoc """
  Suppression visibility card with reversibility copy.
  """

  use Phoenix.Component

  import MailglassAdmin.Components, only: [card: 1]

  attr :suppression_state, :map, default: nil

  def suppression_card(assigns) do
    ~H"""
    <.card padding={:lg} data-testid="operator-suppression-card" data-group-card="operator-suppression-card">
      <div class="mb-md flex items-center justify-between gap-sm">
        <h3 class="text-body font-bold text-base-content">Suppression</h3>
        <span class="badge badge-outline">
          {headline(@suppression_state)}
        </span>
      </div>

      <%= if @suppression_state do %>
        <div class="space-y-md text-body">
          <div class="grid gap-sm sm:grid-cols-2">
            <div>
              <p class="text-label uppercase font-bold text-secondary">Scope</p>
              <p class="mt-xs text-base-content">{label(Map.get(@suppression_state, :scope))}</p>
            </div>
            <div>
              <p class="text-label uppercase font-bold text-secondary">Reason</p>
              <p class="mt-xs text-base-content">{label(Map.get(@suppression_state, :reason))}</p>
            </div>
            <div :if={Map.get(@suppression_state, :stream)}>
              <p class="text-label uppercase font-bold text-secondary">Stream</p>
              <p class="mt-xs text-base-content">{label(Map.get(@suppression_state, :stream))}</p>
            </div>
            <div>
              <p class="text-label uppercase font-bold text-secondary">Source</p>
              <p class="mt-xs text-base-content">{Map.get(@suppression_state, :source, "Unknown")}</p>
            </div>
          </div>
          <p class="text-secondary">{body_copy(@suppression_state)}</p>
        </div>
      <% else %>
        <p class="text-body text-secondary">
          No active Suppression for this Delivery.
        </p>
      <% end %>
    </.card>
    """
  end

  defp headline(nil), do: "No suppression"
  defp headline(%{reversibility: :immutable}), do: "Immutable by policy"
  defp headline(%{reversibility: :reversible}), do: "Reversible in a later phase"
  defp headline(_), do: "No suppression"

  defp body_copy(%{reversibility: :immutable}),
    do: "This Suppression is permanent. Future sends to this address will be blocked."

  defp body_copy(%{reversibility: :reversible}),
    do: "This Suppression is reversible. Remove via the suppressions API or contact support."
  defp body_copy(%{reversibility_copy: copy}) when is_binary(copy), do: copy
  defp body_copy(_), do: "No active Suppression for this Delivery."

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
