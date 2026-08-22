---
phase: 162
slug: protected-release-and-scheduled-control-recovery
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
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
| 162-01-01 | 01 | 1 | AUTO-01 | T-162-01 | Evidence rows require capture time, source, immutable identity, observation, and one disposition. | contract | `mix test test/scripts/phase_162_release_reconciliation_test.exs` | ✅ | ✅ green |
| 162-01-02 | 01 | 1 | AUTO-02 | T-162-02 | PR/branch/check rows cannot be left auto-merge-armed or without merge/retire/retain outcome; validation remains incomplete. | contract | `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_policy_test.exs test/scripts/release_policy_contract_test.exs` | ✅ | ✅ green |
| 162-02-01 | 02 | 2 | AUTO-03 | T-162-05 | Push, schedule, and digest-free dispatch remain proposal-only; every spec-less probe has an explicit status and only protected exact-digest dispatch has merge/tag/release authority. | workflow contract | `mix test test/scripts/release_trigger_recovery_test.exs test/scripts/release_policy_contract_test.exs` | ✅ | ✅ green |
| 162-03-01 | 03 | 2 | AUTO-04 | T-162-09 | Aggregate JSON, text, and exit policy distinguish `pass`, `blocked`, and `cannot-check`. | unit contract | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` | ✅ | ✅ green |
| 162-03-02 | 03 | 2 | AUTO-04 | T-162-10 | Workflow artifact and summary derive from the same Mix task result without independent verdict computation. | workflow contract | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` | ✅ | ✅ green |
| 162-04-01 | 04 | 2 | AUTO-05 | T-162-16 | Scheduled authorized/not-started emits top-level `blocked`; completed/dispatch recovery retains exact versions, all-tags-one-SHA, and content-digest checks without `main` fallback. | workflow/script contract | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/verify_published_release_test.exs` | ✅ | ✅ green |
| 162-05-01 | 05 | 3 | AUTO-01..05 | All Plan 01-04 contract cases exist and pass before the completion gate flips; live evidence refresh remains read-only. | completion gate + live evidence audit | `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs` | ✅ | ✅ green |
| 162-05-02 | 05 | 3 | AUTO-01..05 | Separate control/scheduled rows preserve real provenance; every probe is present and unavailable/unelapsed proof is explicit. | contract + live evidence audit | `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs` | ❌ Plan 05 expands | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements and Ownership

Plan 01 owns only the reconciliation-artifact contract in Wave 1. Plans 02–04 retain
their separately listed missing control cases, and only Plan 05 Task 1 may set
`wave_0_complete: true` after all four focused contracts exist and pass.

- [x] Plan 01 / Wave 1: reconciliation artifact contract covers source, capture time, immutable identity, observation, and exactly one outcome/recovery condition.
- [x] Plan 02 / Wave 2: release-trigger contract covers capture mismatch, unavailable/pending probes, exhaustive coverage, and proposal-only authority.
- [x] Plan 03 / Wave 2: repo-hygiene contract covers `cannot-check`, `blocked`, JSON, text, and fail-closed exits.
- [x] Plan 04 / Wave 2: post-publish contract covers scheduled `authorized`/`publication: not_started` blocking and no `main` substitution.
- [x] Plan 05 Task 1 / Wave 3: focused completion contracts passed before `wave_0_complete: true` was set; actual execution waves remain 01=1, 02-04=2, 05=3.

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
