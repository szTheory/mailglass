---
phase: "179"
slug: "compatibility-policy-status-map-and-brand-pin"
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 179-01-01 | 01 | 1 | BRPOL-02 | T-179-01 | 26 atoms classified once from a source-derived universe; unmapped/nil raise; delivery_class precedence incl. durable failure fields and the pinned operator-row limitation; no real row reaches the "Unknown" fallback; grid cross-check against a pre-declared 29-row oracle | unit | `cd mailglass_admin && mix test test/mailglass_admin/status_map_test.exs` | ✅ present | ✅ green |
| 179-01-02 | 01 | 1 | BRPOL-03 | T-179-02 | Screen strings come from `Copy` (golden, render, closed-set scan with fixed baselines); five mutations recorded | unit + render | `cd mailglass_admin && mix test test/mailglass_admin/copy_contract_test.exs` | ✅ present | ✅ green |
| 179-01-03 | 01 | 1 | BRPOL-02 | — | "Not sent" is pre-send only: zero Delivery rows and events across send/deliver_later/deliver_many, plus positive control; "25" amended to 26 in its own two-line docs commit | integration (DB) | `mix test test/mailglass/outbound/suppressed_not_persisted_test.exs` | ✅ present | ✅ green |
| 179-02-01 | 02 | 1 | BRPOL-01 | T-179-04 | One policy table row parsed from the doc and verified against live code | unit | `cd mailglass_admin && mix test test/mailglass_admin/brand_v2_compat_policy_test.exs` | ✅ present | ✅ green |
| 179-02-02 | 02 | 1 | BRPOL-01 | T-179-05 | Full inventory, every verifier kind, reverse check over `Mailglass.Operator.*`, api_stability pointer; docs lanes green | unit + docs | `cd mailglass_admin && mix test test/mailglass_admin/brand_v2_compat_policy_test.exs test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/stability_contract_test.exs` | ✅ present | ✅ green |
| 179-03-01 | 03 | 1 | BRPOL-04 | T-179-06, T-179-07 | Pin by commit and zip sha256; four byte-identical assets; offline verify green | unit (hermetic) | `mix test test/scripts/brand_pin_test.exs` | ✅ present | ✅ green |
| 179-03-02 | 03 | 1 | BRPOL-04 | T-179-09, T-179-10 | Every tamper case (incl. CRLF, empty, idempotency edges) names its cause; full book absent from tree | unit (hermetic) | `mix test test/scripts/brand_pin_test.exs` | ✅ present | ✅ green |
| 179-03-03 | 03 | 1 | BRPOL-04 | T-179-08 | Advisory online check and reviewed update procedure tested hermetically; mutation run recorded | unit (hermetic) | `mix test test/scripts/brand_pin_test.exs` | ✅ present | ✅ green |
| 179-04-01 | 04 | 1 | BRPOL-05 | T-179-11, T-179-13 | Honest record committed; gate (announcement_allowed?/1 entry, pure /2) denies it; no clock in the test | unit | `mix test test/scripts/brand_trademark_gate_test.exs` | ✅ present | ✅ green |
| 179-04-02 | 04 | 1 | BRPOL-05 | T-179-12 | Planted fail-closed states each name their reason; owner runbook with checked URLs | unit | `mix test test/scripts/brand_trademark_gate_test.exs` | ✅ present | ✅ green |

*Task IDs map to the four plans (179-01..04). Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `mailglass_admin/test/mailglass_admin/status_map_test.exs`, `copy_contract_test.exs`, `brand_v2_compat_policy_test.exs`
- [x] `test/mailglass/outbound/suppressed_not_persisted_test.exs`, `test/scripts/brand_pin_test.exs`, `test/scripts/brand_trademark_gate_test.exs`
- [x] `mailglass_admin/lib/mailglass_admin/status_map.ex`, `copy.ex`; `scripts/brand_pin.exs`, `scripts/brand_trademark_gate.exs`
- [x] `.planning/publish/mailglass_admin-files.expected` regenerated with the new lib files

No framework install needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification (Verification Policy D-52). The only owner hand-off is the trademark USPTO/TMview/WIPO register search, which agents cannot reach (bot challenges); it is recorded as `register_checked: false` with an owner runbook, and the gate fails closed.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated Nyquist audit complete; no owner UAT is required for the covered behaviors.

## Validation Audit 2026-11-17

| Metric | Count |
|---|---|
| Gaps found | 9 |
| Resolved | 9 |
| Escalated | 0 |
