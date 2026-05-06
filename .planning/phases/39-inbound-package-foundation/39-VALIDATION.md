---
phase: 39
slug: inbound-package-foundation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 39 - Validation Strategy

> Per-phase validation contract for the canonical inbound package foundation: stable public contract, routing/mailbox semantics, and tenant-safe persistence boundaries.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix tasks |
| **Config file** | `mix.exs`, `config/test.exs`, and the new `mailglass_inbound/mix.exs` once scaffolded |
| **Quick run command** | `mix test test/mailglass_inbound --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors && cd mailglass_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~60s quick / ~180s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-local `test/mailglass_inbound` command covering the files just changed
- **After every plan wave:** rerun `mix test test/mailglass_inbound --warnings-as-errors`
- **Before `$gsd-verify-work`:** rerun the full suite commands in both projects
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | MODEL-01 | T-39-01 | `%InboundMessage{}` exposes only stable normalized fields and keeps raw/provider-only data out of the public struct | unit / docs contract | `mix test test/mailglass_inbound/inbound_message_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 39-01-02 | 01 | 1 | ROUTE-01, MAILBOX-01 | T-39-02, T-39-03 | router DSL compiles deterministically, enforces first-match-wins semantics, and mailbox callback outcomes stay restricted to the locked result classes | unit / compile-time contract | `mix test test/mailglass_inbound/router_test.exs test/mailglass_inbound/mailbox_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 39-02-01 | 02 | 2 | Phase 39 storage foundation | T-39-04 | canonical inbound records, evidence rows, and replay/history rows preserve tenant scope and stable-vs-raw boundaries | changeset / persistence | `mix test test/mailglass_inbound/persistence_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 39-02-02 | 02 | 2 | Phase 39 storage foundation | T-39-05 | replay linkage cannot be mistaken for fresh receive semantics and package-local FK boundaries remain intact | persistence / regression | `mix test test/mailglass_inbound/replay_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 39-03-01 | 03 | 3 | MODEL-01, ROUTE-01, MAILBOX-01 | T-39-07 | sibling-package scaffolding, docs, and optional-dependency seams compile cleanly without introducing mandatory Oban coupling | compile / contract | `mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors` | ✅ | ✅ green |
| 39-03-02 | 03 | 3 | MODEL-01, ROUTE-01, MAILBOX-01 | T-39-08 | public docs and contract tests describe only the supported Phase 39 surface and exclude deferred router/mailbox/provider features | docs contract / regression | `mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs` - stable struct contract coverage
- [x] `mailglass_inbound/test/mailglass_inbound/router_test.exs` - DSL compile/runtime route semantics
- [x] `mailglass_inbound/test/mailglass_inbound/mailbox_test.exs` - mailbox outcome contract coverage
- [x] `mailglass_inbound/test/mailglass_inbound/persistence_test.exs` - canonical/evidence/history boundary checks
- [x] `mailglass_inbound/test/mailglass_inbound/replay_test.exs` - replay-linkage and non-fresh-receive proof
- [x] `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - supported-surface documentation proof

---

## Manual-Only Verifications

All Phase 39 behaviors are expected to have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-06
