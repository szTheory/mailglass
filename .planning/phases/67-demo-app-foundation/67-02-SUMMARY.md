---
phase: 67-demo-app-foundation
plan: 02
subsystem: infra
tags: [docker-compose, phoenix, playwright, demo-app]
requires:
  - phase: 67-demo-app-foundation
    provides: Demo app baseline and compose topology
provides:
  - Health-gated demo readiness for browser evidence startup
  - Lockfile-based and deterministic browser dependency setup for demo_e2e
affects: [phase-68, phase-70, demo-evidence]
tech-stack:
  added: []
  patterns: [compose-health-gating, npm-ci-lockfile-install, playwright-with-deps]
key-files:
  created: []
  modified:
    - compose.demo.yml
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
key-decisions:
  - "Use demo-local /health endpoint returning plain text ok for compose health probing."
  - "Use npm ci plus playwright install --with-deps chromium in demo_e2e command to keep dependency installs deterministic."
patterns-established:
  - "Browser evidence services must depend on Phoenix service_healthy, not service_started."
  - "Demo browser dependency installs must be lockfile-driven."
requirements-completed: [DX-01, DX-02]
duration: 4min
completed: 2026-06-01
---

# Phase 67 Plan 02: Demo Stack Readiness Summary

**Compose demo now enforces Phoenix health readiness and deterministic Playwright dependency setup for reliable click-around and browser evidence runs.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-01T18:48:00Z
- **Completed:** 2026-06-01T18:52:06Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added demo-only `GET /health` route and controller response (`ok`) in the demo Phoenix app.
- Added a `demo` container healthcheck that probes `http://localhost:4015/health`.
- Switched `demo_e2e` to `depends_on.demo.condition: service_healthy` and replaced `npm install` with `npm ci`, plus `playwright install --with-deps chromium`.

## Task Commits

1. **Task 1: Add Phoenix readiness and Compose health gating** - `4141ea3` (feat)
2. **Task 2: Make browser dependency setup lockfile-based and deterministic** - `2a8d01b` (fix)

## Files Created/Modified
- `compose.demo.yml` - Added `demo` healthcheck, changed `demo_e2e` gating to `service_healthy`, and switched evidence install commands to deterministic lockfile + Playwright deps.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - Added `GET /health` demo route.
- `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` - Added `health/2` returning plain text `ok`.

## Decisions Made
- Health endpoint is implemented in demo app code (`MailglassDemoWeb.PageController`) to keep readiness checks inside `reference/demo_app`, not package source.
- Deterministic browser dependency setup is enforced at compose runtime with `npm ci` and `playwright install --with-deps chromium` while preserving existing cache volumes/env vars.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Demo compose stack now has health-gated readiness semantics and deterministic browser setup prerequisites for follow-on evidence work.
- No blockers identified for downstream demo-app phases.

## Self-Check: PASSED

- Verified modified files exist and are tracked in git history.
- Verified task commit hashes exist: `4141ea3`, `2a8d01b`.
