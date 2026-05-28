---
phase: 59-ci-trust-lanes-checkpoint-evidence
verified: 2026-05-28T17:05:00Z
status: gaps_found
score: 2/3 success criteria verified (EVID-01 code-complete pending live registration; EVID-04 verified; EVID-02 deferred)
overrides_applied: 0
gaps:
  - truth: "Clean-baseline trust lane enforces Hex-first dependency resolution and blocks path-dependency leakage (SC-2 / EVID-02)."
    status: partial
    reason: "DELIBERATELY DEFERRED by maintainer decision 2026-05-28, not forgotten. The `trust_lane_clean_baseline` job is absent from ci.yml because the clean-baseline lane must run `mix verify.reference_host.journey` against the Hex-published siblings (reference/host_app depends on {:mailglass, \"~> 1.2\"}), but `mailglass.trust.run` shipped (Phase 57, commit 293cd74) AFTER the mailglass-v1.2.0 release. The published 1.2.0 package contains no trust task, so a clean-baseline journey would fail 'task could not be found' on every run and block gate-ci-green. The precondition script (scripts/check_clean_baseline_hex_only.sh) IS shipped and verified ready to wire; only the ci.yml job is missing. Tracked in .planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md. EVID-02 is mapped to Phase 59 in REQUIREMENTS.md and is NOT claimed by any later roadmap phase (Phase 60 covers EVID-03, not EVID-02), so it cannot be auto-deferred under the later-phase filter — it is a real, intentional, tracked gap within Phase 59's declared scope."
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "No `trust_lane_clean_baseline` job present (grep count 0). Only `trust_lane_repo_head` was added."
    missing:
      - "Publish a mailglass version that contains the `mailglass.trust.run` task (precondition; outside Phase 59's control)."
      - "Then: bump reference/host_app/mix.exs + mix.lock to that version, add the `trust_lane_clean_baseline` job to ci.yml wiring scripts/check_clean_baseline_hex_only.sh after `mix deps.get`, validate + upload the clean-baseline checkpoint artifact (per 59-02-PLAN.md Task 1 Edit B)."
human_verification:
  - test: "Post-merge branch-protection re-assertion (Plan 02 Task 2, checkpoint:human-action). After commit 56b7855 is on main, run `GH_TOKEN=$BRANCH_PROTECTION_PAT ./scripts/setup_branch_protection.sh main` (or `gh workflow run branch-protection-drift.yml --ref main`)."
    expected: "`gh api repos/szTheory/mailglass/branches/main/protection | jq -r '.required_status_checks.contexts[]'` lists `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` (4 contexts total); `branch_protection_advisory` on the next main CI run reports no drift."
    why_human: "Requires the maintainer's BRANCH_PROTECTION_PAT admin-scoped token, which is not available to an ephemeral agent session. GitHub branch protection is external server-side state; editing setup_branch_protection.sh in code does not change live protection until the script runs against main with admin credentials. Until this runs, EVID-01 enforcement exists in code/config but is NOT yet active on GitHub's live required-check set."
  - test: "(Optional, strongly recommended) End-to-end EVID-01 enforcement self-test: `gh workflow run gate-self-test.yml -f check_name='Trust Lane Repo Head ('` then `gh run watch`."
    expected: "Run summary reports `result=blocked` — proves the new required lane actually blocks a synthetic failing PR end-to-end."
    why_human: "Requires authenticated maintainer gh session with workflow-dispatch permission; opens/closes a real synthetic-failure PR against the live repo."
---

# Phase 59: CI Trust Lanes + Checkpoint Evidence Verification Report

