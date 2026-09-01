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
    "GSD phase lifecycle",
    "GSD project extension loader",
    "GSD runtime state producer",
    "GitHub scheduled-control registry",
    "Phase 161 preservation audit",
    "Phase 161 workspace audit",
    "Phase 162 protected release recovery",
    "Phase 162 scheduled control audit",
    "Phase 162 verification",
    "Phase 163 protected CI audit",
    "Phase 163 verifier",
    "Phase 164 closeout plan",
    "Phase 164 disposition audit",
    "Phase 164 finalization boundary",
    "Phase 164 maintainer reconciliation",
    "Phase 164 package compatibility reconciliation",
    "Phase 164 repository truth contract",
    "Phase 164 shared ledger validation",
    "Phase 164 verifier",
    "mix mailglass.publish.check",
    "scripts/release_policy.exs",
    "scripts/scheduled_control_evidence.sh sweep (content shape only; no root-path producer)",
    "scripts/verify_published_release.sh",
    "shared project tooling producer"
  ]
  @authorities [
    ".gitignore",
    "D-05 through D-12",
    "D-07 and D-09",
    "D-08",
    "D-09 and D-10",
    "D-09 through D-11",
    "D-09 through D-12",
    "D-11",
    "Phase 161 evidence contract",
    "Phase 162 release authority",
    "Phase 162 requirement verification",
    "Phase 162 scheduled-control contract",
    "Phase 163 exact protected run",
    "Phase 163 requirement verification",
    "Phase 164 verification authority",
    "admin package manifest compatibility",
    "current executable authority projection",
    "executable scheduled-control contract",
    "inbound package manifest compatibility",
    "mailglass_admin/.gitignore",
    "mailglass_inbound/.gitignore",
    "maintainer release contract",
    "manifest-derived docs contract",
    "package content contract",
    "package manifest compatibility",
    "protected release policy",
    "published package verification",
    "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore",
    "test/example/.gitignore"
  ]
  @reproducibility [
    "captured from exact event run and workflow identities",
    "captured from exact protected run and SHA",
    "captured from immutable Git facts",
    "captured from protected GitHub and Git facts",
    "derived from Git graph and content",
    "derived from exact protected evidence",
    "derived from tracked evidence",
    "regenerable advisory session claim",
    "regenerable extension-local state",
    "regenerable from audited Git state",
    "regenerable from authorized evidence",
    "regenerable from exact main state",
    "regenerable from extension source",
    "regenerable from immutable package facts",
    "regenerable from package source",
    "regenerable from plan source",
    "regenerable from protected GitHub evidence",
    "regenerable from repository source",
    "regenerable from settled lifecycle contract",
    "regenerable from source",
    "regenerable from the scheduled-control evidence workflow",
    "regenerable from tracked verification process",
    "regenerable machine-local output",
    "reproducible from manifests",
    "reproducible from release controls",
    "reproducible from repository configuration",
    "reproducible from source",
    "reproducible loader boundary"
  ]
  @durable_consumers [
    "GSD project extension loader",
    "GSD runtime and extension boundary",
    "Phase 164 closeout",
    "Phase 164 closeout contract",
    "adopter documentation",
    "closeout CI identity validation",
    "closeout provenance",
    "closeout repository truth gate",
    "closeout scheduled evidence validation",
    "finalize-phase extension boundary",
    "finalize-phase extension dispatcher",
    "finalize-phase stable-porcelain guard",
    "maintainer closeout reader",
    "maintainer finalization command",
    "maintainer provenance",
    "maintainer release gate",
    "mix test closeout contract",
    "mix test documentation gate",
    "mix test maintainer guidance gate",
    "mix test repository truth gate",
    "mix test scheduled evidence gate",
    "none",
    "package release verification",
    "post-completion operational proof",
    "protected release guidance",
    "publish contract tests",
    "rerunnable closeout report",
    "scheduled evidence scripts and workflow",
    "test fixture allowlist",
    "workspace preservation verification"
  ]
  @tracked_evidence [
    "164-02-PLAN.md",
    "164-03-PLAN.md",
    "164-04-PLAN.md",
    "164-05-PLAN.md",
    "164-08-PLAN.md",
    "git ls-files .planning/publish",
    "git ls-files; 164-08-PLAN.md",
    "git ls-files; 164-11-PLAN.md",
    "git ls-files; Phase 161 summary",
    "git ls-files; Phase 162 summary",
    "git ls-files; release-target ledger",
    "git ls-files; run 33002642359",
    "git ls-files; scripts/scheduled_control_evidence.sh"
  ]
  @canonical_relationship_fields [
    "stable_id",
    "kind",
    "producer",
    "state",
    "authority",
    "reproducibility",
    "currentness",
    "durable_consumer",
    "evidence",
    "disposition"
  ]
  @canonical_relationship_sha256 %{
    "scheduled-control-sweep.json" =>
      "95c0c3276cdc09e566b11946520967fe3b95c8c078b39b45782b26ddc636d5eb",
    ".planning/release-target.json" =>
      "c129e0eec2da406b905f048886a063ba822ae44a0a00cfeb89b347cb22ceaa58",
    ".planning/publish/mailglass-publish-summary.json" =>
      "d1e911daa8070253248440d58a1ad51730cbc47632c74cdc6f748bd54b2cfaa5",
    ".planning/publish/mailglass_admin-publish-summary.json" =>
      "172e44a44e6fcc9c566cad4bdd2765a1160203307a90ce62c990f73cdb832f7b",
    ".planning/publish/mailglass_inbound-publish-summary.json" =>
      "3c7311ed1e2ef402d719d233bee06d40fd379d34189350c1b727bdaa4bbcc66d",
    ".planning/publish/mailglass-files.expected" =>
      "267182797cf675b3ac8186647821fb44d2743dc802d03223492118d2471b9656",
    ".planning/publish/mailglass_admin-files.expected" =>
      "9fd00a303ee6f16a4336e9595b55e95a9ce738131dc6bc663b399b6160e684a6",
    ".planning/publish/mailglass_inbound-files.expected" =>
      "ccf745941f7e19fd90640abc89dc79f59f1c6cd4e69b5e1a13029247e0b22a94",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md" =>
      "f0d8f394416c7dceb5e5c1af7e6cb3fd544b6a539a247a04a57251adc80f2b07",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv" =>
      "4714747fa923317db113afca67e0acecaf9a87380494e31152ea256d02caadfd",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md" =>
      "fca8d2fa37933787cf249f1249af5ed3a82862359b07a580bef7a8608038dec1",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md" =>
      "3d579a04554b7b2d731a95ca0557434cac95ff8bef77eeec8a2bcbf9c3025ce1",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md" =>
      "1872b84c67030e849ad735b420ecc4f9e84df72d70a923a0a7c4a2fbef4a2ed6",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md" =>
      "6a62e88c22c1562a93b90299207323c1d6cb2a10f6f301bf4e1b9a4680a7044d",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md" =>
      "156c8793a482b4f57873c34a742c9a848f8aa30f926e0d8c32896df573c96320",
    ".github/scheduled-controls.json" =>
      "9f1688cfc0524ae39fc8fdb66475f95a424a247fa45bc6f0c5dc2d7b2d5fd727",
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv" =>
      "2ffcb7e7dcef97d8fe0b3a0b35a238e206f601d92d5ae64f436c3667d9df3ddc",
    "test/scripts/phase_164_repository_truth_test.exs" =>
      "eb2511792697f86796724d89872fcd20064645ab6595dabced6879a2f609e1fa",
    "MAINTAINING.md" => "16fdbf3f0265a67bcfcd5e5482bf89ad972ea2d9bb957535f84a59126a16cf3a",
    "test/mailglass/publish/maintaining_release_gate_contract_test.exs" =>
      "472d04f71e60a2e4c7bc5c036d9b86f7a0e6538101834b268cb1ddbe9eb463a7",
    "README.md" => "0942020b0f64a8103d4100a91461295d1f1b22430da5763562d0ffc265e4057a",
    "mailglass_admin/README.md" =>
      "5b850e2cdf8249d1e4066ab30d2184a26ace72a0fef9f0f12cc2fbce7f9462db",
    "mailglass_inbound/README.md" =>
      "458b030831a014296505fc1cc9ea5b4e32729694bb02546e5c3c78f1c12ca804",
    "test/mailglass/docs_contract_test.exs" =>
      "d96bd664afccfc94812c38335f345e040c1ab6a1df33c89328a4309ad86a8821",
    "scripts/closeout_repository_truth.sh" =>
      "77facce62c361cc1fcf11c81b5d032383cd289fe6b339e45b08d5c6586e27f06",
    "test/scripts/phase_164_closeout_test.exs" =>
      "36449c59a7431d98d62706f93081ca1b3992f49fbf3ef3e3cc59512d56748dba",
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md" =>
      "e378c14a37c9610cf87b594ff8be6360e126a62cdbef9674eb4ae5575164d878",
    "scripts/validate_repository_truth.exs" =>
      "9d1e6e8f85891907277d87f427d52a54dcb501803d683f779a4dfa22591b37c2",
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-VERIFICATION.md" =>
      "37abe2db9ac0edbab5543e224cf410f528a6d86e6b541b34e70ba82aa9162312",
    ".gitignore" => "52c7aed7a0eaaf139bec59b33cca9e74a8ffda7ff0ec140512f1b5559d362f8a",
    ".gsd/extensions/finalize-phase/extension-manifest.json" =>
      "9a64278b3ac905ea43e5f12a3bd19c6f40f1fa6b22b04945e6aebae18f0649ce",
    ".gsd/extensions/finalize-phase/index.ts" =>
      "ede122a47d9b6cd21802339810be80891a56873e54f3541612814b9c20eb2649",
    "scripts/finalize_phase_164.sh" =>
      "304eaf03834cedf640215a9e8f7777f8d5779ac1adf7d74262978ac7613c631f",
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh" =>
      "7351a41c9f8e820203b2d70c4272134f2378859b6104100bc2e6c20524bb93bd",
    ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md" =>
      "7acb43cf5623bc0ae23be9c43aae52e49b61b6b08b7b70cedbe91784a8bab2cb",
    "scripts/ci_monitor.cjs" => "2a886eaba7c246c5461e915f5199ae1cff89fc735a7c82cd5fec171a12951c6f",
    "scripts/scheduled_control_evidence.sh" =>
      "83583ea9347f0f816dfa071ec5ae3677411cf1dc03fbcc410a2940c63954edcd",
    "test/scripts/scheduled_control_evidence_test.exs" =>
      "345fd03d1a3a3120a44c71f21432b4f758c032c9ad7c9df28b46a0bd8c232003"
  }
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

      unexpected =
        subjects |> MapSet.difference(required_subjects) |> MapSet.to_list() |> Enum.sort()

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

      not valid_canonical_relationship?(row) ->
        {:error, {:invalid_canonical_relationship, row["subject"]}}

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

  defp valid_canonical_relationship?(%{"kind" => "ignore-rule"}), do: true

  defp valid_canonical_relationship?(row) do
    case @canonical_relationship_sha256[row["subject"]] do
      nil ->
        true

      expected_sha256 ->
        actual_sha256 =
          row
          |> then(&Enum.map_join(@canonical_relationship_fields, <<0>>, fn field -> &1[field] end))
          |> then(&:crypto.hash(:sha256, &1))
          |> Base.encode16(case: :lower)

        actual_sha256 == expected_sha256
    end
  end

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
