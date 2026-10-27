---
phase: 175-delivery-investigation-and-safe-replay
plan: "02"
subsystem: operator-ui
tags: [suppression, phoenix-liveview, accessibility, playwright, tdd]
requires:
  - phase: 175-01
    provides: Selected Delivery investigation context and the existing Account-scoped suppression read.
provides:
  - Honest ready, stale, unavailable, and empty suppression refresh states with a stable, focus-restoring Refresh/Retry action.
  - Plain-language expiry and reason-based removal policy on the read-only suppression card.
  - Connected proof that refresh observes external row changes and expiry only within the selected Account and stream.
affects: [Delivery full detail, suppression investigation, operator accessibility]
actuals:
  tokens: 8671
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 3125e31fc3e9407b2f2ceb9f942320644a970ffc
plan_head_after: ac38dab912ab432001032931e0a5c683179b97d5
tech-stack:
  added: []
  patterns:
    - Refresh continues to call the existing tenant, recipient, and stream-scoped read; last-known facts remain separate from fresh-read status.
    - A LiveView completion event restores focus to the stable suppression Refresh/Retry action after its in-flight disabled state.
key-files:
  created:
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-02-red.tap
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-02-red-evidence.json
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
    - mailglass_admin/priv/static/hooks.js
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/phase169-journey.spec.js
key-decisions:
  - "Keep suppression refresh on the existing scoped query; external changes and expiry are proved through fresh LiveView reads without changing domain semantics."
  - "Render only recorded policy and expiry facts: reason-based allow/block copy for known policy values, and explicit not-recorded copy when expiry or policy is unknown."
requirements-completed: [OUTUX-07, OUTUX-08]
coverage:
  - id: D1
    description: Suppression refresh distinguishes a current match, successful empty result, retained stale match, and unavailable read while observing fresh Account/recipient/stream-scoped data.
    requirement: OUTUX-07
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 suppression refresh marks retained evidence stale and recovers on retry"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 suppression refresh keeps initial failure unavailable and successful empty distinct without writes"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 suppression policy refresh observes external changes, expiry, and Account/stream scope"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 175 suppression refresh (1 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: The read-only card explains known removal policies in plain language, identifies an unrecorded expiry, and keeps missing and long Unicode values safe.
    requirement: OUTUX-08
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 suppression policy states removal support, unknown expiry, and safe missing values"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 suppression policy refresh observes external changes, expiry, and Account/stream scope"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 175 suppression policy (1 passed)"
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-10-27
status: complete
---

# Phase 175 Plan 02: Delivery Investigation and Safe Replay Summary

**Delivery suppression refresh now preserves stale evidence truthfully and explains recorded expiry and removal policy without changing the scoped query.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-10-27T15:12:20.762Z
- **Completed:** 2026-10-27T15:33:13Z
- **Tasks:** 2
- **Files modified:** 8 (6 implementation/test files and 2 committed RED evidence files)

## Accomplishments

- Kept suppression state truthful across current match, successful empty, stale retained facts, and unavailable reads. Retry performs a new existing Account/recipient/stream-scoped read, restores focus, and changes no domain rows.
- Replaced command-centric suppression copy with “Removal policy,” reason-based allow/block language, and “Expiry date not recorded.” The card retains its single read-only Refresh/Retry action and Account scope explanation.
- Proved through LiveView reads that an external synthetic source update appears on refresh, an expired match disappears, and same-recipient facts from another Account or stream do not leak into the selected Delivery.
- Added TDD RED report/evidence and tagged policy, expiry, missing-value, Unicode escaping, scope, and refresh coverage.

## Verification

