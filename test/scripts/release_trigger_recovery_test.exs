defmodule Mailglass.Scripts.ReleaseTriggerRecoveryTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @workflow_path Path.expand("../../.github/workflows/release-please.yml", __DIR__)
  @manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @release_target_path Path.expand("../../.planning/release-target.json", __DIR__)
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
    assert preflight =~ "release manifest is missing or unreadable"
    assert preflight =~ "release manifest yielded no expected release tags"
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

  test "checkout precedes preflight and gh queries use the workflow repository" do
    source = workflow_source()
    preflight = extract_step_block!(source, "Detect already-tagged release PR")

    assert preflight =~ "GH_REPO: ${{ github.repository }}"
    assert preflight =~ "gh api --include \"repos/${GH_REPO}/releases/tags/${tag}\""
    assert checkout_precedes_preflight?(source)
    assert tag_checks_precede_pr_parsing?(preflight)

    with_fake_gh(:release_absent, fn temp_dir, env ->
      script = Path.join(temp_dir, "preflight.sh")
      File.write!(script, preflight_script(preflight))

      assert {output, 0} =
               System.cmd("bash", [script],
                 cd: @repo_root,
                 env: Map.to_list(env),
                 stderr_to_stdout: true
               )

      assert output =~ "running release-please"
      assert File.read!(Path.join(temp_dir, "github-output")) =~ "should_run=true"

      calls = File.read!(Path.join(temp_dir, "gh.log"))
      assert calls =~ "test-owner/test-repo api --include repos/test-owner/test-repo/releases/tags/"
      assert calls =~ "test-owner/test-repo pr view"
    end)
  end

  test "preflight fails when checkout did not provide a readable manifest" do
    preflight = extract_step_block!(workflow_source(), "Detect already-tagged release PR")

    with_fake_gh(:release_absent, fn temp_dir, env ->
      script = Path.join(temp_dir, "preflight.sh")
      File.write!(script, preflight_script(preflight))

      assert {output, status} =
               System.cmd("bash", [script],
                 cd: temp_dir,
                 env: Map.to_list(env),
                 stderr_to_stdout: true
               )

      assert status != 0
      assert output =~ "release manifest is missing or unreadable"
      refute should_run?(temp_dir)
    end)
  end

  test "preflight treats only a confirmed 404 as an absent release" do
    preflight = extract_step_block!(workflow_source(), "Detect already-tagged release PR")

    for mode <- [:release_forbidden, :release_api_failure] do
      with_fake_gh(mode, fn temp_dir, env ->
        script = Path.join(temp_dir, "preflight.sh")
        File.write!(script, preflight_script(preflight))

        assert {_output, status} =
                 System.cmd("bash", [script],
                   cd: @repo_root,
                   env: Map.to_list(env),
                   stderr_to_stdout: true
                 )

        assert status != 0
        refute should_run?(temp_dir)
      end)
    end
  end

  test "preflight fails closed when release PR labels cannot be read" do
    preflight = extract_step_block!(workflow_source(), "Detect already-tagged release PR")

    with_fake_gh(:pr_failure, fn temp_dir, env ->
      script = Path.join(temp_dir, "preflight.sh")
      File.write!(script, preflight_script(preflight))

      assert {output, status} =
               System.cmd("bash", [script],
                 cd: @repo_root,
                 env: Map.to_list(env),
                 stderr_to_stdout: true
               )

      assert status != 0
      assert output =~ "could not determine labels"
      refute should_run?(temp_dir)
    end)
  end

  test "empty commit messages check all release states before permitting recovery" do
    preflight = extract_step_block!(workflow_source(), "Detect already-tagged release PR")

    with_fake_gh(:all_present, "", fn temp_dir, env ->
      assert {_output, 0} = run_preflight(preflight, temp_dir, env)
      assert File.read!(Path.join(temp_dir, "github-output")) =~ "should_run=false"
      refute should_run?(temp_dir)
    end)

    with_fake_gh(:partial_release, "", fn temp_dir, env ->
      assert {_output, status} = run_preflight(preflight, temp_dir, env)
      assert status != 0
      refute should_run?(temp_dir)
    end)

    for mode <- [:release_forbidden, :release_api_failure] do
      with_fake_gh(mode, "", fn temp_dir, env ->
        assert {_output, status} = run_preflight(preflight, temp_dir, env)
        assert status != 0
        refute should_run?(temp_dir)
      end)
    end

    with_fake_gh(:release_absent, "", fn temp_dir, env ->
      assert {output, 0} = run_preflight(preflight, temp_dir, env)
      assert output =~ "after confirming all release tags are absent"
      assert should_run?(temp_dir)
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

  test "core/admin-only release synchronization leaves inbound-owned artifacts untouched" do
    sync =
      extract_step_block!(
        workflow_source(),
        "Sync sibling package -> mailglass dep pin on release-please branch"
      )

    assert sync =~ "git show origin/main:.release-please-manifest.json"
    assert sync =~ "INBOUND_CHANGED=false"
    assert sync =~ "INBOUND_CHANGED=true"
    assert sync =~ "if [ \"$INBOUND_CHANGED\" = true ]; then"

    inbound_paths = [
      "mailglass_inbound/README.md",
      "mailglass_inbound/docs/inbound-install.md",
      ".planning/publish/mailglass_inbound-publish-summary.json"
    ]

    inbound_branch = extract_shell_branch(sync, "if [ \"$INBOUND_CHANGED\" = true ]; then")

    Enum.each(inbound_paths, fn path ->
      assert inbound_branch =~ path
    end)

    sync_paths = extract_shell_branch(sync, "SYNC_PATHS=(")
    assert sync_paths =~ "README.md"
    assert sync_paths =~ "mailglass_admin/README.md"

    Enum.each(inbound_paths, fn path ->
      assert sync_paths =~ path
    end)

    assert sync =~ "sync inbound README \\`~>\\` pin + publish-summary to core $CORE_VERSION"
    assert sync =~ "sync core/admin README pins to core $CORE_VERSION"
  end

  test "release target is machine-validated before hands-free auto-merge" do
    source = workflow_source()
    validation = extract_step_block!(source, "Validate automated release target")
    target = Jason.decode!(File.read!(@release_target_path))

    assert target == %{
             "status" => "active",
             "packages" => %{
               "mailglass" => "2.4.0",
               "mailglass_admin" => "2.4.0",
               "mailglass_inbound" => "2.1.1"
             }
           }

    assert validation =~ ".planning/release-target.json"
    assert validation =~ ".release-please-manifest.json"
    assert validation =~ "mailglass_admin/mix.exs"
    assert validation =~ "mailglass_inbound/mix.exs"
    assert validation =~ "Release target mismatch"

    assert step_precedes?(
             source,
             "Validate automated release target",
             "Arm auto-merge on the release PR"
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

    assert protection =~ ~r/failed\s+`cannot_check`\s+outcome/
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

  defp step_precedes?(source, first_name, second_name) do
    {first, _} = :binary.match(source, "- name: #{first_name}")
    {second, _} = :binary.match(source, "- name: #{second_name}")
    first < second
  end

  defp with_fake_gh(mode, fun),
    do: with_fake_gh(mode, "Merge pull request #42 from release-please--branches--main", fun)

  defp with_fake_gh(mode, commit_message, fun) do
    temp_dir =
      Path.join(System.tmp_dir!(), "release-preflight-#{System.unique_integer([:positive])}")

    fake_bin = Path.join(temp_dir, "bin")
    File.mkdir_p!(fake_bin)

    File.write!(Path.join(fake_bin, "gh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    : "${GH_REPO:?missing GH_REPO}"
    printf '%s %s\\n' "$GH_REPO" "$*" >> "$GH_LOG"
    case "$1:$FAKE_GH_MODE" in
      api:release_absent|api:pr_failure)
        printf 'HTTP/2 404 Not Found\\n' >&2
        exit 1
        ;;
      api:all_present)
        printf 'HTTP/2 200 OK\\n'
        exit 0
        ;;
      api:partial_release)
        count=0
        if [ -f "$FAKE_GH_COUNT" ]; then count=$(cat "$FAKE_GH_COUNT"); fi
        count=$((count + 1))
        printf '%s' "$count" > "$FAKE_GH_COUNT"
        if [ "$count" -eq 1 ]; then
          printf 'HTTP/2 200 OK\\n'
          exit 0
        fi
        printf 'HTTP/2 404 Not Found\\n' >&2
        exit 1
        ;;
      api:release_forbidden)
        printf 'HTTP/2 403 Forbidden\\n' >&2
        exit 1
        ;;
      api:release_api_failure)
        printf 'simulated GitHub API failure\\n' >&2
        exit 1
        ;;
      pr:pr_failure)
        printf 'simulated PR query failure\\n' >&2
        exit 1
        ;;
      pr:*)
        printf 'autorelease: pending\\n'
        ;;
      *)
        printf 'unexpected gh invocation: %s\\n' "$*" >&2
        exit 64
        ;;
    esac
    """)

    File.chmod!(Path.join(fake_bin, "gh"), 0o755)

    env = %{
      "PATH" => fake_bin <> ":" <> System.get_env("PATH"),
      "GH_REPO" => "test-owner/test-repo",
      "GH_LOG" => Path.join(temp_dir, "gh.log"),
      "FAKE_GH_COUNT" => Path.join(temp_dir, "gh-count"),
      "FAKE_GH_MODE" => Atom.to_string(mode),
      "GITHUB_OUTPUT" => Path.join(temp_dir, "github-output"),
      "COMMIT_MESSAGE" => commit_message
    }

    try do
      fun.(temp_dir, env)
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp should_run?(temp_dir) do
    output = Path.join(temp_dir, "github-output")
    File.exists?(output) and File.read!(output) =~ "should_run=true"
  end

  defp run_preflight(preflight, temp_dir, env) do
    script = Path.join(temp_dir, "preflight.sh")
    File.write!(script, preflight_script(preflight))

    System.cmd("bash", [script],
      cd: @repo_root,
      env: Map.to_list(env),
      stderr_to_stdout: true
    )
  end

  defp checkout_precedes_preflight?(source) do
    case {
      :binary.match(source, "- name: Checkout triggering revision for release preflight"),
      :binary.match(source, "- name: Detect already-tagged release PR")
    } do
      {{checkout, _}, {preflight, _}} -> checkout < preflight
      _ -> false
    end
  end

  defp tag_checks_precede_pr_parsing?(preflight) do
    {{manifest, _}, {pr_number, _}} =
      {:binary.match(preflight, "manifest=.release-please-manifest.json"),
       :binary.match(preflight, "pr_number=\"\"")}

    manifest < pr_number
  end

  defp preflight_script(preflight) do
    case String.split(preflight, ~r/^\s*run: \|\n/m, parts: 2) do
      [metadata, script] when script != "" ->
        if metadata =~ "GH_REPO: ${{ github.repository }}" and
             script =~ "gh api --include" and script =~ "gh pr view" do
          """
          # macOS's Bash 3 lacks mapfile; GitHub's runner has it. The test
          # harness supplies the equivalent solely so it can execute the
          # extracted workflow script against fake gh on both platforms.
          mapfile() {
            local option="$1" array_name="$2" line
            eval "$array_name=()"
            while IFS= read -r line; do
              eval "$array_name+=(\"$line\")"
            done
          }

          """ <>
            (script
             |> String.split("\n")
             |> Enum.map_join("\n", &String.replace_prefix(&1, "          ", "")))
        else
          raise ArgumentError, "release preflight is missing repository-bound gh commands"
        end

      _ ->
        raise ArgumentError, "could not extract the release preflight shell script"
    end
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
