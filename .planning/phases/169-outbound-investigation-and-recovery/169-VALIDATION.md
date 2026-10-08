---
phase: "169"
slug: "outbound-investigation-and-recovery"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 169 — Validation Strategy

Planning contract only. No Phase 169 product checks, browser launch, or runtime verification have run. All rows below are commands for execution, not passing evidence. Five serial waves contain 12 tasks; every task has a named automated check and an immediately following observable fails_when signal in its PLAN.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit (core and Admin); existing Playwright operator harness |
| Config | Root/Admin Mix projects; `mailglass_admin/playwright.config.cjs` |
| Core quick command | `mix test test/mailglass/operator/deliveries_test.exs test/mailglass/operator/timeline_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/operator/suppressions_test.exs test/mailglass/operator/replay_targets_test.exs --seed 1` |
| Admin quick command | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` |
| Browser focused command | `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169"`; planned named tests in `mailglass_admin/e2e/phase169-journey.spec.js`; zero discovered tests fails the task |
| Full phase command set | Required by 169-05 Task 2 `<verify>` before task completion: named connected browser selection; Core quick command; complete Admin `cd mailglass_admin && mix test --seed 1`; asset build and parity checks below; full existing and new operator browser suite `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser` without grep. Record each result on the current revision in 169-BASELINE.md. |
| Asset checks | `cd mailglass_admin && mix mailglass_admin.assets.build`; `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1`; compare source, built and served CSS hashes |
| Runtime | Execution preflight inventories `asdf list erlang`, `asdf list elixir`, `elixir --version`; select an installed compatible OTP 27/Elixir pair without editing `.tool-versions`; actual runtime and durations are pending |

## Sampling Rate

- After each implementation task: run the narrow affected core or Admin tests; each task states the command and observable failure signal.
- After each connected slice: run targeted browser cases once the existing isolated harness is ready.
- After each wave: run the relevant cumulative semantic checks; run asset parity after CSS/HEEx changes.
- Before phase verification: run the full phase command set and review the connected rendered evidence.
- Feedback target: narrow checks under 60 seconds where practical; measure during execution and split long selections without weakening coverage.

## Per-Task Verification Map

Each command runs from repository root. The Playwright script builds assets and uses the isolated port 4102. All ExUnit paths listed below exist today; the phase browser file is created in 169-01. Each task's PLAN carries the fuller fails_when clause. A named Playwright selector with zero discovered cases is a failure, not a green skip. The final unfiltered browser command also runs incumbent `operator.spec.js` and `flows.spec.js` after their obsolete labels and keyboard assumptions have been updated.

| Wave/task | Requirement | Exact existing/planned test path and command | Threat ref | Observable failure signal | Status |
|---|---|---|---|---|---|
| 1 / 169-01 T1 tracer | OUTUX-02, OUTUX-05 | existing `test/mailglass/operator/deliveries_test.exs`, planned `mailglass_admin/e2e/phase169-journey.spec.js`, owned `mailglass_admin/test/support/operator_fixtures.ex`, `endpoint_case.ex`, `operator_browser_server.ex`; `mix test test/mailglass/operator/deliveries_test.exs --seed 1 && BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 baseline and exact replay tracer"` | T-169-01, T-169-03 | zero case, absent/mismatched before provenance, closed reset lacks persisted off-page ID, foreign exact disclosure, wrong replay ID or lost return context | pending execution |
| 1 / 169-01 T2 | OUTUX-02 | existing `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`, `operator_live_test.exs`; `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs --seed 1` | T-169-02 | invalid draft applied, old Account IDs retained or URL return wrong | pending execution |
| 1 / 169-01 T3 | OUTUX-02 | existing `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `operator/replay_modal_test.exs`; `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1`; audit/update incumbent `e2e/operator.spec.js` and `e2e/flows.spec.js` | T-169-01 | exact selection lost on empty/page change, foreign disclosure or false empty | pending execution |
| 2 / 169-02 T1 | OUTUX-01 | existing `test/mailglass/operator/support_summary_test.exs`, `suppressions_test.exs`, Admin `operator_live_test.exs`; test-only fixture/reset/hook fault seam in `operator_fixtures.ex` and `endpoint_case.ex`; `mix test test/mailglass/operator/support_summary_test.exs test/mailglass/operator/suppressions_test.exs --seed 1 && (cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1)` | T-169-05, T-169-06 | wrong time population, partial failure becomes zero, unexpected fault swallowed or one-shot fault leaks after reset | pending execution |
| 2 / 169-02 T2 | OUTUX-01, OUTUX-04 | existing Admin `operator_live_test.exs`; `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1` | T-169-04 | exact support ID replaced, no-result evidence hidden or false Delivery linkage | pending execution |
| 3 / 169-03 T1 | OUTUX-03 | existing core `timeline_test.exs`, Admin `operator_live_test.exs`; owned `operator_fixtures.ex` and `endpoint_case.ex` define closed persisted 101-event reset; `mix test test/mailglass/operator/timeline_test.exs --seed 1 && (cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1)` | T-169-07, T-169-08 | 101 boundary not disclosed, selected event lost or raw field rendered | pending execution |
| 3 / 169-03 T2 | OUTUX-03 | planned phase browser file and existing Admin `components_test.exs`; `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 exact copy"` | T-169-08 | zero case, replaced original value, silent clipboard rejection or UTC precision loss | pending execution |
| 3 / 169-03 T3 | OUTUX-04 | existing core `suppressions_test.exs`, Admin `operator_live_test.exs`; `mix test test/mailglass/operator/suppressions_test.exs --seed 1 && (cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1)` | T-169-09 | wrong policy removability, foreign/expired match or failed read called no match | pending execution |
| 4 / 169-04 T1 | OUTUX-05 | existing core `replay_targets_test.exs`, Admin `operator_live_test.exs`; owned `operator_fixtures.ex` and `endpoint_case.ex` provide closed replay mutations; audit/update existing `operator_live_test.exs:684`, `e2e/operator.spec.js`, `e2e/flows.spec.js`; `mix test test/mailglass/operator/replay_targets_test.exs --seed 1 && (cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1)` | T-169-10, T-169-11, T-169-12 | changed/replaced target accepted, auth skipped or duplicate submitted | pending execution |
| 4 / 169-04 T2 | OUTUX-05 | existing Admin `operator_live_test.exs`, `operator/replay_modal_test.exs`; `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` | T-169-13 | request called completion, known command result erased or raw error shown | pending execution |
| 5 / 169-05 T1 | OUTUX-01–05 | planned phase browser file; `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 rendered"` | T-169-14, T-169-15 | zero case, responsive/focus/copy/theme assertion fails or asset hash differs | pending execution |
| 5 / 169-05 T2 | OUTUX-01–05 | planned phase browser file; `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 connected"` then `mix test test/mailglass/operator/deliveries_test.exs test/mailglass/operator/timeline_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/operator/suppressions_test.exs test/mailglass/operator/replay_targets_test.exs --seed 1` then `cd mailglass_admin && mix test --seed 1` then `cd mailglass_admin && mix mailglass_admin.assets.build` then `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` then unfiltered `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser` | T-169-10, T-169-14, T-169-16 | named selection zero cases or journey failure; core/Admin/parity/bundle nonzero or zero tests; asset build failure or source/built/served mismatch; unfiltered browser nonzero, zero tests or missing incumbent/phase cases; any command missing current-revision count/duration record | pending execution |

