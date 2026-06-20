---
phase: 116-fixtures-idempotent-ratchet-arm
plan: 06
subsystem: ratchet-arm
status: complete
tags: [ratchet, ratchet-04, baseline-promotion, playwright, demo-cohort, axe, idempotent, keystone]

# Dependency graph
requires:
  - phase: 116-01
    provides: "Persona cohort + DemoData.reset! -> Personas.seed! (rich demo_app data, present at boot AND on /demo/evidence/reset)"
  - phase: 116-02
    provides: "9-cell axe-baseline.json + producer + comparator (measured current counts to promote)"
  - phase: 116-03
    provides: "Interaction pillar binary gates on preview (panel-above-scrim / scroll-chaining / focus-restore / CLS) — evidence for the preview Motion+A11y re-score"
  - phase: 116-04
    provides: "Gallery fjordline specimens + overflow matrix gate"
  - phase: 116-05
    provides: "Bucket-A 24-defect closure manifest (bucket_a_coverage_test.exs)"
provides:
  - "reference/demo_app/assets/e2e/cohort.spec.js — RATCHET-04 Playwright run against rich demo_app cohort data (4 tests)"
  - "Promoted 54-cell ui-baseline-scores.json (current 2026-06-16-phase-103 -> prior; fresh current 2026-06-20-phase-116)"
  - "Promoted 9-cell axe-baseline.json (current 2026-06-20-phase-116-axe -> prior; fresh current axe-2026-06-20-phase-116)"
  - "All three fail-closed comparators green simultaneously — the keystone ratchet-arm is armed"
affects: [117-release-cut]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Demo-harness extension (reuse beforeEach /demo/evidence/reset token seam; no new infra; OperatorBrowserServer untouched)"
    - "Page-level horizontal-overflow contract (documentElement.scrollWidth <= innerWidth) instead of asserting on an intentionally overflow-x-auto table wrapper"
    - "Detail navigation via delivery_id URL param (robust to LiveView connection timing) rather than a phx-click"
    - "Idempotent forward ratchet: promote current->prior, re-measure/re-score fresh current with a DISTINCT run_id, meet-or-beat zero-regression"

key-files:
  created:
    - "reference/demo_app/assets/e2e/cohort.spec.js"
    - ".planning/phases/116-fixtures-idempotent-ratchet-arm/deferred-items.md"
  modified:
    - "mailglass_admin/docs/ui-baseline-scores.json"
    - "mailglass_admin/docs/axe-baseline.json"

key-decisions:
  - "Non-ASCII from[].name verbatim render is NOT asserted on the demo operator surface (it lives in Delivery.metadata['from'], which the operator surface does not render) — that verbatim coverage is the gallery's (116-04 fjordline specimens). The demo run asserts the observable fjordline edge values: long-ID + 64-char mailable truncated, recipient verbatim, nil reject_reason no reason line."
  - "Overflow asserted at the PAGE level (no viewport horizontal scrollbar), not on operator-deliveries-table (that wrapper is intentionally overflow-x-auto — a contained scroll region by design)."
  - "preview Motion+A11y re-scored 3 -> 4: earned by the 116-03 interaction pillar binary gates now green on the preview surface across all three themes, not score-trading."

requirements-completed: [RATCHET-04]

# Metrics
duration: ~17min
completed: 2026-06-20
tasks: 3
files: 4
---

# Phase 116 Plan 06: Idempotent Ratchet-Arm (RATCHET-04) Summary

**The keystone close of v1.13: a Playwright run against the rich `reference/demo_app`
persona cohort (closing the lab-passes-but-ugly gap), then both baselines ratcheted
forward idempotently — the 54-cell aesthetic matrix and the 9-cell axe baseline each
promoted `current -> prior` with a fresh distinct-run_id current and zero regression,
all three fail-closed comparators green simultaneously.**

## What Was Built

### Task 1 — Demo cohort Playwright run (`cohort.spec.js`, commit `7154fcf6`)

`reference/demo_app/assets/e2e/cohort.spec.js` extends the existing demo evidence
harness (D-10 — NO new infra): the same `beforeEach` `POST /demo/evidence/reset`
with `x-mailglass-demo-reset-token` re-runs `DemoData.reset!` -> `Personas.seed!`,
so the suite runs against the rich multi-tenant cohort. Four tests:

