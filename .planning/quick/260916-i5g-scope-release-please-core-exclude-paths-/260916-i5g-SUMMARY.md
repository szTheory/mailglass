---
task: 260916-i5g
title: Scope release-please core exclude-paths
subsystem: release-engineering
tags: [release-please, config, hex-publish]
dependency-graph:
  requires: []
  provides: [corrected-release-please-core-exclude-paths]
  affects: [PR-222-closure]
tech-stack:
  added: []
  patterns: [release-please-elixir-package-config]
key-files:
  created: []
  modified:
    - release-please-config.json
decisions:
  - "Widened core exclude-paths from 5 to 12 entries, adding .github, ci, dev, reference, scripts, test, test_js to the pre-existing brandbook, .planning, prompts, mailglass_admin, mailglass_inbound."
  - "Used chore: commit type (not feat:/fix:) because release-please-config.json sits at repo root and is itself claimed by the core package under exclude-paths — a feat:/fix: title would have registered this very fix as a core library change in the next proposal."
metrics:
  duration: "~10 minutes"
  completed: 2026-09-16
status: complete
actuals:
  tokens: 3500
  tasks: 2
  commits: 1
---

# Quick Task 260916-i5g: Scope release-please core exclude-paths Summary

Widened the `mailglass` core package's `exclude-paths` in `release-please-config.json` from 5 to
12 entries so internal tooling directories (`.github`, `ci`, `dev`, `reference`, `scripts`,
`test`, `test_js`) no longer register conventional-commit tooling changes as core library
releases.

## What Was Done

**Task 1 — Widen core exclude-paths (commit `ea650df1`, on branch `chore/release-please-scope-core-paths`):**

Edited `release-please-config.json`'s `packages["."]["exclude-paths"]` array via a single `Edit`
call, replacing:

```
["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]
```

with:

```
[".github", ".planning", "brandbook", "ci", "dev", "mailglass_admin", "mailglass_inbound", "prompts", "reference", "scripts", "test", "test_js"]
```

Ran the plan's full automated verification (`jq empty`, exact sorted-array match, `last-release-sha`
byte-identity, `mailglass_admin`/`mailglass_inbound`/`plugins`/`$schema` byte-identity via md5
comparison against `HEAD`, no published/release-signalling path excluded, every excluded path
resolves to at least one Git-tracked file). All checks passed — `CONFIG_OK`.

**Task 2 — Commit the corrected config:**

Per the branch_context in this run's instructions, the orchestrator had already created and
checked out branch `chore/release-please-scope-core-paths` from `main`. Rather than creating a
new branch, pushing, opening a PR, and merging (as the plan's Task 2 literally describes), this
execution was scoped to **stage and commit only** — the orchestrator owns push/PR/merge for this
branch.

- Staged by exact pathspec: `git add -- release-please-config.json` (never `-A`, never `.`, never
  `commit -a`).
- Verified `git status --porcelain` showed only `release-please-config.json` staged before
  committing; the user's ` M .planning/config.json` and the untracked quick-task directory were
  confirmed untouched.
- Committed with title `chore(release): scope core exclude-paths to shippable library code` and
  the required `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` trailer.
- Post-commit `git show --stat HEAD` confirms exactly one file changed, one insertion, one
  deletion — the `exclude-paths` line only.
- Post-commit `git status --porcelain` confirms ` M .planning/config.json` and the untracked
  quick-task directory are still present and unmodified.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written for Tasks 1 and 2, with one scope adjustment described
below (not a deviation rule, but a binding instruction from this run's orchestrator).

**Scope adjustment (per this run's explicit instructions, not a Rule 1-4 deviation):** Task 2's
plan text describes creating a new branch, pushing, opening a PR, waiting for CI, and
squash-merging. This run's `<branch_context>` stated the orchestrator had already created and
checked out `chore/release-please-scope-core-paths` and explicitly forbade switching branches,
pushing, or opening a PR — "the orchestrator handles both." Execution was therefore limited to
the config edit, its verification, and a local commit on the existing branch. The orchestrator is
responsible for pushing this branch, opening the PR, merging to `main`, and only then proceeding
to Task 3.

## Task 3 — Deliberately Deferred

**Task 3 (closing PR #222) was NOT executed in this run, per explicit scope restriction.** No
`gh pr close` or `gh pr comment` command was run against #222. PR #222 remains `OPEN` exactly as
observed in the plan's `<planning_observations>`.

**Binding ordering reminder for the orchestrator:** per the plan's `<ordering_decision>`, Task 3
MUST NOT run until the commit made here (`ea650df1`, or its squash-merged equivalent) is on
`origin/main`. Closing #222 before that merge would let the very next push to `main` regenerate
the same stale `2.6.0`/`2.6.0`/`2.3.0` proposal under the OLD (unfixed) config.

**Drafted brand-voice closure comment, carried forward verbatim for the orchestrator to use with
`gh pr close 222 --comment "<comment>"` once the merge lands:**

> Closing this proposal. It has no adopter-visible payload.
>
> The core package is rooted at `.`, so it claimed every repository path that `exclude-paths` did
> not name — including `scripts/`, `.github/`, `dev/`, `test/`, `reference/`, `ci/`, and
> `test_js/`. Conventional-commit types on the repository's own tooling therefore registered as
> core library features and fixes. The changelog here is phase 162–164 GSD and CI work, not
> mailglass.
>
> Since `mailglass-v2.5.0` there are no line changes in `mailglass_admin/lib/` or
> `mailglass_inbound/lib/`, and exactly one line changed in core `lib/` — a version string in
> `lib/mix/tasks/mailglass.docs.check.ex`. Merging this would publish three version bumps to Hex
> with nothing in them.
>
> `release-please-config.json` now scopes the core package to shippable library code.
> release-please will open a fresh proposal on the next push to `main`, built from the corrected
> configuration.

Task 3's plan also requires, after closing: `mergedAt` remains `null`, no version bump, no
`last-release-sha` edit, no workflow dispatch, and confirming no open `chore: release main`
proposal remains (release-please should regenerate #222's replacement automatically off the
corrected config on the next push to `main`).

## Self-Check: PASSED

- FOUND: `release-please-config.json` — exists, contains the 12-entry exclude-paths array
  (verified via `jq`).
- FOUND: commit `ea650df1` — `git log --oneline --all | grep ea650df1` confirms presence on
  `chore/release-please-scope-core-paths`.
- CONFIRMED: `.planning/config.json` still shows ` M` (dirty, untouched) in `git status --porcelain`
  after the commit.
- CONFIRMED: no `.gitignore`/staging changes made to `.planning/quick/260916-i5g-.../` — it remains
  untracked (`??`), left for the orchestrator's docs commit.
