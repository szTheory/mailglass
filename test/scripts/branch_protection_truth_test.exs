defmodule Mailglass.Scripts.BranchProtectionTruthTest do
  use ExUnit.Case, async: true

  @ci_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @scheduled_path Path.expand("../../.github/workflows/branch-protection-drift.yml", __DIR__)
  @outcome_path Path.expand("../../scripts/branch-protection-outcome.sh", __DIR__)

  test "Branch Protection Advisory reports a closed, fail-loud verification outcome" do
    source = File.read!(@ci_path)
    outcome_source = File.read!(@outcome_path)
    job = extract_job_block(source, "branch_protection_advisory")
    verify = extract_step_block(job, "Verify branch protection")
    report = extract_step_block(job, "Report branch protection outcome")

    assert job != "", "branch_protection_advisory job parser returned an empty block"
    assert verify != "", "Verify branch protection step parser returned an empty block"
    assert report != "", "Report branch protection outcome step parser returned an empty block"

    assert verify =~ "./scripts/branch-protection-outcome.sh probe main"
    assert outcome_source =~ "verify-branch-protection.sh"
    assert verify =~ "continue-on-error: true"
    assert outcome_source =~ "classification=\"clean\""
    assert outcome_source =~ "classification=\"drift\""
    assert outcome_source =~ "cannot_check"
    assert report =~ "if: always()"
    assert report =~ "./scripts/branch-protection-outcome.sh report"
    assert outcome_source =~ "Live branch protection matches"
    assert outcome_source =~ "Live branch protection drifted"
    assert outcome_source =~ "Could not verify live branch protection"
    assert outcome_source =~ "[ \"${classification}\" = \"clean\" ]"
  end

  test "Branch Protection Advisory remains publish-gating and outside CI Green" do
    ci_source = File.read!(@ci_path)
    job = extract_job_block(ci_source, "ci_green")

    assert job != "", "ci_green job parser returned an empty block"
    refute job =~ "branch_protection_advisory"
    assert "Branch Protection Advisory" in Mailglass.CILanes.publish_gating_lanes()
  end

  test "the shared outcome seam is a hermetic clean read-only integration path" do
    with_fake_github("clean", fn temp_dir, env ->
      assert {"clean\n", 0} = run_outcome(["probe", "main"], env)

      assert {summary, 0} =
               run_outcome(
                 ["report", "clean"],
                 Map.put(env, "GITHUB_STEP_SUMMARY", Path.join(temp_dir, "summary.md"))
               )

      assert summary == ""

      assert File.read!(Path.join(temp_dir, "summary.md")) =~
               "matches the expected read-only ruleset"

      assert gh_calls(temp_dir) =~ "protection"
      refute gh_calls(temp_dir) =~ "-X PUT"
    end)
  end

  test "the shared outcome seam preserves drift as non-green without mutating in read-only mode" do
    with_fake_github("drift", fn temp_dir, env ->
      assert {"drift\n", 0} = run_outcome(["probe", "main"], env)
      summary_path = Path.join(temp_dir, "summary.md")

      assert {"", 1} =
               run_outcome(
                 ["report", "drift"],
                 Map.put(env, "GITHUB_STEP_SUMMARY", summary_path)
               )

      assert File.read!(summary_path) =~ "drifted"
      refute gh_calls(temp_dir) =~ "-X PUT"
    end)
  end

  test "the shared outcome seam classifies missing token, gh, jq, and API failures as cannot_check" do
    with_fake_github("clean", fn _temp_dir, env ->
      assert {"cannot_check\n", 0} = run_outcome(["probe", "main"], Map.delete(env, "GH_TOKEN"))

      assert {"cannot_check\n", 0} =
               run_outcome(["probe", "main"], %{"PATH" => "/usr/bin:/bin"})

      fake_bin = env |> Map.fetch!("PATH") |> String.split(":") |> hd()
      File.write!(Path.join(fake_bin, "jq"), "#!/usr/bin/env bash\nexit 127\n")
      File.chmod!(Path.join(fake_bin, "jq"), 0o755)

      assert {"cannot_check\n", 0} =
               run_outcome(["probe", "main"], env)
    end)

    with_fake_github("api_failure", fn _temp_dir, env ->
      assert {"cannot_check\n", 0} = run_outcome(["probe", "main"], env)
    end)
  end

  test "scheduled reassertion verifies with GET before PUT and keeps observed drift sticky" do
    with_fake_github("drift", fn temp_dir, env ->
      assert {output, 0} = run_outcome(["probe", "--reassert", "main"], env)
      assert String.ends_with?(output, "drift\n")

      calls = gh_calls(temp_dir)
      get_index = index_of(calls, "branches/main/protection")
      put_index = index_of(calls, "-X PUT")

      assert is_integer(get_index), "expected canonical verifier GET in #{inspect(calls)}"
      assert is_integer(put_index), "expected canonical reassertion PUT in #{inspect(calls)}"
      assert get_index < put_index, "scheduled reassertion must verify before it mutates"
    end)
  end

  test "scheduled workflow consumes the shared probe before its authoritative reporter" do
    source = File.read!(@scheduled_path)
    job = extract_job_block(source, "reassert-protection")
    probe = extract_step_block(job, "Verify and re-assert branch protection")
    report = extract_step_block(job, "Report branch protection outcome")

    assert job != "", "reassert-protection job parser returned an empty block"
    assert probe != "", "scheduled outcome probe parser returned an empty block"
    assert report != "", "scheduled outcome reporter parser returned an empty block"
    assert source =~ "cron: \"37 6 * * *\""
    assert probe =~ "./scripts/branch-protection-outcome.sh probe --reassert main"
    assert report =~ "if: always()"
    assert report =~ "./scripts/branch-protection-outcome.sh report"
  end

  defp with_fake_github(mode, fun) do
    temp_dir =
      Path.join(System.tmp_dir!(), "branch-protection-truth-#{System.unique_integer([:positive])}")

    File.mkdir_p!(temp_dir)
    fake_bin = Path.join(temp_dir, "bin")
    File.mkdir_p!(fake_bin)
    log_path = Path.join(temp_dir, "gh.log")
    write_fake_gh!(Path.join(fake_bin, "gh"))
    File.ln_s!(System.find_executable("bash"), Path.join(fake_bin, "bash"))

    env = %{
      "PATH" => fake_bin <> ":" <> System.get_env("PATH"),
      "GH_TOKEN" => "test-token",
      "GITHUB_REPOSITORY_OWNER" => "test-owner",
      "GITHUB_REPOSITORY" => "test-repo",
      "GH_LOG" => log_path,
      "FAKE_GH_MODE" => mode
    }

    try do
      fun.(temp_dir, env)
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp run_outcome(arguments, env) do
    System.cmd("bash", [@outcome_path | arguments], env: Map.to_list(env), stderr_to_stdout: true)
  end

  defp gh_calls(temp_dir), do: File.read!(Path.join(temp_dir, "gh.log"))

  defp index_of(value, needle) do
    case String.split(value, needle, parts: 2) do
      [_] -> nil
      [before, _after] -> byte_size(before)
    end
  end

  defp write_fake_gh!(path) do
    File.write!(path, """
    #!/usr/bin/env bash
    set -euo pipefail
    printf '%s\\n' "$*" >> "$GH_LOG"

    if [[ "$*" == *"-X PUT"* ]]; then
      cat >/dev/null
      exit 0
    fi

    if [ "$FAKE_GH_MODE" = "api_failure" ]; then
      echo "simulated API failure" >&2
      exit 1
    fi

    strict=true
    if [ "$FAKE_GH_MODE" = "drift" ]; then strict=false; fi
    cat <<JSON
    {"required_status_checks":{"strict":$strict,"contexts":["CI Green","Guard Release Trigger"]},"enforce_admins":{"enabled":false},"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false},"block_creations":{"enabled":false},"required_conversation_resolution":{"enabled":false},"lock_branch":{"enabled":false},"allow_fork_syncing":{"enabled":false}}
    JSON
    """)

    File.chmod!(path, 0o755)
  end

  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] ->
        rest
        |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2)
        |> hd()
        |> then(&(marker <> &1))

      _ ->
        ""
    end
  end

  defp extract_step_block(job_block, step_name) do
    marker = "      - name: #{step_name}\n"

    case String.split(job_block, marker, parts: 2) do
      [_, rest] ->
        rest
        |> String.split("\n      - name:", parts: 2)
        |> hd()
        |> then(&(marker <> &1))

      _ ->
        ""
    end
  end
end
