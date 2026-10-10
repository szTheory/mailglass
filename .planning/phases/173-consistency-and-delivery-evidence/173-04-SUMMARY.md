---
phase: 173-consistency-and-delivery-evidence
plan: 04
subsystem: testing
tags: [playwright, node, exunit, npm-lock, ci-evidence]
requires:
  - phase: 173-01
    provides: Run-owned browser evidence lifecycle and source-identified capture inputs
  - phase: 173-02
    provides: Admin capture manifest and preview evidence contracts
  - phase: 173-03
    provides: Candidate delivery documentation and readiness gate
provides:
  - Synthetic-only retained browser artifact staging with success-only advisory upload
  - Admin actual capture rejection for built-versus-served CSS mismatch and CI mailable restrictions
  - Offline exact-lock dependency gate before all four demo browser npm ci paths
affects: [phase-173-verification, browser-evidence, preview-capture]
actuals:
  tokens: 6267
  tasks: 3
  commits: 3
  plan_head_before: 0981abc844c230aaaf2a705c0e44a9939c7cec59
  plan_head_after: 4a5c2fdb0cc602fe95010b4e31777d9c84e2081a
tech-stack:
  added: []
  patterns: [offline exact-lock validation before install, synthetic allowlist staging]
key-files:
  created:
    - reference/demo_app/assets/scripts/check-demo-browser-deps.cjs
    - reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs
  modified:
    - .github/workflows/ci.yml
    - scripts/run_demo_browser_evidence.sh
    - scripts/test_run_demo_browser_evidence.sh
    - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
    - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
    - mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex
    - mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs
    - mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex
    - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
    - reference/demo_app/Dockerfile
    - reference/demo_app/mix.exs
    - compose.demo.yml
key-decisions:
  - "Only six pinned synthetic browser captures and their validated baseline pairs enter retained evidence."
  - "Keep the browser artifact job advisory and make uploads conditional on successful evidence validation."
  - "Freeze the exact four-package npm lock contract in Node built-ins without adding a dependency."
patterns-established:
  - "Stage evidence in a fresh directory and publish it only after every validation passes."
  - "Run the same offline dependency gate immediately before each demo browser npm ci."
requirements-completed: [UIQ-02, UIQ-03]
coverage:
  - id: D1
    description: Only validated synthetic checkpoint data and six current/baseline PNG pairs can be retained and uploaded.
    requirement: UIQ-02
    verification:
      - kind: unit
        ref: reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
        status: pass
      - kind: integration
        ref: scripts/test_run_demo_browser_evidence.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Admin actual capture rejects built/served CSS divergence and CI limits capture to the synthetic HappyMailer.
    requirement: UIQ-02
    verification:
      - kind: unit
        ref: mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs
        status: pass
      - kind: unit
        ref: mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: All demo browser npm ci entry points validate the exact audited lock first.
    requirement: UIQ-03
    verification:
      - kind: unit
        ref: reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs
        status: pass
      - kind: other
        ref: npm --prefix reference/demo_app/assets audit --package-lock-only --audit-level=high
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 04: Consistency and Delivery Evidence Summary

**Synthetic-only browser evidence retention, fail-closed Admin capture identity, and exact-lock checks before every demo browser install.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-10-10T09:07:00Z (approximate)
- **Completed:** 2026-10-10T09:28:27Z
- **Tasks:** 3
- **Files modified:** 14

## Accomplishments

- The evidence checker validates the six synthetic capture identities and pinned baseline bytes, emits a sanitized checkpoint, and stages only those PNG pairs under `retained/`. The wrapper clears stale retained output before each run, and CI uploads that directory only after the evidence step succeeds.
- Actual Admin manifests and direct actual writes reject built/served CSS hash mismatches. CI capture requires exactly `MailglassAdmin.Fixtures.HappyMailer`, while local dry-run discovery and explicit multi-mailable behavior remain available.
- Added a Node built-in gate for the exact four-package browser dependency lock and called it before Docker, Compose, evidence-wrapper, and `mix setup` installs. The existing advisory evidence job now audits its lock for high vulnerabilities.

