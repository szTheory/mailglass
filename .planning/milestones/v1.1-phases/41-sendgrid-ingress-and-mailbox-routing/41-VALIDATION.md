---
phase: 41
slug: sendgrid-ingress-and-mailbox-routing
status: recovered
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 41 - Validation Strategy

> Recovered validation contract for truthful SendGrid ingress, post-commit mailbox execution, replay-over-stored-truth, and docs-contract enforcement.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Plug request tests + persistence/replay integration + docs contract tests |
| **Config file** | `mailglass_inbound/config/test.exs`, `mailglass_inbound/test/test_helper.exs`, ingress modules, execution lineage schema, replay seam |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/sendgrid_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/sendgrid_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~20-40s task-local / ~90-150s full phase scope |

---

## Sampling Rate

- After every task commit, rerun the smallest changed-surface lane.
- After every plan wave, rerun the affected combined SendGrid or execution lane.
- Before `$gsd-verify-work`, rerun the full Phase 41 proof bundle.
- Max feedback latency: 150 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | `INGRESS-02` | T-41-01, T-41-02 | SendGrid auth fails closed and normalization requires raw MIME instead of lossy multipart-only parsing | provider | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/sendgrid_provider_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 41-01-02 | 01 | 1 | `INGRESS-02` | T-41-01, T-41-03 | Shared ingress plug verifies before tenant resolution and preserves provider-only facts outside the canonical struct | plug integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/ingress/sendgrid_provider_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 41-02-01 | 02 | 2 | `STORE-02` | T-41-04, T-41-05, T-41-06 | Durable receive truth commits before mailbox execution and every attempt appends execution lineage | execution + replay | `cd mailglass_inbound && mix test test/mailglass_inbound/replay_test.exs test/mailglass_inbound/mailbox_execution_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 41-02-02 | 02 | 2 | `STORE-02` | T-41-04, T-41-06 | Post-commit mailbox runner records semantic outcomes and failure classes while ingress still acknowledges after durable persistence | plug + execution | `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 41-03-01 | 03 | 3 | `INGRESS-02`, `STORE-02` | T-41-07, T-41-08 | SendGrid duplicate collapse uses raw MIME fingerprint truth and replay reruns stored canonical plus evidence truth | replay + plug | `cd mailglass_inbound && mix test test/mailglass_inbound/replay_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 41-03-02 | 03 | 3 | `INGRESS-02`, `STORE-02` | T-41-08, T-41-09 | Docs and contract tests keep SendGrid security, replay, and public-surface claims honest | docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing shipped tests cover the recovered phase requirements. The audit gap was missing validation-artifact generation, not missing test surface.

---

## Manual-Only Verifications

All recovered Phase 41 behaviors are backed by automated proof lanes.

---

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 gaps are artifact-generation only
- [x] No watch-mode flags
- [x] Feedback latency < 150s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** recovered 2026-05-06
