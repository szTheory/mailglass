---
phase: "173"
slug: "consistency-and-delivery-evidence"
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Estimated runtime** | Establish from the first focused run; do not guess before the changed browser and Compose paths are measured. |

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
| 173-01-T1 | 01 | 1 | UIQ-02, UIQ-03 | T-173-01, T-173-03 | Run-owned Compose lifecycle; incomplete capture rejected | shell + Node contract | `bash scripts/test_run_demo_browser_evidence.sh && node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs` | New tests created first in task | ⬜ pending |
| 173-01-T2 | 01 | 1 | UIQ-02 | T-173-02, T-173-04 | Synthetic bounded current renders and exact PNG/asset/candidate provenance | Playwright + Node | `node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs && bash scripts/run_demo_browser_evidence.sh` | New phase-owned `phase173-evidence.spec.js`; wrapper selects only this spec; Node negative fixtures added in T1 | ⬜ pending |
| 173-02-T1 | 02 | 2 | UIQ-02 | T-173-05, T-173-06 | Actual Admin PNG bytes and complete owned capture metadata | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/preview/capture_manifest_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --warnings-as-errors --seed 1` | Existing tests expanded before implementation | ⬜ pending |
| 173-02-T2 | 02 | 2 | UIQ-01 | T-173-08 | Guide reflects canonical brand tokens and shipped Admin CSS | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/token_parity_test.exs --warnings-as-errors --seed 1` | Existing focused parity test | ⬜ pending |
| 173-02-T3 | 02 | 2 | UIQ-01 | T-173-07 | Gallery/Storybook routes, themes and served CSS agree on the disposable demo | Playwright | `npm --prefix reference/demo_app/assets run test:e2e -- --grep "review surfaces"` | Existing Playwright spec extended in task | ⬜ pending |
| 173-03-T1 | 03 | 3 | UIQ-03 | T-173-10, T-173-11 | Candidate route ready; built and served CSS match | Playwright | `npm --prefix reference/demo_app/assets run test:e2e -- --grep "working preview readiness"` | Existing Playwright spec extended in task | ⬜ pending |
| 173-03-T2 | 03 | 3 | UIQ-03 | T-173-11, T-173-12 | Actual walkthrough has review URL/command, identity, limits, CI classes and resource disposition; candidate gate fails closed | Node document + fake-CLI shell contracts | `node --test reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs && bash scripts/test_check_phase173_candidate.sh && git diff --check -- reference/demo_app/README.md .planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md` | New Node and shell tests created before runbook/gate; tracked files committed after verification | ⬜ pending |
| 173-03-T3 | 03 | 3 | UIQ-03 | T-173-09, T-173-10, T-173-11 | Retained final-candidate preview has unique project/ports, exact served CSS and required CI Green | shell + HTTP + GitHub CI | `bash scripts/check_phase173_candidate.sh` | Committed gate from T2 runs against its own clean exact-SHA candidate; ignored runtime JSON remains outside tracked candidate | ⬜ pending |

**Environment constraint:** A research-time probe found Docker CLI 29.5.2 but no reachable Docker Engine. Recheck before browser capture. The existing CI runner may supply isolated browser evidence; the final owner-openable retained review preview must run from the exact clean candidate on a reachable host and remain available after the gate. If no reachable host is available, UIQ-03 is unproven. Never label an unavailable lane green or disrupt the retained feedback preview to force it.

---

## Wave 0 Requirements

- [ ] 173-01-T1: Create fake-Docker lifecycle and Node checkpoint negative fixtures before changing the wrapper or checkpoint writer.
- [ ] 173-02-T1: Extend the existing ExUnit capture tests with incomplete/empty, one/many and missing actual PNG cases before changing the writer.
- [ ] 173-03-T2: Create fake-`gh`/`git`/Docker/HTTP exact-candidate and retained-preview failure fixtures before writing the final gate.
- [ ] 173-03-T2: Create the Node built-in runbook content check before writing the walkthrough; include URL/command, candidate and served-asset identity, evidence limits, required/advisory CI, and resource disposition.
- [ ] 173-03-T1: Extend the existing browser route test with source/build/served CSS assertion only where the selected Storybook/preview route currently lacks it.
- Existing ExUnit, LiveView, Playwright, and shell-script infrastructure is present; no framework or dependency installation is planned.

---

## Manual-Only Verifications

All machine-observable Phase 173 criteria are assigned to automation, CI evidence, or source-identified artifacts. Human visual judgment may be offered as feedback on the bounded captures, but it is not an acceptance substitute for a missing automated check. External CI status and live preview identity are queried at execution time; if unavailable, report that evidence as missing rather than asking the owner to infer it.

---

## Validation Sign-Off

- [ ] Every planned task has an automated `<verify>` or a justified Wave 0 dependency.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers every missing test reference identified by research.
- [ ] No watch-mode flags.
- [ ] Focused test latency is measured during execution.
- [ ] `nyquist_compliant: true` set after executable plan checks pass.

**Approval:** pending
