defmodule Mailglass.Scripts.Phase164RepositoryTruthTest do
  use ExUnit.Case, async: true

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
  @dispositions ~w(retain update archive remove ignore)
  @locked_digest "331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e"
  @ignore_files [
    ".gitignore",
    "mailglass_admin/.gitignore",
    "mailglass_inbound/.gitignore",
    "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore",
    "test/example/.gitignore"
  ]
  @tracked_proof_paths [
    ".planning/release-target.json",
    ".planning/publish/mailglass-publish-summary.json",
    ".planning/publish/mailglass_admin-publish-summary.json",
    ".planning/publish/mailglass_inbound-publish-summary.json",
    ".planning/publish/mailglass-files.expected",
    ".planning/publish/mailglass_admin-files.expected",
    ".planning/publish/mailglass_inbound-files.expected",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md",
    ".github/scheduled-controls.json"
  ]
  @phase_artifacts [
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv",
    "test/scripts/phase_164_repository_truth_test.exs",
    "scheduled-control-sweep.json",
    "MAINTAINING.md",
    "test/mailglass/publish/maintaining_release_gate_contract_test.exs",
    "README.md",
    "mailglass_admin/README.md",
    "mailglass_inbound/README.md",
    "test/mailglass/docs_contract_test.exs",
    "scripts/closeout_repository_truth.sh",
    "test/scripts/phase_164_closeout_test.exs",
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md"
  ]

  test "the disposition ledger exposes the stable twelve-column schema and complete rows" do
    assert {:ok, %{headers: @headers, rows: rows}} = parse_ledger(File.read!(@ledger))
    assert rows != []
  end

  test "D-08 records the stale root sweep exactly once with its locked identity and remove disposition" do
    assert {:ok, %{rows: rows}} = parse_ledger(File.read!(@ledger))

    assert [row] = Enum.filter(rows, &(&1["subject"] == "scheduled-control-sweep.json"))
    assert row["stable_id"] == "D-08"
    assert row["disposition"] == "remove"
    assert row["evidence"] =~ @locked_digest
    assert row["kind"] == "generated-output"
    assert row["producer"] =~ "no root-path producer"
    assert row["durable_consumer"] == "none"
  end

  test "ledger ignore-rule rows bijectively inventory all six committed ignore files" do
    assert {:ok, %{rows: rows}} = parse_ledger(File.read!(@ledger))

    expected_subjects =
      @ignore_files
      |> Enum.flat_map(&ignore_subjects/1)
      |> MapSet.new()

    ledger_subjects =
      rows
      |> Enum.filter(&(&1["kind"] == "ignore-rule"))
      |> Enum.map(& &1["subject"])
      |> MapSet.new()

    assert ledger_subjects == expected_subjects

    for row <- Enum.filter(rows, &(&1["kind"] == "ignore-rule")) do
      assert row["disposition"] == "ignore"
      assert row["producer"] not in ["", "none"]
      assert row["rationale"] =~ ~r/narrow|scoped|specific/i
    end
  end

  test "durable tracked proof and every phase artifact have exactly one disposition row" do
    assert {:ok, %{rows: rows}} = parse_ledger(File.read!(@ledger))
    subjects = Enum.map(rows, & &1["subject"])

    tracked_publish = git_ls_files(".planning/publish")
    expected_proof = Enum.uniq(@tracked_proof_paths ++ tracked_publish)

    for path <- expected_proof do
      assert path in git_ls_files(path), "expected durable proof to remain tracked: #{path}"
      assert 1 == Enum.count(subjects, &(&1 == path)), "expected one disposition row for #{path}"
      row = Enum.find(rows, &(&1["subject"] == path))
      assert row["disposition"] in ["retain", "archive"]
      assert row["state"] == "tracked"
    end

    for path <- @phase_artifacts do
      assert 1 == Enum.count(subjects, &(&1 == path)), "expected one Phase 164 disposition row for #{path}"
    end
  end

  @tag :tmp_dir
  test "the parser rejects duplicate, blank, unknown-currentness, stale-without-outcome, and unknown disposition rows",
       %{tmp_dir: tmp_dir} do
    valid = valid_ledger_row()
    duplicate_subject = String.replace(valid, "D-08", "D-09")
    malformed_ledger = Path.join(tmp_dir, "malformed-ledger.tsv")

    File.write!(malformed_ledger, header_line() <> "\n" <> valid <> "\n" <> duplicate_subject)

    assert {:error, {:duplicate_subject, "scheduled-control-sweep.json"}} =
             malformed_ledger |> File.read!() |> parse_ledger()

    assert {:error, {:blank_required_field, "kind"}} =
             parse_ledger(header_line() <> "\n" <> String.replace(valid, "generated-output", ""))

    assert {:error, {:invalid_currentness, "unknown"}} =
             parse_ledger(header_line() <> "\n" <> String.replace(valid, "stale", "unknown"))

    assert {:error, {:stale_without_outcome, "scheduled-control-sweep.json"}} =
             parse_ledger(header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tretain\t"))

    assert {:error, {:invalid_disposition, "destroy"}} =
             parse_ledger(header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tdestroy\t"))
  end

  test "the stale sweep is removed and no ignore rule broadly conceals durable evidence" do
    refute File.exists?(Path.join(@repo_root, "scheduled-control-sweep.json"))

    forbidden = ~w(.planning publish release scheduled-control generated-host)

    for ignore_file <- @ignore_files,
        pattern <- ignore_patterns(ignore_file) do
      refute pattern == "scheduled-control-sweep.json"
      refute Enum.any?(forbidden, &String.contains?(pattern, &1)),
             "#{ignore_file} broadly hides durable evidence with #{pattern}"
    end
  end

  defp ignore_subjects(ignore_file) do
    ignore_file
    |> ignore_patterns()
    |> Enum.map(&"ignore:#{ignore_file}:#{&1}")
  end

  defp ignore_patterns(ignore_file) do
    @repo_root
    |> Path.join(ignore_file)
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.to_list()
  end

  defp git_ls_files(path) do
    {output, 0} = System.cmd("git", ["ls-files", "--", path], cd: @repo_root)
    String.split(output, "\n", trim: true)
  end

  defp parse_ledger(contents) do
    with [header | row_lines] <- String.split(String.trim_trailing(contents), "\n", trim: true),
         @headers <- String.split(header, "\t"),
         {:ok, rows} <- parse_rows(row_lines),
         :ok <- ensure_unique_subjects(rows) do
      {:ok, %{headers: @headers, rows: rows}}
    else
      headers when is_list(headers) -> {:error, {:invalid_header, headers}}
      error -> error
    end
  end

  defp parse_rows(row_lines) do
    row_lines
    |> Enum.reduce_while({:ok, []}, fn line, {:ok, rows} ->
      case row_from_fields(String.split(line, "\t", trim: false)) do
        {:ok, row} -> {:cont, {:ok, [row | rows]}}
        error -> {:halt, error}
      end
    end)
    |> then(fn
      {:ok, rows} -> {:ok, Enum.reverse(rows)}
      error -> error
    end)
  end

  defp row_from_fields(fields) when length(fields) == length(@headers) do
    row = Map.new(Enum.zip(@headers, fields))

    cond do
      blank_field = Enum.find(@headers, &(row[&1] == "")) ->
        {:error, {:blank_required_field, blank_field}}

      row["disposition"] not in @dispositions ->
        {:error, {:invalid_disposition, row["disposition"]}}

      row["currentness"] not in ["current", "historical", "stale"] ->
        {:error, {:invalid_currentness, row["currentness"]}}

      row["currentness"] == "stale" and row["disposition"] not in ["update", "archive", "remove"] ->
        {:error, {:stale_without_outcome, row["subject"]}}

      true ->
        {:ok, row}
    end
  end

  defp row_from_fields(fields), do: {:error, {:invalid_column_count, length(fields)}}

  defp ensure_unique_subjects(rows) do
    case Enum.find(rows, fn row -> Enum.count(rows, &(&1["subject"] == row["subject"])) > 1 end) do
      nil -> :ok
      row -> {:error, {:duplicate_subject, row["subject"]}}
    end
  end

  defp header_line, do: Enum.join(@headers, "\t")

  defp valid_ledger_row do
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
