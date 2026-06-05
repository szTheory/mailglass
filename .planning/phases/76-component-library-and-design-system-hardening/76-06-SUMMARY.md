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
    - All 23 hero-* icon masks in bundle (all admin-referenced icons via Components.icon/1 + status_badge/1)
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
  - "[Rule 1 - Bug] heroicons.js was vendor-copied but never wired; it uses Node.js require/fs/path which the standalone binary cannot load. Created heroicons-inline.js as a self-contained replacement. Initial fix embedded only 12 icons (status_badge/1 scope); completed to all 23 admin-referenced icons after user-approved continuation."
  - "[D-11/Pitfall-2 latent bug] Components.icon/1 renders <span class={[@name]}> — a pure CSS-mask class. ALL 23 hero-* icons referenced by the admin were invisible before this fix because heroicons was never a runtime dependency and the inline plugin was incomplete."
  - "heroicons-inline.js uses module.exports + matchComponents API (same pattern as daisyUI) — no external dependencies"
  - "All 5 conformance grep gates passed with zero real violations; text-base-content matches are DaisyUI semantic color classes (false positives per Footgun 6)"
requirements_completed:
  - DS-01
  - DS-02
  - DS-03
  - DS-04
metrics:
  duration: ~12 minutes
  completed: "2026-06-04"
  tasks_completed: 3
  files_modified: 3
---

# Phase 76 Plan 06: Final Asset Bundle Gate Summary

Rebuilt the admin asset bundle with all new badge classes and all 23 hero-* icon masks. All five conformance grep gates pass. Bundle committed and clean. Full test suite green (1 pre-existing voice_test failure unchanged).

## Performance

- **Duration:** ~12 minutes
- **Tasks:** 3 (conformance verification + bundle rebuild + icon coverage completion)
- **Files modified/created:** 3 (app.css source, heroicons-inline.js, priv/static/app.css)

## Accomplishments

### Task 1: Conformance Grep Gates (all PASS)

- Gate 1 — `defp badge_class`: BADGE-GATE-PASS (zero results)
- Gate 2 — `text-(sm|base|xs)`: TYPE-GATE-PASS (all matches are `text-base-content` DaisyUI color class — Footgun 6 false positives; zero real bare violations)
- Gate 3 — `font-(medium|semibold)`: BOLD-GATE-PASS (zero results)
- Gate 4 — `gap-(3|4|6)`: GAP-GATE-PASS (zero results)
- Gate 5 — hex colors: HEX-GATE-PASS (zero results)
- Gate 6 — bundle_test pre-check: 4/4 tests passed; bundle was 70,789 bytes pre-rebuild

### Task 2: Bundle Rebuild (initial — 12 icons)

- Rebuilt `priv/static/app.css` via `mix mailglass_admin.assets.build`
- All 5 badge classes present
- Initial 12 hero-* icon masks (status_badge/1 scope)
- Bundle size: 81,780 bytes

### Task 3: Icon Coverage Completion (11 additional icons — user-approved)

- Fetched 11 missing SVGs from heroicons v2.2.0 (24/outline set) authoritative source
- Added to heroicons-inline.js: `building-office-2`, `device-phone-mobile`, `envelope`, `inbox-arrow-down`, `inbox-stack`, `lifebuoy`, `magnifying-glass`, `moon`, `pencil-square`, `sun`, `window`
- Updated plugin header comment to reflect all 23 admin-referenced icons
- Rebuilt bundle: all 23 `.hero-*` classes confirmed present (count: 1 each)
- Bundle size: 94,054 bytes (< 150,000 byte ceiling)
- Test suite: 187 tests, 1 pre-existing failure (voice_test "Oops" from Phoenix dep JS)
- `git diff --exit-code mailglass_admin/priv/static/` exits 0 after commit — bundle clean

## Task Commits

1. **Task 2: Bundle rebuild + heroicons-inline plugin (12 icons)** — `232b4ead` (feat)
2. **Task 3: Complete icon coverage to all 23 admin hero-* icons** — (see commit below)

## Files Created/Modified

- `mailglass_admin/assets/vendor/heroicons-inline.js` — standalone-binary-compatible Heroicons plugin with all 23 inline SVGs (23 icons: 12 initial + 11 added in continuation)
- `mailglass_admin/assets/css/app.css` — Added `@plugin "../vendor/heroicons-inline"` directive
- `mailglass_admin/priv/static/app.css` — Rebuilt bundle: badge classes + all 23 hero-* icon masks + all token migrations from Plans 76-01..76-05

## Decisions Made

