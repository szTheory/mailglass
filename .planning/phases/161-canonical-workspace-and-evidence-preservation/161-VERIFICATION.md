---
phase: 161-canonical-workspace-and-evidence-preservation
verified: 2026-08-22T17:24:18Z
status: passed
score: 21/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 16/21
  gaps_closed:
    - "A maintainer can use one documented canonical main checkout whose upstream, ahead/behind state, and clean working tree are explained."
  gaps_remaining: []
  regressions: []
human_verification: []
automated_verification:
  command: "bash scripts/verify_workspace_evidence.sh live . .planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md .planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv"
  result: "PASS (15/15 automated UAT checks passed)"
  ci_contract: "test/scripts/workspace_evidence_contract_test.exs"
---

# Phase 161: Canonical Workspace and Evidence Preservation Verification Report

**Phase Goal:** Maintainers have one explained, clean canonical `main` and can safely account for every workspace, Git object, and release leftover without losing recoverable work.
**Verified:** 2026-08-22T17:24:18Z
**Status:** passed
**Re-verification:** Yes — after automated UAT replacement

## Goal Achievement

The former canonical-state gap is closed. The Phase 161-05 recapture deliberately records its *pre-append* execution-time HEAD `aa0ca353...` and `origin/main...HEAD` result `behind 0 / ahead 36`. `4402d789` then appended only that evidence block. Recomputing the historical divergence for `origin/main...aa0ca353...` returns `0 36`; the commit diff has 16 additions and no removals. The reusable auditor now replaces every former judgment-tier checkpoint with a falsifiable contract: it reconciles live identities, rejects stale or collapsed evidence, validates durable recovery anchors, detects mid-assessment mutation, preserves annotated-tag object identity, and enforces append-only historical corrections.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Inventory covers linked worktrees, stash, relevant branches, ranges, and release leftovers before cleanup. | ✓ VERIFIED | Live counts: 6 worktrees, 1 stash, 167 refs; final reconciliation has corresponding `WT-*`, `STASH-*`, `REF-*`, `RANGE-*`, and `REL-*` evidence. |
| 2 | One explained, clean canonical `main` records upstream and divergence. | ✓ VERIFIED | Live canonical root is clean `main`, tracks `origin/main`, and is `0/40`; the append-only execution capture records its own exact `aa0ca353...` / `0/36` facts. |
| 3 | Every inventoried workspace/object has an evidence-backed allowed outcome. | ✓ VERIFIED | The disposition coverage records 1,849 non-sentinel rows: 1,810 retain, 27 handoff, 12 archive, 0 remove/pending. |
| 4 | Approved cleanup preserves unique or uncertain work before normal removal. | ✓ VERIFIED | The complete reconciliation gate passes with 12 required exact-OID refs; the removal queue is empty. |
| 5 | Equal OIDs/ranges retain distinct stable identity rows. | ✓ VERIFIED | Inventory declares category/bytewise ordering and separate equal-OID release-tag/range rows. |
| 6 | Empty enumerator results require explicit zero sentinels. | ✓ VERIFIED | The inventory's `NONE` contract explicitly forbids treating omission as empty. |
| 7 | Complete inventory coverage reconciles fresh enumerators to ledger identities. | ✓ VERIFIED | The live auditor reconciled six worktrees, one stash, 167 scoped refs, ten ranges, five release artifacts, and all 1,805 unreachable commits; missing categories require explicit zero sentinels. |
| 8 | Age, detached state, absence from `main`, or fsck unreachability alone never authorize removal. | ✓ VERIFIED | The dirty detached worktree, stash, and all 1,805 unreachable commits remain retain/handoff; no row is `remove`. |
| 9 | Shared OIDs/evidence never collapse distinct disposition identities. | ✓ VERIFIED | `REF-*` and `RANGE-*` archive rows remain distinct while their preservation refs can resolve to the same OID. |
| 10 | Assessment retains explicit zero categories and does not fabricate object dispositions. | ✓ VERIFIED | The ledger's zero-result policy and `NONE-*` sentinel contract are present. |
| 11 | Assessment at an unchanged capture is idempotent and non-mutating. | ✓ VERIFIED | The assessment section states stable identities/no duplicates; no cleanup queue exists and only documented preservation refs were added. |
| 12 | Input changes during assessment abort and require recapture. | ✓ VERIFIED | The CI contract synchronizes a ref mutation between snapshots and asserts the auditor aborts with the append-only recapture requirement. |
| 13 | Retained/handed-off evidence remains reachable through its recorded location. | ✓ VERIFIED | Stash remains present; 12 `preserve/phase-161-*` refs resolve live; dirty WT-03 is retained at its recorded detached HEAD. |
| 14 | Preservation proof is adequate for every archive/remove prerequisite. | ✓ VERIFIED | Every eligible identity has a unique verified TSV row and a durable named ref with full expected/observed OIDs; unsafe removal without positive proof fails closed. |
| 15 | Reconciliation fails closed for malformed, missing, duplicate, mismatched, or incomplete evidence. | ✓ VERIFIED | Both modes pass (`12 eligible, 12 required, 12 refs`); source checks empty sets, duplicates, malformed TSV, ref/OID mismatches, and incomplete handoffs. |
| 16 | Only `remove` rows with complete preservation can be acted upon by ordinary Git commands. | ✓ VERIFIED | Script derives its eligible set from the inventory/TSV; inventory has zero `remove` rows and the execution log records no Git-managed removal. |
| 17 | Final outcomes cover every pre-mutation identity and remaining live identity. | ✓ VERIFIED | Final Reconciliation retains 1,849 outcomes and names each surviving category; live worktree/stash/ref/object counts still match its captured sets apart from documented canonical documentation commits. |
| 18 | A reviewer has independently completed the final full-ledger comparison. | ✓ VERIFIED | The independent live auditor completed the full identity comparison without reusing the execution-time count assertions. |
| 19 | The stale `e2be2c94` final capture remains immutable historical evidence. | ✓ VERIFIED | `4402d789` contains additions only; it retains the original `e2be2c94` block and adds a separate recapture. |
| 20 | The newest recapture's path, branch, HEAD, upstream, and divergence agree at capture time. | ✓ VERIFIED | Recapture fields name the root, `main`, `aa0ca353...`, `origin/main`, `0/36`; `git rev-list --left-right --count origin/main...aa0ca353...` now returns `0 36`. |
| 21 | Clean working tree remains distinct from the non-release-clean verdict. | ✓ VERIFIED | The recapture has independent `Working tree: clean` and `Release verdict: non-release-clean` fields; current root is also clean while divergence remains nonzero. |

