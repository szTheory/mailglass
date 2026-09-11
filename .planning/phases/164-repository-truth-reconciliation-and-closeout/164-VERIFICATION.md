---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-11T01:52:47Z
verified_implementation_sha: 44ebadd4a444e4e841b2c876f383f1557e2d5cd4
status: gaps_found
next_action: "Fix the installed-boundary, full-suite isolation, and validator error-handling gaps; then re-run ordinary Phase 164 verification. Do not update completion metadata or run terminal finalization yet."
next_command: "$gsd-plan-phase 164 --gaps"
score: 12/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/13
  gaps_closed:
    - "The generic verify.ci_lane_contract alias is hermetic and passed 380 repository tests with five controlled-host tests excluded."
    - "The installed loader pins canonical repository/origin, validates absolute tools, sanitizes child execution, and enforces installation-OID ancestry."
    - "The terminal history range is exactly 01 through 28 and approved installed bytes match tracked source."
  gaps_remaining:
    - "The controlled-host alias does not verify the real installed executable or approval tuple and currently fails all five selected tests."
    - "The controlled-host tag is still collected by unfiltered protected/full-suite commands."
    - "The standalone ledger validator crashes on an existing but incomplete authority directory."
    - "Terminal no-later-write evidence remains intentionally pending."
  regressions:
    - "mix verify.phase_164.installed_boundary fails 5/5 because fixture expectations conflict with live canonical-checkout behavior."
gaps:
  - truth: "TRTH-03: The controlled-host boundary proves the actual installed finalizer and approved installation tuple."
    status: failed
    reason: "The selected block copies tracked loader source into disposable fixtures and never reads the real installed executable or Plan 164-27 approval record; the fresh alias run failed all five tests."
    artifacts:
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "production_installed_fixture!/2 and invoke_production_loader/3 exercise fixture.installed, not the real installed command or approval tuple."
      - path: "mix.exs"
        issue: "verify.phase_164.installed_boundary selects only this ineffective/failing fixture-backed block."
    missing:
      - "Add fail-closed real path/type/mode, exact approval schema, digest, OID ancestry, and installed --self-check assertions."
      - "Keep disposable source-loader attacks in repository-only coverage and make the controlled-host alias pass non-vacuously."
  - truth: "TRTH-03: Host-specific installed-boundary tests cannot enter protected or repository-only full-suite lanes."
    status: failed
    reason: "Only verify.ci_lane_contract excludes the tag. test/test_helper.exs has no default exclusion, while protected CI and ci.full invoke unfiltered mix test; selected tests hard-code a Jon-specific Node path."
    artifacts:
      - path: "test/test_helper.exs"
        issue: "No default phase_164_installed_production_boundary exclusion."
      - path: ".github/workflows/ci.yml"
        issue: "The protected deterministic-core lane invokes an unfiltered full mix test command."
      - path: "mix.exs"
        issue: "ci.full invokes an unfiltered full suite."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "invoke_production_loader/3 hard-codes /Users/jon/.asdf/installs/nodejs/24.19.0/bin/node."
    missing:
      - "Default-exclude the tag with explicit controlled-host inclusion, or exclude it from every repository/protected full-suite entry point."
      - "Add a contract that expands all full-suite aliases/jobs and proves host-only collection is impossible."
  - truth: "TRTH-02: The public repository-truth validator rejects incomplete authority roots through its controlled diagnostic contract."
    status: failed
    reason: "An existing empty --authority-root reaches File.stream!/1 and raises an uncaught File.Error rather than returning a tagged diagnostic."
    artifacts:
      - path: "scripts/validate_repository_truth.exs"
        issue: "ignore_subjects/1 uses File.stream!/1 after checking only that authority_root is a directory."
    missing:
      - "Use non-raising reads and thread a stable missing-authority-subject error through audit_subjects/2 and main/1."
      - "Add an empty-authority-root CLI regression requiring exit 1 and a bounded diagnostic without a stack trace."
prohibition_flags:
  - statement: "D-09/D-10/D-11: MUST NOT treat controlled-host code tests as terminal protected-main evidence."
    verdict: "violated at the controlled-host proof seam"
  - statement: "T-164-109: terminal evidence must have no later tracked write."
    verdict: "unverified-prohibition — human review recommended; lifecycle evidence is intentionally pending and finalization was not run"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-11T01:52:47Z
