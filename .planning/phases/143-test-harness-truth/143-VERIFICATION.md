---
phase: 143-test-harness-truth
verified: 2026-07-31T18:53:08Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 143: Test-Harness Truth Verification Report

**Phase Goal:** The Ecto Sandbox ownership-leak mechanism is understood and fixed — not masked, not tagged away, not silenced by serialization — Core Full Suite is genuinely green across the full toolchain/schema matrix, and there is a recorded, evidence-backed answer to whether it should gate a release.

**Verified:** 2026-07-31T18:53:08Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The actual `:already_shared` mechanism is empirically explained before its fix, rather than inferred from the original hypothesis. | ✓ VERIFIED | [143-MECHANISM.md](143-MECHANISM.md) records the CI run/job, nested `MatchError` shape, causal chain, D-04 predictions, and three-class inventory. [mechanism_account_contract_test.exs](../../../test/scripts/mechanism_account_contract_test.exs) makes those artifacts a required `mix_task_tests` contract; all four full-suite legs subsequently passed it in Actions runs 30595090072, 30635221221, and 30638980059. |
| 2 | The ownership, schema-drift, and baseline-teardown causes are fixed by restoration/verification paths, not by serializing, skipping, excluding, or catching the symptom. | ✓ VERIFIED | [sandbox_ownership.ex](../../../test/support/sandbox_ownership.ex) has release-first `checkout!/1`, guarded `unsandboxed_module/1`, `with_schema!/2`, and fail-closed baseline verification. [data_case.ex](../../../test/support/data_case.ex), [mailer_case.ex](../../../test/support/mailer_case.ex), and the former leak site call the sanctioned door. The Credo guard rejects raw ownership calls outside the narrowly justified mechanism/fixture modules. The pre/post diff contains no changed existing module async attribute, no new exclusion token, and no `rescue MatchError`. |
| 3 | Every sync-module boundary is observed without module opt-in, and a non-observable or unhealthy state cannot become a quiet green result. | ✓ VERIFIED | [test_helper.exs](../../../test/test_helper.exs) registers `SuiteTruthFormatter` beside `ExUnit.CLIFormatter`; [suite_truth_formatter.ex](../../../test/support/suite_truth_formatter.ex) runs class A/B/C probes only for `tags[:async] == false`, stores final state at `:suite_finished`, and feeds it to `SuiteFloor`. The formatter and ownership regression tests were exercised by the successful root full-suite runs. |
| 4 | Core Full Suite is green on Elixir 1.18/OTP 27 and 1.19/OTP 28, for both `public` and `mailglass`, repeatedly rather than on one lucky seed. | ✓ VERIFIED | Direct GitHub Actions API inspection confirmed all four completed-success jobs in three distinct `main` push runs: 30595090072 (`d6e50388`), 30635221221 (`981b9343`), and 30638980059 (`7649f96f`). Each ran the `Run advisory full suite` step. The scheduled run 30607136165 and tag-shaped dispatch 30595564984 also completed all four legs successfully. |
| 5 | Test loss, unapproved exclusions, and both raw and composed `:already_shared` forms fail the full-suite lane instead of merely being reported. | ✓ VERIFIED | [suite_floor.ex](../../../test/support/suite_floor.ex) reads native `ExUnit.after_suite/1` counts, has per-schema floors (1576/1575), a skipped ceiling, two-form signature classification, and non-zero enforcement. Both full-suite workflow steps set `MAILGLASS_SUITE_FLOOR: "1"`; [lane_classification_drift_test.exs](../../../test/scripts/lane_classification_drift_test.exs) pins both declarations. The deliberate failing-test run 30599206217 made both floor legs fail. |
| 6 | The Core Full Suite release-gating decision is recorded, is reflected in the workflow, and fails closed when the required floor legs are missing or red. | ✓ VERIFIED | [143-GATING-DECISION.md](143-GATING-DECISION.md) records `gate-floor-legs`, rationale, accepted gaps, and live evidence. [publish-hex.yml](../../../.github/workflows/publish-hex.yml) queries advisory-matrix jobs, fails on absent/incomplete/red floor legs, and makes `publish-core` depend on `gate-ci-green`. |
| 7 | A red Core Full Suite demonstrably prevents a Hex publish, while the green path has operated safely. | ✓ VERIFIED | Direct Actions inspection of dry-run negative rehearsal 30654293410: `gate-ci-green` failed and `publish-core` was `completed/skipped`. Its failed log names both floor legs as failures. Positive release runs 30645265238 and 30645266725 both passed `gate-ci-green`; the latter completed its publish path successfully. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/sandbox_ownership.ex` | Sanctioned, fail-closed ownership/restoration seam | ✓ VERIFIED | 1,501 substantive lines; actual public helpers and mechanism errors; used by 60 call sites under `test/`. |
| `test/support/suite_truth_formatter.ex` | Suite-wide hygiene/provenance observer | ✓ VERIFIED | 438 substantive lines; registered in `test_helper`, delegates to ownership helpers, snapshots for `SuiteFloor`. |
| `test/support/suite_floor.ex` | Executed-count/signature/exclusion enforcement | ✓ VERIFIED | `after_suite` callback is registered in `test_helper`; two workflow environment bindings turn reporting into enforcement. |
| `143-MECHANISM.md` and both ledger files | Evidence-backed root-cause record | ✓ VERIFIED | Present, non-empty, cited from the enforced mechanism-account contract test; ledgers contain no tested address/subject/recipient markers. |
| `.github/workflows/advisory-matrix.yml` | Four-leg full-suite matrix | ✓ VERIFIED | Explicit 1.18/27 and 1.19/28 × public/mailglass matrix; each run executes root `mix test --warnings-as-errors --exclude requires_workspace`. |
| `.github/workflows/publish-hex.yml` | Publish gate and publish dependency | ✓ VERIFIED | Exact two-leg gate list is wired; `publish-core.needs: [gate-ci-green]`. Live negative rehearsal exercised the link. |
| `143-GATING-DECISION.md` | Recorded gate decision and rehearsal evidence | ✓ VERIFIED | Seven substantive sections, verdict, positive/rehearsal run IDs, tag cleanup record, and accepted gaps. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `test/test_helper.exs` | `SuiteTruthFormatter` | `ExUnit.configure(formatters: [ExUnit.CLIFormatter, ...])` | ✓ WIRED | Formatter is loaded globally; no CLI `--formatter` replacement is used. |
| `SuiteTruthFormatter` | `SandboxOwnership` | `probe/1` and `baseline_tables_present?/1` | ✓ WIRED | Real formatter path invokes the helper functions; the logic is not duplicated in the formatter. |
| `SuiteTruthFormatter` | `SuiteFloor` | final `:persistent_term` snapshot → `current_state/0` → `after_suite` check | ✓ WIRED | Snapshot occurs at `:suite_finished`, the last live formatter event; unavailable state becomes a violation rather than zero. |
| `SuiteFloor` | Core Full Suite jobs | `MAILGLASS_SUITE_FLOOR: "1"` | ✓ WIRED | Present in both full-suite steps and protected by a drift test. |
| Advisory Matrix | `gate-ci-green` | exact runtime-name classification and Actions API polling | ✓ WIRED | Red/absent gating legs call `core.setFailed`; live negative rehearsal produced that failure. |
| `gate-ci-green` | `publish-core` | GitHub Actions `needs` dependency | ✓ WIRED | Rehearsal 30654293410 left `publish-core` skipped after gate failure. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `SuiteTruthFormatter` | violations/signature tally | Actual ExUnit module/test-finished events and sandbox/Postgres probes | ExUnit event payloads plus live ownership-manager and information-schema reads | ✓ FLOWING |
| `SuiteFloor` | total/excluded/skipped/failures and tallies | `ExUnit.after_suite/1` results plus formatter final snapshot | Native run results, not a summary-line parser or static fixture | ✓ FLOWING |
| `publish-hex.yml` | advisory-matrix job conclusions | GitHub Actions workflow-runs/jobs API | Real workflow/job outcomes; confirmed by the negative dry-run log | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command / evidence | Result | Status |
| --- | --- | --- | --- |
| Full toolchain/schema matrix | `gh run view` for 30595090072, 30635221221, 30638980059 | Four Core Full Suite jobs each completed `success` in each run | ✓ PASS |
| Repeated/cron/tag matrix evidence | `gh run view` for 30607136165 and 30595564984 | All four full-suite jobs completed `success` | ✓ PASS |
| Deliberate regression is caught | `gh run view 30599206217` | Both Elixir 1.18 floor legs failed their actual full-suite step | ✓ PASS |
| Red floor leg blocks publish | `gh run view 30654293410` and failed gate log | Gate failed; `publish-core` skipped; log identifies both red floor legs | ✓ PASS |
| Local focused phase suite | `mix test ... --warnings-as-errors` | Not runnable: local Ecto dependency lock mismatch; Mix requires `mix deps.get`. No dependency mutation performed during verification. | ? SKIP |
| Formatting | `mix format --check-formatted` | Exit 0 | ✓ PASS |

### Probe Execution

No `scripts/**/tests/probe-*.sh` probe was declared or present for this phase. The applicable deliberate-failure probes are GitHub workflows; their independently inspected runs are recorded above.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| HARNESS-01 | 143-01, 03–08 | Empirically establish and fix the Sandbox ownership leak without masking it | ✓ SATISFIED | Mechanism account/ledgers, sanctioned ownership door, formatter, class A/B/C hardening, and raw-call Credo prevention are present and exercised by successful full-suite Actions runs. |
| HARNESS-02 | 143-01, 03, 07, 10–12 | Four-leg full suite, repeated and seed-varied | ✓ SATISFIED | Three distinct green main SHAs, plus successful cron and tag-shaped dispatch, each include all four jobs. |
| HARNESS-03 | 143-02, 09–12 | No manufactured green; count floor/signature zero and deliberate regression probe | ✓ SATISFIED | `SuiteFloor` enforcement and drift link exist; run 30599206217 failed both floor legs on synthetic failure. |
| HARNESS-04 | 143-11–14 | Evidence-backed release-gating decision and a publish-block demonstration | ✓ SATISFIED | Gate decision, workflow dependency, successful release gates, and negative rehearsal 30654293410. |

**Traceability warning (non-blocking):** `REQUIREMENTS.md`’s detailed HARNESS-01 checkbox is checked and its implementation evidence is present, but its status table still says “In Progress (5 of 7 contributing plans landed…)” despite all 14 plans being marked executed. This is stale project tracking, not an implementation gap; update it separately to avoid misleading later audits.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `.planning/REQUIREMENTS.md` | 262 | Stale HARNESS-01 status table row | ⚠️ Warning | Traceability metadata contradicts the completed plan list and requirement checkbox. |
| Local dependency environment | n/a | Ecto lock mismatch blocks focused test execution | ⚠️ Warning | Prevented an additional local test run; it does not invalidate the independently queried successful full-suite CI evidence. |

No `TBD`, `FIXME`, or `XXX` debt marker was found in the implementation artifacts modified for the phase. No blocking stub, orphaned key link, raw static data flow, or masking pattern was found.

### Verification Notes

The Phase 143 decision-coverage parser limitation in `STATE.md` is real but is not a phase defect: its parser cannot parse the punctuation/formatting of D-04, D-12, and D-17. Direct plan evidence confirms D-04 is cited by plans 01/03/04/11, D-12 by 01/06, and D-17 by 01/04/09; their resulting mechanisms are present in source and CI evidence.

The open `TOOL-02` record—`CI Green` remains structurally blind to root-suite regressions—is intentionally routed to Phase 144. It is not a failure of this phase’s release-gating contract: Phase 143’s independent Advisory Matrix Core Full Suite gate demonstrably catches the injected regression before publish.

---

_Verified: 2026-07-31T18:53:08Z_  
_Verifier: the agent (gsd-verifier)_
