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
end
