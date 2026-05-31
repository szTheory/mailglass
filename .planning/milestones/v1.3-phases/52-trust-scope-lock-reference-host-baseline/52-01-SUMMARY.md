---
phase: 52-trust-scope-lock-reference-host-baseline
plan: "01"
subsystem: infra
tags: [reference-host, phoenix, ecto, contract-test]
requires:
  - phase: "52-context"
    provides: "Scope locks and trust-proof boundary decisions for the maintained host baseline"
provides:
  - "Committed maintained host scaffold at reference/host_app"
  - "Canonical clean-checkout setup contract for HOST-01"
  - "Boot contract test that fails closed on README drift"
affects: ["52-02 public seam contract checks", "53 deterministic trust journey runner"]
tech-stack:
  added: ["Phoenix host app scaffold under reference/host_app"]
  patterns: ["published-version host dependency pinning", "README token assertions for trust contract enforcement"]
key-files:
  created:
    - reference/host_app/mix.exs
    - reference/host_app/config/config.exs
    - reference/host_app/config/dev.exs
    - reference/host_app/config/runtime.exs
    - reference/host_app/lib/mailglass_reference_host/application.ex
    - reference/host_app/lib/mailglass_reference_host/repo.ex
    - reference/host_app/lib/mailglass_reference_host_web/router.ex
    - reference/host_app/priv/repo/migrations/20260527000000_create_mailglass_reference_baseline.exs
    - reference/host_app/.env.example
    - reference/host_app/README.md
    - test/reference_host/boot_contract_test.exs
  modified: []
key-decisions:
  - "Keep the baseline host thin and Ecto-capable, with only published Mailglass package constraints and no path dependencies."
  - "Enforce README trust-boundary language with deterministic required/forbidden token assertions in ExUnit."
patterns-established:
  - "Reference host baseline lives in reference/host_app and stays separate from fixture-only test/example."
  - "HOST-01 promises are encoded as README tokens plus boot_contract_test assertions."
requirements-completed: [HOST-01]
duration: 4 min
completed: 2026-05-27
---

# Phase 52 Plan 01: Reference Host Baseline Summary

**A committed maintained Phoenix host baseline now boots with Ecto wiring and a deterministic README-backed boot contract for HOST-01.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-27T09:20:00Z
- **Completed:** 2026-05-27T09:24:19Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Added a thin maintained host app under `reference/host_app` with published Mailglass constraints (`~> 1.2`, `~> 1.2`, `~> 0.2`) and no path dependencies.
- Wired Ecto baseline plumbing (`Repo`, app supervision, migration config, and sentinel migration `mailglass_reference_baseline`).
- Created a canonical setup README and enforced required/forbidden drift tokens with `test/reference_host/boot_contract_test.exs`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold `reference/host_app` as the committed maintained baseline host** - `a56796b` (feat)
2. **Task 2: Document clean-checkout setup and enforce HOST-01 with boot contract tests** - `0e2ce52` (feat)

## Files Created/Modified

- `reference/host_app/mix.exs` - standalone reference host app with published Mailglass dependency constraints.
- `reference/host_app/config/config.exs` - Ecto repo registration and baseline app config.
- `reference/host_app/config/dev.exs` - local Postgres defaults for clean-checkout bootstrap.
- `reference/host_app/config/runtime.exs` - runtime DATABASE_URL/POOL_SIZE repo config.
- `reference/host_app/lib/mailglass_reference_host/application.ex` - app supervisor with Repo child.
- `reference/host_app/lib/mailglass_reference_host/repo.ex` - Postgres repo module.
- `reference/host_app/lib/mailglass_reference_host_web/router.ex` - webhook + preview route baseline using public seams.
- `reference/host_app/priv/repo/migrations/20260527000000_create_mailglass_reference_baseline.exs` - sentinel baseline table migration.
- `reference/host_app/.env.example` - bootstrap environment defaults.
- `reference/host_app/README.md` - canonical host setup lane and explicit boundary statements.
- `test/reference_host/boot_contract_test.exs` - deterministic token-based host bootstrap contract test.

## Decisions Made

- Used a committed host artifact under `reference/host_app` with its own `mix.lock` to keep bootstrap reproducible and separate from fixture-only host seeds.
- Kept operator routes out of the initial baseline router because `mailglass_operator_routes/2` requires adopter auth/session config that is outside HOST-01 scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Router compile guard for admin macro imports**
- **Found during:** Task 1 (host scaffold compile verification)
- **Issue:** `mailglass_admin_routes/2` expansion failed because `live_session/3` was not imported.
- **Fix:** Added `import Phoenix.LiveView.Router` to `reference/host_app/lib/mailglass_reference_host_web/router.ex`.
- **Files modified:** `reference/host_app/lib/mailglass_reference_host_web/router.ex`
- **Verification:** `cd reference/host_app && mix compile --warnings-as-errors`
- **Committed in:** `a56796b`

**2. [Rule 3 - Blocking] Operator route required auth options out of HOST-01 scope**
- **Found during:** Task 1 (host scaffold compile verification)
- **Issue:** `mailglass_operator_routes "/mail-ops"` failed compile because required `:auth` and `:session` options were not provided.
- **Fix:** Removed operator route from baseline router to keep HOST-01 thin and avoid out-of-scope auth scaffolding.
- **Files modified:** `reference/host_app/lib/mailglass_reference_host_web/router.ex`
- **Verification:** `cd reference/host_app && mix compile --warnings-as-errors`
- **Committed in:** `a56796b`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required to satisfy compile verification while preserving HOST-01 scope boundaries.

## Issues Encountered

- Root-project test verification initially reported lock mismatch; running `mix deps.get` in the root workspace cleared the blocker and allowed `mix test test/reference_host/boot_contract_test.exs --warnings-as-errors` to pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 52-02 public seam contract enforcement with a maintained bootable host baseline now committed.
- No blockers for HOST-02/03 planning artifacts in this plan.

## Self-Check: PASSED

---
*Phase: 52-trust-scope-lock-reference-host-baseline*
*Completed: 2026-05-27*
