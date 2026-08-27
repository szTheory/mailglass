---
phase: 164-repository-truth-reconciliation-and-closeout
verified: 2026-08-27T17:00:16Z
status: gaps_found
score: 8/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "D-05/D-12/TRTH-02: Every scoped artifact and every non-comment rule in all six ignore files has exactly one complete evidence-backed disposition."
    status: partial
    reason: "The durable ledger exists and its focused test passes, but the closeout command accepts arbitrary incomplete/semantically invalid ledgers rather than the authoritative ledger and complete validator."
    artifacts:
      - path: "scripts/closeout_repository_truth.sh"
        issue: "Lines 71-72 validate only header, field count, subject, disposition, and duplicate subject; they do not bind the ledger path or enforce mandatory fields, currentness, stale disposition, or audited-subject coverage."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "Its passing fixture supplies a one-row D-01 ledger, proving the closeout gate accepts incomplete coverage."
    missing:
      - "Bind --ledger to the authoritative Phase 164 ledger under the selected canonical repository."
      - "Reuse or extract the full ledger parser and audited-subject inventory in the closeout gate, with negative fixtures for malformed currentness, stale-retain, and missing subjects."
  - truth: "D-09/D-10/TRTH-03: One rerunnable final-evidence command proves a clean canonical /Users/jon/projects/mailglass on main with HEAD equal to origin/main."
    status: failed
    reason: "The CLI documents a canonical-checkout requirement but never compares the resolved --repo path with /Users/jon/projects/mailglass; it can report pass for any clean main checkout. It also checks porcelain before writing caller-controlled output/components, so a pass can leave a non-ignored output path dirty."
    artifacts:
      - path: "scripts/closeout_repository_truth.sh"
        issue: "Lines 23 and 38-44 only canonicalize and inspect the supplied path; lines 25-29 and 85-92 create output after the sole porcelain check without restricting it to ignored tmp/."
      - path: "test/scripts/phase_164_closeout_test.exs"
        issue: "The positive fixture at lines 87-128 creates and passes a disposable temporary repository, and has no noncanonical-repo or output-in-worktree negative case."
    missing:
      - "Reject any --repo that is not the canonical checkout, and test that rejection."
      - "Require ignored tmp/ output (or re-check porcelain after all writes) and test a non-ignored output path."
  - truth: "D-09 through D-11/TRTH-03: A fresh untracked report for exact protected main proves clean canonical Git state, successful exact-SHA CI, and evidence-valid scheduled/recovery outcomes."
    status: failed
    reason: "The retained volatile report is for 84454ae6b60ec9c52114d5bf44ed394dac611f99, while this checkout's HEAD is dd542caa1e5cb0ffc76dde21fc87a07915536a7b and origin/main remains 84454ae6b60ec9c52114d5bf44ed394dac611f99. It is therefore not fresh evidence for the actual workspace state."
    artifacts:
      - path: "tmp/phase-164-closeout/report.json"
        issue: "captured_at is 2026-08-27T16:51:33Z and head_sha/origin_main_sha are 84454a..., not the current local HEAD."
    missing:
      - "After fixing the closeout gate and integrating the verification/report commit, obtain a normal protected-main CI run and regenerate a report for the then-current exact SHA."
---

# Phase 164: Repository Truth Reconciliation and Closeout Verification Report

