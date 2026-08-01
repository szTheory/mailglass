---
phase: 143
slug: test-harness-truth
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-29
validated: 2026-07-31
---

# Phase 143 — Validation Strategy

> Retroactive Nyquist audit of the executed phase. The original pre-execution
> contract has been reconciled with all 14 plans, their summaries, the shipped
> tests, and the Phase 143 verification evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 / OTP 27 on the gating toolchain; Elixir 1.19 / OTP 28 on next-toolchain CI legs) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scripts/ --warnings-as-errors` |
| **Focused phase command** | `mix test test/scripts/mechanism_account_contract_test.exs test/scripts/suite_floor_contract_test.exs test/scripts/lane_classification_drift_test.exs test/scripts/required_checks_test.exs test/mailglass/test_support/sandbox_ownership_test.exs test/mailglass/test_support/suite_truth_formatter_test.exs test/mailglass/mailer_case_test.exs test/mailglass/credo/no_raw_sandbox_ownership_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors --exclude requires_workspace` |
| **Pinned runner** | `make toolchain CMD='<command>'` |
| **Lint gate** | `mix credo --strict` plus `actionlint` for workflow changes |

The host checkout currently stops before ExUnit because its local Ecto dependency
has a lock mismatch. The pinned toolchain is the authoritative local path and ran
the focused phase command on 2026-07-31: **189 tests, 0 failures**, with
`already_shared=0`, `formatter_violations=0`, and zero `SuiteFloor` violations.

## Sampling Rate

- After test-support or policy changes: run the focused affected ExUnit file.
- After script-contract or workflow changes: run `mix test test/scripts/ --warnings-as-errors` and `actionlint` on changed workflows.
- At plan-wave boundaries: run the full root suite on both schema axes.
- Before promotion or release-gate changes: require real Actions evidence; never infer a green matrix from local results.
- Before phase verification: require all four Core Full Suite legs plus the deliberate-failure and publish-block rehearsals.

## Requirement Coverage

| Requirement | Automated coverage | Current status |
|-------------|--------------------|----------------|
| **HARNESS-01** | `sandbox_ownership_test.exs`, `suite_truth_formatter_test.exs`, `mailer_case_test.exs`, `no_raw_sandbox_ownership_test.exs`, and `mechanism_account_contract_test.exs` cover the mechanism, release-first ownership, class A/B/C observation, sanctioned call sites, and recurrence guard. | **COVERED** — focused pinned run green; successful four-leg CI runs exercised the full-suite path. |
| **HARNESS-02** | `advisory-matrix.yml` executes the full suite across Elixir/OTP and schema axes; lane drift tests pin the matrix contract. | **COVERED** — three distinct green `main` SHAs plus successful scheduled and tag-shaped dispatch evidence in `143-VERIFICATION.md`. |
| **HARNESS-03** | `suite_floor_contract_test.exs` covers count loss, exclusion drift, raw and composed `:already_shared` signatures, and fail-closed formatter state; the deliberate regression probe exercises the live lane. | **COVERED** — focused pinned run green; Actions run `30599206217` proves both floor legs fail on an injected regression. |
| **HARNESS-04** | `lane_classification_drift_test.exs`, `required_checks_test.exs`, and `mechanism_account_contract_test.exs` pin lane classification, gate wiring, and the decision record. | **COVERED** — positive release runs passed the gate; rehearsal `30654293410` failed the gate and left `publish-core` skipped. |

## Per-Task Verification Map

| Plan | Wave | Requirements | Verification | Status |
|------|------|--------------|--------------|--------|
| 143-01 | 1 | HARNESS-01 | Formatter unit tests and traced suite observation | COVERED |
| 143-02 | 1 | HARNESS-03 | `actionlint` plus recorded gate-self-test vacuity probe | COVERED |
| 143-03 | 2 | HARNESS-01 | Ledger artifacts and mechanism-account contract | COVERED |
| 143-04 | 3 | HARNESS-01 | Real-repo ownership regression and `release_first` tests | COVERED |
| 143-05 | 4 | HARNESS-01 | Case-template, leak-site, Oban, and mailer regression tests | COVERED |
| 143-06 | 4 | HARNESS-01 | Property, schema-isolation, and migration teardown tests on both schema axes | COVERED |
| 143-07 | 5 | HARNESS-01, HARNESS-02 | Schema/baseline restoration tests and full-suite verification | COVERED |
| 143-08 | 6 | HARNESS-01 | Credo check unit/integration tests and strict whole-tree lint | COVERED |
| 143-09 | 6 | HARNESS-03 | Suite-floor policy, signature classifier, and negative controls | COVERED |
| 143-10 | 7 | HARNESS-02, HARNESS-03 | Green-run threshold evidence, floor contracts, lane drift, and workflow lint | COVERED |
| 143-11 | 8 | HARNESS-04 | Matrix-name expansion negative controls, registry drift, docs contract, and workflow lint | COVERED |
| 143-12 | 9 | HARNESS-02, HARNESS-03 | Deliberate-failure probe and five-condition promotion artifact | COVERED |
| 143-13 | 10 | HARNESS-04 | Publish-workflow lint, lane decision-table tests, and registry drift | COVERED |
| 143-14 | 11 | HARNESS-04 | Decision-record contract plus live positive and negative publish-path rehearsals | COVERED |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Evidence / Instructions |
|----------|-------------|------------|-------------------------|
| Repeated four-leg green across distinct SHAs, schedule, and tag-shaped dispatch | HARNESS-02 | Cross-run, wall-clock Actions evidence cannot be reproduced by a unit test. | Re-check the run IDs and job conclusions recorded in `143-VERIFICATION.md` and `143-PROMOTION-CHECKPOINT.md`. |
| The release-gating verdict and accepted trade-offs | HARNESS-04 | The decision is a maintainer judgment; tests can only pin its recorded consequences. | Review `143-GATING-DECISION.md` for the verdict, rationale, run IDs, and accepted gaps. |
| A red floor leg prevents the publish job from starting | HARNESS-04 | The strongest proof crosses two live workflows and GitHub job dependency semantics. | Re-check rehearsal run `30654293410`: `gate-ci-green` failed and `publish-core` was skipped with zero steps. |

## Validation Audit 2026-07-31

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

No tests were generated: every requirement already had behavior-targeted automated
coverage, and the focused suite ran green on the repository's pinned gating toolchain.

## Validation Sign-Off

- [x] All executable tasks have automated verification; human checkpoints have durable evidence artifacts.
- [x] Sampling continuity has no three-task gap without automated feedback.
- [x] All originally missing Wave 0 references now exist and are exercised.
- [x] No watch-mode flags appear in validation commands.
- [x] Focused feedback latency is under one second after compilation in the pinned runner.
- [x] Every phase requirement is COVERED or explicitly backed by live manual evidence.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** validated — 2026-07-31
