---
phase: "173"
slug: "consistency-and-delivery-evidence"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
---

# Phase 173 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix.LiveViewTest; Playwright Test 1.60.0 |
| **Config file** | `mailglass_admin/mix.exs`; `reference/demo_app/assets/playwright.config.cjs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/preview/capture_manifest_test.exs` |
| **Full suite command** | `bash scripts/gsd-regression-gate.sh` plus `cd mailglass_admin && mix verify.preview` when generated Admin assets are affected |
| **Estimated runtime** | Current focused contracts: 13 seconds for the six shell/Node/ExUnit checks; Playwright could not start in the current host environment (exit 126, missing selected `mix` version). Plan summaries record successful isolated browser runs. |

---

## Sampling Rate

- **After every task commit:** Run the directly affected ExUnit, Playwright, or script-contract check from the map below.
- **After every plan wave:** Run `bash scripts/gsd-regression-gate.sh`; also run `cd mailglass_admin && mix verify.preview` if CSS or generated assets changed.
- **Before phase verification:** Run the focused browser evidence against the isolated candidate; check required `CI Green` on the exact candidate SHA and report advisory browser/capture jobs separately.
- **Max feedback latency:** Target under 120 seconds for the focused ExUnit/manifest checks; measure browser/Compose and full-regression runtime during execution and record the observed values.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 173-01-T1 | 01 | 1 | UIQ-02, UIQ-03 | T-173-01, T-173-03 | Run-owned Compose lifecycle; incomplete capture rejected | shell + Node contract | `bash scripts/test_run_demo_browser_evidence.sh && node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs` | `scripts/test_run_demo_browser_evidence.sh`; `reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs` | ✅ green — fresh: shell contract passed; 10 Node tests passed |
| 173-01-T2 | 01 | 1 | UIQ-02 | T-173-02, T-173-04 | Synthetic bounded current renders and exact PNG/asset/candidate provenance | Playwright + Node | `node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs && bash scripts/run_demo_browser_evidence.sh` | `reference/demo_app/assets/e2e/phase173-evidence.spec.js`; focused wrapper | ✅ green — Plan 01 summary records focused run passed with six captures; fresh checkpoint tests passed. Plan 06 later rejected that candidate's dirty provenance for delivery use |
| 173-02-T1 | 02 | 2 | UIQ-02 | T-173-05, T-173-06 | Actual Admin PNG bytes and complete owned capture metadata | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/preview/capture_manifest_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --warnings-as-errors --seed 1` | `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs`; `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs` | ✅ green — fresh: 18 passed, 0 failed |
| 173-02-T2 | 02 | 2 | UIQ-01 | T-173-08 | Guide reflects canonical brand tokens and shipped Admin CSS | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/token_parity_test.exs --warnings-as-errors --seed 1` | `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | ✅ green — fresh: 5 passed, 0 failed |
| 173-02-T3 | 02 | 2 | UIQ-01 | T-173-07 | Gallery/Storybook routes, themes and served CSS agree on the disposable demo | Playwright | `npm --prefix reference/demo_app/assets run test:e2e -- e2e/persona-screenshots.spec.js --grep "review surfaces"` | `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | ✅ green — prior focused disposable run passed at 768px per Plan 02 summary; no fresh browser run in this audit |
| 173-03-T1 | 03 | 3 | UIQ-03 | T-173-10, T-173-11 | Candidate route ready; built and served CSS match | Playwright | `npm --prefix reference/demo_app/assets run test:e2e -- e2e/persona-screenshots.spec.js --grep "working preview readiness"` | `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | ✅ green — prior focused disposable candidate run passed per Plan 03 summary; no fresh browser run in this audit |
| 173-03-T2 | 03 | 3 | UIQ-03 | T-173-11, T-173-12 | Walkthrough contract and exact-candidate fail-closed checks | Node document + fake-CLI shell contracts | `bash scripts/test_check_phase173_candidate.sh` (fresh safe rerun); delivery-doc contract was not rerun | `reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs`; `scripts/test_check_phase173_candidate.sh` | ⚠ incomplete acceptance input — prior summary reports 4 documentation checks passed; fake-CLI contract passed fresh. The owner-dirty README acceptance input remains excluded/uncommitted |
| 173-03-T3 | 03 | 3 | UIQ-03 | T-173-09, T-173-10, T-173-11 | Retained final-candidate preview, exact served CSS and required CI Green | shell + HTTP + GitHub CI | `bash scripts/check_phase173_candidate.sh` (prior Plan 03/06 gate runs); safe fake-CLI coverage: `bash scripts/test_check_phase173_candidate.sh` | `scripts/check_phase173_candidate.sh`; `scripts/test_check_phase173_candidate.sh` | ⚠ incomplete external gate — gate records no exact-SHA CI Green and excluded owner inputs; Plan 06 also records rejected dirty capture evidence. Fake-CLI contract passed fresh |
| 173-04-T1 | 04 | 4 | UIQ-02, UIQ-03 | T-173-02, T-173-03 | Only a validated sanitized checkpoint and allowlisted PNG pairs are retained | Node + shell contract | `node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs && bash scripts/test_run_demo_browser_evidence.sh` | `reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs`; `scripts/test_run_demo_browser_evidence.sh` | ✅ green — fresh: 10 Node tests and shell contract passed |
| 173-04-T2 | 04 | 4 | UIQ-02 | T-173-05, T-173-06 | Actual Admin capture rejects built/served CSS mismatch; CI allows only synthetic mailable | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/preview/capture_manifest_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --warnings-as-errors --seed 1` | `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs`; `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs` | ✅ green — fresh: 18 passed, 0 failed |
| 173-04-T3 | 04 | 4 | UIQ-02, UIQ-03 | T-173-SC | Exact offline package lock is checked before install paths; advisory audit covers lock | Node + npm audit | `node --test reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs && node reference/demo_app/assets/scripts/check-demo-browser-deps.cjs --lock-only && npm --prefix reference/demo_app/assets audit --package-lock-only --audit-level=high` | `reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs` | ✅ green — fresh: 13 Node tests, lock gate passed, 0 vulnerabilities |
| 173-05-T1 | 05 | 5 | UIQ-02, UIQ-03 | T-173-07, T-173-16 | Reset requires token plus run-owned identity; both producers preflight before POST | ExUnit + Node + shell + Playwright | `cd reference/demo_app && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_demo_web/page_controller_security_test.exs --warnings-as-errors --seed 1 && node --test assets/scripts/check-persona-reset-target.test.cjs && bash ../scripts/test_run_demo_browser_evidence.sh` | `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs`; `reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs`; `scripts/test_run_demo_browser_evidence.sh` | ✅ green — fresh: 9 ExUnit and 12 Node tests plus shell contract passed; Plan 05 summary records the isolated browser wrapper pass |
| 173-05-T2 | 05 | 5 | UIQ-02, UIQ-03 | T-173-13, T-173-14, T-173-15 | Exact candidate gate transfers only pinned baselines and rejects stale/unsafe retained evidence | shell + Node document contract | `bash scripts/test_check_phase173_candidate.sh`; delivery-doc contract prior result only (not rerun) | `scripts/test_check_phase173_candidate.sh`; `reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs` | ✅ green for repeatable contracts — fake-CLI passed fresh; Plan 05 summary reports 4 docs checks passed. Final delivery remains incomplete under 173-06 |
| 173-06-T1 | 06 | 6 | UIQ-03 | T-173-13, T-173-14, T-173-15, T-173-16 | Exact-SHA gate reports CI, owner-input, local regression and retained-evidence status without false completion | exact-candidate machine gate | `bash scripts/check_phase173_candidate.sh` (prior run; not rerun because it invokes acceptance/regression paths touching excluded owner data) | `scripts/check_phase173_candidate.sh`; ignored candidate JSON records named in Plan 06 summary | ⚠ incomplete external machine gate — prior run returned incomplete for missing exact-SHA CI, owner-dirty acceptance input, local regression dependency failure, and `candidate_dirty=true` evidence. UIQ-03 remains Pending |

