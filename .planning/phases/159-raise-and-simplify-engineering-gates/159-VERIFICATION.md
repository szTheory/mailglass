---
phase: 159-raise-and-simplify-engineering-gates
verified: 2026-08-18
status: passed
score: 10/10 requirements verified
requirements:
  - QUAL-01
  - QUAL-03
  - QUAL-04
  - QUAL-05
  - QUAL-06
  - QUAL-07
  - QUAL-08
  - QUAL-09
  - QUAL-10
  - QUAL-11
---

# Phase 159 Verification

## Verdict

**PASSED.** Maintainers now receive one deterministic, fail-closed `CI Green`
merge signal backed by complete package-scoped engineering proof. The seven plan
success criteria and all ten assigned requirements are evidenced by current
repository contracts and fresh verification on 2026-08-18.

The first verification run correctly failed on a stale governed-source location
(`test/mailglass/webhook/ingest_test.exs:296` versus line 297). Commit
`1c70ad88` repaired the registry, and the complete focused suite was rerun from
the new HEAD. Independent review also found and repaired legacy release-tag
recovery and explicit root-permission validation in `0597e18a`; those negative
controls are included in the final green run below.

## Goal-backward evidence

| Requirement | Status | Evidence |
|---|---|---|
| QUAL-01 | VERIFIED | Root `.formatter.exs` owns inbound scope; formatter-scope mutation test and both package formatter checks pass. |
| QUAL-03 | VERIFIED | `config/quality/ci_policy.exs` and `.github/workflows/ci.yml` enumerate 19 required deterministic results; required-check/evaluator mutations reject missing, skipped, failed, cancelled, renamed, unknown, duplicate, and permissive results. |
| QUAL-04 | VERIFIED | Policy/classification tests keep browser, demo, preview, provider-live, next-toolchain, clean-baseline, branch-protection, and publish-only evidence outside merge inputs. |
| QUAL-05 | VERIFIED | Composite setup requires explicit package directory, lockfile, Mix environment, build path, cache namespace, exact toolchain, and `mix deps.get --check-locked`; wildcard/cross-package identity mutation fails. |
| QUAL-06 | VERIFIED | Measured core/inbound baselines (`63.254221%` and `78.464730%`) are immutable pinned-toolchain evidence; floor tests reject missing reports, wrong toolchains, lower covered/relevant lines, lower percentages, and self-ratcheting. Critical-path contracts remain separately named. |
| QUAL-07 | VERIFIED | Pinned Elixir 1.18.4 / OTP 27.3.4.13 root Dialyzer passes with 16 matched filters and 0 unnecessary filters; inbound Dialyzer passes with 0 errors, 0 skipped, and 0 unnecessary skips. Inbound owns its strict ignore file and PLT. |
| QUAL-08 | VERIFIED | Credo strict checks 541 files with 0 issues; nesting/cyclomatic global disables are absent; the owned, expiring, bidirectional static-analysis ledger passes and rejects growth/dead/expired records. |
| QUAL-09 | VERIFIED | `check_test_exceptions.sh` reports the registry complete and unexpired after the line-location repair; contract mutations cover stale, unregistered, missing-metadata, and expired records, while focused async paths use acknowledgements. |
| QUAL-10 | VERIFIED | Shared setup is versioned outside jobs without renaming checks; release tag/target decisions live in tested scripts, including fail-closed legacy recovery when an extracted script is absent. |
| QUAL-11 | VERIFIED | Workflow contracts require one bounded timeout per job, explicit read/none root permissions, exact job-local writes, immutable Postgres/toolchain images, and Dependabot coverage for all Mix/Actions/Docker roots. |

## Plan success criteria

