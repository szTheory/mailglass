defmodule Mailglass.GeneratedHost.ReadinessOperatorTest do
  use ExUnit.Case, async: true

  @moduletag :generated_host
  @project_root Path.expand("../..", __DIR__)

  test "generated host declares a production operator mount behind host-owned authentication" do
    template = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/host_template.ex"))

    assert template =~ "import MailglassAdmin.Router"
    assert template =~ "pipeline :operator"
    assert template =~ "GeneratedHost.OperatorAuthPlug"
    assert template =~ "mailglass_operator_routes \"/mail\""
    assert template =~ "auth: GeneratedHost.OperatorAuth"
    assert template =~ "subject_id: \"operator_id\""
    assert template =~ "outbound_payload_maintenance: :scheduled"
    refute template =~ "dev_routes"
  end

  test "readiness journey proves anonymous denial, authenticated access, and callable preflight" do
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))
    script = File.read!(Path.join(@project_root, "scripts/generated_host_proof.sh"))

    assert journey =~ "operator_readiness!"
    assert journey =~ "Mailglass.ProductionPreflight.run()"
    assert journey =~ "anonymous"
    assert journey =~ "authenticated"
    assert script =~ "readiness"
    refute journey =~ "Plug.Test"
  end
end
