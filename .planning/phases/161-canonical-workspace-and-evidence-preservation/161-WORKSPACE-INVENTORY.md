# Phase 161 Workspace Inventory

## Pre-Mutation Snapshot

**Capture time (UTC):** 2026-08-22T15:35:22Z  
**Capture HEAD / phase-base marker:** `3e7ac266a6c1a7d1ebc8b2f82ec68ba65d42a4ce` (`docs(161): create phase plan`)  
**Capture root:** `/Users/jon/projects/mailglass`  
**Method:** fixed, read-only Git commands only. No checkout, ref creation, reset, merge, prune, removal, force operation, or cleanup command was run.

The matrix is sorted by category and bytewise identity within each category. An equal object ID or shared evidence reference never collapses two identities into one row. `assessment pending` means the item is not cleanup-eligible; `retain` preserves local evidence and `handoff` explicitly reserves interpretation for the later phase.

| ID | category | identity/path | observed state | content/unique-work evidence | reachability evidence | evidence ref | disposition | preservation/handoff | permitted next action | outcome |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CANONICAL | canonical workspace | `/Users/jon/projects/mailglass` | `main`, upstream `origin/main`; production source is clean, with the orchestrator-created tracking diff `M .planning/STATE.md`; live count `behind 0 / ahead 17`; **non-release-clean** until upstream settlement | `git status --short --branch` captured the single tracking diff; `git log --left-right --cherry-mark --oneline '@{upstream}...HEAD'` captured all 17 ahead commits | `git rev-parse HEAD` = `3e7ac266a6c1a7d1ebc8b2f82ec68ba65d42a4ce`; `git rev-list --left-right --count '@{upstream}...HEAD'` = `0 17` | CM-01 | retain | sole canonical path; Phase 162 settles upstream/release meaning | commit this ledger only; no normalization | capture complete; non-release-clean verdict recorded |
| WT-01 | linked worktree | `/Users/jon/projects/mailglass` | canonical `main`; status above; not locked; not prunable | `git -C '/Users/jon/projects/mailglass' status --short --branch` = `## main...origin/main [ahead 17]`, `M .planning/STATE.md` | `git -C '/Users/jon/projects/mailglass' rev-parse HEAD` = `3e7ac266a6c1a7d1ebc8b2f82ec68ba65d42a4ce` | WT-01-CMD | retain | canonical row cross-reference; tracking diff belongs to phase workflow | no cleanup | captured |
| WT-02 | linked worktree | `/private/tmp/mailglass-release-auth.tkJNd5` | clean, branch `chore/authorize-release-91353`, not locked, not prunable | `git -C '/private/tmp/mailglass-release-auth.tkJNd5' status --short --branch` = `## chore/authorize-release-91353...origin/chore/authorize-release-91353` | `git -C '/private/tmp/mailglass-release-auth.tkJNd5' rev-parse HEAD` = `256af3e1030c3cf0070207643809e36d715300eb` | WT-02-CMD | assessment pending / retain | assess branch range before any normal Git-managed action | range assessment in Plan 02 | captured |
| WT-03 | linked worktree | `/private/tmp/mailglass-release-candidate.3B6UyC` | dirty, detached, not locked, not prunable; three modified tracked publish summaries | `git -C '/private/tmp/mailglass-release-candidate.3B6UyC' status --short --branch` lists `M` for `mailglass`, `mailglass_admin`, and `mailglass_inbound` publish summaries | `git -C '/private/tmp/mailglass-release-candidate.3B6UyC' rev-parse HEAD` = `d0369ba76c1f5d033d4d10b804050fa76c784756` | WT-03-CMD; release rows pending | assessment pending / retain | preserve dirty detached candidate; remote meaning is Phase 162 | content assessment and named preservation/handoff only | captured; not cleanup-eligible |
| WT-04 | linked worktree | `/private/tmp/mailglass-release-fix.jaCDGT` | clean, branch `fix/protected-release-freshness`, not locked, not prunable | `git -C '/private/tmp/mailglass-release-fix.jaCDGT' status --short --branch` = `## fix/protected-release-freshness...origin/fix/protected-release-freshness` | `git -C '/private/tmp/mailglass-release-fix.jaCDGT' rev-parse HEAD` = `63ed7997030012695c900b24f93075038e8d940d` | WT-04-CMD | assessment pending / retain | assess branch range before any normal Git-managed action | range assessment in Plan 02 | captured |
| WT-05 | linked worktree | `/private/tmp/mailglass-release-recovery.jvBKbu` | clean, branch `fix/release-ci-recovery`, not locked, not prunable | `git -C '/private/tmp/mailglass-release-recovery.jvBKbu' status --short --branch` = `## fix/release-ci-recovery...origin/fix/release-ci-recovery` | `git -C '/private/tmp/mailglass-release-recovery.jvBKbu' rev-parse HEAD` = `271f4145bb4d06366023bf7fb6ae53b473691453` | WT-05-CMD | assessment pending / retain | assess branch range before any normal Git-managed action | range assessment in Plan 02 | captured |
| WT-06 | linked worktree | `/private/tmp/mailglass-release-retire.mXaBmq` | clean, branch `chore/retire-invalid-release-candidate`, not locked, not prunable | `git -C '/private/tmp/mailglass-release-retire.mXaBmq' status --short --branch` = `## chore/retire-invalid-release-candidate...origin/chore/retire-invalid-release-candidate` | `git -C '/private/tmp/mailglass-release-retire.mXaBmq' rev-parse HEAD` = `40c5c888f29f987dc589e120bd131c67bbfb503c` | WT-06-CMD | assessment pending / retain | assess branch range before any normal Git-managed action | range assessment in Plan 02 | captured |

