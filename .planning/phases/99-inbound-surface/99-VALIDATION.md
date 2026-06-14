---
phase: 99
slug: inbound-surface
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 99 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit + Playwright |
| **Config file** | `mailglass_admin/package.json`, `mailglass_admin/playwright.config.js`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` |
| **Estimated runtime** | ~180-600 seconds depending on browser setup |

---

## Sampling Rate

- **After every task commit:** Run the most local command for touched files:
  - inbound read model: `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/summary_test.exs --warnings-as-errors`
  - admin LiveView/components: `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors`
  - browser assertions: `cd mailglass_admin && npm run test:operator-browser`
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview`
- **Before `$gsd-verify-work`:** Run `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`
- **Max feedback latency:** 600 seconds for the browser gate; keep local ExUnit slices below 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 99-W0-01 | TBD | 0 | GROUP-02 | T-99-01 | Summary totals are tenant-scoped and not derived from capped list rows | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/summary_test.exs --warnings-as-errors` | No | pending |
| 99-W0-02 | TBD | 0 | GROUP-02 | T-99-02 | Admin uses optional gateway seam and still compiles without inbound | unit | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | Yes | pending |
| 99-W0-03 | TBD | 0 | GROUP-03 | T-99-03 | Raw evidence stays absent until capability-gated reveal | unit/browser | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | Yes | pending |
| 99-W0-04 | TBD | 0 | GROUP-03 | T-99-04 | Routing trace masks recipient actuals and does not reimplement matcher semantics | unit/browser | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | Yes | pending |
| 99-W0-05 | TBD | 0 | FLOW-02 | T-99-05 | Seeded browser path proves why-did-inbound-not-route flow end to end | browser | `cd mailglass_admin && npm run test:operator-browser` | Yes | pending |
| 99-W0-06 | TBD | 0 | A11Y-01 / RESP-01 | T-99-06 | Inbound layout has one h1, responsive grid, mobile back, focusable controls | browser | `cd mailglass_admin && npm run test:operator-browser` | Yes | pending |
| 99-W0-07 | TBD | 0 | RATCHET-03 | T-99-07 | Type/tracking conformance fails closed after cleanup | shell/CI | `bash mailglass_admin/scripts/check-conformance-advisory.sh` | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_inbound/test/mailglass_inbound/internal/operator/summary_test.exs` exists and fails before the summary read model lands.
- [ ] `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` includes overview, split-empty, copy-lock, and evidence/routing assertions before or with implementation.
- [ ] `mailglass_admin/e2e/structural.spec.js` includes inbound overview, one-h1, 390/768/1440 grid, and mobile-back assertions.
- [ ] `mailglass_admin/e2e/operator.spec.js` includes the why-did-inbound-not-route flow with seeded no-match routing trace and redacted evidence.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual rhythm of overview, RoutingTrace, and EvidenceCard in light/dark | GROUP-02 / GROUP-03 | Browser assertions prove structure; final visual quality still needs maintainer review or UI audit screenshots | Run the operator browser seed, inspect `/ops/mail/inbound?tenant_id=browser-tenant` at 390, 768, and 1440 in both themes, and compare against Phase 98 Operator rhythm. |
| No misleading overview interpretation for no-run records | GROUP-02 | Product copy and classification nuance may need maintainer judgement if no-run records are common | Confirm whether no-run records appear only in total or have an explicit non-outcome label before execution is accepted. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
