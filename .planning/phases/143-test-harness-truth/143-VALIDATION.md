---
phase: 143
slug: test-harness-truth
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-29
---

# Phase 143 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `143-RESEARCH.md` § Validation Architecture (lines 1215-1279). Do not re-derive — amend here.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 per `.tool-versions`; 1.19.5 on the next-toolchain legs) |
| **Config file** | `test/test_helper.exs` (`ExUnit.start()` at `:1`; conditional `ExUnit.configure(exclude: [:public_only])` at `:54`) |
| **Quick run command** | `mix test test/scripts/ --warnings-as-errors` (the `verify.ci_lane_contract` alias, `mix.exs:296-298`) |
| **Full suite command** | `mix test --warnings-as-errors --exclude requires_workspace` |
| **Lint gate** | `mix credo --strict` (`.credo.exs`, `requires: ["./credo_checks/*.ex"]` at `:180`) |
| **Estimated runtime** | ~5 s quick / ~480 s full suite per leg (observed `Finished in 478.3 seconds`) |

---

## Sampling Rate

- **After every task commit:** `mix test test/scripts/ --warnings-as-errors` + `mix credo --strict` (seconds).
- **After every plan wave:** `mix test --warnings-as-errors --exclude requires_workspace` locally on the
  `public` axis, then `MAILGLASS_SCHEMA=mailglass` on the `mailglass` axis.
- **Wave 2 → Wave 3 boundary:** floors may only be pinned from **green CI runs**, never locally (D-27).
- **Wave 3 → Wave 4 boundary:** D-28's five-condition blocking checkpoint, pasted into the phase artifact.
- **Before `/gsd-verify-work`:** full suite green on all four legs + `mix verify.ci_lane_contract` +
  `mix credo --strict`.
- **Max feedback latency:** 5 s (quick lane) / 480 s (full-suite lane).

---

## Per-Task Verification Map

> Requirement → behavior → automated command. Task IDs are bound by the planner; the behavior rows below
> are the contract each task must satisfy.

