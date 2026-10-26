---
phase: 170-inbound-investigation-and-recovery
plan: "02"
subsystem: inbound-execution
tags: [elixir, mailbox, replay, ecto, tenancy, docs-contract]

# Dependency graph
requires: []
provides:
  - Explicit Mailbox :no_change outcome accepted, normalized, persisted, and returned without changing :ignore or failure semantics
  - Tenant-scoped replay retains exact no-change lineage and refuses unbound legacy mailbox identities
affects: [inbound-replay, inbound-operator-docs, INUX-04]

# Actuals (#2632)
actuals:
  tokens: 4700
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Only an allowlisted literal callback atom becomes a semantic execution outcome."
    - "Legacy replay rows can be classified as matched history without resolving stored module names."

key-files:
  created: []
  modified:
    - mailglass_inbound/lib/mailglass_inbound/mailbox.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
    - mailglass_inbound/test/mailglass_inbound/mailbox_test.exs
    - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
    - mailglass_inbound/test/mailglass_inbound/replay_test.exs
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/docs/inbound-operator.md

key-decisions:
  - "Only a literal :no_change callback result asserts no mutation; :ignore, exceptions, and failed execution remain distinct."
  - "The additive outcome uses the existing text column and finite Ecto enums; no migration, dependency, or execution API change is needed."
  - "Replay keeps the existing tenant predicate and durable route-binding requirement when classifying no-change history."

patterns-established:
  - "Persist callback outcomes as append-only ExecutionRun facts through the existing normalization boundary."
  - "Lock adopter-facing outcome semantics with focused docs-contract assertions."

requirements-completed: [INUX-04]
coverage:
  - id: D1
    description: "An explicit no-change callback result round-trips through fresh execution and stays distinct from ignore, invalid returns, and failures."
    requirement: INUX-04
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/mailbox_test.exs#only the locked mailbox outcomes are treated as valid results"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs#persists an explicit no-change mailbox outcome without conflating ignore"
        status: pass
    human_judgment: false
  - id: D2
    description: "Replay appends and returns the explicit no-change result under the bound mailbox while preserving ignore and tenant isolation; unbound legacy mailbox history remains ineligible."
    requirement: INUX-04
    verification:
      - kind: integration
        ref: "mailglass_inbound/test/mailglass_inbound/replay_test.exs#appends and returns the explicit no-change result from the bound mailbox"
        status: pass
      - kind: integration
        ref: "mailglass_inbound/test/mailglass_inbound/replay_test.exs#recognizes a legacy no-change run as matched while refusing its unbound mailbox"
        status: pass
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/replay_test.exs#the legacy replay schema decodes an explicit no-change outcome"
        status: pass
    human_judgment: false
  - id: D3
    description: "The API stability contract and operator guide state that no-change is explicit and is not inferred from ignore or failure."
    requirement: INUX-04
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs#mailbox no-change docs require an explicit outcome and preserve ignore semantics"
        status: pass
    human_judgment: false

# Metrics
duration: 11 min
completed: 2026-10-09
status: complete
---

# Phase 170 Plan 02: Explicit Mailbox no-change through replay

**An explicit Mailbox :no_change result now persists through fresh execution and tenant-scoped replay with its source and prior outcomes intact.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-09T01:23:00Z
- **Completed:** 2026-10-09 01:34:52 UTC
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added the owner-approved :no_change outcome to the stable Mailbox callback and append-only ExecutionRun normalization. Only the literal atom is accepted; ignore, invalid returns, and failures retain their existing meanings.
- Carried the outcome through replay storage and legacy schema decoding. A real TestRepo replay persists source: :replay, returns :no_change, preserves :ignore, rejects a foreign tenant lookup, and does not make an unbound legacy mailbox replayable.
- Updated the API stability and operator guides and added executable documentation assertions.

## Task Commits

1. **Task 1: Persist an explicitly returned no-change Mailbox execution** — `d99179fa` (RED), `d439ac9f` (GREEN)
2. **Task 2: Keep replay binding resolution and public guidance aligned with the new outcome** — `15ba1ba2` (RED), `f183b602` (GREEN)

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` — documents and validates the additive callback outcome.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` and `inbound_records/execution_run.ex` — normalize only the explicit atom and validate the stored result.
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` and `inbound_records/replay_run.ex` — classify matched history and decode the additive outcome without changing route authority.
- Mailbox, execution, replay, and docs contract tests — cover callback semantics, actual append-only replay, tenant isolation, unsafe legacy binding, and contract wording.
- `mailglass_inbound/docs/api_stability.md` and `docs/inbound-operator.md` — define explicit no-change semantics for adopters and operators.

## Decisions Made

- The callback is the authority for :no_change. No inference is made from :ignore, exceptions, failed runs, or unchanged projections.
- Existing text storage accommodates the outcome, so no schema migration or dependency was introduced.
- Legacy module names remain untrusted routing data; the new matched-history classification only returns the existing ineligible error.

## Deviations from Plan

### Auto-fixed scope clarification

Added `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` to make the new stable wording executable. The PLAN file list, task file list, and scope note were updated before closeout. The additional guard is part of the same public contract and adds no dependency.

**Total deviations:** 1 scoped test addition.
**Impact on plan:** Focused docs checks now catch future drift between callback behavior and the adopter/operator contract.

## Issues Encountered

- The local Hex registry timed out while the checked-out `dialyxir` 1.4.7 differed from the lockfile’s 1.4.8. Focused Mix tests therefore used `--no-deps-check`; rebuilding existing dependency artifacts with the pinned toolchain resolved corrupt BEAM files. No dependency declaration or lockfile changed, and the no-optional compile passed.
- The full inbound `docs_contract_test.exs` run had two unrelated assertions against the unchanged Admin operator-trust document (`does not silently reroute` and `best-effort`). The new inbound docs-contract test passed in isolation (1 passed, 25 excluded); the two Admin-content failures are recorded for later project-level triage.

## User Setup Required

None — no external service or schema setup is required.

## Next Phase Readiness

Plan 170-03 is independent and runnable in Wave 1. INUX-04 remains pending in `REQUIREMENTS.md` because Plans 170-04, 170-05, 170-06, 170-07, and 170-08 also declare it; the readiness gate returned 0/1 IDs safe to mark.

---
*Phase: 170-inbound-investigation-and-recovery*
*Completed: 2026-10-09*
