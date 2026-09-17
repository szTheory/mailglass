---
phase: "166"
slug: "earned-greens-and-controls-that-can-pass"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-17"
---

# Phase 166 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `166-RESEARCH.md` § Validation Architecture. The planner fills the
> Per-Task Verification Map once PLAN.md task IDs exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (all three packages); ExCoveralls for coverage reporting |
| **Config file** | Per-package `test/test_helper.exs` — no central config file |
| **Quick run command** | `cd mailglass_admin && MIX_ENV=test mix test --warnings-as-errors test/` |
| **Full suite command** | `mix ci` (root) — fans out to `verify.support_contract.{core,admin,inbound}` |
| **Estimated runtime** | ~4s (admin widened suite, measured); `mix ci` several minutes |

**Toolchain precondition:** tracked `.tool-versions` pins versions not installed locally.
Export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` before any bare `mix`,
or it fails with a misleading `corrupt atom table`. Do not "fix" the tracked file — it is the
correct CI contract.

---

## Sampling Rate

- **After every task commit:** the targeted `mix test <file>` for the file(s) touched.
- **After every plan wave:** `mix ci` fan-out (already required by every PR in this repo).
- **Before `/gsd-verify-work`:** full suite green.
- **Max feedback latency:** ~10 seconds for targeted runs.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| *(filled by planner)* | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `config/coverage_baselines/admin.json` — does not exist; must be generated from a green run
      of the **widened** 510-test suite in the same change that widens it (D-06), never before.
- [ ] `@ci_yml_suite_floor_occurrences` + its anti-vacuity and negative-control test trio in
      `test/scripts/lane_classification_drift_test.exs` (D-08) — net-new, mirrors the existing
      `advisory-matrix.yml` trio (~50 lines).
- [ ] New cases in `test/mix/tasks/mailglass.repo.hygiene_test.exs` for the CTRL-05 predicate
      (open >14d or failing a required check) — D-35.
- [ ] GREEN-05 has no runnable test: the committed isolation note **is** the artifact
      (`actions/cache` internals are not Elixir-testable).

---

## Manual-Only Verifications

These are inherently post-merge or dispatch-only. They are tracked as **pending post-merge
evidence**, never silently assumed passing — each needs an explicit checklist item in the plan,
distinct from the PR's own merge gates.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `workflow_dispatch` of the schedule path exits 0 against an `inactive` ledger and uploads `post-publish-resolution.json` | CTRL-01 | Needs the workflow present on `main`; cannot be dispatched pre-merge | After merge: `gh workflow run post-publish-smoke.yml` with the new mode input; assert exit 0 and the uploaded artifact |
| No redundant `release-please` re-run against an already-tagged SHA | CTRL-02 | Requires a real `chore: release main` merge | Observe the next release PR merge's `release-please` run |
| Three consecutive pushes to `main` green, `push` and `schedule` agreeing at the same SHA | CTRL-03 | Inherently a 3-push observation | PR-5 and Phase 167's PRs supply the three observations; record each run URL |
| Two consecutive scheduled `repo-hygiene` runs conclude `success` with `status: pass`, with a freshly opened healthy PR open | CTRL-05 | Requires two real cron firings | Record both run URLs plus the open PR number |
| Cache-restore behavior across trust lanes (part 2 of the GREEN-05 proof) | GREEN-05 | Needs a real CI run to observe `actions/cache` restore | CI step listing `reference/host_app/deps` before `deps.get` |
| `faketime '2026-12-01 00:00:00' mix mailglass.audit --kind hex` | CTRL-04 | `faketime`'s interception of BEAM clock reads is unverified (RESEARCH Open Question 1) | Try `faketime`; if BEAM ignores `LD_PRELOAD`, fall back to the documented date-boundary unit test plus a real-date audit run |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s for targeted runs
- [ ] Every ❌/⚠️ row above has a matching post-merge verification checklist item in a PLAN.md
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
