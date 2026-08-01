---
phase: 141-lane-truth-foundation
plan: 05
subsystem: infra
tags: [ci, github-actions, ex-unit, hex-publish, meta-test]

# Dependency graph
requires:
  - phase: 141-01
    provides: "the lane-contract meta-test seam (test/support/ci_yaml.ex, test/scripts/lane_classification_drift_test.exs scaffold, mix verify.ci_lane_contract alias)"
  - phase: 141-04
    provides: "the four-bucket classification axis on Mailglass.CILanes (required/advisory-classified/publish-gating/structural, all_classified_lanes/0) and gate-ci-green's classify/1 rewrite"
provides:
  - "A build-breaking assertion that every ci.yml job is classified: MapSet.new(CIYaml.job_names/1 values) set-equals CILanes.all_classified_lanes/0, both directions named on failure"
  - "Exact-count anti-vacuity guards (24 ci.yml jobs == 24 classified lanes == 24 distinct strings)"
  - "A posture guard proving publish-hex.yml's required-lane presence loop is still intact (source-text assertion, not behavior)"
  - "A negative control proving the drift comparison fails loud, not vacuously, when a structural job (Detect Non-Doc Changes) is removed from the parsed set"
  - "Prefix non-collision, exactly-one-bucket (bare + synthetic matrix-suffix forms), matrix-lane required-array exclusion, printable-ASCII/no-'/no-| charset, and drift/2 order-independence assertions — all mirroring gate-ci-green's classify/1 via a private classify_lane_buckets/1 helper"
affects: [141-06, 142-supply-chain-remediation, 143-test-harness-truth, 144-signal-drift-integrity]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "classify_lane_buckets/1 as an Elixir mirror of gate-ci-green's classify/1 (exact-match for required, prefix-match for the rest), returning ALL matching buckets (not first-match-wins) so tests can assert the count is exactly one"
    - "Synthetic matrix-suffix probing (' (1.18, 27)', ' (22)') as the only static check that can catch an F1-class runtime-name misclassification, since the runtime suffix never appears in ci.yml source"

key-files:
  created: []
  modified:
    - test/scripts/lane_classification_drift_test.exs

key-decisions:
  - "The 'exactly one bucket' synthetic-suffix probe is scoped to the 19 non-required (prefix-matched) lanes, not all 24. required_lanes/0 is matched by EXACT equality by design (RESEARCH F1), and the separate matrix-exact-match-safety test guards the invariant that no required lane ever declares a strategy: block — so a required lane can never legitimately carry a runtime matrix suffix. Applying the suffix to a required lane would assert a property that must be FALSE (zero buckets, not one) and would contradict that guarantee rather than model a genuine F1 hazard for those 5 lanes. (Deviation Rule 1 — the plan's <must_haves> truths wording ('exactly one of the four buckets prefix-matches it,' applied uniformly to all 24+suffixed) and its <action> instructions ('exact equality against required_lanes/0 first') were mutually inconsistent when combined with a synthetic suffix; the <action> text's literal classify/1 mirror was treated as correct since testing an artificial, non-occurring input (a suffixed required lane) as a failure case would contradict the phase's own matrix-safety invariant.)"
  - "Task 1 and Task 2 were committed as two separate atomic commits on the same file, reconstructed in sequence (Task 1's four tests first, verified/probed/committed; Task 2's five tests plus the classify_lane_buckets/1 helper applied and committed second) so each commit's diff maps 1:1 to its task, per task_commit_protocol."

requirements-completed: [TRUTH-09]

