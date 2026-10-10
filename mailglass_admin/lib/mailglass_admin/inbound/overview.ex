defmodule MailglassAdmin.Inbound.Overview do
  @moduledoc """
  Read-only summary tier for the inbound operator surface.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :summary, :map, required: true
  attr :filters, :map, default: %{}

  def overview(assigns) do
    assigns =
      assign(assigns,
        total: summary_count(assigns.summary, :total),
        no_match_rate: summary_rate(assigns.summary, :no_match_rate),
        outcomes: outcome_counts(assigns.summary),
        list_outcome: list_outcome(assigns.filters)
      )

    ~H"""
    <section data-testid="inbound-overview" class="mt-md border-b border-base-300 pb-md">
      <p
        :if={@list_outcome}
        data-testid="inbound-summary-outcome-scope"
        class="mb-sm text-label text-secondary"
      >
        Counts include all outcomes; list shows {@list_outcome}.
      </p>
      <div class="mg-inbound-summary-counts">
        <Components.stat_card
          label="Messages"
          value={@total}
          compact
          severity={:info}
          severity_label="Tracked"
          data-testid="inbound-overview-total"
        />
        <Components.stat_card
          label="No-match rate"
          value={"#{@no_match_rate}%"}
          compact
          severity={rate_severity(@no_match_rate)}
          severity_label={rate_label(@no_match_rate)}
          data-testid="inbound-overview-no-match-rate"
        />
        <Components.stat_card
          :for={{key, label, count} <- @outcomes}
          label={label}
          value={count}
          compact
          severity={if key == :no_match, do: attention_severity(count), else: :neutral}
          severity_label={if key == :no_match, do: attention_label(count), else: "Tracked"}
          data-testid={"inbound-overview-#{String.replace(Atom.to_string(key), "_", "-")}"}
        />
      </div>
    </section>
    """
  end

  defp outcome_counts(summary) do
    [
      {:no_match, "No match"},
      {:accepted, "Accepted"},
      {:reject, "Rejected"},
      {:bounce, "Bounced"},
      {:failed, "Failed"},
      {:ignore, "Ignored"},
      {:no_change, "No change"}
    ]
    |> Enum.map(fn {key, label} ->
      outcome = if key == :accepted, do: :accept, else: key
      {key, label, outcome_count(summary, outcome)}
    end)
  end

  defp list_outcome(filters) do
    case filters["outcome"] do
      "no_match" -> "No match"
      "accept" -> "Accepted"
      "reject" -> "Rejected"
      "bounce" -> "Bounced"
      "failed" -> "Failed"
      "ignore" -> "Ignored"
      "no_change" -> "No change"
      _ -> nil
    end
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

  defp rate_severity(rate) when is_number(rate) and rate > 0, do: :warning
  defp rate_severity(_rate), do: :success

  defp rate_label(rate) when is_number(rate) and rate > 0, do: "Needs attention"
  defp rate_label(_rate), do: "All clear"
end
