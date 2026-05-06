defmodule MailglassInbound.DocsContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../README.md", __DIR__)
  @stability_path Path.expand("../../docs/api_stability.md", __DIR__)

  test "docs inventory names the stable phase 39 public modules" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    for module_name <- ["MailglassInbound.InboundMessage", "MailglassInbound.Router", "MailglassInbound.Mailbox"] do
      assert readme =~ module_name
      assert stability =~ module_name
    end

    assert stability =~ "stable"
    assert stability =~ "internal"
    assert stability =~ "deferred"
  end

  test "package docs describe canonical storage plus raw evidence without overstating shipped ingress" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    for doc <- [readme, stability] do
      assert doc =~ "canonical"
      assert doc =~ "raw evidence"
      assert doc =~ "replay"
      refute doc =~ "Postmark ingress ships today"
      refute doc =~ "SendGrid ingress ships today"
      refute doc =~ "Conductor UI"
    end
  end

  test "docs make the optional Oban seam explicit without making Oban mandatory" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    assert readme =~ "optional Oban"
    assert stability =~ "MailglassInbound.OptionalDeps.Oban"
    assert stability =~ "not part of the stable contract"

    for doc <- [readme, stability] do
      refute doc =~ "Oban is required"
      refute doc =~ "%Oban.Job{}"
    end
  end

  test "docs exclude deferred matcher, mailbox lifecycle, and fan-out claims" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    forbidden_claims = [
      "body matcher",
      "attachment matcher",
      "raw MIME matcher",
      "multi-match fan-out",
      "before_process",
      "after_process",
      "around_process",
      "handle_failed"
    ]

    for doc <- [readme, stability], claim <- forbidden_claims do
      refute doc =~ claim
    end
  end
end
