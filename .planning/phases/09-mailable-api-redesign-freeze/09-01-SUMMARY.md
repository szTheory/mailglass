---
phase: "09"
plan: "01"
subsystem: "mailable-api"
tags:
  - "api-redesign"
  - "swoosh"
  - "deprecations"
dependencies:
  requires: []
  provides:
    - "Native Mailglass.Message setters"
  affects:
    - "Mailglass.Message public surface"
tech_stack:
  added:
    - "igniter"
  patterns:
    - "Native Setter Pattern (proxying to Swoosh)"
key_files:
  modified:
    - "mix.exs"
    - "lib/mailglass/message.ex"
    - "test/mailglass/message_test.exs"
metrics:
  tasks_completed: 3
  total_tasks: 3
  duration: "10m"
key_decisions:
  - "Introduced Message.build/2 internally to sidestep the deprecation warning on Message.new/2."
---

# Phase 09 Plan 01: Mailable API native field setters Summary

Added 8 native field setters on `Mailglass.Message` to provide a clean API surface for adopters.

## Deviations from Plan

**1. [Rule 3 - Refactoring] Internal usage of `Message.new` migrated to `Message.build`**
- **Found during:** Task 3
- **Issue:** Using `@deprecated` on `Message.new/2` causes the CI suite (`mix compile --warnings-as-errors`) to fail because the codebase heavily uses `Message.new/2` internally to mock or build messages for tests and internal layers.
- **Fix:** Renamed the body of `Message.new/2` to a private-ish `@doc false` function `Message.build/2`. `Message.new/2` delegates to `Message.build/2` and carries the `@deprecated` warning. Replaced `Message.new` with `Message.build` across internal implementation and test files.

## Known Stubs
None

## Self-Check: PASSED
- `mix.exs` contains `igniter`
- `lib/mailglass/message.ex` exports `to`, `from`, `subject`, `text_body`, `html_body`, `header`, `attach`, and `put_tag`.
- `new/2` is deprecated.
- Internal tests pass.
