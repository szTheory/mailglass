---
phase: 15-mailgun-webhook-provider
plan: 01
subsystem: webhook
tags: [mailgun, webhook, ets, replay, testing]
requires:
  - phase: 04-webhook-foundation
    provides: webhook provider behaviour, signature error contract, ingest pipeline
provides:
  - Mailgun Wave 0 provider and plug test targets for downstream verification
  - Replay-aware webhook provider contract allowing idempotent replay success
  - Supervised ETS replay cache for Mailgun token deduplication
affects: [webhook, mailgun, provider-ingest, application-supervision]
tech-stack:
  added: []
  patterns: [supervised ets table owner, replay-safe provider verification contract]
key-files:
  created:
    - test/mailglass/webhook/providers/mailgun_test.exs
    - test/mailglass/webhook/plug_mailgun_test.exs
    - lib/mailglass/webhook/providers/mailgun_replay_cache.ex
    - lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex
    - lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex
  modified:
    - lib/mailglass/webhook/provider.ex
    - lib/mailglass/application.ex
key-decisions:
  - "Kept replay handling at the provider contract boundary by widening `verify!/3` to `:ok | {:ok, :replay}` instead of adding Plug-specific branching."
  - "Implemented Mailgun replay defense as a supervised named ETS table using the existing table-owner pattern so protection is available at application boot."
patterns-established:
  - "Wave 0 verification files land before later plans reference them in automated checks."
  - "Replay caches in mailglass use `Mailglass.Clock.utc_now/0` and supervised ETS ownership instead of ad hoc process state."
requirements-completed: [MAILGUN-02]
duration: 3min
completed: 2026-04-28
---

# Phase 15 Plan 01: Mailgun Webhook Provider Summary

**Wave 0 Mailgun webhook scaffolds, replay-aware provider verification, and supervised ETS token deduplication**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-28T20:46:00-04:00
- **Completed:** 2026-04-28T20:48:52-04:00
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Created the Mailgun provider and plug test shells required by Phase 15 validation before later plans reference those files.
- Narrowed the webhook provider behaviour so Mailgun can signal idempotent replay as `{:ok, :replay}` without changing the Conn-free abstraction.
- Added a supervised Mailgun replay cache with named ETS ownership and application startup wiring.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Wave 0 Mailgun test scaffolds before implementation verification** - `6c5f464` (test)
2. **Task 2: Define the replay-aware provider contract** - `395c9cb` (feat)
3. **Task 3: Build the supervised Mailgun replay cache and wire it into the application** - `dfb0d16` (feat)

Additional auto-fix commit:

1. **Rule 3 fix: Keep Wave 0 scaffolds warning-clean under `--warnings-as-errors`** - `30ed9bd` (fix)

## Files Created/Modified
- `test/mailglass/webhook/providers/mailgun_test.exs` - Mailgun provider test scaffold with reserved verification, replay, and normalization describe blocks.
- `test/mailglass/webhook/plug_mailgun_test.exs` - Mailgun plug test scaffold with reserved replay, bad-signature, and route execution describe blocks.
- `lib/mailglass/webhook/provider.ex` - Replay-aware provider callback contract for `verify!/3`.
- `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` - ETS-backed Mailgun replay cache API with `check_and_put/2`, `reset/0`, and `table/0`.
- `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` - Single-child supervisor for the Mailgun replay cache table owner.
- `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` - Named ETS table owner for `:mailglass_webhook_mailgun_replay_cache`.
- `lib/mailglass/application.ex` - Application child wiring for the Mailgun replay cache supervisor.

## Decisions Made
- Kept the behaviour change limited to the `verify!/3` return type so downstream replay handling remains explicit without broadening the provider abstraction.
- Matched the existing ETS ownership style already used in mailglass instead of introducing a new cache lifecycle primitive.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed unused aliases from empty Mailgun test shells**
- **Found during:** Task 3 (Build the supervised Mailgun replay cache and wire it into the application)
- **Issue:** The Wave 0 test scaffolds compiled with unused aliases, which caused the plan’s required `mix test ... --warnings-as-errors` verification to abort.
- **Fix:** Removed the placeholder aliases while preserving the describe block structure for later plans.
- **Files modified:** `test/mailglass/webhook/providers/mailgun_test.exs`, `test/mailglass/webhook/plug_mailgun_test.exs`
- **Verification:** `mix test test/mailglass/webhook/providers/mailgun_test.exs --warnings-as-errors`
- **Committed in:** `30ed9bd`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The fix was required to keep the Wave 0 scaffolds compatible with the plan’s validation contract.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Mailgun-specific test targets now exist for the provider and plug plans that follow.
- Replay-safe verification infrastructure is in place for the Mailgun provider implementation and later plug-level `200` replay handling.

## Self-Check: PASSED
- Verified summary and implementation files exist on disk.
- Verified task and deviation commit hashes exist in git history.

---
*Phase: 15-mailgun-webhook-provider*
*Completed: 2026-04-28*
