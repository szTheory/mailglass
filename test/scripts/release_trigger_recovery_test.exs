defmodule Mailglass.Scripts.ReleaseTriggerRecoveryTest do
  use ExUnit.Case, async: true

  @workflow_path Path.expand("../../.github/workflows/release-please.yml", __DIR__)
  @manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)

  test "release-please retains the complete recovery trigger set" do
    source = File.read!(@workflow_path)

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
    source = File.read!(@workflow_path)
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

  test "release action is mutually guarded by preflight output" do
    source = File.read!(@workflow_path)
    action = extract_action_block!(source, "release")

    assert action =~ "googleapis/release-please-action@"
    assert release_action_guarded?(source)

    refute release_action_guarded?(
             String.replace(source, "steps.release-preflight.outputs.should_run == 'true'", "true",
               global: false
             )
           )
  end

  defp recovery_triggers?(source) do
    push = extract_trigger_block!(source, "push")
    manual = extract_trigger_block!(source, "workflow_dispatch")
    schedule = extract_trigger_block!(source, "schedule")

    push =~ "branches:\n      - main" and
      manual =~ "workflow_dispatch: {}" and
      schedule =~ "cron: \"17 * * * *\""
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
end
