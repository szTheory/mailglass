---
phase: "172"
slug: "recipient-output-and-built-in-pages"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-09"
---

# Phase 172 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit suites; existing Playwright/demo-browser evidence |
| **Config file** | Root `mix.exs`; `reference/demo_app/mix.exs`; `mailglass_admin/package.json` |
| **Quick run command** | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/renderer_test.exs test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors --seed 1` |
| **Full suite command** | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 600 -- bash scripts/gsd-regression-gate.sh` |
| **Estimated runtime** | Up to 600 seconds by the configured gate timeout; a prior run completed within that bound |

The local researcher could not resolve Mix through its initial plain `asdf exec` probe. The project gate exports the repository's locked Erlang/Elixir versions before invoking Mix; use that repository toolchain or CI if the local shim remains unavailable. Browser evidence remains distinct from delivered email-client rendering.

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command for the changed component, renderer, controller, or demo path.
- **After every plan wave:** Run the changed requirement's focused suites; do not repeat the full cross-project browser gate on unrelated waves.
- **Before `$gsd-verify-work`:** Run `bash scripts/gsd-regression-gate.sh` and the existing demo browser evidence command if the reference scenario changes.
- **Max feedback latency:** 600 seconds for the configured full regression gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 172-01-01 | 01 | 1 | MAILUX-01 | T-172-01 | Dynamic email content stays escaped; layout and VML fallbacks remain present | unit/component | `asdf exec mix test test/mailglass/components test/mailglass/renderer_test.exs --warnings-as-errors` | ✅ existing suites; extend assertions | ⬜ pending |
| 172-01-02 | 01 | 1 | MAILUX-02 | T-172-01 | Public-component example is registered and distinguishable from AtlasDesk's custom renderer | integration/browser | `bash scripts/run_demo_browser_evidence.sh` | ✅ existing demo browser evidence; extend scenario assertions | ⬜ pending |
| 172-02-01 | 02 | 2 | MAILUX-03 | T-172-01 | Generated plaintext preserves useful destinations once without changing text-body replacement semantics | unit | `asdf exec mix test test/mailglass/renderer_test.exs --warnings-as-errors --seed 1` | ✅ existing renderer suite; add edge cases | ⬜ pending |
| 172-03-01 | 03 | 3 | MAILUX-04 | T-172-02 | GET is non-mutating; invalid/expired pages do not disclose token or recipient values; POST remains unchanged | integration/controller | `asdf exec mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors --seed 1` | ✅ existing controller suite; extend assertions | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Add focused cases to existing component, renderer, controller, and demo evidence suites; install no framework or package.

---

## Manual-Only Verifications

All in-scope phase behaviors have automated verification. Actual delivered-message rendering in Gmail, Outlook, Apple Mail, image-disabled states, and client dark modes is outside this phase and must not be reported as verified.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency stays within 600 seconds for the full gate
- [ ] `nyquist_compliant: true` set after validation

**Approval:** pending
