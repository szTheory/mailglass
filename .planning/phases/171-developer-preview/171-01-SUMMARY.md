---
phase: 171-developer-preview
plan: 01
subsystem: ui
tags: [phoenix-liveview, preview, renderer, documentation]
requires: []
provides:
  - "Mount-aware scenario selection that displays full active Mailable and scenario identity"
  - "Distinct setup guidance for undiscovered Mailables and Mailables without named scenarios"
  - "Preview documentation for named scenarios, discovery modes, host-owned route exposure, and renderer-only output"
affects: [171-02, 171-03, 171-04, preview]
actuals:
  tokens: 5434
  tasks: 2
  commits: 6
plan_head_before: fd563961a4891b268dfd2776c915279819e17476
plan_head_after: 66ed025a3ad753d9554172609c5a40a0a12524aa
tech-stack:
  added: []
  patterns:
    - "Keep URL selection constrained to existing atoms and discovered values."
    - "Show full selected identity with wrapping text in the compact disclosure."
key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/test/mailglass_admin/voice_test.exs
    - mailglass_admin/test/support/fixtures/mailables.ex
    - brandbook/copy/microcopy.md
    - guides/preview.md
key-decisions:
  - "Display the complete module path and scenario in the compact picker so narrow layouts retain the selected identity."
  - "Render discovery, missing-scenario, and discovery-error states separately with actionable copy for each."
  - "Treat a valid empty preview_props/0 list as a missing-scenario setup state."
  - "Describe Preview as Mailglass.Renderer output and keep route exposure under the host application's dev guard."
patterns-established:
  - "Use a real LiveView patch test to verify scenario selection, identity, and renderer output together."
requirements-completed: [PRVUX-01, PRVUX-03]
coverage:
  - id: D1
    description: "Selecting a discovered scenario updates the full active identity and renderer HTML through a mount-aware LiveView patch."
    requirement: PRVUX-01
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#patching to another discovered scenario updates identity and renderer HTML"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#compact picker exposes long non-ASCII scenario identity without truncation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Empty discovery and discovered Mailables without scenarios have separate setup guidance."
    requirement: PRVUX-01
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#empty branch renders locked copy and setup action without first Mailable CTA"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#discovered Mailables without scenarios point to preview_props setup"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#a valid empty scenario list uses the missing-scenario setup state"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview docs show the supported ordered scenario-to-assigns map and state host ownership of route exposure."
    verification:
      - kind: other
        ref: "guides/preview.md#Mount preview routes; guides/preview.md#Add preview props on a mailable"
        status: pass
    human_judgment: false
# Metrics
duration: 14min
completed: 2026-10-09
status: complete
---

# Phase 171 Plan 01: Developer Preview Summary

**The compact preview picker now identifies the selected Mailable and scenario in full, with renderer output and clear setup routes for both empty states.**

## Performance

- **Duration:** 14 minutes
- **Started:** 2026-10-09T13:25:23Z
- **Completed:** 2026-10-09T13:39:01Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added a LiveView click/patch journey that proves the selected scenario changes both active identity and `Mailglass.Renderer` HTML.
- Made the compact picker show and wrap the full Mailable module path and long non-ASCII scenario names.
- Split undiscovered Mailables, Mailables with no scenarios, and discovery errors into distinct states. The generator command is rendered as a code element.
- Corrected the guide to show ordered named scenarios with assigns maps, explain automatic and explicit discovery, and state that the host owns route exposure.
- Replaced the Mailable Success promise of exact recipient output with renderer-stage wording.

## Task Commits

1. **Task 1: Select one named scenario and inspect its renderer HTML**
   - `32527d76` — RED: selection identity and wrapping assertions
   - `97b7281a` — GREEN: full identity in compact picker
2. **Task 2: Give each absent-scenario state a specific setup route**
   - `4c62f3d0` — RED: separate setup state and code-markup assertions
   - `a3320511` — GREEN: setup states, guide, and canonical copy
   - `d6b1194c` — RED: valid empty `preview_props/0` list regression case
   - `66ed025a` — Rule 2 fix: route empty scenario lists to setup guidance

**Plan metadata:** Captured by the required completion commit.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` — full active identity and wrapping classes.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — distinct discovery and setup states.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` — scenario patch, long identity, and setup-state evidence.
- `mailglass_admin/test/mailglass_admin/voice_test.exs` — code-element assertion for the generator command.
- `mailglass_admin/test/support/fixtures/mailables.ex` — long non-ASCII scenario fixture.
- `brandbook/copy/microcopy.md` — renderer-stage Mailable success language.
- `guides/preview.md` — supported scenario callback and route/discovery guidance.

## Decisions Made

- The active picker identity includes the full module namespace, and uses wrapping styles instead of truncation or a title tooltip.
- A Mailable discovery error gets a separate error state; it is not presented as a missing-scenario setup task.
- Both a missing `preview_props/0` callback and a valid empty scenario list use the missing-scenario setup state.
- Preview documentation says the host's development-only guard owns route exposure; the route macro adds no environment enforcement or authorization.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Recognized valid empty scenario lists**
- **Found during:** Final verification of Task 2
- **Issue:** Discovery accepts `preview_props/0` returning `[]`, but the new setup branch recognized only the `:no_previews` sentinel and would show an empty discovery-error card.
- **Fix:** Route both `:no_previews` and an empty scenario list to the named-scenario setup guidance; add a fixture and regression assertion.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`, `mailglass_admin/test/mailglass_admin/preview_live_test.exs`, `mailglass_admin/test/support/fixtures/mailables.ex`
- **Verification:** Focused preview and voice suites pass (50 tests, 0 failures, 1 pre-existing excluded test).
- **Committed in:** `d6b1194c` (RED test) and `66ed025a` (fix)

**Total deviations:** 1 auto-fixed (Rule 2)

**Impact on plan:** The fix covers a valid discovery result shape that otherwise left authors without the planned setup guidance.

## Verification

- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` — 30 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --warnings-as-errors` — 50 tests, 0 failures, 1 pre-existing excluded test.

The default shell did not select the repository's available Elixir version. Setting `ASDF_ELIXIR_VERSION=1.18.4-otp-27` used the planned Elixir 1.18.4 runtime.

The suite reports one pre-existing excluded LiveReload log test at `mailglass_admin/test/mailglass_admin/voice_test.exs:113`; it remains recorded as open entry 48 in `.planning/WINDOWS.md` because its persistent-term logging prerequisite belongs to earlier work.

## Open Planning Assumptions

- `PRVUX-01` remains `unclassified` / `unresolved` in the SPEC-less edge probe. The selection and setup checks here follow the approved CONTEXT and UI-SPEC; this summary does not invent an edge classification.
- The host-owned route-exposure prohibition is resolved as test-tier: `router_test.exs` pins the development-only adopter guard, and the preview guide states the macro adds no environment enforcement or authorization.

## Next Phase Readiness

The selection-to-render path and setup states are ready for Plan 02's assigns editing work. No production route authorization is implied by this preview work.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `32527d76`, `97b7281a`, `4c62f3d0`, `a3320511`, `d6b1194c`, and `66ed025a` are ancestors of `HEAD`.
- The plan commit ledger measures six task commits from `fd563961a4891b268dfd2776c915279819e17476` through `66ed025a3ad753d9554172609c5a40a0a12524aa`.

---
*Phase: 171-developer-preview*
*Completed: 2026-10-09*
