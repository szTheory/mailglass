---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-10T01:59:34Z
verified_implementation_sha: bd61c3e7ceb22736f663b1f7987d9c24ca28cf75
status: gaps_found
score: 11/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/13
  gaps_closed:
    - "Plan 164-17 rejects a regular working-tree file absent from the Git index and makes direct validator misuse fail closed."
    - "Plan 164-17 authenticates and privately materializes the Phase 164 downstream finalizer instead of directly executing its mutable checkout pathname."
  gaps_remaining:
    - "TRTH-02 validation accepts an unmerged path with only stage-1/2/3 index entries as tracked proof."
    - "TRTH-03 private finalizer execution reaches mutable checkout helpers hidden by assume-unchanged."
    - "TRTH-03 dispatcher authentication resolves a symlink before authenticating the lexical phase shim."
    - "The generic finalize-phase dispatcher accepts other phases but always runs the Phase 164 downstream finalizer."
  regressions:
    - "No prior roadmap truth regressed; the current review exposed deeper, previously uncovered trust-boundary defects."
gaps:
  - truth: "TRTH-02 / D-05 / D-06 / D-12: Every tracked disposition is backed by one stage-0 Git-index identity."
    status: failed
    reason: "git ls-files without --stage collapses unmerged stage-1/2/3 entries to pathnames; the helper accepts the normalized subject although no stage-0 entry exists."
    artifacts:
      - path: "scripts/validate_repository_truth.exs"
        issue: "tracked_subject_in_index/2 checks pathname output only, not index stage."
      - path: "test/scripts/phase_164_repository_truth_test.exs"
        issue: "No unmerged multi-stage index regression exists."
    missing:
      - "Require exactly one NUL-delimited stage-0 entry for the exact literal subject."
      - "Add an unmerged-index regression against production validation."
  - truth: "TRTH-03 / D-09 / D-10 / D-11: Finalization authenticates the complete executable/data chain and exact lexical shim before phase code runs."
    status: failed
    reason: "Only the downstream entry is materialized from HEAD. It invokes mutable checkout helpers, and realpath erases lexical shim identity before authentication."
    artifacts:
      - path: ".gsd/extensions/finalize-phase/index.ts"
        issue: "Authenticates two resolved targets, loses lexical shim identity, and materializes no dependency chain."
      - path: "scripts/finalize_phase_164.sh"
        issue: "Invokes $repo/scripts/closeout_repository_truth.sh from the mutable checkout."
      - path: "scripts/closeout_repository_truth.sh"
        issue: "Launches four additional tools from mutable checkout paths."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "No shim-symlink or assume-unchanged transitive-helper regression exists."
    missing:
      - "Authenticate the lexical regular-file shim and materialize/bind the full executable and data dependency chain to HEAD."
      - "Add symlink-shim and assume-unchanged transitive-helper behavioral regressions."
  - truth: "The project-local finalize-phase command dispatches the finalizer belonging to the accepted phase."
    status: failed
    reason: "The handler accepts every positive integer phase but downstreamCandidate is always scripts/finalize_phase_164.sh."
    artifacts:
      - path: ".gsd/extensions/finalize-phase/index.ts"
        issue: "Generic phase parsing is wired to a Phase-164-only downstream constant."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "No alternate-phase behavioral mapping case exists."
    missing:
      - "Reject non-164 phases or derive and authenticate a trusted phase-specific mapping."
      - "Add an alternate-phase regression."
prohibition_flags:
  - statement: "D-05/D-06/D-12: MUST NOT represent invalid index state as tracked proof."
    verdict: "violated — a UU conflict with only stages 1/2/3 returned :ok"
  - statement: "D-09/D-10/D-11: MUST NOT execute finalization dependencies absent from or different from authenticated HEAD."
    verdict: "violated — checkout helpers execute and assume-unchanged hides their mutation"
  - statement: "D-09/D-10/D-11: MUST NOT substitute another lexical phase identity or finalizer."
    verdict: "violated — symlinks resolve before authentication and all phases map to finalize_phase_164.sh"
  - statement: "All remaining judgment-tier prohibitions from Plans 164-01 through 164-17."
    verdict: "non-authoritative LLM judgment: no additional violation observed; explicit human review recommended"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-10T01:59:34Z
