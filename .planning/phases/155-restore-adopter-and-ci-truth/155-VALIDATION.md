---
phase: 155
slug: restore-adopter-and-ci-truth
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-16
---

# Phase 155 — Validation Strategy

> Nyquist contract for migration generation, fail-closed metadata/repair, real generated-host execution, and protected aggregate truth.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, shell integration scripts, Ecto/PostgreSQL |
| **Config files** | `test/test_helper.exs`; `mailglass_inbound/test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/mailglass_gen_migration_test.exs test/scripts/ci_green_policy_test.exs --warnings-as-errors` |
| **Core migration command** | `mix test test/mailglass/migration_test.exs test/mix/tasks/mailglass_legacy_repair_test.exs --warnings-as-errors` |
| **Inbound migration command** | `cd mailglass_inbound && mix test test/mix/tasks/mailglass_inbound_gen_migration_test.exs test/mailglass_inbound/migrations_test.exs --warnings-as-errors` |
| **CI contract command** | `mix test test/scripts/generated_ecto_host_proof_test.exs test/scripts/ci_green_policy_test.exs test/scripts/required_checks_test.exs test/scripts/lane_classification_drift_test.exs --warnings-as-errors` |
| **Real host command** | `MAILGLASS_PATH="$PWD" bash scripts/generated_ecto_host_proof.sh` with `DATABASE_URL` pointing at PostgreSQL |
| **Full package suites** | `mix test --warnings-as-errors` and `cd mailglass_inbound && mix test --warnings-as-errors` |
| **Expected feedback** | Focused ExUnit commands under 60s; real generated-host proof is the bounded integration exception and runs in the existing 20-minute CI job |

## Sampling Rate

- **After every task commit:** run that task's focused automated command from the map below.
- **After Waves 1–4:** run both package-focused migration commands; Postgres-backed tasks require a reachable test database.
- **After Wave 5:** run the generated-host contract and the real host script against PostgreSQL.
- **After Wave 6:** run the complete CI contract command.
- **Before phase verification:** run both full package suites, the CI contract command, and the real generated-host proof.
- **Maximum ordinary feedback latency:** 60 seconds; the stock-host creation path is deliberately sampled once at Wave 5 and at the phase gate.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threats | Behavior under proof | Test type | Automated command | Wave-0 prerequisite |
|---------|------|------|--------------|---------|----------------------|-----------|-------------------|---------------------|
| 155-01-01 | 01 | 1 | ADOPT-01, ADOPT-02 | T-155-01..03 | Fresh core/inbound wrappers, explicit/one-repo selection, no atom creation, byte-stable rerun | unit / Mix task | `mix test test/mix/tasks/mailglass_gen_migration_test.exs --warnings-as-errors && (cd mailglass_inbound && mix test test/mix/tasks/mailglass_inbound_gen_migration_test.exs --warnings-as-errors)` | Create both Mix-task test files first |
| 155-01-02 | 01 | 1 | ADOPT-03, ADOPT-04 | T-155-02 | Offline upgrade writes a new rollback-aware file; invalid combinations and `--from 0` write nothing | unit / Mix task | same focused core + inbound Mix-task command | Same two test files; failing cases precede implementation |
| 155-02-01 | 02 | 2 | ADOPT-06 | T-155-04..06 | Core returns zero only for absent anchor and raises typed failures otherwise | unit + Postgres integration | `mix test test/mailglass/migration_test.exs --warnings-as-errors` | Existing file extended with injected-result fixtures before runner changes |
| 155-02-02 | 02 | 2 | ADOPT-06 | T-155-04..06 | Inbound mirrors truth while retaining its independent anchor | unit + Postgres integration | `cd mailglass_inbound && mix test test/mailglass_inbound/migrations_test.exs --warnings-as-errors` | Existing file extended before runner changes |
| 155-03-01 | 03 | 3 | ADOPT-03, ADOPT-06 | T-155-07..09 | Selected core repo is authoritative over conflicting app config for startup, adapter, and query | unit + repo-spy integration | `mix test test/mix/tasks/mailglass_gen_migration_test.exs --warnings-as-errors` | Wave-0 task test from 155-01 gains two-repo adapter/query spies first |
| 155-03-02 | 03 | 3 | ADOPT-03, ADOPT-04, ADOPT-06 | T-155-07..09 | Selected inbound repo is authoritative; current-version-1 range refuses upgrades honestly | unit + repo-spy integration | `cd mailglass_inbound && mix test test/mix/tasks/mailglass_inbound_gen_migration_test.exs --warnings-as-errors` | Wave-0 inbound task test gains conflicting-config repo fixture first |
| 155-04-01 | 04 | 4 | ADOPT-05 | T-155-10..12 | Exact empty historical toy repairs up and rolls back to exact toy state | Postgres integration | `mix test test/mix/tasks/mailglass_legacy_repair_test.exs --warnings-as-errors` | Create test with literal pre-Phase-155 generator bytes and scratch schema first |
| 155-04-02 | 04 | 4 | ADOPT-05, ADOPT-06 | T-155-10..12 | Every byte/catalog/population/query ambiguity preserves source and sentinel data | hostile Postgres matrix | same legacy-repair command plus `mix format --check-formatted` | Negative fixture matrix exists before repair implementation |
| 155-05-01 | 05 | 5 | ADOPT-01..06 | T-155-13..15 | Stock Ecto host configures both packages to Host.Repo, generates/migrates/persists/rolls back through Host.Repo | source contract + real E2E | `mix test test/scripts/generated_ecto_host_proof_test.exs --warnings-as-errors && MAILGLASS_PATH="$PWD" bash scripts/generated_ecto_host_proof.sh` | Create script contract first; PostgreSQL and `DATABASE_URL` required for E2E |
| 155-05-02 | 05 | 5 | ADOPT-01 | T-155-13..15 | Existing Installer Host Smoke identity invokes both no-Ecto and Ecto proofs | YAML meta-test | `mix test test/scripts/generated_ecto_host_proof_test.exs test/scripts/required_checks_test.exs --warnings-as-errors` | Generated-host contract file from prior task |
| 155-06-01 | 06 | 6 | QUAL-02 | T-155-16..18 | Detector failure, invalid code output, or any skipped/non-success code leaf fails | shell policy unit | `mix test test/scripts/ci_green_policy_test.exs --warnings-as-errors` | Create policy test before shell/workflow changes |
| 155-06-02 | 06 | 6 | QUAL-02 | T-155-16..18 | Successful docs-only classification permits skips; structural changes need and leaf set remain exact | shell + YAML mutation meta-test | `mix test test/scripts/ci_green_policy_test.exs test/scripts/required_checks_test.exs test/scripts/lane_classification_drift_test.exs --warnings-as-errors` | Policy test and required-check mutation fixtures exist first |
| 155-07-01 | 07 | 7 | ADOPT-01 | T-155-19..21 | Core-first and inbound-first shared-schema rollback removes only package objects; sibling/host objects survive; the final empty package-managed schema may drop | isolated Postgres integration | `cd mailglass_inbound && mix test test/mailglass_inbound/migrations_test.exs --warnings-as-errors` | Extend the inbound migration suite with both rollback orders and host-sentinel assertions before changing either runner |
| 155-07-02 | 07 | 7 | ADOPT-01 | T-155-22 | Two fresh generated Host.Repo journeys make inbound-first and core-first rollback load-bearing: each preserves the sibling/schema after rollback one and removes package relations plus the empty schema after rollback two | source contract + two real E2E journeys | `mix test test/scripts/generated_ecto_host_proof_test.exs --warnings-as-errors && MAILGLASS_PATH="$PWD" bash scripts/generated_ecto_host_proof.sh` | Strengthen the generated-host source contract with both journey calls, opposing generation orders, and both intermediate/final assertion sets before changing the script |

