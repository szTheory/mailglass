Code.require_file("../../scripts/validate_repository_truth.exs", __DIR__)

defmodule Mailglass.Scripts.Phase164RepositoryTruthTest do
  use ExUnit.Case, async: true

  alias Mailglass.RepositoryTruthLedger, as: Ledger

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir ".planning/phases/164-repository-truth-reconciliation-and-closeout"
  @ledger Path.join(@repo_root, Path.join(@phase_dir, "164-TRUTH-DISPOSITION.tsv"))
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

  test "parses and validates the authoritative twelve-column ledger" do
    contents = File.read!(@ledger)

    assert {:ok, %{headers: @headers, rows: rows}} = Ledger.parse(contents)
    assert rows != []
    assert :ok = Ledger.validate(contents, @repo_root)

    assert {:ok, subjects} = Ledger.audit_subjects(@repo_root)
    assert MapSet.member?(subjects, "scripts/validate_repository_truth.exs")
    assert MapSet.member?(subjects, Path.join(@phase_dir, "164-VERIFICATION.md"))
  end

  test "D-08 retains its locked stale removal identity" do
    assert {:ok, %{rows: rows}} = Ledger.parse(File.read!(@ledger))
    assert [row] = Enum.filter(rows, &(&1["subject"] == "scheduled-control-sweep.json"))
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

  test "validates independently of row ordering and fails missing audited subject classes" do
    contents = File.read!(@ledger)
    [header | rows] = String.split(String.trim_trailing(contents), "\n", trim: true)

    assert :ok = Ledger.validate(Enum.join([header | Enum.reverse(rows)], "\n") <> "\n", @repo_root)

    for subject <- [
          "scripts/validate_repository_truth.exs",
          Path.join(@phase_dir, "164-VERIFICATION.md"),
          "ignore:.gitignore:/tmp/",
          ".planning/release-target.json"
        ] do
      assert {:error, {:missing_audited_subjects, missing}} =
               contents |> remove_subject(subject) |> Ledger.validate(@repo_root)

      assert subject in missing
    end
  end

  test "git ignores all GSD runtime state except the finalize-phase extension" do
    assert ignored?(".gsd/gsd.db")
    assert ignored?(".gsd/exec/probe")
    assert ignored?(".gsd/extensions/other/index.ts")
    refute ignored?(".gsd/extensions/finalize-phase/index.ts")
    refute ignored?(".gsd/extensions/finalize-phase/extension-manifest.json")
  end

  test "git ignores the canonical GSD lifecycle lock while planning proof stays visible" do
    assert ignored?(".planning/milestone.lock")
    refute ignored?(".planning/milestone-lock-proof.json")
    refute ignored?(".planning/release-target.json")
  end

  test "finalization artifacts have exactly one tracked current retain disposition" do
    assert {:ok, %{rows: rows}} = Ledger.parse(File.read!(@ledger))

    for subject <- [
          ".gitignore",
          ".gsd/extensions/finalize-phase/extension-manifest.json",
          ".gsd/extensions/finalize-phase/index.ts",
          "scripts/finalize_phase_164.sh",
          Path.join(@phase_dir, "164-FINALIZE.sh"),
          Path.join(@phase_dir, "164-FINALIZATION.md"),
          "scripts/ci_monitor.cjs",
          "scripts/scheduled_control_evidence.sh",
          "test/scripts/scheduled_control_evidence_test.exs"
        ] do
      assert [row] = Enum.filter(rows, &(&1["subject"] == subject))
      assert row["state"] == "tracked"
      assert row["currentness"] == "current"
      assert row["disposition"] == "retain"
    end
  end

  defp remove_subject(contents, subject) do
    contents
    |> String.split("\n", trim: true)
    |> Enum.reject(fn line -> String.split(line, "\t", parts: 3) |> Enum.at(1) == subject end)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp header_line, do: Enum.join(@headers, "\t")

  defp ignored?(path) do
    {_output, status} =
      System.cmd("git", ["check-ignore", "-q", path], cd: @repo_root, stderr_to_stdout: true)

    status == 0
  end

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
