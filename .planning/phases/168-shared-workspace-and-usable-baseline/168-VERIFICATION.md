---
phase: 168-shared-workspace-and-usable-baseline
verified: 2026-10-08T23:14:17Z
status: gaps_found
score: "94/95 plan truths verified; 4/5 roadmap truths verified"
covered_files:
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-01-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-01-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-02-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-02-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-03-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-03-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-04-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-04-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-05-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-05-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-06-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-06-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-07-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-07-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-08-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-08-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-09-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-09-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-REGRESSION.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-REVIEW-DISPOSITION.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-REVIEW.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-SECURITY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-UAT.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-UI-REVIEW.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-VALIDATION.md
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/support/browser-zoom-extension/manifest.json
  - mailglass_admin/e2e/support/browser-zoom-extension/service-worker.js
  - mailglass_admin/lib/mailglass_admin/admin_shell.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/surface_nav.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/admin_shell_test.exs
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/test/support/operator_fixtures.ex
covered_digest: "v3:sha256:908ba2d0d474c489a86fbc49e99fb97306be878977172bde3e97650156fff105"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: "87/92 plan truths; 3/5 roadmap truths"
  gaps_closed:
    - "Actual 200% Chromium zoom clipping of the Account/Appearance controls and complete Delivery detail/timeline values at the verified 720px and combined 320px CSS widths."
    - "Account switching lacked pending feedback while the prior Account and its data remained committed."
  gaps_remaining:
    - "Plan 168-02 D-03: in-scope shared UI still contains 2px spacing utilities despite the approved 4px grid and has no documented exception."
  regressions: []
gaps:
  - truth: "Essential shared-workspace content uses the approved 4px spacing grid (Plan 168-02 D-03)."
    status: failed
    reason: "The accepted UI-SPEC says not to introduce off-grid spacing values. Current shared UI source still contains `mt-0.5` (2px) utilities, and neither the plan nor UI-SPEC grants an optical-alignment exception. The 200% layout/overflow portion of D-03 is now verified; the spacing-grid clause remains false."
    artifacts:
      - path: "mailglass_admin/lib/mailglass_admin/operator/shell.ex"
        issue: "Five current `mt-0.5` utilities create 2px spacing in shared Account/status/help UI."
      - path: "mailglass_admin/lib/mailglass_admin/components.ex"
        issue: "The shared feedback component still uses `mt-0.5` for its status icon."
      - path: "mailglass_admin/lib/mailglass_admin/operator/quick_view.ex"
        issue: "The operator Quick view error treatment still uses `mt-0.5`; it is part of the changed shared workspace."
      - path: "mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex"
        issue: "The shared inbound Quick view error treatment also uses the same off-grid 2px utility."
      - path: "mailglass_admin/lib/mailglass_admin/preview_live.ex"
        issue: "Two shared Preview feedback rows use `mt-0.5` in the phase's appearance/feedback surface."
      - path: "mailglass_admin/lib/mailglass_admin/preview/sidebar.ex"
        issue: "Three scenario-list gaps use `gap-0.5` (2px) in the phase's Preview surface."
    missing:
      - "Replace the in-scope 2px spacing utilities with values on the approved grid, or update the accepted design contract through an explicit owner-approved exception; then rerun the focused spacing and rendered checks."
advisory: []
---

# Phase 168: Shared Workspace and Usable Baseline Verification Report

**Phase Goal:** Operators can use a coherent, readable shared workspace for real tasks, and maintainers can reproduce its baseline and improvements.
**Verified:** 2026-10-08T23:14:17Z
**Status:** Gaps found
**Re-verification:** Yes — the prior gaps report was rechecked after Plan 09.

## Goal Achievement