## Wave 0 Requirements

- [ ] Use existing ExUnit/Playwright infrastructure; inventory installed asdf Erlang/Elixir versions and select a supported compatible pair before execution without changing project pins or installing an unnecessary toolchain.
- [ ] Before product edits, run the baseline case against the existing default seed. Then extend owned `mailglass_admin/test/support/operator_fixtures.ex`, synthetic `endpoint_case.ex` closed reset/mutate dispatch, and `operator_browser_server.ex` boot-seed provenance as each serial wave needs them. The final Phase 169 scenarios persist exact off-page/out-of-window Delivery, 101 ordered Event rows, exact Account support evidence, suppression variants and replay targets before their named browser assertions.
- [ ] Include changed/removed/replaced sole replay target via test-only allowlisted mutation between review and Confirm, duplicate queued confirmation through real controls, requested-only audit and terminal evidence failure cases. Arm panel-specific one-shot known read faults through only the synthetic test hook; reset rows and faults before each browser case. Programming and terminal-audit persistence faults may use isolated LiveView/ExUnit proof with the browser limit recorded honestly.
- [ ] Before first product edit, run the 169-01 baseline-only browser case on port 4102, and capture revision/dirty-source manifest, source/built/served CSS hashes, exact served URL, fixture, route, theme/OS, viewport, zoom and screenshots in 169-BASELINE.md.
- [ ] Update old operator LiveView and `operator.spec.js`/`flows.spec.js` assertions when the affected labels, row controls, copy buttons and keyboard behavior change, keeping scope, denial, focus and authorization checks. The required 169-05 Task 2 final gate runs focused core, complete Admin ExUnit, asset build, parity and bundle tests, and the entire incumbent and new operator browser suite; record counts, runtime and revision for every command.

## Manual-Only Verifications

Agent-operated rendered inspection is required for typography, composition, clipped/wrapped content, focus visibility, overlay containment, and coherent copy in connected Health → same-kind evidence → Delivery → replay → return flows. Capture representative 320/390/768/1440 widths, actual 200% zoom, Light/Dark/System with OS emulation and reduced motion, long/non-ASCII values, keyboard and touch. The phase browser cases record DOM facts; the agent records visual findings, one bounded corrective batch and confirmation in 169-BASELINE.md. User feedback is optional after this automated baseline. Do not substitute source-only or Phase 168 evidence.

## Validation Sign-Off

- [x] Concrete 12-task map and unique T-169-01..16 threat references planned
- [ ] Every task has automated verification and an observable failure signal
- [ ] No three consecutive tasks without automated verification
- [ ] Missing fixtures/tests are created before dependent verification
- [ ] No watch flags or historical proof substituted for current execution
- [ ] Feedback timing measured during execution
- [ ] Execution validation complete before setting nyquist_compliant true

**Approval:** Planning seed; execution evidence pending.
