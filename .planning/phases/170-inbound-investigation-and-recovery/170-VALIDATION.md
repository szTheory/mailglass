---
phase: "170"
slug: inbound-investigation-and-recovery
status: complete
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-08"
---

# Phase 170 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit in `mailglass_inbound` and `mailglass_admin`; Playwright Test for connected operator browser acceptance. |
| **Config files** | `mailglass_inbound/test/test_helper.exs`; `mailglass_admin/test/test_helper.exs`; `mailglass_admin/playwright.config.cjs`. |
| **Inbound quick run command** | From `mailglass_inbound`: `mix test test/mailglass_inbound/internal/operator/records_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/async_execution_test.exs`. |
| **Admin quick run command** | From `mailglass_admin`: `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/inbound/evidence_card_test.exs test/mailglass_admin/inbound/replay_modal_test.exs`. |
| **Connected acceptance command** | From `mailglass_admin`: `npm run test:operator-browser`. |
| **Full suite commands** | `mix test --seed 1` from each of `mailglass_inbound` and `mailglass_admin`; `npm run test:operator-browser` from `mailglass_admin`; build and verify committed assets with `mix mailglass_admin.assets.build` and the existing token-parity/bundle tests when source classes change. |
| **Feedback latency** | Final evidence after the gap test: Admin 575 tests (1 excluded), inbound 3 properties + 478 tests, and full operator browser 203 passed / 1 guarded skip. The focused connected read-failure case passed in 1.7s. |

The project pins Elixir `1.18.4` and Erlang `27.3.4.13`; phase acceptance evidence used the pinned toolchain. Playwright Chromium ran successfully; this audit required runtime escalation because sandbox launch permissions blocked Chromium before test execution. No test or browser dependency was added.

## Sampling Rate

- After each inbound read/replay task commit: run the affected `mailglass_inbound` operator or replay ExUnit modules.
- After each Admin LiveView/component task commit: run the affected `mailglass_admin` inbound ExUnit modules.
- After each connected operator journey task: run its named Playwright case through `npm run test:operator-browser`.
- Before `$gsd-verify-work`: run both package suites, the complete operator browser suite, and the Admin asset/parity checks if CSS changed.
- Never report a browser interaction as verified by a component test alone; record the evidence boundary between ExUnit, connected browser, and rendered inspection.

## Per-Requirement Verification Map

| Requirement | Required observable behavior | Test locations / type | Planned automated evidence | Status |
|-------------|-----------------------------|-----------------------|----------------------------|--------|
| INUX-01 | Exact same-Account selection survives page/filter boundaries; return context is preserved; successful empty, filtered-empty, out-of-range, unavailable selection, absent package, explicit gateway error and DB connection failure are distinct; foreign IDs disclose no existence. | Inbound records ExUnit; Admin LiveView ExUnit; connected Playwright. | Both package suites; full browser suite; focused DB connection failure browser test. | **Green** — full suites and focused read-failure browser case passed. |
| INUX-02 | List and detail agree on the latest fresh disposition; history is chronological; matched Mailbox, no match, failed execution, and missing history remain distinct; current-router trace is labeled as simulation. | Inbound operator ExUnit; Admin LiveView/component ExUnit; connected Playwright. | Both package suites and full operator browser suite. | **Green** — latest-fresh, timeline, component, and connected simulation checks passed. |
| INUX-03 | Verification and route facts follow an explicit safe-field policy; raw payload/MIME is redacted by default; reveal authorization is checked at action time and resets on Account/record changes. | Admin component and LiveView ExUnit; connected keyboard/browser cases. | Admin package suite; full operator browser suite; rendered Phase 170 case. | **Green** — redaction, action-time authorization, keyboard reveal/re-redact, focus return, and rendered checks passed. |
| INUX-04 | Eligibility is revalidated for the exact Account/record at confirmation; denied, busy/duplicate, recorded failure, command failure, and unavailable history remain distinct; `:no_change` appears only when explicitly returned by Mailbox and persisted; context is retained. Selected lineage is a timestamped snapshot until an explicit refresh succeeds. | Inbound replay ExUnit; Admin LiveView/modal ExUnit; connected Playwright. | Both package suites; full operator browser suite; Admin token-parity/bundle tests. | **Green** — callback/replay lineage, exact revalidation, one-submit feedback, and explicit history refresh passed. |

## Wave 0 Requirements

- [x] Existing ExUnit and Playwright infrastructure covers the phase; no framework or fixture package is identified.
- [x] Map all final plan tasks to the verified coverage crosswalk below; each PLAN task retains an observable `<fails_when>` condition.
- [x] Confirm pinned Elixir/Erlang and Playwright availability through recorded package/browser runs.
- [x] D-16 end to end: explicit `:no_change` persistence and presentation; `:ignore`, projection diffs and reread results remain distinct.
- [x] D-17 narrow read failure mapping; unrelated exceptions propagate. A connected DB-failure assertion was added during this audit because the earlier Plan 08 browser cases exercised package absence but not an operational read failure.
- [x] D-18 timestamped selected-history snapshot and explicit native refresh; no polling or new PubSub completion event.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None remaining for machine-observable acceptance. Rendered inspection is complete and recorded in `170-RENDERED.md`; no subjective review remains as a phase acceptance gate. | — | — | — |

