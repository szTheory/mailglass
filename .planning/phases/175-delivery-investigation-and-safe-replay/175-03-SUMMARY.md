---
phase: 175-delivery-investigation-and-safe-replay
plan: "03"
subsystem: operator-ui
tags: [phoenix-liveview, replay, accessibility, inbound, delivery, playwright]
requires:
  - phase: 175-01
    provides: Exact scoped replay command seams and the shared dialog presentation used by Inbound.
provides:
  - Accessible replay dialog presentation shared by Inbound and Delivery while wrappers retain domain-specific identities and outcomes.
  - Exact eligible Inbound replay entry from quick and full detail, with recoverable focus and visible technical evidence.
affects: [175-04, 175-05, replay, operator-ui]
actuals:
  tokens: 17630.25
  tasks: 3
  commits: 5
commits: 5
plan_head_before: 3197c1458f00f31a58c31c86ed350a350d749fae
plan_head_after: 012169207246d9d04f81f5b084e362ddad9a0deb
tech-stack:
  added: []
  patterns:
    - Shared dialog owns only accessible overlay, focus, keyboard and motion presentation; domain wrappers retain identity, data and commands.
    - Inbound quick-view replay eligibility is server-derived from the selected scoped record and existing recorded Mailbox eligibility.
key-files:
  created:
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-03-02-red-evidence.json
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-03-03-red-evidence.json
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/e2e/phase175-inbound.spec.js
    - mailglass_admin/e2e/structural.spec.js
key-decisions:
  - "Keep authorization, exact identity and domain commands in the existing LiveViews and wrappers; the shared shell supplies presentation only."
  - "Only expose Inbound quick replay when the current server-derived exact selection is eligible, and return focus to the exact quick or full trigger."
  - "Keep unavailable Delivery replay explanatory and non-actionable; structural browser checks select seeded exact or ambiguous targets."
patterns-established:
  - "Lower the quick-view panel while its replay dialog is open so the modal layer receives pointer input, while preserving the selected record and disabling underlying arrow navigation."
  - "Use the same accessible shell contract with separate recorded Mailbox and stored webhook identities, outcomes and commands."
requirements-completed: ["UXF-12","REPLAY-04","REPLAY-06","REPLAY-07","REPLAY-08"]
coverage:
  - id: D1
    description: Both replay wrappers use the shared accessible dialog shell while retaining distinct domain identity and confirmation semantics.
    requirement: REPLAY-06
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/components_test.exs test/mailglass_admin/inbound/components_test.exs --only phase175 --trace (shared shell wrapper cases)"
        status: pass
      - kind: automated_ui
        ref: "playwright structural.spec.js --grep replay|Replay (14 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: An eligible exact Inbound record can enter replay review from quick or full detail and retains Account, filter, selection and keyboard context.
    requirement: REPLAY-04
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound/components_test.exs#quick view offers an exact replay review only when recorded Mailbox eligibility is clear"
        status: pass
      - kind: automated_ui
        ref: "playwright phase175-inbound.spec.js --grep Phase 175 Inbound quick (1 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: Full Inbound technical facts are open by default and long Unicode identifiers remain visible and wrapped.
    requirement: UXF-12
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound/components_test.exs#full Inbound technical facts stay open with long Unicode identifiers"
        status: pass
    human_judgment: false
  - id: D4
    description: Successful Inbound replay closes the review, reports the actual recorded Mailbox result and refreshes evidence.
    requirement: REPLAY-07
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/inbound_live_test.exs --only phase175 --trace (9 executed, 0 failed)"
        status: pass
      - kind: automated_ui
        ref: "playwright phase175-inbound.spec.js --grep Phase 175 Inbound full (2 passed)"
        status: pass
    human_judgment: false
  - id: D5
    description: Stale, denied and failed Inbound replay review remains mounted with safe feedback and fresh re-review available.
    requirement: REPLAY-08
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/inbound_live_test.exs --only phase175 --trace (9 executed, 0 failed)"
        status: pass
    human_judgment: false
