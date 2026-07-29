---
phase: 142-supply-chain-remediation-gating
plan: 04
subsystem: infra
tags: [supply-chain, hex-audit, deps-audit, ci, ci-lanes, merge-gating, d-04, d-05, d-06, d-07, d-08, d-09]

# Dependency graph
requires:
  - phase: 142-03
    provides: D-14's blocking checkpoint evidence (live CI detected-and-suppressed run + local negative control), clearing this plan to proceed
provides:
  - "Hex Audit" and "Deps Audit" (renamed from "Deps Audit Advisory") are merge-gating — both are ci.yml's ci_green.needs members AND Mailglass.CILanes.required_lanes/0 members
  - deps_audit_advisory's continue-on-error: true deleted, so a red finding on that job now actually blocks needs.*.result and therefore ci_green
  - MAINTAINING.md's disposition table reflects the promotion (both rows: advisory/publish-gating -> required, promote -> keep-with-reason), still exactly 24 rows
  - lane_classification_drift_test.exs and ci_parity_drift_test.exs updated to the post-promotion bucket shape (7 required + 3 advisory + 12 publish-gating + 2 structural = 24), including the renamed-lane matcher/stale-lane references those meta-tests independently assert
affects: [142-05-triage-docs, 143-test-harness-truth, 144-signal-drift-integrity]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Atomic nine-site promotion commit (D-04): a lane's classification move across three declaration surfaces (ci.yml, publish-hex.yml, MAINTAINING.md) plus their meta-tests' hardcoded counts must land in exactly one commit, verified post-hoc via `git log -1 --stat` rather than trusted by convention — the same discipline the registry-disagreement defect (Phase 141) exists to prevent from recurring."

key-files:
  created:
    - .planning/phases/142-supply-chain-remediation-gating/142-04-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/publish-hex.yml
    - MAINTAINING.md
    - test/scripts/lane_classification_drift_test.exs
    - test/scripts/ci_parity_drift_test.exs
    - test/support/ci_lanes.ex

key-decisions:
  - "Two rename-consistency edits beyond the plan's literal nine-site enumeration were made in the same commit, as Rule 1 bug fixes directly caused by the D-06 rename: ci_parity_drift_test.exs's matcher_for map key and its separate matcher_lanes stale-reference MapSet both still said the old 'Deps Audit Advisory (Elixir 1.18 / OTP 27)' string, which the plan's own CONTEXT.md D-06 'Non-.planning blast radius' list explicitly names (ci_parity_drift_test.exs:114,188) — leaving them unrenamed would have failed the 'lanes_without_matcher' and 'stale' anti-vacuity assertions in that same test file, since the renamed lane now flows through required_lanes() into all_lanes() with no matcher."
  - "Reworded MAINTAINING.md's deps_audit_advisory reason text to avoid the literal substring 'Deps Audit Advisory' (used 'the misleading \"Advisory\" suffix' instead) after discovering the plan's own acceptance criterion ('grep -c \"Deps Audit Advisory\" ... MAINTAINING.md ... returns 0') would otherwise fail against explanatory prose referencing the old name — the criterion is about zero live references to the retired display name, not zero mentions of the rename having happened."
  - "Fixed three additional stale hardcoded-count doc comments/strings in the same files being edited for the nine sites (ci_lanes.ex's required_lanes/0 doc 'five'->'seven', publish-hex.yml's REQUIRED_LANES comment 'five lanes'->'seven lanes', ci_parity_drift_test.exs's moduledoc 'exactly 5'->'exactly 7', lane_classification_drift_test.exs's 24-entries breakdown string '5 required + 4 advisory + 13 publish-gating'->'7 required + 3 advisory + 12 publish-gating') as Rule 1 fixes — these are the same stale-comment defect class D-09 targets, just adjacent occurrences the plan's nine-site enumeration didn't itemize individually."

patterns-established: []

requirements-completed: [VULN-03]

