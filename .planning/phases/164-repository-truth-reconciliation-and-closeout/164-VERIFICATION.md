---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-10T15:20:07Z
verified_implementation_sha: 38e7d8a8c4b77a88fb879c56b17b19b45a3bfb43
status: gaps_found
next_action: "Gaps found. Plan the fixes, then re-run execute-phase before shipping."
next_command: "$gsd-plan-phase 164 --gaps"
score: 12/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/13
  gaps_closed:
    - "Tracked subjects now require one byte-exact NUL-delimited stage-0 Git-index record; stage-1/2/3 conflicts are rejected."
    - "The lexical Phase 164 shim is authenticated before realpath resolution and non-164 phases are rejected."
    - "Declared transitive helpers/data are privately materialized and print failures clean the private root before exit."
  gaps_remaining:
    - "Dependency authentication is not pinned to one immutable commit OID; each awaited Git operation resolves symbolic HEAD again."
    - "The authenticated numbered-plan manifest can silently shrink when a complete PLAN/SUMMARY pair is deleted."
    - "The worktree-loaded extension that creates the authority root is itself outside that authenticated root."
  regressions: []
gaps:
  - truth: "TRTH-03 / D-09 / D-10 / D-11: Finalization authenticates one immutable repository state before phase code runs."
    status: failed
    reason: "Many awaited cat-file, diff, ls-tree, and show calls address symbolic HEAD, so a concurrent HEAD move can create a mixed-commit authority root."
    artifacts:
      - path: ".gsd/extensions/finalize-phase/index.ts"
        issue: "No commit OID is captured, reused, and rechecked before Bash dispatch."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "No real-handler regression moves HEAD between authentication calls."
    missing:
      - "Resolve one full commit OID, use it for every tree/blob operation, and re-check checkout HEAD before dispatch."
      - "Add a moving-HEAD production-seam regression."
  - truth: "TRTH-03 / D-12: Terminal finalization requires the complete authoritative Phase 164 plan/summary history."
    status: failed
    reason: "The numbered set is derived from files still present at HEAD and only required to be nonempty/unique; deleting both members of a pair silently shrinks it."
    artifacts:
      - path: ".gsd/extensions/finalize-phase/index.ts"
        issue: "numberedPhaseDependencies() has no anchored terminal number or contiguous exact-set check."
      - path: "scripts/finalize_phase_164.sh"
        issue: "Terminal state checks summaries only for plans that remain."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "No middle-pair or terminal-pair deletion regression exists."
    missing:
      - "Authenticate an authoritative expected set through Plan 20 and require exactly one PLAN/SUMMARY per number."
      - "Add paired-deletion regressions."
  - truth: "TRTH-03 / D-09 / D-10 / D-11: No mutable checkout executable outside the authenticated root can decide the verdict."
    status: failed
    reason: "GSD imports index.ts from the checkout before it authenticates anything; the module never authenticates its own bytes, so an assume-unchanged mutation can replace the trust bootstrap."
    artifacts:
      - path: ".gsd/extensions/finalize-phase/index.ts"
        issue: "The trust-establishing extension executes before and outside its materialized dependency set."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "Hidden-mutation coverage omits index.ts itself."
    missing:
      - "Move authentication before extension evaluation in a trusted loader/installed command, or explicitly narrow the guarantee to trust local extension bytes."
      - "Add an extension-self-mutation subprocess regression."
prohibition_flags:
  - statement: "D-09/D-10/D-11: MUST NOT execute finalization dependencies absent from or different from authenticated HEAD."
    verdict: "violated — symbolic HEAD can change across authentication and the worktree-loaded extension is unauthenticated"
  - statement: "D-05/D-06/D-12: MUST NOT represent invalid or unmerged Git-index state as tracked proof."
    verdict: "supported by stage-0 regressions; non-authoritative autonomous judgment, human review recommended"
  - statement: "All other judgment-tier prohibitions from Plans 164-01 through 164-20."
    verdict: "non-authoritative autonomous judgment: no additional violation observed; human review recommended"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-10T15:20:07Z
