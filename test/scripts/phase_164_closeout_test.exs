defmodule Mailglass.Scripts.Phase164CloseoutTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/closeout_repository_truth.sh")
  @extension Path.join(@repo_root, ".gsd/extensions/finalize-phase/index.ts")
  @manifest Path.join(
              @repo_root,
              ".gsd/extensions/finalize-phase/extension-manifest.json"
            )
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
    assert source =~ "exitCode"
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
          ~s(source "$1"; scheduled_report_is_acceptable "$2" "$3"),
          "phase-164-closeout-test",
          @script,
          report_path,
          expected_sha
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
        "event" => "schedule",
        "status" => "completed",
        "head_branch" => "main",
        "head_sha" => sha,
        "updated_at" => updated_at
      },
      "result" => %{
        "status" => status,
        "reason" => "fixture_result",
        "workflow_sha" => sha,
        "payload_sha256" => String.duplicate("f", 64)
      }
    }
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
