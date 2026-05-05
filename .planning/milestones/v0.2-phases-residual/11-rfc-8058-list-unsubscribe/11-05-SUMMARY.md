---
phase: 11-rfc-8058-list-unsubscribe
plan: 05
subsystem: tooling
tags: [mix-task, unsubscribe, phoenix-router, tdd]
requires:
  - phase: 11-01
    provides: compliance config accessors and unsubscribe endpoint contract
  - phase: 11-04
    provides: unsubscribe router macro and route collision semantics
provides:
  - read-only `mix mailglass.gen.unsubscribe` checklist output
  - router preflight guidance derived from loaded Phoenix routes
  - generator tests for strict CLI parsing, zero-write behavior, and checklist content
affects: [UNSUB-04, adopter-setup, install-guides]
tech-stack:
  added: []
  patterns: [strict mix task parsing, read-only checklist generators, router reflection preflight]
key-files:
  created:
    - lib/mix/tasks/mailglass.gen.unsubscribe.ex
    - test/mix/tasks/mailglass.gen.unsubscribe_test.exs
  modified:
    - lib/mix/tasks/mailglass.gen.unsubscribe.ex
    - test/mix/tasks/mailglass.gen.unsubscribe_test.exs
key-decisions:
  - "Kept `mix mailglass.gen.unsubscribe` strictly read-only and terminal-output only."
  - "Used loaded router `__routes__/0` reflection for preflight reporting so warnings match the runtime route contract."
patterns-established:
  - "Checklist tasks in mailglass fail loudly on unknown args and positional input."
  - "Read-only installer guidance can validate router state without mutating adopter files."
requirements-completed: [UNSUB-04]
duration: 4min
completed: 2026-04-28
---

# Phase 11 Plan 05: Read-Only Unsubscribe Generator Summary

**Read-only `mix mailglass.gen.unsubscribe` checklist with strict CLI parsing, canonical router instructions, and live route-preflight guidance**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T09:44:00Z
- **Completed:** 2026-04-28T09:48:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `mix mailglass.gen.unsubscribe` as a no-copy checklist task sourced from the runtime compliance config.
- Printed the canonical router contract `import Mailglass.Router` plus `mailglass_router_routes "/mailglass"` with `/mailglass/unsubscribe/:token`.
- Added generator coverage for strict CLI misuse, zero-write behavior, route preflight output, and concrete GET/POST UAT guidance.

## Task Commits

Each task was committed atomically through the TDD red/green flow:

1. **Task 1: Implement the read-only unsubscribe checklist task** - `08dba6f` (`test`), `bf9dbce` (`feat`)
2. **Task 2: Prove zero-write behavior and route preflight warnings** - `cdf2145` (`test`), `8eb762f` (`fix`)

## Files Created/Modified
- `lib/mix/tasks/mailglass.gen.unsubscribe.ex` - Read-only unsubscribe checklist task with config snippets, router instructions, UAT steps, DKIM reminder, and route reflection preflight.
- `test/mix/tasks/mailglass.gen.unsubscribe_test.exs` - TDD coverage for output contract, strict CLI parsing, zero-write behavior, and route preflight reporting.

## Decisions Made
- Kept the generator output-only even when preflight reporting was added; it never calls installer helpers or writes scaffolding.
- Reflected loaded Phoenix routers via `__routes__/0` instead of string-only heuristics so collision guidance stays aligned with the actual mounted path contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Tightened checklist wording to satisfy the no-copy contract**
- **Found during:** Task 2 (Prove zero-write behavior and route preflight warnings)
- **Issue:** The initial task output said "copies zero files" but did not state the stronger "intentionally copies zero files" contract the new tests enforce.
- **Fix:** Updated the checklist heading text in the generator so the read-only guarantee is explicit in the printed output.
- **Files modified:** `lib/mix/tasks/mailglass.gen.unsubscribe.ex`
- **Verification:** `mix test test/mix/tasks/mailglass.gen.unsubscribe_test.exs`
- **Committed in:** `8eb762f`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The adjacent output tweak was required to satisfy the stated read-only checklist contract. No broader scope creep.

## Issues Encountered
- The Task 2 router-success test had to compile its Phoenix router dynamically after setting `:compliance.mount_path`, because `mailglass_router_routes/2` validates the mount-path contract at compile time.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The unsubscribe setup assistant is now in place for adopter documentation and manual UAT flows.
- No blockers discovered for the remaining Phase 11 plans.

## Self-Check: PASSED

- Verified files exist: `lib/mix/tasks/mailglass.gen.unsubscribe.ex`, `test/mix/tasks/mailglass.gen.unsubscribe_test.exs`, `.planning/phases/11-rfc-8058-list-unsubscribe/11-05-SUMMARY.md`
- Verified commits exist: `08dba6f`, `bf9dbce`, `cdf2145`, `8eb762f`
