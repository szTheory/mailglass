---
phase: 161-canonical-workspace-and-evidence-preservation
verified: 2026-08-22T16:35:30Z
status: human_needed
score: 17/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 16/21
  gaps_closed:
    - "A maintainer can use one documented canonical main checkout whose upstream, ahead/behind state, and clean working tree are explained."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Independently compare fresh worktree, stash, ref, range, release-leftover, and selected unreachable-object enumerations with the ledger."
    expected: "Every applicable identity maps once to a ledger row or explicit zero sentinel; the selected-object policy is accepted."
    why_human: "WSPC-01 completeness is explicitly a backstop judgment."
  - test: "Change one monitored assessment input during a controlled rerun."
    expected: "The assessment aborts and requires a full append-only recapture."
    why_human: "The concurrent-change invariant has no exercised test."
  - test: "Review every archive/remove prerequisite against its cited OID or dirty-content handoff."
    expected: "Each claimed prerequisite is adequate recoverable evidence, not merely a matching TSV field."
    why_human: "WSPC-04 proof adequacy is explicitly a backstop judgment."
  - test: "Perform the final identity-by-identity comparison of live Git enumeration with the pre-mutation ledger and manifest."
    expected: "All remaining identities and final outcomes reconcile."
    why_human: "The Plan 04 reviewer comparison is explicitly a backstop."
  - test: "Review the Plan 01 stale-evidence prohibition."
    expected: "No missing, unreadable, or stale evidence is represented as empty or settled."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 01 release-clean prohibition."
    expected: "A clean tree is never presented as release-clean while upstream settlement remains outstanding."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 02 disposable-work prohibition."
    expected: "Age, detached state, absence from main, or fsck output alone did not authorize removal."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 02 identity-collapse prohibition."
    expected: "Distinct worktree/ref identities remain separately dispositioned even when OIDs match."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 03 durable-recoverability prohibition."
    expected: "Recovery does not rely solely on temporary paths, reflogs, or unreachable loose objects."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 03 preservation-mutation prohibition."
    expected: "No existing ref was overwritten, stash consumed, or canonical history changed to preserve evidence."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 04 destructive-cleanup prohibition."
    expected: "No force removal/deletion, reset, force-push, prune, or garbage collection manufactured cleanliness."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 04 immutable-evidence prohibition."
    expected: "Pre-mutation evidence is retained and final state is appended separately."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 05 historical-capture prohibition."
    expected: "The e2be2c94 Final Reconciliation was not rewritten, deleted, or silently corrected."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 05 capture-method prohibition."
    expected: "The recapture did not use Git or remote operations to manufacture its state."
    why_human: "Judgment-tier prohibition."
  - test: "Review the Plan 05 release-verdict prohibition."
    expected: "The empty porcelain result is kept distinct from the non-release-clean verdict."
    why_human: "Judgment-tier prohibition."
---

# Phase 161: Canonical Workspace and Evidence Preservation Verification Report

**Phase Goal:** Maintainers have one explained, clean canonical `main` and can safely account for every workspace, Git object, and release leftover without losing recoverable work.
**Verified:** 2026-08-22T16:35:30Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure

## Goal Achievement