**Implementation SHA evaluated:** `bd61c3e7ceb22736f663b1f7987d9c24ca28cf75`
**Status:** gaps_found
**Re-verification:** Yes — Plan 164-17 closed the prior reproductions, but all four critical findings in the newer `164-REVIEW.md` are substantiated.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees throughout with protected workflow facts. | ✓ VERIFIED | `MAINTAINING.md` exposes one protected exact-candidate/repository-admin model; four focused tests pass. |
| 2 | Historical procedures are explicitly bounded, leaving one current runbook. | ✓ VERIFIED | One exact historical boundary exists; legacy hands-free language is below it. |
| 3 | Current package guidance matches core/admin 2.5 and inbound 2.2 manifests. | ✓ VERIFIED | Manifest-derived README assertions pass. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | D-08 retains digest `331810b4...04ece7e`, stale/untracked state, and remove; the root artifact is absent. |
| 5 | Durable scheduled/release/publish/planning proof remains tracked and discoverable. | ✓ VERIFIED | Canonical validation passes; the ledger contains 38 tracked retain rows. |
| 6 | Every scoped artifact and non-comment rule has one truthful, complete disposition. | ✗ FAILED | A disposable `UU README.md` with index stages 1/2/3 only returned `:ok` from the production tracked helper. |
| 7 | Retained ignore rules are narrow and producer-owned. | ✓ VERIFIED | Exactly 72 ledger ignore rows match 72 non-comment rules across six ignore files. |
| 8 | One rerunnable command composes Git, hygiene, preservation, ledger, CI, and scheduled authorities. | ✓ VERIFIED | Closeout is substantive, shell-valid, and process-tested. |
| 9 | Quiet requires canonical repo/ledger, ignored output, exact origin/main, and post-write cleanliness. | ✓ VERIFIED | Hostile identity/output and late-dirt regressions pass. |
| 10 | Malformed, future, or stale scheduled timestamps cannot be current. | ✓ VERIFIED | Both boundaries enforce `0 <= age <= max_age_seconds`; tests pass. |
| 11 | Quiet requires the complete exact-one ledger gate. | ✓ VERIFIED | Closeout invokes the canonical shared validator and rejects substitute ledgers. |
| 12 | Evidence selection permits only attempt-one normal push CI and natural same-SHA schedules. | ✓ VERIFIED | Mutation and CI-monitor tests pass. Existing capture remains pre-verification-only and was not refreshed. |
| 13 | Terminal finalization is bound to the exact tracked implementation verified. | ✗ FAILED | Only entry bytes are private; mutable transitive helpers execute, lexical shim identity can be lost, and non-164 phases are misrouted. |

