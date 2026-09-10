defmodule Mailglass.Publish.MaintainingReleaseGateContractTest do
  use ExUnit.Case, async: true

  @maintaining_path Path.expand("../../../MAINTAINING.md", __DIR__)

  test "all non-historical guidance records only protected release authority" do
    maintaining = File.read!(@maintaining_path)
    current = section_before!(maintaining, "Historical release procedures")

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

    assert authority_violations(current) == []
  end

  test "current finalization guidance names only the installed executable and its source" do
    maintaining = File.read!(@maintaining_path)
    current = section_before!(maintaining, "Historical release procedures")

    assert current =~ "/Users/jon/.local/bin/mailglass-finalize-phase 164"
    assert current =~
             "/Users/jon/.local/bin/mailglass-finalize-phase 164 --pre-verification"

    assert current =~ "scripts/mailglass_finalize_phase_loader.mjs"
    assert current =~ "Plan 164-23"
    refute current =~ "/finalize-phase 164"
    refute current =~ ".gsd/extensions/finalize-phase"
  end

  test "unsupported authority variants are rejected anywhere before the historical boundary" do
    maintaining = File.read!(@maintaining_path)

    variants = [
      "Release becomes hands-free after the gates pass.",
      "The bot automatically merges and publishes the release.",
      "This release path has no required reviewers.",
      "Publishing proceeds without human approval.",
      "The current workflow is reviewer-free.",
      "The current workflow is approval-free."
    ]

    Enum.each(variants, fn variant ->
      injected =
        String.replace(
          maintaining,
          "## Bus Factor & Continuity",
          "#{variant}\n\n## Bus Factor & Continuity"
        )

      current = section_before!(injected, "Historical release procedures")

      refute authority_violations(current) == [], "expected to reject: #{variant}"
    end)
  end

  test "historical release procedures retain provenance without becoming current guidance" do
    maintaining = File.read!(@maintaining_path)
    historical = section_from!(maintaining, "Historical release procedures")

    assert historical =~ "Phase 38"
    assert historical =~ "Phase 73"
    assert historical =~ "Historical v0.1/v0.5 bus-factor rationale"
    assert historical =~ "hands-free"
    assert historical =~ "no required reviewers"
    assert historical =~ "~> 1.3"
    assert historical =~ "~> 1.0"
    assert historical =~ "non-current"
    assert historical =~ ~r/superseded\s+project-local `\/finalize-phase 164`/
    assert historical =~ ".gsd/extensions/finalize-phase"

    refute section!(
             maintaining,
             "Current protected release and recovery path",
             "Historical release procedures"
           ) =~
             "~> 1.3"
  end

  test "the historical authority boundary must exist exactly once" do
    assert_raise ArgumentError, ~r/missing or duplicated/, fn ->
      section_before!("no historical boundary", "Historical release procedures")
    end

    duplicated = "## Historical release procedures\nfirst\n## Historical release procedures\nsecond"

    assert_raise ArgumentError, ~r/missing or duplicated/, fn ->
      section_before!(duplicated, "Historical release procedures")
    end
  end

  defp section_before!(document, heading) do
    marker = "## #{heading}"

    case String.split(document, marker) do
      [section, _historical] -> section
      _ -> raise ArgumentError, "historical boundary is missing or duplicated: #{marker}"
    end
  end

  defp authority_violations(document) do
    [
      ~r/\bhands[- ]free\b/i,
      ~r/\bautomatically\s+(?:merges?|publishes?)\b/i,
      ~r/\bauto[- ]?(?:merges?|publishes?)\b/i,
      ~r/\bno required reviewers?\b/i,
      ~r/\bwithout (?:human )?(?:review|approval)\b/i,
      ~r/\breviewer[- ]free\b/i,
      ~r/\bapproval[- ]free\b/i
    ]
    |> Enum.filter(&Regex.match?(&1, document))
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
