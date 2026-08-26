---
phase: 163-deterministic-release-path-timeout-repairs
repair_sha: 5d125ad210ef5ff2afb3c537dce03e9b312ae533
protected_run_id: pending
protected_verdict: pending
human_uat_required: false
---

# Phase 163 Proof

## Decision record

The maintainer approved automatic resolution with machine verification only:

- database: accept bounded non-reproduction, make no speculative repair, and capture the next structured protected recurrence;
- browser: apply the evidence-backed finite local repair after current CI-mode reproduction;
- integration: unchanged complete local gates followed by normally triggered exact-SHA protected jobs;
- automation: roll recurrent evidence and monitor contracts into existing CI; do not add schedules, dispatches, merges, releases, broad retries, or global timeout expansion.

## Frozen code identity

`repair_sha: 5d125ad210ef5ff2afb3c537dce03e9b312ae533`

The repair identity contains four implementation commits:

| Commit | Purpose |
| --- | --- |
| `29eb8b3f` | Structured, sanitized database recurrence evidence around unchanged 1,000-run properties |
| `7b9da5b7` | Reproduced gallery owner, finite test-local repair, reporter, and recorder |
| `f46aad8b` | Failure-only artifacts in the two existing protected lanes |
| `9b1a7c0c` | Observable exact-run monitor and CI contract test |
| `7b51ba44` | Exact PR identity and check-rollup inspection |
| `5d125ad2` | Read-only workflow activation-state inspection |

## Focused proof

### Database

- Historical run `32433156236` / job `96628985134` / SHA `81e738e74d59d1ab36c3e1dc3adc03ad6d0c0b84` contains structured SQLSTATE 57014.
- Three exact-SHA reconstruction attempts passed without recurrence; owner verdict remains inconclusive.
- Current focused pair plus recorder/workflow contracts: 2 properties, 6 tests, 0 failures in 64.4s.
- Both properties retain `max_runs: 1000`, unseeded generation, ten-minute ownership, and original cleanup/settle semantics.

### Browser

- Historical run `32865270291` / job `97858959632` / SHA `fda6368bf43c49aab88e3f90da1d6af67ee77d35` confirms the original timeout.
- Current CI-mode reproduction: readiness 243ms, 117 cells, named full body exhausted at 30,002ms and 30,083ms; sibling passed in 3,697ms.
- Repair: only that named body receives `test.setTimeout(60_000)`.
- Three focused first attempts passed in 44,027ms, 47,553ms, and 50,256ms; no retry.

## Complete local integration

| Gate | Result |
| --- | --- |
| `mix test --warnings-as-errors` | 23 properties, 1,964 tests, 0 failures, 7 intentional skips in 174.7s |
| `CI=true npm run test:operator-browser` | 176 passed, 1 intentional skip in 3.3m; no retry |
| Phase evidence contracts | ExUnit recorder/workflow contracts, admin recorder tests, Node reporter/monitor tests all pass |
| Workflow validity | `actionlint .github/workflows/ci.yml` and `git diff --check` pass |

## Policy backstop

- No schema, public API, admin UI, package, lockfile, dependency, action upgrade, schedule, new workflow job, manual dispatch, seed pin, property exclusion, skipped matrix cell, worker increase, or unlimited timeout.
- Global Playwright timeout remains 30 seconds; existing CI retry remains one; local retry remains zero; server lifecycle remains 300 seconds; browser job remains 30 minutes.
- Database owner limits, transaction settings, generators, and global/job limits remain unchanged.
- Evidence artifacts upload only after the exact owning step fails, use strict missing-file behavior, unique run identity, 90-day retention, and full action digest.

## Protected reconciliation

PR: https://github.com/szTheory/mailglass/pull/228

The PR was opened from `phase-163-deterministic-timeout-repairs` through the
repository-local observable monitor. The normally triggered run and its two
named protected job conclusions are pending; no manual workflow dispatch is
authorized or required.
