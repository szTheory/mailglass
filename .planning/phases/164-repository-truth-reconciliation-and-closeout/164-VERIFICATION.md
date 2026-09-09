---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-09T22:52:25Z
verified_implementation_sha: 114415c8f3eaa943235f105d4d0fd533989e8494
status: gaps_found
score: 11/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/13
  gaps_closed:
    - "TRTH-01 current maintainer guidance now presents one protected exact-candidate and fresh repository-admin authority model throughout the non-historical document."
    - "Obsolete v0.1/v0.5 hands-free authority is now retained only beneath the exact Historical release procedures boundary."
  gaps_remaining:
    - "TRTH-02 tracked-state claims are not authenticated against the Git index."
    - "TRTH-03 finalizer dispatch executes mutable working-tree bytes rather than the tracked HEAD blob."
  regressions:
    - "The post-164-16 code review exposed two previously untested trust-boundary defects in the repository-truth validator and finalizer dispatcher."
gaps:
  - truth: "TRTH-02 / D-05 / D-06 / D-12: Every tracked artifact disposition is evidence-backed by actual exact-path Git membership."
    status: failed
    reason: "The production validator treats any regular file as satisfying a ledger row whose state is tracked. In a disposable clone, README.md was removed from the Git index but left on disk; RepositoryTruthLedger.validate/2 still returned :ok."
    artifacts:
      - path: "scripts/validate_repository_truth.exs"
        issue: "ensure_tracked_subjects_exist/2 checks File.regular?/1 only and never verifies git ls-files --error-unmatch for each tracked row."
      - path: "test/scripts/phase_164_repository_truth_test.exs"
        issue: "The finalization-artifact test asserts the row's literal state field but has no untracked-regular-file regression against production validation."
    missing:
      - "Require exact-path Git index membership, as well as the expected regular-file type, for every ledger row whose state is tracked."
      - "Add a disposable-repository regression where an untracked regular file with state=tracked fails and the same committed file passes."
  - truth: "TRTH-03 / D-09 / D-10 / D-11: The finalizer command executes only immutable code authenticated to the tracked implementation at HEAD."
    status: failed
    reason: "The extension checks git ls-files index membership, then executes the resolved working-tree shim. A newly staged or unstaged-modified shim can run before the real finalizer's clean-tree and evidence checks, so the protected closeout authority can be bypassed."
    artifacts:
      - path: ".gsd/extensions/finalize-phase/index.ts"
        issue: "Lines 88-101 do not prove HEAD contains the finalizer or that working-tree bytes equal the HEAD blob before pi.exec runs bash."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "The extension contract checks source strings for git ls-files and pi.exec but does not behaviorally reject staged-new or modified tracked finalizers."
    missing:
      - "Resolve and authenticate HEAD:<relative-finalizer>, reject index/worktree mismatches, and preferably execute a private immutable materialization of the verified HEAD blob."
      - "Add behavioral dispatcher tests for a staged-new finalizer, an unstaged modification, and an unchanged committed finalizer."
prohibition_flags:
  - statement: "D-05/D-06/D-12: MUST NOT represent an untracked artifact as tracked repository proof."
    verdict: "violated — disposable-clone reproduction proves the validator accepts this false state"
  - statement: "D-09/D-10/D-11: MUST NOT execute unauthenticated working-tree finalizer code as protected closeout authority."
    verdict: "violated — dispatcher authenticates index membership but executes mutable working-tree bytes"
  - statement: "D-01/D-04: MUST NOT broaden protected exact-candidate or repository-admin authorization."
    verdict: "non-authoritative LLM judgment: Plan 164-16 documentation and its whole-document contract support compliance; human review recommended"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-09T22:52:25Z