## Validation Sign-Off

- [x] Every final plan task has an `<automated>` verify command or a declared Wave 0 dependency.
- [x] No three consecutive tasks omit automated verification.
- [x] Wave 0 covers every missing runtime/test/browser prerequisite.
- [x] No watch-mode flags appear in commands.
- [x] Nyquist coverage is confirmed by this audit and its executed gap test.

**Approval:** complete — D-52 shift-left automation applied; no machine-observable criterion remains for owner UAT.

## Plan Task Coverage Crosswalk

| Task | Observable behavior covered | Evidence | Status |
|------|-----------------------------|----------|--------|
| 170-01-T1 | Exact tenant record outside page/filter, retained return context, foreign/missing nondisclosure, native selection | Admin LiveView suite; connected exact-selection/foreign-ID cases | Green |
| 170-01-T2 | Empty/filter-empty/out-of-range/package absence/read errors; narrow exception boundary | Admin suite; browser package and DB connection failure cases | Green |
| 170-02-T1 | Explicit callback `:no_change` persistence; distinct from ignore/failure | Inbound suite (`mailbox_test.exs`, `mailbox_execution_test.exs`) | Green |
| 170-02-T2 | Tenant-scoped replay lineage, legacy binding refusal, docs contract | Inbound suite (`replay_test.exs`, `docs_contract_test.exs`) | Green |
| 170-03-T1 | Allowlisted verification projection, redaction, reveal authorization | Admin suite; connected keyboard reveal/re-redact case | Green |
| 170-03-T2 | Masked current-router simulation and native disclosure | Admin component suite; connected simulation/disclosure case | Green |
| 170-04-T1 | Shared latest-fresh disposition, failure/no-match and deterministic tie behavior | Inbound suite (`internal/operator/records_test.exs`) | Green |
| 170-04-T2 | Chronological fresh/replay timeline, IDs/timestamps, missing history and tenant isolation | Inbound suite (`internal/operator/records_test.exs`) | Green |
| 170-05-T1 | Outcome/filter vocabulary, no-change vs ignore, missing history and long values | Admin suite (`inbound_live_test.exs`, inbound/shared component suites) | Green |
| 170-05-T2 | Detail/timeline labels, chronological identity, hidden free-form failure text | Admin inbound component suite | Green |
| 170-06-T1 | Typed scoped eligibility reasons, foreign/missing equivalence, optional gateway | Inbound replay and Admin optional-dependency suites | Green |
| 170-06-T2 | Exact review revalidation before authorization, denial, modal behavior | Admin LiveView/modal suite; connected replay journey | Green |
| 170-07-T1 | Consumed review token, one replay, truthful distinct outcomes and context | Admin LiveView/modal suite; connected replay journey | Green |
| 170-07-T2 | Timestamped history snapshot, explicit refresh, unavailable refresh preservation | Admin LiveView suite; connected history-refresh journey | Green |
| 170-08-T1 | Connected end-to-end and negative states, including operational read failure | Full browser suite; focused `database connection failures` case | Green |
| 170-08-T2 | Responsive/theme/zoom/touch/keyboard/reduced-motion and asset provenance | Rendered case, token-parity/bundle checks, `170-RENDERED.md` | Green |

## Gap Audit Trail (2026-10-09)

- Reviewed all eight Phase 170 plans and summaries, this validation map, D-52 in `.planning/METHODOLOGY.md`, `170-RENDERED.md`, and the source/test seams named by each task.
- Found a Plan 08 browser-coverage hole: the existing connected tests proved optional-package absence but did not trigger an operational database read failure through the rendered page. Added a test-only failing Repo scenario and a behavioral Playwright assertion; product files were not changed.
- Executed `BROWSER_SERVER_PORT=4102 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec npm run test:operator-browser -- --grep "database connection failures"` from `mailglass_admin`: **1 passed, 0 failed** (1.7s). It checks sanitized read-unavailable copy, no synthetic exception text, and no successful-empty state. Then ran all named Phase 170 browser cases with `--grep "Phase 170"`: **4 passed, 0 failed** (10.3s), including connected journey and rendered checks.
- The first sandboxed invocation failed before test execution because Chromium could not start (`bootstrap_check_in ... Permission denied`). The same command passed with runtime escalation; this was an environment launch restriction, not a behavioral failure.
- Final expanded full browser run after adding the database-failure case: **203 passed, 1 guarded skip, 0 failed**. Admin: **575 tests, 0 failures, 1 excluded**; inbound: **3 properties + 478 tests, 0 failures**; token/bundle: **10 tests, 0 failures**. The existing skip is the guarded structural-modal case documented in the plan summary, not a Phase 170 case.
