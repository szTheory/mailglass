---
phase: 161-canonical-workspace-and-evidence-preservation
verified: 2026-08-22T17:10:00Z
status: gaps_found
score: 16/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A maintainer can use one documented canonical `main` checkout whose upstream, ahead/behind state, and clean working tree are explained."
    status: failed
    reason: "The immutable final capture records `origin/main` divergence as behind 0 / ahead 29 at HEAD e2be2c94, but live Git is clean main at HEAD e569f4d0 and behind 0 / ahead 31. The two subsequent Phase 161 commits are not appended as a new current-state capture."
    artifacts:
      - path: ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md"
        issue: "Final Reconciliation is stale for the live canonical HEAD and ahead count."
    missing:
      - "Append a timestamped, read-only canonical-main recapture at e569f4d0 (or current HEAD), including status, upstream, ahead/behind count, and the non-release-clean verdict."
behavior_unverified_items:
  - truth: "WSPC-01 coverage is complete only when fresh worktree, stash, ref, divergent-range, release-leftover, and selected unreachable-object outputs reconcile to ledger rows."
    test: "Independently compare each fresh enumerator's complete identity set with the ledger, including the policy boundary for selected trees/blobs."
    expected: "Every applicable live identity maps once to the ledger or an explicit zero sentinel; no source category is silently aggregated beyond its stated policy."
    why_human: "This plan labels the completeness predicate `verification: backstop`; row counts and symbol checks cannot establish the intended selection policy."
  - truth: "WSPC-03 concurrency safety requires abort-and-recapture if canonical HEAD, stash OIDs, worktree registrations, or assessed ref OIDs change during assessment."
    test: "Change one monitored Git input during a controlled assessment attempt."
    expected: "Assessment aborts and requires a full new snapshot rather than retaining a mixed capture."
    why_human: "This is a backstop invariant; the evidence ledger records a successful static capture, not an exercised concurrent-change path."
  - truth: "WSPC-04 preservation proof is complete only when every archive/remove prerequisite resolves to the recorded OID or committed dirty-content tree."
    test: "Review each reconciliation row against its cited evidence, including the dirty-worktree handoff boundary."
    expected: "Each prerequisite has either an exact ref/OID match or concrete recoverable handoff evidence."
    why_human: "The shell gate proves its declared TSV set and exact ref OIDs, but the plan marks the broader proof predicate as a backstop."
  - truth: "Phase completion requires a reviewer to compare final live Git enumeration with the full pre-mutation ledger and preservation manifest."
    test: "Perform the final identity-by-identity review after the canonical recapture is corrected."
    expected: "All remaining identities and outcomes reconcile without relying on stale final-state claims."
    why_human: "The required reviewer comparison is expressly a backstop and cannot be inferred from documentation alone."
human_verification:
  - test: "Resolve the canonical-main recapture gap, then perform the four backstop reviews above and review the judgment-tier preservation prohibitions."
    expected: "The current clean canonical checkout is accurately captured and no evidence was treated as settled, disposable, or recoverable solely through temporary/unreachable state."
    why_human: "Completeness, concurrent-change handling, preservation adequacy, and the eight judgment-tier must-NOT constraints need maintainer judgment after the automated gap is closed."
---

# Phase 161: Canonical Workspace and Evidence Preservation Verification Report