| Plan | Result | Success-criterion evidence |
|---|---|---|
| 159-01 | PASS | Policy tracer, exact current/target/advisory inventory, and fail-closed negative controls are green before/after promotion. |
| 159-02 | PASS | One formatted baseline and explicit package-scoped locked setup pass scope/cache mutation tests. |
| 159-03 | PASS | Every current skip/flaky/sleep exemption is bidirectionally registered, owned, reasoned, categorized, and unexpired; readiness replacements are deterministic. |
| 159-04 | PASS | Core and inbound floors were measured on the pinned image, not invented, and cannot rewrite themselves during verification. |
| 159-05 | PASS | Inbound shipped code passes Dialyzer with no ignores; root ignores and Credo complexity exceptions are non-growing and expiring. |
| 159-06 | PASS | `CI Green` aggregates all and only deterministic required proof; advisory evidence is negatively asserted absent. Public `CI Green` and existing job display identities remain stable. |
| 159-07 | PASS | Workflow hygiene, immutable Docker/toolchain inputs, least privilege, Dependabot coverage, and extracted release decisions are executable without changing publication semantics. |

## Fresh commands and results

### Focused fail-closed contracts

```text
bash scripts/check_test_exceptions.sh
  OK: test exception registry is complete and unexpired.

mix test test/scripts/{ci_green_policy,required_checks,lane_classification_drift,
  ci_parity_drift,format_scope_contract,setup_action_contract,
  test_exceptions_contract,coverage_floor_contract,static_analysis_contract,
  workflow_hardening_contract,release_policy_contract,
  linked_release_concurrency,release_trigger_recovery}_test.exs --warnings-as-errors
  123 tests, 0 failures
```

The suite contains injected omissions, duplicates, advisory promotions,
wildcard lock identities, stale/expired registry records, lowered coverage,
static-analysis growth, missing permissions/timeouts, mutable images, malformed
release targets, and absent legacy helper scripts. A green result is therefore
non-vacuous.

### Pinned static analysis

Executed in an isolated copy with the immutable
`hexpm/elixir:1.18.4-erlang-27.3.4.13-debian-bookworm-20260623-slim` image at the
committed SHA-256 digest:

```text
root MIX_ENV=test mix dialyzer
  Total errors: 16, Skipped: 16, Unnecessary Skips: 0
  done (passed successfully)

mailglass_inbound MIX_ENV=test mix dialyzer
  Total errors: 0, Skipped: 0, Unnecessary Skips: 0
  done (passed successfully)
```

The 16 root results exactly match its registered maintainer-only filters; no
shipped inbound warning is ignored.

### Formatting, Credo, workflows, and scripts

```text
mix credo --strict
  541 source files, 4719 mods/funs, found no issues

mix run scripts/check_static_analysis_exceptions.exs
  OK: static-analysis exceptions are current, owned, expiring, and non-growing.

mix format --check-formatted
cd mailglass_inbound && mix format --check-formatted
actionlint .github/workflows/*.yml
bash -n scripts/release_policy_expected_tags.sh scripts/release_policy_validate_target.sh
sh -n scripts/assert_gating_toolchain.sh
git diff --check
  all exited 0
```

Credo prints pre-existing module-redefinition warnings while loading custom
checks, but reports zero Credo issues and exits successfully. The optional OTLP
exporter warning also remains informational and does not alter any gate result.

## Scope and safety audit

- No Phase 159 implementation commit changes `mailglass_admin/lib`, admin assets,
  static bundles, router/LiveView code, admin tests, or `mailglass_admin/mix.exs`.
- Package versions remain repository core/admin `2.4.0` and inbound `2.1.1`;
  Phase 159 made no semantic-version selection or publication.
- No `.planning/release-target.json`, Release Please package policy, tags,
  GitHub releases, Hex artifacts, protected-environment behavior, or publication
  targets were changed. Plan 07 only extracted deterministic validation and
  hardened permissions/timeouts/images; legacy recovery is explicitly tested.
- Phase 160 planning artifacts are not consumed by Phase 159 merge inputs and
  received no implementation mutation during verification.
- Advisory/browser/demo/preview/admin-visual/provider-live/next-toolchain/
  clean-baseline/publish-only evidence remains visibly non-merge-gating.

## Residual observations

No phase-blocking gap remains. A developer host running Elixir 1.19/OTP 28 may
hold an incompatible Dialyzer PLT; verification deliberately rebuilt both PLTs
inside the pinned isolated toolchain rather than treating that host cache as
release evidence.

## Final result

**Phase 159 goal achieved.** The engineering gates are comprehensive,
repeatable, package-scoped, measured, and fail closed, while public check
identity, advisory boundaries, independent packages, operator behavior, and
release semantics remain intact.
