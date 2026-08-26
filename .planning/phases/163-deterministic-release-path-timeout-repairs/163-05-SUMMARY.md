---
phase: 163-deterministic-release-path-timeout-repairs
plan: 05
subsystem: testing
tags: [playwright, gallery-matrix, timeout-repair, failure-evidence]
provides:
  - Current CI-mode reproduction attributed to the complete 117-cell matrix body.
  - Evidence-owned finite test-local repairs with focused and full first-attempt passes.
key-files:
  created:
    - mailglass_admin/e2e/support/timeout-evidence-reporter.cjs
    - mailglass_admin/test/support/browser_timeout_evidence.ex
  modified:
    - mailglass_admin/e2e/gallery-matrix.spec.js
    - mailglass_admin/playwright.config.cjs
    - mailglass_admin/test/support/operator_browser_server.ex
key-decisions:
  - Raise only the named complete-matrix body to 240 seconds, two named structural matrices to 60 seconds, and browser sandbox ownership to 20 minutes after protected recurrence; retain every global bound and coverage axis.
requirements-completed: [DTRM-03]
completed: 2026-08-26
status: complete
---

# Phase 163 Plan 05: Gallery Timeout Repair Summary

**A current CI-mode full gate and a protected PR recurrence identified two exact browser owners; finite title-local bounds repair both without changing global policy or coverage.**

## Accomplishments

- Recovered immutable historical run `32865270291`, job `97858959632`, and SHA `fda6368bf43c49aab88e3f90da1d6af67ee77d35`.
- Reproduced the current failure after readiness completed in 243ms while the sibling stress body passed in 3.7s, uniquely identifying the named full matrix body.
- Kept live discovery, the `>50` guard, all 117 cells, stress fixtures, 320/390/768/1440 widths, light/dark/system themes, overflow checks, and 320px clipping proof.
- Added safe first-attempt reporter/server evidence and failure-only CI artifacts.
- Used protected run `32994318111` to attribute a 60-second gallery recurrence and an independent 31.3-second contrast-matrix expiry, then raised only those bodies to 120 and 60 seconds respectively.
- Used protected run `32996524975` to attribute the 120-second gallery recurrence, a 32.6-second primitive-matrix expiry, and downstream sandbox-owner loss after 10 minutes; selected finite 240-second, 60-second, and 20-minute local bounds.

## Focused proof

Three CI-mode, one-worker first attempts passed without retry:

| Run | Full matrix | Stress body |
| ---: | ---: | ---: |
| 1 | 44,027ms | 4,604ms |
| 2 | 47,553ms | 3,685ms |
| 3 | 50,256ms | 3,751ms |

## Guardrails retained

The global test default remains 30 seconds, CI retry policy remains one, local retries remain zero, Playwright startup remains 300 seconds, the job remains 30 minutes, and execution remains one worker. Browser sandbox ownership is now a measured 20 minutes. No UI, package, dependency, locator, or workflow topology change was made.

## Protected recurrence proof

The final exact repaired trio passed first attempt in CI mode (gallery `47.7s`, contrast `17.8s`, primitive matrix `12.2s`). The complete operator-browser lane then passed first attempt with 176 passed and one intentional skip in 3.8 minutes; gallery completed in `47.8s` and no retry ran.

## Commits

- `2333fcad` — immutable historical reconstruction.
- `7b9da5b7` — local repair, recorder, reporter, and regression contracts.
- `f46aad8b` — strict failure-only artifact upload.
- `e8c6260f` — protected recurrence repairs scoped to the two exact test titles.
- `d27de4b6` — exact-run job log and failure-artifact inspection.
- `9d0bcacf` — second protected matrix and browser-owner recurrence repair.

---
*Plan status: complete without human UAT*
