---
phase: 169-outbound-investigation-and-recovery
plan: "05"
subsystem: operator-ui
tags: [health, replay, responsive, playwright, css, validation, api-stability]
requires:
  - phase: 169-04
    provides: replay review/action boundary, persisted test scenarios, and corrected operator trust guidance
provides:
  - Connected Health-to-exact-support-to-Delivery replay journey with return-state assertions
  - Current rendered evidence across 320, 390, 768, and 1440 CSS-pixel widths and native Chrome 200% zoom inspection record
  - Sibling-only exact-read API inventory and final current-revision regression evidence
affects: [phase-verification, operator-ui, outbound-investigation, api-stability]
actuals:
  tokens: 74024.5
  tasks: 2
  commits: 2
  plan_head_before: 30a12fd651ea5392a4c80fe86ce6ce86078aaabf
  plan_head_after: c86bd17d366d0f136a1a6c10db9b11d61effd3c5
tech-stack:
  added: []
  patterns:
    - Persisted browser fixture IDs drive connected support and replay assertions.
    - CSS provenance is compared across source, built, and served bytes.
key-files:
  created:
    - .planning/phases/169-outbound-investigation-and-recovery/169-05-SUMMARY.md
  modified:
    - .planning/phases/169-outbound-investigation-and-recovery/169-BASELINE.md
    - .planning/phases/169-outbound-investigation-and-recovery/169-VALIDATION.md
    - .planning/phases/169-outbound-investigation-and-recovery/artifacts/after/
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/e2e/gallery-matrix.spec.js
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - docs/api_stability.md
    - mailglass_admin/docs/api_stability.md
key-decisions:
  - "Final Back to deliveries clears selected Delivery, full-detail mode, and exact support focus while preserving Account and committed filters/page, per the approved UI spec."
  - "Keep dev-gallery theme specimens stacked through tablet widths; the production Delivery layout switches by available content width."
  - "Document terminal audit write-failure proof as an explicit limit; the browser proves a post-command audit read failure only."
patterns-established:
  - "Every after capture records route, fixture, revision, and source/built/served CSS identity."
  - "Review command-returned outcome separately from persisted terminal audit evidence."
requirements-completed: [OUTUX-01, OUTUX-02, OUTUX-03, OUTUX-04, OUTUX-05]
coverage:
  - id: D1
    description: "Operators can traverse Health support evidence to its exact out-of-window Delivery, review replay, and return without changing Account or committed list state."
    requirement: OUTUX-02
    verification:
      - kind: e2e
        ref: "Phase 169 connected browser selection: 9 passed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rendered Health, list, detail, Quick view, and replay review remain readable across the approved viewport matrix; native 200% Chrome zoom was inspected on one route family."
    requirement: OUTUX-01
    verification:
      - kind: automated_ui
        ref: "Phase 169 rendered selection: 2 passed; full unfiltered operator browser suite: 197 passed, 1 skipped"
        status: pass
      - kind: manual_procedural
        ref: "169-BASELINE.md — After Evidence, native Chrome 200% inspection and visual review"
        status: pass
    human_judgment: true
    rationale: "Visual composition and native browser zoom text/focus behavior require direct visual review; physical-device touch and the full route matrix at 200% remain untested."
  - id: D3
    description: "New exact investigation reads are classified as sibling-package-only and current test/asset provenance is recorded."
    verification:
      - kind: unit
        ref: "Core operator selection 39 passed; Admin suite 537 passed, 1 excluded; parity/bundle 9 passed; built and served CSS hashes match"
        status: pass
    human_judgment: true
    rationale: "Adopter API stability interpretation and the five unresolved prohibition judgments still require independent phase review."
metrics:
  duration: "~2h 25m from the first Plan05 baseline record at 20:15 to final verification at 22:39 EDT; exact executor start was not captured"
  completed: "2026-10-07"
status: complete
---

# Phase 169 Plan 05: Rendered Connected Workflow Summary

