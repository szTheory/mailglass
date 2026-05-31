defmodule Mailglass.Publish.PostPublishSmokeContractTest do
  use ExUnit.Case, async: true

  @workflow_path Path.expand("../../../.github/workflows/post-publish-smoke.yml", __DIR__)

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
    assert workflow =~ "OPS-01 guard:"
    assert workflow =~ "consumer-install"
    assert workflow =~ "EVID-03 journey:"
    assert workflow =~ "published-trust-journey"

    refute workflow =~ "gh issue close"
  end
end
