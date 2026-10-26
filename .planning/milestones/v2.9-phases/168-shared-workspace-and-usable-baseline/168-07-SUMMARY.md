---
phase: 168-shared-workspace-and-usable-baseline
plan: 07
subsystem: ui
tags: [phoenix-liveview, cache-scope, transient-errors, replay, exunit]

# Dependency graph
requires:
  - phase: 168-05
    provides: Responsive operator baseline and gap-closing verification context
provides:
  - Tenant-scoped exact support fallback
  - Interval-scoped Health stale observations
  - Retryable replay confirmation after either transient fresh-read failure
affects: [operator, health, support, replay, phase-168-verification]

# Actuals (#2632)
actuals:
  tokens: 4804
  tasks: 3
  commits: 6

# Tech tracking
tech-stack:
  added: []
  patterns: [scope-bound stale caches, narrow classified transient-read recovery, tagged LiveView regressions]

key-files:
  created:
    - .planning/phases/168-shared-workspace-and-usable-baseline/tdd-evidence/168-07-task-1-red.json
    - .planning/phases/168-shared-workspace-and-usable-baseline/tdd-evidence/168-07-task-2-red.json
    - .planning/phases/168-shared-workspace-and-usable-baseline/tdd-evidence/168-07-task-3-delivery-red.json
    - .planning/phases/168-shared-workspace-and-usable-baseline/tdd-evidence/168-07-task-3-target-red.json
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/support/operator_fixtures.ex

key-decisions:
  - "Reuse stale exact evidence only when tenant, focus, and record identity all match."
  - "Bind Health stale observations to both tenant and the parsed observation window."
  - "Recover only classified transient confirmation reads; retain fail-loud behavior for unexpected errors and preserve authorization on retry."
  - "Keep verification in existing ExUnit/CI infrastructure with no new dependencies, as established by D-52."

patterns-established:
  - "Cache identity includes every user-selected scope dimension that changes what a value means."
  - "A transient action-time read failure restores a retryable UI state without changing the user's exact reviewed target."

requirements-completed: [UXF-02, UXF-04, UXF-06, UXF-07, UXF-08]

coverage:
  - id: D1
    description: Exact support evidence fallback cannot cross Account scope.
    requirement: UXF-02
    verification:
      - kind: integration
        ref: "test/mailglass_admin/operator_live_test.exs#g_168_7"
        status: pass
    human_judgment: false
  - id: D2
    description: Health stale observations remain bound to the selected interval.
    requirement: UXF-06
    verification:
      - kind: integration
        ref: "test/mailglass_admin/operator_live_test.exs#g_168_10"
        status: pass
    human_judgment: false
  - id: D3
    description: Both replay confirmation reads recover transiently while retaining the exact reviewed target for retry.
    requirement: UXF-07
    verification:
      - kind: integration
        ref: "test/mailglass_admin/operator_live_test.exs#g_168_9"
        status: pass
    human_judgment: false

# Metrics
duration: 11min
completed: 2026-10-08
status: complete
---

# Phase 168 Plan 07: Tenant-safe evidence and recoverable replay confirmation

Exact support and Health stale values now stay within their selected scope, and replay confirmation can recover from either classified transient read failure without losing its reviewed target.

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-08T18:08:00Z
- **Completed:** 2026-10-08T18:18:36Z
- **Tasks:** 3
- **Files modified:** 3 source/test files, plus four TDD evidence records

## Accomplishments

- Bound exact support evidence fallback to tenant, focus, and record identity; same-tenant stale fallback remains available.
- Bound Health stale observations to tenant and the parsed `window_hours` selection.
- Made both fresh replay-confirmation reads recoverable on classified transient errors, preserving the exact target and allowing normal action-time authorization and retry.
- Added deterministic tagged LiveView coverage and preserved RED evidence for each behavior without adding dependencies or CI jobs.

## Task Commits

1. **Task 1: Bind exact support evidence fallback to Account identity** - `8d930bb7` RED test/evidence, `459194a4` GREEN fix.
2. **Task 2: Scope stale Health fallback to the selected observation window** - `1f0f5c07` RED test/evidence, `5d8dc7dd` GREEN fix.
3. **Task 3: Recover each transient replay-confirmation read without losing its target** - `3f559759` RED tests/evidence, `99a2f08b` GREEN fix.

## Automated evidence

- `g_168_7`: 1 test, 0 failures; 104 excluded.
- `g_168_10`: 1 test, 0 failures; 105 excluded.
- `g_168_9`: 2 tests, 0 failures; 106 excluded.
- Each RED evidence record passed `gsd_run check tdd-red-evidence`.

## Decisions and deviation

The `selected_delivery` transient fault operation was not present in the fixture despite the original plan wording. A narrowly named one-shot operation was registered in the test fixture so the actual fresh confirmation read could be exercised. No production-only test seam was added.

D-52 remains the default: automate observable behavior at the cheapest reliable seam, keep it in existing CI coverage, avoid unnecessary dependencies, and reserve human judgment for genuinely subjective questions. These three deliverables have complete automated coverage and require no manual UAT.

## Next Phase Readiness

G-168-7, G-168-9, and G-168-10 are resolved in the UAT ledger. G-168-8 remains for Plan 168-08; that plan uses LiveViewTest for the actual Preview dismissal behavior.

## Self-Check: PASSED

- All three planned tasks are complete, with separate RED evidence and GREEN commits.
- Tagged LiveView regressions pass and are recorded in the coverage block and UAT ledger.
- No extra dependency, CI job, or manual UAT step was introduced.

---
*Phase: 168-shared-workspace-and-usable-baseline, Plan 07*
*Completed: 2026-10-08*
