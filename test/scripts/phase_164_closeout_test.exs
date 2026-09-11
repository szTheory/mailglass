defmodule Mailglass.Scripts.Phase164CloseoutTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/closeout_repository_truth.sh")
  @extension Path.join(@repo_root, ".gsd/extensions/finalize-phase/index.ts")
  @immutable_loader Path.join(@repo_root, "scripts/mailglass_finalize_phase_loader.mjs")
  @installed_loader "/Users/jon/.local/bin/mailglass-finalize-phase"
  @install_approval "/Users/jon/.local/share/mailglass/checkpoints/164-27-install-approval.env"
  @installation_source_oid "2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97"
  @installed_loader_sha256 "0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e"
  @install_approval_tuple %{
    "record_version" => "1",
    "phase_plan" => "164-27",
    "installation_source_oid" => @installation_source_oid,
    "source_sha256" => @installed_loader_sha256,
    "destination" => @installed_loader,
    "install_mode" => "0500",
    "node_executable" => "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node",
    "git_executable" => "/opt/homebrew/Cellar/git/2.41.0/bin/git",
    "bash_executable" => "/opt/homebrew/Cellar/bash/5.2.37/bin/bash",
    "gh_executable" => "/opt/homebrew/Cellar/gh/2.95.0/bin/gh",
    "jq_executable" => "/usr/bin/jq",
    "mix_executable" => "/Users/jon/.asdf/shims/mix",
    "elixir_executable" => "/Users/jon/.asdf/shims/elixir",
    "prior_approval_sha256" => "c9750e8becddd7b08ce27b2c6267b5172c1f25954d0d1b5ef9e39f04a909c862",
    "prior_sha256" => "ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9",
    "prior_mode" => "0500",
    "prior_stat_identity" => "16777229:267228421:501:20",
    "rollback_path" =>
      "/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9",
    "approval_status" => "approved"
  }
  @manifest Path.join(
              @repo_root,
              ".gsd/extensions/finalize-phase/extension-manifest.json"
            )
  @finalizer Path.join(@repo_root, "scripts/finalize_phase_164.sh")
  @scheduled_registry Path.join(@repo_root, ".github/scheduled-controls.json")
  @closeout_contract Path.join(
                       @repo_root,
                       ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md"
                     )
  @finalization_contract Path.join(
                           @repo_root,
                           ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md"
                         )
  @ledger Path.join(
            @repo_root,
            ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
          )
  @transitive_executables [
    "scripts/closeout_repository_truth.sh",
    "scripts/verify_workspace_evidence.sh",
    "scripts/validate_repository_truth.exs",
    "scripts/ci_monitor.cjs",
    "scripts/scheduled_control_evidence.sh"
  ]
  @transitive_data [
    ".github/scheduled-controls.json",
    ".planning/phases/164-fixture/164-TRUTH-DISPOSITION.tsv",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md",
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv",
    ".planning/phases/164-fixture/164-VERIFICATION.md",
    ".planning/phases/164-fixture/164-VALIDATION.md",
    ".planning/phases/164-fixture/164-FINALIZATION.md",
    ".planning/phases/164-fixture/164-01-PLAN.md",
    ".planning/phases/164-fixture/164-01-SUMMARY.md",
    ".planning/ROADMAP.md",
    ".planning/REQUIREMENTS.md",
    ".gitignore",
    "mailglass_admin/.gitignore",
    "mailglass_inbound/.gitignore",
    "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore",
    "test/example/.gitignore",
    ".planning/release-target.json",
    ".planning/publish/core.json",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md",
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md",
    ".planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md"
  ]

  test "required and controlled-host aliases keep distinct non-vacuous authority" do
    aliases = Mix.Project.config()[:aliases]

    assert Keyword.fetch!(aliases, :"verify.ci_lane_contract") == [
             "test test/scripts/ --exclude phase_164_installed_production_boundary --warnings-as-errors"
           ]

    assert Keyword.fetch!(aliases, :"verify.phase_164.installed_boundary") == [
             "test test/scripts/phase_164_closeout_test.exs --only phase_164_installed_production_boundary --warnings-as-errors"
           ]

    source = File.read!(__ENV__.file)

    installed_block =
      source
      |> String.split(~s(describe "phase 164 installed production boundary" do))
      |> List.last()
      |> String.split(~s(\n  test "owned sibling cleanup), parts: 2)
      |> List.first()

    assert installed_block =~ "@describetag :phase_164_installed_production_boundary"
    assert Regex.scan(~r/^    test \"/m, installed_block) != []
    refute installed_block =~ "@tag :skip"
    refute installed_block =~ "if File.exists?(@installed_loader)"
    refute installed_block =~ "if File.regular?(@installed_loader)"
  end

  test "rejects a sibling checkout and a foreign symlink before component collection" do
    root = temporary_root!()
    sibling_owner = allocate_owned_sibling!("disposable")
    sibling = sibling_owner.path

    on_exit(fn ->
      File.rm_rf!(root)
      cleanup_owned_sibling!(sibling_owner)
    end)

    link = Path.join(root, "mailglass")
    File.ln_s!(sibling, link)

    for repo <- [sibling, link] do
      marker = Path.join(root, "mix-called-#{System.unique_integer([:positive])}")
      output = Path.join(root, "outside/report.json")

      {_, status} = run(repo, @ledger, output, marker)
      assert status != 0
      refute File.exists?(marker)
      refute File.exists?(output)
    end
  end

  test "rejects copied and arbitrary ledgers before component collection" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    copied = Path.join(root, "complete-copy.tsv")
    arbitrary = Path.join(root, "one-row.tsv")
    File.cp!(@ledger, copied)

    File.write!(
      arbitrary,
      header() <>
        "\nD-01\tproof\tproof\tproducer\ttracked\tauthority\treproducible\tcurrent\tconsumer\tevidence\tretain\trationale\n"
    )

    for ledger <- [copied, arbitrary] do
      marker = Path.join(root, "mix-called-#{System.unique_integer([:positive])}")
      output = Path.join(root, "outside/report.json")

      {_, status} = run(@repo_root, ledger, output, marker)
      assert status != 0
      refute File.exists?(marker)
      refute File.exists?(output)
    end
  end

  test "the shared validator rejects malformed currentness, stale retain, missing subjects, and header-only ledgers" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    contents = File.read!(@ledger)

    mutations = [
      String.replace(contents, "\tcurrent\t", "\tcurrent-forged\t", global: false),
      String.replace(contents, "\tcurrent\t", "\tstale\t", global: false),
      header() <> "\n",
      contents |> String.split("\n") |> List.delete_at(2) |> Enum.join("\n")
    ]

    for {contents, index} <- Enum.with_index(mutations) do
      ledger = Path.join(root, "invalid-#{index}.tsv")
      File.write!(ledger, contents)

      {_, status} =
        System.cmd(
          "elixir",
          ["scripts/validate_repository_truth.exs", "--repo", @repo_root, "--ledger", ledger],
          cd: @repo_root,
          stderr_to_stdout: true
        )

      assert status != 0
    end
  end

  test "rejects non-ignored and lexical-prefix output paths before write" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    filename = "closeout-report-#{System.unique_integer([:positive])}.json"
    tracked = Path.join(@repo_root, filename)
    prefix_escape = Path.join(@repo_root <> "-other", filename)

    for output <- [tracked, prefix_escape] do
      marker = Path.join(root, "mix-called-#{System.unique_integer([:positive])}")
      {_, status} = run(@repo_root, @ledger, output, marker)
      assert status != 0
      refute File.exists?(marker)
      refute File.exists?(output)
    end
  end

  test "does not follow a pre-existing components symlink while collecting evidence" do
    root = temporary_root!()
    output_dir = Path.join(@repo_root, "tmp/phase-164-closeout-symlink-test")
    external = Path.join(root, "external")
    marker = Path.join(root, "mix-called")
    sentinel = Path.join(external, "git.source")

    on_exit(fn ->
      File.rm_rf!(root)
      File.rm_rf!(output_dir)
    end)

    File.mkdir_p!(external)
    File.write!(sentinel, "do-not-overwrite")
    File.mkdir_p!(output_dir)
    File.ln_s!(external, Path.join(output_dir, "components"))

    {_output, status} =
      run(@repo_root, @ledger, Path.join(output_dir, "report.json"), marker)

    assert status != 0
    assert File.read!(sentinel) == "do-not-overwrite"
  end

  test "uses the canonical ledger validator and samples porcelain after report writes" do
    source = File.read!(@script)
    assert source =~ "canonical_repo=/Users/jon/projects/mailglass"
    assert source =~ "validate_repository_truth.exs"
    assert source =~ "--authority-root \"$authority_root\""
    assert source =~ "--ledger \"$authority_ledger\""
    assert source =~ "git -C \"$repo\" check-ignore"
    assert source =~ "status --porcelain=v1 --untracked-files=all"

    assert source =~ "write_report\nfinal_porcelain=$(stable_porcelain)"
  end

  test "aggregate report preserves component evidence and applies fail-closed precedence" do
    valid_block = %{
      "status" => "blocked",
      "reason" => "policy_blocked",
      "checks" => [
        %{
          "status" => "blocked",
          "message" => "expected policy block",
          "details" => %{"policy" => "fixture"}
        }
      ]
    }

    cases = [
      {"malformed", "{malformed", 1, "cannot-check", "closeout_cannot-check", "cannot-check"},
      {"pending", Jason.encode!(%{"status" => "pending", "reason" => "waiting"}), 1, "pending",
       "closeout_pending", "pending"},
      {"policy-blocked", Jason.encode!(valid_block), 1, "pass", "all_authorities_exact_and_current",
       "blocked"},
      {"all-pass", Jason.encode!(%{"status" => "pass", "reason" => "clean"}), 0, "pass",
       "all_authorities_exact_and_current", "pass"}
    ]

    for {name, hygiene_json, hygiene_exit, expected_status, expected_reason,
         expected_hygiene_status} <- cases do
      report = run_aggregate_fixture!(name, hygiene_json, hygiene_exit)

      assert report["status"] == expected_status
      assert report["reason"] == expected_reason
      assert report["components"]["hygiene"]["status"] == expected_hygiene_status

      for component <- ["git", "workspace", "ledger", "ci", "scheduled"] do
        assert report["components"][component]["status"] == "pass"
      end

      for component <- ["git", "hygiene", "workspace", "ledger", "ci", "scheduled"] do
        source = report["components"][component]["source"]
        assert is_binary(source) and source != ""
        assert File.regular?(source), "expected persisted source for #{name}/#{component}"
      end

      assert File.read!(report["components"]["hygiene"]["source"]) == hygiene_json
      cleanup_aggregate_fixture!(report)
    end
  end

  test "durable closeout guidance matches the enforced canonical volatile-report boundary" do
    contract = File.read!(@closeout_contract)
    normalized = Regex.replace(~r/\s+/, contract, " ")

    assert contract =~ "--repo /Users/jon/projects/mailglass"

    assert contract =~
             "--ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"

    assert contract =~ "--ci-run-id <exact-current-main-ci-run-id>"
    assert contract =~ "tmp/phase-164-closeout/report.json"
    assert contract =~ "enforced identities, not examples"
    assert contract =~ "Arbitrary checkouts, copied or equivalent ledgers"
    assert contract =~ "root `/tmp/` ignore rule"
    assert normalized =~ "shared full-ledger validator"
    assert normalized =~ "Stable porcelain is sampled before collection"
    assert normalized =~ "after every component and final-report write"
    assert contract =~ "volatile, untracked runtime evidence"

    for non_pass <- ["pending", "cannot-check", "stale", "malformed", "mismatched"] do
      assert contract =~ non_pass
    end
  end

  @tag :phase_164_installed_boundary
  test "finalization guidance keeps pre-verification and terminal proof non-circular" do
    contract = File.read!(@finalization_contract)
    normalized = Regex.replace(~r/\s+/, contract, " ")

    assert contract =~
             "/Users/jon/.local/bin/mailglass-finalize-phase 164 --pre-verification"

    assert contract =~ "scripts/mailglass_finalize_phase_loader.mjs"
    assert contract =~ "Plan 164-23"
    assert normalized =~ "installed loader is outside checkout evaluation"
    assert normalized =~ "captured repository OID"
    assert normalized =~ "immediately before Bash dispatch"
    assert contract =~ "ordinary phase verifier"
    assert normalized =~ "before `phase.complete` writes tracked completion metadata"
    assert contract =~ "/Users/jon/.local/bin/mailglass-finalize-phase 164"
    refute contract =~ "`/finalize-phase 164"
    assert contract =~ "After the normal verifier has passed"
    assert contract =~ "status: passed"
    assert contract =~ "writes only ignored"
    assert contract =~ "No summary, planning update, commit, push, merge"
    assert contract =~ "CI must be attempt 1"
    assert normalized =~ "Every registered scheduled control must be attempt 1"
    assert normalized =~ "A HEAD change or any stable-porcelain entry"
  end

  test "accepts authoritative per-control freshness and rejects identity or provenance mutations" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    sha = String.duplicate("a", 40)
    report = authoritative_sweep(sha)
    report_path = Path.join(root, "scheduled-sweep.json")

    File.write!(report_path, Jason.encode!(report))
    assert scheduled_report_acceptable?(report_path, sha)

    mutations = [
      put_in(report, ["expected_main_sha"], String.duplicate("b", 40)),
      put_in(
        report,
        ["controls", Access.at(0), "source_run", "head_sha"],
        String.duplicate("b", 40)
      ),
      put_in(report, ["controls", Access.at(0), "source_run", "event"], "workflow_dispatch"),
      put_in(report, ["controls", Access.at(0), "source_run", "attempt"], 2),
      put_in(report, ["controls", Access.at(0), "source_run", "head_branch"], "feature"),
      put_in(report, ["controls", Access.at(0), "source_run", "status"], "in_progress"),
      put_in(
        report,
        ["controls", Access.at(0), "result", "workflow_sha"],
        String.duplicate("b", 40)
      ),
      put_in(report, ["controls", Access.at(0), "evidence_valid"], false),
      put_in(report, ["controls", Access.at(0), "result", "status"], "pending"),
      put_in(report, ["controls", Access.at(2), "result", "payload_sha256"], ""),
      put_in(report, ["status"], "pending"),
      put_in(report, ["status"], "cannot-check"),
      put_in(report, ["evidence_valid"], false)
    ]

    for {mutation, index} <- Enum.with_index(mutations) do
      mutation_path = Path.join(root, "scheduled-sweep-#{index}.json")
      File.write!(mutation_path, Jason.encode!(mutation))
      refute scheduled_report_acceptable?(mutation_path, sha)
    end
  end

  test "rejects incomplete or fabricated scheduled-control sweep provenance" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    sha = String.duplicate("a", 40)
    report = authoritative_sweep(sha)

    mutations = [
      put_in(report, ["controls"], Enum.take(report["controls"], 1)),
      put_in(report, ["controls"], [hd(report["controls"]) | report["controls"]]),
      put_in(report, ["controls", Access.at(0), "source_run", "name"], "foreign-workflow"),
      put_in(report, ["controls", Access.at(0), "source_run", "id"], "0"),
      put_in(report, ["controls", Access.at(0), "result", "reason"], ""),
      put_in(report, ["controls", Access.at(0), "result", "payload_sha256"], "fabricated"),
      put_in(
        report,
        ["controls", Access.at(0), "result", "artifact_archive_digest"],
        "sha256:fabricated"
      ),
      put_in(report, ["status"], "blocked")
    ]

    for {mutation, index} <- Enum.with_index(mutations) do
      path = Path.join(root, "scheduled-incomplete-#{index}.json")
      File.write!(path, Jason.encode!(mutation))
      refute scheduled_report_acceptable?(path, sha)
    end
  end

  test "finalizer selects only an exact attempt-one normal push CI run without caller identity" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    sha = String.duplicate("a", 40)
    runs = Path.join(root, "runs.json")

    File.write!(
      runs,
      Jason.encode!([
        ci_run(12, sha, 2, "2026-08-28T18:00:00Z"),
        ci_run(11, sha, 1, "2026-08-28T17:00:00Z"),
        %{ci_run(13, sha, 1, "2026-08-28T19:00:00Z") | "event" => "workflow_dispatch"},
        ci_run(10, String.duplicate("b", 40), 1, "2026-08-28T16:00:00Z")
      ])
    )

    assert {"11\n", 0} = source_finalizer(~s(select_ci_run_id "$2" "$3"), [runs, sha])

    assert {_, status} =
             source_finalizer(~s(select_ci_run_id "$2" "$3"), [runs, String.duplicate("c", 40)])

    assert status != 0

    source = File.read!(@finalizer)
    assert source =~ "usage: $0 REPO AUTHORITY_ROOT [--pre-verification]"
    refute source =~ ~r/ci_run_id=.*\$\{[123]:-/
    refute source =~ ~r/gh\s+workflow\s+(run|rerun)/
    refute source =~ ~r/gh\s+run\s+rerun/
  end

  test "finalizer accepts only the authoritative origin and GitHub repository identity" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    {_, 0} = System.cmd("git", ["init", "-q", root])

    {_, 0} =
      System.cmd("git", [
        "-C",
        root,
        "remote",
        "add",
        "origin",
        "git@github.com:szTheory/mailglass.git"
      ])

    command = ~s(repository_identity_is_authoritative "$2" "$3")
    assert {_, 0} = source_finalizer(command, [root, "szTheory/mailglass"])

    assert {_, status} =
             source_finalizer("GH_HOST=attacker.example " <> command, [root, "szTheory/mailglass"])

    assert status != 0

    {_, 0} =
      System.cmd(
        "git",
        ["-C", root, "remote", "set-url", "origin", "https://github.com/attacker/mailglass.git"]
      )

    assert {_, status} = source_finalizer(command, [root, "szTheory/mailglass"])
    assert status != 0

    {_, 0} =
      System.cmd(
        "git",
        ["-C", root, "remote", "set-url", "origin", "https://github.com/szTheory/mailglass.git"]
      )

    assert {_, status} = source_finalizer(command, [root, "attacker/mailglass"])
    assert status != 0
  end

  test "finalizer separates pre-verification and terminal tracked-state gates" do
    source = File.read!(@finalizer)

    assert source =~ "--pre-verification"
    assert source =~ "pre-verification-inputs.json"
    assert source =~ "pre-verification-report.json"
    assert source =~ "finalization-inputs.json"
    assert source =~ "164-VERIFICATION.md"
    assert source =~ "TRTH-01"
    assert source =~ "status --porcelain=v1 --untracked-files=all"
    assert source =~ "git fetch origin main"
    assert source =~ "components.ci.source"
    assert source =~ "components.scheduled.source"
    assert source =~ "source_run.attempt == 1"
  end

  test "pre-verification requires summaries through Plan 13 before collection" do
    root = temporary_root!()
    phase_dir = Path.join(root, "phase")
    marker = Path.join(root, "evidence-collected")
    on_exit(fn -> File.rm_rf!(root) end)
    File.mkdir_p!(phase_dir)

    for plan <- 1..13 do
      number = plan |> Integer.to_string() |> String.pad_leading(2, "0")
      File.write!(Path.join(phase_dir, "164-#{number}-SUMMARY.md"), "summary\n")
    end

    command = ~s(require_pre_verification_state "$2" "$3" && touch "$4")
    assert {_, 0} = source_finalizer(command, [root, phase_dir, marker])
    assert File.regular?(marker)

    File.rm!(marker)
    File.rm!(Path.join(phase_dir, "164-13-SUMMARY.md"))
    assert {output, status} = source_finalizer(command, [root, phase_dir, marker])
    assert status != 0
    assert output =~ "missing implementation summary 164-13-SUMMARY.md"
    refute File.exists?(marker)
  end

  test "terminal verifier authority is bound to an ancestor implementation SHA and exact metadata history" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    fixture = terminal_fixture!(Path.join(root, "accepted"))
    assert {_, 0} = terminal_state(fixture.repo, fixture.phase_dir)

    for value <- [nil, "ABC", String.duplicate("f", 40)] do
      write_verification!(fixture.phase_dir, value)
      git!(fixture.repo, ["add", "."])
      git!(fixture.repo, ["commit", "-q", "-m", "verification mutation"])
      assert {_, status} = terminal_state(fixture.repo, fixture.phase_dir)
      assert status != 0
    end

    non_ancestor = terminal_fixture!(Path.join(root, "non-ancestor"))
    git!(non_ancestor.repo, ["checkout", "-q", "--orphan", "unrelated"])
    File.write!(Path.join(non_ancestor.repo, "unrelated"), "history")
    git!(non_ancestor.repo, ["add", "unrelated"])
    git!(non_ancestor.repo, ["commit", "-q", "-m", "unrelated"])
    unrelated_sha = non_ancestor.repo |> git!(["rev-parse", "HEAD"]) |> String.trim()
    git!(non_ancestor.repo, ["checkout", "-q", "main"])
    write_verification!(non_ancestor.phase_dir, unrelated_sha)
    git!(non_ancestor.repo, ["commit", "-qam", "point at unrelated history"])
    assert {_, status} = terminal_state(non_ancestor.repo, non_ancestor.phase_dir)
    assert status != 0
  end

  test "terminal verifier rejects forbidden commits even when a later commit restores the tree" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    direct = terminal_fixture!(Path.join(root, "direct"))
    File.write!(Path.join(direct.repo, "scripts/finalize_phase_164.sh"), "changed")
    git!(direct.repo, ["add", "scripts/finalize_phase_164.sh"])
    git!(direct.repo, ["commit", "-q", "-m", "forbidden source"])
    assert {output, status} = terminal_state(direct.repo, direct.phase_dir)
    assert status != 0
    assert output =~ "outside completion metadata"

    reverted = terminal_fixture!(Path.join(root, "reverted"))
    source = Path.join(reverted.repo, "scripts/finalize_phase_164.sh")
    original = File.read!(source)
    File.write!(source, "changed")
    git!(reverted.repo, ["commit", "-qam", "forbidden source"])
    File.write!(source, original)
    git!(reverted.repo, ["commit", "-qam", "restore source"])
    assert {output, status} = terminal_state(reverted.repo, reverted.phase_dir)
    assert status != 0
    assert output =~ "outside completion metadata"
  end

  test "terminal lifecycle documents the verified SHA and first-parent per-commit allowlist" do
    finalization = File.read!(@finalization_contract)

    validation =
      File.read!(
        Path.join(
          @repo_root,
          ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md"
        )
      )

    for document <- [finalization, validation] do
      assert document =~ "verified_implementation_sha"
      assert document =~ "first-parent"
      assert document =~ "164-VERIFICATION.md"
      assert document =~ ".planning/ROADMAP.md"
      assert document =~ ".planning/REQUIREMENTS.md"
      assert document =~ ".planning/STATE.md"
    end

    assert validation =~ "164-15-01"
    assert validation =~ "T-164-53"

    assert validation =~
             "mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh"
  end

  test "finalizer re-fetches protected main and preserves non-pass evidence when it advances" do
    root = temporary_root!()
    remote = Path.join(root, "remote.git")
    seed = Path.join(root, "seed")
    checkout = Path.join(root, "checkout")
    on_exit(fn -> File.rm_rf!(root) end)

    git!(root, ["init", "-q", "--bare", remote])
    git!(root, ["init", "-q", "-b", "main", seed])
    File.write!(Path.join(seed, "tracked"), "a")
    git!(seed, ["add", "tracked"])
    git!(seed, ["commit", "-q", "-m", "a"])
    git!(seed, ["remote", "add", "origin", remote])
    git!(seed, ["push", "-q", "-u", "origin", "main"])
    git!(root, ["clone", "-q", "-b", "main", remote, checkout])
    sha = checkout |> git!(["rev-parse", "HEAD"]) |> String.trim()

    components = Path.join(root, "components")
    File.mkdir_p!(components)
    scheduled = Path.join(components, "scheduled.source")
    report = Path.join(root, "report.json")
    File.write!(scheduled, Jason.encode!(%{"expected_main_sha" => sha}))

    File.write!(
      report,
      Jason.encode!(%{
        "status" => "pass",
        "reason" => "all_authorities_exact_and_current",
        "components" => %{"scheduled" => %{"source" => scheduled}}
      })
    )

    command = ~s(revalidate_final_main "$2" "$3" "$4")
    assert {_, 0} = source_finalizer(command, [checkout, sha, report])

    File.write!(Path.join(seed, "tracked"), "b")
    git!(seed, ["commit", "-qam", "b"])
    git!(seed, ["push", "-q", "origin", "main"])

    assert {_, status} = source_finalizer(command, [checkout, sha, report])
    assert status != 0

    assert %{"status" => "blocked", "reason" => "protected_main_advanced"} =
             Jason.decode!(File.read!(report))
  end

  test "finalizer independently validates raw CI and registered scheduled provenance" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    components = Path.join(root, "components")
    File.mkdir_p!(components)
    sha = String.duplicate("a", 40)
    ci = Path.join(components, "ci.source")
    scheduled = Path.join(components, "scheduled.source")
    report = Path.join(root, "report.json")
    registry = Path.join(root, "registry.json")

    ci_payload = ci_run(77, sha, 1, "2026-08-28T17:00:00Z")
    File.write!(ci, Jason.encode!(ci_payload))
    File.write!(scheduled, Jason.encode!(authoritative_sweep(sha)))

    File.write!(
      report,
      Jason.encode!(%{
        "components" => %{
          "ci" => %{"source" => ci},
          "scheduled" => %{"source" => scheduled}
        }
      })
    )

    File.write!(
      registry,
      Jason.encode!(%{
        "controls" =>
          Enum.map(["release-please", "repo-hygiene", "post-publish-smoke"], fn id ->
            %{"id" => id, "workflow_name" => id, "max_age_seconds" => 129_600}
          end)
      })
    )

    command = "raw_sources_are_acceptable \"$2\" \"$3\" \"$4\" \"$5\" \"$6\""
    assert {_, 0} = source_finalizer(command, [report, sha, root, registry, "77"])

    File.write!(ci, Jason.encode!(%{ci_payload | "attempt" => 2}))
    assert {_, status} = source_finalizer(command, [report, sha, root, registry, "77"])
    assert status != 0

    File.write!(ci, Jason.encode!(ci_payload))

    scheduled_payload = authoritative_sweep(sha)

    File.write!(
      scheduled,
      Jason.encode!(
        put_in(scheduled_payload, ["controls", Access.at(1), "source_run", "attempt"], 2)
      )
    )

    assert {_, status} = source_finalizer(command, [report, sha, root, registry, "77"])
    assert status != 0

    for updated_at <- [
          "not-an-iso8601-time",
          DateTime.utc_now()
          |> DateTime.add(86_400, :second)
          |> DateTime.truncate(:second)
          |> DateTime.to_iso8601(),
          DateTime.utc_now()
          |> DateTime.add(-129_601, :second)
          |> DateTime.truncate(:second)
          |> DateTime.to_iso8601()
        ] do
      mutated =
        authoritative_sweep(sha)
        |> put_in(["controls", Access.at(1), "source_run", "updated_at"], updated_at)

      File.write!(scheduled, Jason.encode!(mutated))
      assert {_, status} = source_finalizer(command, [report, sha, root, registry, "77"])
      assert status != 0
    end

    File.write!(scheduled, Jason.encode!(authoritative_sweep(sha)))
    assert {_, 0} = source_finalizer(command, [report, sha, root, registry, "77"])
  end

  test "finalizer rejects stale scheduled evidence despite an inflated ambient registry" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    components = Path.join(root, "components")
    File.mkdir_p!(components)
    sha = String.duplicate("a", 40)
    ci = Path.join(components, "ci.source")
    scheduled = Path.join(components, "scheduled.source")
    report = Path.join(root, "report.json")
    inflated_registry = Path.join(root, "inflated-registry.json")

    File.write!(ci, Jason.encode!(ci_run(77, sha, 1, "2026-08-28T17:00:00Z")))

    stale =
      authoritative_sweep(sha)
      |> put_in(
        ["controls", Access.at(0), "source_run", "updated_at"],
        DateTime.utc_now()
        |> DateTime.add(-14_400, :second)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()
      )

    File.write!(scheduled, Jason.encode!(stale))

    File.write!(
      report,
      Jason.encode!(%{
        "components" => %{
          "ci" => %{"source" => ci},
          "scheduled" => %{"source" => scheduled}
        }
      })
    )

    inflated =
      @scheduled_registry
      |> File.read!()
      |> Jason.decode!()
      |> update_in(["controls", Access.all(), "max_age_seconds"], fn _ -> 31_536_000 end)

    File.write!(inflated_registry, Jason.encode!(inflated))

    command =
      ~s(SCHEDULED_CONTROL_CONFIG="$7" raw_sources_are_acceptable "$2" "$3" "$4" "$5" "$6")

    assert {_, status} =
             source_finalizer(command, [
               report,
               sha,
               root,
               @scheduled_registry,
               "77",
               inflated_registry
             ])

    assert status != 0

    source = File.read!(@finalizer)
    assert source =~ ~s(SCHEDULED_CONTROL_CONFIG="$authority_root/$registry_rel")
  end

  describe "phase 164 gap closure" do
    @describetag :phase_164_gap_closure

    test "rejects alternate repository identities before evidence collection" do
      root = temporary_root!()
      disposable = Path.join(root, "clean-main")
      prefix_owner = allocate_owned_sibling!("gap")
      prefix_collision = prefix_owner.path
      foreign_target = Path.join(root, "foreign")
      foreign_link = Path.join(root, "foreign-link")

      on_exit(fn ->
        File.rm_rf!(root)
        cleanup_owned_sibling!(prefix_owner)
      end)

      git!(root, ["init", "-q", "-b", "main", disposable])
      File.write!(Path.join(disposable, "tracked"), "fixture")
      git!(disposable, ["add", "tracked"])
      git!(disposable, ["commit", "-q", "-m", "fixture"])
      File.mkdir_p!(foreign_target)
      File.ln_s!(foreign_target, foreign_link)

      for repo <- [disposable, prefix_collision, foreign_link] do
        marker = Path.join(root, "collector-#{System.unique_integer([:positive])}")
        output = Path.join(@repo_root, "tmp/phase-164-gap-repo/report.json")

        {_, status} = run(repo, @ledger, output, marker)
        assert status != 0
        refute File.exists?(marker)
        refute File.exists?(output)
      end
    end

    test "rejects alternate ledger identities and semantic ledger mutations" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      contents = File.read!(@ledger)

      fixtures = %{
        "copied-complete" => contents,
        "one-row" => header() <> "\n" <> (contents |> String.split("\n") |> Enum.at(1)) <> "\n",
        "missing-subject" => contents |> String.split("\n") |> List.delete_at(2) |> Enum.join("\n"),
        "malformed-currentness" =>
          String.replace(contents, "\tcurrent\t", "\tcurrent-forged\t", global: false),
        "stale-retain" => String.replace(contents, "\tcurrent\t", "\tstale\t", global: false)
      }

      for {name, fixture} <- fixtures do
        ledger = Path.join(root, "#{name}.tsv")
        marker = Path.join(root, "collector-#{name}")
        output = Path.join(@repo_root, "tmp/phase-164-gap-ledger/#{name}.json")
        File.write!(ledger, fixture)

        {_, closeout_status} = run(@repo_root, ledger, output, marker)
        assert closeout_status != 0
        refute File.exists?(marker)
        refute File.exists?(output)

        {_, validator_status} =
          System.cmd(
            "elixir",
            ["scripts/validate_repository_truth.exs", "--repo", @repo_root, "--ledger", ledger],
            cd: @repo_root,
            stderr_to_stdout: true
          )

        if name == "copied-complete",
          do: assert(validator_status == 0),
          else: assert(validator_status != 0)
      end
    end

    test "rejects hostile output destinations without changing an external sentinel" do
      root = temporary_root!()
      output_root = Path.join(@repo_root, "tmp/phase-164-gap-output")
      external = Path.join(root, "external")
      components_link = Path.join(output_root, "components")
      sentinel = Path.join(external, "sentinel")
      tracked_root = Path.join(@repo_root, "phase-164-gap-report.json")
      prefix_escape = Path.join(@repo_root <> "-outside", "report.json")
      non_ignored = Path.join(root, "report.json")

      on_exit(fn ->
        File.rm_rf!(root)
        File.rm_rf!(output_root)
      end)

      File.mkdir_p!(external)
      File.mkdir_p!(output_root)
      File.write!(sentinel, "unchanged")
      File.ln_s!(external, components_link)

      for output <- [
            tracked_root,
            prefix_escape,
            non_ignored,
            Path.join(components_link, "report.json")
          ] do
        marker = Path.join(root, "collector-#{System.unique_integer([:positive])}")
        {_, status} = run(@repo_root, @ledger, output, marker)
        assert status != 0
        refute File.exists?(marker)
        refute File.exists?(output)
        assert File.read!(sentinel) == "unchanged"
      end
    end

    test "late dirt after a component or first report write always wins over clean preflight" do
      for {name, dirty_after_status_call} <- [{"component", 2}, {"report", 8}] do
        report = run_late_dirt_fixture!(name, dirty_after_status_call)

        assert report["status"] == "blocked"
        assert report["reason"] == "closeout_blocked"
        assert report["components"]["git"]["status"] == "blocked"
        assert report["components"]["git"]["reason"] == "post_write_porcelain_dirty"
        assert File.regular?(report["dirt_sentinel"])

        cleanup_late_dirt_fixture!(report)
      end
    end
  end

  describe "phase 164 immutable loader" do
    @describetag :phase_164_immutable_loader

    @tag :phase_164_canonical_loader
    test "production loader owns the canonical repository and normalized origin identity" do
      source = File.read!(@immutable_loader)

      assert source =~ ~s(const CANONICAL_REPOSITORY = "/Users/jon/projects/mailglass")
      assert source =~ ~s(const EXPECTED_REPOSITORY = "szTheory/mailglass")
      assert source =~ "validateCanonicalRepository"
      refute source =~ ~S|git(process.cwd(), ["rev-parse", "--show-toplevel"])|
    end

    @tag :phase_164_loader_shell_terminal_contract
    test "loader and shell authorize exactly terminal pairs 01 through 28" do
      loader = File.read!(@immutable_loader)
      finalizer = File.read!(@finalizer)

      assert loader =~ "const TERMINAL_LAST_PLAN = 28"
      assert loader =~ "exact 01-28 PLAN/SUMMARY set"
      assert finalizer =~ "terminal_last_plan=28"
      assert finalizer =~ ~S|for plan in $(seq -w "$terminal_first_plan" "$terminal_last_plan")|
      assert finalizer =~ ~s(missing terminal plan 164-$plan-PLAN.md)
      assert finalizer =~ ~s(missing terminal summary 164-$plan-SUMMARY.md)
    end

    @tag :phase_164_trusted_toolchain
    test "loader pins validated tools and passes an allowlisted child environment" do
      loader = File.read!(@immutable_loader)
      finalizer = File.read!(@finalizer)

      assert String.starts_with?(loader, "#!/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node\n")
      assert loader =~ "validateTrustedToolchain"
      assert loader =~ "buildChildEnvironment"
      refute loader =~ "...process.env"
      assert loader =~ "MAILGLASS_GIT"
      assert loader =~ "MAILGLASS_BASH"

      for tool <- ~w(GIT GH JQ MIX NODE ELIXIR) do
        assert finalizer =~ ~s(\"${MAILGLASS_#{tool})
      end
    end

    @tag :phase_164_trusted_toolchain
    test "self-check rejects byte-identical loader bytes from unrelated history" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = immutable_loader_fixture!(Path.join(root, "unrelated-installation"))
      unrelated = Path.join(root, "unrelated")
      git!(root, ["init", "-q", "-b", "main", unrelated])
      unrelated_source = Path.join(unrelated, "scripts/mailglass_finalize_phase_loader.mjs")
      File.mkdir_p!(Path.dirname(unrelated_source))
      File.write!(unrelated_source, File.read!(fixture.installed))
      git!(unrelated, ["add", "."])
      git!(unrelated, ["commit", "-q", "-m", "unrelated identical loader"])
      unrelated_oid = unrelated |> git!(["rev-parse", "HEAD"]) |> String.trim()
      git!(fixture.repo, ["fetch", "-q", unrelated, unrelated_oid])

      {output, status} =
        invoke_immutable_loader(fixture, [
          "--self-check",
          "--repo",
          resolved_path!(fixture.repo),
          "--expected-source-oid",
          unrelated_oid
        ])

      assert status != 0
      assert output =~ "installation OID is not an ancestor"
    end

    @tag :phase_164_trusted_toolchain
    test "caller PATH cannot substitute any trusted finalization executable" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = immutable_loader_fixture!(Path.join(root, "forged-tools"))
      forged = Path.join(root, "forged-bin")
      File.mkdir_p!(forged)

      markers =
        for tool <- ~w(git bash gh jq mix node elixir), into: %{} do
          marker = Path.join(root, "#{tool}.marker")

          write_executable!(
            Path.join(forged, tool),
            "#!/bin/sh\ntouch #{inspect(marker)}\nexit 97\n"
          )

          {tool, marker}
        end

      {output, status} =
        invoke_immutable_loader(fixture, ["164", "--pre-verification"], [
          {"PATH", "#{forged}:#{System.fetch_env!("PATH")}"}
        ])

      assert status == 0, output
      assert File.regular?(fixture.marker)
      for {_tool, marker} <- markers, do: refute(File.exists?(marker))
    end

    test "dispatches committed bytes from one authority OID and rejects a moving HEAD" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)

      accepted = immutable_loader_fixture!(Path.join(root, "accepted"))
      {_, 0} = invoke_immutable_loader(accepted, ["164", "--pre-verification"])
      assert File.regular?(accepted.marker)
      assert File.read!(accepted.marker) =~ "--pre-verification"

      moving = immutable_loader_fixture!(Path.join(root, "moving"), move_head: true)

      {moving_output, moving_status} =
        invoke_immutable_loader(moving, ["164", "--pre-verification"], moving.env)

      assert moving_status == 0, moving_output
      assert File.regular?(moving.marker)
      refute File.exists?(moving.git_log)
    end

    test "checkout mutations cannot replace authenticated private execution bytes" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = immutable_loader_fixture!(Path.join(root, "hidden"))

      git!(fixture.repo, ["update-index", "--assume-unchanged", "--", fixture.downstream_relative])
      File.write!(fixture.downstream, hostile_script(fixture.hostile_marker))
      File.chmod!(fixture.downstream, 0o755)

      {_, 0} = invoke_immutable_loader(fixture, ["164", "--pre-verification"])
      assert File.regular?(fixture.marker)
      refute File.exists?(fixture.hostile_marker)
    end

    test "version and invalid invocations are bounded and never dispatch Bash" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = immutable_loader_fixture!(Path.join(root, "inspection"))

      assert {"mailglass-finalize-phase-loader 1\n", 0} =
               System.cmd(System.find_executable("node"), [fixture.installed, "--version"],
                 cd: Path.dirname(fixture.installed),
                 stderr_to_stdout: true
               )

      for args <- [[], ["165"], ["164", "--unknown"], ["--self-check"]] do
        {output, status} = invoke_immutable_loader(fixture, args)
        assert status != 0
        assert byte_size(output) <= 16_000
      end

      refute File.exists?(fixture.marker)
    end

    test "self-check binds external installed bytes to the installation OID and current source" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = immutable_loader_fixture!(Path.join(root, "self-check"))

      {output, 0} =
        invoke_immutable_loader(fixture, [
          "--self-check",
          "--repo",
          resolved_path!(fixture.repo),
          "--expected-source-oid",
          fixture.installation_oid
        ])

      assert output =~ "installation_oid=#{fixture.installation_oid}"
      assert output =~ "current_oid=#{fixture.current_oid}"
      assert output =~ "terminal_range=01-28"
      assert output =~ "mode=0500"
      refute File.exists?(fixture.marker)

      invalid = [
        String.slice(fixture.installation_oid, 0, 12),
        String.duplicate("f", 40)
      ]

      for oid <- invalid do
        {bad_output, status} =
          invoke_immutable_loader(fixture, [
            "--self-check",
            "--repo",
            resolved_path!(fixture.repo),
            "--expected-source-oid",
            oid
          ])

        assert status != 0
        assert byte_size(bad_output) <= 16_000
      end

      File.write!(Path.join(fixture.repo, "dirty"), "dirty\n")

      {dirty_output, dirty_status} =
        invoke_immutable_loader(fixture, [
          "--self-check",
          "--repo",
          resolved_path!(fixture.repo),
          "--expected-source-oid",
          fixture.installation_oid
        ])

      assert dirty_status != 0
      assert dirty_output =~ "repository is not clean"
      refute File.exists?(fixture.marker)
    end

    test "requires every exact PLAN and SUMMARY pair through the authorized terminal range" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)

      for plan <- [10, 20, 28] do
        fixture = immutable_loader_fixture!(Path.join(root, "missing-#{plan}"))
        number = plan |> Integer.to_string() |> String.pad_leading(2, "0")
        phase = ".planning/phases/164-fixture/164-#{number}"
        git!(fixture.repo, ["rm", "-q", "#{phase}-PLAN.md", "#{phase}-SUMMARY.md"])
        git!(fixture.repo, ["commit", "-q", "-m", "remove pair #{number}"])

        {output, status} = invoke_immutable_loader(fixture, ["164", "--pre-verification"])
        assert status != 0
        assert output =~ "numbered history is not the exact 01-28"
        refute File.exists?(fixture.marker)
      end
    end

    test "rejects singleton, malformed, and unexpected numbered artifacts before Bash" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)

      mutations = [
        {"singleton",
         fn fixture ->
           git!(fixture.repo, ["rm", "-q", ".planning/phases/164-fixture/164-10-SUMMARY.md"])
         end},
        {"malformed",
         fn fixture ->
           path = ".planning/phases/164-fixture/164-10-PLAN.md.backup"
           File.write!(Path.join(fixture.repo, path), "malformed\n")
           git!(fixture.repo, ["add", "--", path])
         end},
        {"unexpected",
         fn fixture ->
           path = ".planning/phases/164-fixture/164-29-PLAN.md"
           File.write!(Path.join(fixture.repo, path), "unexpected\n")
           git!(fixture.repo, ["add", "--", path])
         end}
      ]

      for {name, mutate} <- mutations do
        fixture = immutable_loader_fixture!(Path.join(root, name))
        mutate.(fixture)
        git!(fixture.repo, ["commit", "-q", "-m", name])

        {output, status} = invoke_immutable_loader(fixture, ["164", "--pre-verification"])
        assert status != 0
        assert output =~ "numbered history is not the exact 01-28"
        refute File.exists?(fixture.marker)
      end
    end

    test "loader and shell share an explicit 01-28 terminal contract recorded in the ledger" do
      loader = File.read!(@immutable_loader)
      finalizer = File.read!(@finalizer)
      ledger = File.read!(@ledger)

      assert loader =~ "const TERMINAL_FIRST_PLAN = 1"
      assert loader =~ "const TERMINAL_LAST_PLAN = 28"
      assert finalizer =~ "terminal_first_plan=1"
      assert finalizer =~ "terminal_last_plan=28"
      assert finalizer =~ ~S|for plan in $(seq -w "$terminal_first_plan" "$terminal_last_plan")|
      assert ledger =~ "scripts/mailglass_finalize_phase_loader.mjs"
      assert ledger =~ "scripts/finalize_phase_164.sh"
    end
  end

  describe "phase 164 installed boundary" do
    @describetag :phase_164_installed_boundary

    test "retired project extension bytes are absent from the checkout and authority path" do
      refute File.exists?(@extension)
      refute File.exists?(@manifest)

      loader = File.read!(@immutable_loader)
      refute loader =~ ".gsd/extensions/finalize-phase"
      refute loader =~ "registerCommand"
    end

    test "a hostile recreation of the retired extension cannot influence direct loader execution" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = immutable_loader_fixture!(Path.join(root, "hostile-retired-extension"))
      retired_dir = Path.join(fixture.repo, ".gsd/extensions/finalize-phase")
      hostile_marker = Path.join(fixture.repo, "retired-extension.marker")

      File.mkdir_p!(retired_dir)

      File.write!(
        Path.join(retired_dir, "index.ts"),
        "import { writeFileSync } from 'node:fs'; writeFileSync(#{inspect(hostile_marker)}, 'executed');\n"
      )

      File.write!(Path.join(retired_dir, "extension-manifest.json"), ~s({"id":"hostile"}\n))

      {_, 0} = invoke_immutable_loader(fixture, ["164", "--pre-verification"])
      assert File.regular?(fixture.marker)
      refute File.exists?(hostile_marker)
    end
  end

  describe "phase 164 hardened loader reinstall contract" do
    @describetag :phase_164_reinstall_contract

    test "committed source contains every hardened authority required before proposal" do
      loader = File.read!(@immutable_loader)

      assert String.starts_with?(loader, "#!/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node\n")
      assert loader =~ ~s(const CANONICAL_REPOSITORY = "/Users/jon/projects/mailglass")
      assert loader =~ ~s(const EXPECTED_REPOSITORY = "szTheory/mailglass")
      assert loader =~ "validateCanonicalRepository"
      assert loader =~ "validateTrustedToolchain"
      assert loader =~ "buildChildEnvironment"
      assert loader =~ "installationOidIsAncestor"
      assert loader =~ "const TERMINAL_FIRST_PLAN = 1"
      assert loader =~ "const TERMINAL_LAST_PLAN = 28"
      assert loader =~ "exact 01-28 PLAN/SUMMARY set"

      for path <- [
            "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node",
            "/opt/homebrew/Cellar/git/2.41.0/bin/git",
            "/opt/homebrew/Cellar/bash/5.2.37/bin/bash",
            "/opt/homebrew/Cellar/gh/2.95.0/bin/gh",
            "/usr/bin/jq",
            "/Users/jon/.asdf/shims/mix",
            "/Users/jon/.asdf/shims/elixir"
          ] do
        assert loader =~ inspect(path)
      end
    end

    test "Plan 164-23 approval remains immutable prior-object provenance" do
      summary =
        File.read!(
          Path.join(
            @repo_root,
            ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-23-SUMMARY.md"
          )
        )

      assert summary =~ "installation_source_oid=7f57e1cd0aafe6d236624da98f7292e86e6de697"

      assert summary =~
               "source_sha256=ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9"

      assert summary =~ "destination=/Users/jon/.local/bin/mailglass-finalize-phase"
      assert summary =~ "install_mode=0500"
      assert summary =~ "approval_status=approved"
      assert summary =~ "with immutable provenance"

      contract = File.read!(@finalization_contract)
      assert contract =~ "Plan 164-23 approval record remains immutable prior provenance"
      assert contract =~ "7f57e1cd0aafe6d236624da98f7292e86e6de697"
      assert contract =~ "ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9"
    end

    test "lifecycle requires approved recoverable reinstall before readiness" do
      contract = File.read!(@finalization_contract)
      normalized = Regex.replace(~r/\s+/, contract, " ")

      assert normalized =~ "Plan 164-27"
      assert normalized =~ "exact approval"
      assert normalized =~ "atomic replacement"
      assert normalized =~ "rollback"
      assert normalized =~ "controlled-host"
      assert normalized =~ "superseded operationally only after"

      assert normalized =~
               "post-summary → ordinary verifier → protected completion metadata → exact-main terminal"

      assert normalized =~ "does not run canonical pre-verification or terminal finalization"
      assert normalized =~ "terminal finalization remains pending"
    end
  end

  describe "phase 164 repository-only installed-loader attacks" do
    @describetag :phase_164_installed_boundary

    test "production loader rejects a foreign repository before private dispatch" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = production_installed_fixture!(Path.join(root, "accepted"))

      {output, status} = invoke_production_loader(fixture, ["164", "--pre-verification"])
      assert status != 0
      assert output =~ "numbered history is not the exact 01-28"
      refute File.exists?(fixture.marker)
    end

    test "absolute installed executable rejects a moving HEAD before Bash" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = production_installed_fixture!(Path.join(root, "moving"), move_head: true)

      {output, status} =
        invoke_production_loader(fixture, ["164", "--pre-verification"], fixture.env)

      assert status != 0
      assert output =~ "numbered history is not the exact 01-28"
      refute File.exists?(fixture.marker)
      refute File.exists?(fixture.hostile_marker)
    end

    test "absolute installed executable rejects deleted middle and terminal pairs before Bash" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)

      for plan <- [10, 20, 28] do
        fixture = production_installed_fixture!(Path.join(root, "missing-#{plan}"))
        number = plan |> Integer.to_string() |> String.pad_leading(2, "0")
        phase = ".planning/phases/164-fixture/164-#{number}"
        git!(fixture.repo, ["rm", "-q", "#{phase}-PLAN.md", "#{phase}-SUMMARY.md"])
        git!(fixture.repo, ["commit", "-q", "-m", "remove pair #{number}"])

        {output, status} = invoke_production_loader(fixture, ["164", "--pre-verification"])
        assert status != 0
        assert output =~ "numbered history is not the exact 01-28"
        refute File.exists?(fixture.marker)
        refute File.exists?(fixture.hostile_marker)
      end
    end

    test "assume-unchanged hostile retired extension is never evaluated" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = production_installed_fixture!(Path.join(root, "hostile-extension"))
      hostile_extension = Path.join(fixture.repo, ".gsd/extensions/finalize-phase/index.ts")

      git!(fixture.repo, [
        "update-index",
        "--assume-unchanged",
        "--",
        ".gsd/extensions/finalize-phase/index.ts"
      ])

      File.write!(
        hostile_extension,
        "import { writeFileSync } from 'node:fs'; writeFileSync(#{inspect(fixture.hostile_marker)}, 'executed');\n"
      )

      assert git!(fixture.repo, [
               "status",
               "--porcelain",
               "--",
               ".gsd/extensions/finalize-phase/index.ts"
             ]) == ""

      {output, status} = invoke_production_loader(fixture, ["164", "--pre-verification"])
      assert status != 0
      assert output =~ "numbered history is not the exact 01-28"
      refute File.exists?(fixture.marker)
      refute File.exists?(fixture.hostile_marker)
    end

    test "production authority constants cannot be overridden by argv or environment" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)
      fixture = production_installed_fixture!(Path.join(root, "override"))

      for {args, env} <- [
            {["164", "--repo", fixture.repo], []},
            {["164"], [{"MAILGLASS_REPOSITORY", fixture.repo}, {"GIT", "git"}]}
          ] do
        {output, status} = invoke_production_loader(fixture, args, env)
        assert status != 0

        assert output =~ "expected phase 164" or
                 output =~ "numbered history is not the exact 01-28"

        refute File.exists?(fixture.marker)
      end
    end
  end

  describe "phase 164 installed production boundary" do
    @describetag :phase_164_installed_production_boundary

    test "real installed command and approval are regular non-symlinks with exact modes" do
      assert_regular_mode!(@installed_loader, 0o500)
      assert_regular_mode!(@install_approval, 0o400)

      approval = parse_install_approval!(@install_approval)
      assert approval["destination"] == @installed_loader
      assert approval["install_mode"] == "0500"
      assert approval["approval_status"] == "approved"
      assert approval["installation_source_oid"] == @installation_source_oid
      assert approval["source_sha256"] == @installed_loader_sha256
    end

    test "approval binds all nineteen immutable Plan 164-27 fields exactly once" do
      approval = parse_install_approval!(@install_approval)

      assert map_size(approval) == 19
      assert approval["record_version"] == "1"
      assert approval["phase_plan"] == "164-27"
      assert approval["node_executable"] == "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node"
      assert approval["git_executable"] == "/opt/homebrew/Cellar/git/2.41.0/bin/git"
      assert approval["bash_executable"] == "/opt/homebrew/Cellar/bash/5.2.37/bin/bash"
      assert approval["gh_executable"] == "/opt/homebrew/Cellar/gh/2.95.0/bin/gh"
      assert approval["jq_executable"] == "/usr/bin/jq"
      assert approval["mix_executable"] == "/Users/jon/.asdf/shims/mix"
      assert approval["elixir_executable"] == "/Users/jon/.asdf/shims/elixir"

      assert approval["prior_approval_sha256"] ==
               "c9750e8becddd7b08ce27b2c6267b5172c1f25954d0d1b5ef9e39f04a909c862"

      assert approval["prior_sha256"] ==
               "ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9"

      assert approval["prior_mode"] == "0500"
      assert approval["prior_stat_identity"] == "16777229:267228421:501:20"

      assert approval["rollback_path"] ==
               "/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9"
    end

    test "installed digest equals the approved committed loader blob at an ancestor OID" do
      approval = parse_install_approval!(@install_approval)
      assert sha256_file!(@installed_loader) == approval["source_sha256"]

      {blob, 0} =
        System.cmd(
          "git",
          [
            "show",
            "#{approval["installation_source_oid"]}:scripts/mailglass_finalize_phase_loader.mjs"
          ],
          cd: @repo_root
        )

      assert blob |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower) ==
               approval["source_sha256"]

      assert {_, 0} =
               System.cmd(
                 "git",
                 ["merge-base", "--is-ancestor", approval["installation_source_oid"], "HEAD"],
                 cd: @repo_root,
                 stderr_to_stdout: true
               )
    end

    test "installed executable self-check reports every approved authority field" do
      approval = parse_install_approval!(@install_approval)
      {output, 0} = invoke_installed_self_check(@installed_loader, approval)

      assert output =~ "installation_oid=#{approval["installation_source_oid"]}"
      assert output =~ "current_oid="
      assert output =~ "loader_sha256=#{approval["source_sha256"]}"
      assert output =~ "executable=#{approval["destination"]}"
      assert output =~ "mode=#{approval["install_mode"]}"
      assert output =~ "terminal_range=01-28"
    end

    test "approval validation rejects malformed and duplicate records fail-closed" do
      root = temporary_root!()
      on_exit(fn -> File.rm_rf!(root) end)

      for {name, contents, expected} <- [
            {"blank", "record_version=1\nphase_plan=\n", "blank approval value"},
            {"malformed", "not-an-assignment\n", "malformed approval line"},
            {"duplicate", "record_version=1\nrecord_version=1\n", "duplicate approval key"},
            {"unknown", "unknown=value\n", "unknown approval key"}
          ] do
        path = Path.join(root, name)
        File.write!(path, contents)
        File.chmod!(path, 0o400)
        assert_raise RuntimeError, ~r/#{expected}/, fn -> parse_install_approval!(path) end
      end
    end
  end

  test "owned sibling cleanup refuses pre-existing and token-replaced paths" do
    root = temporary_root!()
    candidate = @repo_root <> "-gap-preexisting-#{System.unique_integer([:positive])}"
    File.mkdir!(candidate)
    on_exit(fn -> File.rm_rf!(root) end)

    try do
      assert_raise RuntimeError, ~r/refusing to reuse existing sibling fixture/, fn ->
        allocate_owned_sibling!("gap", candidate)
      end

      assert File.dir?(candidate)
    after
      File.rmdir!(candidate)
    end

    owner = allocate_owned_sibling!("gap")
    File.write!(owner.ownership_file, "replacement")

    assert_raise RuntimeError, ~r/ownership check failed/, fn ->
      cleanup_owned_sibling!(owner)
    end

    assert File.dir?(owner.path)
    File.write!(owner.ownership_file, owner.token)
    cleanup_owned_sibling!(owner)
    refute File.exists?(owner.path)
  end

  defp run(repo, ledger, output, marker) do
    root = Path.dirname(marker)
    bin = Path.join(root, "bin-#{System.unique_integer([:positive])}")
    File.mkdir_p!(bin)
    mix = Path.join(bin, "mix")
    File.write!(mix, "#!/usr/bin/env bash\nprintf invoked > #{inspect(marker)}\nexit 99\n")
    File.chmod!(mix, 0o755)

    System.cmd(
      "bash",
      [
        @script,
        "--repo",
        repo,
        "--authority-root",
        repo,
        "--ledger",
        ledger,
        "--ci-run-id",
        "123",
        "--output",
        output
      ],
      env: [{"PATH", "#{bin}:#{System.fetch_env!("PATH")}"}],
      stderr_to_stdout: true
    )
  end

  defp scheduled_report_acceptable?(report_path, expected_sha) do
    {_, status} =
      System.cmd(
        "bash",
        [
          "-c",
          ~s(source "$1"; scheduled_report_is_acceptable "$2" "$3" "$4"),
          "phase-164-closeout-test",
          @script,
          report_path,
          expected_sha,
          @scheduled_registry
        ],
        cd: @repo_root,
        stderr_to_stdout: true
      )

    status == 0
  end

  defp authoritative_sweep(sha) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    hourly = now |> DateTime.add(-3_600, :second) |> DateTime.to_iso8601()
    daily = now |> DateTime.add(-14_400, :second) |> DateTime.to_iso8601()

    %{
      "kind" => "sweep",
      "status" => "pass",
      "reason" => "all_controls_current",
      "evidence_valid" => true,
      "expected_main_sha" => sha,
      "controls" => [
        scheduled_control("release-please", sha, hourly, "pass"),
        scheduled_control("repo-hygiene", sha, daily, "pass"),
        scheduled_control("post-publish-smoke", sha, daily, "blocked")
      ]
    }
  end

  defp scheduled_control(control, sha, updated_at, status) do
    %{
      "control" => control,
      "evidence_valid" => true,
      "source_run" => %{
        "id" => "16214",
        "name" => control,
        "attempt" => 1,
        "event" => "schedule",
        "status" => "completed",
        "conclusion" => if(status == "pass", do: "success", else: "failure"),
        "head_branch" => "main",
        "head_sha" => sha,
        "updated_at" => updated_at
      },
      "result" => %{
        "status" => status,
        "reason" => "fixture_result",
        "workflow_sha" => sha,
        "payload_sha256" => String.duplicate("f", 64),
        "artifact_archive_digest" => "sha256:#{String.duplicate("e", 64)}"
      }
    }
  end

  defp ci_run(id, sha, attempt, created_at) do
    %{
      "databaseId" => id,
      "workflowName" => "CI",
      "headBranch" => "main",
      "headSha" => sha,
      "event" => "push",
      "attempt" => attempt,
      "status" => "completed",
      "conclusion" => "success",
      "createdAt" => created_at
    }
  end

  defp source_finalizer(command, args) do
    System.cmd(
      "bash",
      ["-c", ~s(source "$1"; #{command}), "phase-164-finalizer-test", @finalizer | args],
      cd: @repo_root,
      env: [
        {"MAILGLASS_GIT", System.find_executable("git")},
        {"MAILGLASS_BASH", System.find_executable("bash")},
        {"MAILGLASS_GH", System.find_executable("gh")},
        {"MAILGLASS_JQ", System.find_executable("jq")},
        {"MAILGLASS_MIX", System.find_executable("mix")},
        {"MAILGLASS_NODE", System.find_executable("node")},
        {"MAILGLASS_ELIXIR", System.find_executable("elixir")}
      ],
      stderr_to_stdout: true
    )
  end

  defp terminal_state(repo, phase_dir) do
    source_finalizer(~s(require_terminal_state "$2" "$3" "$2"), [repo, phase_dir])
  end

  defp terminal_fixture!(repo) do
    phase_rel = ".planning/phases/164-repository-truth-reconciliation-and-closeout"
    phase_dir = Path.join(repo, phase_rel)
    File.mkdir_p!(Path.join(repo, "scripts"))
    File.mkdir_p!(phase_dir)
    git!(Path.dirname(repo), ["init", "-q", "-b", "main", repo])

    File.write!(Path.join(repo, "scripts/finalize_phase_164.sh"), "verified source")

    File.write!(
      Path.join(repo, ".planning/ROADMAP.md"),
      "- [x] **Phase 164: Repository Truth Reconciliation and Closeout**\n"
    )

    File.write!(
      Path.join(repo, ".planning/REQUIREMENTS.md"),
      Enum.map_join(["TRTH-01", "TRTH-02", "TRTH-03"], "\n", &"- [x] **#{&1}**") <> "\n"
    )

    File.write!(Path.join(repo, ".planning/STATE.md"), "state\n")

    for plan <- 1..28 do
      number = plan |> Integer.to_string() |> String.pad_leading(2, "0")
      File.write!(Path.join(phase_dir, "164-#{number}-PLAN.md"), "plan\n")
      File.write!(Path.join(phase_dir, "164-#{number}-SUMMARY.md"), "summary\n")
    end

    git!(repo, ["add", "."])
    git!(repo, ["commit", "-q", "-m", "verified implementation"])
    verified_sha = repo |> git!(["rev-parse", "HEAD"]) |> String.trim()
    write_verification!(phase_dir, verified_sha)
    git!(repo, ["add", "."])
    git!(repo, ["commit", "-q", "-m", "verification metadata"])

    File.write!(Path.join(repo, ".planning/STATE.md"), "complete\n")
    git!(repo, ["commit", "-qam", "completion metadata"])

    %{repo: repo, phase_dir: phase_dir, verified_sha: verified_sha}
  end

  defp write_verification!(phase_dir, verified_sha) do
    sha_line = if verified_sha, do: "verified_implementation_sha: #{verified_sha}\n", else: ""

    File.write!(
      Path.join(phase_dir, "164-VERIFICATION.md"),
      "---\nstatus: passed\n#{sha_line}---\n"
    )
  end

  defp run_aggregate_fixture!(name, hygiene_json, hygiene_exit) do
    root = temporary_root!()
    fixture_script = Path.join(root, "closeout_repository_truth.sh")

    production_source = File.read!(@script)
    canonical_assignment = "canonical_repo=/Users/jon/projects/mailglass"
    assert length(:binary.matches(production_source, canonical_assignment)) == 1

    File.write!(
      fixture_script,
      String.replace(
        production_source,
        canonical_assignment,
        ~s(canonical_repo="#{@repo_root}"),
        global: false
      )
    )

    File.chmod!(fixture_script, 0o755)

    output_dir =
      Path.join(@repo_root, "tmp/phase-164-aggregate-#{name}-#{System.unique_integer([:positive])}")

    output = Path.join(output_dir, "report.json")
    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)
    File.mkdir_p!(output_dir)

    sha = String.duplicate("a", 40)
    scheduled_json = Jason.encode!(authoritative_sweep(sha))

    write_executable!(
      Path.join(bin, "git"),
      """
      #!/bin/bash
      case "$3" in
        status) exit 0 ;;
        rev-parse) printf '%s\\n' "$FIXTURE_SHA" ;;
        branch) printf 'main\\n' ;;
        check-ignore) exit 0 ;;
        *) exit 99 ;;
      esac
      """
    )

    write_executable!(
      Path.join(bin, "mix"),
      """
      #!/bin/bash
      printf '%s' "$HYGIENE_JSON"
      exit "$HYGIENE_EXIT"
      """
    )

    write_executable!(Path.join(bin, "elixir"), "#!/bin/bash\nprintf 'ledger valid\\n'\n")

    write_executable!(
      Path.join(bin, "node"),
      """
      #!/bin/bash
      printf '{"databaseId":123,"workflowName":"CI","event":"push","attempt":1,"headBranch":"main","headSha":"%s","status":"completed","conclusion":"success"}\\n' "$FIXTURE_SHA"
      """
    )

    write_executable!(
      Path.join(bin, "bash"),
      """
      #!/bin/bash
      case "$1" in
        *verify_workspace_evidence.sh)
          printf 'workspace valid\\n'
          exit 0
          ;;
        scripts/scheduled_control_evidence.sh|*/scripts/scheduled_control_evidence.sh)
          while [ "$#" -gt 0 ]; do
            if [ "$1" = "--output" ]; then
              shift
              printf '%s' "$SCHEDULED_JSON" > "$1"
              exit 0
            fi
            shift
          done
          exit 2
          ;;
        *) exit 99 ;;
      esac
      """
    )

    {_output, status} =
      System.cmd(
        "/bin/bash",
        [
          fixture_script,
          "--repo",
          @repo_root,
          "--authority-root",
          @repo_root,
          "--ledger",
          @ledger,
          "--ci-run-id",
          "123",
          "--output",
          output
        ],
        env: [
          {"PATH", "#{bin}:#{System.fetch_env!("PATH")}"},
          {"FIXTURE_SHA", sha},
          {"HYGIENE_JSON", hygiene_json},
          {"HYGIENE_EXIT", Integer.to_string(hygiene_exit)},
          {"SCHEDULED_JSON", scheduled_json}
        ],
        stderr_to_stdout: true
      )

    if name in ["policy-blocked", "all-pass"], do: assert(status == 0), else: assert(status != 0)
    assert File.regular?(output)

    report = output |> File.read!() |> Jason.decode!()
    Map.put(report, "fixture_cleanup", [root, output_dir])
  end

  defp cleanup_aggregate_fixture!(report) do
    capture_root =
      report["components"]["git"]["source"]
      |> Path.dirname()
      |> Path.dirname()

    for path <- [capture_root | report["fixture_cleanup"]], do: File.rm_rf!(path)
  end

  defp run_late_dirt_fixture!(name, dirty_after_status_call) do
    root = temporary_root!()
    fixture_script = Path.join(root, "closeout_repository_truth.sh")

    output_dir =
      Path.join(@repo_root, "tmp/phase-164-late-dirt-#{name}-#{System.unique_integer([:positive])}")

    output = Path.join(output_dir, "report.json")

    dirt_sentinel =
      Path.join(@repo_root, "phase-164-late-dirt-#{System.unique_integer([:positive])}")

    status_counter = Path.join(root, "status-counter")
    bin = Path.join(root, "bin")
    sha = String.duplicate("a", 40)

    File.mkdir_p!(bin)
    File.mkdir_p!(output_dir)
    File.write!(status_counter, "0")

    production_source = File.read!(@script)
    canonical_assignment = "canonical_repo=/Users/jon/projects/mailglass"
    assert length(:binary.matches(production_source, canonical_assignment)) == 1

    File.write!(
      fixture_script,
      String.replace(
        production_source,
        canonical_assignment,
        ~s(canonical_repo="#{@repo_root}"),
        global: false
      )
    )

    File.chmod!(fixture_script, 0o755)

    write_executable!(
      Path.join(bin, "git"),
      """
      #!/bin/bash
      case "$3" in
        status)
          count=$(($(cat "$STATUS_COUNTER") + 1))
          printf '%s' "$count" > "$STATUS_COUNTER"
          if [ "$count" -ge "$DIRTY_AFTER_STATUS_CALL" ]; then
            : > "$DIRT_SENTINEL"
            printf '?? %s\n' "${DIRT_SENTINEL#"$FIXTURE_REPO"/}"
          fi
          ;;
        rev-parse) printf '%s\n' "$FIXTURE_SHA" ;;
        branch) printf 'main\n' ;;
        check-ignore) exit 0 ;;
        *) exit 99 ;;
      esac
      """
    )

    write_executable!(
      Path.join(bin, "mix"),
      "#!/bin/bash\nprintf '{\"status\":\"pass\",\"reason\":\"clean\"}'\n"
    )

    write_executable!(Path.join(bin, "elixir"), "#!/bin/bash\nprintf 'ledger valid\\n'\n")

    write_executable!(
      Path.join(bin, "node"),
      """
      #!/bin/bash
      printf '{"databaseId":123,"workflowName":"CI","event":"push","attempt":1,"headBranch":"main","headSha":"%s","status":"completed","conclusion":"success"}\n' "$FIXTURE_SHA"
      """
    )

    scheduled_json = Jason.encode!(authoritative_sweep(sha))

    write_executable!(
      Path.join(bin, "bash"),
      """
      #!/bin/bash
      case "$1" in
        *verify_workspace_evidence.sh)
          printf 'workspace valid\n'
          exit 0
          ;;
        scripts/scheduled_control_evidence.sh|*/scripts/scheduled_control_evidence.sh)
          while [ "$#" -gt 0 ]; do
            if [ "$1" = "--output" ]; then
              shift
              printf '%s' "$SCHEDULED_JSON" > "$1"
              exit 0
            fi
            shift
          done
          exit 2
          ;;
        *) exit 99 ;;
      esac
      """
    )

    {_command_output, status} =
      System.cmd(
        "/bin/bash",
        [
          fixture_script,
          "--repo",
          @repo_root,
          "--authority-root",
          @repo_root,
          "--ledger",
          @ledger,
          "--ci-run-id",
          "123",
          "--output",
          output
        ],
        env: [
          {"PATH", "#{bin}:#{System.fetch_env!("PATH")}"},
          {"FIXTURE_REPO", @repo_root},
          {"FIXTURE_SHA", sha},
          {"STATUS_COUNTER", status_counter},
          {"DIRTY_AFTER_STATUS_CALL", Integer.to_string(dirty_after_status_call)},
          {"DIRT_SENTINEL", dirt_sentinel},
          {"SCHEDULED_JSON", scheduled_json}
        ],
        stderr_to_stdout: true
      )

    assert status != 0
    assert File.regular?(output)

    output
    |> File.read!()
    |> Jason.decode!()
    |> Map.put("dirt_sentinel", dirt_sentinel)
    |> Map.put("fixture_cleanup", [root, output_dir, dirt_sentinel])
  end

  defp cleanup_late_dirt_fixture!(report) do
    capture_root =
      report["components"]["git"]["source"]
      |> Path.dirname()
      |> Path.dirname()

    for path <- [capture_root | report["fixture_cleanup"]], do: File.rm_rf!(path)
  end

  defp write_executable!(path, contents) do
    File.write!(path, contents)
    File.chmod!(path, 0o755)
  end

  defp extension_fixture!(repo, options \\ []) do
    phase_dir = Path.join(repo, ".planning/phases/164-fixture")
    scripts_dir = Path.join(repo, "scripts")
    shim = Path.join(phase_dir, "164-FINALIZE.sh")
    downstream = Path.join(scripts_dir, "finalize_phase_164.sh")
    marker = Path.join(repo, "execution.marker")
    bytes_marker = Path.join(repo, "bytes.marker")
    hostile_marker = Path.join(repo, "hostile.marker")
    File.mkdir_p!(phase_dir)
    File.mkdir_p!(scripts_dir)
    git!(Path.dirname(repo), ["init", "-q", "-b", "main", repo])

    File.write!(
      downstream,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      target_repo="$1"
      if [ "${2:-}" != "" ] && [ "${2#--}" = "$2" ]; then
        authority_root="$2"
        mode="${3:-}"
      else
        authority_root="$target_repo"
        mode="${2:-}"
      fi
      printf '%s|%s|%s|%s' "$0" "$authority_root" "$target_repo" "$mode" > "$MARKER"
      cat "$0" > "$BYTES_MARKER"
      "$authority_root/scripts/closeout_repository_truth.sh" "$authority_root"
      exit "${FINALIZER_EXIT:-0}"
      """
    )

    File.chmod!(downstream, 0o755)
    git!(repo, ["add", "scripts/finalize_phase_164.sh"])
    git!(repo, ["commit", "-q", "-m", "committed downstream"])

    File.write!(
      shim,
      "#!/usr/bin/env bash\nexec \"$1/scripts/finalize_phase_164.sh\" \"$@\"\n"
    )

    File.chmod!(shim, 0o755)

    if Keyword.get(options, :commit_shim, true) do
      git!(repo, ["add", ".planning/phases/164-fixture/164-FINALIZE.sh"])
      git!(repo, ["commit", "-q", "-m", "committed shim"])
    end

    for path <- @transitive_executables do
      absolute = Path.join(repo, path)
      File.mkdir_p!(Path.dirname(absolute))

      contents =
        if path == "scripts/closeout_repository_truth.sh" do
          reads =
            Enum.map_join(
              @transitive_data,
              "\n",
              &~s(grep -q '^MUTATED:' "$root/#{&1}" && touch "$HOSTILE_MARKER" || true)
            )

          helpers = Enum.map_join(@transitive_executables -- [path], "\n", &~s("$root/#{&1}"))
          "#!/usr/bin/env bash\nset -euo pipefail\nroot=\"$1\"\n#{helpers}\n#{reads}\n"
        else
          "#!/usr/bin/env bash\nexit 0\n"
        end

      File.write!(absolute, contents)
      File.chmod!(absolute, 0o755)
    end

    for path <- @transitive_data do
      absolute = Path.join(repo, path)
      File.mkdir_p!(Path.dirname(absolute))
      File.write!(absolute, "trusted:#{path}\n")
    end

    git!(repo, ["add" | @transitive_executables ++ @transitive_data])
    git!(repo, ["commit", "-q", "-m", "committed authority dependencies"])

    %{
      repo: repo,
      shim: shim,
      shim_relative: ".planning/phases/164-fixture/164-FINALIZE.sh",
      downstream: downstream,
      downstream_relative: "scripts/finalize_phase_164.sh",
      marker: marker,
      bytes_marker: bytes_marker,
      hostile_marker: hostile_marker
    }
  end

  defp immutable_loader_fixture!(repo, options \\ []) do
    fixture = extension_fixture!(repo)
    loader_source = Path.join(repo, "scripts/mailglass_finalize_phase_loader.mjs")
    File.cp!(@immutable_loader, loader_source)

    phase_dir = Path.join(repo, ".planning/phases/164-fixture")

    source = File.read!(@immutable_loader)

    source =
      if Keyword.get(options, :production, false) do
        source
      else
        String.replace(
          source,
          ~s(const CANONICAL_REPOSITORY = "/Users/jon/projects/mailglass"),
          ~s(const CANONICAL_REPOSITORY = #{inspect(resolved_path!(repo))})
        )
      end

    source =
      String.replace(
        source,
        "const TEST_ENV_KEYS = [];",
        ~s(const TEST_ENV_KEYS = ["MARKER", "BYTES_MARKER", "HOSTILE_MARKER", "FINALIZER_EXIT"];)
      )

    File.write!(loader_source, source)
    git!(repo, ["remote", "add", "origin", "git@github.com:szTheory/mailglass.git"])

    for plan <- 2..28 do
      number = plan |> Integer.to_string() |> String.pad_leading(2, "0")
      File.write!(Path.join(phase_dir, "164-#{number}-PLAN.md"), "plan #{number}\n")
      File.write!(Path.join(phase_dir, "164-#{number}-SUMMARY.md"), "summary #{number}\n")
    end

    git!(repo, ["add", "."])
    git!(repo, ["commit", "-q", "-m", "installable immutable loader authority"])
    installation_oid = repo |> git!(["rev-parse", "HEAD"]) |> String.trim()

    File.write!(Path.join(repo, "metadata"), "later metadata\n")
    git!(repo, ["add", "metadata"])
    git!(repo, ["commit", "-q", "-m", "metadata only"])
    current_oid = repo |> git!(["rev-parse", "HEAD"]) |> String.trim()

    install_dir = Path.join(Path.dirname(repo), "installed-#{Path.basename(repo)}")
    File.mkdir_p!(install_dir)
    installed = Path.join(install_dir, "mailglass-finalize-phase")
    File.cp!(loader_source, installed)
    File.chmod!(installed, 0o500)

    git_log = Path.join(Path.dirname(repo), "git.log")
    real_git = System.find_executable("git")
    env = [{"REAL_GIT", real_git}, {"GIT_LOG", git_log}]

    env =
      if Keyword.get(options, :move_head, false) do
        shim_dir = Path.join(Path.dirname(repo), "git-shim")
        counter = Path.join(Path.dirname(repo), "git-counter")
        File.mkdir_p!(shim_dir)
        File.write!(counter, "0")

        write_executable!(
          Path.join(shim_dir, "git"),
          """
          #!/usr/bin/env bash
          set -euo pipefail
          printf '%s\\n' "$*" >> "$GIT_LOG"
          "$REAL_GIT" "$@"
          status=$?
          count=$(($(cat "$GIT_COUNTER") + 1))
          printf '%s' "$count" > "$GIT_COUNTER"
          if [ "$count" -eq 4 ]; then
            printf 'advanced\\n' > "$FIXTURE_REPO/head-advance"
            "$REAL_GIT" -C "$FIXTURE_REPO" add head-advance
            GIT_AUTHOR_NAME='Phase 164 Test' GIT_AUTHOR_EMAIL=phase164@example.test \\
            GIT_COMMITTER_NAME='Phase 164 Test' GIT_COMMITTER_EMAIL=phase164@example.test \\
              "$REAL_GIT" -C "$FIXTURE_REPO" commit -q -m 'advance head during authentication'
          fi
          exit "$status"
          """
        )

        [
          {"PATH", "#{shim_dir}:#{System.fetch_env!("PATH")}"},
          {"GIT_COUNTER", counter},
          {"FIXTURE_REPO", repo}
          | env
        ]
      else
        env
      end

    Map.merge(fixture, %{
      installed: installed,
      installation_oid: installation_oid,
      current_oid: current_oid,
      git_log: git_log,
      env: env
    })
  end

  defp production_installed_fixture!(repo, options \\ []) do
    fixture = immutable_loader_fixture!(repo, Keyword.put(options, :production, true))
    retired_extension = Path.join(repo, ".gsd/extensions/finalize-phase/index.ts")
    File.mkdir_p!(Path.dirname(retired_extension))
    File.write!(retired_extension, "export default function retired() { return 'retired'; }\n")
    git!(repo, ["add", ".gsd/extensions/finalize-phase/index.ts"])
    git!(repo, ["commit", "-q", "-m", "record retired extension fixture"])
    fixture
  end

  defp invoke_production_loader(fixture, args, extra_env \\ []) do
    node = fixture_node!()

    System.cmd(node, [fixture.installed | args],
      cd: fixture.repo,
      env:
        extra_env ++
          [
            {"MARKER", fixture.marker},
            {"BYTES_MARKER", fixture.bytes_marker},
            {"HOSTILE_MARKER", fixture.hostile_marker},
            {"GIT_LOG", fixture.git_log},
            {"REAL_GIT", System.find_executable("git")}
          ],
      stderr_to_stdout: true
    )
  end

  defp invoke_immutable_loader(fixture, args, extra_env \\ []) do
    node = fixture_node!()

    System.cmd(node, [fixture.installed | args],
      cd: fixture.repo,
      env:
        extra_env ++
          [
            {"MARKER", fixture.marker},
            {"BYTES_MARKER", fixture.bytes_marker},
            {"HOSTILE_MARKER", fixture.hostile_marker},
            {"GIT_LOG", fixture.git_log},
            {"REAL_GIT", System.find_executable("git")}
          ],
      stderr_to_stdout: true
    )
  end

  defp fixture_node! do
    discovered =
      System.find_executable("node") || raise "node executable is required for loader fixtures"

    case System.cmd(discovered, ["-p", "process.execPath"], stderr_to_stdout: true) do
      {path, 0} ->
        resolved = String.trim(path)

        if File.regular?(resolved),
          do: resolved,
          else: raise("node resolved to non-file: #{resolved}")

      {output, status} ->
        raise "node executable discovery failed with #{status}: #{String.trim(output)}"
    end
  end

  defp parse_install_approval!(path) do
    assert_regular_mode!(path, 0o400)

    approval =
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.reduce(%{}, fn line, fields ->
        case String.split(line, "=", parts: 2) do
          ["", _value] ->
            raise "blank approval key"

          [_key, ""] ->
            raise "blank approval value"

          [key, value] ->
            unless Map.has_key?(@install_approval_tuple, key),
              do: raise("unknown approval key: #{key}")

            if Map.has_key?(fields, key), do: raise("duplicate approval key: #{key}")
            Map.put(fields, key, value)

          _ ->
            raise "malformed approval line"
        end
      end)

    missing = Map.keys(@install_approval_tuple) -- Map.keys(approval)
    if missing != [], do: raise("missing approval keys: #{Enum.join(Enum.sort(missing), ",")}")

    for {key, expected} <- @install_approval_tuple do
      actual = Map.fetch!(approval, key)
      if actual != expected, do: raise("approval tuple mismatch for #{key}")
    end

    approval
  end

  defp assert_regular_mode!(path, expected_mode) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular, mode: mode}} ->
        actual_mode = Bitwise.band(mode, 0o777)

        if actual_mode != expected_mode do
          raise "wrong mode for #{path}: expected #{Integer.to_string(expected_mode, 8)}, got #{Integer.to_string(actual_mode, 8)}"
        end

        :ok

      {:ok, %File.Stat{type: type}} ->
        raise "not a regular non-symlink file: #{path} (#{type})"

      {:error, reason} ->
        raise "cannot lstat #{path}: #{:file.format_error(reason)}"
    end
  end

  defp sha256_file!(path) do
    assert_regular_mode!(path, 0o500)

    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp invoke_installed_self_check(path, approval) do
    assert_regular_mode!(path, 0o500)

    System.cmd(
      path,
      [
        "--self-check",
        "--repo",
        @repo_root,
        "--expected-source-oid",
        approval["installation_source_oid"]
      ],
      cd: @repo_root,
      stderr_to_stdout: true
    )
  end

  defp hostile_script(marker) do
    "#!/usr/bin/env bash\nprintf hostile > #{inspect(marker)}\n"
  end

  defp allocate_owned_sibling!(tag, candidate \\ nil) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    basename_prefix = "#{Path.basename(@repo_root)}-#{tag}-"
    path = candidate || Path.join(Path.dirname(@repo_root), basename_prefix <> token)

    case File.mkdir(path) do
      :ok -> :ok
      {:error, :eexist} -> raise "refusing to reuse existing sibling fixture: #{path}"
      {:error, reason} -> raise "could not allocate sibling fixture #{path}: #{inspect(reason)}"
    end

    ownership_file = Path.join(path, ".phase-164-owner")
    File.write!(ownership_file, token, [:exclusive])

    %{
      path: path,
      token: token,
      ownership_file: ownership_file,
      resolved_parent: resolved_path!(Path.dirname(path)),
      basename: Path.basename(path),
      basename_prefix: basename_prefix
    }
  end

  defp cleanup_owned_sibling!(owner) do
    owned =
      match?({:ok, %File.Stat{type: :directory}}, File.lstat(owner.path)) and
        resolved_path!(Path.dirname(owner.path)) == owner.resolved_parent and
        Path.basename(owner.path) == owner.basename and
        String.starts_with?(owner.basename, owner.basename_prefix) and
        match?({:ok, %File.Stat{type: :regular}}, File.lstat(owner.ownership_file)) and
        File.read(owner.ownership_file) == {:ok, owner.token}

    if owned do
      File.rm_rf!(owner.path)
    else
      raise "sibling fixture ownership check failed; leaving path untouched: #{owner.path}"
    end
  end

  defp resolved_path!(path) do
    case System.cmd("realpath", [path], stderr_to_stdout: true) do
      {resolved, 0} -> String.trim(resolved)
      {message, status} -> raise "realpath failed (#{status}): #{message}"
    end
  end

  defp git!(directory, args) do
    {output, 0} =
      System.cmd("git", args,
        cd: directory,
        env: [
          {"GIT_AUTHOR_NAME", "Phase 164 Test"},
          {"GIT_AUTHOR_EMAIL", "phase164@example.test"},
          {"GIT_COMMITTER_NAME", "Phase 164 Test"},
          {"GIT_COMMITTER_EMAIL", "phase164@example.test"}
        ],
        stderr_to_stdout: true
      )

    output
  end

  defp header do
    "stable_id\tsubject\tkind\tproducer\tstate\tauthority\treproducibility\tcurrentness\tdurable_consumer\tevidence\tdisposition\trationale"
  end

  defp temporary_root do
    Path.join(System.tmp_dir!(), "mailglass-closeout-#{System.unique_integer([:positive])}")
  end

  defp temporary_root! do
    root = temporary_root()
    File.mkdir_p!(root)
    root
  end
end
