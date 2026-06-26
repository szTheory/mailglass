---
phase: 110-primitives
plan: "01"
subsystem: ui
tags: [phoenix-liveview, phoenix-component, tailwind, daisyui, accessibility]

requires:
  - phase: 109-foundations-gate-tightening
    provides: "Semantic focus rings, target-size utilities, system-theme boundary, and clean conformance gates"
provides:
  - "Public MailglassAdmin.Components primitive API for nav_link, nav_pill, tenant_chip, theme_picker, and stat_card"
  - "Native three-choice theme picker radio contract with optional shell event/value passthrough"
  - "Focused primitive component tests covering state, a11y, and severity contracts"
  - "Rebuilt committed admin CSS bundle for new primitive class strings"
affects: [phase-110, phase-112, phase-113, mailglass_admin, admin-design-system]

tech-stack:
  added: []
  patterns:
    - "Phoenix.Component public primitives with attr declarations and closed atom values"
    - "Disabled navigation primitives render inert markup with aria-disabled and no LiveView navigation"
    - "Stat severity is icon plus visible label plus semantic color"

key-files:
  created:
    - .planning/phases/110-primitives/110-01-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Theme picker exposes an `event` attr that renders per-option `phx-click` plus `phx-value-theme` values; persistence and no-FOUC remain downstream scope."
  - "Theme choices are native radios with closed atom values `:system`, `:light`, and `:dark`; no `aria-pressed`, storage, hook, or explicit `data-theme=\"system\"` behavior was introduced."
  - "Stat-card severity uses the existing vendored Heroicons inventory rather than adding new icons in Plan 110-01."

patterns-established:
  - "Public primitives live in MailglassAdmin.Components before downstream shell/gallery/stat migrations."
  - "Primitive contract tests assert component markup directly with Phoenix.LiveViewTest.render_component/2."
  - "CSS bundle updates stay committed whenever new HEEx class strings enter the admin package."

requirements-completed: [PRIM-01, PRIM-02, PRIM-03, PRIM-04, PRIM-05, PRIM-07]

duration: 8 min
completed: 2026-06-18
status: complete
---

# Phase 110 Plan 01: Primitive API Summary

**Public admin primitives now live in `MailglassAdmin.Components` with structural contracts and a clean rebuilt CSS bundle.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-18T20:04:14Z
- **Completed:** 2026-06-18T20:12:16Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added public `nav_link/1`, `nav_pill/1`, `tenant_chip/1`, `theme_picker/1`, and `stat_card/1` functions with explicit Phoenix `attr` declarations.
- Locked disabled nav behavior at the primitive: `aria-disabled="true"` and no LiveView navigation attribute.
- Implemented `theme_picker/1` as a native `fieldset`/`legend` radio group with exactly system/light/dark values and optional `set_theme` event/value passthrough.
- Implemented `stat_card/1` with truncating titled labels, tabular no-wrap values, and closed severity states with icon plus visible label plus semantic color.
- Added focused component tests for active/current, inactive, disabled, hover-ready, focus-visible, long-content, selected/checked, empty, loading, unavailable, and severity contracts.
- Rebuilt and committed `mailglass_admin/priv/static/app.css` for the new primitive class strings.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add public primitive component functions** - `0a6a51fe` (feat)
2. **Task 2: Add component contracts and rebuild the CSS bundle** - `483ffca5` (test)

**Plan metadata:** this summary commit

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/components.ex` - Public primitive functions plus helpers for nav, tenant chip, theme options, and stat-card severity/value rendering.
- `mailglass_admin/test/mailglass_admin/components_test.exs` - Focused component contracts for all five new public primitives.
- `mailglass_admin/priv/static/app.css` - Rebuilt Tailwind/daisyUI bundle containing the new primitive utilities.
- `.planning/phases/110-primitives/110-01-SUMMARY.md` - Plan completion record.

## Decisions Made

- Used `event` as the primitive's optional shell event attr; when set to `set_theme`, every theme radio emits `phx-click="set_theme"` and its own `phx-value-theme`.
- Kept `theme_picker/1` strictly structural: no browser storage, cookie persistence, matchMedia behavior, LiveView hook, or explicit system theme attribute.
- Used existing vendored icons for `stat_card/1` severities (`minus-circle`, `question-mark-circle`, `check-circle`, `exclamation-triangle`, `x-circle`) to avoid expanding the icon bundle before Plan 110-04's icon-exists gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rendered stat-card loading state with explicit ARIA value**

- **Found during:** Task 2 (component contract tests)
- **Issue:** `aria-busy={true}` rendered as a bare attribute in the stat-card loading state, while the intended semantic contract is `aria-busy="true"`.
- **Fix:** Changed `stat_card/1` to render `aria-busy="true"` only for `state: :loading`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/components.ex`
- **Verification:** `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` passed 66 tests.
- **Committed in:** `483ffca5`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The fix tightened the planned loading-state semantics without expanding scope.

## Issues Encountered

- A one-off render probe initially called `render_component/2` at top level and failed because it is a macro. The check was rerun inside a temporary module and passed; no code change was needed for that probe issue.

## User Setup Required

None - no external service configuration required.

## Verification

- `rg -n 'def (nav_link|nav_pill|tenant_chip|theme_picker|stat_card)\(assigns\)|def (nav_link|nav_pill)\(%\{disabled: true\}' mailglass_admin/lib/mailglass_admin/components.ex` -> all public primitives and disabled nav clauses found.
- `rg -n 'hover-ready|focus-visible|loading|not applicable|phx-click|phx-value-theme|set_theme' mailglass_admin/test/mailglass_admin/components_test.exs` -> required contract markers found.
- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.`
- `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` -> 66 tests, 0 failures.
- `cd mailglass_admin && mix mailglass_admin.assets.build` -> success.
- `cd mailglass_admin && git diff --exit-code priv/static/` -> passed after committing the rebuilt bundle.

## Known Stubs

None.

## Self-Check: PASSED

- `mailglass_admin/lib/mailglass_admin/components.ex` exists.
- `mailglass_admin/test/mailglass_admin/components_test.exs` exists.
- `mailglass_admin/priv/static/app.css` exists.
- Commit `0a6a51fe` exists.
- Commit `483ffca5` exists.
- No tracked files were deleted by either task commit.
- No package manifest, recipient-facing email template, or brandbook token files changed.

## Next Phase Readiness

Ready for Plan 110-02 to migrate shell/stat consumers onto the public primitives and wire the theme picker through the public event/value contract without further edits to `components.ex`.

---
*Phase: 110-primitives*
*Completed: 2026-06-18*