- **Tenant picker** — `/demo/login?return_to=/ops/mail` (no `tenant_id`) lands on
  the `:select_required` picker; asserts the `tenant-selector` lists `northstar`
  + `fjordline-aps` links and `helios-void` is absent (realized by absence).
- **fjordline-aps edge values** — opens the single delivery's detail (via the
  `delivery_id` URL param), asserts the long delivery id
  (`del_01JXW9ZQKB3V1N4P2RMT7FHCG`) and the 64-char mailable
  (`...TransactionalEmailWithVeryLongModuleName`) render verbatim in the detail
  header with NO page-level horizontal overflow (truncation contract), the
  recipient renders verbatim, and the `:delivered` / `reject_reason: nil` event
  produces NO "Reason:" line in the timeline (the legitimate null branch).
- **northstar high-count** — the many/high-count lifecycle renders with no page
  overflow and `> 1` delivery rows.
- **helios-void direct URL** — `/ops/mail?tenant_id=helios-void&view=deliveries`
  renders the scoped "No deliveries" empty state (heading), zero rows, no
  server-error page.

Kept serial (the shared `playwright.config.cjs` — destructive reset races a shared
DB). **4 passed.** No `reference/demo_app/mix.lock` drift committed.

### Task 2 — Promote + re-score the 54-cell aesthetic baseline (`ui-baseline-scores.json`, commit `804d704f`)

The milestone's ONLY full pillar re-score (D-02). Promoted the existing current
(`2026-06-16-phase-103`) to `prior`; generated a fresh `current`
(`2026-06-20-phase-116`, distinct run_id -> anti-vacuity guard satisfied).
`schema_version` stays 3; all 54 cells present in both blocks, scores 1..4, zero
regression. One cell moved forward — `preview.Motion+A11y` `3 -> 4` across
light/dark/system — earned by the 116-03 interaction pillar binary gates
(panel-above-scrim, scroll-chaining, focus-restore, CLS-within-threshold) now
green on the preview surface. `ratchet_baseline_test.exs`: **4 tests, 0 failures.**

### Task 3 — Promote the 9-cell axe baseline + all-three-comparator gate (`axe-baseline.json`, commit `26dc0414`)

Re-ran the producer (`e2e/axe-baseline.spec.js`, `PERSIST_AXE_BASELINE=1`) against
the completed work — the 9 measured cells were unchanged (1 violation/cell;
`scrollable-region-focusable` on deliveries/inbound, `aria-allowed-attr` on
preview), confirming no a11y regression. Then promoted the measured current to
`prior` (run_id `2026-06-20-phase-116-axe`) and assigned the fresh current a
distinct run_id `axe-2026-06-20-phase-116`. Meet-or-beat holds per cell total AND
per rule-id. Ran all three comparators together — `ratchet_baseline_test` +
`axe_baseline_test` + `bucket_a_coverage_test` = **22 tests, 0 failures
simultaneously.** The keystone ratchet-arm is armed.

## Baseline run_ids (input to Phase 117 release cut)

| Baseline | prior run_id | current run_id (fresh) |
|----------|--------------|------------------------|
| 54-cell aesthetic (`ui-baseline-scores.json`) | `2026-06-16-phase-103` | `2026-06-20-phase-116` |
| 9-cell axe (`axe-baseline.json`) | `2026-06-20-phase-116-axe` | `axe-2026-06-20-phase-116` |

## Cells that needed an underlying fix to meet-or-beat

**None.** No cell regressed. The single forward move (`preview.Motion+A11y` 3 -> 4)
is an earned improvement backed by the 116-03 interaction pillar gates, not a fix
to avoid a regression. The axe cells were unchanged (equal meet-or-beat).

## All three comparators green on main

Confirmed run on main (not a worktree — deps/_build gitignored):
`MIX_ENV=test mix test test/mailglass_admin/axe_baseline_test.exs
test/mailglass_admin/ratchet_baseline_test.exs
test/mailglass_admin/bucket_a_coverage_test.exs` -> **22 tests, 0 failures.**
Demo `cohort.spec.js` -> 4 passed. Axe producer -> 9 passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Demo overflow asserted on the wrong element; row click flaky**
- **Found during:** Task 1 (first cohort.spec.js run — 3 of 4 tests failed).
- **Issue:** (a) The initial spec asserted no-overflow on `operator-deliveries-table`,
  but that wrapper carries `overflow-x-auto` (a contained scroll region by design),
  so the check tripped on intended behavior. (b) The detail-open via `phx-click` on
  the table row raced LiveView connection (`operator-detail-header` never appeared).
  (c) The empty-state assertion `getByText("No deliveries")` matched both the heading
  and the body copy (strict-mode violation).
