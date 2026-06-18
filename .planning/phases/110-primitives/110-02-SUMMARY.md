---
phase: 110-primitives
plan: "02"
subsystem: ui
tags: [phoenix-liveview, phoenix-component, shell, theme-picker, stat-card]

requires:
  - phase: 110-primitives
    provides: "Plan 110-01 public primitive API for nav_link, nav_pill, tenant_chip, theme_picker, and stat_card"
provides:
  - "Operator shell consumers of public MailglassAdmin.Components primitives"
  - "Three-way shell theme picker event routing through URL patch helpers"
  - "Operator and inbound overview stat cards migrated to Components.stat_card/1"
  - "Focused shell tests for theme choice/path mapping and public picker event/value rendering"
affects: [phase-110, phase-112, phase-113, mailglass_admin, admin-design-system]

tech-stack:
  added: []
  patterns:
    - "Shell primitives are consumed through MailglassAdmin.Components, not private shell helpers"
    - "Theme picker uses URL-only LiveView patch semantics; system deletes the explicit theme query value"
    - "Overview KPI cards use Components.stat_card/1 with visible severity label plus semantic severity atom"

key-files:
  created:
    - .planning/phases/110-primitives/110-02-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/overview.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "The shell passes `event=\"set_theme\"` into the public `Components.theme_picker/1` and relies on component-rendered `phx-value-theme` values."
  - "Theme `system` remains absence of an explicit query value; `Shell.set_theme_path/2` removes `theme` while preserving unrelated query params."
  - "Operator and inbound overview runtime-missing stat values render `Unavailable` through `Components.stat_card/1`, not a bare glyph placeholder."
  - "Existing `dark_chrome` root-theme behavior remains unchanged; this plan only wires picker state and URL patches."

patterns-established:
  - "Public primitive consumers are covered by shell render tests plus grep gates."
  - "Stat-card migration preserves browser-test anchors through component global attrs."
  - "Admin CSS bundle is rebuilt and committed whenever HEEx class usage changes."

requirements-completed: [PRIM-01, PRIM-03, PRIM-04, PRIM-05]

duration: 8 min
completed: 2026-06-18
status: complete
---

# Phase 110 Plan 02: Primitive Consumers Summary

**Operator shell and overview surfaces now render public primitives with URL-only three-way theme selection and canonical stat cards.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-18T20:19:04Z
- **Completed:** 2026-06-18T20:26:39Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Replaced private shell `nav_link`, `nav_pill`, `tenant_chip`, and `theme_toggle` copies with `MailglassAdmin.Components` calls.
- Added `Shell.theme_choice/1` and `Shell.set_theme_path/2` with tests for system/light/dark mapping and query preservation.
- Added `set_theme` handlers in operator and inbound LiveViews while preserving the existing `dark_chrome` root behavior.
- Migrated all operator and inbound overview KPI/stat cards to `Components.stat_card/1`.
- Rebuilt and committed the admin CSS bundle after class usage changed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace private shell atoms with public component calls** - `5c2d6888` (feat)
2. **Task 2: Route shell theme picker events through existing URL patch semantics** - `d71bfa91` (feat)
3. **Task 3: Migrate overview stat cards to the canonical primitive** - `f4526333` (feat)

**Plan metadata:** this summary commit

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - Public primitive shell consumers plus deterministic theme choice/path helpers.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Operator `theme_choice` assign/event handling and canonical overview stat-card consumers.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - Inbound `theme_choice` assign/event handling.
- `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` - Inbound overview stat-card consumers with no page-local stat helper.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - Shell tests for active nav, theme mapping, path mapping, and picker event/value markup.
- `mailglass_admin/priv/static/app.css` - Rebuilt bundle reflecting changed class usage.

## Decisions Made

- Used the Plan 110-01 `event` attr as the public theme-picker event seam; shell consumers pass `set_theme` and do not render their own `phx-value-theme` options.
- Kept system theme as no explicit `theme` query value. `Shell.set_theme_path/2` deletes `theme` for `"system"` and writes `theme=light` or `theme=dark` for explicit choices.
- Preserved current `dark_chrome` behavior for root `data-theme`; Phase 112 still owns persistence, no-FOUC, and root/system behavior.
- Used `Unavailable` for runtime-missing overview stats, with visible severity labels on every `stat_card`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix mailglass_admin.assets.build` produced an expected `priv/static/app.css` delta after old overview class strings were removed. The rebuilt bundle was committed in Task 3 and the post-commit static diff check passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` -> 17 tests, 0 failures.
- `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` -> 83 tests, 0 failures.
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` -> 76 tests, 0 failures.
- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.`
- `cd mailglass_admin && mix mailglass_admin.assets.build` -> success.
- `cd mailglass_admin && git diff --exit-code priv/static/` -> passed after committing the rebuilt bundle.
- `rg -n 'Components\.stat_card' mailglass_admin/lib/mailglass_admin/operator_live.ex mailglass_admin/lib/mailglass_admin/inbound/overview.ex` -> all eight overview stat-card consumers found.
- Negative scan for private shell/stat helpers passed: no `defp nav_link`, `defp nav_pill`, `defp tenant_chip`, `defp theme_toggle`, or `defp stat` remains in the migrated files.

## Known Stubs

None.

## Self-Check: PASSED

- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` exists.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` exists.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` exists.
- `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` exists.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` exists.
- `mailglass_admin/priv/static/app.css` exists.
- Commit `5c2d6888` exists.
- Commit `d71bfa91` exists.
- Commit `f4526333` exists.
- No tracked files were deleted by task commits.
- No package manifest, recipient-facing email template, or brandbook token files changed.

## Next Phase Readiness

Ready for Plan 110-03 to migrate gallery specimens to the same public primitives and render the widened primitive state matrix.

---
*Phase: 110-primitives*
*Completed: 2026-06-18*
