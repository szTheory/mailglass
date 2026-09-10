---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-09-10T21:57:10Z
verified_implementation_sha: c6dc54fe783d88b25853a5f91f424f8ea523691e
status: gaps_found
next_action: "Gaps found. Plan the fixes, then re-run execute-phase before shipping."
next_command: "$gsd-plan-phase 164 --gaps"
score: 12/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/13
  gaps_closed:
    - "The installed loader now captures one full commit OID and uses it for tree/blob operations."
    - "The Phase 164 numbered history is anchored to the exact 01-24 PLAN/SUMMARY set."
    - "The retired project-local extension is no longer evaluated on the supported finalization path."
  gaps_remaining:
    - "Required CI unconditionally depends on maintainer-local installed files."
    - "The installed loader accepts and executes authority bytes from any repository selected by the caller's working directory."
    - "The installed trust boundary relies on ambient PATH for Node, Git, Bash, and downstream tools."
    - "Current Phase 164 metadata is not integrated to origin/main and no terminal report exists for the current SHA."
  regressions:
    - "The Plan 164-24 installed-production test positively codifies execution from an arbitrary temporary repository."
gaps:
  - truth: "TRTH-03: The supported finalization path is runnable by required protected CI without maintainer-local state."
    status: failed
    reason: "mix verify.ci_lane_contract selects all test/scripts tests, including five production-boundary tests that immediately require two /Users/jon-local files unavailable on GitHub runners and other contributors."
    artifacts:
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "The required CI suite contains unconditional absolute-host assertions at the installed-production boundary."
      - path: "mix.exs"
        issue: "verify.ci_lane_contract unconditionally selects the entire test/scripts directory."
    missing:
      - "Keep required CI hermetic by moving host-install assertions to a separately invoked controlled-host suite or explicit opt-in contract."
      - "Add a CI contract proving the generic required lane does not require absolute host files."
  - truth: "D-09/D-10/D-11/TRTH-03: The installed executable accepts only the canonical Mailglass repository authority."
    status: failed
    reason: "finalize() discovers the repository only from process.cwd() and does not pin the canonical path or szTheory/mailglass origin before authenticating and executing repository-supplied finalizer bytes."
    artifacts:
      - path: "scripts/mailglass_finalize_phase_loader.mjs"
        issue: "Repository discovery at lines 299-305 has no loader-owned canonical-path or origin-identity check."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "The passing installed-production test expects an arbitrary temporary repository's finalizer marker to execute."
    missing:
      - "Pin and verify the canonical real path and expected remote identity in loader-owned code before dependency enumeration."
      - "Replace the foreign-repository acceptance test with a rejection test."
  - truth: "D-09/D-10/D-11/TRTH-03: Finalization trust decisions cannot be replaced through caller-controlled executable lookup."
    status: failed
    reason: "The installed script uses /usr/bin/env node and bare git/bash names, while the authenticated Bash chain inherits PATH for all remaining tools; a forged PATH can replace the trust oracle itself."
    artifacts:
      - path: "scripts/mailglass_finalize_phase_loader.mjs"
        issue: "Shebang and spawnSync calls resolve Node, Git, and Bash through ambient PATH."
      - path: "scripts/finalize_phase_164.sh"
        issue: "Git, gh, jq, mix, node, and elixir inherit the caller's unsanitized PATH."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "Tests inject cooperative PATH shims but contain no adversarial forged-Git rejection proof."
    missing:
      - "Establish a pinned trusted toolchain using validated absolute executable paths and a sanitized child environment."
      - "Add a fake-Git attack that returns internally consistent forged objects and prove rejection before dispatch."
  - truth: "Roadmap SC3 / TRTH-03: Final closeout evidence describes the actual completed protected-main repository state."
    status: failed
    reason: "HEAD c6dc54fe is not origin/main d903b040, ROADMAP and REQUIREMENTS still mark Phase 164 incomplete/gaps-found, 164-FINALIZATION.md says terminal finalization is pending, and no terminal report was found for the current SHA."
    artifacts:
      - path: ".planning/ROADMAP.md"
        issue: "The post-execution installed terminal command remains unchecked and the completion text is stale."
      - path: ".planning/REQUIREMENTS.md"
        issue: "TRTH-01, TRTH-02, and TRTH-03 remain unchecked and Gaps Found."
      - path: ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md"
        issue: "Explicitly states ordinary verification, protected integration, and terminal finalization remain pending."
    missing:
      - "After code gaps close, integrate all tracked metadata through protected main."
      - "Run the repaired installed terminal command on exact protected main and retain a no-later-write terminal report."
