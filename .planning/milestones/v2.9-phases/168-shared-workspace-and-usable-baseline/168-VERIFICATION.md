---
phase: 168-shared-workspace-and-usable-baseline
verified: 2026-10-09T00:25:38Z
status: passed
score: "96/96 plan truths; 5/5 roadmap truths"
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
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-10-PLAN.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-10-SUMMARY.md
  - .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/support/browser-zoom-extension/manifest.json
  - mailglass_admin/e2e/support/browser-zoom-extension/service-worker.js
  - mailglass_admin/lib/mailglass_admin/admin_shell.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
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
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/test/support/operator_fixtures.ex
covered_digest: "v3:sha256:f8585eef6102417959dfed4c469d05ee2d2d1691ae56de95654e834d5fa7741b"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: "96/96 plan truths; 5/5 roadmap truths"
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 168: Shared Workspace and Usable Baseline Verification Report

**Phase Goal:** Operators can use a coherent, readable shared workspace for real tasks, and maintainers can reproduce its baseline and improvements.
**Verified:** 2026-10-09T00:25:38Z
**Status:** Passed
**Re-verification:** Yes — refreshed after the Plan 10 spacing gap closure; prior passing truths were rechecked.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A maintainer can reproduce representative before/after workflows from a compact inventory. | ✓ VERIFIED | `168-BASELINE.md` identifies preserved workspace, revisions, served CSS URL/hash, routes, fixture/persona, theme, viewport/zoom, interaction states, screenshots, observations, and evidence limits. |
| 2 | An operator can identify the current surface and Account, navigate a representative task, and retain scope with accurate active navigation. | ✓ VERIFIED | Shared shell and route handling are exercised by the Account-scope browser flow; server-scoped reads and changed URLs are checked. The recorded Admin/browser regression runs pass. |
| 3 | Essential information is readable at narrow and desktop widths and browser zoom, with coherent hierarchy and exact details available. | ✓ VERIFIED | Existing width/zoom assertions cover actual 200% tab zoom and complete Delivery values. The spacing guard now finds no off-grid spacing in seven shared templates; focused computed-style checks prove operator, Inbound, and Preview values are 4px. |
| 4 | Shared controls and overlays are operable by keyboard/touch and expose applicable states, status semantics, and focus behavior. | ✓ VERIFIED | Existing browser and LiveView checks cover focus, keyboard/touch paths, target identity, status semantics, disabled/busy states, and focus containment/return. The delayed Account-switch browser flow covers pending and committed scope. |
| 5 | One Light/Dark/System preference persists and follows OS changes; feedback and motion remain understandable through updates and reduced motion. | ✓ VERIFIED | Existing browser/component regression checks cover the selected preference, persistence/reload, OS changes, reduced motion, and LiveView feedback/dismissal. |

**Score:** 5/5 roadmap truths verified; 96/96 plan truths verified.

### Re-verification and Plan Must-Have Audit

The prior verification failed one clause of Plan 168-02 D-03: multiple shared templates used 2px spacing, including an unsupported `gap-2xs` in the Inbound evidence card. Plan 10 changed the relevant utilities and expanded the regression protection. Current inspection finds no `0.5` or `2xs` spacing utilities in the seven protected templates: operator shell, shared components, operator Quick view, Inbound Quick view, Inbound evidence card, Preview LiveView, and Preview sidebar.

The guard in `token_parity_test.exs` checks half-step and unsupported `2xs` margin/padding/gap/space classes; adverse examples cover negative values, named and arbitrary variants, nested variants, and slash-qualified variants. It asserts the source token is 4px and the generated `.mt-xs` and `.gap-xs` rules resolve through that token. The focused ExUnit test passed: 4 tests, 0 failures, 3 excluded. The focused Playwright test passed: operator icon `margin-top`, Inbound evidence row `row-gap`, and Preview scenario row `row-gap` each computed to 4px.

Plans 168-01 through 168-09 retain their previous passing evidence and regression checks. Plan 168-10's source scan and runtime checks close the only carried gap. Aggregate plan score: 96/96; roadmap score: 5/5.

