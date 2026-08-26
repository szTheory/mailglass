defmodule Mailglass.Publish.MaintainingReleaseGateContractTest do
  use ExUnit.Case, async: true

  @maintaining_path Path.expand("../../../MAINTAINING.md", __DIR__)

  test "current protected release and recovery path records exact authority and fail-closed evidence" do
    maintaining = File.read!(@maintaining_path)
    current = section!(maintaining, "Current protected release and recovery path", "Historical release procedures")

    assert current =~ "mix mailglass.repo.hygiene --check --format json"
    assert current =~ "protected exact-candidate dispatch"
    assert current =~ "nonempty candidate digest"
    assert current =~ "repository-admin"
    assert current =~ "scripts/ci_monitor.cjs"
    assert current =~ "exact run/SHA"
    assert current =~ "scheduled-control evidence"
    assert current =~ "immutable post-publish target validation"

    assert current =~ ~r/ordinary push, schedule, and blank-digest dispatch are proposal-only/i
    assert current =~ ~r/cannot merge, tag,\s+or publish/

    assert current =~ "cannot-check"
    assert current =~ "non-success"
    assert current =~ "malformed"
    assert current =~ "stale"
    assert current =~ "wrong-SHA"
    assert current =~ "mismatched artifact/summary"

    refute current =~ "auto-merges"
    refute current =~ "hands-free after CI is green"
  end

  test "historical release procedures retain provenance without becoming current guidance" do
    maintaining = File.read!(@maintaining_path)
    historical = section_from!(maintaining, "Historical release procedures")

    assert historical =~ "Phase 38"
    assert historical =~ "Phase 73"
    assert historical =~ "~> 1.3"
    assert historical =~ "~> 1.0"
    assert historical =~ "non-current"

    refute section!(maintaining, "Current protected release and recovery path", "Historical release procedures") =~
             "~> 1.3"
  end

  defp section!(document, start_heading, end_heading) do
    start_marker = "## #{start_heading}"
    end_marker = "## #{end_heading}"

    [_before, from_start] = String.split(document, start_marker, parts: 2)
    [section, _after] = String.split(from_start, end_marker, parts: 2)
    section
  end

  defp section_from!(document, heading) do
    [_before, section] = String.split(document, "## #{heading}", parts: 2)
    section
  end
end
