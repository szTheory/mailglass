# Pitfalls Research

**Domain:** Mailglass v2.7 repository stewardship and operational hygiene
**Researched:** 2026-08-21
**Confidence:** HIGH for repository-specific findings; LOW for the two external operational references.

## Critical Pitfalls

### Pitfall 1: Destructive cleanup erases the only copy of release work

**What goes wrong:** A maintainer treats the five linked `/private/tmp/mailglass-release-*` worktrees, detached candidate, stash, or divergent branches as disposable because v2.6 is published. One can still contain unmerged recovery work, a unique ledger mutation, or the only readable release evidence. Deleting directories directly also leaves Git worktree metadata behind.

**Why it happens:** `main` is ahead of `origin/main`, the root has active planning edits, and the release branches have similar names and partially overlapping commits. That makes a visual inventory misleading; a clean-looking worktree is not proof that its commits are reachable from canonical `main`.

**How to avoid:** Make a read-only disposition ledger first: path, branch/detached SHA, clean/dirty status, upstream, `merge-base --is-ancestor <sha> main`, unique commits, PR/release purpose, and proposed outcome. Preserve every non-reachable or dirty item with a named local branch or bundle before removal. Remove only a verified-clean linked worktree through `git worktree remove <absolute-path>`; never use `--force`, `rm -rf`, or branch deletion as the discovery mechanism. Run `git worktree prune --dry-run` before (and only after necessary) metadata pruning.

**Warning signs:** A detached candidate is present; `git stash list` is non-empty; worktree HEADs differ from main; a branch cannot be deleted because a worktree has it checked out; any item has untracked files; or `git worktree list --porcelain` still lists a supposedly removed path.

**Verification:** Archive the inventory in the phase evidence. For every retired branch/worktree, record its SHA and prove either ancestry from `main` or the preservation ref/bundle. Re-run `git worktree list --porcelain`, `git status --short --branch`, `git stash list`, and `git fsck --no-reflogs` after cleanup. The only desired end state is one canonical `main` workspace with no unexplained linked worktree, stash, ahead/behind drift, or dirty file.

**Phase to address:** Phase 1 — canonical-workspace inventory and recoverable disposition.

---

### Pitfall 2: A repaired schedule reports success without proving the scheduled control ran

**What goes wrong:** `release-please`, `repo-hygiene`, or post-publish smoke is edited or manually dispatched, then declared recovered from YAML validity or one green ad hoc run. The scheduled path remains inactive, lacks access to the protected branch-protection token, targets the wrong ref/SHA, or emits no usable artifact.

**Why it happens:** These workflows are trigger-sensitive. `repo-hygiene` needs GitHub and protection visibility; release-please has proposal and protected-digest paths; publication self-heal probes exact CI runs on an exact SHA. A schedule is an operational promise, not a unit-test-only behavior.

**How to avoid:** Preserve the current cron cadence and permissions unless an observed failure requires a narrow change. Add or retain a test/contract for each trigger-sensitive branch. Recover with a `workflow_dispatch` that exercises the same checkout/ref and environment, then inspect the resulting run, summary, and artifact—not just its conclusion. For scheduled workflows, compare the next actual scheduled run to the manual control run and capture both URLs/IDs in the disposition evidence.

**Warning signs:** Workflow success with “Repo hygiene did not produce an artifact”; `unknown` protection status presented as pass; a run whose `headSha` is not the inspected SHA; schedule-only runs absent after cron time; or a manual dispatch succeeding where schedule has different credentials.

**Verification:** `mix mailglass.repo.hygiene --check --format json` must distinguish `pass`, `blocked`, and `unknown`; its scheduled workflow must upload `repo-hygiene.json` on `always()`. For release and smoke, prove the selected ref/SHA, package/tag, digest, and workflow run identifiers match the release ledger. Validate workflow syntax and run the focused workflow/script contract tests; then retain one successful scheduled-run observation per repaired workflow.

**Phase to address:** Phase 2 — scheduled automation recovery and truthful evidence.

---

### Pitfall 3: Blocked release state is “cleared” by bypassing the immutable release protocol

**What goes wrong:** A stale release PR or candidate is merged, deleted, re-run, or manually version-bumped based on appearance instead of its precise state. That can recreate an existing tag, publish a partially released three-package set, or authorize a proposal whose package content no longer matches the protected candidate digest.

**Why it happens:** The repository intentionally has a nonstandard sequence: proposal-only release-please, dual-authorized protected dispatch, exact candidate/content digest validation, ordered core → admin → inbound publication, and post-publish handoff. Existing history includes an already-tagged PR failure mode and invalidated candidates.

