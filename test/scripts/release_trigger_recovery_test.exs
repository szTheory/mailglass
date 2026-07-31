defmodule Mailglass.Scripts.ReleaseTriggerRecoveryTest do
  use ExUnit.Case, async: true

  @workflow_path Path.expand("../../.github/workflows/release-please.yml", __DIR__)
  @manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @contributing_path Path.expand("../../CONTRIBUTING.md", __DIR__)
  @recovery_runbook_facts [
    "GitHub-native auto-merge",
    "GITHUB_TOKEN",
    "minute 17",
    "hourly",
    "up to one hour",
    "roughly 30 minutes",
    "all expected tags",
    "autorelease: tagged",
    "partial linked-tag state",
    "requires reconciliation",
    "workflow_dispatch",
    "Direct manual recovery",
    "manually creating the missing GitHub releases",
    "release: published"
  ]

  test "release-please retains the complete recovery trigger set" do
    source = workflow_source()

    assert extract_trigger_block!(source, "push") =~ "branches:\n      - main"
    assert extract_trigger_block!(source, "workflow_dispatch") =~ "workflow_dispatch: {}"
    assert extract_trigger_block!(source, "schedule") =~ "cron: \"17 * * * *\""

    Enum.each(["push", "workflow_dispatch", "schedule"], fn trigger ->
      broken = String.replace(source, "  #{trigger}:", "  removed-#{trigger}:", global: false)

      assert_raise ExUnit.AssertionError, fn ->
        recovery_triggers?(broken)
      end
    end)
  end

  test "preflight derives its expected tags from the manifest and converges every release state" do
    source = workflow_source()
    preflight = extract_step_block!(source, "Detect already-tagged release PR")

    assert File.exists?(@manifest_path)
    assert preflight =~ ".release-please-manifest.json"
    assert preflight =~ "to_entries[]"
    assert preflight =~ "mailglass-v\\($version)"
    assert preflight =~ "${#present_tags[@]}"
    assert preflight =~ "${#missing_tags[@]}"

    assert full_tags_noop?(preflight)
    assert partial_tags_fail?(preflight)
    assert tagged_release_noop?(preflight)
    assert pending_release_runs?(preflight)

    refute full_tags_noop?(
             String.replace(preflight, "echo \"should_run=false\"", "", global: false)
           )

    refute partial_tags_fail?(
             String.replace(preflight, "Partial release state detected", "", global: false)
           )

    refute tagged_release_noop?(
             String.replace(preflight, "grep -qx 'autorelease: tagged'", "grep -qx 'removed'",
               global: false
             )
           )

    refute pending_release_runs?(
             String.replace(preflight, "Release PR #$pr_number is not fully published yet", "",
               global: false
             )
           )
  end

  test "preflight binds gh to the workflow repository without a checkout" do
    preflight = extract_step_block!(workflow_source(), "Detect already-tagged release PR")

    assert preflight =~ "GH_REPO: ${{ github.repository }}"

    with_fake_gh(fn temp_dir, env ->
      File.cp!(@manifest_path, Path.join(temp_dir, ".release-please-manifest.json"))
      File.write!(Path.join(temp_dir, "preflight.sh"), preflight_script(preflight))

      assert {output, 0} =
               System.cmd("bash", ["preflight.sh"],
                 cd: temp_dir,
                 env: Map.to_list(env),
                 stderr_to_stdout: true
               )

      assert output =~ "running release-please"
      assert File.read!(Path.join(temp_dir, "github-output")) =~ "should_run=true"

      calls = File.read!(Path.join(temp_dir, "gh.log"))
      assert calls =~ "test-owner/test-repo release view"
      assert calls =~ "test-owner/test-repo pr view"
    end)
  end

  test "release action is mutually guarded by preflight output" do
    source = workflow_source()
    action = extract_action_block!(source, "release")

    assert action =~ "googleapis/release-please-action@"
    assert release_action_guarded?(source)

    refute release_action_guarded?(
             String.replace(source, "steps.release-preflight.outputs.should_run == 'true'", "true",
               global: false
             )
           )
  end

  test "contributing documents the bounded hourly recovery and manual fallbacks" do
    recovery_runbook =
      extract_markdown_section!(
        File.read!(@contributing_path),
        "If a release publishes but the tags/publish never fire"
      )

    assert recovery_runbook?(recovery_runbook)
    refute recovery_runbook =~ "runs only `on: push: main`"

    refute recovery_runbook?(
             String.replace(recovery_runbook, "minute 17", "minute 18", global: true)
           )

    refute recovery_runbook?(
             String.replace(recovery_runbook, "up to one hour", "immediately", global: false)
           )

    refute recovery_runbook?(
             String.replace(recovery_runbook, "workflow_dispatch", "manual dispatch", global: true)
           )
  end

  test "contributing documents the PAT-backed CI trigger and fail-loud branch-protection outcome" do
    source = File.read!(@contributing_path)

    sync =
      extract_markdown_section!(
        source,
        "How release-please syncs README install pins (and what it no longer does)"
      )

    protection = extract_markdown_section!(source, "One-time setup: branch protection automation")

    assert sync =~ "RELEASE_PLEASE_PAT"
    assert sync =~ "pull_request: synchronize"
    refute sync =~ "sync push uses `GITHUB_TOKEN`"

    assert protection =~ "failed `cannot_check` outcome"
    refute protection =~ "no-ops and posts a notice"
  end

  defp recovery_triggers?(source) do
    push = extract_trigger_block!(source, "push")
    manual = extract_trigger_block!(source, "workflow_dispatch")
    schedule = extract_trigger_block!(source, "schedule")

    push =~ "branches:\n      - main" and
      manual =~ "workflow_dispatch: {}" and
      schedule =~ "cron: \"17 * * * *\""
  end

  defp workflow_source, do: File.read!(@workflow_path)

  defp with_fake_gh(fun) do
    temp_dir =
      Path.join(System.tmp_dir!(), "release-preflight-#{System.unique_integer([:positive])}")

    fake_bin = Path.join(temp_dir, "bin")
    File.mkdir_p!(fake_bin)

    File.write!(Path.join(fake_bin, "gh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    : "${GH_REPO:?missing GH_REPO}"
    printf '%s %s\\n' "$GH_REPO" "$*" >> "$GH_LOG"
    if [ "$1" = "release" ]; then exit 1; fi
    printf 'autorelease: pending\\n'
    """)

    File.chmod!(Path.join(fake_bin, "gh"), 0o755)

    env = %{
      "PATH" => fake_bin <> ":" <> System.get_env("PATH"),
      "GH_REPO" => "test-owner/test-repo",
      "GH_LOG" => Path.join(temp_dir, "gh.log"),
      "GITHUB_OUTPUT" => Path.join(temp_dir, "github-output"),
      "COMMIT_MESSAGE" => "Merge pull request #42 from release-please--branches--main"
    }

    try do
      fun.(temp_dir, env)
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp preflight_script(preflight) do
    [_, script] = String.split(preflight, "        run: |\\n", parts: 2)

    script
    |> String.split("\\n")
    |> Enum.map_join("\\n", &String.replace_prefix(&1, "          ", ""))
  end

  defp recovery_runbook?(section) do
    Enum.all?(@recovery_runbook_facts, &String.contains?(section, &1))
  end

  defp full_tags_noop?(preflight) do
    branch = extract_shell_branch(preflight, "if [ \"${#missing_tags[@]}\" -eq 0 ]; then")

    branch =~ "All expected release tags already exist" and branch =~ "echo \"should_run=false\""
  end

  defp partial_tags_fail?(preflight) do
    preflight =~ "if [ \"${#present_tags[@]}\" -gt 0 ] && [ \"${#missing_tags[@]}\" -gt 0 ]; then" and
      preflight =~ "Partial release state detected" and preflight =~ "exit 1"
  end

  defp tagged_release_noop?(preflight) do
    branch =
      extract_shell_branch(preflight, "if grep -qx 'autorelease: tagged' <<<\"$labels\"; then")

    branch =~ "already tagged; skipping release-please rerun" and
      branch =~ "echo \"should_run=false\""
  end

  defp pending_release_runs?(preflight) do
    preflight =~ "Release PR #$pr_number is not fully published yet; running release-please." and
      preflight =~ "echo \"should_run=true\""
  end

  defp release_action_guarded?(source) do
    action = extract_action_block!(source, "release")

    action =~ "uses: googleapis/release-please-action@" and
      action =~ "if: ${{ steps.release-preflight.outputs.should_run == 'true' }}"
  end

  defp extract_trigger_block!(source, trigger) do
    lines = String.split(source, "\n")

    start_index =
      Enum.find_index(lines, fn line ->
        line == "  #{trigger}:" or line == "  #{trigger}: {}"
      end)

    assert start_index != nil, "expected nonempty #{trigger} trigger block"

    block =
      lines
      |> Enum.drop(start_index)
      |> Enum.take_while(fn line ->
        line == "" or String.starts_with?(line, "    ") or
          line == "  #{trigger}:" or line == "  #{trigger}: {}"
      end)
      |> Enum.join("\n")

    assert String.trim(block) != "", "#{trigger} trigger block must not be empty"
    block
  end

  defp extract_step_block!(source, name) do
    extract_bounded_block!(source, "      - name: #{name}", "step #{name}")
  end

  defp extract_action_block!(source, id) do
    extract_bounded_block!(source, "      - id: #{id}", "action #{id}")
  end

  defp extract_bounded_block!(source, header, description) do
    lines = String.split(source, "\n")
    start_index = Enum.find_index(lines, &(&1 == header))

    assert start_index != nil, "expected #{description} header #{inspect(header)}"

    block =
      lines
      |> Enum.drop(start_index)
      |> Enum.take_while(fn line ->
        line == header or line == "" or not String.starts_with?(line, "      - ")
      end)
      |> Enum.join("\n")

    assert String.trim(block) != "", "#{description} block must not be empty"
    block
  end

  defp extract_shell_branch(source, header) do
    case String.split(source, header, parts: 2) do
      [_, after_header] ->
        [branch | _] = String.split(after_header, "\n          fi", parts: 2)
        branch

      _ ->
        ""
    end
  end

  defp extract_markdown_section!(source, heading) do
    header = "## #{heading}"
    [_, after_header] = String.split(source, header, parts: 2)
    [section | _] = String.split(after_header, ~r/\n## /, parts: 2)

    assert String.trim(section) != "", "#{header} section must not be empty"
    section
  end
end
