---
phase: 99
slug: inbound-surface
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
updated: 2026-06-14
---

# Phase 99 - Validation Strategy

> Final plan-set validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit + Playwright |
| **Config file** | `mailglass_admin/package.json`, `mailglass_admin/playwright.config.cjs`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` |
| **Estimated runtime** | ~180-600 seconds depending on browser setup |

---

## Sampling Rate

- **After every task commit:** Run the most local command for touched files:
  - inbound read model: `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/summary_test.exs --warnings-as-errors`
  - admin LiveView/components: `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors`
  - admin component contracts: `cd mailglass_admin && mix test test/mailglass_admin/inbound/components_test.exs --warnings-as-errors`
  - browser assertions: first run `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors`, then the relevant `npx playwright test --config=playwright.config.cjs --workers=1 ...` command
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview`
- **Before `$gsd-verify-work`:** Run `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`
- **Max feedback latency:** 600 seconds for the browser gate; keep local ExUnit slices below 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 99-01-01 | 99-01 | 1 | GROUP-02 | T-99-01 / T-99-04 | Summary totals are tenant-scoped, exact past list caps, and ignore selected outcome narrowing | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/summary_test.exs --warnings-as-errors` | planned |
| 99-01-02 | 99-01 | 1 | GROUP-02 | T-99-05 | Admin uses optional gateway seam and still compiles without inbound | compile | `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` and `cd mailglass_admin && mix compile --warnings-as-errors` | planned |
| 99-02-01 | 99-02 | 2 | GROUP-02 | T-99-06 / T-99-06A | Overview renders tenant-scoped summary without addresses, subjects, headers, or raw payload, and `/ops/mail/inbound?tenant_id=...` returns the exact zero summary when `gateway_available?/0` is false before any summary `apply/3` call | LiveView unit + no-optional compile | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` and `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` | planned |
| 99-02-02 | 99-02 | 2 | GROUP-02 | T-99-07 / T-99-08 | Responsive IA, mobile filters, and mobile back stay on URL state and existing routes | LiveView unit | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | planned |
| 99-02-03 | 99-02 | 2 | GROUP-02 | T-99-10 | Empty-state classification is no-tenant first, active-filtered empty second, and truly-empty only for an unfiltered tenant with no records/history | LiveView unit | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | planned |
| 99-03-01 | 99-03 | 1 | GROUP-03 | T-99-11 / T-99-12 | Routing trace masks recipient actuals and does not reimplement matcher semantics | component unit | `cd mailglass_admin && mix test test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` | planned |
| 99-03-02 | 99-03 | 1 | GROUP-03 | T-99-13 / T-99-14 | Raw evidence stays absent until capability-gated reveal | component unit | `cd mailglass_admin && mix test test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` | planned |
| 99-03-03 | 99-03 | 1 | GROUP-03 | T-99-15 | Filter labels and replay modal are token/copy clean with safe bounded raw payload display | component unit | `cd mailglass_admin && mix test test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` | planned |
| 99-04-01 | 99-04 | 3 | GROUP-02 / GROUP-03 | T-99-17 / T-99-19 | Single browser seed reaches all inbound states without adding runtime routes | ExUnit | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | planned |
| 99-04-02 | 99-04 | 3 | GROUP-02 / GROUP-03 | T-99-16 / T-99-18 | Why-did-inbound-not-route flow is browser-proven after fast LiveView/component precheck | ExUnit + browser | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors`; `cd mailglass_admin && mix mailglass_admin.assets.build && npx playwright test --config=playwright.config.cjs --workers=1 e2e/operator.spec.js` | planned |
| 99-04-03 | 99-04 | 3 | GROUP-02 / GROUP-03 | T-99-16 / T-99-20 | Responsive, a11y, redaction, detail-error, filtered-empty, truly-empty, and no-tenant states are structurally browser-covered after fast precheck | ExUnit + browser | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors`; `cd mailglass_admin && mix mailglass_admin.assets.build && npx playwright test --config=playwright.config.cjs --workers=1 e2e/operator.spec.js e2e/structural.spec.js` | planned |
| 99-05-01 | 99-05 | 4 | GROUP-02 / GROUP-03 | T-99-24 | Preview cleanup is limited to the D-14 text-token replacement | source gate | `bash -lc "! rg -n 'text-(lg|xl|2xl|3xl|4xl|5xl)\\b' mailglass_admin/lib/mailglass_admin/preview_live.ex"` | planned |
| 99-05-02 | 99-05 | 4 | GROUP-02 / GROUP-03 | T-99-21 | Type/tracking conformance fails closed after cleanup | shell/CI | `bash mailglass_admin/scripts/check-conformance-advisory.sh` | planned |
| 99-05-03 | 99-05 | 4 | GROUP-02 / GROUP-03 | T-99-22 | Static bundle and final admin/browser gates are clean, with focused ExUnit precheck before browser work | shell + ExUnit + browser | `cd mailglass_admin && mix mailglass_admin.assets.build`; `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors`; `cd mailglass_admin && mix verify.preview`; `cd mailglass_admin && npm run test:operator-browser`; `cd mailglass_admin && git diff --exit-code priv/static/` | planned |

*Status: planned / green / red / flaky*

---

## Wave 0 Requirements

- [x] `99-01` requires `mailglass_inbound/test/mailglass_inbound/internal/operator/summary_test.exs` before or with the summary read model.
- [x] `99-02` requires `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` for overview, responsive IA, split-empty, impossible-filtered-empty, copy-lock, and detail-error assertions.
- [x] `99-03` requires `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` for routing trace, evidence reveal, filters, and replay modal assertions.
- [x] `99-04` preserves browser gates for browser-only behavior and adds focused ExUnit/component prechecks before Playwright.
- [x] `99-05` runs conformance/source checks and focused ExUnit prechecks before the final preview/browser gates.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual rhythm of overview, RoutingTrace, and EvidenceCard in light/dark | GROUP-02 / GROUP-03 | Browser assertions prove structure; final visual quality still needs maintainer review or UI audit screenshots | Run the operator browser seed, inspect `/ops/mail/inbound?tenant_id=browser-tenant` at 390, 768, and 1440 in both themes, and compare against Phase 98 Operator rhythm. |
| No misleading overview interpretation for no-run records | GROUP-02 | Product copy and classification nuance may need maintainer judgement if no-run records are common | Confirm whether no-run records appear only in total or have an explicit non-outcome label before execution is accepted. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 600s, with fast ExUnit/component prechecks before browser gates where practical
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned 2026-06-14
