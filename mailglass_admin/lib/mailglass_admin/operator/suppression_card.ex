defmodule MailglassAdmin.Operator.SuppressionCard do
  @moduledoc """
  Suppression visibility card with reversibility copy.
  """

  use Phoenix.Component

  attr :suppression_state, :map, default: nil

  def suppression_card(assigns) do
    ~H"""
    <article data-testid="operator-suppression-card" class="card rounded-box border border-base-300 bg-base-200 p-6">
      <div class="mb-4 flex items-center justify-between gap-sm">
        <h3 class="text-body font-bold text-base-content">Suppression state</h3>
        <span class="badge badge-outline">
          {headline(@suppression_state)}
        </span>
      </div>

      <%= if @suppression_state do %>
        <div class="space-y-3 text-body">
          <div class="grid gap-sm sm:grid-cols-2">
            <div>
              <p class="text-label font-bold uppercase tracking-[0.08em] text-secondary">Scope</p>
              <p class="mt-1 text-base-content">{label(Map.get(@suppression_state, :scope))}</p>
            </div>
            <div>
              <p class="text-label font-bold uppercase tracking-[0.08em] text-secondary">Reason</p>
              <p class="mt-1 text-base-content">{label(Map.get(@suppression_state, :reason))}</p>
            </div>
            <div :if={Map.get(@suppression_state, :stream)}>
              <p class="text-label font-bold uppercase tracking-[0.08em] text-secondary">Stream</p>
              <p class="mt-1 text-base-content">{label(Map.get(@suppression_state, :stream))}</p>
            </div>
            <div>
              <p class="text-label font-bold uppercase tracking-[0.08em] text-secondary">Source</p>
              <p class="mt-1 text-base-content">{Map.get(@suppression_state, :source, "Unknown")}</p>
            </div>
          </div>
          <p class="text-secondary">{body_copy(@suppression_state)}</p>
        </div>
      <% else %>
        <p class="text-body text-secondary">
          No active suppression entry matches this delivery.
        </p>
      <% end %>
    </article>
    """
  end

  defp headline(nil), do: "No suppression"
  defp headline(%{reversibility: :immutable}), do: "Immutable by policy"
  defp headline(%{reversibility: :reversible}), do: "Reversible in a later phase"
  defp headline(_), do: "No suppression"

  defp body_copy(%{reversibility: :immutable}), do: "This suppression is immutable by policy."
  defp body_copy(%{reversibility: :reversible}), do: "This suppression is reversible in a later phase."
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
