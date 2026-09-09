---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-09T21:23:26Z
verified_implementation_sha: 6b8e5948e8b6c5cd512deccc1c58643836d6a1e6
status: gaps_found
score: 11/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/13
  gaps_closed:
    - "Terminal finalization now requires one exact verified_implementation_sha and rejects forbidden source history in every later first-parent commit."
    - "Pre-verification now requires summaries 164-01 through 164-13 before evidence collection."
    - "The hostile sibling fixture now requires exclusive allocation and a matching non-symlink ownership token before recursive cleanup."
    - "Scheduled evidence producer and finalizer now reject malformed, future, and over-age timestamps with a closed freshness interval."
  gaps_remaining: []
  regressions:
    - "A previously missed contradiction remains in current-facing MAINTAINING.md: the Bus Factor & Continuity section describes release as hands-free after gates pass."
gaps:
  - truth: "TRTH-01 / D-01 / D-02 / D-04: Maintainers have one unmistakable current release and recovery path whose authority agrees everywhere with the protected exact-candidate workflow."
    status: failed
    reason: "MAINTAINING.md first documents protected exact-candidate dispatch plus repository-admin authorization, then its still-current Bus Factor & Continuity section says the release pipeline is hands-free after gates pass and has no reviewer control. The focused contract scopes its negative assertions too narrowly and passes despite the contradiction."
    artifacts:
      - path: "MAINTAINING.md"
        issue: "Lines 359-366 present obsolete v0.1/v0.5 hands-free authority before the Historical release procedures boundary."
      - path: "test/mailglass/publish/maintaining_release_gate_contract_test.exs"
        issue: "The test refutes obsolete authority only inside the opening extracted section, not across all non-historical guidance."
    missing:
      - "Move or explicitly bound the obsolete v0.1/v0.5 release-authority prose as historical, or rewrite it to match the protected exact-candidate/repository-admin workflow."
      - "Extend the contract to reject hands-free/no-approval authority throughout all non-historical content."
prohibition_flags:
  - statement: "D-01/D-04: MUST NOT broaden protected exact-candidate or repository-admin authorization."
    verdict: "non-authoritative LLM judgment: violated by the current Bus Factor & Continuity guidance; remediation required"
  - statement: "Phase 164 finalization and evidence MUST NOT use caller-selected, rerun, stale, malformed, future-dated, alternate-SHA, or post-verification source evidence."
    verdict: "non-authoritative LLM judgment: automated production-seam tests support compliance; human review recommended"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-09T21:23:26Z
**Implementation SHA evaluated:** `6b8e5948e8b6c5cd512deccc1c58643836d6a1e6`
**Status:** gaps_found
**Re-verification:** Yes — all four prior gaps closed; one previously missed documentation blocker remains.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees throughout with protected workflow facts. | ✗ FAILED | `MAINTAINING.md:5-48` states the protected exact-candidate/repository-admin boundary, but lines 359-366 call the current pipeline hands-free after gates pass. |
| 2 | Historical release procedures are explicitly bounded, leaving one unmistakable current runbook. | ✗ FAILED | The named historical section is bounded, but obsolete v0.1/v0.5 authority remains in non-historical content before that boundary. |
| 3 | Current package guidance matches the core/admin 2.5 and inbound 2.2 manifests. | ✓ VERIFIED | Manifest-derived README contract passed in the 96-test focused run. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | The ledger retains the exact `331810b4...04ece7e` D-08 digest/remove row and the root file is absent. |
| 5 | Durable scheduled/release/publish/planning proof remains tracked and discoverable. | ✓ VERIFIED | The production repository-derived ledger validator passed against the canonical checkout. |
| 6 | Every scoped artifact and non-comment rule in all six ignore files has one complete disposition. | ✓ VERIFIED | The authoritative validator printed `repository truth ledger: valid`; exact-set and hostile ledger tests passed. |
| 7 | Retained ignore rules are narrow and producer-owned. | ✓ VERIFIED | Six-file inventory and `.gsd` exception tests passed; only the named extension is re-included while runtime state remains ignored. |
| 8 | One rerunnable command composes Git, hygiene, preservation, ledger, CI, and scheduled authorities. | ✓ VERIFIED | `closeout_repository_truth.sh` invokes the real authority seams and its process tests passed. |
| 9 | Quiet requires canonical repo/ledger, ignored output, exact origin/main, and post-write cleanliness. | ✓ VERIFIED | Alternate repository/ledger/output, symlink, and late-dirt process regressions passed. |
| 10 | Malformed, future, or stale scheduled timestamps cannot be accepted as current. | ✓ VERIFIED | Both production predicates enforce `0 <= age <= max_age_seconds`; producer and finalizer mutation tests passed. |
| 11 | Quiet requires the complete exact-one ledger gate. | ✓ VERIFIED | Closeout invokes the canonical shared validator with the authoritative ledger path. |
| 12 | Evidence selection permits only attempt-one normal push CI and natural same-SHA scheduled controls. | ✓ VERIFIED | Attempt/event/branch/SHA/status/digest mutation tests passed; existing d903b040 pre-verification raw evidence remains inspectable but non-terminal. |
| 13 | Terminal finalization is bound to the exact implementation verified and permits only four completion-metadata paths afterward. | ✓ VERIFIED | Process tests cover absent/malformed/non-ancestor SHA, direct forbidden source, change-then-revert history, and allowed metadata-only commits against `require_terminal_state`. |

