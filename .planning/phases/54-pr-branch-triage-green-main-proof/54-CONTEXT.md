# Phase 54: PR/Branch Triage + Green Main Proof - Context

**Gathered:** 2026-05-27
**Status:** Ready for execution planning
**Milestone:** v1.3 Release Discipline & Repo Truth

## Purpose

Phase 52/53 produced the v1.3 release-discipline implementation on `work/v1.3-release-discipline` at commit `fab1384`. Phase 54 closes the remaining repo-truth blockers: open PR ambiguity, stale branch ambiguity, pushed-branch CI evidence, branch-protection evidence, and final hygiene JSON.

The phase is operational rather than feature-building. It should not rewrite the hygiene implementation unless execution discovers a concrete defect. The default path is to push the current v1.3 branch, open or update its PR, dispose the open backlog against that known integration branch, and record evidence.

## Inputs

- Implementation branch: `work/v1.3-release-discipline`
- Implementation commit: `fab1384 chore: add release discipline hygiene automation`
- Preserved local-state branch: `preserve/release-discipline-preclean-20260527`
- Canonical command: `mix mailglass.repo.hygiene --check --format json`
- Branch-protection verifier: `scripts/verify-branch-protection.sh`
- Maintainer runbook: `MAINTAINING.md`
- Hygiene workflow: `.github/workflows/repo-hygiene.yml`

## Decisions

### D-54-01: Treat `fab1384` as the integration base

Phase 54 starts from the v1.3 hygiene implementation already committed on `work/v1.3-release-discipline`. Do not squash, rewrite, or recut the implementation unless verification identifies a required fix.

### D-54-02: Use explicit PR dispositions

Every currently open PR must end in one of three states: merged, closed as superseded/stale, or deferred with a recorded reason and owner/status. Ambiguous open PRs are not release-ready.

Current PRs to triage:

- #39 `dependabot/hex/postgrex-0.22.1` - v1.3 lock refresh already carries `postgrex` beyond this version; likely superseded after v1.3 branch lands.
- #38 `dependabot/hex/phoenix-1.8.7` - v1.3 lock refresh carries `phoenix` 1.8.7; likely superseded after v1.3 branch lands.
- #37 `dependabot/github_actions/actions/setup-node-6` - not covered by the v1.3 lock refresh; inspect, refresh, and merge if still applicable and CI/policy pass.
- #30 `cleanup/v0-1-2-batch` - stale draft; close unless diff audit finds unique release-engineering work that is not already present.
- #29 `dependabot/hex/sigra-1.20.0` - v1.3 lock refresh carries `sigra` 1.20.0; likely superseded after v1.3 branch lands.
- #28 `dependabot/hex/oban-2.22.1` - v1.3 lock refresh carries `oban` 2.22.1; likely superseded after v1.3 branch lands.
- #27 `dependabot/hex/swoosh-1.25.1` - v1.3 lock refresh carries `swoosh` beyond this version; likely superseded after v1.3 branch lands.
- #17 `feat/phase-16-ses-webhook-provider` - old human feature branch; likely superseded by v1.2 inbound SES provider work, but requires diff audit before closure.

### D-54-03: Preserve archive branches unless proved safe

Do not delete `preserve/*` branches. They are explicit safety archives. Other local branches may be pruned only when merged or documented as having no unique work needed for current release truth.

Known local branches at planning time:

- `feat/phase-16-ses-webhook-provider`
- `main`
- `preserve/local-main-20260508-1`
- `preserve/release-discipline-preclean-20260527`
- `release/v0.2.0-prep`
- `release/v0.2.0-trigger`
- `work/v1.3-release-discipline`
- `worktree-agent-a0e139cddf6eef359`
- `worktree-agent-a82841ff64848c7d9`

### D-54-04: Evidence is the phase output

Do not claim v1.3 release readiness until CI runs on the pushed v1.3 SHA and branch protection is either verified or explicitly recorded as unavailable due to missing credentials. The final hygiene JSON should be captured even if the only remaining blocker is an intentionally open v1.3 PR awaiting merge.

## Required Artifacts

- `.planning/phases/54-pr-branch-triage-green-main-proof/54-TRIAGE-RECORD.md`
- `.planning/phases/54-pr-branch-triage-green-main-proof/54-GREEN-MAIN-EVIDENCE.md`

## Non-Goals

- Do not add new product features.
- Do not silently delete archived local state.
- Do not force-push or rewrite history as part of normal execution.
- Do not bypass Hex publish environment approval or branch-protection policy.
