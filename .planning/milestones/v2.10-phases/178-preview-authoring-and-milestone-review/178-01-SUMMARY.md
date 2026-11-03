---
phase: 178-preview-authoring-and-milestone-review
plan: "01"
subsystem: ui
tags: [phoenix-liveview, heex, a11y, aria, playwright, axe, mailglass_admin, preview]

requires:
  - phase: 175-inbound-evidence
    provides: "evidence_card secondary-action class precedent and the mutation-proven prohibition contract pattern"
provides:
  - "Preview 'Restore defaults' action: bordered, full width below sm, end-aligned from sm, handler unchanged"
  - "Removal of the five generic per-field type helpers; one form-level read-only note (preview-assigns-readonly-note)"
  - "Id-closed aria-describedby on the Preview assigns form (assert_ids_closed!/1 helper, browser proof)"
  - "Preview axe cell falsified unchanged before and after (A1)"
affects: [178-04, 178-08, 178-11]

phase_base_sha: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_before: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_after: 20008d29633b0d438f6ff890d208c0e5019690da

actuals:
  tokens: 5400
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Form-level note + per-display aria-describedby instead of per-field helpers"
    - "Id-closure assertion (every aria-describedby/labelledby token resolves in the same fragment)"
    - "Browser geometry proof: content-box vs button box at 390/639/640/1280 in light and dark"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
    - mailglass_admin/test/mailglass_admin/voice_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/structural.spec.js

key-decisions:
  - "Note wording kept verbatim after the ux-writing review: \"Read-only values come from this scenario's defaults. Edit them in its Mailable.\""
  - "described_by is a private /2 (nil when no error, else the error id); read-only displays take the note id through the new field/1 attr note_id, read with Map.get so a standalone render carries no describedby"
  - "Read-only div keeps data-readonly-display, aria-readonly, aria-labelledby and classes so the axe cell does not move"

requirements-completed: ["PRVUX-05", "PRVUX-06"]

coverage:
  - id: D1
    description: "Restore defaults is a bordered, aligned secondary action (full width at 390/639, end-aligned and narrower than half at 640/1280, >=44px tall, visible border and focus ring, light and dark) with the reset_assigns handler unchanged"
    requirement: "PRVUX-05"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: Phase 178 restore defaults geometry, border and focus"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: Phase 178 restore defaults under reduced motion"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#the assigns form ends with one Restore defaults action using the secondary classes"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generic per-field helpers are gone; one form-level read-only note renders only when read-only values sit beside editable ones; every aria-describedby/labelledby id resolves"
    requirement: "PRVUX-06"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#one form-level note describes read-only values and each display references it"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#every typed_values page state resolves its aria references"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview assigns and operator replay radios keep explicit labels and descriptions"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview axe cell unchanged for light, dark and system (single aria-allowed-attr on #assigns-plan) before and after"
    requirement: "PRVUX-06"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: Phase 178 axe cell matches the committed baseline"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 01: Restore defaults and sample-value guidance Summary

**Preview assigns form now ends with a bordered, aligned "Restore defaults" action (handler untouched), drops the five generic type helpers for one form-level read-only note, and keeps every aria-describedby id resolvable, with the Preview axe cell unchanged.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-29T08:25Z (approx.)
- **Completed:** 2026-10-29
- **Tasks:** 2
- **Files modified:** 5

## Recorded values (plan output spec)

- **phase_base_sha:** `61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc` (plan 178-08 reviews `phase_base_sha..HEAD`)
- **Pre-change count** (`voice_test.exs` + `preview_live_test.exs`, `--seed 0`): 61 tests, 0 failures, 1 excluded.
- **After task 1:** 61 tests, 0 failures (pins rewritten in place). **After task 2:** 68 tests, 0 failures, 1 excluded. Full admin suite `mix test --seed 0`: 1095 tests, 0 failures, 1 excluded.
- **Red/green (task 2):** the new and rewritten behavior tests ran red first: 8 failures of 68 (invalid-draft describedby/copy, forged-event note, editable-no-helper, read-only note, string, boolean, atom and map/DateTime pins); 0 failures after the edit. Tests that passed before the edit by design: idempotent restore, Restore defaults classes (task 1), note-absent branch, id-closure on the old markup, and the assert_ids_closed!/1 self-test.
- **Mutation sanity (task 1):** reverting the button classes made the geometry case fail ("light 390px full-width", 170px off), then restored.
- **A1 axe cell, before (unmodified tree):** light, dark and system each = `{aria-allowed-attr: 1}`, node target `["#assigns-plan"]`. **After:** identical map and the same target `["#assigns-plan"]` for all three themes; equals `docs/axe-baseline.json` `current.violations.preview`. No rebaseline.
- **ux-writing decision (D-03):** before `Read-only values come from this scenario's defaults. Edit them in its Mailable.`; after: unchanged. Rationale: 13 words in two sentences (8 and 5), states the cause first and then the action, uses the direct verb "Edit", names the real artifact (Mailable), and mirrors the existing no-editable sentence so the two form-level messages read as one voice.
- **Wall time of verify commands:** targeted `mix test` (two files) about 5s; Playwright block (structural + flows, `--grep Phase 178|Preview happy`) 8.7s for 4 tests; task 2 block (structural, 4 tests) 8.7s; `check-conformance.sh` about 1s; full admin `mix test --seed 0` 16s.

