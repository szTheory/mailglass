---
phase: 168-shared-workspace-and-usable-baseline
plan: 04
subsystem: ui
tags: [phoenix-liveview, accessibility, overlays, playwright, css]

requires:
  - phase: 168-03
    provides: Shared theme, feedback, motion and timestamp presentation
provides:
  - Consolidated Quick view positioning in the shared stylesheet
  - Keyboard-opened Quick view with exact-row focus restoration
  - Truthful exact-target replay confirmation with pending, denial and completion evidence
  - Source-identified 52-criterion before/after baseline inventory
affects: [168-verification, operator-ui, browser-acceptance]

actuals:
  tokens: 78869
  tasks: 3
  commits: 4
  plan_head_before: 93c5a61357dcdec0c44f87c13b03a2583de4542a
  plan_head_after: ae66da0b37b28f018807d05453bcea3bf25983d9

tech-stack:
  added: []
  patterns:
    - Exact stable desktop/mobile trigger IDs for modal focus return
    - Inline presentation for gallery-only transient feedback specimens

key-files:
  created:
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-04-SUMMARY.md
    - .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan04/quick-view-320-light.png
    - .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan04/quick-view-390-light.png
    - .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan04/quick-view-768-light.png
    - .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan04/quick-view-1440-light.png
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/test/mailglass_admin/token_parity_test.exs
    - mailglass_admin/test/support/endpoint_case.ex
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md

key-decisions:
  - "Return Quick view focus only to a stable row ID matching the URL-selected delivery."
  - "Keep gallery Flash examples inline so static specimens do not overlay other focus targets."
  - "Use unavailable copy for missing replay evidence while retaining the existing target and authorization checks."

patterns-established:
  - "Hold a real LiveView reply in Playwright to verify pending UI without replacing the server action."
  - "Keep gallery-only component examples out of fixed overlay layers."

requirements-completed: [UXF-01, UXF-04, UXF-06, UXF-07, UXF-08]

coverage:
  - id: D1
    description: Quick view panel styling is owned by the shared built stylesheet and remains responsive.
    requirement: UXF-01
    verification:
      - kind: automated_ui
        ref: "Plan168-04 viewport, overlay-layer and reduced-motion browser probe at 320/390/768/1440"
        status: pass
    human_judgment: false
  - id: D2
    description: Quick view names the selected record and restores keyboard focus to its exact row.
    requirement: UXF-04
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 168 Quick view focus"
        status: pass
    human_judgment: false
  - id: D3
    description: Replay confirmation keeps an exact target visible through pending, denial and completion states.
    requirement: UXF-06
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 168 confirmation focus"
        status: pass
    human_judgment: false
  - id: D4
    description: The shared workspace baseline inventories 52 UI-SPEC criteria with evidence and limits.
    requirement: UXF-07
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md#Final UI-SPEC Coverage Inventory (52 Criteria)"
        status: pass
    human_judgment: false
  - id: D5
    description: Narrow Inbound and Preview content wraps, gallery specimens avoid fixed overlay obstruction, and shared CSS matches the demo served asset.
    requirement: UXF-08
    verification:
      - kind: e2e
        ref: "npm run test:operator-browser — 183 passed, 0 failed, 1 existing guarded skip"
        status: pass
      - kind: unit
        ref: "mix test focused shell/components/operator/inbound/voice/token/bundle set — 302 passed, 0 failures, 1 excluded"
        status: pass
    human_judgment: false

duration: 60min
completed: 2026-10-07
status: complete
---

# Phase 168 Plan 04: Shared workspace and usable baseline summary

**Responsive Quick view, exact-target replay confirmation and focus restoration, backed by a source-identified 52-criterion baseline.**

## Performance

- **Duration:** approximately 60 minutes
- **Started:** 2026-10-07T16:12:00-04:00
- **Completed:** 2026-10-07T17:12:39-04:00
- **Tasks:** 3
- **Files modified:** 22, including rendered evidence and this summary

## Accomplishments

- Moved `.mg-detail-panel` positioning from inline root markup to `assets/css/app.css`, rebuilt `priv/static/app.css`, and verified the demo-served stylesheet hash matches the bundle.
- Added keyboard activation and stable exact-row focus return for Quick view; clarified selected identity, outcome and unavailable evidence.
- Completed accessible replay confirmation with exact target, held-response busy state, stale-auth denial, success audit events, and zero-target behavior.
- Filled the 52-row source and evidence inventory in `168-BASELINE.md`.
- Fixed reproduced Phase 168 narrow-screen overflows in Inbound metadata and Preview render errors, a gallery sidebar overflow, the theme-picker pointer affordance, and the fixed Flash samples that blocked gallery focus.

## Task Commits

1. **Task 1: Consolidate rendered Quick view positioning and reduced-motion styling** — `61abe36d` (`fix`)
2. **Task 2: Complete Quick view identity, evidence and keyboard focus path** — `68ef9c25` (`feat`)
3. **Task 3: Confirm exact-target actions with truthful busy and completion feedback** — `70d67e57` (`feat`)
4. **Task 3 follow-up: Keep gallery feedback samples inline** — `ae66da0b` (`fix`)
5. **Task 3 audit correction: Preserve chooser semantics and modal focus** — `ed53da64` (`fix`)

The original four commits are measured from `plan_head_before` through `plan_head_after` in the frontmatter. The later audit correction is recorded separately above and in `168-REVIEW-FIX.md`.

## Files Created/Modified

