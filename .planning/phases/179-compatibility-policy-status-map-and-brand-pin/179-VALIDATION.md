---
phase: "179"
slug: "compatibility-policy-status-map-and-brand-pin"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-13"
---

# Phase 179 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `179-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4); `Phoenix.LiveViewTest.render_component/2`, Floki 0.38.5 |
| **Config file** | `mailglass_admin/test/test_helper.exs`; root `test/test_helper.exs` |
| **Quick run (admin)** | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/status_map_test.exs test/mailglass_admin/copy_contract_test.exs test/mailglass_admin/brand_v2_compat_policy_test.exs --warnings-as-errors` |
| **Quick run (core)** | `MIX_ENV=test mix test test/mailglass/outbound/suppressed_not_persisted_test.exs test/scripts/brand_pin_test.exs test/scripts/brand_trademark_gate_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.support_contract.admin`; root `mix test --warnings-as-errors` |
| **Estimated runtime** | ~105 s (admin lane); root suite longer |

Toolchain: `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

---

## Sampling Rate

- **After every task commit:** the relevant quick-run command above
- **After every plan wave:** `cd mailglass_admin && mix verify.support_contract.admin` and `mix test test/scripts test/mailglass/outbound --warnings-as-errors`
- **Before `/gsd-verify-work`:** root `mix test --warnings-as-errors`; admin lane; `mix mailglass.publish.check --allowlist-only` (`conflict=0`); `MIX_ENV=dev mix mailglass.docs.check`; `MIX_ENV=dev mix docs --warnings-as-errors`; `mix format --check-formatted` at root and in `mailglass_admin`; `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors`
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 179-01-xx | 01 | 1 | BRPOL-02 | — | Every status/event atom classified once; unmapped/nil raises | unit | `cd mailglass_admin && mix test test/mailglass_admin/status_map_test.exs` | ❌ W0 | ⬜ pending |
| 179-01-xx | 01 | 1 | BRPOL-02 | — | "Not sent" is pre-send only: zero Delivery rows and events across send/deliver_later/deliver_many | integration (DB) | `mix test test/mailglass/outbound/suppressed_not_persisted_test.exs` | ❌ W0 | ⬜ pending |
| 179-01-xx | 01 | 1 | BRPOL-03 | — | Screen strings come from `Copy`; drift fails; mutation recorded | unit + render | `cd mailglass_admin && mix test test/mailglass_admin/copy_contract_test.exs` | ❌ W0 | ⬜ pending |
| 179-02-xx | 02 | 1 | BRPOL-01 | — | Every retained public name exists; reverse check over `Mailglass.Operator.*` | unit | `cd mailglass_admin && mix test test/mailglass_admin/brand_v2_compat_policy_test.exs` | ❌ W0 | ⬜ pending |
| 179-03-xx | 03 | 1 | BRPOL-04 | T-179 pin tamper | Hash/asset tamper fails with named cause | unit (hermetic) | `mix test test/scripts/brand_pin_test.exs` | ❌ W0 | ⬜ pending |
| 179-03-xx | 03 | 1 | BRPOL-05 | — | Trademark record parses; gate fails closed | unit | `mix test test/scripts/brand_trademark_gate_test.exs` | ❌ W0 | ⬜ pending |

*Task IDs are finalized by the planner. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/status_map_test.exs`, `copy_contract_test.exs`, `brand_v2_compat_policy_test.exs`
- [ ] `test/mailglass/outbound/suppressed_not_persisted_test.exs`, `test/scripts/brand_pin_test.exs`, `test/scripts/brand_trademark_gate_test.exs`
- [ ] `mailglass_admin/lib/mailglass_admin/status_map.ex`, `copy.ex`; `scripts/brand_pin.exs`, `scripts/brand_trademark_gate.exs`
- [ ] `.planning/publish/mailglass_admin-files.expected` regenerated with the new lib files

No framework install needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification (Verification Policy D-52). The only owner hand-off is the trademark USPTO/TMview/WIPO register search, which agents cannot reach (bot challenges); it is recorded as `register_checked: false` with an owner runbook, and the gate fails closed.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
