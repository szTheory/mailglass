---
phase: 175-delivery-investigation-and-safe-replay
plan: "04"
subsystem: ui
tags: [delivery-replay, liveview, authorization, playwright, idempotency]

# Dependency graph
requires:
  - phase: 175-02
    provides: Scoped replay review, exact target identity, authorization and idempotent command foundation.
  - phase: 175-03
    provides: Delivery replay entry points and adverse identity handling used by recovery.
provides:
  - Mounted inline Delivery replay failure feedback with a fresh exact-scope review path.
  - Test proof for revoked authorization, exact target retention, unavailable review, and truthful no-change outcome.
affects: [175-05, 175-06, delivery-replay, operator-live]

# Actuals (#2632)
actuals:
  tokens: 12994.5
  tasks: 2
  commits: 3
commits: 3
plan_head_before: cca14fe5f3640922d3d97639cd3a7772cbf74dc1
plan_head_after: b5b15dad25ee2e6a601c1692c9020ade0e000e55

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Mounted replay-dialog feedback keeps safe failure copy and an explicit fresh-review action beside the exact retained request.
    - Test-only authorization revocation seam proves host access is checked again at confirmation time.

key-files:
  created:
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-04-02-red-evidence.json
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_action.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/e2e/flows.spec.js

key-decisions:
  - "A failed replay stays in the mounted dialog and requires a fresh scoped review before another confirmation."
  - "When exact target evidence is unavailable, offer review again without enabling replay confirmation."
  - "Keep existing authorization, audit and idempotency transaction boundaries; the revocation switch exists only in test support."

patterns-established:
  - "Replay failures use structured safe dialog copy and clear pending state while preserving the selected request identity."
  - "Fresh review creates a new one-shot review from the same selected Account, Delivery and exact eligible target set."

requirements-completed: ["REPLAY-04", "REPLAY-05", "REPLAY-06", "REPLAY-07", "REPLAY-08"]

# Coverage metadata
coverage:
  - id: D1
    description: "Command failure remains visible in the same dialog and can recover after a fresh eligibility review."
    requirement: REPLAY-08
    verification:
      - kind: unit
        ref: "test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery recovery re-reviews the exact request after command failure"
        status: pass
      - kind: e2e
        ref: "flows.spec.js#Phase 175 Delivery recovery and Phase 168 confirmation focus"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact target identity is retained and revoked authorization blocks replay with no unintended audit write."
    requirement: REPLAY-04
    verification:
      - kind: unit
        ref: "test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery safety rechecks authorization revoked after review opens"
        status: pass
      - kind: e2e
        ref: "flows.spec.js#Phase 175 Delivery safety keeps exact target, denial and no-change outcomes visible"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unavailable exact target evidence explains the state and does not enable replay confirmation."
    requirement: REPLAY-05
    verification:
      - kind: unit
        ref: "test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery entry explains unavailable replay and rejects forged identities"
        status: pass
      - kind: e2e
        ref: "flows.spec.js#Phase 175 Delivery safety keeps exact target, denial and no-change outcomes visible"
        status: pass
    human_judgment: false
  - id: D4
    description: "The shared replay dialog retains its accessible confirmation flow, and permitted replay reports the persisted new-work or no-change result."
    requirement: REPLAY-06
    verification:
      - kind: unit
        ref: "test/mailglass_admin/operator_live_test.exs#operator replay and persisted outcome cases"
        status: pass
      - kind: e2e
        ref: "flows.spec.js#Phase 168 confirmation focus and Phase 175 Delivery safety"
        status: pass
    human_judgment: false
  - id: D5
    description: "Replay success feedback and refreshed evidence reflect the actual persisted no-change outcome."
    requirement: REPLAY-07
    verification:
      - kind: unit
        ref: "test/mailglass_admin/operator_live_test.exs#persisted replay outcome and idempotency cases"
        status: pass
      - kind: e2e
        ref: "flows.spec.js#Phase 175 Delivery safety keeps exact target, denial and no-change outcomes visible"
        status: pass
    human_judgment: false

# Metrics
duration: 30min
completed: 2026-10-27
status: complete
---

# Phase 175 Plan 04: Delivery Failure Recovery Summary

**Delivery replay failures remain mounted and recover through a fresh exact-scope review, with action-time authorization and persisted no-change outcomes proven.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-10-27T16:08:37Z
- **Completed:** 2026-10-27T16:38:39Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Kept stale, denied, unavailable and command-failure feedback inside the open replay dialog; the same request identity remains visible and a fresh review is reachable.
- Preserved exact scoped reread, current host authorization, one-shot review behavior, existing audit/idempotency writes and truthful new-work/no-change result messaging.
- Added server and browser proof for an exact-target recovery, auth revoked after review opened, unavailable pre-dialog state, pending confirmation, and persisted no-change feedback.

