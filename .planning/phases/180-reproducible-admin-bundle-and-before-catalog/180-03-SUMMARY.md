---
phase: 180-reproducible-admin-bundle-and-before-catalog
plan: 03
subsystem: admin-theme-ownership-browser-proof
tags: [playwright, e2e, theme, data-theme, daisyui, color-scheme, mutation-proof, advisory-lane]

requires:
  - phase: 180-reproducible-admin-bundle-and-before-catalog
    provides: "root-only theme ownership in lib (plan 02) and a byte-identical bundle gate (plan 01)"
provides:
  - "`e2e/theme-ownership.spec.js`: 37 browser cases (cookie x OS matrix over five surfaces, theme picker round trip, push_patch plus frame control, forced colours, back navigation, no-JS first response, iframe isolation, backdrop pixels)"
  - "`e2e/support/theme.cjs` (`applyThemeEmulation`, `setThemeCookie`, `openInTheme`) shared by the new and reworked specs"
  - "Gallery light/dark/system matrices re-expressed as one page load per theme in gallery-matrix and structural, with `<html>`-anchored theme assertions in structural, flows and phase168"
  - "A real-browser pixel observation of the Preview frame backdrop (closes 180-02 deliverable D5)"
affects: [180-04, 181-token-swap, 183-docs-pass]

actuals:
  tokens: 13990
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Theme is an OUTER per-page-load loop (cookie + emulated OS + goto); System is no cookie with the OS emulated dark"
    - "Assert ownership by counting every [data-theme] element (1 explicit, 0 System), not by reading shells"
    - "Compare computed tokens against <html>'s own value; luminance thresholds replace hex literals"

key-files:
  created:
    - mailglass_admin/e2e/support/theme.cjs
    - mailglass_admin/e2e/theme-ownership.spec.js
  modified:
    - mailglass_admin/e2e/gallery-matrix.spec.js
    - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - reference/demo_app/assets/e2e/persona-screenshots.spec.js
    - reference/demo_app/assets/e2e/phase178-stories.spec.js
    - .planning/phases/180-reproducible-admin-bundle-and-before-catalog/deferred-items.md

key-decisions:
  - "Kept every pinned test title and `test.setTimeout` bound (timeout_evidence_ci_contract_test.exs, bucket_a_coverage_test.exs read them); the theme loop moved inside the existing tests instead of renaming them"
  - "System is `no cookie` with the OS emulated dark in every per-theme loader, so a pass proves System follows the OS rather than defaulting to light"
  - "The frame backdrop pixel check decodes an element screenshot in-page and compares luminance (light above 0.9, dark below 0.05), so it does not hard-code a browser's Canvas colour"
  - "Did not edit the Preview axe cell test that times out in suite; recorded with measurements in deferred-items.md item 4"

requirements-completed: [BRPIPE-02]

