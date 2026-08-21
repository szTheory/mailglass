---
phase: 155-restore-adopter-and-ci-truth
verified: 2026-08-17T03:11:07Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "A generated Ecto host runs the documented core and inbound migration wrappers for both applying and rolling back schema changes."
  gaps_remaining: []
  regressions: []
---

# Phase 155: Restore Adopter and CI Truth Verification Report

**Phase Goal:** Adopters can generate, upgrade, repair, and roll back the real package migrations safely, and code changes cannot claim passing proof when that required path was skipped.
**Verified:** 2026-08-17T03:11:07Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A generated Ecto host runs documented core and inbound wrappers for applying and rolling back schema changes. | ✓ VERIFIED | Fresh dedicated generated hosts passed both `inbound_first` and `core_first` rollback journeys. Each applied façade-only wrappers, inserted/reloaded core and inbound data through `Host.Repo`, preserved the sibling package after the first rollback, then removed all package relations and the empty schema after the second. |
| 2 | An adopter can select a repository explicitly; inference works only for exactly one configured Ecto repo. | ✓ VERIFIED | `MigrationGenerator.resolve_repo!/1` selects only configured repo modules; focused core/inbound task acceptance suites passed. |
| 3 | Upgrade creates a timestamped migration, accepts only valid older offline versions, and rolls back without changing applied migrations. | ✓ VERIFIED | Shared generator validates prior versions, writes exclusively to a new timestamped path, and renders `down(version: prior_version)`; focused task tests passed. |
| 4 | Legacy toy repair fails closed; malformed metadata/query errors remain distinct from an absent anchor. | ✓ VERIFIED | Exact source/catalog/empty-table preflight plus runtime revalidation are wired; catalog readers return `0` only for an absent anchor. Focused legacy and migration tests passed. |
| 5 | A code change cannot receive passing protected proof when change detection fails or a required code lane was skipped. | ✓ VERIFIED | `CI Green` explicitly needs `changes` and sends detector result/output plus every required leaf to the strict policy. Decision-table and mutation tests, shell syntax, and actionlint passed. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/migration_generator.ex` | Shared repo-aware additive migration generator | ✓ VERIFIED | Substantive and wired to both public Mix tasks. |
| Core/inbound Postgres runners | Honest anchor classification and safe package schema lifecycle | ✓ VERIFIED | Public façades dispatch to both runners; new PostgreSQL `DO` guards preserve sibling/host objects under `RESTRICT` and drop only a truly empty schema. |
| `lib/mailglass/migrations/legacy_toy.ex` | Exact fail-closed legacy repair | ✓ VERIFIED | Source, catalog, row-count, and runtime revalidation controls are substantive and tested. |
| `scripts/generated_ecto_host_proof.sh` | Real generated-host proof | ✓ VERIFIED | Two fresh generated Phoenix hosts and derived scratch databases exercised both rollback orders end-to-end. |
| `scripts/ci_green_policy.sh` | Fail-closed protected aggregate policy | ✓ VERIFIED | Directly invoked by `ci_green` with structural detector and required-leaf inputs. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Core/inbound Mix tasks | `Mailglass.MigrationGenerator` | Shared configured-repo contract | ✓ WIRED | Automated key-link checks pass. |
| Generated wrapper | Public migration façades | `up/0` / `down/0` delegation | ✓ WIRED | Fresh generated hosts emitted façade-only wrappers and Ecto executed them. |
| `.github/workflows/ci.yml` | Generated-host proof | `Installer Host Smoke` Postgres step | ✓ WIRED | Workflow source and contract tests retain the public lane identity and command. |
| `.github/workflows/ci.yml` | CI Green policy | Detector + all required leaf results | ✓ WIRED | Structural `changes` dependency and leaf-set equality mutation checks pass. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated host proof | Core delivery and inbound record | Dedicated generated Phoenix hosts using `Host.Repo` | Inserted and reloaded both package records before rollback | ✓ FLOWING |
| CI Green policy | Detector and required-lane outcomes | GitHub Actions `needs` values | Explicit values reach strict shell policy | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core generator, legacy repair, generated-host contracts, CI policy/contracts | Phase-155 focused core ExUnit command with `--warnings-as-errors` | 86 tests, 0 failures | ✓ PASS |
| Inbound generator, migration classification, shared-schema rollback | `cd mailglass_inbound && MIX_ENV=test mix test ... --warnings-as-errors` | 21 tests, 0 failures | ✓ PASS |
| Inbound-first generated Host.Repo journey | Fresh isolated execution of generated proof with only `core_first` invocation removed | `Generated Ecto host proof passed.` | ✓ PASS |
| Core-first generated Host.Repo journey | Fresh isolated execution of generated proof with only `inbound_first` invocation removed | `Generated Ecto host proof passed.` | ✓ PASS |
| Shell/YAML/format checks | `bash -n`, `actionlint .github/workflows/ci.yml`, root formatter, targeted inbound formatter | Passed | ✓ PASS |

The local public schema still has the known unrelated `mailglass_outbound_payloads` FK contamination, which makes its broad core rollback test fail. It was not deleted or used as evidence. All adoption proof here uses separate validated `mailglass_generated_ecto_host_verify155final_{inbound_first,core_first}` databases, which were cleaned up after successful completion.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| ADOPT-01 | 155-01, 155-05, 155-07 | Generated host uses real core/inbound wrappers for apply and rollback | ✓ SATISFIED | Two isolated Host.Repo rollback orders passed. |
| ADOPT-02 | 155-01, 155-03 | Explicit repo selection and only unambiguous inference | ✓ SATISFIED | Core/inbound task acceptance matrices pass. |
| ADOPT-03 | 155-01, 155-03 | Additive reversible live/offline upgrade | ✓ SATISFIED | Timestamped wrapper and prior-version rollback tests pass. |
| ADOPT-04 | 155-01, 155-03 | Valid, older offline-version requirement | ✓ SATISFIED | `--from` acceptance/refusal matrix passes. |
| ADOPT-05 | 155-04 | Fail-closed non-destructive legacy repair | ✓ SATISFIED | Isolated exact/ambiguous/populated repair matrix passes. |
| ADOPT-06 | 155-02, 155-03, 155-04 | Absent anchor distinct from malformed/query failure | ✓ SATISFIED | Core/inbound catalog classification tests pass. |
| QUAL-02 | 155-06 | CI Green fails closed on detector/lane failure | ✓ SATISFIED | Policy decision table and workflow mutation contracts pass. |

### Anti-Patterns Found

None in Phase 155 implementation files. The prior shared-schema ownership failure is closed by retaining `RESTRICT` and suppressing only PostgreSQL's expected `dependent_objects_still_exist` condition inside the migration transaction.

### Gaps Summary

No gaps remain. The prior blocker was reproduced, fixed, and then falsified through fresh generated-host executions in both possible package rollback orders. No later-phase deferral or override was used.

---

_Verified: 2026-08-17T03:11:07Z_
_Verifier: the agent (gsd-verifier)_