The former canonical-state gap is closed. The Phase 161-05 recapture deliberately records its *pre-append* execution-time HEAD `aa0ca353...` and `origin/main...HEAD` result `behind 0 / ahead 36`. `4402d789` then appended only that evidence block. Recomputing the historical divergence for `origin/main...aa0ca353...` returns `0 36`; the commit diff has 16 additions and no removals. The later documentation commits explain the verifier-time `HEAD 7b2931cd...` / `0 40` state rather than contradicting the capture.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Inventory covers linked worktrees, stash, relevant branches, ranges, and release leftovers before cleanup. | ✓ VERIFIED | Live counts: 6 worktrees, 1 stash, 167 refs; final reconciliation has corresponding `WT-*`, `STASH-*`, `REF-*`, `RANGE-*`, and `REL-*` evidence. |
| 2 | One explained, clean canonical `main` records upstream and divergence. | ✓ VERIFIED | Live canonical root is clean `main`, tracks `origin/main`, and is `0/40`; the append-only execution capture records its own exact `aa0ca353...` / `0/36` facts. |
| 3 | Every inventoried workspace/object has an evidence-backed allowed outcome. | ✓ VERIFIED | The disposition coverage records 1,849 non-sentinel rows: 1,810 retain, 27 handoff, 12 archive, 0 remove/pending. |
| 4 | Approved cleanup preserves unique or uncertain work before normal removal. | ✓ VERIFIED | The complete reconciliation gate passes with 12 required exact-OID refs; the removal queue is empty. |
| 5 | Equal OIDs/ranges retain distinct stable identity rows. | ✓ VERIFIED | Inventory declares category/bytewise ordering and separate equal-OID release-tag/range rows. |
| 6 | Empty enumerator results require explicit zero sentinels. | ✓ VERIFIED | The inventory's `NONE` contract explicitly forbids treating omission as empty. |
| 7 | Complete inventory coverage reconciles fresh enumerators to ledger identities. | ⚠️ UNCERTAIN | The plan labels this a `backstop`; count/OID checks are strong but cannot decide the selected-object policy. |
| 8 | Age, detached state, absence from `main`, or fsck unreachability alone never authorize removal. | ✓ VERIFIED | The dirty detached worktree, stash, and all 1,805 unreachable commits remain retain/handoff; no row is `remove`. |
| 9 | Shared OIDs/evidence never collapse distinct disposition identities. | ✓ VERIFIED | `REF-*` and `RANGE-*` archive rows remain distinct while their preservation refs can resolve to the same OID. |
| 10 | Assessment retains explicit zero categories and does not fabricate object dispositions. | ✓ VERIFIED | The ledger's zero-result policy and `NONE-*` sentinel contract are present. |
| 11 | Assessment at an unchanged capture is idempotent and non-mutating. | ✓ VERIFIED | The assessment section states stable identities/no duplicates; no cleanup queue exists and only documented preservation refs were added. |
| 12 | Input changes during assessment abort and require recapture. | ⚠️ UNCERTAIN | Required concurrency behavior is a plan-declared `backstop`; no controlled-change test exists. |
| 13 | Retained/handed-off evidence remains reachable through its recorded location. | ✓ VERIFIED | Stash remains present; 12 `preserve/phase-161-*` refs resolve live; dirty WT-03 is retained at its recorded detached HEAD. |
| 14 | Preservation proof is adequate for every archive/remove prerequisite. | ⚠️ UNCERTAIN | Exact OID verification passes, but the broader adequacy predicate is a `backstop` judgment. |
| 15 | Reconciliation fails closed for malformed, missing, duplicate, mismatched, or incomplete evidence. | ✓ VERIFIED | Both modes pass (`12 eligible, 12 required, 12 refs`); source checks empty sets, duplicates, malformed TSV, ref/OID mismatches, and incomplete handoffs. |
| 16 | Only `remove` rows with complete preservation can be acted upon by ordinary Git commands. | ✓ VERIFIED | Script derives its eligible set from the inventory/TSV; inventory has zero `remove` rows and the execution log records no Git-managed removal. |
| 17 | Final outcomes cover every pre-mutation identity and remaining live identity. | ✓ VERIFIED | Final Reconciliation retains 1,849 outcomes and names each surviving category; live worktree/stash/ref/object counts still match its captured sets apart from documented canonical documentation commits. |
| 18 | A reviewer has independently completed the final full-ledger comparison. | ⚠️ UNCERTAIN | This is the Plan 04 `backstop`, requiring maintainer review. |
| 19 | The stale `e2be2c94` final capture remains immutable historical evidence. | ✓ VERIFIED | `4402d789` contains additions only; it retains the original `e2be2c94` block and adds a separate recapture. |
| 20 | The newest recapture's path, branch, HEAD, upstream, and divergence agree at capture time. | ✓ VERIFIED | Recapture fields name the root, `main`, `aa0ca353...`, `origin/main`, `0/36`; `git rev-list --left-right --count origin/main...aa0ca353...` now returns `0 36`. |
| 21 | Clean working tree remains distinct from the non-release-clean verdict. | ✓ VERIFIED | The recapture has independent `Working tree: clean` and `Release verdict: non-release-clean` fields; current root is also clean while divergence remains nonzero. |

**Score:** 17/21 truths verified (4 non-inferable backstops require human review).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `161-WORKSPACE-INVENTORY.md` | Immutable ledger, dispositions, final recapture | ✓ VERIFIED | 2,095 lines; substantive tracked evidence, append-only recapture, and current live data trace. |
| `161-VALIDATION.md` | Requirement-to-evidence validation contract | ✓ VERIFIED | 99-line contract with per-plan gates and manual-verification boundary. |
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

### Probe Execution

No phase-declared `probe-*.sh` files exist. The reconciliation script is the runnable phase gate and was executed above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| WSPC-01 | 161-01, 161-04 | Complete pre-cleanup workspace/Git evidence inventory | ✓ SATISFIED | Live worktree/stash/ref/unreachable counts reconcile to inventory categories; completeness-policy review remains human-required. |
| WSPC-02 | 161-01, 161-04, 161-05 | Explained canonical main/upstream/divergence and no unexplained changes | ✓ SATISFIED | Historical capture-time equality and independent current clean-tree check pass; later commits correctly advance only live counts. |
| WSPC-03 | 161-02, 161-04 | Evidence-backed disposition for every inventoried identity | ✓ SATISFIED | 1,849 rows have allowed outcomes and `EVID-*` references; concurrency invariant remains human-required. |
| WSPC-04 | 161-03, 161-04 | Recoverability before normal cleanup | ✓ SATISFIED | Exact-OID gate passes and no removal is eligible; preservation adequacy remains human-required. |

No orphaned Phase 161 requirement IDs were found: all four roadmap-mapped IDs occur in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, or `XXX` marker in phase-deliverable artifacts; no placeholder/empty implementation found. | ℹ️ Info | No automated blocker. |

The generic key-link tool reports prose-valued `from` fields as non-files; those links were manually traced above rather than treated as broken wiring.

## Human Verification Required

Fifteen escalation-gate items remain in frontmatter: four plan-declared backstops and eleven judgment-tier must-NOT constraints. They are not implementation failures, but must be explicitly accepted by a maintainer before this phase can be marked passed.

## Gaps Summary

No automated implementation gap remains. The previous stale-canonical-capture gap is closed by the append-only Plan 05 record. Status is `human_needed`, not `passed`, because the roadmap/plan leave four non-inferable proof predicates and eleven judgment-tier safety prohibitions for maintainer decision.

---

_Verified: 2026-08-22T16:35:30Z_
_Verifier: the agent (gsd-verifier)_