**Phase Goal:** Maintainers have one explained, clean canonical `main` and can safely account for every workspace, Git object, and release leftover without losing recoverable work.
**Verified:** 2026-08-22T17:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can inspect an inventory of every linked worktree, stash, relevant branch, divergent range, and release leftover before cleanup occurs. | ✓ VERIFIED | Live: 6 worktrees, 1 stash, 167 refs, 10 named ranges; ledger retains 6 `WT-*`, 1 `STASH-*`, relevant `REF-*`/`RANGE-*`, and 5 `REL-*` rows. |
| 2 | A maintainer can use one documented canonical `main` checkout whose upstream, ahead/behind state, and clean working tree are explained. | ✗ FAILED | Live `main` is clean, tracks `origin/main`, and is `0/31`; Final Reconciliation states `0/29` at older HEAD `e2be2c94`. |
| 3 | Every inventoried workspace or Git object has an allowed outcome backed by unique-work and reachability evidence. | ✓ VERIFIED | Inventory's 1,849 non-sentinel rows state an `EVID-*` reference and allowed disposition. Live unreachable-commit set is exactly 1,805 OIDs, matching its `OBJ-*` rows. |
| 4 | Approved cleanup preserves unique or uncertain work on a recoverable ref or documented handoff before normal Git-managed removal. | ✓ VERIFIED | Complete reconciliation gate passed: `12 eligible, 12 required, 12 refs`; the `remove` queue is empty and no Git removal occurred. |
| 5 | The pre-mutation ledger identifies the sole canonical root and every Git-registered linked worktree. | ✓ VERIFIED | `git worktree list --porcelain` yields six paths and matches `WT-01`–`WT-06`; one `CANONICAL` row names the root. |
| 6 | The ledger preserves equal identities/ranges separately and has an explicit empty-input policy. | ✓ VERIFIED | Equal-OID release tags have individual rows; ledger records no enumerated empty category at capture and requires `NONE-*` rows on a future zero result. |
| 7 | No item is considered disposable solely because it is old, detached, absent from `main`, or fsck-unreachable. | ✓ VERIFIED | The dirty detached `WT-03`, stash, and 1,805 unreachable commits are retained/handoff, with no `remove` disposition. |
| 8 | Assessment is idempotent at an unchanged capture and each assessed non-sentinel row has content, uniqueness, reachability, evidence, and one disposition. | ✓ VERIFIED | The ledger records 1,849 rows with evidence/dispositions; its final reconciliation describes no altered original identity. |
| 9 | Archive/remove prerequisites are one-to-one and fail closed on missing, duplicate, mismatched, or incomplete evidence. | ✓ VERIFIED | Both `partial` and `complete` runs of the phase script passed; its source rejects empty eligibility, duplicate source rows, mismatches, unresolved refs, and incomplete handoffs. |
| 10 | Cleanup uses only ordinary non-force operations for eligible `remove` rows; all pre-mutation identities have a final outcome. | ✓ VERIFIED | Git history from phase base is evidence/planning commits only; Final Reconciliation reports zero authorized removals and preserves the original matrix/outcome mapping. |
| 11 | Complete inventory coverage has an independently exercised held-out proof. | ⚠️ INSUFFICIENT_SPEC | `verification: backstop`; live count/OID sampling is strong but not the specified human completeness judgment. |
| 12 | Assessment aborts and recaptures when its inputs change concurrently. | ⚠️ INSUFFICIENT_SPEC | `verification: backstop`; no controlled concurrent-change test exists. |
| 13 | Preservation proof is complete beyond the declared TSV/ref checks. | ⚠️ INSUFFICIENT_SPEC | `verification: backstop`; exact-OID gate passes but adequacy remains reviewer judgment. |
| 14 | A reviewer has compared final live Git enumeration with the complete pre-mutation ledger and manifest. | ⚠️ INSUFFICIENT_SPEC | `verification: backstop`; no independent reviewer evidence, and the current state has drifted past the final capture. |

