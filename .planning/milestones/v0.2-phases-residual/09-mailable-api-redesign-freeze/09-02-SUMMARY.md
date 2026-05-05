---
phase: 09-mailable-api-redesign-freeze
plan: 02
subsystem: core
tags: [api-freeze, mailable, swoosh-removal]
requires: ["09-01"]
provides: ["Native Message setters in Mailable"]
affects: ["lib/mailglass/mailable.ex"]
tech-stack:
  added: []
  patterns: ["Macro Injection Pattern"]
key-files:
  created: []
  modified:
    - lib/mailglass/mailable.ex
    - test/mailglass/mailable_test.exs
key-decisions:
  - "D-22: Replaced Swoosh.Email import with Mailglass.Message in the Mailable macro, restricting to 8 native setters to prevent namespace pollution."
metrics:
  duration: 300
  completed: "2026-04-27T20:18:56Z"
---

# Phase 09 Plan 02: Update Mailable Macro Summary

Native Message setters injected into Mailable, removing Swoosh.Email dependency for adopters.

## Implementation Details

- Located `__using__/1` macro in `lib/mailglass/mailable.ex`.
- Removed `import Swoosh.Email, except: [new: 0]`.
- Added `import Mailglass.Message, only: [to: 2, from: 2, subject: 2, html_body: 2, text_body: 2, header: 3, attach: 2, put_tag: 2]`.
- Ensured AST budget (under 20 top-level forms) is maintained and passed LINT checks.
- Verified test `test/mailglass/mailable_test.exs` and updated internal manual AST count comment to reflect the new import logic.

## Deviations from Plan

None - plan executed exactly as written. (Noted and deferred pre-existing unrelated mix test `ERROR XX000 (internal_error)` failures via `deferred-items.md`).

## Threat Flags

None.

## Known Stubs

None.
## Self-Check: PASSED
