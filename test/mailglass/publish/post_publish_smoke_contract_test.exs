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
    assert resolver =~ "cmp --silent \"$control_resolved\" \"$resolved\""
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

    assert job =~ "mix verify.reference_host.journey --host-root \"${HOST_ROOT}\""
    assert job =~ "run: bash scripts/check_trust_runner_checkpoint.sh --require-completed"
    assert job =~ "name: trust-runner-published-${{ github.run_id }}"
    assert job =~ "if-no-files-found: error"
    assert job =~ "retention-days: 90"
    assert job =~ "path: tmp/mailglass_trust_runner/checkpoint.json"

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
    assert workflow =~ "trust-runner-published-${context.runId}"
    refute workflow =~ "gh issue close"
  end

  defp extract_job!(workflow, start_key, next_key) do
    [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
    [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
    job
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