**Implementation SHA evaluated:** `44ebadd4a444e4e841b2c876f383f1557e2d5cd4`
**Status:** gaps_found
**Re-verification:** Yes — after Plans 164-25 through 164-28.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees with protected workflow facts. | ✓ VERIFIED | Focused current-guidance contracts passed. |
| 2 | Historical procedures are explicitly bounded, leaving one current runbook. | ✓ VERIFIED | Docs contracts passed; the sole historical skip is registered and not sole proof. |
| 3 | Current package guidance agrees with current manifests. | ✓ VERIFIED | README/package contract assertions passed. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | Canonical ledger validator passed and the root sweep remains absent. |
| 5 | Durable release, publish, scheduled-control, planning, and installation proof remains classified and discoverable. | ✓ VERIFIED | The 122-line ledger validates against tracked state. |
| 6 | Tracked dispositions require one byte-exact stage-0 index identity. | ✓ VERIFIED | Repository-truth regressions passed. |
| 7 | All six ignore inventories have exact-one narrow classifications. | ✓ VERIFIED | Production validator returned `repository truth ledger: valid`. |
| 8 | Closeout composes Git, hygiene, preservation, ledger, CI, and scheduled evidence fail-closed. | ✓ VERIFIED | Repository-only closeout regressions are substantive and wired. |
| 9 | Quiet requires canonical path, exact main, ignored output, and post-write cleanliness. | ✓ VERIFIED | Fixture-backed canonical/fail-closed tests pass in repository scope. |
| 10 | Scheduled freshness and provenance remain registry-specific and fail closed. | ✓ VERIFIED | Scheduled evidence tests passed. |
| 11 | Loader pins canonical repository/tool authority, installation ancestry, and exact 01-28 history. | ✓ VERIFIED | Source inspection confirms each gate and shared range. |
| 12 | Installed bytes match approved tracked loader source. | ✓ VERIFIED | Files are regular modes 0500/0400; both digests equal `0dbcc034...d8676e`; installation OID is an ancestor of HEAD. |
| 13 | Finalization has valid controlled-host proof and can proceed to truthful terminal evidence. | ✗ FAILED | Controlled-host alias fails 5/5, does not validate the actual installation tuple, leaks into full suites, and terminal evidence remains pending. |