## Wave 0 Requirements

- [ ] `test/mix/tasks/mailglass_gen_migration_test.exs` — core fresh/offline/live/repo-authority task matrix.
- [ ] `mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs` — inbound parity and conflicting-config repo fixture.
- [ ] Injected catalog-result seams in existing core/inbound migration tests — absent, malformed, impossible, and query-error classifications.
- [ ] `test/mix/tasks/mailglass_legacy_repair_test.exs` — exact historical bytes, real Postgres success, and destructive negative controls.
- [ ] `test/scripts/generated_ecto_host_proof_test.exs` — anti-vacuity source/mutation contract including both package repo config entries and Host.Repo migrate/rollback.
- [ ] `test/scripts/ci_green_policy_test.exs` — detector/code/docs decision-table tests.
- [ ] `mailglass_inbound/test/mailglass_inbound/migrations_test.exs` — isolated shared-schema core-first/inbound-first rollback and host-object preservation matrix.
- [ ] `test/scripts/generated_ecto_host_proof_test.exs` — mutation-backed anchors for two isolated real-host journeys, opposing generation/rollback orders, both sibling-survival states, and both final empty-schema removals.

Wave 0 is performed test-first inside the corresponding tracer task; no production implementation may precede its listed failing proof.

## Resolved Research Questions

| Question | Binding resolution | Validation |
|----------|--------------------|------------|
| Is `--upgrade --from 0` valid? | No. Zero denotes a genuinely absent anchor; reject with guidance to run initial generation without `--upgrade`, and write no file. | Core/inbound Mix-task negative cases in 155-01 and preserved through 155-03/04. |
| Which legacy toy variants are repairable? | Only the exact byte-for-byte output of the current pre-Phase-155 core generator, including old app-derived module, whitespace/newlines, `change/0`, and body. Every variant is ambiguous and fails closed. | Literal fixture plus one-byte/module/catalog/population mutation matrix in 155-04. |

## Manual-Only Verifications

All scoped behaviors have automated verification. The remote `Installer Host Smoke` run is corroborating CI evidence, not a substitute for the locally runnable generated-host script.

## Validation Sign-Off

- [x] Every implementation task has a concrete automated command.
- [x] Every new test file is named in Wave 0 and created before its production change.
- [x] Selected-repo authority has explicit conflicting-configuration tests for both façades.
- [x] The real host contract pins both package repo config entries and Host.Repo migrate/rollback.
- [x] Both RESEARCH open questions have binding resolutions and negative coverage.
- [x] No watch-mode or error-suppressing verification command is used.
- [x] No admin/operator UI surface appears in the task map.
- [x] `nyquist_compliant: true` is set.

**Approval:** ready for Wave-0-first execution.
