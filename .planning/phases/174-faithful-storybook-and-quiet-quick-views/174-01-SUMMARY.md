---
phase: 174-faithful-storybook-and-quiet-quick-views
plan: "01"
subsystem: ui
tags: [phoenix-live-view, phoenix-storybook, playwright, elixir]
requires: []
provides:
  - Quiet Delivery previous/next navigation with measured targets and connected keyboard proof
  - Root-mounted Storybook navigation and a retained production Delivery quick-view story
  - A declarative Delivery scenario and feedback ledger with an Inbound builder reserved for the following plan
affects: [174-02, 174-03, 174-04, 174-05, 174-06, 175, 176, 177, 178]
actuals:
  tokens: 11332
  tasks: 2
  commits: 3
commits: 3
plan_head_before: b3b4222f83544fd3592ded7b663fb1995e12a2e5
plan_head_after: 8411a25fbc5531113749f25677822ae258ba0476
tech-stack:
  added: []
  patterns:
    - Pure scenario builders read deterministic facts from a compile-time JSON manifest.
    - Fixed-overlay Storybook examples need a bounded iframe canvas so auto-sizing retains the viewport.
key-files:
  created:
    - reference/demo_app/assets/e2e/quick-views.spec.js
    - reference/demo_app/storybook/quick_views/delivery.story.exs
    - reference/persona_spec/quick_view_scenarios.ex
    - reference/persona_spec/quick_view_scenarios.json
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - reference/demo_app/lib/mailglass_demo_web/router.ex
key-decisions:
  - "Keep empty Helios absence connected-route-only; do not fabricate a selected record or Storybook variation."
  - "Declare supported Inbound projections now, while leaving Inbound scenarios and its production story to Plan 174-02."
  - "Retain synthetic Delivery projections and exact Fjordline Unicode/long values; do not truncate technical facts."
requirements-completed: [STORY-03]
requirements-in-progress: [UXF-11]
coverage:
  - id: D1
    description: "Delivery quick-view navigation keeps selected Account and filters, supports keyboard traversal/activation/Escape, returns focus, and presents quiet named controls with 44px targets."
    verification:
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/quick-views.spec.js — Phase174 tracer and Phase174 delivery cases"
        status: pass
    human_judgment: false
  - id: D2
    description: "Storybook root, sidebar, Theme Picker, direct Delivery story and prefixed assets resolve under /dev/storybook."
    requirement: STORY-03
    verification:
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/quick-views.spec.js — Phase174 tracer"
        status: pass
    human_judgment: false
  - id: D3
    description: "Four production-component Delivery variants and the connected-route-only empty case are accounted for by the scenario manifest and builder."
    verification:
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/quick-views.spec.js — retained variants and scenario manifest cases"
        status: pass
    human_judgment: false
  - id: D4
    description: "Bounded 350×600 light and dark component captures are available for visual review."
    verification:
      - kind: automated_ui
        ref: "reference/demo_app/tmp/demo_browser_evidence/phase174/delivery-light.png and delivery-dark.png (ignored runtime evidence)"
        status: pass
    human_judgment: true
    rationale: "Automation verifies the canvas dimensions and distinct production theme colors, but an owner must judge visual restraint; the Storybook column is 350px wide, so this capture shows the responsive bottom-sheet state."
duration: 25min
completed: 2026-10-27
status: complete
---

# Phase 174 Plan 01: Delivery Quick-View and Storybook Summary

**Production Delivery quick views now have quiet, keyboard-usable navigation and a correctly routed, scenario-backed Storybook story with retained boundary variants.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-10-27T01:46:54Z
- **Completed:** 2026-10-27T02:11:45Z
- **Tasks:** 2
- **Files modified:** 6 implementation/test files

## Accomplishments

- Removed the idle border from Delivery navigation while retaining `btn-ghost`, focus styling, accessible labels, and the existing minimum 44px targets. Connected route checks verify filter and Account preservation, next/previous activation, Escape, stable focus return, position, and truthful first/last/single/empty/nil-position behavior.
- Mounted PhoenixStorybook 1.2.0 at `/dev/storybook` with generated assets at `/dev/storybook/assets`, keeping the existing development-only guard and browser pipeline. The retained iframe story renders the production quick-view component.
- Added four rendered Delivery variants plus Helios empty state metadata. The four rendered scenarios select eight light/dark axe cases; this is selection metadata, not a claim that axe ran. The Inbound builder is declared for Plan 174-02 but produces no current manifest scenario or story.
- Kept all 12 current owner-feedback rows visible with source symbols, owning requirements/phases, disposition, and evidence pointers. Delivery arrow and Storybook rows are partial; rows owned by Phases 175–178 remain pending.

## Verification

