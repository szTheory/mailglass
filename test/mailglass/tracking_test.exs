defmodule Mailglass.TrackingTest do
  use ExUnit.Case, async: true

  alias Mailglass.Tracking
  alias Mailglass.FakeFixtures.TestMailer
  alias Mailglass.FakeFixtures.TrackingMailer

  # Arbitrary module that does NOT use Mailglass.Mailable
  defmodule PlainModule do
  end

  # Test 1: TestMailer (no tracking opts) → all off
  test "Test 1: enabled?/1 returns all-false for TestMailer (no tracking opts)" do
    flags = Tracking.enabled?(mailable: TestMailer)
    assert flags == %{opens: false, clicks: false}
  end

  # Test 2: TrackingMailer (opens: true, clicks: true) → both on
  test "Test 2: enabled?/1 returns opens + clicks true for TrackingMailer" do
    flags = Tracking.enabled?(mailable: TrackingMailer)
    assert flags == %{opens: true, clicks: true}
  end

  # Test 3: plain module without __mailglass_opts__/0 → all off (off-by-default)
  test "Test 3: enabled?/1 returns all-false for non-mailable module" do
    flags = Tracking.enabled?(mailable: PlainModule)
    assert flags == %{opens: false, clicks: false}
  end
end
