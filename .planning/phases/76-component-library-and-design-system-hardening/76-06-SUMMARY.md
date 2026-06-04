---
phase: 76-component-library-and-design-system-hardening
plan: "06"
subsystem: mailglass_admin
tags:
  - bundle
  - heroicons
  - design-system
  - asset-build
dependency_graph:
  requires:
    - phase: 76-02
      provides: status_badge/1 unified atom; all badge_class/1 copies deleted
    - phase: 76-03
      provides: Tier1/Tier2 support-card restructure
    - phase: 76-04
      provides: token migration of 5 badge-rewired files
    - phase: 76-05
      provides: token migration of 15 remaining admin files + hex fix
  provides:
    - Committed priv/static/app.css with badge-primary/success/warning/error/outline CSS rules
    - All 12 hero-* icon masks in bundle (paper-airplane, arrow-path, check-circle, exclamation-triangle, x-circle, exclamation-circle, bell-slash, envelope-open, hand-thumb-up, arrow-uturn-left, question-mark-circle, minus-circle)
    - DS-01 and DS-04 production-complete
  affects:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/assets/vendor/heroicons-inline.js
    - mailglass_admin/priv/static/app.css
tech_stack:
  added:
    - "heroicons-inline.js: self-contained standalone-binary-compatible Tailwind plugin"
  patterns:
    - "Self-contained JS plugin (no require/fs/path) for Tailwind v4 standalone binary"
    - "Inline SVG embedded as URI-encoded data URLs in CSS mask properties"
    - "matchComponents('hero', ...) pattern for class-name-based icon resolution"
key_files:
  created:
    - mailglass_admin/assets/vendor/heroicons-inline.js
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
key_decisions:
  - "[Rule 1 - Bug] heroicons.js was vendor-copied but never wired; it uses Node.js require/fs/path which the standalone binary cannot load. Created heroicons-inline.js as a self-contained replacement that embeds the 12 needed SVGs as inline strings."
  - "heroicons-inline.js uses module.exports + matchComponents API (same pattern as daisyUI) — no external dependencies"
  - "All 5 conformance grep gates passed with zero real violations; text-base-content matches are DaisyUI semantic color classes (false positives per Footgun 6)"
requirements_completed:
  - DS-01
  - DS-02
  - DS-03
  - DS-04
metrics:
  duration: ~8 minutes
  completed: "2026-06-04"
  tasks_completed: 2
  files_modified: 3
---

# Phase 76 Plan 06: Final Asset Bundle Gate Summary

Rebuilt the admin asset bundle with all new badge classes and hero-* icon masks. All five conformance grep gates pass. Bundle committed and clean. Full test suite green (1 pre-existing voice_test failure unchanged).

## Performance

- **Duration:** ~8 minutes
- **Tasks:** 2 (conformance verification + bundle rebuild)
- **Files modified/created:** 3 (app.css source, heroicons-inline.js, priv/static/app.css)

## Accomplishments

### Task 1: Conformance Grep Gates (all PASS)

- Gate 1 — `defp badge_class`: BADGE-GATE-PASS (zero results)
- Gate 2 — `text-(sm|base|xs)`: TYPE-GATE-PASS (all matches are `text-base-content` DaisyUI color class — Footgun 6 false positives; zero real bare violations)
- Gate 3 — `font-(medium|semibold)`: BOLD-GATE-PASS (zero results)
- Gate 4 — `gap-(3|4|6)`: GAP-GATE-PASS (zero results)
- Gate 5 — hex colors: HEX-GATE-PASS (zero results)
- Gate 6 — bundle_test pre-check: 4/4 tests passed; bundle was 70,789 bytes pre-rebuild

### Task 2: Bundle Rebuild

