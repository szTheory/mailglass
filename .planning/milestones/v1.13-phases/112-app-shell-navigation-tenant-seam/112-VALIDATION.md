---
phase: 112
slug: app-shell-navigation-tenant-seam
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
---

# Phase 112 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest + Playwright browser structural tests |
| **Config file** | `mix.exs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser -- --grep "Phase 112"` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command for files touched by the task.
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview`.
- **Before `/gsd:verify-work`:** Run `cd mailglass_admin && mix verify.preview`, conformance, and the Phase 112 Playwright browser proof.
- **Max feedback latency:** 180 seconds for focused checks; full browser proof may exceed this when the dev server starts cold.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 1 | SHELL-01, SHELL-02 | T-112-01 | Tenant discovery tests prove actor-context scoping and inbound-only tenant inclusion through the optional gateway. | unit/integration | `mix test test/mailglass/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-01-02 | 01 | 1 | SHELL-01, SHELL-02 | T-112-01 | Core outbound projection is scoped; admin shell selector seam unions optional inbound ids without direct `MailglassInbound.*` references. | unit/integration | `mix test test/mailglass/operator/tenants_test.exs test/mailglass/operator/deliveries_test.exs mailglass_admin/test/mailglass_admin/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-02-01 | 02 | 2 | SHELL-01, SHELL-02, SHELL-03 | T-112-03, T-112-04, T-112-05 | Tenant auto-select, switcher, and scope persistence are captured in LiveView and shell path tests. | LiveView | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-02-02 | 02 | 2 | SHELL-01, SHELL-02, SHELL-03 | T-112-03, T-112-04, T-112-05 | Operator and inbound surfaces consume `MailglassAdmin.Operator.Tenants.list_tenants/2` and preserve tenant URL state. | LiveView | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-03-01 | 03 | 3 | SHELL-03, SHELL-04 | T-112-06, T-112-07, T-112-08 | Explicit theme cookie tests prove first-paint light/dark, system deletion, and mount-path cookie scoping. | ExUnit | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/router_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-03-02 | 03 | 3 | SHELL-04 | T-112-06, T-112-07, T-112-08 | Root layout emits explicit light/dark only; invalid/system cookie values produce no concrete root theme. | ExUnit | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/router_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-03-03 | 03 | 3 | SHELL-03, SHELL-04 | T-112-08 | Shell theme paths preserve tenant/filter/surface return state through the persistence seam. | ExUnit | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-04-01 | 04 | 4 | SHELL-05 | T-112-09, T-112-10 | Component/shell tests prove active nav has non-color structural cues and `aria-current`. | component | `mix test mailglass_admin/test/mailglass_admin/components_test.exs mailglass_admin/test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-04-02 | 04 | 4 | SHELL-05 | T-112-09, T-112-10 | Shared nav primitives and compiled CSS keep active cue, focus ring, and target-size contracts. | component/conformance | `mix test mailglass_admin/test/mailglass_admin/components_test.exs mailglass_admin/test/mailglass_admin/operator/shell_test.exs --warnings-as-errors && cd mailglass_admin && ./scripts/check-conformance.sh && git diff --exit-code mailglass_admin/priv/static/app.css` | yes | green - 2026-06-19; conformance passed |
| 112-05-01 | 05 | 5 | SHELL-06 | T-112-11, T-112-12, T-112-13 | Read-model tests prove total counts and page boundaries come from tenant-scoped queries, not capped entries. | unit | `mix test test/mailglass/operator/deliveries_test.exs mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-05-02 | 05 | 5 | SHELL-06 | T-112-11, T-112-12, T-112-13 | Delivery and inbound page APIs normalize page params, cap page size, and preserve existing list API compatibility. | unit | `mix test test/mailglass/operator/deliveries_test.exs mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs --warnings-as-errors` | yes | green - 2026-06-19; covered by package full gate |
| 112-06-01 | 06 | 6 | SHELL-01..06 | T-112-14, T-112-15, T-112-16 | Integrated browser proof covers tenant, theme, nav, pagination, and scope persistence after fast LiveView smoke checks. | LiveView/browser | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors && cd mailglass_admin && npm run test:operator-browser -- --grep "Phase 112"` | yes | green - 2026-06-19; browser proof passed |
| 112-06-02 | 06 | 6 | SHELL-06 | T-112-16 | UI pagination consumes read-model metadata and conformance rejects tenant/theme/pagination regressions. | LiveView/conformance | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors && cd mailglass_admin && ./scripts/check-conformance.sh` | yes | green - 2026-06-19; conformance passed |
| 112-06-03 | 06 | 6 | SHELL-01..06 | T-112-regression | Phase validation evidence records green full-gate proof for all requirements. | full gate | `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser -- --grep "Phase 112"` | yes | green - 2026-06-19; full gate passed |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [x] `test/mailglass/operator/*tenant*_test.exs` or adjacent operator read-model tests - scoped tenant listing projection.
- [x] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - sole-tenant auto-select, multi-tenant switcher, clear-filters tenant preservation, theme set preserving tenant, detail/back tenant preservation.
- [x] `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - inbound tenant persistence and pagination metadata assertions.
- [x] `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - shell path builders preserve `tenant_id` and theme choice.
- [x] `mailglass_admin/e2e/structural.spec.js` - Phase 112 browser proof for no-FOUC theme root behavior and non-color active navigation cues.
- [x] `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs` - paginated metadata/count tests if inbound pagination is implemented in the inbound read model.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | SHELL-01..06 | Phase 112 shell behavior should be covered by ExUnit, LiveViewTest, and Playwright structural assertions. | N/A |

---

## Validation Sign-Off

- [x] All planned task areas have automated verification targets.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 coverage maps every missing test reference and is green.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** green - automated evidence recorded 2026-06-19

## Execution Evidence

- 2026-06-19: `cd mailglass_admin && mix verify.preview` passed: 348 tests, 0 failures, 1 excluded.
- 2026-06-19: `cd mailglass_admin && ./scripts/check-conformance.sh` passed: `OK: design-system conformance clean.`
- 2026-06-19: `cd mailglass_admin && npm run test:operator-browser -- --grep "Phase 112"` passed: 2 Playwright tests.
- 2026-06-19: Root-level `mix verify.preview` was attempted first and failed because the repository root does not define that Mix task; the package-local command above is the runnable Phase 112 gate.