**Phase Goal:** enforce trust proof in required CI lanes and publish machine-readable checkpoint evidence artifacts.
**Verified:** 2026-05-28T17:05:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal decomposes into three roadmap success criteria mapped to EVID-01, EVID-02, EVID-04. Two are achieved in the codebase (one of those pending a live external-state registration that is a maintainer-credentialed checkpoint); one (EVID-02) is deliberately and verifiably deferred with a tracked follow-up.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Repo-head trust lane is required and fails on missing trust checkpoints (SC-1 / EVID-01) | ✓ VERIFIED (code/config) — ⚠️ live registration pending human-action | `ci.yml:810-875` `trust_lane_repo_head` job, literal name `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`, runs `mix verify.reference_host.journey` from repo root + `bash scripts/check_trust_runner_checkpoint.sh` (which exits 1 on missing/malformed checkpoint). Registered in `setup_branch_protection.sh` REQUIRED_CHECKS (line 21) + `print_expected_text` heredoc (line 30); `--print-expected` and `--print-expected-json` both emit it. Not in publish-hex.yml `ADVISORY_LANES` (line 139-141 = only `Operator Browser Gate`) → blocks gate-ci-green by default. No `if:` on the job (Pitfall 2). **Live GitHub branch-protection registration is a pending `checkpoint:human-action` (Plan 02 Task 2) requiring BRANCH_PROTECTION_PAT.** |
| 2 | Clean-baseline trust lane enforces Hex-first resolution and blocks path-dependency leakage (SC-2 / EVID-02) | ✗ FAILED (deferred, tracked) | No `trust_lane_clean_baseline` job in `ci.yml` (grep count 0). Deliberately deferred per maintainer decision 2026-05-28 — documented in 59-02-SUMMARY.md Deviations + `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md`. Root cause confirmed in codebase: `verify.reference_host.journey` is an alias only in root `mix.exs` (lines 53, 225), absent from `reference/host_app/mix.exs`; `reference/host_app/mix.lock` resolves `mailglass 1.2.0` (a release predating the trust runner). Precondition script `scripts/check_clean_baseline_hex_only.sh` IS shipped and verified working. See override suggestion below. |
| 3 | CI emits machine-readable trust checkpoint artifacts for release evidence ingestion (SC-3 / EVID-04) | ✓ VERIFIED | `ci.yml:869-875` uploads `tmp/mailglass_trust_runner/checkpoint.json` as `trust-runner-repo-head-${{ github.run_id }}` via pinned `actions/upload-artifact@ea165f8…` with `if-no-files-found: error` + `retention-days: 90` + exact-file path (Pitfall 6). Data-flow verified: a real `trust_runner.v1` checkpoint exists locally (5 stages, SHA present) and passes the validator (exit 0). |

