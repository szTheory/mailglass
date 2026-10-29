---
phase: 178-preview-authoring-and-milestone-review
plan: "09"
subsystem: testing
tags: [hosted-ci, draft-pr, workflow-dispatch, owner-approval, stopped, demo-browser-evidence]
status: complete

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "candidate_sha from 178-08 and the pre-approval dry run (task 1)"
provides:
  - "The approved remote actions, run once each: branch pushed to the candidate SHA, draft PR #317, one workflow_dispatch of ci.yml"
  - "Required contexts CI Green and Guard Release Trigger = success for the exact candidate SHA"
  - "Saved, hashed failure logs and a recorded stop: hosted_status stopped, new advisory failure (Demo Browser Evidence)"
affects: [178-10]

candidate_sha: 2bdf18161182beeb286435b556f26e205976e658
plan_head_before: 8cc98c7364b0523fe2cb0d079b1f55a2a2dcce77
plan_head_after: 5d152a7e9714b72b372441544254146eed96a3a7

actuals:
  tokens: 9000
  tasks: 5
  commits: 5

hosted_status: "stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))"
requirements-completed: []

key-decisions:
  - "Classified the Demo Browser Evidence red as a new advisory failure: its failing title (storybook-axe.test.cjs) is in no recorded set, and the Demo matched set is empty by construction. The plan stops; no cost disposition is written."
  - "The Operator Browser Gate failure in the PR run (flows.spec.js:2453 'Phase174 scroll access: Inbound overflow...') is recorded but not matched either; the same job passed in the dispatch run on the same SHA."
  - "No source patch, rerun or second push was made. A fix needs a new freeze and a new 178-09-02 approval (plan rule)."

coverage:
  - id: D1
    description: "No remote write before owner approval; exactly the three authorized actions ran once each; main, release ledger and PR draft state unchanged"
    requirement: "UIQ-08"
    verification:
      - kind: integration
        ref: "178-AUTOMATION.md ### Remote actions and Post-action audit (git ls-remote main = pre_approval_main_sha; PR 317 true OPEN null; both runs attempt 1)"
  - id: D2
    description: "CI Green and Guard Release Trigger success for the candidate SHA"
    requirement: "UIQ-08"
    verification:
      - kind: integration
        ref: "gh api repos/szTheory/mailglass/commits/2bdf18161182beeb286435b556f26e205976e658/check-runs"
  - id: D3
    description: "Hosted identity-bound evidence and cost disposition for the candidate"
    requirement: "UIQ-07"
    verification:
      - kind: manual_procedural
        ref: "NOT MET: Demo Browser Evidence failed before capture in both runs; no 178-COST-DISPOSITION.json"
---

# Phase 178 Plan 09: Hosted candidate evidence Summary

**The candidate is pushed, a never-merged draft PR #317 shows `CI Green` and `Guard Release Trigger` green on the exact SHA, but Demo Browser Evidence fails before capture in both hosted runs, so the plan stopped and no hosted cost disposition exists (UIQ-07 hosted measurement unmet).**

## Owner approval

Checkpoint 178-09-02 was answered by the owner directly in the orchestrator session (genuine owner input): `approve-all`, recorded verbatim as `owner_decision: approve-all` in 178-AUTOMATION.md. Live scope shown at the checkpoint: 351 commits ahead of `origin/main` (656 files, +213365/-2163) and 52 commits ahead of the remote branch (68 files, +13048/-233). Before pushing, the remote branch was re-verified at `25dc21cf...` (an ancestor of the candidate) and main at `8328093e...`.

## Remote actions (UTC, 2026-10-29)

| Time | Command | Result |
|------|---------|--------|
| 15:41:51Z | `git push origin 2bdf18161182beeb286435b556f26e205976e658:refs/heads/gsd/v2.10-ui-repairs-storybook` | fast-forward `25dc21cf..2bdf1816`, no force |
| 15:42:06Z | `gh pr create --draft --base main --head gsd/v2.10-ui-repairs-storybook --title "chore(ui): v2.10 UI repairs review candidate (do not merge)" --body-file .../pr-body.md` | https://github.com/szTheory/mailglass/pull/317 (draft, open, not merged) |
| 15:42:15Z | `gh workflow run ci.yml --ref gsd/v2.10-ui-repairs-storybook` | https://github.com/szTheory/mailglass/actions/runs/40904249445 |

