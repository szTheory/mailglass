---
phase: 174-faithful-storybook-and-quiet-quick-views
plan: "05"
subsystem: testing
tags: [storybook, playwright, axe, accessibility, phoenix-liveview]
requires:
  - phase: 174-01
    provides: Retained production Delivery quick view and selected Storybook variants
  - phase: 174-02
    provides: Retained production Inbound quick view and scenario fixtures
  - phase: 174-04
    provides: Story-local themes, production CSS/fonts, and stable Storybook mounts
provides:
  - Admin-owned fail-closed Axe sweep over the exact 18 selected Storybook cases
  - Keyboard-focusable Delivery and Inbound quick-view scroll panels with regression coverage
  - Independent pre-repair and final scan reports with exact incomplete-finding triage
affects: [174-06, 178]

actuals:
  tokens: 209860
  tasks: 3
  commits: 10
commits: 10
plan_head_before: 143ae3d45b25b7975ddf9585e51c1f9782450d17
plan_head_after: cc9aa419be6ac59f9970221ac08e041080e50d4f

tech-stack:
  added: []
  patterns:
    - Reuse Admin's locked @axe-core/playwright installation from a separate Storybook-only Playwright config.
    - Compare safe Axe fingerprints by rule, stable target, scenario, state, and theme against independent evidence.
key-files:
  created:
    - mailglass_admin/playwright.storybook.config.cjs
    - mailglass_admin/e2e/storybook-axe.spec.js
    - mailglass_admin/e2e/support/storybook-axe.cjs
    - mailglass_admin/e2e/support/storybook-axe.test.cjs
    - .planning/phases/174-faithful-storybook-and-quiet-quick-views/174-05-reproduced-before-storybook-axe-6a14fcaf-r5.json
    - .planning/phases/174-faithful-storybook-and-quiet-quick-views/174-05-final-storybook-axe.json
  modified:
    - mailglass_admin/package.json
    - mailglass_admin/docs/storybook-axe-approved.json
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
key-decisions:
  - Keep the selected scan on Admin's existing locked Axe dependency; add no package or lockfile changes.
  - Require caller-supplied run/revision/digest identity and all 18 exact executions; count-only comparisons cannot pass.
  - Triage incomplete results against a separate reproduced pre-repair report and leave violation approvals empty.
  - Make the named dialog itself keyboard-focusable and render Delivery boundary navigation as native disabled buttons.
patterns-established:
  - Storybook scans write raw reports to a caller-selected path outside Playwright's cleaned test-results directory.
  - Incomplete Axe results retain exact safe selectors and explicit evidence without implying an accessibility pass.
requirements-completed: [UIQ-05]
coverage:
  - id: D1
    description: The Admin Axe gate executes all 18 selected cases and rejects unapproved or untriaged findings.
    requirement: UIQ-05
    verification:
      - kind: unit
        ref: "node --test mailglass_admin/e2e/support/storybook-axe.test.cjs (18 tests)"
        status: pass
      - kind: e2e
        ref: "174-05-final-storybook-axe.json; run phase174-05-final-current-cc9aa419; comparator CLI"
        status: pass
    human_judgment: true
    rationale: Axe returned incomplete color-contrast cases; they remain explicitly retained for manual contrast review and are not reported as passing.
  - id: D2
    description: Both quick-view dialogs accept keyboard focus and scroll through clipped content while preserving focus and boundary behavior.
    requirement: UIQ-05
    verification:
      - kind: e2e
        ref: "flows.spec.js: Phase174 scroll access and Phase174 client hooks (3 cases)"
        status: pass
    human_judgment: false

metrics:
  duration: 1h26m
  completed: 2026-10-27
status: complete
---

# Phase 174 Plan 05: Selected Storybook Axe Gate and Keyboard Scroll Access Summary

**A fail-closed 18-case Storybook scan compares exact findings while both production quick-view panels become keyboard-scrollable.**

## Performance

- **Duration:** about 1h 26m
- **Started:** 2026-10-27T04:08:14Z
- **Completed:** 2026-10-27T05:34:39Z
- **Tasks:** 3
- **Plan artifacts:** 17 (11 task files, five raw scan reports, and this summary)

## Accomplishments

- Added an Admin-owned Storybook scan using the existing locked `@axe-core/playwright` dependency. The comparator rejects stale identity, partial/duplicate execution, changed fingerprints, unapproved violations, and untriaged incomplete results.
- Made both production quick-view dialogs keyboard-focusable. Delivery's unavailable previous/next controls now use native disabled buttons; connected checks cover long overflow, PageDown/End scrolling, 44px targets, boundary state, focus trap, Escape, and focus return.
- Preserved independent raw scan receipts outside Playwright's cleanup directory. The reproduced pre-repair run completed all 18 cases with 8 `aria-prohibited-attr` violations and 278 incomplete findings. The accepted final run completed all 18 with zero violations, 230 incomplete findings, zero unapproved findings, and zero untriaged findings. All final incomplete fingerprints occur in the pre-repair report; 48 baseline fingerprints are absent from the final report.

## Task Commits

