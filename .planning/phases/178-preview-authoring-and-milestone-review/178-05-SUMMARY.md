---
phase: 178-preview-authoring-and-milestone-review
plan: "05"
subsystem: testing
tags: [storybook, phoenix-liveview, persona-spec, feedback-ledger, doc-truth, playwright, mailglass_admin]

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "178-01 AssignsForm (Restore defaults, read-only note), 178-02 FeedbackLedger detectors, 178-03 isolated candidate launcher, 178-04 ScenarioLabel and Sidebar.menu open attr"
provides:
  - "MailglassDemo.QuickViewScenarios.preview_authoring/1 with a closed identifier table and tagged value decoders"
  - "Five preview-authoring-* manifest rows and Storybook.PreviewAuthoring at /dev/storybook/preview_authoring (production AssignsForm and Sidebar.menu)"
  - "fb-preview-reset and fb-preview-identity automated; the only open row is partial fb-storybook-fidelity"
  - "FeedbackLedger.story_accounting/2, unrendered_linked_scenarios/2, boundary and doc-truth detectors, table_after/2 parser"
  - "178-AUTOMATION.md with Reproduce, Preview authoring, Readable scenario selector and Retained stories (STORY-07) sections"
affects: [178-07, 178-08, 178-09, 178-11]

phase_base_sha: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_before: aefd6ecabf0337dc146c8a76337e94e9640eb06d
plan_head_after: 3c65b6553e983d66ebf53441ea99fb3d345cca97

actuals:
  tokens: 18700
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Closed compile-time identifier map in the builder: manifest strings become assign keys, scenario names and Mailable modules without any runtime atom creation"
    - "Explicit {type, value} tags for typed manifest values (string, integer, float, boolean, date, datetime, atom, map)"
    - "Doc-truth test: a markdown table is parsed and held equal to a computed accounting, with fixture-copy mutations (edit, drop, add, swap, stale count)"
    - "Pointer resolution for the planning doc follows the live-or-archive resolver so archiving the phase cannot break the test"

key-files:
  created:
    - reference/demo_app/storybook/preview_authoring.story.exs
    - reference/demo_app/assets/e2e/phase178-stories.spec.js
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
  modified:
    - reference/persona_spec/quick_view_scenarios.ex
    - reference/persona_spec/quick_view_scenarios.json
    - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
    - mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs
    - mailglass_admin/test/support/feedback_ledger.ex

key-decisions:
  - "The story menu uses the demo AccountMailer for typed/no-editable/error/long cases and two synthetic Billing.ReceiptMailer atoms for the leaf collision; the closed map holds the only atoms the manifest can name"
  - "Boundary column in the accounting table is the row's own proof_boundary, else the sorted distinct boundaries of its linked scenarios; Preview therefore reads story-render-only and the record's sentence labels it pure-only (story-render-only)"
  - "A scenario counts as linked when a row lists it or it lists a row, matching unrendered_linked_scenarios/2; the per-row Linked without story render count uses the same union"
  - "The story spec asserts one iframe per manifest row (bidirectional inventory); the exact five-row set is pinned by ExUnit, which keeps the task 1 tracer spec valid with one row"

requirements-completed: ["STORY-07", "UIQ-04"]