## Canonical Main Evidence

The root is the sole `CANONICAL` row. Its upstream is `origin/main`; capture-time divergence is `0 behind, 17 ahead`. Therefore a clean production source alone does not make it release-clean: it is explicitly **non-release-clean** until the upstream relationship is settled. The `M .planning/STATE.md` status line is the known orchestrator phase-start tracking diff, not unclassified product work.

The locked **seven-commit** v2.6 archive/retrospective and v2.7 initialization semantic subrange is listed separately from later Phase 161 planning commits:

1. `7e039bc6` — `chore: archive v2.6 milestone files`
2. `5a19ddfb` — `chore: remove v2.6 live milestone artifacts`
3. `c723f357` — `docs: update retrospective for v2.6`
4. `5a5e0950` — `docs: create milestone v2.7 roadmap (4 phases)`
5. `d6a050a0` — `docs: define milestone v2.7 requirements`
6. `d583fa0c` — `docs: complete project research`
7. `06ac996c` — `docs: start milestone v2.7 Repository Stewardship & Operational Hygiene`

Later commits `2b05bdab` through `3e7ac266` are Phase 161 context, research, validation, pattern, plan, correction, and plan-creation commits. The live count is intentionally capture-time evidence; the immutable semantic claim is the seven-commit subrange, not a permanently fixed ahead total.

## Command Evidence

### CM-01 — Canonical main

- **Capture time:** `2026-08-22T15:35:22Z`; **exit codes:** all `0`.
- `git status --short --branch` → `## main...origin/main [ahead 17]`; ` M .planning/STATE.md`
- `git branch --show-current` → `main`
- `git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'` → `origin/main`
- `git rev-list --left-right --count '@{upstream}...HEAD'` → `0 17`
- `git rev-parse HEAD` → `3e7ac266a6c1a7d1ebc8b2f82ec68ba65d42a4ce`
- `git log --left-right --cherry-mark --oneline '@{upstream}...HEAD'` → 17 `>` rows, from `7e039bc6` through `3e7ac266`; semantic classification is recorded above.

### WT-01-CMD through WT-06-CMD — Registered worktrees

- **Capture time:** `2026-08-22T15:35:22Z`; **exit codes:** all `0`.
- Command: `git worktree list --porcelain -z` decoded as NUL-delimited porcelain (no direct `.git` inspection). It yielded **6** records: the six `WT-*` rows above, with no `locked` or `prunable` attributes.
- Command per exact registered path: `git -C '<path>' status --short --branch` and `git -C '<path>' rev-parse HEAD`. Concise results and exact HEADs are retained directly in each matrix row.

## Capture Contract

This is the first immutable pre-mutation evidence block. Any later observation must append a new timestamp and HEAD rather than silently rewriting this block. Empty categories will be represented with explicit `NONE-*` rows, never by omission, in the category expansion snapshot.
