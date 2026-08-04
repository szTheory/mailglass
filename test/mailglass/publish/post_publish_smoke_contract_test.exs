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

  test "published consumer smoke delegates the complete journey to the canonical runner" do
    workflow = File.read!(@workflow_path)
    consumer_install = extract_job!(workflow, "consumer-install", "published-trust-journey")

    assert consumer_install =~ "DEP_MODE: hex"
    assert consumer_install =~ "run: DEP_MODE=hex bash scripts/generated_host_proof.sh --stage all"
    assert consumer_install =~ "image: postgres:16-alpine"
    assert consumer_install =~ "POSTGRES_HOST: localhost"
    assert consumer_install =~ "--health-cmd pg_isready"
  end

  test "exact resolver-selected Hex journey rejects floating and local dependencies" do
    workflow = File.read!(@workflow_path)
    consumer_install = extract_job!(workflow, "consumer-install", "published-trust-journey")

    assert consumer_install =~ "DEP_MODE: hex"
    assert consumer_install =~ "elixir scripts/resolve_release_packages.exs"
    assert consumer_install =~ "jq -er '.packages[$package]'"
    assert consumer_install =~ "DEP_MODE=hex bash scripts/generated_host_proof.sh --stage all"
    assert consumer_install =~ "canonical runner rejects local/path/git dependencies"
    assert consumer_install =~ "floating dependency constraint"
    assert consumer_install =~ "release-proof-post-publish"
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

  defp extract_job!(workflow, start_key, next_key) do
    [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
    [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
    job
  end
end