duration: "~29 min (approximate; plan start was not persisted)"
completed: 2026-10-27
status: complete
---

# Phase 175 Plan 03: Delivery Investigation and Safe Replay Summary

**Inbound quick/full replay now shares an accessible review shell with Delivery while preserving each domain’s exact identity and command outcome.**

## Performance

- **Duration:** approximately 29 minutes.
- **Started:** approximately 2026-10-27T15:36:00Z (start inferred from the prior plan’s final commit and dispatch timing).
- **Completed:** 2026-10-27T16:05:24Z.
- **Tasks:** 3/3.
- **Files modified:** 13 unique committed paths, including two persisted TDD evidence records.

## Accomplishments

- Added `Components.replay_dialog/1` as a presentation-only shell and moved the Delivery wrapper into it without merging Delivery webhook reprocessing and Inbound recorded Mailbox execution.
- Exposed eligible Inbound replay from Quick view using server-derived exact-record eligibility; preserved quick/full trigger focus, filter and Account context, keyboard containment and open full-detail technical facts.
- Kept Inbound stale/auth/command failures mounted with safe feedback and a fresh-review action, and verified successful recorded Mailbox outcomes refresh the evidence and announce the actual result.

## Task Commits

Each task was committed atomically. TDD tasks have a RED evidence/test commit followed by a GREEN implementation commit.

1. **175-03-01 — Complete and recover a recorded Inbound replay:** `41addb1a` (`feat(175-03-01): recover Inbound replay through shared dialog`).
2. **175-03-02 — Expose Inbound quick replay and grouped full technical facts:** `7e6c8578` (`test(175-03-02): specify quick replay and open technical evidence`), then `32484ad8` (`feat(175-03-02): add quick replay and open technical evidence`).
3. **175-03-03 — Reuse dialog presentation on Delivery:** `5fd3e730` (`test(175-03-03): add failing shared replay shell contract`), then `01216920` (`feat(175-03-03): use shared shell for Delivery replay`).

**Plan summary commit:** `ce5acdcd` (`docs(175-03): record replay review execution summary`).

**Measured plan commit count:** 5 commits from `3197c1458f00f31a58c31c86ed350a350d749fae` through `012169207246d9d04f81f5b084e362ddad9a0deb`. The summary and GSD metadata commits are separate.

## Verification

- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs --only phase175 --trace` — 9 Phase 175 tests executed, 0 failures, 75 excluded.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound/components_test.exs --only phase175 --trace` — 2 Phase 175 tests executed, 0 failures, 28 excluded.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/components_test.exs test/mailglass_admin/inbound/components_test.exs --only phase175 --trace` — 6 Phase 175 tests executed, 0 failures, 139 excluded.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/auth_actions_contract_test.exs --trace` — 4 tests executed, 0 failures.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase175-inbound.spec.js --grep "Phase 175 Inbound full"` — 2 passed, 0 skipped. Covers the recorded Mailbox outcome, refreshed timeline and Escape focus return.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase175-inbound.spec.js --grep "Phase 175 Inbound quick"` — 1 passed, 0 skipped. Covers exact record/Account/filter context, arrow suppression, forward/reverse Tab containment, Escape and pointer-operable Cancel focus return.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- structural.spec.js --grep "replay|Replay"` — 14 passed, 0 skipped across shared shell, exact/ambiguous Delivery targets, Inbound focus parity, theme, stacking, scroll containment and trigger restoration.
- `git diff --check` — passed. Both persisted RED records returned `RED_EVIDENCE_OK`; their named target assertions and failure reasons were semantically inspected.

## TDD Gate Compliance

- **Task 175-03-02 RED:** `175-03-02-red-evidence.json` records the exact QuickView test failing because `#inbound-quick-replay-open-btn` was absent before implementation; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`. The assertion was specific to the planned exact eligible review control. RED commit `7e6c8578` precedes GREEN commit `32484ad8`.
- **Task 175-03-03 RED:** `175-03-03-red-evidence.json` records the exact Delivery shell test failing because the old wrapper used `p-4` instead of the shared shell’s `p-md`; the target assertion failed after successful compilation. The classifier returned `RED_EVIDENCE_OK`. RED commit `5fd3e730` precedes GREEN commit `01216920`.
- Global TDD mode was disabled; both task-level TDD cycles were completed and gated as required.

