defmodule Mailglass.Scripts.SuiteFloorContractTest do
  use ExUnit.Case, async: true

  @moduledoc """
  HARNESS-03's anti-vacuity contract seam (D-13..D-18). Wired into a real CI
  job via the `verify.ci_lane_contract` alias (`mix_task_tests`,
  `.github/workflows/ci.yml`), which globs `test test/scripts/` — no
  `mix.exs` change is needed or permitted for this file to run in the
  required lane.

  Every test below drives `Mailglass.TestSupport.SuiteFloor.violations/3`
  and `Mailglass.TestSupport.SuiteTruthFormatter.signature/1` directly —
  the SAME pure functions the real `ExUnit.after_suite/1` path calls, never
  a re-implementation, so a future edit that weakens either function breaks
  its own negative control here too (the
  `lane_classification_drift_test.exs:155-193` idiom).

  A guard that cannot fail is worse than none — it manufactures confidence.
  Every violation class below is proven to fire (not merely asserted to
  exist) with an injected-breakage fixture, following the same
  sanity-first-then-injected-breakage-then-assert-only-that-fired shape.
  """

  alias Mailglass.TestSupport.SuiteFloor
  alias Mailglass.TestSupport.SandboxOwnership.LeakError
  alias Mailglass.TestSupport.SuiteTruthFormatter

  # A synthetic `ExUnit.after_suite/1`-shaped report. `excluded`/`skipped`
  # default to 0 so `total` directly controls `executed` (`total - excluded -
  # skipped`) unless a test overrides one of them explicitly to probe the
  # skipped-ceiling boundary. `already_shared`/`formatter_violations` default
  # to 0 (the "nothing wrong" state) so a test overriding only the one seam
  # it is exercising can never accidentally drive an unrelated violation.
  defp report(opts) do
    %{
      total: Keyword.fetch!(opts, :total),
      excluded: Keyword.get(opts, :excluded, 0),
      skipped: Keyword.get(opts, :skipped, 0),
      failures: Keyword.get(opts, :failures, 0),
      already_shared: Keyword.get(opts, :already_shared, 0),
      formatter_violations: Keyword.get(opts, :formatter_violations, 0)
    }
  end

  # ---------------------------------------------------------------------------
  # Anti-vacuity guard on the pipeline's own vocabulary
  # ---------------------------------------------------------------------------

  test "anti-vacuity: SuiteFloor.violations/3's violation-class vocabulary is non-empty" do
    classes = SuiteFloor.violation_classes()

    assert MapSet.size(MapSet.new(classes)) > 0,
           "Mailglass.TestSupport.SuiteFloor.violations/3 has no known violation classes — a " <>
             "refactor emptied the pipeline, which would make every negative control below " <>
             "pass trivially."
  end

  test "SuiteFloor's known exclusion-tag allowlist is pinned to exactly the two current " <>
         "sources (D-14)" do
    assert MapSet.new(SuiteFloor.known_exclusion_tags()) ==
             MapSet.new([:requires_workspace, :public_only]),
           "SuiteFloor.known_exclusion_tags/0 drifted from the two documented sources " <>
             "(advisory-matrix.yml's --exclude requires_workspace; test_helper.exs's " <>
             "conditional :public_only) — a legitimate new source must update this guard " <>
             "deliberately, not silently."
  end

  # ---------------------------------------------------------------------------
  # Executed-floor boundary — two points
  # ---------------------------------------------------------------------------

  describe "executed-floor boundary (D-16)" do
    test "executed exactly at the floor produces no floor violation" do
      floor = SuiteFloor.executed_floor("public")
      violations = SuiteFloor.violations(report(total: floor), MapSet.new([]), "public")

      refute Enum.any?(violations, &(&1.name == :executed_floor)),
             "executed == floor must NOT violate — got #{inspect(violations)}"
    end

    test "executed one below the floor produces exactly one violation naming both numbers" do
      floor = SuiteFloor.executed_floor("public")
      violations = SuiteFloor.violations(report(total: floor - 1), MapSet.new([]), "public")

      assert [violation] = Enum.filter(violations, &(&1.name == :executed_floor))
      assert violation.kind == :violation
      assert violation.message =~ Integer.to_string(floor - 1)
      assert violation.message =~ Integer.to_string(floor)
    end
  end

  # ---------------------------------------------------------------------------
  # Skipped-ceiling boundary — two points
  # ---------------------------------------------------------------------------

  describe "skipped-ceiling boundary (D-16)" do
    test "skipped exactly at the ceiling produces no ceiling violation" do
      ceiling = SuiteFloor.skipped_ceiling()
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(
          report(total: floor + ceiling, skipped: ceiling),
          MapSet.new([]),
          "public"
        )

      refute Enum.any?(violations, &(&1.name == :skipped_ceiling)),
             "skipped == ceiling must NOT violate — got #{inspect(violations)}"
    end

    test "skipped one above the ceiling produces exactly one violation" do
      ceiling = SuiteFloor.skipped_ceiling()
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(
          report(total: floor + ceiling + 1, skipped: ceiling + 1),
          MapSet.new([]),
          "public"
        )

      assert [violation] = Enum.filter(violations, &(&1.name == :skipped_ceiling))
      assert violation.kind == :violation
      assert violation.message =~ Integer.to_string(ceiling + 1)
    end
  end

  # ---------------------------------------------------------------------------
  # Nudge-margin boundary — two points. The nudge MUST be a warning, never a
  # violation — a nudge that fails the build would fail on every added test.
  # ---------------------------------------------------------------------------

  describe "nudge-margin boundary (D-16) — advisory only, never a build failure" do
    test "executed exactly forty above the floor produces no violation (nudge or otherwise)" do
      floor = SuiteFloor.executed_floor("public")
      margin = SuiteFloor.nudge_margin()

      violations =
        SuiteFloor.violations(report(total: floor + margin), MapSet.new([]), "public")

      refute Enum.any?(violations, &(&1.name == :executed_nudge)),
             "executed == floor + nudge_margin must NOT nudge yet — got #{inspect(violations)}"

      refute Enum.any?(violations, &(&1.kind == :violation)),
             "no other violation should fire on a synthetic report with 0 excluded/skipped/" <>
               "already_shared/formatter_violations — got #{inspect(violations)}"
    end

    test "executed forty-one above the floor produces the warn-only nudge, and it is a " <>
           "warning, never a violation" do
      floor = SuiteFloor.executed_floor("public")
      margin = SuiteFloor.nudge_margin()

      violations =
        SuiteFloor.violations(report(total: floor + margin + 1), MapSet.new([]), "public")

      assert [nudge] = Enum.filter(violations, &(&1.name == :executed_nudge))
      assert nudge.kind == :warning

      refute Enum.any?(violations, &(&1.kind == :violation)),
             "a nudge that fails the build would fail on every added test — " <>
               "SuiteFloor.violations/3 must report :executed_nudge as kind: :warning, " <>
               "never kind: :violation. Got #{inspect(violations)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Exclusion-tag allowlist, both directions (D-14) — the load-bearing invariant
  # ---------------------------------------------------------------------------

  describe "exclusion-tag allowlist, both directions (D-14)" do
    test "sanity: today's real exclusion sets agree with SuiteFloor on both schema axes" do
      public_floor = SuiteFloor.executed_floor("public")
      mailglass_floor = SuiteFloor.executed_floor("mailglass")

      public_violations =
        SuiteFloor.violations(
          report(total: public_floor),
          MapSet.new([:requires_workspace]),
          "public"
        )

      mailglass_violations =
        SuiteFloor.violations(
          report(total: mailglass_floor),
          MapSet.new([:requires_workspace, :public_only]),
          "mailglass"
        )

      allowlist_names = [:exclusion_allowlist_unknown_tag, :exclusion_allowlist_dead_entry]

      assert Enum.filter(public_violations, &(&1.name in allowlist_names)) == [],
             "public schema's own real exclusion set (--exclude requires_workspace) must " <>
               "not trip the allowlist check — got #{inspect(public_violations)}"

      assert Enum.filter(mailglass_violations, &(&1.name in allowlist_names)) == [],
             "mailglass schema's own real exclusion set (--exclude requires_workspace, plus " <>
               "test_helper.exs's :public_only) must not trip the allowlist check — got " <>
               "#{inspect(mailglass_violations)}"
    end

    test "an effective exclusion set carrying an unknown token produces exactly one " <>
           "violation naming that token" do
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(
          report(total: floor),
          MapSet.new([:requires_workspace, :flaky]),
          "public"
        )

      assert [violation] =
               Enum.filter(violations, &(&1.name == :exclusion_allowlist_unknown_tag))

      assert violation.kind == :violation
      assert violation.message =~ "flaky"
    end

    test "an effective exclusion set missing an allowlisted token produces exactly one " <>
           "violation naming that token" do
      # `expected_exclusion_tags/1` asserts only `:public_only` in the "missing"
      # direction (never `:requires_workspace`, which is applied by an external
      # CLI flag and legitimately absent on narrower lanes — see SuiteFloor's
      # moduledoc). Use the "mailglass" schema, whose expected set is exactly
      # `{:public_only}`, and omit it from the effective set.
      floor = SuiteFloor.executed_floor("mailglass")

      violations =
        SuiteFloor.violations(
          report(total: floor),
          MapSet.new([:requires_workspace]),
          "mailglass"
        )

      assert [violation] = Enum.filter(violations, &(&1.name == :exclusion_allowlist_dead_entry))
      assert violation.kind == :violation
      assert violation.message =~ "public_only"
    end
  end

  # ---------------------------------------------------------------------------
  # The verbatim :already_shared classifier — D-17's highest-value single test
  # ---------------------------------------------------------------------------

  describe "the verbatim :already_shared classifier (D-17's highest-risk vacuity)" do
    test "the verbatim captured nested MatchError term classifies :already_shared, not :other" do
      # Verbatim shape from 143-MECHANISM.md § "The exact failure term" (CI run
      # 30464215272, job 90617762038).
      failure = {:error, %MatchError{term: {:error, {{:badmatch, :already_shared}, []}}}, []}

      assert SuiteTruthFormatter.signature(failure) == :already_shared,
             "a classifier matching {:badmatch, :already_shared} at the TOP LEVEL of the " <>
               "ExUnit failure term would return :other here, because the unlinked " <>
               "Agent.start/1 in ecto_sql wraps the badmatch one level deeper than a naive " <>
               "top-level match expects — a signature guard that can never fire is the exact " <>
               "vacuity this test exists to exclude."
    end

    test "the composed SandboxOwnership.LeakError also classifies :already_shared " <>
           "(the laundering guard)" do
      failure = {:error, %LeakError{caller: SomeModule, mode: {:shared, self()}}, []}

      assert SuiteTruthFormatter.signature(failure) == :already_shared,
             "checkout!/1 replaces the raw badmatch term with this composed error at the " <>
               "confirmed leak sites — counting only the raw shape would make this tally " <>
               "read zero the moment checkout!/1 is adopted, while the leak keeps happening " <>
               "under a name nothing is watching."
    end
  end

  # ---------------------------------------------------------------------------
  # Classifier coverage — the remaining signatures
  # ---------------------------------------------------------------------------

  describe "classifier coverage: the remaining signatures" do
    test "a Postgrex.Error with an unqualified missing relation classifies :undefined_table" do
      error = %Postgrex.Error{
        postgres: %{
          code: :undefined_table,
          message: ~s(relation "mailglass_deliveries" does not exist)
        }
      }

      assert SuiteTruthFormatter.signature({:error, error, []}) == :undefined_table
    end

    test "the same error qualified by a prefix differing from the configured schema " <>
           "classifies :config_schema_drift" do
      configured = Mailglass.Config.schema()
      other_prefix = if configured == "public", do: "mailglass", else: "public"

      error = %Postgrex.Error{
        postgres: %{
          code: :undefined_table,
          message: ~s(relation "#{other_prefix}.mailglass_suppressions" does not exist)
        }
      }

      assert SuiteTruthFormatter.signature({:error, error, []}) == :config_schema_drift
    end

    test "a DBConnection.OwnershipError classifies :sandbox_ownership" do
      error = %DBConnection.OwnershipError{message: "cannot find ownership process"}

      assert SuiteTruthFormatter.signature({:error, error, []}) == :sandbox_ownership
    end

    test "a RuntimeError raised through a Mailglass.TestSupport.CitextProbe stacktrace " <>
           "frame classifies :citext_probe" do
      stacktrace = [
        {Mailglass.TestSupport.CitextProbe, :do_probe, 4,
         [file: ~c"test/support/citext_probe.ex", line: 51]}
      ]

      error = %RuntimeError{
        message: "citext probe exhausted for Mailglass.TestRepo after 5 attempts"
      }

      assert SuiteTruthFormatter.signature({:error, error, stacktrace}) == :citext_probe
    end

    test "an arbitrary RuntimeError classifies :other" do
      failure = {:error, %RuntimeError{message: "boom"}, []}

      assert SuiteTruthFormatter.signature(failure) == :other,
             "an arbitrary RuntimeError with no CitextProbe stacktrace frame must fall to " <>
               ":other, not :citext_probe — a match broad enough to catch this would make " <>
               "the citext_probe classification vacuous."
    end
  end

  # ---------------------------------------------------------------------------
  # Signature-assertion negative control (D-17)
  # ---------------------------------------------------------------------------

  describe "signature-assertion negative control (D-17)" do
    test "a report with a non-zero combined already_shared tally produces exactly one " <>
           "violation naming the signature and the count" do
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(report(total: floor, already_shared: 3), MapSet.new([]), "public")

      assert [violation] = Enum.filter(violations, &(&1.name == :already_shared))
      assert violation.kind == :violation
      assert violation.message =~ "3"
    end

    test "a report with zero already_shared produces no already_shared violation" do
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(report(total: floor, already_shared: 0), MapSet.new([]), "public")

      refute Enum.any?(violations, &(&1.name == :already_shared))
    end

    test "a report with a non-zero formatter_violations count produces exactly one " <>
           "violation naming it" do
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(
          report(total: floor, formatter_violations: 2),
          MapSet.new([]),
          "public"
        )

      assert [violation] = Enum.filter(violations, &(&1.name == :formatter_violations))
      assert violation.kind == :violation
      assert violation.message =~ "2"
    end

    test "a report with :cannot_verify already_shared (formatter unreachable) produces a " <>
           "violation rather than being treated as zero" do
      floor = SuiteFloor.executed_floor("public")

      violations =
        SuiteFloor.violations(
          report(total: floor, already_shared: :cannot_verify),
          MapSet.new([]),
          "public"
        )

      assert [violation] = Enum.filter(violations, &(&1.name == :already_shared))
      assert violation.kind == :violation

      assert violation.message =~ "not found",
             "a check that cannot observe its subject must not report green (silence must " <>
               "not be read as zero) — got #{inspect(violation.message)}"
    end
  end

  # ---------------------------------------------------------------------------
  # mix.exs is untouched — the directory glob auto-collects this file
  # ---------------------------------------------------------------------------

  test "this file adds no mix.exs alias — verify.ci_lane_contract's directory glob " <>
         "auto-collects it" do
    repo_root = Path.expand("../..", __DIR__)
    mix_exs = File.read!(Path.join(repo_root, "mix.exs"))

    assert mix_exs =~ "test test/scripts/ --warnings-as-errors",
           "verify.ci_lane_contract's directory glob (test test/scripts/) must still exist " <>
             "for this file to be auto-collected into the required mix_task_tests lane"
  end
end
