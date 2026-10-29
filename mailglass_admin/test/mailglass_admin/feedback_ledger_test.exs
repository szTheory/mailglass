defmodule MailglassAdmin.FeedbackLedgerTest do
  @moduledoc """
  UIQ-04 / D-08: the owner-feedback ledger in
  `reference/persona_spec/quick_view_scenarios.json` is checked by a
  phase-independent rule. Every row whose status is not `pending` must name
  scenarios (or carry the connected-real-route-only boundary) and an
  `evidence_pointer` that resolves to a real file and heading. No `owner_phase`
  value is consulted, so the rule survives phase archival.
  """

  use ExUnit.Case, async: true

  @moduletag :phase178

  alias MailglassAdmin.TestSupport.FeedbackLedger
  alias MailglassDemo.QuickViewScenarios

  @ledger_source Path.expand("../support/feedback_ledger.ex", __DIR__)

  @expected_row_ids ~w(
    fb-health-crowding
    fb-preview-reset
    fb-preview-identity
    fb-account-context
    fb-auto-apply-filters
    fb-quiet-quick-view-arrows
    fb-raw-source-hierarchy
    fb-suppression-refresh
    fb-inbound-addresses
    fb-storybook-fidelity
    fb-replay-review
    fb-technical-details
  )

  describe "real manifest" do
    test "Phase 178 ledger: every non-pending row satisfies the D-08 rule" do
      assert FeedbackLedger.rule_violations(
               QuickViewScenarios.feedback(),
               QuickViewScenarios.scenarios(),
               FeedbackLedger.repo_root()
             ) == []
    end

    test "Phase 178 ledger: the repo root contains the planning tree" do
      assert File.dir?(Path.join(FeedbackLedger.repo_root(), ".planning"))
    end

    test "Phase 178 ledger: the manifest keeps exactly the 12 rows in their current order (D-07)" do
      assert Enum.map(QuickViewScenarios.feedback(), & &1["id"]) == @expected_row_ids
    end
  end

  describe "no phase coupling" do
    test "Phase 178 ledger: the rule functions do not reference owner_phase" do
      source = File.read!(@ledger_source)

      refute references_owner_phase?(source),
             "FeedbackLedger must not consult owner_phase (D-08 phase independence)"
    end

    test "Phase 178 ledger: the owner_phase scan has teeth" do
      assert references_owner_phase?(~s|Enum.filter(rows, &(&1["owner_phase"] == "178"))|)
      assert references_owner_phase?(~s|row.owner_phase|)
      refute references_owner_phase?(~s|row["status"] == "pending"|)
    end
  end

  defp references_owner_phase?(source), do: String.contains?(source, "owner_phase")
end
