---
phase: 102-motion-micro-interaction-pass
plan: 01
subsystem: testing
tags: [playwright, bash, conformance, motion, css, animation, reduced-motion]

# Dependency graph
requires:
  - phase: 94-token-rebaseline
    provides: check-conformance.sh five-gate idiom + advisory gate
  - phase: 95-audit-apparatus
    provides: structural.spec.js six-fact Playwright spec + FACT 4 reduced-motion baseline
  - phase: 96-research-dossier
    provides: MOTION-LD-01..14 locked decisions (ease-out only, transform/opacity only, prefers-reduced-motion snaps)
provides:
  - MOTION-GATE in check-conformance.sh banning layout-property transitions (MOTION-LD-10) and stray ease-in (MOTION-LD-01)
  - MOTION-02 structural proof: Playwright test asserting animationDuration/transitionDuration ≤ 0.05s under prefers-reduced-motion
  - Enter/exit asymmetry scaffold: test.fixme assertion on phx-remove presence on #delivery-detail-*, pending Plan 102-03
affects:
  - 102-02 (CSS/HEEx changes: MOTION-GATE must stay green after every motion-class addition)
  - 102-03 (must un-skip the enter/exit asymmetry test.fixme after adding phx-remove to operator_live.ex:466)
  - 103-verification-closeout (both gates are part of the phase gate: check-conformance.sh + npx playwright test e2e/structural.spec.js)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Grep gate idiom (fail-on-match, word-boundary anchored, POSIX-compatible): ban layout-property transitions and stray ease-in tokens without false positives on transition-colors/transition-all/ease-in-out"
    - "Playwright computed-style assertion under emulateMedia: click to bring conditional motion element into DOM, then evaluate getComputedStyle().animationDuration and transitionDuration, assert parseFloat ≤ 0.05"
    - "test.fixme scaffold: skip asymmetry test with TODO(102-NN) comment so Wave 1 stays green; un-skip in the citing plan's closing task"

key-files:
  created: []
  modified:
    - mailglass_admin/scripts/check-conformance.sh
    - mailglass_admin/e2e/structural.spec.js

key-decisions:
  - "MOTION-GATE uses two separate grep passes: one for layout-property transition utilities (word-boundary anchored regex), one for stray ease-in (pipe through grep -v to exclude ease-in-out and --ease-symmetric) — avoids POSIX lookahead incompatibility"
  - "Reduced-motion test clicks first delivery row to bring .motion-reveal into DOM before asserting computed style — the detail pane is conditional on delivery selection, not present on operator overview"
  - "Enter/exit asymmetry test marked test.fixme (not test.skip) with inline TODO(102-03) — fixme is the Playwright canonical annotation for known-failing tests pending implementation"
  - "Threshold of ≤ 0.05 (50ms), never === 0, because app.css:294,297 sets 0.01ms !important (not 0ms) — parseFloat('0.01ms') = 0.01, which would spuriously fail a strict === 0 check"

patterns-established:
  - "Plan 102-01: tighten-then-change pattern — conformance gates added BEFORE any CSS/HEEx motion change so Plans 02–03 cannot regress silently"

requirements-completed: [MOTION-01, MOTION-02]

# Metrics
duration: 5min
completed: 2026-06-16
---

# Phase 102 Plan 01: Motion Gates — Conformance grep + Playwright structural assertions

**MOTION-GATE added to check-conformance.sh banning layout-property transitions and stray ease-in; Playwright structural test proving animationDuration/transitionDuration ≤ 0.05s under prefers-reduced-motion now passes; enter/exit asymmetry scaffold in place (test.fixme, pending 102-03)**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-16T16:58:31Z
- **Completed:** 2026-06-16T17:02:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- MOTION-GATE block in `check-conformance.sh`: bans `transition-{height,width,padding,margin,top,left,right,bottom,max-height}` utilities and arbitrary JIT `transition-[...]` forms naming those properties (MOTION-LD-10); bans `ease-in\b` tokens excluding `ease-in-out` and `--ease-symmetric` (MOTION-LD-01); exits 0 on clean tree, exits 1 on both negative probes
- New Playwright test in FACT 4 "reduced-motion suppresses animation": clicks first delivery row to bring `.motion-reveal` into DOM, then asserts `animationDuration` and `transitionDuration` via `getComputedStyle` are each ≤ 0.05s — the MOTION-02 structural proof against current CSS (app.css uses `0.01ms !important`)
- New FACT 7 "enter/exit asymmetry" describe block with `test.fixme` assertion on `phx-remove` attribute presence on `#delivery-detail-*` element, citing `TODO(102-03)` — scaffold exists now, un-skip when Plan 103 adds the attribute to `operator_live.ex:466`
- Full structural spec: 40/41 pass, 1 skipped (fixme); no existing facts regress; advisory gate clean

