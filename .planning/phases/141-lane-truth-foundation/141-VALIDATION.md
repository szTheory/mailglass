---
phase: 141
slug: lane-truth-foundation
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 141 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `141-RESEARCH.md` § Validation Architecture (lines 779-836).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18 / OTP 27, per `.tool-versions`) |
| **Config file** | `test/test_helper.exs` — boots `Mailglass.TestRepo` and runs migrations (**requires Postgres**) |
| **`test_paths`** | not set in `mix.exs` → defaults to `["test"]`, so `test/scripts/` **is** in the default `mix test` run |
| **`elixirc_paths(:test)`** | `["lib", "credo_checks", "test/support", "dev"]` (`mix.exs:114`) |
| **Quick run command** | `MIX_ENV=test mix test test/scripts/ --no-start --warnings-as-errors` |
| **Full suite command** | `mix ci` (requires Postgres + network) |
| **Estimated runtime** | ~5 s quick (17 tests at `dcbd6488`) · ~6-9 min full |

**Blocking precondition (F5):** `mix test test/scripts/ --warnings-as-errors` aborts today on a
provably-dead assertion at `test/scripts/ci_parity_drift_test.exs:159-162`. That assertion must be
removed before the quick-run command is usable as a sampling gate.

**Enforcement gap (F2):** no `ci.yml` lane executes `test/scripts/` today. Every core lane runs a
file- or directory-scoped `verify.*` alias; the only full-suite surface is `advisory-matrix.yml:114`,
which `gate-ci-green` cannot see (`workflow_id: 'ci.yml'`). Until the new `verify.ci_lane_contract`
alias is wired into `mix_task_tests`, criterion 1 is satisfied on paper and enforced nowhere.

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix test test/scripts/ --warnings-as-errors`
- **After every plan wave:** `mix ci.fast` (tasks touching `mix.exs` must keep compile + credo green)
- **Before `/gsd-verify-work`:** full `mix ci` green, **plus** criteria 1b and 2b executed once by a
  human and their observed output recorded in SUMMARY.md
- **Max feedback latency:** ~5 s (quick) / ~90 s (`ci.fast`)

---

## Per-Task Verification Map

*Seeded as draft — task IDs are assigned by the planner. `/gsd-validate-phase` fills and confirms
this table against the final PLAN.md files.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0 | — | — | N/A | unit | `MIX_ENV=test mix test test/scripts/ci_parity_drift_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 1 | TRUTH-07 | — | N/A | unit | `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | TRUTH-09 | — | N/A | unit | `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | TRUTH-05 | — | N/A | unit | `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | 2 | CONFORM-04 | — | N/A | static | `grep -c 'name: Design System Conformance' .github/workflows/ci.yml` | ❌ W0 | ⬜ pending |
| TBD | TBD | 2 | TRUTH-09 | — | N/A | integration | `mix verify.ci_lane_contract` | ❌ W0 | ⬜ pending |
| TBD | TBD | 3 | HIST-01 | — | N/A | static | `test -f .planning/TOOLING-DEFECTS.md && grep -q 'cleared:' .planning/TOOLING-DEFECTS.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Success Criteria → Concrete Checks

| # | Criterion | Runnable check | Runs where |
|---|---|---|---|
| 1 | The three registries agree; a meta-test fails on drift | `mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors` | **CI** (`mix_task_tests` via `verify.ci_lane_contract`) + local `mix ci` |
| 1b | The meta-test genuinely fails on drift (negative control) | Temporarily delete one entry from `publish-hex.yml`'s publish-gating array; assert the test fails; revert. Model on `ci_parity_drift_test.exs:205-221`. | **Human, once** — record the observed failure message in SUMMARY.md |
| 2 | No `ci.yml` job sits unclassified | Meta-test set-equality assertion: `CIYaml.job_names/1` values vs. the union of the three `CILanes` classification buckets | **CI** |
| 2b | The classification set matches *runtime* reality, not just YAML | `gh api repos/szTheory/mailglass/actions/runs/<run>/jobs --jq '.jobs[].name'` on a run where lanes actually executed; every name prefix-matches exactly one array | **Human, once** — the only check that catches F1-class errors, because matrix name suffixes do not exist in the YAML |
| 3 | Two distinguishable job names | `grep -n 'name: Credo Strict\|name: Design System Conformance' .github/workflows/ci.yml` → 2 hits; the two jobs' step lists are disjoint | **CI** (actionlint validates the YAML) + human read |
| 4 | Every lane carries a written disposition | Meta-test assertion: every ledger row's disposition ∈ `{promote, keep-with-reason, retire}`, and row count equals the classified-lane count | **CI** |
| 5 | 132-137 restored; defect recorded | `find .planning/milestones/v2.0-phases -type f \| wc -l` → `48`; `test -f .planning/TOOLING-DEFECTS.md`; `grep -c 'cleared:' .planning/TOOLING-DEFECTS.md` ≥ 1 | **Human, once** (first two already true — see F7) |

---

## Wave 0 Requirements

- [ ] `test/scripts/ci_parity_drift_test.exs:159-162` — remove the dead assertion (**F5**; unblocks
      `--warnings-as-errors`, which every later sampling command depends on)
- [ ] `test/support/ci_yaml.ex` — `job_names/1` + `matrix_job_names/1` helpers
- [ ] `test/scripts/lane_classification_drift_test.exs` — the drift assertions (TRUTH-05/07/09)
- [ ] `mix.exs` — `verify.ci_lane_contract` alias + `preferred_cli_env` entry
- [ ] `.github/workflows/ci.yml` — `mix_task_tests` step invoking the new alias
      (**without this, criterion 1 is unenforced**)

No framework install needed. No new dependency (`.planning/research/v2.2/SUMMARY.md:32` lock honored).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Runtime job names match the classification arrays including matrix suffixes | TRUTH-09 | GitHub appends matrix values to a matrix job's explicit `name:` **at runtime only** (F1). The suffix does not exist in `ci.yml`, so no static parse can prove prefix-match correctness. | On a CI run where the lanes actually executed (not skipped): `gh api repos/szTheory/mailglass/actions/runs/<run>/jobs --jq '.jobs[].name'`. Assert every returned name prefix-matches exactly one entry across the three arrays. |
| The drift meta-test fails when a registry drifts | TRUTH-07 | A meta-test that passes vacuously is this milestone's originating failure mode. Proving it fails requires deliberately introducing drift. | Delete one entry from `publish-hex.yml`'s publish-gating array → run the meta-test → confirm a **named, specific** failure (not a vacuous pass) → revert. Record the message. |
| Live branch protection still lists only `CI Green` + `Guard Release Trigger` | CONFORM-04 | Requires authenticated GitHub API; not reproducible from repo contents. Re-confirms D-10's blast-radius-zero claim after the rename lands. | `gh api repos/szTheory/mailglass/branches/main/protection --jq '.required_status_checks.contexts'` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90 s
- [ ] Criteria 1b and 2b executed once and their output recorded in SUMMARY.md
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
