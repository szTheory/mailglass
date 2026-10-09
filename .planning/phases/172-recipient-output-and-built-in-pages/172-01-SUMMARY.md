---
phase: 172-recipient-output-and-built-in-pages
plan: 01
subsystem: email
tags: [elixir, heex, mailglass-components, mailer-preview, playwright]

requires: []
provides:
  - AtlasDesk-branded registered public-component invoice preview scenario.
  - Fluid public component container output and focused source/browser evidence for both authoring paths.
affects: [mailers, email-components, demo-preview, phase-172]

actuals:
  tokens: 5206
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns:
    - One-arity HEEx Mailable function rendered through the existing Mailglass pipeline.
    - Embedded SVG data URI keeps the deterministic preview illustration self-contained.

key-files:
  created: []
  modified:
    - reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs
    - lib/mailglass/components.ex
    - test/mailglass/components/content_test.exs
    - test/mailglass/components/button_test.exs
    - reference/demo_app/assets/e2e/demo.spec.js

key-decisions:
  - Keep the public-component preview distinct from the existing bespoke AtlasDesk scenarios.
  - Keep invoice illustration bytes local to the preview and preserve live text as the source of essential meaning.
  - Treat preview/browser checks as generated-output evidence, not email-client compatibility certification.

patterns-established:
  - Public component previews can exercise a HEEx function body through the existing Mailable and Renderer APIs.
  - The inner container table can use width 100% with a 600px maximum to fit narrow preview frames.

requirements-completed: [MAILUX-01, MAILUX-02]
coverage:
  - id: D1
    description: Public components render fluid, escaped, readable invoice content with a live-text CTA and useful image alternative.
    requirement: MAILUX-01
    verification:
      - kind: unit
        ref: test/mailglass/components/content_test.exs and test/mailglass/components/button_test.exs; focused content/button/row/VML suite
        status: pass
      - kind: other
        ref: bash scripts/gsd-regression-gate.sh
        status: pass
    human_judgment: false
  - id: D2
    description: The demo preview exposes the AtlasDesk public-component scenario beside an existing bespoke HTML scenario.
    requirement: MAILUX-02
    verification:
      - kind: unit
        ref: reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs
        status: pass
      - kind: e2e
        ref: Playwright preview scenario: public component and AtlasDesk HTML authoring paths (targeted run)
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-10-09
status: complete
plan_head_before: eab656967a303c4e2591511a723b7dd688ad99cc
plan_head_after: 28f72a70ff5450259ff23b8fce1a699df15a8ca9
commits: 7
---

# Phase 172 Plan 01: Recipient Output and Built-in Pages Summary

**A registered AtlasDesk invoice preview now demonstrates public HEEx components alongside the existing bespoke HTML mailers, with narrow-layout output and browser evidence.**

## Performance

- **Duration:** 45 minutes
- **Started:** 2026-10-09T21:08:11Z
- **Completed:** 2026-10-09T21:53:17Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `ComponentMailer.invoice_ready/1`, registered it in the development preview, and kept the existing AtlasDesk HTML scenarios intact.
- Added focused demo and component contracts for the sender, rendering path, live text, image alternative, long content, and email-safe output.
- Extended connected browser evidence to inspect both authoring paths and check the public preview at a narrow viewport and 2× rendered-email zoom.

## Task Commits

Each task was committed atomically; TDD RED and implementation commits are listed separately:

1. **Task 1: Render one named public-component Mailable** — `28e2eae9` (test), `e19999d9` (feat), `97ad617a` (test assertion correction).
2. **Task 2: Make component output readable under long and narrow content** — `fb06b010` (test), `fb7c0295` (feat), `3423a807` (browser-discovered fluid-width and preview-image correction).
3. **Task 3: Inspect both authoring paths in the connected browser preview** — `28f72a70` (test).

## Files Created/Modified

- `reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex` — deterministic AtlasDesk invoice scenario composed with public components and a self-contained SVG illustration.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` — registers the new preview Mailable.
- `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` — checks the registered scenario and distinguishes component output from existing bespoke HTML.
- `lib/mailglass/components.ex` — allows the inner presentation table to shrink while retaining its 600px maximum.
- `test/mailglass/components/content_test.exs` and `test/mailglass/components/button_test.exs` — assert the component output contract and compatibility details.
- `reference/demo_app/assets/e2e/demo.spec.js` — inspects the public and bespoke scenarios in the connected preview.

## Decisions Made

- The public-component and bespoke examples remain separate scenarios under the same AtlasDesk identity so evaluators can see which authoring path produced each output.
- The invoice illustration is embedded as SVG data so the demo does not depend on a non-existent `.example` image host. Live text carries the invoice and action meaning if an image is unavailable.
- Responsive browser assertions cover generated HTML only; they make no claim about receiving mail clients.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the inner container table's narrow viewport width**
- **Found during:** Task 3 browser evidence.
- **Issue:** The fixed `width="600"` table attribute made the rendered email document 608px wide inside a 320px preview frame, despite the CSS width rule.
- **Fix:** Changed the inner table width attribute to `100%` while preserving `max-width:600px;width:100%`.
- **Files modified:** `lib/mailglass/components.ex`, `test/mailglass/components/content_test.exs`.
- **Verification:** Focused component tests, regression gate, and targeted Playwright scenario passed.
- **Committed in:** `3423a807`.

**2. [Rule 1 - Bug] Made the demo invoice illustration render without an unavailable remote asset**
- **Found during:** Task 3 browser evidence review.
- **Issue:** The prior `.example` image URL could not supply a useful illustration in the preview.
- **Fix:** Embedded a small SVG data URI, retained descriptive alternative text, and asserted the final alt text and live AtlasDesk label.
- **Files modified:** `reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex`, `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs`.
- **Verification:** Focused Mailable test and targeted Playwright preview passed.
- **Committed in:** `3423a807`.

**Total deviations:** 2 auto-fixed issues (Rule 1). **Impact:** Both corrections were directly required for the planned rendered preview to be usable and verifiable.

## Issues Encountered

- The demo app's standard focused Mix command attempted a locked dependency check against its existing lockfile and could not update the shared Hex cache. The focused test passed with `--no-deps-check` using the already available dependencies; no package was installed. Docker dependency resolution modified `reference/demo_app/mix.lock` during browser runs, and that initially clean file was restored afterward.
- `bash scripts/gsd-regression-gate.sh` passed: core contracts (72 tests), admin/component suite (593 tests, 1 excluded), inbound deterministic suite (480 tests, 3 excluded), and connected browser suite (30 tests).
- The full `bash scripts/run_demo_browser_evidence.sh` ran 74 browser tests and reported 71 passing, including screenshots. Its first run of the new preview test exposed an unnecessary 600px document-height cap (actual height 602px); that assertion was removed because the contract concerns horizontal fit and content availability. The corrected preview scenario passed in a focused Playwright run. Two remaining full-lane failures are existing unrelated checks: Helios empty-state heading in `cohort.spec.js` and `inbound-detail-header` in `demo.spec.js`.
- `reference/demo_app/assets/e2e/demo.spec.js` passed `node --check`; the final targeted browser run passed 1 test.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The registered public-component example and narrow-layout component behavior are ready for later recipient-output and built-in-page work. The demo browser lane remains advisory and has the two unrelated failures noted above.

## Self-Check: PASSED

All seven declared implementation files and this summary exist. All seven task commits are ancestors of the current plan head, and the final JavaScript syntax and changed-source whitespace checks pass.

---
*Phase: 172-recipient-output-and-built-in-pages*
*Completed: 2026-10-09*
