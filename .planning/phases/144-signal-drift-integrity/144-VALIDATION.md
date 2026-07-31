---
phase: 144
slug: signal-drift-integrity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-31
---

# Phase 144 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus the existing Bash conformance gate |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scripts/required_checks_test.exs test/scripts/guard_release_trigger_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.ci_lane_contract` |
| **Icon gate command** | `bash mailglass_admin/scripts/check-conformance.sh` |
| **Estimated runtime** | Under 120 seconds after dependencies are available |

## Sampling Rate

- **After every task commit:** Run the focused ExUnit file(s) changed by that task; when the icon script changes, also run `bash mailglass_admin/scripts/check-conformance.sh`.
- **After every plan wave:** Run `mix verify.ci_lane_contract`.
- **Before `$gsd-verify-work`:** The full contract suite and normal icon gate must be green, and the deliberate dynamic-icon negative fixture must have been observed failing before cleanup.
- **Max feedback latency:** 120 seconds after dependencies are available.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | TRUTH-02 | T-144-01, T-144-03 | Missing credentials/tooling cannot yield green while the advisory remains read-only | workflow contract | `mix test test/scripts/branch_protection_truth_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 144-01-02 | 01 | 1 | TRUTH-02, TRUTH-03 | T-144-01, T-144-02, T-144-03 | Scheduled verification fails visibly and protected context uses the reported display name | workflow/identity contract | `mix test test/scripts/branch_protection_truth_test.exs test/scripts/required_checks_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 144-02-01 | 02 | 2 | TRUTH-06 | T-144-04, T-144-05 | CLI distinguishes clean, drift, and cannot-check without aggregate false success | Mix-task contract | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |
| 144-03-01 | 03 | 2 | CONFORM-02 | T-144-06, T-144-07 | Dynamic missing icons fail closed and fixtures are removed | shell integration fixture | `mix test test/scripts/icon_exists_gate_test.exs --warnings-as-errors && bash mailglass_admin/scripts/check-conformance.sh` | ❌ W0 | ⬜ pending |
| 144-04-01 | 04 | 2 | TRUTH-08 | T-144-08, T-144-09, T-144-10 | Linked release events serialize without losing idempotent no-op behavior | workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 144-05-01 | 05 | 2 | TRUTH-04 | T-144-11, T-144-12, T-144-13 | Recovery remains idempotent and partial state fails | workflow contract | `mix test test/scripts/release_trigger_recovery_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 144-05-02 | 05 | 2 | TRUTH-04 | T-144-11, T-144-12 | Maintainer docs state the bounded cadence, no-op branches, hard failure, and manual fallback | workflow/docs contract | `mix test test/scripts/release_trigger_recovery_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] Add focused workflow contracts for branch-protection unavailable, drift, and clean outcomes.
- [ ] Extend `test/scripts/required_checks_test.exs` with an anti-vacuous display-name-versus-job-id regression.
- [ ] Add a repo-hygiene test seam for the `branch_protection` outcome classification.
- [ ] Add a dynamic-icon fixture harness that runs the real gate and guarantees cleanup.
- [ ] Add source-contract coverage for both release concurrency blocks and release-please recovery behavior/documentation.
- [ ] Run `mix deps.get` before local ExUnit validation if the dependency lock remains stale.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Deliberate dynamic icon negative fixture fails and is removed | CONFORM-02 | The requirement explicitly calls for observing the real gate against a throwaway fixture | Run the fixture harness, confirm non-zero output names the missing dynamic `hero-*` icon, then verify the fixture is absent and the normal gate passes. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is under 120 seconds.
- [ ] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** pending
