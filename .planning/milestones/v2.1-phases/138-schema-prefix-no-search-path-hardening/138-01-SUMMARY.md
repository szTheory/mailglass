---
phase: 138-schema-prefix-no-search-path-hardening
plan: 01
subsystem: database
tags: [ecto, postgres, schema-prefix, webhook-replay, unsubscribe, tdd]

requires:
  - phase: 132-137
    provides: v2.0 dedicated mailglass Postgres schema foundation and Repo.multi_opts/1 prefix helper
provides:
  - Hostile no-search-path runtime proofs for Webhook.Replay projection updates
  - Hostile no-search-path runtime proofs for unsubscribe idempotency conflict lookups
  - Explicit Repo.multi_opts() use at both raw callback call sites in this plan
affects: [138-schema-prefix-no-search-path-hardening, schema-prefix, webhook-replay, unsubscribe]

tech-stack:
  added: []
  patterns:
    - Raw Ecto.Multi callback repo calls touching mailglass tables pass Repo.multi_opts()
    - Hostile tests set Config.schema() to mailglass and force SET search_path TO public
    - Runtime hostile proofs are paired with source-contract assertions for explicit prefix opts

key-files:
  created:
    - test/mailglass/schema_prefix_hardening_test.exs
  modified:
    - lib/mailglass/webhook/replay.ex
    - lib/mailglass/compliance/unsubscribe_controller.ex

key-decisions:
  - "Use explicit per-operation Ecto prefix opts, not connection search_path, for raw callback repo calls."
  - "Pair hostile runtime tests with source-contract assertions because Ecto-loaded prefix metadata can mask missing raw callback opts in one replay path."

patterns-established:
  - "Hostile schema-prefix proof: migrate mailglass schema, insert configured-schema rows, force public search_path, assert configured-schema effects and public-schema non-targeting."
  - "Raw callback prefix contract: assign the query/changeset, then call repo.update/2 or repo.one!/2 with Repo.multi_opts()."

requirements-completed: [SCHEMA-01, SCHEMA-02]

duration: 9 min
completed: 2026-07-07
status: complete
---

# Phase 138 Plan 01: Core Hostile Runtime Proofs Summary

**Webhook replay and unsubscribe replay now prove configured-schema behavior under hostile search_path and use explicit raw callback prefix opts.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-07T13:24:29Z
- **Completed:** 2026-07-07T13:32:45Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments

- Added `Mailglass.SchemaPrefixHardeningTest` with `@moduletag :schema_prefix`, an inline `PrefixedWrapperMigration`, and focused hostile runtime coverage.
- Proved `Mailglass.Webhook.Replay.execute/1` replays a stored Postmark delivery while the active connection search_path is `public`, mutating `mailglass.mailglass_deliveries` and not `public.mailglass_deliveries`.
- Proved two unsubscribe POSTs for the same token leave exactly one configured-schema `:unsubscribed` event and zero public-schema events under the same hostile path.
- Updated both raw callback sites to pass `Repo.multi_opts()` inside their existing transaction callbacks.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Webhook replay hostile proof** - `e03c9c9e` (`test`)
2. **Task 1 GREEN: Webhook replay source fix** - `e3bcb67f` (`feat`)
3. **Task 2 RED: Unsubscribe conflict hostile proof** - `2574e1dd` (`test`)
4. **Task 2 GREEN: Unsubscribe conflict source fix** - `a9dcd9a9` (`feat`)

## Files Created/Modified

- `test/mailglass/schema_prefix_hardening_test.exs` - Hostile no-search-path runtime proofs plus explicit source-contract assertions for the two plan call sites.
- `lib/mailglass/webhook/replay.ex` - Extracts the replay projection changeset and calls `repo.update(changeset, Repo.multi_opts())`.
- `lib/mailglass/compliance/unsubscribe_controller.ex` - Extracts the conflict lookup query and calls `repo.one!(query, Repo.multi_opts())`.

## Decisions Made

- Keep explicit Ecto `prefix:` options as the correctness mechanism; do not alter connection search_path to fix runtime behavior.
- Keep the unsubscribe conflict lookup inside the existing transaction callback so lifecycle composition and idempotency semantics stay unchanged.
- Add source-contract assertions alongside hostile runtime checks because the replay path can pass at runtime through Ecto prefix metadata even before the explicit raw callback opts are present.

## Verification

- `MIX_ENV=test mix ecto.create -r Mailglass.TestRepo` - created the missing local test database needed to run the focused proof.
- `mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix --warnings-as-errors` - final result: 4 tests, 0 failures.
- `mix format --check-formatted test/mailglass/schema_prefix_hardening_test.exs lib/mailglass/webhook/replay.ex lib/mailglass/compliance/unsubscribe_controller.ex` - passed.
- Acceptance source checks confirmed `Repo.multi_opts()` at `repo.update/2` and `repo.one!/2` call sites.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Test Functionality] Added source-contract assertions**
- **Found during:** Task 1 RED
- **Issue:** The hostile replay runtime proof passed before the source fix because Ecto preserved prefix metadata on the loaded delivery struct, so the runtime test alone was not fail-closed for the explicit raw callback opts requirement.
- **Fix:** Added source-contract assertions for `repo.update(changeset, Repo.multi_opts())` and `repo.one!(query, Repo.multi_opts())` in the focused schema-prefix test file.
- **Files modified:** `test/mailglass/schema_prefix_hardening_test.exs`
- **Verification:** RED failed before each source fix; final focused test command passed.
- **Committed in:** `e03c9c9e`, `2574e1dd`

**2. [Rule 3 - Blocking] Created missing local test database**
- **Found during:** Task 1 RED verification
- **Issue:** The initial test run could not connect because local database `mailglass_test` did not exist.
- **Fix:** Ran `MIX_ENV=test mix ecto.create -r Mailglass.TestRepo`.
- **Files modified:** None
- **Verification:** Subsequent focused test runs reached the intended RED/GREEN gates.
- **Committed in:** Not applicable - environment setup only.

---

**Total deviations:** 2 auto-handled (1 missing critical test functionality, 1 blocking environment setup)
**Impact on plan:** Scope stayed within SCHEMA-01 and SCHEMA-02. The source-contract assertions make the plan stricter without changing product behavior.

## Issues Encountered

- Local test database was absent and was created with the explicit test repo.
- The test command emits an existing non-blocking OTLP exporter warning; it did not affect the focused schema-prefix proof.

## Known Stubs

None - no placeholder UI/data stubs were introduced.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commits present: `e03c9c9e`, `2574e1dd`
- GREEN commits present after RED: `e3bcb67f`, `a9dcd9a9`
- REFACTOR commits: none needed

## Next Phase Readiness

Ready for `138-02-PLAN.md`. The core hostile runtime proofs are in place, and the remaining Phase 138 plans can build the inbound raw-repo contract, static guard, and focused verification alias on top of this test lane.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/138-schema-prefix-no-search-path-hardening/138-01-SUMMARY.md`.
- Key files exist: `test/mailglass/schema_prefix_hardening_test.exs`, `lib/mailglass/webhook/replay.ex`, `lib/mailglass/compliance/unsubscribe_controller.ex`.
- Task commits exist: `e03c9c9e`, `e3bcb67f`, `2574e1dd`, `a9dcd9a9`.
- Final focused verification passed: `mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix --warnings-as-errors`.

---
*Phase: 138-schema-prefix-no-search-path-hardening*
*Completed: 2026-07-07*
