---
phase: 58
slug: verify-first-webhook-operator-path
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-27
---

# Phase 58 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| External webhook -> reference host router | Untrusted Postmark webhook payload and headers enter `POST /inbound/:tenant_id/postmark`. | Provider request body, headers, and authentication facts. |
| Reference host router -> inbound ingress plug | Public reference-host route delegates to `MailglassInbound.Ingress.Plug`; verification must happen before tenant, persistence, or execution work. | Verified or rejected ingress request state. |
| Inbound record -> operator diagnosis | Tenant-scoped inbound message facts are transformed into operator-facing no-match diagnosis evidence. | Bounded route-trace facts and masked diagnosis state. |
| Runner -> checkpoint artifact | Local command emits machine-readable evidence consumed by later CI/release phases. | `trust_runner.v1` checkpoint rows and bounded evidence maps. |
| Checkpoint artifact -> shell validator | JSON evidence crosses from Elixir encoder into Bash/Python validation. | Schema, stage, hash, and evidence fields. |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| 58-01:T-58-01 | Spoofing/Tampering | `POST /inbound/:tenant_id/postmark` via `MailglassReferenceHostWeb.Router` | mitigate | Route-level proof asserts forged Postmark returns 401, `status: "rejected"`, `reason: "bad_credentials"`, and nil tenant/persistence/execution markers; signed and forged requests execute through `MailglassReferenceHostWeb.Router.call/2`. Evidence: `test/reference_host/webhook_operator_path_test.exs:17`, `lib/mailglass/reference_host/webhook_operator_proof.ex:113`, `lib/mailglass/reference_host/webhook_operator_proof.ex:123`. | closed |
| 58-01:T-58-02 | Information Disclosure | `webhook_ingest` evidence map | mitigate | Runner emits bounded webhook evidence keys only, and fixture tests pin the expected map. Raw payload, headers, sender, recipient, subject, and body are not included in runner evidence. Evidence: `lib/mix/tasks/mailglass.trust.run.ex:156`, `test/support/reference_host/trust_runner_fixtures.ex:40`. | closed |
| 58-01:T-58-03 | Information Disclosure | Operator diagnosis | accept | Plan 01 accepted this only as an intra-phase deferral. Plan 02 superseded the temporary acceptance with bounded operator diagnosis evidence before phase completion. Evidence: `lib/mailglass/reference_host/operator_diagnosis_proof.ex:46`, `test/reference_host/webhook_operator_path_test.exs:29`. | closed |
| 58-01:T-58-04 | Repudiation/Tampering | Runner checkpoint stage semantics | mitigate | Five-stage pipeline, `trust_runner.v1`, row-hash scope, and dry-run compatibility are preserved. Evidence: `lib/mix/tasks/mailglass.trust.run.ex:33`, `lib/mailglass/reference_host/trust_checkpoint.ex:6`, `lib/mailglass/reference_host/trust_checkpoint.ex:64`, `test/reference_host/trust_runner_checkpoint_contract_test.exs:12`. | closed |
| 58-02:T-58-01 | Spoofing/Tampering | `webhook_ingest` checkpoint evidence | mitigate | Validator requires `negative_status == 401`, `negative_reason == "bad_credentials"`, and `verified_before_tenant == true`; contract tests assert generated checkpoint evidence. Evidence: `scripts/check_trust_runner_checkpoint.sh:170`, `test/reference_host/trust_runner_checkpoint_contract_test.exs:78`. | closed |
| 58-02:T-58-02 | Information Disclosure | Checkpoint evidence JSON | mitigate | Validator defines forbidden evidence keys and recursively rejects them; contract tests validate malformed evidence rejection. Evidence: `scripts/check_trust_runner_checkpoint.sh:137`, `scripts/check_trust_runner_checkpoint.sh:149`, `test/reference_host/trust_runner_checkpoint_contract_test.exs:108`. | closed |
| 58-02:T-58-03 | Information Disclosure | `operator_troubleshooting` diagnosis evidence | mitigate | Operator evidence includes only bounded no-match facts: `recipient_masked`, `raw_payload_included: false`, `private_recipient_included: false`, route dimensions, and trace count. Tests assert raw payload, recipient, sender, subject, and rendered HTML keys are absent. Evidence: `lib/mailglass/reference_host/operator_diagnosis_proof.ex:46`, `test/reference_host/webhook_operator_path_test.exs:44`. | closed |
| 58-02:T-58-04 | Repudiation/Tampering | `TrustCheckpoint` and `scripts/check_trust_runner_checkpoint.sh` | mitigate | `trust_runner.v1`, fixed stage order, and SHA-256 over ordered `stage|status|fixture_id` rows are preserved and validated. Evidence: `lib/mailglass/reference_host/trust_checkpoint.ex:6`, `lib/mailglass/reference_host/trust_checkpoint.ex:10`, `lib/mailglass/reference_host/trust_checkpoint.ex:64`, `scripts/check_trust_runner_checkpoint.sh:51`, `scripts/check_trust_runner_checkpoint.sh:202`. | closed |

Status: open · closed
Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-58-01 | 58-01:T-58-03 | Plan 01 accepted operator-diagnosis disclosure risk only as an intra-phase deferral. Plan 02 implemented bounded operator evidence before Phase 58 completion, so there is no remaining accepted production risk for this threat. | GSD security audit | 2026-05-27 |

## Threat Flags

| Flag | Source | Mapping | Disposition |
|------|--------|---------|-------------|
| threat_flag: config_surface | `58-01-SUMMARY.md`; `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | Informational, maps to verification harness support for 58-01:T-58-01 and evidence generation for 58-01:T-58-02. | Not a blocker; production defaults remain unchanged and the proof saves/restores app env in `lib/mailglass/reference_host/webhook_operator_proof.ex:209`. |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-27 | 8 | 8 | 0 | gsd-security-auditor |

## Verification Notes

- Required phase plans and summaries were loaded before analysis.
- Project-local `.claude/skills` and `.agents/skills` directories were checked; no repo-local skill indexes were present.
- Implementation files were read-only during this audit. Only this `58-SECURITY.md` file was created.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-27