coverage:
  - id: D1
    description: "Hex Audit and Deps Audit are both merge-gating: present in ci.yml's ci_green.needs, present in Mailglass.CILanes.required_lanes/0, and no longer masked by continue-on-error — verified structurally via git log -1 --stat plus the drift meta-test suite, not assumed."
    requirement: "VULN-03"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs (40 tests total across test/scripts/, 0 failures)"
        status: pass
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs"
        status: pass
      - kind: other
        ref: "git log -1 --stat 34702fde — shows exactly one commit touching all six planned files"
        status: pass
    human_judgment: false
  - id: D2
    description: "All nine D-05 edit sites landed in exactly one atomic commit (D-04), not split across commits."
    requirement: "VULN-03"
    verification:
      - kind: other
        ref: "git diff HEAD~1 -- scripts/setup_branch_protection.sh (empty, D-06 untouched); git diff --stat shows 6 files changed in commit 34702fde"
        status: pass
    human_judgment: false
  - id: D3
    description: "No HIGH-severity merge threshold introduced anywhere in the commit — the gate still blocks on any non-allowlisted finding (D-08)."
    requirement: "VULN-03"
    verification:
      - kind: other
        ref: "git diff HEAD~1 -- mix.exs test/scripts/ci_parity_drift_test.exs | grep -iE 'severity|HIGH' (no matches)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Mailglass.CILanes.all_classified_lanes/0 still totals exactly 24 entries after the promotion (5+4+13+2 -> 7+3+12+2); MAINTAINING.md's disposition table still parses to exactly 24 rows."
    requirement: "VULN-03"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs 'ci.yml parses to exactly 24 jobs and all_classified_lanes/0 returns exactly 24 distinct names' and 'MAINTAINING.md's disposition table parses to exactly 24 non-empty rows (anti-vacuity)'"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-07-29
status: complete
---

# Phase 142 Plan 04: The Atomic Merge-Gating Promotion Summary

**Hex Audit and Deps Audit (renamed from "Deps Audit Advisory") promoted from publish-gating/advisory to merge-gating in one atomic commit — nine D-05 edit sites across ci.yml, ci_lanes.ex, publish-hex.yml, MAINTAINING.md, and two drift meta-tests, with continue-on-error deleted so the promotion actually blocks PR merges.**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-07-29T04:30:00Z
- **Completed:** 2026-07-29T04:52:00Z
- **Tasks:** 1 (`type="auto"`, deliberately singular per D-04)
- **Files modified:** 6 (plus this SUMMARY)

## Accomplishments

- `ci.yml`'s `ci_green.needs` and its shell result-loop both gained `hex_audit` and `deps_audit_advisory` — the two audit lanes now genuinely block a PR merge, not just a Hex publish.
- `deps_audit_advisory`'s `continue-on-error: true` deleted (D-07) — without this, the `needs:` addition alone would have been cosmetic, since job-level `continue-on-error` forces `needs.*.result` to `success` regardless of the job's real conclusion.
- The stale `isAdvisory()` comment block deleted and replaced with an accurate one-liner (D-09) — Phase 141 already removed the `isAdvisory()` function this comment described.
- `deps_audit_advisory`'s display name renamed from `Deps Audit Advisory (Elixir 1.18 / OTP 27)` to `Deps Audit (Elixir 1.18 / OTP 27)` (D-06) — a merge-gating lane named "Advisory" is exactly the signal-honesty defect this milestone exists to fix.
- `Mailglass.CILanes`'s four buckets moved both lanes into `@required_lanes` and out of `@advisory_lanes_ci`, `@advisory_classified_lanes`, and `@publish_gating_lanes` (5+4+13+2 → 7+3+12+2, still 24 total, verified by `all_classified_lanes/0`'s totality test).
- `publish-hex.yml`'s `REQUIRED_LANES`, `ADVISORY_LANES`, and `PUBLISH_GATING_LANES` arrays mirrored the same move.
- `MAINTAINING.md`'s two disposition rows flipped in place (classification `advisory`/`publish-gating` → `required`, disposition `promote` → `keep-with-reason`, with reason text explaining the promotion) — table stayed exactly 24 rows, edited in place per the plan's constraint.
- `lane_classification_drift_test.exs`'s three hardcoded bucket-size assertions updated (`ADVISORY_LANES` 4→3, `PUBLISH_GATING_LANES` 13→12, `REQUIRED_LANES` 5→7); `ci_parity_drift_test.exs`'s `required_lanes()` anti-vacuity count updated (5→7).
- Landed as exactly one commit (`34702fde`), touching all six files the plan's frontmatter listed — verified structurally via `git log -1 --stat`, not assumed.

## Task Commits

1. **Task 1: The atomic promotion — nine sites, one commit** - `34702fde` (ci)

**Plan metadata:** (this commit — see below)

_This plan is deliberately one task, not 2-3, per D-04: splitting the nine sites across multiple tasks would have split the commit too, reproducing the exact registry-disagreement defect Phase 141 closed._

## Files Created/Modified