- Rebuilt `priv/static/app.css` via `mix mailglass_admin.assets.build`
- All 5 badge classes present: `badge-primary`, `badge-success`, `badge-warning`, `badge-error`, `badge-outline`
- All 12 hero-* icon masks present: `hero-paper-airplane`, `hero-arrow-path`, `hero-check-circle`, `hero-exclamation-triangle`, `hero-x-circle`, `hero-exclamation-circle`, `hero-bell-slash`, `hero-envelope-open`, `hero-hand-thumb-up`, `hero-arrow-uturn-left`, `hero-question-mark-circle`, `hero-minus-circle`
- Bundle size: 81,780 bytes (< 150,000 byte ceiling; +11KB from icon SVG masks)
- `git diff --exit-code mailglass_admin/priv/static/` exits 0 — bundle committed and clean
- Test suite: 187 tests, 1 pre-existing failure (voice_test "Oops" from Phoenix dep JS)

## Task Commits

1. **Task 2: Bundle rebuild + heroicons-inline plugin** — `232b4ead` (feat)

## Files Created/Modified

- `mailglass_admin/assets/vendor/heroicons-inline.js` — NEW: standalone-binary-compatible Heroicons plugin with 12 inline SVGs
- `mailglass_admin/assets/css/app.css` — Added `@plugin "../vendor/heroicons-inline"` directive
- `mailglass_admin/priv/static/app.css` — Rebuilt bundle: badge classes + hero-* icon masks + all token migrations from Plans 76-01..76-05

## Decisions Made

- `heroicons-inline.js` is the standalone-binary-compatible replacement for `heroicons.js` — same `matchComponents("hero", ...)` pattern but without Node.js `require`/`fs`/`path` dependencies. The original `heroicons.js` template was vendor-copied but never wired (because it cannot work with the standalone binary). `heroicons-inline.js` is self-contained and works identically to daisyUI's plugin structure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] heroicons.js plugin was vendor-copied but never wired into app.css**

- **Found during:** Task 2 — bundle rebuild verification (`grep -c 'hero-paper-airplane'` returned 0)
- **Issue:** The vendored `heroicons.js` plugin uses Node.js `require("tailwindcss/plugin")`, `require("fs")`, and `require("path")` — none of which are available in the Tailwind v4 standalone binary. Adding `@plugin "../vendor/heroicons"` to app.css caused the build to exit with error code 1. The research assumption "no additional configuration required" was incorrect — the plugin had never been wired and cannot be wired with the standalone binary as-is.
- **Fix:** Created `mailglass_admin/assets/vendor/heroicons-inline.js` — a self-contained plugin that:
  - Uses `module.exports` + direct `matchComponents` API (same pattern as daisyUI.js — no external `require()`)
  - Embeds the 12 needed Heroicon SVGs directly as inline strings (MIT-licensed; sourced from heroicons v2.2.0, 24/outline set)
  - Uses `mask`/`-webkit-mask` CSS properties with `data:image/svg+xml;utf8,` encoded URLs — identical to the original plugin output
  - Wire: `@plugin "../vendor/heroicons-inline"` added to assets/css/app.css
- **Files modified:** `mailglass_admin/assets/vendor/heroicons-inline.js` (created), `mailglass_admin/assets/css/app.css`
- **Committed in:** `232b4ead`

## Known Stubs

None — this plan delivers the committed production bundle.

## Threat Flags

None. This plan runs conformance greps, creates a self-contained JS plugin with embedded SVG data (no network access, no external packages), rebuilds a CSS bundle, and commits the artifact. No new auth, session, data-access, or input-validation surface introduced.

## Self-Check

Files created/modified:
- [x] `mailglass_admin/assets/vendor/heroicons-inline.js` — FOUND
- [x] `mailglass_admin/assets/css/app.css` — FOUND
- [x] `mailglass_admin/priv/static/app.css` — FOUND

Commits:
- [x] `232b4ead` — FOUND

Bundle verification:
- [x] `badge-primary` in bundle — FOUND (count: 1)
- [x] `hero-paper-airplane` in bundle — FOUND (count: 1)
- [x] `hero-check-circle` in bundle — FOUND (count: 1)
- [x] `hero-question-mark-circle` in bundle — FOUND (count: 1)
- [x] Bundle size 81780 bytes < 150000 — PASS
- [x] `git diff --exit-code priv/static/` exits 0 — BUNDLE-CLEAN

## Self-Check: PASSED

---
*Phase: 76-component-library-and-design-system-hardening*
*Completed: 2026-06-04*
