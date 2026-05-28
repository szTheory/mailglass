---
phase: 59-ci-trust-lanes-checkpoint-evidence
plan: "02"
subsystem: ci
tags:
  - ci
  - trust-evidence
  - branch-protection
  - upload-artifact
  - github-actions
dependency_graph:
  requires:
    - phase: 59-01
      provides: scripts/check_clean_baseline_hex_only.sh, test/scripts/required_checks_test.exs
  provides:
    - .github/workflows/ci.yml::trust_lane_repo_head job (EVID-01 required lane)
    - scripts/setup_branch_protection.sh REQUIRED_CHECKS + print_expected_text extended (repo-head)
  affects:
    - Task 2 (post-merge branch-protection re-assertion — PENDING HUMAN ACTION)
    - Phase 60 (release ceremony can download trust-runner-repo-head-* artifacts by run_id prefix)
    - EVID-02 clean-baseline lane DEFERRED (see Deviations)
tech_stack:
  added: []
  patterns:
    - Atomic commit (workflow + REQUIRED_CHECKS array + heredoc) per D-02 + Pitfall 1
    - upload-artifact@v4 pinned SHA reuse (no new SHA surface)
    - if-no-files-found error + exact checkpoint.json file path (Pitfall 6)
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - scripts/setup_branch_protection.sh
key-decisions:
  - "Atomic commit (D-02 + Pitfall 1): repo-head job + REQUIRED_CHECKS + heredoc land in ci(59) commit 56b7855"
  - "Repo-head validator uses no --checkpoint flag (runner default matches script default)"
  - "Human-glance step writes checkpoint_sha256 to GITHUB_STEP_SUMMARY"
  - "EVID-02 clean-baseline lane DEFERRED (maintainer decision 2026-05-28): cannot run a clean-baseline journey against published mailglass 1.2.0 because the trust runner shipped after that release"
requirements-completed:
  - EVID-01
  - EVID-04
requirements-deferred:
  - EVID-02
duration: 50min
completed: "2026-05-28"
---

# Phase 59 Plan 02: CI Trust Lanes + Checkpoint Evidence Summary

**Added `trust_lane_repo_head` (required, EVID-01) to ci.yml and registered it in
branch-protection REQUIRED_CHECKS + heredoc atomically; uploads a 90-day
`trust_runner.v1` checkpoint artifact (EVID-04). The clean-baseline lane (EVID-02)
was deferred — see Deviations.**

## Accomplishments

- `trust_lane_repo_head` job added to ci.yml: postgres service, Elixir 1.18 / OTP 27
  matrix, deps cache, `mix verify.reference_host.journey` from repo root, checkpoint
  validation via `scripts/check_trust_runner_checkpoint.sh`, `$GITHUB_STEP_SUMMARY`
  human-glance step, and `actions/upload-artifact@v4` (pinned SHA) with
  `if-no-files-found: error`, `retention-days: 90`, exact `checkpoint.json` path.
- `scripts/setup_branch_protection.sh` REQUIRED_CHECKS array + `print_expected_text`
  heredoc both extended with `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` (atomic, one commit).
- No `if:` condition on the job (Pitfall 2). No new pinned-Action SHA introduced. No mix.lock changes.
- Plan 01 contract test (`required_checks_test.exs`) stays green (2 tests, 0 failures) — array + heredoc moved together.

## Task Commits

1. **Task 1: Add repo-head trust lane + register repo-head** — `56b7855` (ci)

## Task 2: PENDING HUMAN ACTION (post-merge branch-protection re-assertion)

`checkpoint:human-action` — requires the maintainer's `BRANCH_PROTECTION_PAT` (admin scope)
to push the new required check to GitHub's live branch-protection state. Must run after the
Task 1 commit is on `main`. Instructions are in 59-02-PLAN.md Task 2 (Steps 1–6).

## Deviations from Plan

### EVID-02 clean-baseline lane DEFERRED (maintainer decision, 2026-05-28)

The plan specified a second job, `trust_lane_clean_baseline`, running
`mix verify.reference_host.journey` with `working-directory: reference/host_app`
against the Hex-published `~> 1.2` siblings. Investigation during execution found this
**cannot work**:

- `verify.reference_host.journey` is an alias defined only in the **root** `mix.exs`
  (delegating to the `mailglass.trust.run` Mix task). `reference/host_app/mix.exs` defines
  no such alias (aliases are not inherited from deps).
- `mailglass.trust.run` was added in Phase 57 (`293cd74`), **after** the `mailglass-v1.2.0`
  tag. The Hex-published 1.2.0 package (`reference/host_app/deps/mailglass`) contains no
  trust/verify Mix task.

So the lane would fail "task could not be found" on every CI run, and because it is a
non-advisory `ci.yml` job it would block `gate-ci-green` (the Hex publish gate Phase 60 needs).

Root cause is milestone sequencing: a clean-baseline trust proof can only run against a
published release that already contains the trust runner. The repo-head lane (EVID-01) is
unaffected — it runs from the repo root where the alias + task exist (verified locally: all
5 stages complete, checkpoint validates).

Per maintainer decision, EVID-02 is deferred to a post-release follow-up (after a mailglass
version containing the trust runner is published, bump `reference/host_app` to that version
and add the clean-baseline lane — a one-job change). Plan 01's `check_clean_baseline_hex_only.sh`
remains shipped and ready to wire when that lane is added.

## Self-Check

### Created/Modified Files

- `.github/workflows/ci.yml`: FOUND (modified, trust_lane_repo_head added; clean-baseline NOT added)
- `scripts/setup_branch_protection.sh`: FOUND (modified, REQUIRED_CHECKS + heredoc extended)
- `.planning/phases/59-ci-trust-lanes-checkpoint-evidence/59-02-SUMMARY.md`: FOUND (this file)

### Verification Results

| Check | Result |
|-------|--------|
| `actionlint .github/workflows/ci.yml` | PASS |
| `shellcheck scripts/setup_branch_protection.sh` | PASS |
| `grep trust_lane_repo_head:` ci.yml | PASS (1) |
| `grep trust_lane_clean_baseline:` ci.yml | PASS (0 — deferred) |
| Repo-head name in setup_branch_protection.sh (array + heredoc) | PASS (2) |
| Clean-baseline name in setup_branch_protection.sh | PASS (0) |
| `setup_branch_protection.sh --print-expected` includes repo-head | PASS |
| upload-artifact pinned SHA reused (no new SHA) | PASS |
| retention-days: 90 on repo-head lane | PASS |
| No `if:` on the job (Pitfall 2) | PASS |
| `mix test test/scripts/required_checks_test.exs` | PASS (2 tests, 0 failures) |
| Repo-head journey local run (repo root) + validator | PASS (5 stages, checkpoint validates, exit 0) |
| No mix.lock changes committed | PASS |

## Self-Check: PASSED

EVID-01 + EVID-04 landed and verified locally. EVID-02 deferred with documented rationale.
Task 2 (branch-protection re-assertion) awaits maintainer action.
