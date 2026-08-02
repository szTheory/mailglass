---
phase: 144
slug: signal-drift-integrity
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-31
---

# Phase 144 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus executable Bash/workflow contracts |
| **Config file** | `mix.exs`, `.formatter.exs` |
| **Quick run command** | `mix test <plan test files> --warnings-as-errors` |
| **Full suite command** | `mix verify.ci_lane_contract && mix verify.mix_tasks` |
| **Estimated runtime** | ~25 seconds |

## Sampling Rate

- **After every task commit:** Run the task's focused ExUnit command.
- **After every plan wave:** Run `mix verify.ci_lane_contract` and the affected subsystem gate.
- **Before phase completion:** Run focused Phase 144 tests, both verification aliases, conformance, formatting, workflow lint, and shell lint.
- **Max feedback latency:** 30 seconds for the Phase 144 contract suite.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | TRUTH-02 | T-144-01 | Only a verified clean protection state is green | hermetic integration | `mix test test/scripts/branch_protection_truth_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 144-01-02 | 01 | 1 | TRUTH-03 | T-144-02/03 | Scheduled verification precedes mutation; display name is canonical | hermetic integration | `mix test test/scripts/branch_protection_truth_test.exs test/scripts/required_checks_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 144-02-01 | 02 | 2 | TRUTH-06 | T-144-04/05 | Drift and cannot-check remain distinct non-success states | integration | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 144-03-01 | 03 | 2 | CONFORM-02 | T-144-06/07 | Computed icons are inventory-checked; unresolved forms fail closed | real-script integration | `mix test test/scripts/icon_exists_gate_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 144-04-01 | 04 | 2 | TRUTH-08 | T-144-08/09/10 | Linked release fan-out serializes and retries no-op successfully | workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 144-05-01 | 05 | 2 | TRUTH-04 | T-144-11/12/13 | Recovery is state-aware and fails closed on incomplete/unavailable truth | hermetic integration | `mix test test/scripts/release_trigger_recovery_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 144-05-02 | 05 | 2 | TRUTH-04 | T-144-11 | Maintainer recovery facts cannot drift from workflow behavior | documentation contract | `mix test test/scripts/release_trigger_recovery_test.exs --warnings-as-errors` | ✅ | ✅ green |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements; no Wave 0 additions remain.

## Manual-Only Verifications

All phase behaviors have automated verification. No UAT is required.

## Validation Audit 2026-07-31

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity has no three-task gap.
- [x] No missing test references remain.
- [x] Commands are one-shot, with no watch-mode flags.
- [x] Feedback latency is under 30 seconds.
- [x] `nyquist_compliant: true` is set.

**Approval:** approved 2026-07-31
