defmodule Mailglass.GeneratedHost.SyncAsyncParityTest do
  use ExUnit.Case, async: true

  @project_root Path.expand("../..", __DIR__)

  test "generated host defines a real normal-mode sync/async parity journey" do
    template = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/host_template.ex"))
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))

    assert template =~ "GeneratedHost.CaptureAdapter"
    assert template =~ "GeneratedHost.SampleMailable"
    assert template =~ "queues: [mailglass_outbound: 1]"
    assert template =~ "{Oban, Application.fetch_env!(:generated_host, Oban)}"
    assert journey =~ "Mailglass.Outbound.deliver"
    assert journey =~ "Mailglass.Outbound.deliver_later"
    assert journey =~ "poll_until!"
    assert journey =~ "oban_jobs"
    assert journey =~ "mailglass_outbound"
    refute journey =~ "Worker.perform"
    refute journey =~ "Oban.drain_queue"
    refute journey =~ "testing: :"
  end

  test "generated host records only hashed async lifecycle evidence" do
    checkpoint = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/checkpoint.ex"))
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))

    assert checkpoint =~ "async_parity"
    assert checkpoint =~ "payload_scrubbed"
    assert journey =~ "payload_scrubbed"
    assert journey =~ "transition_order"
    assert journey =~ "sha"
    refute checkpoint =~ "recipient"
    refute checkpoint =~ "provider_input"
  end

  test "checkpoint rejects an async stage without durable scrub evidence" do
    validator = Path.join(@project_root, "scripts/check_generated_host_proof.sh")

    checkpoint =
      Path.join(
        System.tmp_dir!(),
        "generated-host-async-incomplete-#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(checkpoint) end)

    File.write!(
      checkpoint,
      ~s({"schema_version":"generated_host_proof.v1","dependency_mode":"local","source_sha256":"#{String.duplicate("a", 64)}","packages":[],"stages":[{"name":"install","status":"passed"},{"name":"migrate","status":"passed"},{"name":"async_parity","status":"passed"}],"overall_status":"passed","checkpoint_sha256":"#{String.duplicate("b", 64)}"})
    )

    {_output, status} =
      System.cmd("bash", [validator, "--checkpoint", checkpoint], stderr_to_stdout: true)

    assert status != 0
  end
end
