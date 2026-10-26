---
phase: 171-developer-preview
plan: 04
subsystem: ui
tags: [phoenix-liveview, preview, responsive, accessibility, playwright]
requires:
  - phase: 171-03
    provides: "Connected preview output tabs and long-output navigation."
provides:
  - "Independent CSS-pixel frame width, browser backdrop, and Admin appearance controls."
  - "Responsive preview evidence for long identities, output, narrow widths, and actual 200% browser zoom."
  - "A bounded rendered review that distinguishes preview-pipeline evidence from recipient-client behavior."
affects: [preview, 171-developer-preview, guides]
actuals:
  tokens: 73954
  tasks: 2
  commits: 5
plan_head_before: 3a651ba10626e42ff43950c0edc5b73eaa1a89b8
plan_head_after: 916150a5ae955bb70067c316be0b5eb412f391cf
tech-stack:
  added: []
  patterns:
    - "Give CSS-pixel controls concise visible values with full accessible names."
    - "Stack preview identity and controls until the available header width can hold them without squeezing selected identity."
key-files:
  created:
    - .planning/phases/171-developer-preview/171-RENDERED-REVIEW.md
    - .planning/phases/171-developer-preview/171-04-task1-red.json
    - .planning/phases/171-developer-preview/171-04-task2-red.json
    - .planning/phases/171-developer-preview/171-04-task2-reflow-red.json
    - .planning/phases/171-developer-preview/deferred-items.md
  modified:
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/lib/mailglass_admin/preview/device_frame.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/discovery_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/test/mailglass_admin/voice_test.exs
    - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
    - mailglass_admin/test/support/fixtures/mailables.ex
key-decisions:
  - "Frame widths are labelled in CSS pixels, with accessible names retaining the full unit while short labels fit narrow galleries."
  - "Keep preview header controls stacked until the wide breakpoint, and remove the spacing-token max-width that collapsed the selected identity to 16 px."
  - "Treat screenshots and capture matrices as browser preview-pipeline evidence, not recipient-client or email dark-mode certification."
metrics:
  duration: 25min
  completed: 2026-10-09
  tasks: 2
  files: 16
  commits: 5
status: complete
requirements-completed: [PRVUX-01, PRVUX-02, PRVUX-03, PRVUX-04]
---

# Phase 171 Plan 04: Developer Preview Responsive Framing Summary

**Preview width, browser backdrop, and Admin appearance now remain independent across connected remounts, while narrow and zoomed layouts keep the selected scenario and controls usable.**

## Performance

- **Duration:** 25 minutes
- **Started:** 2026-10-09 10:21 local (first task commit)
- **Completed:** 2026-10-09 10:45 local
- **Tasks:** 2
- **Files in plan diff:** 16
- **Measured commits:** 5

## Accomplishments

- Clarified the three frame widths as CSS pixels and described the backdrop as browser preview framing. The visible note says the preview does not establish email-client compatibility or dark-mode behavior.
- Added connected checks proving width, backdrop, and persisted Admin appearance remain independent through a theme remount. The frame controls expose visible keyboard focus.
- Added narrow and actual 200% zoom journeys covering the long Unicode mailable identity, controls and target sizes, editable/read-only assigns, pending and failure/stale output states, output scrolling, reduced motion, and focus. Browser screenshots cover narrow Light, system Dark, and wide Dark.
- Repaired selected identity squeezing caused by `sm:max-w-md` resolving to a 16 px spacing token, and kept controls stacked until the wide breakpoint. Short visible frame labels prevent gallery overflow while accessible names retain “CSS pixels.”
- Recorded source revision, served stylesheet digest, fixture and route, viewport/theme states, corrective pass, and evidence limits in [171-RENDERED-REVIEW.md](171-RENDERED-REVIEW.md).

## Task Commits

1. **Task 1 RED — independent frame state assertions** — `a22a5afb` (`test`)
2. **Task 1 GREEN — independent CSS-pixel controls** — `e6c34468` (`feat`)
3. **Task 2 RED — narrow preview readability journeys** — `02998946` (`test`)
4. **Task 2 GREEN — responsive layout and refreshed Admin expectations** — `7fd442ab` (`fix`)
5. **Rendered evidence and advisory deferrals** — `916150a5` (`docs`)

