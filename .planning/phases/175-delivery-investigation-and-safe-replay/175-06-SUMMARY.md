---
phase: 175-delivery-investigation-and-safe-replay
plan: "06"
subsystem: testing
tags: [playwright, axe, node-test, github-actions, replay, evidence]
requires:
  - phase: 175-05
    provides: retained Delivery scenarios, current selected Axe cases, Storybook fidelity and current UI acceptance surface
provides:
  - Existing durable Demo replay asserts an accessible actual-outcome toast and persisted no-change audit result
  - Composable Phase 175 browser selection and fail-closed source-bound receipt checker with negative controls
  - Current cold/warm artifacts, exact requirement and acceptance mappings, reproduction commands, CI placement and measured local limits
affects: [phase-178-storybook-fidelity, delivery-replay, browser-evidence]
actuals:
  tokens: 677680
  tasks: 3
  commits: 15
plan_head_before: 12e9a71b5cb0b758c231598ffe710aaecac41616
plan_head_after: dc41805a6272e5e43625005ac8aa4e6a634b2ab8
tech-stack:
  added: []
  patterns: [exact expected/executed case identities, source and asset digests, run-owned serial cold/warm evidence, fail-closed receipts]
key-files:
  created:
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-06-SUMMARY.md
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md
    - .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175/phase175/execution.json
    - .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175/axe-history/
    - mailglass_admin/docs/phase175-review.md
  modified:
    - reference/demo_app/assets/e2e/outbound-replay.spec.js
    - scripts/run_demo_browser_evidence.sh
    - scripts/check_phase175_evidence.cjs
    - scripts/check_phase175_evidence.test.cjs
    - scripts/gsd-regression-gate.sh
    - .github/workflows/ci.yml
    - reference/persona_spec/quick_view_scenarios.json
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-VALIDATION.md
key-decisions:
  - "Keep Phase 175 selection composable with the existing Phase 174 runner and validate explicit reports, source inputs, URLs, assets, and actual case IDs."
  - "Keep the existing Demo Browser Evidence job advisory and preserve every existing required-context meaning."
  - "Retain Axe incomplete findings as incomplete, preserve failed historical evidence, and record rendered contrast triage separately."
  - "Use the isolated mailglass_demo_phase175_05 database because the default Demo database had a migration ledger but lacked the Demo schema."
patterns-established:
  - "Receipt validity requires nonempty exact expected/executed IDs and current source/asset identity; process exit alone is not proof."
  - "Cold/warm Demo, Admin, fidelity, and Axe evidence is serialized under one owned Compose project with explicit cleanup receipts."
