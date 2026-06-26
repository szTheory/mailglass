---
phase: 118-method-audit-storybook-stand-up
plan: 01
subsystem: testing
tags: [phoenix_storybook, dev-tooling, component-review, data-theme, sandbox-css, demo-app]

# Dependency graph
requires:
  - phase: 117 (v1.13 admin design-system)
    provides: "the public MailglassAdmin.Components primitives (nav_link, nav_pill, tenant_chip, theme_picker, stat_card) and the served committed app.css bundle route /dev/mail/css-<md5>"
provides:
  - "Dev-only /dev/storybook review surface in the demo app (phoenix_storybook ~> 1.2, only: :dev)"
  - "Hand-written MailglassDemoWeb.Storybook backend reusing the committed admin bundle as sandbox CSS (no new asset build)"
  - "Initial foundations + 5-primitive *.story.exs inventory with template-level data-theme bridge"
  - "Git-ignored screenshot evidence cache (.planning/research/**/.cache/) — the Wave-0 prereq for the Plan 03 persona-critic harness"
affects: [118-02, 118-03, 119, persona-critic-harness, defect-register]

# Tech tracking
tech-stack:
  added: [phoenix_storybook ~> 1.2 (demo dev-only)]
  patterns:
    - "css_path as a remote @import URL to the served committed bundle (zero new build)"
    - "per-variation template-level data-theme bridge (no class->data-theme CSS alias)"

key-files:
  created:
    - reference/demo_app/lib/mailglass_demo_web/storybook.ex
    - reference/demo_app/storybook/foundations.story.exs
    - reference/demo_app/storybook/_primitives.index.exs
    - reference/demo_app/storybook/primitives/nav_link.story.exs
    - reference/demo_app/storybook/primitives/nav_pill.story.exs
    - reference/demo_app/storybook/primitives/tenant_chip.story.exs
    - reference/demo_app/storybook/primitives/theme_picker.story.exs
    - reference/demo_app/storybook/primitives/stat_card.story.exs
  modified:
    - .gitignore
    - reference/demo_app/mix.exs
    - reference/demo_app/mix.lock
    - reference/demo_app/lib/mailglass_demo_web/router.ex

key-decisions:
  - "Theme bridge via per-variation template-level data-theme (light = story template default, dark variations override template:), NOT the storybook color_mode class picker — color_mode only emits a CSS class, which the admin components do not key off."
  - "css_path is the absolute URL of the served committed bundle (/dev/mail/css-<md5>); the compile-time 'asset_hash not found' warning is harmless — the iframe emits @import \"<path>\" with no ?hash= suffix and the css-<md5> URL is already content-addressed."
  - "mix.lock curation: committed only phoenix_storybook + its genuine transitive deps (makeup*, mdex*, nimble_parsec, rustler_precompiled) + the storybook-required phoenix_live_view 1.1.x pin; reverted unrelated transitive drift (plug/plug_cowboy/premailex/swoosh that mix deps.get opportunistically re-bumps)."

patterns-established:
  - "Story inventory mirrors the existing gallery's structural.spec.js state enumeration so storybook and the ratchet gallery stay in lockstep."
  - "Dev-only review tooling lives in the demo app, never under mailglass_admin/lib/ (the :files glob would tarball it to adopters)."

requirements-completed: [METHOD-01, STORY-01]