The RED evidence files document the missing state and visible focus behavior. A second Task 2 RED capture isolated the 16 px selected-identity width before its fix. The implementation and corrective passes followed with connected browser checks.

## Verification

- `mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` — 40 tests, 0 failures before the compact-label correction.
- `mix verify.support_contract.admin` — 589 tests, 0 failures, 1 excluded. The first attempt exposed three outdated assertions for the existing five-scenario fixture and current page copy; those expectations and the fixture comment were refreshed before the required rerun.
- `mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` — 10 tests, 0 failures.
- Focused post-correction browser rerun — 5 passed: full gallery overflow matrix, stress gallery overflow matrix, independent framing/remount, narrow journey, and actual Chromium 200% zoom.
- Preview capture dry-run — 30 deterministic scenario × width × theme entries and 2 intentional skips; deterministic manifest/checkpoint were written under package `tmp/`.
- Elixir format check and `git diff --check` passed.
- Advisory full browser run — 207 passed, 1 skipped, 3 failed before the compact-label correction. The gallery overflow failure was fixed and both gallery checks passed in the focused post-correction run. Two older assertions remain deferred: a `.btn-primary` selector for the preview render action and an expectation that the picker omits the selected module name. The full advisory suite was not rerun after the compact-label correction; details are in [deferred-items.md](deferred-items.md).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored selected identity width and responsive header layout**
- **Found during:** Task 2 rendered review
- **Issue:** `sm:max-w-md` compiled to `max-width: var(--spacing-md)` and resolved to 16 px, squeezing the mailable identity. The header also needed to stack controls at 1024 CSS px.
- **Fix:** Removed the erroneous max-width utility and stacked the header controls until the wide breakpoint.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex`, `mailglass_admin/lib/mailglass_admin/preview_live.ex`, `mailglass_admin/priv/static/app.css`
- **Commit:** `7fd442ab`

**2. [Rule 2 - Missing accessibility and responsive behavior] Added visible focus and compact frame labels**
- **Found during:** Task 2 browser and gallery matrix checks
- **Issue:** Width buttons lacked a visible focus indicator, and longer visible labels caused 320 px gallery overflow.
- **Fix:** Added the shared focus-ring class and compact labels with full accessible names.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex`, `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/test/mailglass_admin/preview_live_test.exs`, `mailglass_admin/priv/static/app.css`
- **Commit:** `7fd442ab`

**3. [Rule 3 - Blocking test assertions] Refreshed stale Support Contract Admin expectations**
- **Found during:** Task 2 required suite
- **Issue:** Three assertions still expected four fixture scenarios and outdated Preview copy, blocking the required Admin suite.
- **Fix:** Updated scenario order/count expectations, current copy assertions, and the fixture comment to match the existing five-scenario fixtures.
- **Files modified:** `mailglass_admin/test/mailglass_admin/discovery_test.exs`, `mailglass_admin/test/mailglass_admin/voice_test.exs`, `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs`, `mailglass_admin/test/support/fixtures/mailables.ex`
- **Commit:** `7fd442ab`

The two remaining stale advisory browser assertions were left unchanged because they are outside this plan's responsive preview changes and are documented for follow-up. The optional Windows ledger append was unavailable because its rendered table disagrees with fenced JSON row 48; the `gsd-tools` error was preserved and the findings remain in the phase-local deferred list.

## Threat Flags

None. The changes only refine planned preview labels, focus, layout, and synthetic rendered evidence. Screenshots remain temporary and preview-pipeline-only.

The browser-client certification prohibition is resolved as test-tier by the exact limitation-copy assertion in `preview_live_test.exs` and the connected framing journey in `structural.spec.js`.

## Self-Check: PASSED

- All three RED evidence files, the rendered review, deferred items, and this summary exist.
- All five measured plan commits are ancestors of the current checkout.
- Measured plan commit count is 5 (`3a651ba10626e42ff43950c0edc5b73eaa1a89b8..916150a5ae955bb70067c316be0b5eb412f391cf`).