coverage:
  - id: D1
    description: "In a real browser, for cookie {light, dark, none} x emulated OS {light, dark}, `<html>` is the only [data-theme] owner (exactly [html] for explicit cookies, none for System) and computed --color-base-100 and color-scheme on the shell, visible Preview pane, open operator-quick-view dialog, gallery specimen and root-layout toast equal <html>'s, with base-100 luminance above 0.8 resolved-light and below 0.2 resolved-dark, on Preview show, Preview index, operator list, operator detail with the dialog open, and the gallery"
    requirement: BRPIPE-02
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/theme-ownership.spec.js (30 matrix cases; advisory operator_browser_gate, never the required proof)"
        status: pass
      - kind: integration
        ref: "mutations: nested data-theme on the preview tabpanel (6 of 6 preview show cases red), on the shared shell root plus a gallery specimen (33 of 37 red); each restored with git checkout and re-run green"
        status: pass
    human_judgment: false
  - id: D2
    description: "The real picker round trip light -> dark -> system, a push_patch scenario switch, the Preview frame control (changes only preview-frame-backdrop), the no-JS first response, the email iframe document (no [data-theme], empty --color-base-100, about:srcdoc), forced-colours focus outline (solid 2px), and a back-navigation probe all hold"
    requirement: BRPIPE-02
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/theme-ownership.spec.js#theme ownership: controls and #first response and iframe (7 cases)"
        status: pass
      - kind: integration
        ref: "mutation: preview_frame_color_scheme(true) returns light -> push_patch plus frame control case and pixel case red"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Preview html pane backdrop paints the intended pixels in a real browser with the final wrapper structure: frame light rgb(255,255,255), frame dark rgb(18,18,18), identical under admin light and admin dark (closes 180-02 D5)"
    requirement: BRPIPE-02
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/theme-ownership.spec.js#Preview frame backdrop pixels"
        status: pass
    human_judgment: false
  - id: D4
    description: "Existing admin e2e specs that pinned a nested theme attribute (structural, flows, gallery-matrix, phase168) assert the root-owner contract or load the gallery once per theme, with nothing deleted without a replacement; admin-assets and phase176-filters pass unchanged; axe baseline spec runs unpersisted and docs/axe-baseline.json is unchanged; bundle byte-identical after the suite's rebuild"
    requirement: BRPIPE-02
    verification:
      - kind: e2e
        ref: "npm run test:operator-browser: 353 passed, 1 failed, 1 skipped; the one failure is structural.spec.js:2655 (Preview axe cell timeout, deferred-items.md item 4), a test this plan did not edit; git diff --quiet -- mailglass_admin/priv/static mailglass_admin/docs/axe-baseline.json exits 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "The demo specs reworked here (persona-screenshots, phase178-stories StatCard production half) pass in the advisory demo lane"
    requirement: BRPIPE-02
    verification:
      - kind: other
        ref: "node --check on both files plus the plan greps; the production-gallery half reproduced verbatim as a throwaway spec against the admin OperatorBrowserServer (1 passed). Not run on the demo: make demo failed to start (deferred-items.md item 5)"
        status: unknown
    human_judgment: true
    rationale: "The Docker demo did not start locally, so the Storybook halves and the persona spec have not executed. The advisory demo_browser_evidence lane is the executing lane; the verifier classifies D5 from that run."

duration: 74min
completed: 2026-11-15
status: complete
commits: 5
plan_head_before: a649709ab9fc7d599c41c6867505dee507263378
plan_head_after: 75301e9035191a469e41895c4d0b2d6f8dfc483c
---

# Phase 180 Plan 03: Theme-Ownership Browser Proof Summary

