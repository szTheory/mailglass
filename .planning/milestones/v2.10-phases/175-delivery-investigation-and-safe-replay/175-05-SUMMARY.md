---
phase: 175-delivery-investigation-and-safe-replay
plan: "05"
subsystem: ui
tags: [delivery, replay, storybook, playwright, axe, accessibility]
requires:
  - phase: 175-04
    provides: Mounted Delivery failure recovery and exact-target safety proof.
provides:
  - Bounded retained Delivery scenarios using production components, with connected empty-route proof.
  - Representative Northstar and Fjordline pure-fact comparisons to scoped persisted Delivery projections.
  - Current-source responsive, real-zoom, keyboard, contrast and selected Axe evidence.
affects: [175-06, 178, delivery-investigation, replay, accessibility]
actuals:
  tokens: 114938.5
  tasks: 2
  commits: 4
plan_head_before: e9c47c2fc08aadf79ba312e5133cd2dbf002065d
plan_head_after: e3e9b4bf377e580e0cce37e071ebc7d60852a1fb
tech-stack:
  added: []
  patterns: [Existing Playwright and axe-core infrastructure, Chromium tab zoom, production component stories]
key-files:
  created:
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-05-02-red-evidence.json
    - reference/demo_app/assets/e2e/delivery-investigation.spec.js
  modified:
    - reference/persona_spec/quick_view_scenarios.ex
    - reference/persona_spec/quick_view_scenarios.json
    - reference/demo_app/storybook/delivery_investigation.story.exs
    - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
    - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/phase175-inbound.spec.js
    - mailglass_admin/e2e/storybook-axe.spec.js
    - mailglass_admin/e2e/support/storybook-axe-supplement.cjs
    - mailglass_admin/e2e/support/storybook-axe.cjs
    - mailglass_admin/e2e/support/storybook-axe.test.cjs
    - mailglass_admin/docs/storybook-axe-approved.json
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/priv/static/app.css
    - reference/demo_app/dev/mailglass_demo_web/storybook.ex
key-decisions:
  - "Keep empty Helios route-only and never fabricate a selected Delivery record."
  - "Retain Axe incomplete findings separately from violations and add separately identified review runs."
  - "Check every current Axe contrast selector match in the story root and keep the lowest ratio per selector."
  - "Refresh persisted fidelity source identity and executed case inventory when the source changes."
patterns-established:
  - "Bounded scenario declarations drive production-component stories while scoped persisted projections remain the data comparison boundary."
  - "Current-source receipts bind URLs, assets, fonts, theme, hooks, browser zoom and exact executed case IDs to a full digest."
  - "Supplemental contrast and focus evidence never changes Axe incomplete status."
requirements-completed: [UXF-12, OUTUX-07, OUTUX-08, REPLAY-04, REPLAY-05, REPLAY-06, REPLAY-07, REPLAY-08]
coverage:
  - id: D1
    description: Retained complete Delivery and adverse scenarios use production components; Northstar and Fjordline facts match scoped persisted projections, and Helios remains connected-empty.
    requirement: UXF-12
    verification:
      - kind: unit
        ref: mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 175 Northstar and Fjordline facts match scoped Delivery projections
        status: pass
      - kind: e2e
        ref: reference/demo_app/assets/e2e/delivery-investigation.spec.js#Phase 175 retained Delivery scenario inventory and production composition
        status: pass
    human_judgment: false
  - id: D2
    description: Delivery and Inbound layouts pass named narrow, wide, long-text, keyboard and real 200% Chromium tab-zoom checks.
    requirement: REPLAY-06
    verification:
      - kind: automated_ui
        ref: mailglass_admin/e2e/flows.spec.js#Phase 175 connected Delivery layout
        status: pass
      - kind: automated_ui
        ref: mailglass_admin/e2e/phase175-inbound.spec.js#Phase 175 Inbound layout
        status: pass
      - kind: e2e
        ref: reference/demo_app/assets/e2e/storybook-fidelity.spec.js#Phase 175 fidelity: current Delivery story, connected focus, assets, themes and actual zoom
        status: pass
    human_judgment: false
  - id: D3
    description: The selected current-source Axe inventory executes every case and preserves incomplete findings with separately reviewed rendered contrast and focus receipts.
    requirement: REPLAY-06
    verification:
      - kind: automated_ui
        ref: mailglass_admin/e2e/storybook-axe.spec.js#Phase 175 selected Axe
        status: pass
    human_judgment: false
duration: 19min 22s
completed: 2026-10-27
status: complete
---

# Phase 175 Plan 05: Retained Delivery Investigation and Safe Replay Summary

**Bounded retained Delivery scenarios, scoped projection comparisons, and current-source responsive, browser-zoom and Axe evidence across story and connected paths**

## Performance

- **Duration:** 19 minutes 22 seconds
- **Started:** 2026-10-27T17:46:15Z
- **Completed:** 2026-10-27T18:05:37Z
- **Tasks:** 2
- **Files modified:** 18

## Accomplishments