**Implementation SHA evaluated:** `114415c8f3eaa943235f105d4d0fd533989e8494`
**Status:** gaps_found
**Re-verification:** Yes — the Plan 164-16 documentation gap is closed; two fresh critical review defects contradict TRTH-02 and TRTH-03.
**Next action:** Plan the two fixes, then re-run execute-phase (`$gsd-plan-phase 164 --gaps`).

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees throughout with protected workflow facts. | ✓ VERIFIED | `MAINTAINING.md:5-48` defines exact-candidate/repository-admin authority; lines 357-368 now explicitly defer to it. The whole-document contract passed. |
| 2 | Historical release procedures are explicitly bounded, leaving one unmistakable current runbook. | ✓ VERIFIED | Exactly one `## Historical release procedures` heading exists; v0.1/v0.5 hands-free language appears only after it, and missing/duplicate-boundary tests pass. |
| 3 | Current package guidance matches the core/admin 2.5 and inbound 2.2 manifests. | ✓ VERIFIED | Manifest-derived README assertions passed in the 98-test focused run. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | Ledger retains the exact `331810b4...04ece7e` D-08 digest/remove row; the root file remains absent. |
| 5 | Durable scheduled/release/publish/planning proof currently remains tracked and discoverable. | ✓ VERIFIED | Direct Git membership audit found 38 tracked ledger rows and zero currently missing index entries. |
| 6 | Every scoped artifact and non-comment rule in all six ignore files has one truthful, complete disposition. | ✗ FAILED | Canonical data passes today, but the production validator accepts a regular untracked file as `state=tracked`; disposable-clone reproduction returned `:ok`. |
| 7 | Retained ignore rules are narrow and producer-owned. | ✓ VERIFIED | Six-file exact inventory and `.gsd` exception tests pass; durable evidence is not broadly ignored. |
| 8 | One rerunnable command composes Git, hygiene, preservation, ledger, CI, and scheduled authorities. | ✓ VERIFIED | `closeout_repository_truth.sh` is substantive, wired to the real authority seams, shell-valid, and exercised by process tests. |
| 9 | Quiet requires canonical repo/ledger, ignored output, exact origin/main, and post-write cleanliness. | ✓ VERIFIED | Alternate repository/ledger/output, symlink, origin race, and late-dirt regressions pass. |
| 10 | Malformed, future, or stale scheduled timestamps cannot be accepted as current. | ✓ VERIFIED | Both production boundaries enforce `0 <= age <= max_age_seconds`; producer/finalizer mutation tests pass. |
| 11 | Quiet requires the complete exact-one ledger gate. | ✓ VERIFIED | Closeout invokes the canonical shared validator using the authoritative ledger path and rejects caller-selected substitutes. |
| 12 | Evidence selection permits only attempt-one normal push CI and natural same-SHA scheduled controls. | ✓ VERIFIED | Attempt/event/branch/SHA/status/digest mutation tests and Node CI-monitor tests pass. Existing protected evidence is explicitly pre-verification-only. |
| 13 | Terminal finalization is bound to the exact tracked implementation verified. | ✗ FAILED | The shell finalizer has SHA/history guards, but the extension can execute modified working-tree shim bytes before those guards run. |

