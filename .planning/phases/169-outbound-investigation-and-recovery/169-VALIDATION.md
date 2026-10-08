---
phase: "169"
slug: "outbound-investigation-and-recovery"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-07"
---

# Phase 169 — Validation Strategy

This file records the five-wave Phase 169 validation map (12 tasks). The terminal audit database write-failure path is covered at the core command and Admin LiveView boundaries. The three previously unclassified edge assumptions are adjudicated against concrete behavioral tests below. The five prohibition statements have assertion or source-review evidence recorded below; this is a validation audit, not enforcement by the phase probe serializer. Phase completion and verifier sign-off remain separate.

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
| 4 / 169-04 T2 | OUTUX-05 | core `test/mailglass/webhook/replay_test.exs`; Admin `operator_live_test.exs`, `operator/replay_modal_test.exs` | T-169-13 | request called completion, known command result erased or raw error shown | green: core replay 10 passed; Admin focused replay selection 104 passed. Trigger rejects terminal success audit; transaction rolls back normalized writes/projections, request and failed facts remain, and safe feedback omits raw database text |
| 5 / 169-05 T1 | OUTUX-01–05 | `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 rendered"` | T-169-14, T-169-15 | zero case, responsive/focus/copy/theme assertion fails or asset hash differs | green: 2 passed, 0 failed (Plan 169-05 current-revision evidence) |
| 5 / 169-05 T2 | OUTUX-01–05 | Named connected selection; core operator selection; complete Admin; asset build; parity/bundle; unfiltered operator browser suite (commands and runtimes in `169-BASELINE.md`) | T-169-10, T-169-14, T-169-16 | named selection zero cases or journey failure; core/Admin/parity/bundle nonzero or zero tests; asset build failure or source/built/served mismatch; unfiltered browser nonzero, zero tests or missing incumbent/phase cases; any command missing current-revision count/duration record | green baseline gates per `169-BASELINE.md`: connected 9 passed; core 39 passed; Admin 537 passed / 1 excluded; parity/bundle 9 passed; browser 197 passed / 1 skipped; source/built/served hashes match |

### Adversarial Gap — terminal replay audit database write failure

Added `test/mailglass/webhook/replay_test.exs` behavioral integration coverage that installs a PostgreSQL trigger rejecting only the terminal success audit row for a real stored webhook. The baseline command on the pinned runtime reproduced the defect: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass/webhook/replay_test.exs --seed 1` — **9 passed, 1 failed**, with raw `%Postgrex.Error{}` escaping from `Replay.execute/1`.

**Escalation repair evidence (2026-10-08):** `Replay.execute/1` now catches only `Postgrex.Error` at the replay transaction boundary and returns `{:error, :result_persistence_failed}`; non-Postgrex programming/configuration errors still raise. Its terminal audit, normalized Event inserts, and projections remain one transaction. The request audit is persisted before that transaction, and the safe failed audit is attempted after rollback. The trigger regression asserts the controlled error, retained requested/failed audit, absent terminal-success and normalized Event rows, unchanged Delivery state, and classified failure reason. It does not substitute a read fault for a database write fault.

Commands on this repair revision with `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15`:

- `mix test test/mailglass/webhook/replay_test.exs --seed 1` — **10 passed, 0 failed**.
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` — **104 passed, 0 failed**. Added a second trigger-backed LiveView regression asserting safe feedback, retained requested/failed audit display, no success audit, and no raw database exception detail.
- `git diff --check` — passed.

The write-failure escalation is resolved for OUTUX-05 / T-169-13. The follow-up audit below adjudicates the remaining flagged edges and prohibition statements. Parent phase verification remains separate from Nyquist coverage.

### Edge assumption adjudication

These three rows lacked a probe classification; they are not standalone product gaps. Each is covered by approved task acceptance criteria and current behavioral assertions:

| Assumption | Evidence and disposition |
|---|---|
| OUTUX-01: Health has no classified edge predicate | **Adjudicated / covered.** `operator_live_test.exs` tests `zero Health observations use limited evidence copy without global clearance`, `failed webhook rows remain a named observation without overall health claims`, `keeps a failed observation isolated while retaining its last known value`, and `propagates unexpected observation failures`. |
| OUTUX-04: suppression/support has no classified edge predicate | **Adjudicated / covered.** `suppressions_test.exs` covers foreign tenant, expired match, no-match, and complaint/unsubscribe removal policy; LiveView tests cover exact Account support ID surviving newer exemplars/empty Delivery results, foreign IDs sharing non-disclosing state, and unavailable exact reads preserving other observations. |
| OUTUX-05: replay has no classified edge predicate | **Adjudicated / covered.** `replay_targets_test.exs` and LiveView tests cover zero/one/many, changed/replaced targets, action-time authorization, duplicate confirmation, requested-only evidence, and terminal write failure. |

### Prohibition disposition (not probe-enforced)

The probe artifact has no `check_*` descriptors, so no result is attributed to probe enforcement. Source review below means checking named user-facing copy and rendering branches; it does not guarantee arbitrary future copy remains compliant.

