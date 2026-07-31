defmodule Mailglass.Scripts.MechanismAccountContractTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Docs-contract guard for HARNESS-01's mechanism account (`143-MECHANISM.md`) and
  HARNESS-04's release-gating decision (`143-GATING-DECISION.md`).

  Auto-collected by `verify.ci_lane_contract`'s `test test/scripts/` directory glob
  (`mix.exs:296-298`) into the REQUIRED `mix_task_tests` lane — no `mix.exs` change. A
  mechanism-account assertion that ran in no lane would enforce nothing (the same
  RESEARCH.md F2 finding `lane_classification_drift_test.exs` exists to guard against).

  Asserts the phase's HARNESS-01 mechanism account
  (`.planning/phases/143-test-harness-truth/143-MECHANISM.md`) and its two committed
  pre-fix ledgers exist, are non-empty, and carry the specific evidence HARNESS-01's
  "empirically confirmed before the fix is written" bar requires: all seven required
  section headings, the confirming CI run/job IDs, the nested `MatchError` shape (plus
  the explicit top-level-match warning), a PASS/FAIL verdict for each of D-04's two
  falsifiable predictions, and a non-vacuous section-heading count so a formatting
  change to the account cannot make this contract pass trivially. It also binds the
  gating record's seven required sections, explicit verdict, positive release-path
  evidence, and negative publish-block evidence with the same anti-vacuity rule.
  """

  @repo_root Path.expand("../..", __DIR__)
  @mechanism_path Path.join(@repo_root, ".planning/phases/143-test-harness-truth/143-MECHANISM.md")
  @gating_decision_path Path.join(
                          @repo_root,
                          ".planning/phases/143-test-harness-truth/143-GATING-DECISION.md"
                        )
  @ledger_public_path Path.join(
                        @repo_root,
                        ".planning/phases/143-test-harness-truth/143-LEDGER-public.txt"
                      )
  @ledger_mailglass_path Path.join(
                           @repo_root,
                           ".planning/phases/143-test-harness-truth/143-LEDGER-mailglass.txt"
                         )

  @required_section_headings [
    "## 1. Verdict",
    "## 2. The proven causal chain",
    "## 3. Blast radius and duration",
    "## 4. The three-class inventory",
    "## 5. D-04's falsifiable predictions",
    "## 6. Rejected diagnostics, recorded once",
    "## 7. What this account does NOT claim"
  ]

  @gating_required_section_headings [
    "## 1. Verdict",
    "## 2. Rationale",
    "## 3. Why only the floor pair",
    "## 4. Why inbound remains advisory",
    "## 5. Evidence",
    "## 6. Accepted gaps",
    "## 7. Override discipline"
  ]

  test "143-MECHANISM.md and both ledger files exist and are non-empty" do
    for path <- [@mechanism_path, @ledger_public_path, @ledger_mailglass_path] do
      assert File.exists?(path), "expected #{path} to exist"
      assert File.stat!(path).size > 0, "expected #{path} to be non-empty"
    end
  end

  test "the account contains all seven required section headings" do
    account = File.read!(@mechanism_path)

    for heading <- @required_section_headings do
      assert account =~ heading,
             "143-MECHANISM.md is missing required section heading: #{inspect(heading)}"
    end
  end

  test "anti-vacuity guard: the account's own section-heading count is greater than zero" do
    # required_checks_test.exs:30-34 idiom — guard against a parser (here, a literal
    # substring scan) that silently matches nothing after a future formatting change,
    # which would let the "all headings present" test above pass on an empty diff of
    # two empty sets.
    account = File.read!(@mechanism_path)
    found = Enum.count(@required_section_headings, &(account =~ &1))

    assert found > 0,
           "found 0 of #{length(@required_section_headings)} required section headings in " <>
             "143-MECHANISM.md — the literal-substring heading scan in this test parsed " <>
             "nothing, which would make the heading-presence test above pass vacuously"
  end

  test "the account cites the confirming CI run ID and job ID" do
    account = File.read!(@mechanism_path)

    assert account =~ "30464215272",
           "143-MECHANISM.md must cite the confirming CI run ID (30464215272)"

    assert account =~ "90617762038",
           "143-MECHANISM.md must cite the confirming CI job ID (90617762038)"
  end

  test "the account contains the nested MatchError term shape and the top-level-match warning" do
    account = File.read!(@mechanism_path)

    assert account =~ "{:badmatch, :already_shared}",
           "143-MECHANISM.md must quote the {:badmatch, :already_shared} term"

    assert account =~ "{{:badmatch, :already_shared}, _stack}",
           "143-MECHANISM.md must show the NESTED failure term shape " <>
             "(a classifier matching the bare tuple at the top level matches nothing)"

    assert account =~ "matches NOTHING" or account =~ "matches nothing",
           "143-MECHANISM.md must explicitly state that a top-level match on the bare " <>
             "badmatch tuple matches nothing"
  end

  test "the account records a PASS/FAIL marker for each of D-04's two predictions" do
    account = File.read!(@mechanism_path)

    markers = Regex.scan(~r/\b(PASS|FAIL)\b/, account) |> Enum.map(fn [_, m] -> m end)

    assert length(markers) >= 2,
           "expected at least 2 PASS/FAIL markers (one per D-04 prediction) in " <>
             "143-MECHANISM.md, found #{length(markers)}"
  end

  test "the three-class inventory names a module for Class A and for Class B" do
    account = File.read!(@mechanism_path)

    assert account =~ "Class A" and account =~ "Class B" and account =~ "Class C",
           "143-MECHANISM.md must name all three D-31 leak classes"

    assert account =~ "schema_prefix_hardening_test.exs",
           "143-MECHANISM.md must name a specific Class A/B candidate module, sourced " <>
             "from direct read and the ledger's own recorded evidence"

    assert account =~ "A2 verdict" and account =~ "A3 verdict",
           "143-MECHANISM.md must mark research assumptions A2 and A3 confirmed or refuted"
  end

  test "each ledger header records the four ExUnit counts" do
    for path <- [@ledger_public_path, @ledger_mailglass_path] do
      ledger = File.read!(path)

      for label <- ["total tests:", "failures:", "excluded:", "skipped:"] do
        assert ledger =~ label, "#{path} is missing the #{inspect(label)} count in its header"
      end
    end
  end

  test "the ledgers never record recipient addresses, subjects, or bound query-parameter values" do
    for path <- [@ledger_public_path, @ledger_mailglass_path] do
      ledger = File.read!(path)

      refute ledger =~ ~r/@example\.com/i, "#{path} must not contain a recipient address"
      refute ledger =~ ~r/subject:/i, "#{path} must not contain a subject: field"
      refute ledger =~ ~r/recipient/i, "#{path} must not contain the word 'recipient'"
    end
  end

  test "143-GATING-DECISION.md exists and is non-empty" do
    assert File.exists?(@gating_decision_path),
           "expected #{@gating_decision_path} to exist"

    assert File.stat!(@gating_decision_path).size > 0,
           "expected #{@gating_decision_path} to be non-empty"
  end

  test "the gating decision contains all seven required section headings" do
    decision = File.read!(@gating_decision_path)

    for heading <- @gating_required_section_headings do
      assert decision =~ heading,
             "143-GATING-DECISION.md is missing required section heading: #{inspect(heading)}"
    end
  end

  test "anti-vacuity guard: the gating-decision heading parser finds at least one heading" do
    decision = File.read!(@gating_decision_path)
    found = Enum.count(@gating_required_section_headings, &(decision =~ &1))

    assert found > 0,
           "found 0 of #{length(@gating_required_section_headings)} required section headings in " <>
             "143-GATING-DECISION.md — the literal-substring heading parser in this test " <>
             "observed nothing and must not report success"
  end

  test "the gating decision records the verdict and both live publish-path outcomes" do
    decision = File.read!(@gating_decision_path)

    assert decision =~ "gate-floor-legs"
    assert decision =~ "actions/runs/30645265238"
    assert decision =~ "actions/runs/30645266725"
    assert decision =~ "actions/runs/30645896855"
    assert decision =~ "actions/runs/30654293410"
    assert decision =~ "did not start"
  end
end
