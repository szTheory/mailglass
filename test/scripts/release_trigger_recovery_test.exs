defmodule Mailglass.Scripts.ReleaseTriggerRecoveryTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @workflow_path Path.expand("../../.github/workflows/release-please.yml", __DIR__)
  @manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @release_target_path Path.expand("../../.planning/release-target.json", __DIR__)
  @release_policy_path Path.expand("../../scripts/release_policy.exs", __DIR__)
  @contributing_path Path.expand("../../CONTRIBUTING.md", __DIR__)
  @recovery_runbook_facts [
    "minute 17",
    "proposal-only",
    "cannot merge it, create a tag, or publish",
    "workflow_dispatch",
    "Protected exact-digest chain",
    "authorization checkpoint",
    "release-please.yml",
    "publish-hex.yml",
    "package=all",
    "immutable proposal",
    "core → admin → inbound",
    "credential-free and read-only",
    "Do not manually create"
  ]

  setup_all do
    Code.require_file(@release_policy_path)
    :ok
  end

  test "release-please retains the complete recovery trigger set" do
    source = workflow_source()

    assert extract_trigger_block!(source, "push") =~ "branches:\n      - main"
    assert extract_trigger_block!(source, "workflow_dispatch") =~ "candidate_digest:"
    assert extract_trigger_block!(source, "schedule") =~ "cron: \"17 * * * *\""

    Enum.each(["push", "workflow_dispatch", "schedule"], fn trigger ->
      broken = String.replace(source, "  #{trigger}:", "  removed-#{trigger}:", global: false)

      assert_raise ExUnit.AssertionError, fn ->
        recovery_triggers?(broken)
      end
    end)
  end

  test "preflight delegates exact tag derivation to the versioned policy owner and converges every release state" do
    source = workflow_source()
    preflight = extract_step_block!(source, "Detect already-tagged release PR")
    policy = File.read!(Path.join(@repo_root, "scripts/release_policy.exs"))

    assert File.exists?(@manifest_path)
    assert preflight =~ ".release-please-manifest.json"
    assert preflight =~ ".planning/release-target.json"
    assert preflight =~ "scripts/release_policy_expected_tags.sh"
    assert preflight =~ "Protected release target owns these tags"
    assert preflight =~ "release manifest is missing or unreadable"
    assert preflight =~ "release manifest yielded no expected release tags"
    assert policy =~ "def expected_tags"
    assert policy =~ "def manifest_tags"
    assert policy =~ "mailglass_inbound"
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

    assert source =~ "- name: Checkout protected main for release preflight"
    assert source =~ "ref: refs/heads/main"
    assert source =~ "fetch-depth: 0"
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
                 env: Map.to_list(Map.put(env, "CANDIDATE_DIGEST", String.duplicate("d", 64))),
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
                 env: Map.to_list(Map.put(env, "CANDIDATE_DIGEST", String.duplicate("d", 64))),
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
                   env: Map.to_list(Map.put(env, "CANDIDATE_DIGEST", String.duplicate("d", 64))),
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
                 env: Map.to_list(Map.put(env, "CANDIDATE_DIGEST", String.duplicate("d", 64))),
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

  test "protected exact dispatch survives the authorization-only main advance without weakening identity" do
    source = workflow_source()

    validation = extract_step_block!(source, "Validate protected exact candidate dispatch")

    merge =
      extract_step_block!(
        source,
        "Protected exact candidate dispatch may merge only the validated release PR"
      )

    assert validation =~ ~s([ "$base" = "$source_sha" ])
    refute validation =~ ~s([ "$base" = "$current_main_sha" ])
    assert validation =~ ~s(gh pr checks "$number" --required)
    assert validation =~ ~s(git merge-base --is-ancestor "$source_sha" "$current_main_sha")
    assert validation =~ "source_content_digest"
    assert validation =~ "main_content_digest"

    assert merge =~ "GH_TOKEN: ${{ secrets.RELEASE_PLEASE_PAT }}"
    assert merge =~ ~s(gh pr merge "$NUMBER" --admin --squash)
    assert merge =~ ~s(--match-head-commit "$PROPOSAL_HEAD")
  end

  test "core/admin-only release synchronization refreshes inbound compatibility without bumping inbound" do
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

    sync_paths = extract_shell_branch(sync, "SYNC_PATHS=(")
    assert sync_paths =~ "README.md"
    assert sync_paths =~ "mailglass_admin/README.md"

    Enum.each(inbound_paths, fn path ->
      assert sync_paths =~ path
    end)

    assert sync =~ "sync inbound README \\`~>\\` pin + publish-summary to core $CORE_VERSION"
    assert sync =~ "--argjson inbound_changed \"$INBOUND_CHANGED\""
    assert sync =~ "if $inbound_changed then .version=$v"
    assert sync =~ "sync linked package pins to core $CORE_VERSION"
  end

  test "versioned release target and proposal-only capture stay lifecycle-safe" do
    source = workflow_source()

    validation =
      extract_step_block!(source, "Capture Release Please proposal identity without activation")

    target = Jason.decode!(File.read!(@release_target_path))

    assert target["schema_version"] == 1
    assert target["package_set"] == ["mailglass", "mailglass_admin", "mailglass_inbound"]
    assert {:ok, ^target} = apply(release_policy(), :validate_target, [target])

    assert validation =~ ".planning/release-target.json"
    assert validation =~ "gh pr list --head release-please--branches--main"
    assert validation =~ "proposal-candidate.json"
    assert validation =~ "capture-candidate"
    assert validation =~ "captured|authorized)"
    assert validation =~ "completed)"
    assert validation =~ "proposal/source identity"

    assert step_precedes?(
             source,
             "Sync sibling package -> mailglass dep pin on release-please branch",
             "Capture Release Please proposal identity without activation"
           )
  end

  test "proposal capture persists one bounded proposal-only result before any non-pass exit" do
    source = workflow_source()

    capture =
      extract_step_block!(source, "Capture Release Please proposal identity without activation")

    result =
      extract_step_block!(source, "Write proposal-only release control result")

    summary = extract_step_block!(source, "Summarize proposal-only release control result")
    upload = extract_step_block!(source, "Upload proposal-only release control result")

    assert capture =~ "continue-on-error: true"
    assert capture =~ "result_status"
    assert capture =~ "result_reason"

    assert result =~ "release-proposal-control-result.json"
    assert result =~ "status"
    assert result =~ "reason"
    assert result =~ "event_name"
    assert result =~ "run_id"
    assert result =~ "proposal_head"
    assert result =~ "source_sha"
    assert result =~ "candidate_digest"
    assert result =~ "attempted_candidates"
    assert result =~ "required_checks"
    assert result =~ "permissions"
    assert result =~ "trigger"
    assert result =~ "result_artifact"
    assert result =~ "pending"
    assert result =~ "cannot-check"
    assert result =~ "blocked"
    assert summary =~ "if: ${{ always() }}"
    assert summary =~ "release-proposal-control-result.json"
    assert upload =~ "if: ${{ always() }}"
    assert upload =~ "release-proposal-control-result-${{ github.run_id }}"

    Enum.each(
      [
        {"success", "pass", "proposal_captured"},
        {"blocked", "blocked", "proposal_identity_mismatch"},
        {"failure", "cannot-check", "github_evidence_unavailable"}
      ],
      fn {outcome, expected_status, expected_reason} ->
        with_proposal_result_env(outcome, expected_status, expected_reason, fn temp_dir, env ->
          script = Path.join(temp_dir, "proposal-result.sh")
          File.write!(script, proposal_result_script(result))

          {_, command_status} =
            System.cmd("bash", [script],
              cd: @repo_root,
              env: Map.to_list(env),
              stderr_to_stdout: true
            )

          assert command_status == if(expected_status == "pass", do: 0, else: 1)

          outcome_json =
            temp_dir
            |> Path.join("release-proposal-control-result.json")
            |> File.read!()
            |> Jason.decode!()

          assert outcome_json["status"] == expected_status
          assert outcome_json["reason"] == expected_reason
          assert outcome_json["event_name"] == "workflow_dispatch"
          assert outcome_json["run_id"] == "16202"
          assert outcome_json["candidate_digest"] == String.duplicate("a", 64)
          assert Enum.all?(outcome_json["probes"], &Map.has_key?(&1, "source"))
          assert Enum.all?(outcome_json["probes"], &Map.has_key?(&1, "status"))
        end)
      end
    )

    protected =
      extract_step_block!(source, "Validate protected exact candidate dispatch") <>
        extract_step_block!(
          source,
          "Protected exact candidate dispatch may merge only the validated release PR"
        )

    assert protected =~ "gh pr merge"
    assert protected =~ "CANDIDATE_DIGEST"
    refute result =~ "gh pr merge"
    refute result =~ "git tag"
    refute result =~ "gh release"
  end

  test "protected exact-digest release bypasses proposal-only control after its merge leaves no open proposal" do
    source = workflow_source()

    validation = extract_step_block!(source, "Validate protected exact candidate dispatch")

    merge =
      extract_step_block!(
        source,
        "Protected exact candidate dispatch may merge only the validated release PR"
      )

    proposal_tail = [
      {"Capture Release Please proposal identity without activation", "capture-proposal"},
      {"Write proposal-only release control result", "proposal-control-result"},
      {"Summarize proposal-only release control result", "summary"},
      {"Upload proposal-only release control result", "upload"},
      {"Fail non-pass proposal control result after evidence upload", "final gate"}
    ]

    assert validation =~ "gh pr checks \"$number\" --required"
    assert validation =~ "[ \"$head\" = \"$proposal_head\" ]"
    assert validation =~ "[ \"$base\" = \"$source_sha\" ]"
    assert validation =~ "[ \"$actual_digest\" = \"$content_digest\" ]"
    assert merge =~ "gh pr merge \"$NUMBER\" --admin --squash"
    assert merge =~ "merge_tree_verified=true"

    Enum.each(proposal_tail, fn {name, role} ->
      block = extract_step_block!(source, name)

      assert block =~ "github.event.inputs.candidate_digest == ''",
             "protected lifecycle must skip proposal-only #{role}"
    end)

    {command_log, post_merge_proposals} = run_protected_dispatch_lifecycle()

    assert command_log =~ "gh pr checks 222 --required"
    assert command_log =~ "gh pr merge 222 --admin --squash"
    assert command_log =~ "release-please create-release"
    assert post_merge_proposals == []
    refute command_log =~ "capture-proposal"
    refute command_log =~ "proposal_missing"
  end

  test "an empty-digest schedule records bounded pending evidence when no Release Please proposal is open" do
    source = workflow_source()
    preflight = extract_step_block!(source, "Detect already-tagged release PR")

    discovery =
      extract_step_block!(source, "Discover scheduled Release Please proposal before capture")

    result = extract_step_block!(source, "Write proposal-only release control result")
    summary = extract_step_block!(source, "Summarize proposal-only release control result")
    upload = extract_step_block!(source, "Upload proposal-only release control result")
    gate = extract_step_block!(source, "Fail non-pass proposal control result after evidence upload")

    assert summary =~ "release-proposal-control-result.json"
    assert upload =~ "release-proposal-control-result-${{ github.run_id }}"

    assert step_precedes?(source, "Sync sibling package -> mailglass dep pin on release-please branch", "Discover scheduled Release Please proposal before capture")
    assert step_precedes?(source, "Discover scheduled Release Please proposal before capture", "Capture Release Please proposal identity without activation")
    assert step_precedes?(source, "Write proposal-only release control result", "Summarize proposal-only release control result")
    assert step_precedes?(source, "Summarize proposal-only release control result", "Upload proposal-only release control result")
    assert step_precedes?(source, "Upload proposal-only release control result", "Fail non-pass proposal control result after evidence upload")

    with_idle_schedule_fixture(:none, fn temp_dir, env ->
      File.write!(Path.join(temp_dir, "preflight.sh"), preflight_script(preflight))
      File.write!(Path.join(temp_dir, "discovery.sh"), proposal_result_script(discovery))
      File.write!(Path.join(temp_dir, "result.sh"), proposal_result_script(result))
      File.write!(Path.join(temp_dir, "gate.sh"), proposal_result_script(gate))

      assert {_, 0} =
               System.cmd("bash", [Path.join(temp_dir, "preflight.sh")],
                 cd: @repo_root,
                 env: Map.to_list(env),
                 stderr_to_stdout: true
               )

      assert read_output!(env["GITHUB_OUTPUT"])["should_run"] == "true"

      assert {_, 0} =
               System.cmd("bash", [Path.join(temp_dir, "discovery.sh")],
                 cd: @repo_root,
                 env: Map.to_list(env),
                 stderr_to_stdout: true
               )

      discovery_outputs = read_output!(env["GITHUB_OUTPUT"])
      assert discovery_outputs["should_capture"] == "false"
      assert discovery_outputs["result_status"] == "pending"
      assert discovery_outputs["result_reason"] == "no_open_proposal"

      writer_env =
        env
        |> Map.merge(%{
          "CAPTURE_OUTCOME" => "skipped",
          "CAPTURE_STATUS" => "",
          "CAPTURE_REASON" => "",
          "DISCOVERY_STATUS" => discovery_outputs["result_status"],
          "DISCOVERY_REASON" => discovery_outputs["result_reason"],
          "PROPOSAL_HEAD" => "",
          "SOURCE_SHA" => ""
        })

      assert {_, 0} =
               System.cmd("bash", [Path.join(temp_dir, "result.sh")],
                 cd: @repo_root,
                 env: Map.to_list(writer_env),
                 stderr_to_stdout: true
               )

      json =
        temp_dir
        |> Path.join("release-proposal-control-result.json")
        |> File.read!()
        |> Jason.decode!()

      assert Map.take(json, ["status", "reason", "event_name", "run_id", "proposal_head", "source_sha", "candidate_digest"]) == %{
               "status" => "pending",
               "reason" => "no_open_proposal",
               "event_name" => "schedule",
               "run_id" => "16208",
               "proposal_head" => "",
               "source_sha" => "",
               "candidate_digest" => ""
             }

      gate_env = %{"RESULT_STATUS" => "pending", "RESULT_REASON" => "no_open_proposal"}
      assert {_, 0} = System.cmd("bash", [Path.join(temp_dir, "gate.sh")], env: Map.to_list(gate_env), stderr_to_stdout: true)

      calls = File.read!(env["GH_LOG"])
      assert calls == "pr list --head release-please--branches--main --base main --state open --json number,headRefOid,baseRefOid\n"
      refute File.read!(env["COMMAND_LOG"]) =~ ~r/(gh pr merge|git tag|gh release|git push|protected-dispatch)/
    end)
  end

  test "scheduled discovery preserves capture for active or ambiguous proposals and fails unavailable evidence" do
    discovery =
      workflow_source()
      |> extract_step_block!("Discover scheduled Release Please proposal before capture")

    for {mode, expected_capture, expected_status, expected_reason, expected_exit} <- [
          {:one, "true", "", "", 0},
          {:many, "true", "", "", 0},
          {:unavailable, "false", "cannot-check", "github_evidence_unavailable", 1}
        ] do
      with_idle_schedule_fixture(mode, fn temp_dir, env ->
        script = Path.join(temp_dir, "discovery.sh")
        File.write!(script, proposal_result_script(discovery))

        assert {_, ^expected_exit} =
                 System.cmd("bash", [script], cd: @repo_root, env: Map.to_list(env), stderr_to_stdout: true)

        outputs = read_output!(env["GITHUB_OUTPUT"])
        assert outputs["should_capture"] == expected_capture
        assert outputs["result_status"] == expected_status
        assert outputs["result_reason"] == expected_reason
      end)
    end
  end

  test "proposal capture emits its real post-worktree outcome before cleanup and the writer preserves it" do
    source = workflow_source()

    capture =
      extract_step_block!(source, "Capture Release Please proposal identity without activation")

    result = extract_step_block!(source, "Write proposal-only release control result")

    assert capture =~ "git worktree add --detach"
    assert length(Regex.scan(~r/^\s*trap .* EXIT$/m, capture)) == 1

    for {fixture, expected_status, expected_reason} <- [
          {:pass, "pass", "proposal_captured"},
          {:identity_mismatch, "blocked", "proposal_identity_mismatch"}
        ] do
      with_capture_fixture(fixture, capture, result, fn temp_dir, capture_env ->
        {capture_output, capture_status} = run_capture(capture, temp_dir, capture_env)

        assert capture_status == if(fixture == :pass, do: 0, else: 1)

        emitted = read_output!(Path.join(temp_dir, "capture-output"))
        assert emitted["result_status"] == expected_status
        assert emitted["result_reason"] == expected_reason
        assert emitted["proposal_head"] == String.duplicate("b", 40)
        assert emitted["source_sha"] == String.duplicate("c", 40)
        assert emitted["candidate_digest"] == String.duplicate("a", 64)

        if fixture == :pass do
          assert emitted["captured"] == "true"
        else
          refute Map.has_key?(emitted, "captured")
        end

        assert capture_output =~ "proposal candidate captured after sibling synchronization" or
                 fixture == :identity_mismatch

        git_log = File.read!(Path.join(temp_dir, "git.log"))
        assert git_log =~ "worktree add"
        assert git_log =~ "worktree remove"
        refute File.exists?(capture_worktree_path!(git_log))

        writer_env =
          capture_env
          |> Map.merge(%{
            "CAPTURE_OUTCOME" => if(fixture == :pass, do: "success", else: "failure"),
            "CAPTURE_STATUS" => emitted["result_status"],
            "CAPTURE_REASON" => emitted["result_reason"],
            "PROPOSAL_HEAD" => emitted["proposal_head"],
            "SOURCE_SHA" => emitted["source_sha"],
            "CANDIDATE_DIGEST" => emitted["candidate_digest"],
            "RUNNER_TEMP" => temp_dir,
            "GITHUB_OUTPUT" => Path.join(temp_dir, "writer-output")
          })

        {_, writer_status} = run_proposal_writer(result, temp_dir, writer_env)
        assert writer_status == if(fixture == :pass, do: 0, else: 1)

        result_json =
          temp_dir
          |> Path.join("release-proposal-control-result.json")
          |> File.read!()
          |> Jason.decode!()

        assert Map.take(result_json, [
                 "status",
                 "reason",
                 "proposal_head",
                 "source_sha",
                 "candidate_digest"
               ]) ==
                 Map.take(emitted, [
                   "result_status",
                   "result_reason",
                   "proposal_head",
                   "source_sha",
                   "candidate_digest"
                 ])
                 |> Map.new(fn
                   {"result_status", value} -> {"status", value}
                   {"result_reason", value} -> {"reason", value}
                   {key, value} -> {key, value}
                 end)

        command_log = File.read!(Path.join(temp_dir, "command.log"))
        refute command_log =~ "gh pr merge"
        refute command_log =~ "git tag"
        refute command_log =~ "gh release"
        refute command_log =~ "git push"
      end)
    end
  end

  test "contributing documents proposal-only triggers and the protected exact-digest chain" do
    recovery_runbook =
      extract_markdown_section!(
        File.read!(@contributing_path),
        "If a release proposal or protected delivery stalls"
      )

    assert recovery_runbook?(recovery_runbook)
    refute recovery_runbook =~ "runs only `on: push: main`"

    refute recovery_runbook?(
             String.replace(recovery_runbook, "minute 17", "minute 18", global: true)
           )

    refute recovery_runbook =~ "schedule is a tag-recovery mechanism"

    refute recovery_runbook?(
             String.replace(recovery_runbook, "workflow_dispatch", "manual dispatch", global: true)
           )

    {release_dispatch, _} = :binary.match(recovery_runbook, "gh workflow run release-please.yml")
    {tag_wait, _} = :binary.match(recovery_runbook, "Wait until all three expected tags")
    {publish_dispatch, _} = :binary.match(recovery_runbook, "gh workflow run publish-hex.yml")

    assert release_dispatch < tag_wait
    assert tag_wait < publish_dispatch
    assert recovery_runbook =~ ~s(-f candidate_digest="$DIGEST")
    assert recovery_runbook =~ ~s(-f tag="mailglass-v${CORE_VERSION}")
    assert recovery_runbook =~ "-f dry_run=false"
    assert recovery_runbook =~ "-f core_full_suite_gate_skip_reason=n/a"
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
      manual =~ "candidate_digest:" and
      schedule =~ "cron: \"17 * * * *\""
  end

  defp run_protected_dispatch_lifecycle do
    temp_dir = Path.join(System.tmp_dir!(), "release-protected-lifecycle-#{System.unique_integer([:positive])}")
    command_log = Path.join(temp_dir, "command.log")
    proposal_state = Path.join(temp_dir, "open-proposals")

    File.mkdir_p!(temp_dir)
    File.write!(proposal_state, "222\n")

    try do
      File.write!(
        Path.join(temp_dir, "protected-lifecycle.sh"),
        """
        #!/usr/bin/env bash
        set -euo pipefail
        printf 'gh pr checks 222 --required\\n' >> \"$COMMAND_LOG\"
        printf 'gh pr merge 222 --admin --squash\\n' >> \"$COMMAND_LOG\"
        : > \"$PROPOSAL_STATE\"
        printf 'release-please create-release\\n' >> \"$COMMAND_LOG\"
        """
      )

      File.chmod!(Path.join(temp_dir, "protected-lifecycle.sh"), 0o755)

      assert {_, 0} =
               System.cmd("bash", [Path.join(temp_dir, "protected-lifecycle.sh")],
                 env: [{"COMMAND_LOG", command_log}, {"PROPOSAL_STATE", proposal_state}],
                 stderr_to_stdout: true
               )

      {File.read!(command_log), File.read!(proposal_state) |> String.split("\n", trim: true)}
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp workflow_source, do: File.read!(@workflow_path)

  defp release_policy, do: Module.concat([Mailglass, ReleasePolicy])

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

  defp with_proposal_result_env(outcome, status, reason, fun) do
    temp_dir =
      Path.join(System.tmp_dir!(), "release-proposal-result-#{System.unique_integer([:positive])}")

    File.mkdir_p!(temp_dir)

    env = %{
      "CAPTURE_OUTCOME" => outcome,
      "CAPTURE_STATUS" => status,
      "CAPTURE_REASON" => reason,
      "EVENT_NAME" => "workflow_dispatch",
      "RUN_ID" => "16202",
      "PROPOSAL_HEAD" => String.duplicate("b", 40),
      "SOURCE_SHA" => String.duplicate("c", 40),
      "CANDIDATE_DIGEST" => String.duplicate("a", 64),
      "RUNNER_TEMP" => temp_dir,
      "GITHUB_OUTPUT" => Path.join(temp_dir, "github-output")
    }

    try do
      fun.(temp_dir, env)
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp with_idle_schedule_fixture(mode, fun) do
    temp_dir = Path.join(System.tmp_dir!(), "release-idle-schedule-#{System.unique_integer([:positive])}")
    fake_bin = Path.join(temp_dir, "bin")
    File.mkdir_p!(fake_bin)

    File.write!(Path.join(fake_bin, "gh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf '%s\\n' "$*" >> "$GH_LOG"
    if [ "$*" = "pr list --head release-please--branches--main --base main --state open --json number,headRefOid,baseRefOid" ]; then
      case "$FAKE_DISCOVERY" in
        none) printf '[]\\n' ;;
        one) printf '[{"number":222,"headRefOid":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","baseRefOid":"cccccccccccccccccccccccccccccccccccccccc"}]\\n' ;;
        many) printf '[{"number":222},{"number":223}]\\n' ;;
        unavailable) printf 'simulated GitHub API failure\\n' >&2; exit 1 ;;
      esac
      exit 0
    fi
    printf 'unexpected gh invocation: %s\\n' "$*" >&2
    exit 64
    """)

    File.write!(Path.join(fake_bin, "git"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'git %s\\n' "$*" >> "$COMMAND_LOG"
    exit 64
    """)

    File.chmod!(Path.join(fake_bin, "gh"), 0o755)
    File.chmod!(Path.join(fake_bin, "git"), 0o755)
    File.write!(Path.join(temp_dir, "command.log"), "")

    env = %{
      "PATH" => fake_bin <> ":" <> System.get_env("PATH"),
      "GH_REPO" => "test-owner/test-repo",
      "GH_LOG" => Path.join(temp_dir, "gh.log"),
      "COMMAND_LOG" => Path.join(temp_dir, "command.log"),
      "GITHUB_OUTPUT" => Path.join(temp_dir, "github-output"),
      "GITHUB_STEP_SUMMARY" => Path.join(temp_dir, "summary"),
      "RUNNER_TEMP" => temp_dir,
      "EVENT_NAME" => "schedule",
      "RUN_ID" => "16208",
      "CANDIDATE_DIGEST" => "",
      "COMMIT_MESSAGE" => "",
      "FAKE_DISCOVERY" => Atom.to_string(mode)
    }

    try do
      fun.(temp_dir, env)
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp with_capture_fixture(fixture, capture, result, fun) do
    temp_dir =
      Path.join(System.tmp_dir!(), "release-capture-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(temp_dir, "bin"))
    File.mkdir_p!(Path.join(temp_dir, "scripts"))

    proposal_head = String.duplicate("b", 40)
    source_sha = String.duplicate("c", 40)
    recorded_head = if fixture == :pass, do: proposal_head, else: String.duplicate("e", 40)

    target = %{
      "status" => "captured",
      "candidate_versions" => %{"mailglass" => "2.5.0", "mailglass_admin" => "2.5.0"},
      "proposal_identity" => %{"head_sha" => recorded_head, "source_sha" => source_sha},
      "publishable_content" => %{"digest" => String.duplicate("a", 64)}
    }

    File.write!(Path.join(temp_dir, "target.json"), Jason.encode!(target))
    File.write!(Path.join(temp_dir, "capture.sh"), capture_script(capture))
    File.write!(Path.join(temp_dir, "proposal-result.sh"), proposal_result_script(result))

    write_capture_shims!(temp_dir)

    env = %{
      "PATH" => Path.join(temp_dir, "bin") <> ":" <> System.get_env("PATH"),
      "CANDIDATE_DIGEST" => String.duplicate("a", 64),
      "EVENT_NAME" => "workflow_dispatch",
      "RUN_ID" => "16206",
      "GITHUB_OUTPUT" => Path.join(temp_dir, "capture-output"),
      "FAKE_TARGET" => Path.join(temp_dir, "target.json"),
      "GIT_LOG" => Path.join(temp_dir, "git.log"),
      "COMMAND_LOG" => Path.join(temp_dir, "command.log")
    }

    try do
      fun.(temp_dir, env)
    after
      File.rm_rf!(temp_dir)
    end
  end

  defp write_capture_shims!(temp_dir) do
    bin = Path.join(temp_dir, "bin")

    File.write!(Path.join(bin, "gh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'gh %s\\n' "$*" >> "$COMMAND_LOG"
    printf '[{"number":222,"headRefOid":"%s","baseRefOid":"%s"}]\\n' "$(printf 'b%.0s' {1..40})" "$(printf 'c%.0s' {1..40})"
    """)

    File.write!(Path.join(bin, "git"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'git %s\\n' "$*" >> "$COMMAND_LOG"
    case "$1:$2" in
      fetch:*|checkout:*) exit 0 ;;
      show:*) cat "$FAKE_TARGET" ;;
      merge-base:*) exit 0 ;;
      worktree:add)
        printf 'worktree add %s\\n' "$4" >> "$GIT_LOG"
        mkdir -p "$4"
        ;;
      worktree:remove)
        printf 'worktree remove %s\\n' "$4" >> "$GIT_LOG"
        rmdir "$4"
        ;;
      *) printf 'unexpected git command: %s\\n' "$*" >&2; exit 64 ;;
    esac
    """)

    File.write!(Path.join(bin, "mix"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'mix %s\\n' "$*" >> "$COMMAND_LOG"
    """)

    File.write!(Path.join(temp_dir, "scripts/release_policy_content_digest.sh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'digest %s\\n' "$*" >> "$COMMAND_LOG"
    printf '%s\\n' "$(printf 'a%.0s' {1..64})"
    """)

    File.write!(Path.join(temp_dir, "scripts/release_policy_validate_target.sh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf 'validate-target %s\\n' "$*" >> "$COMMAND_LOG"
    """)

    for path <- [Path.join(bin, "gh"), Path.join(bin, "git"), Path.join(bin, "mix")] do
      File.chmod!(path, 0o755)
    end

    for path <- [
          Path.join(temp_dir, "scripts/release_policy_content_digest.sh"),
          Path.join(temp_dir, "scripts/release_policy_validate_target.sh")
        ] do
      File.chmod!(path, 0o755)
    end
  end

  defp run_capture(_capture, temp_dir, env) do
    System.cmd("bash", [Path.join(temp_dir, "capture.sh")],
      cd: temp_dir,
      env: Map.to_list(env),
      stderr_to_stdout: true
    )
  end

  defp run_proposal_writer(_result, temp_dir, env) do
    System.cmd("bash", [Path.join(temp_dir, "proposal-result.sh")],
      cd: temp_dir,
      env: Map.to_list(env),
      stderr_to_stdout: true
    )
  end

  defp capture_script(capture), do: proposal_result_script(capture)

  defp read_output!(path) do
    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Map.new(fn line ->
      [key, value] = String.split(line, "=", parts: 2)
      {key, value}
    end)
  end

  defp capture_worktree_path!(git_log) do
    [_, path] = Regex.run(~r/worktree add (.+)/, git_log)
    path
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
      # Historical tag recovery runs only for the protected dispatch path. The
      # ordinary proposal path intentionally exits before it queries GitHub.
      env: Map.to_list(Map.put_new(env, "CANDIDATE_DIGEST", String.duplicate("d", 64))),
      stderr_to_stdout: true
    )
  end

  defp checkout_precedes_preflight?(source) do
    case {
      :binary.match(source, "- name: Checkout protected main for release preflight"),
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

  defp proposal_result_script(result) do
    case String.split(result, ~r/^\s*run: \|\n/m, parts: 2) do
      [_, script] when script != "" ->
        script
        |> String.split("\n")
        |> Enum.map_join("\n", &String.replace_prefix(&1, "          ", ""))

      _ ->
        raise ArgumentError, "could not extract the proposal result shell script"
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
      action =~ "steps.release-preflight.outputs.should_run == 'true'" and
      action =~ "steps.protected-dispatch.outputs.content_verified == 'true'" and
      action =~ "steps.protected-merge.outcome == 'success'"
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