| Requirement | Prohibition | Evidence and disposition |
|---|---|---|
| OUTUX-01 | No universal clearance from partial/windowed observations | **Assertion-backed.** LiveView tests explicitly refute “Email delivery is healthy” / “All clear” for zero observations and refute overall-health claims for named failed webhook evidence; named populations and windows are asserted. |
| OUTUX-02 | No silent Account or Delivery substitution | **Assertion-backed.** Core exact Delivery tests require exact tenant/ID matching and return no row for malformed, missing, or foreign IDs; LiveView tests require foreign exact support IDs to share the non-disclosing Account state and preserve requested exact IDs across moving exemplars. |
| OUTUX-03 | No inbox/human-read claim from handoff, tracking, or audit | **Source-reviewed, bounded.** Timeline tests preserve provider Event names, replay audit types, and recorded-time facts; replay outcome text says it does not establish provider receipt or mail delivery. Reviewed rendered labels do not claim inbox placement or human reading. No separate negative assertion enumerates every possible phrase. |
| OUTUX-04 | No send permission or generic repair claim from one suppression/unmatched fact | **Assertion and source-backed.** Suppression tests cover policy removability; LiveView/component tests assert Account-local one-record scope, configured-store/provider caveat, no-match wording, and read-only presentation. |
| OUTUX-05 | No resend/exactly-once/completion claim from requested-only replay | **Assertion-backed.** Replay modal test asserts stored-request replay “does not resend outbound mail”; requested-only test asserts “completion not recorded”; terminal-write LiveView regression asserts safe failed evidence and no success fact. Feature copy says processing does not prove provider receipt. |

These dispositions resolve the audit questions against current artifacts; they neither create probe descriptors nor claim universal negative-phrase testing. No implementation issue remains from this validation audit.

## Wave 0 Requirements

- [x] Use existing ExUnit/Playwright infrastructure; selected installed Erlang/Elixir versions without changing project pins or installing a toolchain.
- [x] Run the baseline case against the default seed and record before/after provenance, served assets and responsive evidence in `169-BASELINE.md`. Named fixtures cover exact off-page/out-of-window Delivery, 101-event timeline, Account support evidence, suppression variants, and replay targets.
- [x] Cover changed/removed/replaced replay target, duplicate confirmation, requested-only evidence, reader faults, and terminal audit persistence failure through test-only fixtures and isolated core/Admin tests.
- [x] Update incumbent LiveView/browser expectations for changed labels and controls while retaining scope, denial, focus, keyboard and authorization assertions. Plan 169-05 final core/Admin/browser/asset results are recorded in `169-BASELINE.md`; current-revision replay closeout results are recorded above.

## Manual-Only Verifications

Agent-operated rendered inspection is required for typography, composition, clipped/wrapped content, focus visibility, overlay containment, and coherent copy in connected Health → same-kind evidence → Delivery → replay → return flows. Capture representative 320/390/768/1440 widths, actual 200% zoom, Light/Dark/System with OS emulation and reduced motion, long/non-ASCII values, keyboard and touch. The phase browser cases record DOM facts; the agent records visual findings, one bounded corrective batch and confirmation in 169-BASELINE.md. User feedback is optional after this automated baseline. Do not substitute source-only or Phase 168 evidence.

## Validation Sign-Off

- [x] Concrete 12-task map and unique T-169-01..16 threat references planned
- [x] Every task has automated verification and an observable failure signal
- [x] No three consecutive tasks without automated verification
- [x] Missing fixtures/tests are created before dependent verification
- [x] No watch flags or historical proof substituted for current execution
- [x] Feedback timing and current-revision command provenance are recorded in `169-BASELINE.md`; focused replay rechecks were run on the repair revision.
- [x] Execution validation complete; source-reviewed prohibition boundaries are labeled as such and are not represented as probe enforcement.

**Approval:** Phase plans executed; the terminal audit write-failure and all 12 task verification rows have behavioral evidence. Three edge assumptions were mapped to existing task tests. Five prohibition statements were separately adjudicated with explicit automated or source-review evidence; none is claimed as probe-enforced. Nyquist validation is compliant for the mapped phase requirements. Parent phase verification remains pending.

**Plan 169-05 execution evidence:** Complete at checkout `e45aa8e1b82f97dd45e08c67c9cfe6fdd7f31d68`; complete counts, runtimes, native Chrome zoom record, CSS provenance, and explicit proof limits are in `169-BASELINE.md` → “After Evidence — Plan 169-05”. This does not mark Phase 169 complete; parent review and phase verification remain separate.

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 |

## Validation Audit 2026-10-08 (closeout)

| Metric | Count |
|---|---|
| Items reviewed (terminal-write gap, three unclassified assumptions, five prohibition dispositions) | 9 |
| Resolved | 9 |
| Escalated | 0 |

Current closeout commands: core replay 10 passed; core operator selection 39 passed; focused Admin operator LiveView + replay modal 104 passed. The 537-pass full Admin and 197-pass full browser suite are Plan 169-05 final-gate evidence on the pre-repair revision; this closeout did not rerun those broad suites. Manual residuals remain: physical-device touch and the full native 200% zoom/theme/route matrix were not performed; these are recorded for phase-level visual review.

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Gaps found | 9 |
| Resolved | 9 |
| Escalated | 0 |
