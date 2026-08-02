---
phase: 141-lane-truth-foundation
plan: 02
subsystem: docs
tags: [planning-artifacts, requirements, contributing-guide, branch-protection, tooling-defect]

# Dependency graph
requires: []
provides:
  - ".planning/TOOLING-DEFECTS.md — TOOL-01 defect record (phases.clear archive omission), milestone-independent"
  - "TRUTH-09 amended in .planning/REQUIREMENTS.md to the three-bucket (+structural) classification model"
  - "CONTRIBUTING.md's branch-protection claim corrected to the true two required contexts"
affects: [141-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Milestone-independent .planning/ register (no milestone: frontmatter key) — deliberate divergence from RATCHET-GAP-REGISTER.md / DEFECT-REGISTER.md precedent, for records that must survive a milestone boundary"
    - "Section-name citation (MAINTAINING.md § 'Required Checks') instead of a line-range citation, so a later rewrite of that section cannot silently invalidate the pointer"

key-files:
  created:
    - .planning/TOOLING-DEFECTS.md
  modified:
    - .planning/REQUIREMENTS.md
    - CONTRIBUTING.md

key-decisions:
  - "D-19's prescribed primary mitigation (--archive-version) is demoted to necessary-but-insufficient, not repeated as the fix — the 70099869 commit body proves it was passed and the defect fired anyway. A post-condition file-count check is recorded as the sole primary mitigation."
  - "Zero restoration work budgeted for HIST-01 — RESEARCH.md F7 already verified both v2.0 (48/48) and v2.1 (39/39) restorations byte-exact; re-deriving from a stale blob would turn a closed defect into a live one."
  - "All three commits use the docs: conventional-commit type — CONTRIBUTING.md is a repo-root file and release-please-config.json claims root paths, so a feat:/fix: commit here risks the exact accidental-release-train class recorded in CLAUDE.md (the 1.6.2 incident)."

patterns-established:
  - "Milestone-independent defect register as a distinct artifact class from milestone-scoped gap/defect registers already present in this repo."

requirements-completed: [HIST-01, TRUTH-09]

coverage:
  - id: D1
    description: "TOOL-01 defect record created at .planning/TOOLING-DEFECTS.md (root, no milestone: key), citing both occurrences (b5fed519/a629fb82, 70099869) and demoting --archive-version to necessary-but-insufficient"
    requirement: "HIST-01"
    verification:
      - kind: other
        ref: "test -f .planning/TOOLING-DEFECTS.md && grep -c 'cleared:'/'TOOL-01'/'necessary but insufficient'/'70099869'/'b5fed519' .planning/TOOLING-DEFECTS.md (all >=1); awk frontmatter check for '^milestone:' -> 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "v2.0-phases (48 files) and v2.1-phases (39 files) restorations confirmed untouched by this plan; git status --porcelain .planning/milestones/ empty"
    requirement: "HIST-01"
    verification:
      - kind: other
        ref: "find .planning/milestones/v2.0-phases -type f | wc -l -> 48; find .planning/milestones/v2.1-phases -type f | wc -l -> 39; git status --porcelain .planning/milestones/ -> empty"
        status: pass
    human_judgment: false
  - id: D3
    description: "TRUTH-09's text in REQUIREMENTS.md amended to the three-bucket (merge-gating/publish-gating/advisory) + structural model, replacing the stale two-bucket wording and the stale '9+ unclassified jobs' enumeration, citing 141-CONTEXT.md D-02/D-03"
    requirement: "TRUTH-09"
    verification:
      - kind: other
        ref: "grep -c 'as merge-gating or advisory' -> 0; grep -c 'The 9+' -> 0; awk-scoped TRUTH-09 block contains 'publish-gating' (4), 'structural' (1), '141-CONTEXT.md' (1); TRUTH- bullet count unchanged (7 before/after)"
        status: pass
    human_judgment: false
  - id: D4
    description: "CONTRIBUTING.md's branch-protection claim corrected from five wrong contexts to the true two (CI Green, Guard Release Trigger), pointing at MAINTAINING.md § 'Required Checks' by section name"
    verification:
      - kind: other
        ref: "grep -v '^#' CONTRIBUTING.md | grep -c 'PR title (semantic)' -> 0; grep -c 'CI Green'/'Guard Release Trigger'/'setup_branch_protection.sh'/'branch-protection-drift.yml' -> all >=1; grep -c 'MAINTAINING.md.*:[0-9]' -> 0; git diff --numstat -> 6+4=10 lines (<15)"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-07-28
status: complete
---

# Phase 141 Plan 02: Lane Truth Foundation — Tooling-Defect Record & Requirement/Doc Reconciliation Summary

**Wrote the standalone, milestone-independent `.planning/TOOLING-DEFECTS.md` recording the `phases.clear` archive-omission defect (TOOL-01) with its refuted-mitigation evidence, amended `TRUTH-09`'s text in `.planning/REQUIREMENTS.md` to the three-bucket classification model this phase ships, and corrected `CONTRIBUTING.md`'s five-wrong-context branch-protection claim to the true two contexts — closing HIST-01 and reconciling two of the phase's five disagreeing registries with zero CI or code changes.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-28
- **Tasks:** 3 (all `type="auto"`, no checkpoints)
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Closed **HIST-01**: created `.planning/TOOLING-DEFECTS.md` at the `.planning/` root, deliberately carrying no `milestone:` frontmatter key so the record survives a milestone boundary (unlike the two milestone-scoped precedent registers it borrows its shape from). The `TOOL-01` entry cites both occurrences (`b5fed519`/`a629fb82` for v2.0 phases 132-137, `70099869` for v2.1 phases 138-140) with the load-bearing recognize-on-screen symptom line (`cleared: N` reported with no `milestones/<version>-phases/` directory written).
- Applied **F6's refutation** rather than repeating D-19's original prescription: the commit body of `70099869` proves `--archive-version` was passed and the defect fired anyway, so the file records it as *necessary but insufficient*, not as the fix. A post-condition file-count check is promoted to sole primary mitigation.
- Amended **TRUTH-09** in `.planning/REQUIREMENTS.md` so the requirement's own text describes the three-named-bucket (+structural) model this phase ships, rather than the stale two-bucket ("merge-gating or advisory") wording — preventing the requirement itself from becoming a sixth disagreeing registry. Replaced the stale "9+ currently-unclassified jobs" enumeration with the accurate, complete list (including `Branch Protection Advisory` and the new `Design System Conformance` lane) and cited `141-CONTEXT.md` D-02/D-03 as the amendment's decision record.
- Corrected `CONTRIBUTING.md`'s fifth disagreeing registry: the claim that `main` requires five status checks (`Tests`, `Credo Strict`, `Dialyzer`, `actionlint`, `PR title (semantic)`) was wrong on all five names. Replaced with the live-verified two true contexts (`CI Green`, `Guard Release Trigger`) and a pointer to `MAINTAINING.md` § "Required Checks" **by section name**, not line range, so plan 141-06's rewrite of that section cannot silently invalidate the pointer.
- Re-confirmed, as required by the plan's threat model (T-141-09), that neither `.planning/milestones/v2.0-phases/` (48 files) nor `.planning/milestones/v2.1-phases/` (39 files) was touched by this plan — `git status --porcelain .planning/milestones/` produced no output.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author `.planning/TOOLING-DEFECTS.md` with the `phases.clear` defect record (TOOL-01)** - `f20f84de` (docs)
2. **Task 2: Amend TRUTH-09's text in `.planning/REQUIREMENTS.md` to the shipped classification model** - `7075f2bb` (docs)
3. **Task 3: Correct `CONTRIBUTING.md`'s branch-protection claim — the fifth registry** - `4a4322ee` (docs)

_All three commits use the `docs:` conventional-commit type, per T-141-08 — a repo-root `feat:`/`fix:` commit on `CONTRIBUTING.md` risks triggering an unintended Hex release train (the 1.6.2 incident recorded in `CLAUDE.md`); v2.2 ships no release._

## Files Created/Modified

- `.planning/TOOLING-DEFECTS.md` - New milestone-independent register; `TOOL-01` entry documents the `phases.clear` archive-omission defect, both occurrences, the refuted mitigation, and the live recurrence risk for v2.2's own upcoming milestone close (phases 141-144).
- `.planning/REQUIREMENTS.md` - TRUTH-09's body rewritten to the three-bucket + structural model with an italic amendment footer citing `141-CONTEXT.md` D-02/D-03. No other requirement touched; requirement count unchanged (7 TRUTH-prefixed bullets before and after).
- `CONTRIBUTING.md` - The branch-protection paragraph at (formerly) lines 116-119 corrected to name `CI Green` and `Guard Release Trigger` and point at `MAINTAINING.md` § "Required Checks"; the two surrounding accurate sentences about `scripts/setup_branch_protection.sh` and `.github/workflows/branch-protection-drift.yml` preserved.

## Decisions Made

1. **D-19's primary mitigation demoted, not repeated** — recording "pass `--archive-version`" as the fix would write down a mitigation the repo's own evidence (`70099869`) already shows doesn't work. The post-condition file-count check is the sole primary mitigation; `--archive-version` is recorded as necessary (for correct milestone filing, since `new-milestone` switches `STATE.md` before `phases.clear` runs) but insufficient to prevent this defect.
2. **Zero restoration work budgeted** — RESEARCH.md F7's per-file `git hash-object` comparison already confirmed both restorations byte-exact (48/48, 39/39); this plan only re-ran the two file-count commands as closing evidence, never touching `.planning/milestones/`.
3. **All three commits typed `docs:`** — `CONTRIBUTING.md` is a repo-root file claimed by `release-please-config.json`'s root path; a releasing type here risks reproducing the 1.6.2 accidental-release-train defect this milestone exists partly to guard against.

## Deviations from Plan

None - plan executed exactly as written. All three tasks' `<action>` steps were followed verbatim; every `<acceptance_criteria>` check (grep counts, awk-scoped block checks, frontmatter key check, file-count checks, `git status --porcelain` check, `git diff --numstat` line-count check) was run and passed without needing any adjustment beyond the planned edits.

## Issues Encountered

None. One phrasing hazard was caught during authoring, before running the checks: an early draft of the TRUTH-09 amendment footer used the phrase "classified every job **as** merge-gating or advisory", which would have left the literal forbidden substring `as merge-gating or advisory` in the file (acceptance criteria requires that exact substring's count be `0`). Rephrased to `the original text read "merge-gating or advisory"` before running the grep check, so no re-edit cycle was needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- HIST-01 is fully closed: both restorations are confirmed byte-exact (prior research) and the defect that caused them is now recorded where a future `phases.clear` run — including this milestone's own v2.2 close over phases 141-144 — would be recognized as a repeat rather than a discovery.
- TRUTH-09's text now agrees with the classification model plans 141-04/141-05/141-06 implement in code and in `MAINTAINING.md`; no further requirement-text drift is expected once those plans land.
- `CONTRIBUTING.md`'s pointer to `MAINTAINING.md` § "Required Checks" is deliberately section-named (not line-ranged), so it survives 141-06's rewrite of that section without going stale.
- No blockers for 141-03 through 141-06. This plan touched no CI configuration, no `ci_lanes.ex`, and no `MAINTAINING.md` — its scope was strictly the two non-CI registries plus the tooling-defect record.

## Self-Check: PASSED

All created/modified files confirmed present on disk; all three commit hashes (`f20f84de`, `7075f2bb`, `4a4322ee`) confirmed in `git log --oneline --all`.

---
*Phase: 141-lane-truth-foundation*
*Completed: 2026-07-28*