requirements-completed: ["UXF-12","OUTUX-07","OUTUX-08","REPLAY-04","REPLAY-05","REPLAY-06","REPLAY-07","REPLAY-08"]
coverage:
  - id: D1
    description: "Delivery and Inbound full-detail technical evidence remains visible with bounded long-value and real-zoom proof."
    requirement: UXF-12
    verification:
      - kind: integration
        ref: "175-06-03: focused Admin/auth ExUnit command (353 tests, 0 failures)"
        status: pass
      - kind: automated_ui
        ref: "artifacts/phase175/phase175/execution.json: Admin 10/10 and fidelity 10/10 per cold/warm condition"
        status: pass
    human_judgment: false
  - id: D2
    description: "Account-scoped suppression refresh preserves stale/unavailable distinctions and truthful expiry/removal wording."
    requirement: OUTUX-07
    verification:
      - kind: integration
        ref: "175-06-03: focused Admin/auth ExUnit command (353 tests, 0 failures)"
        status: pass
      - kind: automated_ui
        ref: "flows.spec.js: Phase 175 suppression refresh; retained cold/warm Admin case receipts"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unknown suppression expiry and read-only removal policy remain distinct and accurate."
    requirement: OUTUX-08
    verification:
      - kind: integration
        ref: "175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08"
        status: pass
    human_judgment: false
  - id: D4
    description: "Exact Delivery and Inbound selection enters the proper replay review without falling back to another record."
    requirement: REPLAY-04
    verification:
      - kind: integration
        ref: "focused Admin/auth ExUnit; retained Phase 175 Admin 10/10 cold/warm reports"
        status: pass
    human_judgment: false
  - id: D5
    description: "Unavailable, stale, denied, and ambiguous replay targets retain their exact safety reasons."
    requirement: REPLAY-05
    verification:
      - kind: automated_ui
        ref: "flows.spec.js: Phase 175 Delivery safety; Phase 175 Axe scenario/state IDs"
        status: pass
    human_judgment: false
  - id: D6
    description: "Shared replay review has accessible close controls, Escape handling, focus containment, and trigger return."
    requirement: REPLAY-06
    verification:
      - kind: automated_ui
        ref: "flows.spec.js and phase175-inbound.spec.js: Phase 175 replay and focus cases"
        status: pass
    human_judgment: false
  - id: D7
    description: "Successful replay announces the actual result and retains the durable Demo audit outcome."
    requirement: REPLAY-07
    verification:
      - kind: e2e
        ref: "outbound-replay.spec.js: outbound replay from the demo completes and records a durable no-change outcome"
        status: pass
      - kind: automated_ui
        ref: "Phase 175 Demo reports: 4/4 cases each cold/warm; exact case ID retained in execution.json"
        status: pass
    human_judgment: false
  - id: D8
    description: "Replay failure stays visible with safe recovery and duplicate/stale confirmation protection."
    requirement: REPLAY-08
    verification:
      - kind: integration
        ref: "focused Admin/auth ExUnit; retained Phase 175 Delivery recovery and Inbound confirmation cases"
        status: pass
    human_judgment: false
  - id: D9
    description: "Phase 175 receipts reject missing, zero, malformed, duplicate, unexpected, skipped, failed, stale, and wrong-source evidence."
    verification:
      - kind: unit
        ref: "node --test scripts/check_phase175_evidence.test.cjs (5 passed, 0 failed, 0 skipped)"
        status: pass
      - kind: other
        ref: "node scripts/check_phase175_evidence.cjs --evidence-dir .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175 --pilot"
        status: pass
    human_judgment: false
metrics:
  duration: "2h 01m from first recorded task commit"
  completed: 2026-10-27
  status: complete
---

# Phase 175 Plan 06: Delivery Investigation and Safe Replay Summary

**Source-bound cold/warm Delivery and Inbound evidence now validates exact replay outcomes, accessible toast behavior, fidelity, and fail-closed case receipts.**

## Performance

- **Duration:** 2h 01m, measured from the first recorded Task 1 commit because the pre-commit executor start timestamp was not retained.
- **Started:** 2026-10-27T18:16:48Z (first recorded Task 1 commit).
- **Completed:** 2026-10-27T20:18:26Z.
- **Tasks:** 3.
- **Files modified:** 180 plan files, including this summary; state/roadmap/requirements tracking is handled separately.
- **Measured plan commits:** 15 from `plan_head_before` through `plan_head_after`; the final GSD metadata commit is separate.

## Accomplishments

- Extended the existing successful Demo replay proof to assert its accessible actual-result toast and the persisted no-change audit outcome, preserving the existing reset-token, grant, and authorization-actions guards.
- Added composable `--phase175` selection to the isolated Phase 174 evidence runner, source and asset receipts, and a narrow checker that requires exact nonzero expected/executed IDs and rejects missing, malformed, duplicate, unexpected, skipped, failed, stale-source, and wrong-source evidence.
- Wired five checker tests into the existing regression gate and the existing advisory Demo Browser Evidence CI job without changing required-context meanings or adding dependencies.
- Retained the final current-source cold/warm evidence, three historical Axe records, exact selected/executed inventories, screenshots, URLs, assets, and cleanup receipts; mapped all eight assigned requirements, 31 edge rows, and 29 UI rows to proof.
- Recorded reproduction steps, source identity, local attributable runtime, CI placement, database posture, and evidence limits in the review and automation documents.

## Current-Source Evidence

The final combined run is `mailglass-evidence-20261027200450-16960-29407`, produced at source revision `8cd973774c293cc3d95b1e8f9be489b5e4ca5caa`. Its Phase 175 source digest is `77fdd45e830c44b07e1062af584414eb4d2c07f2747a7607aa47866cbf81153b`; the Phase 174 digest is `6ee30730cda7c54ebce77fce0561bf6b6f729afb841f326670cb607345435a06`. The post-run documentation commit does not modify any selected source or asset input, and the retained receipt checker validates their current bytes.

