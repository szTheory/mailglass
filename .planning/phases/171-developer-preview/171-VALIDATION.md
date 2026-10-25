---
phase: "171"
slug: developer-preview
status: complete
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
---

# Phase 171 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest in `mailglass_admin`; existing Playwright Test suite for connected browser behavior and layout. |
| **Config files** | `mailglass_admin/test/test_helper.exs`; `mailglass_admin/playwright.config.cjs`. |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.support_contract.admin`; `cd mailglass_admin && npm run test:operator-browser`; run existing asset/token-parity and bundle checks when preview CSS changes. |
| **Estimated runtime** | Focused ExUnit command should remain under 30 seconds; full browser/runtime not measured during planning research. |
| **Recurring CI coverage** | Support Contract Admin is a required leaf behind CI Green. Operator Browser Gate and Preview Capture Advisory are outside the CI Green aggregate and remain advisory. Do not promote a lane or change branch protection. |
| **Feedback latency** | Aim for at most 30 seconds for focused LiveView feedback; use the existing browser suite for real-browser interaction evidence. |

The research environment does not currently have the pinned Elixir `1.18.4` installed in asdf, so local `mix` commands could not run there. Recheck/select the version already declared by `.tool-versions` during execution; do not change project runtime versions. CI's pinned BEAM setup remains available as the existing automated fallback. Node/npm are available; Playwright/Chromium launch behavior still needs confirmation in the actual existing browser lane.

---

## Sampling Rate

- **After every LiveView/component task commit:** Run the focused preview ExUnit module above.
- **After every connected browser-interaction task:** Run the existing Playwright preview/operator browser suite; do not use a LiveView component test as evidence for browser focus or keyboard behavior.
- **After any CSS/asset task:** Run the existing asset build, token-parity, and bundle checks for changed surfaces.
- **Before `$gsd-verify-work`:** Run the required Admin support contract and the relevant full browser and asset checks. Report the browser and capture lane status as advisory where the current CI graph does so.
- **Max feedback latency:** 30 seconds for focused LiveView checks.

---

## Per-Task Verification Map

The task/plan IDs below match the final four-plan vertical slicing. Commands are planned for execution; no local Mix, browser, capture, or CI result is asserted here.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 171-01-T1 | 01 | 1 | PRVUX-01 | T-171-01 | Selected route and event values resolve against discovered Mailables/scenarios only. | LiveView | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | `mailglass_admin/test/mailglass_admin/preview_live_test.exs` (selection, invalid-selection, mount-path, and renderer `srcdoc` assertions) | ✅ green — 40 tests, 0 failures (2026-10-09) |
| 171-01-T2 | 01 | 1 | PRVUX-01 | T-171-02 | Zero discovery and no-scenario setup remain distinct; host owns the dev route guard. | LiveView + voice | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --warnings-as-errors` | `mailglass_admin/test/mailglass_admin/preview_live_test.exs`, `mailglass_admin/test/mailglass_admin/voice_test.exs` (empty/no-scenario UI and host-route/copy contracts) | ✅ green — 58 tests, 0 failures, 1 excluded (2026-10-09) |
| 171-02-T1 | 02 | 2 | PRVUX-02 | T-171-03 | Only known editable scalar keys parse; invalid drafts never silently reuse defaults. | LiveView + voice | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --warnings-as-errors` | Same focused modules (typed scalar, invalid numeric/date, unknown/structured input assertions) | ✅ green — 58 tests, 0 failures, 1 excluded (2026-10-09) |
| 171-02-T2 | 02 | 2 | PRVUX-02 | T-171-04 | Failure retains editor/draft and marks previous output as last successful. | LiveView | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | `mailglass_admin/test/mailglass_admin/preview_live_test.exs` (failure, stale-output, retry, correction, and reset sequence assertions) | ✅ green — 40 tests, 0 failures (2026-10-09) |
| 171-03-T1 | 03 | 3 | PRVUX-03 | T-171-06, T-171-08 | Renderer output, illustrative Raw/header labels, and script-disabled iframe are asserted. | LiveView | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | `mailglass_admin/test/mailglass_admin/preview_live_test.exs` (renderer parity, provenance labels, aria panel relationships, long values, iframe sandbox) | ✅ green — 40 tests, 0 failures (2026-10-09) |
| 171-03-T2 | 03 | 3 | PRVUX-03 | T-171-06 | Browser proves manual tab focus/activation and keyboard panel access. | Browser | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 BROWSER_SERVER_PORT=4102 npm run test:operator-browser -- --grep "Phase 171 tabs"` | `mailglass_admin/e2e/structural.spec.js` — connected Chromium keyboard journey. Targeted audit rerun: 1/1 passed (the combined four-case rerun also passed all 4). | ✅ green — Chromium had to run outside the sandbox; no test failure (2026-10-09) |
| 171-04-T1 | 04 | 4 | PRVUX-04 | T-171-09 | CSS-pixel width, browser backdrop, and Admin theme stay independent across remount. | LiveView + browser | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 BROWSER_SERVER_PORT=4102 npm run test:operator-browser -- --grep "Phase 171 framing"` | LiveView assertions in `mailglass_admin/test/mailglass_admin/preview_live_test.exs`; connected Chromium case in `mailglass_admin/e2e/structural.spec.js`. Targeted rerun passed. | ✅ green — 1/1 connected browser case (2026-10-09) |
| 171-04-T2 | 04 | 4 | PRVUX-01–04 | T-171-10 | Synthetic captures and connected layout/state checks keep evidence bounded to browser preview. | Browser + asset + capture contract | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 BROWSER_SERVER_PORT=4102 npm run test:operator-browser -- --grep "Phase 171 rendered"`; `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1`; `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix mailglass_admin.preview.capture --dry-run --base-url http://localhost:4000/dev/mail --output-dir tmp/mailglass_admin_preview_capture`; `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin`; advisory full suite: `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 BROWSER_SERVER_PORT=4102 npm run test:operator-browser` | `mailglass_admin/e2e/structural.spec.js`; `mailglass_admin/test/mailglass_admin/token_parity_test.exs`; `mailglass_admin/test/mailglass_admin/bundle_test.exs`; capture contract tests under support contract. Focused browser rerun: 3 rendered cases passed; asset parity/bundle: 10 passed; capture wrote 30 entries and 2 intentional skips; support contract: 589 passed, 0 failures, 1 excluded. Full advisory suite: 44 passed, 167 failed of 211; failures begin with unrelated full-suite/fixture checks (including stale Preview render-button selector), after which the server becomes unreachable and Phase 171 cases fail with connection refused. | ⚠️ Phase 171 focused checks green; full advisory browser lane red from broader-suite failures/server loss |