coverage:
  - id: D1
    description: "Adding an unclassified ci.yml job now fails the build: the set-equality assertion between Mailglass.CIYaml.job_names/1 and Mailglass.CILanes.all_classified_lanes/0 names both drift directions and the two files to edit"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'every ci.yml job display name is classified...' — mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors"
        status: pass
      - kind: other
        ref: "Deliberate-drift probe: added 'throwaway_probe_job' to ci.yml, confirmed the test failed naming 'Throwaway Drift Probe Job', reverted via git checkout --"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact-count anti-vacuity guards: 24 ci.yml jobs, 24 classified lanes, 24 distinct strings (no lane in two buckets)"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'ci.yml parses to exactly 24 jobs...'"
        status: pass
    human_judgment: false
  - id: D3
    description: "publish-hex.yml's required-lane presence loop (the '(missing)' marker and 'Delivery blocked: required CI lane(s)...' message) is still present as a structural guard against a refactor that would fold it into classify/1 and let a zero-job response pass"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'publish-hex.yml still contains the required-lane presence loop...'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Negative control: removing 'Detect Non-Doc Changes' from the parsed ci.yml job map makes drift/2 report exactly that entry, proving the comparison fails loud rather than passing vacuously"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'negative control: removing Detect Non-Doc Changes...'"
        status: pass
    human_judgment: false
  - id: D5
    description: "No classified display name is a prefix of another (adjacency safety); each of the 24 names, and the 19 non-required names with a synthetic matrix suffix, resolves to exactly one classification bucket under a helper mirroring gate-ci-green's classify/1"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'no classified display name is a prefix of another...' and 'each classified name — bare and with a synthetic matrix suffix — matches exactly one bucket'"
        status: pass
    human_judgment: false
  - id: D6
    description: "Matrix-strategy jobs (dialyzer, operator_browser_gate, preview_capture_advisory) are proven absent from required_lanes/0 and present in exactly one of the three prefix-matched buckets — the F1 landmine (a promoted matrix lane in REQUIRED_LANES reporting '(missing)' and blocking every publish) is machine-enforced"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'matrix_job_names/1 lanes are absent from required_lanes/0...'"
        status: pass
      - kind: other
        ref: "Deliberate-drift probe A: added strategy: to hex_audit + added it to REQUIRED_LANES; confirmed pre-existing matrix-exact-match-safety test FAILED naming the lane; reverted"
        status: pass
    human_judgment: false
  - id: D7
    description: "Every classified display name is printable ASCII with no ' or | characters, making byte-exact comparison across ci.yml/ci_lanes.ex/publish-hex.yml/MAINTAINING.md a proven-sound assumption"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'every classified display name is printable ASCII...'"
        status: pass
      - kind: other
        ref: "Deliberate-drift probe B: injected a Unicode en-dash into one @publish_gating_lanes entry in ci_lanes.ex; confirmed the charset test FAILED naming the exact mutated entry; reverted via git checkout --"
        status: pass
    human_judgment: false
  - id: D8
    description: "drift/2 is order-independent: reversing a registry list before building a MapSet yields an identical two-empty-set verdict, guarding against a future refactor from MapSet.difference/2 to list equality"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'drift/2 is order-independent...'"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-07-28
status: complete
---

# Phase 141 Plan 05: Lane Classification Drift Meta-Test Hardening Summary

**Nine new assertions on `test/scripts/lane_classification_drift_test.exs` (7 → 16 tests) make "no `ci.yml` job sits unclassified" a build-breaking fact: a set-equality drift assertion, exact-count anti-vacuity guards, a posture guard on `publish-hex.yml`'s required-lane loop, a negative control, and five hazard-specific guards (prefix non-collision, exactly-one-bucket under a `classify/1`-mirroring helper, matrix-lane required-array exclusion, byte-exact charset, and drift/2 order-independence) — three of them demonstrated to fail on injected real-file mutations, then reverted.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-28T21:42:14Z (STATE.md last_updated at plan start)
- **Completed:** 2026-07-28T21:51:01Z
- **Tasks:** 2/2
- **Files modified:** 1

## Accomplishments

- **Task 1 — the load-bearing assertion.** `MapSet.new(Mailglass.CIYaml.job_names(ci.yml source) |> Map.values())` now asserted set-equal to `MapSet.new(Mailglass.CILanes.all_classified_lanes())`, naming both drift directions and the two files to edit (`Mailglass.CILanes` and `publish-hex.yml`'s classification arrays) on failure. Paired with exact-count guards (`map_size(job_names) == 24`, `length(all_classified_lanes()) == 24`, `MapSet.size(MapSet.new(all_classified_lanes())) == 24`) so a lane cannot silently sit in two buckets. A source-text posture guard confirms `publish-hex.yml` still contains the `(missing)` marker and the `Delivery blocked: required CI lane(s)...` message — the structural guard against a refactor that would fold the required-lane presence check into `classify/1` and let a zero-job API response fall through to success. A negative control removes `Detect Non-Doc Changes` (the one structural job easy to overlook because it's a path filter, not a check lane) from the parsed job map and proves `drift/2` reports it, and only it.
- **Task 2 — the two hazards a comment cannot hold.** A private `classify_lane_buckets/1` helper mirrors `gate-ci-green`'s `classify/1` exactly (exact equality for required, `String.starts_with?` prefix matching for the other three), returning every matching bucket so tests can assert the count is exactly one. Built on it: (a) prefix non-collision across all ordered pairs of the 24 classified names; (b) exactly-one-bucket for each bare name, plus each of the 19 non-required names with a synthetic matrix suffix appended (` (1.18, 27)`, ` (22)`) — the only static check that can catch an F1-class runtime-name misclassification, since the runtime suffix never appears in `ci.yml` source; (c) `matrix_job_names/1`'s ≥3 matrix-strategy lanes proven absent from `required_lanes/0` and present in exactly one prefix bucket; (d) every classified name proven printable-ASCII with no `'` or `|`; (e) `drift/2` proven order-independent against a reversed registry list.
- **Three deliberate-drift probes run against the real files, observed red, and reverted**, per the plan's acceptance criteria — see "Deliberate-Drift Probes" below for the verbatim failure output.
- `MIX_ENV=test mix verify.ci_lane_contract` (33 tests, 0 failures) and `mix ci.fast` (exit 0) both green after the plan's changes.

