---
phase: 173-consistency-and-delivery-evidence
plan: 08
subsystem: delivery-verification
tags: [git-sparse-checkout, docker, exact-sha, playwright, mix]
requires:
  - phase: 173-07
    provides: Exact-SHA preview and synthetic browser evidence workflow
provides:
  - Protected-path-safe candidate launcher with sparse exclusions before materialization
  - Lock-preserving dependency preparation and clean candidate delivery evidence
  - Exact-SHA local delivery results with CI and owner acceptance kept separate
affects: [UIQ-03, Phase-173-verification]
tech-stack:
  added: []
  patterns: [no-checkout sparse candidate, lock-enforced dependency setup, scoped candidate cleanup]
key-files:
  created:
    - .planning/phases/173-consistency-and-delivery-evidence/173-08-SUMMARY.md
  modified:
    - .dockerignore
    - scripts/check_phase173_candidate.sh
    - scripts/test_check_phase173_candidate.sh
key-decisions:
  - "Use sparse exclusions before candidate materialization and exclude both protected inputs from Docker contexts."
  - "Install only lockfile-pinned Mix/npm dependencies in the detached candidate and restore only candidate-generated demo lock drift."
  - "Keep delivery incomplete until required exact-SHA CI Green and protected owner acceptance are verified."
metrics:
  duration: 32min
  completed: 2026-10-10
  commits: 3
  plan_head_before: 3acadb53b70af464e64be17863210561b00dc8b8
  plan_head_after: a7fd4843d17c2bf201fb1366c588d65af0f22c3d
status: complete
actuals:
  tokens: 10018
  tasks: 2
  commits: 3
requirements-completed: []
---

# Phase 173 Plan 08: Protected Candidate Delivery Gate Summary

**The protected-path candidate gate now runs on exact SHA `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`; local checks pass while UIQ-03 remains open for CI and owner acceptance.**

## Accomplishments

- Changed the candidate launcher to capture only the original checkout HEAD, create a detached `--no-checkout` worktree, install non-cone sparse rules for both protected paths, then materialize the candidate. The deliverable scan skips both exact paths before Git probes; the root Docker ignore rules exclude them from build contexts.
- Added synthetic positive and mutation checks for origin inventory prohibition, sparse ordering and exclusions, protected scan skips, Docker filtering, exact lock setup, lock restoration, focused browser selection, and the rule that green fake CI still cannot satisfy owner acceptance.
- Prepared the detached candidate using only already-locked dependencies: pinned Mix `deps.get --check-locked` for root, Admin, and Inbound, followed by Admin `npm ci`. The preview startup can rewrite the demo lock in a detached candidate; the launcher restores that candidate-only file to the captured SHA and verifies it before evidence acceptance.
- Ran the full candidate gate for exact SHA `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`. Results: Core 79 tests passed; Admin 605 passed/1 excluded; Inbound 3 properties and 480 tests passed/3 excluded; connected Playwright 30 passed. The preview served all five required routes and built/served CSS hashes matched. The focused browser evidence checkpoint passed with six clean captures and twelve validated PNG files. The candidate remained clean and its lockfile matched HEAD after the gate.
- Updated the ignored delivery disposition at `reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json` and SHA-only origin record. Dirty-path inventory remains `not-collected`; no protected input was accessed.

## Task Commits

- `127c8b9abc37416e14b855da9c3254fffa2dc9ed` — `fix(173-08): enforce protected-path candidate isolation`
- `222d64381b3e91a66c19a286ff7cdfb3700310fc` — `fix(173-08): restore candidate dependencies without lock drift`
- `a7fd4843d17c2bf201fb1366c588d65af0f22c3d` — `fix(173-08): pin candidate Mix toolchain during setup`

## Delivery Predicates

| Predicate | Result |
|---|---|
| Candidate regression | Passed |
| Preview routes and served assets | Passed |
| Focused synthetic browser evidence | Passed; six captures, clean candidate, twelve PNG hashes |
| Exact-SHA required CI Green | Missing |
| Protected owner acceptance | Unverified |
| Overall delivery / UIQ-03 | Incomplete |