**Score:** 11/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` | One current protected release/recovery path | ✗ FAILED | Substantive and tracked, but contains contradictory current authority. |
| Package READMEs | Manifest-derived current compatibility | ✓ VERIFIED | Root, admin, and inbound documentation contract passed. |
| `164-TRUTH-DISPOSITION.tsv` | Complete exact-one disposition ledger | ✓ VERIFIED | Canonical validator passed; D-08 and all six ignore sets remain present. |
| `scripts/validate_repository_truth.exs` | Shared production ledger validator | ⚠️ PARTIAL | Valid canonical invocation passes and closeout supplies exact flags, but standalone no-argument and misspelled-option invocations silently exit 0. |
| `scripts/closeout_repository_truth.sh` | Canonical fail-closed evidence composition | ✓ VERIFIED | Substantive, shell-valid, wired to the shared validator and authority sources, and behaviorally tested. |
| `scripts/finalize_phase_164.sh` | Hash-bound pre-verification/terminal lifecycle gate | ✓ VERIFIED | Summary prerequisites, per-commit SHA binding, raw-source checks, and stable-porcelain gates are behaviorally tested. |
| `.gsd/extensions/finalize-phase/` | Project-local finalization command | ✓ VERIFIED | Manifest declares exactly one command; dispatcher validates one tracked phase finalizer and uses `pi.exec`. |
| `164-FINALIZATION.md` | Accurate lifecycle contract | ✓ VERIFIED | Matches Plans 01-13 prerequisites and the per-first-parent verified-SHA boundary. |
| `164-VALIDATION.md` | Complete task/threat verification map | ✓ VERIFIED | Contains 164-15-01/02/03 and T-164-53 through T-164-57 mappings. |
| Phase-owned focused tests | Non-vacuous production-seam proof | ✓ VERIFIED | 96 tests, 0 failures, 1 unrelated historical skip. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Current maintainer prose | protected release workflow | authority projection | ✗ PARTIAL | Opening section agrees; later non-historical bus-factor prose contradicts it. |
| Package READMEs | package manifests | dynamically derived major/minor assertions | ✓ WIRED | Docs contract passed. |
| Six ignore files and durable proof | truth ledger | repository-derived exact-set validation | ✓ WIRED | Production validator and adversarial test passed. |
| Closeout | authoritative ledger | exact canonical path and production CLI | ✓ WIRED | Caller-selected ledger paths are rejected before collection. |
| Closeout/finalizer | CI and scheduled raw sources | exact attempt/event/SHA/provenance checks | ✓ WIRED | Behavior and mutation tests passed. |
| Passing verifier | terminal HEAD | `verified_implementation_sha` plus per-commit first-parent allowlist | ✓ WIRED | Plan 164-15 gap-closure regressions passed. |
| `164-13-SUMMARY.md` | pre-verification collection | required summary presence | ✓ WIRED | Missing-summary regression proves collection does not begin. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Closeout report | Git/hygiene/workspace/ledger/CI/scheduled results | Real repository commands and persisted component sources | Yes | ✓ FLOWING |
| Pre-verification report | protected-main identities and raw CI/scheduled evidence | Ignored report/source files for `d903b040...` | Yes, explicitly non-terminal | ✓ FLOWING |
| Terminal verifier authority | implementation identity | `verified_implementation_sha` in this report | Yes, exact evaluated commit | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete focused Phase 164 contracts | `mix test` over five Phase 164-linked test files | 96 tests, 0 failures, 1 unrelated historical skip | ✓ PASS |
| Authoritative ledger | `elixir scripts/validate_repository_truth.exs --repo ... --ledger ...` | `repository truth ledger: valid`, exit 0 | ✓ PASS |
| Shell entrypoints | `bash -n` over closeout, finalizer, scheduled evidence, and shim | exit 0 | ✓ PASS |
| Standalone validator rejects invalid invocation | no arguments; `--ledgr bogus` | both exited 0 with no output | ⚠️ WARNING |
| Current maintainer authority is globally consistent | inspect all content before `Historical release procedures` | contradictory `hands-free` release statement at lines 359-366 | ✗ FAIL |

### Probe Execution

SKIPPED — no `probe-*.sh` is declared for Phase 164. The focused production scripts and tests are the documented execution seams.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| TRTH-01 | 164-02, 03, 06, 07, 14, 15 | Guidance agrees with protected workflow, published package state, and supported commands. | ✗ BLOCKED | Package truth passes, but current maintainer release authority contradicts itself. |
| TRTH-02 | 164-01, 04, 06-09, 11, 13-15 | Every changed/generated artifact and ignore rule is classified; durable proof remains discoverable. | ✓ SATISFIED | Authoritative ledger and exact-set contracts pass. |
| TRTH-03 | 164-05-07, 09-15 | Reproducible exact-main closeout with clean Git, protected CI, explained schedules, and complete dispositions. | ✓ SATISFIED | Capability is wired and behaviorally tested, including SHA-bound terminal history; the external terminal capture remains the documented post-completion gate. |

All requirement IDs declared by all fifteen PLAN frontmatters are exactly TRTH-01, TRTH-02, or TRTH-03 and are present in `.planning/REQUIREMENTS.md`. No orphaned Phase 164 requirement exists.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | Behavioral/value | PASS |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | Process/behavioral | PASS |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | Process/behavioral | PASS |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | Value/contract | INSUFFICIENT: only the opening section is checked for obsolete authority |
| `docs_contract_test.exs` | TRTH-01 | yes | 1 unrelated Phase 38 test | No | Value/contract | PASS with existing unrelated skip |

No disabled test is the sole proof for a Phase 164 requirement, and no circular expected-value generator was found. The maintainer contract's assertion scope is insufficient for the phase-wide single-runbook claim.

### Anti-Patterns and Advisory Review Findings

| Finding | Independent Verdict | Severity | Evidence |
| --- | --- | --- | --- |
| CR-01 contradictory current release authority | CONFIRMED | 🛑 BLOCKER | `MAINTAINING.md:359-366` contradicts lines 5-48; the test only refutes obsolete language in its extracted opening section. |
| WR-01 standalone validator invalid invocations succeed | CONFIRMED | ⚠️ WARNING | No-argument and `--ledgr bogus` subprocesses both exited 0 with no output because the CLI body is conditional on seeing literal `--repo` or `--ledger`. Closeout itself passes both exact flags, so its production link remains fail-closed. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the phase-owned implementation files.

### Decision Coverage

All 12 trackable CONTEXT decisions are honored by shipped artifacts according to the non-blocking decision-coverage gate.

### Human Verification Required

N/A — infrastructure/documentation foundation phase with no user-facing UI. All goal checks are programmatically inspectable; the flagged prohibitions remain non-authoritative LLM judgments recorded in frontmatter.

### Gaps Summary

The four prior implementation gaps are closed with executable regression evidence. Phase 164 still cannot pass because the main maintainer document presents two incompatible current release-authority models, and its focused test is scoped so narrowly that the contradiction passes. This directly blocks roadmap criterion 1 and TRTH-01. The standalone validator's fail-open invalid-argument boundary is also confirmed as a warning, but the closeout path invokes it with exact required flags and remains wired fail-closed.

No later milestone phase exists to defer the documentation gap. After correcting the prose and broadening the contract, rerun verification against the resulting implementation commit and update `verified_implementation_sha`. The separate terminal `/finalize-phase 164` capture remains intentionally downstream of a passing verifier plus protected completion metadata.

---

_Verified: 2026-09-09T21:23:26Z_
_Verifier: the agent (gsd-verifier)_