1. **Task 1: Selected Admin Storybook scan** — `2954ecef` (`test`).
2. **Task 2: Strict report comparator** — `1471676f` (RED), `f08ce5b0` (GREEN), `d288b429` (producer integration).
3. **Task 3: Scroll repair and final evidence** — `6a14fcaf` (RED), `05ed07c9` (production repair), `84123b4d` (stable iframe identity), `37e311ae` (synchronous readiness polling), `11ffeae9` (initial triage provenance), `cc9aa419` (reproduced-report provenance).

The plan ledger measured 10 commits from `143ae3d45b25b7975ddf9585e51c1f9782450d17` through `cc9aa419be6ac59f9970221ac08e041080e50d4f` before the summary/state metadata commit.

## Files Created/Modified

- `mailglass_admin/playwright.storybook.config.cjs` and `mailglass_admin/e2e/storybook-axe.spec.js` — isolated Admin runner with explicit 18-case scenario/state/theme identity and safe report output.
- `mailglass_admin/e2e/support/storybook-axe.cjs` and `storybook-axe.test.cjs` — strict report/fingerprint validation and 18 negative/control tests.
- `mailglass_admin/docs/storybook-axe-approved.json` — 278 exact incomplete triage records from independent pre-repair run `phase174-05-pre-repair-6a14fcaf-repro-r5`; `approved_fingerprints` remains empty.
- `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`, `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex`, and `mailglass_admin/e2e/flows.spec.js` — focusable scroll panels and connected keyboard regressions.
- `.planning/phases/174-faithful-storybook-and-quiet-quick-views/174-05-reproduced-before-storybook-axe-6a14fcaf-r2.json` through `r5.json` and `174-05-final-storybook-axe.json` — five durable raw reports with independent run/source identities.

## Verification

- `node --test mailglass_admin/e2e/support/storybook-axe.test.cjs` — 18 passed.
- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/axe_baseline_test.exs` from `mailglass_admin` — 12 passed; the existing nine-cell baseline was not changed.
- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm run test:operator-browser -- flows.spec.js --grep 'Phase174 scroll access|Phase174 client hooks' --reporter=junit` from `mailglass_admin` — 3 passed.
- `npm --prefix mailglass_admin run test:storybook-axe -- --grep 'Phase174 selected axe'` — final report run `phase174-05-final-current-cc9aa419`, 18 passed. Source revision `cc9aa419be6ac59f9970221ac08e041080e50d4f`; source digest `0529a5871a01593d02c4639a33dba3f644b404ac8725e608a31cf0b56bdb4db2`.
- The same report comparator CLI returned `expected=18`, `successful=18`, `violations=0`, `unapproved=0`, `untriaged=0`, `valid=true`.

## Decisions Made

- The existing nine-cell Admin baseline remains intact; the Storybook sweep is a separate selected gate.
- Incomplete contrast checks stay visible as manual-review items. Their triage does not assert WCAG AA compliance.
- Empty Storybook routes remain excluded with their explicit route-only proof boundary; the selected set remains nine rendered variants across light and dark.

## Deviations from Plan

### Auto-fixed Issues

**1. Rule 1 — Playwright async polling returned a false readiness value**
- **Found during:** Task 3 final scan stabilization
- **Issue:** In Playwright 1.59.1, the async `page.waitForFunction` predicate returned a Promise object to the poller, which treated it as truthy before resolution. The resulting handle serialized as `false` and failed selected-root identity.
- **Fix:** Use a synchronous poll predicate and wait until the iframe's `FontFaceSet.status` is `loaded` before returning the stable story identity.
- **Files modified:** `mailglass_admin/e2e/storybook-axe.spec.js`
- **Verification:** Focused Chromium case reached Axe analysis; final 18-case run passed.
- **Committed in:** `37e311ae`.

**Total deviations:** 1 auto-fixed bug (Rule 1). No package or lockfile changes and no scope expansion.

## Issues Encountered and Evidence Limits

- A later `test:operator-browser` run cleaned Playwright's default `mailglass_admin/test-results/` directory and deleted the original raw scan from run `phase174-05-20261027T041038Z-initial-final`. That raw JSON is not preserved or reconstructed. The retained task-3 input is a newly identified before report produced from a disposable pre-repair snapshot at commit `6a14fcaf`, run `phase174-05-pre-repair-6a14fcaf-repro-r5`, with its own source revision and digest. Reports `r2`–`r4` retain additional completed pre-repair runs; their incomplete counts varied, so comparison is by exact fingerprints rather than counts.
- The before report contains 8 `aria-prohibited-attr` violations on unavailable Delivery navigation. The final report contains none. The scroll access regression was reproduced in connected long-content tests; the actual dialog was made focusable even though Axe's `scrollable-region-focusable` rule did not independently flag the `role=dialog` panel.
- The 230 final incomplete results remain unresolved machine verdicts, not approved passes. Exact targets are triaged against the independent pre-repair report; there are no approved violation fingerprints and no human acceptance of residual violations.
- The descriptor-less transparency prohibition remains flagged-unverified. This plan claims no owner approval or required-CI status. The connected Demo host was already seeded; no database reset was attempted, and Plan 174-06 owns a fresh service identity.

## Next Phase Readiness

Plan 174-06 can wrap the committed final report using the independent source/run identity. Phase 174 remains in progress until its final plan and phase-level checks complete.

## Self-Check: PASSED

---
*Phase: 174-faithful-storybook-and-quiet-quick-views*
*Completed: 2026-10-27*
