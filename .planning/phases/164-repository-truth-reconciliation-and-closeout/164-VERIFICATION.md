---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-09T19:25:08Z
status: gaps_found
score: 11/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/13
  gaps_closed:
    - "Closeout now binds --ledger to the authoritative Phase 164 ledger and invokes the shared complete validator."
    - "Closeout now rejects noncanonical repositories and non-ignored outputs and rechecks stable porcelain after writes."
    - "Fresh pre-verification evidence exists for integrated implementation SHA d903b040c72fff62a69a57cacbcc7e7d7c2f6167."
  gaps_remaining: []
  regressions:
    - "Terminal finalization accepts a stale status: passed verifier without binding it to the implementation being finalized."
    - "Pre-verification stops at summaries 01-11 and does not require the Plan 13 repair contract."
    - "A hostile-path test can recursively delete a pre-existing sibling directory outside its temporary root."
    - "Scheduled evidence freshness accepts timestamps in the future."
gaps:
  - truth: "D-09 through D-11/TRTH-03: Terminal final evidence is bound to the implementation that received goal-level verification."
    status: failed
    reason: "Terminal mode checks only for status: passed in 164-VERIFICATION.md; it compares no verified implementation SHA and permits arbitrary source changes before terminal HEAD."
    artifacts:
      - path: "scripts/finalize_phase_164.sh"
        issue: "require_terminal_state at lines 98-120 accepts a stale passing verifier solely by frontmatter status."
      - path: ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md"
        issue: "The promised terminal boundary is not backed by an executable verified-source binding."
    missing:
      - "Record a verified implementation SHA and bind terminal HEAD to it with an explicit metadata-only diff allowlist, or use an equivalent hash-bound final verification result."
      - "Add a regression proving a source commit after a passing verifier is rejected."
  - truth: "D-09/D-10/TRTH-03: Pre-verification mechanically requires the complete tracked repair through Plan 164-13 before evidence collection."
    status: failed
    reason: "The actual d903b040 capture contains Plan 13, but the reusable gate only checks summaries 01 through 11."
    artifacts:
      - path: "scripts/finalize_phase_164.sh"
        issue: "require_pre_verification_state at lines 90-96 never requires 164-12-SUMMARY.md or 164-13-SUMMARY.md."
      - path: ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md"
        issue: "The pre-verification instructions still say Plans 01-11, conflicting with Plan 164-14."
    missing:
      - "Require the current expected summary set through Plan 13 before collection."
      - "Add a process regression proving missing 164-13-SUMMARY.md prevents collection."
  - truth: "Phase-owned verification is safe to run and cannot delete unrelated developer data."
    status: failed
    reason: "The hostile-repository test uses a VM-local integer for a sibling path, accepts an existing path, and unconditionally deletes it recursively on exit."
    artifacts:
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "Lines 600-606 construct a path beside the repository and call File.rm_rf!/1 without exclusive ownership proof."
    missing:
      - "Use an exclusively-created temporary directory or keep the fixture under the test temporary root."
      - "Delete only a path this invocation proves it owns."
  - truth: "D-11/TRTH-03: Malformed or temporally impossible scheduled evidence cannot be accepted as current."
    status: partial
    reason: "Both freshness checks enforce only age <= max_age. A future timestamp produces a negative age and passes; an independent jq probe returned true for now+86400 seconds."
    artifacts:
      - path: "scripts/scheduled_control_evidence.sh"
        issue: "Lines 348-352 omit a nonnegative-age check."
      - path: "scripts/finalize_phase_164.sh"
        issue: "Lines 177-180 repeat the one-sided predicate, so independent validation does not catch it."
    missing:
      - "Require age >= 0 and age <= max_age, with an explicitly bounded clock-skew allowance only if needed."
      - "Add future and invalid timestamp fixtures to both evidence layers."
prohibition_flags:
  - statement: "MUST NOT label the repository quiet when evidence is stale, malformed, mismatched, missing, or unexplained."
    verdict: "non-authoritative LLM judgment: violated by stale-verifier binding and future-timestamp acceptance"
  - statement: "MUST NOT represent pre-verification evidence as terminal evidence or edit tracked state after capture."
    verdict: "non-authoritative LLM judgment: lifecycle is documented, but executable verifier-to-HEAD binding is incomplete; human review recommended"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-09T19:25:08Z
