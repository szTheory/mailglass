---
phase: 160
slug: certification-documentation-and-release
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-20
validated: 2026-08-20
---

# Phase 160 — Validation Strategy

> Reconstructed post-execution validation contract for the certified v2.6 package-family release.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) plus shell/workflow contract checks |
| **Config file** | `test/test_helper.exs`, `mailglass_admin/test/test_helper.exs`, `mailglass_inbound/test/test_helper.exs` |
| **Quick run command** | `mix test <task-specific files> --warnings-as-errors` |
| **Full phase command** | Run the four requirement groups in the verification report plus `actionlint` for the three release workflows |
| **Observed runtime** | Focused groups complete in approximately 4–30 seconds each; timing-contract groups take approximately 90 seconds |

## Sampling Rate

- **After every task commit:** Run the task's focused `<automated>` command.
- **After every plan wave:** Run that plan's aggregate verification command.
- **Before `$gsd-verify-work`:** Run all four requirement groups and validate the completed release ledger.
- **Max feedback latency:** Approximately 90 seconds for the slowest intentional workflow-timing group.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Evidence | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|--------------------|-------------|--------|
| 160-01-01 | 01 | 1 | REL-01 | T-160-01, T-160-02 | Ordered, sanitized durable host checkpoints | integration/negative | Generated-host and trust-runner command contracts | ✅ | ✅ green |
| 160-01-02 | 01 | 1 | REL-01 | T-160-03 | Scoped repos, prefixes, upgrades, rollbacks, and reruns | integration/negative | Generated-host and checkpoint contracts plus disposable-host proof | ✅ | ✅ green |
| 160-02-01 | 02 | 1 | REL-02 | T-160-04–06 | Public inventory rejects stale or fabricated promises | contract/mutation | Core and inbound documentation contracts | ✅ | ✅ green |
| 160-02-02 | 02 | 1 | REL-02 | T-160-04–06 | Shipped docs match the executable inventory | contract | `mix mailglass.docs.check` plus documentation suites | ✅ | ✅ green |
| 160-03-01 | 03 | 2 | REL-03 | T-160-07, T-160-09 | Remote metadata is parsed exactly and reported durably | unit/negative | Reconciliation fixture and hostile-input tests | ✅ | ✅ green |
| 160-03-02 | 03 | 2 | REL-03 | T-160-08 | Exactly three version baselines feed a policy-valid target | contract | Reconciliation and package stability contracts | ✅ | ✅ green |
| 160-04-01 | 04 | 3 | REL-03, REL-04 | T-160-10–12 | Candidate schema, identity, permissions, and input handling fail closed | unit/contract | Release-policy, concurrency, recovery, and hardening suites | ✅ | ✅ green |
| 160-04-02 | 04 | 3 | REL-03, REL-04 | T-160-10–12 | Dry-run preparation cannot activate publication | workflow/negative | Workflow contracts plus `actionlint` | ✅ | ✅ green |
| 160-05-01 | 05 | 4 | REL-03, REL-04 | T-160-13 | Candidate digest binds versions, package set, source, and content | policy/negative | `validate-candidate` and release-policy tests | ✅ | ✅ green |
| 160-05-02 | 05 | 4 | REL-04 | T-160-14 | Authorization names one exact candidate digest | immutable evidence | Completed ledger records the explicit authorization | ✅ | ✅ green |
| 160-06-01 | 06 | 5 | REL-04 | T-160-15, T-160-16 | Human authority binds the protected immutable ref | immutable evidence | Protected tag SHA and publication-run identity | ✅ | ✅ green |
| 160-06-02 | 06 | 5 | REL-04 | T-160-15–17 | All three packages publish or completion fails closed | external verifier | Publication run, release IDs, and Hex checksums | ✅ | ✅ green |
| 160-06-03 | 06 | 5 | REL-04 | T-160-17, T-160-18 | Exact-Hex adoption rejects path/git fallback | integration/negative | Post-publish and checkpoint contracts plus `verify-complete` | ✅ | ✅ green |

## Requirement Coverage

| Requirement | Coverage | Current Evidence |
|-------------|----------|------------------|
| REL-01 | COVERED | 22 generated-host/trust-runner tests pass; immutable exact-Hex artifact contains 20 ordered passed stages. |
| REL-02 | COVERED | Documentation checker passes; 72 core/inbound contracts pass with one intentional historical skip. |
| REL-03 | COVERED | Reconciliation, policy, recovery, and workflow negative controls pass; release tag matches all three public versions. |
| REL-04 | COVERED | 14 adoption contracts pass; `verify-complete` reports the exact package family and both successful protected runs. |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Every referenced test, fixture, script, and workflow exists; no Wave 0 stubs remain.

## Manual-Only Verifications

None remain. The two human decision checkpoints were executed with explicit candidate-digest authorization, and their outcomes are now independently checked by the immutable ledger, protected workflow runs, public package metadata, and downloaded checkpoint hashes.

## Validation Sign-Off

- [x] All tasks have automated verification or immutable externally verifiable evidence.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] No MISSING test references or Wave 0 gaps remain.
- [x] No watch-mode flags are used.
- [x] Feedback latency remains bounded by the intentional timing-contract suite.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** validated 2026-08-20

## Audit Record

The validate-phase reconstruction found 13/13 tasks and REL-01 through REL-04 covered. Fresh audit runs passed the 22-test generated-host group, the 72-test documentation group, and the 14-test exact-Hex adoption group; the completed ledger returned `completed=true`. No Nyquist gap required generated tests or a remediation agent.