coverage:
  - id: D1
    description: "Five Preview authoring variations render through the production AssignsForm.assigns_form/1 and Sidebar.menu/1 from manifest facts: typed values, no editable, field error, long Unicode, duplicate label"
    requirement: "STORY-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring no_editable renders the no-editable message and no note"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring field_error renders the specific error with an error-only describedby"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring long_unicode shows the raw atom in the technical line"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring duplicate_label opens the menu with distinct primaries and Mailable labels"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pure-only boundary: typed-values projection equals HappyMailer defaults and its story render shows the live /dev/mail field set; every authoring row is story-render-only and none is in axe_selection (20)"
    requirement: "STORY-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring typed values story render shows the live route's field set"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring rows carry the full object shape and stay out of the axe selection"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 178 Preview authoring manifest carries exactly the five retained variations in story order"
        status: pass
    human_judgment: false
  - id: D3
    description: "fb-preview-reset and fb-preview-identity are automated, link their authoring scenarios both ways, and point at resolvable 178-AUTOMATION.md anchors; open rows are exactly partial fb-storybook-fidelity"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: the Preview rows are automated and link the preview-authoring scenarios both ways"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: the one open row is the partial fidelity row, so none can hide"
        status: pass
    human_judgment: false
  - id: D4
    description: "STORY-07 accounting is computed, written and enforced: every row has a story or the connected-only boundary (zero-story set is exactly fb-auto-apply-filters), and every linked scenario without a story render is a counted boundary entry, both tables held equal to 178-AUTOMATION.md"
    requirement: "STORY-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 accounting: the Retained stories table equals the computed accounting row for row"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 accounting: every real row has a story or the connected-only boundary, and only filters has none"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 accounting: editing a count, dropping or adding a row in a fixture copy of the doc fails"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 accounting: the Linked scenarios table equals the manifest and fails when it drifts"
        status: pass
    human_judgment: false
  - id: D5
    description: "The retained stories render in the demo Storybook: one iframe per manifest row with the right scenario id, state, theme owner and production roots"
    requirement: "STORY-07"
    verification:
      - kind: automated_ui
        ref: "reference/demo_app/assets/e2e/phase178-stories.spec.js#Phase 178 retained Preview authoring stories render through production components"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 05: Preview authoring stories and STORY-07 accounting Summary

**Five Preview authoring states are retained as production-component stories (typed values, no editable, field error, long Unicode, duplicate label) with a pure-to-live field-set check, both Preview ledger rows are closed, and a doc-truth-tested accounting makes every story-backed row, the one connected-only row and the two linked non-story scenarios visible.**

## Performance

- **Duration:** 15 min (13:30Z to 13:46Z)
- **Tasks:** 3 (1 tracer, 2 tdd/auto)
- **Files:** 3 created, 5 modified

## Scenario table

| Scenario id | Variation | Distinct fact proven through the production component | Feedback |
| --- | --- | --- | --- |
| `preview-authoring-typed-values` | `typed_values` | 8 fields (text, number x2, checkbox, date, 3 read-only) plus the single read-only note; decodes to `HappyMailer.preview_props()[:typed_values]`; same `{label, control kind}` set as the live `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values` | reset, identity |
| `preview-authoring-no-editable` | `no_editable` | no-editable message, no `#preview-assigns-readonly-note` | reset |
| `preview-authoring-field-error` | `field_error` | "Enter a whole number.", `aria-invalid="true"`, `aria-describedby="assigns-quantity-error"` only, draft value 3.5; sibling field carries neither attribute | reset |
| `preview-authoring-long-unicode` | `long_unicode` | raw `welcome_überraschung_東京__with_a_deliberately_long_name` inside `preview-email-menu-active-technical`; primary "Welcome überraschung 東京 with a deliberately long name" with no double space | identity |
| `preview-authoring-duplicate-label` | `duplicate_label` | `<details open>`, two options with different visible primaries (raw atoms after the collision), two different Mailable group labels (`Northstar.Billing.ReceiptMailer`, `Fjordline.Billing.ReceiptMailer`) | identity |

All five are `proof_boundary: story-render-only`, `theme_owner: preview-authoring-story`, `theme_picker_testid: preview-authoring-review-theme`; `axe_selection` stays at 20 with none of them. Manifest now has 47 scenarios (42 before).

## Accounting table (STORY-07)

| Feedback | Story-backed | Linked without story render | Boundary |
| --- | --- | --- | --- |
| fb-health-crowding | 5 | 0 | story-render-only |
| fb-preview-reset | 3 | 0 | story-render-only |
| fb-preview-identity | 3 | 0 | story-render-only |
| fb-account-context | 6 | 0 | story-render-only |
| fb-auto-apply-filters | 0 | 0 | connected-real-route-only |
| fb-quiet-quick-view-arrows | 9 | 2 | five boundaries incl. connected-real-route-only |
| fb-raw-source-hierarchy | 4 | 0 | story-render-only |
| fb-suppression-refresh | 4 | 0 | story-render-and-connected-route, story-render-only |
| fb-inbound-addresses | 7 | 0 | story-render-only |
| fb-storybook-fidelity | 22 | 2 | five boundaries incl. connected-real-route-only |
| fb-replay-review | 5 | 0 | story-render-and-connected-route, story-render-only |
| fb-technical-details | 2 | 0 | story-render-and-connected-route, story-render-and-persisted-projection |