**Score:** 11/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` | One current protected release/recovery authority | ✓ VERIFIED | Substantive, tracked, globally consistent before the historical boundary. |
| Package READMEs | Manifest-derived current compatibility | ✓ VERIFIED | Root, admin, and inbound documentation contract passed. |
| `164-TRUTH-DISPOSITION.tsv` | Complete exact-one disposition ledger | ✓ VERIFIED | Canonical bytes parse and current rows match the index, but enforcement of tracked state is defective below. |
| `scripts/validate_repository_truth.exs` | Shared production truth validator | ✗ FAILED | Substantive and wired, but fails to authenticate tracked-state claims; invalid standalone invocations also silently exit 0. |
| `scripts/closeout_repository_truth.sh` | Canonical fail-closed evidence composition | ✓ VERIFIED | Shell-valid and behaviorally tested across hostile identity, output, and evidence cases. |
| `scripts/finalize_phase_164.sh` | Hash-bound pre-verification/terminal lifecycle gate | ✓ VERIFIED | Its internal SHA/history, raw-source, timestamp, and porcelain checks are substantive and tested. |
| `.gsd/extensions/finalize-phase/index.ts` | Authenticated dispatcher for the tracked finalizer | ✗ FAILED | Executes working-tree finalizer bytes after only an index-membership check. |
| `164-FINALIZATION.md` | Accurate lifecycle contract | ✓ VERIFIED | Documents verified implementation SHA and first-parent completion-metadata boundary. |
| `164-VALIDATION.md` | Complete task/threat verification map | ✓ VERIFIED | Covers Plans 01-16 and preserves the pending post-completion terminal gate. |
| Phase-owned focused tests | Non-vacuous production-seam proof | ⚠️ PARTIAL | 98 tests pass, but neither current critical review defect is exercised. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Current maintainer prose | protected release workflow | whole-non-historical authority projection | ✓ WIRED | Plan 164-16 repair and four active contract tests pass. |
| Package READMEs | package manifests | dynamically derived major/minor assertions | ✓ WIRED | Docs contract passed. |
| Six ignore files and durable proof | truth ledger | repository-derived exact-set validation | ⚠️ PARTIAL | Subject inventory is wired, but `state=tracked` is not authenticated against Git per row. |
| Closeout | authoritative ledger | exact canonical path and production CLI | ✓ WIRED | Caller-selected ledger paths are rejected before evidence collection. |
| Extension | phase finalizer | `git ls-files` followed by `pi.exec("bash", working-tree-path)` | ✗ NOT_WIRED SAFELY | Membership is not HEAD-byte authentication; mutable code is executed. |
| Finalizer | CI and scheduled raw sources | exact attempt/event/SHA/provenance checks | ✓ WIRED | Behavioral and mutation tests passed. |
| Passing verifier | terminal HEAD | `verified_implementation_sha` plus per-commit first-parent allowlist | ✓ WIRED INTERNALLY | Shell gate is correct, but the unsafe extension entrypoint can bypass it. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Truth ledger validation | tracked-state assertion | ledger row plus filesystem regular-file check | No Git membership proof | ✗ DISCONNECTED |
| Finalizer dispatch | executable bytes | mutable working-tree phase shim | Not authenticated to HEAD | ✗ DISCONNECTED |
| Closeout report | Git/hygiene/workspace/ledger/CI/scheduled results | real repository commands and persisted component sources | Yes | ✓ FLOWING |
| Pre-verification evidence | exact protected-main CI/scheduled identities | ignored raw report sources | Yes, explicitly non-terminal | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete focused Phase 164 contracts | `mix test` over five Phase 164-linked files | 98 tests, 0 failures, 1 historical skip | ✓ PASS |
| Canonical authoritative ledger | `elixir scripts/validate_repository_truth.exs --repo ... --ledger ...` | `repository truth ledger: valid` | ✓ PASS |
| False tracked-state claim | disposable clone; `git rm --cached README.md`; call `RepositoryTruthLedger.validate/2` | returned `:ok` while `README.md` was untracked | ✗ FAIL |
| Node CI-monitor contract | `node --test test_js/ci-monitor.test.cjs` | 5 tests passed | ✓ PASS |
| Shell entrypoints | `bash -n` over closeout, finalizer, scheduled evidence, and phase shim | exit 0 | ✓ PASS |
| Elixir formatting | `mix format --check-formatted` over Phase 164 source/tests | exit 0 | ✓ PASS |
| Standalone validator invalid invocation | no arguments; `--ledgr bogus` | both exit 0 with zero output | ⚠️ WARNING |
| Whitespace integrity | `git diff --check` | exit 0 | ✓ PASS |

### Probe Execution

SKIPPED — no `probe-*.sh` is declared for Phase 164. The focused production scripts and tests are the documented execution seams.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| TRTH-01 | 164-02, 03, 06, 07, 14-16 | Guidance agrees with protected workflow, published package state, and supported commands. | ✓ SATISFIED | Whole-document maintaining contract and manifest-derived package contracts pass. |
| TRTH-02 | 164-01, 04, 06-09, 11, 13-15 | Every changed/generated artifact and ignore rule is truthfully classified; proof remains discoverable. | ✗ BLOCKED | CR-02: tracked-state rows are accepted without Git membership, so the machine-enforced classification can be false. |
| TRTH-03 | 164-05-07, 09-15 | Reproducible exact-main closeout with clean Git, protected CI, explained schedules, and complete dispositions. | ✗ BLOCKED | CR-01: the dispatcher can execute uncommitted shim bytes before the protected finalizer gates. |

All requirement IDs declared across all sixteen PLAN frontmatters are exactly TRTH-01, TRTH-02, or TRTH-03, and all three are present in `.planning/REQUIREMENTS.md`. No orphaned Phase 164 requirement exists. No later milestone phase exists to defer either blocker.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | Behavioral/value | INSUFFICIENT — no Git-membership mutation for a tracked row |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | Process/behavioral | INSUFFICIENT — extension test checks source strings, not staged/modified dispatcher behavior |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | Process/behavioral | PASS |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | Whole-document value/contract | PASS |
| `docs_contract_test.exs` | TRTH-01 | yes | 1 historical | No | Value/contract | PASS with unrelated historical skip |

No disabled test is the sole proof for a Phase 164 requirement, and no circular expected-value generator was found. The 98-test green result does not prove the two untested trust boundaries.

### Anti-Patterns and Review Findings

| Finding | Independent Verdict | Classification | Goal/Requirement Impact |
| --- | --- | --- | --- |
| CR-01 mutable working-tree finalizer execution | CONFIRMED | 🛑 BLOCKER | Directly contradicts reliable protected closeout authority and TRTH-03. |
| CR-02 untracked regular file accepted as tracked | CONFIRMED + REPRODUCED | 🛑 BLOCKER | Directly contradicts truthful evidence-backed classification and TRTH-02. |
| WR-01 invalid standalone validator invocation exits 0 | CONFIRMED | ⚠️ WARNING | Weakens direct CLI robustness, but does not independently block the phase because the documented closeout path supplies both exact required flags and preserves nonzero validation failure. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the phase-owned implementation files.

### Decision Coverage

All 12 trackable `164-CONTEXT.md` decisions are honored according to the non-blocking decision-coverage gate. This heuristic does not override the concrete CR-01/CR-02 failures.

### Human Verification Required

N/A — repository infrastructure/documentation phase with no user-facing UI. Both blockers are programmatically observable. Judgment-tier prohibition conclusions remain explicitly non-authoritative and human review is recommended, but no manual test can convert either failed truth to verified.

### Gaps Summary

Plan 164-16 successfully closed the prior TRTH-01 documentation contradiction. Phase 164 still cannot pass because its two trust anchors are not trustworthy under adversarial but valid repository states: the ledger can certify an untracked file as tracked, and the extension can execute finalizer bytes that were never authenticated to `HEAD`. These directly defeat the phase goal's promise that maintainers can rely on tracked artifacts and final evidence.

The standalone validator's no-argument/unknown-option success remains a warning, not a separate blocker. The post-completion terminal `/finalize-phase 164` capture remains downstream of a future passing verifier and protected completion-metadata integration; it must not run to bless the current defective implementation.

## Recommended Fix Plan

### 164-17-PLAN.md: Authenticate tracked artifacts and finalizer bytes

1. Make `RepositoryTruthLedger.validate/2` require exact Git index membership and expected file type for every `state=tracked` subject; add committed-versus-untracked disposable-repository tests.
2. Make the extension authenticate the phase finalizer against `HEAD` and execute an immutable verified blob; add staged-new, unstaged-modified, and unchanged-committed behavioral tests.
3. Fix direct validator argument handling as a bounded companion warning, then rerun the complete Phase 164 focused suite, production validator reproduction, Node tests, syntax, formatting, and diff checks.

---

_Verified: 2026-09-09T22:52:25Z_
_Verifier: the agent (gsd-verifier)_
