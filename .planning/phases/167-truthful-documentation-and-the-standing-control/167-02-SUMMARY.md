---
phase: 167-truthful-documentation-and-the-standing-control
plan: 02
subsystem: docs
tags: [release-please, claude-md, changelog, readme, docs-contract-test, exunit, drift-guard]

requires:
  - phase: 167-01
    provides: "docs_contract_test.exs drift-guard idiom (negative refute + positive backstop, positive-only presence assertion) this plan reuses for CLAUDE.md/README.md/CHANGELOG.md"
provides:
  - "CLAUDE.md's Engineering DNA sibling-pin bullet corrected to the bare `~>` + linked-versions convention, agreeing with the file's own line 24"
  - "CLAUDE.md's release-mechanics bullet corrected to describe the disarmed-auto-merge plus protected candidate-digest dispatch path, with the required_reviewers security-control language intact"
  - "CLAUDE.md's inbound '1.0 contract' line softened to 'stable contract (semver-honored since 1.0)' per 167-RESEARCH.md assumption A3 — deliberately unpinned"
  - "README.md links guides/upgrading-to-v2_0.md from the Documentation list"
  - "CHANGELOG.md's 2.0.0 section additively names the PostgreSQL schema-isolation move as the adopter-facing breaking change"
  - "2 new describe blocks (CLAUDE.md contract, CHANGELOG.md contract) + 3 new tests + 1 new test in the existing README.md contract block in test/mailglass/docs_contract_test.exs"
affects: [167-03, release ceremony docs, docs_contract_test.exs future extensions]

actuals:
  tokens: 2614
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Negative-first refute + positive backstop pairing, scoped to a single extracted bullet line (not the whole file) to avoid a false-positive match against an unrelated pre-existing occurrence of the same substring"
    - "Positive-only wildcard generalization (Path.wildcard + Enum.each) for an absence defect, so a future guide added to guides/ is covered without editing the test"
    - "Additive-diff proof: a positive assertion re-checking the original release-please-generated bullet is still present, alongside the new content assertion, so the CHANGELOG correction can never regress into history-rewriting"

key-files:
  created: []
  modified:
    - CLAUDE.md
    - README.md
    - CHANGELOG.md
    - test/mailglass/docs_contract_test.exs

key-decisions:
  - "Softened (not pinned) CLAUDE.md's inbound 'stable 1.0 contract' line per 167-RESEARCH.md assumption A3 — the claim is defensible (api_stability.md is genuinely the canonical contract inventory and inbound has never had a breaking removal), so spending a falsifiable test assertion on it would over-constrain a true statement."
  - "Placed the CLAUDE.md contract describe block after CONTRIBUTING.md contract (before the private helper functions), matching Plan 01's block ordering convention."
  - "Added the CHANGELOG.md contract test as its own describe block after CLAUDE.md contract rather than folding it into README.md contract, since it targets a different file and has no shared setup."

requirements-completed: [DOCS-02, DOCS-06]

coverage:
  - id: D1
    description: "CLAUDE.md no longer instructs an == exact sibling pin; corrected bullet names ~> and linked-versions, scoped to the Engineering DNA bullet so the file's unrelated pre-existing ~> occurrence can't satisfy it vacuously"
    requirement: DOCS-02
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#CLAUDE.md contract sibling pin guidance matches the ~> convention the sibling mix files carry"
        status: pass
    human_judgment: false
  - id: D2
    description: "CLAUDE.md no longer claims the release PR auto-merges on green; corrected bullet names the disarmed auto-merge plus protected candidate-digest dispatch, with required_reviewers/three-approvals language intact"
    requirement: DOCS-02
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#CLAUDE.md contract release PR merge path is described as disarmed plus protected dispatch"
        status: pass
    human_judgment: false
  - id: D3
    description: "README.md links guides/upgrading-to-v2_0.md; the assertion generalizes over every guides/upgrading-*.md file on disk, so a future guide can't go unlinked"
    requirement: DOCS-06
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#README.md contract every upgrade guide on disk is linked from README.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "CHANGELOG.md's 2.0.0 section names the PostgreSQL schema-isolation move (Phases 132-137), appended after (not replacing) the release-please-generated bullet"
    requirement: DOCS-06
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#CHANGELOG.md contract 2.0.0 changelog entry names the schema-isolation breaking change"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-09-18
status: complete
---

# Phase 167 Plan 02: CLAUDE.md Release Mechanics + v2.0 Discoverability Summary

**Corrected CLAUDE.md's two false release-mechanics claims (a stale `==` sibling-pin instruction contradicting the file's own line 24, and an auto-merge claim the workflow no longer honors) and made the already-shipped `guides/upgrading-to-v2_0.md` discoverable from README.md plus honestly labeled in CHANGELOG.md — all four corrections pinned by new ExUnit assertions, two proven against live mutations.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-09-18
- **Tasks:** 2
- **Files modified:** 4 (CLAUDE.md, README.md, CHANGELOG.md, test/mailglass/docs_contract_test.exs)

## Accomplishments

