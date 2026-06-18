---
phase: 102-motion-micro-interaction-pass
plan: 02
subsystem: ui
tags: [css, motion, tailwind, phoenix-live-view, view-transitions, skeleton, animation]

# Dependency graph
requires:
  - phase: 102-01
    provides: MOTION-GATE in check-conformance.sh banning layout-property transitions and stray ease-in; Playwright reduced-motion structural assertion
  - phase: 96-research-dossier
    provides: MOTION-LD-01..14 locked decisions (ease-out only, transform/opacity only, tab-swap ease-symmetric exception)
provides:
  - --ease-symmetric CSS token aliasing --ease-in-out in @theme (MOTION-LD-05)
  - .motion-tab-swap now resolves through var(--ease-symmetric)
  - MOTION-LD-06 focus→--duration-instant / hover→--duration-fast resolution documented in :root
  - .mg-skeleton connection-state placeholder (opacity-only, no shimmer) with .phx-loading/.phx-connected selectors
  - @view-transition { navigation: auto } inside @media (prefers-reduced-motion: no-preference) PE block
  - Rebuilt priv/static/app.css bundle committed bit-clean
affects:
  - 102-03 (HEEx phx-remove exit work — MOTION-GATE stays green; .mg-skeleton available for use in templates)
  - 103-verification-closeout (bundle-clean gate, conformance gates, reduced-motion Playwright gate all green)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "--ease-symmetric as an alias token pattern: MOTION-LD-05 names a token that didn't exist; alias --ease-in-out under the dossier's name rather than forking or ignoring the dossier reference"
    - "phx-loading/phx-connected CSS class selectors for connection-state: LiveView 1.1.28 sets PHX_LOADING_CLASS/PHX_CONNECTED_CLASS as classList mutations on the container element (not body attributes); use .phx-loading/.phx-connected not [phx-loading]"
    - "@view-transition wrapped in prefers-reduced-motion: no-preference — required (not optional) because the global reduce @media block does not cover VT pseudo-elements"

key-files:
  created: []
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "phx-connected is a CSS class (not attribute) on the LiveView container element — confirmed against phoenix_live_view.js PHX_CONNECTED_CLASS/PHX_LOADING_CLASS (lines 82-83 in LV 1.1.28 runtime); use .phx-connected not [phx-connected] for skeleton hide selectors"
  - "--ease-symmetric aliasing --ease-in-out added to @theme; .motion-tab-swap switched to var(--ease-symmetric) (MOTION-LD-05). The dossier names a token that wasn't present in app.css; the reversible token-alias pattern resolves the mismatch without editing the locked dossier"
  - "MOTION-LD-06 resolution: focus rings bind to --duration-instant (90ms, satisfies ≤100ms ceiling); row background/color hover binds to --duration-fast (150ms). Different signals merit different timing."
  - ".mg-skeleton is a static connection-state placeholder with no shimmer/pulse — honest for a synchronous server-rendered LiveView where mount/3 assigns inline (no assign_async); .motion-reveal on content arrival is the primary 'settled into place' signal"
  - "@view-transition PE is inert for LiveView WS patches (live_patch/live_navigate do not trigger document navigation); visible only on hard navigations into /ops/mail or /dev/mail; no-ops on unsupported browsers (pre-Chrome 126, pre-Safari 18.2)"

patterns-established:
  - "Plan 102-02: CSS-only connection-state skeleton via LiveView phx-loading/phx-connected classes — no custom hook, no JS, framework-owned state"
  - "Plan 102-02: @view-transition PE scoped to no-preference media query so the global reduce block gap on VT pseudo-elements is covered at the rule level"

requirements-completed: [MOTION-01, MOTION-02]

# Metrics
duration: 4min
completed: 2026-06-16
---

# Phase 102 Plan 02: CSS Motion Token Uplift — ease-symmetric, skeleton, view-transitions, bundle rebuild

**--ease-symmetric token added (aliasing --ease-in-out), tab-swap crossfade resolved through it (MOTION-LD-05); .mg-skeleton opacity-only connection-state placeholder; @view-transition cross-document PE wrapped in prefers-reduced-motion: no-preference; bundle rebuilt bit-clean**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-16T17:07:13Z
- **Completed:** 2026-06-16T17:11:23Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `--ease-symmetric: var(--ease-in-out)` added to `@theme` — the single non-ease-out curve permitted (MOTION-LD-05 tab-swap exception); `.motion-tab-swap` switched from `var(--ease-out)` to `var(--ease-symmetric)` with inline comment naming MOTION-LD-05 and documenting that `ease-in`/`ease-in-out`/`--ease-symmetric` are the ONLY non-ease-out curves permitted
- MOTION-LD-06 resolution documented in `:root` duration block: `--duration-instant` (90ms) for focus rings (≤100ms WCAG target), `--duration-fast` (150ms) for row/hover state transitions; inline token comments updated
- `.mg-skeleton` connection-state placeholder added (opacity-only, no shimmer keyframe) with `.phx-loading .mg-skeleton { opacity: 1 }` and `.phx-connected .mg-skeleton { display: none }` — confirmed against LiveView 1.1.28 runtime that `phx-connected`/`phx-loading` are CSS **classes** on the container element (not body attributes)
- `@view-transition { navigation: auto }` added inside `@media (prefers-reduced-motion: no-preference)` — cross-document PE, inert for LV WS patches, commented with scope expectations
- Both conformance gates (`check-conformance.sh` + `check-conformance-advisory.sh`) clean; `priv/static/app.css` rebuilt and committed bit-clean; Playwright reduced-motion 4/4 pass

