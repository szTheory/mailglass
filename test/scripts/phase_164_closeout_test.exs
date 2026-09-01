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
  @ledger Path.join(
            @repo_root,
            ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
          )

  test "rejects a sibling checkout and a foreign symlink before component collection" do
    root = temporary_root!()
    sibling = @repo_root <> "-disposable"
    File.mkdir_p!(sibling)

    on_exit(fn ->
      File.rm_rf!(root)
      File.rm_rf!(sibling)
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
      System.cmd("git", ["-C", root, "remote", "add", "origin", "git@github.com:szTheory/mailglass.git"])

    command = ~s(repository_identity_is_authoritative "$2" "$3")
    assert {_, 0} = source_finalizer(command, [root, "szTheory/mailglass"])

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
            %{"id" => id, "workflow_name" => id}
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