Both cold and warm conditions executed all declared cases once: Demo 4/4, connected Admin 10/10, fidelity 10/10, and Axe 26/26. Delivery and Inbound each completed six layout cases across 320, 375, 768, 1280, and 1440 CSS-pixel widths, including actual 200% browser zoom. The combined runner exited 0, validated both conditions, removed the owned Compose project and volumes, and retained the final `execution.json` as valid.

Current cold and warm Axe reports each have 0 violations and 116 incomplete findings, with 0 untriaged findings. These findings remain incomplete and are not described as a clean accessibility pass. The historical 114 report, the failed 116 report with two untriaged fingerprints, and an independent 116 report remain separate under `artifacts/phase175/axe-history/`. The failed report contains exactly two additions over the earlier 114: `color-contrast` on `.min-w-0:nth-child(2) > .mono.mt-1.break-all` for `delivery-investigation-northstar-normal`, state `normal-permitted-review`, in Light and Dark. Phase 175-01 made grouped technical details visible by default, exposing the provider event ID. Independent rendered sampling measured 17.3939:1 Light and 14.0910:1 Dark at 16px/400 against a 4.5:1 minimum; these samples explain the triage and do not change Axe's incomplete result.

The story route is `http://demo:4015/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode`. The connected cold and warm Account routes, production CSS URL and hash, all six font URLs and hashes, inline `about:srcdoc` mode/origin, source hashes, and exact case IDs are retained in the cold/warm reports. The CSS hash is `4f971db6dd8efa8d5b8af9f3ab27aac5f5abd6b3ac8cda6db03dc8af603d1359`; every font face loaded with the expected hash.

## Verification

- `bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot` — exit 0; cold/warm scopes complete, exact expected cases executed, Axe incompletes accounted separately, teardown verified.
- `node scripts/check_phase175_evidence.cjs --evidence-dir .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175 --pilot` — exit 0; final receipt valid against current selected-source files.
- `node --test scripts/check_phase175_evidence.test.cjs` — 5 passed, 0 failed, 0 skipped.
- `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/auth_actions_contract_test.exs` — 353 tests, 0 failures.
- `bash scripts/gsd-regression-gate.sh` — passed Node contracts 40/40, core renderer 81/81, Admin LiveView/component 658 tests (0 failures, 1 excluded), Inbound deterministic 480 tests (0 failures, 3 excluded), and connected Operator/Preview 31/31.
- `git diff --check` — passed.

The current durable Demo no-change case ran in both cold and warm selected reports and asserted the accessible toast plus persisted actual audit result. The browser test dependency install/download occurred in the isolated evidence runtime; no package or version changes were made.

## Runtime, Placement, and Limits

The runner attributes 45,255 ms (0.75425 minutes) to the incremental Phase 175 selection: 24,219 ms cold, 20,937 ms warm, plus checker overhead. This is local incremental wall time, not total combined-workflow time or a hosted runner-minute measurement. It is within the provisional five-minute added PR wall allowance; the provisional ten-minute runner limit has not been measured in hosted CI. The existing `Demo Browser Evidence (Docker Compose / Chromium)` job runs the combined selector and uploads its artifact, but remains advisory and outside required branch-protection contexts. No hosted run or hosted cost is claimed.

The default Demo database had a migration ledger but lacked the Demo schema, so the run used the isolated `mailglass_demo_phase175_05` database. The default database was not repaired or modified. Teardown completed in 2,286 ms and removed owned volumes. Evidence covers the declared Chromium, theme, state, viewport, and selected-action inventory; it does not establish support for all browsers, operating systems, devices, or every viewport/theme combination. No provider delivery is claimed by the durable no-change toast or audit result.

Machine-observable acceptance closes under METHODOLOGY D-52 without owner UAT. Eight descriptor-less prohibition-recall flags remain `flagged-unverified`; no check descriptor was invented. Final STORY-07/UIQ ownership remains in Phase 178. No merge, release, publication, or deployment was performed.

## Task Commits

