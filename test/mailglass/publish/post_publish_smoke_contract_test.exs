defmodule Mailglass.Publish.PostPublishSmokeContractTest do
  use ExUnit.Case, async: true

  @moduletag :requires_workspace

  @workflow_path Path.expand("../../../.github/workflows/post-publish-smoke.yml", __DIR__)
  @hex_lock_guard Path.expand("../../../scripts/check_clean_baseline_hex_only.sh", __DIR__)
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

    assert resolver =~ ~s("$command" .planning/release-target.json)
    assert resolver =~ "[ -n \"$INPUT_CORE\" ]"
    assert resolver =~ "[ -n \"$INPUT_ADMIN\" ]"
    assert resolver =~ "[ -n \"$INPUT_INBOUND\" ]"
    assert resolver =~ "[ \"$INPUT_CORE\" = \"$core\" ]"
    assert resolver =~ "[ \"$INPUT_ADMIN\" = \"$admin\" ]"
    assert resolver =~ "[ \"$INPUT_INBOUND\" = \"$inbound\" ]"
    assert resolver =~ "ref: ${{ github.sha }}"

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
    assert job =~ ~s({:mailglass, "== ${VERSION_CORE}"})
    assert job =~ ~s({:mailglass_admin, "== ${VERSION_ADMIN}"})
    assert job =~ ~s({:mailglass_inbound, "== ${VERSION_INBOUND}"})
    assert job =~ "mix deps.get"
    assert job =~ "MAILGLASS_EXPECTED_CORE_VERSION"
    assert job =~ "MAILGLASS_EXPECTED_ADMIN_VERSION"
    assert job =~ "MAILGLASS_EXPECTED_INBOUND_VERSION"
    assert job =~ "bash \"${GITHUB_WORKSPACE}/scripts/check_clean_baseline_hex_only.sh\" mix.lock"
    assert job =~ "mix compile --warnings-as-errors"
    assert job =~ "Application.ensure_all_started(:mailglass_reference_host)"
    assert job =~ "Application.spec(app, :vsn)"
    assert job =~ "run: mix verify.reference_host.journey --dry-run --host-root"
    assert job =~ "run: bash scripts/check_trust_runner_checkpoint.sh"
    assert job =~ "name: trust-runner-published-${{ github.run_id }}"
    assert job =~ "if-no-files-found: error"
    assert job =~ "retention-days: 90"
    assert job =~ "path: tmp/mailglass_trust_runner/checkpoint.json"

    refute job =~ "working-directory: reference/host_app"
    refute job =~ "mix verify.reference_host.journey --host-root reference/host_app"
    refute job =~ "mix deps.get && mix compile"
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
        "\\1\"short\"", global: false)

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
end