- **Fix:** (a) Switched to a PAGE-level overflow contract
  (`documentElement.scrollWidth <= innerWidth`, the real "no horizontal scrollbar"
  invariant). (b) Navigate to detail via the `delivery_id` URL param (the
  `demo.spec.js` pattern), robust to connection timing. (c) Scoped to
  `getByRole("heading", { name: "No deliveries" })`.
- **Files modified:** `reference/demo_app/assets/e2e/cohort.spec.js`.
- **Verification:** 4/4 cohort tests pass.
- **Committed in:** `7154fcf6` (Task 1 commit — fixes folded in before commit).

### Render-surface scoping (recorded, not a code defect)

- **Non-ASCII `from[].name` verbatim render is not observable on the demo operator
  surface.** Those display names live in `Delivery.metadata["from"]`, which the
  operator detail/timeline/list do NOT render (the schema has no structured `from`
  field — 116-01 decision). The demo run therefore asserts the *observable*
  fjordline edge values (long-ID + long-mailable truncation, recipient verbatim,
  nil reject_reason no reason line); the non-ASCII verbatim render is covered by
  the gallery fjordline specimens (plan 116-04) and the persona drift-guard.

## Issues Encountered

- **Pre-existing operator-browser matrix failures (out of scope — see
  `deferred-items.md`).** Running the full `npm run test:operator-browser` matrix
  (a plan `<verification>` item) surfaced **16 failures** in `operator.spec.js` /
  `structural.spec.js` (133 passed, 1 skipped). Root cause: Phase 113 (`532a8b17`)
  split deliveries into a desktop `operator-deliveries-table` and a `md:hidden`
  mobile `operator-deliveries-list`, but `operator.spec.js`'s `openOperator` helper
  (last touched Phase 111) still asserts the now-mobile-only list is visible at the
  1280px desktop viewport. These are stale-since-Phase-113 failures entirely
  independent of 116-06 — this plan's three commits touched only `cohort.spec.js`
  (demo) and two `docs/*.json` baseline files, none of which can affect those admin
  browser tests. Logged to `deferred-items.md` with a suggested harness fix; NOT
  fixed here (SCOPE BOUNDARY).

- **demo_app baseline lock-coupling.** Running the demo Playwright suite requires
  `mix deps.get` in `reference/demo_app` (the frozen baseline pins `premailex
  0.3.20` but the core path-dep needs `~> 1.0`; resolving also bumps swoosh to
  1.26.1). Resolved transiently for each test run; `mix.lock` reverted via
  `git checkout reference/demo_app/mix.lock` before every commit. No lock drift
  committed.

## User Setup Required

None. `DEMO_EVIDENCE_RESET_TOKEN` defaults to a local value for the demo run; CI
supplies the real token.

## Next Phase Readiness

- **Phase 117 (release cut):** Both baselines are promoted with distinct run_ids
  and the three fail-closed comparators are green simultaneously — the v1.13 ratchet
  is armed. The pre-existing operator-browser harness staleness (deferred-items.md)
  should be triaged before any CI lane treats the full matrix as blocking.
- **No blockers** introduced by this plan.

## Known Stubs

None. Every assertion runs against live demo/admin surfaces or real measured
baseline counts.

## Self-Check: PASSED

- `reference/demo_app/assets/e2e/cohort.spec.js` — FOUND (4 tests pass)
- `mailglass_admin/docs/ui-baseline-scores.json` — FOUND (promoted, distinct run_ids)
- `mailglass_admin/docs/axe-baseline.json` — FOUND (promoted, distinct run_ids)
- `.planning/phases/116-fixtures-idempotent-ratchet-arm/deferred-items.md` — FOUND
- Commits `7154fcf6`, `804d704f`, `26dc0414` — FOUND in git log
- Three comparators green: 22 tests, 0 failures

---
*Phase: 116-fixtures-idempotent-ratchet-arm*
*Completed: 2026-06-20*