## Task Commits

1. **Task 1: Assert every `ci.yml` job is classified** - `028929ee` (test)
2. **Task 2: Machine-enforce the matrix name-space seam, prefix safety, and byte-exact comparability** - `1bdc3124` (test)

**Plan metadata:** (this commit)

## Files Created/Modified

- `test/scripts/lane_classification_drift_test.exs` — 9 new tests (7 → 16 total) plus a new `classify_lane_buckets/1`/`maybe_add/3`/`prefix_match?/2` private helper block. No changes to `test/support/ci_yaml.ex`, `test/support/ci_lanes.ex`, `.github/workflows/publish-hex.yml`, or `.github/workflows/ci.yml` — this plan is test-only, per its `files_modified` frontmatter.

## Decisions Made

- **Scoped the synthetic-matrix-suffix "exactly one bucket" probe to the 19 non-required lanes, not all 24.** `required_lanes/0` is matched by exact equality by design, and the plan's own separate matrix-exact-match-safety test guards the invariant that no required lane ever declares a `strategy:` block. Appending a synthetic matrix suffix to a required lane's name and asserting it still resolves to exactly one bucket would assert something that must be false (0 buckets, not 1) and contradicts that guarantee — it does not model a genuine F1 hazard for those 5 lanes, since a required lane can never legitimately carry a runtime matrix suffix in the first place. Confirmed by running the literal universal-quantification version first: it failed on all 5 required lanes' suffixed forms with 0 matched buckets (expected, correct behavior), which would have been a false test failure, not a caught defect. (Deviation Rule 1 — the plan's `<must_haves>` truths wording and its `<action>` instructions described mutually inconsistent scopes once combined with a synthetic suffix; the `<action>` text's literal `classify/1` mirror — exact equality for required — was treated as authoritative since it matches the production mechanism being tested.)
- **Committed Task 1 and Task 2 as two separate atomic commits despite both modifying the same single file.** Task 1's four tests were written, verified (11 tests total), probed, and committed first; only then was Task 2's block (five tests + the `classify_lane_buckets/1` helper) applied, verified (16 tests total), probed twice, and committed second. Each commit's diff maps 1:1 to its task's `<behavior>`/`<acceptance_criteria>`, per `task_commit_protocol`.
- **Probe B's real-file mutation used a Unicode en-dash inserted into `Mix Task Tests`, not a literal hyphen replacement**, because no `@publish_gating_lanes` entry contains an ASCII hyphen character to replace. The acceptance criterion's intent — proving the charset test fails and names the mutated entry when a non-ASCII character is introduced — was satisfied; the literal "replace a hyphen" framing does not apply to any of the 13 publish-gating entries as they exist today.

## Deviations from Plan

None beyond the two decisions documented above (both Rule-1/Rule-priority-consistent, no scope change, no production code touched).

## Issues Encountered

None. All nine new tests passed on first correct implementation after the "exactly one bucket" scope correction (see Decisions Made); no auto-fix cycles beyond that design correction were needed.

## User Setup Required

None - no external service configuration required.

## Deliberate-Drift Probes (verbatim, as run against the real files)

**Probe 1 (Task 1 acceptance criteria) — unclassified job added to `ci.yml`:**

Added a `throwaway_probe_job` (`name: Throwaway Drift Probe Job`) ahead of the `changes:` job. `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs` reported (among 3 failures, this being the load-bearing one):

