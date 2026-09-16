---
phase: 164-repository-truth-reconciliation-and-closeout
fixed_at: 2026-09-01T14:59:00Z
review_path: .planning/phases/164-repository-truth-reconciliation-and-closeout/164-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 164: Code Review Fix Report

**Fixed at:** 2026-09-01T14:59:00Z
**Source review:** `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-03: Ambient scheduled-control registry can relax canonical freshness policy

**Files modified:** `scripts/finalize_phase_164.sh`, `test/scripts/phase_164_closeout_test.exs`
**Commit:** fe20b570
**Applied fix:** The finalizer now invokes the closeout composer with `GH_HOST`, `GITHUB_REPOSITORY`, and `SCHEDULED_CONTROL_CONFIG` pinned to canonical authorities. Its independent raw-source predicate loads canonical workflow names and per-control maximum ages from the canonical registry, validates those ages as positive numbers, parses every run timestamp, and rejects evidence older than the corresponding canonical limit. The adversarial regression supplies an ambient copied registry with one-year freshness limits while presenting a four-hour-old hourly control; the finalizer still rejects it under the canonical three-hour policy.
**Status:** fixed: requires human verification — this changes the final authority predicate; focused and integrated regressions prove the reported registry-inflation path is closed.
**RED:** `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs:429` — exit 2; 1 test, 1 failure because the stale sweep returned status 0 despite the inflated ambient registry.
**GREEN:** The same focused command after the production change — exit 0; 1 test, 0 failures. `bash -n scripts/finalize_phase_164.sh` also exited 0.

### CR-05: Subject-bound ledger semantics exclude every ignore-rule disposition

**Files modified:** `scripts/validate_repository_truth.exs`, `test/scripts/phase_164_repository_truth_test.exs`
**Commit:** 4b0edbf0
**Applied fix:** Added a canonical subject-to-stable-ID map for all 71 ignore rules and a canonical semantic profile binding kind, producer, state, authority, reproducibility, currentness, durable consumer, evidence, and disposition. Exceptional GSD lifecycle and extension rules have explicit overrides; ordinary and fixture ignore relationships remain deterministic from their canonical subject. Unknown ignore subjects and every unmapped non-ignore subject now fail closed. Regressions cover a whitelisted producer transplant, an ignore stable-ID swap, and an otherwise valid unmapped non-ignore row.
**Status:** fixed: requires human verification — this changes semantic authority logic; all canonical ledger rows and the adversarial cases pass, but maintainers remain the ultimate authority for the subject mapping.
**RED:** `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs:153 test/scripts/phase_164_repository_truth_test.exs:163 test/scripts/phase_164_repository_truth_test.exs:176` — exit 2; 3 tests, 3 failures. The producer transplant and stable-ID swap both returned `:ok`, and the unmapped non-ignore row parsed successfully.
**GREEN:** The same focused command after the production change — exit 0; 3 tests, 0 failures. The complete repository-truth file then passed 13 tests, 0 failures, and the canonical ledger CLI returned `repository truth ledger: valid`.

## Integrated Verification

Verification ran in the **main checkout** because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs test/scripts/phase_164_repository_truth_test.exs test/scripts/scheduled_control_evidence_test.exs` passed 38 tests, 0 failures.
- `bash -n scripts/finalize_phase_164.sh scripts/closeout_repository_truth.sh scripts/scheduled_control_evidence.sh` exited 0.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` returned `repository truth ledger: valid`.
- `mix format --check-formatted` passed for the changed Elixir source and test, and `git diff --check` exited 0.
- No push, merge, workflow dispatch/rerun, or modifications to local `main` or the preserved WIP checkpoint branch were performed.
- Verification location: main checkout on `gsd/phase-164-security-gap-closure`.

---

_Fixed: 2026-09-01T14:59:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
