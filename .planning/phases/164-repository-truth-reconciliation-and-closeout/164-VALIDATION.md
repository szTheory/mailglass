---
phase: 164
slug: repository-truth-reconciliation-and-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-26
---

# Phase 164 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix project tests |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Focused tests under 2 minutes; `mix ci.fast` under 15 minutes |

---

## Sampling Rate

- **After every task commit:** Run the focused test file(s) named by that task.
- **After every plan wave:** Run `mix ci.fast`.
- **Before `$gsd-verify-work`:** Run `mix ci.fast`, then the final closeout command against exact protected `main` and fresh scheduled-control evidence.
- **Max feedback latency:** 15 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 164-01-01 | 01 | 1 | TRTH-01 | T-164-01 | Protected release authority is not broadened by maintainer guidance | docs contract | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | ✅ extend existing | ⬜ pending |
| 164-02-01 | 02 | 1 | TRTH-02 | Every audited item and ignore rule has exactly one evidence-backed disposition | schema contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | ❌ W0 | ⬜ pending |
| 164-03-01 | 03 | 2 | TRTH-03 | Wrong identity, stale evidence, dirty state, and cannot-check outcomes cannot produce a quiet verdict | integration/contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scripts/phase_164_repository_truth_test.exs` — ledger schema, exact-one-disposition coverage, all six ignore files, locked D-08 digest/removal record, and documentation truth assertions.
- [ ] `test/scripts/phase_164_closeout_test.exs` — fixture-backed failures for wrong branch/SHA, dirty state, pending or cannot-check scheduled evidence, and duplicate or missing ledger evidence.
- [ ] Add a focused closeout wrapper/report only if existing commands cannot provide one machine-readable verdict without reimplementing their logic.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Exact protected `main` closeout | TRTH-03 | Requires live GitHub branch, workflow, and scheduled-control state after the protected merge | From `/Users/jon/projects/mailglass` on clean `main`, confirm `HEAD == origin/main`, required checks pass for that exact SHA, and each applicable scheduled/recovery control has valid event, run, workflow-SHA, artifact provenance, and a pass or evidence-backed policy-blocked disposition. Preserve the volatile report outside tracked repository state. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15 minutes
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