**Status:** gaps_found
**Re-verification:** Yes — prior gaps closed, current review exposed new blockers.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees with protected workflow facts. | ✓ VERIFIED | `MAINTAINING.md:5-48` names exact authority, identity, scheduled evidence, immutable target, and fail-closed states; contract passed. |
| 2 | Historical v1 procedures are discoverable but non-current. | ✓ VERIFIED | Current guidance disclaims historical procedures as alternate authority; contract passed. |
| 3 | Package guidance matches core/admin 2.5 and inbound 2.2 manifests. | ✓ VERIFIED | README constraints and manifest-derived docs contract agree. |
| 4 | Locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | D-08 locked digest/remove row remains; root output is absent; production validator passed. |
| 5 | Durable scheduled/release/publish/planning proof remains tracked. | ✓ VERIFIED | Principal artifacts are tracked and repository-derived validation passed. |
| 6 | Every scoped artifact and ignore rule has one complete disposition. | ✓ VERIFIED | Production validator printed `repository truth ledger: valid`; adversarial completeness tests are active. |
| 7 | Retained ignore rules are narrow and producer-owned. | ✓ VERIFIED | Six-file exact-set inventory passed; no broad proof-hiding rule found. |
| 8 | One rerunnable command composes all evidence authorities. | ✓ VERIFIED | `closeout_repository_truth.sh:132-143` invokes workspace, ledger, CI, and scheduled sources; focused tests passed. |
| 9 | Quiet requires canonical repo/ledger, ignored output, exact origin/main, and post-write cleanliness. | ✓ VERIFIED | Exact path gates and late-dirt regression tests passed. |
| 10 | Quiet rejects malformed temporal scheduled evidence. | ✗ FAILED | Exact provenance is checked, but future timestamps pass both one-sided age predicates. |
| 11 | Quiet requires the complete exact-one ledger gate. | ✓ VERIFIED | Closeout invokes the canonical shared validator; canonical ledger passed independently. |
| 12 | Handoff uses attempt-one normal push CI and natural same-SHA schedules. | ✓ VERIFIED | Raw sources for `d903b040...` match CI run `34284583200` and the exact natural attempt-one control set. |
| 13 | Final evidence reliably describes the verified implementation and terminal state. | ✗ FAILED | Terminal mode accepts any older `status: passed` verifier without a verified-source SHA binding; terminal capture is not yet run. |