- `mailglass_admin/assets/css/app.css` and `priv/static/app.css` — consolidated responsive panel rules and generated bundle.
- `operator/quick_view.ex`, `operator/replay_modal.ex`, `operator_live.ex` — record identity, exact-trigger focus return, meaningful confirmation and truthful action state.
- `mailglass_admin/e2e/flows.spec.js` — Quick view keyboard and replay pending/denial/success browser cases.
- `components.ex` and `gallery_live.ex` — opt-in inline Flash placement for static gallery samples.
- `inbound/detail_header.ex`, `preview_live.ex`, `preview/sidebar.ex` — narrow layout wrapping and gallery sizing fixes.
- `mailglass_admin/e2e/structural.spec.js` — stable Account option assertions and gallery feedback-overlay regression check.
- `mailglass_admin/test/support/endpoint_case.ex` — isolated browser fixture can represent stale recent authentication.
- `168-BASELINE.md` — per-task review records, 52-criterion evidence inventory and final runtime confirmation.

## Decisions Made

- Quick view accepts only a focus-return target that exactly matches the selected delivery's stable desktop or mobile row ID.
- Gallery Flash examples use inline placement while production Flash defaults remain fixed toasts.
- Replay request and replay completion remain distinct outcomes; no downstream delivery success is inferred.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected responsive content overflow found by the full Phase 168 browser suite**
- **Found during:** Task 3 (full browser verification)
- **Issue:** Inbound metadata grid children, long Preview error identifiers, and the gallery sidebar overflowed at the tested viewport widths.
- **Fix:** Constrained metadata grid items and enabled wrapping for long technical identifiers; constrained the gallery directory's min-width behavior.
- **Files modified:** `inbound/detail_header.ex`, `preview_live.ex`, `preview/sidebar.ex`
- **Verification:** The affected focused flows passed; final browser suite passed 183 tests with no failures.
- **Committed in:** `70d67e57` and `ae66da0b`.

**2. [Rule 1 - Bug] Kept static Flash gallery samples out of fixed toast overlays**
- **Found during:** Task 3 (gallery focus matrix)
- **Issue:** Four fixed gallery Flash specimens covered a focusable nav link at 320px; hit testing showed the 600px-high toast overlay intercepting the target.
- **Fix:** Added an inline placement option used only by gallery specimens and a regression assertion that gallery Flash cells contain no fixed `.toast` wrapper.
- **Files modified:** `components.ex`, `gallery_live.ex`, `structural.spec.js`
- **Verification:** Focus/hover/touch target matrix passed and the final browser suite passed 183 tests with no failures.
- **Committed in:** `ae66da0b`.

**3. [Rule 1 - Bug] Corrected focused tests for Account chooser behavior and theme control affordance**
- **Found during:** Task 3 (full browser verification)
- **Issue:** The Account chooser assertion became ambiguous with repeated visible account labels, and the radio label did not expose a pointer cursor.
- **Fix:** Opened the chooser and asserted stable account IDs; added the pointer cursor to the interactive theme label.
- **Files modified:** `structural.spec.js`, `components.ex`
- **Verification:** Account chooser test and full browser suite passed.
- **Committed in:** `70d67e57`.

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs). **Impact:** fixes were needed to satisfy demonstrated Phase 168 responsive and focus criteria; no new recovery flow or product toolchain was introduced.

## Verification

- Full `npm run test:operator-browser`: **183 passed, 0 failed, 1 guarded skip**. The skipped case requires a header-anchored overlay only if one exists.
- Focused ExUnit shell/components/operator/inbound/voice/token/bundle set: **302 tests, 0 failures, 1 excluded**.
- Focused Plan04 acceptance cases: Quick view keyboard flow, exact-target confirmation flow, gallery hover/focus/touch-target matrix, Inbound and Preview error overflow, Account switching, and 120-cell gallery width/theme matrix passed.
- Demo route `/dev/mail/css-a5aa8f353f9543034287ed8382ce0e70` and `priv/static/app.css` both SHA-256 `b19d6219708e6f73b65dcf144db5483b2a848678ab95957deffea45bbc26e783`.
- Impeccable detection retained only existing findings: the legacy `border-l-4` tab treatment and existing Inter font declaration.

## Issues Encountered

- Full browser verification initially exposed six failures across Phase 168-shared UI; all reproduced Phase 168 regressions were corrected and the full suite then passed.
- The existing browser harness emitted its known Oban-unavailable and best-effort inbound-execution warnings.

## User Setup Required

None.

## Next Phase Readiness

Plan 168-04 is complete. Parent execution should run the whole-phase review and verifier before marking Phase 168 complete.

---
*Phase: 168-shared-workspace-and-usable-baseline*
*Plan: 04*
*Completed: 2026-10-07*

## Self-Check: PASSED

The summary and all four rendered artifacts exist, and task commits `61abe36d`, `68ef9c25`, `70d67e57`, and `ae66da0b` are ancestors of HEAD.

## Post-Audit Confirmation

Code review WR-01/02 were fixed in `ed53da64`, including the shared modal focus hook and semantic Account links. Current full browser result: 184 passed, 0 failures, 1 guarded skip (185 discovered). Current full ExUnit result: 513 tests, 0 failures, 1 excluded; focused post-format browser confirmation: 8 passed. The source/served CSS hash is `c04faaedbf0bb15352be22f0afa040b7f87119a6a89f59e3d96c2012b6aa42b7`. See `168-BASELINE.md` and `168-REVIEW-FIX.md` for current evidence and remaining Partial/N/A criteria.
