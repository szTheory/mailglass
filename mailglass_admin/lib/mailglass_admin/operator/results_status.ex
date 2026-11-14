defmodule MailglassAdmin.Operator.ResultsStatus do
  @moduledoc false

  # Settled-state announcement text for the persistent `role="status"` region of
  # each filterable collection. The text depends only on how a read settled, never
  # on a draft or a keystroke, so the region announces once per settled result.

  @type collection :: :deliveries | :inbound
  @type state :: :ready | :error | :stale

  @spec text(%{
          required(:collection) => collection(),
          required(:state) => state(),
          required(:count) => non_neg_integer() | nil,
          required(:filters_active?) => boolean(),
          optional(:loaded_at) => DateTime.t() | nil
        }) :: String.t()
  def text(%{state: :stale} = status), do: stale_title(Map.get(status, :loaded_at))

  def text(%{collection: :deliveries, state: :error}), do: "Couldn't load deliveries"
  def text(%{collection: :inbound, state: :error}), do: "Couldn't load inbound messages"

  def text(%{collection: collection, state: :ready, count: count})
      when is_integer(count) and count > 0 do
    {one, many} = nouns(collection)

    if count == 1, do: "1 #{one} matches", else: "#{count} #{many} match"
  end

  def text(%{collection: collection, state: :ready, filters_active?: true}),
    do: "No #{elem(nouns(collection), 1)} match the current filters"

  def text(%{collection: :deliveries, state: :ready}), do: "No deliveries in this time window"
  def text(%{collection: :inbound, state: :ready}), do: "No messages have been received yet"

  @spec stale_title(DateTime.t() | nil) :: String.t()
  def stale_title(%DateTime{} = loaded_at),
    do: "Showing results from #{Calendar.strftime(loaded_at, "%H:%M")} UTC; refresh failed"

  def stale_title(_loaded_at), do: "Showing earlier results; refresh failed"

  defp nouns(:deliveries), do: {"delivery", "deliveries"}
  defp nouns(:inbound), do: {"message", "messages"}
end