## Task Commits

Each task was committed atomically:

1. **Task 1: Recover a failed Delivery replay in the mounted dialog** - `09ee6a6f` (`feat`).
2. **Task 2 RED: Prove action-time authorization revocation** - `10644a9a` (`test`).
3. **Task 2 GREEN: Retry unavailable Delivery replay reviews** - `b5b15dad` (`fix`).

## Files Created/Modified

- `.planning/phases/175-delivery-investigation-and-safe-replay/175-04-02-red-evidence.json` - Captures the intended failing revocation assertion and semantic RED assessment.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Keeps failures mounted and rebuilds a fresh review for the selected Delivery.
- `mailglass_admin/lib/mailglass_admin/operator/replay_action.ex` - Allows a fresh retry from an initial target-read-unavailable review state.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` - Renders safe inline failure copy and Review again without enabling confirm for an unavailable target.
- `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` - Provides truthful retry guidance for unavailable replay evidence.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Covers command failure recovery, revoked access, exact identity, and persisted outcome assertions.
- `mailglass_admin/test/support/endpoint_case.ex` - Adds a test-only current-authorization revocation control.
- `mailglass_admin/e2e/flows.spec.js` - Covers mounted recovery, unavailable state, deliberate exact-target choice, denial, pending controls, and no-change feedback.

## Decisions Made

- Retain the dialog and exact selected request after failure; recovery always starts with a new scoped read and one-shot review.
- An unavailable exact target permits “Review again” but never a replay confirmation action.
- Keep host authorization, audit and idempotency at the existing command boundary; do not add domain storage or provider contracts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added a review retry from the initial unavailable-target state**
- **Found during:** Task 2 (exact identity and adverse outcomes)
- **Issue:** An initial scoped target read failure had explanatory text directing the operator to review again, but no reachable retry control existed.
- **Fix:** Added a review-only action for the unavailable dialog state while keeping replay confirmation disabled until exact eligible evidence is available; updated stale retry copy and expectations in older dialog tests.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/replay_action.ex`, `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`, `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Verification:** Full operator and auth contract suites and the named Phase 175 browser safety flow passed.
- **Committed in:** `b5b15dad`

**Total deviations:** 1 auto-fixed (Rule 2 - missing critical functionality)
**Impact on plan:** Closed a recovery dead end while preserving the required exact identity and confirmation safety boundary.

## TDD Gate Compliance

- RED evidence is persisted in `175-04-02-red-evidence.json`; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- The tagged authorization-revocation test ran and failed on the planned denial-copy assertion because the test auth adapter ignored the revocation toggle. No setup, compile or unrelated failure occurred.
- RED was committed as `10644a9a`; the test-only revocation seam and passing implementation were committed as `b5b15dad`.
- GREEN verification: the full operator and auth contract command passed with **124 tests, 0 failures**; the tagged Phase 175 command passed with **120 tests, 0 failures, 110 excluded**.

## Verification Evidence

- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/auth_actions_contract_test.exs --trace` — **124 tests, 0 failures**.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase175 --trace` — **120 tests, 0 failures, 110 excluded**; named Phase 175 cases appeared in trace output.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 Delivery recovery|Phase 168 confirmation focus"` — **2 passed**.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 Delivery safety"` — **1 passed**.
- `mix format --check-formatted` for touched Elixir files and `git diff --check` passed.

## Issues Encountered

- The initial unavailable-target dialog lacked a reachable “Review again” action despite its retry guidance; this was fixed and covered before completion.
- No auth gate or new network, storage, provider, or schema surface was introduced.

## Known Stubs

None. The scan found only intentional empty HTML option values and the user-facing “not available” state copy; no placeholder implementation, TODO/FIXME, skipped test, or unrun planned verification remains.

## Next Phase Readiness

Plans 175-05 and 175-06 can continue from this safe recovery behavior. The plan’s five requirement IDs are recorded above as completed for plan traceability; the shared requirements readiness gate still reports no ready IDs because sibling phase plans retain those requirements, so the shared checklist remains pending.

---
*Phase: 175-delivery-investigation-and-safe-replay*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary file exists at the planned phase path.
- Task commits `09ee6a6f`, `10644a9a`, and `b5b15dad` are ancestors of HEAD.
- Measured task commit count is 3 from plan base `cca14fe5f3640922d3d97639cd3a7772cbf74dc1`.