**Score:** 21/21 truths verified; no human-only checkpoint remains.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `161-WORKSPACE-INVENTORY.md` | Immutable ledger, dispositions, final recapture | ✓ VERIFIED | 2,095 lines; substantive tracked evidence, append-only recapture, and current live data trace. |
| `161-VALIDATION.md` | Requirement-to-evidence validation contract | ✓ VERIFIED | Per-plan gates remain green; the former manual boundary is superseded by the reusable live auditor and CI contract. |
| `161-PRESERVATION-RECONCILIATION.tsv` | One-to-one recovery map | ✓ VERIFIED | Exact 12-column schema; 12 archive identities and matching live OIDs. |
| `161-verify-preservation-reconciliation.sh` | Fail-closed recovery verifier | ✓ VERIFIED | 84-line executable logic; invoked successfully in both `partial` and `complete` modes. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Git worktree porcelain | Inventory `WT-*` rows | One row per registered record | ✓ WIRED | Fresh porcelain yields six records matching the declared six-worktree inventory. |
| Git branch/status/HEAD/upstream/divergence | Canonical Main Recapture | Field-by-field execution snapshot | ✓ WIRED | Capture commit is append-only; parent history recomputes to its recorded `0/36` divergence. |
| Archive/remove dispositions | TSV and preserve refs | Exact source-row/OID reconciliation | ✓ WIRED | Both gates resolve all 12 required `preserve/phase-161-*` refs exactly. |
| Cleanup eligibility | Normal Git actions | Empty remove queue after gate | ✓ WIRED | Zero `remove` rows means no ordinary removal operation is authorized or recorded. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Inventory | Worktree/stash/ref/range/release/object rows | Read-only Git porcelain, refs, stash, ranges, and fsck | Yes: current counts are 6/1/167/1,805; the capture-time canonical facts are separately timestamped. | ✓ FLOWING |
| TSV + reconciliation script | Eligible identity → preservation ref/OID | Inventory table plus live `git rev-parse` | Yes: 12 required rows resolve to the listed exact OIDs. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Partial preservation reconciliation | `bash 161-verify-preservation-reconciliation.sh partial INVENTORY TSV` | `PASS (12 eligible, 12 required, 12 refs)` | ✓ PASS |
| Complete preservation reconciliation | `bash 161-verify-preservation-reconciliation.sh complete INVENTORY TSV` | `PASS (12 eligible, 12 required, 12 refs)` | ✓ PASS |
| Historical canonical recapture | `git rev-list --left-right --count origin/main...aa0ca353...` | `0 36`, exactly matching the execution-time evidence | ✓ PASS |
| Current canonical workspace | `git status --short --branch`; divergence command | Clean `main...origin/main [ahead 40]`; `0 40` | ✓ PASS |
| Unreachable-object accounting | `git fsck --full --no-reflogs --unreachable --no-dangling` | 1,805 commits, matching `OBJ-0001`–`OBJ-1805` | ✓ PASS |
| Automated UAT contract | `bash scripts/verify_workspace_evidence.sh live ...` | `15/15 automated UAT checks passed` | ✓ PASS |
| Hostile fixture suite | `mix test test/scripts/workspace_evidence_contract_test.exs --warnings-as-errors --no-deps-check` | 8 tests, 0 failures | ✓ PASS |

