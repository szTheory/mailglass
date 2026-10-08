---
phase: 169-outbound-investigation-and-recovery
plan: "04"
subsystem: operator-ui
tags: [phoenix-liveview, webhook-replay, audit-evidence, accessibility]

requires:
  - phase: 169-03
    provides: bounded event history and current suppression evidence for outbound recovery
provides:
  - frozen exact webhook replay review with action-time material revalidation and host authorization
  - one-submit replay guard and truthful separation of command feedback from persisted audit evidence
affects: [169-05, outbound-recovery, operator-trust]

actuals:
  tokens: 83085
  tasks: 2
  commits: 3
commits: 3
plan_head_before: efd2db2948db515d8f906d9e59f8ccc529e2b68e
plan_head_after: 5bdc10980d8f1b2265f5c967fd9b8884e10aa596

tech-stack:
  added: []
  patterns:
    - Freeze and compare the exact replay candidate tuple before calling host authorization.
    - Keep local command result feedback independent from persisted audit read state.

key-files:
  created: []
  modified:
    - lib/mailglass/operator/replay_targets.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/docs/operator-trust.md
    - test/mailglass/operator/replay_targets_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Freeze the selected webhook ID and all consequence-relevant Account, Delivery, provider, receipt-time, and eligibility facts at review open."
  - "Re-read and compare the same target before host authorization; reject stale or replaced review without selecting a substitute."
  - "Use command-returned row counts for local outcomes and persisted audit reads only for terminal evidence."
  - "Do not expose raw audit metadata, actor identifiers, failure reasons, or exception bodies in operator feedback."

requirements-completed: [OUTUX-05]

coverage:
  - id: D1
    description: Exact webhook replay is frozen at review and revalidated before action-time host authorization.
    requirement: OUTUX-05
    verification:
      - kind: unit
        ref: "test/mailglass/operator/replay_targets_test.exs --seed 1 (5 passed)"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs and replay_modal_test.exs --seed 1 (103 passed)"
        status: pass
      - kind: e2e
        ref: "Playwright replay-filtered browser sweep on port 4102 (37 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: Replay command outcomes remain separate from requested or unavailable persisted audit evidence.
    requirement: OUTUX-05
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs and replay_modal_test.exs --seed 1 (103 passed)"
        status: pass
      - kind: e2e
        ref: "Playwright replay-filtered browser sweep on port 4102 (37 passed)"
        status: pass
    human_judgment: false

duration: 22m
completed: 2026-10-07
status: complete
---

# Phase 169 Plan 04: Frozen Webhook Replay and Truthful Outcomes Summary

Operators now review one exact stored webhook request, see its Account and Delivery consequences, and submit only after the same material target facts remain eligible and host authorization is rechecked. Replay feedback reports newly normalized rows from the command separately from requested or terminal persisted audit evidence.

## Performance

- **Duration:** 22m from the first plan commit through final implementation verification
- **Started:** 2026-10-07T21:40:12-04:00
- **Completed:** 2026-10-07T22:01:23-04:00
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments

- Froze exact target identity and consequence-relevant facts, rejected stale/replaced targets, and consumed each review before submission.
- Distinguished requested-only audit evidence, newly normalized rows, no-change outcomes, command failures, and unavailable persisted evidence.
- Added deterministic mutation and failure fixtures plus rendered checks for zero/one/many candidates, mobile containment, focus handling, and feedback retention.
- Updated operator trust documentation to clarify that webhook replay reprocesses stored requests through current normalization; it does not resend outbound mail or prove provider receipt.

## Task Commits

1. **Task 1: Freeze and revalidate the reviewed exact webhook target** — `99340a87` (feat)
2. **Task 2: Assert truthful replay outcomes** — `1ec8b7d3` (test, TDD red)
3. **Task 2: Report replay command and evidence separately** — `5bdc1098` (feat, TDD green)

## Decisions Made

