defmodule Mailglass.Scripts.ScheduledControlEvidenceTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @evidence_script Path.join(@repo_root, "scripts/scheduled_control_evidence.sh")
  @append_only_script Path.join(@repo_root, "scripts/check_append_only_evidence.sh")
  @monitor_workflow Path.join(@repo_root, ".github/workflows/scheduled-control-evidence.yml")

  test "bind adds immutable run provenance and renders one canonical digest" do
    in_tmp(fn temp_dir ->
      artifact = Path.join(temp_dir, "release-proposal-control-result.json")
      File.write!(artifact, ~s({"status":"blocked","reason":"proposal_identity_mismatch"}))

      {summary, 0} = bind("release-please", artifact)
      json = artifact |> File.read!() |> Jason.decode!()

      assert json["evidence_schema"] == "mailglass.scheduled-control/v1"
      assert json["control"] == "release-please"
      assert json["event_name"] == "schedule"
      assert json["run_id"] == "16214"
      assert json["workflow_sha"] == String.duplicate("a", 40)
      assert json["head_sha"] == String.duplicate("a", 40)
      assert summary =~ "status: `blocked`"
      assert summary =~ "payload-sha256: `"
    end)
  end

  test "bind writes bounded cannot-check evidence and fails when the producer omitted its result" do
    in_tmp(fn temp_dir ->
      artifact = Path.join(temp_dir, "repo-hygiene.json")

      {summary, status} = bind("repo-hygiene", artifact)
      json = artifact |> File.read!() |> Jason.decode!()

      assert status != 0
      assert json["status"] == "cannot-check"
      assert json["reason"] == "source_result_missing"
      assert json["control"] == "repo-hygiene"
      assert summary =~ "source_result_missing"
    end)
  end

  test "verify-file accepts truthful bounded failure evidence from an exact scheduled run" do
    in_tmp(fn temp_dir ->
      artifact = Path.join(temp_dir, "post-publish-resolution.json")
      run_json = Path.join(temp_dir, "run.json")
      output = Path.join(temp_dir, "verification.json")

      File.write!(artifact, ~s({"status":"blocked","reason":"scheduled_target_not_published"}))
      assert {_, 0} = bind("post-publish-smoke", artifact)
      File.write!(run_json, Jason.encode!(run("post-publish-smoke")))

      assert {_, 0} =
               System.cmd(
                 "bash",
                 [
                   @evidence_script,
                   "verify-file",
                   "--control",
                   "post-publish-smoke",
                   "--artifact",
                   artifact,
                   "--run-json",
                   run_json,
                   "--output",
                   output
                 ],
                 cd: @repo_root,
                 stderr_to_stdout: true
               )

      report = output |> File.read!() |> Jason.decode!()
      assert report["kind"] == "run"
      assert report["evidence_valid"]
      assert report["source_run"]["attempt"] == 1
      assert report["source_run"]["conclusion"] == "failure"
      assert report["result"]["status"] == "blocked"
    end)
  end

  test "verify-file rejects manual provenance and workflow SHA mismatches" do
    in_tmp(fn temp_dir ->
      artifact = Path.join(temp_dir, "release-proposal-control-result.json")
      run_json = Path.join(temp_dir, "run.json")
      output = Path.join(temp_dir, "verification.json")

      File.write!(artifact, ~s({"status":"pending","reason":"no_open_proposal"}))
      assert {_, 0} = bind("release-please", artifact)

      File.write!(
        run_json,
        Jason.encode!(%{run("release-please") | "event" => "workflow_dispatch"})
      )

      assert verify_file_status("release-please", artifact, run_json, output) != 0

      File.write!(
        run_json,
        Jason.encode!(%{run("release-please") | "head_sha" => String.duplicate("b", 40)})
      )

      assert verify_file_status("release-please", artifact, run_json, output) != 0

      File.write!(
        run_json,
        Jason.encode!(%{run("release-please") | "run_attempt" => 2})
      )

      assert verify_file_status("release-please", artifact, run_json, output) != 0
    end)
  end

  test "sweep binds current protected main and emits bounded pending pre-deployment evidence" do
    in_tmp(fn temp_dir ->
      run_sha = String.duplicate("a", 40)
      main_sha = String.duplicate("b", 40)

      current_fixture =
        write_sweep_fixture!(Path.join(temp_dir, "current"), run_sha, run_sha)

      assert {_, 0} = run_sweep(current_fixture)

      current_report = current_fixture.output |> File.read!() |> Jason.decode!()
      assert current_report["kind"] == "sweep"
      assert current_report["expected_main_sha"] == run_sha
      assert get_in(current_report, ["controls", Access.at(0), "source_run", "head_sha"]) == run_sha
      assert get_in(current_report, ["controls", Access.at(0), "source_run", "attempt"]) == 1

      fixture = write_sweep_fixture!(Path.join(temp_dir, "stale"), run_sha, main_sha)

      {output, status} = run_sweep(fixture)

      assert status != 0
      assert output =~ "awaiting_current_main_schedule"

      pending_report = fixture.output |> File.read!() |> Jason.decode!()
      assert pending_report["kind"] == "sweep"
      assert pending_report["status"] == "pending"
      refute pending_report["evidence_valid"]
      assert pending_report["expected_main_sha"] == main_sha

      assert [pending_control] = pending_report["controls"]
      assert pending_control["control"] == "release-please"
      refute pending_control["evidence_valid"]
      assert pending_control["source_run"]["head_sha"] == run_sha
      assert pending_control["result"]["status"] == "pending"
      assert pending_control["result"]["reason"] == "awaiting_current_main_schedule"
    end)
  end

  test "monitor is read-only, consumes trusted code, and covers every scheduled control" do
    workflow = File.read!(@monitor_workflow)
    verifier = File.read!(@evidence_script)

    assert workflow =~ "workflow_run:"
    assert workflow =~ "workflows: [release-please, repo-hygiene, post-publish-smoke]"
    assert workflow =~ "cron: \"47 13 * * *\""
    assert workflow =~ "actions: read"
    assert workflow =~ "contents: read"
    refute workflow =~ ~r/(actions|contents|pull-requests|packages|checks|issues): write/
    refute workflow =~ "secrets."
    assert workflow =~ "ref: refs/heads/main"
    assert workflow =~ "scheduled_control_evidence.sh verify-run"
    assert workflow =~ "scheduled_control_evidence.sh sweep"
    assert workflow =~ "sweep_status=$?"
    assert workflow =~ ~s(exit "$sweep_status")
    assert workflow =~ "if: ${{ always() }}"
    assert verifier =~ ~s([ "$artifact_digest" = "sha256:$archive_sha" ])
    assert verifier =~ "logs do not contain the retained payload digest"

    config =
      @repo_root
      |> Path.join(".github/scheduled-controls.json")
      |> File.read!()
      |> Jason.decode!()

    assert config["evidence_schema"] == "mailglass.scheduled-control/v1"
    assert config["verification_schema"] == "mailglass.scheduled-control-verification/v2"

    assert Enum.map(config["controls"], & &1["id"]) == [
             "release-please",
             "repo-hygiene",
             "post-publish-smoke"
           ]

    assert Enum.map(config["controls"], & &1["max_age_seconds"]) == [10_800, 129_600, 129_600]
  end

  test "each source workflow binds evidence before uploading its retained JSON" do
    for {workflow_file, control, upload_name} <- [
          {"release-please.yml", "release-please", "Upload proposal-only release control result"},
          {"repo-hygiene.yml", "repo-hygiene", "Upload hygiene artifact"},
          {"post-publish-smoke.yml", "post-publish-smoke", "Upload post-publish resolution"}
        ] do
      workflow = File.read!(Path.join(@repo_root, ".github/workflows/#{workflow_file}"))
      binder = "--control #{control}"

      assert workflow =~ binder
      assert index!(workflow, binder) < index!(workflow, "- name: #{upload_name}")
      assert workflow =~ "github.workflow_sha"
      assert workflow =~ "tee -a \"$GITHUB_STEP_SUMMARY\""
    end
  end

  test "append-only gate accepts additions and rejects edits to retained evidence" do
    in_tmp(fn temp_dir ->
      git!(temp_dir, ["init"])
      git!(temp_dir, ["config", "user.email", "test@example.com"])
      git!(temp_dir, ["config", "user.name", "Test"])
      File.mkdir_p!(Path.join(temp_dir, ".github"))

      File.write!(
        Path.join(temp_dir, ".github/scheduled-controls.json"),
        Jason.encode!(%{"append_only_evidence_paths" => ["evidence.md"]})
      )

      File.write!(Path.join(temp_dir, "evidence.md"), "retained line\n")
      git!(temp_dir, ["add", "."])
      git!(temp_dir, ["commit", "-m", "base"])
      base = git!(temp_dir, ["rev-parse", "HEAD"])

      File.write!(Path.join(temp_dir, "evidence.md"), "retained line\nappended line\n")
      git!(temp_dir, ["add", "."])
      git!(temp_dir, ["commit", "-m", "append"])
      appended = git!(temp_dir, ["rev-parse", "HEAD"])

      assert {_, 0} =
               System.cmd("bash", [@append_only_script, base, appended],
                 cd: temp_dir,
                 stderr_to_stdout: true
               )

      File.write!(Path.join(temp_dir, "evidence.md"), "rewritten line\nappended line\n")
      git!(temp_dir, ["add", "."])
      git!(temp_dir, ["commit", "-m", "rewrite"])
      rewritten = git!(temp_dir, ["rev-parse", "HEAD"])

      assert {output, status} =
               System.cmd("bash", [@append_only_script, appended, rewritten],
                 cd: temp_dir,
                 stderr_to_stdout: true
               )

      assert status != 0
      assert output =~ "retained evidence was edited or removed"
    end)
  end

  test "required CI executes the append-only gate and the directory-scoped contract suite" do
    ci = File.read!(Path.join(@repo_root, ".github/workflows/ci.yml"))
    actionlint = File.read!(Path.join(@repo_root, ".github/workflows/actionlint.yml"))
    mix = File.read!(Path.join(@repo_root, "mix.exs"))

    assert ci =~ "scripts/check_append_only_evidence.sh"
    assert ci =~ "mix verify.ci_lane_contract"
    assert mix =~ ~s("verify.ci_lane_contract": [)
    assert mix =~ "test test/scripts/ --warnings-as-errors"
    assert actionlint =~ ".github/scheduled-controls.json"
    assert actionlint =~ "scripts/scheduled_control_evidence.sh"
    assert actionlint =~ "scripts/check_append_only_evidence.sh"
  end

  defp bind(control, artifact) do
    System.cmd(
      "bash",
      [@evidence_script, "bind", "--control", control, "--artifact", artifact],
      cd: @repo_root,
      env: [
        {"GITHUB_EVENT_NAME", "schedule"},
        {"GITHUB_RUN_ID", "16214"},
        {"GITHUB_WORKFLOW_SHA", String.duplicate("a", 40)},
        {"GITHUB_SHA", String.duplicate("a", 40)}
      ],
      stderr_to_stdout: true
    )
  end

  defp verify_file_status(control, artifact, run_json, output) do
    {_, status} =
      System.cmd(
        "bash",
        [
          @evidence_script,
          "verify-file",
          "--control",
          control,
          "--artifact",
          artifact,
          "--run-json",
          run_json,
          "--output",
          output
        ],
        cd: @repo_root,
        stderr_to_stdout: true
      )

    status
  end

  defp write_sweep_fixture!(temp_dir, run_sha, main_sha) do
    File.mkdir_p!(temp_dir)
    bin_dir = Path.join(temp_dir, "bin")
    File.mkdir_p!(bin_dir)
    config = Path.join(temp_dir, "scheduled-controls.json")
    artifact = Path.join(temp_dir, "release-proposal-control-result.json")
    artifact_zip = Path.join(temp_dir, "artifact.zip")
    logs = Path.join(temp_dir, "logs.txt")
    logs_zip = Path.join(temp_dir, "logs.zip")
    output = Path.join(temp_dir, "sweep.json")
    run_json = Path.join(temp_dir, "run.json")
    artifacts_json = Path.join(temp_dir, "artifacts.json")

    File.write!(
      config,
      Jason.encode!(%{
        "schema_version" => 1,
        "evidence_schema" => "mailglass.scheduled-control/v1",
        "verification_schema" => "mailglass.scheduled-control-verification/v2",
        "controls" => [
          %{
            "id" => "release-please",
            "workflow_name" => "release-please",
            "workflow_file" => "release-please.yml",
            "artifact_name" => "release-proposal-control-result-{run_id}",
            "artifact_file" => "release-proposal-control-result.json",
            "max_age_seconds" => 10_800
          }
        ]
      })
    )

    File.write!(
      artifact,
      Jason.encode!(%{
        "evidence_schema" => "mailglass.scheduled-control/v1",
        "control" => "release-please",
        "event_name" => "schedule",
        "run_id" => "16214",
        "workflow_sha" => run_sha,
        "head_sha" => run_sha,
        "status" => "blocked",
        "reason" => "proposal_identity_mismatch"
      })
    )

    zip!(artifact_zip, artifact)
    artifact_archive_digest = sha256!(artifact_zip)
    payload_digest = sha256!(artifact)
    File.write!(logs, "payload-sha256: `#{payload_digest}`\n")
    zip!(logs_zip, logs)

    File.write!(
      run_json,
      Jason.encode!(%{
        "id" => 16_214,
        "run_attempt" => 1,
        "name" => "release-please",
        "event" => "schedule",
        "status" => "completed",
        "conclusion" => "failure",
        "head_branch" => "main",
        "head_sha" => run_sha,
        "html_url" => "https://github.com/example/mailglass/actions/runs/16214",
        "updated_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      })
    )

    File.write!(
      artifacts_json,
      Jason.encode!(%{
        "artifacts" => [
          %{
            "id" => 99,
            "name" => "release-proposal-control-result-16214",
            "expired" => false,
            "digest" => "sha256:#{artifact_archive_digest}"
          }
        ]
      })
    )

    gh = Path.join(bin_dir, "gh")

    File.write!(
      gh,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      case "$*" in
        "api repos/example/mailglass/actions/workflows/release-please.yml/runs?event=schedule&per_page=1 --jq .workflow_runs[0].id") printf '16214\\n' ;;
        "api repos/example/mailglass/actions/runs/16214") cat '#{run_json}' ;;
        "api repos/example/mailglass/actions/runs/16214/artifacts?per_page=100") cat '#{artifacts_json}' ;;
        "api repos/example/mailglass/actions/artifacts/99/zip") cat '#{artifact_zip}' ;;
        "api repos/example/mailglass/actions/runs/16214/logs") cat '#{logs_zip}' ;;
        "api repos/example/mailglass/git/ref/heads/main --jq .object.sha") printf '%s\\n' '#{main_sha}' ;;
        *) printf 'unexpected gh call: %s\\n' "$*" >&2; exit 64 ;;
      esac
      """
    )

    File.chmod!(gh, 0o755)

    %{bin_dir: bin_dir, config: config, output: output}
  end

  defp run_sweep(fixture) do
    System.cmd(
      "bash",
      [@evidence_script, "sweep", "--output", fixture.output],
      cd: @repo_root,
      env: [
        {"PATH", "#{fixture.bin_dir}:#{System.fetch_env!("PATH")}"},
        {"GITHUB_REPOSITORY", "example/mailglass"},
        {"SCHEDULED_CONTROL_CONFIG", fixture.config}
      ],
      stderr_to_stdout: true
    )
  end

  defp zip!(archive, file) do
    {_, 0} = System.cmd("zip", ["-q", "-j", archive, file])
  end

  defp sha256!(file) do
    {digest, 0} = System.cmd("shasum", ["-a", "256", file])
    digest |> String.split() |> hd()
  end

  defp run(workflow_name) do
    %{
      "id" => 16_214,
      "run_attempt" => 1,
      "name" => workflow_name,
      "event" => "schedule",
      "status" => "completed",
      "conclusion" => "failure",
      "head_branch" => "main",
      "head_sha" => String.duplicate("a", 40),
      "html_url" => "https://github.com/szTheory/mailglass/actions/runs/16214",
      "updated_at" => "2026-08-25T12:30:00Z"
    }
  end

  defp index!(source, needle) do
    {index, _length} = :binary.match(source, needle)
    index
  end

  defp git!(directory, arguments) do
    {output, 0} = System.cmd("git", arguments, cd: directory, stderr_to_stdout: true)
    String.trim(output)
  end

  defp in_tmp(fun) do
    temp_dir =
      Path.join(
        System.tmp_dir!(),
        "mailglass-scheduled-control-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(temp_dir)
    File.mkdir_p!(temp_dir)

    try do
      fun.(temp_dir)
    after
      File.rm_rf!(temp_dir)
    end
  end
end