---

## Wave 0 Requirements

- [x] Existing ExUnit, LiveViewTest, Playwright, fixture, and capture infrastructure is present; no framework, new test configuration, or dependency is needed.
- [x] Requirement-specific assertions are present in the existing preview LiveView and browser modules; real keyboard/focus assertions remain in the browser suite.
- [x] Selected the declared Elixir 1.18.4/OTP 27 runtime via asdf for local Mix checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Evidence |
|----------|-------------|----------|
| Subjective visual composition of representative rendered previews | PRVUX-01, PRVUX-03, PRVUX-04 | Bounded narrow light, narrow System/Dark, wide dark, and actual 200% zoom review is recorded in [171-RENDERED-REVIEW.md](171-RENDERED-REVIEW.md), including source revision, served CSS digest, correction, confirmation, and evidence limits. No owner UAT remains. |

---

## Validation Sign-Off

- [x] All final plan tasks map to automated verification commands and observable failure conditions.
- [x] Sampling continuity: every task has automated verification.
- [x] Wave 0 gaps are closed; existing test framework and dependencies are used.
- [x] No watch-mode flags appear in commands.
- [x] Focused LiveView feedback is under 30 seconds; connected-browser verification remains bounded to the existing browser lane.
- [x] `nyquist_compliant: true` set after checking task-to-test coverage.

**Status:** Phase 171 focused behavioral checks pass. The full advisory Playwright lane is not green in this checkout: it completed 211 tests with 44 passed and 167 failed, including existing broader-suite failures and later connection-refused errors after the browser server became unavailable. The four focused Phase 171 browser cases pass when run alone. The initial in-sandbox Chromium launch failed before tests ran; rerunning outside the sandbox succeeded.
