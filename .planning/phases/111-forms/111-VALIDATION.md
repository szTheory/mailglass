---
phase: 111
slug: forms
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 111-W0-01 | TBD | 0 | FORM-01 | T-111-01 | Duplicate filter markup is rejected outside shared primitives | conformance | `cd mailglass_admin && ./scripts/check-conformance.sh` | yes, extend | pending |
| 111-W0-02 | TBD | 0 | FORM-02 | T-111-02 | Labels, help text, error text, and ARIA state are source-asserted | component | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | yes, extend | pending |
| 111-W0-03 | TBD | 0 | FORM-02 | T-111-03 | Invalid filter params remain bounded and surface recovery text | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes, extend | pending |
| 111-W0-04 | TBD | 0 | FORM-03 | T-111-04 | Disabled and read-only/display-only states are programmatically distinct | component + browser structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && npm run test:operator-browser` | yes, extend | pending |
| 111-W0-05 | TBD | 0 | FORM-03 | T-111-05 | Focus stays on the same control across ordinary LiveView filter patches | browser structural | `cd mailglass_admin && npm run test:operator-browser` | yes, extend | pending |
| 111-W0-06 | TBD | 0 | FORM-02/FORM-03 | T-111-06 | Preview assigns controls and replay radios are updated or explicitly certified | LiveView/component + browser structural | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors && npm run test:operator-browser` | yes, extend | pending |

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/components_test.exs` includes contract tests for `filter_field/1` and `filter_section/1`: visible `label for`, stable control `id`, help/error IDs, `aria-describedby`, `aria-invalid`, disabled state, native readonly where valid, and display-only read-only rendering for non-text controls.
- [ ] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` and `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` include invalid-param recovery assertions for normalized-away or defaulted filter params without widening tenant/data boundaries.
- [ ] `mailglass_admin/e2e/structural.spec.js` includes focus-persistence assertions across ordinary `phx-change` and `push_patch` filter updates, plus disabled/read-only/display-only structure checks across the existing structural matrix.
- [ ] `mailglass_admin/scripts/check-conformance.sh` includes a deterministic FORM-01 duplicate-filter-markup guard that allows thin wrappers but rejects page-local label/control HEEx duplication.
- [ ] `mailglass_admin/test/mailglass_admin/preview_live_test.exs` and replay-related tests update or certify Preview assigns controls and replay target radios.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | FORM-01/FORM-02/FORM-03 | Phase scope is covered by component, LiveView, conformance, and Playwright structural assertions | All phase behaviors require automated verification before closeout |

---

## Validation Sign-Off

- [ ] All planned tasks include automated verification or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no 3 consecutive task commits without an automated check.
- [ ] Wave 0 covers all missing references listed above.
- [ ] No watch-mode flags are used in verification commands.
- [ ] Feedback latency stays under 240 seconds for full gate runs.
- [ ] Set `nyquist_compliant: true` after the final PLAN.md files reference these checks and all Wave 0 rows have concrete plan/task IDs.

**Approval:** pending