```
1) test every ci.yml job display name is classified in Mailglass.CILanes.all_classified_lanes/0 (TRUTH-09) (Mailglass.Scripts.LaneClassificationDriftTest)
   test/scripts/lane_classification_drift_test.exs:221
   ci.yml and Mailglass.CILanes.all_classified_lanes/0 have drifted — an unclassified job can be merged, which recreates the hidden third gating tier this phase eliminates:
     In ci.yml but not classified in CILanes (add to Mailglass.CILanes AND to publish-hex.yml's classification arrays): ["Throwaway Drift Probe Job"]
     Classified in CILanes but not present in ci.yml (stale entry — remove from Mailglass.CILanes and publish-hex.yml): []
```

Reverted via `git checkout -- .github/workflows/ci.yml`; re-ran, confirmed `11 tests, 0 failures` (at the Task-1-only point in history) / `16 tests, 0 failures` (final state).

**Probe A (Task 2 acceptance criteria) — matrix-in-required landmine:**

Added a `strategy: { matrix: { include: [{elixir: "1.18", otp: "27"}] } }` block to `ci.yml`'s `hex_audit` job, and added `'Hex Audit (Elixir 1.18 / OTP 27)'` to `publish-hex.yml`'s `REQUIRED_LANES`. `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs` reported 4 failures, including the pre-existing matrix-exact-match-safety test (landed in plan 141-01/04, exercised here as the acceptance criterion demands):

```
1) test no matrix-strategy ci.yml job's display name appears in REQUIRED_LANES (F1 safety) (Mailglass.Scripts.LaneClassificationDriftTest)
   test/scripts/lane_classification_drift_test.exs:110
   these ci.yml jobs declare a strategy: (matrix) block AND appear in publish-hex.yml's exact-equality REQUIRED_LANES array — GitHub appends matrix values to a matrix job's runtime name, so REQUIRED_LANES's exact match would never see it and every publish would report it '(missing)': ["Hex Audit (Elixir 1.18 / OTP 27)"]
```

Reverted via `git checkout -- .github/workflows/ci.yml .github/workflows/publish-hex.yml`; re-ran, confirmed `16 tests, 0 failures`.

**Probe B (Task 2 acceptance criteria) — non-ASCII character injected into `ci_lanes.ex`:**

Replaced `Mix Task Tests` with `Mix Task Tests–X` (Unicode en-dash, no ASCII hyphen existed in any `@publish_gating_lanes` entry to literally substitute — see Decisions Made) in `test/support/ci_lanes.ex`. `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs` reported 5 failures, including the charset test naming the exact mutated entry:

```
2) test every classified display name is printable ASCII with no ' or | characters (byte-exact comparability) (Mailglass.Scripts.LaneClassificationDriftTest)
   test/scripts/lane_classification_drift_test.exs:380
   'Mix Task Tests–X (Elixir 1.18 / OTP 27)' contains a non-printable-ASCII character — comparison across ci.yml, ci_lanes.ex, publish-hex.yml, and MAINTAINING.md is byte-exact and would break
```

Reverted via `git checkout -- test/support/ci_lanes.ex`; re-ran, confirmed `16 tests, 0 failures`.

`git status --porcelain` was clean after each probe's revert.

## Next Phase Readiness

- `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors` — 16 tests, 0 failures.
- `MIX_ENV=test mix verify.ci_lane_contract` — 33 tests, 0 failures.
- `mix ci.fast` — exit 0.
- `git status --porcelain` clean (all three deliberate-drift probes reverted).
- ROADMAP criterion 2 is now machine-enforced: an unclassified `ci.yml` job cannot be merged without failing `mix_task_tests` (publish-gating), and the F1 matrix name-space seam plus byte-exact comparability are proven-sound assumptions, not implicit ones.
- Plan 141-06 (the `MAINTAINING.md` § "Required Checks" 24-row disposition table) can proceed against the same `Mailglass.CILanes.all_classified_lanes/0` this plan hardened — no further meta-test work is a precondition.

---
*Phase: 141-lane-truth-foundation*
*Completed: 2026-07-28*

## Self-Check: PASSED

- FOUND: `.planning/phases/141-lane-truth-foundation/141-05-SUMMARY.md`
- FOUND: `028929ee` (Task 1)
- FOUND: `1bdc3124` (Task 2)
