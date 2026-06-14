defmodule MailglassAdmin.RatchetBaselineTest do
  @moduledoc """
  Fail-closed score-baseline assertion (RATCHET-01).

  Phase 95: establishes and validates shape/range/coverage of the 36-cell
  score baseline (3 surfaces × 6 pillars × 2 themes).

  Phase 103 adds: load prior baseline, assert no cell regresses (only-forward).
  The `compare_baselines/2` private function below is the Phase 103 hook point —
  it exists in Phase 95 but is never called until Phase 103 enables it.

  If this test fails with "missing cell", the scoring step was incomplete. Run the
  LLM scoring step (D-07 procedure) to fill all 36 surface × pillar × theme cells
  in `mailglass_admin/docs/ui-baseline-scores.json`.

  If it fails with "score out of range", the LLM scored outside 1–4. All scores
  must be integers in 1..4 (1 = non-conformant, 4 = excellent).
  """

  use ExUnit.Case, async: true

  # Two levels up from test/mailglass_admin/ → test/ → mailglass_admin/ → docs/
  # docs/ is outside priv/, so use __DIR__ relative path (not Application.app_dir).
  @scores_path Path.join([__DIR__, "..", "..", "docs", "ui-baseline-scores.json"])

  @surfaces ["deliveries", "inbound", "preview"]
  @pillars ["Spacing", "Radius", "Color", "Type", "Elevation", "Motion+A11y"]
  @themes ["light", "dark"]
  @valid_scores 1..4

  setup_all do
    assert File.exists?(@scores_path),
           "ui-baseline-scores.json not found at #{@scores_path} — " <>
             "run the LLM scoring step (D-07) first to populate " <>
             "mailglass_admin/docs/ui-baseline-scores.json"

    # Phase 103 hook: reference compare_baselines/2 so --warnings-as-errors passes
    # in Phase 95. Phase 103 replaces this line with the real call site that loads
    # the prior committed baseline and asserts meet-or-beat regression.
    if false, do: compare_baselines(%{}, %{})

    {:ok, baseline: Jason.decode!(File.read!(@scores_path))}
  end

  test "schema_version is present and supported", %{baseline: b} do
    assert b["schema_version"] == 1,
           "Expected schema_version 1, got #{inspect(b["schema_version"])}. " <>
             "If upgrading the JSON format, bump schema_version and update this assertion."
  end

  test "all 36 graded cells are present (3 surfaces × 6 pillars × 2 themes)", %{baseline: b} do
    missing =
      for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
        score = get_in(b, ["surfaces", surface, pillar, theme])
        if score == nil, do: "#{surface}.#{pillar}.#{theme}", else: nil
      end
      |> Enum.reject(&is_nil/1)

    assert missing == [],
           "Missing cells (#{length(missing)}) in ui-baseline-scores.json:\n" <>
             Enum.join(missing, "\n") <>
             "\nRun the LLM scoring step (D-07) to fill all 36 cells."
  end

  test "all 36 scores are in the valid range 1-4", %{baseline: b} do
    out_of_range =
      for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
        score = get_in(b, ["surfaces", surface, pillar, theme])

        if score not in @valid_scores,
          do: "#{surface}.#{pillar}.#{theme}: #{inspect(score)}",
          else: nil
      end
      |> Enum.reject(&is_nil/1)

    assert out_of_range == [],
           "Scores out of range 1-4 (#{length(out_of_range)}) in ui-baseline-scores.json:\n" <>
             Enum.join(out_of_range, "\n") <>
             "\nAll scores must be integers 1–4 " <>
             "(1=non-conformant, 2=significant-gaps, 3=mostly-conformant, 4=excellent)."
  end

  # Phase 103 hook point — called by the closeout re-run assertion.
  # In Phase 95 this function exists but is never called.
  # Phase 103 only ADDS the call site: compare_baselines(prior_baseline, current_baseline).
  # It does NOT rewrite this function.
  defp compare_baselines(prior, current) do
    regressions =
      for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
        prior_score = get_in(prior, ["surfaces", surface, pillar, theme]) || 0
        current_score = get_in(current, ["surfaces", surface, pillar, theme]) || 0

        if current_score < prior_score,
          do:
            "#{surface}.#{pillar}.#{theme}: #{prior_score} → #{current_score} (REGRESSION)",
          else: nil
      end
      |> Enum.reject(&is_nil/1)

    assert regressions == [],
           "Score regressions (#{length(regressions)}) — only-forward ratchet violated:\n" <>
             Enum.join(regressions, "\n") <>
             "\nEach cell must meet or beat the prior committed baseline."
  end
end