**Environment and scope:** Fresh safe checks in this audit passed: shell isolation contract; 10 evidence Node tests; 12 reset-target Node tests; 13 dependency-lock Node tests; candidate fake-CLI contract; 18 capture ExUnit tests; 5 token-parity ExUnit tests; 9 reset-endpoint ExUnit tests; lock-only gate; npm audit (0 vulnerabilities). Browser and delivery-doc test results are cited from the plan summaries where not rerun. The protected `reference/demo_app/assets/e2e/demo.spec.js` and owner-dirty `reference/demo_app/README.md` were not opened, read, modified, staged, or executed. Tests that consume README contents and the actual candidate gate were not rerun. No exact-SHA `CI Green` evidence is available; Plan 06's recorded gate result remains incomplete and is not replaced by human UAT.

---

## Wave 0 Requirements

- [x] 173-01-T1: Create fake-Docker lifecycle and Node checkpoint negative fixtures before changing the wrapper or checkpoint writer.
- [x] 173-02-T1: Extend the existing ExUnit capture tests with incomplete/empty, one/many and missing actual PNG cases before changing the writer.
- [x] 173-03-T2: Create fake-`gh`/`git`/Docker/HTTP exact-candidate and retained-preview failure fixtures before writing the final gate.
- [x] 173-03-T2: Create the Node built-in runbook content check before writing the walkthrough; include URL/command, candidate and served-asset identity, evidence limits, required/advisory CI, and resource disposition.
- [x] 173-03-T1: Extend the existing browser route test with source/build/served CSS assertion only where the selected Storybook/preview route currently lacks it.
- Existing ExUnit, LiveView, Playwright, and shell-script infrastructure is present; no framework or dependency installation is planned.