**How to avoid:** Classify the blocked PR before mutation: open/closed, head/base SHA, required checks, labels, expected tags, GitHub release existence, Hex versions, `.planning/release-target.json` status, and whether its package-content digest still equals protected main. Use the existing policy wrappers (`release_policy_expected_tags.sh`, `release_policy_hex_release_state.sh`, `release_policy_validate_target.sh`, `verify_published_release.sh`) as the authority. Choose one explicit disposition: retain/recover via the exact digest path, retire as invalidated, or close as already published. Never hand-edit `.release-please-manifest.json` or invent a ceremonial patch release.

**Warning signs:** Mixed expected-tag existence; `autorelease: tagged` on a PR whose workflow is re-run; more than one open release-please PR; candidate digest/proposal head/source SHA mismatch; `main` changed publishable content; a package is already live while a sibling is absent; or a suggested recovery omits the `candidate_digest`.

**Verification:** Run the release policy and lifecycle tests plus `test/scripts/release_trigger_recovery_test.exs`, `release_policy_hex_release_state_test.exs`, and linked-release concurrency contract. Record the pre/post PR and tag states. Any retirement must prove no authorized unpublished candidate remains; any recovery must prove exactly one PR, exact required checks, candidate/content digest equality, all package state, and the downstream smoke handoff.

**Phase to address:** Phase 2 — release-PR triage and state reconciliation.

---

### Pitfall 4: Timeout “fixes” mask a PostgreSQL/test-harness defect

**What goes wrong:** The database property test is given an infinite/global timeout, fewer generated cases, a convenient seed, or a broad skip/exclusion to turn CI green. The property then stops bounding the real failure or the suite conceals PostgreSQL shared-state/type-cache interference already called out by the v2.6 audit.

**Why it happens:** Several property modules use `@moduletag timeout: :infinity`; the audit explicitly requires serial database/migration execution or isolated databases because of PostgreSQL type-cache contamination. The advisory matrix also pins `--seed 0` to avoid a known property pool flake. Broadening a timeout or copying the seed workaround looks cheap but weakens truth.

**How to avoid:** First capture the slow test, seed, elapsed time, DB setup, and competing processes. Narrow only the observed target—e.g. a per-test finite timeout plus an explicit tagged/focused invocation—and retain the existing `max_runs` and assertions unless measurement proves another change. Keep DB-owning properties serial or give them an isolated database; do not convert a release-relevant failure into `:flaky`, an allowlist entry, or a global timeout exception. Add a regression proving the focused command executes the property and that timeout exhaustion fails visibly.

**Warning signs:** New `timeout: :infinity`; lower `max_runs`; `--seed 0` copied into a release path; changed exclusion/skip totals; retry-only greens; test duration near job timeout; or “fix” that changes no ownership/isolation condition.

**Verification:** Run the affected property repeatedly with recorded seeds against PostgreSQL, once alongside the intended suite shape, and inspect ExUnit totals/skip governance. Run the exception-governance and suite-floor contracts. The targeted test must finish inside its documented bound without reducing executions or changing the property’s invariant; the broader canonical `mix ci` remains the final integration check.

**Phase to address:** Phase 3 — targeted release-path timeout correction.

---

### Pitfall 5: A Playwright gallery timeout turns a failed assertion into a slower red or a vacuous green

**What goes wrong:** The gallery matrix’s fixed 30-second test timeout is simply increased globally, while its web-server timeout, per-expect timeout, retry behavior, selector discovery, or 4 widths × 3 themes × all discovered cells remains unmeasured. Or the suite is shortened by reducing axes/cells/allowlists, so it passes but no longer proves the gallery contract.

**Why it happens:** The test is intentionally large and has separate budgets: 30s test, 5s expectation, one CI retry, and 300s web-server startup. The gallery test deliberately discovers cells dynamically and maintains a constrained md+ allowlist; changing the wrong budget hides a real browser/server/selector regression.

**How to avoid:** Time the actual failure boundary first: server startup, navigation, one cell locator, resize sweep, or final assertion. Change only the owning budget, with a finite value and a comment tied to measured CI cold-start evidence. Keep all four widths, three themes, stress cells, dynamic discovery floor, and overflow assertion behavior. Do not add broad `test.slow`, disable retries, or extend every Playwright test for one gallery path.

**Warning signs:** A global config timeout change for a single spec; modified `MATRIX_WIDTHS`, themes, `cells.length` floor, or wide-shell allowlist; a test passing only on retry; timeout logs with no server step output; or test duration that approaches the job timeout.

**Verification:** Run the exact gallery spec with one worker in CI-equivalent configuration and retain timing output. Run the existing persona-drift and bucket-A coverage guards so the dynamic/stress coverage has not been weakened. Confirm a deliberately invalid overflow/selector control would fail (locally or in a focused contract), then run the advisory browser lane without promoting it to merge-gating.

**Phase to address:** Phase 3 — targeted browser-gallery timeout correction.

---

