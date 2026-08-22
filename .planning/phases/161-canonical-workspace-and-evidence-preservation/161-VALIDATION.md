---
phase: 161
slug: canonical-workspace-and-evidence-preservation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-21
---

# Phase 161 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus read-only Git porcelain and artifact-schema checks |
| **Config file** | `config/test.exs` and this validation checklist |
| **Quick run command** | `git status --short --branch && git worktree list --porcelain` |
| **Full suite command** | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` after the pre-existing `req`/`swoosh` lock mismatch is resolved; otherwise run the complete read-only Git command set below |
| **Estimated runtime** | ~30 seconds for read-only Git checks; ExUnit runtime excluded while dependencies are blocked |

---

## Sampling Rate

- **After every task commit:** Re-run the task's listed read-only Git checks and verify that any workspace-state change is reflected in `161-WORKSPACE-INVENTORY.md`.
- **After every plan wave:** Re-run the full WSPC-01 inventory command set and compare every result with an inventory disposition.
- **Before `$gsd-verify-work`:** Canonical `main` must remain clean, all unique or uncertain work must have a recoverable ref or handoff, and every removal must have prior evidence.
- **Max feedback latency:** 30 seconds for the read-only Git checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 161-01-01 | 01 | 1 | WSPC-01 | T-161-02 | Inventory captures all linked worktrees before mutation. | shell integration | `git worktree list --porcelain -z` | ❌ W0 inventory | ⬜ pending |
| 161-01-02 | 01 | 1 | WSPC-01 | T-161-02 | Inventory captures stashes, relevant refs/ranges, release leftovers, and selected unreachable candidates. | shell integration | `git stash list && git for-each-ref --format='%(refname) %(objectname)' refs/heads refs/remotes refs/tags && git fsck --no-reflogs --unreachable --no-dangling` | ❌ W0 inventory | ⬜ pending |
| 161-02-01 | 02 | 2 | WSPC-02 | T-161-01 | Canonical root is `main`, clean, upstream-bearing, and its exact divergence is explained. | shell integration | `git status --short --branch && git rev-list --left-right --count '@{upstream}...HEAD'` | ❌ W0 inventory | ⬜ pending |
| 161-02-02 | 02 | 2 | WSPC-03 | T-161-02 | Every inventory row records an allowed disposition plus content, unique-work, reachability, and evidence. | artifact schema | `rg -n 'retain|handoff|merge|archive|remove' .planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md` | ❌ W0 inventory | ⬜ pending |
| 161-03-01 | 03 | 3 | WSPC-04 | T-161-01 | Unique or uncertain work is preserved before normal Git-managed removal. | shell integration + safety review | `git show-ref --verify refs/heads/preserve/<name>` or verify the documented handoff before removal | ❌ preservation refs depend on evidence | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `161-WORKSPACE-INVENTORY.md` — durable schema and initial pre-mutation snapshot covering WSPC-01 through WSPC-04.
- [ ] Inventory schema includes identity/path, current ref or detached commit, clean/dirty state, content summary, unique-work evidence, reachability evidence, evidence reference, and disposition.
- [ ] Preservation-before-removal checklist requires a verified `preserve/*` ref or documented handoff for every unique or uncertain candidate.
- [ ] Resolve the pre-existing `req` and `swoosh` dependency lock mismatch before treating the ExUnit hygiene-task regression command as an executable phase gate; dependency changes are outside Phase 161.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inventory completeness and evidence quality | WSPC-01, WSPC-03 | Git commands enumerate candidates but cannot judge whether content summaries and dispositions are adequate. | Compare each command result against exactly one inventory row; inspect each row for content, unique-work, reachability, evidence reference, and allowed disposition. |
| Preservation precedes any cleanup | WSPC-04 | Whether a handoff is adequate and whether uncertain work is preserved requires maintainer judgment. | Before each removal, verify the named `preserve/*` ref with `git show-ref --verify` or inspect the documented handoff; then use normal `git worktree remove` or `git branch -d` only when evidence permits. |
| Canonical `main` explanation is accurate | WSPC-02 | Later Phase 161 documentation commits can legitimately change the ahead count. | Re-run status and divergence commands immediately before sign-off and update the exact count/range explanation without rewriting history. |

---

## Threat References

| Ref | Threat | Required mitigation |
|-----|--------|---------------------|
| T-161-01 | Accidental loss of unique local work | Preserve a named ref or documented handoff before removal; prohibit force/reset/history rewrite. |
| T-161-02 | Incomplete inventory creates false cleanup confidence | Use stable Git porcelain/ref/fsck commands and map every result to a disposition row. |
| T-161-03 | Release proof mistaken for generated junk | Treat publish summaries and release ledger material as tracked evidence; defer remote interpretation to Phase 162. |
| T-161-04 | Shell or ref parsing ambiguity | Use fixed quoted arguments and porcelain/NUL formats where available; do not parse `.git` internals directly. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is under 30 seconds for read-only Git checks.
- [ ] `nyquist_compliant: true` is set only after task IDs and commands match finalized plans.

**Approval:** pending
