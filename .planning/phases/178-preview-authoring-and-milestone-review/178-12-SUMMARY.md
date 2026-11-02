---
phase: 178-preview-authoring-and-milestone-review
plan: "12"
subsystem: testing
tags: [exunit, contract-test, planning-docs, state-md, ci-green]

requires:
  - phase: 177-readable-health-and-coherent-account-navigation
    provides: "deferred-items.md record of the two state_md_contract_test failures on local main"
provides:
  - "STATE.md prohibitions retained; permanent DOCS-01 facts re-homed to the v2.8 requirements record with mutation teeth"
  - "Root core lanes (support_contract_core, core_deterministic_suite) green except a proven local-only phase_164 failure"
affects: [178-08, ci-green, release-candidate]

actuals:
  tokens: 1900
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Section-scoped contract extractor that raises on a missing marker (no vacuous pass)"
    - "Pure violations function plus in-test String.replace mutations as teeth"

key-files:
  created: []
  modified:
    - test/mailglass/state_md_contract_test.exs

key-decisions:
  - "D-16: positive permanent-fact assertions move from tool-written STATE.md to the DOCS-01 entry of .planning/milestones/v2.8-REQUIREMENTS.md; prohibitions stay on STATE.md"
  - "Assertions are scoped to the text between **DOCS-01** and **DOCS-02**, and a missing marker raises ArgumentError"

requirements-completed: ["UIQ-08"]

coverage:
  - id: D1
    description: "state_md_contract_test no longer fails on the committed tool-written STATE.md; permanent facts enforced at the DOCS-01 record"
    requirement: "UIQ-08"
    verification:
      - kind: unit
        ref: "test/mailglass/state_md_contract_test.exs (12 tests, 0 failures, --seed 0)"
        status: pass
      - kind: other
        ref: "real-file mutation f733fc22 -> f733fc2X turned the clean-state test and the f733fc22 teeth test red, then reverted"
        status: pass
    human_judgment: false
  - id: D2
    description: "Root core lanes green at the committed HEAD apart from the proven local-only phase_164 failure"
    requirement: "UIQ-08"
    verification:
      - kind: integration
        ref: "mix verify.support_contract.core -> 1 property, 140 tests, 0 failures, 1 skipped"
        status: pass
      - kind: integration
        ref: "MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors --seed 0 -> 23 properties, 2246 tests, 1 failure (phase_164:261, local-only), 27 excluded, 7 skipped"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-29
status: complete
plan_head_before: 8c02bf7e1a0d29c8198cafa71273debaa8d68d39
plan_head_after: c1b279779acdb151c9c20af6814e6dc0f425efd7
commits: 1
---

# Phase 178 Plan 12: State MD Contract Re-home Summary

**The two failing positive STATE.md assertions now live against the DOCS-01 entry of the v2.8 requirements record, section-scoped and mutation-proven, while the three STATE.md prohibitions stay on STATE.md; the core suite's only remaining red is a proven local-only `.gsd/.gitignore` artifact.**

## Performance

- **Duration:** about 12 min (2026-10-29, 13:03Z to 13:14Z)
- **Tasks:** 2 (1 tracer commit, 1 verification-only)
- **Files modified:** 1

## Accomplishments

- Removed the two positive tests that asserted `gh issue list` and `f733fc22` against the tool-written `.planning/STATE.md`. STATE.md was never edited.
- Added `@durable_record_path`, `docs01_section/1` (raises `ArgumentError` naming `**DOCS-01**` or `**DOCS-02**` when a marker is missing) and `durable_fact_violations/1` (names `f733fc22`, `d65a1aa8`, `gh pr list`, `gh issue list`, `#222 closed`, `#129 closed`).
- New describe "permanent facts live in the v2.8 DOCS-01 record": 1 clean-state test, 6 teeth tests (one per fact), 2 missing-marker tests.
- Rewrote the moduledoc comment to say why the facts moved.

## Task Commits

1. **Task 1: re-home permanent-fact assertions** - `c1b27977` (test)
2. **Task 2: root core lanes on committed HEAD** - no file changes (verification and this record only)

## Test counts and TDD evidence

