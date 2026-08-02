---
phase: 150
slug: private-envelope-and-atomic-durable-enqueue
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-02
---

# Phase 150 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs`; `Mailglass.DataCase`, `Mailglass.MailerCase`, and `test/support/oban_helpers.ex` |
| **Quick run command** | `mix test test/mailglass/outbound/envelope_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds quick; full-suite runtime depends on local PostgreSQL and tagged browser/integration lanes |

---

## Sampling Rate

- **After every task commit:** Run the task's focused ExUnit command; gateway or worker edits also run `mix compile --no-optional-deps --warnings-as-errors`.
- **After every plan wave:** Run `mix test --warnings-as-errors`.
- **Before `$gsd-verify-work`:** Full suite and prefix/migration tests must be green.
- **Max feedback latency:** 180 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 150-01-01 | 01 | 1 | ENVL-01, ENVL-02 | T-150-01 | Private payload is tenant scoped; unsafe terms and private-content leakage are rejected | unit | `mix test test/mailglass/outbound/envelope_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 150-01-02 | 01 | 1 | ENVL-05 | T-150-02 | V06 creates a prefix-safe one-to-one payload store without false legacy backfill | integration | `mix test test/mailglass/migration_test.exs test/mailglass/schema_prefix_hardening_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-02-01 | 02 | 2 | ENVL-01, ENVL-04, ENVL-05 | T-150-03 | Delivery, Event, Payload, and Job commit together or roll back together | integration | `mix test test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-02-02 | 02 | 2 | ENVL-05 | T-150-03 | Each eligible batch item uses the same per-envelope atomic boundary | integration | `mix test test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-03-01 | 03 | 3 | ENVL-04 | T-150-04 | Worker loads immutable private payload under restored tenant and only uses legacy metadata for identified old rows | integration | `mix test test/mailglass/outbound/worker_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-03-02 | 03 | 3 | ENVL-06, ENVL-07, ENVL-08 | T-150-05 | Explicit Oban fails closed; explicit TaskSupervisor stays non-durable; queue is `mailglass_outbound` | unit + integration | `mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-04-01 | 04 | 4 | ENVL-07, ENVL-08 | — | Public docs/config checks state the durable boundary and canonical queue exactly | contract | `mix test test/mailglass/docs_migration_smoke_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/outbound/envelope_test.exs` — V1 structural round trips, deterministic JSON bounds, unsafe-value rejection, and attachment materialization.
- [ ] Add transaction-failure injection seams for private Payload and Oban job insertion; assertions cover absence of all four durable records after rollback.
- [ ] Extend `test/mailglass/migration_test.exs` and `test/mailglass/schema_prefix_hardening_test.exs` for V06 create/down, payload indexes, hostile `search_path`, and no false legacy backfill.
- [ ] Keep all Oban manual/inline tests `async: false` and use the existing real `oban_jobs` test migration.

---

## Manual-Only Verifications

All Phase 150 behaviors have automated verification. Phase 153 owns the generated production-host proof that a real queue is actively consumed.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
