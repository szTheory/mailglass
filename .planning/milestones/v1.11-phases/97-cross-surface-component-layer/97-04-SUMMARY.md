---
phase: 97-cross-surface-component-layer
plan: 04
subsystem: ui
tags: [daisyui, heex, phoenix-component, aria, status-badge, timeline, routing-trace, evidence-card]

# Dependency graph
requires:
  - phase: 97-cross-surface-component-layer
    provides: plan 01-03 component uplift context
provides:
  - Verified ARIA correctness on icon/logo/flash/badge/status_badge in components.ex
  - Verified all 22 status_badge atoms map to correct daisyUI badge class per STATE-LD-05
  - Verified motion-timeline container + highlighted event border-primary ring-1 ring-primary/40 in timeline.ex
  - Verified dot class dispatch: bg-error/bg-warning/bg-accent/bg-primary per STATE-LD-16
  - Verified routing_trace first-failing border-l-4 border-error + badge-outline badge-error (no changes needed)
  - Verified evidence_card reveal button min-h-11 effective 44px + revealed pre token class string
affects:
  - 97-05-PLAN
  - 97-07-PLAN (bundle rebuild)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "btn-sm + min-h-11 coexist: .btn uses height:var(--size), .min-h-11 sets min-height separately — min-h-11 wins the 44px floor"

key-files:
  created: []
  modified: []

key-decisions:
  - "All four target files already conform to STATE-LD-05/16/18/19 — no code changes required; verify pass complete"
  - "btn-sm + min-h-11 on evidence_card reveal button: min-h-11 wins because .btn uses height:var(--size) (separate CSS property from min-height); effective min-height is 44px"

patterns-established:
  - "Verify-then-fix pattern: read the spec, read the code, grep-check; only edit if wrong; compile to gate"

requirements-completed: [COMP-01, COMP-02, COMP-03]

# Metrics
duration: 7min
completed: 2026-06-14
---

# Phase 97 Plan 04: Verify-and-fix pass on components.ex, timeline.ex, routing_trace.ex, evidence_card.ex

**Verification-only outcome: all four target files already conform to STATE-LD-05/16/18/19 — no code changes needed, compile is clean.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-14T16:04:00Z
- **Completed:** 2026-06-14T16:11:22Z
- **Tasks:** 3
- **Files modified:** 0

## Accomplishments

- Confirmed all ARIA attributes correct in components.ex: icon has `aria-hidden="true"`, logo has `role="img"` + `aria-label="mailglass"`, flash has `role="status"` + `aria-live="polite"` + `motion-reveal`
- Confirmed all 22 status_badge atoms map to correct daisyUI class (badge-primary/badge-success/badge-warning/badge-error/badge-outline) with phantom fallback per STATE-LD-05
- Confirmed timeline.ex: `motion-timeline` on ol container, `event_container_class/2` returns `border-primary ring-1 ring-primary/40` for highlighted event, `event_dot_class/1` correctly dispatches all dot color groups per STATE-LD-16
- Confirmed routing_trace.ex: first-failing clause has `border-l-4 border-error px-3`, route badge has `badge-outline badge-error` (verify-only, no edits)
- Confirmed evidence_card.ex: reveal button has `min-h-11` which wins over `btn-sm` (btn-sm uses height:var(--size), not min-height — min-h-11 sets min-height:44px uncontested), revealed pre has full token class string including `max-h-80 overflow-auto rounded-box border border-base-300 bg-base-100`
- Compile clean: `mix compile --warnings-as-errors` exits 0

## Task Commits

This plan had no code changes — all files already conformed to spec. No task commits were produced.

**Plan metadata:** (see final commit hash below)

## Files Created/Modified

None — all target files passed verification without requiring edits.

## Decisions Made

- btn-sm + min-h-11 on `evidence_card.ex` reveal button: confirmed min-h-11 wins. The `.btn` daisyUI class sets `height: var(--size)` (not `min-height`); `.btn-sm` overrides `--size` to 2rem (32px); `.min-h-11` sets `min-height: 44px` which is a separate CSS property and overrides height. Effective rendered height is 44px — no change needed.

## Deviations from Plan

None — plan executed exactly as written. All four files passed verification without correction.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Known Stubs

None. All four files render real data from assigns; no placeholder or hardcoded empty values.

## Threat Flags

No new security-relevant surface was introduced (verify-only pass, no code changes).

## Next Phase Readiness

- Plans 97-04 verification complete; components.ex/timeline.ex/routing_trace.ex/evidence_card.ex all conform to the STATE-LD design contract
- Ready for plan 97-05 (shell.ex nav_link/nav_pill focus rings, theme_toggle, orientation_strip copy)

---
*Phase: 97-cross-surface-component-layer*
*Completed: 2026-06-14*