- `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js --grep "Phase174 tracer"` — **1 passed**. A real authenticated Delivery opens, the same production component renders in Storybook, root/sidebar/Theme Picker/deep-link routes work, prefixed assets return 200, and measured controls are at least 44×44px.
- `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js --grep "Phase174 delivery"` — **4 passed**. Connected keyboard, URL/filter, Account, boundary, nil-position, long/Unicode fact, four-story, manifest, and feedback checks passed.
- The variant test also verifies an iframe height of at least 600px, checks that light/dark production panel colors differ, and writes component-only captures to the ignored runtime path `reference/demo_app/tmp/demo_browser_evidence/phase174/`.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix format --check-formatted ../persona_spec/quick_view_scenarios.ex storybook/quick_views/delivery.story.exs lib/mailglass_demo_web/router.ex` — passed.
- `gsd check evaluation-scope --plan 174-01 --commits-only` — resolved with all three plan commits reachable and no missing or out-of-scope plan subjects.

The captures are 350×600 because the Storybook example column is narrow; they show the responsive bottom-sheet presentation, not the desktop-width panel. The connected 1280×900 operator route separately exercises the wide production surface. The ignored captures are review aids, not committed or pixel-comparison baselines.

## Task Commits

1. **Task 1: Repair and retain one real Delivery quick-view path** — `3165b47f` (`feat`)
2. **Task 2: Retain Delivery boundaries and begin the feedback/scenario ledger** — `f5d2a203` (`feat`)
3. **Rule 1 fix: Size the retained fixed-overlay Storybook viewport** — `8411a25f` (`fix`)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` — quieter Delivery arrows with existing names, focus, targets, and paths.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` — root-scoped Storybook macros with the full route and asset prefixes.
- `reference/demo_app/storybook/quick_views/delivery.story.exs` — production quick-view variants in a 600px isolated canvas.
- `reference/demo_app/assets/e2e/quick-views.spec.js` — connected route/story checks, focused keyboard proof, scenario facts, and bounded theme captures.
- `reference/persona_spec/quick_view_scenarios.ex` — deterministic Delivery projection builder and supported future Inbound assigns.
- `reference/persona_spec/quick_view_scenarios.json` — five Delivery case records, axe selection metadata, and 12 feedback dispositions.

## Decisions Made

- Helios empty remains a connected-real-route-only case because no selected record exists to render in Storybook.
- Storybook retains real production component behavior; the pure builder supplies deterministic safe assigns without Repo calls or persisted seed changes.
- The manifest records only four currently rendered Delivery cases; the empty case is unselected for axe, and future Inbound variants are not counted as produced.
- UXF-11 remains in progress at the phase level: the Delivery side is proved, while the Inbound quick-view arrow repair is owned by Plan 174-02. STORY-03 is complete for root/sidebar/deep-link routing.

## Feedback Dispositions

| Feedback ID | Owner | Status |
|---|---:|---|
| `fb-health-crowding` | 177 | pending |
| `fb-preview-reset` | 178 | pending |
| `fb-preview-identity` | 178 | pending |
| `fb-account-context` | 177 | pending |
| `fb-auto-apply-filters` | 176 | pending |
| `fb-quiet-quick-view-arrows` | 174 | partial — Delivery fixed; Inbound remains for Plan 174-02 |
| `fb-raw-source-hierarchy` | 176 | pending |
| `fb-suppression-refresh` | 175 | pending |
| `fb-inbound-addresses` | 176 | pending |
| `fb-storybook-fidelity` | 174, then 178 | partial — routes and Delivery story fixed; typography/theme/hooks/catalogue evidence remains pending |
| `fb-replay-review` | 175 | pending |
| `fb-technical-details` | 175 | pending |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the retained iframe canvas collapsing around fixed-position content**
- **Found during:** Task 2 visual capture
- **Issue:** PhoenixStorybook's content-height sizing measured only 42px for a fixed quick-view overlay. DOM assertions passed, but the captured story was visually clipped.
- **Fix:** Gave the story root a deterministic 600px minimum height, asserted the actual iframe height, and captured the component iframe in both themes.
- **Files modified:** `reference/demo_app/storybook/quick_views/delivery.story.exs`, `reference/demo_app/assets/e2e/quick-views.spec.js`
- **Verification:** The new assertion failed at 42px before the fix; the retained-variant case and all four Phase174 delivery cases pass after it.
- **Committed in:** `8411a25f`

### Test Setup Adjustment

The plan referenced Demo login/reset helpers. The connected scenarios use authenticated UI and read only seeded Northstar, Fjordline, and Helios data; no reset POST was needed. The browser reset helper's configured base-URL prerequisite was absent, so tests avoid reset and remain read-only.

**Total deviations:** 1 correctness fix and 1 read-only test setup adjustment. No product API, query, selection-ownership, package, or persisted-data changes were made.

## Issues Encountered

- Chromium could not start in the default sandbox due to its Mach rendezvous restriction; the required local Playwright runs passed with sandbox escalation.
- A broad formatter check reported existing drift outside this plan, and the admin formatter check was blocked by the pre-existing lockfile mismatch. These files were not changed; details are recorded in `deferred-items.md`. All three changed Elixir files passed the targeted formatter check above.
- `state.update-progress` reported that this STATE.md has no body `Progress:` line; `state.advance-plan` did update its frontmatter position/progress data. `roadmap.update-plan-progress 174` also declined without changing ROADMAP.md: the active v2.10 phase section appears before archived `<details>` blocks, while the CLI’s writable-region scan uses content after the final closing `</details>`. The plan summary is on disk, but the visible roadmap row remains unchanged for the orchestrator to reconcile.

## User Setup Required

None.

## Next Phase Readiness

Plan 174-02 can wire the declared Inbound assigns to the production component and add actual Inbound story/manifest evidence. Do not treat UXF-11 as complete until the Inbound arrows are quiet and verified; continue the still-pending Storybook, font/theme, hook, accessibility execution, and final catalogue work in their owning plans.

---
*Phase: 174-faithful-storybook-and-quiet-quick-views*
*Completed: 2026-10-27*

## Self-Check: PASSED

- All four implementation artifacts and the summary/deferred-items files exist.
- All three plan commits are ancestors of the current HEAD.
