defmodule Mailglass.Scripts.Phase162ReleaseReconciliationTest do
  use ExUnit.Case, async: true

  @ledger Path.expand(
            "../../.planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md",
            __DIR__
          )

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
    assert ledger =~ "`authorized` plus `publication: not_started`"
  end

  test "unavailable GitHub acquisition is explicitly cannot-check and names a recovery command" do
    ledger = File.read!(@ledger)

    assert ledger =~ "cannot-check"
    assert ledger =~ "gh pr view 222"
    assert ledger =~ "Recovery command"
  end

  test "the expanded ledger covers every canonical source in stable category and identity order" do
    ledger = File.read!(@ledger)

    for source <- [
          "GitHub PR API",
          "GitHub Checks API",
          "Git refs",
          "Git tags/releases",
          "Hex package API",
          "release-target.json",
          "canonical publish summaries",
          "WT-03 retained diff",
          "Phase 161 recovery refs"
        ] do
      assert ledger =~ source
    end

    rows = matrix_rows(ledger, "Expanded evidence matrix")
    assert rows != []

    identities = Enum.map(rows, & &1["Immutable identity"])

    assert Enum.map(rows, &{&1["Category"], &1["Immutable identity"]}) ==
             Enum.sort_by(rows, &{&1["Category"], &1["Immutable identity"]})
             |> Enum.map(&{&1["Category"], &1["Immutable identity"]})

    assert Enum.all?(identities, &(&1 != ""))
  end

  test "every scoped disposition is singular and empty scoped categories are explicit" do
    ledger = File.read!(@ledger)
    rows = matrix_rows(ledger, "Expanded disposition matrix")

    assert rows != []
    assert Enum.all?(rows, &(&1["Outcome"] in ["retain", "retire", "protected-merge"]))
    assert Enum.uniq_by(rows, &{&1["Category"], &1["Immutable identity"]}) == rows

    for empty_category <- ["NONE-stale-release-branches", "NONE-unavailable-remote-response"] do
      assert Enum.any?(rows, &(&1["Immutable identity"] == empty_category))
    end
  end

  test "publication rows preserve all three exact versions and checksums without creating authority" do
    ledger = File.read!(@ledger)

    for checksum <- [
          "8ffab2c0708b5eb3b18693ec6df1b4ad105abc38d7041f1f7b7650cb046f05de",
          "19a4400bb76631605424f6edba30905de50c1d31e8db6667ec31007222ba832c",
          "b3261d51b58fa8d69ffee7045507f9a0e2c57ea4b09be7f796378f267ad84cc2"
        ] do
      assert ledger =~ checksum
    end

    assert ledger =~ "publication: not_started"
    refute ledger =~ "authorized release authority"
  end

  test "a final control recovery capture preserves prior blocks and records final outcomes" do
    ledger = File.read!(@ledger)

    assert ledger =~ "## Capture 2026-08-22T18:43:11Z"
    assert ledger =~ "## Capture 2026-08-22T18:45:01Z — Expanded scope"
    assert ledger =~ "## Final Control Recovery Capture"
    assert ledger =~ ~r/\*\*Captured UTC:\*\* `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z`/
    assert ledger =~ "**Canonical HEAD:**"

    rows = matrix_rows(ledger, "Final disposition matrix")
    assert rows != []
    assert Enum.all?(rows, &(&1["Outcome"] in ["retain", "retire", "protected-merge"]))
    assert Enum.uniq_by(rows, &{&1["Category"], &1["Immutable identity"]}) == rows
  end

  test "final run evidence keeps control and schedule provenance distinct and blocks unresolved threats" do
    ledger = File.read!(@ledger)
    rows = matrix_rows(ledger, "Final run evidence")

    assert Enum.any?(rows, &(&1["Event"] == "workflow_dispatch"))
    assert Enum.any?(rows, &(&1["Event"] == "schedule"))

    assert Enum.all?(rows, fn row ->
             row["Status"] == "pending" or String.trim(row["Run ID"]) != ""
           end)

    assert Enum.all?(rows, &(String.trim(&1["Artifact SHA-256"]) != ""))

    real_run_ids =
      rows
      |> Enum.reject(&(&1["Status"] == "pending"))
      |> Enum.map(& &1["Run ID"])

    assert Enum.uniq(real_run_ids) == real_run_ids
    assert ledger =~ "manual dispatch is not scheduled proof"
    assert ledger =~ "## Threat closure"
    assert ledger =~ "T-162-20"
    assert ledger =~ "Phase result: blocked"
  end

  test "every Phase 162 threat has an explicit final closure and each pending schedule names its cron" do
    ledger = File.read!(@ledger)

    for number <- 1..20 do
      assert ledger =~ "T-162-#{String.pad_leading(Integer.to_string(number), 2, "0")}"
    end

    for cron <- ["17 * * * *", "30 12 * * *", "0 12 * * *"] do
      assert ledger =~ cron
    end
  end

  defp matrix_rows(ledger, title) do
    [_, table] = String.split(ledger, "### #{title}\n\n", parts: 2)

    [header, _separator | rows] =
      table
      |> String.split("\n")
      |> Enum.take_while(&String.starts_with?(&1, "|"))
      |> Enum.map(&parse_row/1)

    Enum.map(rows, &Map.new(Enum.zip(header, &1)))
  end

  defp parse_row(row) do
    row
    |> String.trim("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end
end
