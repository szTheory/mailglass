---
phase: 57
slug: deterministic-trust-runner-fixtures
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 57 establishes the deterministic trust-runner command plus stable fixture/checkpoint contract for JOUR-01 and JOUR-02.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit integration/contract tests + deterministic checkpoint validation script |
| **Config file** | root `mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md` |
| **Quick run command** | `mix test test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.reference_host.journey` |
| **Estimated runtime** | ~90-180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix verify.reference_host.journey`
- **Before `/gsd-verify-work`:** Runner command and checkpoint validator must be green on fresh rerun
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | JOUR-01 | T-57-01 | Single deterministic runner entrypoint executes all stage checkpoints | integration | `mix verify.reference_host.journey` | ❌ W0 | ⬜ pending |
| 57-01-02 | 01 | 1 | JOUR-01 | T-57-02 | Runner stage names and ordering remain stable | contract | `mix test test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 57-02-01 | 02 | 1 | JOUR-02 | T-57-03 | Fixture IDs/payloads are deterministic and stable | contract | `mix test test/reference_host/trust_runner_fixture_contract_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 57-02-02 | 02 | 1 | JOUR-02 | T-57-04 | Checkpoint schema/boundary/hash are deterministic across reruns | contract + script | `mix test test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` and `bash scripts/check_trust_runner_checkpoint.sh --checkpoint tmp/mailglass_trust_runner/checkpoint.json` | ❌ W0 | ⬜ pending |
| 57-03-01 | 03 | 2 | JOUR-01 | T-57-05 | Local and CI wrappers call canonical runner entrypoint only | grep + contract | `rg -n "verify.reference_host.journey|mailglass\\.trust\\.run" .github/workflows/ci.yml MAINTAINING.md` | ❌ W0 | ⬜ pending |
| 57-03-02 | 03 | 2 | JOUR-02 | T-57-06 | Deferred Phase 58 concerns remain explicit and not silently claimed complete | docs contract | `rg -n "Phase 58|JOUR-03|JOUR-04|deferred" .planning/phases/57-deterministic-trust-runner-fixtures/*-PLAN.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/reference_host/trust_runner_command_contract_test.exs` — canonical runner command contract
- [ ] `test/reference_host/trust_runner_fixture_contract_test.exs` — deterministic fixture identity contract
- [ ] `test/reference_host/trust_runner_checkpoint_contract_test.exs` — checkpoint schema/determinism contract
- [ ] `scripts/check_trust_runner_checkpoint.sh` — executable checkpoint validation gate

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Runner output language remains bounded (no over-claim of global trust guarantees) | JOUR-01 | wording quality cannot be fully linted | Review runner output/docs and confirm bounded-claim posture ("pipeline confidence", not universal guarantees). |
| Fixture set remains intentionally minimal and maintainable | JOUR-02 | cardinality/maintainability tradeoff is judgment-heavy | Review fixture count and IDs; reject additions that are breadth expansion disguised as determinism. |
| Deferred Phase 58 semantics stay out of Phase 57 done claims | JOUR-01/JOUR-02 | requires intent interpretation | Verify checkpoint and docs state signed-negative and non-happy-path diagnosis are deferred to Phase 58. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
