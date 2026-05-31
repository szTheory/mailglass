---
phase: 58-verify-first-webhook-operator-path
reviewed: 2026-05-27T22:39:17Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/mailglass/reference_host/operator_diagnosis_proof.ex
  - lib/mailglass/reference_host/trust_checkpoint.ex
  - lib/mailglass/reference_host/webhook_operator_proof.ex
  - lib/mix/tasks/mailglass.trust.run.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
  - reference/host_app/README.md
  - scripts/check_trust_runner_checkpoint.sh
  - test/reference_host/trust_runner_checkpoint_contract_test.exs
  - test/reference_host/trust_runner_command_contract_test.exs
  - test/reference_host/webhook_operator_path_test.exs
  - test/support/reference_host/trust_runner_fixtures.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 58: Code Review Report

**Reviewed:** 2026-05-27T22:39:17Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed the Phase 58 trust-runner proof modules, checkpoint encoder, Mix task, ingress plug path, shell validator, README contract text, and supporting tests. The new reference-host proof path is narrowly scoped and has good regression coverage for signed/forged Postmark routing and no-match operator evidence.

One existing ingress behavior in the reviewed scope is still incorrect for SES/SNS retry semantics: a permanent S3 fetch failure returns a non-2xx response while the code and tests claim that this stops redelivery.

## Warnings

### WR-01: Permanent SES S3 Failures Still Trigger SNS Redelivery

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:151`

**Issue:** The `S3FetchError` rescue maps `:s3_fetch_failed` to HTTP 422. For an SES inbound path delivered through SNS, any non-2xx endpoint response is treated as a failed delivery and SNS retries according to the topic subscription policy. The surrounding comment says 422 is permanent and "stops the redelivery storm", but the implementation does the opposite for SNS: permanent failures such as access denied or missing bucket will keep redelivering without any record being persisted, because this branch exits before persistence and dedupe. The test at `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs:587` also locks in the incorrect assumption.

**Fix:** Acknowledge non-retryable SES S3 failures with a 2xx no-op response, while keeping transient `:s3_object_not_ready` as non-2xx so SNS retries. Also update the plug test to expect the permanent path to ack.

```elixir
e in S3FetchError ->
  {status, response_status} =
    case e.type do
      :s3_object_not_ready -> {500, "s3_fetch_error"}
      :s3_fetch_failed -> {200, "s3_fetch_failed"}
    end

  resp =
    send_json(conn, status, %{
      status: response_status,
      reason: Atom.to_string(e.type)
    })

  {resp, %{provider: provider, status: :s3_fetch_error, error_kind: e.type}}
```

---

_Reviewed: 2026-05-27T22:39:17Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