The zero-story set is exactly `fb-auto-apply-filters` (FILTER-01..04, connected-only, proof `mailglass_admin/e2e/phase176-filters.spec.js`). Linked scenarios without a story render: 2 (`qv-delivery-empty`, `qv-inbound-empty`, both `connected-real-route-only`, linked by `fb-quiet-quick-view-arrows` and `fb-storybook-fidelity`). The Phase 175 Delivery investigation path (9 `delivery-investigation-*` scenarios, one with `story-render-and-persisted-projection`) is named as the composed Delivery job and cites the two existing projection-agreement tests; no new Delivery check was written.

## Red and green counts

- **Task 1 (tracer):** the plan marks it a tracer, so the builder, row, story, spec and tests landed together. No red run. Green: `quick_view_projection_test.exs` + `feedback_ledger_test.exs` 52 tests, 0 failures.
- **Task 2 (tdd):** behavior tests written first, run against the task 1 manifest: 5 failures in `quick_view_projection_test.exs` (manifest-of-five, no_editable, field_error, long_unicode, duplicate_label) plus 2 in `feedback_ledger_test.exs` (open rows now only the partial row; Preview rows automated and back-linked), 7 red in total. After the four JSON rows and the two ledger rows: only the two pointer failures remained until `178-AUTOMATION.md` existed; then 58 tests, 0 failures.
- **Task 3 (tdd):** 11 accounting tests written first, all 11 red (undefined functions). After implementing the detectors 7 passed and 4 (the doc-truth cases) waited for the section; after the section 45 tests, 0 failures in the ledger file and 69 together with the projection file.
- **Mutation proof** of the new detectors (single-line mutation, file restored byte for byte after each; the 7th escaped the first run and a test was added):

| Mutation | Failing tests |
| --- | --- |
| `story_backed?` ignores `story_path` | 1 |
| boundary check dropped | 1 |
| zero-story check dropped | 1 |
| feedback_ids-only link ignored | 1 |
| row diff always clean | 2 |
| count check always clean | 1 |
| row order ignored | 0, then 1 after adding "swapping two table rows ... fails" |

- **Full admin lane:** `mix verify.support_contract.admin --seed 0`: 1183 tests, 0 failures, 1 excluded (100.7 s). `mix format --check-formatted` clean for every touched Elixir file. `node --test` on the Phase 174/175 validators and storybook-axe: 40 pass.

## Gate G178-05-DEMO (isolated demo)

- **Valid run:** record `/Users/jon/projects/mailglass/reference/demo_app/tmp/phase178_candidate/stories-1793281009.json`, source SHA `c4d0a6e7`, `final_status=pass`. `/dev/storybook/preview_authoring` returned 200 and `/dev/mail` returned 200. Demo spec: 1 passed (all five variations, 547 ms). Teardown restored `reference/demo_app/mix.lock` (`git diff --quiet` clean), stopped the compose project, removed the worktree and run parent. `before=2 after=2 left=0`: the owner's review-demo containers were untouched and no `mailglass-phase178-review-*` container remains. **Measured wall: 67 s** (bound 900 s).
- **Invalid first run:** the first run (`stories-1793280832.json`, SHA `8c2c1b0c`, wall 80 s, teardown clean) failed with "Expected 5, received 1". That was my race, not a product fault: I extended the working-tree manifest to five rows while the run was in flight, and the spec reads the working-tree manifest while the launcher builds the committed HEAD (one variation). The run's route probe, launcher and teardown all behaved. The gate was repeated once after the task 2 commit, so HEAD held all five rows and variations.

## Task Commits