### Pitfall 6: Documentation and ignore cleanup destroys proof or preserves false claims

**What goes wrong:** Maintainers gitignore tracked release proof snapshots, delete generated artifacts that are contractual inputs, or update prose based on old runbooks. Conversely, stale instructions keep claiming `RELEASE_PLEASE_TOKEN`, ordinary auto-merge, and hands-free publication even though the workflow uses `RELEASE_PLEASE_PAT` and a protected exact-candidate dispatch.

**Why it happens:** This repository intentionally mixes scratch output with tracked evidence. `MAINTAINING.md` says `.planning/publish/*-publish-summary.json` is tracked proof and must not be ignored, while root `.gitignore` correctly ignores Playwright results, tarballs, and `.planning/research/**/.cache/`. Older runbook text has diverged from the protected release workflow.

**How to avoid:** Classify every candidate path as tracked contractual evidence, source, reproducible scratch, tool cache, or package exclusion. Use `git ls-files`, package `:files` allowlists, docs contract tests, and release policy inputs before adding an ignore or deletion. Reconcile release documentation from live workflow/policy first, then `PROJECT.md`/roadmap/evidence in the priority order already prescribed by `MAINTAINING.md`. State only what current commands and artifacts prove.

**Warning signs:** A proposed ignore matches `.planning/publish`, a broad `.planning/**` pattern, or a tracked path; generated tarball checks change without a paired allowlist/release summary review; docs mention a secret or automated merge condition absent from workflow; planning says a release is live but tags/Hex/policy disagree.

**Verification:** For each changed ignore rule run `git check-ignore -v` on representative intended and protected paths plus `git ls-files` to ensure no tracked contract is hidden. Run publish-summary/stability/docs contracts and the affected release-policy tests. Search all docs for superseded release terms and validate final claims against workflow and release ledger. The final repository hygiene audit should be clean, not merely silenced by ignores.

**Phase to address:** Phase 4 — documentation, artifact, ignore-rule reconciliation and closeout.

---

### Pitfall 7: Bounded maintenance grows into an unreviewable redesign

**What goes wrong:** Worktree cleanup turns into history rewriting; schedule repair turns into CI topology/performance work; timeout repair turns into suite architecture changes; release triage turns into dependency/version churn or a release solely to make the board green.

**Why it happens:** Each surface has real nearby debt, and the repository has many archived planning artifacts that make it easy to reopen completed work. v2.7’s goal is operational truth after v2.6, not product or pipeline evolution.

**How to avoid:** Require every change to identify one audited residue/failure, a minimal before/after proof, an owned v2.7 requirement, and a rollback/recovery path. Treat changes to public APIs, schemas, UI behavior, dependencies, CI topology, unrelated formatting, or release versions as out of scope unless the issue cannot be repaired safely without them and the milestone owner explicitly re-scopes it.

**Warning signs:** A change lacks a direct inventory item or failing run; new dependency lock changes; broad workflow job reshaping; UI snapshots/components changing for gallery timing; release notes/version changes with no adopter-facing correction; or more than one independent concern in a PR.

**Verification:** Keep a disposition-to-commit/evidence matrix. Review diffs against the v2.7 scope lock and run only the focused proof plus the canonical integration gate required by the touched seam. Close only when every inventory item has an explicit retain/recover/retire outcome and `main` is clean and truthful.

**Phase to address:** Phase 1 establishes the scope ledger; every phase enforces it; Phase 4 performs final reconciliation.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| `git worktree remove --force` or directory deletion | Fast cleanup | Can erase unique work or leave stale metadata | Never for v2.7; preserve and use normal removal |
| Treating `unknown` automation state as success | Quiet dashboard | Repeats the historical false-green failure | Never |
| Hand-editing release manifest/version | Appears to unblock a PR | Breaks candidate/ledger/package truth | Never; use an explicit disposition or policy path |
| Global/infinite test timeout | Quick green | Hides deadlock, contention, or a weakened property | Only existing documented non-release cases; new v2.7 change must be finite and targeted |
| Broad ignore rule for planning/generated paths | Cleaner `git status` | Hides required release evidence | Only proven scratch/cache paths with negative checks |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| GitHub Actions scheduler | Treat manual dispatch as schedule proof | Inspect both a manual control run and the next scheduled run, including SHA, permissions, summary, artifact |
| GitHub branch protection / `gh` | Equate inaccessible API with drift or pass | Preserve `unknown`/blocked distinction and retry with read-capable `GH_TOKEN` |
| Release Please + protected publication | Recover from a tag/PR symptom without policy state | Validate tags, live Hex state, one proposal head, source SHA, candidate/content digests, then use the existing protected path |
| PostgreSQL + StreamData | Hide a slow property with seed/timeout changes | Preserve executions and isolate/serialize DB ownership; measure target path |
| Playwright + Phoenix server | Raise global test timeout for cold server or matrix issue | Identify whether startup, navigation, assertion, or matrix sweep owns elapsed time and change only that budget |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|---|---|---|---|
| Gallery resize matrix budget conflated with server startup | 30s test red despite server still compiling/migrating | Separate and record web-server vs test timing | Cold CI/Chromium runs |
| Property DB sharing | Seed-dependent red, type-cache contamination, retry-only pass | Serial/isolated database execution and focused repeat runs | Concurrent DB/migration tests |
| Release self-heal wait treated as a speed bug | Missing exact-SHA workflow run, then unsafe bypass proposal | Keep bounded explicit recovery and inspect evidence | Bot-triggered/tag recovery paths |

