defmodule MailglassAdmin.Inbound.Overview do
  @moduledoc """
  Read-only summary tier for the inbound operator surface.
  """

  use Phoenix.Component

  attr :summary, :map, required: true

  def overview(assigns) do
    assigns =
      assign(assigns,
        total: summary_count(assigns.summary, :total),
        no_match: outcome_count(assigns.summary, :no_match),
        accepted: outcome_count(assigns.summary, :accept),
        no_match_rate: summary_rate(assigns.summary, :no_match_rate),
        secondary: secondary_counts(assigns.summary)
      )

    ~H"""
    <section
      data-testid="inbound-overview"
      class="rounded-box border border-base-300 bg-base-200 p-4 md:p-5"
    >
      <div class="grid gap-sm sm:grid-cols-2 xl:grid-cols-4">
        <.stat label="InboundMessages" value={@total} />
        <.stat label="No match" value={@no_match} />
        <.stat label="Accepted" value={@accepted} />
        <.stat label="No-match rate" value={"#{@no_match_rate}%"} />
      </div>

      <div :if={@secondary != []} class="mt-4 flex flex-wrap gap-2">
        <span
          :for={{label, count} <- @secondary}
          class="rounded-box border border-base-300 bg-base-100 px-3 py-2 text-label text-secondary"
        >
          <span>{label}</span>
          <span class="mono font-bold text-base-content">{count}</span>
        </span>
      </div>
    </section>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp stat(assigns) do
    ~H"""
    <div class="rounded-box border border-base-300 bg-base-100 p-4">
      <p class="text-label uppercase font-bold text-secondary">{@label}</p>
      <p class="mono mt-2 text-display text-base-content">{@value}</p>
    </div>
    """
  end

  defp secondary_counts(summary) do
    [
      {"Rejected", outcome_count(summary, :reject)},
      {"Bounced", outcome_count(summary, :bounce)},
      {"Failed", outcome_count(summary, :failed)},
      {"Ignored", outcome_count(summary, :ignore)}
    ]
    |> Enum.reject(fn {_label, count} -> count == 0 end)
  end

  defp summary_count(summary, key) do
    summary
    |> value_for(key)
    |> normalize_count()
  end

  defp outcome_count(summary, outcome) do
    outcomes =
      summary
      |> value_for(:outcomes)
      |> case do
        outcomes when is_map(outcomes) -> outcomes
        _ -> %{}
      end

    outcomes
    |> value_for(outcome)
    |> normalize_count()
  end

  defp summary_rate(summary, key) do
    summary
    |> value_for(key)
    |> case do
      value when is_float(value) -> Float.round(value, 1)
      value when is_integer(value) -> Float.round(value * 1.0, 1)
      _ -> 0.0
    end
  end

  defp value_for(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp value_for(_map, _key), do: nil

  defp normalize_count(value) when is_integer(value) and value >= 0, do: value
  defp normalize_count(_value), do: 0
end