- Task 1: Corrected CLAUDE.md's Engineering DNA sibling-pin bullet (`== <version>` → bare `~> <core-major.minor>` + linked-versions plugin, now agreeing with line 24) and the release-mechanics auto-merge bullet ("A Release Please PR auto-merges on green" → "Ordinary auto-merge on the release PR is disarmed... the merge proceeds only via a later protected exact candidate-digest dispatch"), transcribed from `release-please.yml`'s own "Arm auto-merge on the release PR" step echo. The surviving `required_reviewers`/three-approvals security-control language was left untouched and is now positively pinned. Also softened (not pinned) the inbound "stable `1.0` contract" line per research assumption A3. New `describe "CLAUDE.md contract"` block with two negative-first + positive-backstop tests, one scoped to the extracted Engineering DNA bullet line specifically to defeat the file's pre-existing unrelated `~>` occurrence. Mutation proof: deleting the sibling-pin bullet entirely produced RED (`refute is_nil(sibling_bullet)` fired), confirmed and reverted.
- Task 2: Added a README.md Documentation bullet linking `guides/upgrading-to-v2_0.md` (placed before the v1_0 bullet, newest-first), sourced its one-line description from the guide's own opening. Appended (not rewrote) a provenance-prefixed `**Note (added Phase 167):**` bullet to CHANGELOG.md's `## [2.0.0]` section naming the Phases 132-137 PostgreSQL schema-isolation move, sourced from `guides/upgrading-to-v2_0.md` and the CHANGELOG's own existing Feature-commit trail (132-01..137). New positive-only `every upgrade guide on disk is linked from README.md` test (generalizes over `Path.wildcard("guides/upgrading-*.md")`, refutes an empty wildcard first) and `2.0.0 changelog entry names the schema-isolation breaking change` test (region-extracts the 2.0.0 section, asserts both the new content and that the original release-please bullet text survives verbatim). Mutation proof: `touch guides/upgrading-to-v9_9.md` produced RED naming that exact unlinked path, confirmed and reverted.

## Task Commits

1. **Task 1: Correct CLAUDE.md's sibling-pin and auto-merge claims** - `9bbb14c0` (fix)
2. **Task 2: Link the v2.0 upgrade guide from README and name the real v2.0 breaking change in CHANGELOG** - `574ae44a` (feat)

_No plan-metadata commit yet — that follows this SUMMARY per the executor's `<final_commit>` step._

## Files Created/Modified

- `CLAUDE.md` - three one-line corrections: sibling-pin bullet, auto-merge bullet, inbound contract-stability wording softened
- `README.md` - one new Documentation bullet linking `guides/upgrading-to-v2_0.md`
- `CHANGELOG.md` - one appended bullet in the `## [2.0.0]` `⚠ BREAKING CHANGES` block naming the schema-isolation move
- `test/mailglass/docs_contract_test.exs` - new `describe "CLAUDE.md contract"` (2 tests) and `describe "CHANGELOG.md contract"` (1 test) blocks, plus one new test added to the existing `describe "README.md contract"` block

## Decisions Made

- CLAUDE.md's inbound "stable 1.0 contract" line was softened for precision, not pinned with an assertion — 167-RESEARCH.md judges it defensible (assumption A3), and a falsifiable pin on a true claim would over-constrain future edits for no correctness gain.
- The CLAUDE.md contract describe block was placed after CONTRIBUTING.md contract (Plan 01's last block), matching the file's existing block ordering.
- The CHANGELOG.md contract test lives in its own describe block rather than folding into README.md contract, since it targets an unrelated file with no shared setup.

## Deviations from Plan

None — plan executed exactly as written. Both tasks' acceptance criteria and mutation proofs passed on first implementation.

## Issues Encountered

- `grep -c 'guides/upgrading-to-v2_0.md' README.md` returns `1`, not the plan's stated "at least 2," because the markdown link's target and link text sit on the same source line and `grep -c` counts matching *lines*, not occurrences (`grep -o ... | wc -l` correctly reports 2). This matches the existing convention for every other guide bullet in the same list (e.g. `upgrading-to-v1_0.md` also greps to 1 with `-c`), so the added bullet is consistent with the surrounding file; the plan's acceptance-criteria command itself undercounts due to the `-c` vs `-o` distinction, not a defect in the change.

## Next Phase Readiness

- Both DOCS-02 CLAUDE.md corrections and DOCS-06's README/CHANGELOG discoverability fix are complete, committed, and green against both the targeted test file (57/57 passing, 1 pre-existing unrelated skip) and the `support_contract_core` full CI lane (124/124 passing).
- No blockers for 167-03 onward.

---
*Phase: 167-truthful-documentation-and-the-standing-control*
*Completed: 2026-09-18*

## Self-Check: PASSED

All modified files (CLAUDE.md, README.md, CHANGELOG.md, test/mailglass/docs_contract_test.exs) and the
SUMMARY.md itself confirmed present on disk. Both task commit hashes (9bbb14c0, 574ae44a) confirmed
present in `git log --oneline --all`.
