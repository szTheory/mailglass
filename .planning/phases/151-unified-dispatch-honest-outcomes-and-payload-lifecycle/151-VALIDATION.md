---
phase: 151
slug: unified-dispatch-honest-outcomes-and-payload-lifecycle
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-02
---
# Phase 151 — Validation Strategy

## Test Infrastructure
| Property | Value |
|---|---|
| Framework | ExUnit + Ecto/Postgres + Oban manual execution |
| Config | `config/test.exs`, `test/test_helper.exs`, `Mailglass.DataCase`, Phase 150 Oban helpers |
| Focused convention | `mix test <files> --only phase_151_task:<tag> --warnings-as-errors` |
| Full suite | `mix test --warnings-as-errors` |
| Optional runtime | `MIX_ENV=test mix verify.no_optional_runtime` |

## Sampling Rate
- After every task commit: run its exact tagged command below.
- After each wave: run all Phase 151 test files introduced/extended through that wave plus inherited Phase 150 worker/envelope regressions.
- Before verification: run support contract, no-optional-runtime proof, then full suite.
- If a focused sampler exceeds 30 seconds after dependencies/database are ready, split its tag group before continuing.

## Per-Task Verification Map
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---:|---:|---|---|---|---|---|---|---|
| 151-01-01 | 01 | 1 | ENVL-03 | T-151-01..02 | Complete adapter input parity; private surface separation | integration | `mix test test/mailglass/outbound/wire_equivalence_test.exs --only phase_151_task:t151_01_01 --warnings-as-errors` | ❌ W0 | ⬜ |
| 151-02-01 | 02 | 1 | DISP-01 | T-151-03..04 | Closed structural classification; no raw text leakage | unit | `mix test test/mailglass/outbound/dispatch_outcome_test.exs test/mailglass/adapters/swoosh_test.exs --only phase_151_task:t151_02_01 --warnings-as-errors` | ❌/✅ | ⬜ |
| 151-03-01 | 03 | 1 | PRIV-01/02/04 | T-151-05..06 | Prefix-safe lifecycle schema and tombstone constraint | migration integration | `mix test test/mailglass/v07_migration_test.exs test/mailglass/migration_test.exs --only phase_151_task:t151_03_01 --warnings-as-errors` | ❌/✅ | ⬜ |
| 151-04-01 | 04 | 2 | PRIV-01 | T-151-07..10 | CAS claim, external I/O, atomic success scrub | integration/concurrency | `mix test test/mailglass/outbound/payload_lifecycle_test.exs --only phase_151_task:t151_04_01 --warnings-as-errors` | ❌ W0 | ⬜ |
| 151-04-02 | 04 | 2 | DISP-02/03 PRIV-03/04 | T-151-07..10 | Exhaustive Oban mapping and fail-closed invalid payloads | integration | `mix test test/mailglass/outbound/worker_test.exs test/mailglass/outbound/payload_lifecycle_test.exs --only phase_151_task:t151_04_02 --warnings-as-errors` | ✅/❌ | ⬜ |
| 151-05-01 | 05 | 3 | PRIV-02/03/04 | T-151-11..13 | Finite policy, one bounded tenant/prefix batch, honest recovery | integration | `mix test test/mailglass/config_test.exs test/mailglass/outbound/payload_lifecycle_test.exs --only phase_151_task:t151_05_01 --warnings-as-errors` | ✅/❌ | ⬜ |
| 151-06-01 | 06 | 4 | PRIV-02 | T-151-14..15 | Same manual/optional prune path; no-Oban compile | integration/runtime | `mix test test/mailglass/outbound/payload_pruner_test.exs --only phase_151_task:t151_06_01 --warnings-as-errors && MIX_ENV=test mix verify.no_optional_runtime` | ❌ W0 | ⬜ |
| 151-07-01 | 07 | 5 | DISP-04 PRIV-02/03/04 | T-151-16..18 | Honest boundary/privacy/operations wording | contract | `mix test test/mailglass/docs_contract_test.exs --only phase_151_task:t151_07_01 --warnings-as-errors && MIX_ENV=test mix verify.support_contract.core` | ✅ | ⬜ |

## Wave 0 Requirements
- [ ] Create `wire_equivalence_test.exs`, `dispatch_outcome_test.exs`, `v07_migration_test.exs`, `payload_lifecycle_test.exs`, and `payload_pruner_test.exs` in their owning tasks before production edits.
- [ ] Extend existing Swoosh, worker, migration, config, and docs tests under exact `phase_151_task` tags.
- [ ] Reuse actual public enqueue jobs, guarded scratch schemas, hostile search paths, and private unique sentinels; do not construct false-green worker arguments.
- [ ] Preserve `async: false` for application-config, DDL, concurrency, and Oban-manual tests.

## Manual-Only Verifications
All Phase 151 behavior has automated verification. Phase 153 owns generated-host/operator proof.

## Phase Gate
`mix test test/mailglass/outbound/wire_equivalence_test.exs test/mailglass/outbound/dispatch_outcome_test.exs test/mailglass/outbound/payload_lifecycle_test.exs test/mailglass/outbound/payload_pruner_test.exs test/mailglass/outbound/worker_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/v07_migration_test.exs test/mailglass/config_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors && MIX_ENV=test mix verify.no_optional_runtime && MIX_ENV=test mix verify.support_contract.core && mix test --warnings-as-errors`

## Validation Sign-Off
- [ ] All task samplers green
- [ ] No three consecutive tasks lack automated feedback
- [ ] Wave 0 files created before behavior implementation
- [ ] No watch-mode flags
- [ ] Full suite, support contract, and no-optional-runtime gate green
- [ ] Set `wave_0_complete: true`, `nyquist_compliant: true`, and `status: validated`

**Approval:** pending