### Roadmap Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A maintainer can reproduce representative before/after workflows from a compact inventory. | ✓ VERIFIED | `168-BASELINE.md` records the preserved backup and digest, cleanup/reconciled/served revisions, served CSS URL and hash, routes, fixture/persona, theme, viewport/zoom, interaction states, screenshots, observations, and evidence limits. The archive and before/after artifacts exist. |
| 2 | An operator can identify the current surface and Account, navigate a representative task, and retain scope with accurate active navigation. | ✓ VERIFIED | The shared shell renders the committed Account name and full ID; URL patches flow through `handle_params/3` into server-scoped reads. The Account-scope browser test checks URL, old-record clearing, and the scoped new result. Navigation tests and baseline review check active route cues and configured surfaces. |
| 3 | Essential information is readable at narrow and desktop widths and browser zoom, with coherent hierarchy and exact details available. | ✗ FAILED | Plan 09 closes zoom clipping: the current regression checks real tab zoom 2, controls, exact fixture values and geometry at 720 and combined 320 CSS px. However, the remaining 2px `mt-0.5` spacing in shared source directly violates D-03's approved 4px grid; there is no approved exception. This narrow spacing gap blocks the literal criterion. |
| 4 | Shared controls and overlays are operable by keyboard/touch and expose applicable states, status semantics, and focus behavior. | ✓ VERIFIED | The delayed Account-switch regression checks visible `role=status`, `aria-live="polite"`, `aria-atomic="true"`, old Account/data retention while held, and new scope plus cleared pending state after release. Existing browser tests cover keyboard/touch, focus containment/return, target identity, disabled/busy and status states. |
| 5 | One Light/Dark/System preference persists and follows OS changes; feedback and motion remain understandable through updates and reduced motion. | ✓ VERIFIED | Existing browser/component checks cover one selected preference, persistence/navigation/reload, emulated OS changes, reduced motion, and stable repeated LiveView feedback. |

**Roadmap score:** 4/5 truths verified. **Plan truth score:** 94/95 verified; 1 failed.

### Plan Must-Have Audit

All nine PLAN frontmatters and SUMMARYs were checked against current source and evidence. Plans 01–08 retain their earlier verified behavior with regression checks; the prior five failures were reconciled against Plan 09: the zoom clipping, Delivery/timeline readability, and pending Account feedback failures are closed. The only remaining failed truth is Plan 02 D-03's 4px-grid requirement.

| Plan | Truths | Verified | Failed | Evidence / remaining issue |
|---|---:|---:|---:|---|
| 168-01 | 16 | 16 | 0 | Account scope/navigation and reproducible baseline verified; delayed-switch pending status now closes E2/loading. |
| 168-02 | 23 | 22 | 1 | Empty/loading/error/filter/data and exact-value criteria pass. D-03 fails only its explicit 4px-grid clause: in-scope `mt-0.5` remains. Zoom overflow and long-value failures are closed. |
| 168-03 | 22 | 22 | 0 | Appearance, OS selection, feedback, and reduced-motion criteria pass; Plan 09 verifies Appearance radio/label geometry at actual zoom. |
| 168-04 | 14 | 14 | 0 | Quick view/replay identity, focus, authorization, motion, and evidence are wired and covered by named browser/LiveView tests. |
| 168-05 | 3 | 3 | 0 | Exact Mailable text, generated wrapping CSS, and four CSS-width geometry checks pass. |
| 168-06 | 5 | 5 | 0 | Downstream Delivery outcomes render across table/card/detail/Quick view; real zoom is distinguished from CSS viewport captures. |
| 168-07 | 6 | 6 | 0 | Tenant/window cache scope and both retryable transient confirmation reads have tagged regressions. |
| 168-08 | 3 | 3 | 0 | Preview's rendered dismissal clears its actual `:info` flash entry. |
| 168-09 | 3 | 3 | 0 | Actual zoom/control/value geometry and delayed Account-switch pending/commit transitions pass the final focused browser run. |

### Required Artifacts

The CLI artifact check for Plans 01–08 reports **32/32 present and substantive**. Plan 09 expresses its artifact expectations as prose rather than path objects, so the CLI returned not applicable (0 declared artifacts); its current source artifacts were checked directly.

| Artifact group | Status | Evidence |
|---|---|---|
| Shared shell, route/scope, filter and navigation artifacts | ✓ VERIFIED | LiveView calls the shared shell; shell option links patch the URL; the route handler resolves the new scope. Component and browser tests exercise these paths. |
| Source and generated CSS | ✓ VERIFIED as wired | `assets/css/app.css` owns shared tokens/rules, `priv/static/app.css` is the generated bundle, and browser tests inspect computed style and rendered geometry. The bundle contains the source changes. |
| Appearance, feedback and overlays | ✓ VERIFIED | Shared components are used by operator/preview LiveViews; existing browser and LiveView tests cover selection, dismissal, focus and status. |
| Delivery values/status and current zoom tests | ✓ VERIFIED | Detail/list/Quick view call the downstream status helper; Playwright asserts real fixture values and exact browser zoom/geometry. |
| Account pending feedback | ✓ VERIFIED | `operator/shell.ex` renders a polite atomic status for the target option; `flows.spec.js` checks it during a held server patch and after commit. |
| Shared spacing | ✗ FAILED (one D-03 clause) | Source contains 2px `mt-0.5` utilities with no accepted exception; see gap. |

