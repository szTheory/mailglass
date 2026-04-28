---
phase: 09-mailable-api-redesign-freeze
plan: 04
subsystem: api
tags: [elixir, mix, swoosh, stability, docs]

requires:
  - phase: 09-mailable-api-redesign-freeze
    provides: [Native Message setters, update_swoosh/2 escape hatch]
provides:
  - Enforced API stability script (mix mailglass.stability.check)
  - Documented v0.2 API freeze and deprecation policies
affects: [08-release-engineering-hardening, 10-stream-separation]

tech-stack:
  added: []
  patterns: [Custom Mix Tasks for CI verification, API Stability guarantees]

key-files:
  created:
    - lib/mix/tasks/mailglass.stability.check.ex
  modified:
    - docs/api_stability.md

key-decisions:
  - "Used source code scanning instead of Code.Typespecs API for the stability script to reliably detect Swoosh.Email.t() leaks."
  - "Declared update_swoosh/2 as the official escape hatch for advanced Swoosh functionality."
  - "Promised 'freeze-until-vNext' for the v0.2 milestone."

patterns-established:
  - "Script/Task Execution Pattern: Custom Mix tasks that exit with 1 on failure and 0 on success for CI gating."

requirements-completed: [API-06]

duration: 15min
completed: 2026-04-27
---

# Phase 09 Plan 04: Mailable API Redesign Freeze Summary

**Enforced v0.2 API stability via a CI script scanning for Swoosh type leaks and documented the official freeze policy.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-27T20:25:00Z
- **Completed:** 2026-04-27T20:40:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Implemented `mix mailglass.stability.check` to scan the `lib/mailglass` namespace for accidental exposure of `Swoosh.Email.t()` types, containing the engine's blast radius.
- Updated `docs/api_stability.md` with the v0.2 API freeze policy and deprecation rules.
- Explicitly documented `Mailglass.Message.update_swoosh/2` as the official escape hatch for advanced Swoosh-specific builder functionality.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add API Stability Script** - `1140f65` (feat)
2. **Task 2: Write api_stability.md v2** - `176e54a` (docs)

## Files Created/Modified
- `lib/mix/tasks/mailglass.stability.check.ex` - New Mix task enforcing API stability by checking for leaked Swoosh types in `@spec` and `@type` definitions.
- `docs/api_stability.md` - Updated to establish the v0.2 freeze policy, promise backward compatibility, and document the escape hatch.

## Decisions Made
- Scanned `.ex` source files with regex directly instead of using BEAM's `Code.Typespec.fetch_specs` / `Code.Typespec.fetch_types` because Elixir AST formatting for typespecs can hide string matches. Regex over source code is simpler, faster, and reliable for `@spec.*Swoosh.Email.t()`.
- Allowed explicit internal paths (`Mailglass.Adapters.*`, `Mailglass.Compliance`) and legacy/escape hatch functions (`new/2`, `update_swoosh/2`, `send/2`) to continue utilizing `Swoosh.Email.t()` as they either reside behind trust boundaries or are explicitly allowed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added Boundary usage to Mix Task**
- **Found during:** Task 1 (Add API Stability Script)
- **Issue:** Running `mix mailglass.stability.check` produced a compiler warning: `Mix.Tasks.Mailglass.Stability.Check is not included in any boundary`.
- **Fix:** Added `use Boundary, classify_to: Mailglass` to the top of the module.
- **Files modified:** `lib/mix/tasks/mailglass.stability.check.ex`
- **Verification:** Ran `mix mailglass.stability.check` again, which successfully compiled without the boundary warning.
- **Committed in:** `1140f65` (part of Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 Bug)
**Impact on plan:** Ensure code is clean and passes all compiler strictness checks. No scope creep.

## Issues Encountered
- `Code.Typespec.spec_to_quoted` proved complex and error-prone when trying to introspect BEAM chunks directly, so I utilized source code grep, which explicitly satisfies the plan's allowance: "scan either the BEAM chunks... or grep the generated documentation/source for any exposed Swoosh.Email.t()".

## Next Phase Readiness
- The public Mailable API is now officially frozen, documented, and machine-verified. Ready for Phase 10: Stream Separation.

---
*Phase: 09-mailable-api-redesign-freeze*
*Completed: 2026-04-27*

## Self-Check: PASSED