**The connected Health-to-replay path now preserves exact evidence and committed list context across responsive layouts, with current rendered and regression provenance.**

## Performance

- **Duration:** Approximately 2h 25m from the recorded baseline capture to the final unfiltered suite; the exact executor start time was not captured.
- **Started:** 2026-10-07 20:15 EDT (first Plan05 baseline timestamp; executor start may have preceded this record).
- **Completed:** 2026-10-07 22:39 EDT.
- **Tasks:** 2/2.
- **Files modified:** 35 files across the two task commits, including the 20 after screenshots.

## Accomplishments

- Added a real-control journey from filtered Health to same-kind exact support evidence, an out-of-window linked Delivery, Quick view, full detail, replay result, and Back to deliveries. The explicit final Back clears Delivery/full-detail/support focus while retaining Account, provider/event/window filters, and page.
- Recorded 20 current after captures and exact route/fixture/source/built/served CSS provenance; all four app viewports had zero page overflow, 16 px body text, 14 px labels, and 17 decorative icons hidden from assistive technology.
- Classified the new exact read helpers as sibling-package-only and ran the focused core, full Admin, asset build, parity/bundle, named rendered/connected, and unfiltered operator browser gates.

## Task Commits

Each task was committed atomically:

1. **Task 1: Inspect and refine the rendered outbound states in the existing visual language** — `e45aa8e1` (`test(169-05): add rendered responsive acceptance matrix`).
2. **Task 2: Prove the connected journey and publish sibling-read and investigation truth** — `c86bd17d` (`test(169-05): close connected journey and regression evidence`).

**Plan metadata:** recorded in the subsequent docs commit.

## Files Created/Modified