## Security Mistakes

| Mistake | Risk | Prevention |
|---|---|---|
| Replacing protected digest validation with manual merge/dispatch | Unauthorized or stale package content reaches immutable release | Preserve exact candidate, content digest, required-check, and protected-main comparisons |
| Broadening workflow token/permissions to cure a scheduled failure | Expands repository mutation capability | Keep least privilege; repair the specific read/auth prerequisite and prove it |
| Deleting release work before a preservation ref | Loss of auditability and recovery evidence | Inventory, preserve, then remove only verified-clean paths |

## "Looks Done But Isn't" Checklist

- [ ] **Workspace cleanup:** each removed worktree/branch/stash has a SHA, unique-work decision, and preservation/ancestry proof.
- [ ] **Scheduled automation:** one successful manual run and one actual scheduled run produced the expected artifact/state on the intended SHA.
- [ ] **Release PR:** tags, Hex state, target ledger, PR head/base, candidate digest, and content digest agree on an explicit outcome.
- [ ] **Property timeout:** targeted property still executes its original generation count and invariant under PostgreSQL; no skip/seed/global-timeout laundering.
- [ ] **Gallery timeout:** all matrix axes, dynamic specimen discovery, stress cells, and existing coverage guards remain intact.
- [ ] **Docs/ignores:** every deletion/ignore is classified; tracked release proof remains tracked; prose matches live workflow semantics.
- [ ] **Scope:** no API, schema, UI, dependency, CI-topology, or ceremonial-release change entered without explicit re-scoping.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| Worktree/branch residue | LOW if preserved; HIGH if force-deleted | Restore preservation ref/bundle or reflog, re-add worktree, then redo inventory |
| Scheduled workflow false-green | MEDIUM | Disable claim, inspect run logs/permissions/ref, repair narrowly, dispatch control run, await next schedule |
| Release-state drift | HIGH | Freeze publication, gather tag/Hex/ledger/PR evidence, choose retire or exact protected recovery; never duplicate tags |
| Flaky-test masking | MEDIUM | Revert exemption, restore invariant/runs, isolate DB or targeted finite bound, repeat with captured seeds |
| Documentation/ignore overclaim | LOW–MEDIUM | Restore tracked evidence, correct docs from live controls, run contract checks and re-audit |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| Destructive cleanup | Phase 1: workspace inventory/disposition | Preservation/ancestry ledger; final worktree/status/stash/fsck checks |
| Scope growth | Phase 1 then all phases | Disposition-to-commit matrix; scope-lock diff review |
| False-green scheduled automation | Phase 2: automation recovery | JSON status semantics, artifacts, manual plus observed scheduled run |
| Release-state drift | Phase 2: blocked release triage | Policy/lifecycle/recovery tests plus exact PR/tag/Hex/digest evidence |
| PostgreSQL property timeout masking | Phase 3: targeted DB timeout | Repeated focused PG runs, unchanged execution/invariant, suite governance checks |
| Gallery timeout masking | Phase 3: targeted browser timeout | Exact spec timing, preserved matrix/stress coverage, browser guard tests |
| Docs/artifacts/ignore drift | Phase 4: reconciliation/closeout | `git check-ignore`, tracked-file checks, docs/publish/release contracts, final hygiene audit |

## Sources

- Local primary evidence (HIGH): `.planning/PROJECT.md`; v2.6 roadmap and milestone audit; `.github/workflows/{ci,release-please,repo-hygiene,publish-hex,post-publish-smoke}.yml`; `dev/mix/tasks/mailglass.repo.hygiene.ex`; release-policy scripts/tests; `MAINTAINING.md`; `.gitignore`; property tests; and admin Playwright configuration/gallery matrix.
- [Git worktree documentation](https://git-scm.com/docs/git-worktree) (LOW via web-search confidence seam): clean worktrees are removable through Git-managed cleanup; pruning addresses stale metadata.
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) (LOW via web-search confidence seam): scheduled workflows use UTC and expose the triggering schedule.

---
*Pitfalls research for: Mailglass v2.7 Repository Stewardship & Operational Hygiene*
*Researched: 2026-08-21*
