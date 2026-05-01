defmodule MailglassAdmin.Operator.SuppressionCard do
  @moduledoc """
  Suppression visibility card with reversibility copy.
  """

  use Phoenix.Component

  attr :suppression_state, :map, default: nil

  def suppression_card(assigns) do
    ~H"""
    <article class="card rounded-box border border-base-300 bg-base-200 p-6">
      <div class="mb-4 flex items-center justify-between gap-3">
        <h3 class="text-base font-bold text-base-content">Suppression state</h3>
        <span class="badge badge-outline">
          {headline(@suppression_state)}
        </span>
      </div>

      <%= if @suppression_state do %>
        <div class="space-y-3 text-sm">
          <div class="grid gap-3 sm:grid-cols-2">
            <div>
              <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">Scope</p>
              <p class="mt-1 text-base-content">{label(@suppression_state.scope)}</p>
            </div>
            <div>
              <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">Reason</p>
              <p class="mt-1 text-base-content">{label(@suppression_state.reason)}</p>
            </div>
            <div :if={@suppression_state.stream}>
              <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">Stream</p>
              <p class="mt-1 text-base-content">{label(@suppression_state.stream)}</p>
            </div>
            <div>
              <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">Source</p>
              <p class="mt-1 text-base-content">{@suppression_state.source}</p>
            </div>
          </div>
          <p class="text-secondary">{@suppression_state.reversibility_copy}</p>
        </div>
      <% else %>
        <p class="text-sm text-secondary">
          No active suppression entry matches this delivery.
        </p>
      <% end %>
    </article>
    """
  end

  defp headline(nil), do: "No suppression"
  defp headline(%{reversibility: :immutable}), do: "Immutable by policy"
  defp headline(%{reversibility: :reversible}), do: "Reversible in a later phase"

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
