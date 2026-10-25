defmodule MailglassAdmin.Inbound.Overview do
  @moduledoc """
  Read-only summary tier for the inbound operator surface.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:summary, :map, required: true)
  attr(:filters, :map, default: %{})

  def overview(assigns) do
    assigns = assign(assigns, outcomes: outcome_counts(assigns.summary))

    ~H"""
    <section
      :if={all_outcomes?(@filters)}
      data-testid="inbound-overview"
      class="mt-md border-b border-base-300 pb-md"
    >
      <div class="mg-inbound-summary-counts">
        <Components.stat_card
          :for={{key, label, count, help} <- @outcomes}
          id={"inbound-overview-#{String.replace(Atom.to_string(key), "_", "-")}"}
          label={label}
          value={count}
          compact
          data-testid={"inbound-overview-#{String.replace(Atom.to_string(key), "_", "-")}"}
        >
          <:label_help>
            <Components.field_help
              id={"inbound-overview-#{String.replace(Atom.to_string(key), "_", "-")}-help"}
              label={label}
              text={help}
            />
          </:label_help>
        </Components.stat_card>
      </div>
    </section>
    """
  end

  defp outcome_counts(summary) do
    [
      {:accepted, "Accepted", :accept,
       "Messages whose latest fresh run was accepted by a mailbox."},
      {:no_match, "Unrouted", :no_match,
       "No mailbox routing rule matched these messages. Open a message to inspect the routes that were checked."},
      {:failed, "Failed", :failed,
       "Mailbox processing ended in failure. Open a message to inspect the recorded error."}
    ]
    |> Enum.map(fn {key, label, outcome, help} ->
      {key, label, outcome_count(summary, outcome), help}
    end)
  end

  defp all_outcomes?(filters), do: Map.get(filters, "outcome") in [nil, ""]

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

  defp value_for(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp value_for(_map, _key), do: nil

  defp normalize_count(value) when is_integer(value) and value >= 0, do: value
  defp normalize_count(_value), do: 0
end
