---
phase: 2
slug: persistence-tenancy
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18+) + StreamData (property tests) + Ecto SQL Sandbox |
| **Config file** | `test/test_helper.exs` — sandbox mode + `Mailglass.DataCase` / `Mailglass.TenancyCase` |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test --trace` |
| **Estimated runtime** | ~15 seconds (unit) / ~90 seconds (property + integration) |

---

## Sampling Rate

- **After every task commit:** `mix test --stale`
- **After every plan wave:** `mix test --trace`
- **Before `/gsd-verify-work`:** Full suite green (incl. property tests)
- **Max feedback latency:** 90 seconds (full) / 15 seconds (stale)

---

## Per-Task Verification Map

> Filled after planner produces plans; planner MUST emit `<automated>` or Wave 0 ref for every task so this table is complete before execution.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 0 | — | — | Wave 0 test infra bootstrap | infra | `mix test --stale` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02 | 1 | PERSIST-06 | — | Migration generator emits runnable file | unit | `mix test test/mailglass/migration_test.exs` | ❌ W0 | ⬜ pending |
| 2-02-02 | 02 | 1 | PERSIST-01, PERSIST-02 | — | SQLSTATE 45A01 raised on UPDATE/DELETE of events | integration | `mix test test/mailglass/events_immutability_test.exs` | ❌ W0 | ⬜ pending |
| 2-03-01 | 03 | 2 | PERSIST-01..05 | — | Ecto schemas + changesets pass structural validation | unit | `mix test test/mailglass/schemas_test.exs` | ❌ W0 | ⬜ pending |
| 2-04-01 | 04 | 2 | TENANT-01, TENANT-02 | — | `tenant_id` on every schema; `SingleTenant` is no-op default | unit | `mix test test/mailglass/tenancy_test.exs` | ❌ W0 | ⬜ pending |
| 2-05-01 | 05 | 3 | PERSIST-04 | — | `Events.append/2` outside `Ecto.Multi` raises `ArgumentError` | unit | `mix test test/mailglass/events_append_guard_test.exs` | ❌ W0 | ⬜ pending |
| 2-05-02 | 05 | 3 | PERSIST-03 (MAIL-03) | — | StreamData 1000-sequence webhook replay convergence | property | `mix test test/mailglass/events_idempotency_property_test.exs` | ❌ W0 | ⬜ pending |
| 2-06-01 | 06 | 4 | PERSIST-01..05, TENANT-01..02 | — | End-to-end: migrate → insert delivery → apply events → suppression check | integration | `mix test test/mailglass/persistence_integration_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Filled during planning — planner may refine task IDs and add rows; every task MUST appear here with an automated command before execution begins.*

---

## Wave 0 Requirements

- [ ] `test/support/data_case.ex` — shared sandbox setup (inherits `Ecto.Adapters.SQL.Sandbox`)
- [ ] `test/support/tenancy_case.ex` — tenant-scoped test helpers (sets + clears `Mailglass.Tenancy` process state)
- [ ] `test/test_helper.exs` — `ExUnit.start()` + StreamData seed config
- [ ] `test/mailglass/events_immutability_test.exs` — skeleton (asserts SQLSTATE 45A01)
- [ ] `test/mailglass/events_append_guard_test.exs` — skeleton (asserts `ArgumentError` outside Multi)
- [ ] `test/mailglass/events_idempotency_property_test.exs` — StreamData property harness skeleton
- [ ] `test/mailglass/tenancy_test.exs` — skeleton for `SingleTenant` resolver

*Wave 0 lands before any persistence code so failing tests drive implementation in Waves 1–4.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix mailglass.gen.migration` produces a runnable migration file in a fresh adopter app | PERSIST-06 | Requires integrator-level flow (new Phoenix app, add dep, run generator, run `mix ecto.migrate`) — not feasible inside unit test sandbox | Scripted in release checklist; CI `mix-test-adopter` lane (Phase 7) codifies this end-to-end; interim: manual smoke run on sibling scratch app |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (test files above)
- [ ] No watch-mode flags (CI lane uses `mix test`, not `mix test.watch`)
- [ ] Feedback latency < 90s full / < 15s stale
- [ ] `nyquist_compliant: true` set in frontmatter once planner fills the task map

**Approval:** pending