This refresh followed the prior passing verification. The subsequent changes in Plans 168-05, 168-06, and 168-10 are wording/file-reference corrections; implementation, test files, and regression evidence have not changed since the prior pass. Their current contents and the affected Inbound spacing source/test paths were inspected again.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` | Inbound reveal spacing on approved token | ✓ VERIFIED | Unsupported `gap-2xs` replaced with the existing 4px utility; rendered row gap measured at 4px. |
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | Seven-template guard and source/generated CSS parity | ✓ VERIFIED | Named test passed; scans all seven paths and asserts token-backed generated utilities. |
| `mailglass_admin/e2e/flows.spec.js` | Browser checks for computed spacing | ✓ VERIFIED | Focused Playwright test passed all three rendered measurements. |
| `mailglass_admin/assets/css/app.css` and `mailglass_admin/priv/static/app.css` | Source and served 4px spacing utility rules | ✓ VERIFIED | Source declares `--spacing-xs: 4px`; built bundle defines token-backed `.mt-xs` and `.gap-xs`; browser read computed 4px values. |
| Shared shell, navigation, filters, details, overlays, and baseline inventory | Working shared operator workspace with real scoped data and reproducible evidence | ✓ VERIFIED | Prior plan audit plus the phase regression gate and current targeted tests. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Shared HEEx templates | `token_parity_test.exs` | Enumerated source paths and utility matcher | WIRED | Seven templates are explicitly read and checked. |
| `assets/css/app.css` | `priv/static/app.css` | Mix asset build and parity assertions | WIRED | Source token and generated utility rules are asserted. |
| Rendered operator, Inbound, Preview fixtures | Computed styles | Existing operator-browser Playwright lane | WIRED | A focused browser test reads all three computed style values from served UI. |
| OperatorLive scope and shell | Scoped workspace route/data | URL patch, `handle_params/3`, scoped reads | WIRED | Account selection, committed scope, and rendered result are exercised by existing browser checks. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Operator/Inbound/Preview rendered acceptance | Computed margin and row gaps | Served HTML plus generated CSS in browser fixture | Yes | ✓ FLOWING |
| Shared operator workspace | Account scope and records | Server-resolved route and scoped reads | Yes | ✓ FLOWING |

Spacing tokens are configuration/style inputs, not database-backed values; their source-to-generated-to-computed-style chain is verified above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Seven shared templates reject off-grid classes and generated spacing maps to 4px | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/token_parity_test.exs:109 --seed 1` | 4 tests, 0 failures, 3 excluded | ✓ PASS |
| Operator, Inbound evidence, and Preview rendered spacing is 4px | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4103 npx playwright test e2e/flows.spec.js --grep 'Phase 168 shared spacing: operator, Inbound reveal, and Preview gaps use 4px' --workers=1` | 1 passed; three computed styles each equaled `4px` | ✓ PASS |
| Phase-wide Admin and operator-browser regression | Commands and evidence in `168-REGRESSION.md` | Admin: 551 tests, 0 failures, 1 excluded. Browser: 199 passed, 1 existing guarded skip, 0 failed. | ✓ PASS |
| Root core suite | Command and output in `168-REGRESSION.md` | Non-green: 2,200 tests, 10 failures, 9 invalid; reported setup, fixture, and sandbox issues are outside Phase 168 source scope. | ℹ️ NOT PHASE-BLOCKING |

### Probe Execution

Not applicable. Phase 168 does not declare or imply a `probe-*.sh` verification probe.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| UXF-01 | 168-01 | Reproducible current/refined workflow inventory | ✓ SATISFIED | `168-BASELINE.md` and preserved before/after artifacts. |
| UXF-02 | 168-01, 168-07 | Account/surface orientation and scope-safe navigation | ✓ SATISFIED | Shared shell, URL patch, scoped read tests, Account-switch browser flow. |
| UXF-03 | 168-02, 168-05, 168-06, 168-09, 168-10 | Readable type, spacing, responsive values, and zoom | ✓ SATISFIED | Source/CSS guard, focused 4px rendered test, and actual 200% zoom/value browser checks. |
| UXF-04 | 168-02, 168-03, 168-04, 168-07, 168-08, 168-09 | Shared control states and operability | ✓ SATISFIED | Browser and LiveView control/state/focus checks. |
| UXF-05 | 168-03 | Persistent Light/Dark/System preference | ✓ SATISFIED | Appearance selection, reload, navigation, and OS-change checks. |
| UXF-06 | 168-01, 168-02, 168-04, 168-06, 168-07 | Accurate domain language and exact investigation detail | ✓ SATISFIED | Shared copy/detail behavior, scoped evidence fallbacks, and Delivery status/wrapping tests. |
| UXF-07 | 168-01, 168-03, 168-04, 168-07, 168-08 | Keyboard/touch navigation, overlays, focus, and status | ✓ SATISFIED | Existing browser and LiveView checks for names, targets, focus, status, and dismissal. |
| UXF-08 | 168-01, 168-03, 168-04, 168-07, 168-08, 168-09 | Prompt understandable feedback and reduced motion | ✓ SATISFIED | Pending scope, retry, flash dismissal, LiveView update, and reduced-motion checks. |

All eight Phase 168 requirements map to one or more phase plans; no orphaned Phase 168 requirement was found.

### Decision Coverage

The GSD decision-coverage check found all 11 trackable CONTEXT.md decisions honored by shipped artifacts; it reported no unhonored decisions.

### Anti-Patterns Found

None blocking. The protected shared templates contain no `0.5` or `2xs` spacing utilities. No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the reviewed Phase 168 source/test files. The `return null` matches in `flows.spec.js` are parsing/helper fallbacks and do not feed rendered application output; placeholder references in product copy describe explicit unavailable/redacted states.

### Advisory (New Scope, Unevidenced)

None. The documented root core suite failures are reproducible regression-gate results but do not concern the Phase 168 changed surfaces or contradict a Phase 168 truth; they remain recorded in `168-REGRESSION.md` for separate project-health work.

### Human Verification Required

None. The previous gap and the Plan 10 rendered criterion are machine-observable and now covered by passing deterministic tests. Following D-52, these checks do not return to owner UAT.

### Gaps Summary

The prior 4px spacing failure is closed. Source inspection, the seven-template ExUnit guard, generated CSS assertions, and a focused browser test confirm that operator, Inbound, and Preview spacing uses the approved 4px grid. The Phase 168 regression record reports passing Admin and browser suites; the root core suite remains non-green for unrelated setup/fixture/sandbox issues. No must-have gap or human-verification item remains.

---

_Verified: 2026-10-09T00:25:38Z_
_Verifier: the agent (gsd-verifier)_