- Retained normal, long-Unicode, stale-suppression, unavailable, unknown-expiry and ambiguous-replay Delivery scenarios with declared identity, source, state, requirements, retention reason and proof boundary. The browser group covered nine retained scenario/connected cases; Helios remained connected-empty.
- Compared representative Northstar and Fjordline pure facts against tenant-scoped persisted projections. The Phase 175 projection test asserted Account, exact identity, values and domain outcomes at the existing production read seam.
- Added named connected Delivery and Inbound layout checks, including target geometry, wrap behavior, no horizontal overflow, dialog action reachability, visible focus and exact focus return.
- Recorded a ten-case Delivery fidelity receipt with current source, Storybook and connected URLs, CSS bytes/hash, six loaded font faces, theme/OS behavior, hook effects and actual Chromium tab zoom.
- Executed the selected Axe inventory across 13 variants and 26 theme cases. The committed current-source run passed 26/26 with zero violations and zero untriaged findings. The report retains 114 Axe incomplete findings, including 64 new Delivery fingerprints; all remain explicitly incomplete and have independent review records with rendered contrast or focus evidence.

## Current-Source Evidence

- Persisted fidelity receipt: reference/demo_app/tmp/demo_browser_evidence/phase175/fidelity.json. Source revision e3e9b4bf377e580e0cce37e071ebc7d60852a1fb; digest 1d20bcbcecd6af9ca1d6d8822c6b902e7a597399dc63ef5598d316c2ab608bbb; 10 selected and 10 executed case IDs.
- Story route: http://127.0.0.1:4015/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode
- Connected route: http://127.0.0.1:4015/ops/mail?delivery_id=01a17e60-a2c5-786f-bb51-79d499f5c0aa&tenant_id=northstar&window_hours=168
- CSS response returned 200 with 137,809 bytes, SHA-256 4f971db6dd8efa8d5b8af9f3ab27aac5f5abd6b3ac8cda6db03dc8af603d1359. Six font assets returned 200 and all six expected faces loaded.
- Real browser zoom used Chromium tab zoom factor 2. Effective CSS viewport and document width were both 320px, with DPR 4. The bounded captures are in reference/demo_app/tmp/demo_browser_evidence/phase175/ and mailglass_admin/test-results/phase175-layout/.
- Final Axe report: mailglass_admin/test-results/phase175-storybook-axe.json, run phase175-05-final-committed-20261027, revision e3e9b4bf377e580e0cce37e071ebc7d60852a1fb, digest 1d20bcbcecd6af9ca1d6d8822c6b902e7a597399dc63ef5598d316c2ab608bbb. The 114 incomplete results remain separate from the zero-violation result.

## Verification

- ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/quick_view_projection_test.exs --only phase175 --trace — 1 Phase 175 test executed, 0 failures; four unrelated tests were excluded by the tag filter.
- ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 175.*layout" — 2/2 Delivery and Inbound layout cases passed.
- ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- --grep "Phase 175 fidelity|Phase 175 retained" — 2/2 browser groups passed; fidelity receipt recorded 10/10 cases.
- ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:storybook-axe -- --grep "Phase 175" — 26/26 cases passed; 0 violations, 114 incomplete, 0 untriaged.
- node --test --test-reporter=tap mailglass_admin/e2e/support/storybook-axe.test.cjs — 24/24 passed.
- ASDF_ELIXIR_VERSION=1.18.4-otp-27 MIX_ENV=dev mix compile in reference/demo_app — passed.
- git diff --check — passed.

## TDD Evidence

The new validator contract for checking every current Axe incomplete before triage first failed because the report contained a new target while supplemental coverage remained empty. After changing the check to derive targets from the current report, the Axe helper suite passed 24/24. The persisted-fidelity assertion also reproduced stale source identity and a one-case persisted inventory; the writer now resets stale receipts and stores all current executed case IDs, verified by the ten-case browser group.

## Task Commits

1. Task 1: retain Delivery investigation scenarios — 644b9435 (feat).
2. Task 2 RED: pin expanded selected Axe inventory — 9eaa586a (test).
3. Task 2 implementation and verification — a65a670d (fix).
4. Current-source receipt and evidence correction — e3e9b4bf (fix).

Plan tracking metadata is recorded in the GSD close-out commit following the summary self-check.

## Files Created/Modified

- reference/demo_app/assets/e2e/delivery-investigation.spec.js — retained story and connected empty-route cases.
- reference/persona_spec/quick_view_scenarios.ex and reference/persona_spec/quick_view_scenarios.json — bounded Delivery source manifest/projection.
- mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs — scoped pure/persisted equality.
- mailglass_admin/e2e/flows.spec.js and mailglass_admin/e2e/phase175-inbound.spec.js — connected responsive and keyboard evidence.
- reference/demo_app/assets/e2e/storybook-fidelity.spec.js — persisted exact current-source/URL/asset/theme/zoom receipt.
- mailglass_admin/e2e/storybook-axe.spec.js and mailglass_admin/e2e/support/storybook-axe*.cjs — strict selected case, contrast and independently identified triage evidence.
- mailglass_admin/docs/storybook-axe-approved.json — exact Delivery incomplete fingerprints and independent evidence run.
- mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex and replay_modal.ex, reference/demo_app/dev/mailglass_demo_web/storybook.ex, reference/demo_app/storybook/delivery_investigation.story.exs, mailglass_admin/priv/static/app.css — production layout, theme/story ownership and narrow-width corrections.
- .planning/phases/175-delivery-investigation-and-safe-replay/175-05-02-red-evidence.json — retained TDD RED evidence.

