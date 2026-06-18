defmodule Mailglass.ReferenceHost.WebhookOperatorPathTest do
  use ExUnit.Case, async: false

  # Requires the full repo workspace (sibling MailglassInbound compiled for the
  # reference-host router), unavailable in the isolated-core Core Full Suite
  # Advisory lane. Excluded there via `--exclude requires_workspace`; covered in
  # CI by the dedicated Trust Lane lanes.
  @moduletag :requires_workspace

  alias Mailglass.ReferenceHost.OperatorDiagnosisProof
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

  test "no-match operator diagnosis evidence is deterministic and PII-safe" do
    evidence = OperatorDiagnosisProof.run()

    assert evidence["scenario"] == "no_match"
    assert evidence["outcome"] == "no_match"
    assert evidence["stage"] == "operator_troubleshooting"
    assert evidence["status_language"] == "no matching mailbox route"
    assert evidence["finding"] == "message did not match any configured inbound route"
    assert evidence["remediation"] == "review recipient, subject, and header route clauses"
    assert evidence["route_clause_dimensions"] == ["recipient", "subject", "header:x-priority"]
    assert evidence["trace_card_count"] == 3
    assert evidence["recipient_masked"] == true
    assert evidence["raw_payload_included"] == false
    assert evidence["private_recipient_included"] == false

    refute Map.has_key?(evidence, "raw_payload")
    refute Map.has_key?(evidence, "recipient")
    refute Map.has_key?(evidence, "sender")
    refute Map.has_key?(evidence, "subject")
    refute Map.has_key?(evidence, "rendered_html")
  end

  test "trust runner emits no-match operator evidence under operator_troubleshooting" do
    checkpoint_path =
      Path.expand(
        "../tmp/mailglass_trust_runner/operator-diagnosis-proof-test.json",
        __DIR__
      )

    File.rm(checkpoint_path)
    Mix.Task.rerun("mailglass.trust.run", ["--checkpoint-out", checkpoint_path])

    checkpoint = checkpoint_path |> File.read!() |> Jason.decode!()
    operator = Enum.find(checkpoint["checkpoints"], &(&1["stage"] == "operator_troubleshooting"))

    assert operator["status"] == "completed"
    assert operator["fixture_id"] == "trust.operator_troubleshooting.001"
    assert operator["evidence"]["scenario"] == "no_match"
    assert operator["evidence"]["outcome"] == "no_match"
    assert operator["evidence"]["status_language"] == "no matching mailbox route"
    assert operator["evidence"]["recipient_masked"] == true
    assert operator["evidence"]["raw_payload_included"] == false
  end
end
