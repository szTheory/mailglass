---
phase: 178-preview-authoring-and-milestone-review
plan: "11"
subsystem: testing
tags: [exunit, prohibition-contract, mutation-proof, preview, feedback-ledger, mailglass_admin]

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "178-04 ScenarioLabel and selector testids, 178-05 178-AUTOMATION.md, 178-06 real-zoom relabel, 178-07 ledger closed (open_rows empty)"
provides:
  - "MailglassAdmin.Phase178ProhibitionContractTest: seven D-15 must-NOT rules (P1-P7), 21 tests, merge-blocking in the admin lane"
  - "Seven recorded source mutations, each turning at least one contract test red before a path-specific revert"
  - "178-AUTOMATION.md section 'Prohibition contract (D-15)' with the rule table, the mutation table and the lane"
affects: [178-08, 178-09]

phase_base_sha: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_before: 98bc0d01f9bf671867d5c58d93f707398cc523ba
plan_head_after: 5b4743e72a851a9a86410bb32a47a94058186883

actuals:
  tokens: 8100
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Prohibition detectors return violation lists and are proven with fail-first fixtures plus clean-state tests on real renders, then proven red by a recorded source mutation"
    - "A source-scan rule carries a non-vacuity guard (more than 15 spec files read, at least one style.zoom use seen)"
    - "Collisions for P4 are computed from ScenarioLabel.humanize/1 alone so the detector does not trust the label table it judges"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs
    - .planning/phases/178-preview-authoring-and-milestone-review/178-11-SUMMARY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md

key-decisions:
  - "P1's -help id family is scoped to the assigns form (assigns-*-help). The real page renders preview-backdrop-help for an unrelated toggle, which a bare -help suffix check flagged on first run; the narrower family is the actual prohibition"
  - "P4 derives the colliding set from ScenarioLabel.humanize/1, not from ScenarioLabel.build/1, so the detector cannot be satisfied by a regression in the table it judges"
  - "P7 judges only a test block's title and string literals (not comments) for real-zoom wording, and splits at test( and test.describe( boundaries; test.step( is not a boundary so a step cannot separate a title from its style.zoom call"
  - "Commit trailer is Co-Authored-By: Claude Sonnet 5.5 per the runtime attribution reminder (as in 178-06 and 178-07), not the plan text's Claude Opus 5.5"

requirements-completed: ["UIQ-04", "STORY-07"]

coverage:
  - id: D1
    description: "Every Phase 178 must-NOT (P1-P7) is an executable detector with a fail-first teeth test and a clean-state test on real renders or real sources"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs (21 tests, 0 failures, --seed 0 --warnings-as-errors)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each rule was proven red by a source mutation of committed code and reverted byte-for-byte (git diff --quiet HEAD per file)"
    requirement: "STORY-07"
    verification:
      - kind: command
        ref: "mutation table in 178-AUTOMATION.md#prohibition-contract-d-15; git diff --quiet HEAD -- mailglass_admin/lib reference/persona_spec mailglass_admin/e2e reference/demo_app/assets/e2e <contract file> exits 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "The contract runs in the merge-blocking admin lane and the whole lane is green"
    requirement: "UIQ-04"
    verification:
      - kind: command
        ref: "mix verify.support_contract.admin --seed 0 (1204 tests, 0 failures, 1 excluded; 1183 before this plan plus 21)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 11: D-15 prohibition contract Summary

**Seven Phase 178 must-NOT rules (generic helpers, dangling aria ids, title-only identity, raw-atom primaries, reset_assigns behavior, open feedback rows, CSS zoom called real zoom) are now a 21-test merge-blocking contract, each rule proven red by a recorded source mutation and reverted clean.**

## Performance

- **Duration:** about 25 min (13:55Z to 14:20Z)
- **Tasks:** 2 (1 tracer, 1 auto)
- **Files:** 1 test file created, 1 planning record extended, this summary

## Accomplishments

- **Contract (task 1).** `phase178_prohibition_contract_test.exs` uses `MailglassAdmin.LiveViewCase, async: false` (P5 needs a live view) and `@moduletag :phase178`. Detectors: `generic_helper_violations/1`, `dangling_id_violations/1`, `title_only_identity_violations/2`, `raw_primary_violations/2`, `reset_violations/3`, `css_zoom_label_violations/1`; P6 calls `FeedbackLedger.open_rows/1` on `QuickViewScenarios.feedback/0`. 8 teeth tests feed each detector a known-bad and a known-clean fixture; 13 clean-state tests cover `assigns_form/1` in typed, editable-only, read-only, mixed, empty and error states, the live `typed_values` page on mount / after an invalid edit / after Restore defaults, `Sidebar.menu/1` closed and open over every fixture scenario plus the render-error entry, the real manifest, and 33 real e2e spec sources.
- **Mutation proofs (task 1).** One mutation per rule against committed source, each red, each reverted with `git checkout HEAD -- <that file>` and confirmed with `git diff --quiet HEAD -- <file>`:

| Rule | File mutated | Mutation | Failing test | Revert command |
| --- | --- | --- | --- | --- |
| P1 | `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | Added `<p id={@control_id <> "-help"}>Whole number.</p>` to the integer field | `P1: ... assigns_form/1 renders none for typed, editable-only, read-only, mixed and error states` and `... the typed_values page renders none on mount, after an invalid edit and after Restore defaults` | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` |
| P2 | `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | Read-only `aria-describedby` points at non-rendered `preview-assigns-missing` | `P2: ... assigns_form/1 resolves every reference in every state` and `... every typed_values page state resolves its references` | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` |
| P3 | `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | Technical identity span emptied, identity moved to `title={@identity.technical}` | `P3: ... every fixture scenario shows ScenarioLabel.technical/2 in the trigger text` and `... the live scenario page shows the identity in the trigger` | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` |
| P4 | `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | Option primary renders `Atom.to_string(scenario_name)` | `P4: ... the open menu never shows a raw atom as the primary of a non-colliding option` and `... non-colliding primaries equal ScenarioLabel.humanize/1 ...` | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` |
| P5 | `mailglass_admin/lib/mailglass_admin/preview_live.ex` | Dropped `assign(:field_errors, %{})` from the `reset_assigns` handler | `P5: reset_assigns is unchanged Restore defaults fires reset_assigns, restores the default and clears every field error` | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview_live.ex` |
| P6 | `reference/persona_spec/quick_view_scenarios.json` | `fb-health-crowding` status `automated` to `partial` | `P6: ... the real manifest has no open row` | `git checkout HEAD -- reference/persona_spec/quick_view_scenarios.json` |
| P7 | `mailglass_admin/e2e/phase176-filters.spec.js` | Title "under CSS zoom 2x" renamed to "under 200% zoom" | `P7: ... no spec in the Admin or demo e2e trees labels CSS zoom as real zoom` | `git checkout HEAD -- mailglass_admin/e2e/phase176-filters.spec.js` |

- **Record (task 2).** `178-AUTOMATION.md` gained `## Prohibition contract (D-15)` (rules and tests, the mutation table, scope notes, the Support Contract Admin lane and a standalone reproduction command). Heading count is 1.

## Verification

- `mix test test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0 --warnings-as-errors`: 21 tests, 0 failures (plan floor 14).
- `git diff --quiet HEAD -- mailglass_admin/lib reference/persona_spec mailglass_admin/e2e reference/demo_app/assets/e2e mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs`: exit 0 after all seven mutations.
- `mix format --check-formatted test/mailglass_admin/phase178_prohibition_contract_test.exs`: clean.
- `mix verify.support_contract.admin --seed 0`: 1204 tests, 0 failures, 1 excluded (1183 at 178-07 plus the 21 new tests, so the file runs in the merge-blocking lane).
- `git status --short mailglass_admin/lib mailglass_admin/priv/static reference/persona_spec`: empty.

## Task Commits

1. **Task 1 (tracer): D-15 prohibition contract** - `a6596155`
2. **Task 2: prohibition contract record** - `5b4743e7`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] P1 -help id check was too broad**
- **Found during:** Task 1, first clean-state run
- **Issue:** The detector flagged any id ending in `-help`; the live typed_values page legitimately renders `preview-backdrop-help` (backdrop toggle), so the clean-state test failed on a non-violation.
- **Fix:** Scoped the forbidden family to `assigns-*-help` ids and references, which is the actual Phase 178 prohibition (per-field helpers on the assigns form). Teeth fixtures use `assigns-` ids.
- **Files modified:** `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs`
- **Commit:** `a6596155` (fixed before the first commit)

### Plan-text drift (no behavior change)

- The plan says "at least 14 tests"; the file has 21 (8 teeth, 13 clean-state).
- Commits use `Co-Authored-By: Claude Sonnet 5.5` per the runtime attribution reminder instead of the plan text's Claude Opus 5.5.
- The mutation proofs ran through a scratchpad driver script (apply, run contract, `git checkout HEAD -- <file>`, `git diff --quiet`); the script is not committed, the table above is the record.

**Total deviations:** 1 auto-fixed (detector scope bug caught before commit). **Impact:** none on scope.

## Authentication Gates

None.

## Known Stubs

None.

## Issues Encountered

The admin lane prints a GenServer crash dump from an existing test during the run; the lane still reports 0 failures. It is pre-existing noise and untouched by this plan.

## Threat Flags

None. T-178-34: every mutation was reverted by path and verified against HEAD, and the post-proof `git diff --quiet` gate covers lib, persona_spec and both e2e trees. T-178-19: P7 has a non-vacuity guard (more than 15 spec files, at least one `style.zoom` use) and every rule has teeth. T-178-SC: no package installs, no lockfile changes.

## Next Phase Readiness

- UIQ-04 and STORY-07 are also declared by sibling plans (178-08 to 178-10), so `REQUIREMENTS.md` stays unticked until the last declaring plan finishes.
- 178-08 and 178-09 can cite `178-AUTOMATION.md#prohibition-contract-d-15` as the machine-checked answer for every D-15 must-NOT; no prohibition routes to the owner.

## Self-Check: PASSED

- Files exist: `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs`, `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md`.
- Commits exist on `main`: `a6596155`, `5b4743e7`.