**Score:** 2/3 success criteria verified (SC-1 code-complete pending live registration; SC-3 fully verified; SC-2 deferred).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/check_clean_baseline_hex_only.sh` | Reusable Hex-source guard, executable, no grep on mix.lock | ✓ VERIFIED | Exists, `-rwxr-xr-x`, shellcheck clean. Happy-path against real `reference/host_app/mix.lock` exits 0 ("Hex-first OK" for all 3 siblings). Missing-lockfile sad path exits 1 with locked message. CR-01 shell-injection fix applied (env-var passing + single-quoted `-e`). Wired by the deferred clean-baseline lane — currently ORPHANED in CI but intentionally so (ready-to-wire precondition). |
| `.github/workflows/gate-self-test.yml` | `check_name` workflow_dispatch input, default `"Tests ("`, plumbed into poll loop | ✓ VERIFIED | Input declared (lines 20-23), default `"Tests ("` preserves existing behavior. WR-01 fix applied: poll uses jq `env.CHECK_NAME` (line 124) not raw `${{ }}` interpolation. actionlint clean. No stale `startswith("Tests (")` literal. |
| `test/scripts/required_checks_test.exs` | ExUnit drift contract REQUIRED_CHECKS ↔ heredoc | ✓ VERIFIED | 2 tests, 0 failures. Name-agnostic drift detection + Phase-27-lock backstop. Async, no DB. |
| `.github/workflows/ci.yml::trust_lane_repo_head` | Required repo-head trust lane | ✓ VERIFIED | Full job present (postgres service, 1.18/OTP27 matrix, pinned SHAs, journey run, validator, GITHUB_STEP_SUMMARY glance, upload). |
| `.github/workflows/ci.yml::trust_lane_clean_baseline` | Required clean-baseline trust lane | ✗ MISSING | Deliberately deferred (see SC-2). |
| `scripts/setup_branch_protection.sh` | Repo-head appended to REQUIRED_CHECKS + heredoc atomically | ✓ VERIFIED | Repo-head name present exactly twice (array line 21 + bullet line 30); clean-baseline name absent (0) per A1 lock; shellcheck clean. |
| `tmp/mailglass_trust_runner/checkpoint.json` | Real `trust_runner.v1` checkpoint | ✓ VERIFIED | schema_version=`trust_runner.v1`, checkpoint_count=5, sha present, 5 stages; validator exit 0. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ci.yml::trust_lane_repo_head.name` | `setup_branch_protection.sh::REQUIRED_CHECKS` | byte-identical `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` | ✓ WIRED | Present in ci.yml once (line 811) + setup script twice (array + heredoc). |
| `ci.yml::trust_lane_repo_head` | `scripts/check_trust_runner_checkpoint.sh` | `bash scripts/check_trust_runner_checkpoint.sh` (line 863) | ✓ WIRED | Validator exists, executable, exits 1 on missing checkpoint (EVID-01 fail-on-missing). |
| `ci.yml::trust_lane_repo_head` (both lanes intent) | `publish-hex.yml::gate-ci-green` | NOT in ADVISORY_LANES → default publish-gate inclusion | ✓ WIRED | ADVISORY_LANES = `['Operator Browser Gate']` only; trust lane blocks publish on failure. |
| `setup_branch_protection.sh::REQUIRED_CHECKS` | GitHub live branch protection on `main` | `gh api -X PUT .../branches/main/protection` (run by maintainer) | ⚠️ NOT YET WIRED | Pending `checkpoint:human-action` (Plan 02 Task 2). Code/config ready; live external state not yet asserted. |
| `ci.yml::trust_lane_clean_baseline` | `scripts/check_clean_baseline_hex_only.sh` | `bash ../../scripts/check_clean_baseline_hex_only.sh` from reference/host_app | ✗ NOT WIRED | Job deferred; script ready-to-wire (precondition only). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `trust-runner-repo-head-*` artifact | `tmp/mailglass_trust_runner/checkpoint.json` | `mix verify.reference_host.journey` (root alias → `mailglass.trust.run`) | Yes — real `trust_runner.v1`, 5 stages, SHA | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Clean-baseline guard happy-path | `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` | exit 0; "Hex-first OK" x3 (mailglass 1.2.0, admin 1.2.0, inbound 0.2.0) | ✓ PASS |
| Clean-baseline guard missing-lockfile | `bash scripts/check_clean_baseline_hex_only.sh /nonexistent/mix.lock` | exit 1; "Clean-baseline Hex-first check blocked: missing or empty" | ✓ PASS |
| REQUIRED_CHECKS drift contract | `MIX_ENV=test mix test test/scripts/required_checks_test.exs` | 2 tests, 0 failures | ✓ PASS |
| Trust checkpoint validator | `bash scripts/check_trust_runner_checkpoint.sh` | exit 0; trust_runner.v1, 5 stages | ✓ PASS |
| Branch-protection print includes repo-head | `setup_branch_protection.sh --print-expected[-json]` | repo-head present (both views) | ✓ PASS |
| shellcheck (both scripts) | `shellcheck scripts/check_clean_baseline_hex_only.sh scripts/setup_branch_protection.sh` | clean | ✓ PASS |
| actionlint (both workflows) | `actionlint ci.yml gate-self-test.yml` | clean | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| EVID-01 | 59-01, 59-02 | Required repo-head trust lane fails on missing journey checkpoints | ✓ SATISFIED (code) / ⚠️ NEEDS HUMAN (live registration) | `trust_lane_repo_head` job + validator + REQUIRED_CHECKS registration in code; live branch-protection PUT pending maintainer PAT (Plan 02 Task 2). |
| EVID-02 | 59-01, 59-02 | Clean-baseline trust lane enforces Hex-first + blocks path leakage | ✗ BLOCKED (deferred) | No `trust_lane_clean_baseline` job; precondition script shipped. Deferred per maintainer decision; tracked in pending todo. Not claimed by any later roadmap phase. |
| EVID-04 | 59-02 | Trust lanes emit machine-readable checkpoint artifacts | ✓ SATISFIED | `trust-runner-repo-head-${{ github.run_id }}` upload, 90-day retention, real `trust_runner.v1` checkpoint validated. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.github/workflows/ci.yml` | 641, 715 | `actions/setup-node@v4` floating tag (not SHA-pinned) | ℹ️ Info (pre-existing, NOT introduced by Phase 59) | Violates CLAUDE.md SHA-pinning policy, but git blame confirms both lines predate Phase 59 (line 641 from 6b4732fc 2026-05-05; line 715 from 26696c4 Phase 999.2-03). Phase 59's own job (`trust_lane_repo_head`) correctly pins every action to a SHA. Flagged by REVIEW.md CR-01/CR-02; out of Phase 59's modified surface. Recommend a separate housekeeping fix, not a Phase 59 blocker. |
| `scripts/check_clean_baseline_hex_only.sh` | — | (was: shell-injection CR-01) | ✓ Resolved | Fixed in commit 544415f — path now passed via env var, `-e` single-quoted. |
| `.github/workflows/gate-self-test.yml` | — | (was: jq expression-injection WR-01) | ✓ Resolved | Fixed in commit 544415f — uses jq `env.CHECK_NAME`. |

No debt markers (TBD/FIXME/XXX/HACK/PLACEHOLDER) in any Phase 59-modified file.

### Human Verification Required

#### 1. Post-merge branch-protection re-assertion (Plan 02 Task 2 — checkpoint:human-action)

**Test:** After commit 56b7855 is on `main`, run `GH_TOKEN=$BRANCH_PROTECTION_PAT ./scripts/setup_branch_protection.sh main` (or `gh workflow run branch-protection-drift.yml --ref main`).
**Expected:** `gh api repos/szTheory/mailglass/branches/main/protection | jq -r '.required_status_checks.contexts[]'` lists `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` (4 contexts total); `branch_protection_advisory` reports no drift on the next `main` CI run.
**Why human:** Requires the maintainer's BRANCH_PROTECTION_PAT admin token (not available to an agent session). Until this runs, EVID-01 enforcement is code-complete but NOT active on GitHub's live required-check set — a PR could theoretically merge with the trust lane red.

#### 2. End-to-end EVID-01 enforcement self-test (optional, recommended)

**Test:** `gh workflow run gate-self-test.yml -f check_name='Trust Lane Repo Head ('` then `gh run watch`.
**Expected:** Run summary reports `result=blocked`.
**Why human:** Requires authenticated maintainer gh session; opens/closes a real synthetic-failure PR.

### Gaps Summary

EVID-01 and EVID-04 are achieved in the codebase: the `trust_lane_repo_head` job is fully wired (journey → validator → pinned upload-artifact with 90-day retention), the repo-head check is registered in `setup_branch_protection.sh` (array + heredoc, contract-tested), the lane defaults to publish-gate-blocking, and a real `trust_runner.v1` checkpoint validates locally. Two items keep the phase short of fully-complete:

1. **EVID-02 (clean-baseline lane) is deliberately deferred** by maintainer decision — a genuine, tracked, intentional gap, not an oversight or a broken implementation. The blocker is milestone sequencing: a clean-baseline journey can only run against a published mailglass release that contains the trust runner, and the runner shipped after v1.2.0. The precondition script is shipped and verified ready. Because EVID-02 is mapped to Phase 59 (not to any later roadmap phase), it counts as an open item within Phase 59's declared scope — hence `gaps_found` rather than `passed`. See the override suggestion below to formally accept this deviation.

2. **EVID-01 live branch-protection registration is a pending `checkpoint:human-action`** requiring the maintainer's admin PAT. The enforcement is complete in code/config; only the external GitHub server-side state assertion remains.

#### Override suggestion for the EVID-02 deferral

The EVID-02 gap is an intentional, maintainer-approved, well-documented deferral with a working precondition and a tracked follow-up todo. To formally accept this deviation and stop it counting against the phase, add to this file's frontmatter:

```yaml
overrides:
  - must_have: "Clean-baseline trust lane enforces Hex-first dependency resolution and blocks path-dependency leakage (SC-2 / EVID-02)."
    reason: "Deliberately deferred 2026-05-28: clean-baseline journey requires a Hex-published mailglass release containing the trust runner (shipped after v1.2.0). Precondition script (check_clean_baseline_hex_only.sh) is shipped and verified; lane wiring tracked in .planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md. Reversible one-job change after republish."
    accepted_by: "<maintainer>"
    accepted_at: "<ISO timestamp>"
```

---

_Verified: 2026-05-28T17:05:00Z_
_Verifier: Claude (gsd-verifier)_
