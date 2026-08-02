---
phase: 149
slug: first-send-contract-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| TBD-01 | TBD | TBD | FIRST-01 | T-149-01 | Only configured `SingleTenant` may normalize an unstamped caller to tenant `"default"` | integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| TBD-02 | TBD | TBD | FIRST-02 | T-149-01 | Custom tenancy remains fail-closed for missing, invalid, or unrestorable context | unit + integration | `mix test test/mailglass/tenancy_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| TBD-03 | TBD | TBD | FIRST-03 | T-149-02 | Every zero- or multi-recipient shape across `to`/`cc`/`bcc` is rejected without selecting or dropping an address | unit | `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| TBD-04 | TBD | TBD | FIRST-04 | T-149-03 | Recipient rejection precedes rendering, limits, persistence, jobs, and provider dispatch | integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| TBD-05 | TBD | TBD | FIRST-05 | T-149-04 | Explicit plaintext survives and text-only messages remain sendable | unit + integration | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| TBD-06 | TBD | TBD | FIRST-06 | T-149-04 | Plaintext generation and CSS inlining settings behave identically across render, sync, async, and preview | unit + integration + LiveView | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| TBD-07 | TBD | TBD | FIRST-07 | T-149-03 / T-149-04 | Unsupported body/envelope shapes produce bounded non-PII `:preflight_rejected` errors before delivery or job creation | unit + integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |

*Task IDs, plans, and waves are reconciled after PLAN.md generation. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky.*

---

## Wave 0 Requirements

- [ ] Extend `mailglass_admin/test/mailglass_admin/preview_live_test.exs` with config-isolated renderer-parity regressions for `renderer.plaintext` and `renderer.css_inliner`.
- [ ] Confirm or add a stable assertion seam proving preflight rejection inserts zero Oban jobs.
- [ ] Add config-isolated renderer tests that restore application environment and the Mailglass config cache after every case.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Any Task.Supervisor/Fake-adapter ownership warnings observed during research must remain non-failing and must not replace row/job/provider side-effect assertions.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for focused checks
- [ ] Per-task map reconciled to final PLAN task IDs
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