coverage:
  - id: D1
    description: "Screenshot evidence cache is git-ignored before any harness runs (.planning/research/**/.cache/)"
    requirement: "METHOD-01"
    verification:
      - kind: integration
        ref: "git check-ignore -v .planning/research/v1.14/.cache/screenshots/x.png (exit 0); sibling DEFECT-REGISTER.md / STRESS-TEST-PROMPT.md exit 1 (not ignored)"
        status: pass
    human_judgment: false
  - id: D2
    description: "phoenix_storybook ~> 1.2 only: :dev mounted dev-only with hand-written backend + committed app.css sandbox; demo compiles; nothing under mailglass_admin/lib/"
    requirement: "STORY-01"
    verification:
      - kind: integration
        ref: "cd reference/demo_app && mix compile (Generated mailglass_demo app, clean apart from the harmless css_path-hash warning)"
        status: pass
      - kind: integration
        ref: "git diff ae120bb8~1 HEAD -- mailglass_admin/lib mailglass_admin/assets mailglass_admin/priv/static/app.css (empty — admin untouched)"
        status: pass
    human_judgment: true
    rationale: "Whether the sandbox actually renders the primitives styled + on-brand inside the explorer is a rendered/visual property — confirm by loading /dev/storybook against a running `make demo` and checking the @import resolves the committed bundle (research A1 verify step)."
  - id: D3
    description: "Initial foundations + 5-primitive story inventory compiles + validates; theme-sensitive components carry paired light/dark template-level data-theme"
    requirement: "STORY-01"
    verification:
      - kind: integration
        ref: "backend.load_story/1 for all 6 stories returns {:ok, _} with StoryValidator passing (foundations page + nav_link 6 / nav_pill 6 / tenant_chip 6 / theme_picker 5 / stat_card 13 variations)"
        status: pass
      - kind: integration
        ref: "grep -rn 'mailglass-light|mailglass-dark' reference/demo_app/storybook → 12 data-theme hits; no class->data-theme alias added to app.css"
        status: pass
    human_judgment: false

# Metrics
duration: 11min
completed: 2026-06-26
status: complete
---

# Phase 118 Plan 01: Method-Audit Storybook Stand-up Summary

**Dev-only phoenix_storybook (~> 1.2, only: :dev) mounted at /dev/storybook in the demo app, reusing the committed admin app.css as its sandbox stylesheet (zero new build), with a foundations + 5-primitive story inventory bridging themes via template-level data-theme — plus the Wave-0 .gitignore that protects the persona-critic screenshot cache.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-26T16:15:31Z
- **Completed:** 2026-06-26T16:26:06Z
- **Tasks:** 3
- **Files modified:** 12 (4 modified, 8 created)

## Accomplishments
- Git-ignored the persona-critic screenshot evidence cache (`/.planning/research/**/.cache/`) so the gsd commit seam never sweeps the ~80-120 evidence PNGs the Plan 03 harness produces — scoped narrowly so tracked sibling artifacts (DEFECT-REGISTER.md, story files, MILESTONE-SEED.md) stay tracked.
- Stood up a dev-only `/dev/storybook` review surface: `{:phoenix_storybook, "~> 1.2", only: :dev}`, a hand-written `MailglassDemoWeb.Storybook` backend (no `mix phx.gen.storybook` scaffold, no esbuild watcher), and a `live_storybook` + `storybook_assets()` mount inside the existing dev-only `/dev` scope.
- Wired the sandbox CSS to the already-served committed admin bundle (`css_path → /dev/mail/css-<md5>` via `Assets.css_hash/0`) — a plain `@import` URL, NOT a new Tailwind/esbuild build; `app.css` is untouched and the zero-Node adopter guarantee is preserved.
- Authored an initial story inventory (foundations page + the five named admin primitives) with the D-08 theme bridge: paired light/dark variations set `data-theme="mailglass-light|mailglass-dark"` at the template level on a `.mg-admin-root` root — no class→data-theme CSS alias anywhere.

## Task Commits

Each task was committed atomically:

1. **Task 1: .gitignore entry for the screenshot evidence cache** - `ae120bb8` (chore)
2. **Task 2: phoenix_storybook only: :dev + hand-written backend + dev-only router mount** - `19e48154` (feat)
3. **Task 3: foundations + primitives *.story.exs inventory with data-theme bridge** - `8a1371ba` (feat)

**Plan metadata:** _(this commit)_ (docs: complete plan)

