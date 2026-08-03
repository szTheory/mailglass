defmodule Mailglass.GeneratedHost.HttpJourneyTest do
  use ExUnit.Case, async: true

  @moduletag :generated_host
  @project_root Path.expand("../..", __DIR__)

  @tag journey: :feedback
  test "generated host sends signed and forged provider feedback through its public HTTP router" do
    template = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/host_template.ex"))
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))

    assert template =~ "GeneratedHostWeb.Router"
    assert template =~ "mailglass_webhook_routes"
    assert template =~ "Mailglass.Webhook.CachingBodyReader"
    assert template =~ "basic_auth"
    assert journey =~ "feedback!"
    assert journey =~ "http_post!"
    assert journey =~ "forged"
    assert journey =~ "webhook_events"
    refute journey =~ "Plug.Test"
    refute journey =~ "Webhook.Ingest.ingest"
  end

  @tag journey: :feedback
  test "checkpoint rejects incomplete or privacy-leaking feedback evidence" do
    validator = Path.join(@project_root, "scripts/check_generated_host_proof.sh")

    checkpoint =
      Path.join(
        System.tmp_dir!(),
        "generated-host-feedback-#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(checkpoint) end)

    File.write!(
      checkpoint,
      ~s({"schema_version":"generated_host_proof.v1","dependency_mode":"local","source_sha256":"#{String.duplicate("a", 64)}","packages":[],"stages":[{"name":"feedback","status":"passed","valid_status":200}],"overall_status":"passed","checkpoint_sha256":"#{String.duplicate("b", 64)}"})
    )

    {_output, status} =
      System.cmd("bash", [validator, "--checkpoint", checkpoint], stderr_to_stdout: true)

    assert status != 0
  end

  @tag journey: :one_click
  test "generated host replays a delivery-derived one-click request and proves scoped public enforcement" do
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))
    checkpoint = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/checkpoint.ex"))

    assert journey =~ "one_click!"
    assert journey =~ "List-Unsubscribe-Post"
    assert journey =~ "Mailglass.Outbound.deliver"
    assert journey =~ "matching"
    assert journey =~ "transactional"
    assert journey =~ "unrelated"
    assert checkpoint =~ "one_click!"
    refute journey =~ "UnsubscribeConvergence.run"
    refute journey =~ "UnsubscribeController.unsubscribe"
  end
end
