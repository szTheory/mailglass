---
phase: 162
slug: protected-release-and-scheduled-control-recovery
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-22
---

# Phase 162 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (project Mix test suite) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs test/scripts/release_trigger_recovery_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~180 seconds focused; full suite may take up to 10 minutes |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit files covering the changed task or control; default to `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs test/scripts/release_trigger_recovery_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs`.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full suite must be green and the phase evidence record must cite fresh live captures.
- **Max feedback latency:** 180 seconds for focused automated feedback; live scheduled-run proof is tracked separately and may remain pending until the applicable schedule fires.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 162-01-01 | 01 | 0 | AUTO-01 | T-162-01 | Evidence rows require capture time, source, immutable identity, observation, and one disposition. | contract | `mix test test/scripts/release_policy_test.exs test/scripts/release_policy_contract_test.exs` plus the Phase 162 reconciliation checker/test | ❌ W0 | ⬜ pending |
| 162-01-02 | 01 | 0 | AUTO-02 | T-162-02 | PR/branch/check rows cannot be left auto-merge-armed or without merge/retire/retain outcome. | contract | Phase 162 reconciliation checker/test | ❌ W0 | ⬜ pending |
| 162-02-01 | 02 | 1 | AUTO-03 | T-162-03 | Push, schedule, and digest-free dispatch remain proposal-only; only protected exact-digest dispatch has merge/tag/release authority. | workflow contract | `mix test test/scripts/release_trigger_recovery_test.exs test/scripts/release_policy_contract_test.exs` | ✅ | ⬜ pending |
| 162-03-01 | 03 | 1 | AUTO-04 | T-162-04 | Aggregate JSON, text, exit policy, artifact, and summary distinguish `pass`, `blocked`, and `cannot-check` without recomputing verdicts independently. | unit + workflow contract | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` | ✅ base / ❌ W0 cases | ⬜ pending |
| 162-04-01 | 04 | 1 | AUTO-05 | Scheduled unpublished target emits explicit bounded evidence; completed/dispatch recovery retains exact versions, all-tags-one-SHA, and content-digest checks without `main` fallback. | workflow/script contract | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/verify_published_release_test.exs` | ✅ base / ❌ W0 case | ⬜ pending |
| 162-05-01 | 05 | 2 | AUTO-01..05 | Live evidence refresh records read-only GitHub/Actions/Git/Hex sources and separate control/scheduled run IDs; unavailable sources are `cannot-check`. | live evidence audit | Run the plan-defined Phase 162 evidence checker against the tracked reconciliation record, then inspect cited run events/artifacts | ❌ W0 checker | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add a reconciliation-artifact contract test or deterministic checker for source, capture time, immutable identity, observation, and exactly one outcome/recovery condition.
- [ ] Extend `test/mix/tasks/mailglass.repo.hygiene_test.exs` with separate aggregate `cannot-check`, policy `blocked`, JSON string, text output, and nonzero-exit cases.
- [ ] Extend `test/mailglass/publish/post_publish_smoke_contract_test.exs` with scheduled `authorized`/`publication: not_started` explicit-result coverage and a no-`main`-substitution assertion.
- [ ] Extend `test/scripts/release_trigger_recovery_test.exs` with capture-mismatch reporting that proves proposal-only triggers gain no merge/tag/release authority.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh PR #222, branch/ref, check, tag/release, Hex checksum, and ledger capture | AUTO-01, AUTO-02 | Remote state is time-sensitive and cannot be frozen into a deterministic local test. | Run the plan-defined read-only `gh`, Git, and Hex capture commands; record UTC time, URL/command, exact SHA/version/checksum, and outcome in the append-only reconciliation artifact. Record `cannot-check` for acquisition failure rather than absence. |
| Applicable scheduled release-please, repository-hygiene, and post-publish outcomes | AUTO-03, AUTO-04, AUTO-05 | GitHub's schedule event must actually fire; a dispatch is not equivalent evidence. | Cite observed `event=schedule` run IDs, conclusions, job summaries, and downloaded JSON artifacts. Verify the artifact verdict matches the summary/log and keep missing elapsed-time evidence pending. |
| Protected release disposition remains non-authorizing unless exact candidate dispatch succeeds | AUTO-02, AUTO-03 | Live branch protection, PR checks, and authorization inputs are external control-plane facts. | Confirm ordinary auto-merge is absent; if the exact protected recovery condition is not satisfied, record `retain` or `retire` with reason and do not merge/tag/publish. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Focused feedback latency < 180 seconds
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