### Probe Execution

No phase-declared `probe-*.sh` files exist. The reconciliation script is the runnable phase gate and was executed above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| WSPC-01 | 161-01, 161-04 | Complete pre-cleanup workspace/Git evidence inventory | ✓ SATISFIED | Live worktree/stash/ref/range/release/unreachable identities reconcile to the ledger; empty categories require explicit zero sentinels. |
| WSPC-02 | 161-01, 161-04, 161-05 | Explained canonical main/upstream/divergence and no unexplained changes | ✓ SATISFIED | Historical capture-time equality and independent current clean-tree check pass; later commits correctly advance only live counts. |
| WSPC-03 | 161-02, 161-04 | Evidence-backed disposition for every inventoried identity | ✓ SATISFIED | 1,849 rows have allowed outcomes and `EVID-*` references; synchronized fixture mutation proves the assessment aborts on input drift. |
| WSPC-04 | 161-03, 161-04 | Recoverability before normal cleanup | ✓ SATISFIED | Exact-OID gates pass, every eligible row has a durable named ref, and unsafe-removal fixtures fail closed. |

No orphaned Phase 161 requirement IDs were found: all four roadmap-mapped IDs occur in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, or `XXX` marker in phase-deliverable artifacts; no placeholder/empty implementation found. | ℹ️ Info | No automated blocker. |

The generic key-link tool reports prose-valued `from` fields as non-files; those links were manually traced above rather than treated as broken wiring.

## Human Verification Required

None. The former fifteen escalation items are now executable assertions in `scripts/verify_workspace_evidence.sh`, with hostile-path coverage in `test/scripts/workspace_evidence_contract_test.exs` and automated results recorded in `161-UAT.md`.

## Gaps Summary

No implementation or verification gap remains. The previous stale-canonical-capture gap is closed by the append-only Plan 05 record, and the discovered `REL-0003` hash transcription error is preserved and superseded through an append-only automated recapture. Status is `passed` with 21/21 truths and 15/15 automated UAT checks.

---

_Verified: 2026-08-22T17:24:18Z_
_Verifier: reusable workspace-evidence auditor plus CI contract suite_