## Task Commits

1. **Task 1: Stage only checked synthetic browser evidence for advisory upload** - `e721c6a9` (`feat`)
2. **Task 2: Reject false Admin CSS proof and non-synthetic CI mailables** - `a4b43836` (`fix`)
3. **Task 3: Validate the exact demo browser package set before existing installs** - `4a5c2fdb` (`feat`)

## Files Created/Modified

- `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs` - validates capture provenance and stages allowlisted evidence.
- `reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs` - adds upload workflow contracts.
- `scripts/run_demo_browser_evidence.sh` and `scripts/test_run_demo_browser_evidence.sh` - clear stale retained output, validate before install, and prove wrapper behavior.
- `.github/workflows/ci.yml` - success-only retained artifact upload and lock audit in the advisory job.
- `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex` - enforces actual CSS identity at both writer boundaries.
- `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` - tests mismatch rejection and absence of completed proof.
- `mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex` - applies the CI synthetic-mailable allowlist before discovery.
- `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs` - tests CI restrictions and local discovery behavior.
- `reference/demo_app/assets/scripts/check-demo-browser-deps.cjs` and `.test.cjs` - exact offline lock validation and drift/install-order contracts.
- `reference/demo_app/Dockerfile`, `reference/demo_app/mix.exs`, and `compose.demo.yml` - gate the remaining browser install paths.

## Decisions Made

- Keep retained evidence limited to a sanitized checkpoint and the six fixed synthetic PNG pairs.
- Preserve the existing advisory CI classification and 14-day artifact retention.
- Use the checked-in lock’s exact tarball URLs, SRI values, metadata, and dependency edges as frozen source-controlled expectations.

## Deviations from Plan

**1. [Rule 1 - Bug] Corrected the Admin test fixture to represent matching built and served CSS.**
- **Found during:** Task 2 verification.
- **Issue:** Existing valid-capture fixtures used distinct built and served hashes, contradicting the new actual-capture invariant.
- **Fix:** Aligned the success fixture hashes and kept distinct hashes in dedicated rejection cases.
- **Files modified:** `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs`.
- **Verification:** Focused ExUnit passed, 18 tests and 0 failures.
- **Committed in:** `a4b43836`.

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The adjustment makes existing success fixtures represent the proof contract enforced by the new writer invariant.

## TDD Gate Compliance

The three tasks were tagged `tdd="true"`, but execution produced one atomic commit per task and did not produce separate failing-test RED commits or RED evidence records. The focused tests were run after their corresponding changes and passed. This is a TDD process deviation; the plan frontmatter is `type: execute` and project `workflow.tdd_mode` is false.

## Verification

- `node --test reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs` — passed, 10 tests.
- `bash scripts/test_run_demo_browser_evidence.sh` — passed.
- `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/preview/capture_manifest_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --warnings-as-errors --seed 1` — passed, 18 tests and 0 failures.
- `node --test reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs` — passed, 13 tests.
- `node reference/demo_app/assets/scripts/check-demo-browser-deps.cjs --lock-only` — passed.
- `npm --prefix reference/demo_app/assets audit --package-lock-only --audit-level=high` — passed, 0 vulnerabilities.

## Issues Encountered

- The environment initially denied writes to `.git`; the authorized GSD SDK operations succeeded after the narrowly scoped filesystem escalation.
- A read-only smoke attempt against the pre-existing local Playwright report found that it was not from `phase173-evidence.spec.js`; no new browser run was performed as part of the plan’s focused verification commands.

## User Setup Required

None.

## Next Phase Readiness

Plan 04’s deterministic artifact, Admin capture, and package-lock contracts are implemented and verified. Plan 05 can exercise the end-to-end candidate and retained-evidence chain.

---
*Phase: 173-consistency-and-delivery-evidence*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary file exists at the plan output path.
- All three task commits are ancestors of the current HEAD.
