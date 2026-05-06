---
phase: 39-inbound-package-foundation
plan: "01"
subsystem: api
tags: [elixir, inbound, router, mailbox, tdd]
requires:
  - phase: 38-release-proof-and-cutover-record
    provides: stable v1.0 baseline before the sibling inbound package contract work
provides:
  - stable MailglassInbound.InboundMessage public value object
  - thin inbound router DSL with compiled ordered route data
  - mailbox behaviour with locked public outcomes
affects: [Phase 40, Phase 41, mailglass_inbound]
tech-stack:
  added: [nimble_options]
  patterns: [plain public value object, thin macro DSL, pure matcher engine, explicit outcome validation]
key-files:
  created:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/lib/mailglass_inbound.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_message.ex
    - mailglass_inbound/lib/mailglass_inbound/router.ex
    - mailglass_inbound/lib/mailglass_inbound/router/route.ex
    - mailglass_inbound/lib/mailglass_inbound/router/matcher.ex
    - mailglass_inbound/lib/mailglass_inbound/mailbox.ex
    - mailglass_inbound/test/test_helper.exs
    - mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs
    - mailglass_inbound/test/mailglass_inbound/router_test.exs
    - mailglass_inbound/test/mailglass_inbound/mailbox_test.exs
  modified:
    - .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md
key-decisions:
  - "Keep InboundMessage as a plain normalized struct with no raw payload, replay, or mailbox execution fields."
  - "Compile router declarations into ordered %Route{} data and keep runtime matching in a pure matcher module."
  - "Treat mailbox raises, throws, and exits as execution failures outside the public outcome contract."
patterns-established:
  - "Inbound contracts mirror Mailglass.Message: stable value object first, persistence and evidence deferred behind internal boundaries."
  - "Router macros stay thin and validate into runtime-owned data rather than expanding side effects."
requirements-completed: [MODEL-01, ROUTE-01, MAILBOX-01]
duration: 38min
completed: 2026-05-06
---

# Phase 39 Plan 01: Inbound Contract Foundations Summary

**Normalized inbound message contract with ordered mailbox routing DSL and locked mailbox outcome surface for `mailglass_inbound`**

## Performance

- **Duration:** 38 min
- **Started:** 2026-05-06T15:25:00Z
- **Completed:** 2026-05-06T16:03:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Bootstrapped the minimal `mailglass_inbound` sibling package shell required to compile and test the Phase 39 public contract.
- Added a stable `%MailglassInbound.InboundMessage{}` struct with explicit normalized routing, provenance, body, timestamp, and attachment fields only.
- Implemented a thin router DSL, ordered `%Route{}` data, pure first-match matcher semantics, and a mailbox behaviour restricted to the approved public outcome classes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Bootstrap the minimal package shell and define the stable `InboundMessage` public struct** - `ce43a8a` (test), `bb0173f` (feat)
2. **Task 2: Implement the thin router DSL, pure matcher engine, and narrow mailbox behaviour** - `2455c88` (test), `47e6cf9` (feat)

**Plan metadata:** summary-only completion commit recorded separately because user scope excluded the usual `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` updates.

## Files Created/Modified

- `mailglass_inbound/mix.exs` - Minimal sibling package definition with the small dependency surface needed for contract testing.
- `mailglass_inbound/lib/mailglass_inbound.ex` - Package root with the stable `version/0` helper.
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` - Stable normalized inbound value object.
- `mailglass_inbound/lib/mailglass_inbound/router.ex` - Thin routing DSL that compiles declarations into ordered route data.
- `mailglass_inbound/lib/mailglass_inbound/router/route.ex` - Internal pure route struct.
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` - Runtime first-match routing engine.
- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` - Mailbox behaviour and public outcome validator.
- `mailglass_inbound/test/test_helper.exs` - ExUnit bootstrap for the sibling package.
- `mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs` - Wave 0 contract proof for the public inbound struct.
- `mailglass_inbound/test/mailglass_inbound/router_test.exs` - Contract proof for ordered route compilation and matching semantics.
- `mailglass_inbound/test/mailglass_inbound/mailbox_test.exs` - Contract proof for mailbox callback shape and valid outcomes.

## Decisions Made

- Used envelope-recipient matching as the first-class recipient routing input so adopters do not depend solely on visible `To` headers.
- Normalized headers as `%{String.t() => [String.t()]}` to support exact and regex header matching without leaking provider payload shape.
- Added `MailglassInbound.Mailbox.valid_outcome?/1` as the narrow runtime guard for the four allowed mailbox results while leaving execution failure handling to later internal runners.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched package dependencies so the new sibling package could execute tests**
- **Found during:** Task 1 (Bootstrap the minimal package shell and define the stable `InboundMessage` public struct)
- **Issue:** `mix test` could not run because `nimble_options` was not fetched for the new package.
- **Fix:** Ran `mix deps.get` inside `mailglass_inbound`, used the generated dependencies for verification, and removed generated `_build/`, `deps/`, and `mix.lock` artifacts afterward because they were outside the approved write scope.
- **Files modified:** none committed
- **Verification:** `mix test test/mailglass_inbound/inbound_message_test.exs --warnings-as-errors`
- **Committed in:** n/a (local verification-only step)

**2. [Rule 1 - Bug] Normalized macro inputs before validating router declarations**
- **Found during:** Task 2 (Implement the thin router DSL, pure matcher engine, and narrow mailbox behaviour)
- **Issue:** The initial `route/2` macro validated alias and regex AST nodes instead of concrete module and matcher values, causing compile-time failures for valid route declarations.
- **Fix:** Expanded the mailbox alias and evaluated literal route option values before running `NimbleOptions` validation.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/router.ex`
- **Verification:** `mix test test/mailglass_inbound/router_test.exs test/mailglass_inbound/mailbox_test.exs --warnings-as-errors`
- **Committed in:** `47e6cf9`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were necessary to make the scoped package compile and to preserve the narrow router contract described in the plan. No user-facing scope creep.

## Issues Encountered

- The local `gsd-sdk query init.execute-phase` entrypoint described by the executor workflow was unavailable in this environment, so execution used the checked-in plan and context files directly.
- User scope restricted writes to the package files and this summary, so `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` were intentionally not modified even though the generic workflow would normally update them.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 40 can build provider ingress and storage work on top of a stable public `InboundMessage`, router, and mailbox contract.
- Remaining planning metadata updates were deferred because they fell outside the approved write scope for this execution.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md`.
- Task commits verified in git history: `ce43a8a`, `bb0173f`, `2455c88`, `47e6cf9`.
- Verification rerun after package-local bootstrap:
  - `cd mailglass_inbound && mix deps.get`
  - `cd mailglass_inbound && mix test test/mailglass_inbound/inbound_message_test.exs --warnings-as-errors`
  - `cd mailglass_inbound && mix test test/mailglass_inbound/router_test.exs test/mailglass_inbound/mailbox_test.exs --warnings-as-errors`

---
*Phase: 39-inbound-package-foundation*
*Completed: 2026-05-06*
