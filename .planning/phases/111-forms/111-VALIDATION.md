---
phase: 111
slug: forms
status: planning-ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
---

# Phase 111 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix.LiveViewTest plus Playwright structural tests |
| **Config file** | `mailglass_admin/test/test_helper.exs`, `mailglass_admin/playwright.config.cjs`, `mailglass_admin/package.json`, `mailglass_admin/scripts/check-conformance.sh` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser` |
| **Estimated runtime** | ~120-240 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrow ExUnit file for the touched code, plus `cd mailglass_admin && ./scripts/check-conformance.sh` when primitive or filter markup changes.
- **After every plan wave:** Run `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` and `cd mailglass_admin && npm run test:operator-browser`.
- **Before `/gsd:verify-work`:** Run `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser`.
- **Max feedback latency:** 240 seconds for full phase gate; narrow task checks should stay under 90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-T2 | 111-01 Task 2 | 1 | FORM-02/FORM-03 | T-111-01/T-111-02/T-111-03 | Shared primitives source-assert visible labels, help/error IDs, ARIA state, disabled, and read-only/display-only behavior | component | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | yes, extend | pending |
| 111-02-T1 | 111-02 Task 1 | 2 | FORM-01/FORM-03 | T-111-04/T-111-05 | Operator and inbound wrappers consume shared primitives while preserving stable filter form/control identity | component + LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes, extend | pending |
| 111-02-T2 | 111-02 Task 2 | 2 | FORM-02 | T-111-04/T-111-05/T-111-06 | Invalid filter params remain bounded and surface recovery text without widening tenant/data boundaries | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes, extend | pending |
| 111-03-T1 | 111-03 Task 1 | 2 | FORM-02/FORM-03 | T-111-07 | Preview assigns controls are labelled and read-only states are honest without changing Preview parsing behavior | LiveView/component | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | yes, extend | pending |
| 111-03-T2 | 111-03 Task 2 | 2 | FORM-02/FORM-03 | T-111-08/T-111-09 | Replay target controls are explicitly labelled/certified and selected state is not color-only | component | `cd mailglass_admin && mix test test/mailglass_admin/operator/replay_modal_test.exs test/mailglass_admin/inbound/replay_modal_test.exs --warnings-as-errors` | planned create | pending |
| 111-04-T1 | 111-04 Task 1 | 3 | FORM-01/FORM-02/FORM-03 | T-111-12 | Gallery specimens exercise real shared form primitives and migrated wrappers | browser structural | `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery|form"` | yes, extend | pending |
| 111-04-T2 | 111-04 Task 2 | 3 | FORM-01 | T-111-10 | Duplicate filter markup is rejected outside shared primitives | conformance | `cd mailglass_admin && ./scripts/check-conformance.sh` | yes, extend | pending |
| 111-04-T3 | 111-04 Task 3 | 3 | FORM-02/FORM-03 | T-111-11/T-111-12 | Browser proof covers labels, invalid state, disabled/read-only structure, Preview/replay controls, and focus persistence across ordinary patches | browser structural + phase gate | `cd mailglass_admin && npm run test:operator-browser` and `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser` | yes, extend | pending |

---

## Concrete Plan Coverage

- [x] Plan 111-01 Task 2 covers `mailglass_admin/test/mailglass_admin/components_test.exs` contract tests for `filter_field/1` and `filter_section/1`: visible `label for`, stable control `id`, help/error IDs, `aria-describedby`, `aria-invalid`, disabled state, native readonly where valid, and display-only read-only rendering for non-text controls.
- [x] Plan 111-02 Task 2 covers `mailglass_admin/test/mailglass_admin/operator_live_test.exs` and `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` invalid-param recovery assertions for normalized-away or defaulted filter params without widening tenant/data boundaries.
- [x] Plan 111-04 Task 3 covers `mailglass_admin/e2e/structural.spec.js` focus-persistence assertions across ordinary `phx-change` and `push_patch` filter updates, plus disabled/read-only/display-only structure checks across the existing structural matrix.
- [x] Plan 111-04 Task 2 covers `mailglass_admin/scripts/check-conformance.sh` with a deterministic FORM-01 duplicate-filter-markup guard that allows thin wrappers but rejects page-local label/control HEEx duplication.
- [x] Plan 111-03 Tasks 1 and 2 cover `mailglass_admin/test/mailglass_admin/preview_live_test.exs` plus replay modal tests to update or certify Preview assigns controls and replay target radios.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | FORM-01/FORM-02/FORM-03 | Phase scope is covered by component, LiveView, conformance, and Playwright structural assertions | All phase behaviors require automated verification before closeout |

---

## Validation Sign-Off

- [x] All planned tasks include automated verification.
- [x] Sampling continuity: no 3 consecutive task commits without an automated check.
- [x] Concrete plan/task mappings cover all missing validation references listed above.
- [x] No watch-mode flags are used in verification commands.
- [x] Feedback latency stays under 240 seconds for full gate runs.
- [x] `nyquist_compliant: true` because the final PLAN.md files reference these checks and all validation rows have concrete plan/task IDs.

**Approval:** planning-ready; execution results pending
