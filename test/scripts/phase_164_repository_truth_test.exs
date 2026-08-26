defmodule Mailglass.Scripts.Phase164RepositoryTruthTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @ledger Path.join(@repo_root, ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv")
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
  @ignore_files [
    ".gitignore",
    "mailglass_admin/.gitignore",
    "mailglass_inbound/.gitignore",
    "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore",
    "test/example/.gitignore"
  ]

  test "the disposition ledger exposes the stable twelve-column schema" do
    assert {:ok, %{headers: @headers}} = parse_ledger(File.read!(@ledger))
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

  test "the parser rejects duplicate subjects, blank required fields, and unknown dispositions" do
    valid = valid_ledger_row()
    duplicate_subject = String.replace(valid, "D-08", "D-09")

    assert {:error, {:duplicate_subject, "scheduled-control-sweep.json"}} =
             parse_ledger(header_line() <> "\n" <> valid <> "\n" <> duplicate_subject)

    blank_required_field = String.replace(valid, "generated-output", "")
    assert {:error, {:blank_required_field, "kind"}} = parse_ledger(header_line() <> "\n" <> blank_required_field)

    invalid_disposition = String.replace(valid, "\tremove\t", "\tdestroy\t")
    assert {:error, {:invalid_disposition, "destroy"}} = parse_ledger(header_line() <> "\n" <> invalid_disposition)
  end

  test "the stale sweep is removed without adding a proof-hiding ignore rule" do
    refute File.exists?(Path.join(@repo_root, "scheduled-control-sweep.json"))

    for ignore_file <- @ignore_files do
      refute File.read!(Path.join(@repo_root, ignore_file)) =~ "scheduled-control-sweep.json"
    end
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
      fields = String.split(line, "\t", trim: false)

      case row_from_fields(fields) do
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

      row["disposition"] not in ["retain", "update", "archive", "remove", "ignore"] ->
        {:error, {:invalid_disposition, row["disposition"]}}

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
