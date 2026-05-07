---
phase: 39-inbound-package-foundation
plan: "02"
subsystem: database
tags: [elixir, ecto, postgres, inbound, replay]
requires:
  - phase: 39-inbound-package-foundation
    provides: stable public `MailglassInbound.InboundMessage`, router, and mailbox contracts from Plan 39-01
provides:
  - package-local canonical inbound record storage
  - raw evidence storage isolated from adopter-facing normalized truth
  - replay-run persistence that records mailbox outcomes and execution failures separately from fresh receive rows
affects: [Phase 40, Phase 41, mailglass_inbound]
tech-stack:
  added: [ecto_sql, uuidv7]
  patterns: [package-local repo facade, canonical-vs-evidence storage split, append-only replay lineage]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/schema.ex
    - mailglass_inbound/lib/mailglass_inbound/repo.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex
    - mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs
    - mailglass_inbound/test/mailglass_inbound/persistence_test.exs
    - mailglass_inbound/test/mailglass_inbound/replay_test.exs
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/mix.lock
    - .planning/phases/39-inbound-package-foundation/39-02-SUMMARY.md
key-decisions:
  - "Kept `%MailglassInbound.InboundMessage{}` as a plain public value object and moved all Ecto-backed truth into package-local `InboundRecord`, `InboundEvidence`, and `ReplayRun` schemas."
  - "Stored raw payload, raw MIME, raw headers, verification facts, parse warnings, and attachment blobs only on `InboundEvidence` so canonical rows stay normalized and tenant-safe."
  - "Normalized public mailbox outcomes into replay storage fields at the context boundary so replays are persisted as append-only execution truth, not as fresh receives."
patterns-established:
  - "Sibling-package persistence mirrors core schema/repo conventions locally instead of reaching across package boundaries for storage helpers."
  - "Replay lineage is expressed by separate rows linked to canonical records and evidence, never by mutating prior evidence or duplicating a new receive row."
requirements-completed: []
duration: 2min
completed: 2026-05-06
---

# Phase 39 Plan 02: Inbound Storage Foundation Summary

**Tenant-scoped canonical inbound storage, isolated raw evidence, and replay-run persistence for `mailglass_inbound`**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-06T06:19:36-04:00
- **Completed:** 2026-05-06T06:21:40-04:00
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added package-local `MailglassInbound.Schema` and `MailglassInbound.Repo` helpers plus an `InboundRecords` context for host-repo-backed persistence.
- Created normalized `InboundRecord` and raw `InboundEvidence` schemas with a single migration that keeps every row tenant-scoped and all foreign keys package-local.
- Added `ReplayRun` storage and context normalization so public mailbox outcomes and execution failures are recorded as append-only replay truth linked to stored evidence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create package-local canonical and evidence persistence boundaries** - `bf05d21` (test), `2e6a6d1` (feat)
2. **Task 2: Record replay lineage as append-only execution truth, not fresh receive truth** - `5803378` (test), `409d2a7` (feat)

**Plan metadata:** summary-only closeout recorded here because the approved write scope excluded the normal `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` updates.

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/schema.ex` - local schema stamping for binary UUID keys and UTC microsecond timestamps.
- `mailglass_inbound/lib/mailglass_inbound/repo.ex` - host-repo resolver for the sibling package using `config :mailglass_inbound, :repo`.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` - small persistence context for canonical rows, evidence rows, and replay runs.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` - normalized canonical inbound schema with adopter-facing truth only.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex` - raw evidence schema for payloads, raw headers, raw MIME, verification facts, parse warnings, and attachment blobs.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex` - replay execution history schema linked to both canonical record and stored evidence.
- `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs` - package-local DDL for canonical, evidence, and replay tables plus package-owned indexes and foreign keys.
- `mailglass_inbound/test/mailglass_inbound/persistence_test.exs` - tenant, boundary, migration, and repo-facade contract coverage.
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs` - replay linkage, mailbox-outcome normalization, and append-only context coverage.
- `mailglass_inbound/mix.exs` - compile-only scope exception to add `ecto_sql` and `uuidv7` so the sibling package can build its persistence layer.
- `mailglass_inbound/mix.lock` - sibling-package lockfile for the new persistence dependencies.

## Decisions Made

- Reused the core package’s schema and repo conventions locally instead of sharing the core modules directly, preserving the sibling-package storage boundary.
- Kept replay persistence separate from canonical receives and evidence, with explicit `inbound_record_id` and `inbound_evidence_id` links on every replay row.
- Let the context normalize mailbox outcomes like `{:reject, reason}` and execution failures into storage fields so the table shape stays stable and later runners can record outcomes consistently.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing Ecto dependencies to the sibling package**
- **Found during:** Task 1 (Create package-local canonical and evidence persistence boundaries)
- **Issue:** `mailglass_inbound` Plan 39-01 scaffolding did not yet depend on `ecto_sql` or `uuidv7`, so the new persistence schemas and migration could not compile.
- **Fix:** Updated `mailglass_inbound/mix.exs`, generated `mailglass_inbound/mix.lock`, and reran `mix deps.get` so the scoped storage modules could compile.
- **Files modified:** `mailglass_inbound/mix.exs`, `mailglass_inbound/mix.lock`
- **Verification:** `cd mailglass_inbound && mix test test/mailglass_inbound/persistence_test.exs --warnings-as-errors`
- **Committed in:** `2e6a6d1`

**2. [Rule 1 - Bug] Normalized public mailbox outcomes into replay storage attrs**
- **Found during:** Task 2 (Record replay lineage as append-only execution truth, not fresh receive truth)
- **Issue:** `InboundRecords.change_replay_run/1` initially expected pre-normalized storage fields, so a public outcome like `{:reject, "spam"}` failed validation instead of being recorded as replay truth.
- **Fix:** Added replay attr normalization in `MailglassInbound.InboundRecords` for `:accept`, `:ignore`, `{:reject, reason}`, `{:bounce, reason}`, and `:execution_failure` inputs.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`
- **Verification:** `cd mailglass_inbound && mix test test/mailglass_inbound/replay_test.exs --warnings-as-errors`
- **Committed in:** `409d2a7`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were required to make the sibling package compile and to persist replay truth in the public mailbox outcome shapes the plan called for. No cross-package FK leakage or public-contract drift was introduced.

## Issues Encountered

- The generic executor workflow’s repo-wide state update steps were intentionally skipped because the user restricted this execution to the package write scope plus the scoped summary file.
- Package-local verification required temporary `mailglass_inbound/deps/` and `mailglass_inbound/_build/` directories from `mix deps.get` / `mix test`; those generated artifacts were not committed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 40 can build provider-specific ingress on top of a stable package-owned storage boundary that cleanly separates canonical rows, raw evidence, and replay lineage.
- Replay runners can now persist public mailbox outcomes and execution failures without conflating them with fresh provider receives.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/39-inbound-package-foundation/39-02-SUMMARY.md`.
- Task commits verified in git history: `bf05d21`, `2e6a6d1`, `5803378`, `409d2a7`.
- Verification rerun:
  - `cd mailglass_inbound && mix test test/mailglass_inbound/persistence_test.exs --warnings-as-errors`
  - `cd mailglass_inbound && mix test test/mailglass_inbound/replay_test.exs --warnings-as-errors`

---
*Phase: 39-inbound-package-foundation*
*Completed: 2026-05-06*
