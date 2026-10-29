---
phase: 178-preview-authoring-and-milestone-review
plan: "07"
subsystem: testing
tags: [storybook, playwright, font-roles, feedback-ledger, phase-close-invariant, mailglass_admin]

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "178-02 FeedbackLedger detectors, 178-03 isolated candidate launcher, 178-05 178-AUTOMATION.md and retained stories, 178-06 real-zoom cases"
provides:
  - "Demo case 'Phase 178 StatCard story uses the production font roles' (computed font roles of the StatCard story vs the production Admin gallery, light and dark)"
  - "fb-storybook-fidelity closed (automated, pending_phases removed); no feedback row is pending or partial"
  - "Merge-blocking phase-close invariant 'Phase 178 ledger: no feedback row is pending or partial'"
  - "178-AUTOMATION.md sections 'Storybook fidelity and real zoom (UIQ-06)' (with Width selection and Hook receipts) and 'Feedback ledger (UIQ-04)'"
  - "phase174-review.md replay command on the installed toolchain (D-11) and a current-status feedback table"
affects: [178-08, 178-09, 178-11]

phase_base_sha: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_before: cefc44f0019743482cefe37c12585406c78ae398
plan_head_after: 6421930e83643bdac001e76746625936013aca06

actuals:
  tokens: 7100
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Font-role receipts compare the story against the same component rendered by the production Admin gallery from the same CSS bytes, not against hard-coded family names"
    - "A :component story without container: :iframe renders inline inside .psb-sandbox; resolve its variation block by the generated id (neutral_light -> #neutral-light-component)"

key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-07-SUMMARY.md
  modified:
    - reference/demo_app/assets/e2e/phase178-stories.spec.js
    - reference/persona_spec/quick_view_scenarios.json
    - mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - mailglass_admin/docs/phase174-review.md

key-decisions:
  - "No story or Storybook-setup change was needed: the StatCard already resolves to the production faces (Inter for UI and label, IBM Plex Mono for the value) inside .psb-sandbox, so the serif in the owner's todo does not reproduce at this revision; the receipt is the new fact"
  - "The receipt also asserts .psb-sandbox itself resolves to the production UI face, because that element is the one the todo blames; injecting Georgia there fails the case (expected Inter, received Georgia)"
  - "Production reference is the /dev/mail/gallery stat_card cell (a real production render), not the /dev/mail shell; /dev/mail stays a launcher readiness route"
  - "Commit trailer is Co-Authored-By: Claude Sonnet 5.5 per the runtime attribution reminder, as in 178-06, not the plan text's Claude Opus 5.5"

requirements-completed: ["UIQ-06", "UIQ-04", "STORY-07"]

coverage:
  - id: D1
    description: "The StatCard story's label, value and UI text resolve to the same first font family and weight as the production Admin gallery StatCard in light and dark, with no serif fallback, loaded production faces, and a .psb-sandbox that resolves to the production UI face"
    requirement: "UIQ-06"
    verification:
      - kind: automated_ui
        ref: "reference/demo_app/assets/e2e/phase178-stories.spec.js#Phase 178 StatCard story uses the production font roles"
        status: pass
    human_judgment: false
  - id: D2
    description: "fb-storybook-fidelity is automated with its pointer at 178-AUTOMATION.md#storybook-fidelity-and-real-zoom-uiq-06, and the merge-blocking ledger test fails if any of the 12 rows is pending or partial"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: no feedback row is pending or partial"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: every non-pending row satisfies the D-08 rule"
        status: pass
    human_judgment: false
  - id: D3
    description: "178-AUTOMATION.md records fidelity, real-zoom receipts, Width selection (320/390/639/640/1280 plus why not 768/1440), Hook receipts (no hook added or changed) and the Feedback ledger section with the 12-row final status table"
    requirement: "UIQ-06"
    verification:
      - kind: command
        ref: "bash -c width-selection and Hook receipts awk/grep verify from 178-07-PLAN task 178-07-01"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs (accounting doc-truth cases still equal the doc tables)"
        status: pass
    human_judgment: false
  - id: D4
    description: "phase174-review.md replays on the installed toolchain (ASDF_ERLANG_VERSION=27.3.4.15), .tool-versions is unchanged, and the review claims tests still pass"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "scripts/phase174-review-claims.test.cjs and scripts/check_phase174_evidence.test.cjs (11 pass, 0 fail)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 07: StatCard font-role receipt and phase-close ledger Summary