**Phase Goal:** Maintainers can rely on documentation, tracked artifacts, ignore rules, and final evidence to describe the repository's actual supported and operational state.
**Verified:** 2026-08-27T17:00:16Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | TRTH-01: Maintainer, release, recovery, and supported-command guidance agrees with protected workflow facts. | ✓ VERIFIED | `MAINTAINING.md:5-48` names hygiene, exact-candidate digest, repository-admin authorization, exact run/SHA, scheduled evidence, and non-success states; the focused contract passed. |
| 2 | Historical v1 procedures remain discoverable but are unmistakably non-current. | ✓ VERIFIED | `MAINTAINING.md:474-479` explicitly labels Phase 38/73 procedures historical and non-current; contract test passed. |
| 3 | Current package guidance matches core/admin 2.5.0 and inbound 2.2.0 manifests. | ✓ VERIFIED | `mix.exs:4`, `mailglass_admin/mix.exs:4`, and `mailglass_inbound/mix.exs:4` agree with README constraints; dynamic docs contract passed. |
| 4 | The locked stale root sweep has one evidence-backed remove disposition rather than concealment. | ✓ VERIFIED | Ledger D-08 contains the locked SHA, stale generated identity, no consumer, and `remove`; `scheduled-control-sweep.json` is absent and no ignore rule names it. |
| 5 | Durable scheduled/release/publish/planning proof remains tracked and discoverable. | ✓ VERIFIED | The repository-truth contract checks tracked proof paths and Phase 164 artifacts; focused suite passed. |
| 6 | Every scoped artifact and every non-comment ignore rule has one **complete** evidence-backed disposition. | ✗ FAILED | The closeout gate accepts a one-row fixture ledger and only performs a partial AWK validation; it cannot prove complete authoritative coverage. |
| 7 | Retained ignore rules are narrowly scoped and name a shared producer. | ✓ VERIFIED | Ledger inventories all six ignore files bijectively and the focused ledger contract passed. |
| 8 | A rerunnable command composes hygiene, preservation, CI, scheduled-control, and ledger evidence into a volatile report. | ✓ VERIFIED | `scripts/closeout_repository_truth.sh:38-91` invokes all five authorities and normalizes component JSON; fixture contract passed. |
| 9 | Quiet requires the canonical checkout on main, at exact origin/main, with no tracked or untracked entries. | ✗ FAILED | Script accepts any supplied clean `main` repository and writes output after its sole porcelain check. |
| 10 | Quiet requires exact-main protected CI and current identity-matched scheduled/recovery evidence. | ✗ FAILED | Existing report proves only old SHA `84454a...`; current local `HEAD` is `dd542c...`, and no current exact-SHA report exists. |
| 11 | Quiet requires the complete exact-one ledger gate. | ✗ FAILED | The script's line-72 AWK gate omits the actual ledger's completeness and semantic rules. |
| 12 | Protected-main handoff uses a normally-triggered CI run for the supplied exact SHA. | ✓ VERIFIED | Stored report's CI source ties run `33085442330` to `84454a...`; this was valid for that historical snapshot, not current closeout. |
| 13 | Final evidence describes the repository's **actual current** operational state. | ✗ FAILED | Current workspace is locally ahead of `origin/main`; stored volatile report is stale and its claimed quiet state is no longer current. |

