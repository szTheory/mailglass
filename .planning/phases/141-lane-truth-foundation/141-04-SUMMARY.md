---
phase: 141-lane-truth-foundation
plan: 04
subsystem: infra
tags: [ci, github-actions, ecto-free, elixir, ex-unit, hex-publish]

# Dependency graph
requires:
  - phase: 141-01
    provides: "the lane-contract meta-test seam (test/support/ci_yaml.ex, test/scripts/lane_classification_drift_test.exs scaffold, mix verify.ci_lane_contract alias)"
  - phase: 141-03
    provides: "the conformance_gates job split from credo_strict, landing 'Design System Conformance (shell gates)' as the 24th ci.yml job"
provides:
  - "Mailglass.CILanes classification axis: advisory_classified_lanes/0 (4), publish_gating_lanes/0 (13), structural_lanes/0 (2), all_classified_lanes/0 (24, no duplicates)"
  - "gate-ci-green rewritten to classify every ci.yml job through one classify/1 enumerating all four buckets — the '/ Advisory \\(/' naming-convention matcher is gone"
  - "four set-equality meta-tests binding Mailglass.CILanes to publish-hex.yml's JS arrays, with a demonstrated fail-loud property"
affects: [142-supply-chain-remediation, 143-test-harness-truth, 144-signal-drift-integrity, 141-05, 141-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Orthogonal classification axis alongside an existing parity axis in the same module, documented as 'Two independent axes' in the moduledoc so a future edit does not partition one to build the other"
    - "JS classify(name) enumerating four arrays (exact-equality for REQUIRED_LANES, prefix-match for the other three) instead of a naming-convention regex, to survive GitHub's runtime matrix-suffix appending"

key-files:
  created: []
  modified:
    - test/support/ci_lanes.ex
    - .github/workflows/publish-hex.yml
    - test/scripts/lane_classification_drift_test.exs

key-decisions:
  - "all_classified_lanes/0 composes via the public accessor functions (required_lanes() ++ advisory_classified_lanes() ++ publish_gating_lanes() ++ structural_lanes()) rather than the raw @attribute list the plan's action text sketched — this keeps each attribute's own grep-count at exactly 2 (definition + its own accessor), matching the plan's own acceptance criteria, with identical runtime output. Deviation Rule 1 (the action text and its own acceptance criteria were mutually inconsistent; the acceptance criteria's literal counts were treated as the correctness target since they are the plan's committed, checkable contract)."
  - "gate-ci-green keeps two separate core.setFailed call sites (blockingFailures for publish-gating/structural, unclassifiedFailures for the new unclassified-red case) rather than merging them, per the plan's explicit branch-by-branch design — this preserves today's exact 'non-advisory failures' message for every existing lane and adds a distinct, fix-naming message only for the genuinely new case."

requirements-completed: [TRUTH-09, TRUTH-07]

coverage:
  - id: D1
    description: "Mailglass.CILanes exposes the full classification axis (required_lanes/0=5, advisory_classified_lanes/0=4, publish_gating_lanes/0=13, structural_lanes/0=2, all_classified_lanes/0=24 with no duplicates) alongside the untouched parity axis (advisory_lanes/0 still 11)"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "mix run --no-start -e 'IO.puts(length(Mailglass.CILanes.all_classified_lanes()))' -> 24"
        status: pass
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs (4 tests, file unedited)"
        status: pass
    human_judgment: false
  - id: D2
    description: "gate-ci-green (publish-hex.yml) classifies every job via one classify/1 over four enumerated arrays; the naming-convention regex is deleted; publish posture is preserved byte-for-byte with one added diagnostic (unclassified-but-green warns)"
    requirement: "TRUTH-09"
    verification:
      - kind: unit
        ref: "actionlint .github/workflows/publish-hex.yml (no output = pass); node --check on the extracted+wrapped script block"
        status: pass
      - kind: other
        ref: "grep-based acceptance criteria in 141-04-PLAN.md Task 2 (array/function presence, isAdvisory absence, required-loop untouched, ASCII charset, 24 quoted entries)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Elixir registry and publish-hex.yml JS arrays proven string-identical in both directions by set-equality tests, with a demonstrated fail-loud property (deliberate-drift probe)"
    requirement: "TRUTH-07"
    verification:
      - kind: unit
        ref: "mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors (7 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mix verify.ci_lane_contract (24 tests, 0 failures)"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-07-28
status: complete
---

# Phase 141 Plan 04: Lane Classification Axis + gate-ci-green Rewrite Summary

**`Mailglass.CILanes` gains a four-bucket classification axis (required/advisory-classified/publish-gating/structural, 24 lanes total) orthogonal to its existing parity axis, and `gate-ci-green` reads it through one `classify/1` instead of a naming-convention regex — bound together by four set-equality meta-tests with a demonstrated fail-loud property.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-28T21:35:04Z (first task commit)
- **Completed:** 2026-07-28T21:39:54Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- `Mailglass.CILanes` now answers "what does this lane block?" for all 24 `ci.yml` jobs across four named buckets (`required_lanes/0`=5, `advisory_classified_lanes/0`=4, `publish_gating_lanes/0`=13, `structural_lanes/0`=2, `all_classified_lanes/0`=24 with zero duplicates), while the existing parity axis (`advisory_lanes/0`=11, `advisory_lanes_ci/0`, `advisory_lanes_browser/0`) is untouched byte-for-byte — proven by a zero-removed-lines diff and `ci_parity_drift_test.exs` passing unedited.
- A new "Two independent axes" `@moduledoc` section (plus a name-space-seam paragraph) documents both axes explicitly so a future edit does not partition one to build the other.
- `gate-ci-green` in `publish-hex.yml` is rewritten: `ADVISORY_LANES` now holds the 4 full display names (replacing the 2 short prefixes), plus new `PUBLISH_GATING_LANES` (13) and `STRUCTURAL_LANES` (2) arrays, matched by a single `classify(name)` function (exact equality for `REQUIRED_LANES`, prefix matching — `startsWithAny` — for the other three). The `/ Advisory \(/` naming-convention matcher is deleted; both lanes that depended on it (`Deps Audit Advisory`, `Preview Capture Advisory`) are now enumerated by full name, so neither silently promotes to publish-blocking.
- Publish posture preserved byte-for-byte: publish-gating-or-structural red still blocks with the same message; advisory red still only warns; the required-lane presence/exact-equality loop is untouched. The only new behavior is a `core.warning` diagnostic on an unclassified-but-green lane (unclassified-but-red now blocks with a message naming the fix, per TRUTH-09, instead of blocking silently via generic fall-through).
- `test/scripts/lane_classification_drift_test.exs` gained three new set-equality tests (advisory/publish-gating/structural) reusing the existing `parse_js_array/2` parser and `drift/2` helper — no second comparison path — each with an exact-size anti-vacuity guard. The negative-control test was extended to also cover `PUBLISH_GATING_LANES` using `Design System Conformance (shell gates)` (this phase's newest lane) as the removed entry.
- Ran the required deliberate-drift probe on the real file (removed `Hex Audit (Elixir 1.18 / OTP 27)` from `PUBLISH_GATING_LANES`, confirmed red, reverted, confirmed green again) — see "Deliberate-Drift Probe" below for the observed failure messages.

## Task Commits

1. **Task 1: Add the classification axis to `Mailglass.CILanes`** - `477b7b0e` (ci)
2. **Task 2: Rewrite `gate-ci-green`'s classification step** - `246e2d8f` (ci)
3. **Task 3: Bind the Elixir registry and JS arrays with set-equality assertions** - `de232444` (test)
4. **Formatting fix (mix format)** - `0333b8da` (style) — see Deviations below.

**Plan metadata:** (this commit)

## Files Created/Modified

- `test/support/ci_lanes.ex` — added `@advisory_classified_lanes` (4), `@publish_gating_lanes` (13), `@structural_lanes` (2) attributes, their accessors, `all_classified_lanes/0`, and the "Two independent axes" moduledoc section. Existing `@required_lanes`/`@advisory_lanes_ci`/`@advisory_lanes_browser` and their accessors are byte-unchanged.
- `.github/workflows/publish-hex.yml` — `gate-ci-green`'s classification step rewritten: `ADVISORY_LANES` repopulated with 4 full display names, `PUBLISH_GATING_LANES` and `STRUCTURAL_LANES` added, `isAdvisory`/`/ Advisory \(/` deleted, `classify`/`startsWithAny` added, blocking/warning branches extended for `unclassifiedFailures` and `unclassifiedGreen`. Required-lane presence loop untouched.
- `test/scripts/lane_classification_drift_test.exs` — 3 new set-equality tests + extended negative control + updated moduledoc.

## Decisions Made

- **`all_classified_lanes/0` composes via public accessor calls, not raw `@attribute`s directly.** The plan's action text sketched `@required_lanes ++ @advisory_classified_lanes ++ @publish_gating_lanes ++ @structural_lanes`, but the plan's own acceptance criteria required `grep -c '@publish_gating_lanes'` (etc.) to return exactly `2` (attribute definition + its own accessor body) — a literal `@attribute` reference inside `all_classified_lanes/0` would make that `3`. Composing from `required_lanes()`/`advisory_classified_lanes()`/`publish_gating_lanes()`/`structural_lanes()` instead produces byte-identical runtime output and satisfies both the semantic intent and the literal, checkable acceptance criteria. (Deviation Rule 1 — the plan text was internally inconsistent; the acceptance criteria is the plan's committed, machine-checkable contract, so it took precedence.)
- **Two separate `core.setFailed` call sites in `gate-ci-green`** (`blockingFailures` for publish-gating/structural, `unclassifiedFailures` for the new unclassified-red case) rather than one merged branch, matching the plan's explicit design — this keeps the existing "non-advisory failures" message byte-identical for every lane that already triggers it today, and adds a distinct TRUTH-09-naming message only for the genuinely new case.
- **`unclassifiedGreen` warns, never fails.** Per the plan's posture note (D-02: preserve today's publish posture byte-for-byte), a green-but-unclassified lane only produces a `core.warning`; the hard failure for "a job was added without classification" lives in the meta-test (this plan's Task 3), which runs on the PR that adds the lane.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug/tooling] `mix format` reflow on `all_classified_lanes/0`'s composition line**
- **Found during:** post-Task-3 `mix ci.fast` run
- **Issue:** `mix ci.fast`'s `mix format --check-formatted` step failed — the `do: required_lanes() ++ ...` line exceeded the formatter's line-length limit.
- **Fix:** Ran `mix format test/support/ci_lanes.ex`; the formatter wrapped the expression across three lines. No semantic change.
- **Files modified:** `test/support/ci_lanes.ex`
- **Verification:** `mix ci.fast` re-run, exit 0.
- **Committed in:** `0333b8da`

---

**Total deviations:** 1 auto-fixed (Rule 1, tooling/formatting), plus the `all_classified_lanes/0` composition-style decision documented above (a plan-internal-consistency correction, not a scope change).
**Impact on plan:** No scope creep. Both changes are mechanical/cosmetic; runtime behavior and the four bucket contents are exactly as specified in the plan.

## Deliberate-Drift Probe

Per Task 3's acceptance criteria, removed `'Hex Audit (Elixir 1.18 / OTP 27)',` from `PUBLISH_GATING_LANES` in `.github/workflows/publish-hex.yml`, ran `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs`, and observed:

```
1) test PUBLISH_GATING_LANES (publish-hex.yml) set-equals Mailglass.CILanes.publish_gating_lanes/0 (Mailglass.Scripts.LaneClassificationDriftTest)
   test/scripts/lane_classification_drift_test.exs:76
   expected exactly 13 entries parsed from publish-hex.yml's PUBLISH_GATING_LANES array — parser or file format changed
   code: assert MapSet.size(publish_gating_from_js) == 13,
   stacktrace:
     test/scripts/lane_classification_drift_test.exs:80: (test)

2) test negative control: removing one entry from the parsed REQUIRED_LANES set makes the drift comparison report it (fail-loud property is tested) (Mailglass.Scripts.LaneClassificationDriftTest)
   test/scripts/lane_classification_drift_test.exs:153
   sanity check failed: PUBLISH_GATING_LANES and Mailglass.CILanes.publish_gating_lanes/0 should agree before the injected-breakage assertion runs
   code: assert drift(publish_gating_from_js, @publish_gating_lanes) == {MapSet.new(), MapSet.new()},
   stacktrace:
     test/scripts/lane_classification_drift_test.exs:193: (test)

7 tests, 2 failures
```

Reverted via `git checkout -- .github/workflows/publish-hex.yml`; re-ran the same test file and confirmed `7 tests, 0 failures`. The fail-loud property is demonstrated on the real file, not assumed.

## Issues Encountered

None beyond the formatting deviation documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix verify.ci_lane_contract` (24 tests, 0 failures) and `mix ci.fast` (exit 0) are both green.
- `test/scripts/ci_parity_drift_test.exs` remains unedited and green (4 tests, 0 failures) — MIXCI-03's local-parity guarantee is unchanged.
- Plan 141-05 (per the phase's artifact table) can now build its "no job can silently sit unclassified" hard-fail meta-test and matrix-lane prefix-safety assertions directly on `Mailglass.CILanes.all_classified_lanes/0` and the four `publish-hex.yml` arrays landed here.
- Plan 141-06 can transcribe `MAINTAINING.md`'s § "Required Checks" 24-row disposition table directly from this plan's four buckets — no further Elixir/JS reconciliation needed.

---
*Phase: 141-lane-truth-foundation*
*Completed: 2026-07-28*

## Self-Check: PASSED

- FOUND: `.planning/phases/141-lane-truth-foundation/141-04-SUMMARY.md`
- FOUND: `477b7b0e` (Task 1)
- FOUND: `246e2d8f` (Task 2)
- FOUND: `de232444` (Task 3)
- FOUND: `0333b8da` (format fix)
