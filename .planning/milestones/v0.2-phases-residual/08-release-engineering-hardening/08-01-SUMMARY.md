---
phase: 08-release-engineering-hardening
plan: "01"
subsystem: infra
tags: [github-actions, hex, actionlint, release-engineering, publish, ci-cd]

# Dependency graph
requires: []
provides:
  - "publish-hex.yml triggered by GitHub release publication (on: release: types: [published])"
  - "mix hex.info idempotency guard in both publish-core and publish-admin jobs"
  - "post-publish-smoke.yml triggered by same release event, version resolved from release.tag_name"
affects:
  - "08-release-engineering-hardening (subsequent plans rely on stable publish pipeline)"
  - "Maintainer publish runbook (no more manual workflow_dispatch needed on release)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "on: release: types: [published] as the canonical Hex publish trigger (fires once per release, not on workflow rerun)"
    - "mix hex.info idempotency guard before mix hex.publish (exits 0 / sets skip=true when version already on Hex)"
    - "Version resolution from github.event.release.tag_name for release-triggered workflows"

key-files:
  created: []
  modified:
    - ".github/workflows/publish-hex.yml"
    - ".github/workflows/post-publish-smoke.yml"

key-decisions:
  - "Use on: release: types: [published] not on: push: tags: — release event is gated by maintainer publishing in GitHub UI; push: tags fires on rerun and would double-publish (PITFALLS.md REL-01)"
  - "Add mix hex.info idempotency guard in BOTH publish-core and publish-admin jobs independently — each package guards its own publish step"
  - "Keep schedule: cron in post-publish-smoke.yml — plan said 'same trigger swap' meaning replace workflow_run, not remove all other triggers"
  - "Auto-fix: add cron-guard to notify-on-failure needs: list (was missing in original, causing actionlint expression error)"
  - "Auto-fix: add shellcheck disable=SC2064 on intentional double-quote trap (SERVER_PID must expand at setup time)"

patterns-established:
  - "idempotency-guard-before-publish: mix hex.info check gates mix hex.publish in every publish job"
  - "release-event-version-resolution: github.event.release.tag_name is the canonical source for the published tag in release-triggered workflows"

requirements-completed: [REL-01]

# Metrics
duration: 4min
completed: 2026-04-27
---

# Phase 8 Plan 01: Publish Trigger Swap + Idempotency Guard Summary

**Replace dead workflow_run-with-head_branch gate with on: release: types: [published] across both publish workflows, and add mix hex.info idempotency guard so workflow reruns cannot double-publish.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-27T03:11:18Z
- **Completed:** 2026-04-27T03:15:12Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- publish-hex.yml now fires on actual GitHub release publication — the workflow_run trigger with `head_branch` comparison (which always resolved to "main") is gone
- mix hex.info pre-check added to both publish-core and publish-admin jobs: sets `skip=true` output and skips `mix hex.publish` when the version is already on Hex.pm, preventing double-publish on workflow rerun
- post-publish-smoke.yml version resolution fixed: cron-guard now reads `github.event.release.tag_name` for release events instead of the dead `workflow_run.head_branch` path that produced `VERSION=main`
- Both files pass actionlint with no errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Swap publish-hex.yml trigger + add idempotency guard** - `1ffe5e1` (feat)
2. **Task 2: Swap post-publish-smoke.yml trigger + fix version resolution** - `d298d58` (feat)

## YAML Diff Summary

### publish-hex.yml

**Trigger block (lines 3-7):**
```yaml
# Before
on:
  workflow_run:
    workflows: ["release-please"]
    types:
      - completed

# After
on:
  release:
    types: [published]
```

**prepublish-summary if: gate removed** — the `startsWith(github.event.workflow_run.head_branch, 'mailglass-v')` conditional never matched (head_branch was always "main"); the new trigger fires only on release publication, making the gate unnecessary.

**publish-core/publish-admin if: conditions** — replaced `github.event_name == 'workflow_run'` branches with `github.event_name == 'release'`.

**Checkout ref** — updated from `github.event.workflow_run.head_branch` to `github.event.release.tag_name`.

**gate-ci-green SHA resolution** — updated from `context.payload.workflow_run?.head_sha` to `context.payload.release?.tag_name`.

**Idempotency guard added in publish-core:**
```yaml
- name: Skip if version already on Hex
  id: idempotency
  run: |
    VERSION="${{ steps.version.outputs.version }}"
    if mix hex.info mailglass "${VERSION}" 2>/dev/null | grep -q "Released:"; then
      echo "Version ${VERSION} of mailglass already on Hex — skipping publish (idempotency guard)."
      echo "skip=true" >> "$GITHUB_OUTPUT"
    fi
- name: Publish mailglass to Hex.pm
  if: steps.idempotency.outputs.skip != 'true'
  ...
```

**Idempotency guard also added in publish-admin** (same pattern, guards `mailglass_admin` package independently).

