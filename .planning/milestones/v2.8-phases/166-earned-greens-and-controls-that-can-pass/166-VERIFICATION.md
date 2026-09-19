---
phase: 166-earned-greens-and-controls-that-can-pass
verified: 2026-09-19T18:15:31Z
status: passed
score: 10/10 roadmap requirements verified
covered_files:
  - .github/workflows/ci.yml
  - .github/workflows/post-publish-smoke.yml
  - .github/workflows/release-please.yml
  - .planning/REQUIREMENTS.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-01-PLAN.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-01-SUMMARY.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-02-PLAN.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-02-SUMMARY.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-03-PLAN.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-03-SUMMARY.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-04-PLAN.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-04-SUMMARY.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-05-PLAN.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-05-SUMMARY.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-06-PLAN.md
  - .planning/phases/166-earned-greens-and-controls-that-can-pass/166-06-SUMMARY.md
  - config/coverage_baselines/admin.json
  - dev/mix/tasks/mailglass.repo.hygiene.ex
  - docs/ci-cache-isolation.md
  - lib/mailglass/supply_chain/accepted_advisories.ex
  - mailglass_admin/mix.exs
  - mailglass_admin/mix.lock
  - scripts/check_post_publish_target.sh
  - scripts/release_policy.exs
  - test/mailglass/supply_chain/accepted_advisories_test.exs
  - test/mix/tasks/mailglass.repo.hygiene_test.exs
  - test/scripts/coverage_floor_contract_test.exs
  - test/scripts/lane_classification_drift_test.exs
covered_digest: "v1:sha256:7788dd078319d4c22718c27e4ef0a9ea32146ec47c012b69fd264e1729f2e08c"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 10/10
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 166: Earned Greens and Controls That Can Pass — Verification Report

**Phase Goal:** Every CI signal either means what it says or can reach its own pass state — without any gate being relaxed.

**Verified:** 2026-09-19T18:15:31Z
**Status:** passed
**Re-verification:** Yes — stale passed report refreshed against the current checkout.

## Goal Achievement

### Observable Truths

The roadmap contracts ten Phase 166 requirements. The handoff's eight-ID subset is covered below; CTRL-04 and CTRL-05 are also retained because Plans 03 and 06 and `REQUIREMENTS.md` assign them to this phase. Omitting them would reduce the phase contract.

| # | Truth | Status | Checkout evidence |
|---|---|---|---|
| 1 | GREEN-01: the Admin support-contract lane runs the complete admin cohort, not a nine-file allow-list. | ✓ VERIFIED | `mailglass_admin/mix.exs:212-214` defines the alias as `test --warnings-as-errors`; `.github/workflows/ci.yml:932-939` invokes that alias in the required job. Direct execution: 510 tests, 0 failures. Root `mix ci.full` calls the same alias at `mix.exs:435`; the parity test is in the passing focused suite. |
| 2 | GREEN-02: the Admin coverage gate is measured and can fail on a regression. | ✓ VERIFIED | `admin.json` supplies the measured triple, toolchain, command and report hash; `ci.yml:934-939` generates the report then calls `check_coverage_floor.sh`. `coverage_floor_contract_test.exs` reads the Admin baseline and the UAT regression drill records failures for each ratchet member. |
| 3 | GREEN-03: the required deterministic lane enforces the full-suite floor. | ✓ VERIFIED | `ci.yml:463-468` sets `MAILGLASS_SUITE_FLOOR: "1"` on the deterministic test step; `test/support/suite_floor.ex` reads that runtime variable. The independent CI-YAML occurrence, anti-vacuity, and negative-control tests are present at `lane_classification_drift_test.exs:648-693`; UAT captures the required-lane FULL SUITE log with 0 failures. |
| 4 | GREEN-04: a CI path builds the demo against Hex dependencies rather than only path dependencies. | ✓ VERIFIED | `ci.yml:292-296` runs an isolated `reference/demo_app` build with `MAILGLASS_DEMO_DEPS: hex`; `reference/demo_app/mix.exs` owns the env-driven dependency selection. The passing trust-lane contract test and UAT record the post-merge Hex-resolution run. |
| 5 | GREEN-05: cache-contamination is resolved with a demonstrated, test-pinned mechanism rather than an assertion. | ✓ VERIFIED | The two trust cache keys and restore prefixes are distinct at `ci.yml:1226-1244` and `:1322-1340`; each records pre-install `reference/host_app/deps` evidence. `docs/ci-cache-isolation.md` is substantive (186 lines) and the passing `ci_trust_lane_contract_test.exs` checks the executable workflow seam. |
| 6 | CTRL-01: post-publish schedule resolution has a satisfiable inactive-ledger baseline path without weakening live dispatch. | ✓ VERIFIED | `release_policy.exs:369-396` implements `baseline-versions` and emits distinct `baseline=true`; `post-publish-smoke.yml:154-167` selects it only for inactive schedule/baseline mode. `check_post_publish_target.sh:89-106` scopes the null-digest bypass to baseline mode. Focused contract tests pass and UAT records a successful baseline resolution. |
| 7 | CTRL-02: an already-tagged push does not re-run release-please. | ✓ VERIFIED | `release-please.yml:133-163` sets `should_run=false` after the tag/label check, and the action step is gated on that output at `:299`. Passing release-policy and trigger-recovery seam tests exercise the tagged path; UAT has the post-merge evidence. |
| 8 | CTRL-03: transient GitHub API failures are classified and retried without converting `cannot-check` into pass. | ✓ VERIFIED | Both `retry_gh` implementations classify only 403/429 plus a secondary-rate phrase and bound retries (`release-please.yml:529-579`, `:674-...`). The final pass predicate at `:889` and `:917` admits only `pass` or the named pending states, never `cannot-check`. Focused seam tests pass. |
| 9 | CTRL-04: the Hex-audit expiry control remains active while the documented cowlib dispositions are truthful and re-checkable. | ✓ VERIFIED | Both entries retain expiry machinery and use `recheck_by: ~D[2027-03-17]`; `expired_entries/1` is strictly-after and `unused_entries/1` remains implemented (`accepted_advisories.ex:216-234`). Boundary and anti-vacuity tests pass; UAT records the accepted real-clock/boundary evidence. |
| 10 | CTRL-05: repo-hygiene distinguishes a non-verdict from an alarm and does not flag a healthy new PR. | ✓ VERIFIED | The PR query requests `createdAt,statusCheckRollup` (`repo_hygiene.ex:289-304`), stale means more than 14 complete days (`:434-445`), and focused tests cover healthy, 14-day, 15-day, null-rollup, and distinct nonzero exit paths. UAT records monitored schedule evidence. |