prohibition_flags:
  - statement: "D-09/D-10/D-11: MUST NOT let mutable or caller-selected executable/repository bytes establish finalization authority."
    verdict: "violated — caller cwd selects the repository and ambient PATH selects every trust executable"
  - statement: "All remaining judgment-tier prohibitions from Plans 164-01 through 164-24."
    verdict: "non-authoritative autonomous judgment: no additional violation observed; human review recommended"
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-09-10T21:57:10Z
**Implementation SHA evaluated:** `c6dc54fe783d88b25853a5f91f424f8ea523691e`
**Status:** gaps_found
**Re-verification:** Yes — Plans 164-21 through 164-24 closed the prior immutable-OID, exact-history, and project-extension gaps, but the fresh review's three trust-boundary blockers are confirmed and terminal evidence is still absent.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01 maintainer/release/recovery guidance agrees with protected workflow facts. | ✓ VERIFIED | Current maintainer contract passed; protected exact-candidate, repository-admin, proposal-only, and fail-closed terms are present. |
| 2 | Historical procedures are explicitly bounded, leaving one current runbook. | ✓ VERIFIED | The contract enforces one `Historical release procedures` boundary. |
| 3 | Current package guidance agrees with current manifests. | ✓ VERIFIED | Documentation contract passed against core/admin 2.5 and inbound 2.2 guidance. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition. | ✓ VERIFIED | D-08 digest/remove row remains and the root output is absent. |
| 5 | Durable release, publish, scheduled-control, planning, and installation proof remains classified and discoverable. | ✓ VERIFIED | The 118-line ledger passes the production validator. |
| 6 | Tracked dispositions require one byte-exact stage-0 index identity. | ✓ VERIFIED | Production parser uses literal `ls-files --stage -z --error-unmatch`; focused ledger tests passed. |
| 7 | All six ignore inventories have exact-one narrow classifications. | ✓ VERIFIED | 72 non-comment ignore rules are covered by the passing canonical validator. |
| 8 | Closeout composes Git, hygiene, preservation, ledger, CI, and scheduled evidence fail-closed. | ✓ VERIFIED | Substantive scripts and existing process regressions remain wired. |
| 9 | Quiet requires canonical path, exact main, ignored output, and post-write cleanliness. | ✓ VERIFIED | Closeout-level hostile path and late-dirt behavior remains tested. |
| 10 | Scheduled freshness and provenance remain registry-specific and fail closed. | ✓ VERIFIED | Scheduled and finalizer checks preserve exact attempt/event/SHA/age constraints. |
| 11 | The installed loader uses one captured OID and exact 01-24 history, and excludes the retired extension. | ✓ VERIFIED | Source inspection plus 5/5 installed-boundary tests prove these narrower repairs. |
| 12 | Installed bytes and approval record match the committed loader source. | ✓ VERIFIED | External files are regular modes 0500/0400 and installed/source SHA-256 both equal `ca760f78...b7d9`. |
| 13 | Finalization is a hermetic, canonical-repository, trusted-toolchain path that can produce terminal protected-main evidence. | ✗ FAILED | Required CI is host-coupled; caller cwd and PATH control authority; HEAD is not origin/main; terminal capture is pending. |

**Score:** 12/13 truths verified (0 present, behavior-unverified)

### Plan Must-Have Coverage

Every one of the 83 PLAN truth entries and 70 artifact declarations was checked. Repeated truths were merged into the observable contracts above; the table records each plan's resulting disposition.

