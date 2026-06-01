# Phase 54 PR and Branch Triage Record

Generated: 2026-06-01T17:08:50Z

## Canonical v1.3 PR

- #41 `chore(v1.3): release discipline and repo truth hygiene`
  - URL: https://github.com/szTheory/mailglass/pull/41
  - Branch: `work/v1.3-release-discipline`
  - Implementation base: `fab1384 chore: add release discipline hygiene automation`
  - Final head SHA: `265a6f299c88ebebaa69aa8375de9af77a60ff7f`
  - Merge commit: `fd4f3c98fe1d67aac8a57593c588b6748914b441`
  - Status: merged 2026-05-27T07:44:41Z
  - Result: v1.3 release-discipline hygiene work landed on `main`.

## PR Dispositions

| PR | Disposition | Reason |
|----|-------------|--------|
| #17 | Closed | Superseded by completed inbound provider work already on main; the PR was conflicting stale duplicate work. |
| #27 | Closed | Superseded by #41; `swoosh` was `1.25.3` in v1.3, newer than the PR's `1.25.1`. |
| #28 | Closed | Superseded by #41; `oban` was `2.22.1` in v1.3, matching the PR. |
| #29 | Closed | Superseded by #41; `sigra` was `1.20.0` in v1.3, matching the PR. |
| #30 | Closed | Superseded by #41; its post-publish smoke semver guard was folded into v1.3 at `7317d3b`. |
| #37 | Closed | Superseded by #41; its `actions/setup-node` v6 change was folded into v1.3 at `7317d3b`. |
| #38 | Closed | Superseded by #41; `phoenix` was `1.8.7` in v1.3, matching the PR. |
| #39 | Closed | Superseded by #41; `postgrex` was `0.22.2` in v1.3, newer than the PR's `0.22.1`. |

## Current Open PRs

These PRs opened after the Phase 54 v1.3 closeout window and are current release-hygiene blockers as of 2026-06-01:

| PR | State | Head | Note |
|----|-------|------|------|
| #45 | Open | `dependabot/github_actions/actions/upload-artifact-7.0.1` | Newer Dependabot PR, not part of the original Phase 54 backlog. |
| #46 | Open | `dependabot/hex/mjml-6.0.0` | Newer Dependabot PR, not part of the original Phase 54 backlog. |
| #47 | Open | `dependabot/hex/swoosh-1.26.0` | Newer Dependabot PR, not part of the original Phase 54 backlog. |
| #48 | Open | `dependabot/hex/oban-2.23.0` | Newer Dependabot PR, not part of the original Phase 54 backlog. |
| #49 | Open | `dependabot/hex/floki-0.38.3` | Newer Dependabot PR, not part of the original Phase 54 backlog. |
| #50 | Open | `dependabot/hex/phoenix_live_view-1.1.31` | Newer Dependabot PR, not part of the original Phase 54 backlog. |

## Branch Decisions

Remote branches for the closed Dependabot/workflow PRs were pruned by GitHub after closure.

Current local branch inventory:

- `main` - local branch is clean but ahead of `origin/main` by 163 commits; preserve, do not rewrite.
- `feat/phase-16-ses-webhook-provider` - stale PR #17 branch still exists remotely; PR closed as superseded, branch retained as historical work.
- `preserve/local-main-20260508-1` - intentional archive; keep.
- `preserve/release-discipline-preclean-20260527` - intentional archive; keep.
- `release/v0.2.0-prep` - local branch tracks a gone remote; retained because it contains unique historical release work.
- `release/v0.2.0-trigger` - local branch tracks a gone remote; retained because it contains unique historical release trigger work.
- `worktree-agent-a0e139cddf6eef359` - retained; old worktree branch with unique historical planning output.
- `worktree-agent-a82841ff64848c7d9` - retained; old worktree branch with unique historical planning output.
- `worktree-agent-a03452eb610c29dd4`, `worktree-agent-a1a64a7bcc7a941bf`, `worktree-agent-a1f37831fe9b069db`, `worktree-agent-a4b8944f02de15d8e`, `worktree-agent-a77b1dfd9cedca003`, `worktree-agent-a9be17d3501b51620` - retained because the current checkout has later local milestone history and these branches were not safely pruned during this retrospective closeout.

No local branches were deleted during this run. `preserve/*` branches are intentional archives.