**Score:** 12/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` and package READMEs | Current operational/package truth | ✓ VERIFIED | Substantive and contract-checked. |
| `164-TRUTH-DISPOSITION.tsv` and validator | Exact-one artifact/ignore classification | ⚠ PARTIAL | Canonical input passes; incomplete authority root crashes. |
| `scripts/mailglass_finalize_phase_loader.mjs` | Canonical immutable loader authority | ✓ VERIFIED | Repository, tools, ancestry, and 01-28 history are wired. |
| Installed command and Plan 27 approval | Installed authority tuple | ✓ PRESENT | Bytes/modes/provenance agree; named controlled-host tests do not read this tuple. |
| `test/scripts/phase_164_closeout_test.exs` | Repository and installed-boundary proof | ✗ FAILED | Installed block is fixture-backed, hard-codes local Node, enters unfiltered suites, and fails 5/5. |
| `164-VALIDATION.md`, `164-SECURITY.md`, `164-FINALIZATION.md` | Truthful proof/lifecycle records | ⚠ PARTIAL | Terminal is correctly pending, but installed-boundary closure is overstated. |
| Current terminal ignored report | Final operational evidence | ⏳ PENDING | Existing report is for `84454ae6...`; evaluated HEAD is `44ebadd4...`. |

### Key Link Verification

| From | To | Status | Details |
| --- | --- | --- | --- |
| Maintainer/package prose | workflows/manifests | ✓ WIRED | Focused contracts passed. |
| Ledger | Git index, ignores, proof | ⚠ PARTIAL | Canonical flow works; malformed authority handling fails. |
| Required CI | repository-only tests | ✓ WIRED | 380 passed, 5 controlled-host tests excluded. |
| Controlled-host alias | real installed tuple | ✗ NOT WIRED | Tests execute `fixture.installed`; alias failed 5/5. |
| Protected/full-suite entries | host-tag exclusion | ✗ NOT WIRED | `test_helper`, protected `mix test`, and `ci.full` have no exclusion. |
| Ordinary verification | terminal finalizer | ⏳ PENDING | Correctly not executed; blockers must close first. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Status |
| --- | --- | --- | --- |
| Ledger | audited subjects/dispositions | live index, six ignores, tracked proof | ⚠ PARTIAL |
| Installed loader | repository/tool authority | loader-owned constants/absolute identities | ✓ FLOWING |
| Controlled-host proof | installed bytes/approval | disposable `fixture.installed` | ✗ DISCONNECTED |
| Terminal report | completed exact-main evidence | stale prior captures only | ⏳ PENDING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Repository-only lane | `mix verify.ci_lane_contract` pinned to project Elixir/Erlang | 380 tests, 0 failures, 5 excluded | ✓ PASS |
| Controlled-host boundary | `mix verify.phase_164.installed_boundary` | 5 tests, 5 failures, 44 excluded | ✗ FAIL |
| Docs/ledger/scheduled contracts | focused four-file `mix test` | 86 tests, 0 failures, 1 registered historical skip | ✓ PASS |
| Canonical ledger | production validator | `repository truth ledger: valid` | ✓ PASS |
| Incomplete authority root | validator with existing empty temporary root | exit 1 plus uncaught `File.Error` stack trace | ✗ FAIL |
| Loader/shell syntax and diff | `node --check`; `bash -n`; `git diff --check` | exit 0 | ✓ PASS |

### Probe Execution

SKIPPED — no `probe-*.sh` is declared. Terminal finalization was deliberately not run.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| TRTH-01 | 02, 03, 06, 07, 14-16, 22, 24, 28 | ✓ SATISFIED | Current/historical/package contracts pass. |
| TRTH-02 | 01, 04, 06-09, 11, 13-15, 17, 18, 20, 22, 24, 28 | ⚠ PARTIAL | Canonical ledger passes; public malformed-authority boundary crashes. |
| TRTH-03 | 05-07, 09-15, 17, 19-28 | ✗ BLOCKED | Controlled-host proof is disconnected/failing and leaks into protected full suites. |

All 28 PLAN frontmatters declare only `TRTH-01`, `TRTH-02`, and `TRTH-03`; each maps to `REQUIREMENTS.md`. No Phase 164 requirement is orphaned and no later milestone phase can absorb these gaps. Current requirement checkboxes are completion metadata and remain untouched pending a passing verification.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Verdict |
| --- | --- | --- | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | PASS, missing incomplete-authority CLI case |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | BLOCKER — wrong source, full-suite leak, 5/5 failure |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | PASS |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | PASS |
| `docs_contract_test.exs` | TRTH-01/02/03 | yes | 1 historical | No | PASS with registered historical skip |
| `ci_parity_drift_test.exs` | TRTH-03 | yes | 0 | No | INSUFFICIENT — does not cover all unfiltered suites |

No requirement relies solely on a disabled test and no circular expected-value generator was found.

### Review Findings Reconciliation

| Finding | Verdict | Evidence | Impact |
| --- | --- | --- | --- |
| CR-01: gate never verifies installed executable/approval tuple | CONFIRMED | Selected block has no real path/approval read; helper uses `fixture.installed`; alias failed 5/5 | 🛑 BLOCKER |
| CR-02: host-only tests execute in protected full suites | CONFIRMED | No default exclusion; protected CI/`ci.full` use unfiltered full suites; helper hard-codes Jon's Node | 🛑 BLOCKER |
| WR-01: incomplete authority directory crashes validator | CONFIRMED | Empty root produced uncaught `File.Error` from `File.stream!/1` | ⚠ WARNING / TRTH-02 partial |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/scripts/phase_164_closeout_test.exs` | 1270-1366 | Fixture proof labeled installed; hard-coded local Node | 🛑 Blocker | False/non-portable controlled-host proof |
| `test/test_helper.exs` | 1-69 | No default host-tag exclusion | 🛑 Blocker | Full suites collect host tests |
| `scripts/validate_repository_truth.exs` | 419-429, 791-800 | Raising stream at malformed-input boundary | ⚠ Warning | Stack trace replaces diagnostic |
| `164-VALIDATION.md` / `164-SECURITY.md` | current closure sections | Claims conflict with fresh evidence | ⚠ Warning | Records are not yet reliable |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in Plans 164-25 through 164-28 files.

### Decision Coverage

All 12/12 trackable context decisions are honored according to the non-blocking fuzzy gate. This does not override concrete failures.

### Human Verification Required

N/A — infrastructure/operational tooling. Failures are deterministic. Judgment-tier prohibition review remains recommended but cannot substitute for fixes.

### Terminal Lifecycle Gate

T-164-109 remains intentionally open. `HEAD` is `44ebadd4...`, `origin/main` is `d903b040...`, and ignored reports describe older SHAs (`84454ae6...` and `382ebb0a...`). Terminal finalization was not run. Required order remains: passing verifier → authorized completion metadata only → protected-main integration → exact attempt-1 push CI/natural schedules → installed terminal capture → no later tracked write. This report does not mark the phase complete.

### Gaps Summary

Plans 164-25 through 164-27 improved repository-only CI and loader authority, but all submitted review findings remain observable. The repository lane is green; the installed-boundary lane is disconnected and fails, its tag leaks into protected full suites, and the standalone validator raises on an incomplete authority root. Terminal capture remains pending behind a future passing verifier and protected lifecycle.

---

_Verified: 2026-09-11T01:52:47Z_
_Verifier: the agent (gsd-verifier)_