1. Task 1: `3fe56768` Demo toast and durable no-change test; `4806e74c` inbound replay toast assertion.
2. Task 2: `f8ddc027` failing receipt controls; `c6037ef7` receipt checker; `d866c879` runner/CI/regression integration; `a36a2e55`, `7d5244f7`, `65ee8c3c`, `0967a07f`, and `dcee5ee5` current source, iframe, and Axe schema alignment.
3. Task 3: `3b212e05` feedback proof pointers; `6cdbf484` feedback status contract; `dc41805a` final cold/warm artifacts and documentation.
4. Phase integration fixes: `5d581f90` and `8cd97377`.

## Decisions Made

- Kept Phase 175 narrow and composable with the existing isolated Phase 174 runner and CI lane.
- Required actual receipt case IDs and file/asset identities; did not infer proof from exit status.
- Kept incomplete Axe findings and failed history visible as such.
- Kept CI advisory and the existing required-context meanings unchanged.
- Recorded the isolated database choice instead of altering the default Demo database.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Reconciled the Phase 174/170 regression contract with Phase 175 visible technical details.**
- **Found during:** Task 2 full regression gate.
- **Issue:** The previous cohort assertion required technical details to be collapsible, while Phase 175-01 intentionally made the technical container visible without expansion. The regression gate also exposed stale Phase 170 copy/close assertions, a missing frozen `review_id`, and an unused helper warning under warnings-as-errors.
- **Fix:** Updated only the affected test contracts and fixtures to assert the visible technical container/content and current copy, accessible Close, retain-on-error, actual success toast, run-count update, and valid review identity; removed the now-unused helper. Production behavior was not changed by this integration repair.
- **Files modified:** `reference/demo_app/assets/e2e/cohort.spec.js`, `mailglass_admin/e2e/phase170-journey.spec.js`, `mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`, `mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs`, `mailglass_admin/test/mailglass_admin/voice_test.exs`.
- **Verification:** Focused ExUnit 25 tests passed; focused Phase 170 browser selection 6/6 passed; full regression gate passed.
- **Committed in:** `5d581f90`, `8cd97377`.

The retained current report schema and current source manifest required narrow tuple, asset inventory, iframe `srcdoc` parent-origin, and Axe fixture alignment during implementation. These refinements preserve exact case/source requirements and are documented in the task commits. Browser launch initially failed under the sandbox's local Mach-port restriction; the authorized escalated run completed successfully. No package/version change or new trust-boundary endpoint was introduced.

**Total deviations:** 1 regression integration repair, with scoped report-schema alignment refinements.
**Impact on plan:** All planned scopes completed; the combined gate now validates the Phase 175-01 UI contract. No unrelated files were staged.

## TDD Gate Compliance

- **RED:** `artifacts/phase175/tdd-red-175-06-02.json` preserves the target TAP assertion failure: the validator scaffold did not yet reject an empty expected case set.
- **GREEN:** `c6037ef7` implemented the Phase 175 receipt checker; the final five checker tests pass against representative actual cold/warm reports and negative controls.
- **REFACTOR:** The checker and receipt contracts were aligned with the actual source/asset manifests and report shape without relaxing missing, skipped, failed, zero-case, or wrong-source rejection.
- Task 3 adds documentation and evidence; all current source suites and the full regression gate passed.

## Issues Encountered

- The default Demo database retained a migration ledger without the Demo schema. The runner used the pre-established isolated `mailglass_demo_phase175_05` database, with the default left untouched.
- The sandboxed browser could not establish its local Mach-port rendezvous; authorized escalated execution completed cold/warm evidence and teardown.
- Existing warnings about missing Oban/background maintenance and the QuickViewScenarios boundary were emitted by tests but did not fail any verification.

## Known Stubs

None found in the files created or modified by this plan. The generated evidence's empty/nullable fields represent actual bounded missing facts and are not UI placeholders.

## User Setup Required

None.

## Next Phase Readiness

Phase 178 retains STORY-07/UIQ fidelity follow-up. The Phase 175 assigned requirements, edge acceptance, visible UI proof, source-bound cold/warm reports, and replay result contract are ready for phase-level verification.

---
*Phase: 175-delivery-investigation-and-safe-replay*
*Completed: 2026-10-27*

## Self-Check: PASSED

All referenced summary, automation, review, current run, Phase 174, and Axe history artifacts exist and are nonempty. All 15 measured plan commits are ancestors of HEAD; the retained Phase 175 checker and reports passed before closeout.
