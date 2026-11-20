---
phase: 184-close-admin-and-docs-browser-evidence-gaps
plan: "11"
subsystem: candidate verification
tags: [hex, offline-cache, evidence, route]
requires:
  - phase: 184-close-admin-and-docs-browser-evidence-gaps
    provides: Sealed a295 source, five-lock graph, and approved Phase 184 patch
provides:
  - Candidate-free exact-path and raw-checksum fixtures
  - Terminal blocked preallocation evidence with owner-cache and cleanup reconciliation
affects: [phase-182-verification, phase-183-verification, phase-184-verification, v2.11-milestone-audit]
actuals:
  tokens: 233718
  tasks: 1
  commits: 2
commits: 2
plan_head_before: 4c80af7ff7891cd962d876b50e77ad1393da106f
plan_head_after: 23f9caa60364742dd8207753a22d9b6ac154ae72
tech-stack:
  added: []
  patterns: [canonical patch path resolution, raw Hex checksum comparison, append-only route custody]
key-files:
  created:
    - .planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-11-route.cjs
    - .planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-11-route.test.cjs
    - .planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-11-EVIDENCE.json
    - .planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-11-retained/
  modified: []
key-decisions:
  - "Stop the one-shot route when the cached cc_precompiler dependency tuple disagreed with the sealed lock; do not normalize or retry after consumption."
  - "Keep BRADM-01, BRADM-07, and BRDOC-02 open because the actual offline prefetch and downstream candidate gates were not reached."
metrics:
  duration: 43min
  completed: 2026-11-20
  status: halted
requirements-completed: []
coverage:
  - id: D1
    description: Candidate-free fixtures verify the approved patch path and raw checksum semantics.
    verification:
      - kind: unit
        ref: "node --test .planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-11-route.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: The real schema-5 inspection stopped on a cached dependency tuple mismatch before offline prefetch.
    requirement: BRDOC-02
    verification:
      - kind: other
        ref: "184-11-EVIDENCE.json#firstStop"
        status: fail
    human_judgment: false
  - id: D3
    description: The blocked route was finalized with zero downstream effects and owned roots absent.
    verification:
      - kind: other
        ref: "node .planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-11-route.cjs verify-stage terminal"
        status: pass
    human_judgment: false
---

# Phase 184 Plan 11 Summary

**Candidate-free patch and checksum controls passed; the single real registry inspection stopped before offline prefetch on a lock/cache dependency mismatch.**

## Performance

- **Duration:** about 43 minutes from the first persisted plan commit through terminal replay.
- **Started:** 2026-11-19T23:48:41-05:00 (first persisted plan work).
- **Completed:** 2026-11-20T00:32:07-05:00.
- **Tasks:** Task 1 reached a terminal blocked gate; Tasks 2 and 3 were not run.
- **Files modified or created:** 8 plan-owned files, including the retained evidence set.

## Accomplishments

- Added and passed 10 candidate-free fixtures for canonical patch resolution, exact SHA-256, raw 32-byte checksum semantics, retained registry receipt parsing, and blocked-route custody. The controller selftest also passed marker-last cleanup and confirmed zero route stages.
- Ran the single authorized `cache-preflight`. Hex 2.6.0 read the existing schema-5 cache but stopped at `cc_precompiler@0.1.11` dependency metadata validation. The real offline `Hex.Registry.Server.open` and `prefetch` did not run.
- Confirmed the owner cache stayed byte-identical (8,047,831 bytes; SHA-256 `10be1860e7b3c66e541db8a42397336437da75a7bee5576643f8ad9563e9d0b5`). The candidate, preflight, and scratch roots are absent; candidate allocation, push, dispatch, and preview counters are zero. Read-only preallocation and terminal replay passed.

## Gate Diagnosis

The lock expects `cc_precompiler@0.1.11` to depend on `elixir_make` with requirement `~> 0.7`. A separate read-only reconciliation of the existing cache record found the requirement `~> 0.7 or ~> 0.8 or ~> 0.9`, with the same package/app and `optional: false`. This is the first stop. The route was consumed and no retry or comparator change was made.

## Task Commits

1. **Task 1 fixtures:** `0f4b2cdb` — exact patch path and raw checksum fixtures.
2. **Task 1 verifier and cleanup fixtures:** `23f9caa6` — retained receipt verification and blocked terminal custody.

The final evidence and summary commit is recorded separately from the two task commits.

## Retained Evidence

- [184-11-EVIDENCE.json](./184-11-EVIDENCE.json) — exact source identity, first stop, zero downstream effects, owner cache identity, and terminal disposition.
- [preallocation-stop.json](./184-11-retained/preallocation-stop.json) — sanitized blocked-gate receipt.
- [custody.jsonl](./184-11-retained/custody.jsonl) — one preflight reservation, blocked result, and terminal marker.
- [terminal-preimage.json](./184-11-retained/terminal-preimage.json) — blocked evidence before terminal finalization.
- [tdd-red-evidence.json](./184-11-retained/tdd-red-evidence.json) — candidate-free RED evidence for the exact-path fixture.

## Issues Encountered

- The initial runtime error named the mismatched package but omitted both dependency values. A read-only diagnostic established the expected and observed requirements above; no consumed command was rerun.
- No browser container or other Docker resource was started or changed. No remote GitHub, dispatch, preview, or review action occurred.

## Deviations from Plan

The route stopped at the first real registry-record gate as required. The successful offline prefetch, candidate builds, hosted run, Admin preview, and independent reviews remain unverified. BRADM-01, BRADM-07, and BRDOC-02 remain open. The unused D-30 plan allowance remains unspent and requires separately authorized scope.

## Next Phase Readiness

This route is terminally blocked. Do not retry the cache preflight or allocate a candidate under 184-11. The next action belongs to the parent orchestrator: reconcile the Phase 182, 183, and 184 verification records and milestone audit from this terminal evidence, then preserve the remaining plan allowance pending separate authorization.

---
*Phase: 184-close-admin-and-docs-browser-evidence-gaps*
*Completed: 2026-11-20*

## Self-Check: PASSED

The controller, fixture suite, blocked evidence, retained custody files, and summary exist. Both Task 1 commits are ancestors of the current HEAD.