**Score:** 10/10 truths verified; 0 present-but-behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mailglass_admin/mix.exs` and `mix.lock` | widened alias and ExCoveralls configuration | ✓ VERIFIED | Substantive configuration; called by the workflow and root CI alias. |
| `config/coverage_baselines/admin.json` | measured triple plus provenance | ✓ VERIFIED | All required keys present; values are `3334/3992/83.517034`, with exact toolchain and report hash. |
| `.github/workflows/ci.yml` | admin floor, suite floor, Hex demo, isolated trust cache controls | ✓ VERIFIED | Four independent phase paths are present and actionlint accepts the workflow. |
| `test/scripts/coverage_floor_contract_test.exs` and `lane_classification_drift_test.exs` | ratchet and deletion-detection contracts | ✓ VERIFIED | Both are substantive and included in the passing focused regression run. |
| `accepted_advisories.ex` and its test | expiry, re-check rationale, boundary behavior | ✓ VERIFIED | Expiry and unused-entry functions are live code, with direct boundary/anti-vacuity tests. |
| `.github/workflows/release-please.yml` | tagged-SHA guard and bounded recovery | ✓ VERIFIED | Workflow is actionlint-clean and covered by release seam tests. |
| `docs/ci-cache-isolation.md` | mechanism-level cache-isolation evidence | ✓ VERIFIED | 186-line checked-in deliverable; workflow seam test verifies the keys, paths, and observation order it describes. |
| `post-publish-smoke.yml`, `release_policy.exs`, and `check_post_publish_target.sh` | inactive-ledger baseline resolution, live-path guards retained | ✓ VERIFIED | Workflow selects the new verb, and the script's bypass is explicitly baseline-only. |
| `mailglass.repo_hygiene.ex` and its test | age/check predicate and distinct nonzero exits | ✓ VERIFIED | The implementation is exercised through fake-`gh` integration cases, including malformed/null input. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `support_contract_admin` job | widened Admin alias | `cd mailglass_admin && mix verify.support_contract.admin` | ✓ WIRED | Actual alias execution produced 510 tests, 0 failures. |
| Admin coverage workflow step | Admin baseline and ratchet script | generated ExCoveralls JSON then `check_coverage_floor.sh` | ✓ WIRED | Exact baseline path and `1.18.4/27` toolchain are passed by CI. |
| deterministic CI step | `SuiteFloor` runtime enforcement | `MAILGLASS_SUITE_FLOOR` environment | ✓ WIRED | `SuiteFloor` reads the environment at runtime; drift guard prevents silent deletion. |
| demo CI proof | `reference/demo_app/mix.exs` | `MAILGLASS_DEMO_DEPS=hex` | ✓ WIRED | Isolated build step explicitly selects Hex and leaves legacy path-dep steps intact. |
| release preflight | release-please action | `should_run` output in action `if:` | ✓ WIRED | Tagged label makes `should_run=false`; no action re-run is reachable on that path. |
| post-publish resolver | `baseline-versions` CLI | inactive ledger / baseline dispatch selection | ✓ WIRED | Distinct `baseline` output flows to the schedule predicate; `completed` is not overloaded. |
| repo-hygiene status | exit mapping/rendering | aggregate status | ✓ WIRED | Tests prove blocked and cannot-check exit codes are different and both nonzero. |

### Data-Flow Trace (Level 4)

No phase artifact renders dynamic user data. The relevant control data flows are non-hollow: CI values flow into runtime environment/script inputs; baseline versions flow from the validated ledger through `release_policy.exs`; and GitHub PR fields flow through the hygiene predicate. No static-success return or disconnected rendered value was found.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full Admin suite is actually selected by the alias | `cd mailglass_admin && MIX_ENV=test mix verify.support_contract.admin` | 510 tests, 0 failures | ✓ PASS |
| Phase 166 control seams | focused `MIX_ENV=test mix test --warnings-as-errors` across 10 Phase 166 test files | exit 0 | ✓ PASS |
| Workflow and shell syntax | `actionlint` on all three changed workflows; `shellcheck scripts/check_post_publish_target.sh`; `git diff --check` | exit 0 | ✓ PASS |
| End-to-end and operational assertions | `166-UAT.md` | 19/19 checks pass | ✓ PASS |

### Requirements Coverage

| Requirement | Source plan | Status | Evidence |
|---|---|---|---|
| GREEN-01 | 166-01 | ✓ SATISFIED | Widened alias, unchanged CI/root invocation, direct 510-test execution. |
| GREEN-02 | 166-01 | ✓ SATISFIED | Measured baseline, exact toolchain ratchet, regression-drill UAT. |
| GREEN-03 | 166-02 | ✓ SATISFIED | Required-lane environment, runtime reader, three-part deletion guard, UAT log. |
| GREEN-04 | 166-05 | ✓ SATISFIED | Isolated Hex build plus contract/UAT evidence. |
| GREEN-05 | 166-05 | ✓ SATISFIED | Lane-specific caches, pre-install evidence, documented mechanism, seam test. |
| CTRL-01 | 166-06 | ✓ SATISFIED | Baseline resolver, workflow selection, scoped digest bypass, UAT. |
| CTRL-02 | 166-04 | ✓ SATISFIED | Tagged-SHA preflight/action link and passing recovery seams. |
| CTRL-03 | 166-04 | ✓ SATISFIED | Bounded classified retry; pass predicate still rejects `cannot-check`. |
| CTRL-04 | 166-03 | ✓ SATISFIED | Active expiry/unused-entry behavior, boundary tests, accepted UAT evidence. |
| CTRL-05 | 166-06 | ✓ SATISFIED | Age/check predicate, nonzero distinction, focused behavior tests. |

No orphaned Phase 166 requirement was found: all ten IDs in `REQUIREMENTS.md` map to exactly one of Plans 01–06.

### Anti-Patterns Found

No blocker or warning anti-patterns were found in the Phase 166 implementation files. The scan found only expected literal strings in a negative test fixture and workflow error messages; no `TBD`, `FIXME`, `XXX`, stub return, hollow control path, or unreferenced debt marker was present. There are no declared probes for this phase.

### Security and UI Evidence

`166-SECURITY.md` is current and reports `threats_open: 0` (19 mitigated, 7 explicitly accepted low-risk/public-information items). `166-UI-REVIEW.md` correctly marks the UI surface N/A: Phase 166 changes CI, release, audit, cache, and CLI controls, not rendered application UI.

### Advisory (New Scope, Unevidenced)

None. This refresh found no new-scope concern requiring advisory treatment.

### Gaps Summary

No gaps. The phase goal holds in the current checkout: the controls are wired to their consumers, have executable proof for their controllable behavior, and the observed CI/UAT evidence closes the external-runtime acceptance checks. The direct code and tests show no gate was relaxed to earn those greens.

---

_Verified: 2026-09-19T18:15:31Z_
_Verifier: gsd-verifier_
