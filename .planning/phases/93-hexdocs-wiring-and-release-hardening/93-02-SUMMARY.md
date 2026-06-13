---
phase: 93-hexdocs-wiring-and-release-hardening
plan: "02"
subsystem: release-pipeline
tags: [release-please, ci, branch-protection, guard, exclude-paths, RELH-01]
dependency_graph:
  requires: []
  provides: [RELH-01]
  affects: [release-please-config.json, .github/workflows/guard-release-trigger.yml, test/scripts/guard-release-trigger-cases.sh]
tech_stack:
  added: []
  patterns: [exclude-paths, pull_request-guard-workflow, offline-fixture-test]
key_files:
  created:
    - .github/workflows/guard-release-trigger.yml
    - test/scripts/guard-release-trigger-cases.sh
  modified:
    - release-please-config.json
decisions:
  - "Use belt-and-suspenders: exclude-paths (silent, secondary) + guard workflow (loud, primary required check) — neither alone trusted"
  - "Guard triggers on plain pull_request (not pull_request_target): single-maintainer, no fork PRs, lint needs no secrets"
  - "GUARDED array uses only 3 brand/planning paths (brandbook/, .planning/, prompts/) — sibling package dirs NOT included in the workflow guard so a fix(inbound): legitimately touching mailglass_inbound/ PASS"
  - "exclude-paths uses 5 paths (adds mailglass_admin, mailglass_inbound) to stop the second 1.6.x trigger (fix(inbound): bumping core)"
  - "Workflow uses only preinstalled gh — no marketplace actions, no SHA-pin needed for the run step"
  - "Branch-protection required-check registration was blocked by auto-mode classifier — documented as manual follow-up"
metrics:
  duration: "18 minutes"
  completed: "2026-06-13T14:28:19Z"
  tasks_completed: 2
  tasks_documented: 1
  files_created: 2
  files_modified: 1
---

# Phase 93 Plan 02: Release Pipeline Hardening — RELH-01 Summary

**One-liner:** Belt-and-suspenders release guard — exclude-paths defense-in-depth in release-please-config.json plus a new guard-release-trigger PR workflow that fails any bump-triggering PR whose every changed file is under brand/planning paths, preventing the 1.6.x accidental-release pattern.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add exclude-paths to root . release-please package | aa67fa67 | release-please-config.json |
| 2 | Create guard-release-trigger workflow + offline fixture test | f244d755 | .github/workflows/guard-release-trigger.yml, test/scripts/guard-release-trigger-cases.sh |
| 3 | Register guard-release-trigger as required branch-protection check | — (documented follow-up) | — |

## What Was Built

### Task 1: exclude-paths (SECONDARY mechanism)

Added `exclude-paths` to the root `.` package in `release-please-config.json`:

```json
"exclude-paths": ["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]
```

Five paths: the three brand/planning directories (prevent the 1.6.x `feat:` brandbook trigger) plus the two sibling package directories (prevent the second proven 1.6.x trigger: `fix(inbound):` bumping core because root `.` claimed all paths). Sibling package entries (`mailglass_admin`, `mailglass_inbound`) are untouched — they own their own release triggers. Bare directory names, no leading `./`, no trailing `/`.

This is the SILENT defense-in-depth mechanism: commits confined to excluded paths get no bump, no alert. It is secondary; the guard workflow is primary and loud.

### Task 2: guard-release-trigger workflow (PRIMARY mechanism)

New `.github/workflows/guard-release-trigger.yml`:

- Triggers on `pull_request` (NOT `pull_request_target`) — safer for single-maintainer repo, no fork PRs, no secrets needed
- **Deliberately omits `paths-ignore`** — the load-bearing inversion of `ci.yml`; the guard must run on brand/planning-only PRs that `ci.yml` skips
- Least-privilege permissions: `pull-requests: read` + `contents: read`
- No marketplace actions — only preinstalled `gh`; no SHA-pin required
- Decision logic transcribed verbatim from 93-RESEARCH.md Open Item 1 "Check logic":
  - `GUARDED=( "brandbook/" ".planning/" "prompts/" )` — exactly 3 paths (sibling package dirs NOT included; a `fix(inbound):` touching `mailglass_inbound/` correctly PASSES)
  - Conventional-commit title regex capturing type + bang
  - `is_bump` case: `feat|fix` → true, any `!` → true, `BREAKING CHANGE` in title → true
  - Short-circuit exit 0 for non-bump types (before fetching files)
  - `gh pr view "$PR_NUMBER" --json files --jq '.files[].path'` for PR-level aggregate file set
  - Subset test: all files guarded → FAIL with `::error::` annotation; any non-guarded file → PASS

### Task 2: offline fixture test

New `test/scripts/guard-release-trigger-cases.sh`:

All six assertions pass (`bash test/scripts/guard-release-trigger-cases.sh` exits 0):

| Case | Title | Files | Expected | Result |
|------|-------|-------|----------|--------|
| 1: mixed feat: + lib/ | `feat: add sealed-flap brand` | `brandbook/x.svg`, `lib/mailglass/foo.ex` | PASS | OK |
| 2: docs: brand-only | `docs: update brand book` | `brandbook/x.svg`, `.planning/y.md` | PASS | OK |
| 3: feat: brand-only (the bug) | `feat: add sealed-flap brand` | `brandbook/x.svg` | FAIL | OK |
| 3b: fix: planning-only | `fix: correct roadmap entry` | `.planning/ROADMAP.md` | FAIL | OK |
| 4: chore!: planning-only | `chore!: overhaul planning docs` | `.planning/y.md` | FAIL | OK |
| 5: non-conventional title | `Update the README` | `README.md` | PASS | OK |