**Score:** 11/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` | One protected current authority | ✓ VERIFIED | Substantive and globally consistent before history. |
| Package READMEs | Manifest-derived compatibility | ✓ VERIFIED | Root/admin/inbound contracts pass. |
| `164-TRUTH-DISPOSITION.tsv` | Exact-one disposition ledger | ⚠ PARTIAL | 111 data rows pass current validation, but tracked-stage enforcement is defective. |
| `scripts/validate_repository_truth.exs` | Shared truth validator | ✗ FAILED | CLI handling is fixed; index proof does not require stage 0. |
| `scripts/closeout_repository_truth.sh` | Fail-closed evidence composition | ⚠ PARTIAL | Substantive, but executed from mutable checkout and launches mutable tools. |
| `scripts/finalize_phase_164.sh` | Hash/history-bound gate | ⚠ PARTIAL | Private entry invokes unauthenticated dependencies. |
| `.gsd/extensions/finalize-phase/index.ts` | Authenticated phase dispatcher | ✗ FAILED | Loses lexical identity, authenticates an incomplete chain, misroutes phases, and print-exits before cleanup. |
| `164-FINALIZATION.md` | Lifecycle contract | ⚠ PARTIAL | Non-circular lifecycle is accurate; authenticated execution claim is not achieved. |
| `164-VALIDATION.md` | Complete verification map | ⚠ PARTIAL | Covers Plans 01-17 but claims no automated gap remains while current attacks are uncovered. |
| Phase focused tests | Production-seam proof | ⚠ PARTIAL | 102 pass; no conflict-stage, transitive assume-unchanged, shim-symlink, alternate-phase, or print-cleanup case. |

### Key Links and Data Flow

| Link | Status | Evidence |
| --- | --- | --- |
| Maintainer prose → protected workflow | ✓ WIRED | Whole-current-region contract passes. |
| Package READMEs → manifests | ✓ WIRED | Values are dynamically derived. |
| Ignore/proof inventory → ledger | ⚠ PARTIAL | Exact inventory; incomplete index-stage identity. |
| Closeout → canonical ledger | ✓ WIRED | Substitute paths rejected. |
| Extension → lexical shim/full execution chain | ✗ NOT WIRED SAFELY | `realpathSync` precedes auth; only one downstream blob is materialized. |
| Private finalizer → component tools | ✗ DISCONNECTED FROM HEAD | Direct checkout paths execute. |
| Accepted phase → downstream | ✗ MISWIRED | Hard-coded Phase 164 target. |

The automated Plan 164-17 key-link query returned 2/2 because text patterns exist. That is presence evidence and is contradicted by the behavior/data-flow trace above.

### Behavioral Spot-Checks

| Behavior | Result | Status |
| --- | --- | --- |
| One complete focused `mix test` run over five linked files | 102 tests, 0 failures, 1 historical skip (101 executed) | ✓ PASS |
| Canonical validator invocation | `repository truth ledger: valid` | ✓ PASS |
| Disposable unmerged-index attack | `UU README.md`, stages 1/2/3 only; production helper returned `:ok` | ✗ FAIL |
| Disposable hidden-mutation premise | porcelain empty and `git diff --quiet` 0 after assume-unchanged mutation; changed payload executed | ✗ FAIL |
| `node --test test_js/ci-monitor.test.cjs` | 5 passed | ✓ PASS |
| Bash syntax, Elixir formatting, `git diff --check` | all exit 0 | ✓ PASS |

### Probe Execution

SKIPPED — no `probe-*.sh` is declared. The terminal `/finalize-phase 164` gate was intentionally not run.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| TRTH-01 | 164-02,03,06,07,14-16 | ✓ SATISFIED | Whole-document maintaining and manifest-derived package contracts pass. `REQUIREMENTS.md` retains the prior unchecked workflow state pending a passing phase verifier. |
| TRTH-02 | 164-01,04,06-09,11,13-15,17 | ✗ BLOCKED | CR-01: multi-stage conflict is falsely accepted as tracked proof. |
| TRTH-03 | 164-05-07,09-15,17 | ✗ BLOCKED | CR-02/03 defeat the trusted entry chain; CR-04 misroutes the advertised generic dispatcher. |

All requirement IDs in all 17 PLAN frontmatters resolve to these three IDs in `REQUIREMENTS.md`. No orphaned Phase 164 requirement and no later milestone phase exists for deferral.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Verdict |
| --- | --- | --- | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | INSUFFICIENT — no unmerged-index case |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | INSUFFICIENT — four dispatcher/finalizer cases absent |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | PASS |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | PASS |
| `docs_contract_test.exs` | TRTH-01 | yes | 1 historical | No | PASS; skip is unrelated |

No disabled test is sole requirement proof and no circular expected-value generator was found.

### Current Code Review Reconciliation

| Finding | Verdict | Severity | Direct Evidence |
| --- | --- | --- | --- |
| CR-01 multi-stage conflicts certified | CONFIRMED + REPRODUCED | 🛑 BLOCKER | Disposable conflict showed only stages 1/2/3 and returned `:ok`. |
| CR-02 mutable transitive helpers | CONFIRMED + PREMISE REPRODUCED | 🛑 BLOCKER | Private entry calls checkout closeout; closeout calls four checkout tools. assume-unchanged hid modified bytes from status/diff. |
| CR-03 symlink authenticates target | CONFIRMED | 🛑 BLOCKER | `realpathSync(finalizerCandidate)` precedes relative Git auth; `statSync` follows symlinks. |
| CR-04 every phase runs Phase 164 | CONFIRMED | 🛑 BLOCKER | Positive-integer parser plus unconditional `scripts/finalize_phase_164.sh`. |
| WR-01 print failure skips cleanup | CONFIRMED | ⚠ WARNING | `process.exit(1)` occurs inside `try` before `finally`; harness never uses `--print`. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found.

### Decision and Prohibition Coverage

The non-blocking decision query reports all 12 `164-CONTEXT.md` decisions honored. It cannot override concrete failures.

All 18 judgment-tier prohibitions were reviewed individually. “Supported” below is a non-authoritative LLM judgment and still requires explicit human resolution; none is silently green.

| Plan | Prohibition (abridged) | Judgment |
| --- | --- | --- |
| 01 | Do not conceal the stale root sweep instead of locked removal. | Supported; D-08 row and root absence are intact. |
| 02 | Do not broaden protected authority or turn unavailable evidence green. | Supported by current docs/control contracts. |
| 04a | Do not delete/broadly ignore durable proof without disposition. | Supported by exact ledger/ignore inventory. |
| 04b | Do not promote user-local or broad durable-proof ignores. | Supported by six-file inventory. |
| 05 | Do not label incomplete/mismatched evidence quiet. | **Violated in the authenticated-chain sense:** hostile hidden helper bytes can influence the verdict. |
| 06 | Do not substitute manual/alternate-SHA/forced evidence. | Supported by selection contracts; terminal capture not run. |
| 08 | Do not conceal/drop proof to pass completeness. | Supported by current inventory, subject to CR-01’s false index-state classification. |
| 09 | Do not manufacture quiet with alternate paths or early cleanliness. | Supported by hostile path/late-dirt tests. |
| 10 | Do not change ages/workflow/provenance to pass. | Supported by registry and mutation tests. |
| 11 | Do not dispatch/rerun/select identity/write tracked state in finalization. | Supported for exposed operations; terminal capture not run. |
| 12 | Do not represent pre-verification as terminal or mutate controls/state. | Supported; artifacts explicitly retain the boundary. |
| 13 | Do not misrepresent incomplete/forged/alternate/self-dirty state as quiet. | **Violated:** unmerged index state can be certified as tracked. |
| 14 | Do not manufacture protected/terminal evidence. | Supported; no evidence refresh was performed here. |
| 15a | Do not accept stale/missing/future verifier/timestamp bindings. | Supported by focused tests. |
| 15b | Do not recursively delete unowned test paths. | Supported by ownership-token tests. |
| 16 | Do not broaden exact-candidate/repository-admin authority. | Supported by whole-document contract. |
| 17a | Do not represent an untracked regular file as tracked proof. | Supported for that literal case; CR-01 exposes a distinct conflicted-index hole. |
| 17b | Do not execute finalizer bytes absent from/different from HEAD. | **Violated for the effective chain:** only the entry blob is authenticated; mutable helpers execute afterward. |

### Human Verification Required

N/A for goal status — this infrastructure/documentation phase has programmatically observable blockers. Human review remains recommended for unresolved judgment-tier prohibitions but cannot override the code failures.

### Gaps Summary

Plan 164-17 closed the previous shallow trust-anchor defects. Deeper variants remain: conflict stages masquerade as tracked proof, and finalization authenticates only its entry instead of its complete executable/data chain. The dispatcher also loses lexical shim identity and advertises generic phase selection while always running Phase 164. Print-mode cleanup is a warning to fix with the dispatcher work.

No gap is deferred. Phase 164 is the final milestone phase. Do not run terminal finalization until these blockers are fixed, re-verified, and tracked completion metadata reaches protected main.

---

_Verified: 2026-09-10T01:59:34Z_
_Verifier: the agent (gsd-verifier)_
