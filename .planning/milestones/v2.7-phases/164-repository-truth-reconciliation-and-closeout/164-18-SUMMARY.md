---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 18
subsystem: repository-truth-validation
tags: [git, elixir, index-stages, nul-framing, trust-boundary]
requires:
  - phase: 164-17
    provides: literal-pathspec Git-index authentication for tracked disposition subjects
provides:
  - exact NUL-delimited stage-0 Git-index authentication for every tracked ledger subject
  - production-seam regressions for unmerged stages, malformed records, duplicate records, and byte-exact path identity
affects: [phase-verification, terminal-finalization, TRTH-02]
actuals:
  tokens: 2429
  tasks: 1
  commits: 2
tech-stack:
  added: []
  patterns: [NUL-delimited Git record parsing, closed stage-zero authority, byte-exact pathname comparison]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-18-SUMMARY.md
  modified:
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_repository_truth_test.exs
key-decisions:
  - "Tracked proof accepts only one complete stage-0 record whose NUL-framed pathname is byte-identical to the requested subject; nonzero or additional valid records are identity mismatches, while malformed framing or metadata remains a distinct failure."
patterns-established:
  - "Git index trust checks use staged NUL output and never line splitting, trimming, path unquoting, or wildcard pathspec expansion."
  - "A genuine unresolved merge fixture proves production validation rejects stage-1/2/3 index state even while the working-tree subject remains a regular file."
requirements-completed: [TRTH-02]
coverage:
  - id: D1
    description: "Every tracked disposition subject requires one byte-exact stage-0 Git-index record and rejects unmerged, duplicate, missing, malformed, or mismatched records."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#phase 164 stage-0 index identity"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 18: Stage-Aware Tracked Proof Summary

**Repository-truth validation now accepts tracked evidence only through one exact NUL-delimited stage-0 Git-index identity and rejects unresolved merge stages at the production seam.**

## Performance

- **Duration:** 15 minutes
- **Started:** 2026-09-10T03:14:45Z
- **Completed:** 2026-09-10T03:30:13Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Replaced pathname-only `git ls-files` proof with literal-pathspec staged NUL output whose mode, object ID, numeric stage, tab separator, record terminator, and pathname are parsed without normalization.
- Required a sole stage-0 record with byte-exact subject equality while preserving separate untracked, identity-mismatch, malformed-output, and Git-command-failure outcomes.
- Added four tagged production-seam cases covering a genuine `UU` three-stage index, ordinary stage-0 proof, metacharacter/prefix/newline identity, record ordering, duplicates, missing output, malformed metadata, and path mismatch.

## Task Commits

1. **Task 1: Require one exact stage-0 index record for every tracked subject** — `b5962dcd` (RED), `f08a6ac9` (GREEN)

## Files Created/Modified

- `scripts/validate_repository_truth.exs` — Exact staged-record parser and fail-closed tracked-subject authentication.
- `test/scripts/phase_164_repository_truth_test.exs` — Disposable Git conflict fixture plus stage-0 positive and hostile record controls.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-18-SUMMARY.md` — Plan outcome, verification, and traceability record.

## Decisions Made

- Syntactically valid records that are nonzero-stage, additional, or path-mismatched are repository identity failures; incomplete NUL framing or invalid mode/object/stage metadata is malformed Git output.
- The genuine-conflict assertion enumerates all three stages without `--error-unmatch`, because Git's error-unmatch mode emits only its first matched staged record; the production command still uses the required error-unmatch probe and rejects the returned nonzero stage.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Git combines `--error-unmatch` with staged output by emitting only the first matching conflict record. The fixture therefore independently proves all three stages with an unfiltered literal lookup, while the production command rejects the first nonzero stage and direct parser cases prove any multi-record output fails closed.
- Focused tests emit the existing optional OTLP-exporter warning; it does not affect compilation or outcomes.

## TDD Gate Compliance

- RED commit `b5962dcd` reproduced embedded-newline pathname normalization failures, undefined staged-record validation, and the previously accepted unmerged trust path.
- GREEN commit `f08a6ac9` made all four tagged cases pass; the tracer gate reran the tagged command successfully after the commit.
- No refactor commit was needed.

## Verification

- Tagged tracer group: 4 tests, 0 failures, selected nonzero tests, and passed again after GREEN commit.
- Complete repository-truth file: 24 tests, 0 failures.
- Canonical validator: `repository truth ledger: valid`.
- Elixir formatting for both changed files: passed.
- `git diff --check`: passed.
- Scope audit: only the two plan-declared implementation/test files changed before metadata closeout; no ledger row, ignore rule, documentation, release authority, dependency, schema, UI, package version, or terminal evidence artifact changed.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The concrete TRTH-02 conflict-stage bypass is closed with production-seam behavioral proof.
- Plan 164-19 can repair the remaining lexical shim and authenticated dependency-chain findings. Terminal `/finalize-phase 164` remains intentionally unrun.

## Self-Check: PASSED

- Both changed code/test files and this summary exist.
- Commits `b5962dcd` and `f08a6ac9` are present in Git history.
- Fresh complete verification passed after the last code change.
- No goal-blocking stub, new skipped test, unrun plan verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