**Score:** 11/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` | Current release/recovery truth | ✓ VERIFIED | Substantive, tracked, contract-tested. |
| Package READMEs | Manifest-derived compatibility | ✓ VERIFIED | Root/admin/inbound constraints dynamically checked. |
| `164-TRUTH-DISPOSITION.tsv` | Complete artifact/ignore ledger | ✓ VERIFIED | Canonical validator passed. |
| `scripts/validate_repository_truth.exs` | Shared validator | ✓ VERIFIED | Tracked and invoked by tests and closeout. |
| `scripts/closeout_repository_truth.sh` | Canonical fail-closed composition | ⚠️ PARTIAL | Original gaps closed; upstream freshness accepts future timestamps. |
| `scripts/finalize_phase_164.sh` | Safe lifecycle gate | ✗ FAILED | Omits Plan 13 prerequisite and verified-source binding. |
| `test/scripts/phase_164_closeout_test.exs` | Safe hostile-path contract | ✗ FAILED | Passing test contains unsafe out-of-root cleanup. |
| `164-FINALIZATION.md` | Accurate lifecycle contract | ⚠️ PARTIAL | Still says Plans 01-11 and lacks a verifier-SHA contract. |
| Ignored pre-verification evidence | Exact protected implementation proof | ✓ VERIFIED | Report/raw sources exist and independently validate for `d903b040...`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Maintainer/package docs | workflows/manifests | contract assertions | ✓ WIRED | Focused documentation tests passed. |
| Closeout | authoritative ledger | exact CLI invocation | ✓ WIRED | Shared validator called at closeout line 136. |
| Closeout | canonical repo/output | physical identity, ignore gate, post-write porcelain | ✓ WIRED | Prior gaps closed and hostile fixtures pass. |
| Finalizer | Plan 13 prerequisite | summary presence | ✗ NOT_WIRED | Loop stops at summary 11. |
| Passing verifier | terminal HEAD | verified SHA and metadata-only delta | ✗ NOT_WIRED | Only `status: passed` is checked. |
| Scheduled sweep | final raw validation | freshness and provenance | ⚠️ PARTIAL | Identity is checked; negative age is accepted. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Closeout report | Git/hygiene/workspace/ledger/CI/scheduled | Real Git and existing tools | Yes | ✓ FLOWING |
| Pre-verification report | protected-main identities | Ignored raw files | Yes, for `d903b040...` | ✓ FLOWING |
| Terminal verifier authority | verifier applicability to terminal source | Verification frontmatter | No implementation identity flows | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Phase 164 contracts | four focused ExUnit files | 81 tests, 0 failures, 1 pre-existing historical skip | ✓ PASS |
| Authoritative ledger | production validator CLI | `repository truth ledger: valid` | ✓ PASS |
| Shell syntax | `bash -n` on closeout/finalizer/shim | exit 0 | ✓ PASS |
| Pre-verification raw identity | exact CI/scheduled jq predicates | both true | ✓ PASS |
| Future timestamp rejection | one-day-future jq age probe | `true` | ✗ FAIL |

### Probe Execution

SKIPPED — no Phase 164 `probe-*.sh` is declared; focused scripts and the finalizer are the execution seams.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| TRTH-01 | 164-02, 03, 06, 07, 14 | ✓ SATISFIED | Maintainer and package contracts pass. |
| TRTH-02 | 164-01, 04, 06-09, 11, 13, 14 | ✓ SATISFIED | Canonical exact-one validator passes against proof and six ignore inventories. |
| TRTH-03 | 164-05-07, 09-14 | ✗ BLOCKED | Terminal verification is not source-bound; pre-verification is under-scoped; future timestamps can pass. |

Every requirement ID from all fourteen PLAN frontmatters is one of TRTH-01, TRTH-02, or TRTH-03 and is present in REQUIREMENTS.md. No orphaned Phase 164 requirement exists.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | Behavioral/value | PASS |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | Process/behavioral | BLOCKER: unsafe cleanup and missing review regressions |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | Value/contract | PASS |
| `docs_contract_test.exs` | TRTH-01 | yes | 1 unrelated Phase 38 test | No | Value/contract | PASS with existing skip |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | Behavioral | WARNING: no future-timestamp rejection |

The skipped historical test is not the sole proof for any Phase 164 requirement. No circular expected-value generator was found.

### Anti-Patterns and Advisory Review Findings

| Finding | Independent Verdict | Severity | Evidence |
| --- | --- | --- | --- |
| CR-01 stale verifier can authorize later source | CONFIRMED | 🛑 BLOCKER | `finalize_phase_164.sh:115-120` checks only status; no SHA/diff binding exists. |
| CR-02 pre-verification omits Plans 12/13 | CONFIRMED | 🛑 BLOCKER | `finalize_phase_164.sh:93-95` loops only through 11. Actual capture contains Plan 13, but the gate does not enforce it. |
| CR-03 cleanup may remove unrelated sibling | CONFIRMED | 🛑 BLOCKER | Test lines 600-606 use VM-local uniqueness and unconditional recursive deletion outside the temp root. |
| WR-01 future timestamps accepted | CONFIRMED | ⚠️ WARNING / goal gap | Both predicates lack `age >= 0`; direct probe returned true one day ahead. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in phase-owned implementation files.

### Decision Coverage

All 12 trackable CONTEXT decisions are honored by shipped artifacts according to the non-blocking decision-coverage gate.

### Prohibition Review

The 13 plan prohibitions remain descriptor-less and flagged `unverified`. Automated evidence supports the no-dispatch/no-rerun, narrow-ignore, canonical-path, and durable-proof portions. The false-quiet family cannot pass judgment while verifier binding and timestamp validation remain open. These are non-authoritative LLM judgments; human review remains recommended after remediation.

### Gaps Summary

The prior three gaps were genuinely repaired, and the integrated implementation has internally consistent exact-SHA pre-verification evidence. Phase 164 still cannot pass: terminal finalization can reuse an old passing verifier after source changes; pre-verification does not enforce the current Plan 13 prerequisite; a phase-owned test has destructive cleanup risk; and future scheduled timestamps are accepted as fresh. No later milestone phase exists to defer these gaps.

The checkout is `main` at `38928c92...`, five metadata/review commits ahead of `origin/main` at `d903b040...`. This pre-integration delta is not itself treated as an implementation gap. Terminal capture remains a post-completion operation, but its binding defect must be repaired first.

---

_Verified: 2026-09-09T19:25:08Z_
_Verifier: the agent (gsd-verifier)_
