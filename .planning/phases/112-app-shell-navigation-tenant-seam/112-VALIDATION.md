---
phase: 112
slug: app-shell-navigation-tenant-seam
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Full suite command** | `mix verify.preview && cd mailglass_admin && npm run test:operator-browser -- --grep "Phase 112"` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command for files touched by the task.
- **After every plan wave:** Run `mix verify.preview`.
- **Before `/gsd:verify-work`:** Run `mix verify.preview` and the Phase 112 Playwright browser proof.
- **Max feedback latency:** 180 seconds for focused checks; full browser proof may exceed this when the dev server starts cold.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 1 | SHELL-01, SHELL-02 | T-112-tenant-listing | Tenant discovery uses a core read model and `Mailglass.Tenancy.scope/2`; admin does not query raw Repo. | unit/integration | `mix test test/mailglass/operator mailglass_admin/test/mailglass_admin/operator_live_test.exs` | yes | pending |
| 112-01-02 | 01 | 1 | SHELL-01, SHELL-03 | T-112-invisible-scope | Sole tenant auto-select canonicalizes to URL `tenant_id`; switcher preserves scoped URLs. | LiveView | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | yes | pending |
| 112-02-01 | 02 | 1 | SHELL-04 | T-112-theme-cookie | Explicit light/dark theme is host-scoped and server-rendered; system emits no `data-theme`. | LiveView/browser | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs && cd mailglass_admin && npm run test:operator-browser -- --grep "theme"` | yes | pending |
| 112-03-01 | 03 | 2 | SHELL-05 | T-112-active-nav | Active nav has visible non-color cues at both levels and keeps `aria-current` semantics. | component/browser | `mix test mailglass_admin/test/mailglass_admin/components_test.exs mailglass_admin/test/mailglass_admin/operator/shell_test.exs && cd mailglass_admin && npm run test:operator-browser -- --grep "nav"` | yes | pending |
| 112-04-01 | 04 | 2 | SHELL-06 | T-112-pagination-count | Counts and page boundaries come from read models, not truncated list length. | unit/LiveView | `mix test test/mailglass/operator mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | yes | pending |
| 112-05-01 | 05 | 3 | SHELL-01..06 | T-112-regression | Final shell/browser proof covers tenant, theme, nav, pagination, and scope persistence together. | full gate | `mix verify.preview && cd mailglass_admin && npm run test:operator-browser -- --grep "Phase 112"` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/operator/*tenant*_test.exs` or adjacent operator read-model tests - scoped tenant listing projection.
- [ ] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - sole-tenant auto-select, multi-tenant switcher, clear-filters tenant preservation, theme set preserving tenant, detail/back tenant preservation.
- [ ] `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - inbound tenant persistence and pagination metadata assertions.
- [ ] `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - shell path builders preserve `tenant_id` and theme choice.
- [ ] `mailglass_admin/e2e/structural.spec.js` - Phase 112 browser proof for no-FOUC theme root behavior and non-color active navigation cues.
- [ ] `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs` - paginated metadata/count tests if inbound pagination is implemented in the inbound read model.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | SHELL-01..06 | Phase 112 shell behavior should be covered by ExUnit, LiveViewTest, and Playwright structural assertions. | N/A |

---

## Validation Sign-Off

- [x] All planned task areas have automated verification targets.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test references.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
