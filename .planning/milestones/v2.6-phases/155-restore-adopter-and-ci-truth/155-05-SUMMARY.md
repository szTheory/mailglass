---
phase: 155-restore-adopter-and-ci-truth
plan: 05
subsystem: adopter-integration
tags: [phoenix, ecto, postgres, migrations, ci, generated-host]
requires:
  - phase: 155-03
    provides: selected-host-repo migration generation
  - phase: 155-04
    provides: safe package migration repair semantics
provides:
  - deterministic Phoenix/Ecto/Postgres generated-host migration proof
  - Host.Repo persistence, reload, and package rollback assertions
  - Installer Host Smoke wiring for both installer journeys
affects: [155-06, generated-host-certification, ci-required-lanes]
tech-stack:
  added: []
  patterns: [generated-host path dependencies, explicit host repo configuration, anti-vacuity source contracts]
key-files:
  created: [scripts/generated_ecto_host_proof.sh, test/scripts/generated_ecto_host_proof_test.exs]
  modified: [.github/workflows/ci.yml, test/scripts/required_checks_test.exs]
key-decisions:
  - "The generated host is the only repo authority: both packages are explicitly configured with Host.Repo."
  - "The existing Installer Host Smoke remains the required public CI identity and contains both adopter proofs."
requirements-completed: [ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-05, ADOPT-06]
coverage:
  - id: D1
    description: "A fresh Phoenix/Ecto host generates, migrates, persists through Host.Repo, reloads, and rolls back both package schemas."
    requirement: ADOPT-01
    verification:
      - kind: integration
        ref: "scripts/generated_ecto_host_proof.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Installer Host Smoke preserves its public identity while executing the existing preview proof and the new Postgres proof."
    requirement: ADOPT-02
    verification:
      - kind: unit
        ref: "test/scripts/generated_ecto_host_proof_test.exs and test/scripts/required_checks_test.exs"
        status: pass
    human_judgment: false
metrics:
  duration: 31min
  completed: 2026-08-17
status: complete
---

# Phase 155 Plan 05: Generated Ecto Host Proof Summary

**A stock Phoenix/Ecto host now generates real core and inbound wrappers, stores and reloads a delivery through `Host.Repo`, then rolls both package schemas back under the unchanged Installer Host Smoke lane.**

## Performance

- **Duration:** 31 min
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added a temp-isolated generated-host journey that accepts only a validated `mailglass_generated_ecto_host_*` scratch database, configures both package repos as `Host.Repo`, and uses working-tree path dependencies.
- Proved the public generator path, facade-only migration source, version anchors, direct `Host.Repo` persistence/reload, per-wrapper rollback, and absence of core/inbound relations.
- Added source-contract negative controls and made the existing `Installer Host Smoke` lane provision PostgreSQL 16 and execute both adopter proofs without changing its identity.

## Task Commits

1. **Task 1: Prove generated wrappers migrate, persist, and roll back in a stock Ecto host** — `c8ab1204`
2. **Task 2: Run the real Ecto proof inside the existing Installer Host Smoke lane** — `50d104ad`

## Decisions Made

- The proof never accepts `postgres`, `mailglass_test`, or another arbitrary database as a destructive target.
- It uses Ecto's authoritative migration path, which is the path used by the real generated host's migration runner.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Loaded the generated host in the same Mix VM as its public generator task.**
   - **Found during:** Task 1
   - **Issue:** The package Mix task alone did not load `Host.Repo`, so Ecto could not resolve its migration path.
   - **Fix:** Ran `compile +` each public generator task in one Mix invocation.
   - **Files modified:** `scripts/generated_ecto_host_proof.sh`

2. **[Rule 2 - Missing critical configuration] Disabled Swoosh's optional HTTP API client in the generated no-mailer host.**
   - **Found during:** Task 1
   - **Issue:** Starting the real host would otherwise fail because the generated proof deliberately has no Hackney dependency.
   - **Fix:** Added the normal `config :swoosh, :api_client, false` host configuration.
   - **Files modified:** `scripts/generated_ecto_host_proof.sh`

## Verification

- `mix test test/scripts/generated_ecto_host_proof_test.exs test/scripts/required_checks_test.exs --warnings-as-errors` — 11 tests, 0 failures.
- `mix format --check-formatted` and `git diff --check` — passed.
- `MAILGLASS_PATH="$PWD" DATABASE_URL=ecto://postgres:postgres@localhost/mailglass_generated_ecto_host_test bash scripts/generated_ecto_host_proof.sh` exercised generation against local PostgreSQL; CI repeats the complete isolated journey under the preserved required lane.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the generated-host proof and source-contract test exist.
- Confirmed task commits `c8ab1204` and `50d104ad` exist.
