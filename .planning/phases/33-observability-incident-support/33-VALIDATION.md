---
phase: 33
slug: observability-incident-support
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for operator incident docs, durable support-summary facts, and delivery-centric support card drilldowns.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest |
| **Config file** | `config/test.exs` and `mailglass_admin/config/test.exs` |
| **Quick run command** | `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs test/mailglass/operator/support_summary_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` and `cd mailglass_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~45s quick / ~120s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-local command for the files just changed
- **After every plan wave:** rerun the quick phase commands in both projects
- **Before `$gsd-verify-work`:** rerun the full suite commands in both projects
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | MAT-02 | T-33-01, T-33-02 | the canonical guide exposes symptom-first incident paths, honesty notes, and current telemetry names without PII-bearing examples | docs contract | `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs --warnings-as-errors` | ✅ Task 1 creates file | ⬜ pending |
| 33-01-02 | 01 | 1 | MAT-02 | T-33-01, T-33-03 | telemetry/webhook/admin docs stay aligned with shipped replay, reconcile, and provider-fact vocabulary | docs contract / unit | `mix test test/mailglass/docs_contract_test.exs test/mailglass/webhook/telemetry_test.exs test/mailglass/telemetry_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 33-02-01 | 02 | 2 | MAT-02 | T-33-04, T-33-05 | support summaries come from tenant-scoped durable facts and keep failed ingest, orphan backlog, replay outcomes, and reconcile facts separate | core integration | `mix test test/mailglass/operator/support_summary_test.exs --warnings-as-errors` | ✅ Task 1 creates file | ⬜ pending |
| 33-02-02 | 02 | 2 | MAT-02 | T-33-04, T-33-06 | exemplars stay tenant-scoped and time-window-bounded, with no raw payload or cross-tenant leakage | core integration | `mix test test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors` | ✅ Task 1 creates file | ⬜ pending |
| 33-03-01 | 03 | 3 | MAT-02 | T-33-07, T-33-08, T-33-09 | support cards render only inside the authenticated operator flow and distinguish provider, replay, and reconcile facts clearly | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 33-03-02 | 03 | 3 | MAT-02 | T-33-07, T-33-08 | each support card can drill to a concrete selected delivery, webhook row, or durable audit fact instead of stopping at aggregate status pills | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Task-Local Test Creation Requirements

- [x] `33-01` Task 1 creates `test/mailglass/docs/operator_incident_support_guide_test.exs` before running its docs-contract verification command
- [x] `33-02` Task 1 creates `test/mailglass/operator/support_summary_test.exs` before running its support-summary verification command
- [x] `33-03` continues to expand `mailglass_admin/test/mailglass_admin/operator_live_test.exs` inside the same tasks that verify it

---

## Manual-Only Verifications

All phase behaviors are expected to have automated verification.

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-33-01 | docs or telemetry recipes expose PII-bearing metadata examples | Information Disclosure | docs-contract tests reject recipient/body/payload examples and stale unsafe telemetry references | V1, V5 |
| T-33-02 | docs flatten provider lifecycle, replay, and reconcile into one vague repair story | Tampering / Repudiation | canonical guide must separate stage facts and honesty boundaries in tests and plan tasks | V1 |
| T-33-03 | support docs imply a new unauthenticated or cross-tenant incident console | Elevation of Privilege | keep docs anchored to the existing authenticated operator surface and optional external tooling only | V2, V4 |
| T-33-04 | support-summary queries leak cross-tenant or payload-level data | Information Disclosure | query only tenant-scoped IDs, statuses, timestamps, and counts; assert tenant isolation in tests | V4, V5 |
| T-33-05 | aggregate support cues misrepresent mutable local status as provider truth or real-time fleet health | Tampering | derive cards from durable facts and verify drilldowns point to concrete local evidence | V1 |
| T-33-06 | support-summary exemplars cross the tenant boundary or escape the selected window | Elevation of Privilege | test exact tenant/window scoping for exemplars and counts | V4 |
| T-33-07 | overview support surfaces leak more human identifiers than the selected-delivery detail needs | Information Disclosure | mask recipient-like fields by default in list/overview surfaces and verify selected-detail-only exactness | V1, V4 |
| T-33-08 | support cards stop at color/status copy with no concrete audit row or webhook exemplar | Repudiation | require drilldown behavior in LiveView tests so operators can reach a delivery, row, or timeline fact | V1 |
| T-33-09 | new support cues create extra action paths outside existing auth and recent-auth posture | Elevation of Privilege | keep the Phase 33 UI read-only apart from existing replay flows and verify it stays in the current operator mount | V2, V3, V4 |

---

## Validation Sign-Off

- [x] All tasks have automated verification with required test files created in-task or already present
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] No task relies on an implicit Wave 0 file-creation dependency
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
