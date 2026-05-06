---
phase: 40
slug: postmark-ingress-and-replayable-persistence
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for verify-first Postmark ingress, replay-oriented canonical/evidence persistence, and honest no-execution-yet contract proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Plug/Phoenix request tests + Ecto persistence tests + docs contract tests |
| **Config file** | `mailglass_inbound/config/test.exs`, `mailglass_inbound/test/test_helper.exs`, package-local migrations and ingress modules |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/postmark_provider_test.exs test/mailglass_inbound/ingress/persist_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_inbound && mix test --warnings-as-errors` |
| **Estimated runtime** | ~20-40s task-local / ~90-150s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest changed-surface package-local test lane
- **After every plan wave:** rerun the quick phase commands for ingress + persistence
- **Before `$gsd-verify-work`:** `cd mailglass_inbound && mix test --warnings-as-errors`
- **Max feedback latency:** 150 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 1 | `INGRESS-01` | T-40-01, T-40-02 | Postmark ingress verifies before tenant resolution, fails closed on bad auth, and normalizes only into the locked `%InboundMessage{}` fields | provider / request | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/postmark_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ⬜ Task creates files | ⬜ pending |
| 40-01-02 | 01 | 1 | `INGRESS-01` | T-40-03 | raw-body capture remains path-local and exact, with explicit config error when the body reader is absent | request / unit | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/caching_body_reader_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ⬜ Task creates files | ⬜ pending |
| 40-02-01 | 02 | 2 | `STORE-01` | T-40-04, T-40-05 | canonical record + evidence row persist in one transaction with replayable truth and no fresh-ingress replay write | persistence | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/persist_test.exs --warnings-as-errors` | ⬜ Task creates files | ⬜ pending |
| 40-02-02 | 02 | 2 | `INGRESS-01`, `STORE-01` | T-40-06 | duplicate Postmark receives collapse on `(tenant_id, provider, provider_message_id)`, return explicit duplicate outcomes without reprocessing, and prove route compatibility without mailbox execution | persistence / integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ⬜ Task creates files | ⬜ pending |
| 40-03-01 | 03 | 3 | `INGRESS-01`, `STORE-01` | T-40-07 | adopter-facing docs describe one honest mount/config path, replayable storage truth, and explicit rejection/duplicate semantics without claiming mailbox execution | docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ existing lane extended | ⬜ pending |
| 40-03-02 | 03 | 3 | `INGRESS-01`, `STORE-01` | T-40-08 | end-to-end contract proof covers parse, storage, duplicate, and rejection paths while preserving the “routing compatibility only” boundary | integration bundle | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/postmark_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ⬜ mixed existing/new | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new harness or
standalone `route_compatibility_test.exs` file is required before planning;
route-compatibility proof is covered inside `persist_test.exs` and
`plug_test.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Adopter mount/config snippets match a real Phoenix `Plug.Parsers` setup using the inbound body reader | `INGRESS-01` | The exact host-app parser stack is integration-specific and not fully represented inside the sibling package tests | Confirm the docs show `:body_reader` wiring and the request path matches the package-local plug examples without relying on root-package webhook docs alone. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual-only rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 150s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
