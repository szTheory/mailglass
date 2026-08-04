defmodule Mailglass.GeneratedHost.NegativeControlsTest do
  use ExUnit.Case, async: true

  @moduletag :generated_host
  @project_root Path.expand("../..", __DIR__)

  @tag control_family: :queue_schema
  test "queue and schema controls are closed, isolated, and prove no effects" do
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))
    template = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/host_template.ex"))
    runner = File.read!(Path.join(@project_root, "scripts/generated_host_proof.sh"))

    for control <- ~w(instance_unavailable schema_wrong) do
      assert journey =~ control
    end

    assert journey =~ "effect_snapshot"
    assert journey =~ "assert_unchanged!"
    assert journey =~ "with_mailglass_env"
    assert journey =~ "Mailglass.ProductionPreflight.run()"
    assert journey =~ ":unavailable_adapter"
    refute journey =~ "dependency_missing"
    refute journey =~ "canonical_queue_missing"
    refute journey =~ "migration_missing"
    assert template =~ "input_message"
    assert runner =~ "negative-controls"
    assert runner =~ "--family"
  end

  @tag control_family: :input
  test "input controls use the public outbound entrypoint and reject before effects" do
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))
    checkpoint = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/checkpoint.ex"))

    for control <-
          ~w(zero_recipient to_cc duplicate_recipient multiple_recipients unsupported_attachment unsupported_payload unsupported_provider_options oversized_json) do
      assert journey =~ control
    end

    assert journey =~ "Mailglass.Outbound.deliver_later"
    assert journey =~ "input_error_shape"
    assert journey =~ ":serialization_failed"
    assert journey =~ ":invalid_envelope"
    assert journey =~ "render_count"
    assert checkpoint =~ "negative_controls!"
    assert checkpoint =~ "before"
    assert checkpoint =~ "after"
    assert checkpoint =~ "nonzero effect delta"
  end

  @tag control_family: :input
  test "checkpoint validator rejects a negative control with a nonzero effect delta" do
    validator = Path.join(@project_root, "scripts/check_generated_host_proof.sh")

    checkpoint =
      Path.join(
        System.tmp_dir!(),
        "generated-host-negative-mutated-#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(checkpoint) end)

    File.write!(
      checkpoint,
      ~s({"schema_version":"generated_host_proof.v1","dependency_mode":"local","source_sha256":"#{String.duplicate("a", 64)}","packages":[],"stages":[{"name":"negative_controls","status":"passed","controls":[{"name":"zero_recipient","reason_class":"recipient_count_invalid","before":{"jobs":0,"deliveries":0,"events":0,"payloads":0,"captures":0,"renders":0,"tasks":0},"after":{"jobs":1,"deliveries":0,"events":0,"payloads":0,"captures":0,"renders":0,"tasks":0}}]}],"overall_status":"passed","checkpoint_sha256":"#{String.duplicate("b", 64)}"})
    )

    {_output, status} =
      System.cmd("bash", [validator, "--checkpoint", checkpoint], stderr_to_stdout: true)

    assert status != 0
  end

  @tag control_family: :input
  test "checkpoint validator accepts bounded recipient control names without treating them as PII" do
    validator = Path.join(@project_root, "scripts/check_generated_host_proof.sh")

    checkpoint =
      Path.join(
        System.tmp_dir!(),
        "generated-host-negative-valid-#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(checkpoint) end)

    File.write!(
      checkpoint,
      ~s({"schema_version":"generated_host_proof.v1","dependency_mode":"local","source_sha256":"#{String.duplicate("a", 64)}","packages":[],"stages":[{"name":"negative_controls","status":"passed","controls":[{"name":"zero_recipient","reason_class":"recipient_count_invalid","result":"rejected","before":{"jobs":0,"deliveries":0,"events":0,"payloads":0,"captures":0,"renders":0,"tasks":0},"after":{"jobs":0,"deliveries":0,"events":0,"payloads":0,"captures":0,"renders":0,"tasks":0}}]}],"overall_status":"passed","checkpoint_sha256":"#{String.duplicate("b", 64)}"})
    )

    {output, status} =
      System.cmd("bash", [validator, "--checkpoint", checkpoint], stderr_to_stdout: true)

    assert status == 0, output
  end

  @tag control_family: :input
  test "every input control requires a public rejection before its zero-effect snapshot is accepted" do
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))

    assert journey =~ "assert_input_rejected!"
    assert journey =~ "unsupported_provider_options"
    assert journey =~ "oversized_json"
    assert journey =~ "error.context[:reason_class]"

    template = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/host_template.ex"))

    for control <-
          ~w(to_cc duplicate_recipient multiple_recipients unsupported_attachment unsupported_payload unsupported_provider_options oversized_json) do
      assert template =~ ~s|input_message("#{control}")|
    end

    assert template =~ "Swoosh.Email.cc"
    assert template =~ "Map.put(&1, :attachments, [%{}])"
    assert template =~ "String.duplicate(\"x\", 1_048_577)"
  end
end