### Key Link Verification

The CLI string-reference checker returned false for declared links because Elixir component calls and CSS build relationships do not quote destination file paths. Manual source tracing found the required links intact; the automated false negatives are not treated as broken wiring.

| Link group | Status | Evidence |
|---|---|---|
| LiveViews → shared shell → Account URL patch → server scope | ✓ WIRED | `OperatorLive` and `InboundLive` pass scope/labels/options; `tenant_switch_path/2` creates the patch; `handle_params/3` reloads the server scope. |
| Shared nav → configured destinations and committed active cue | ✓ WIRED | `SurfaceNav` filters destinations by configuration and availability; shell renders links and active-route semantics. |
| Theme picker → existing preference/cookie → root theme and CSS | ✓ WIRED | Native radio values use the existing persistence route; root choice remains distinct from OS-derived effective theme. |
| LiveViews → Quick view/replay → authorization and exact target | ✓ WIRED | URL-selected record drives Quick view; confirmation uses existing action-time authorization/recent-auth and exact-target checks. |
| HEEx/CSS source → generated static bundle → browser assertions | ✓ WIRED | Mix asset build produces the bundle; Playwright inspects computed wrapping and geometry from the served app. |
| Data status helper → list/detail/Quick view badges | ✓ WIRED | `Components.delivery_display_status/1` feeds each presentation; rendered component tests cover downstream states without mutating stored status. |
| Preview flash → shared dismissal control → LiveView clear-flash | ✓ WIRED | Preview passes `flash_key={:info}` while retaining success styling; `g_168_8` activates the actual control and checks subsequent render. |
| Account option → pending status → old/new committed scope | ✓ WIRED | `JS.show` targets an enumerated numeric option index; browser holds the real LiveView reply and checks both sides of completion. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data? | Status |
|---|---|---|---|---|
| Health/Delivery content | Scoped records and observations | URL-resolved tenant plus host-owned read models | Yes; ExUnit and browser fixtures render populated records | ✓ FLOWING |
| Account context | ID, label, permitted host options | LiveView assigns and host Account selector | Yes; Account-scope case checks the selected ID and scoped result | ✓ FLOWING |
| Delivery status/details/timeline | Latest recorded events and exact identifiers/times | Selected persisted Delivery/event records and `delivery_display_status/1` | Yes; rendered outcome tests and deterministic Playwright fixture values | ✓ FLOWING |
| Preview feedback | Phoenix `:info` flash | Preview reload LiveView message | Yes; `g_168_8` clicks dismiss and checks later render | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Evidence/command | Result | Status |
|---|---|---|---|
| True 200% zoom and controls/exact values at 720 CSS px and combined 320 CSS px | `168-VALIDATION.md`: final named run of `Phase 168 Delivery Mailable wrapping` and `Phase 168 Account scope` | 2 passed, 0 failed; zoom readback 2, visible radio-label geometry, exact fixture values and overflow assertions | ✓ PASS |
| Delayed Account switch keeps old identity/data paired, announces pending, then commits new scope | `flows.spec.js#Phase 168 Account scope`; included in final focused 2/2 and full suite | Pending visible and polite/atomic while held; new URL/scope appears and status clears after release | ✓ PASS |
| Admin/component/LiveView regression suite | `168-REGRESSION.md`: `mix test --seed 1` from `mailglass_admin` | 542 tests, 0 failures, 1 excluded | ✓ PASS |
| Operator browser suite | `168-REGRESSION.md`: `npm run test:operator-browser` | 198 passed, 0 failed, 1 existing guarded skip | ✓ PASS |

The operator-browser CI job remains advisory and outside CI Green, per D-52. The reported local runs are deterministic evidence; no owner UAT is requested for these machine-observable criteria.

### Probe Execution

Not applicable. Phase 168 is a product UI phase and declares no migration/tooling probes.

### Requirements Coverage

