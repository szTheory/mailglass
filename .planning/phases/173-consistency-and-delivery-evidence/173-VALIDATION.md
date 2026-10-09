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
| Planner assigned | TBD | TBD | UIQ-01 | — | No stale values or incomplete Gallery/Storybook claim | contract + browser | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs`; focused demo Storybook/Gallery route check | Token parity exists; add only missing guide/surface assertions | ⬜ pending |
| Planner assigned | TBD | TBD | UIQ-02 | — | Synthetic data only; candidate and actual capture/asset bytes stay distinguishable | manifest + browser | `cd mailglass_admin && mix test test/mailglass_admin/preview/capture_manifest_test.exs`; `bash scripts/run_demo_browser_evidence.sh` under an isolated Compose project | Manifest/browser paths exist; extend for missing provenance and adverse states | ⬜ pending |
| Planner assigned | TBD | TBD | UIQ-03 | — | Cleanup targets only the evidence-owned project; no false candidate/CI claim | asset + script + CI | `cd mailglass_admin && mix verify.preview`; isolated evidence-script contract; `gh run list -R szTheory/mailglass --commit "$CANDIDATE_SHA" --workflow CI --json status,conclusion,headSha` | Asset task and CI exist; add a cleanup contract only if current tests do not cover it | ⬜ pending |

**Environment constraint:** A research-time probe found Docker CLI 29.5.2 but no reachable Docker Engine. Recheck before browser capture. If still unavailable locally, use the existing configured CI runner if it can exercise the phase's browser evidence; otherwise record the browser/working-preview criterion as not yet proven. Never label an unavailable lane green or disrupt the retained feedback preview to force it.

---

## Wave 0 Requirements

- [ ] Add tests for incomplete provenance and zero current captures to the existing `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` only if these cases are not already covered.
- [ ] Add a regression check that Compose evidence uses a unique explicit project identity for every lifecycle operation and cannot tear down the retained default demo project.
- [ ] Extend source/build/served asset assertion only if the existing browser proof does not cover the selected Storybook/preview route.
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
