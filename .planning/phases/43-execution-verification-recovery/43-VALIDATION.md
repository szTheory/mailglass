---
phase: 43
slug: execution-verification-recovery
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for restoring execution verification evidence and requirement bookkeeping for inbound Phases 39 to 41.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, docs-contract tests, grep/file verification over planning artifacts |
| **Config file** | `mailglass_inbound/mix.exs`, package-local test files, `.planning/REQUIREMENTS.md` |
| **Quick run command** | phase-local proof lane for the phase being recovered |
| **Full suite command** | `cd mailglass_inbound && mix test --warnings-as-errors` |
| **Estimated runtime** | ~30-90s per recovered phase lane |

---

## Sampling Rate

- **After every task commit:** rerun the narrow proof lane named by the task.
- **After every plan wave:** rerun the full proof lane for the affected recovered phase.
- **Before `$gsd-verify-work`:** confirm all recovered verification files exist and rerun the targeted package-local commands for Phases 39 to 41.
- **Max feedback latency:** 90 seconds per task lane.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | MODEL-01, ROUTE-01, MAILBOX-01 | T-43-01 | recovered Phase 39 report proves the public contract, persistence boundary, and docs contract with execution evidence rather than summary-only claims | integration + docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/inbound_message_test.exs test/mailglass_inbound/router_test.exs test/mailglass_inbound/mailbox_test.exs test/mailglass_inbound/persistence_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 43-02-01 | 02 | 1 | INGRESS-01, STORE-01 | T-43-02 | recovered Phase 40 report proves verify-first Postmark ingress, durable storage, duplicate collapse, and honest docs posture | integration + docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/postmark_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 43-03-01 | 03 | 2 | INGRESS-02, STORE-02 | T-43-03 | new Phase 41 validation strategy names the real proof lanes for SendGrid ingress, mailbox execution, replay, and docs contract | file/grep validation | `rg -n \"INGRESS-02|STORE-02|mailbox_execution_test|sendgrid_provider_test|docs_contract_test\" .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VALIDATION.md` | ⬜ task creates file | ⬜ pending |
| 43-03-02 | 03 | 2 | INGRESS-02, STORE-02 | T-43-04 | replacement Phase 41 verification report proves executed behavior, not plan quality | integration + docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/sendgrid_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 43-03-03 | 03 | 2 | MODEL-01, ROUTE-01, MAILBOX-01, INGRESS-01, STORE-01, INGRESS-02, STORE-02 | T-43-05 | requirement traceability flips only after the recovered verification artifacts exist and mark the mapped requirements satisfied | grep / artifact check | `rg -n \"MODEL-01|ROUTE-01|MAILBOX-01|INGRESS-01|STORE-01|INGRESS-02|STORE-02\" .planning/REQUIREMENTS.md .planning/phases/39-inbound-package-foundation/39-VERIFICATION.md .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VERIFICATION.md .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md` | ⬜ mixed existing/new | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The recovery work depends on already-present package-local test lanes and planning artifacts rather than new harness creation.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The wording in recovered verification reports is execution-evidence language rather than planning or summary language | all | This is partly a document-truth judgment, not only a command result | Compare the recovered reports against `35-VERIFICATION.md` and `37-VERIFICATION.md`; reject wording such as `planned`, `will`, or `passes checker` when describing executed Phase 39 to 41 behavior. |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit manual-only rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
