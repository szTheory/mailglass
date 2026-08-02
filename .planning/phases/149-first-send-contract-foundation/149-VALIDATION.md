---
phase: 149
slug: first-send-contract-foundation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-02
---

# Phase 149 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit under Mix 1.19.5 / OTP 28 |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/renderer_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | Measure during Wave 0; keep focused feedback below 60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused test file(s) named by that task's `<automated>` verification.
- **After every plan wave:** Run `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/renderer_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors`.
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green.
- **Max feedback latency:** 60 seconds for focused checks; record and split any slower task-level command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 149-01-01 | 149-01 | 1 | FIRST-01 | T-149-01 | Only configured `SingleTenant` may normalize an unstamped caller to tenant `"default"` | integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-01-02 | 149-01 | 1 | FIRST-02 | T-149-01 | Custom tenancy remains fail-closed for missing, invalid, or unrestorable context | unit + integration | `mix test test/mailglass/tenancy_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-02-01 | 149-02 | 2 | FIRST-03 | T-149-02 | Every zero- or multi-recipient shape across `to`/`cc`/`bcc` is rejected without selecting or dropping an address | unit | `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-02-02 | 149-02 | 2 | FIRST-04 / FIRST-07 | T-149-03 / T-149-04 | Recipient/body rejection precedes rendering, limits, persistence, jobs, and provider dispatch; unsupported shapes use bounded non-PII errors | unit + integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-03-01 | 149-03 | 3 | FIRST-05 | T-149-04 | Explicit plaintext survives and text-only messages remain sendable | unit + integration | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-03-02 | 149-03 | 3 | FIRST-06 | T-149-04 | Plaintext generation and CSS inlining settings behave identically across render, sync, async, and preview | unit + integration + LiveView | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-04-01 | 149-04 | 4 | FIRST-01..FIRST-07 | T-149-01 / T-149-02 / T-149-04 | Stable API, authoring, and tenancy docs match the tested typed-error and preflight contract | docs + contract regression | `mix docs && mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-04-02 | 149-04 | 4 | FIRST-01 / FIRST-05 / FIRST-06 | T-149-04 | Getting-started, jobs, and preview docs match tested renderer behavior without future-phase claims | docs + integration | `mix docs && mix test test/mailglass/renderer_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |

*Task IDs, plans, and waves are reconciled after PLAN.md generation. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky.*

---

## Wave 0 Requirements

- [x] Plan 149-03 Task 02 extends `mailglass_admin/test/mailglass_admin/preview_live_test.exs` test-first with config-isolated renderer-parity regressions for `renderer.plaintext` and `renderer.css_inliner`.
- [x] Plan 149-02 Task 02 confirms or adds a stable assertion seam before implementation that proves preflight rejection inserts zero Oban jobs.
- [x] Plan 149-03 Tasks 01-02 add config-isolated renderer tests that restore application environment and relevant Mailglass config cache state after every case.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Any Task.Supervisor/Fake-adapter ownership warnings observed during research must remain non-failing and must not replace row/job/provider side-effect assertions.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 coverage is assigned test-first before the corresponding implementation
- [x] No watch-mode flags
- [x] Feedback latency target is below 60s for focused checks and must be measured during execution
- [x] Per-task map reconciled to final PLAN task IDs
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