1. **Task 1: Preview authoring story tracer** - `8c2c1b0c` (test)
2. **Task 2: Remaining four variations and closed Preview ledger rows** - `c4d0a6e7` (feat)
3. **Task 3: STORY-07 accounting and doc-truth table** - `3c65b655` (test)

**Plan metadata:** committed separately (docs: complete plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Process] Gate G178-05-DEMO raced with my own manifest edit and was re-run after task 2**
- **Found during:** Task 1 gate
- **Issue:** The plan runs the gate once after task 1's commit. I started task 2 in the working tree while the gate ran; the spec's working-tree manifest (5 rows) then disagreed with the committed one-variation story (1 iframe).
- **Fix:** Recorded the first run as invalid and re-ran the same gate once after the task 2 commit, where HEAD, manifest and story agree. It verifies all five variations, a superset of the task 1 check. Task 1's tracer evidence is therefore the in-process tests plus the second run.
- **Files modified:** none
- **Verification:** valid run above, `rc=0`, wall 67 s.

**2. [Rule 3 - Process] Commit trailer model name**
- **Issue:** The plan prescribes `Co-Authored-By: Claude Opus 5.5`; the session attribution names `Claude Sonnet 5.5`, the model that authored the commits.
- **Fix:** Used the session trailer, matching plans 178-01, 178-02 and 178-04. Explicit-path `git add` and `git commit -- <paths>` were followed; `gsd-sdk query commit` was not used for code.

**3. [Rule 2 - Missing coverage] Row-order mutation was not caught**
- **Found during:** Task 3 mutation proof
- **Issue:** Ignoring row order in the doc-truth diff passed every test.
- **Fix:** Added "swapping two table rows in a fixture copy of the doc fails"; the mutation now fails 1 test.
- **Files modified:** `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs`
- **Committed in:** `3c65b655`

**4. [Rule 1 - Bug] Unused identifier in the closed table**
- **Issue:** The first draft listed `typed_values` as a nameable atom although no projection names it.
- **Fix:** Removed it before the task 2 commit so the table holds only what the five rows use.

**Plan notes (not deviations):** the plan's story-spec text asks for the exact five rows; the spec asserts one iframe per manifest row (both directions) and ExUnit pins the exact five, so the task 1 tracer spec stays valid with one row. The Boundary column is computed from the manifest (distinct boundaries), so the "pure-only (story-render-only)" label for Preview sits in the record's D-09 sentence rather than in a cell.

**Total deviations:** 4 (2 process, 1 coverage gap, 1 draft bug). **Impact:** none on scope; the second gate run is the only departure from the plan's sequence.

## Issues Encountered

- `warning: MailglassDemo.QuickViewScenarios is not included in any boundary` still prints when the admin test build compiles the persona spec. It predates this plan (see 178-02) and does not fail the lane.
- No hosted or remote action was taken (no push, no `gh` write, no dispatch); those are plan 178-09.

## Known Stubs

None.

## Threat Flags

None. The builder adds no endpoint or auth path. T-178-13: all fixture values are synthetic (HappyMailer defaults, AtlasDesk `AccountMailer`, `Northstar`/`Fjordline` namespaces). T-178-14: the doc-truth tests are in the merge-blocking admin lane with fixture-copy mutation cases. T-178-15: no runtime atom creation (`grep -c 'String.to_atom'` stays at 1, the pre-existing doc mention; unknown identifiers raise `ArgumentError`). T-178-SC: no package or lockfile changes.

## Self-Check: PASSED

- FOUND: `reference/demo_app/storybook/preview_authoring.story.exs`, `reference/demo_app/assets/e2e/phase178-stories.spec.js`, `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md`
- FOUND: commits `8c2c1b0c`, `c4d0a6e7`, `3c65b655` are ancestors of HEAD
- Acceptance: `def preview_authoring` 1; `String.to_atom` 1 (baseline); 5 `preview-authoring-` rows, `axe_selection` 20, no pending row; three required headings 3; `## Retained stories (STORY-07)` 1; `### Linked scenarios without a story render (STORY-07)` 1 with count line 2 equal to 2 table rows and 2 manifest-computed; `reference/demo_app/mix.lock` unchanged.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-10-29*