The gate exited incomplete for the two external predicates above. Its read-only CI query found no successful `CI Green` run for the exact candidate SHA. No CI dispatch, push, merge, release, or visual UAT was performed. Keep UIQ-03 and Phase 173 open until exact-SHA CI Green and authorized owner acceptance are recorded.

## First Gate Attempt and Recovery

The earlier committed candidate `222d64381b3e91a66c19a286ff7cdfb3700310fc` could not select an asdf Mix version in the fresh worktree, and its preview routes returned 000. The candidate still passed retained evidence validation after candidate-only lock restoration. The launcher was corrected to pass the same pinned Erlang/Elixir versions that the regression gate exports. The follow-up run on `a7fd4843…` then passed the dependency preparation and all local predicates. No dependency declarations or locks were updated.

The first run also confirmed that the Docker startup's candidate lock changes must be restored before evidence acceptance. Only the detached candidate lockfile was restored; the original checkout lockfile was not touched.

## Retained Resources

Keep the review Compose project and detached candidate available for owner review. The current URL is [http://127.0.0.1:49699/dev/mail](http://127.0.0.1:49699/dev/mail), project `mailglass-phase173-review-a7fd4843-20261010130719-18415-18650`, worktree `/private/tmp/mailglass-phase173.EFSZPqqT/candidate`. Preserve the earlier Plan 07 review project as well. Scoped cleanup commands are in the ignored phase disposition; none were run.

## Deviations from Plan

**1. [Rule 3 - Blocking setup issue] Added explicit pinned asdf versions to candidate dependency preparation.**
- **Found during:** Task 2
- **Issue:** A fresh sparse worktree had no project-selected asdf Mix version, so the initial `mix deps.get --check-locked` preparation stopped before regression tests.
- **Fix:** Passed Erlang 27.3.4.13 and Elixir 1.18.4-otp-27 to each Mix preparation call, matching the regression gate's pinned toolchain; expanded the synthetic contract.
- **Files modified:** `scripts/check_phase173_candidate.sh`, `scripts/test_check_phase173_candidate.sh`
- **Commit:** `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`

The fake contract also needed updates for its source-boundary slice, lock hash mock, npm stub, and expected cleanliness message. These were test fixture corrections; the final contract passed.

## Plan 08 Execution Self-Check: PASSED (`a7fd4843d17c2bf201fb1366c588d65af0f22c3d`)

- The candidate delivery JSON names the committed full SHA and reports local regression, preview, and browser evidence as passed.
- The retained checkpoint reports `candidate_dirty=false`, six captures, and each capture clean; retained evidence validation checked the PNG bytes and hashes.
- Candidate status is clean with explicit exclusions for the two protected paths, and `reference/demo_app/mix.lock` matches the captured candidate SHA.
- `ownerAcceptance.status` remains `unverified`, CI is `missing`, original dirty inventory is `not-collected`, and overall delivery remains `incomplete`.
- The review Compose project and detached candidate remain available; prior retained resources were preserved.

## Post-Plan Review Follow-Up (`4994442105315afdaa71beba73f6ab85e40f8533`)

- The Nyquist audit added secure evidence-writer assertions for existing PNG destinations, symlink destinations, and JSON trusted-root escape; the synthetic candidate contract passed.
- Independent code review found that `captures/../<pinned-baseline>.png` could alias a baseline as a current screenshot. The candidate gate now requires a safe top-level PNG path tied to its capture ID and rejects duplicate paths.
- The new baseline-alias fixture failed against the old gate and passed after the fix. The independent re-review is clean.
- The Plan 08 full delivery gate has not been rerun for this follow-up SHA. The prior local pass is historical; exact-SHA CI and owner acceptance remain unverified, so Phase 173 and UIQ-03 remain incomplete.

---
*Plan: 173-08*  
*Completed: 2026-10-10*
