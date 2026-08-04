---
phase: 149-first-send-contract-foundation
plan: "03"
subsystem: renderer contract
tags: [elixir, swoosh, premailex, floki, phoenix-liveview, rendering]
requires:
  - phase: 149-02
    provides: "Pure envelope/body preflight before rendering or outbound effects"
provides:
  - "Validated renderer configuration accessor for plaintext and CSS-inliner switches"
  - "Renderer-owned explicit-text, text-only, HTML-only, and CSS-inlining precedence"
  - "Automated direct, sync, monitored async, and LiveView preview parity evidence"
affects: [149-04, outbound, async-delivery, preview]
tech-stack:
  added: []
  patterns:
    - "Renderer reads validated Config.renderer/0 once and remains the only body/config transformation owner"
    - "Consumer parity tests inspect real Fake messages and LiveView artifacts while restoring application configuration"
key-files:
  created: []
  modified:
    - lib/mailglass/config.ex
    - lib/mailglass/renderer.ex
    - test/mailglass/renderer_test.exs
    - test/mailglass/outbound_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
key-decisions:
  - "Nonblank explicit plaintext is authoritative and preserved byte-for-byte; blank text is absent."
  - "The :none switch skips only Premailex; HEEx rendering and data-mg stripping remain mandatory."
patterns-established:
  - "Async renderer assertions wait for monitored Task.Supervisor completion through the established helper rather than sleeping."
requirements-completed: [FIRST-05, FIRST-06]
coverage:
  - id: D1
    description: "Direct rendering preserves authored Unicode plaintext, supports text-only mail, conditionally generates HTML-only plaintext, and honors the CSS switch."
    requirement: FIRST-05
    verification:
      - kind: unit
        ref: "test/mailglass/renderer_test.exs#render/2 body and switch contract"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sync Fake delivery, monitored async preparation, and LiveView preview consume the same renderer semantics."
    requirement: FIRST-06
    verification:
      - kind: integration
        ref: "mix test test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors"
        status: pass
      - kind: automated_ui
        ref: "cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
metrics:
  duration: 7m
  completed: 2026-08-02
status: complete
---

# Phase 149 Plan 03: First-Send Contract Foundation Summary

**Renderer-owned body precedence now preserves authored plaintext, supports text-only messages, and applies validated plaintext/CSS switches identically in direct, sync, async, and preview consumers.**

## Performance

- **Duration:** 7m
- **Started:** 2026-08-02T17:54:00Z
- **Completed:** 2026-08-02T18:01:00Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added `Mailglass.Config.renderer/0`, keeping renderer options validated through the existing configuration schema.
- Made `Mailglass.Renderer` preserve nonblank authored text exactly, pass text-only messages through without an HTML body, generate text only for eligible HTML-only mail, and skip only CSS inlining for `:none`.
- Proved body/config parity using direct unit tests, sync Fake records, monitored Task.Supervisor async records, and real LiveView HTML/Text tabs.

## Task Commits

1. **Task 1: Implement renderer-owned body precedence and switches** - `67d04d98` (test), `551c08a9` (feat)
2. **Task 2: Prove sync, async, and preview renderer parity** - `ea982169` (test)

## Files Created/Modified

- `lib/mailglass/config.ex` - Exposes validated renderer options.
- `lib/mailglass/renderer.ex` - Owns published body precedence and CSS dispatch.
- `test/mailglass/renderer_test.exs` - Covers Unicode, text-only, HTML-only, CSS, stripping, and direct error behavior.
- `test/mailglass/outbound_test.exs` - Inspects sync Fake output under renderer settings.
- `test/mailglass/outbound/deliver_later_test.exs` - Inspects monitored async Fake output without sleeps.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` - Exercises HTML/Text preview behavior with a renderer-parity fixture mailable.

## Decisions Made

- Explicit nonblank plaintext is preserved byte-for-byte, including Unicode/grapheme content; only blank text is eligible for generation.
- `css_inliner: :none` leaves authored CSS intact but never bypasses HEEx rendering or `data-mg-*` stripping.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Ran the admin preview test from its owning Mix project**
- **Found during:** Task 2
- **Issue:** The plan's single root `mix test` command cannot compile `mailglass_admin` tests because its `LiveViewCase` support module belongs to the nested Mix project.
- **Fix:** Kept the exact test file and assertions, but ran the core tests from the root and the preview test with `cd mailglass_admin`.
- **Verification:** Both commands passed; no test or production behavior was skipped.

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Verification was strengthened with the runnable per-project command; no scope expansion.

## Issues Encountered

The existing admin suite emits pre-existing Phoenix warnings for forms with `phx-change` and no `id`; the focused test suite still completed with 28 passing tests and no new warning introduced by this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 149-04 can rely on one renderer-owned configuration and body contract across all documented consumers.

## Self-Check: PASSED

- Confirmed task commits `67d04d98`, `551c08a9`, and `ea982169` exist.
- Confirmed all six modified implementation and test files exist.
