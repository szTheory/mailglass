---
phase: 150
slug: private-envelope-and-atomic-durable-enqueue
status: ready
nyquist_compliant: true
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
| **Focused run convention** | `mix test <task files> --only phase_150_task:<task_tag> --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Focused latency target** | `<30 seconds` per task after dependencies are compiled and the test database is available; execution records measured duration rather than assuming it |
| **Broad-gate runtime** | Unbounded here: wave integration, docs, no-optional-deps compilation, and the full suite are measured during execution and run only at wave/phase gates |

---

## Sampling Rate

- **After every task commit:** Run only that task's `phase_150_task`-tagged unit/smoke command. The executor records elapsed time; if a sampler exceeds 30 seconds, split its tag group before proceeding.
- **After Wave 1:** Run the combined envelope + migration + hostile-prefix integration gate from Plan 01.
- **After Wave 2:** Run the combined envelope + single/batch enqueue integration gate from Plan 02.
- **After Wave 3:** Run the combined payload/worker/readiness suites and `mix compile --no-optional-deps --warnings-as-errors` from Plan 03.
- **After Wave 4:** Run the combined production-readiness, boot-separation, and production-checklist smoke gate from Plan 04.
- **After Wave 5 / before `$gsd-verify-work`:** Run docs generation/checks, the full Phase 150 focused-file integration command, then `mix test --warnings-as-errors` as the final broad phase gate.
- **After gap-closure Wave 6:** Run the complete envelope sampler, dedicated V06 lifecycle regression gate, and `MIX_ENV=test mix verify.no_optional_runtime`; Plans 150-06, 150-07, and 150-09 have disjoint file ownership and may execute in parallel.
- **After gap-closure Wave 7:** Run envelope + durable enqueue + worker together, then the full gap-closure command and `mix test --warnings-as-errors`; Plan 150-08 depends on 150-06's decoded message-plus-route contract.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 150-01-01 | 01 | 1 | ENVL-01, ENVL-02, ENVL-04 | T-150-01..04 | Private payload is tenant scoped; unsafe terms, mutable attachments, and private-content leakage are rejected | unit/smoke | `mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_01_01 --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 150-01-02 | 01 | 1 | ENVL-05 | T-150-05 | V06 creates exact prefix-safe storage without false legacy backfill | focused integration | `mix test test/mailglass/migration_test.exs test/mailglass/schema_prefix_hardening_test.exs --only phase_150_task:t150_01_02 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-02-01 | 02 | 2 | ENVL-01, ENVL-04, ENVL-05 | T-150-06, T-150-07 | Delivery, Event, Payload, and Job commit together or roll back together | focused integration | `mix test test/mailglass/outbound/deliver_later_test.exs --only phase_150_task:t150_02_01 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-02-02 | 02 | 2 | ENVL-05 | T-150-08 | Each eligible batch item uses the same per-envelope atomic boundary | focused integration | `mix test test/mailglass/outbound/deliver_many_test.exs --only phase_150_task:t150_02_02 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-03-01 | 03 | 3 | ENVL-04, ENVL-08 | T-150-09, T-150-10 | Worker loads immutable private payload under restored tenant and only uses legacy metadata for identified old rows | focused integration | `mix test test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_03_01 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-03-02 | 03 | 3 | ENVL-06, ENVL-08 | T-150-11, T-150-12 | Explicit Oban fails closed, queue is canonical, and no TaskSupervisor downgrade occurs | unit/smoke | `mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_03_02 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-04-01 | 04 | 4 | ENVL-07, ENVL-08 | T-150-13, T-150-14 | `Config.production_readiness/0` rejects TaskSupervisor, passes canonical-ready Oban, and stays separate from ordinary boot | unit/smoke | `mix test test/mailglass/config_test.exs test/mailglass/application_test.exs --only phase_150_task:t150_04_01 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-04-02 | 04 | 4 | ENVL-07, ENVL-08 | T-150-15 | Production checklist config and callable readiness smoke use only the canonical worker queue | contract smoke | `mix test test/mailglass/docs_migration_smoke_test.exs --only phase_150_task:t150_04_02 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-05-01 | 05 | 5 | ENVL-01, ENVL-06, ENVL-07, ENVL-08 | T-150-16..19 | Every active outbound source/API/adopter fallback seam agrees with fail-closed Oban and explicit non-durable TaskSupervisor; historical/inbound provenance is preserved | contract smoke | `mix test test/mailglass/docs_contract_test.exs --only phase_150_task:t150_05_01 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-06-01 | 06 | 6 | ENVL-02, ENVL-04 | T-150-20..23 | Full V1 field/adapter/nil/ordered-duplicate fidelity and attachment TOCTOU materialization | unit/integration | `mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_06_01 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-06-02 | 06 | 6 | ENVL-02 | T-150-20, T-150-21 | Recursive JSON depth/item/byte bounds and explicit IEEE non-finite rejection occur before persistence | unit/boundary | `mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_06_02 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-07-01 | 07 | 6 | ENVL-05 | T-150-24..26 | Exact V06 prefix-qualified catalog, no-backfill, hostile-search-path, down, and re-up lifecycle | focused integration | `mix test test/mailglass/v06_migration_test.exs --only phase_150_task:t150_07_01 --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 150-08-01 | 08 | 7 | ENVL-04 | T-150-27..29 | Real queued Oban worker ignores changed live render/assign/route state and uses the persisted V1 route | focused integration | `mix test test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_08_01 --warnings-as-errors` | ✅ extend | ⬜ pending |
| 150-09-01 | 09 | 6 | ENVL-06 | T-150-30..32 | Genuine Oban-free runtime invokes public send, returns dependency_unavailable, and produces zero effects | runtime smoke | `MIX_ENV=test mix verify.no_optional_runtime` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/outbound/envelope_test.exs` — V1 structural round trips, deterministic JSON bounds, unsafe-value rejection, and attachment materialization.
- [ ] Add transaction-failure injection seams for private Payload and Oban job insertion; assertions cover absence of all four durable records after rollback.
- [ ] Extend `test/mailglass/migration_test.exs` and `test/mailglass/schema_prefix_hardening_test.exs` for V06 create/down, payload indexes, hostile `search_path`, and no false legacy backfill.
- [ ] Keep all Oban manual/inline tests `async: false` and use the existing real `oban_jobs` test migration.
- [ ] Add task-scoped `phase_150_task` tags exactly as listed above so every per-task sampler runs only its new/changed behavioral slice; broad regression coverage remains at wave gates.
- [ ] Keep the Task 150-05-01 source-contract manifest scoped to active outbound source/API/adopter regions; historical planning archives, changelog/provenance, inbound sibling behavior, and webhook-maintenance cron fallback text are explicit exclusions.
- [ ] Expand `test/mailglass/outbound/envelope_test.exs` under task tags `t150_06_01` and `t150_06_02` for complete field/adapter/nil/collection fidelity, attachment source mutation/removal, and exact recursive resource boundaries.
- [ ] Create `test/mailglass/v06_migration_test.exs` under `t150_07_01` for direct V05→V06→down→up hostile-search-path catalog and zero-backfill proof.
- [ ] Extend `test/mailglass/outbound/worker_test.exs` under `t150_08_01` so the job is inserted through public `deliver_later/2`, live render/route state changes, and the actual stored job is performed.
- [ ] Create the isolated no-optional runtime script/probe and `verify.no_optional_runtime` alias for `t150_09_01`; the executing process must assert Oban/Worker absence before public send and measure every zero-effect store.

---

## Manual-Only Verifications

All Phase 150 behaviors have automated verification. Phase 153 owns the generated production-host proof that a real queue is actively consumed.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Each measured per-task sampler meets the <30s target, or its tag group is split before execution continues
- [ ] All nine task rows remain mapped after the Plan 04/05 scope split
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