## Task Commits

1. **Task 1: Add MOTION-GATE to check-conformance.sh** - `4dfd1bb5` (feat)
2. **Task 2: Extend structural.spec.js with reduced-motion duration + enter/exit asymmetry assertions** - `523c7f05` (feat)

## Files Created/Modified

- `mailglass_admin/scripts/check-conformance.sh` — Added 33-line MOTION-GATE block after HEX-GATE, before the final error summary
- `mailglass_admin/e2e/structural.spec.js` — Added computed-duration test to FACT 4 (lines ~777-806) and new FACT 7 enter/exit asymmetry describe block (lines ~930-968)

## Decisions Made

- Two-grep approach for MOTION-GATE ease-in: `grep -rEn '\bease-in\b' | grep -v -- '--ease-symmetric' | grep -v 'ease-in-out'` — POSIX ERE does not support negative lookahead, so piped `grep -v` exclusions are the idiomatic bash alternative. Tested both that `ease-in"` triggers it and that `ease-in-out`/`--ease-symmetric` do not.
- Computed-style test clicks the first delivery row: the `.motion-reveal` element in `operator_live.ex:466` is inside a `cond do` branch that only renders when `@selected_delivery` is non-nil. The operator overview with `view=deliveries` does not pre-select a delivery, so `.motion-reveal` is absent until a row is clicked. This click does not interfere with the `emulateMedia({ reducedMotion: "reduce" })` call (which was set before navigation).
- `test.fixme` over `test.skip`: Playwright's `fixme` annotation semantics say "expected to fail now, will be fixed later" — more accurate than `skip` for a scaffold that will be un-skipped by 102-03.

## Deviations from Plan

None — plan executed exactly as written. The one deviation in approach (clicking first row before evaluating `.motion-reveal`) was required because the plan's suggested fallback (`.motion-timeline > *`) is also conditional on delivery selection on the operator surface; resolving to click the row is within the "locate the first .motion-reveal" instruction intent.

## Issues Encountered

- First version of the computed-duration test timed out (30s) waiting for `.motion-reveal` because neither `.motion-reveal` nor `.motion-timeline > *` are in the DOM on the operator overview without a delivery selected. Fixed by clicking the first delivery row button before evaluating computed style.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 102-02: CSS/HEEx motion uplift (enter/exit CSS classes, view-transition block, connection-state skeleton, focus-transition standardization). MOTION-GATE will catch any layout-property transition violations introduced.
- Plan 102-03: phx-remove exit attribute on `operator_live.ex:466` and `inbound_live.ex:389`. Must un-skip `test.fixme("Operator: detail pane carries phx-remove exit attribute (MOTION-LD-13)")` in `structural.spec.js` as the closing task.

---
*Phase: 102-motion-micro-interaction-pass*
*Completed: 2026-06-16*

## Self-Check: PASSED

- `mailglass_admin/scripts/check-conformance.sh` — exists, contains MOTION-GATE (3 occurrences), exits 0 on clean tree
- `mailglass_admin/e2e/structural.spec.js` — exists, contains animationDuration assertion, enter/exit asymmetry describe block with test.fixme
- Commit `4dfd1bb5` — verified in git log (Task 1)
- Commit `523c7f05` — verified in git log (Task 2)
- Full structural spec: 40/41 pass, 1 skipped — no new failures vs pre-change baseline (was 40 pass/0 skip before this plan; +1 skip is the new fixme)
