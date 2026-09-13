---
phase: "165"
slug: "reconcile-terminal-proof-and-milestone-archive-ordering"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-13"
---

# Phase 165 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit under Mix/Elixir 1.19.5, using disposable Git repositories and subprocess assertions |
| **Config file** | `mix.exs`; `test/test_helper.exs` |
| **Quick run command** | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` |
| **Full suite command** | `mix verify.ci_lane_contract` |
| **Estimated runtime** | ~90 seconds quick; repository lane timing observed during execution |

---

## Sampling Rate

- **After every task commit:** Run the focused Phase 165 test file and syntax checks for changed Node/shell sources.
- **After every plan wave:** Run `mix verify.ci_lane_contract`.
- **Before `$gsd-verify-work`:** The full required repository lane, installed readiness proof, validation reconciliation, and ordinary verification must be green.
- **Max feedback latency:** 120 seconds for repository-local sampling; controlled-host and terminal gates are separate authorities.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 165-01-01 | 01 | 1 | D-06–D-09 | T-165-01 | Metadata changes are minimal, truthful, and audit-recognized | semantic contract | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` | ❌ W0 | ⬜ pending |
| 165-01-02 | 01 | 1 | D-02–D-05 | T-165-02 | Separate v2.7 authority authenticates archived paths and leaves Phase 164 bytes unchanged | unit/integration | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` | ❌ W0 | ⬜ pending |
| 165-02-01 | 02 | 2 | D-12/D-15 | T-165-03 | Stale audit, incomplete archive, dirty or moving HEAD, selected/rerun CI, non-natural schedules, and output leakage all fail closed | negative integration | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` | ❌ W0 | ⬜ pending |
| 165-02-02 | 02 | 2 | D-03/D-16 | T-165-04 | Installed bytes match an approved tuple and readiness proof cannot dispatch terminal capture | controlled-host | `mix verify.phase_165.installed_boundary` | ❌ W0 | ⬜ pending |
| 165-03-01 | 03 | 3 | D-13 | T-165-05 | Canonical audit has exact required scores and all five phases validation-compliant | audit contract | `test -s .planning/v2.7-MILESTONE-AUDIT.md && rg -q 'strict requirements.*16/16' .planning/v2.7-MILESTONE-AUDIT.md` | ❌ W0 | ⬜ pending |
| 165-03-02 | 03 | 3 | D-14/D-17 | T-165-06 | Archive preview is non-null, includes exactly 161–165, excludes quick tasks, and performs no unauthorized remote action | lifecycle integration | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs milestone complete v2.7 --dry-run` | ✅ | ⬜ pending |
| 165-04-01 | 04 | 4 | D-14/D-15 | T-165-07 | Archived layout and machine state agree before exact-SHA remote evidence is accepted | post-archive contract | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` | ❌ W0 | ⬜ pending |

*Task identifiers are provisional until the planner finalizes plan boundaries; the decision coverage and commands are binding.*

---

## Wave 0 Requirements

- [ ] `test/scripts/phase_165_milestone_finalizer_test.exs` — archived-layout fixtures and all D-12 negative cases.
- [ ] Phase 165 controlled-host exclusion and `mix verify.phase_165.installed_boundary` alias — keeps external state outside repository-only CI.
- [ ] Disposable canonical-audit/archive fixtures — exact five phases, stale audit, missing archive member, tracked-output leakage, and final state agreement.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Exact installed-authority approval tuple | D-16 | External installation changes require fresh operator authority over final bytes | Present source OID, SHA-256, destination, mode, predecessor disposition, runtime closure, and rollback; proceed only after explicit approval. |
| Irreversible milestone archive | D-14/D-16 | `--confirm` moves canonical planning artifacts and rewrites lifecycle state | Present the verified dry-run with non-null audit, exactly phases 161–165, and no quick tasks; proceed only after explicit confirmation. |
| Terminal protected evidence | D-04/D-15 | Exact attempt-one CI and natural schedules exist only after final protected-main integration | At clean `HEAD == origin/main`, derive rather than select the exact remote evidence, run the installed v2.7 finalizer once, verify ignored-only output, then make no later v2.7 write. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency under 120 seconds for repository-local checks
- [ ] Controlled-host and terminal commands remain outside the required repository lane
- [ ] `nyquist_compliant: true` set in frontmatter after observed execution evidence

**Approval:** pending
