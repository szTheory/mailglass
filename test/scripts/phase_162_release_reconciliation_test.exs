defmodule Mailglass.Scripts.Phase162ReleaseReconciliationTest do
  use ExUnit.Case, async: true

  @ledger Path.expand("../../.planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md", __DIR__)

  test "the PR #222 tracer has complete source, identity, observation, and disposition evidence" do
    ledger = File.read!(@ledger)

    assert ledger =~ "# Release-State Capture"
    assert ledger =~ "Captured UTC"
    assert ledger =~ "gh pr view 222"
    assert ledger =~ "PR #222"
    assert ledger =~ ~r/head SHA[^\n]*[0-9a-f]{40}/
    assert ledger =~ ~r/base SHA[^\n]*[0-9a-f]{40}/
    assert ledger =~ "auto-merge: null"
    assert ledger =~ "protected-merge"
    assert ledger =~ "exact candidate-digest protected dispatch"
    assert ledger =~ "authorized" <> " plus `publication: not_started`"
  end

  test "unavailable GitHub acquisition is explicitly cannot-check and names a recovery command" do
    ledger = File.read!(@ledger)

    assert ledger =~ "cannot-check"
    assert ledger =~ "gh pr view 222"
    assert ledger =~ "Recovery command"
  end
end