The PR creation started the `pull_request` run https://github.com/szTheory/mailglass/actions/runs/40904235961. Both runs: attempt 1, headSha = candidate, `completed`, `failure`. Nothing else was pushed, rerun, merged or edited.

## Check runs and job outcomes

- `CI Green` = success, `Guard Release Trigger` = success for the candidate SHA. Preview Capture Advisory = success (PR run).
- `Demo Browser Evidence (Docker Compose / Chromium)`: failure in both runs (about 11 to 14 s). Logs: `reference/demo_app/tmp/demo_browser_evidence/ci/40904235961-attempt-1/demo-job.log` (sha256 `66c1f1ac...b54f`) and `.../40904249445-attempt-1/demo-job.log` (sha256 `6703d781...b646`).
- `Operator Browser Gate`: PR run failure (309 passed, 1 failed, 1 skipped, 15.0 min; log sha256 `f1743382...9516`); dispatch run success.

## Classification and stop

The Demo failure is the pre-capture step `node --test ... mailglass_admin/e2e/support/storybook-axe.test.cjs`: `storybook-axe-supplement.cjs:1` requires `@playwright/test`, which is not installed in that job (`MODULE_NOT_FOUND`). No evidence was captured and the artifact upload found no files. The test passes locally because the `mailglass_admin/e2e` dependencies are installed there. This is a candidate source/workflow defect that the 178-08 local gate did not catch. By the plan's B1 stop rule it is a new advisory failure: `hosted_status: stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))`, with `stop_log` set to the dispatch Demo job log. No owner checkpoint was created.

The PR-run Operator Browser Gate failure (`e2e/flows.spec.js:2453:3 ... Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled`) is also in no recorded set. It passed in the dispatch run on the same SHA, which suggests a PR-run (merge-commit) or timing sensitivity. It is recorded, not diagnosed.

## Post-action audit

PR 317: `isDraft true`, `OPEN`, `mergedAt null`. `git ls-remote origin refs/heads/main` = `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b` (equals `pre_approval_main_sha`). `.planning/release-target.json` unchanged. Both runs at attempt 1. No leftover `mailglass-phase178-review-*` containers.

## Task results

| Task | Result | Commit |
|------|--------|--------|
| 178-09-01 dry run (earlier session) | done | 39959c73 |
| 178-09-02 owner checkpoint | `approve-all` | n/a |
| 178-09-03 remote actions | done; `remote_runs_status: completed`, verify OK | 872c0d99, 9198821f |
| 178-09-04 capture and classify | stopped (new advisory failure); verify OK | 4bddf6c3 |
| 178-09-05 cost disposition | "not measured: hosted run stopped"; no `178-COST-DISPOSITION.json`; verify OK | 5d152a7e |

## Deviations from Plan

- **Commit trailer:** the plan text names `Claude Opus 5.5`; commits use `Co-Authored-By: Claude Sonnet 5.5` per the orchestrator's instruction and the current attribution rule. No other deviation.
- No source defect was patched, per the plan.

## Implications for 178-10

Its precondition (`hosted_status: completed`) fails. UIQ-07's hosted measurement and the identity-bound evidence are unmet, and UIQ-08's required CI is only partly evidenced (the two required contexts are green, but the hosted evidence lane is red). Moving on needs a decision outside this plan: a fix to the Demo job (make `@playwright/test` available to the new `storybook-axe.test.cjs` step, or scope that test out of the root Demo job), a new candidate freeze, and a new 178-09-02 approval. PR #317 stays a draft and is not merged. The owner's Phase 178 verification and requirement closure should treat UIQ-07 and UIQ-08 as not met.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Commits found: 872c0d99, 9198821f, 4bddf6c3, 5d152a7e (ancestors of HEAD).
- Saved logs exist and are non-empty under `reference/demo_app/tmp/demo_browser_evidence/ci/`; `178-COST-DISPOSITION.json` is absent by design.
