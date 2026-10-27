---
phase: 174-faithful-storybook-and-quiet-quick-views
plan: "04"
subsystem: ui
tags: [phoenix-storybook, themes, typography, playwright]
requires:
  - phase: 174-01
    provides: Retained production Delivery quick view and root-mounted Storybook routes
  - phase: 174-02
    provides: Retained Inbound quick view and synthetic scenario fixtures
  - phase: 174-03
    provides: Shared production hooks and Demo-only Storybook asset routes
provides:
  - Story-local Light/Dark/System ownership with live OS preference updates for Delivery and Inbound
  - Production CSS, WOFF2, computed-role, and responsive quick-view evidence
affects: [174-05, 174-06, 178]
tech-stack:
  added: []
  patterns:
    - Story-local theme preference resolves with matchMedia inside the Storybook iframe and never persists a host preference.
    - Browser evidence compares served CSS/font bytes and loaded font faces to committed production assets.
key-files:
  created:
    - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
    - .planning/174-04-task-1-red-evidence.json
    - .planning/174-04-task-2-red-evidence.json
    - reference/demo_app/tmp/demo_browser_evidence/phase174/fidelity.json (git-ignored runtime receipt)
  modified:
    - reference/demo_app/dev/mailglass_demo_web/storybook.ex
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/storybook/quick_views/delivery.story.exs
    - reference/demo_app/storybook/quick_views/inbound.story.exs
    - reference/demo_app/storybook/primitives/theme_picker.story.exs
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
key-decisions:
  - Keep Light/Dark/System preference and OS resolution on the retained story root; do not write the authenticated host preference or create another socket.
  - Serve production hooks plus the local theme adapter from a Demo-only versioned route. The pinned PhoenixStorybook macro evaluates use options before module attributes, so js_path uses the computed literal hash with a compile-time equality guard.
  - Scope Inter, Inter Tight, and IBM Plex Mono to the production .mg-admin-root, display, and code roles while retaining existing global defaults.
  - Keep source CSS, compiled bundle, and served response digests as separate receipt fields; assert byte equality only for built and served CSS.
metrics:
  duration: 33m43s
  completed: 2026-10-27
actuals:
  tokens: 82886.25
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 159ec9d4602cbc5ead9947bb064fd0da7f64931d
plan_head_after: a3b3548abe93c19a71a7ee3d43d0390952314826
status: complete
requirements-completed: [STORY-04, STORY-05]
---

# Phase 174 Plan 04: Faithful Storybook Theme and Typography Receipts

Storybook Delivery and Inbound quick views now own a live Light/Dark/System review theme and load the production CSS and six self-hosted font faces, with byte-level asset and responsive layout receipts.

## What Changed

- Added a Demo-only adapter to the hashed Storybook review asset route. It combines the shared production hooks with a local `matchMedia` theme owner, tracks selected preference separately from resolved scheme, responds to OS changes, and removes listeners when roots leave the iframe. The quick-view stories expose native Light/Dark/System radios; primitive Theme Picker variations remain labelled as static examples.
- Scoped the existing Inter, Inter Tight, and IBM Plex Mono roles to `.mg-admin-root`, its headings, and its code/mono descendants. Rebuilt the committed production `app.css` bundle through the existing Mix task; no dependency or lockfile changes were needed.
- Extended `storybook-fidelity.spec.js` with theme, font, and responsive cases. It writes the runtime receipt and six narrow/boundary/wide Storybook screenshots under `reference/demo_app/tmp/demo_browser_evidence/phase174/`.

## Coverage and Receipts

| Requirement | Result | Evidence |
|---|---|---|
| STORY-04 | Pass | Delivery and Inbound own Light/Dark/System. System matches light/dark OS preferences and live flips; explicit choices stay stable and match production route tokens without changing host preference. |
| STORY-05 | Pass | Each story fetched all six production WOFF2 assets successfully. Response bytes match the committed font files; all 400/700 faces report loaded and the computed UI/display/code roles match a connected production quick view. |
| Responsive quick views | Pass | 20 cases cover requested widths 320, 375, 768, 1280, and 1440 in both themes across normal and first-position scenarios. Actual Storybook iframe/pane widths ranged from 270 to 718 px. Position and Close remain within the panel; all visible quick-view targets are at least 44×44 px; exact technical IDs remain unabridged and fit their copy controls. |
| Focus and reduced motion | Pass | Keyboard focus is visible. With reduced motion enabled, Escape closes the connected production quick view and restores focus to its opener. |

The runtime receipt is `reference/demo_app/tmp/demo_browser_evidence/phase174/fidelity.json`. Its source CSS digest is `0d964dcd…b9887e5`; the committed built and both served CSS responses share digest `b74a5250…a689e475b`. It records 12 font response receipts (six assets for each story), computed roles, theme owner/OS values, and all 26 selected/executed case IDs. The three representative screenshots per story show 320, 768, and 1440 px Storybook views.

## Verification

- `npm --prefix reference/demo_app/assets run test:e2e -- storybook-fidelity.spec.js` — 6 passed.
- `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 MIX_ENV=dev mix mailglass_admin.assets.build` — succeeded; a repeat build preserved SHA-256 `b74a52501d325bc14e8201ab6fe94c77686d38c3d8ce6f4d674ec51a689e475b`.
- `node --check reference/demo_app/assets/e2e/storybook-fidelity.spec.js` and `git diff --check` — passed.
- The Task 2 JUnit RED record classified as `RED_EVIDENCE_OK`. Both TDD tasks have a test commit before their implementation commit.

## Task Commits

1. **Task 1: Theme ownership RED and GREEN** — `bed78842`, `03b019d6`.
2. **Task 2: Font and responsive receipts RED and GREEN** — `c950cb9b`, `a3b3548a`.

## TDD Gate Compliance

| Task | RED commit | GREEN commit | Result |
|---|---|---|---|
| 1 — theme owner | `bed78842` | `03b019d6` | Missing story owner failed before implementation; both theme cases passed after implementation. |
| 2 — fonts and widths | `c950cb9b` | `a3b3548a` | Serif reset replaced Inter before implementation (`RED_EVIDENCE_OK`); all six fidelity tests passed after implementation. |

## Deviations from Plan

None. No dependencies or build steps were added. The `js_path` hash literal is checked against the computed combined JavaScript hash at compile time to accommodate the pinned PhoenixStorybook macro evaluation behavior.

## Evidence Limits

- The checks used the already-seeded Demo host at `127.0.0.1:4015` and synthetic Northstar scenarios. The reset credential was unavailable, so no database reset was attempted; Plan 174-06 owns validation against a fresh service identity.
- At a requested 320 px Storybook width, the complete review-radio group extends slightly beyond the iframe click area. Width cases select the native radio through its change event; the theme suite verifies physical Light/Dark/System selection at desktop width.
- Real browser zoom reconciliation remains owned by Phase 178.

## Self-Check: PASSED

- Summary, both RED evidence files, and the runtime fidelity receipt exist.
- All four task commits are ancestors of HEAD; the measured plan commit count is 4.
- Both RED evidence records return `RED_EVIDENCE_OK`.
- `git diff --check` passes.