The decision function in the test is logically identical to the workflow's inline shell, so the test is a faithful offline proof of the guard.

### Task 3: Branch-Protection Required Check (MANUAL FOLLOW-UP REQUIRED)

**Status:** Could not be set automatically — documented as explicit manual follow-up.

**Why:** The auto-mode classifier blocked the `gh api -X PATCH repos/szTheory/mailglass/branches/main/protection/required_status_checks` call (high-severity modification of shared security configuration). Additionally, even if the API call were permitted, the `guard-release-trigger` check name must have run on at least one PR before it appears as a selectable context in the branch-protection picker.

**Current required checks on main** (verified via `gh api`):
- `Support Contract Core (Elixir 1.18 / OTP 27)`
- `Support Contract Admin (Elixir 1.18 / OTP 27)`
- `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
- `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`
- `Installer Host Smoke`

**Manual follow-up steps:**

1. Merge a PR that exercises the guard workflow (any PR against `main` will trigger it — the guard runs on every PR with no `paths-ignore`). This registers `guard-release-trigger` as a known check context.

2. Then add it to main branch protection via either:

   **Option A — GitHub UI:** Settings > Branches > main > "Require status checks to pass" > search for `guard-release-trigger` > add.

   **Option B — `gh` CLI** (run after step 1):
   ```bash
   gh api -X PATCH repos/szTheory/mailglass/branches/main/protection/required_status_checks \
     --field strict=true \
     --field 'contexts[]=Support Contract Core (Elixir 1.18 / OTP 27)' \
     --field 'contexts[]=Support Contract Admin (Elixir 1.18 / OTP 27)' \
     --field 'contexts[]=Compile No Optional Deps (Elixir 1.18 / OTP 27)' \
     --field 'contexts[]=Trust Lane Repo Head (Elixir 1.18 / OTP 27)' \
     --field 'contexts[]=Installer Host Smoke' \
     --field 'contexts[]=guard-release-trigger'
   ```

Until step 2 is complete, the guard workflow will run and report status on PRs but will NOT block merges. The `exclude-paths` defense-in-depth in `release-please-config.json` (Task 1) is already active as the secondary silent mechanism.

## Verification Results

| Check | Result |
|-------|--------|
| `jq -e '.packages["."]["exclude-paths"]'` confirms all 5 entries present | PASS |
| Bare names (no leading `./`, no trailing `/`) | PASS |
| `jq -e '.' release-please-config.json` (valid JSON) | PASS |
| No `exclude-paths` on mailglass_admin or mailglass_inbound entries | PASS |
| `bash test/scripts/guard-release-trigger-cases.sh` exits 0 | PASS |
| Workflow uses `pull_request` (not `pull_request_target`) | PASS |
| Workflow has NO `paths-ignore` | PASS |
| GUARDED array: exactly 3 paths (brandbook/, .planning/, prompts/) | PASS |
| No marketplace actions (no SHA-pin required) | PASS |
| Least-privilege permissions: pull-requests: read + contents: read | PASS |
| Branch-protection required-check set | MANUAL FOLLOW-UP (see Task 3 above) |

## Deviations from Plan

### Auto-attempted and documented: Task 3 branch-protection API call

**Found during:** Task 3
**Issue:** The `gh api -X PATCH` call to add `guard-release-trigger` to branch-protection required status checks was blocked by the Claude Code auto-mode security classifier (high-severity modification of shared security configuration). Additionally, the GitHub API requires a check to have run at least once on a PR before it can be added as a required context.
**Resolution:** Per the `checkpoint_resolution` instructions in the prompt, the outcome is documented as an explicit manual follow-up in the SUMMARY rather than silently skipping. The two-step process (merge a PR to register the check, then add it via UI or `gh` CLI) is documented above.
**Classification:** Expected outcome, not a bug. The `exclude-paths` Task 1 mechanism is already providing silent defense-in-depth.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The new workflow reads PR metadata via the default `GITHUB_TOKEN` (read-only `pull-requests: read`). No new trust boundaries opened. STRIDE threats T-93-04 through T-93-SC are addressed by the implementation as designed.

## Known Stubs

None. This plan creates CI infrastructure (a guard workflow, an exclude-paths config, an offline fixture test). There is no UI rendering, no data source wiring, and no placeholder content.

## Self-Check: PASSED

- `release-please-config.json` — FOUND and modified (aa67fa67)
- `.github/workflows/guard-release-trigger.yml` — FOUND, created (f244d755)
- `test/scripts/guard-release-trigger-cases.sh` — FOUND, created (f244d755)
- Commit aa67fa67 — FOUND (`git log --oneline` confirms)
- Commit f244d755 — FOUND (`git log --oneline` confirms)
- All fixture test cases pass (`bash test/scripts/guard-release-trigger-cases.sh` exits 0)
- Branch-protection follow-up documented in Task 3 section