**The serif StatCard feedback now has a computed font-role receipt (Storybook vs the production Admin gallery, Inter and IBM Plex Mono, light and dark, `.psb-sandbox` included), `fb-storybook-fidelity` is closed, and a merge-blocking test keeps all 12 owner-feedback rows out of pending and partial.**

## Performance

- **Duration:** 10 min (14:01Z to 14:12Z)
- **Tasks:** 2 (1 tracer, 1 auto)
- **Files:** 5 modified, 1 created (this summary)

## Accomplishments

- **StatCard receipt (UIQ-06, D-07).** `phase178-stories.spec.js` reads computed `font-family` and `font-weight` for the theme root (UI), the label span and the `p.mono` value of the `neutral_light` and `neutral_dark` blocks, and the same three roles from the production gallery cell `gallery-stat_card-neutral` at `/dev/mail/gallery`. It asserts equal first family and weight per role, a production face (not a serif generic), `document.fonts.check` true plus a `loaded` face, and that `.psb-sandbox` resolves to the production UI face. The case has teeth: with `.psb-sandbox { font-family: Georgia, serif }` injected it fails with expected "Inter", received "Georgia".
- **Ledger closed (UIQ-04, D-07/D-15).** `fb-storybook-fidelity` is `automated`, `pending_phases` is removed, the pointer is `178-AUTOMATION.md#storybook-fidelity-and-real-zoom-uiq-06`, and the disposition names the StatCard receipt, the five Phase 178 real-zoom cases and the extended Phase 171 case. The "known open" test is replaced by the invariant "Phase 178 ledger: no feedback row is pending or partial" (45 tests, 0 failures).
- **Records.** `178-AUTOMATION.md` gained `## Storybook fidelity and real zoom (UIQ-06)` (receipt, real-zoom table, CI lanes, `### Width selection`, `### Hook receipts`, limits) and `## Feedback ledger (UIQ-04)` (D-08 rule, merge-blocking test and teeth, dual-location resolver, replaced demo assertion, 12-row final status table).
- **Hooks (SC4).** `grep -n 'phx-hook'` over `assigns_form.ex` and `sidebar.ex` prints nothing (exit 1); `tabs.ex` still carries `PreviewTabs` (line 40) and `PreviewPanelScroll` (line 71); `tabs.ex` and `priv/static/hooks.js` have no diff since `phase_base_sha`. No new hook receipt is needed.
- **D-11.** `phase174-review.md` replay command uses `ASDF_ERLANG_VERSION=27.3.4.15`; `.tool-versions` is unchanged and has no log since `phase_base_sha`. The limits paragraph cites 178-AUTOMATION.md, and the Feedback disposition table states each row's manifest status and pointer.

## StatCard families before and after

Computed first family and weight, identical in the story and in production for both themes (full record in `178-AUTOMATION.md`):

| Role | Before (no receipt; same on committed `2a4c64b0`) | After (receipt, committed `890a7e67`) |
| --- | --- | --- |
| UI text | Inter 400 | Inter 400 |
| Label | Inter 700 | Inter 700 |
| Value | IBM Plex Mono 700 | IBM Plex Mono 700 |

No fix was applied, so before equals after. The serif the owner reported does not reproduce at this revision (`.psb-sandbox` computes Inter). The full stacks differ after the first family (the story lists `"Segoe UI", Roboto, "Helvetica Neue"`, the gallery does not); the receipt asserts the first family, which decides the rendered face once loaded.

## Gate G178-07-DEMO

- **Record:** `reference/demo_app/tmp/phase178_candidate/statcard-1793282939.json` (gitignored)
- **Source:** committed `890a7e67`
- **Result:** 2 passed (Preview authoring stories, StatCard receipt)
- **Wall:** 112 s against the 900 s bound
- **Teardown:** compose project stopped, worktree removed, `mix.lock` restored, 0 `mailglass-phase178-review-*` containers left, owner review-demo container count unchanged at 2
- **First run (`2a4c64b0`):** red in 81 s because the case looked for an iframe (see Deviations); torn down cleanly with the same container checks.

## Verification

