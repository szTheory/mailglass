Code.require_file("../../scripts/validate_repository_truth.exs", __DIR__)

defmodule Mailglass.Scripts.Phase164RepositoryTruthTest do
  use ExUnit.Case, async: true

  alias Mailglass.RepositoryTruthLedger, as: Ledger

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir ".planning/phases/164-repository-truth-reconciliation-and-closeout"
  @headers [
    "stable_id",
    "subject",
    "kind",
    "producer",
    "state",
    "authority",
    "reproducibility",
    "currentness",
    "durable_consumer",
    "evidence",
    "disposition",
    "rationale"
  ]
  @locked_digest "331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e"

  test "parses a valid twelve-column ledger and derives its complete audit inventory" do
    assert {:ok, %{headers: @headers, rows: [_]}} =
             Ledger.parse(header_line() <> "\n" <> valid_row())

    assert {:ok, subjects} = Ledger.audit_subjects(@repo_root)
    assert MapSet.member?(subjects, "scripts/validate_repository_truth.exs")
    assert MapSet.member?(subjects, Path.join(@phase_dir, "164-VERIFICATION.md"))
  end

  test "D-08 retains its locked stale removal identity" do
    assert {:ok, %{rows: [row]}} = Ledger.parse(header_line() <> "\n" <> valid_row())
    assert row["stable_id"] == "D-08"
    assert row["disposition"] == "remove"
    assert row["evidence"] =~ @locked_digest
  end

  test "rejects malformed schema, exact-currentness forgeries, and stale retained rows" do
    valid = valid_row()

    assert {:error, {:invalid_header, _}} = Ledger.parse("wrong\theader\n" <> valid)

    assert {:error, {:invalid_currentness, "current-forged"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tstale\t", "\tcurrent-forged\t")
             )

    assert {:error, {:invalid_currentness, "stale-looking"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tstale\t", "\tstale-looking\t")
             )

    assert {:error, {:stale_without_outcome, "scheduled-control-sweep.json"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tretain\t")
             )

    assert {:ok, _} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tarchive\t")
             )
  end

  test "rejects empty, incomplete, and duplicate-subject ledgers" do
    valid = valid_row()

    assert {:error, :empty_ledger} = Ledger.parse("")
    assert {:error, :empty_ledger} = Ledger.parse(header_line() <> "\n")

    assert {:error, {:blank_required_field, "kind"}} =
             Ledger.parse(header_line() <> "\n" <> String.replace(valid, "generated-output", ""))

    assert {:error, {:duplicate_subject, "scheduled-control-sweep.json"}} =
             Ledger.parse(
               header_line() <> "\n" <> valid <> "\n" <> String.replace(valid, "D-08", "D-09")
             )
  end

  defp header_line, do: Enum.join(@headers, "\t")

  defp valid_row do
    Enum.join(
      [
        "D-08",
        "scheduled-control-sweep.json",
        "generated-output",
        "no root-path producer",
        "untracked",
        "D-08",
        "reproducible",
        "stale",
        "none",
        "sha256:#{@locked_digest}",
        "remove",
        "stale generated root sweep"
      ],
      "\t"
    )
  end
end