**A 37-case Playwright spec now shows in a real browser that `<html>` alone owns the admin theme on five surfaces for every cookie x OS combination (computed tokens and color-scheme on the shell, pane, quick-view dialog, gallery specimen and toast equal `<html>`'s), the Preview frame backdrop paints rgb(255,255,255) or rgb(18,18,18) independent of the admin theme, and every structural, flow, gallery and persona spec that pinned a nested theme attribute was reworked to the root-owner contract; the full operator browser suite is 353 passed with one unrelated axe-cell timeout recorded, not edited.**

## Performance

- **Duration:** 74 min (4,429 s wall clock, much of it the three full-suite runs and the axe-stall investigation)
- **Started:** 2026-11-15T00:42:36Z
- **Completed:** 2026-11-15T01:56:25Z (SUMMARY write; last task commit earlier)
- **Tasks:** 3 of 3 (Task 1 was the tracer)
- **Files modified:** 2 created and 6 modified e2e files, plus `deferred-items.md` and this SUMMARY

## Accomplishments

- **Tracer (Task 1).** `e2e/support/theme.cjs` and the Preview-show matrix. The tracer gate re-ran the plan's verify against the final tree before expanding: `-g "preview show cookie=dark os=light"` 1 passed, and the six `preview show` cases 6 passed. Research had measured this exact check red at HEAD 7a848162 in two of four combinations (pane `#f8fbfd` against `<html>` `#0d1b2a`); it is green on the root-owner tree, and a live mutation (re-adding `data-theme="mailglass-light"` on the tabpanel) turned all six red with the element list expected `[html]`/`[]` and received four to six elements. Restored with `git checkout --`.
- **Every surface and control (Task 2).** `theme-ownership.spec.js` grew to 37 cases: 30 matrix cases (Preview show, Preview index, operator list, operator detail with the `operator-quick-view` dialog open, gallery, each cookie x OS), plus the picker round trip (Light, Dark, System, each a full redirect, re-asserted each time), a `push_patch` scenario switch and the frame control (only `preview-frame-backdrop` changes; html, shell and pane tokens stay equal), forced colours (focused picker segment keeps `outline` solid 2px), a back-navigation probe, the no-JS first response (raw response `<html>` tag and a scripting-disabled load, with the LiveView verified never to connect), and iframe isolation (`about:srcdoc`, zero `[data-theme]`, empty `--color-base-100`).
- **Gallery matrices (Task 2).** `gallery-matrix.spec.js` and `structural.spec.js` load the gallery once per theme with `openInTheme`; the width loops, overflow and 320 px clipping checks, the allowlist and composed-inner exclusions are unchanged. "System wrapper has no data-theme" became "no element inside the cell carries data-theme". `phase168-plan03-acceptance.spec.js` assertions moved from the shells to `<html>` plus a `[data-theme]` count.
- **Structural and flows (Task 3).** Every `preview-shell`/`preview-pane` theme-attribute assertion became `expectRootTheme` (html attribute plus a count of 1 or 0) plus "shell and pane carry no theme attribute"; the frame toggle reads `preview-frame-backdrop` for the before/after background and `color-scheme`; the FLOW-03 picker asserts on `<html>`; the composed-group specimens read one specimen from a light page load; the inbound contrast matrix and A16-system anchor on `<html>`. The D-08 "swap never animates" test is unchanged (it already set the attribute on the root).
- **Backdrop pixels (closes 180-02 D5).** An element screenshot of `preview-frame-backdrop`, decoded in-page, sampled in the wrapper's top padding: frame light rgb(255,255,255), frame dark rgb(18,18,18), identical under admin light and admin dark.
- **Demo specs (Task 2).** `persona-screenshots.spec.js` reads the `dark_selected` cell's Dark radio directly. `phase178-stories.spec.js` loads the production gallery once per theme (cookie, `emulateMedia`, goto), asserts `<html>` owns the theme, the specimen has no nested scope and its `--color-base-100` equals `<html>`'s, then reads the font roles; the Storybook halves are untouched.

## Task Commits

1. **Task 1 (tracer): theme helper and Preview matrix** - `6f674d80` test(admin): add the theme-ownership browser matrix for the preview surface
2. **Task 2: every surface, gallery matrices, demo specs**
   - `0228db9f` test(admin): cover every admin surface and control in the theme-ownership matrix
   - `cfb6242b` test(admin): load the gallery once per theme in browser matrices
   - `68516cfc` test(demo): read the gallery theme picker specimen without a nested theme scope
3. **Task 3: structural and flows** - `75301e90` test(admin): assert the root html owns the theme in structural and flow specs

**Plan metadata:** the `docs(180-03)` commits that add this SUMMARY and `deferred-items.md`, then STATE.md, ROADMAP.md and REQUIREMENTS.md.

## Evidence (all commands run from `mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`)

| Check | Command | Result |
|---|---|---|
| Task 1 verify | `npx playwright test --config=playwright.config.cjs --workers=1 e2e/theme-ownership.spec.js -g "preview show cookie=dark os=light"` | 1 passed (2.6 s) |
| Phase gate: six preview cases | same, `-g "preview show"` | 6 passed (12.3 s) |
| Whole new spec | `... e2e/theme-ownership.spec.js` | 37 passed (14.3 s) |
| Task 2 smoke | `... --grep @smoke180 e2e/theme-ownership.spec.js e2e/gallery-matrix.spec.js e2e/phase168-plan03-acceptance.spec.js` | 12 passed |
| Task 3 smoke | `... --grep @smoke180 e2e/structural.spec.js e2e/flows.spec.js` | 7 passed; `git diff --quiet -- priv/static docs/axe-baseline.json` exit 0 |
| Phase gate: eight files, PERSIST_AXE_BASELINE unset | `... e2e/theme-ownership.spec.js e2e/gallery-matrix.spec.js e2e/phase168-plan03-acceptance.spec.js e2e/structural.spec.js e2e/flows.spec.js e2e/admin-assets.spec.js e2e/phase176-filters.spec.js e2e/axe-baseline.spec.js` | 268 passed, 1 failed, 1 skipped (6.0 min) |
| Phase gate: full suite | `npm run test:operator-browser` (rebuilds the bundle first: `Done in 134ms`) | 353 passed, 1 failed, 1 skipped (6.8 min); `git diff --quiet -- priv/static docs/axe-baseline.json` exit 0 |
| ExUnit contracts that read e2e sources | `mix test test/mailglass_admin/bucket_a_coverage_test.exs` (admin); `mix test test/scripts/timeout_evidence_ci_contract_test.exs` (root) | 9 tests, 0 failures; 3 tests, 0 failures |
| Evidence-checker node tests | `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs` | 42 pass, 0 fail |
| Demo production half (throwaway, not committed) | the verbatim per-theme loop against the admin `OperatorBrowserServer` | 1 passed; Inter 400 / Inter 700 / IBM Plex Mono 700 in light and dark |

The one failure in both gate runs and the one skip: failure `structural.spec.js:2655` "Preview: Phase 178 axe cell matches the committed baseline" (see Issues Encountered); skip `structural.spec.js:3652` (the guarded "header-anchored overlay transform-origin ... IF such an overlay exists" conditional skip, pre-existing and unrelated).

The full suite rewrites screenshots under `.planning/milestones/v2.9-phases/168-*/artifacts` and `169-*/artifacts` (`scripts/gsd-regression-gate.sh` backs these up and restores them for the same reason). I restored them with `git checkout -- <those two artifact directories>`; `git status --short` was clean afterwards.

### Lane table (which lane proves what)

| Proof | Lane |
|---|---|
| Document counts, gallery structure, static scan, detectors: `root_theme_ownership_contract_test.exs`, reworked `admin_shell_test.exs` and `preview_live_test.exs` (plan 180-02) | REQUIRED: `support_contract_admin`; this is the required proof of BRPIPE-02 |
| `theme-ownership.spec.js`, reworked structural/flows/gallery-matrix/phase168 | ADVISORY: `operator_browser_gate` (`config/quality/ci_policy.exs:145`); never cited as the required proof |
| Reworked demo `persona-screenshots.spec.js` and `phase178-stories.spec.js` | ADVISORY: `demo_browser_evidence`; not executed locally (item 5 in deferred-items) |

## D-14 bfcache record

**bfcache: not reproduced** by the back-navigation test (`back navigation shows the cookie's theme, not the previous document's`: operator page, click Dark, go to `/dev/mail`, `page.goBack()`, `<html data-theme>` equals `mailglass-dark`). Scope of that statement: Playwright launches Chromium with `--disable-back-forward-cache` (`playwright-core/lib/server/chromium/chromiumSwitches.js:59`), so this probe exercises HTTP-cache restoration of the old document, not the real bfcache. No `pageshow` reload or `no-store` header was added; D-14 says to add one only when a test shows a stale theme, and none did. A real-bfcache check would need a headed Chromium or Safari, which this advisory lane does not run.

## Mutation Protocol (METHODOLOGY), local evidence

| Mutation | Result |
|---|---|
| `data-theme="mailglass-light"` re-added on the Preview tabpanel (`preview/tabs.ex`) | all 6 `preview show` cases red (`[data-theme]` elements expected `[html]`/`[]`, received 4 to 6) |
| `data-theme="mailglass-light"` added to the shared shell root (`admin_shell.ex`) and to the gallery specimen wrapper (`gallery_live.ex`) | 33 of 37 red (every matrix surface, picker round trip, push_patch plus frame, no-JS); the 4 still green (forced colours, back navigation, iframe, pixels) assert other properties |
| `preview_frame_color_scheme(true)` returns `"light"` (`preview/tabs.ex`) | the push_patch plus frame-control case (`the backdrop wrapper color-scheme flips`) and the pixel case red; picker, forced colours and back navigation stayed green |

Each was restored with `git checkout -- <file>`; `git status --short` showed only the intended e2e edits afterwards.

## Decisions Made

- Test titles and `test.setTimeout(...)` bounds that `timeout_evidence_ci_contract_test.exs` and `bucket_a_coverage_test.exs` pin were kept. The three structural tests whose titles still say "wrappers" keep them for that reason; their bodies load the gallery once per theme.
- The no-JS test asserts three things: the raw first response's `<html>` tag, the DOM of a scripting-disabled load, and that the LiveView never connects (proving scripting really was off).
- The frame-backdrop pixel check samples the wrapper's top padding strip, clear of the rounded corners and the iframe, from an element screenshot decoded in-page; it asserts luminance and equality across admin themes.

## Deviations from Plan

### Auto-fixed Issues

None. No lib, config or bundle file changed in this plan (`git diff --quiet -- mailglass_admin/lib mailglass_admin/priv/static mailglass_admin/docs/axe-baseline.json` is clean), and the temporary lib mutations and the profiling checkouts of the 7a848162 `tabs.ex` were all reverted.

### Recorded, not fixed

**1. [Scope boundary] One suite failure, structural.spec.js:2655 (Preview axe cell), recorded as deferred item 4**
- **Found during:** Task 3 phase gate (4 of 4 suite or subset runs; the same test passes alone in 32.7 s).
- **Issue:** the test scans three themes in one 90 s body; `@axe-core/playwright` stalls about 30 s per scan inside the script-disabled email `srcdoc` iframe once the page has settled.
- **Evidence it is not a theme-ownership defect:** with the 7a848162 `tabs.ex` restored and the page allowed to settle, axe stalls 29.2 s on 4 of 4 scans (8 of 8 on the 180-02 tree); scans that start before the LiveView connect take ~1.1 s on both. Caveat: in the unsettled harness the pre-180 `tabs.ex` passed 7 of 7 runs and the 180-02 `tabs.ex` failed 4 of 4, so the 180-02 markup moved a race across its timing window (cause not isolated under a 20 to 55 load average).
- **Disposition:** not edited (one concern per plan); `axe-baseline.spec.js` and `docs/axe-baseline.json` untouched. Suggested follow-up and exact `exclude` selector are in `deferred-items.md` item 4.

**2. [Environment] Demo specs not run on the demo**
- `make demo` (isolated project `mailglass-demo-180`, ports 4045/5445) exited 1 inside the container (`could not load /workspace/mailglass_admin/mix.exs ... enoent`); torn down with `docker compose -p mailglass-demo-180 down -v`. Syntax and plan greps pass; the production-gallery half was reproduced against the admin server (1 passed). Coverage D5 is therefore `human_judgment: true` pending the advisory demo lane (deferred item 5).

**3. [Process] Added work beyond the plan text**
- The backdrop pixel test (closes 180-02 D5) was requested by the orchestrator guidance, not by the plan task text. The throwaway profiling and mutation helpers lived only in the scratchpad or were deleted before commit.

**4. [Process] Commit subjects follow the plan's `test(admin):`/`test(demo):` scope** (as in plans 180-01 and 180-02). The authoritative record is `plan_head_before..plan_head_after` in the frontmatter (5 commits, measured with `git rev-list --count`).

---

**Total deviations:** 0 auto-fixed, 1 recorded failure (unrelated test), 1 environment limit, 2 process notes. **Impact on plan:** the browser half of BRPIPE-02 is complete and green except one pre-existing-in-kind axe stall; nothing in `lib/` changed.

## Issues Encountered

- **Axe stall, structural.spec.js:2655.** Described above and in `deferred-items.md` item 4. It makes the advisory full suite 353 passed, 1 failed, 1 skipped instead of fully green. The 180-02 required lane is unaffected.
- **Docker demo would not start.** Item 5. No repository file changed (checked with `git status`).
- **Machine load.** The load average sat between 20 and 55 during the investigation, so absolute timings are noisy; the 29.2 s stall is the stable signal.

## Known Stubs

None.

## Threat Flags

None. T-180-10 (an advisory run claimed as required proof) is mitigated: the spec header, this SUMMARY's lane table and the plan verification all name `root_theme_ownership_contract_test.exs` in `support_contract_admin` as the required proof. T-180-11 (assertions deleted without replacement) is mitigated: every removed nested-attribute assertion has an `<html>`-anchored or per-theme-load replacement, the acceptance greps hold, and the gallery matrix keeps every width and theme. T-180-12 (timing flake) is accepted as planned: new assertions use auto-waiting expects and `.phx-connected`, never `networkidle`. T-180-SC: no package was added.

## Follow-ups

- **Owner decision, test scope:** exclude the email iframe from the Phase 178 axe cell test (and, together with Phase 181's single baseline regeneration, from `axe-baseline.spec.js`); see `deferred-items.md` item 4.
- **Run the reworked demo specs** in the advisory demo lane (`make demo-e2e`, or `npx playwright test e2e/phase178-stories.spec.js -g "StatCard"` plus `persona-screenshots.spec.js` in `reference/demo_app/assets` against a running demo).
- Carried from 180-02: gallery duplicate ids (item 3), `WINDOWS.md` row 48, and CLAUDE.md "Things Not To Do" #6 (Phase 183 docs pass).

## Release effect

Test-only. The five commits are `test(admin):` and `test(demo):` touching `mailglass_admin/e2e` (excluded from the release) and `reference/demo_app/assets/e2e`; none touches `mailglass_admin/lib` or `priv/static`, so no package bump follows from this plan. `.planning/release-target.json` and every release config are untouched.

## Next Phase Readiness

- Plan 180-04 (catalog) captures on a tree where the browser proof is in place: `theme-ownership.spec.js` already shows `nested_theme_attr_count` would be 0 on every surface, and `e2e/support/theme.cjs` is the cookie plus `emulateMedia` recipe the capture script can reuse.
- Phase 181 edits `brandbook/tokens.css`: the new spec compares computed values against `<html>`'s own tokens and thresholds luminance, so it needs no edit for a token swap. The Preview axe-cell decision (follow-up above) should land before the baseline regeneration.

---
*Phase: 180-reproducible-admin-bundle-and-before-catalog*
*Completed: 2026-11-15*

## Self-Check: PASSED

- Created and modified files exist on disk: `theme.cjs`, `theme-ownership.spec.js`, `gallery-matrix.spec.js`, `phase168-plan03-acceptance.spec.js`, `structural.spec.js`, `flows.spec.js`, the two demo specs, `deferred-items.md`.
- All five task commits are ancestors of HEAD: `6f674d80`, `0228db9f`, `cfb6242b`, `68516cfc`, `75301e90`.
- `git diff --quiet -- mailglass_admin/lib mailglass_admin/priv/static mailglass_admin/docs/axe-baseline.json` exits 0 (no lib, bundle or axe baseline change); working tree clean apart from this SUMMARY and `deferred-items.md`.
- Acceptance greps hold: `module.exports` in `theme.cjs` 1; `operator_browser_gate` in the spec header 1; hex literals `0d1b2a`/`f8fbfd` in the spec 0; `themeWrapper` in gallery-matrix 0; `javaScriptEnabled: false` 1; `forcedColors` 1; `goBack` 1; structural `data-theme="mailglass-${theme}"` 0, `preview-shell")).toHaveAttribute("data-theme"` 0, `data-theme="${theme.expectedTheme}"` 0; demo `[data-theme="mailglass-dark"]` in persona 1, gallery `cell.locator(\`[data-theme=` in phase178 0, `gallery-stat_card-neutral-system` 1, `emulateMedia` 2, `data-theme-owner` 1.
