---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 16
subsystem: documentation
tags: [release-policy, maintainer-guidance, protected-authority, historical-boundary, exunit]
requires:
  - phase: 164-15
    provides: verified terminal evidence integrity and the remaining TRTH-01 documentation gap
provides:
  - One globally consistent protected release authority model across all current maintainer guidance
  - A whole-non-historical regression contract with a strict historical boundary
affects: [phase-verification, terminal-finalization, TRTH-01]
actuals:
  tokens: 1635
  tasks: 1
  commits: 2
tech-stack:
  added: []
  patterns: [whole-document documentation contract, exact historical boundary, negative authority variants]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-16-SUMMARY.md
  modified:
    - MAINTAINING.md
    - test/mailglass/publish/maintaining_release_gate_contract_test.exs
key-decisions:
  - "Current bus-factor guidance binds release progress to the protected exact-candidate dispatch and fresh exact repository-admin authorization; green gates alone grant no authority."
  - "The original v0.1/v0.5 hands-free rationale remains discoverable only after the exact Historical release procedures boundary."
patterns-established:
  - "Documentation authority tests scan the complete current-facing region rather than a position-dependent opening section."
  - "Historical applicability boundaries fail closed when missing or duplicated."
requirements-completed: [TRTH-01]
coverage:
  - id: D1
    description: "All non-historical maintainer guidance presents only the protected exact-candidate and fresh repository-admin release authority."
    requirement: TRTH-01
    verification:
      - kind: integration
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs#all non-historical guidance records only protected release authority"
        status: pass
      - kind: integration
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs#unsupported authority variants are rejected anywhere before the historical boundary"
        status: pass
    human_judgment: false
  - id: D2
    description: "The v0.1/v0.5 bus-factor rationale remains historical provenance behind one exact, mandatory boundary."
    requirement: TRTH-01
    verification:
      - kind: integration
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs#historical release procedures retain provenance without becoming current guidance"
        status: pass
      - kind: integration
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs#the historical authority boundary must exist exactly once"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-09-09
status: complete
---

# Phase 164 Plan 16: Whole-Document Maintainer Authority Reconciliation Summary

**Current maintainer guidance now exposes one protected exact-candidate release model, while the original v0.1/v0.5 hands-free rationale survives only as explicitly historical provenance.**

## Performance

- **Duration:** 3 minutes
- **Started:** 2026-09-09T22:11:07Z
- **Completed:** 2026-09-09T22:14:17Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Reconciled `Bus Factor & Continuity` with the current protected exact-candidate and fresh exact repository-admin authority at the start of `MAINTAINING.md`.
- Moved the original v0.1/v0.5 single-maintainer rationale beneath the exact `Historical release procedures` boundary without altering its provenance.
- Expanded the documentation contract across every non-historical byte, rejecting representative automatic, reviewer-free, and approval-free authority variants regardless of paragraph position.
- Made a missing or duplicated historical boundary fail the contract explicitly.

## Task Commits

The TDD tracer task was committed through explicit RED and GREEN gates:

1. **Task 1 RED: Whole-document authority contract** — `3c798e04` (test)
2. **Task 1 GREEN: Reconciled maintainer release authority** — `185f0d4b` (feat)

## Files Created/Modified

- `MAINTAINING.md` — Current bus-factor guidance now references the protected authority model; obsolete v0.1/v0.5 rationale is explicitly historical.
- `test/mailglass/publish/maintaining_release_gate_contract_test.exs` — Position-independent current-region assertions, injected semantic variants, and an exact-boundary helper.

## Decisions Made

- Kept the current single-maintainer and public Hex transfer information in place while removing obsolete current-facing release authority.
- Preserved the original hands-free and reviewer wording verbatim in meaning under a historical v0.1/v0.5 subsection, rather than erasing operational provenance.
- Left `.github/workflows/release-please.yml` and `scripts/release_policy.exs` untouched; executable controls remain the sole authority.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repository's default `.tool-versions` runtime is unavailable locally. Verification used the already-installed Elixir `1.19.5-otp-28` and Erlang `28.4.1` through per-process ASDF variables; no version file or dependency changed.
- The focused run emits the existing optional OTLP-exporter warning. It does not affect this documentation contract and was not introduced by Plan 164-16.

## TDD Gate Compliance

- RED failed for the intended reasons: the non-historical bus-factor section contained `hands-free` and `no required reviewers`, and the required historical v0.1/v0.5 subsection did not exist.
- GREEN passed all 4 focused tests after reconciling the guide.
- No refactor commit was necessary after formatting the test in the GREEN change.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` — 4 tests, 0 failures.
- `git diff --check` — passed.
- Executable-control diff from the pre-RED parent through GREEN for `.github/workflows` and `scripts/release_policy.exs` — empty.
- Acceptance probes confirmed one exact historical heading, v0.1/v0.5 rationale after that heading, and both RED/GREEN commits present.

## Known Stubs

None.

## Threat Flags

None — the plan narrows documentation authority and adds contract coverage without changing a network endpoint, authentication path, file-access boundary, schema, workflow operation, package version, or executable release authorization.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The remaining TRTH-01 documentation contradiction is closed with rerunnable focused evidence.
- Phase 164 is ready for refreshed ordinary verification against this implementation history, followed by the separately governed terminal finalization after protected completion metadata reaches `main`.

## Self-Check: PASSED

- `MAINTAINING.md` and `test/mailglass/publish/maintaining_release_gate_contract_test.exs` exist and contain the planned changes.
- RED commit `3c798e04` and GREEN commit `185f0d4b` are present in Git history.
- Every task verification, acceptance criterion, tracer gate, and plan-level verification passed in this execution session.
- No goal-blocking stub, skipped test, unrun verification, executable-control diff, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-09*