**Version read step added in publish-admin** — was missing in the original file; now reads `@version` from `mailglass_admin/mix.exs` for the idempotency guard.

### post-publish-smoke.yml

**Trigger block:**
```yaml
# Before
on:
  workflow_run:
    workflows: ["publish-hex"]
    types: [completed]
  schedule: ...
  workflow_dispatch:
    inputs:
      version: ...

# After
on:
  release:
    types: [published]
  schedule: ...
  workflow_dispatch:
    inputs:
      tag: ...
```

**cron-guard version resolution** — added `release` event handler that reads `context.payload.release.tag_name` and normalizes it via the existing `normalizeVersion()` function. Removed the `workflow_run` branch that read `head_branch` (was always "main").

**actionlint confirmation:** Both files pass `actionlint 1.7.12` with no errors.

## Files Created/Modified

- `.github/workflows/publish-hex.yml` — trigger swapped, head_branch gate removed, idempotency guard added to both publish jobs, version read step added to publish-admin
- `.github/workflows/post-publish-smoke.yml` — trigger swapped, version resolution fixed to use release.tag_name, workflow_dispatch input renamed from version to tag

## Decisions Made

- **on: release: types: [published] over on: push: tags:** — The todo files recommended `push: tags` but the PLAN.md explicitly mandates `release: types: [published]`. Release event is the correct choice: it's gated by the maintainer consciously publishing in GitHub UI (not just pushing a tag), matches PITFALLS.md REL-01 guidance, and cannot fire on a workflow rerun (only on the original release publication).
- **Kept schedule: cron in post-publish-smoke.yml** — plan says "same trigger swap" (replace workflow_run), not "remove all other triggers." The daily cron's 7-day window guard provides ongoing post-publish health monitoring that complements the release-triggered smoke.
- **Branch-protection updates deferred to 08-05 PR-C** — marking the strict CI gate as required in branch protection is a `szTheory`-only admin action per D-08-13; this plan only modifies workflow files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added cron-guard to notify-on-failure needs: list**
- **Found during:** Task 2 (post-publish-smoke.yml)
- **Issue:** `notify-on-failure` referenced `needs.cron-guard.outputs.should_run` in its `if:` condition but `cron-guard` was not in its `needs:` list. actionlint flagged this as an expression error: "property 'cron-guard' is not defined in object type {consumer-install, retracted-check, ...}." This pre-existed in the original file.
- **Fix:** Added `cron-guard` to `notify-on-failure`'s `needs:` list: `needs: [cron-guard, wait-for-index, wait-for-hexdocs, consumer-install, retracted-check]`
- **Files modified:** `.github/workflows/post-publish-smoke.yml`
- **Verification:** actionlint PASS
- **Committed in:** d298d58 (Task 2 commit)

**2. [Rule 1 - Bug] Added shellcheck disable=SC2064 on intentional double-quote trap**
- **Found during:** Task 2 (post-publish-smoke.yml)
- **Issue:** `trap "kill $SERVER_PID 2>/dev/null || true" EXIT` — shellcheck SC2064 warns that double quotes cause `$SERVER_PID` to expand at trap setup time rather than signal time. In this script, `$SERVER_PID` is set immediately before the trap (line N-1), so the double-quote expansion is correct and intentional — the trap must capture the current PID value.
- **Fix:** Added `# shellcheck disable=SC2064` on the preceding line to document the intentional behavior.
- **Files modified:** `.github/workflows/post-publish-smoke.yml`
- **Verification:** actionlint PASS (SC2064 suppressed cleanly)
- **Committed in:** d298d58 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both auto-fixes were pre-existing bugs surfaced by actionlint during verification. No scope creep — both fixes are contained to the workflow file that was already being modified.

## Issues Encountered

None — both tasks completed on the first implementation pass. actionlint was not installed initially and was installed via `brew install actionlint` during verification.

## User Setup Required

None — no external service configuration required. The `HEX_API_KEY` secret is already configured in the `hex-publish` GitHub Environment (noted in project MEMORY.md).

The publish flow now triggers automatically on GitHub release publication. Manual `workflow_dispatch` with a `tag:` input is retained as the recovery path.

## Next Phase Readiness

- REL-01 is complete: publish-hex.yml and post-publish-smoke.yml are event-correct and idempotent.
- Ready for 08-02 (next plan in the phase — REL-02, REL-03, or REL-04 depending on wave assignment).
- Branch-protection update (PR-C in D-08-13) deferred to 08-05 — this is a `szTheory`-only admin action.
- No blockers introduced.

---

## Self-Check: PASSED

Files verified to exist:
- `.github/workflows/publish-hex.yml` — FOUND
- `.github/workflows/post-publish-smoke.yml` — FOUND

Commits verified:
- `1ffe5e1` — FOUND (feat(08-01): swap publish-hex.yml trigger...)
- `d298d58` — FOUND (feat(08-01): swap post-publish-smoke.yml trigger...)

---
*Phase: 08-release-engineering-hardening*
*Completed: 2026-04-27*
