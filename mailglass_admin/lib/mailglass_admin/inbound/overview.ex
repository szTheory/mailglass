defmodule MailglassAdmin.Inbound.Overview do
  @moduledoc """
  Read-only summary tier for the inbound operator surface.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

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
    <section data-testid="inbound-overview" class="grid gap-md">
      <div class="grid gap-sm sm:grid-cols-2 xl:grid-cols-4">
        <Components.stat_card
          label="InboundMessages"
          value={@total}
          severity={:info}
          severity_label="Tracked"
          data-testid="inbound-overview-total"
        />
        <Components.stat_card
          label="No match"
          value={@no_match}
          severity={attention_severity(@no_match)}
          severity_label={attention_label(@no_match)}
          data-testid="inbound-overview-no-match"
        />
        <Components.stat_card
          label="Accepted"
          value={@accepted}
          severity={accepted_severity(@accepted)}
          severity_label={accepted_label(@accepted)}
          data-testid="inbound-overview-accepted"
        />
        <Components.stat_card
          label="No-match rate"
          value={"#{@no_match_rate}%"}
          severity={rate_severity(@no_match_rate)}
          severity_label={rate_label(@no_match_rate)}
          data-testid="inbound-overview-no-match-rate"
        />
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

  defp attention_severity(count) when is_integer(count) and count > 0, do: :warning
  defp attention_severity(_count), do: :success

  defp attention_label(count) when is_integer(count) and count > 0, do: "Needs attention"
  defp attention_label(_count), do: "All clear"

  defp accepted_severity(count) when is_integer(count) and count > 0, do: :success
  defp accepted_severity(_count), do: :neutral

  defp accepted_label(count) when is_integer(count) and count > 0, do: "Healthy"
  defp accepted_label(_count), do: "No accepted mail yet"

  defp rate_severity(rate) when is_number(rate) and rate > 0, do: :warning
  defp rate_severity(_rate), do: :success

  defp rate_label(rate) when is_number(rate) and rate > 0, do: "Needs attention"
  defp rate_label(_rate), do: "All clear"
end