| Req | Behavior | Test type | Automated Command | File Exists |
|---|---|---|---|---|
| HARNESS-01 | The mechanism account is written and cites the confirming run | doc contract | `mix test test/scripts/ --warnings-as-errors` | ❌ W1 |
| HARNESS-01 | A leaked shared owner produces `:already_shared` on the next `start_owner!(shared: true)`; `shared: false` survives; `stop_owner`/`mode(:auto)` heal | unit (mechanism regression, D-04) | `mix test test/mailglass/test_support/sandbox_ownership_test.exs` | ❌ W2 |
| HARNESS-01 | `checkout!/1` registers release before any statement that can raise | unit | `mix test test/mailglass/test_support/sandbox_ownership_test.exs --only release_first` | ❌ W2 |
| HARNESS-01 | The four S2 no-ops are deleted; `set_mailglass_global/0` semantics unchanged | unit + grep tripwire | `mix test test/mailglass/mailer_case_test.exs` + `mix credo --strict` | ⚠️ file exists; add assertions |
| HARNESS-01 | Raw `Sandbox.*` under `test/` outside the sanctioned helper fails lint | Credo | `mix credo --strict` | ❌ W2 |
| HARNESS-01 | Class A: baseline tables present at every `async: false` module boundary | formatter probe (suite-level) | full suite with `MAILGLASS_SUITE_FLOOR=1` | ❌ W2 |
| HARNESS-01 | Class B: `Config.schema()` equals its boot value at every `async: false` module boundary | formatter probe (suite-level) | full suite with `MAILGLASS_SUITE_FLOOR=1` | ❌ W2 |
| HARNESS-02 | All four legs green | CI (integration) | `advisory-matrix.yml` — three consecutive completed runs across three distinct `main` SHAs, ≥1 `schedule`, ≥1 `workflow_dispatch` on a tag-shaped ref (D-28) | ✅ lane exists, currently red |
| HARNESS-02 | Green is not seed-luck | CI (repeat) | the three runs above use random seeds (no `--seed` in the lane) — that *is* the seed variation | ✅ |
| HARNESS-03 | `violations/1` fires when executed count drops | unit (negative control) | `mix test test/scripts/suite_floor_contract_test.exs` | ❌ W3 |
| HARNESS-03 | `violations/1` fires on an unknown `--exclude` tag, in both directions | unit | same file | ❌ W3 |
| HARNESS-03 | The signature classifier returns `:already_shared` for the **verbatim captured failure term** | unit | same file | ❌ W3 — highest-value single test in the phase |
| HARNESS-03 | The classifier also counts the composed guard error (laundering guard) | unit | same file | ❌ W3 |
| HARNESS-03 | The lane catches a deliberately-injected regression | CI probe | `gh workflow run gate-self-test.yml -f check_name='Core Full Suite (' -f required_only=false` → expect `result=blocked` | ⚠️ workflow exists; needs 2 inputs + never-appeared outcome |
| HARNESS-03 | The existing probe is vacuous against `CI Green` (D-18a) | CI probe, one-shot | `gh workflow run gate-self-test.yml` (defaults) → expect `result=leaked` | ✅ runnable today |
| HARNESS-04 | Registry ↔ YAML ↔ `MAINTAINING.md` agree on the 7 advisory-matrix lanes | drift meta-test | `mix test test/scripts/lane_classification_drift_test.exs` | ⚠️ file exists; add assertions |
| HARNESS-04 | `expanded_matrix_job_names/1` is non-vacuous | unit + negative control | same file | ❌ W3 |
| HARNESS-04 | The 24-row `ci.yml` counts are unchanged | drift meta-test | same file (`:442-465`) | ✅ exists — must stay green |
| HARNESS-04 | Branch protection still exactly `{CI Green, Guard Release Trigger}` | unit | `mix test test/scripts/required_checks_test.exs` (`:45-58`) | ✅ exists |
| HARNESS-04 | A red gating leg blocks a Hex publish | CI rehearsal (negative) | tag a branch with one deliberately failing core test; `gh workflow run publish-hex.yml -f tag=<tag> -f dry_run=true` → gate fails, `publish-core` never starts | ❌ W4 (D-29) |
| HARNESS-04 | A green gating leg permits the publish path | CI rehearsal (positive) | throwaway tag on `main` created after merge; `-f dry_run=true` → gate passes, `publish-core` skips on the idempotency guard (`publish-hex.yml:394-401`) | ❌ W4 (D-29) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/sandbox_ownership.ex` — the sanctioned ownership door (D-06)
- [ ] `test/support/suite_truth_formatter.ex` — hygiene probe + failure-signature tally (D-08/D-09)
- [ ] `test/support/suite_floor.ex` — floors, tag allowlist, ceilings (D-13/D-15/D-16)
- [ ] `credo_checks/no_raw_sandbox_ownership.ex` — prevention layer (D-08)
- [ ] `test/scripts/suite_floor_contract_test.exs` — negative controls; **auto-collected, no `mix.exs`
      change** (`verify.ci_lane_contract` is a directory glob)
- [ ] `test/mailglass/test_support/sandbox_ownership_test.exs` — mechanism-level regression test (D-04)
- [ ] Two `env: MAILGLASS_SUITE_FLOOR: "1"` additions (`advisory-matrix.yml`, full-suite steps at `:113`, `:216`)
- [ ] `Mailglass.CIYaml.expanded_matrix_job_names/1` + `Mailglass.CILanes` third axis (D-24)
- [ ] `MAINTAINING.md` new `## Advisory Matrix Lanes` section (D-25)

**Framework install: none.** ExUnit, Credo, and the drift-test harness all already exist.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The recorded gating decision itself (prose judgment on whether Core Full Suite should gate a release) | HARNESS-04 | A decision record is a human judgment, not a computable predicate; only its *consequences* (gate wiring, rehearsal outcomes) are automatable | Read the decision record in the phase artifact; confirm it states a verdict, its rationale, and the evidence run IDs it rests on |
| D-28 five-condition promotion checkpoint | HARNESS-02 | Requires reading three real CI runs across three distinct `main` SHAs over wall-clock time | Paste the five conditions and the satisfying run IDs into the phase artifact before Wave 4 starts |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 480s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
