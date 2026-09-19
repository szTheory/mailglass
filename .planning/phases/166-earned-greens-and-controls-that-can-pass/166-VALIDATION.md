---
phase: "166"
slug: "earned-greens-and-controls-that-can-pass"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 166-01 T1 (tracer) | 166-01 | 1 | GREEN-01 | — | widened lane cannot silently run 185 tests | integration | `cd mailglass_admin && MIX_ENV=test mix verify.support_contract.admin` | ✅ | ✅ green |
| 166-01 T1 (parity) | 166-01 | 1 | GREEN-01 | — | alias-name parity unchanged | unit | `mix test test/scripts/ci_parity_drift_test.exs` | ✅ | ✅ green |
| 166-01 T2 | 166-01 | 1 | GREEN-02 | T-166-01, T-166-02, T-166-SC | measured triple + exact toolchain, minimal CI scope | script + unit | `mix coveralls.json … && bash scripts/check_coverage_floor.sh config/coverage_baselines/admin.json …` ; `mix test test/scripts/coverage_floor_contract_test.exs` ; `actionlint .github/workflows/ci.yml` | ✅ | ✅ green |
| 166-01 T3 | 166-01 | 1 | GREEN-02 | T-166-02 | floor demonstrably fires on each ratchet member | regression drill | perturb-and-check loop over covered_lines / relevant_lines / percentage | ✅ | ✅ green |
| 166-02 T1 | 166-02 | 2 | GREEN-03 | T-166-05 | no floor re-pinning to force green | integration | `MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors` | ✅ | ✅ green |
| 166-02 T2 | 166-02 | 2 | GREEN-03 | T-166-04, T-166-06 | env line guarded against silent deletion | unit + lint | `mix test test/scripts/lane_classification_drift_test.exs` ; `actionlint .github/workflows/ci.yml` | ✅ | ✅ green |
| 166-03 T1 | 166-03 | 3 | CTRL-04 | T-166-07 | clock fake scoped to one command, never release machinery | probe | `faketime '2026-12-01 00:00:00' elixir -e 'Date.utc_today()'` | ✅ | ✅ green (substituted real-clock evidence) |
| 166-03 T2 | 166-03 | 3 | CTRL-04 | T-166-08, T-166-09 | expiry machinery intact; data-only lib/ edit | unit | `mix test test/mailglass/supply_chain/accepted_advisories_test.exs` | ✅ | ✅ green |
| 166-03 T3 | 166-03 | 3 | CTRL-04 | T-166-07 | real unmodified audit binary under a faked or real clock | integration | `mix mailglass.audit --kind hex` (faketime-wrapped on the primary branch) | ✅ | ✅ green (real-clock evidence) |
| 166-03 T4 | 166-03 | 3 | CTRL-04 | T-166-08 | exemption named, substituted evidence accepted | human | *(checkpoint — blocking human)* | n/a | ✅ accepted substitution |
| 166-04 T1 | 166-04 | 4 | CTRL-02 | T-166-14 | no new hard-fail reachable on an ordinary push | lint + unit | `actionlint .github/workflows/release-please.yml` ; `mix test test/scripts/release_policy_contract_test.exs test/scripts/release_trigger_recovery_test.exs test/scripts/guard_release_trigger_test.exs test/scripts/linked_release_concurrency_test.exs` | ✅ | ✅ green |
| 166-04 T2 | 166-04 | 4 | CTRL-03 | T-166-11, T-166-12, T-166-13 | bounded retry, no scope creep, cannot-check never passes | lint + structural + unit | `actionlint …` ; YAML assertion that the action step is `continue-on-error` ; `mix test test/scripts/ test/mix/tasks/` | ✅ | ✅ green |
| 166-04 T3 | 166-04 | 4 | CTRL-02, CTRL-03 | T-166-13 | tagged-SHA skip and bounded retry classifications | GitHub seam + lint | `mix test test/scripts/release_policy_contract_test.exs test/scripts/release_trigger_recovery_test.exs --warnings-as-errors` ; `actionlint .github/workflows/release-please.yml` | ✅ | ✅ green |
| 166-05 T1 | 166-05 | 5 | GREEN-04 | T-166-16, T-166-SC | hex build isolated; path-dep build untouched; `--check-locked` kept | integration + lint | isolated `MAILGLASS_DEMO_DEPS=hex mix deps.get --check-locked && mix compile` with before/after deps listing ; `actionlint .github/workflows/ci.yml` | ✅ | ✅ green |
| 166-05 T2 | 166-05 | 5 | GREEN-05 | T-166-17, T-166-19 | cache keys provably distinct; note demonstrates | structural + lint | YAML assertion that the two trust-lane cache keys differ ; note-content greps ; `mix test test/scripts/` | ✅ | ✅ green |
| 166-05 T3 | 166-05 | 5 | GREEN-05 | T-166-19 | distinct cache namespaces, narrow path scope, observation ordering | workflow seam | `mix test test/mailglass/publish/ci_trust_lane_contract_test.exs --warnings-as-errors` ; `actionlint .github/workflows/ci.yml` | ✅ | ✅ green |
| 166-06 T1 | 166-06 | 6 | CTRL-01 | T-166-20, T-166-21 | live-dispatch guards retained; distinct baseline signal | lint + unit + CLI | `actionlint .github/workflows/post-publish-smoke.yml` ; `shellcheck scripts/check_post_publish_target.sh` ; `mix test test/scripts/release_policy_contract_test.exs test/scripts/release_policy_test.exs test/scripts/release_policy_close_out_test.exs test/scripts/scheduled_control_evidence_test.exs test/scripts/workflow_hardening_contract_test.exs` ; `elixir scripts/release_policy.exs baseline-versions .planning/release-target.json` | ✅ | ✅ green |
| 166-06 T2 | 166-06 | 6 | CTRL-05 | T-166-22, T-166-23, T-166-24 | cannot-check stays non-zero; malformed rollup does not crash | unit (TDD) | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` | ✅ | ✅ green |
| 166-06 T3 | 166-06 | 6 | CTRL-01, CTRL-05 | T-166-20 | scheduled evidence and hygiene boundaries | unit + continuous monitor | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors` | ✅ | ✅ green |

*All Phase 166 task rows were reconciled against `166-VERIFICATION.md` on 2026-09-19; every requirement has green executable evidence or an accepted evidence substitution.*

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

## Continuous Operational Evidence

GitHub Actions still produces runtime evidence for release, cache, and cron paths. That evidence is
consumed by read-only monitors and alerts; it is not a manual verification queue. Phase closure relies
on executable seam and integration tests for controllable behavior, so no human must manufacture a
release, force a cache hit, or wait for scheduled runs.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s for targeted runs
- [x] Every requirement has an executable automated verification path
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automation-first verification