- Revalidate the exact selected ID and material tuple before calling host authorization immediately before execution.
- Keep local command outcome and persisted evidence read state as separate operator-visible facts.
- Render only allowlisted audit fields and safe failure cause mappings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bound the replay review to the viewport at narrow widths**
- **Found during:** Task 1 browser verification
- **Issue:** The shared `max-w-2xl` utility resolved to 48px with the app’s custom spacing tokens, putting the Confirm control outside the visible panel.
- **Fix:** Set an explicit `42rem` maximum width and a viewport-bounded, internally scrollable review panel.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`, `mailglass_admin/priv/static/app.css`, and focused E2E selectors/assertions.
- **Verification:** The replay browser sweep passed 37/37, including 320px panel containment and keyboard focus checks.
- **Committed in:** `5bdc1098`

**2. [Rule 1 - Bug] Updated replay browser assertions for consumed review focus and the contracted close label**
- **Found during:** Task 2 browser verification
- **Issue:** Existing tests expected the old “Close” name and expected an already-consumed disabled Confirm button to remain in the keyboard loop.
- **Fix:** Assert the “Close replay review” label and focus the next enabled control after stale authorization consumes the review.
- **Files modified:** `mailglass_admin/e2e/flows.spec.js`, `mailglass_admin/e2e/structural.spec.js`
- **Verification:** All 37 replay-filtered browser tests passed.
- **Committed in:** `5bdc1098`

**Total deviations:** 2 auto-fixed issues. Both were direct correctness and accessibility findings in the changed replay review; no scope expansion was needed.

## Verification

- `mix test test/mailglass/operator/replay_targets_test.exs --seed 1` — 5 passed.
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` — 103 passed.
- `BROWSER_SERVER_PORT=4102 npm run test:operator-browser -- --grep replay` — 37 passed.
- Impeccable detector on the changed replay modal — no findings.
- `git diff --check` — passed.

## Issues Encountered

- The first browser attempt was blocked before test execution because sandboxed Chromium could not register its macOS Mach port. The authorized rerun outside the sandbox completed successfully; no application test failed.

## Next Phase Readiness

Plan 169-05 can run connected rendered acceptance against the frozen replay review and truthful feedback implementation. No plan-level blockers remain.

---
*Phase: 169-outbound-investigation-and-recovery*
*Completed: 2026-10-07*

## Self-Check: PASSED

- SUMMARY file exists at the required phase path.
- Task commits `99340a87`, `1ec8b7d3`, and `5bdc1098` are ancestors of HEAD.
- `gsd_run check evaluation-scope --plan 169-04 --commits-only --raw` resolved all three reachable plan commits with no missing files.

## Orchestrator Post-Wave Integration Gate

Admin compilation passed. The complete Admin suite caught the trust-doc outcome assertion. Review also found residual inbound mailbox execution paragraphs beneath outbound replay semantics. The document now names normalized-row new-work/no-change semantics, states synchronous outbound replay, and labels inbound scheduling/mailbox-history guidance separately. The strengthened contract test checks that separation and unavailable persisted-evidence copy.

Full rerun from `mailglass_admin`: `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 HEX_HOME=/private/tmp/mailglass-169-hex MIX_ENV=test mix test --seed 1` — 536 passed, 0 failed, 1 excluded. Schema and UI gates report `block:false`; codebase-drift abstains with `no-structure-md`.

## Nyquist Escalation Repair Addendum (2026-10-08)

The later adversarial audit found that `Replay.execute/1` allowed a PostgreSQL error from writing the terminal `webhook_replay_succeeded` audit row to escape instead of returning supported command feedback. The replay transaction now converts only `Postgrex.Error` to `{:error, :result_persistence_failed}`; other exception classes retain their prior behavior. Normalized Events and projection writes roll back with the terminal audit failure. The already persisted request remains, and a safe failed audit is attempted afterward.

The core trigger-backed regression now passes **10/10**, asserting the controlled error, retained request and failed audit, absent success audit and normalized rows, unchanged Delivery state, and the safe classified failure reason. The Admin trigger-backed LiveView regression confirms the operator receives safe persistence-failure feedback and does not see the raw exception. Combined focused Admin coverage passes **104/104**. Exact commands and runtime are recorded in `169-VALIDATION.md` → “Adversarial Gap — terminal replay audit database write failure.” This closes the specific OUTUX-05 / T-169-13 escalation; it does not close the separate plan-coverage gaps or change phase-level Nyquist status.
