defmodule Mailglass.Publish.PackageAllowlistPrLaneTest do
  # A stale `.planning/publish/<pkg>-files.expected` used to surface only in
  # publish-hex.yml, after the release tags were cut (2.7.0 publish run
  # 40372273962), and forced a tag move. These contracts pin the PR-time lane:
  # the required Mix Task Tests job runs the allowlist diff for every package.
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @task_path Path.join(@repo_root, "lib/mix/tasks/mailglass.publish.check.ex")
  @step_name "Check package allowlists (all packages)"

  test "the required Mix Task Tests lane runs the allowlist diff for every package" do
    ci = File.read!(@ci_path)
    assert allowlist_lane?(ci)

    job = job_block!(ci, "mix_task_tests")
    assert job =~ "if: needs.changes.outputs.code == 'true'"
    assert File.read!(Path.join(@repo_root, "config/quality/ci_policy.exs")) =~ ~s("mix_task_tests")

    # Negative controls: each mutation must make the predicate fail.
    refute allowlist_lane?(String.replace(ci, "- name: #{@step_name}", "- name: Renamed"))

    refute allowlist_lane?(
             String.replace(
               ci,
               "run: mix mailglass.publish.check --allowlist-only",
               "run: mix mailglass.publish.check --allowlist-only --package mailglass"
             )
           )

    refute allowlist_lane?(
             String.replace(
               ci,
               "run: mix mailglass.publish.check --allowlist-only",
               "run: mix mailglass.publish.check --allowlist-only\n        continue-on-error: true"
             )
           )
  end

  test "allowlist-only mode shares the publish lane's compare and denylist steps" do
    source = File.read!(@task_path)
    assert allowlist_only_mode?(source)

    refute allowlist_only_mode?(String.replace(source, "allowlist_only: :boolean", ""))

    refute allowlist_only_mode?(
             String.replace(
               source,
               ~s|step(counts, :unchanged, package, "compare allowlist", ctx, &verify_allowlist/1)|,
               "{counts, ctx}",
               global: true
             )
           )
  end

  test "an allowlist-only change is code, not docs, for the changed-path gate" do
    ci = File.read!(@ci_path)
    lines = Regex.scan(~r/^\s+(NON_DOC=.*)$/m, ci, capture: :all_but_first) |> List.flatten()
    assert length(lines) == 2, "expected the pull_request and push gates to share one filter"
    assert Enum.uniq(lines) |> length() == 1

    [line] = Enum.uniq(lines)

    assert non_doc(line, ".planning/publish/mailglass-files.expected") ==
             ".planning/publish/mailglass-files.expected"

    assert non_doc(line, ".planning/STATE.md\nprompts/x.md") == ""
    assert non_doc(line, "lib/mailglass.ex\n.planning/STATE.md") == "lib/mailglass.ex"

    # Negative control: the pre-carve-out filter treats the allowlist as docs.
    legacy = ~S"""
    NON_DOC=$(echo "$CHANGED" | grep -v '^\.planning/' | grep -v '^prompts/' || true)
    """

    assert non_doc(legacy, ".planning/publish/mailglass-files.expected") == ""
  end

  defp non_doc(line, changed) do
    {out, 0} =
      System.cmd(
        "bash",
        ["-eo", "pipefail", "-c", String.trim(line) <> ~S(; printf '%s' "$NON_DOC")],
        env: [{"CHANGED", changed}]
      )

    out
  end

  defp allowlist_lane?(ci) do
    job = job_block!(ci, "mix_task_tests")

    case step_block(job, @step_name) do
      nil ->
        false

      step ->
        step =~ ~r/^\s+run: mix mailglass\.publish\.check --allowlist-only\s*$/m and
          not (step =~ "--package") and not (step =~ "continue-on-error")
    end
  end

  defp allowlist_only_mode?(source) do
    with true <- source =~ "allowlist_only: :boolean",
         true <- source =~ "execute_allowlist_only(package, opts[:keep] == true)",
         [_, body] <-
           Regex.run(~r/defp execute_allowlist_only\(.*?\n(.*?)\n  defp /s, source) do
      body =~ "&build_tarball/1" and body =~ "&verify_allowlist/1" and
        body =~ "&verify_denylist/1"
    else
      _ -> false
    end
  end

  defp job_block!(source, job) do
    [_, block] = Regex.run(~r/^  #{job}:\n(.*?)(?=^  [a-z_]+:\n|\z)/ms, source)
    block
  end

  defp step_block(job, name) do
    case Regex.run(~r/^      - name: #{Regex.escape(name)}\n(.*?)(?=^      - name: |\z)/ms, job) do
      [_, block] -> block
      nil -> nil
    end
  end
end
