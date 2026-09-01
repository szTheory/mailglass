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

    assert {:error, {:invalid_kind_relationship, "scheduled-control-sweep.json"}} =
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
             Ledger.parse(header_line() <> "\n" <> valid <> "\n" <> valid)
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

  test "rejects fabricated semantic authority fields and extra subjects" do
    contents = File.read!(@ledger)

    mutations = [
      mutate_first_row(contents, "stable_id", "FORGED"),
      mutate_first_row(contents, "kind", "forged-kind"),
      mutate_first_row(contents, "producer", "forged-producer"),
      mutate_first_row(contents, "state", "forged-state"),
      mutate_first_row(contents, "authority", "forged-authority"),
      mutate_first_row(contents, "reproducibility", "forged-reproducibility"),
      mutate_first_row(contents, "durable_consumer", "forged-consumer"),
      mutate_first_row(contents, "evidence", "fabricated-evidence")
    ]

    for mutation <- mutations do
      assert {:error, _reason} = Ledger.validate(mutation, @repo_root)
    end

    [header | rows] = String.split(contents, "\n", trim: true)
    tracked = Enum.find(rows, &String.starts_with?(&1, "M-01\t"))

    fabricated =
      tracked
      |> String.replace_prefix("M-01\t", "M-99\t")
      |> String.replace("\t#{Enum.at(String.split(tracked, "\t"), 1)}\t", "\tfabricated-subject\t")

    assert {:error, {:invalid_canonical_relationship, "fabricated-subject"}} =
             Ledger.validate(contents <> fabricated <> "\n", @repo_root)

    assert header == header_line()
  end

  test "rejects cross-row borrowing of canonical authority relationships" do
    contents = File.read!(@ledger)

    transplanted =
      swap_row_semantics(
        contents,
        "README.md",
        ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md"
      )

    assert {:error,
            {:invalid_canonical_relationship,
             ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md"}} =
             Ledger.validate(transplanted, @repo_root)
  end

  test "rejects a whitelisted producer transplanted onto an ignore subject" do
    contents = File.read!(@ledger)
    subject = "ignore:.gitignore:/_build/"

    transplanted = mutate_subject_row(contents, subject, "producer", "GSD phase lifecycle")

    assert {:error, {:invalid_canonical_relationship, ^subject}} =
             Ledger.validate(transplanted, @repo_root)
  end

  test "rejects stable IDs swapped between ignore subjects" do
    contents = File.read!(@ledger)
    first_subject = "ignore:.gitignore:/_build/"
    second_subject = "ignore:.gitignore:/cover/"

    swapped = swap_subject_column(contents, first_subject, second_subject, "stable_id")

    assert {:error, {:invalid_canonical_relationship, subject}} =
             Ledger.validate(swapped, @repo_root)

    assert subject in [first_subject, second_subject]
  end

  test "fails closed for an otherwise valid non-ignore subject absent from the canonical map" do
    contents = File.read!(@ledger)
    canonical_subject = "README.md"
    unmapped_subject = "future-audited-proof.md"

    [header | rows] = String.split(String.trim_trailing(contents), "\n", trim: true)
    row = Enum.find(rows, &String.contains?(&1, "\t#{canonical_subject}\t"))
    unmapped = String.replace(row, "\t#{canonical_subject}\t", "\t#{unmapped_subject}\t")

    assert {:error, {:invalid_canonical_relationship, ^unmapped_subject}} =
             Ledger.parse(Enum.join([header, unmapped], "\n") <> "\n")
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
        "scripts/scheduled_control_evidence.sh sweep (content shape only; no root-path producer)",
        "untracked",
        "D-08",
        "regenerable from the scheduled-control evidence workflow",
        "stale",
        "none",
        "D-08; sha256:#{@locked_digest}; Phase 162 scheduled-control proof",
        "remove",
        "stale generated root sweep"
      ],
      "\t"
    )
  end

  defp mutate_first_row(contents, column, value) do
    [header, first | rest] = String.split(String.trim_trailing(contents), "\n", trim: true)
    index = Enum.find_index(@headers, &(&1 == column))
    fields = String.split(first, "\t", trim: false)
    mutated = fields |> List.replace_at(index, value) |> Enum.join("\t")
    Enum.join([header, mutated | rest], "\n") <> "\n"
  end

  defp swap_row_semantics(contents, first_subject, second_subject) do
    semantic_indexes =
      @headers
      |> Enum.with_index()
      |> Enum.reject(fn {column, _index} -> column in ["subject", "rationale"] end)
      |> Enum.map(&elem(&1, 1))

    lines = String.split(String.trim_trailing(contents), "\n", trim: true)
    first_index = Enum.find_index(lines, &String.contains?(&1, "\t#{first_subject}\t"))
    second_index = Enum.find_index(lines, &String.contains?(&1, "\t#{second_subject}\t"))
    first = String.split(Enum.at(lines, first_index), "\t", trim: false)
    second = String.split(Enum.at(lines, second_index), "\t", trim: false)

    swap = fn target, donor ->
      Enum.reduce(semantic_indexes, target, fn index, fields ->
        List.replace_at(fields, index, Enum.at(donor, index))
      end)
      |> Enum.join("\t")
    end

    lines
    |> List.replace_at(first_index, swap.(first, second))
    |> List.replace_at(second_index, swap.(second, first))
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp mutate_subject_row(contents, subject, column, value) do
    lines = String.split(String.trim_trailing(contents), "\n", trim: true)
    row_index = Enum.find_index(lines, &String.contains?(&1, "\t#{subject}\t"))
    column_index = Enum.find_index(@headers, &(&1 == column))

    mutated =
      lines
      |> Enum.at(row_index)
      |> String.split("\t", trim: false)
      |> List.replace_at(column_index, value)
      |> Enum.join("\t")

    lines
    |> List.replace_at(row_index, mutated)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp swap_subject_column(contents, first_subject, second_subject, column) do
    lines = String.split(String.trim_trailing(contents), "\n", trim: true)
    first_index = Enum.find_index(lines, &String.contains?(&1, "\t#{first_subject}\t"))
    second_index = Enum.find_index(lines, &String.contains?(&1, "\t#{second_subject}\t"))
    column_index = Enum.find_index(@headers, &(&1 == column))
    first = String.split(Enum.at(lines, first_index), "\t", trim: false)
    second = String.split(Enum.at(lines, second_index), "\t", trim: false)

    lines
    |> List.replace_at(
      first_index,
      first |> List.replace_at(column_index, Enum.at(second, column_index)) |> Enum.join("\t")
    )
    |> List.replace_at(
      second_index,
      second |> List.replace_at(column_index, Enum.at(first, column_index)) |> Enum.join("\t")
    )
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end
end
