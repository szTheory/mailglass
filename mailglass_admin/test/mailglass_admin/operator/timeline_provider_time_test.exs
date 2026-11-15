defmodule MailglassAdmin.Operator.TimelineProviderTimeTest do
  @moduledoc """
  The provider's own time of an event (D-09, BRADM-02): a value that parses as an ISO 8601
  datetime renders through `Components.timestamp/1` and so always shows its zone. A value
  that does not parse is shown as the provider's raw text, labelled as such, and never as
  a bare time. Rendering is HEEx-escaped, so a hostile value stays text (T-182-07).
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Operator.Timeline

  @at ~U[2026-11-15 14:05:09.123456Z]

  defp event(provider_occurred_at) do
    %{
      id: "event-provider-time",
      type: :delivered,
      reject_reason: nil,
      occurred_at: @at,
      metadata: %{},
      provider_occurred_at: provider_occurred_at
    }
  end

  defp doc(provider_occurred_at) do
    (&Timeline.timeline/1)
    |> render_component(timeline_events: [event(provider_occurred_at)])
    |> Floki.parse_fragment!()
  end

  defp text(nodes) do
    nodes |> Floki.text() |> String.replace(~r/\s+/, " ") |> String.trim()
  end

  test "an ISO 8601 provider time renders as a zoned timestamp after its label" do
    doc = doc("2026-11-15T14:04:58Z")

    [provider_p] =
      doc
      |> Floki.find("[data-testid=operator-timeline-event] p")
      |> Enum.filter(&(text(&1) =~ "Provider time"))

    assert text(provider_p) == "Provider time: Nov 15, 2026, 2:04 PM UTC"
    assert [time] = Floki.find(provider_p, "time")
    assert Floki.attribute(time, "datetime") == ["2026-11-15T14:04:58Z"]
    assert Floki.find(provider_p, "[data-raw-provider-time]") == []
    # A provider time is not a copy control: no nested button.
    assert Floki.find(provider_p, "button") == []
  end

  test "an offset provider time is shown in UTC with its zone" do
    doc = doc("2026-11-15T09:04:58-05:00")

    assert doc |> Floki.find("time[datetime='2026-11-15T14:04:58Z']") |> length() == 1
  end

  test "a provider time that does not parse is shown as the provider's raw value, labelled" do
    for raw <- ["yesterday around 2", "2026-11-15 14:04:58", "1763215498"] do
      doc = doc(raw)
      assert [span] = Floki.find(doc, "[data-raw-provider-time]")
      assert text(span) == "Provider time, as reported: #{raw}"
      # The raw value is never rendered as a <time> of its own.
      refute doc |> Floki.find("time") |> Enum.any?(&(text(&1) =~ raw))
    end
  end

  test "a hostile provider value is escaped text, not markup" do
    hostile = ~s|<img src=x onerror="alert(1)"><script>alert(2)</script>|
    html = render_component(&Timeline.timeline/1, timeline_events: [event(hostile)])

    refute html =~ "<img src=x"
    refute html =~ "<script>alert"
    assert html =~ "&lt;img src=x"
    assert [span] = html |> Floki.parse_fragment!() |> Floki.find("[data-raw-provider-time]")
    assert Floki.find(span, "img") == []
  end

  test "a non-string provider value is shown inspected, never crashing the timeline" do
    assert [span] = Floki.find(doc(%{"epoch" => 1}), "[data-raw-provider-time]")
    assert text(span) =~ "Provider time, as reported:"
  end

  test "an event with no provider time shows no provider line" do
    doc = doc(nil)

    assert Floki.find(doc, "[data-raw-provider-time]") == []

    refute doc
           |> Floki.find("[data-testid=operator-timeline-event] p")
           |> Enum.any?(&(text(&1) =~ "Provider time"))
  end
end
