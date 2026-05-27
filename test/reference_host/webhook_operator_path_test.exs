defmodule Mailglass.ReferenceHost.WebhookOperatorPathTest do
  use ExUnit.Case, async: false

  alias Mailglass.ReferenceHost.WebhookOperatorProof

  test "signed Postmark webhook enters the reference host router and persists" do
    proof = WebhookOperatorProof.run()

    assert proof.provider == "postmark"
    assert proof.route == "/inbound/:tenant_id/postmark"
    assert proof.positive_status == 200
    assert proof.positive_body["status"] in ["inserted", "duplicate"]
    assert proof.positive_tenant_resolved == true
  end

  test "forged Postmark webhook is verified before tenant persistence or execution work" do
    proof = WebhookOperatorProof.run()

    assert proof.negative_status == 401
    assert proof.negative_body["status"] == "rejected"
    assert proof.negative_reason == "bad_credentials"
    assert proof.verified_before_tenant == true
    assert proof.tenant_resolution_marker == nil
    assert proof.persistence_marker == nil
    assert proof.execution_marker == nil
  end
end