**Implementation SHA evaluated:** `38e7d8a8c4b77a88fb879c56b17b19b45a3bfb43`
**Status:** gaps_found
**Re-verification:** Yes — Plans 164-18 through 164-20 close the prior stage/shim/descendant-chain reproductions, but the current review's three deeper trust findings are substantiated.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees with protected workflow facts. | ✓ VERIFIED | The whole-current-region maintaining contract passes four active tests. |
| 2 | Historical procedures are explicitly bounded, leaving one current runbook. | ✓ VERIFIED | One exact historical boundary exists and duplicate/missing boundaries are rejected. |
| 3 | Current package guidance agrees with current manifests. | ✓ VERIFIED | Documentation tests pass against the current 2.5/2.2 package state. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | The D-08 digest/remove row remains valid and the root artifact is absent. |
| 5 | Durable scheduled/release/publish/planning proof remains tracked and discoverable. | ✓ VERIFIED | Canonical ledger validation passes. |
| 6 | Every tracked disposition requires exactly one byte-exact stage-0 Git-index identity. | ✓ VERIFIED | The staged NUL parser and genuine unmerged-index production test pass. |
| 7 | Retained ignore rules are narrow and producer-owned. | ✓ VERIFIED | 72 ledger ignore rows equal 72 non-comment rules across six ignore files. |
| 8 | One rerunnable command composes Git, hygiene, preservation, ledger, CI, and scheduled authorities. | ✓ VERIFIED | Closeout is substantive, shell-valid, authority-root wired, and process-tested. |
| 9 | Quiet requires canonical repo/ledger, ignored output, exact origin/main, and post-write cleanliness. | ✓ VERIFIED | Hostile path, identity, and late-dirt regressions pass. |
| 10 | Malformed, future, or stale scheduled timestamps cannot be current. | ✓ VERIFIED | Producer and finalizer enforce bounded nonnegative age. |
| 11 | Quiet requires the exact-one ledger gate and all current audited subjects. | ✓ VERIFIED | The current 111-row ledger passes the production validator. |
| 12 | Evidence selection permits only attempt-one normal push CI and natural same-SHA schedules. | ✓ VERIFIED | Selection/provenance contracts and CI-monitor tests pass; terminal capture remains pending. |
| 13 | Terminal finalization is bound to one immutable, complete, authenticated repository state. | ✗ FAILED | Symbolic HEAD is re-resolved, paired history deletion shrinks the manifest, and the trust-establishing extension executes from unauthenticated worktree bytes. |

