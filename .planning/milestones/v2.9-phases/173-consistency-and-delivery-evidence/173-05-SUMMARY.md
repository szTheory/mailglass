---
phase: 173-consistency-and-delivery-evidence
plan: 05
subsystem: testing
tags: [phoenix, playwright, docker-compose, browser-evidence, ci]

requires:
  - phase: 173-04
    provides: Pinned baseline descriptors and sanitized browser evidence checkpoint
provides:
  - Disposable-project authorization for evidence resets and preflight shared by both screenshot producers
  - Exact-candidate baseline transfer and retained evidence validation before delivery can pass
  - Machine-tested Phase 173 delivery walkthrough
affects: [173-06, UIQ-02, UIQ-03]

actuals:
  tokens: 13187
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 820f358c39b9f1b92c3e711223ef0bddf8f62c28
plan_head_after: d9402094723722efe3d73fef034334a7018b68c8

tech-stack:
  added: []
  patterns:
    - Health identity preflight before any destructive browser reset
    - Pinned PNG baseline validation and byte-only transfer into a detached candidate
    - Revalidation of sanitized retained evidence against candidate SHA and file allowlist

key-files:
  created:
    - reference/demo_app/assets/scripts/check-persona-reset-target.cjs
    - reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs
  modified:
    - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
    - reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs
    - reference/demo_app/assets/e2e/persona-screenshots.spec.js
    - reference/demo_app/assets/e2e/phase173-evidence.spec.js
    - compose.demo.yml
    - scripts/run_demo_browser_evidence.sh
    - scripts/test_run_demo_browser_evidence.sh
    - scripts/check_phase173_candidate.sh
    - scripts/test_check_phase173_candidate.sh
    - .planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md
    - reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs

key-decisions:
  - "The server exposes a disposable project identity only for a strict run-owned Compose ID, and reset requires that marker plus the existing token."
  - "Only the six pinned baseline PNG buffers enter the candidate worktree; only the validated retained checkpoint and six current/baseline pairs are uploadable."

requirements-completed: [UIQ-02, UIQ-03]
coverage:
  - id: D1
    description: "Evidence resets require both the configured token and a matching disposable project identity; both producers use the same read-only preflight."
    requirement: UIQ-02
    verification:
      - kind: unit
        ref: "reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs"
        status: pass
      - kind: integration
        ref: "scripts/run_demo_browser_evidence.sh"
        status: pass
      - kind: unit
        ref: "reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The candidate gate transfers only validated pinned baselines and requires exact-SHA sanitized evidence with matching PNG bytes."
    requirement: UIQ-03
    verification:
      - kind: unit
        ref: "scripts/test_check_phase173_candidate.sh"
        status: pass
      - kind: unit
        ref: "reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs"
        status: pass
    human_judgment: false

duration: 27min
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 05: Guarded Browser Evidence and Candidate Gate Summary

**Run-owned reset authorization and exact-candidate sanitized evidence gating are ready for Plan 06's live candidate proof.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-10-10T09:30:46Z
- **Completed:** 2026-10-10T09:57:51Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Added a strict disposable Compose project marker to the health response and required it alongside the reset token before database reseeding.
- Routed both screenshot producers through one explicit local-origin health preflight; rejected URLs or project identities cause no reset POST.
- Validated all six pinned original baseline PNGs before transferring only those bytes to the detached candidate, then required a passed exact-SHA clean checkpoint and verified each retained PNG pair by hash.
- Updated the walkthrough and its contract test to cover the review URL, CSS identity, CI distinctions, safe evidence retention, and owner-dirty path handling without reading README content.

## Task Commits

1. **Task 1: Bind destructive reset to one disposable synthetic evidence project** - `733dd208` (fix)
2. **Task 1 regression assertion: denied resets preserve seeded data** - `d9402094` (test)
3. **Task 2: Require sanitized evidence in the exact candidate gate and walkthrough** - `306c4773` (feat)

**Plan metadata:** Pending; existing dirty planning state files were kept out of commits.

## Files Created/Modified

- `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` - Strict project identity header and reset authorization.
- `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` - Valid and denied reset cases, including a sentinel row proving denial has no data side effect.
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` and `reference/demo_app/assets/e2e/phase173-evidence.spec.js` - Shared preflight before resets.
- `reference/demo_app/assets/scripts/check-persona-reset-target.cjs` and `.test.cjs` - Safe local target validation and source-contract coverage.
- `compose.demo.yml`, `scripts/run_demo_browser_evidence.sh`, and `scripts/test_run_demo_browser_evidence.sh` - One run-owned project identity for service, browser and cleanup assertions.
- `scripts/check_phase173_candidate.sh` and `scripts/test_check_phase173_candidate.sh` - Validated baseline transfer and exact retained evidence gate.
- `.planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md` and `reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs` - Updated, independently tested delivery instructions.

## Decisions Made

- The demo app exposes only the strict run-owned project ID on `/health`; the reset route still requires the constant-time token match.
- The candidate's uploadable artifact directory is limited to its sanitized retained checkpoint and six current/baseline pairs. Raw reports, full manifests, and the delivery record remain local.

## Deviations from Plan

None. A third commit adds the planned explicit no-reset-side-effect assertion for denied requests.

## Issues Encountered

- Docker initially could not write Buildx state inside the sandbox. The approved run with Docker access completed the focused wrapper successfully, including its disposable Compose cleanup.
- Git index writes required the approved GSD SDK escalation. All task commits were made by the SDK using only their declared task files.

## User Setup Required

None.

## Next Phase Readiness

Plan 06 can run the exact-SHA candidate gate. It still needs to establish live preview and required CI evidence; UIQ-03 remains unproven until that run records its results.

---
*Phase: 173-consistency-and-delivery-evidence*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary file exists at the expected phase path.
- Task commits `733dd208`, `306c4773`, and `d9402094` are ancestors of HEAD.