## Decisions Made

- Keep Storybook declarations synthetic and bounded while comparing selected facts through production-scoped materializers.
- Keep empty Helios route-only rather than manufacturing a selectable record.
- Preserve Axe incomplete findings as incomplete even when separate rendered contrast or focus checks pass.
- Store the newer Axe review run independently so existing triage remains tied to its original evidence basis.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented technical ID overflow at narrow widths**
- **Found during:** Task 2.
- **Issue:** Long provider-event and replay target IDs exceeded the 320px content boundary.
- **Fix:** Allowed the relevant technical identity containers to shrink and break long values; preserved readable action labels.
- **Files modified:** mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex, mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex, mailglass_admin/priv/static/app.css.
- **Verification:** Narrow-width and real-zoom browser cases passed with document width at 320px.
- **Committed in:** a65a670d.

**2. [Rule 2 - Missing Critical] Added the Delivery story’s local theme owner**
- **Found during:** Task 2.
- **Issue:** The Demo Storybook adapter did not claim the Delivery story root and picker under its own theme boundary.
- **Fix:** Added the Delivery story owner/picker mapping and route to the existing Demo-only adapter.
- **Files modified:** reference/demo_app/dev/mailglass_demo_web/storybook.ex, reference/demo_app/storybook/delivery_investigation.story.exs.
- **Verification:** Ten-case fidelity run proved System/light/dark preference, OS changes and explicit preference stability.
- **Committed in:** a65a670d.

**3. [Rule 1 - Bug] Kept supplemental accessibility evidence aligned with current Axe targets**
- **Found during:** Task 2.
- **Issue:** A broad h3 selector matched multiple nodes, untriaged current findings were excluded from contrast checks, and story-root targets could be mistaken for dialog-only targets.
- **Fix:** Check all matching story-root nodes, aggregate the lowest measured contrast conservatively, require supplemental coverage for every current report target, and retain Axe incomplete status.
- **Files modified:** mailglass_admin/e2e/storybook-axe.spec.js, mailglass_admin/e2e/support/storybook-axe-supplement.cjs, mailglass_admin/e2e/support/storybook-axe.cjs, mailglass_admin/e2e/support/storybook-axe.test.cjs, mailglass_admin/docs/storybook-axe-approved.json.
- **Verification:** Full selected 26-case matrix passed with no missing supplemental targets and no untriaged findings.
- **Committed in:** a65a670d and e3e9b4bf.

**4. [Rule 1 - Bug] Bound persisted fidelity receipts to the latest source and cases**
- **Found during:** Task 2 follow-up verification.
- **Issue:** The on-disk receipt retained a previous source identity and only stored the top-level story case instead of all ten executed cases.
- **Fix:** Reset accumulated case IDs when source identity changes, update the source object and persist the full executedCaseIds list; assert the written receipt matches this run.
- **Files modified:** reference/demo_app/assets/e2e/storybook-fidelity.spec.js, mailglass_admin/docs/storybook-axe-approved.json.
- **Verification:** Combined retained/fidelity command passed and persisted 10/10 cases under digest 1d20bcbcecd6af9ca1d6d8822c6b902e7a597399dc63ef5598d316c2ab608bbb.
- **Committed in:** e3e9b4bf.

**Total deviations:** 4 auto-fixed (three Rule 1 bugs, one Rule 2 missing critical behavior).
**Impact on plan:** Corrections tighten the requested current-source proof and fix reproduced narrow-width behavior; no new dependencies or fixture engine were added.

## Issues Encountered

- Initial selected Axe runs stopped on an iframe ID with a duplicated Storybook prefix and on stale/nonmodal metadata; both selectors and the explicit scenario metadata were corrected before the full matrix passed.
- The sandbox could not launch Chromium or create .git/index.lock in the normal mode. The same approved local browser and commit commands succeeded with the required escalation.
- No external auth or user setup was required.

## Next Phase Readiness

Plan 175-05 is complete and Plan 175-06 can proceed. The eight Phase 175 requirement IDs remain pending in REQUIREMENTS.md because Plan 175-06 also declares all eight; mark them complete after the final declaring plan is summarized.

## Self-Check: PASSED

- Summary and all 18 plan-scoped files exist.
- Task commits 644b9435, 9eaa586a, a65a670d and e3e9b4bf are ancestors of the current HEAD.
- All plan verification commands passed; the current-source report has 26/26 executions, zero violations and zero untriaged findings.

