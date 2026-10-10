---
phase: 173-consistency-and-delivery-evidence
plan: 01
subsystem: testing
tags: [playwright, docker-compose, evidence, node-test, browser]
requires:
  - phase: 171-developer-preview
    provides: Existing demo routes, seeded preview fixtures, and browser review surfaces
  - phase: 172-recipient-output-and-built-in-pages
    provides: Recipient unsubscribe route and current demo state
provides:
  - Isolated per-run Compose lifecycle for demo browser evidence
  - Focused Phase 173 Playwright coverage with six source-identified captures
  - Fail-closed evidence checkpoint bound to candidate revision, PNG bytes, baselines, and source/build/served assets
affects: [173-02, 173-03, browser-evidence, ci]
actuals:
  tokens: 12792
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 1f84f510fcf6e80799fa99027bd1a33b186f47fa
plan_head_after: 9dfe992dcc14d61f017fcfb9e10b951712eab7c6
tech-stack:
  added: []
  patterns: [Run-owned Compose projects and ephemeral host ports, Playwright JSON plus byte-verified screenshot provenance, Node built-in contract tests]
key-files:
  created:
    - reference/demo_app/assets/e2e/phase173-evidence.spec.js
    - scripts/test_run_demo_browser_evidence.sh
  modified:
    - scripts/run_demo_browser_evidence.sh
    - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
    - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
key-decisions:
  - "Each evidence run uses one unique Compose project and two non-default host ports, and cleans only its own project."
  - "Select only the phase-owned Playwright spec so the dirty Phase 172 demo spec is never discovered or executed."
  - "Record historical full-page image dimensions separately from the browser viewport so baseline bytes are validated without relabeling them."
  - "Record browser rendering evidence only; the checkpoint does not claim delivered-email client behavior."
patterns-established:
  - "Evidence contract tests use fake Docker and temporary PNG fixtures to verify isolation and fail-closed provenance without Docker."
  - "A checkpoint binds the full candidate revision, dirty-tree state, actual PNG SHA-256, baseline identity, and source/build/served assets."
requirements-completed: [UIQ-02, UIQ-03]
coverage:
  - id: D1
    description: "Run-owned browser evidence lifecycle and failure cleanup are checked by a local fake-Docker contract."
    requirement: UIQ-03
    verification:
      - kind: unit
        ref: "bash scripts/test_run_demo_browser_evidence.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Focused browser evidence captures current primary and adverse states with candidate, asset, baseline, and PNG byte provenance."
    requirement: UIQ-02
    verification:
      - kind: unit
        ref: "node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs"
        status: pass
      - kind: e2e
        ref: "bash scripts/run_demo_browser_evidence.sh; checkpoint candidate 9dfe992dcc14d61f017fcfb9e10b951712eab7c6"
        status: pass
    human_judgment: false
duration: 35min
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 01: Isolated Browser Evidence Summary

**A run-owned Compose workflow now produces six current browser captures whose candidate, baseline, asset, and PNG byte identities pass a fail-closed checkpoint.**

## Performance

- **Duration:** approximately 35 minutes
- **Started:** 2026-10-10T00:35:52Z
- **Completed:** 2026-10-10T01:10:26Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added an isolated demo evidence runner with unique project identity, distinct non-default loopback ports, focused spec selection, owned-project cleanup, and bounded failure logs.
- Added fake-Docker lifecycle checks and Node built-in tests for missing/unsafe paths, PNG byte hashes, candidate provenance, asset mismatch, and historical baseline image dimensions.
- Added five focused Playwright tests producing six bounded screenshots across dashboard, preview, outbound, inbound, empty-account, and expired-recipient states. Captures use synthetic fixtures and carry route, theme, viewport, interaction, browser, baseline, candidate, and asset provenance.
- Captured the baseline before changing the evidence target from revision `7e3720237f51f2907b77c7dcb03042f2dd379d53` with a dirty working tree. Baseline images and hashes are recorded in the phase-owned spec; baseline full-page dimensions are verified against their PNG bytes.
- Ran the final wrapper against candidate `9dfe992dcc14d61f017fcfb9e10b951712eab7c6`. Checkpoint status was `passed`, with six captures and Chromium `148.0.7778.0`. The candidate dirty flag is `true` because unrelated owner changes remained in the shared checkout.
- The run-owned Compose project and disposable volumes were removed. No active containers remained for that project.

## Verification

- `bash scripts/test_run_demo_browser_evidence.sh` — passed.
- `node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs` — 9 passed, 0 failed.
- `BUILDX_CONFIG=/tmp/mailglass-phase173-buildx bash scripts/run_demo_browser_evidence.sh` — passed; checkpoint recorded six captures and the final candidate revision.
- `git diff --check HEAD~4..HEAD` — passed.
- Required Playwright titles passed: dashboard navigation; outbound delivery quick view; inbound mailbox quick view; empty account; expired recipient state.

The browser evidence certifies only rendered browser surfaces. It does not establish Gmail, Outlook, Apple Mail, remote image, or delivered-email dark-mode behavior. The dirty Phase 172 `demo.spec.js` was not read, imported, staged, or executed.

## Task Commits

1. **Task 1: Preserve the retained preview while proving one complete demo evidence route** — `7e372023` (`fix`).
2. **Task 2: Capture bounded current and adverse browser evidence with exact provenance** — `f79b55f1` (`fix`).
3. **Task 2 follow-up: Use the container's absolute report path** — `f7649d25` (`fix`); found by the actual run and verified in the next full run.
4. **Task 2 follow-up: Record historical full-page baseline dimensions** — `9dfe992d` (`fix`); keeps viewport and image dimensions distinct and is verified in the final full run.

**Plan metadata:** this summary is committed separately; pre-existing dirty `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` changes were preserved and left unstaged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used an absolute evidence report path inside the runner container**
- **Found during:** Task 2 end-to-end verification
- **Issue:** The `demo_e2e` service's effective working directory did not resolve the relative report path to the shared evidence directory.
- **Fix:** Redirect Playwright JSON to `/workspace/reference/demo_app/tmp/demo_browser_evidence/playwright-report.json`.
- **Files modified:** `scripts/run_demo_browser_evidence.sh`
- **Commit:** `f7649d25`

**2. [Rule 1 - Bug] Validated full-page baseline dimensions separately from viewport dimensions**
- **Found during:** Task 2 end-to-end verification
- **Issue:** Historical baselines are full-page PNGs whose heights exceed their recorded browser viewport; exact height equality incorrectly rejected their genuine bytes.
- **Fix:** Record baseline capture dimensions explicitly and verify width, minimum viewport height, and exact PNG dimensions against the declared capture dimensions.
- **Files modified:** `reference/demo_app/assets/e2e/phase173-evidence.spec.js`, `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs`, `reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs`
- **Commit:** `9dfe992d`

## Deferred Issues

- Required CI checks and remote delivery evidence remain in later Phase 173 plans.
- GSD state/roadmap/requirement bookkeeping remains pending because those tracked files contain unrelated pre-existing dirty changes; they were not staged or committed in this plan-owned summary commit.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All four measured plan commits (`7e372023`, `f79b55f1`, `f7649d25`, `9dfe992d`) are ancestors of `HEAD`.
- `plan_head_before` is `HEAD~4`; measured plan commits are 4; `plan_head_after` matches current `HEAD` `9dfe992dcc14d61f017fcfb9e10b951712eab7c6`.
- The plan-owned source files contain no TODO, FIXME, placeholder, or coming-soon stubs.