**Score:** 8/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `MAINTAINING.md` | Current release/recovery path and historical boundary | ✓ VERIFIED | Substantive, contract-tested documentation; links to workflow authority. |
| Package READMEs | Manifest-derived compatibility guidance | ✓ VERIFIED | Substantive, dynamically tested against all three manifests. |
| `164-TRUTH-DISPOSITION.tsv` | Complete artifact/ignore disposition ledger | ⚠️ HOLLOW IN CLOSEOUT | Ledger and its direct contract are substantive; the consuming closeout CLI does not validate its full meaning or scope. |
| `test/scripts/phase_164_repository_truth_test.exs` | Ledger contract | ⚠️ WARNING | Focused test passes, but `String.starts_with?/2` at lines 244-249 accepts forged currentness prefixes such as `current-forged`. |
| `scripts/closeout_repository_truth.sh` | Fail-closed canonical closeout CLI | ✗ FAILED | Substantive and wired, but omits canonical-path/output cleanliness/complete-ledger enforcement. |
| `test/scripts/phase_164_closeout_test.exs` | Identity and failure-precedence contract | ⚠️ INSUFFICIENT | Passes, while its pass fixture demonstrates the noncanonical-repository bypass and incomplete ledger acceptance. |
| `164-CLOSEOUT.md` | Stable rerun contract | ⚠️ CONTRADICTED | Claims canonical path and complete ledger conditions the executable CLI does not enforce. |
| `tmp/phase-164-closeout/report.json` | Fresh exact-main volatile proof | ✗ STALE | Report SHA `84454a...` differs from current `HEAD` `dd542c...`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `MAINTAINING.md` | `.github/workflows/release-please.yml` | exact command, digest, repository-admin authority | ✓ WIRED | Contract and prose align with guarded workflow language. |
| Package READMEs | three manifests | dynamic major/minor assertions | ✓ WIRED | `docs_contract_test.exs` computes manifest versions. |
| Ignore files/proof paths | disposition ledger | deterministic exact-one inventory | ⚠️ PARTIAL | Direct test inventories them, but final closeout uses a different partial validator. |
| Closeout CLI | evidence tools | normalized component report | ✓ WIRED | Script invokes hygiene, workspace evidence, CI monitor, and scheduled sweep. |
| CLI `--repo`/`--ledger` | authoritative canonical paths | exact identity binding | ✗ NOT_WIRED | Arbitrary existing paths are accepted. |
| checkpoint SHA/CI | current volatile report | independent exact identity assertions | ✗ NOT_WIRED | Stored report is bound to a prior SHA, not current workspace identity. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Closeout CLI | Git identity/porcelain | `git -C "$repo"` | Yes, but any caller-supplied repo | ⚠️ UNSCOPED |
| Closeout CLI | ledger verdict | caller-supplied TSV + partial AWK | No complete semantic coverage | ✗ HOLLOW |
| Closeout report | CI/scheduled components | `ci_monitor.cjs` and `scheduled_control_evidence.sh` | Historical report contains real evidence for `84454a...` | ⚠️ STALE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase ledger/docs/closeout contracts | `mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | 49 tests, 0 failures, 1 skipped | ✓ PASS (but insufficient for the failed truth cases) |
| Closeout script parses | `bash -n scripts/closeout_repository_truth.sh` | exit 0 | ✓ PASS |
| Current report identity | `git rev-parse HEAD; git rev-parse refs/remotes/origin/main; jq .head_sha tmp/phase-164-closeout/report.json` | `dd542c...`; `84454a...`; `84454a...` | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` files found.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| TRTH-01 | 164-02, 164-03, 164-06, 164-07 | Guidance agrees with actual supported protected workflow, package state, and commands. | ✓ SATISFIED | Current/historical maintenance and package contracts pass, with manifest/workflow evidence. |
| TRTH-02 | 164-01, 164-04, 164-06, 164-07 | All tracked/generated artifacts and ignore rules have evidence-backed classifications; proof remains discoverable. | ✗ BLOCKED | Direct ledger evidence is strong, but the final closeout acceptance path can pass an incomplete/invalid arbitrary ledger. |
| TRTH-03 | 164-05, 164-06, 164-07 | Reproducible final closeout proves clean canonical state, protected CI, outcomes, and dispositions. | ✗ BLOCKED | Canonical repository, complete ledger, output-cleanliness, and fresh-current evidence claims are not enforced/proven. |

No orphaned Phase 164 requirements: all three mapped IDs appear in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/closeout_repository_truth.sh` | 23, 38-44 | Caller-controlled canonical identity | 🛑 Blocker | A clean noncanonical repository can receive `pass`. |
| `scripts/closeout_repository_truth.sh` | 25-29, 85-92 | Writes after porcelain check | 🛑 Blocker | A pass may leave non-ignored untracked output in the checked repository. |
| `scripts/closeout_repository_truth.sh` | 71-72 | Partial ledger parser | 🛑 Blocker | Complete disposition coverage is asserted without enforcement. |
| `test/scripts/phase_164_repository_truth_test.exs` | 244-249 | Prefix currentness validation | ⚠️ Warning | `current-forged`/`stale-but-not-really` can be accepted. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in phase-owned implementation files.

### Prohibition Review — Human Decision Required

All seven plan-declared prohibitions are judgment-tier and remain flagged `unverified` in the plans. Automated inspection found no broad new proof-hiding ignore rule and no code path that dispatches, merges, publishes, or changes authorization. A maintainer must still decide whether the closeout policy-block interpretation and the historical authority boundaries meet the intended operational policy; this review cannot silently turn those judgment prohibitions green.

### Gaps Summary

The documentation and direct ledger evidence are mostly real, but the phase goal is blocked by its central final-evidence mechanism. The closeout script can certify an arbitrary clean repository and a one-row ledger, contradicting its own durable contract. Additionally, the only volatile report belongs to an earlier SHA and the working checkout is no longer aligned with `origin/main`; it cannot describe the repository's current state. These are implementation gaps, not deferred work: no later milestone phase covers them.

---

_Verified: 2026-08-27T17:00:16Z_
_Verifier: the agent (gsd-verifier)_
