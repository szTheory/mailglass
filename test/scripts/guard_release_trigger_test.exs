defmodule Mailglass.Scripts.GuardReleaseTriggerTest do
  use ExUnit.Case, async: true

  # Path to the workflow file this test guards.
  @workflow_path Path.expand("../../.github/workflows/guard-release-trigger.yml", __DIR__)

  # Always-reporting trigger types: a fresh status must be posted on every PR
  # update to main so that making Guard Release Trigger a required context does
  # not re-introduce green-but-BLOCKED (a required check that never reports
  # leaves the PR stuck "Expected — waiting for status").
  @required_trigger_types ~w[opened synchronize reopened]

  # The job display name that branch-protection scripts register as the
  # required context string. A mismatch here would make the required context
  # silently never report on any PR.
  @expected_job_name "Guard Release Trigger"

  # ---------------------------------------------------------------------------
  # Test: pull_request trigger targets main
  # ---------------------------------------------------------------------------

  test "guard-release-trigger.yml has a pull_request trigger targeting branches: [main]" do
    {source, pr_trigger_block} = parse_workflow()

    # Anti-vacuity: the parser must have found the pull_request block.
    assert pr_trigger_block != nil,
           "No pull_request trigger found in guard-release-trigger.yml — " <>
             "parser failed or file format changed. Source excerpt:\n#{String.slice(source, 0, 300)}"

    assert pr_trigger_block =~ "main",
           "pull_request trigger does not target branches: [main] in guard-release-trigger.yml.\n" <>
             "Trigger block:\n#{pr_trigger_block}"
  end

  # ---------------------------------------------------------------------------
  # Test: no paths: or paths-ignore: filter on pull_request
  # ---------------------------------------------------------------------------

  test "guard-release-trigger.yml pull_request trigger has NO paths: or paths-ignore: filter (GATE-04)" do
    {_source, pr_trigger_block} = parse_workflow()

    # Anti-vacuity guard: fail loudly if the parser found no pull_request block
    # at all — a format change must never make this test vacuously pass.
    refute pr_trigger_block == nil,
           "Anti-vacuity: no pull_request trigger parsed from guard-release-trigger.yml. " <>
             "A path-filter check against a missing block would vacuously pass. Investigate the file format."

    # A paths: or paths-ignore: key under pull_request would let some PRs skip
    # the workflow entirely, leaving the required context unreported and the PR
    # stuck "Expected". Guard-release-trigger must always run.
    refute pr_trigger_block =~ ~r/^\s*paths:/m,
           "guard-release-trigger.yml has a paths: filter on its pull_request trigger. " <>
             "Remove it — a path filter lets some PRs skip the workflow, causing the required " <>
             "context to never report and leaving the PR stuck \"Expected\".\n" <>
             "Trigger block:\n#{pr_trigger_block}"

    refute pr_trigger_block =~ ~r/^\s*paths-ignore:/m,
           "guard-release-trigger.yml has a paths-ignore: filter on its pull_request trigger. " <>
             "Remove it — same green-but-BLOCKED risk as paths:.\n" <>
             "Trigger block:\n#{pr_trigger_block}"
  end

  # ---------------------------------------------------------------------------
  # Test: always-reporting trigger types
  # ---------------------------------------------------------------------------

  test "guard-release-trigger.yml pull_request types: include always-reporting events (GATE-04)" do
    {_source, pr_trigger_block} = parse_workflow()

    refute pr_trigger_block == nil,
           "Anti-vacuity: no pull_request trigger parsed from guard-release-trigger.yml."

    # Extract the types: value list from the trigger block.
    types_line =
      pr_trigger_block
      |> String.split("\n")
      |> Enum.find(&(&1 =~ ~r/types:/))

    assert types_line != nil,
           "No types: line found in the pull_request trigger block of guard-release-trigger.yml.\n" <>
             "Trigger block:\n#{pr_trigger_block}"

    for event_type <- @required_trigger_types do
      assert types_line =~ event_type,
             "guard-release-trigger.yml pull_request types: must include '#{event_type}' to guarantee " <>
               "a status is always reported on PR #{event_type} events.\n" <>
               "Found: #{types_line}"
    end
  end

  # ---------------------------------------------------------------------------
  # Test: job display name matches required-context string
  # ---------------------------------------------------------------------------

  test "guard-release-trigger.yml job display name is exactly '#{@expected_job_name}'" do
    source = File.read!(@workflow_path)

    # Parse job name: lines (4-space indent)
    job_names =
      source
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^    name: .+$/, &1))
      |> Enum.map(fn line ->
        [[_, name]] = Regex.scan(~r/^    name: (.+)$/, line)
        String.trim(name)
      end)

    assert job_names != [],
           "No job name: lines found in guard-release-trigger.yml — parser or file format changed."

    assert @expected_job_name in job_names,
           "guard-release-trigger.yml job display name must be exactly '#{@expected_job_name}'. " <>
             "This string is registered as the required branch-protection context — a mismatch means " <>
             "the context silently never reports.\n" <>
             "Found job names: #{inspect(job_names)}"
  end

  # ---------------------------------------------------------------------------
  # Parser helpers
  # ---------------------------------------------------------------------------

  # Returns {full_source, pull_request_trigger_block_or_nil}.
  # The pull_request block is the indented section under `on:` → `pull_request:`.
  # We collect: the `  pull_request:` line itself, plus all following lines that
  # are more deeply indented (4+ spaces) — stopping at the first line that is
  # 0-2 spaces indented (a sibling key or top-level section).
  defp parse_workflow do
    source = File.read!(@workflow_path)

    lines = String.split(source, "\n")

    pr_block =
      case Enum.find_index(lines, &(&1 =~ ~r/^\s{2}pull_request:$/)) do
        nil ->
          nil

        start_idx ->
          # Include the pull_request: header line, then take all child lines
          # (indented 4+ spaces or blank/empty within the block).
          [header | rest] = Enum.drop(lines, start_idx)

          children =
            Enum.take_while(rest, fn line ->
              # Stop when we hit a new 0- or 2-space-indented key (sibling or top-level).
              # Blank lines within the block are included; a blank line between
              # pull_request and the next sibling is harmless.
              Regex.match?(~r/^\s{4,}/, line) or line == ""
            end)

          (Enum.join([header | children], "\n"))
      end

    {source, pr_block}
  end
end
