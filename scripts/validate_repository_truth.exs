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
  @states ~w(tracked untracked ignored)
  @kinds ~w(ci-evidence-client closeout-report closeout-script contract-test finalization-guidance finalization-script finalization-shim forensic-proof generated-output gsd-extension-command gsd-extension-manifest ignore-rule maintainer-guidance package-allowlist package-guidance planning-artifact protected-ci-proof publish-proof release-proof repository-ignore-contract repository-truth-validator scheduled-control-contract scheduled-control-proof scheduled-control-verifier verification-report)
  @producers [
    "GSD phase lifecycle", "GSD project extension loader", "GSD runtime state producer",
    "GitHub scheduled-control registry", "Phase 161 preservation audit", "Phase 161 workspace audit",
    "Phase 162 protected release recovery", "Phase 162 scheduled control audit", "Phase 162 verification",
    "Phase 163 protected CI audit", "Phase 163 verifier", "Phase 164 closeout plan",
    "Phase 164 disposition audit", "Phase 164 finalization boundary", "Phase 164 maintainer reconciliation",
    "Phase 164 package compatibility reconciliation", "Phase 164 repository truth contract",
    "Phase 164 shared ledger validation", "Phase 164 verifier", "mix mailglass.publish.check",
    "scripts/release_policy.exs", "scripts/scheduled_control_evidence.sh sweep (content shape only; no root-path producer)",
    "scripts/verify_published_release.sh", "shared project tooling producer"
  ]
  @authorities [
    ".gitignore", "D-05 through D-12", "D-07 and D-09", "D-08", "D-09 and D-10",
    "D-09 through D-11", "D-09 through D-12", "D-11", "Phase 161 evidence contract",
    "Phase 162 release authority", "Phase 162 requirement verification", "Phase 162 scheduled-control contract",
    "Phase 163 exact protected run", "Phase 163 requirement verification", "Phase 164 verification authority",
    "admin package manifest compatibility", "current executable authority projection",
    "executable scheduled-control contract", "inbound package manifest compatibility",
    "mailglass_admin/.gitignore", "mailglass_inbound/.gitignore", "maintainer release contract",
    "manifest-derived docs contract", "package content contract", "package manifest compatibility",
    "protected release policy", "published package verification", "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore", "test/example/.gitignore"
  ]
  @reproducibility [
    "captured from exact event run and workflow identities", "captured from exact protected run and SHA",
    "captured from immutable Git facts", "captured from protected GitHub and Git facts",
    "derived from Git graph and content", "derived from exact protected evidence", "derived from tracked evidence",
    "regenerable advisory session claim", "regenerable extension-local state", "regenerable from audited Git state",
    "regenerable from authorized evidence", "regenerable from exact main state", "regenerable from extension source",
    "regenerable from immutable package facts", "regenerable from package source", "regenerable from plan source",
    "regenerable from protected GitHub evidence", "regenerable from repository source",
    "regenerable from settled lifecycle contract", "regenerable from source",
    "regenerable from the scheduled-control evidence workflow", "regenerable from tracked verification process",
    "regenerable machine-local output", "reproducible from manifests", "reproducible from release controls",
    "reproducible from repository configuration", "reproducible from source", "reproducible loader boundary"
  ]
  @durable_consumers [
    "GSD project extension loader", "GSD runtime and extension boundary", "Phase 164 closeout",
    "Phase 164 closeout contract", "adopter documentation", "closeout CI identity validation",
    "closeout provenance", "closeout repository truth gate", "closeout scheduled evidence validation",
    "finalize-phase extension boundary", "finalize-phase extension dispatcher",
    "finalize-phase stable-porcelain guard", "maintainer closeout reader", "maintainer finalization command",
    "maintainer provenance", "maintainer release gate", "mix test closeout contract",
    "mix test documentation gate", "mix test maintainer guidance gate", "mix test repository truth gate",
    "mix test scheduled evidence gate", "none", "package release verification", "post-completion operational proof",
    "protected release guidance", "publish contract tests", "rerunnable closeout report",
    "scheduled evidence scripts and workflow", "test fixture allowlist", "workspace preservation verification"
  ]
  @tracked_evidence [
    "164-02-PLAN.md", "164-03-PLAN.md", "164-04-PLAN.md", "164-05-PLAN.md", "164-08-PLAN.md",
    "git ls-files .planning/publish", "git ls-files; 164-08-PLAN.md", "git ls-files; 164-11-PLAN.md",
    "git ls-files; Phase 161 summary", "git ls-files; Phase 162 summary", "git ls-files; release-target ledger",
    "git ls-files; run 33002642359", "git ls-files; scripts/scheduled_control_evidence.sh"
  ]
  @locked_removal_evidence "D-08; sha256:331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e; Phase 162 scheduled-control proof"
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
          with {:ok, rows} <- parse_rows(row_lines),
               :ok <- ensure_unique_subjects(rows),
               :ok <- ensure_unique_stable_ids(rows) do
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
      unexpected = subjects |> MapSet.difference(required_subjects) |> MapSet.to_list() |> Enum.sort()

      cond do
        missing != [] -> {:error, {:missing_audited_subjects, missing}}
        unexpected != [] -> {:error, {:unexpected_audited_subjects, unexpected}}
        true -> ensure_tracked_subjects_exist(rows, repo_root)
      end
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

      row["kind"] not in @kinds ->
        {:error, {:invalid_kind, row["kind"]}}

      row["producer"] not in @producers ->
        {:error, {:invalid_producer, row["producer"]}}

      row["state"] not in @states ->
        {:error, {:invalid_state, row["state"]}}

      row["authority"] not in @authorities ->
        {:error, {:invalid_authority, row["authority"]}}

      row["reproducibility"] not in @reproducibility ->
        {:error, {:invalid_reproducibility, row["reproducibility"]}}

      row["durable_consumer"] not in @durable_consumers ->
        {:error, {:invalid_durable_consumer, row["durable_consumer"]}}

      row["currentness"] == "stale" and row["disposition"] not in ~w(update archive remove) ->
        {:error, {:stale_without_outcome, row["subject"]}}

      not valid_kind_relationship?(row) ->
        {:error, {:invalid_kind_relationship, row["subject"]}}

      not valid_evidence?(row) ->
        {:error, {:invalid_evidence, row["subject"]}}

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

  defp ensure_unique_stable_ids(rows) do
    case Enum.find(rows, fn row -> Enum.count(rows, &(&1["stable_id"] == row["stable_id"])) > 1 end) do
      nil -> :ok
      row -> {:error, {:duplicate_stable_id, row["stable_id"]}}
    end
  end

  defp valid_kind_relationship?(%{"kind" => "ignore-rule"} = row) do
    Regex.match?(~r/^I-\d{3}$/, row["stable_id"]) and row["state"] == "ignored" and
      row["currentness"] == "current" and row["disposition"] == "ignore" and
      String.starts_with?(row["subject"], "ignore:#{row["authority"]}:")
  end

  defp valid_kind_relationship?(%{"kind" => "generated-output"} = row) do
    row["stable_id"] == "D-08" and row["subject"] == "scheduled-control-sweep.json" and
      row["state"] == "untracked" and row["currentness"] == "stale" and
      row["disposition"] == "remove" and row["authority"] == "D-08"
  end

  defp valid_kind_relationship?(row) do
    Regex.match?(~r/^[MP]-\d{2}$/, row["stable_id"]) and row["state"] == "tracked" and
      row["currentness"] in ~w(current historical) and row["disposition"] == "retain"
  end

  defp valid_evidence?(%{"kind" => "ignore-rule"} = row),
    do: String.starts_with?(row["evidence"], row["authority"] <> " rule")

  defp valid_evidence?(%{"kind" => "generated-output"} = row),
    do: row["evidence"] == @locked_removal_evidence

  defp valid_evidence?(row), do: row["evidence"] in @tracked_evidence

  defp ensure_tracked_subjects_exist(rows, repo_root) do
    case Enum.find(rows, fn row ->
           row["state"] == "tracked" and not File.regular?(Path.join(repo_root, row["subject"]))
         end) do
      nil -> :ok
      row -> {:error, {:tracked_subject_missing, row["subject"]}}
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
