---
phase: 69
slug: click
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 69 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix ConnCase) plus existing Playwright smoke seed |
| **Config file** | `reference/demo_app/test/test_helper.exs`; `reference/demo_app/assets/playwright.config.cjs` |
| **Quick run command** | `cd reference/demo_app && mix test test/mailglass_demo_web/page_controller_dashboard_test.exs` or `cd reference/demo_app && mix test test/mailglass_demo/docs_contract_test.exs` |
| **Full suite command** | `cd reference/demo_app && mix test --warnings-as-errors` |
| **Estimated runtime** | Targeted per-task commands: <30 seconds each; full suite gate: ~60 seconds |

---

## Sampling Rate

- **After dashboard task commits:** Run `cd reference/demo_app && mix test test/mailglass_demo_web/page_controller_dashboard_test.exs test/mailglass_demo_web/page_controller_security_test.exs`
- **After docs task commits:** Run `cd reference/demo_app && mix test test/mailglass_demo/docs_contract_test.exs`
- **After every plan wave:** Run `cd reference/demo_app && mix test --warnings-as-errors`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** <30 seconds for targeted per-task feedback; the ~60 second full suite is retained only for wave and phase gates because this phase intentionally keeps verification inside existing Mix/ExUnit lanes instead of adding new tooling.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-01-01 | 01 | 0 | DEMO-03 | T-69-01 | Dashboard route renders safe links to `/dev/mail`, `/demo/login?return_to=/ops/mail?tenant_id=northstar`, and `/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar`. | controller | `cd reference/demo_app && mix test test/mailglass_demo_web/page_controller_dashboard_test.exs` | yes | covered |
| 69-01-02 | 01 | 0 | DX-03 | T-69-02 | Canonical demo docs describe quickstart, persona/JTBD, seeded data, reset semantics, dependency mode, and demo-vs-contract boundary. | docs contract | `cd reference/demo_app && mix test test/mailglass_demo/docs_contract_test.exs` | yes | covered |
| 69-02-01 | 02 | 1 | DEMO-03 | T-69-01 | Safe `return_to` filtering remains restricted to local operator paths and rejects external redirects. | controller | `cd reference/demo_app && mix test test/mailglass_demo_web/page_controller_security_test.exs` | yes | covered |
| 69-02-02 | 02 | 1 | DX-03 | T-69-03 | Reset wording remains explicit that demo evidence tables are truncated and reseeded. | controller + docs | `cd reference/demo_app && mix test --warnings-as-errors` | yes | covered |

---

## Wave 0 Requirements

- [x] `reference/demo_app/test/mailglass_demo_web/page_controller_dashboard_test.exs` - route, dashboard content, link, reset warning, and Northstar summary assertions for DEMO-03.
- [x] `reference/demo_app/test/mailglass_demo/docs_contract_test.exs` - static assertions for DX-03 terms in `reference/demo_app/README.md`.
- [x] Keep `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` green while changing dashboard/login/reset code.

---

## Manual-Only Verifications

All Phase 69 behaviors have automated verification. Full browser screenshots, deterministic browser checkpoints, and `demo_browser_evidence.v1` artifact hardening are intentionally deferred to Phase 70.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Targeted per-task feedback latency < 30s; full suite may remain ~60s at wave and phase gates
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-02