- `.github/workflows/ci.yml` - `ci_green.needs` + result-loop gained `hex_audit`/`deps_audit_advisory`; `continue-on-error: true` and the stale `isAdvisory()` comment deleted from `deps_audit_advisory`; its display name renamed to `Deps Audit (Elixir 1.18 / OTP 27)`
- `test/support/ci_lanes.ex` - `Mailglass.CILanes`'s four buckets updated (both lanes moved into `@required_lanes`); `required_lanes/0`'s stale doc count fixed ("five" → "seven")
- `.github/workflows/publish-hex.yml` - `REQUIRED_LANES`/`ADVISORY_LANES`/`PUBLISH_GATING_LANES` mirrored the same move; adjacent stale doc-comment count fixed ("five lanes" → "seven lanes")
- `MAINTAINING.md` - `deps_audit_advisory` and `hex_audit` disposition rows flipped in place (still 24 rows total)
- `test/scripts/lane_classification_drift_test.exs` - three hardcoded bucket-size assertions updated; stale 24-entries breakdown string in the totality test's error message updated
- `test/scripts/ci_parity_drift_test.exs` - `required_lanes()` anti-vacuity count updated; the renamed lane's matcher-map key and its separate stale-reference `matcher_lanes` MapSet entry both updated from `Deps Audit Advisory (...)` to `Deps Audit (...)`; moduledoc's stale count fixed

## Decisions Made

- **Extended the rename beyond the plan's literal nine-site list to two matcher references in `ci_parity_drift_test.exs`** (its `matcher_for` map key at what was line 114, and its `matcher_lanes` MapSet at what was line 188). The plan's own `142-CONTEXT.md` D-06 "Non-`.planning` blast radius" already named these exact two locations; leaving them unrenamed would have made the renamed `Deps Audit (Elixir 1.18 / OTP 27)` lane — now reachable via `required_lanes()` into `ci_parity_drift_test.exs`'s `all_lanes/0` — fail the "no lane silently ignored" and "no stale matcher" anti-vacuity assertions in that same test file. This is Rule 1 (auto-fix bugs): the rename created a live drift that the plan's own meta-tests would have caught, so fixing it inline in the same commit was required for the acceptance criteria (`MIX_ENV=test mix test test/scripts/ --warnings-as-errors` exits 0) to actually hold.
- **Reworded MAINTAINING.md's `deps_audit_advisory` reason text to avoid the literal substring "Deps Audit Advisory."** The plan's own acceptance criteria include `grep -c "Deps Audit Advisory" .github/workflows/ci.yml test/support/ci_lanes.ex .github/workflows/publish-hex.yml MAINTAINING.md` returning `0`. My first draft of the reason text explained the rename by quoting the old name, which violated that literal criterion. Reworded to "the misleading 'Advisory' suffix" — same substance, zero literal occurrences of the retired name.
- **Fixed three adjacent stale-count doc comments/strings** (`ci_lanes.ex`'s `required_lanes/0` doc, `publish-hex.yml`'s `REQUIRED_LANES` comment, `ci_parity_drift_test.exs`'s moduledoc, `lane_classification_drift_test.exs`'s 24-entries breakdown error string) that said "five"/"5+4+13+2" and would have been factually wrong post-promotion. These are the same stale-comment defect class D-09 explicitly targets (a comment describing a mechanism/count that no longer holds) — Rule 1, fixed inline in the files already being edited for the nine sites, no new files touched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Renamed-lane matcher references in `ci_parity_drift_test.exs` left stale by the D-06 rename**
- **Found during:** Task 1, immediately after making the nine planned edits, while tracing what `all_lanes()` would resolve to post-rename
- **Issue:** `ci_parity_drift_test.exs`'s `matcher_for` map (keyed by lane display name) and its separate `matcher_lanes` stale-reference `MapSet` both still keyed/listed the old string `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"`. Since the lane's canonical name changed to `"Deps Audit (Elixir 1.18 / OTP 27)"` and now flows into `all_lanes()` via `required_lanes()`, the renamed lane would have had no matcher (failing "no lane silently ignored") while the old string would have been flagged as a stale reference (failing "no matcher may reference a lane absent from ci_lanes").
- **Fix:** Renamed both occurrences to `"Deps Audit (Elixir 1.18 / OTP 27)"`.
- **Files modified:** `test/scripts/ci_parity_drift_test.exs`
- **Verification:** `MIX_ENV=test mix test test/scripts/ --warnings-as-errors` — 40 tests, 0 failures.
- **Committed in:** `34702fde` (part of the single Task 1 commit)

**2. [Rule 1 - Bug] Stale hardcoded-count doc comments/strings adjacent to the nine edit sites**
- **Found during:** Task 1, while reviewing the full diff before staging
- **Issue:** Four doc comments/error-message strings in the files already being edited stated the pre-promotion bucket counts ("five required lanes", "5+4+13+2", "exactly 5") that would be factually wrong the moment this commit lands — the same stale-comment defect class D-09 explicitly names.
- **Fix:** Updated `ci_lanes.ex`'s `required_lanes/0` doc, `publish-hex.yml`'s `REQUIRED_LANES` matching-rule comment, `ci_parity_drift_test.exs`'s moduledoc, and `lane_classification_drift_test.exs`'s 24-entries assertion error string to the post-promotion counts.
- **Files modified:** `test/support/ci_lanes.ex`, `.github/workflows/publish-hex.yml`, `test/scripts/ci_parity_drift_test.exs`, `test/scripts/lane_classification_drift_test.exs`
- **Verification:** `MIX_ENV=test mix test test/scripts/ --warnings-as-errors` — 40 tests, 0 failures (these were error-message strings only, not assertions, so they could not have failed a test, but leaving them would have shipped inaccurate documentation in the same commit that claims to fix signal honesty).
- **Committed in:** `34702fde` (part of the single Task 1 commit)

