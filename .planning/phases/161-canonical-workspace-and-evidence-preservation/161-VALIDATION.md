---
phase: 161
slug: canonical-workspace-and-evidence-preservation
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| 161-01-01 | 01 | 0 | WSPC-01, WSPC-02 | T-161-02 | Inventory captures all linked worktrees before mutation. | shell integration | `git worktree list --porcelain -z` | ✅ `161-WORKSPACE-INVENTORY.md` | ✅ green |
| 161-01-02 | 01 | 0 | WSPC-01 | T-161-02 | Inventory captures stashes, relevant refs/ranges, release leftovers, and selected unreachable candidates. | shell integration | `git stash list && git for-each-ref --format='%(refname) %(objectname)' refs/heads refs/remotes refs/tags && git fsck --no-reflogs --unreachable --no-dangling` | ✅ `161-WORKSPACE-INVENTORY.md` | ✅ green |
| 161-02-01 | 02 | 2 | WSPC-03 | T-161-01 | Every inventoried identity has `EVID-*`-backed content, unique-work, and exact reachability evidence before disposition. | artifact schema + shell evidence | Existing schema gate plus final read-only recapture. | ✅ inventory | ✅ green |
| 161-02-02 | 02 | 2 | WSPC-03 | T-161-02 | Every inventory row records an allowed disposition plus content, unique-work, reachability, and evidence. | artifact schema | `rg -n 'retain|handoff|merge|archive|remove' .planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md` | ✅ inventory | ✅ green |
| 161-03-01 | 03 | 3 | WSPC-04 | T-161-01 | Every eligible archive/remove row maps one-to-one to an exact-OID ref, concrete handoff, or evidence-backed not-required determination; eligible and required counts are nonzero. | TSV reconciliation + shell integration | `161-verify-preservation-reconciliation.sh partial` | ✅ reconciliation TSV + verifier | ✅ green |
| 161-03-02 | 03 | 3 | WSPC-04 | T-161-01 | Dirty evidence is committed to the exact ref/OID or represented by a concrete handoff with location, blocker, and permitted next action. | TSV reconciliation + artifact schema | `161-verify-preservation-reconciliation.sh complete`; `pending: 0` | ✅ preservation refs/handoffs | ✅ green |
| 161-04-01 | 04 | 4 | WSPC-04 | T-161-01 | Cleanup eligibility consumes the unchanged Plan 03 row-level reconciliation before any action. | shell integration + safety gate | Complete reconciliation before the empty cleanup queue. | ✅ complete reconciliation | ✅ green |
| 161-04-02 | 04 | 4 | WSPC-01, WSPC-02, WSPC-03, WSPC-04 | T-161-02 | Final recapture preserves the stable seven-commit semantic range, current live ahead count, all outcomes, and surviving recovery anchors. | shell integration + artifact reconciliation | Final enumerators plus `161-verify-preservation-reconciliation.sh complete`. | ✅ final reconciliation | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `161-WORKSPACE-INVENTORY.md` — durable schema and initial pre-mutation snapshot covering WSPC-01 through WSPC-04.
- [x] Inventory schema includes identity/path, current ref or detached commit, clean/dirty state, content summary, unique-work evidence, reachability evidence, evidence reference, and disposition.
- [x] Preservation-before-removal checklist requires a verified `preserve/*` ref or documented handoff for every unique or uncertain candidate.
- [x] `161-PRESERVATION-RECONCILIATION.tsv` uses the fixed schema from Plan 03, contains exactly one row per archive/remove ledger identity, contains at least one eligible and one `required` row for the known evidence set, and fails on ref/OID mismatch or incomplete handoff fields.
- [x] `161-verify-preservation-reconciliation.sh` provides the shared `partial` and `complete` fail-closed gates used by both Plan 03 and Plan 04; no second cleanup-specific interpretation is allowed.
- [ ] Resolve the pre-existing `req` and `swoosh` dependency lock mismatch before treating the ExUnit hygiene-task regression command as an executable phase gate; dependency changes are outside Phase 161.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inventory completeness and evidence quality | WSPC-01, WSPC-03 | Git commands enumerate candidates but cannot judge whether content summaries and dispositions are adequate. | Compare each command result against exactly one inventory row; inspect each row for content, unique-work, reachability, evidence reference, and allowed disposition. |
| Preservation evidence quality | WSPC-04 | Automation proves one-to-one mapping and exact ref/OID equality, but a maintainer still judges whether the cited content/patch evidence justifies a `not-required` determination. | Review every `not-required` TSV row against its `EVID-*` content and reachability evidence; automation handles required refs and concrete handoff field completeness. |
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

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] Plan 03 and Plan 04 execute the same fail-closed row-level reconciliation over `161-PRESERVATION-RECONCILIATION.tsv` before cleanup eligibility and final sign-off.
- [x] No watch-mode flags.
- [x] Feedback latency is under 30 seconds for read-only Git checks.
- [x] `nyquist_compliant: true` is set only after task IDs and commands match finalized plans.

**Approval:** Complete — 2026-08-22T15:56:05Z. All read-only Git captures, exact range checks, preservation reconciliation, row/outcome comparison, canonical cleanliness, and sampling continuity passed. The pre-existing `req`/`swoosh` lock mismatch remains outside this phase and does not replace or invalidate the completed read-only phase gates.
