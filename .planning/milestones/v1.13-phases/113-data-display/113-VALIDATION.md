---
phase: 113
slug: data-display
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-19
---

# Phase 113 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Instantiated from `113-RESEARCH.md` § Validation Architecture (lines 491–523).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest (component/live); Playwright `@playwright/test` 1.59.1 (browser structural) |
| **Config file** | `mailglass_admin/playwright.config.cjs` (browser); ExUnit via `mailglass_admin/mix.exs` test setup |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && bash scripts/check-conformance.sh && npm run test:operator-browser -- --grep "responsive\|stat_card\|status\|overflow\|Data"` |
| **Estimated runtime** | ~120 seconds (ExUnit quick ~15s; full suite incl. verify.preview + conformance + browser grep ~90–120s) |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors`
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview && bash scripts/check-conformance.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (incl. `npm run test:operator-browser` Phase 113 greps)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-----------|--------|
| 113-01-01 | 01 | 1 | DATA-03 | — | N/A | conformance/structural | `cd mailglass_admin && bash scripts/check-conformance.sh && mix verify.preview` | ✅ extend | ⬜ pending |
| 113-01-02 | 01 | 1 | DATA-03 | — | N/A | unit (component) | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | ✅ add cases | ⬜ pending |
| 113-01-03 | 01 | 1 | DATA-02 | — | N/A | unit (component) | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 113-02-01 | 02 | 2 | DATA-01, DATA-05 | T-113-SC | XSS: no `raw/1` on long values/title; HEEx escaping preserved | unit (live) + browser | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors && npm run test:operator-browser -- --grep "responsive\|overflow"` | ✅ extend | ⬜ pending |
| 113-02-02 | 02 | 2 | DATA-03 | T-113-SC | permission-denied template distinct from no-data (no info disclosure) | unit (live) | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ add cases | ⬜ pending |
| 113-02-03 | 02 | 2 | DATA-02 | T-113-SC | tenant-scoped read-model assigns only; `mask_recipient/1` preserved | unit (component) + conformance | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && bash scripts/check-conformance.sh` | ✅ extend | ⬜ pending |
| 113-03-01 | 03 | 2 | DATA-01, DATA-05 | T-113-SC | XSS: no `raw/1` on long values/title; synchronous render (no `assign_async`) | unit (live) + browser | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors && npm run test:operator-browser -- --grep "responsive\|overflow"` | ✅ extend | ⬜ pending |
| 113-03-02 | 03 | 2 | DATA-03 | T-113-SC | stale-data render-time honest, no polling; permission-denied distinct | unit (live) | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | ✅ add cases | ⬜ pending |
| 113-03-03 | 03 | 2 | DATA-02 | T-113-SC | tenant-scoped read-model assigns only; `mask_recipient/1` preserved | unit (component) + conformance | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && bash scripts/check-conformance.sh` | ✅ extend | ⬜ pending |
| 113-04-01 | 04 | 3 | DATA-03, DATA-04, DATA-05 | — | N/A | gallery + browser structural | `cd mailglass_admin && npm run test:operator-browser -- --grep "stat_card\|status\|Data\|overflow"` | ✅ extend | ⬜ pending |
| 113-04-02 | 04 | 3 | DATA-01, DATA-04, DATA-05 | — | legacy testids migrated, not orphaned (suite stays green) | browser structural | `cd mailglass_admin && npm run test:operator-browser -- --grep "responsive\|overflow\|status\|Data"` | ✅ extend | ⬜ pending |
| 113-04-03 | 04 | 3 | DATA-02, DATA-04 | — | committed bit-clean `priv/static/app.css` (`git diff --exit-code`) | conformance + verify.preview | `cd mailglass_admin && bash scripts/check-conformance.sh && mix verify.preview` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Phase 113 has **no separate Wave 0** — the four RESEARCH § Wave 0 Gaps are folded directly into plan tasks (every target is a MODIFY of an existing module/test with a strong in-repo analog, per `113-PATTERNS.md`). Each gap maps to a real task above:

- [ ] `operator-deliveries-table/-cards` + `inbound-records-table/-cards` assertions → tasks 113-02-01 (live), 113-03-01 (live), 113-04-02 (structural)
- [ ] Data-state tests/specimens (no-data / unavailable / permission-denied / stale) → tasks 113-01-02 (component), 113-02-02, 113-03-02 (live), 113-04-01 (gallery/browser)
- [ ] Playwright long-value specimens/assertions (UUIDs, tenant/provider ids, module/function names, URLs, non-ASCII, timestamps) → tasks 113-04-01, 113-04-02
- [ ] Extend `check-conformance.sh` with Phase 113 drift gates (`STATUS-BADGE`/`DATA-STATE`) — only after selectors/component names exist → task 113-04-03

*Existing ExUnit + Playwright infrastructure covers all phase requirements; no framework install needed (zero-Node asset boundary; `@axe-core/playwright` deliberately NOT installed — Phase 116 scope).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification (structural, not pixel-diff). The 5-second "operator-under-stress" scannability of severity (DATA-04) is proxied by structural icon+label+color assertions, not subjective human review (D-08, repo-local proof only).*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (12/12 tasks carry an automated `<verify>`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (folded into plan tasks; mapped above)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-19
