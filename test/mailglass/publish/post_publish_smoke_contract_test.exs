defmodule Mailglass.Publish.PostPublishSmokeContractTest do
  use ExUnit.Case, async: true

  # Exercises the published post-publish-smoke trust journey (reference-host proof
  # + sibling MailglassInbound), unavailable in the isolated-core Core Full Suite
  # Advisory lane. Excluded there via `--exclude requires_workspace`; the
  # post-publish smoke runs for real in the publish-hex pipeline.
  @moduletag :requires_workspace

  @workflow_path Path.expand("../../../.github/workflows/post-publish-smoke.yml", __DIR__)

  test "published trust journey runs full reference-host proof and uploads checkpoint" do
    workflow = File.read!(@workflow_path)
    job = extract_job!(workflow, "published-trust-journey", "retracted-check")

    assert job =~ "needs: [cron-guard, consumer-install]"
    assert job =~ "if: ${{ needs.cron-guard.outputs.should_run == 'true' }}"
    assert job =~ "timeout-minutes: 20"
    assert job =~ "ref: ${{ needs.cron-guard.outputs.release_ref }}"
    assert job =~ "working-directory: reference/host_app"
    assert job =~ "run: bash ../../scripts/check_clean_baseline_hex_only.sh"
    assert job =~ "run: mix verify.reference_host.journey --host-root reference/host_app"
    assert job =~ "run: bash scripts/check_trust_runner_checkpoint.sh"
    assert job =~ "name: trust-runner-published-${{ github.run_id }}"
    assert job =~ "if-no-files-found: error"
    assert job =~ "retention-days: 90"
    assert job =~ "path: tmp/mailglass_trust_runner/checkpoint.json"
  end

  test "published consumer smoke delegates install guards to the shared script" do
    workflow = File.read!(@workflow_path)
    consumer_install = extract_job!(workflow, "consumer-install", "published-trust-journey")

    assert consumer_install =~ "DEP_MODE: hex"
    assert consumer_install =~ "run: bash scripts/consumer_install_smoke.sh"
  end

  test "consumer smoke resolves all exact packages from an immutable completed target" do
    workflow = File.read!(@workflow_path)
    cron_guard = extract_job!(workflow, "cron-guard", "wait-for-index")
    consumer_install = extract_job!(workflow, "consumer-install", "published-trust-journey")

    assert cron_guard =~
             "version_inbound: ${{ needs.resolve-completed-target.outputs.inbound }}"

    assert workflow =~ "resolve-completed-target:"
    assert workflow =~ "completed-versions .planning/release-target.json"
    assert workflow =~ "validate_completed_target"
    assert cron_guard =~ "COMPLETED_CORE"
    assert cron_guard =~ "COMPLETED_ADMIN"
    assert cron_guard =~ "COMPLETED_INBOUND"
    refute cron_guard =~ "read-inbound-version"

    assert consumer_install =~
             "VERSION_INBOUND: ${{ needs.cron-guard.outputs.version_inbound }}"

    assert consumer_install =~
             "Published consumer proof could not resolve mailglass_inbound from the release ref."

    assert consumer_install =~ ~s(mix hex.info mailglass_inbound "${VERSION_INBOUND}")
    assert consumer_install =~ "exit 1"
    refute consumer_install =~ "Skipping inbound consumer dependency"

    assert consumer_install =~ "DEP_MODE: hex"
    assert consumer_install =~ "VERSION: ${{ needs.cron-guard.outputs.version }}"
    assert consumer_install =~ "INCLUDE_INBOUND: true"
  end

  test "post-publish smoke auto-closes tracker only after green guard and journey evidence" do
    workflow = File.read!(@workflow_path)

    assert(workflow =~ "close-publish-smoke-tracker-on-success:")
    assert(workflow =~ "name: Close issue on smoke success")

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
    assert workflow =~ "OPS-01 guard:"
    assert workflow =~ "consumer-install"
    assert workflow =~ "EVID-03 journey:"
    assert workflow =~ "published-trust-journey"

    refute workflow =~ "gh issue close"
  end

  test "smoke accepts three explicit exact versions and resolves automation paths from completed targets" do
    workflow = File.read!(@workflow_path)

    for input <- ["core_version:", "admin_version:", "inbound_version:"] do
      assert workflow =~ input
    end

    assert workflow =~ "validate_completed_target"
    assert workflow =~ "mailglass_admin"
    assert workflow =~ "mailglass_inbound"
    cron_guard = extract_job!(workflow, "cron-guard", "wait-for-index")
    refute cron_guard =~ "releases.list"
  end

  defp extract_job!(workflow, start_key, next_key) do
    [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
    [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
    job
  end
end
