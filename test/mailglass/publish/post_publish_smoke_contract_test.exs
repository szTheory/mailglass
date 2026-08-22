defmodule Mailglass.Publish.PostPublishSmokeContractTest do
  use ExUnit.Case, async: true

  @moduletag :requires_workspace

  @workflow_path Path.expand("../../../.github/workflows/post-publish-smoke.yml", __DIR__)
  @hex_lock_guard Path.expand("../../../scripts/check_clean_baseline_hex_only.sh", __DIR__)
  @target_guard Path.expand("../../../scripts/check_post_publish_target.sh", __DIR__)
  @content_digest Path.expand("../../../scripts/release_policy_content_digest.sh", __DIR__)
  @reference_lock Path.expand("../../../reference/host_app/mix.lock", __DIR__)

  test "candidate release events are successful no-ops and protected dispatch requires three exact versions" do
    workflow = File.read!(@workflow_path)
    resolver = extract_job!(workflow, "resolve-completed-target", "cron-guard")
    guard = extract_job!(workflow, "cron-guard", "wait-for-index")

    for input <- ["core_version", "admin_version", "inbound_version"] do
      block = workflow_dispatch_input_block!(workflow, input)
      assert block =~ "required: true"
      assert block =~ "type: string"
    end

    target_ref = workflow_dispatch_input_block!(workflow, "target_ref")
    assert target_ref =~ "required: true"
    assert target_ref =~ "Immutable 40-character tag SHA"

    assert resolver =~ "name: Classify trigger"
    assert resolver =~ "EVENT_NAME: ${{ github.event_name }}"
    assert resolver =~ "release)"
    assert resolver =~ "resolve=false"
    assert resolver =~ "schedule|workflow_dispatch)"
    assert resolver =~ "resolve=true"
    assert resolver =~ "if: ${{ steps.trigger.outputs.resolve == 'true' }}"

    release_branch = shell_case_branch!(resolver, "release", "schedule|workflow_dispatch")
    refute release_branch =~ "tag_name"
    refute release_branch =~ "mailglass-v"
    refute release_branch =~ "mailglass_admin-v"
    refute release_branch =~ "mailglass_inbound-v"

    assert guard =~ "if (eventName === 'release')"
    assert guard =~ "core.setOutput('should_run', 'false')"
    assert guard =~ "core.info('Candidate release event is intentionally a no-op;"
  end

  test "dispatch resolves the protected candidate while schedule alone requires a completed target" do
    workflow = File.read!(@workflow_path)
    resolver = extract_job!(workflow, "resolve-completed-target", "cron-guard")

    assert resolver =~ "command=\"authorized-versions\""

    assert resolver =~
             "if [ \"$EVENT_NAME\" = \"schedule\" ]; then command=\"completed-versions\"; fi"

    assert resolver =~ ~s("$command" "$target")
    assert resolver =~ ~s($1 == "target_ref")
    assert resolver =~ "[ -n \"$INPUT_CORE\" ]"
    assert resolver =~ "[ -n \"$INPUT_ADMIN\" ]"
    assert resolver =~ "[ -n \"$INPUT_INBOUND\" ]"
    assert resolver =~ "[ \"$INPUT_CORE\" = \"$core\" ]"
    assert resolver =~ "[ \"$INPUT_ADMIN\" = \"$admin\" ]"
    assert resolver =~ "[ \"$INPUT_INBOUND\" = \"$inbound\" ]"
    assert resolver =~ "[[ \"$INPUT_TARGET_REF\" =~ ^[0-9a-f]{40}$ ]]"
    assert resolver =~ "target_ref=\"$INPUT_TARGET_REF\""
    assert resolver =~ "ref: ${{ github.workflow_sha }}"

    for forbidden <- [
          "listReleases",
          "releases.list",
          "const latest",
          "package latest",
          "read-inbound-version",
          "source_versions",
          "github.event.inputs.tag",
          "github.event.release.tag_name ||",
          "DEP_MODE: path"
        ] do
      refute workflow =~ forbidden
    end
  end

  test "scheduled authorized unpublished targets persist one blocked resolution before failing closed" do
    workflow = File.read!(@workflow_path)
    resolver = extract_job!(workflow, "resolve-completed-target", "cron-guard")

    assert resolver =~ "post-publish-resolution.json"
    assert resolver =~ "command=\"completed-versions\""
    assert resolver =~ "authorized-versions\" \"$control_target\""
    assert resolver =~ "write_resolution \"blocked\" \"scheduled_target_not_published\""

    for field <- [
          "event_name",
          "run_id",
          "ledger_status",
          "publication_status",
          "target_ref",
          "core",
          "admin",
          "inbound"
        ] do
      assert resolver =~ "\"#{field}\":"
    end

    assert resolver =~
             "resolution_finalized=true\n                  echo \"Scheduled target is authorized but unpublished; wrote blocked resolution evidence.\" >&2\n                  exit 1"

    assert resolver =~ "if: ${{ always() }}"
    assert resolver =~ "name: Upload post-publish resolution"
    assert resolver =~ "name: Summarize post-publish resolution"
    assert resolver =~ "path: ${{ runner.temp }}/post-publish-resolution.json"
  end

  test "post-publish resolver paths materialize one bounded resolution before upload" do
    workflow = File.read!(@workflow_path)
    classify = workflow_step_script!(workflow, "Classify trigger")

    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-post-publish-resolution-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(root) end)
    File.mkdir_p!(root)

    for {event_name, expected_status, expected_reason} <- [
          {"release", "pending", "release_event_noop"},
          {"schedule", "cannot-check", "resolver_not_started"},
          {"workflow_dispatch", "cannot-check", "resolver_not_started"}
        ] do
      runner_temp = Path.join(root, event_name)
      output = Path.join(runner_temp, "github-output")
      File.mkdir_p!(runner_temp)
      File.write!(output, "")

      assert {_, 0} =
               System.cmd("bash", ["-c", classify],
                 env: [
                   {"EVENT_NAME", event_name},
                   {"INPUT_TARGET_REF", String.duplicate("a", 40)},
                   {"RUNNER_TEMP", runner_temp},
                   {"RUN_ID", "fixture-run"},
                   {"GITHUB_OUTPUT", output}
                 ],
                 stderr_to_stdout: true
               )

      resolution_path = Path.join(runner_temp, "post-publish-resolution.json")
      assert File.exists?(resolution_path)
      assert {:ok, resolution} = resolution_path |> File.read!() |> Jason.decode()
      assert resolution["status"] == expected_status
      assert resolution["reason"] == expected_reason
      assert resolution["event_name"] == event_name
      assert resolution["run_id"] == "fixture-run"
      assert resolution["target_ref"] == ""
      assert resolution["core"] == ""
      assert resolution["admin"] == ""
      assert resolution["inbound"] == ""
    end
  end

  test "real resolver shell preserves pass, blocked, and cannot-check resolution semantics" do
    workflow = File.read!(@workflow_path)
    resolver = workflow_step_script!(workflow, "Resolve protected target versions")
    target_ref = String.duplicate("a", 40)

    assert_resolution_fixture!(resolver, "schedule-pass",
      event_name: "schedule",
      completed_result: policy_result(completed: true, target_ref: target_ref),
      expected_status: 0,
      expected_resolution: {"pass", "exact_target_verified", target_ref}
    )

    assert_resolution_fixture!(resolver, "schedule-blocked",
      event_name: "schedule",
      completed_status: 1,
      authorized_result: policy_result(status: "authorized"),
      publication_status: "not_started",
      expected_status: 1,
      expected_resolution: {"blocked", "scheduled_target_not_published", ""}
    )

    assert_resolution_fixture!(resolver, "schedule-cannot-check",
      event_name: "schedule",
      completed_status: 17,
      authorized_result: policy_result(status: "unknown"),
      expected_status: 17,
      expected_resolution: {"cannot-check", "resolver_failed", ""}
    )

    assert_resolution_fixture!(resolver, "protected-dispatch-pass",
      event_name: "workflow_dispatch",
      input_target_ref: target_ref,
      input_core: "3.0.0",
      input_admin: "3.0.0",
      input_inbound: "2.2.0",
      authorized_result: policy_result(status: "authorized", completed: false, authorized: true),
      expected_status: 0,
      expected_resolution: {"pass", "exact_target_verified", target_ref}
    )
  end

  test "policy and every repository-backed proof stay on immutable control and target refs" do
    workflow = File.read!(@workflow_path)
    resolver = extract_job!(workflow, "resolve-completed-target", "cron-guard")

    assert resolver =~ "name: Checkout immutable workflow control plane"
    assert resolver =~ "ref: ${{ github.workflow_sha }}"
    refute resolver =~ "ref: ${{ github.sha }}"
    refute resolver =~ "ref: main"

    assert resolver =~ "name: Checkout immutable published target"
    assert resolver =~ "if: ${{ github.event_name == 'workflow_dispatch' }}"
    assert resolver =~ "ref: ${{ github.event.inputs.target_ref }}"
    assert resolver =~ "path: immutable-target"
    assert resolver =~ "control_target=.planning/release-target.json"
    assert resolver =~ "target=immutable-target/.planning/release-target.json"
    assert resolver =~ ~s("authorized-versions" "$control_target")
    assert resolver =~ ~s("$command" "$target")

    assert resolver =~
             "for identity_key in core admin inbound candidate_digest content_digest proposal_head source_sha"

    assert resolver =~ "[ \"$control_value\" = \"$target_value\" ]"
    assert resolver =~ "published) [ \"$control_tag_sha\" = \"$INPUT_TARGET_REF\" ]"
    refute resolver =~ "cmp --silent \"$control_resolved\" \"$resolved\""
    assert resolver =~ "bash scripts/check_post_publish_target.sh"
    assert resolver =~ "--target-ref \"$target_ref\""
    assert resolver =~ "--core \"$core\""
    assert resolver =~ "--admin \"$admin\""
    assert resolver =~ "--inbound \"$inbound\""

    for {job_name, next_job} <- [
          {"wait-for-index", "wait-for-hexdocs"},
          {"consumer-install", "published-trust-journey"},
          {"published-trust-journey", "retracted-check"},
          {"retracted-check", "notify-on-failure"}
        ] do
      job = extract_job!(workflow, job_name, next_job)
      checkout = checkout_step!(job)

      assert checkout =~ "ref: ${{ needs.cron-guard.outputs.release_ref }}",
             "#{job_name} must checkout the validated immutable release_ref"

      refute checkout =~ "ref: main"
      refute checkout =~ "ref: ${{ github.sha }}"
    end
  end

  test "every wait install and package check consumes three separately named exact outputs" do
    workflow = File.read!(@workflow_path)
    cron_guard = extract_job!(workflow, "cron-guard", "wait-for-index")
    wait_index = extract_job!(workflow, "wait-for-index", "wait-for-hexdocs")
    wait_docs = extract_job!(workflow, "wait-for-hexdocs", "consumer-install")
    consumer = extract_job!(workflow, "consumer-install", "published-trust-journey")
    journey = extract_job!(workflow, "published-trust-journey", "retracted-check")
    retracted = extract_job!(workflow, "retracted-check", "notify-on-failure")

    assert cron_guard =~ "version_core: ${{ needs.resolve-completed-target.outputs.core }}"
    assert cron_guard =~ "version_admin: ${{ needs.resolve-completed-target.outputs.admin }}"
    assert cron_guard =~ "version_inbound: ${{ needs.resolve-completed-target.outputs.inbound }}"

    for job <- [wait_index, wait_docs, consumer, journey, retracted],
        {name, output} <- [
          {"VERSION_CORE", "version_core"},
          {"VERSION_ADMIN", "version_admin"},
          {"VERSION_INBOUND", "version_inbound"}
        ] do
      assert job =~ "#{name}: ${{ needs.cron-guard.outputs.#{output} }}"
    end

    assert wait_index =~ ~s(mix hex.info mailglass "${VERSION_CORE}")
    assert wait_index =~ ~s(mix hex.info mailglass_admin "${VERSION_ADMIN}")
    assert wait_index =~ ~s(mix hex.info mailglass_inbound "${VERSION_INBOUND}")
    assert wait_docs =~ ~s(hexdocs.pm/mailglass_admin/${VERSION_ADMIN}/)
    assert consumer =~ ~s(mix hex.info mailglass_admin "${VERSION_ADMIN}")
    assert consumer =~ "VERSION: ${{ needs.cron-guard.outputs.version_core }}"
    assert consumer =~ "VERSION_INBOUND: ${{ needs.cron-guard.outputs.version_inbound }}"
    assert consumer =~ "services:"
    assert consumer =~ "image: postgres:16-alpine@sha256:"
    assert consumer =~ "POSTGRES_USER: postgres"
    assert consumer =~ "POSTGRES_PASSWORD: postgres"
    assert consumer =~ "POSTGRES_DB: postgres"
    assert consumer =~ "- 5432:5432"
    assert consumer =~ "--health-cmd pg_isready"
    assert retracted =~ ~s(mix hex.info mailglass_admin "${VERSION_ADMIN}")
  end

  test "published trust journey creates and boots a disposable exact-Hex host" do
    workflow = File.read!(@workflow_path)
    job = extract_job!(workflow, "published-trust-journey", "retracted-check")

    assert job =~ "HOST_ROOT: ${{ runner.temp }}/mailglass-published-host-${{ github.run_id }}"
    assert job =~ ~s(rm -rf "${HOST_ROOT}/deps" "${HOST_ROOT}/_build" "${HOST_ROOT}/mix.lock")
    assert job =~ "export CORE_DEP=\"{:mailglass, \\\"== ${VERSION_CORE}\\\"}\""
    assert job =~ "export ADMIN_DEP=\"{:mailglass_admin, \\\"== ${VERSION_ADMIN}\\\"}\""

    assert job =~
             "export INBOUND_DEP=\"{:mailglass_inbound, \\\"== ${VERSION_INBOUND}\\\"}\""

    assert job =~ "mix deps.get"
    assert job =~ "MAILGLASS_EXPECTED_CORE_VERSION"
    assert job =~ "MAILGLASS_EXPECTED_ADMIN_VERSION"
    assert job =~ "MAILGLASS_EXPECTED_INBOUND_VERSION"
    assert job =~ "bash \"${GITHUB_WORKSPACE}/scripts/check_clean_baseline_hex_only.sh\" mix.lock"
    assert job =~ "mix compile --warnings-as-errors"
    assert job =~ ~s(ln -s "${HOST_ROOT}/_build" "${GITHUB_WORKSPACE}/reference/host_app/_build")
    assert job =~ "Application.ensure_all_started(:mailglass_reference_host)"
    assert job =~ "Application.spec(app, :vsn)"
    assert job =~ "MAILGLASS_CORE_WORKSPACE_EBIN=\"${HOST_ROOT}/_build/dev/lib/mailglass/ebin\""

    assert job =~
             "MAILGLASS_INBOUND_WORKSPACE_EBIN=\"${HOST_ROOT}/_build/dev/lib/mailglass_inbound/ebin\""

    assert job =~ "refusing an ambiguous override"
    assert job =~ "config :swoosh, :api_client, false"

    assert_ordered!(job, [
      ~s|File.write!("mix.exs", updated)|,
      "config :swoosh, :api_client, false",
      "MIX_ENV=dev mix deps.get"
    ])

    assert job =~ "mix verify.reference_host.journey --host-root \"${HOST_ROOT}\""
    assert job =~ "bash scripts/check_trust_runner_checkpoint.sh --require-completed"
    assert job =~ "name: published-adoption-evidence-${{ github.run_id }}"
    assert job =~ "if-no-files-found: error"
    assert job =~ "retention-days: 90"
    assert job =~ "path: tmp/published-adoption-evidence"

    assert_ordered!(job, [
      "mix verify.reference_host.journey --host-root",
      "bash scripts/check_trust_runner_checkpoint.sh --require-completed",
      "uses: actions/upload-artifact@"
    ])

    refute job =~ "working-directory: reference/host_app"
    refute job =~ "--dry-run"
    refute job =~ "if: always()"
    refute job =~ "mix verify.reference_host.journey --host-root reference/host_app"
    refute job =~ "mix deps.get && mix compile"
  end

  test "published trust journey executes the complete generated-host proof from exact Hex packages" do
    workflow = File.read!(@workflow_path)
    job = extract_job!(workflow, "published-trust-journey", "retracted-check")

    assert_exact_hex_generated_proof!(job)

    for mutation <- [
          String.replace(job, "MAILGLASS_PACKAGE_MODE: exact_hex", "MAILGLASS_PACKAGE_MODE: path",
            global: false
          ),
          String.replace(job, "MAILGLASS_EXACT_ADMIN_VERSION", "MAILGLASS_EXACT_CORE_VERSION",
            global: false
          ),
          String.replace(job, "bash scripts/generated_ecto_host_proof.sh", "echo skipped",
            global: false
          )
        ] do
      assert_raise ExUnit.AssertionError, fn -> assert_exact_hex_generated_proof!(mutation) end
    end
  end

  test "target guard rejects arbitrary commits, content drift, and incomplete tag sets" do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-post-publish-target-#{System.unique_integer([:positive])}"
      )

    repo = Path.join(root, "candidate")
    remote = Path.join(root, "remote.git")
    target = Path.join(repo, ".planning/release-target.json")
    on_exit(fn -> File.rm_rf!(root) end)

    File.mkdir_p!(Path.join(repo, "mailglass_admin"))
    File.mkdir_p!(Path.join(repo, "mailglass_inbound"))
    File.mkdir_p!(Path.join(repo, "lib"))
    git!(repo, ["init", "--initial-branch=main"])
    git!(repo, ["config", "user.email", "smoke@example.com"])
    git!(repo, ["config", "user.name", "Smoke Contract"])
    File.write!(Path.join(repo, "mix.exs"), "defmodule Core do\nend\n")
    File.write!(Path.join(repo, "mailglass_admin/mix.exs"), "defmodule Admin do\nend\n")
    File.write!(Path.join(repo, "mailglass_inbound/mix.exs"), "defmodule Inbound do\nend\n")
    File.write!(Path.join(repo, "lib/proof.ex"), "defmodule Proof do\nend\n")
    git!(repo, ["add", "."])
    git!(repo, ["commit", "-m", "candidate content"])

    {digest, 0} = System.cmd("bash", [@content_digest, "--repo", repo])
    File.mkdir_p!(Path.dirname(target))

    File.write!(
      target,
      Jason.encode!(%{"publishable_content" => %{"digest" => String.trim(digest)}})
    )

    git!(repo, ["add", ".planning/release-target.json"])
    git!(repo, ["commit", "-m", "authorized ledger"])
    target_ref = git_output!(repo, ["rev-parse", "HEAD"])

    tags = ["mailglass-v3.0.0", "mailglass_admin-v3.0.0", "mailglass_inbound-v2.2.0"]
    Enum.each(tags, &git!(repo, ["tag", &1, target_ref]))
    git!(root, ["init", "--bare", remote])
    git!(repo, ["remote", "add", "origin", remote])
    git!(repo, ["push", "origin", "main", "--tags"])

    assert {valid_output, 0} = run_target_guard(repo, target, target_ref)
    assert valid_output =~ "post-publish target verified"

    File.write!(Path.join(repo, ".arbitrary"), "not authorized\n")
    git!(repo, ["add", ".arbitrary"])
    git!(repo, ["commit", "-m", "arbitrary sha"])
    arbitrary_ref = git_output!(repo, ["rev-parse", "HEAD"])
    assert {arbitrary_output, arbitrary_status} = run_target_guard(repo, target, arbitrary_ref)
    assert arbitrary_status != 0
    assert arbitrary_output =~ "does not resolve to target_ref"

    File.write!(Path.join(repo, "lib/proof.ex"), "defmodule ChangedProof do\nend\n")
    git!(repo, ["add", "lib/proof.ex"])
    git!(repo, ["commit", "-m", "content drift"])
    drift_ref = git_output!(repo, ["rev-parse", "HEAD"])
    Enum.each(tags, &git!(repo, ["tag", "--force", &1, drift_ref]))
    git!(repo, ["push", "--force", "origin", "--tags"])
    assert {drift_output, drift_status} = run_target_guard(repo, target, drift_ref)
    assert drift_status != 0
    assert drift_output =~ "content digest mismatch"

    git!(repo, ["push", "origin", ":refs/tags/mailglass_inbound-v2.2.0"])
    assert {missing_output, missing_status} = run_target_guard(repo, target, drift_ref)
    assert missing_status != 0
    assert missing_output =~ "required tag is unavailable"
  end

  test "exact-Hex lock guard rejects a stale version and malformed checksum" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mailglass-exact-hex-lock-#{System.unique_integer([:positive])}")

    stale_lock = Path.join(tmp_dir, "stale.lock")
    malformed_lock = Path.join(tmp_dir, "malformed.lock")
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    File.mkdir_p!(tmp_dir)
    File.cp!(@reference_lock, stale_lock)

    env = [
      {"MAILGLASS_EXPECTED_CORE_VERSION", "99.99.99"},
      {"MAILGLASS_EXPECTED_ADMIN_VERSION", "99.99.99"},
      {"MAILGLASS_EXPECTED_INBOUND_VERSION", "99.99.98"}
    ]

    {stale_output, stale_status} =
      System.cmd("bash", [@hex_lock_guard, stale_lock], env: env, stderr_to_stdout: true)

    assert stale_status == 1
    assert stale_output =~ "exact version mismatch"

    malformed =
      @reference_lock
      |> File.read!()
      |> String.replace(
        ~r/("mailglass": \{:hex, :mailglass, "[^"]+", )"[0-9a-f]{64}"/,
        "\\1\"short\"",
        global: false
      )

    File.write!(malformed_lock, malformed)

    {checksum_output, checksum_status} =
      System.cmd("bash", [@hex_lock_guard, malformed_lock], stderr_to_stdout: true)

    assert checksum_status == 1
    assert checksum_output =~ "checksum is not a 64-character lowercase hex digest"
  end

  test "post-publish smoke auto-closes tracker only after green guard and journey evidence" do
    workflow = File.read!(@workflow_path)

    assert workflow =~ "close-publish-smoke-tracker-on-success:"
    assert workflow =~ "name: Close issue on smoke success"

    assert workflow =~
             "needs: [cron-guard, wait-for-index, wait-for-hexdocs, consumer-install, published-trust-journey, retracted-check]"

    assert workflow =~ "needs.consumer-install.result == 'success'"
    assert workflow =~ "needs.published-trust-journey.result == 'success'"
    assert workflow =~ "needs.retracted-check.result == 'success'"
    assert workflow =~ "needs.cron-guard.outputs.should_run == 'true'"
    assert workflow =~ "github.rest.issues.createComment"
    assert workflow =~ "github.rest.issues.update"
    assert workflow =~ ~s(state: "closed")
    assert workflow =~ ~s(state_reason: "completed")
    assert workflow =~ "published-adoption-evidence-${context.runId}"
    refute workflow =~ "gh issue close"
  end

  defp extract_job!(workflow, start_key, next_key) do
    [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
    [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
    job
  end

  defp workflow_step_script!(workflow, step_name) do
    [_before, rest] = String.split(workflow, "\n      - name: #{step_name}\n", parts: 2)
    [_before, script_and_after] = String.split(rest, "        run: |\n", parts: 2)
    [script | _after] = String.split(script_and_after, "\n      - name:", parts: 2)

    script
    |> String.split("\n")
    |> Enum.map_join("\n", &String.replace_prefix(&1, "          ", ""))
  end

  defp assert_resolution_fixture!(resolver, name, options) do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-post-publish-resolver-#{name}-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(root) end)
    bin = Path.join(root, "bin")
    runner_temp = Path.join(root, "runner-temp")
    github_output = Path.join(root, "github-output")
    File.mkdir_p!(bin)
    File.mkdir_p!(runner_temp)
    File.write!(github_output, "")

    File.write!(Path.join(bin, "mix"), mix_fixture_shim())
    File.write!(Path.join(bin, "bash"), target_guard_fixture_shim())
    File.chmod!(Path.join(bin, "mix"), 0o755)
    File.chmod!(Path.join(bin, "bash"), 0o755)

    event_name = Keyword.fetch!(options, :event_name)
    expected_status = Keyword.fetch!(options, :expected_status)
    {expected_resolution_status, expected_reason, expected_target_ref} =
      Keyword.fetch!(options, :expected_resolution)

    env = [
      {"PATH", "#{bin}:#{System.get_env("PATH")}"},
      {"EVENT_NAME", event_name},
      {"RUN_ID", "fixture-run"},
      {"RUNNER_TEMP", runner_temp},
      {"GITHUB_OUTPUT", github_output},
      {"INPUT_TARGET_REF", Keyword.get(options, :input_target_ref, "")},
      {"INPUT_CORE", Keyword.get(options, :input_core, "")},
      {"INPUT_ADMIN", Keyword.get(options, :input_admin, "")},
      {"INPUT_INBOUND", Keyword.get(options, :input_inbound, "")},
      {"COMPLETED_RESULT", Keyword.get(options, :completed_result, "")},
      {"COMPLETED_STATUS", to_string(Keyword.get(options, :completed_status, 0))},
      {"AUTHORIZED_RESULT", Keyword.get(options, :authorized_result, policy_result())},
      {"PUBLICATION_STATUS", Keyword.get(options, :publication_status, "published")}
    ]

    {resolver_output, status} =
      System.cmd("/bin/bash", ["-c", resolver], env: env, cd: root, stderr_to_stdout: true)

    assert status == expected_status, "resolver fixture output:\n#{resolver_output}"

    resolution_path = Path.join(runner_temp, "post-publish-resolution.json")
    assert {:ok, resolution} = resolution_path |> File.read!() |> Jason.decode()
    assert resolution["status"] == expected_resolution_status
    assert resolution["reason"] == expected_reason
    assert resolution["event_name"] == event_name
    assert resolution["run_id"] == "fixture-run"
    assert resolution["target_ref"] == expected_target_ref
    expected_versions =
      if expected_resolution_status == "cannot-check", do: {"", "", ""}, else: {"3.0.0", "3.0.0", "2.2.0"}

    {expected_core, expected_admin, expected_inbound} = expected_versions
    assert resolution["core"] == expected_core
    assert resolution["admin"] == expected_admin
    assert resolution["inbound"] == expected_inbound

    if expected_resolution_status == "pass" do
      assert File.read!(github_output) =~ "target_ref=#{expected_target_ref}"
    else
      assert File.read!(github_output) == ""
    end
  end

  defp policy_result(overrides \\ []) do
    defaults = %{
      status: "completed",
      completed: true,
      authorized: false,
      core: "3.0.0",
      admin: "3.0.0",
      inbound: "2.2.0",
      target_ref: String.duplicate("a", 40),
      candidate_digest: "candidate",
      content_digest: "content",
      proposal_head: "proposal",
      source_sha: "source",
      tag_sha: ""
    }

    values = Enum.into(overrides, defaults)

    [
      "status=#{values.status}",
      "completed=#{values.completed}",
      "authorized=#{values.authorized}",
      "core=#{values.core}",
      "admin=#{values.admin}",
      "inbound=#{values.inbound}",
      "target_ref=#{values.target_ref}",
      "candidate_digest=#{values.candidate_digest}",
      "content_digest=#{values.content_digest}",
      "proposal_head=#{values.proposal_head}",
      "source_sha=#{values.source_sha}",
      "tag_sha=#{values.tag_sha}"
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp mix_fixture_shim do
    """
    #!/bin/bash
    set -euo pipefail
    case "$*" in
      *completed-versions*) printf '%s' "${COMPLETED_RESULT:-}"; exit "$COMPLETED_STATUS" ;;
      *authorized-versions*) printf '%s' "${AUTHORIZED_RESULT:-}"; exit 0 ;;
      *Jason.decode*) printf '%s' "$PUBLICATION_STATUS"; exit 0 ;;
      *) exit 0 ;;
    esac
    """
  end

  defp target_guard_fixture_shim do
    """
    #!/bin/bash
    set -euo pipefail
    if [ "$1" = "scripts/check_post_publish_target.sh" ]; then exit 0; fi
    exec /bin/bash "$@"
    """
  end

  defp workflow_dispatch_input_block!(workflow, input) do
    [_before, rest] = String.split(workflow, "\n      #{input}:\n", parts: 2)
    [block | _after] = Regex.split(~r/\n      [a-z_]+:\n/, rest, parts: 2)
    block
  end

  defp shell_case_branch!(source, branch, next_branch) do
    [_before, rest] = String.split(source, "#{branch})", parts: 2)
    [block | _after] = String.split(rest, "#{next_branch})", parts: 2)
    block
  end

  defp checkout_step!(job) do
    [_before, checkout] = String.split(job, "uses: actions/checkout@", parts: 2)
    [step | _after] = String.split(checkout, "\n      - name:", parts: 2)
    step
  end

  defp run_target_guard(repo, target, target_ref) do
    System.cmd(
      "bash",
      [
        @target_guard,
        "--repo",
        repo,
        "--target",
        target,
        "--target-ref",
        target_ref,
        "--core",
        "3.0.0",
        "--admin",
        "3.0.0",
        "--inbound",
        "2.2.0"
      ],
      stderr_to_stdout: true
    )
  end

  defp assert_exact_hex_generated_proof!(job) do
    assert job =~ "name: Execute 20-stage exact-Hex generated-host proof"
    assert job =~ "MAILGLASS_PACKAGE_MODE: exact_hex"
    assert job =~ "MAILGLASS_EXACT_CORE_VERSION: ${{ needs.cron-guard.outputs.version_core }}"
    assert job =~ "MAILGLASS_EXACT_ADMIN_VERSION: ${{ needs.cron-guard.outputs.version_admin }}"

    assert job =~
             "MAILGLASS_EXACT_INBOUND_VERSION: ${{ needs.cron-guard.outputs.version_inbound }}"

    assert job =~ "mailglass_generated_ecto_host_published_${{ github.run_id }}"
    assert job =~ "bash scripts/generated_ecto_host_proof.sh"
    assert job =~ "MAILGLASS_GENERATED_HOST_CHECKPOINT_OUT:"
    assert job =~ "generated-host-checkpoint.txt"
    assert job =~ "trust-runner-checkpoint.json"
    assert job =~ "shasum -a 256 generated-host-checkpoint.txt trust-runner-checkpoint.json"
    assert job =~ "name: Upload published adoption evidence"
    assert job =~ "path: tmp/published-adoption-evidence"

    assert_ordered!(job, [
      "Boot disposable exact-Hex host and run nonvisual compatibility gate",
      "Execute 20-stage exact-Hex generated-host proof",
      "Execute exact-Hex trust journey"
    ])
  end

  defp git!(directory, args) do
    {output, status} = System.cmd("git", args, cd: directory, stderr_to_stdout: true)
    assert status == 0, "git #{Enum.join(args, " ")} failed:\n#{output}"
    output
  end

  defp git_output!(directory, args), do: directory |> git!(args) |> String.trim()

  defp assert_ordered!(source, tokens) do
    Enum.reduce(tokens, source, fn token, remaining ->
      [_before, after_token] = String.split(remaining, token, parts: 2)
      after_token
    end)
  end
end