- `mailglass_admin/e2e/phase169-journey.spec.js` — responsive rendered matrix, immutable before-evidence guard, and connected persisted-fixture journey.
- `mailglass_admin/test/support/operator_fixtures.ex` — current Health failure exemplar linked to an aged-out Delivery.
- `mailglass_admin/e2e/{gallery-matrix,operator,phase168-plan03-acceptance,structural}.spec.js` — narrow corrections to stale assertions and gallery diagnostics/responsive coverage.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` — keeps dev-only light/dark/System specimens full width through tablet viewports.
- `mailglass_admin/lib/mailglass_admin/operator/{detail_header,timeline}.ex` and `mailglass_admin/priv/static/app.css` — narrow wrapping utility and rebuilt tracked CSS.
- `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md` — sibling-only exact-read classification.
- `.planning/phases/169-outbound-investigation-and-recovery/169-BASELINE.md`, `169-VALIDATION.md`, and `artifacts/after/` — current rendered evidence, regression results, proof boundaries, and validation status.

## Decisions Made

- Followed the approved `169-UI-SPEC.md` final Back semantics: clear selected Delivery, full-detail mode, and exact support focus, without reopening Quick view; preserve Account and committed filter/page state.
- Stacked dev-gallery theme wrappers until `xl` after the 768 px matrix showed that three narrow theme columns caused two specimens to overflow. Production layout continues to use available content width for the table/card threshold.
- Kept the missing terminal audit database write-failure as an explicit proof limit. The browser establishes successful command feedback and a subsequent one-shot audit-history read failure; existing LiveView tests establish requested-only and unavailable-history behavior.
- Preserved the five OUTUX prohibition judgments as flagged/unverified because the phase probe serializer does not yet provide direct enforcement judgments.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Regression] Updated stale responsive and Health drill-through assertions.**
- **Found during:** Task 2 full unfiltered browser regression.
- **Issue:** Existing assertions expected an obsolete `event=failed` link and a table at 768 CSS px even though the current approved behavior uses support focus and actual content-column width.
- **Fix:** Updated the exact href assertion and responsive test to assert the available `main` width; updated the fail-closed Bucket A title citation.
- **Files modified:** `operator.spec.js`, `structural.spec.js`, `bucket_a_coverage_test.exs`.
- **Verification:** Targeted five-case correction gate passed; final unfiltered suite passed.
- **Committed in:** `c86bd17d`.

**2. [Rule 1 - Regression] Removed a stale internal DOM-mutation expectation.**
- **Found during:** Task 2 full unfiltered browser regression.
- **Issue:** The repeated replay test treated same-text LiveView DOM repatching as visible feedback change.
- **Fix:** Retained assertions for stable status node/text, stable detail node, and no detail animation; removed the internal mutation-count equality.
- **Files modified:** `phase168-plan03-acceptance.spec.js`.
- **Verification:** The named case passed in the targeted correction run and final full browser suite.
- **Committed in:** `c86bd17d`.

**3. [Rule 1 - Responsive defect] Corrected narrow tablet gallery specimens.**
- **Found during:** Task 2 full unfiltered browser regression.
- **Issue:** The dev gallery squeezed three theme wrappers into one 768 px row, overflowing detail-header and long timeline specimens.
- **Fix:** Kept the three wrappers stacked until `xl` and made overflow failures report offending descendants.
- **Files modified:** `gallery_live.ex`, `gallery-matrix.spec.js`, rebuilt `priv/static/app.css`.
- **Verification:** All-specimen and long-value stress matrices passed across 320/390/768/1440 × light/dark/System.
- **Committed in:** `c86bd17d`.

**Total deviations:** 3 narrow corrections (two stale regression assumptions and one dev-gallery responsive defect). They were required to make the approved behavior and final browser gate accurately observable.

## Issues Encountered

- Non-elevated Chromium runs failed before test execution because macOS denied MachPortRendezvous startup. The plan-authorized host-process reruns passed; no test packages were installed.
- The installed asdf runtime versions do not match the exact patch pins in the repository `.tool-versions`; a temporary local runtime override selected installed Erlang/OTP 27.3.4.15 and Elixir 1.18.4/OTP27, then was removed. The tracked runtime pin was not changed.
- A first final Admin run caught one stale fail-closed responsive test-title citation; it was corrected and the full Admin suite then passed.
- The full browser suite regenerated two Phase168 review-fix PNGs. Parent confirmed they were clean before this run; I restored only those two generated outputs from `HEAD`. The original three dirty planning paths remain untouched.
- Impeccable's installed launcher supports `detect`, while its skill reference lists `audit`; the `audit` attempt returned “Unknown command”. `detect` completed for the changed UI files without output; no scored audit report is claimed.

## Verification Results

See [169-BASELINE.md](169-BASELINE.md) for complete run provenance and explicit limits. Final current-checkout counts:

- Rendered selection: 2 passed.
- Connected selection: 9 passed.
- Focused core operator selection: 39 passed, 0 excluded.
- Full Admin: 537 passed, 1 excluded.
- Asset build: passed; source SHA-256 `8f3b778e…`, built and served SHA-256 `b3eb3830…` matched byte-for-byte.
- Parity/bundle: 9 passed.
- Full unfiltered operator browser suite: 197 passed, 1 skipped, 0 failed (198 tests, 2.7 minutes).

**Unverified boundaries:** Browser coverage does not inject a terminal audit database write failure; native Chrome 200% zoom was visually inspected on one route family only; physical-device touch and manual OS appearance switching were not performed. OUTUX-01 through OUTUX-05 prohibition judgments remain flagged/unverified for independent phase review.

## User Setup Required

None.

## Next Phase Readiness

Plan 169-05 is complete and its artifacts are ready for the parent’s independent phase review and verifier. Phase 169 remains in execution/review; this summary does not mark the phase complete.

## Self-Check: PASSED

- Summary path exists.
- Task commits `e45aa8e1` and `c86bd17d` exist and are ancestors of the current checkout.
- Current CSS source/built hashes and the ten immutable before-image checksums were rechecked before commit.

---
*Phase: 169-outbound-investigation-and-recovery*
*Plan: 05*
*Completed: 2026-10-07*
