---
phase: 98
slug: operator-deliveries-surface
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
audited_at: 2026-06-14T17:56:23-04:00
auditor: codex-inline
---

# Phase 98 - Validation Strategy

> Completed Nyquist validation contract for the operator deliveries surface.
> The original draft W0 items were rechecked after phase execution; all phase
> requirements now have automated verification.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (`@playwright/test`, `mailglass_admin/e2e/`) |
| **Config file** | `mailglass_admin/mix.exs`; `mailglass_admin/playwright.config.cjs`; admin test support under `mailglass_admin/test/support/` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/assets_test.exs test/mailglass_admin/router_test.exs --warnings-as-errors` |
| **Conformance gate** | `cd mailglass_admin && bash scripts/check-conformance.sh` |
| **Bundle gate** | `cd mailglass_admin && mix mailglass_admin.assets.build && git diff --exit-code priv/static/ && git diff --quiet docs/ui-baseline-scores.json test/mailglass_admin/ratchet_baseline_test.exs` |
| **Browser gate** | `cd mailglass_admin && mix compile --force --warnings-as-errors && npx playwright test --config=playwright.config.cjs --workers=1 e2e/operator.spec.js e2e/structural.spec.js` |
| **Estimated runtime** | ~20s for focused ExUnit + conformance + bundle; ~15s for browser gate on this machine |

---

## Sampling Rate

- **After every task commit:** Run the quick ExUnit command plus `bash scripts/check-conformance.sh`.
- **After every plan wave:** Run quick ExUnit, conformance, bundle gate, and the Playwright browser gate with `--workers=1`.
- **Before `$gsd-verify-work`:** Run all commands in Test Infrastructure and keep `priv/static/` plus frozen UI baseline files clean.
- **Max feedback latency:** ~60 seconds for the focused phase validation lane.

---

## Requirement Verification Map

| Req / Decision | Phase Evidence | Automated Command / Assertion | Test Files | Status |
|----------------|----------------|-------------------------------|------------|--------|
| GROUP-01 | Operator groups use token spacing/elevation and token-clean in-pane labels. | `check-conformance.sh`; operator source assertion rejects `tracking-[`; overview/browser group tests assert operator overview/list/detail cells. | `test/mailglass_admin/operator_live_test.exs`; `e2e/operator.spec.js`; `e2e/structural.spec.js` | GREEN |
| PAGE-01 | Overview landing and deliveries master-detail view both exist and are browser-covered. | `operator.spec.js` asserts `operator-overview`, `operator-overview-health`, `operator-overview-nav`; mobile orientation/list/detail ordering is asserted. | `e2e/operator.spec.js`; `test/mailglass_admin/operator_live_test.exs` | GREEN |
| PAGE-02 | Error, empty, suppressed, and selected-detail states are reachable and coherent. | `structural.spec.js` reaches `operator-detail-error`, `operator-empty-filtered`, `operator-empty-truly`, and suppressed badge fallback by URL. | `e2e/structural.spec.js`; `test/mailglass_admin/operator_live_test.exs` | GREEN |
| RESP-01 | 390/768/1440 layout contract is verified against computed styles. | Playwright checks full-width mobile list, hidden mobile master after selection, `operator-detail-back`, and grid column ratios at 768/1440. | `e2e/operator.spec.js`; `e2e/structural.spec.js` | GREEN |
| FLOW-01 | One browser seed reaches happy, detail-error, filtered-empty, truly-empty, active suppression, and suppressed-row states. | Seed ordering ExUnit locks `browser-selected` first and `browser-suppressed` last; structural URL matrix reaches each state. | `test/support/operator_fixtures.ex`; `test/mailglass_admin/operator_live_test.exs`; `e2e/structural.spec.js` | GREEN |
| FLOW-02 | Failed-delivery audit and replay flows pass end-to-end. | `operator.spec.js` asserts index-pinned failed SendGrid row details and exact/ambiguous/noop replay flows. | `e2e/operator.spec.js` | GREEN |
| A11Y-01 | ARIA, focus, one-h1, touch target, and no-raise robustness are covered. | Structural tests assert `aria-selected`, `aria-current`, one h1, focus outline, and >=44px controls; ExUnit covers CR nil guards. | `e2e/structural.spec.js`; `test/mailglass_admin/operator_live_test.exs` | GREEN |
| A11Y-02 | Contrast/token discipline is covered without adding new LLM baseline cells. | Accent allowlist structural tests pass; operator tracking-clean assertion passes; bundle and frozen baseline diffs are clean. | `e2e/structural.spec.js`; `test/mailglass_admin/operator_live_test.exs`; `docs/ui-baseline-scores.json` unchanged | GREEN |
| D-01 | Overview and deliveries surfaces are both preserved. | Overview testids and delivery master-detail testids are asserted from ExUnit/browser coverage. | `test/mailglass_admin/operator_live_test.exs`; `e2e/operator.spec.js` | GREEN |
| D-02 | Master-detail grid uses 40/60 at 768 and 33/67 at 1440. | `grid-template-columns` is parsed and ratio-checked in Playwright; stale `minmax(22rem,28rem)` is absent. | `e2e/structural.spec.js`; `lib/mailglass_admin/operator_live.ex` | GREEN |
| D-03 | Arbitrary tracking is removed from the operator surface. | Operator-scoped ExUnit source scan asserts zero non-comment `tracking-[` hits across operator files. | `test/mailglass_admin/operator_live_test.exs` | GREEN |
| D-04 | Seed ordering and replay row indices stay stable. | ExUnit locks first/last seed ordering; operator browser specs keep failed SendGrid row at index 4 and replay rows stable. | `test/mailglass_admin/operator_live_test.exs`; `e2e/operator.spec.js` | GREEN |
| D-05 | CR-01/02/03 nil/novel-shape paths do not raise. | ExUnit renders novel-shape suppression fallback, `:suppressed` status fallback, and nil selected-delivery event handlers. | `test/mailglass_admin/operator_live_test.exs` | GREEN |
| D-06 | Mobile filters use stateless `JS.toggle`, not a server-side toggle event. | Source contains `JS.toggle(to: "#operator-filter-panel")`; browser touch-target test covers `operator-filters-toggle`; no `toggle_filters` handler exists. | `lib/mailglass_admin/operator_live.ex`; `e2e/structural.spec.js` | GREEN |
| D-07 | Flat-elevation/token conformance remains clean. | `scripts/check-conformance.sh` passes; operator group cards keep token classes and no operator-surface arbitrary tracking. | `lib/mailglass_admin/operator*.ex`; `scripts/check-conformance.sh` | GREEN |
| D-08 | Group testids and rebuilt CSS bundle are committed and clean. | `operator-filters`, overview, list, detail, empty, and error testids are asserted; bundle gate leaves `priv/static/` clean. | `e2e/operator.spec.js`; `e2e/structural.spec.js`; `priv/static/app.css` | GREEN |

*Status legend: GREEN = covered and passing in the current audit; PARTIAL = test exists but is incomplete or failing; MISSING = no automated coverage found.*

---

## Original W0 Gap Audit

| Draft W0 Item | Current Coverage | Status |
|---------------|------------------|--------|
| Per-state Playwright matrix for detail-error, filtered-empty, truly-empty, suppressed-row | `e2e/structural.spec.js` operator state coverage block | GREEN |
| Group container `data-testid="operator-{group}"` assertions | Overview, filters, master-detail, list, detail, empty, and error testids are in ExUnit/browser coverage | GREEN |
| DeliveriesList filtered-empty vs truly-empty ExUnit branch tests | `describe "filters_active? empty states"` | GREEN |
| CR-01/02/03 unit coverage | `describe "CR-01/02/03 nil-guards"` | GREEN |
| `:suppressed` seed row appended last | `describe "browser seed ordering"` and `operator_fixtures.ex` `hours_ago(8)` row | GREEN |
| Advisory tracking gate decision | Global advisory flip deferred to Phase 99; Phase 98 has operator-scoped ExUnit regression coverage | GREEN |
| 1440 breakpoint decision | Implemented as `min-[1440px]:!grid-cols-[33%_67%]`; computed ratio checked by Playwright | GREEN |
| Bundle-clean gate | `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` passes | GREEN |

Existing infrastructure covers all phase requirements. No new tests were generated during this validation audit because no current gaps remained.

---

## Manual-Only Verifications

None. Phase 98 has no blocking manual-only validation items. The prior subjective visual-rhythm note is covered by the existing structural/browser/conformance lane and the frozen UI baseline remains unchanged.

---

## Validation Audit 2026-06-14

| Metric | Count |
|--------|-------|
| Requirements audited | 8 |
| Decisions / draft W0 items audited | 16 |
| Current gaps found | 0 |
| New tests generated by this audit | 0 |
| Escalated to manual-only | 0 |

Fresh verification from this audit:

| Check | Result |
|-------|--------|
| `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/assets_test.exs test/mailglass_admin/router_test.exs --warnings-as-errors` | PASS: 41 tests, 0 failures |
| `cd mailglass_admin && bash scripts/check-conformance.sh` | PASS: `OK: design-system conformance clean.` |
| `cd mailglass_admin && mix mailglass_admin.assets.build && git diff --exit-code priv/static/ && git diff --quiet docs/ui-baseline-scores.json test/mailglass_admin/ratchet_baseline_test.exs` | PASS: bundle clean and frozen baseline unchanged |
| `cd mailglass_admin && mix compile --force --warnings-as-errors && npx playwright test --config=playwright.config.cjs --workers=1 e2e/operator.spec.js e2e/structural.spec.js` | PASS: 38 tests, 0 failures |

---

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity maintained; no plan wave depends on manual-only verification.
- [x] Draft W0 references are covered by existing committed tests.
- [x] No watch-mode flags.
- [x] Feedback latency under 60s on the focused phase validation lane.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-14