**3. [Rule 1 - Bug] MAINTAINING.md reason text initially violated the plan's own "no leftover old name" acceptance criterion**
- **Found during:** Task 1, while running the plan's literal acceptance-criteria grep checks before committing
- **Issue:** My first draft of the `deps_audit_advisory` disposition row's reason text explained the rename by quoting the retired name ("renamed from 'Deps Audit Advisory' to 'Deps Audit'"), which made `grep -c "Deps Audit Advisory" ... MAINTAINING.md` return `1` instead of the plan's required `0`.
- **Fix:** Reworded to describe the rename without repeating the retired string ("renamed to drop the misleading 'Advisory' suffix from its display name").
- **Files modified:** `MAINTAINING.md`
- **Verification:** Re-ran `grep -c "Deps Audit Advisory" .github/workflows/ci.yml test/support/ci_lanes.ex .github/workflows/publish-hex.yml MAINTAINING.md` — all four return `0`. Re-ran the full drift test suite after the reword — still 40 tests, 0 failures.
- **Committed in:** `34702fde` (part of the single Task 1 commit, caught before the commit was made)

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs the D-06 rename would otherwise have introduced or left stale)
**Impact on plan:** All three fixes were necessary for the plan's own stated acceptance criteria to hold (drift tests green, zero leftover old-name references) and for documentation accuracy in the exact commit that claims to fix signal-honesty defects. No scope creep — all edits stayed within the six files the plan already targeted; no new files were touched, and `scripts/setup_branch_protection.sh` and `mix.exs` remain untouched per D-06.

## Issues Encountered

None beyond the deviations documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **ROADMAP criterion 2 is now structurally true:** both `Hex Audit` and `Deps Audit` are merge-gating (`ci_green.needs` + `Mailglass.CILanes.required_lanes/0` members), and no HIGH-severity threshold was introduced anywhere — the gate blocks on any non-allowlisted finding, matching `mailglass.publish.check`'s existing block-on-any semantics.
- **No lane other than these two changed classification** — `MAINTAINING.md`'s 24-row disposition table is preserved everywhere else; only the two `promote` rows Phase 141 recorded were touched, edited in place.
- **142-05 (VULN-04 triage docs)** is now unblocked to add its `## Dependency Advisory Triage` section adjacent to `## Security Response SLA` in `MAINTAINING.md` — Wave 2 (this plan) is done, and D-13's wave ordering sequences 142-05 after this plan's `MAINTAINING.md` table edit so the two never edit that file concurrently.
- **Verification commands run and green:** `MIX_ENV=test mix test test/scripts/ --warnings-as-errors` (40 tests, 0 failures), `mix verify.ci_lane_contract` (same 40 tests, 0 failures), `MIX_ENV=test mix test test/scripts/conformance_advisory_test.exs --warnings-as-errors` (3 tests, 0 failures — sanity check that D-07's deletion didn't collaterally touch the unrelated conformance step), `mix ci.fast` (format/compile/compile-no-optional-deps/credo --strict, exit 0).
- **git status --short** shows only the pre-existing, orchestrator-owned `.planning/config.json` modification (auto-mode flag) untouched, per instruction — no other stray changes.

## Self-Check: PASSED

- `git log -1 --stat` at `34702fde` shows exactly 6 files changed: `.github/workflows/ci.yml`, `.github/workflows/publish-hex.yml`, `MAINTAINING.md`, `test/scripts/ci_parity_drift_test.exs`, `test/scripts/lane_classification_drift_test.exs`, `test/support/ci_lanes.ex` — matches the plan's `files_modified` frontmatter exactly.
- `git diff HEAD~1 -- scripts/setup_branch_protection.sh` — empty (D-06 untouched).
- `git diff HEAD~1 -- mix.exs test/scripts/ci_parity_drift_test.exs | grep -iE "severity|HIGH"` — no matches (D-08 negative confirmation).
- `MIX_ENV=test mix test test/scripts/ --warnings-as-errors` — 40 tests, 0 failures (re-verified after all fixes, including the MAINTAINING.md reword).
- This SUMMARY.md file exists at the path above (verified via the Write tool's success).

---
*Phase: 142-supply-chain-remediation-gating*
*Completed: 2026-07-29*
