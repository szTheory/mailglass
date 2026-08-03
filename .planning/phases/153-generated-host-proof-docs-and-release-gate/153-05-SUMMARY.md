---
phase: 153
plan: 05
subsystem: production-readiness
tags: [elixir, mix, phoenix, oban, operator-auth, generated-host]
requires:
  - phase: 153-04
    provides: generated Phoenix/Ecto/Postgres host with real HTTP proof seams
provides:
  - callable secret-safe production preflight and strict Mix command
  - authenticated generated-host operator mount with readiness checkpoint
affects: [153-06, adoption-gate, release-gate]
tech-stack:
  added: []
  patterns: [aggregated bounded readiness checks, host-owned authenticated operator mount, sanitized status-only proof]
key-files:
  created:
    - lib/mailglass/production_preflight.ex
    - lib/mix/tasks/mailglass.preflight.ex
    - test/mailglass/production_preflight_test.exs
    - test/mailglass/mix_tasks/preflight_test.exs
    - test/generated_host/readiness_operator_test.exs
  modified:
    - lib/mailglass/config.ex
    - dev/mailglass/generated_host/host_template.ex
    - dev/mailglass/generated_host/journey.ex
    - dev/mailglass/generated_host/checkpoint.ex
    - scripts/generated_host_proof.sh
    - scripts/check_generated_host_proof.sh
    - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
key-decisions:
  - "Production preflight returns all bounded check results rather than stopping at the first missing prerequisite."
  - "The generated operator proof uses a host-owned BasicAuth pipeline and an explicit MailglassAdmin.Auth/session whitelist, never dev_routes."
  - "An installed but unconfigured optional inbound package is unavailable to the operator surface."
requirements-completed: [ADOPT-05]
coverage:
  - id: D1
    description: "Callable preflight reports repo, schema, migration, adapter, signing, queue, maintenance, and operator checks without secret output."
    requirement: ADOPT-05
    verification:
      - kind: unit
        ref: "mix test test/mailglass/production_preflight_test.exs test/mailglass/mix_tasks/preflight_test.exs --seed 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated production host rejects anonymous operator access and accepts an authenticated operator only when preflight is ready."
    requirement: ADOPT-05
    verification:
      - kind: integration
        ref: "DEP_MODE=local generated-host readiness journey and sanitized checkpoint validator"
        status: pass
      - kind: unit
        ref: "test/generated_host/readiness_operator_test.exs"
        status: pass
    human_judgment: false
metrics:
  duration: 12 min
  tasks_completed: 2
  files_changed: 12
  completed: 2026-08-03
status: complete
---

# Phase 153 Plan 05: Production Preflight and Operator Readiness Summary

Mailglass now exposes a secret-safe production readiness contract and proves an authenticated, non-dev generated-host operator route against real PostgreSQL and Oban.

## Tasks Completed

1. Added the public `Mailglass.ProductionPreflight.run/1` contract, documented config accessors, and `mix mailglass.preflight` command.
2. Added the generated host's authenticated `/ops/mail` mount and a readiness checkpoint proving anonymous denial, authorized access, and a ready preflight.

## Verification

- `mix test test/mailglass/production_preflight_test.exs test/mailglass/mix_tasks/preflight_test.exs test/generated_host/readiness_operator_test.exs --seed 0` — passed (6 tests, 0 failures).
- `mix compile --warnings-as-errors` — passed.
- `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/operator_live_test.exs --seed 0` — passed (97 tests, 0 failures).
- Package-shaped local generated host readiness journey — passed with schema `mailglass_proof_1785778589_4135`: preflight ready, anonymous `/ops/mail` returned 401, and authenticated `/ops/mail` returned 200.
- Sanitized readiness checkpoint validator — passed; the checkpoint contains only readiness boolean and the 401/200 status pair.

## Task Commits

1. Task 1 RED — `0785f46c` `test(153-05): define production preflight contract`
2. Task 1 GREEN — `d470d789` `feat(153-05): add production preflight`
3. Task 2 RED — `c01c84cc` `test(153-05): define production operator readiness proof`
4. Task 2 GREEN — `e189d2b8` `feat(153-05): prove production operator readiness`

## Decisions Made

- Preflight reports every named prerequisite in one result and emits remediation only, never configured values.
- The host owns HTTP authentication and the operator callback; Mailglass core does not import admin internals.
- Scheduled payload maintenance is explicit in the generated production configuration; `:manual` remains the documented bounded fallback.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Optional inbound availability now requires a configured host Repo.
- **Found during:** Task 2 generated-host readiness proof.
- **Issue:** An installed but unconfigured `mailglass_inbound` package was treated as available, so the operator tenant selector queried a missing inbound Repo and returned HTTP 500.
- **Fix:** The optional inbound gateway reports unavailable unless `:mailglass_inbound, :repo` is a non-nil module, keeping the optional surface hidden in a host that has not adopted inbound persistence.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex`
- **Verification:** The retained package-shaped host changed from authorized 500 to authorized 200; the focused admin operator suite passed.
- **Committed in:** `e189d2b8`

**Total deviations:** 1 auto-fixed Rule 1 issue. The correction was required for the requested production operator proof and did not add an inbound feature.

## Known Stubs

None.

## Next Phase Readiness

Plan 06 can use the callable preflight and generated-host `readiness` stage as the D-15/D-16 executable evidence seam.

## Self-Check: PASSED

- Created production preflight source, strict Mix task, and generated-host readiness oracle exist.
- All four RED/GREEN task commits exist in git history.

*Phase: 153-generated-host-proof-docs-and-release-gate*
*Completed: 2026-08-03*
