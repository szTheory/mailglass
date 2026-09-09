defmodule Mailglass.Scripts.Phase164CloseoutTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/closeout_repository_truth.sh")
  @extension Path.join(@repo_root, ".gsd/extensions/finalize-phase/index.ts")
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
    assert source =~ "--ledger \"$canonical_ledger\""
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

  test "finalization guidance keeps pre-verification and terminal proof non-circular" do
    contract = File.read!(@finalization_contract)
    normalized = Regex.replace(~r/\s+/, contract, " ")

    assert contract =~ "/finalize-phase 164 --pre-verification"
    assert contract =~ "ordinary phase verifier"
    assert normalized =~ "before `phase.complete` writes tracked completion metadata"
    assert contract =~ "/finalize-phase 164"
    assert contract =~ "After the normal verifier has passed"
    assert contract =~ "status: passed"
    assert contract =~ "writes only ignored"
    assert contract =~ "No summary, planning update, commit, push, merge"
    assert contract =~ "CI must be attempt 1"
    assert normalized =~ "Every registered scheduled control must be attempt 1"
    assert normalized =~ "A HEAD change or any stable-porcelain entry"
  end

  test "finalize-phase manifest exposes exactly one compatible community command" do
    manifest = @manifest |> File.read!() |> Jason.decode!()

    assert manifest["id"] == "finalize-phase"
    assert manifest["tier"] == "community"
    assert manifest["requires"] == %{"platform" => ">=2.29.0"}
    assert manifest["provides"] == %{"commands" => ["finalize-phase"]}
  end

  test "finalize-phase command validates one phase and dispatches one tracked finalizer via pi.exec" do
    source = File.read!(@extension)

    assert source =~ ~s(import type { ExtensionAPI } from "@gsd/pi-coding-agent")
    assert source =~ ~s(pi.registerCommand("finalize-phase")
    assert source =~ ~r/\^\[1-9\]\\d\*\$/
    assert source =~ "--pre-verification"
    assert source =~ "git ls-files --error-unmatch"
    assert source =~ ~s(pi.exec("bash", [finalizer, repoRoot, ...modeArgs])
    assert source =~ "result.code"
    assert source =~ "process.exitCode = 1"
    assert source =~ ~s|process.argv.includes("--print")|
    assert source =~ "process.exit(1)"
    assert source =~ "ctx.ui.notify"
    assert source =~ "slice(-MAX_OUTPUT_BYTES)"

    refute source =~ "child_process"
    refute source =~ "registerTool"
    refute source =~ "pi.on("
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
    assert source =~ "usage: $0 REPO [--pre-verification]"
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
    assert source =~ ~s(SCHEDULED_CONTROL_CONFIG="$repo/$registry_rel")
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
      [@script, "--repo", repo, "--ledger", ledger, "--ci-run-id", "123", "--output", output],
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
      stderr_to_stdout: true
    )
  end

  defp terminal_state(repo, phase_dir) do
    source_finalizer(~s(require_terminal_state "$2" "$3"), [repo, phase_dir])
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

    for plan <- 1..15 do
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