## Task Commits

1. **Task 1: Add --ease-symmetric token + point tab-swap at it; standardize focus-ring duration token** - `3aebc192` (feat)
2. **Task 2: Add connection-state loading skeleton + CSS-only View-Transitions PE; rebuild and commit bundle** - `a6d3a00a` (feat)

## Files Created/Modified

- `mailglass_admin/assets/css/app.css` — Added `--ease-symmetric` token to `@theme`; updated `.motion-tab-swap` to use it; added MOTION-LD-06 documentation to `:root` duration block; added `.mg-skeleton` skeleton rules; added `@view-transition` PE block; 38 lines added
- `mailglass_admin/priv/static/app.css` — Rebuilt compiled bundle (Tailwind v4.1.12 + daisyUI 5.5.19)

## Decisions Made

- **phx-connected is a CSS class, not an attribute:** LiveView 1.1.28 runtime uses `classList.add(PHX_CONNECTED_CLASS)` on the container element; the RESEARCH Assumption A1 used `[phx-connected]` (attribute selector form). The correct selectors are `.phx-connected` and `.phx-loading`. Confirmed by reading `phoenix_live_view.js` lines 82-83 and `setContainerClasses` at line 4302.
- **`--ease-symmetric` as an alias (not a new curve):** The dossier names `--ease-symmetric` for the tab-swap crossfade (MOTION-LD-05), but `app.css` only had `--ease-in-out`. Rather than silently re-using `--ease-in-out` or ignoring the dossier name, added `--ease-symmetric: var(--ease-in-out)` as an alias so the dossier reference resolves through the named token. Reversible, no breaking change, matches the RESEARCH Pitfall 4 recommendation.
- **Static skeleton, no shimmer:** The LiveViews render synchronously (mount/3 assigns inline, no assign_async). A pulsing shimmer over synchronous content would animate indefinitely over instantly-available data — dishonest and an infinite-animation reduced-motion risk. The static connection-state placeholder + `.motion-reveal` on content arrival is the correct idiom.

## Deviations from Plan

None — plan executed exactly as written. The one clarification (using `.phx-connected` class selector instead of `[phx-connected]` attribute selector) was explicitly anticipated as RESEARCH Assumption A1 and confirmed by reading the LV runtime before authoring selectors — consistent with the plan's instruction to "confirm the exact attribute/class form against the bundled phoenix_live_view.js before authoring CSS selectors."

## Issues Encountered

- Assumption A1 (`phx-connected` as attribute vs class): confirmed LiveView uses CSS classes (`classList.add`), not `setAttribute`. The class selector form `.phx-connected` is correct. No code was written before this was verified — plan instruction followed exactly.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 102-03: HEEx phx-remove exit attribute work on `operator_live.ex:466` and `inbound_live.ex:389`. MOTION-GATE will catch any layout-property transition violations. The `test.fixme` asymmetry assertion in `structural.spec.js` must be un-skipped as the closing task.
- All CSS motion token deliverables for MOTION-01/02 are complete; Plan 103 closeout gate will find conformance + reduced-motion + bundle-clean all green.

---
*Phase: 102-motion-micro-interaction-pass*
*Completed: 2026-06-16*

## Self-Check: PASSED

- `mailglass_admin/assets/css/app.css` — exists, contains `--ease-symmetric` (1 definition), `.motion-tab-swap` references `var(--ease-symmetric)`, `.mg-skeleton` present (3 occurrences), `@view-transition` present inside `no-preference` block
- `mailglass_admin/priv/static/app.css` — exists, rebuilt bit-clean (`git diff --exit-code priv/static/` exits 0 after rebuild)
- Commit `3aebc192` — Task 1 (feat: --ease-symmetric token + tab-swap + MOTION-LD-06 docs)
- Commit `a6d3a00a` — Task 2 (feat: .mg-skeleton + @view-transition + bundle rebuild)
- `scripts/check-conformance.sh` exits 0; `scripts/check-conformance-advisory.sh` exits 0
- Playwright reduced-motion: 4/4 pass
