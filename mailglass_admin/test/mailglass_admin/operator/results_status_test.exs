defmodule MailglassAdmin.Operator.ResultsStatusTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Operator.ResultsStatus

  @moduletag :phase176

  defp text(collection, state, count, filters_active?, loaded_at \\ nil) do
    ResultsStatus.text(%{
      collection: collection,
      state: state,
      count: count,
      filters_active?: filters_active?,
      loaded_at: loaded_at
    })
  end

  describe "Phase 176 ResultsStatus.text/1 for Deliveries" do
    test "Phase 176 settled states announce one specific sentence each" do
      assert text(:deliveries, :ready, 24, true) == "24 deliveries match"
      assert text(:deliveries, :ready, 24, false) == "24 deliveries match"
      assert text(:deliveries, :ready, 1, false) == "1 delivery matches"
      assert text(:deliveries, :ready, 0, true) == "No deliveries match the current filters"
      assert text(:deliveries, :ready, 0, false) == "No deliveries in this time window"
      assert text(:deliveries, :error, nil, true) == "Couldn't load deliveries"
    end

    test "Phase 176 stale announces the title with the load time" do
      assert text(:deliveries, :stale, 24, true, ~U[2026-10-28 14:05:09Z]) ==
               "Showing results from 14:05 UTC; refresh failed"

      assert text(:deliveries, :stale, 24, true) ==
               "Showing earlier results; refresh failed"
    end
  end

  describe "Phase 176 ResultsStatus.text/1 for Inbound" do
    test "Phase 176 settled states announce one specific sentence each" do
      assert text(:inbound, :ready, 24, true) == "24 messages match"
      assert text(:inbound, :ready, 1, false) == "1 message matches"
      assert text(:inbound, :ready, 0, true) == "No messages match the current filters"
      assert text(:inbound, :ready, 0, false) == "No messages have been received yet"
      assert text(:inbound, :error, nil, false) == "Couldn't load inbound messages"

      assert text(:inbound, :stale, 3, true, ~U[2026-10-28 09:01:00Z]) ==
               "Showing results from 09:01 UTC; refresh failed"
    end
  end

  describe "Phase 176 ResultsStatus.stale_title/1" do
    test "Phase 176 stale_title names the load time, or admits none is known" do
      assert ResultsStatus.stale_title(nil) == "Showing earlier results; refresh failed"

      assert ResultsStatus.stale_title(~U[2026-10-28 14:05:09Z]) ==
               "Showing results from 14:05 UTC; refresh failed"
    end
  end
end