| Stage | Result |
|-------|--------|
| Baseline at HEAD 8c02bf7e (`mix test test/mailglass/state_md_contract_test.exs --seed 0`) | 5 tests, 2 failures (:38 `gh issue list`, :52 `f733fc22`) |
| RED: new describe added before the helpers existed | Compile error, `undefined function docs01_section/1` and `durable_fact_violations/1` |
| After | 12 tests, 0 failures (`--seed 0 --warnings-as-errors`) |

### Real-file mutation

`sed -i.bak 's/f733fc22/f733fc2X/' .planning/milestones/v2.8-REQUIREMENTS.md`, then the scoped test: 12 tests, 2 failures.

- `test permanent facts live in the v2.8 DOCS-01 record the real DOCS-01 entry carries every permanent fact and live-state pointer` (left: `["f733fc22"]`)
- `test permanent facts live in the v2.8 DOCS-01 record teeth: removing f733fc22 from the DOCS-01 entry is named as a violation` (its premise `refute mutated == section` also trips, since the literal was already absent)

Reverted with `mv ...v2.8-REQUIREMENTS.md.bak ...v2.8-REQUIREMENTS.md`; `git diff --quiet HEAD -- .planning/milestones/v2.8-REQUIREMENTS.md` exited 0 afterwards. No `git stash` or broad checkout was used.

## Root lane results (committed HEAD c1b27977, Postgres at /tmp:5432 accepting)

| Command | Summary line | Wall time |
|---------|--------------|-----------|
| `mix verify.support_contract.core` | `1 property, 140 tests, 0 failures, 1 skipped` (exit 0) | 2 s (build already warm) |
| `MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors --seed 0` | `23 properties, 2246 tests, 1 failure, 27 excluded, 7 skipped` (exit 2) | 471 s |

The single failure is `test/scripts/phase_164_repository_truth_test.exs:261`, "git runtime rules do not conceal the retired finalize-phase extension paths" (the line is current; the grep prints `261:`). It is unrelated to this plan's file and is local-only, with these four proofs:

1. `git ls-files .gsd` prints nothing, so no `.gsd` path is tracked and a CI checkout contains no `.gsd/.gitignore`.
2. `git ls-files --error-unmatch .gsd/.gitignore` exits 1, so the ignore file is untracked and local.
3. `git check-ignore --no-index -v .gsd/extensions/finalize-phase/index.ts` prints `.gsd/.gitignore:1:*	.gsd/extensions/finalize-phase/index.ts`, so the rule ignoring it lives in that untracked local file.
4. `grep -nxF '!/.gsd/extensions/finalize-phase/' .gitignore` prints `59:!/.gsd/extensions/finalize-phase/`, so with tracked rules only the path is not ignored, which is what the test asserts.

The plan's second automated verify (the `.gsd` local-only chain) exits 0. The local `.gsd/.gitignore` was not touched. The test cannot reproduce in CI.

## Deviations from Plan

### Auto-fixed Issues

None to code. One note:

**1. [Attribution] Commit trailer**
- **Found during:** Task 1 commit
- **Issue:** The plan's commit discipline names the trailer `Co-Authored-By: Claude Opus 5.5`; the session's attribution instruction names `Claude Sonnet 5.5`, which is the model that actually authored the commit.
- **Fix:** Used `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. No acceptance criterion depends on the trailer.

**Total deviations:** 0 code deviations, 1 trailer substitution. **Impact:** none.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. Test-only change; no new endpoints, auth paths or schema.

## Issues Encountered

- During authoring the final file briefly held a duplicate describe and a duplicate `@durable_record_path` attribute (an artifact of building from the red copy); both were removed before the first green run and before the commit.

## Self-Check: PASSED

- `test/mailglass/state_md_contract_test.exs` exists; commit `c1b27977` is an ancestor of HEAD.
- `git show --stat c1b27977` lists only `test/mailglass/state_md_contract_test.exs`.
- `git diff --quiet HEAD -- .planning/STATE.md .planning/milestones/v2.8-REQUIREMENTS.md` exits 0.
- `grep -c 'v2.8-REQUIREMENTS.md'` = 2; `14 open PR` = 3; `refute` = 6 (baseline 4); no STATE.md-targeted `gh issue list` assertion remains.
- `mix format --check-formatted` passes for the file; the commit subject starts `test(`.
