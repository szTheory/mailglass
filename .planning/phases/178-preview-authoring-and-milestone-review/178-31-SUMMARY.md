---
phase: 178-preview-authoring-and-milestone-review
plan: "31"
subsystem: testing
tags: [elixir, mix, nimble_options, dependency-lock, preview-evidence]
requires:
  - phase: 178
    provides: [Cycle 06 candidate identity, bounded preview approval, and existing demo lock]
provides:
  - Targeted nimble_options 1.2.0 dev lock refresh with local locked-install and compile evidence
  - Accurate Cycle 06 startup failure and candidate-only cleanup record, with UIQ-08 left open
affects: [178-23, 178-24, UIQ-08]
actuals:
  tokens: 13043
  tasks: 3
  commits: 1
commits: 1
plan_head_before: 3f40a9f8f1118835fae35c51f835cbeb7e8cdc73
plan_head_after: d89343e706ce7b750ef4a24b209e0679899f8b65
tech-stack:
  added: []
  patterns:
    - Targeted Hex lock refresh, retained locked-install and warnings-as-errors evidence
    - Candidate-bound approval and preview failure records remain immutable and explicit
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-CYCLE-06-SUMMARY.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-31-SUMMARY.md
  modified:
    - reference/demo_app/mix.lock
    - .planning/phases/178-preview-authoring-and-milestone-review/178-31-PLAN.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-CYCLE-06.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-DELIVERY.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-VERIFICATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/COVERAGE.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - Refresh only nimble_options from 1.1.1 to 1.2.0; do not widen the lock update or conflate it with the separate cowlib advisory.
  - Treat Cycle 06 authority as consumed after its one startup failure; a future preview needs a new candidate, current exact-source CI, and fresh bounded approval.
  - Keep UIQ-08 open because local dependency installation and compilation do not establish a working owner preview.
patterns-established:
  - Preserve candidate identity and one-attempt authority in the cycle record; do not transfer old hosted proof to changed source.
  - Report dev asset-path logger warnings separately from compiler warnings and compile exit status.
requirements-completed: []
coverage:
  - id: D1
    description: The demo dev lock contains only the nimble_options 1.2.0 refresh, and locked installation plus warnings-as-errors compilation pass.
    verification:
      - kind: other
        ref: reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/locked-install.log and compile.log with exit files
        status: pass
    human_judgment: false
  - id: D2
    description: Cycle 06's consumed startup failure and teardown are recorded while UIQ-08 remains open.
    requirement: UIQ-08
    verification:
      - kind: other
        ref: 178-RECOVERY-CYCLE-06.json invariants and independent read-only review
        status: pass
    human_judgment: true
    rationale: A working preview tied to a new candidate and current evidence is still required for UIQ-08 acceptance and owner review.
duration: not measured
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 31 Summary

**Demo nimble_options lock refreshed to 1.2.0 with passing locked dev install and warnings-as-errors compilation; Cycle 06 remains consumed and UIQ-08 remains open.**

## Performance

- **Duration:** Not measured across the primary/child context handoff.
- **Started:** Not captured.
- **Completed:** 2026-11-02
- **Tasks:** 3
- **Files modified:** 11, including this summary.

## Accomplishments

- Updated only the demo lock's `nimble_options` entry from 1.1.1 to 1.2.0 with the Hex-provided checksum. Hex release metadata records insertion at `2026-11-02T08:37:25.588622Z` ([release metadata](https://hex.pm/api/packages/nimble_options/releases/1.2.0)).
- Kept the `cowlib` 2.21.0 EEF-CVE-2026-43966 advisory visible and separate from the lock drift ([OSV advisory](https://osv.dev/vulnerability/EEF-CVE-2026-43966)).
- Recorded Cycle 06's one failed startup attempt, exact evidence hashes, completed candidate-only teardown, and consumed approval. Route, CSS identity, and page-marker checks did not run.
- Updated phase verification and state while keeping UIQ-08 open and requiring a new candidate, current exact-source CI, and fresh bounded approval for any future preview.

## Checks Performed

- Root-context `asdf exec mix deps.update nimble_options`: exit 0; only the named package was upgraded.
- Dev `asdf exec mix deps.get --check-locked`: exit 0.
- Dev `asdf exec mix compile --warnings-as-errors`: exit 0.
- Compile output logged missing Storybook CSS and JS asset paths because those files are created by `mix assets.build`, which was not run. These were runtime logger warnings; the compile command completed successfully.
- Cycle 06 record invariants passed: stopped status, one attempt, exit 1, empty route results, CSS and marker checks not run, no retries, and owner demo untouched. Teardown completed at `2026-11-02T14:56:20.649Z`.
- `.planning/state.json` remains byte-identical to its saved SHA-256: `2c2175996f9515cc0bc61461c90762be35a0d56b3279fb509d0c8c80200ddc28`.
- Independent final review found no remaining fact, authority, UIQ-08, or state-preservation blockers. The reviewer confirmed the stale approval instruction was removed and the candidate boundary remains clear.

## Plan Commit

- Primary-context implementation commit: `d89343e706ce7b750ef4a24b209e0679899f8b65` (one measured plan commit after `3f40a9f8f1118835fae35c51f835cbeb7e8cdc73`).

## Files Created/Modified

- `reference/demo_app/mix.lock` — targeted nimble_options lock refresh.
- `178-31-PLAN.md` — included in the explicit modified-file list.
- `178-RECOVERY-CYCLE-06.json` — consumed attempt, failure evidence, and cleanup.
- `178-CYCLE-06-SUMMARY.md` — Cycle 06 result and next boundary.
- `178-DELIVERY.md`, `178-AUTOMATION.md` — current blocked status and retained cycle evidence.
- `178-VERIFICATION.md`, `COVERAGE.md` — current gap status; UIQ-08 remains open.
- `.planning/STATE.md`, `.planning/ROADMAP.md` — current stop, recovery, and plan status.
- `178-31-SUMMARY.md` — this execution record.

## Decisions Made

- Only `nimble_options` was refreshed. The unchanged `cowlib` advisory was not part of the lock delta.
- The previous candidate SHA and hosted CI result do not validate the locally changed lock. Any new preview needs a newly identified candidate, current exact-source required CI, and fresh bounded approval.
- UIQ-08 is not marked complete based on dependency installation or compilation; no working owner preview was established.

## Deviations from Plan

The child context could not stage files because the sandbox denied creation of `.git/index.lock`. Per instruction, it did not retry Git operations or use a workaround. The primary context committed the scoped implementation as one plan commit rather than separate per-task commits.

## Issues Encountered

- An earlier delegated dependency update failed fetching the Hex tarball with `:eperm`; the single authorized primary-context retry succeeded. Locked installation and compilation then passed.
- Cycle 06 had already failed before Plan 31 due to the stale candidate lock. Its one preview attempt was consumed and cleanup completed; Plan 31 did not retry any preview operation.
- The separate cowlib advisory remains visible and unresolved by this targeted lock repair.

## Next Phase Readiness

The local lock repair and its dev verification are complete. UIQ-08 remains open: a new candidate with current exact-source required CI and fresh bounded preview approval is required before the owner can review a working preview. No further preview or hosted operation was authorized by this plan.

## Self-Check: PASSED

- The summary and Cycle 06 artifacts exist and the summary's commit metadata matches the primary-context measurement provided for this plan.
- JSON, state-hash, roadmap, lock-version, UIQ-08, and local command evidence invariants passed; independent review found no remaining scoped findings.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02*