All eight UXF IDs are mapped to Phase 168 in ROADMAP.md/REQUIREMENTS.md and are claimed by at least one plan frontmatter. No requirement ID assigned to this phase is orphaned.

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| UXF-01 | 168-01, 168-04 | ✓ SATISFIED | Preserved workspace archive, source-identified before/after inventory, and current served CSS identity in `168-BASELINE.md`. |
| UXF-02 | 168-01, 168-04, 168-07 | ✓ SATISFIED | URL-backed server scope, navigation cues, record clearing, and cross-tenant cache isolation are tested. |
| UXF-03 | 168-02, 168-05, 168-06, 168-09 | ✗ BLOCKED | Real zoom readability is now verified at 720/320 CSS px, but Plan 02 D-03's explicit spacing-grid clause is still violated by 2px utilities. |
| UXF-04 | 168-02, 168-03, 168-04, 168-07, 168-08, 168-09 | ✓ SATISFIED | Applicable control states, appearance labels, focus/overlay behavior, dismissal and pending status have current source/test evidence. |
| UXF-05 | 168-03 | ✓ SATISFIED | Exactly one saved choice persists; System follows emulated OS scheme without replacing the selection. |
| UXF-06 | 168-01, 168-02, 168-03, 168-04, 168-06, 168-07 | ✓ SATISFIED | Domain copy, unavailable/stale distinctions and downstream outcomes preserve observed facts; exact evidence stays available. |
| UXF-07 | 168-01, 168-03, 168-04, 168-07, 168-08 | ✓ SATISFIED | Keyboard/touch navigation, focus containment/return, exact targets and status cues are covered by existing browser/LiveView checks. |
| UXF-08 | 168-03, 168-04, 168-07, 168-08, 168-09 | ✓ SATISFIED | Feedback remains prompt and understandable, including held Account patches, reduced motion and LiveView updates. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` | 331, 354, 384, 400, 452 | `mt-0.5` (2px) | 🛑 BLOCKER for D-03 | Five off-grid spacing values in shared Account/status/help chrome. |
| `mailglass_admin/lib/mailglass_admin/components.ex` | 773 | `mt-0.5` (2px) | 🛑 BLOCKER for D-03 | Shared feedback icon remains off-grid. |
| `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` | 91 | `mt-0.5` (2px) | 🛑 BLOCKER for D-03 | Changed shared workspace error treatment remains off-grid. |
| `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` | 85 | `mt-0.5` (2px) | 🛑 BLOCKER for D-03 | Shared Inbound error treatment remains off-grid. |
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | 464, 475 | `mt-0.5` (2px) | 🛑 BLOCKER for D-03 | Shared Preview feedback rows remain off-grid. |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | 173, 212, 226 | `gap-0.5` (2px) | 🛑 BLOCKER for D-03 | Shared Preview scenario-list spacing remains off-grid. |
| `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` | 49 | `gap-2xs` has no generated CSS rule | ⚠️ WARNING | UI review flagged an undefined spacing utility. This is outside the Phase 168 shared-shell/content changes and is not counted as a blocker. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in reviewed source. The phase-scope files contain no stubbed rendered path or empty data source. The 2px uses are deliberate code, but intent is not an accepted exception to the D-03 contract.

### Human Verification Required

None. The remaining spacing mismatch is directly inspectable and machine-verifiable; D-52 says not to send deterministic acceptance back as owner UAT. The advisory UI review notes do not block phase progress on their own.

### Non-blocking UI Review Observations

The current UI review also flags the unselected-state overview CTA, informational uses of the reserved accent, the undefined `gap-2xs` utility, and qualitative accent-area balance. These remain visible review notes, separate from the explicit D-03 blocker above. The Plan 09 actual-zoom geometry and pending-state failures are closed; those UI warnings were not used to inflate the blocking gap count.

### Gaps Summary

Plan 09 closes both prior behavioral gaps with passing current browser assertions and full regression evidence. Essential content and controls now reflow at true 200% zoom, and a delayed Account switch announces progress while keeping old-scope data correctly paired until commit. One explicit must-have remains unmet: the shared source uses several 2px `mt-0.5` spacing utilities against the UI-SPEC's 4px grid, without an approved exception. UXF-03 and roadmap criterion 3 therefore remain blocked until that contract gap is resolved.

---

_Verified: 2026-10-08T23:14:17Z_  
_Verifier: the agent (gsd-verifier)_