---

## Manual-Only Verifications

All machine-observable Phase 173 criteria are assigned to automation, CI evidence, or source-identified artifacts. Human visual judgment may be offered as feedback on the bounded captures, but it is not an acceptance substitute for a missing automated check. External CI status and live preview identity are queried at execution time; if unavailable, report that evidence as missing rather than asking the owner to infer it.

---

## Validation Sign-Off

- [x] Every planned task has an automated `<verify>` or a justified Wave 0 dependency.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers every missing test reference identified by research.
- [x] No watch-mode flags.
- [x] Focused test latency is measured during execution (safe fresh checks completed in 20s wall time when run in parallel; Playwright was not rerun in this audit).
- [x] `nyquist_compliant: true`: all 14 task acceptance areas have repeatable automated checks; where live/external prerequisites are missing, the automated gate records an incomplete outcome. This does not mark UIQ-03 complete.

**Approval:** validation coverage is compliant; 11/14 task checks are green and 3/14 are correctly incomplete because UIQ-03 requires external candidate/owner acceptance proof. UIQ-03 remains Pending.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Planned task checks audited | 14 |
| Repeatable checks green | 11 |
| Incomplete acceptance gates | 3 (173-03-T2, 173-03-T3, 173-06-T1) |
| Missing automated test gaps | 0 |
| Escalated implementation bugs | 0 |

The incomplete rows are covered by repeatable machine checks, but their current acceptance inputs are absent or rejected: the owner-dirty README acceptance input is excluded, exact-SHA required CI is absent, the exact candidate's local regression lacked dependencies during the recorded gate, and retained evidence with `candidate_dirty=true` was rejected. These are external delivery prerequisites, not human visual UAT. UIQ-03 must remain Pending until the committed candidate gate passes with those machine-observable inputs.
