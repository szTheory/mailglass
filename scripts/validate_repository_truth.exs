defmodule Mailglass.RepositoryTruthLedger do
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
  @header_line Enum.join(@headers, "\t")
  @dispositions ~w(retain update archive remove ignore)
  @currentness ~w(current historical stale)
  @ignore_files [
    ".gitignore",
    "mailglass_admin/.gitignore",
    "mailglass_inbound/.gitignore",
    "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore",
    "test/example/.gitignore"
  ]
  @proof_paths [
    ".planning/release-target.json",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md",
    ".github/scheduled-controls.json"
  ]
  @phase_dir ".planning/phases/164-repository-truth-reconciliation-and-closeout"

  def parse(contents) when is_binary(contents) do
    case String.split(String.trim_trailing(contents), "\n", trim: true) do
      [] ->
        {:error, :empty_ledger}

      [header] when header == @header_line ->
        {:error, :empty_ledger}

      [header | row_lines] when row_lines != [] ->
        if header == @header_line do
          with {:ok, rows} <- parse_rows(row_lines), :ok <- ensure_unique_subjects(rows) do
            {:ok, %{headers: @headers, rows: rows}}
          end
        else
          {:error, {:invalid_header, String.split(header, "\t")}}
        end

      [header | _] ->
        {:error, {:invalid_header, String.split(header, "\t")}}
    end
  end

  def audit_subjects(repo_root) do
    with :ok <- ensure_repository(repo_root) do
      subjects =
        ignore_subjects(repo_root) ++
          tracked_subjects(repo_root, ".planning/publish") ++
          @proof_paths ++
          phase_artifacts(repo_root) ++ [Path.join(@phase_dir, "164-VERIFICATION.md")]

      {:ok, MapSet.new(subjects)}
    end
  end

  def validate(contents, repo_root) do
    with {:ok, %{rows: rows}} <- parse(contents),
         {:ok, required_subjects} <- audit_subjects(repo_root) do
      subjects = rows |> Enum.map(& &1["subject"]) |> MapSet.new()
      missing = required_subjects |> MapSet.difference(subjects) |> MapSet.to_list() |> Enum.sort()

      if missing == [], do: :ok, else: {:error, {:missing_audited_subjects, missing}}
    end
  end

  defp parse_rows(lines) do
    lines
    |> Enum.reduce_while({:ok, []}, fn line, {:ok, rows} ->
      case row_from_fields(String.split(line, "\t", trim: false)) do
        {:ok, row} -> {:cont, {:ok, [row | rows]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, rows} -> {:ok, Enum.reverse(rows)}
      error -> error
    end
  end

  defp row_from_fields(fields) when length(fields) == length(@headers) do
    row = Map.new(Enum.zip(@headers, fields))

    cond do
      blank_field = Enum.find(@headers, &(row[&1] == "")) ->
        {:error, {:blank_required_field, blank_field}}

      row["disposition"] not in @dispositions ->
        {:error, {:invalid_disposition, row["disposition"]}}

      row["currentness"] not in @currentness ->
        {:error, {:invalid_currentness, row["currentness"]}}

      row["currentness"] == "stale" and row["disposition"] not in ~w(update archive remove) ->
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

  defp ensure_repository(repo_root) do
    if File.dir?(repo_root), do: :ok, else: {:error, {:invalid_repository, repo_root}}
  end

  defp ignore_subjects(repo_root) do
    @ignore_files
    |> Enum.flat_map(fn ignore_file ->
      repo_root
      |> Path.join(ignore_file)
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.map(&"ignore:#{ignore_file}:#{&1}")
    end)
  end

  defp tracked_subjects(repo_root, path) do
    {output, 0} = System.cmd("git", ["ls-files", "--", path], cd: repo_root)
    String.split(output, "\n", trim: true)
  end

  defp phase_artifacts(repo_root) do
    repo_root
    |> Path.join(Path.join(@phase_dir, "164-*-PLAN.md"))
    |> Path.wildcard()
    |> Enum.flat_map(&plan_files_modified/1)
    |> Enum.uniq()
  end

  defp plan_files_modified(plan) do
    case Regex.run(~r/^files_modified:\n(?<paths>(?:\s+- .+\n)*)^autonomous:/m, File.read!(plan),
           capture: :all_names
         ) do
      [paths] ->
        paths
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end
end

if Enum.any?(System.argv(), &(&1 in ["--repo", "--ledger"])) do
  argv = Enum.drop_while(System.argv(), &(&1 == "--"))
  {opts, _, errors} = OptionParser.parse(argv, strict: [repo: :string, ledger: :string])

  result =
    with [] <- errors,
         repo when is_binary(repo) <- opts[:repo],
         ledger when is_binary(ledger) <- opts[:ledger],
         {:ok, contents} <- File.read(ledger) do
      Mailglass.RepositoryTruthLedger.validate(contents, repo)
    else
      nil -> {:error, :missing_required_cli_option}
      {:error, reason} -> {:error, reason}
      errors when is_list(errors) -> {:error, {:invalid_options, errors}}
    end

  case result do
    :ok ->
      IO.puts("repository truth ledger: valid")

    {:error, reason} ->
      IO.puts(:stderr, "repository truth ledger: #{inspect(reason)}")
      System.halt(1)
  end
end
