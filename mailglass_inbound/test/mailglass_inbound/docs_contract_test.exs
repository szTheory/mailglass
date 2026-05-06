defmodule MailglassInbound.DocsContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../README.md", __DIR__)
  @stability_path Path.expand("../../docs/api_stability.md", __DIR__)
  @postmark_ingress_path Path.expand("../../docs/postmark_ingress.md", __DIR__)
  @sendgrid_ingress_path Path.expand("../../docs/sendgrid_ingress.md", __DIR__)
  @operator_trust_path Path.expand("../../../mailglass_admin/docs/operator-trust.md", __DIR__)

  test "docs inventory names the stable public modules for the inbound slice" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    for module_name <- [
          "MailglassInbound.InboundMessage",
          "MailglassInbound.Ingress.Plug",
          "MailglassInbound.Ingress.CachingBodyReader",
          "MailglassInbound.Router",
          "MailglassInbound.Mailbox"
        ] do
      assert readme =~ module_name
      assert stability =~ module_name
    end

    assert stability =~ "stable"
    assert stability =~ "internal"
    assert stability =~ "deferred"
  end

  test "package docs describe canonical storage plus raw evidence without widening provider internals" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    postmark = File.read!(@postmark_ingress_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    for doc <- [readme, stability, postmark, sendgrid] do
      assert doc =~ "canonical"
      assert doc =~ "raw evidence"
      assert doc =~ "replay"
      refute doc =~ "public provider behaviour"
      refute doc =~ "public provider extension API"
      refute doc =~ "Conductor UI"
    end
  end

  test "postmark docs describe the body_reader requirement and explicit duplicate semantics" do
    postmark = File.read!(@postmark_ingress_path)

    assert postmark =~ "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
    assert postmark =~ "MailglassInbound.Ingress.Plug"
    assert postmark =~ "duplicate"
    assert postmark =~ "route compatibility"
    refute postmark =~ "Mailbox.process/1 runs during ingress"
  end

  test "docs make the optional Oban seam explicit without making Oban mandatory" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    assert readme =~ "Oban-backed execution"
    assert readme =~ "Task.Supervisor fallback"
    assert readme =~ "best-effort only"
    assert readme =~ "replay or operator action"
    assert stability =~ "MailglassInbound.OptionalDeps.Oban"
    assert stability =~ "MailglassInbound.Execution.Worker"
    assert stability =~ "Task.Supervisor"
    assert stability =~ "not part of the stable contract"

    for doc <- [readme, stability] do
      refute doc =~ "Oban is required"
      refute doc =~ "%Oban.Job{}"
    end
  end

  test "sendgrid docs describe raw mime, basic auth, and persistence-before-execution posture" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    for doc <- [readme, stability, sendgrid] do
      assert doc =~ "SendGrid"
      assert doc =~ "basic auth"
      assert doc =~ "raw MIME"
      assert doc =~ "before mailbox execution"
    end

    assert sendgrid =~ "execution outcomes do not control provider retries"
    assert sendgrid =~ "raw_mime_fingerprint"
  end

  test "readme gives one canonical manual setup lane and rejects installer framing" do
    readme = File.read!(@readme_path)

    assert readme =~ "mix deps.get"
    assert readme =~ "mix ecto.migrate"
    assert readme =~ "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
    assert readme =~ ~s(forward "/inbound/:tenant_id/postmark")
    assert readme =~ ~s(forward "/inbound/:tenant_id/sendgrid")
    assert readme =~ "router: MyApp.MailglassInboundRouter"
    assert readme =~ "Oban-backed execution is the durable path"
    assert readme =~ "Task.Supervisor fallback is bounded best-effort only"
    assert readme =~ "mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"

    refute readme =~ "mix mailglass.install"
    refute readme =~ "installer"
  end

  test "stability docs keep workers, queue details, and replay orchestration internal" do
    stability = File.read!(@stability_path)

    assert stability =~ "MailglassInbound.Execution.Worker"
    assert stability =~ "queue names"
    assert stability =~ "internal"
    assert stability =~ "public replay API"

    refute stability =~ "stable public replay API"
    refute stability =~ "public worker contract"
  end

  test "operator trust docs keep replay separate from fresh receive and public ui claims" do
    operator_trust = File.read!(@operator_trust_path)

    assert operator_trust =~ "fresh provider receipt"
    assert operator_trust =~ "Task.Supervisor fallback"
    assert operator_trust =~ "best-effort"
    assert operator_trust =~ "no_prior_match"
    assert operator_trust =~ "execution_history_missing"

    refute operator_trust =~ "public replay API"
    refute operator_trust =~ "operator UI already ships"
    refute operator_trust =~ "silent reroute"
  end

  test "docs reject replay-as-fresh and unshipped verification claims" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    for doc <- [readme, stability, sendgrid] do
      refute doc =~ "replay as fresh receive"
      refute doc =~ "re-ingest provider payloads"
      refute doc =~ "signed multipart verification shipped"
      refute doc =~ "replay reroutes silently"
    end
  end

  test "docs exclude deferred matcher, mailbox lifecycle, and fan-out claims" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    postmark = File.read!(@postmark_ingress_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

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

    for doc <- [readme, stability, postmark, sendgrid], claim <- forbidden_claims do
      refute doc =~ claim
    end
  end
end
