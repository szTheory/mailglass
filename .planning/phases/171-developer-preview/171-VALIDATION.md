---
phase: "171"
slug: developer-preview
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 171-01-T1 | 01 | 1 | PRVUX-01 | T-171-01 | Selected route and event values resolve against discovered Mailables/scenarios only. | LiveView | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | Existing module/fixtures; focused assertions to add | ⬜ pending |
| 171-01-T2 | 01 | 1 | PRVUX-01 | T-171-02 | Zero discovery and no-scenario setup remain distinct; host owns the dev route guard. | LiveView + voice | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --warnings-as-errors` | Existing modules; focused assertions to add | ⬜ pending |
| 171-02-T1 | 02 | 2 | PRVUX-02 | T-171-03 | Only known editable scalar keys parse; invalid drafts never silently reuse defaults. | LiveView + voice | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --warnings-as-errors` | Existing modules/fixtures; typed cases to add | ⬜ pending |
| 171-02-T2 | 02 | 2 | PRVUX-02 | T-171-04 | Failure retains editor/draft and marks previous output as last successful. | LiveView | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | Existing module/fixtures; failure sequence to add | ⬜ pending |
| 171-03-T1 | 03 | 3 | PRVUX-03 | T-171-06, T-171-08 | Renderer output, illustrative Raw/header labels, and script-disabled iframe are asserted. | LiveView | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | Existing module; provenance cases to add | ⬜ pending |
| 171-03-T2 | 03 | 3 | PRVUX-03 | T-171-06 | Browser proves manual tab focus/activation and keyboard panel access. | Browser | `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 171 tabs"` | Existing suite; connected cases to add | ⬜ pending |
| 171-04-T1 | 04 | 4 | PRVUX-04 | T-171-09 | CSS-pixel width, browser backdrop, and Admin theme stay independent across remount. | LiveView + browser | `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 171 framing"` | Existing suites; connected cases to add | ⬜ pending |
| 171-04-T2 | 04 | 4 | PRVUX-01–04 | T-171-10 | Synthetic captures and connected layout/state checks keep evidence bounded to browser preview. | Browser + asset + capture contract | `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 171 rendered"` | Existing browser/capture paths; cases to add | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing ExUnit, LiveViewTest, Playwright, fixture, and capture infrastructure is present; no framework, new test configuration, or dependency is needed.
- [ ] Add the requirement-specific assertions in Plans 01–04 to the existing preview LiveView and browser test modules; keep real keyboard/focus assertions in the browser suite.
- [ ] Confirm the pinned Elixir toolchain is selected before running local Mix checks; CI remains the existing pinned-runtime path if the local toolchain is unavailable.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bounded visual composition review of a representative rendered preview | PRVUX-01, PRVUX-03, PRVUX-04 | Automated checks cover layout bounds, labels, state, and interaction; visual hierarchy and polish are not fully captured by DOM assertions. This is not a handoff for machine-observable behavior. | Inspect one representative current rendered output at narrow and wide widths and light/dark/System combinations; allow one corrective pass and one confirmation round unless a concrete blocker remains. |

---

## Validation Sign-Off

- [ ] All final plan tasks have an `<automated>` verify command with an observable `<fails_when>` condition or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing test/runtime references; no new framework or dependency is introduced.
- [ ] No watch-mode flags appear in commands.
- [ ] Focused feedback latency is at most 30 seconds, or the plan identifies the existing bounded fallback.
- [ ] `nyquist_compliant: true` set in frontmatter after final task-to-test coverage is checked.

**Approval:** pending plan verification