**Score:** 12/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` and package READMEs | Current operational/package truth | ✓ VERIFIED | Current contracts pass. |
| `164-TRUTH-DISPOSITION.tsv` | Exact-one disposition ledger | ✓ VERIFIED | 111 rows; canonical validator reports valid. |
| `scripts/validate_repository_truth.exs` | Stage-aware truth validator | ✓ VERIFIED | Exact staged-record parser is wired and tested. |
| `scripts/closeout_repository_truth.sh` | Fail-closed authority composition | ✓ VERIFIED | Reads helper/data paths through `authority_root`. |
| `scripts/finalize_phase_164.sh` | Terminal lifecycle gate | ⚠ PARTIAL | Paired plan/summary deletion is not detected. |
| `.gsd/extensions/finalize-phase/index.ts` | Immutable authenticated dispatcher/bootstrap | ✗ FAILED | Descendants are materialized, but commit identity, manifest cardinality, and bootstrap are not anchored. |
| `164-VALIDATION.md` | Current automated proof map | ⚠ PARTIAL | Correctly records 114 passing tests but omits current critical attacks. |
| `164-FINALIZATION.md` | Truthful lifecycle contract | ✗ FAILED | Claims a closed immutable authority chain that code does not establish. |

### Key Link Verification

| From | To | Status | Evidence |
| --- | --- | --- | --- |
| Maintainer/package prose | workflows/manifests | ✓ WIRED | Current contracts pass. |
| Ledger validator | target Git index | ✓ WIRED | `ls-files --stage -z` plus direct behavioral proof. |
| Extension | lexical Phase 164 shim | ✓ WIRED | Symlink and alternate-phase regressions pass. |
| Private finalizer | declared descendants | ✓ WIRED | Hidden descendant mutations do not execute. |
| Authentication operations | one immutable commit | ✗ NOT WIRED | Every operation still names symbolic `HEAD`. |
| Phase identity | complete Plan 01-20 history | ✗ NOT WIRED | Completeness is derived from remaining files. |
| Trusted loader | extension bootstrap | ✗ NOT WIRED | The extension is evaluated directly from the worktree. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Status |
| --- | --- | --- | --- |
| Ledger | audited subjects/dispositions | Git index, ignores, proof paths | ✓ FLOWING |
| Closeout report | Git/CI/scheduled/component status | live observations plus private authority tools | ✓ FLOWING |
| Private authority root | dependency bytes | repeated symbolic-HEAD reads | ✗ MIXED-AUTHORITY RISK |
| Numbered phase history | PLAN/SUMMARY set | files remaining at HEAD | ✗ HOLLOW COMPLETENESS |

### Behavioral Spot-Checks

| Behavior | Result | Status |
| --- | --- | --- |
| Complete focused Phase 164 contracts | 114 tests, 0 failures, 1 historical skip | ✓ PASS |
| Canonical production ledger | `repository truth ledger: valid` | ✓ PASS |
| CI monitor contract | 5 tests passed | ✓ PASS |
| Bash syntax and `git diff --check` | exit 0 | ✓ PASS |
| Immutable commit binding | no captured OID; symbolic HEAD used across awaited calls | ✗ FAIL |
| Complete numbered history | only nonempty/unique remaining paths required | ✗ FAIL |
| Authenticated bootstrap | extension omitted from hidden-mutation boundary | ✗ FAIL |

### Probe Execution

SKIPPED — no `probe-*.sh` is declared. Terminal `/finalize-phase 164` was correctly not run before a passing verifier and protected metadata integration.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| TRTH-01 | 164-02, 03, 06, 07, 14-16 | ✓ SATISFIED | Current documentation contracts pass. Its unchecked REQUIREMENTS checkbox is stale metadata, not contrary code evidence. |
| TRTH-02 | 164-01, 04, 06-09, 11, 13-15, 17, 18, 20 | ✓ SATISFIED | Stage-0 repair, validator, and linked tests pass. |
| TRTH-03 | 164-05-07, 09-15, 17, 19, 20 | ✗ BLOCKED | The finalizer trust bootstrap can mix commits, lose complete history, or be replaced before authentication. |

All requirement IDs from all twenty PLAN frontmatters resolve to these three IDs in `REQUIREMENTS.md`. No Phase 164 requirement is orphaned and no later milestone phase exists for deferral.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Verdict |
| --- | --- | --- | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | PASS — behavioral |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | INSUFFICIENT — no moving-HEAD, paired-history deletion, or extension-self-mutation case |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | PASS — behavioral |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | PASS — value/behavioral |
| `docs_contract_test.exs` | TRTH-01 | yes | 1 historical | No | WARNING — four current 2.5 literals duplicate manifest-derived expectations |
| `ci-monitor.test.cjs` | TRTH-03 | yes | 0 | No | PASS — behavioral |

No requirement depends solely on a disabled test and no circular expected-value generator was found.

### Review, Security, and Validation Reconciliation

| Finding/claim | Verdict | Impact |
| --- | --- | --- |
| REVIEW CR-01: authentication is not bound to one immutable HEAD | CONFIRMED | 🛑 BLOCKER |
| REVIEW CR-02: paired plan/summary deletion shrinks the trusted manifest | CONFIRMED | 🛑 BLOCKER |
| REVIEW CR-03: root extension executes before authentication | CONFIRMED | 🛑 BLOCKER |
| REVIEW WR-01: docs test hardcodes 2.5 | CONFIRMED | ⚠ WARNING; current docs remain correct |
| SECURITY: T-164-17 closed / secured | CONTRADICTED | Descendants are materialized, but immutable-commit and bootstrap trust remain open. |
| VALIDATION: no automated gaps through Plan 20 | CONTRADICTED | The 114 tests pass but do not cover the three current attacks. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `.gsd/extensions/finalize-phase/index.ts` | 119-197 | repeated symbolic `HEAD` | 🛑 Blocker | mixed-commit root possible |
| `.gsd/extensions/finalize-phase/index.ts` | 162-186 | self-derived nonempty numbered manifest | 🛑 Blocker | paired deletion invisible |
| `.gsd/extensions/finalize-phase/index.ts` | module entry | unauthenticated trust bootstrap | 🛑 Blocker | hidden extension mutation bypasses checks |
| `test/mailglass/docs_contract_test.exs` | 52-58 | hardcoded package version | ⚠ Warning | next package-line change creates a false failure |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in reviewed phase files.

### Decision and Prohibition Coverage

The non-blocking decision gate reports 12/12 trackable context decisions honored. It cannot override concrete trust failures.

All 23 PLAN prohibitions remain judgment-tier/unresolved. Autonomous review is non-authoritative: the stage-0 prohibition is supported, while the prohibition against executing dependencies absent from or different from authenticated HEAD is violated. Human review remains recommended for the others, but the automated blockers already determine `gaps_found`.

### Human Verification Required

None can close the observed code defects. Terminal finalization must remain unrun until blockers are fixed, ordinary verification passes, and completion metadata reaches protected main.

### Gaps Summary

Plans 164-18 and 164-19 close the previously reported conflict-stage, lexical-shim, alternate-phase, descendant hidden-mutation, and print-cleanup defects. The remaining three gaps share one root concern: the implementation still does not establish one immutable and complete authenticated repository state. They block TRTH-03. No gap is deferred because Phase 164 is the final milestone phase.

---

_Verified: 2026-09-10T15:20:07Z_
_Verifier: the agent (gsd-verifier)_