- `heroicons-inline.js` is the standalone-binary-compatible replacement for `heroicons.js` — same `matchComponents("hero", ...)` pattern but without Node.js `require`/`fs`/`path` dependencies. The original `heroicons.js` template was vendor-copied but never wired (because it cannot work with the standalone binary).
- heroicons is NOT a runtime dependency of this repo (not in mix.lock, no `deps/heroicons`). All SVG data must be embedded inline. The complete set of 23 icons is required because `Components.icon/1` renders `<span class={[@name]}>` — any icon NOT in the bundle is invisible (pure CSS-mask approach).
- Initial fix in `232b4ead` embedded only the 12 icons needed by `status_badge/1`. The user approved completing coverage to all 23 admin-referenced icons (D-11/Pitfall-2 latent bug — all hero icons were invisible before this plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] heroicons.js plugin was vendor-copied but never wired into app.css**

- **Found during:** Task 2 — bundle rebuild verification (`grep -c 'hero-paper-airplane'` returned 0)
- **Issue:** The vendored `heroicons.js` plugin uses Node.js `require("tailwindcss/plugin")`, `require("fs")`, and `require("path")` — none of which are available in the Tailwind v4 standalone binary. Adding `@plugin "../vendor/heroicons"` to app.css caused the build to exit with error code 1. The research assumption "no additional configuration required" was incorrect — the plugin had never been wired and cannot be wired with the standalone binary as-is.
- **Fix:** Created `mailglass_admin/assets/vendor/heroicons-inline.js` — a self-contained plugin that:
  - Uses `module.exports` + direct `matchComponents` API (same pattern as daisyUI.js — no external `require()`)
  - Embeds all 23 admin-referenced Heroicon SVGs directly as inline strings (MIT-licensed; sourced from heroicons v2.2.0, 24/outline set)
  - Uses `mask`/`-webkit-mask` CSS properties with `data:image/svg+xml;utf8,` encoded URLs — identical to the original plugin output
  - Wire: `@plugin "../vendor/heroicons-inline"` added to assets/css/app.css
- **Files modified:** `mailglass_admin/assets/vendor/heroicons-inline.js` (created), `mailglass_admin/assets/css/app.css`
- **Initial commit:** `232b4ead` (12 icons); **completion commit:** see below (all 23 icons)

**2. [D-11/Pitfall-2 latent bug] All 23 hero-* icons referenced by admin were invisible pre-bundle**

- **Root cause:** heroicons is NOT a dependency (not in mix.lock). `Components.icon/1` renders `<span class={[@name]}>` — a pure CSS-mask class that resolves to invisible if the `.hero-*` rule is absent. The initial fix covered only 12 icons (status_badge/1 scope); the remaining 11 icons used by other admin components (nav, dark-mode toggle, search, detail views) were still invisible.
- **Fix:** Fetched all 11 missing SVGs from heroicons v2.2.0 authoritative source (verified non-empty, starts with `<svg`); added to heroicons-inline.js in single-line escaped format consistent with existing entries. User approved completing coverage.
- **All 23 icons now embedded:** arrow-path, arrow-uturn-left, bell-slash, building-office-2, check-circle, device-phone-mobile, envelope, envelope-open, exclamation-circle, exclamation-triangle, hand-thumb-up, inbox-arrow-down, inbox-stack, lifebuoy, magnifying-glass, minus-circle, moon, paper-airplane, pencil-square, question-mark-circle, sun, window, x-circle

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
- [x] `232b4ead` — FOUND (12-icon initial bundle)

Bundle verification (all 23 icons):
- [x] `badge-primary` in bundle — FOUND (count: 1)
- [x] `hero-arrow-path` in bundle — FOUND (count: 1)
- [x] `hero-building-office-2` in bundle — FOUND (count: 1)
- [x] `hero-device-phone-mobile` in bundle — FOUND (count: 1)
- [x] `hero-envelope` in bundle — FOUND (count: 1)
- [x] `hero-inbox-arrow-down` in bundle — FOUND (count: 1)
- [x] `hero-inbox-stack` in bundle — FOUND (count: 1)
- [x] `hero-lifebuoy` in bundle — FOUND (count: 1)
- [x] `hero-magnifying-glass` in bundle — FOUND (count: 1)
- [x] `hero-moon` in bundle — FOUND (count: 1)
- [x] `hero-pencil-square` in bundle — FOUND (count: 1)
- [x] `hero-sun` in bundle — FOUND (count: 1)
- [x] `hero-window` in bundle — FOUND (count: 1)
- [x] `hero-paper-airplane` in bundle — FOUND (count: 1)
- [x] `hero-check-circle` in bundle — FOUND (count: 1)
- [x] `hero-question-mark-circle` in bundle — FOUND (count: 1)
- [x] Bundle size 94054 bytes < 150000 — PASS
- [x] `git diff --exit-code priv/static/` exits 0 after commit — BUNDLE-CLEAN

## Self-Check: PASSED

---
*Phase: 76-component-library-and-design-system-hardening*
*Completed: 2026-06-04*
