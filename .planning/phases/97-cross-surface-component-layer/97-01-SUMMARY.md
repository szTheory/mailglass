---
phase: 97-cross-surface-component-layer
plan: "01"
subsystem: ui
tags: [tailwind, heex, daisy-ui, accessibility, wcag, focus-ring, orientation-strip]

requires:
  - phase: 96-research-dossier
    provides: STATE-LD-06 (focus ring gap), COPY-LD-11/12 (domain-noun copy corrections), STATE-LD-08 (theme_toggle btn-sm analysis)

provides:
  - nav_link with WCAG 2.4.7-compliant focus-visible ring using semantic ring-primary token
  - nav_pill with WCAG 2.4.7-compliant focus-visible ring using semantic ring-primary token
  - orientation_strip copy using domain nouns (Delivery, Suppression list, InboundMessage)
  - theme_toggle verified at 44px effective min-height (min-h-11 wins over btn-sm height)

affects:
  - 97-02 (components.ex uplift — same semantic ring-primary pattern)
  - 98-operator-surface (consumes corrected shell nav + orientation strip)
  - 99-inbound-surface (consumes InboundMessage copy)

tech-stack:
  added: []
  patterns:
    - "focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1 on static class string (never in conditional branch)"
    - "btn-sm sets height via --size CSS var; min-h-11 sets min-height — no conflict, min-height wins when larger"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex

key-decisions:
  - "ring-primary semantic token used (never ring-[#277B96] or ring-[#A6EAF2]) — resolves correctly per theme (Glass in light, Ice in dark per DARK-LD-03)"
  - "Focus ring classes added to static string, not inside if(@active, ...) branch — ring must appear in both active and inactive nav states"
  - "theme_toggle btn-sm kept: btn-sm sets height:32px via --size CSS var; min-h-11 sets min-height:44px — different properties, min-height 44px is the effective compiled height"

patterns-established:
  - "Focus ring placement: on static class string only, never inside conditional branch"
  - "Domain-noun copy enforcement: Delivery not Email; Suppression list not suppressions; InboundMessage not Message"

requirements-completed:
  - COMP-01
  - COMP-02

duration: 5min
completed: "2026-06-14"
---

# Phase 97 Plan 01: Shell Component Uplift Summary

**WCAG 2.4.7 focus rings added to nav_link and nav_pill via semantic ring-primary token; orientation_strip copy corrected to domain nouns (Delivery, Suppression list, InboundMessage)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-14T15:53:49Z
- **Completed:** 2026-06-14T15:56:41Z
- **Tasks:** 3 (2 with code changes, 1 verification-only)
- **Files modified:** 1

## Accomplishments

- Added `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` to `nav_link` static class string (WCAG 2.4.7, STATE-LD-06)
- Added `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` to `nav_pill` static class string (WCAG 2.4.7, STATE-LD-06)
- Verified `theme_toggle` effective min-height is 44px: `btn-sm` sets `height` via `--size` CSS variable; `min-h-11` sets `min-height` — different properties, `min-height` wins; no code change needed
- Replaced three orientation strip copy strings with domain-noun forms per COPY-LD-11/12
- `mix compile --warnings-as-errors` clean after all changes

## Task Commits

1. **Task 1: Add focus-visible rings to nav_link and nav_pill** - `490108fa` (feat)
2. **Task 2: Verify theme_toggle min-h-11 compiled height** - no commit (verification-only, no change needed)
3. **Task 3: Replace orientation_strip copy with domain-noun strings** - `8513650d` (feat)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — nav_link + nav_pill focus rings; orientation_strip domain-noun copy

## Decisions Made

- **ring-primary semantic token (not arbitrary color):** Focus ring uses `ring-primary` which resolves to Glass #277B96 in light and Ice #A6EAF2 in dark, per DARK-LD-03. This is the semantic token path — never hardcoded hex.
- **Focus ring on static string:** The three focus-visible classes are added to the static (non-conditional) part of the class list so the ring appears in both active and inactive nav states.
- **theme_toggle btn-sm retained:** daisyUI `btn-sm` sets `--size: calc(var(--size-field,.25rem)*8)` which drives `height: 2rem (32px)` via `.btn { height: var(--size) }`. Tailwind `min-h-11` sets `min-height: calc(var(--spacing)*11) = 2.75rem (44px)`. Since `min-height` takes precedence over `height` when larger, the effective compiled touch target is 44px. Dropping `btn-sm` is not needed.

## Deviations from Plan

None — plan executed exactly as written. Task 2 was a verification-only task by design (the plan stated "no change needed" if `min-h-11` wins), and that was confirmed via `app.css` analysis.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Task 1-3 of the plan are complete; shell.ex is uplifted
- nav_link and nav_pill now have WCAG 2.4.7-compliant focus rings using the project's semantic token
- orientation_strip copy uses domain nouns throughout
- Plan 97-02 (components.ex uplift) can proceed; the same `ring-primary` focus ring pattern applies

## Self-Check

- [x] `mailglass_admin/lib/mailglass_admin/operator/shell.ex` modified (verified via git log)
- [x] Commit `490108fa` exists (Task 1)
- [x] Commit `8513650d` exists (Task 3)
- [x] `grep -c "focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1"` = 2
- [x] `grep -c "aria-current"` = 2
- [x] 3 domain-noun copy strings present
- [x] 0 banned strings ("Email never arrived", "Check suppressions") remaining
- [x] `mix compile --warnings-as-errors` clean

## Self-Check: PASSED

---
*Phase: 97-cross-surface-component-layer*
*Completed: 2026-06-14*