## Files Created/Modified
- `.gitignore` - Added `/.planning/research/**/.cache/` to ignore the screenshot evidence cache (D-02).
- `reference/demo_app/mix.exs` - Added `{:phoenix_storybook, "~> 1.2", only: :dev}` to `deps/0`.
- `reference/demo_app/mix.lock` - New `phoenix_storybook` + genuine transitive deps (makeup*, mdex*, nimble_parsec, rustler_precompiled) + storybook-required `phoenix_live_view` 1.1.x; unrelated drift reverted.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - `import PhoenixStorybook.Router`, `storybook_assets()`, and `live_storybook "/storybook"` in the dev-only `/dev` scope.
- `reference/demo_app/lib/mailglass_demo_web/storybook.ex` - Hand-written `use PhoenixStorybook` backend: `sandbox_class: "mg-admin-root"`, `css_path → /dev/mail/css-<hash>`, no `js_path`.
- `reference/demo_app/storybook/foundations.story.exs` - `:page` documenting the sandbox + theme-bridge contract and brand palette.
- `reference/demo_app/storybook/_primitives.index.exs` - Orders the Primitives folder.
- `reference/demo_app/storybook/primitives/{nav_link,nav_pill,tenant_chip,theme_picker,stat_card}.story.exs` - Component stories pointing `function` at the public `MailglassAdmin.Components.<primitive>/1`, with paired light/dark template-level `data-theme` variations.

## Decisions Made
- **Theme bridge = per-variation template-level `data-theme`** (light is the story `template/0` default; dark variations override the `template:` field with a dark `.mg-admin-root` root). Chosen over `color_mode: true` because phoenix_storybook's color-mode only toggles a CSS *class*, and the admin components key off `data-theme` — a class would not switch them unless a forbidden class→data-theme alias were added to `app.css` (D-08).
- **`css_path` is the served bundle's absolute URL.** phoenix_storybook reads `css_path` from `priv/static/` only to compute a cache-busting hash; when the file is absent it logs a harmless warning and emits `@import "<path>"` with no `?hash=`. The `/dev/mail/css-<md5>` URL is already content-addressed, so the cache-buster is intrinsic — the warning is cosmetic and the sandbox styles from the committed bundle.
- **mix.lock curated** to commit only the intentional new dep + its genuine transitive closure, reverting the opportunistic plug/plug_cowboy/premailex/swoosh re-bumps that `mix deps.get` produces on every run (per the project's mix.lock integration-resolution policy + the demo_app swoosh-lock-drift memory).

## Deviations from Plan

None — plan executed exactly as written. (The `phoenix_live_view` downgrade to 1.1.x is not a deviation: it is a required consequence of phoenix_storybook 1.2.0 pinning `~> 1.1.0`, and the plan's mix.lock policy explicitly anticipates committing storybook's genuine transitive deps.)

## Issues Encountered
- **`mix verify.preview` reports `priv/static/app.css` drift** — a pre-existing, out-of-scope tooling condition (the documented "token-parity bundle landmine"): verify.preview runs a fresh daisyUI build that emits a raw-inline `@layer properties` block differing from the committed bundle, even with NO admin CSS change. Plan 01 added nothing under `mailglass_admin/` (`git diff ae120bb8~1 HEAD -- mailglass_admin/lib mailglass_admin/assets mailglass_admin/priv/static/app.css` is empty), so the Plan-01 invariant ("my changes don't alter app.css") holds. The verify.preview rebuild side-effect was reverted with `git checkout -- priv/static/app.css`. Logged to `deferred-items.md`; NOT fixed here (milestone-wide tooling issue — a blind rebuild+commit is explicitly cautioned against).
- **css_path-hash warning at compile** — `Can't resolve css_path: .../priv/static/dev/mail/css-<hash> not found`. Expected and harmless (see Decisions): the URL is served live, not from priv/static.

## User Setup Required
None - no external service configuration required. The storybook surface is dev-only; viewing it requires a running demo (`make demo`) and a browser at `/dev/storybook`.

## Next Phase Readiness
- The `/dev/storybook` review surface and story inventory are ready for the Plan 03 persona-critic harness to walk; the screenshot cache is safely git-ignored.
- The story inventory deliberately starts small (foundations + 5 primitives mirroring the gallery enumeration); groups/pages can expand as Phases 119+ need them — stories are review aids, not gates.
- **Visual confirmation pending (D2 human_judgment):** load `/dev/storybook` against a running `make demo` and confirm the primitives render styled + on-brand and the light/dark variations actually switch (the css_path @import resolving the committed bundle is research assumption A1's verify step).

## Self-Check: PASSED

- All 8 created files present on disk.
- All 3 task commits present in git history (`ae120bb8`, `19e48154`, `8a1371ba`).

---
*Phase: 118-method-audit-storybook-stand-up*
*Completed: 2026-06-26*
