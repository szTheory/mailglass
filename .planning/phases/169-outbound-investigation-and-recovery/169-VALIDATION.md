---
phase: "169"
slug: "outbound-investigation-and-recovery"
status: validated
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 169 — Validation Strategy

This file records the five-wave Phase 169 validation map (12 tasks). The phase execution evidence is in `169-BASELINE.md`; the terminal audit database write-failure escalation has now been repaired and covered at the core command and Admin LiveView boundaries. Phase 169 verification remains partial: three edge assumptions and five descriptor-less prohibition judgments remain explicitly flagged in `169-PLAN-COVERAGE.md`.

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
| Runtime | Installed compatible runtime selected per command without editing the tracked project pin: Erlang/OTP `27.3.4.15`, Elixir `1.18.4` for OTP 27, Node `22.14.0`; see current command provenance in `169-BASELINE.md` |

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
| 1 / 169-01 T1 tracer | OUTUX-02, OUTUX-05 | `mix test test/mailglass/operator/deliveries_test.exs --seed 1`; connected path recorded in `169-BASELINE.md` and Plan 169-05 summary | T-169-01, T-169-03 | zero case, absent/mismatched before provenance, closed reset lacks persisted off-page ID, foreign exact disclosure, wrong replay ID or lost return context | green: focused core 39 passed; connected Phase 169 selection 9 passed (Plan 169-05 current-revision evidence) |
| 1 / 169-01 T2 | OUTUX-02 | existing `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`, `operator_live_test.exs`; `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs --seed 1` | T-169-02 | invalid draft applied, old Account IDs retained or URL return wrong | green: current-revision Admin suite 537 passed, 1 excluded |
| 1 / 169-01 T3 | OUTUX-02 | existing `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `operator/replay_modal_test.exs`; connected and unfiltered browser suites recorded in `169-BASELINE.md` | T-169-01 | exact selection lost on empty/page change, foreign disclosure or false empty | green: connected selection 9 passed; unfiltered operator browser 197 passed, 1 skipped |
| 2 / 169-02 T1 | OUTUX-01 | existing `test/mailglass/operator/support_summary_test.exs`, `suppressions_test.exs`, Admin `operator_live_test.exs`; `mix test test/mailglass/operator/support_summary_test.exs test/mailglass/operator/suppressions_test.exs --seed 1 && (cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1)` | T-169-05, T-169-06 | wrong time population, partial failure becomes zero, unexpected fault swallowed or one-shot fault leaks after reset | green: current-revision core operator selection 39 passed; Admin suite 537 passed, 1 excluded |
| 2 / 169-02 T2 | OUTUX-01, OUTUX-04 | existing Admin `operator_live_test.exs`; full Admin suite | T-169-04 | exact support ID replaced, no-result evidence hidden or false Delivery linkage | green: full Admin suite 537 passed, 1 excluded |
| 3 / 169-03 T1 | OUTUX-03 | existing core `timeline_test.exs`, Admin `operator_live_test.exs`; `mix test test/mailglass/operator/timeline_test.exs --seed 1 && (cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1)` | T-169-07, T-169-08 | 101 boundary not disclosed, selected event lost or raw field rendered | green: current-revision core operator selection 39 passed; Admin suite 537 passed, 1 excluded |
| 3 / 169-03 T2 | OUTUX-03 | `mailglass_admin/e2e/phase169-journey.spec.js`, existing Admin `components_test.exs`; rendered/connected browser suites | T-169-08 | zero case, replaced original value, silent clipboard rejection or UTC precision loss | green: rendered selection 2 passed; connected selection 9 passed |
| 3 / 169-03 T3 | OUTUX-04 | existing core `suppressions_test.exs`, Admin `operator_live_test.exs`; full core operator and Admin suites | T-169-09 | wrong policy removability, foreign/expired match or failed read called no match | green: current-revision core operator selection 39 passed; Admin suite 537 passed, 1 excluded |
| 4 / 169-04 T1 | OUTUX-05 | existing core `replay_targets_test.exs`, Admin `operator_live_test.exs`; closed replay mutations in `operator_fixtures.ex` and `endpoint_case.ex`; full current core/Admin suites | T-169-10, T-169-11, T-169-12 | changed/replaced target accepted, auth skipped or duplicate submitted | green: core operator 39 passed; Admin suite 537 passed, 1 excluded; browser 197 passed, 1 skipped |
| 4 / 169-04 T2 | OUTUX-05 | existing Admin `operator_live_test.exs`, `operator/replay_modal_test.exs`; full Admin suite | T-169-13 | request called completion, known command result erased or raw error shown | green: command persistence failure returns a controlled error, preserves requested/failed audit facts, rolls back normalized writes, and renders safe cause-specific feedback; focused Admin tests 104 passed |
| 5 / 169-05 T1 | OUTUX-01–05 | `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 rendered"` | T-169-14, T-169-15 | zero case, responsive/focus/copy/theme assertion fails or asset hash differs | green: 2 passed, 0 failed (Plan 169-05 current-revision evidence) |
| 5 / 169-05 T2 | OUTUX-01–05 | Named connected selection; core operator selection; complete Admin; asset build; parity/bundle; unfiltered operator browser suite (commands and runtimes in `169-BASELINE.md`) | T-169-10, T-169-14, T-169-16 | named selection zero cases or journey failure; core/Admin/parity/bundle nonzero or zero tests; asset build failure or source/built/served mismatch; unfiltered browser nonzero, zero tests or missing incumbent/phase cases; any command missing current-revision count/duration record | green baseline gates per `169-BASELINE.md`: connected 9 passed; core 39 passed; Admin 537 passed / 1 excluded; parity/bundle 9 passed; browser 197 passed / 1 skipped; source/built/served hashes match |