**Score:** 16/21 truths verified (0 present, behavior-unverified; four non-inferable backstops abstained).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `161-WORKSPACE-INVENTORY.md` | Pre-mutation/final Git evidence ledger | ⚠️ STALE | Substantive (2,079 lines), tracked and used by the reconciliation script; final canonical count/head need recapture. |
| `161-VALIDATION.md` | Requirement-to-evidence sampling contract | ✓ VERIFIED | Substantive, tracked 99-line validation contract; references the shared reconciliation commands. |
| `161-PRESERVATION-RECONCILIATION.tsv` | One-to-one recovery map | ✓ VERIFIED | Exact 12-column TSV, 12 verified archive rows, consumed by the gate. |
| `161-verify-preservation-reconciliation.sh` | Fail-closed reconciliation verifier | ✓ VERIFIED | Substantive 84-line script; both modes executed successfully against live refs. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `git worktree list --porcelain -z` | Inventory | `WT-*` rows | ✓ WIRED | Live porcelain count is 6 and matches `WT-01`–`WT-06`. |
| Upstream divergence command | Inventory | Canonical Main / Final Reconciliation | ✗ STALE | Connection exists, but currently reports `0 31` while last recorded final evidence is `0 29`. |
| Archive/remove dispositions | Preservation refs | TSV and gate | ✓ WIRED | Script joins the inventory set to TSV and resolves all 12 `preserve/phase-161-*` refs to expected OIDs. |
| Cleanup eligibility | Normal Git actions | Gate before queue | ✓ WIRED | Gate passes but finds zero `remove` rows; therefore no removal action is permitted or performed. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Inventory | Workspace/ref/stash/object rows | Read-only Git porcelain, refs, stash, ranges, fsck | Yes; live worktree/stash/ref and unreachable-commit checks match the captured identity sets | ⚠️ Current canonical divergence is stale |
| Reconciliation TSV + script | Eligible archive/remove rows and ref OIDs | Inventory rows and live `git rev-parse` | Yes; 12 exact live ref/OID matches | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Fail-closed reconciliation (partial) | `bash 161-verify-preservation-reconciliation.sh partial INVENTORY TSV` | `PASS (12 eligible, 12 required, 12 refs)` | ✓ PASS |
| Fail-closed reconciliation (complete) | `bash 161-verify-preservation-reconciliation.sh complete INVENTORY TSV` | `PASS (12 eligible, 12 required, 12 refs)` | ✓ PASS |
| Canonical state agrees with final capture | `git status --short --branch; git rev-list --left-right --count '@{upstream}...HEAD'` | Clean `main`, `0 31`; ledger final says `0/29` | ✗ FAIL |
| Unreachable commit accounting | `git fsck --full --no-reflogs --unreachable --no-dangling` compared to `OBJ-*` OIDs | 1,805 live commits; 1,805 ledger OIDs; no set difference | ✓ PASS |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| WSPC-01 | 161-01, 161-04 | Complete pre-cleanup workspace/Git evidence inventory | ✓ SATISFIED | Live worktree/stash/ref/object checks reconcile to its captured identity rows. |
| WSPC-02 | 161-01, 161-04 | Explained canonical main/upstream/divergence and no unexplained changes | ✗ BLOCKED | Working tree is clean, but documented final divergence is stale by two commits. |
| WSPC-03 | 161-02, 161-04 | Evidence-backed per-item disposition | ✓ SATISFIED | All inventoried non-sentinel identities are dispositioned with evidence and no unsafe `remove`. |
| WSPC-04 | 161-03, 161-04 | Preservation before normal cleanup | ✓ SATISFIED | Exact-OID reconciliation passes; no removal became eligible. |

No orphaned Phase 161 requirement IDs were found: all four roadmap-mapped IDs appear in plan frontmatter.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `161-WORKSPACE-INVENTORY.md` | 2050–2068 | Final live-state evidence is not append-recaptured after two additional Phase 161 commits | 🛑 Blocker | Makes the documented current canonical divergence false (`29` vs live `31`). |

No `TBD`, `FIXME`, or `XXX` debt markers were found in phase-modified artifacts. Generic key-link tooling could not parse prose-valued `from` fields; the links above were manually traced instead.

## Human Verification Required

After correcting the canonical recapture, a maintainer must complete the four backstop checks in frontmatter and explicitly review the judgment-tier prohibitions: stale/missing evidence must not be treated as settled; clean `main` must remain non-release-clean while drift exists; no distinct identity may be collapsed; and no temporary/reflog/unreachable-only preservation may be accepted as durable. These are escalation-gate items, not automated passes.

## Gaps Summary

The phase has durable inventory and preservation machinery, and the live recovery references reconcile. Its canonical-main claim is nevertheless stale: the last final capture is at `e2be2c94`, ahead 29, while live clean `main` is `e569f4d0`, ahead 31. Append a new read-only final recapture rather than rewriting the prior evidence, then route the backstop and prohibition judgments to maintainer review.

---

_Verified: 2026-08-22T17:10:00Z_
_Verifier: the agent (gsd-verifier)_
