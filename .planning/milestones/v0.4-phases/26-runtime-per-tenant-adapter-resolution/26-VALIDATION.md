---
phase: 26
slug: runtime-per-tenant-adapter-resolution
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for tenant-aware outbound routing, queue-time route persistence, and single-tenant fallback regression coverage.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Oban.Testing + StreamData |
| **Config file** | `test/test_helper.exs` plus support harnesses under `test/support/` |
| **Quick run command** | `mix test test/mailglass/tenancy_test.exs test/mailglass/config_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test test/mailglass/tenancy_test.exs test/mailglass/config_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs test/mailglass/migration_test.exs test/mailglass/persistence_integration_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~45s quick / ~75s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-scoped command for the files just changed
- **After every plan wave:** rerun the quick phase command
- **Before `$gsd-verify-work`:** rerun the full phase command
- **Max feedback latency:** 75 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | TENANT-01, TENANT-03 | T-26-01, T-26-03 | tenancy callback supports named refs, explicit default, and typed failure without breaking zero-config single-tenant behavior | unit | `mix test test/mailglass/tenancy_test.exs test/mailglass/config_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | TENANT-01, TENANT-03 | T-26-02, T-26-04 | every new queued route has a durable `adapter_ref`, including the reserved default ref | schema + migration | `mix test test/mailglass/outbound/delivery_test.exs test/mailglass/migration_test.exs test/mailglass/persistence_integration_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 26-02-01 | 02 | 2 | TENANT-01, TENANT-03 | T-26-05, T-26-08 | per-call override beats tenancy callback, tenancy callback beats default, and invalid routing fails loudly | unit + integration | `mix test test/mailglass/outbound_test.exs test/mailglass/core_send_integration_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 26-02-02 | 02 | 2 | TENANT-02, TENANT-03 | T-26-06, T-26-07, T-26-08 | async enqueue persists route identity and worker dispatch never recomputes provider choice from the tenancy callback | integration | `mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 26-03-01 | 03 | 3 | TENANT-01, TENANT-03 | T-26-09, T-26-11 | docs and runtime config examples stay aligned with the shipped routing surface and avoid deferred-scope promises | docs regression | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 26-03-02 | 03 | 3 | TENANT-01, TENANT-02, TENANT-03 | T-26-10 | public contract tests pin named refs, explicit default fallback, and queued no-drift semantics | regression | `mix test test/mailglass/docs_contract_test.exs test/mailglass/config_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors are expected to have automated verification.

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-26-01 | malformed tenant callback output reroutes mail unpredictably | Tampering | closed callback outcomes, explicit `:default`, typed errors | V5 |
| T-26-02 | route identity leaks credentials into persistence | Information Disclosure | persist only `adapter_ref`, resolve credentials at dispatch | V6 |
| T-26-03 | named registry values bypass config validation | Elevation of Privilege | route ref resolution goes through `Mailglass.Config` only | V5 |
| T-26-04 | provider provenance and queue intent blur together | Integrity | dedicated `adapter_ref`, keep `provider` for post-dispatch provenance | V4 |
| T-26-05 | precedence regressions silently change routing behavior | Integrity | explicit override → tenant callback → default tests | V1 |
| T-26-06 | queued retries drift across providers after config changes | Tampering | persist route identity for every queued send, including default path | V4 |
| T-26-07 | worker args expand to include secrets or config blobs | Information Disclosure | keep Oban args limited to ids and tenant stamp | V6 |
| T-26-08 | broken persisted refs silently fall back to the default adapter | Denial of Service | typed failures on unknown refs or malformed config | V5 |
| T-26-09 | docs promise unsupported routing features | Repudiation | docs-contract coverage and minimal runtime examples | V1 |
| T-26-10 | later refactors remove default-path no-drift guarantees | Integrity | regression coverage for reserved default ref semantics | V1 |
| T-26-11 | runtime examples encourage secret persistence or registry magic | Information Disclosure | use `config/runtime.exs` as canonical, minimal example surface | V1 |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit Wave 0 coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 75s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-01