### Adversarial Gap — terminal replay audit database write failure

Added `test/mailglass/webhook/replay_test.exs` behavioral integration coverage that installs a PostgreSQL trigger rejecting only the terminal success audit row for a real stored webhook. The baseline command on the pinned runtime reproduced the defect: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass/webhook/replay_test.exs --seed 1` — **9 passed, 1 failed**, with raw `%Postgrex.Error{}` escaping from `Replay.execute/1`.

**Escalation repair evidence (2026-10-08):** `Replay.execute/1` now catches only `Postgrex.Error` at the replay transaction boundary and returns `{:error, :result_persistence_failed}`; non-Postgrex programming/configuration errors still raise. Its terminal audit, normalized Event inserts, and projections remain one transaction. The request audit is persisted before that transaction, and the safe failed audit is attempted after rollback. The trigger regression asserts the controlled error, retained requested/failed audit, absent terminal-success and normalized Event rows, unchanged Delivery state, and classified failure reason. It does not substitute a read fault for a database write fault.

Commands on this repair revision with `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15`:

- `mix test test/mailglass/webhook/replay_test.exs --seed 1` — **10 passed, 0 failed**.
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` — **104 passed, 0 failed**. Added a second trigger-backed LiveView regression asserting safe feedback, retained requested/failed audit display, no success audit, and no raw database exception detail.
- `git diff --check` — passed.

The write-failure escalation is resolved for OUTUX-05 / T-169-13. This does not establish that all negative prohibitions in the phase are covered by assertions; the separate edge assumptions and descriptor-less prohibition judgments remain open. Phase-level Nyquist compliance remains false pending their resolution and parent verification.

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

**Approval:** Phase plans executed; the OUTUX-05 terminal audit write-failure escalation is resolved with current-revision core and LiveView proof. Parent phase verification remains pending, and Nyquist compliance stays false while the explicitly recorded coverage gaps remain open.

**Plan 169-05 execution evidence:** Complete at checkout `e45aa8e1b82f97dd45e08c67c9cfe6fdd7f31d68`; complete counts, runtimes, native Chrome zoom record, CSS provenance, and explicit proof limits are in `169-BASELINE.md` → “After Evidence — Plan 169-05”. This does not mark Phase 169 complete or set `nyquist_compliant: true`; parent review and phase verification remain separate.

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 |