## Files Created/Modified

- `.planning/phases/175-delivery-investigation-and-safe-replay/175-03-02-red-evidence.json` and `175-03-03-red-evidence.json` — persisted target-specific TDD RED evidence.
- `mailglass_admin/lib/mailglass_admin/components.ex` — shared accessible replay presentation shell.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex`, `inbound_live.ex`, `inbound/quick_view.ex`, `inbound/detail_header.ex` — recorded Mailbox dialog, fresh eligibility, focus restoration and quick/full presentation.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` — Delivery wrapper using the same shell while retaining exact webhook selection, identity, command and consequence copy.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`, `inbound/components_test.exs`, `components_test.exs` — tagged replay, quick-entry, technical-fact and cross-wrapper shell assertions.
- `mailglass_admin/e2e/phase175-inbound.spec.js`, `mailglass_admin/e2e/structural.spec.js` — connected Inbound recovery/context and replay-shell structural proof.

## Decisions Made

- The shell owns only overlay semantics, focus trap, named Close, Escape handling and restrained motion. Each wrapper retains its identity, eligibility, data, confirmation and domain outcome.
- Inbound quick review stays bound to the selected Account-scoped record and recorded Mailbox; its browser origin only determines the exact trigger used for focus return.
- Missing Delivery replay linkage remains explanatory and non-actionable; automated structural flows choose the seeded exact or ambiguous target instead of asserting a dead-end action.
- D-52 applies: observable interaction and result criteria close with automated evidence, with no owner UAT requested.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Lowered the underlying Inbound Quick view while replay review is open.**

- **Found during:** Task 2.
- **Issue:** The fixed Quick view panel at overlay z-index 40 intercepted pointer input from the shared dialog scrim at z-index 30, so Cancel could not be clicked from quick-entry review.
- **Fix:** While the replay dialog is open, the Quick view panel uses its base layer; the shared review remains above it and the selected Quick view stays mounted.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`.
- **Verification:** Named Quick Inbound browser case passed, including pointer-clicking Cancel, restoring focus and preserving the route context.
- **Committed in:** `32484ad8`.

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** Required for the planned quick-entry dialog controls to be operable; no command, authorization or storage boundary changed.

## Issues Encountered

- The first structural browser attempt selected `browser-selected@example.com`, a fixture whose replay is intentionally unavailable, and waited for a control the UI correctly omits. The helper now selects seeded exact and ambiguous targets. The shared shell also names its X button “Close”; the stale structural accessible-name assertion was updated. The final requested structural group passed 14/14.
- The first draft of the component contract needed the Inbound review ID fixture and domain-specific confirmation styles (`btn-error` for recorded Inbound execution, `btn-primary` for Delivery). Those test-fixture/assertion corrections were included in the GREEN commit; the final tagged component run passed.

## Known Stubs

None found in the files created or modified by this plan.

## User Setup Required

None.

## Next Phase Readiness

Plan 175-04 can proceed against the tested shared dialog contract. The plan’s shared REPLAY requirement IDs remain pending until their final declaring summary.

## Self-Check: PASSED

The summary path exists; all five task commits are ancestors of the plan head; the 13 modified paths match the measured plan diff; all named unit, browser and auth-contract checks passed with nonzero expected counts.

---
*Phase: 175-delivery-investigation-and-safe-replay*
*Completed: 2026-10-27*

## Orchestrator metadata reconciliation

The declared requirement IDs above match PLAN.md verbatim; shared IDs remain pending until all declaring plans finish. Production/TDD commits used task-suffixed subjects that the installed plan-scope resolver does not match: `41addb1a`, `7e6c8578`, `32484ad8`, `5fd3e730`, and `01216920`. Final code review and verification must explicitly include these commits and the plan-declared paths rather than infer no production changes from that resolver result. No history was rewritten.
