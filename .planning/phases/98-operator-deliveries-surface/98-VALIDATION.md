---
phase: 98
slug: operator-deliveries-surface
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 98 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `98-RESEARCH.md` "Validation Architecture". The harness is e2e via ONE fixed
> seed (`OperatorFixtures.seed_browser_scenario!/0`) with URL-param-driven state nav. No new
> LLM-score baseline cells (the 36-cell baseline is frozen).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (`@playwright/test`, `mailglass_admin/e2e/`) |
| **Config file** | `mailglass_admin/mix.exs` aliases (`verify.preview`, `verify.support_contract.admin`); Playwright config in `e2e/` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` |
| **Conformance gate** | `bash mailglass_admin/scripts/check-conformance.sh` (hard) + `check-conformance-advisory.sh` (advisory, currently `exit 0`) |
| **Full suite command** | `cd mailglass_admin && mix verify.preview` (compile → test → assets.build → `git diff --exit-code priv/static/`) + Playwright `e2e/operator.spec.js e2e/structural.spec.js` |
| **Estimated runtime** | ~90s ExUnit + conformance; Playwright lane ~2–3 min |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` + `bash scripts/check-conformance.sh`
- **After every plan wave:** Run `mix verify.support_contract.admin` + Playwright `e2e/operator.spec.js e2e/structural.spec.js`
- **Before `/gsd:verify-work`:** `mix verify.preview` green (bundle committed, `git diff --exit-code priv/static/`) + full Playwright lane green
- **Max feedback latency:** ~120 seconds (ExUnit + conformance)

---

## Per-Task Verification Map

> Concrete deterministic method per requirement / decision. Task IDs finalize in PLAN.md; this maps
> each REQ-ID + D-0x to its validation type so the planner can attach `<automated>` verify to tasks.

| Req / Decision | Test Type | Automated Command / Assertion | File Exists |
|----------------|-----------|-------------------------------|-------------|
| GROUP-01 | grep conformance + ExUnit structural | `check-conformance.sh` GAP-GATE clean; ExUnit assert group `data-testid="operator-*"` cells carry `bg-base-200 border border-base-300 rounded-box`, no `shadow` | ✅ |
| PAGE-01 | Playwright structural | `operator.spec.js` overview has `operator-overview-health` + `operator-overview-nav`; deliveries two-pane master-detail | ✅ |
| PAGE-02 | Playwright structural (per-state URL) | `structural.spec.js` reach `operator-detail-error` (bad `delivery_id`), `operator-empty-detail` (no selection), filtered-empty (non-matching filter) | ❌ W0 |
| RESP-01 | Playwright structural @ 390/768/1440 | `setViewportSize`; 390 list 100% + reveal-with-back; 768/1440 two-pane via computed `grid-template-columns` on `operator-master-detail` | ❌ W0 |
| FLOW-01 | ExUnit (seed) + Playwright (reach) | ExUnit assert seed inserts new `:suppressed`/suppression rows; Playwright navigate each State Coverage URL, assert expected `data-testid` | ❌ W0 |
| FLOW-02 | Playwright behavioural | existing replay flows + select→timeline→suppression chain; extend with failed-sendgrid row inspection | ✅ (extend) |
| A11Y-01 | Playwright structural | `structural.spec.js` FACT 1 (aria-selected/current), FACT 2 (≥44px), FACT 5 (focus outline >0); one-h1 via `getByRole("heading",{level:1})` count | ✅ (extend) |
| A11Y-02 | Playwright computed-style + existing LLM-score | `structural.spec.js` FACT 6 accent allowlist; dark `border-input` mapping asserted via computed `border-color` (no new baseline cell) | ✅ (extend) |
| D-01 | Playwright structural | overview testids + deliveries testids both visible | ✅ |
| D-02 | Playwright computed-style + ExUnit grep | `operator-master-detail` computed `grid-template-columns` = 40/60 @768 and 33/67 @≥1440; ExUnit assert markup has NO `minmax(22rem,28rem)` | ❌ W0 |
| D-03 | grep conformance + ExUnit | `tracking-\[` returns 0 in operator markup; ExUnit assert deliveries-list `h2` carries `text-label uppercase font-bold text-secondary` | ❌ W0 |
| D-04 | ExUnit + Playwright | ExUnit row count/ordering snapshot; all 5 existing `deliveryRow` index tests still green | ✅ (regression) |
| D-05 | ExUnit unit | CR-01 `body_copy(%{})` returns fallback (no raise); CR-02 render with `selected_delivery: nil` no raise in both handlers; CR-03 `status_badge` accepts `:suppressed`, renders `badge-outline` | ❌ W0 |
| D-06 | Playwright structural + grep | 390 "Filters" button visible, panel `hidden` initial, toggles on click; 768 panel visible + button `md:hidden`; grep `JS.toggle` present, NO new `handle_event("toggle_filters"…)` | ❌ W0 |
| D-07 | grep conformance + ExUnit | GAP-GATE clean; group containers have no `shadow` (except replay_modal) | ✅ |
| D-08 | Playwright + bundle gate | `getByTestId` per new group cell; `mix verify.preview` `git diff --exit-code priv/static/` green | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New Playwright assertions in `e2e/structural.spec.js` for the per-state matrix (detail-error, filtered-empty, truly-empty, suppressed-row) — **extend, do NOT add LLM-baseline cells**
- [ ] New `data-testid="operator-{group}"` cells in `operator_live.ex` for new group containers (D-08), then `getByTestId` assertions
- [ ] ExUnit: `DeliveriesList` empty-state branch tests for COPY-LD-01 (filtered-empty) vs COPY-LD-02 (truly-empty) — requires the new `filters_active?`/`empty_kind` signal (Research A4)
- [ ] ExUnit: CR-01/02/03 unit coverage (no test currently exercises `body_copy(%{})` or nil `selected_delivery` in the two handlers)
- [ ] Seed: `:suppressed` row (+ second suppression shape if matrix needs), timed `hours_ago(7)+` to APPEND last so existing `deliveryRow` indices 0–3 stay timestamp-pinned (Research §Seed stability)
- [ ] Decision gate: does Phase 98 flip `check-conformance-advisory.sh` TRACK/TYPE to hard-fail (operator-scoped) or defer to Phase 99? (Open Question 2)
- [ ] Decision gate: which Tailwind breakpoint realizes the 1440 33/67 tier (`xl:` / `2xl:` / `min-[1440px]:`)? (Open Question 1)

*Existing infra already covers (green): master-detail two-pane, selection flow, replay flows, MOTION-01/02, overview landing, orientation strips, focus rings, ARIA, touch targets.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Subjective on-brand visual rhythm / "joy" of composed groups | GROUP-01, PAGE-01 | Aesthetic quality is LLM-scored, not structurally assertable | Milestone LLM-score pass (frozen 36-cell baseline, meet-or-beat) — not a per-task gate |

*All structurally-assertable behaviors have automated verification per the map above.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING (❌ W0) references above
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