- Tagged server acceptance: `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase175 --trace` — **118 tests discovered, 8 phase175 cases executed, 0 failures, 110 excluded**. The active cases include both refresh transitions, external updates/expiry/Account-stream isolation, and safe policy/missing-value rendering.
- Task 1 browser tracer: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep 'Phase 175 suppression refresh'` — **1 passed**; it verifies stale retained values, focus restoration, same route/selection, and fresh changed facts after retry.
- Task 2 browser policy: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep 'Phase 175 suppression policy'` — **1 passed**; it verifies supported/blocked copy, recorded/unknown expiry, stable action placement, and absence of a mutation action.
- Updated shared-card journey: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase169-journey.spec.js --grep 'Phase 169 current suppression stays distinct'` — **1 passed**.
- Elixir formatting and `git diff --check` passed.

## Task Commits

1. **Task 1: Refresh one scoped suppression through failure and successful retry** — `adc1ecc8` (`feat`)
2. **Task 2 RED: Add failing suppression policy proof** — `c7705c4b` (`test`)
3. **Task 2 GREEN: Explain suppression expiry and removal policy** — `ac38dab9` (`feat`)

The Summary and state/roadmap metadata commits are created during closeout.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — Tracks scoped last-known suppression data separately from ready/stale/unavailable read status and emits completion for focus restoration.
- `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex` — Shows the approved expiry and removal policy copy while preserving the read-only, Account-local card.
- `mailglass_admin/priv/static/hooks.js` — Restores focus to the same Refresh/Retry action after a LiveView read completes.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — Adds tagged state, external-change, expiry, Account/stream, unknown-policy, missing-value, timestamp, and Unicode escaping assertions.
- `mailglass_admin/e2e/flows.spec.js` — Adds the named Phase 175 refresh and policy browser checks.
- `mailglass_admin/e2e/phase169-journey.spec.js` — Keeps existing shared-card expectations aligned with the approved wording.
- `.planning/phases/175-delivery-investigation-and-safe-replay/175-02-red.tap` and `175-02-red-evidence.json` — Preserve the actual 8-case RED report and classifier input.

## Decisions Made

- Kept `Mailglass.Operator.Suppressions.get_delivery_suppression_state/2` unchanged; the current service already filters by tenant and expiry before matching recipient/domain/stream.
- Unknown removal policy and expiry remain explicitly unrecorded; no permanence claim or suppression mutation control was added.

## TDD Gate Compliance

- **RED:** The named target `test operator surface Phase 175 suppression policy states removal support, unknown expiry, and safe missing values` failed on the intended `Removal policy` copy assertion. The same TAP run executed 8 phase175 cases; the real scoped external-change/expiry/Account-stream test passed while the target policy-copy test failed. `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check tdd-red-evidence .planning/phases/175-delivery-investigation-and-safe-replay/175-02-red-evidence.json --raw` returned **`RED_EVIDENCE_OK`**. RED commit: `c7705c4b`.
- **GREEN:** The required tagged server command passed all 8 phase175 cases. Both named browser acceptance cases passed. GREEN commit: `ac38dab9`.
- **REFACTOR:** None needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restore focus after suppression reads disable the action**
- **Found during:** Task 1 (Refresh one scoped suppression through failure and successful retry)
- **Issue:** The browser tracer showed that LiveView’s in-flight disabled state could leave focus off the stable refresh action after the read completed.
- **Fix:** Added a completion event and `SuppressionRefreshFocus` hook that returns focus to the existing action; supplied the stable DOM id required by the hook.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex`, `mailglass_admin/priv/static/hooks.js`, `mailglass_admin/e2e/flows.spec.js`
- **Verification:** The named browser refresh test asserts action focus after both failed and successful reads; it passed.
- **Committed in:** `adc1ecc8`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Focus recovery completes the planned stable-action behavior; the scoped read and domain semantics are unchanged.

## Issues Encountered

- An initial synthetic foreign suppression fixture violated the database rule that complaint rows have no expiry. The fixture was corrected to a valid manual row before the recorded RED run; the final scope/expiry integration case passed.
- Browser execution required host access because macOS Chromium could not start in the default sandbox. The named cases passed after the authorized escalation.
- Best-effort append of the focus deviation to `.planning/WINDOWS.md` was refused because that existing ledger’s rendered table disagrees with its fenced JSON source for row 48. No ledger file was changed; the unrelated inconsistency was preserved.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. Suppression facts remain wired to the existing scoped query; empty and unknown values are intentional presentation states.

## Next Phase Readiness

The suppression refresh and policy states are ready for the dependent Phase 175 plans. `requirements.ready-ids` returned 0/2 because `OUTUX-07` and `OUTUX-08` are shared with unfinished sibling plans; REQUIREMENTS.md remains pending until those summaries are complete. No owner UAT or external setup remains for this plan.

---
*Phase: 175-delivery-investigation-and-safe-replay*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary and both persisted RED evidence files exist; the evidence JSON parses.
- The Task 1, Task 2 RED, and Task 2 GREEN commits are ancestors of the current HEAD.
- All three task commits have no tracked-file deletions.
- The classifier accepted the recorded RED report as `RED_EVIDENCE_OK`; final tagged server and browser checks passed.