| Plans | Status | Notes |
| --- | --- | --- |
| 164-01 through 164-10 | ✓ VERIFIED | Documentation, package, ledger, ignore, closeout, and freshness contracts remain substantive and wired. |
| 164-11 | ✓ SUPERSEDED/VERIFIED | Its project-local extension artifacts were intentionally retired by Plan 22; retained finalizer behavior remains present. |
| 164-12 through 164-16 | ✓ VERIFIED | Pre-verification, adversarial ledger/closeout, history, timestamp, and documentation contracts are present; captures are correctly non-terminal. |
| 164-17 through 164-20 | ✓ SUPERSEDED/VERIFIED | Stage-0 and transitive-authentication behavior remains; missing extension files are intentional Plan-22 retirement, not stubs. |
| 164-21 | ✗ PARTIAL | Captured OID and exact 01-24 set exist, but the installed loader does not establish canonical repository or trusted executable authority. |
| 164-22 | ✓ VERIFIED | Retired extension is absent, installed command is documented, and replacement ledger evidence exists. |
| 164-23 | ⚠ PARTIAL | Installation tuple and byte identity exist; self-check does not enforce installation-OID ancestry, although the recorded OID is currently an ancestor. |
| 164-24 | ✗ PARTIAL | Five named tests pass, but the accepted-path test positively demonstrates foreign-repository execution and makes required CI host-dependent. |

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md`, three READMEs, documentation tests | Current operational/package truth | ✓ VERIFIED | Focused 70-test run passed with one historical skip. |
| `164-TRUTH-DISPOSITION.tsv`, validator, repository-truth test | Complete exact-one classification | ✓ VERIFIED | Validator prints `repository truth ledger: valid`; export checker false positives were manually resolved at `parse/1`, `audit_subjects/2`, and `validate/3`. |
| Closeout/finalizer/scheduled scripts and tests | Fail-closed evidence composition | ✓ VERIFIED | Substantive and wired; CI-monitor Node tests passed 5/5. |
| `scripts/mailglass_finalize_phase_loader.mjs` | Installed pre-evaluation trust authority | ✗ FAILED | Byte-identical installation exists, but repository and executable lookup remain caller-controlled. |
| Installed executable and approval record | External immutable installation state | ⚠ PARTIAL | Exist with correct modes/digest; external-state artifact false negatives from `verify.artifacts` were manually resolved. Provenance ancestry is not enforced by self-check. |
| `164-VALIDATION.md` / `164-FINALIZATION.md` | Truthful proof map and lifecycle state | ⚠ PARTIAL | Correctly says terminal proof is pending, but claims automated installed authority is closed despite confirmed trust defects. |
| Terminal ignored report for current protected-main SHA | Final operational evidence | ✗ MISSING | Existing reports are pre-verification or stale; current HEAD is not origin/main. |

### Key Link Verification

| From | To | Status | Details |
| --- | --- | --- | --- |
| Maintainer/package prose | workflows and manifests | ✓ WIRED | Focused contracts pass. |
| Ledger validator | Git index, six ignores, durable proof, external installation subjects | ✓ WIRED | Canonical validator passes. |
| Installed loader | one captured OID and exact Phase 164 history | ✓ WIRED | OID-addressed tree/blob reads and exact 01-24 set are present. |
| Installed loader | canonical `/Users/jon/projects/mailglass` / `szTheory/mailglass` identity | ✗ NOT WIRED | `process.cwd()` alone selects the authority repository. |
| Installed loader | trusted Node/Git/Bash toolchain | ✗ NOT WIRED | `/usr/bin/env` and bare executable names resolve from ambient PATH. |
| Required CI lane | repository-only tests | ✗ NOT WIRED | Generic `test/scripts/` selection reaches host-only installed-production tests. |
| Current tracked metadata | protected origin/main and terminal report | ✗ NOT WIRED | Local HEAD differs from origin/main and terminal gate remains unchecked. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Status |
| --- | --- | --- | --- |
| Ledger | audited subjects and dispositions | Git index, ignore files, plan-owned proof, approved installation tuple | ✓ FLOWING |
| Closeout report | Git/CI/scheduled/component statuses | live observations and authenticated private dependencies | ✓ FLOWING at closeout layer |
| Loader authority repository | repository root and authority objects | caller cwd plus ambient `git` | ✗ UNTRUSTED SOURCE |
| Child executable identity | Git/Bash and downstream tools | caller PATH | ✗ UNTRUSTED SOURCE |
| Terminal report | completed exact-main evidence | none for current SHA | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command / result | Status |
| --- | --- | --- |
| Canonical production ledger | pinned Elixir validator: `repository truth ledger: valid` | ✓ PASS |
| Installed boundary group | pinned ExUnit tag: 5 tests, 0 failures | ✓ PASS, but insufficient/wrong oracle |
| Current documentation and ledger contracts | pinned focused run: 70 tests, 0 failures, 1 historical skip | ✓ PASS |
| CI monitor contract | `node --test test_js/ci-monitor.test.cjs`: 5 passed | ✓ PASS |
| Canonical protected-main identity | `HEAD=c6dc54fe...`, `origin/main=d903b040...` | ✗ FAIL |
| Foreign-repository rejection | Test at lines 1089-1108 expects arbitrary fixture finalizer execution | ✗ FAIL |
| Trusted executable lookup | loader uses `/usr/bin/env node`, `spawnSync("git")`, and `spawnSync("bash")` | ✗ FAIL |

### Probe Execution

SKIPPED — no `probe-*.sh` is declared. The terminal installed command was not run because its trust boundary is unsafe and protected-main prerequisites are unmet.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| TRTH-01 | 02, 03, 06, 07, 14-16, 22, 24 | Maintainer/package guidance matches supported state | ✓ SATISFIED | Documentation tests pass. |
| TRTH-02 | 01, 04, 06-09, 11, 13-15, 17-20, 22, 24 | Exact evidence-backed artifact/ignore classification | ✓ SATISFIED | Canonical validator and focused tests pass. |
| TRTH-03 | 05-07, 09-15, 17, 19-24 | Reproducible exact-main quiet closeout evidence | ✗ BLOCKED | Host-coupled CI, foreign-repository authority, PATH substitution, and absent terminal evidence. |

All requirement IDs declared across all 24 PLAN frontmatters are one or more of TRTH-01, TRTH-02, and TRTH-03, and each maps to the matching REQUIREMENTS.md entry. No Phase 164 requirement is orphaned. There is no later milestone phase to which a gap can be deferred.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `phase_164_repository_truth_test.exs` | TRTH-02 | yes | 0 | No | Behavioral | PASS |
| `phase_164_closeout_test.exs` | TRTH-03 | yes | 0 | No | Behavioral | BLOCKER — five host-only tests enter generic CI and accepted fixture asserts insecure foreign-repository execution. |
| `scheduled_control_evidence_test.exs` | TRTH-03 | yes | 0 | No | Behavioral | PASS |
| `maintaining_release_gate_contract_test.exs` | TRTH-01 | yes | 0 | No | Value/behavioral | PASS |
| `docs_contract_test.exs` | TRTH-01 | yes | 1 historical | No | Value | PASS with historical skip |
| `ci-monitor.test.cjs` | TRTH-03 | yes | 0 | No | Behavioral | PASS |

No requirement relies solely on a disabled test and no circular expected-value generator was found. The decisive issue is a strong assertion aimed at the wrong security outcome.

### Review, Security, and Validation Reconciliation

| Finding/claim | Verdict | Impact |
| --- | --- | --- |
| REVIEW CR-01: required CI depends on maintainer-local installation | CONFIRMED | 🛑 BLOCKER |
| REVIEW CR-02: installed command executes from any current repository | CONFIRMED | 🛑 BLOCKER |
| REVIEW CR-03: ambient PATH can forge trust decisions | CONFIRMED | 🛑 BLOCKER |
| REVIEW WR-01: self-check does not prove installation OID ancestry | CONFIRMED | ⚠ WARNING; current recorded OID is an ancestor, but code does not enforce it |
| SECURITY: all high threats closed / secured | CONTRADICTED | Canonical-repository and executable-integrity boundaries remain open. |
| VALIDATION: installed boundary complete through Plan 24 | CONTRADICTED | 5/5 tests pass but omit PATH forgery and affirm foreign-repository execution. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/scripts/phase_164_closeout_test.exs` | 8-9, 1086-1095 | absolute maintainer-local prerequisites in generic CI directory | 🛑 Blocker | protected CI cannot run hermetically |
| `test/scripts/phase_164_closeout_test.exs` | 1089-1108 | foreign repository execution asserted as success | 🛑 Blocker | insecure behavior is regression-locked |
| `scripts/mailglass_finalize_phase_loader.mjs` | 1, 83-94, 299-320 | caller PATH/cwd establish trust | 🛑 Blocker | repository and executable authority are forgeable |
| `scripts/mailglass_finalize_phase_loader.mjs` | 274-283 | installation OID not ancestry-checked | ⚠ Warning | provenance can name an unrelated local commit |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in phase-owned implementation/test files.

### Decision Coverage

All 12/12 trackable `164-CONTEXT.md` decisions are honored by shipped artifacts according to the non-blocking decision-coverage gate. This fuzzy coverage result does not override concrete trust-boundary failures.

### Human Verification Required

N/A — infrastructure/operational tooling phase. The observed failures are concrete code and lifecycle defects; manual UAT cannot close them.

### Gaps Summary

Plans 164-21 through 164-24 successfully repair the previous captured-OID, exact-history, and mutable-extension defects. They do not establish a safe operational trust root: required CI depends on one machine, arbitrary repositories can supply the authenticated payload, and ambient PATH can replace every trust decision. The positive installed-boundary test codifies rather than rejects the foreign-repository behavior. Final exact-main evidence is also absent and cannot be captured safely until these defects are repaired. Phase 164 therefore remains blocked with TRTH-03 unsatisfied.

---

_Verified: 2026-09-10T21:57:10Z_
_Verifier: the agent (gsd-verifier)_
