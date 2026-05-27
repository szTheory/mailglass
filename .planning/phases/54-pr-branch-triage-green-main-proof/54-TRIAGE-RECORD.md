# Phase 54 PR and Branch Triage Record

Generated: 2026-05-27T06:18:00Z

## Canonical v1.3 PR

- #41 `chore(v1.3): release discipline and repo truth hygiene`
  - URL: https://github.com/szTheory/mailglass/pull/41
  - Branch: `work/v1.3-release-discipline`
  - Head SHA: `5f62410d9fe7fc6994ad916f90e4d72eb5c3725c`
  - Status: open, not merged
  - Reason: all required branch-protection checks passed, but the advisory full suite failed.

## PR Dispositions

| PR | Disposition | Reason |
|----|-------------|--------|
| #17 | Closed | Superseded by completed inbound provider work already on main; the PR was conflicting stale duplicate work. |
| #27 | Closed | Superseded by #41; `swoosh` is `1.25.3` in v1.3, newer than the PR's `1.25.1`. |
| #28 | Closed | Superseded by #41; `oban` is `2.22.1` in v1.3, matching the PR. |
| #29 | Closed | Superseded by #41; `sigra` is `1.20.0` in v1.3, matching the PR. |
| #30 | Closed | Superseded by #41; its post-publish smoke semver guard was folded into v1.3 at `7317d3b`. |
| #37 | Closed | Superseded by #41; its `actions/setup-node` v6 change was folded into v1.3 at `7317d3b`. |
| #38 | Closed | Superseded by #41; `phoenix` is `1.8.7` in v1.3, matching the PR. |
| #39 | Closed | Superseded by #41; `postgrex` is `0.22.2` in v1.3, newer than the PR's `0.22.1`. |

## Branch Decisions

Remote branches for the closed Dependabot/workflow PRs were pruned by GitHub after closure and removed locally by `git fetch --prune`.

Local branch inventory after pruning:

- `work/v1.3-release-discipline` - active v1.3 branch; keep.
- `main` - local main is preserved; not modified during Phase 54 execution.
- `feat/phase-16-ses-webhook-provider` - stale PR #17 branch still exists remotely; PR closed as superseded, branch retained for now because it is not merged into the active v1.3 branch.
- `release/v0.2.0-prep` - local branch tracks a gone remote; retained because it contains unique historical release work.
- `release/v0.2.0-trigger` - local branch tracks a gone remote; retained because it contains unique historical release trigger work.
- `worktree-agent-a0e139cddf6eef359` - retained because it is not merged into the active v1.3 branch.
- `worktree-agent-a82841ff64848c7d9` - retained because it is not merged into the active v1.3 branch.
- `preserve/local-main-20260508-1` - intentional archive; keep.
- `preserve/release-discipline-preclean-20260527` - intentional archive; keep.

No local branches were deleted because `git branch --merged HEAD` showed only the active branch.