## Accomplishments

- Replaced "Reset assigns" with "Restore defaults" using the `evidence_card` secondary-action classes inside the existing `flex flex-wrap` wrapper; `reset_assigns` handler and `preview_live.ex` are byte-identical.
- Deleted `help_text_for/1`, `field_help/1`, `help_id/1`, the `:help_text`/`:help_id` assigns and all six call sites; editable fields now emit `aria-describedby` only with an error (`assigns-<key>-error`).
- Added one `preview-assigns-readonly-note` paragraph, rendered only when read-only values sit beside editable fields; read-only displays reference it. Standalone `field/1` carries no describedby.
- Added three Phase 178 browser cases (geometry/border/focus in light+dark at 390/639/640/1280, reduced motion, axe cell) and rewrote the Preview assigns browser case to the new contract.

## Task Commits

1. **Task 1: Restore defaults end to end** - `fd0dc70d` (feat)
2. **Task 2: Remove generic helpers; one read-only note; id-closed describedby** - `20008d29` (feat)

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` - Restore defaults button, `@readonly_note`, `readonly_values?/1`, `note_id` attr, helper removal
- `mailglass_admin/test/mailglass_admin/voice_test.exs` - verb+noun pin now "Restore defaults"
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` - pins rewritten; `assert_ids_closed!/1`, `refute_generic_helpers!/1`, and eight new tests
- `mailglass_admin/e2e/flows.spec.js` - button role name pin
- `mailglass_admin/e2e/structural.spec.js` - axe-cell, geometry, reduced-motion cases; assigns case rewritten

## Decisions Made

- Note copy unchanged after review (see above).
- `described_by` is a private `/2` rather than the planned `/3`: the third argument would have been unused, since read-only displays take `note_id` directly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Commit trailer model name**
- **Found during:** Task 1 commit
- **Issue:** The plan prescribes `Co-Authored-By: Claude Opus 5.5`, but the session's attribution instruction names `Claude Sonnet 5.5`, which is the model that authored the commits.
- **Fix:** Used the session attribution trailer for both commits. Everything else in the commit discipline (explicit paths, no `gsd-sdk query commit` for code) was followed.
- **Files modified:** none
- **Committed in:** `fd0dc70d`, `20008d29`

**2. [Rule 1 - Bug] Test drafts that Playwright and ExUnit could not run as first written**
- **Found during:** Tasks 1 and 2
- **Issue:** The reduced-motion keyboard path tabbed from a date input (three tab stops), and the idempotency test compared whole-page HTML containing per-render ids; the note test compared raw HTML with an HTML-escaped apostrophe.
- **Fix:** Tab from `#assigns-ratio` (one stop); compare the `#preview-assigns-form` fragment; compare the note via parsed text.
- **Files modified:** `e2e/structural.spec.js`, `test/mailglass_admin/preview_live_test.exs`
- **Verification:** all cases green; geometry case mutation-checked.
- **Committed in:** `fd0dc70d`, `20008d29`

---

**Total deviations:** 2 auto-fixed (1 blocking/process, 1 test-authoring bug). **Impact on plan:** none on scope or behavior.

## Issues Encountered

- The plan's `<automated>` Playwright block uses an unquoted `$A` that only word-splits in bash; run under zsh it silently did nothing for the artifact cleanup. Re-ran every block under `bash -c`; the tracked artifact and `priv/static` paths were clean before and after (`ARTIFACTS_CLEAN`).

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or schema changes; `preview_live.ex` is unchanged (T-178-01 held), and T-178-02 is covered by `assert_ids_closed!/1` on every form state.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 178-04 can delegate `humanize/1` (untouched here). Plan 178-11 can mutation-prove rules P1, P2, P5 against the contracts pinned here.
- No blockers.

## Self-Check: PASSED

- `assigns_form.ex`, `structural.spec.js`, `preview_live_test.exs` exist; commits `fd0dc70d` and `20008d29` are ancestors of HEAD.
- Acceptance greps: `Reset assigns` 0 in assigns_form.ex; `Restore defaults` 2; class string 1; generic strings 0; `help_text_for` 0; `field_help` 0; `preview-assigns-readonly-note` 2; `git diff --quiet preview_live.ex` clean; conformance "OK: design-system conformance clean."; `mix format --check-formatted` clean for the three Elixir files; `priv/static` untouched.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-10-29*
