---
phase: 141-lane-truth-foundation
verified: 2026-07-28T20:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 141: Lane Truth Foundation Verification Report

**Phase Goal:** Every CI lane in this repository has exactly one recorded, machine-verified
classification (required, advisory, or retired) instead of three disagreeing registries and an
undocumented default bucket, and the planning artifacts a tooling defect deleted mid-milestone are
restored.

**Verified:** 2026-07-28
**Status:** passed
**Re-verification:** No — initial verification

## Method

This verification did not trust `141-0X-SUMMARY.md` claims. Every load-bearing claim below was
independently re-derived against the actual codebase at `HEAD 18247647` (one docs-only commit past
the `7a603e34` SHA the SUMMARYs cite — diff confirmed to touch only `.planning/REQUIREMENTS.md`,
`.planning/ROADMAP.md`, `.planning/STATE.md`, and the 141-06 SUMMARY itself, i.e. no code or CI
change since the cited SHA):

- Ran `MIX_ENV=test mix verify.ci_lane_contract` and `mix test test/scripts/lane_classification_drift_test.exs` myself (not copy-pasted from a SUMMARY).
- Read `test/support/ci_yaml.ex` and the full 650-line `test/scripts/lane_classification_drift_test.exs` to confirm the anti-vacuity guards are real: every parser (`parse_js_array/2`, `find_required_checks_section/1`, `parse_disposition_table/1`) returns an empty result on non-match rather than raising, and every one of those call sites is paired with an exact-size assertion (`== 5`, `== 4`, `== 13`, `== 2`, `== 24`) that would fail loudly if the parser silently matched nothing. A test that would pass on empty input does not exist here — the exact-count guard closes that hole at every site.
- Independently injected and reverted a throwaway unclassified `ci.yml` job myself (not relying on the SUMMARY's transcript) and confirmed the drift test failed by name, then confirmed a clean revert (`git status --porcelain` empty, 23/23 tests passing again).
- Independently called the live GitHub API (branch protection + the cited workflow run's job list) rather than trusting the transcribed values in `141-06-SUMMARY.md`, and independently re-derived the classification of all 24 real runtime job names (matrix suffixes included) against `Mailglass.CILanes`'s four buckets using the actual registry functions — zero unclassified, zero double-matched.
- Ran `mix ci.fast`, `mix verify.support_contract.core`, and `mix test test/mailglass/docs_contract_test.exs` myself.
- Grepped `MAINTAINING.md`, `CONTRIBUTING.md`, `.planning/REQUIREMENTS.md`, and `.planning/TOOLING-DEFECTS.md` directly rather than trusting the SUMMARY's grep-count claims.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `ci_lanes.ex`, `publish-hex.yml`'s `gate-ci-green`, and `MAINTAINING.md` agree on every lane's status, with a meta-test that fails on drift | ✓ VERIFIED | `mix verify.ci_lane_contract` (40 tests, 0 failures, independently run). Read `publish-hex.yml:194-330` — `classify/1` enumerates `REQUIRED_LANES`/`ADVISORY_LANES`/`PUBLISH_GATING_LANES`/`STRUCTURAL_LANES` with no naming-convention regex. `MAINTAINING.md`'s 24-row table is bound to `Mailglass.CILanes` and to `publish-hex.yml` by `lane_classification_drift_test.exs`'s pair-set-equality tests (independently re-run). Fail-loud property independently reproduced (see Method). |
| 2 | No `ci.yml` job can silently sit in neither `ci_green.needs` nor the recognized-advisory set — each of the 9+ previously-hidden jobs carries an explicit classification | ✓ VERIFIED | `Mailglass.CILanes.all_classified_lanes/0` returns 24 entries (independently run: `mix run --no-start -e ...` → 24, distinct). `mix.exs`/`ci.yml` parse to 24 jobs (independently run). The set-equality assertion between `Mailglass.CIYaml.job_names/1` and `all_classified_lanes/0` is real (independently injected-and-reverted an unclassified job; it failed by name). |
| 3 | The "Credo Strict" lane's job list distinguishes it from the design-system conformance gate by name alone, with an explicit required/advisory/neither status | ✓ VERIFIED | `.github/workflows/ci.yml` declares `credo_strict` (6 steps) and `conformance_gates` (4 steps) as disjoint job regions (independently verified with `awk` region counts: 6 and 4). Both classified `publish-gating` in `Mailglass.CILanes` and in the `MAINTAINING.md` table. Independently reconfirmed live: run `30408642505` shows `Credo Strict (Elixir 1.18 / OTP 27)` and `Design System Conformance (shell gates)` both present and green in the same run. |
| 4 | Every lane in the reconciled set carries a written disposition (promote/keep-with-reason/retire) in a durable, findable place | ✓ VERIFIED | `MAINTAINING.md` § "Required Checks": 24 data rows, 1 separator (independently grepped), disposition counts 22 `keep-with-reason` + 2 `promote` = 24 (independently grepped, matches the plan's own predicted counts exactly). Vocabulary is closed and machine-asserted (`~w(promote keep-with-reason retire)`). |
| 5 | `.planning/milestones/v2.0-phases/` contains the restored 132-137 artifacts, and the `phases.clear` defect is written down so a future run recognizes it as a repeat | ✓ VERIFIED | `find .planning/milestones/v2.0-phases -type f \| wc -l` → 48; `v2.1-phases` → 39 (both independently run). `.planning/TOOLING-DEFECTS.md` exists at the `.planning/` root, has no `milestone:` frontmatter key (independently checked with `awk`), and its `TOOL-01` entry cites both occurrences (`b5fed519`, `70099869`) and demotes `--archive-version` to "necessary but insufficient" (independently grepped). |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/support/ci_yaml.ex` | `Mailglass.CIYaml.job_names/1` + `matrix_job_names/1` parsers | ✓ VERIFIED | Read in full (105 lines). Returns empty map/set on non-match (no raise); 2 public functions, 2 `@spec`s (confirmed by grep). |
| `test/scripts/lane_classification_drift_test.exs` | Drift meta-test, three-way registry agreement | ✓ VERIFIED | Read in full (650 lines). 23 tests, 0 failures (independently run). Anti-vacuity guards confirmed real (see Method). |
| `test/support/ci_lanes.ex` | Four-bucket classification axis + untouched parity axis | ✓ VERIFIED | `required_lanes/0`=5, `advisory_classified_lanes/0`=4, `publish_gating_lanes/0`=13, `structural_lanes/0`=2, `all_classified_lanes/0`=24 distinct (independently run via `mix run --no-start`). |
| `.github/workflows/ci.yml` | `verify.ci_lane_contract` wired into `mix_task_tests`; `credo_strict`/`conformance_gates` split; `ci_green.needs` unchanged | ✓ VERIFIED | `grep -c 'run: mix verify.ci_lane_contract'` → 1; `ci_green.needs` region has exactly the 5 pre-existing entries (independently confirmed via `awk`). |
| `.github/workflows/publish-hex.yml` | `gate-ci-green` rewritten with 4 enumerated arrays, no naming-convention regex | ✓ VERIFIED | Read the full script block. `isAdvisory`/`/ Advisory \(/` absent; `classify`/`startsWithAny` present; required-lane presence loop (`(missing)` / `core.setFailed`) preserved verbatim. |
| `MAINTAINING.md` | One 24-row disposition table, § "Required Checks" | ✓ VERIFIED | Independently grepped: 24 rows, 1 separator, correct disposition-word counts, advisory-matrix.yml lanes covered in prose (see note below). |
| `.planning/TOOLING-DEFECTS.md` | TOOL-01 defect record, milestone-independent | ✓ VERIFIED | Exists, no `milestone:` key, both occurrences cited, mitigation correctly ranked. |
| `.planning/REQUIREMENTS.md` | TRUTH-09 amended to the shipped 3-bucket+structural model | ✓ VERIFIED | Stale "merge-gating or advisory" and "The 9+" text both absent (independently grepped, count 0). |
| `CONTRIBUTING.md` | Correct 2-context branch-protection claim | ✓ VERIFIED | Names `CI Green`/`Guard Release Trigger`; no `PR title (semantic)` stale claim; diff scope confined to the claimed paragraph. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `mix_task_tests` job (`ci.yml`) | `mix verify.ci_lane_contract` | real CI step | ✓ WIRED | `grep -c 'name: Run CI lane-contract meta-tests'` → 1; independently ran the alias itself. |
| `Mailglass.CILanes` (Elixir) | `publish-hex.yml`'s 4 JS arrays | `lane_classification_drift_test.exs` set-equality | ✓ WIRED | 4 set-equality tests independently passed; fail-loud independently reproduced on `ci.yml`. |
| `Mailglass.CILanes` | `MAINTAINING.md`'s disposition table | `parse_disposition_table/1` + pair-set-equality | ✓ WIRED | Independently grepped row/column shape; test suite (23 tests in this file) passes. |
| Live GitHub runtime job names | `Mailglass.CILanes`'s 4 buckets | prefix/exact matching | ✓ WIRED | Independently re-derived classification of all 24 real job names (with matrix suffixes) from run `30408642505` against the actual registry functions — 0 unclassified, 0 double-matched. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Drift meta-test fails loud on an injected unclassified `ci.yml` job | Injected `throwaway_probe_job`, ran `mix test test/scripts/lane_classification_drift_test.exs`, reverted | Test failed naming the injected job; clean revert confirmed (`git status --porcelain` empty, 23/23 passing) | ✓ PASS |
| `mix verify.ci_lane_contract` is the real, wired CI gate | `MIX_ENV=test mix verify.ci_lane_contract` | 40 tests, 0 failures | ✓ PASS |
| `mix ci.fast` green (this phase touched `mix.exs`, `ci_lanes.ex`) | `mix ci.fast` | Credo: 482 files, no issues; exit 0 | ✓ PASS |
| Live branch protection is exactly 2 contexts | `gh api .../branches/main/protection --jq '.required_status_checks.contexts'` | `["CI Green","Guard Release Trigger"]` | ✓ PASS |
| Live CI run's 24 job names each classify to exactly one bucket | Custom Elixir script against `Mailglass.CILanes`'s real accessors, fed the run's actual job names | 24/24 classified, 0 unclassified, 0 double-matched | ✓ PASS |
| `mix ci` green locally (plan 141-06's own Verification Group 5) | `mix ci` | Fails at "Unchecked dependencies for environment dev" | ✗ FAIL (see note below — sandbox/environment gap, not a code defect) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| TRUTH-07 | 141-01, 141-04, 141-06 | Reconcile 3 disagreeing registries to 1, verified by drift-failing test | ✓ SATISFIED | Set-equality tests across all 4 registries pass; fail-loud independently reproduced. |
| TRUTH-09 | 141-02, 141-04, 141-05 | Hidden third gating tier eliminated; every job explicitly classified | ✓ SATISFIED | 24/24 classified, independently confirmed against live runtime names. |
| TRUTH-05 | 141-06 | Every lane carries a recorded disposition | ✓ SATISFIED (scoped) | 24-row table, closed vocabulary, machine-verified. See note below on `advisory-matrix.yml` scope. |
| CONFORM-04 | 141-03, 141-04 | Rename/split "Credo Strict" with explicit disposition | ✓ SATISFIED | Split confirmed disjoint; both lanes green in same live run; classified `publish-gating`. |
| HIST-01 | 141-02 | Restore v2.0 phase artifacts; document the `phases.clear` defect | ✓ SATISFIED | 48/39 file counts independently confirmed; `TOOLING-DEFECTS.md` independently confirmed. |

All 5 phase-141 requirement IDs from `.planning/REQUIREMENTS.md`'s traceability table are accounted
for above. No orphans: cross-referencing `.planning/REQUIREMENTS.md`'s "Phase 141" row assignments
against the `requirements:` frontmatter of all 6 plans shows a 1:1 match.

### Anti-Patterns Found

None found in the files this phase modified. Debt markers checked (`TBD`/`FIXME`/`XXX`) — none introduced.
Accepted, explicitly-recorded debt (not a defect): `required_checks_test.exs`'s parsers were
deliberately not refactored to delegate to `Mailglass.CIYaml` (recorded in both files' docs, with an
explicit rationale, per the plan's own decision record).

### Notes (not gaps — recorded for transparency)

1. **TRUTH-05's scope is `ci.yml`'s 24 jobs, not `advisory-matrix.yml`'s additional lanes
   (`Core Full Suite Advisory`, `Provider Compatibility Advisory`, `Inbound Full Suite Advisory`).**
   These three lanes are covered only by unstructured prose in `MAINTAINING.md` (independently
   confirmed: no table row, no closed-vocabulary disposition word, not bound by the meta-test) rather
   than a machine-verified disposition. This is a **deliberate, explicitly-recorded** scope boundary,
   not an oversight: `141-CONTEXT.md` and `141-RESEARCH.md` both record that extending `gate-ci-green`
   to inspect `advisory-matrix.yml` is Phase 143/HARNESS-04's work, and TRUTH-05's own requirement text
   says dispositions are recorded "against the reconciled set" — the set TRUTH-09 reconciles, which is
   `ci.yml`-scoped by its own wording. I did not treat this as a gap given the explicit decision trail,
   but a stricter reading of TRUTH-05's literal "every lane" wording could disagree — flagging for
   awareness.

2. **`mix ci` does not run green in this sandbox** (plan 141-06's own internal Verification Group 5,
   not a ROADMAP success criterion). Independently reproduced: it fails at "Unchecked dependencies for
   environment dev" — a `mix deps.get`/network-availability gap in this sandbox, not a code or
   assertion failure. Format, compile, and Credo all independently confirmed to pass first. The
   phase's own substitute evidence (a live, non-doc-only, `workflow_dispatch`-forced CI run showing
   24/24 jobs correctly classified, with only the pre-existing, unrelated `Demo Browser Evidence` job
   red and not a member of `ci_green.needs`) was independently re-derived by this verification, not
   merely copied from the SUMMARY, and is adequate substitute evidence for this phase's goal.

### Human Verification Required

None. All must-haves were machine-verifiable and were independently re-executed against the live
repository and the live GitHub API by this verification pass (not merely re-read from SUMMARY.md
transcripts).

### Gaps Summary

No gaps. All 5 ROADMAP success criteria and all 5 requirement IDs (TRUTH-09, TRUTH-07, TRUTH-05,
CONFORM-04, HIST-01) are independently verified against the actual codebase and live GitHub state,
not merely asserted by the SUMMARYs. The two items under "Notes" above are recorded for transparency
and are not blocking: one is an explicitly-decided scope boundary carried forward to a later phase,
the other is a local sandbox limitation with adequate substitute evidence that was itself
independently reproduced during this verification.

---
_Verified: 2026-07-28_
_Verifier: Claude (gsd-verifier)_
