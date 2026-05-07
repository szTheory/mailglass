---
phase: 44
slug: async-adoption-closeout-reconciliation
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-06
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a closeout-proof + bookkeeping-reconciliation phase. The shipped Phase 42 test surface is the canonical proof; Phase 44 work is artifact creation (`42-VERIFICATION.md`, `v1.1-MILESTONE-AUDIT-CLOSEOUT.md`) and central bookkeeping reconciliation. No new test infrastructure is required.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing) + Mix tasks + grep/file verification + `actionlint` |
| **Config file** | `mailglass_inbound/mix.exs`, `mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors && cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors && actionlint .github/workflows/release-please.yml` |
| **Estimated runtime** | ~20–40s task-local · ~120–180s full phase scope |

---

## Sampling Rate

- **After every task commit:** Run quick run command above
- **After every plan wave:** Run full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green AND closeout grep checks must pass AND audit re-run must record `status: passed`
- **Max feedback latency:** ~40 seconds for task-local, ~180 seconds for full suite

---

## Per-Task Verification Map

> Task IDs are placeholders that the planner will replace with concrete `44-01-NN` / `44-02-NN` task numbers. Each row maps a planning artifact or bookkeeping change back to a requirement and the test command that proves the underlying behavior.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | EXEC-01 | — | Durable Oban-backed dispatch via internal worker (no public surface widening) | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 44-01-02 | 01 | 1 | EXEC-02 | — | Bounded `Task.Supervisor` fallback with explicit `:best_effort` warning emitted once per node | unit + plug integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 44-01-03 | 01 | 1 | ADOPT-01 | — | Honest adoption docs + drift guard + root release/publish proof | docs contract + root contract + workflow lint | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors && cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors && actionlint .github/workflows/release-please.yml` | ✅ | ⬜ pending |
| 44-01-04 | 01 | 1 | EXEC-01 / EXEC-02 / ADOPT-01 | — | `42-VERIFICATION.md` exists, uses execution-evidence language (not plan-check language), and ties each Observable Truth to a re-run command | grep | `test -f .planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md && ! rg -n "passes plan checker\|✓ PLANNED\|Plan-Check Findings\|will execute" .planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md` | ⬜ task creates | ⬜ pending |
| 44-02-01 | 02 | 2 | EXEC-01 / EXEC-02 / ADOPT-01 | — | `REQUIREMENTS.md` traceability table no longer marks any of the three requirements `Pending` against Phase 44 | grep | `! rg -n "\| (EXEC-01\|EXEC-02\|ADOPT-01) \| Phase 44 \| Pending \|" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 44-02-02 | 02 | 2 | (closeout) | — | `STATE.md` records Phase 44 activity and removes any contradiction with the requirement reconciliation | grep | `rg -n "Phase 44" .planning/STATE.md` | ✅ | ⬜ pending |
| 44-02-03 | 02 | 2 | (closeout) | — | `ROADMAP.md` Phase 43/44 rows no longer leave a misleading status (e.g., Phase 43 `Pending` after Phase 43 closure) | grep | `rg -n "Phase 43" .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 44-02-04 | 02 | 2 | (closeout) | — | Milestone audit re-run produces a closeout artifact recording an audit-pass result | grep + file existence | `test -f .planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md && rg -n "status: passed" .planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` | ⬜ task creates | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — all required test infrastructure already exists. Phase 42 already created:

- `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs` (EXEC-01 / EXEC-02 behavioral proof)
- `mailglass_inbound/test/mailglass_inbound/worker_test.exs` (internal worker contract)
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (ADOPT-01 docs drift guard, including `refute readme =~ "%Oban.Job{}"` and `refute stability =~ "stable public replay API"`)
- `test/mailglass/stability_contract_test.exs` (root verification + sibling-package release/publish truth)
- `actionlint` over `.github/workflows/release-please.yml`

Phase 44 creates only planning artifacts (`42-VERIFICATION.md`, `v1.1-MILESTONE-AUDIT-CLOSEOUT.md`, Phase 44 SUMMARY files) and central bookkeeping edits. Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recovered `42-VERIFICATION.md` uses execution-evidence language and not plan-check language | EXEC-01 / EXEC-02 / ADOPT-01 | Document-truth judgment, mirroring the Phase 43 manual-only check. Grep guards catch the obvious tells (`passes plan checker`, `✓ PLANNED`, `Plan-Check Findings`, `will execute`) but the holistic shape is human-judged. | Compare `42-VERIFICATION.md` against `.planning/phases/39-inbound-package-foundation/39-VERIFICATION.md` and `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md`. Reject any wording that describes Phase 42 behavior in future tense or as a planning fact. |
| Closeout artifact records the actual audit re-run result rather than a paraphrase | (closeout) | Audit truth is forensic — the artifact must capture the genuine output of the re-run, not a summary of expected outcomes. | Confirm the re-run command was actually executed against the repaired evidence chain and that the output (or a faithful summary including `status` and any surfaced gaps) is present in `v1.1-MILESTONE-AUDIT-CLOSEOUT.md`. |
| `42-VERIFICATION.md` does not promote internal Oban worker / queue / retry / replay machinery to public surface | EXEC-01 / EXEC-02 (per D-44-08) | Surface promises are subjective in tone even when the docs-contract test asserts the negatives. | Confirm the report language matches `mailglass_inbound/docs/api_stability.md` (`internal` surfaces stay `internal`); re-run `mix test test/mailglass_inbound/docs_contract_test.exs` to mechanically verify no `%Oban.Job{}` or `"stable public replay API"` strings leaked into shipped docs. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — N/A this phase)
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter once plans are accepted by the plan-checker

**Approval:** pending
