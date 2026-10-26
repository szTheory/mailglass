---
phase: 170-inbound-investigation-and-recovery
plan: "04"
subsystem: inbound-operator-read-model
tags: [elixir, ecto, inbound, tenancy, execution-history]

# Dependency graph
requires:
  - phase: 170-01
    provides: Tenant-scoped inbound selection and read-state contracts
  - phase: 170-02
    provides: Persisted explicit Mailbox :no_change outcome
provides:
  - Consistent latest-fresh disposition in inbound list and exact detail
  - Deterministic latest-fresh tie-breaking by ExecutionRun ID
  - Verified tenant-scoped chronological fresh and replay history
affects: [inbound-operator-ui, INUX-02, INUX-04]

# Actuals (#2632)
actuals:
  tokens: 3491
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Select the latest fresh ExecutionRun with a shared inserted_at-descending, ID-descending order."
    - "Keep historical fresh and replay rows separate from the current fresh disposition."
    - "Keep timeline projections tenant-scoped and limited to explicit historical facts."

key-files:
  created: []
  modified:
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex
    - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs

key-decisions:
  - "A later fresh failure or no-match is the record's current disposition even when an older fresh run matched."
  - "When fresh runs share inserted_at, the greatest ExecutionRun ID wins in both list and detail."
  - "The timeline remains a separate chronological history ordered by executed_at, inserted_at, then ID; replay never replaces fresh summary."
  - "No-change and ignore remain distinct stored outcomes; missing history stays nil/empty and does not imply no-change."

patterns-established:
  - "List and detail use the same tenant-scoped latest-fresh ordering and preserve Tenancy.scope/2 plus the configured Repo prefix."
  - "Timeline reads keep exact source, ID, and timestamps while omitting failure-map text."

requirements-completed: [INUX-02, INUX-04]

# Coverage metadata
coverage:
  - id: D1
    description: "List and exact detail use the same deterministic latest fresh disposition; newer failed/no-match runs replace older matches, replay stays separate, and missing history remains absent."
    requirement: INUX-02
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Detail.fetch/2 a later fresh failure replaces an older matched disposition"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Detail.fetch/2 a later fresh no-match replaces an older matched disposition"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Detail.fetch/2 missing history stays missing and replay does not replace fresh disposition"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Records.list_records/2 disposition projection (WR-01) a same-time tie chooses the fresh run with the greatest id"
        status: pass
    human_judgment: false
  - id: D2
    description: "The scoped timeline preserves fresh and replay source, outcome, IDs, and exact timestamps in chronological order, including same-time ID ties and empty history."
    requirement: INUX-02
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Timeline.list_runs/2 preserves exact source, outcome, ID and times with same-time ID ordering"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Timeline.list_runs/2 returns [] when a scoped record has no execution history"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Timeline.list_runs/2 does not return another tenant's runs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The persisted :no_change outcome remains distinguishable from :ignore in both the current detail disposition and chronological history."
    requirement: INUX-04
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Detail.fetch/2 missing history stays missing and replay does not replace fresh disposition"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#test Timeline.list_runs/2 preserves exact source, outcome, ID and times with same-time ID ordering"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-10-09
status: complete
---

# Phase 170 Plan 04: Latest-fresh disposition and chronological lineage

**Inbound list and detail now agree on the latest fresh execution, while the timeline preserves scoped historical fresh and replay facts.**

## Performance

- **Duration:** 8 min.
- **Started:** 2026-10-09T02:28:11Z.
- **Completed:** 2026-10-09T02:36:43Z.
- **Tasks:** 2.
- **Files modified:** 4 implementation and test files.

## Accomplishments

- Removed Detail's preference for any older matched fresh run. A newer failure or no-match now replaces that current disposition in exact detail, matching the list projection.
- Added a UUID ID tie-breaker after `inserted_at` in both latest-fresh queries so list and detail choose the same row deterministically.
- Verified that replay rows do not replace fresh disposition; absent history remains nil in detail and an empty timeline; explicit `:no_change` stays distinct from `:ignore`.
- Verified the existing timeline's tenant predicate, `Tenancy.scope/2`, Repo prefix, ascending `executed_at`/`inserted_at`/ID ordering, source and timestamp projection, and lack of failure-map output. No timeline query change was needed.

## Task Commits

1. **Task 1 RED / Task 2 regression fixtures:** `8d77101b` (`test(170-04): pin latest-fresh disposition and timeline contracts`). The focused run discovered 39 tests and failed the two named latest-fresh detail cases; GSD classified the persisted JUnit evidence as `RED_EVIDENCE_OK`. The semantic assessment and unmodified report are stored under `artifacts/tdd-red/`.
2. **Task 1 GREEN:** `c4e7b2f8` (`fix(170-04): align inbound detail with latest fresh run`).

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex` — exact detail now returns only the latest fresh run's disposition.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` — added the deterministic ID tie-breaker to the correlated latest-fresh projection.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex` — clarified the already implemented chronological ordering.
- `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs` — added latest-fresh, tie, replay, no-history, no-change/ignore, and exact timeline regression cases.

## Deviations from Plan

The planned `detail_test.exs` and `timeline_test.exs` files do not exist in this repository. Both read models already have focused coverage inside `records_test.exs`, so the tests and plan file lists were aligned with that established suite instead of adding duplicate fixture setup or a test dependency. Timeline behavior was already correct; regression tests were added, but no query change was necessary.

**Total deviations:** 1 test-organization correction; no product-scope or dependency change.

## Issues Encountered

- The focused tests used the pinned Erlang/Elixir toolchain with `--no-deps-check` because the local Dialyxir checkout still differs from the lockfile, as recorded in Plan 170-02. No dependency declarations or lockfiles changed.

## User Setup Required

None.

## Next Plan Readiness

- Plan 170-05 is the next plan; Plans 170-01 and 170-02 satisfy its listed prerequisites.
- INUX-02 and INUX-04 remain pending at phase level because sibling plans also own deliverables for those requirements; the readiness gate reports `0/2` IDs ready to mark complete.
- Admin presentation of execution history and truthful recovery controls continues in Plan 170-05.

## Self-Check: PASSED

- RED evidence was classified `RED_EVIDENCE_OK`; the stale matched-run behavior is recorded as the cause.
- Focused verification passed: 39 tests passed. Formatter check and `git diff --check` passed.
- Timeline coverage passed without changing the existing tenant-scoped chronological query.

---
*Phase: 170-inbound-investigation-and-recovery*
*Completed: 2026-10-09*