- `feedback_ledger_test.exs --seed 0 --trace`: 45 tests, 0 failures; "Phase 178 ledger: no feedback row is pending or partial" appears in the trace.
- `mix verify.support_contract.admin --seed 0`: 1183 tests, 0 failures, 1 excluded.
- `mix format --check-formatted test/mailglass_admin/feedback_ledger_test.exs`: clean.
- `node --test scripts/phase174-review-claims.test.cjs scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs`: 18 pass, 0 fail.
- `npx playwright test --list e2e/phase178-stories.spec.js` lists the StatCard case; the demo suite lists 111 tests in 14 files and the Admin suite is unchanged at 311 in 18.
- Acceptance: manifest node check exits 0 (baseline 1); UIQ-06 heading count 1; one `### Width selection` naming 320, 390, 639, 640, 1280, 768 and 1440; `### Hook receipts` count 1; `27.3.4.13` count 0 and `27.3.4.15` count 1; `.tool-versions` clean; `git status --short mailglass_admin/priv/static reference/demo_app/mix.lock` empty.

## Task Commits

1. **Task 1 (tracer): receipt, closed row, invariant** - `2a4c64b0`
2. **Task 1 fix: inline variation lookup and sandbox assertion** - `890a7e67`
3. **Task 2: ledger record and D-11 command** - `6421930e`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] StatCard story renders inline, not in an iframe**
- **Found during:** Task 1, gate G178-07-DEMO first run
- **Issue:** The receipt looked for `iframe[id*="variation-neutral_light"]`, as the retained Preview authoring case does. The StatCard is a `:component` story without `container: :iframe`, so PhoenixStorybook renders each variation inline inside `.psb-sandbox` in the explorer page; the case failed with 0 iframes (the production half had already passed).
- **Fix:** Resolve the variation block by its generated id (`#neutral-light-component`, `#neutral-dark-component`), and additionally assert `.psb-sandbox` resolves to the production UI face, since that is the element the owner's todo names. Proved the new assertion with a Georgia sandbox mutation (fails: expected "Inter", received "Georgia"); the spec was restored from a copy, not reverted from git.
- **Files modified:** `reference/demo_app/assets/e2e/phase178-stories.spec.js`
- **Commit:** `890a7e67`

### Plan-text drift (no behavior change)

- The production reference is `/dev/mail/gallery` (cell `gallery-stat_card-neutral`), because `/dev/mail` itself renders no StatCard; `/dev/mail` stays as a launcher readiness route.
- The plan expected the isolated demo to take more than 300 s; the image layers were cached, so the gate took 112 s. The 900 s bound and the record are unchanged.
- The "Reproduce and check" section already existed from 178-05, so only the two named sections were appended.
- Commits use `Co-Authored-By: Claude Sonnet 5.5` per the runtime attribution reminder.

**Total deviations:** 1 auto-fixed (bug), plus plan-text drift. **Impact:** none on scope; the receipt got stronger (sandbox assertion with a proven mutation).

## Authentication Gates

None.

## Known Stubs

None.

## Issues Encountered

None beyond the iframe deviation. Plan `<automated>` blocks were run under `bash -c` as required; the gate was run through a scratch script copy of the plan's command.

## Threat Flags

None. T-178-18: no shipped bundle or story template was edited, and `mailglass_admin/priv/static` is clean. T-178-33: the gate used only `scripts/check_phase178_candidate.sh` and left the owner's review demo containers untouched (count 2 before and after). T-178-SC: no package installs and no lockfile changes.

## Next Phase Readiness

- UIQ-06, UIQ-04 and STORY-07 are also declared by sibling plans (178-08 to 178-11), so `REQUIREMENTS.md` stays unticked until the last declaring plan finishes.
- 178-11 (prohibition contract) can assume `FeedbackLedger.open_rows/1` is `%{pending: [], partial: []}`, so its P6 clean state holds.
- The `Demo Browser Evidence` lane already picks up the StatCard case (the demo suite runs `e2e/*.spec.js`); no CI registration is needed.

## Self-Check: PASSED

- Files exist: `reference/demo_app/assets/e2e/phase178-stories.spec.js`, `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs`, `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md`, `mailglass_admin/docs/phase174-review.md`.
- Commits exist on `main`: `2a4c64b0`, `890a7e67`, `6421930e`.
