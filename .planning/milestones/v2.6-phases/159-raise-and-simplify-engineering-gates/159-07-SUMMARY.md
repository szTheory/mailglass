---
phase: 159-raise-and-simplify-engineering-gates
plan: 07
status: complete
completed: 2026-08-18
requirements: [QUAL-05, QUAL-10, QUAL-11]
---

# Plan 159-07 Summary

Every job in all twelve GitHub Actions workflows now has an explicit bounded
timeout. Workflow-wide permissions remain read-only; write scopes moved to the
five jobs that actually mutate GitHub state. Existing triggers, job/check names,
concurrency, environments, package targets, advisory dispositions, and release
effects are unchanged.

All workflow Postgres services use the verified immutable
`postgres:16-alpine` multi-platform digest. The toolchain and demo Dockerfiles
use the verified immutable Hex image for the exact supported Elixir 1.18.4 / OTP
27.3.4.13 patch pair. The toolchain assertion now checks both patches exactly,
and its image includes `jq`, which the extracted release decisions require.
Dependabot covers Docker inputs in both repository Docker roots.

Pure expected-tag selection and active release-target validation now live in
versioned shell scripts with adversarial fixture tests. GitHub API calls,
credentials, protected environments, idempotency, workflow dispatch, release
publication, and other side effects remain inline in their existing workflow
jobs.

## Commits

- `ae857eba` — harden workflow and release policy contracts

## Verification

- exact pinned container confirmed Elixir 1.18.4 / OTP 27.3.4.13
- pinned-container workflow/release suite: 27 tests, 0 failures
- final host workflow/release/classification suite: 94 tests, 0 failures
- `actionlint .github/workflows/*.yml`: passed for all twelve workflows
- release-policy Bash syntax and toolchain POSIX-shell syntax: passed
- formatter and `git diff --check`: passed

No compose files, package versions, release targets, publication behavior,
Phase 160 policy, or admin/operator UI files were changed.
