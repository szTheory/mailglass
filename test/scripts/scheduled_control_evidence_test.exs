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
      assert report["evidence_valid"]
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
    assert verifier =~ ~s([ "$artifact_digest" = "sha256:$archive_sha" ])
    assert verifier =~ "logs do not contain the retained payload digest"

    config =
      @repo_root
      |> Path.join(".github/scheduled-controls.json")
      |> File.read!()
      |> Jason.decode!()

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

  defp run(workflow_name) do
    %{
      "id" => 16_214,
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
