---
phase: 180-reproducible-admin-bundle-and-before-catalog
plan: 02
subsystem: admin-theme-ownership
tags: [theme, data-theme, daisyui, color-scheme, liveview, exunit-contract-test, mutation-proof]

requires:
  - phase: 180-reproducible-admin-bundle-and-before-catalog
    provides: "the --check bundle drift gate (plan 01) that proves every lib edit here leaves the compiled CSS byte-identical"
provides:
  - "`<html>` (layouts/root.html.heex) is the only owner of the theme attribute across lib and every rendered admin document"
  - "Preview frame light/dark toggle as a `preview-frame-backdrop` wrapper using `color-scheme` and `background: Canvas`, iframe pinned to `color-scheme: light`, sandbox unchanged"
  - "Gallery renders one specimen per component state in the current admin theme"
  - "`root_theme_ownership_contract_test.exs`: 23 required-lane cases (document counts x4 surfaces x3 modes, gallery structure, static scan, detector teeth)"
affects: [180-03, 180-04, 181-token-swap, 183-docs-pass]

actuals:
  tokens: 7540
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Detectors written as pure functions of (path, source) so the same code scans lib and is proven on planted violations"
    - "Count the theme attribute in the whole dead-render document (live/2 returns the root layout) instead of asserting on a nested fragment"
    - "A frame toggle is a wrapper `color-scheme` + `Canvas`, never a token set"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/admin_shell.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/mailglass_admin/admin_shell_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - .planning/phases/180-reproducible-admin-bundle-and-before-catalog/deferred-items.md

key-decisions:
  - "Delete every nested theme owner (D-11) rather than keep Preview and Gallery as intentional scopes; the root layout is the single owner"
  - "Static scan flags token DECLARATIONS (`--mg-x:` / `--color-x:`) anywhere in lib text, a superset of the required inline-style and arbitrary-class forms; JS `setProperty` of a layout metric (`--mg-tooltip-arrow-x`) is deliberately not flagged"
  - "Gallery duplicate ids are floored at 39 (measured), not asserted zero: the remaining ids are component-owned and out of this plan's files (deferred-items.md item 3)"
  - "Backdrop wrapper adds `width: max-content; min-width: 100%` inline so the Canvas stage extends under a wide iframe; no new CSS rule, bundle unchanged"

requirements-completed: [BRPIPE-02]

coverage:
  - id: D1
    description: "Only `<html>` carries the theme attribute in the preview show, operator, inbound and gallery documents: exactly one (value mailglass-dark or mailglass-light) for an explicit cookie, zero for system"
    requirement: BRPIPE-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs#document-level theme ownership (12 cases: preview show, operator, inbound, gallery x dark/light/system)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Preview frame toggle keeps `data-preview-frame-theme` as a state marker, carries no theme attribute, drives a `preview-frame-backdrop` wrapper (`color-scheme: light|dark; background: Canvas`) around an iframe pinned to `color-scheme: light` with no admin-token background, and the iframe sandbox stays exactly `allow-same-origin`"
    requirement: BRPIPE-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#dark toggle (frame toggle drives the backdrop wrapper without changing the root theme; iframe stays pinned to a light, transparent, script-disabled document; backdrop only changes HTML and text panes)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The gallery renders one specimen wrapper per component state, the document mounts with live/2, and duplicated id values cannot grow past the post-collapse floor (182 to 39)"
    requirement: BRPIPE-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs#gallery renders one specimen per state"
        status: pass
    human_judgment: false
  - id: D4
    description: "No file under mailglass_admin/lib other than layouts/root.html.heex sets the theme attribute, and none assigns `--mg-*` or `--color-*` in an inline style, arbitrary-property class or css text; planted violations of each form go red"
    requirement: BRPIPE-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs#static ownership scan and #detectors have teeth"
        status: pass
      - kind: integration
        ref: "mutation A (shell attribute re-added) and mutations B1/B2 (planted inline style and arbitrary class): contract file red, restored green; mutations C/D on tabs.ex red in preview_live_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "The Preview html pane paints the intended pixels in a real browser (frame dark 121212/1E1E1E, frame light FFFFFF, independent of admin theme) with the final wrapper structure"
    requirement: BRPIPE-02
    verification: []
    human_judgment: true
    rationale: "The wrapper was pixel-probed in a standalone Chromium and WebKit page during research, not in the app with the added padding and max-content width. The browser proof is plan 180-03's Playwright spec in the advisory operator_browser_gate lane; the required-lane proof here is the markup and style contract. The verifier classifies it from the 180-03 run."

duration: 9min
completed: 2026-11-15
status: complete
commits: 6
plan_head_before: 846ede067a58b5870b67aae649742be79bdcb2e5
plan_head_after: 06a8ff24b1b9bac02c72a6847795357065655608
---

# Phase 180 Plan 02: Root-Only Theme Ownership Summary

**`<html>` is now the only element that carries the admin theme attribute: five nested owners (shell, two shell callers, the Preview html/text tab panels, two gallery specimen wrappers) were deleted, the Preview frame toggle became a `color-scheme` + `Canvas` wrapper, and a 23-case required-lane contract test counts the attribute in every dead-render document (1 for light or dark, 0 for system) and statically scans `mailglass_admin/lib` for nested owners and token re-declarations.**

## Performance

- **Duration:** 9 min (518 s wall clock)
- **Started:** 2026-11-15T00:31:26Z
- **Completed:** 2026-11-15T00:40:04Z (last task commit; SUMMARY follows)
- **Tasks:** 3 of 3 (Task 1 was the tracer)
- **Files modified:** 7 source and test files, 1 created test file, plus this SUMMARY and `deferred-items.md`

## Accomplishments

- **Red first, recorded before any lib edit (RESEARCH Code Examples 3).** `root_theme_ownership_contract_test.exs` ran against unmodified lib code and failed with exactly the predicted occurrence counts (identical Floki element count and `\sdata-theme=` regex count in every case):

  | Surface | cookie dark | cookie light | system |
  |---|---|---|---|
  | Preview show | 4 | 4 | 2 |
  | Operator | 2 | 2 | 0 (passes) |
  | Inbound | 2 | 2 | 0 (passes) |
  | Gallery (`get/2`) | 245 | 245 | 244 |

  10 of 12 cases red. The system-mode preview count of 2 is the defect in its purest form: the html and text panels forced `mailglass-light` with no cookie at all.
- **Tracer: shells (D-11).** `theme_attr` attr, the attribute on the shell root, both callers (`operator/shell.ex`, `preview_live.ex`) and the now-unused `admin_theme_attr/1` were deleted in one commit so `--warnings-as-errors` never saw an undeclared attribute. The `mg-admin-root` class stays (D-14, `check-conformance.sh`). Operator and inbound went 2/2/0 to 1/1/0. After this task Preview measured 3/3/2, as predicted.
- **Preview pane (D-12 as refined by F4).** The nested attribute and `preview_frame_data_theme_attr/2` are gone. `data-preview-frame-theme` stays as the state marker. The email iframe sits in `data-testid="preview-frame-backdrop"` whose inline style is `color-scheme: light|dark; background: Canvas; width: max-content; min-width: 100%;` (derived only from the `@preview_frame_dark_chrome` boolean). The iframe is pinned `color-scheme: light`, lost its `background: var(--color-base-100)`, and keeps `sandbox="allow-same-origin"`, `phx-update="ignore"`, id and title. Text, headers and raw tabs follow the admin theme. No token is assigned anywhere.
- **Gallery.** The light and dark specimen wrappers were deleted; the `-system` wrapper, its testid and `specimen_id` suffix are unchanged. Moduledoc rewritten (keeps `/dev/mail/gallery`, contains no theme-attribute literal). Gallery document counts went 245/245/244 to 1/1/0.
- **Static scan with teeth (D-13).** Pure-function detectors scan all 64 `lib/**/*.{ex,heex}` files: the theme attribute (as markup, as a quoted attribute name, or `dataset.theme =`) is allowed only on the `<html` line of `mailglass_admin/layouts/root.html.heex`; any `--mg-*`/`--color-*` declaration is rejected. Eight planted violation shapes and eight clean controls pin both directions; failure messages name `file:line` and the fix.
- **Lane green.** `mix verify.support_contract.admin`: bundle check line, then `1341 tests, 0 failures, 1 excluded` (plan 01 baseline 1318 plus 23).

## Task Commits

1. **Task 1 (tracer): root-only theme on the operator and inbound shells**
   - `750a3d99` fix(admin): let the root html element own the admin theme on the shells (3 lib files, -6 lines)
   - `26e0344f` test(admin): prove the operator and inbound shells carry no nested theme (contract test created, `admin_shell_test.exs` reworked)
   - Tracer gate: `<verify>` (5 test files, 329 tests, 0 failures; `--check` exit 0; `check-conformance.sh` clean) re-run against the final tree before expanding: Tracer verified end-to-end, expanding.
2. **Task 2: Preview pane backdrop**
   - `40efc42d` fix(admin): stop forcing light tokens on the preview pane and frame the email with color-scheme (`tabs.ex`)
   - `6f6573f1` test(admin): pin root-only theme and the color-scheme frame backdrop on preview (`preview_live_test.exs`, contract test)
3. **Task 3: Gallery collapse, static scan, mutation proof, full lane**
   - `aed2d578` fix(admin): render one gallery specimen per state in the current theme (`gallery_live.ex`)
   - `06a8ff24` test(admin): scan admin templates for nested theme owners and token re-declarations (contract test)

**Plan metadata:** the `docs(180-02)` commits that add this SUMMARY and `deferred-items.md`, then STATE.md, ROADMAP.md and REQUIREMENTS.md.

## D-15 Classification of Each Removal (no visible regression claimed where none was reproduced)

| Removal | Classification | Evidence |
|---|---|---|
| `admin_shell.ex` theme attribute, `theme_attr` attr, `operator/shell.ex` and `preview_live.ex` callers, `admin_theme_attr/1` | **Latent-defect fix.** No visible shell-versus-`<html>` disagreement was reproduced in any current render path (the shell was always handed the same value `<html>` received). | Counts 2/2/0 to 1/1/0; no pixel claim made |
| `preview/tabs.ex` nested theme on the html and text tab panels | **Demonstrated defect.** Under admin dark or system-dark the html/text panes were painted with the light token set (`#f8fbfd` against `<html>` `#0d1b2a`, browser-measured in RESEARCH Code Examples 4). Server-side evidence: system-mode preview count 2 with no cookie. | Red-first count 4/4/2; green 1/1/0 |
| `gallery_live.ex` light and dark specimen wrappers | **Latent-defect fix, plus an incidental one.** The wrappers re-declared the token set per column; the audit page showed three columns where one theme was in force. Collapsing also removes the threefold specimen copies: distinct duplicated id values drop from 182 to 39. | Gallery 245/245/244 to 1/1/0 |

## Named Visible Change (D-15)

The Preview HTML-tab backdrop toggle ("Preview background", Light/Dark) used to repaint the **whole panel** (every token inside the panel, via the nested attribute). It now repaints only the **email stage**: the `preview-frame-backdrop` wrapper (`color-scheme` + `Canvas`), with the panel padding keeping admin tokens. The text tab no longer changes with that toggle at the token level either; it follows the admin theme. This is a visible behaviour change with no token, font, logo or copy change. `e2e/flows.spec.js:871` asserts the pane background changes on toggle; plan 180-03 reworks that assertion.

## Mutation Protocol (METHODOLOGY), local evidence

Baseline 23 contract cases green. Each mutation was applied, the touched file(s) run, then restored with `git checkout --` and re-run green:

| Mutation | Red result |
|---|---|
| A: re-add the shell attribute (`attr` + attribute + operator caller) | 4 document-count cases (operator and inbound, dark and light, 2 found) plus the static scan naming `mailglass_admin/admin_shell.ex:33` (5 failures) |
| B1: `style="--color-base-100: #fff"` on the tabs root | static scan names `preview/tabs.ex:33` (1 failure) |
| B2: class `[--mg-color-background:#fff]` on the tabs root | static scan names `preview/tabs.ex:33` (1 failure) |
| C: `sandbox="allow-same-origin allow-scripts"` in `tabs.ex` | `preview_live_test.exs` iframe case and the tabs artifact case (2 failures); the grep gate `grep -c 'sandbox="allow-same-origin"'` prints 0 |
| D: delete the `data-preview-frame-theme` state marker | three `preview_live_test.exs` cases (3 failures) |

All restored: `git status --short` showed only intended edits, contract file 23 tests, 0 failures.

## Evidence (local unless it names a CI run)

- **Lane:** `cd mailglass_admin && mix verify.support_contract.admin` exit 0; output `Admin bundle matches a fresh build (136877 bytes).` then `1341 tests, 0 failures, 1 excluded`.
- **Bundle:** `MIX_ENV=test mix mailglass_admin.assets.build --check` green after every lib edit; `git diff --quiet 7a848162 -- brandbook mailglass_admin/priv/static mailglass_admin/lib/mailglass_admin/copy.ex` exits 0 (no token, font, logo or copy change).
- **Conformance and format:** `bash scripts/check-conformance.sh` exit 0 (`OK: design-system conformance clean.`); `mix format --check-formatted` inside `mailglass_admin` exit 0; `mix credo --strict` on the eight touched files: no issues.
- **Coverage floor (A4/P4):** `MIX_ENV=test mix coveralls.json --output-dir <scratch> test --warnings-as-errors` then `scripts/check_coverage_floor.sh config/coverage_baselines/admin.json`: exit 0. Measured **5672/6530 (86.86%)** against the baseline 3334/3992 (83.52%): no baseline edit and no extra tests needed. (The report was written to a scratch directory; the repo `coverage/` path was not touched.)
- **Acceptance greps:** `theme_attr`/`admin_theme_attr` occurrences in lib 0; `data-theme=` in lib outside `layouts/root.html.heex` 0; `mg-admin-root` in `admin_shell.ex` 1; `preview_frame_data_theme_attr` 0; `preview-frame-backdrop` 1; `background: Canvas` 1; `data-preview-frame-theme` 1; `sandbox="allow-same-origin"` 1; `gallery-#{component}-#{state}-system` 1; `/dev/mail/gallery` in `gallery_live.ex` 2.
- **Unedited pins stayed green:** `router_test.exs`, `operator_live_test.exs:2760,2777`, `inbound_live_test.exs:2665,2683`, `token_parity_test.exs`, `persona_drift_guard_test.exs`.

### Lane table (which lane proves what)

| Proof | Lane |
|---|---|
| Document counts, gallery structure, static scan, teeth, reworked `admin_shell_test.exs` and `preview_live_test.exs` | REQUIRED: `support_contract_admin` only |
| Computed-style and pixel proof of the backdrop in a real browser | ADVISORY (plan 180-03, `operator_browser_gate`); never cited as the required proof |

## Files Created/Modified

- `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs` - NEW, 23 cases, 343 lines
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex` - `theme_attr` attr and attribute removed
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `preview_live.ex` - callers and `admin_theme_attr/1` removed
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` - nested attribute and helper removed; backdrop wrapper, `preview_frame_color_scheme/1`, `preview_frame_dark_chrome` attr on `tab_content/1`
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - two specimen wrappers removed, moduledoc rewritten
- `mailglass_admin/test/mailglass_admin/admin_shell_test.exs`, `preview_live_test.exs` - reworked to the root-only contract (nothing deleted without a replacement)
- `.planning/phases/180-reproducible-admin-bundle-and-before-catalog/deferred-items.md` - item 3

## Decisions Made

- D-11 taken literally: every nested owner deleted. Storybook (`reference/demo_app/dev/.../storybook.ex`) keeps its own template-level `data-theme`/`data-theme-owner` by design (Phase 174 fidelity harness, outside `mailglass_admin/lib`, outside this scan).
- Detectors treat `[data-theme=...]` as a selector (a read), not an owner, so a future CSS or variant selector in lib text does not false-positive.
- The static scan's root exemption is line-scoped: a second `data-theme` inside `layouts/root.html.heex` (anywhere but the `<html` line) is flagged, and a separate test pins the root attribute to the `<html>` element exactly once.

## Deviations from Plan

### Auto-fixed Issues

**1. [Scope boundary / plan assumption did not hold] Gallery still has 39 duplicated id values after the collapse**
- **Found during:** Task 3 (gallery document cases)
- **Issue:** The plan truth and RESEARCH F10 expected the collapse to leave no duplicate ids. It removes the threefold copies (182 distinct duplicated ids at HEAD) but 39 remain: shared components emit literal or fixture-derived ids that the gallery renders across several states (`flash-error`, `inbound-routing-trace-content`, `inbound-evidence-*`, `delivery-detail-*`, `delivery-outcome-*`, `delivery-event-*`, ...). `live/2` still mounts the gallery without a duplicate-id raise, which is the behaviour the plan's acceptance names.
- **Fix:** Not fixed (out of scope: about seven shared components outside this plan's `files_modified`, and selectors e2e specs read). The test asserts what is true: `live/2` mounts, one specimen per state, and a floor (`@duplicate_id_floor 39`) so the count cannot grow back. Logged as `deferred-items.md` item 3 with the suggested follow-up.
- **Files modified:** `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs`, `deferred-items.md`
- **Committed in:** `06a8ff24`
- **Impact:** one stated must-have truth ("no duplicate element ids") is NOT fully met; the owner-relevant part of that truth (live/2 mounts, no `-light`/`-dark` copies) is.

**2. [Rule 2 - Missing Critical] Gallery cell test needed a cell definition that survives composed specimens**
- **Found during:** Task 3
- **Issue:** The plan's "each state renders exactly one specimen cell" cannot be a naive `gallery-*` testid pairing: three inner composed-layout wrappers (`gallery-composed-support-triage`, `-routing-evidence`, `-detail-timeline`) carry a `gallery-` testid but are not cells.
- **Fix:** A cell is a gallery element that contains `-system` wrappers; each must contain exactly the wrapper named `<testid>-system`, and the total wrapper count must equal the cell count (119 and 119).
- **Files modified:** same contract test
- **Committed in:** `06a8ff24`

**3. [Rule 2 - Missing Critical] Static scan widened beyond the two plan forms**
- **Found during:** Task 3
- **Issue:** Scanning only `data-theme=` and style/class assignments would miss the attribute written through a builder (`Map.put(attrs, "data-theme", ...)`), `setAttribute`, or `dataset.theme =`, and custom-property declarations in plain css text inside lib strings.
- **Fix:** Three owner patterns and a declaration pattern (`--mg-*:`/`--color-*:`), each with a planted case and clean controls (`setProperty("--mg-tooltip-arrow-x", ...)`, `var(--color-base-300)`, `data-theme-owner=`, `data-preview-frame-theme=`, `[data-theme=...]`).
- **Committed in:** `06a8ff24`

**4. [Process] Commit subjects follow the plan's `type(admin):` scope, not `type(180-02):`**
- Same note as plan 180-01 deviation 4: the plan prescribes exact subjects so Release Please and Guard Release Trigger classify by kind and package scope. The authoritative record is `plan_head_before..plan_head_after` in the frontmatter (6 commits, measured with `git rev-list --count`).

**5. [Scope boundary] Broken-windows ledger append declined by the tool**
- `gsd-tools windows append` returned `Ledger table in .planning/WINDOWS.md disagrees with the fenced JSON entries ... for row id(s): 48` and wrote nothing. The mismatch is committed at HEAD and pre-dates this plan; hand-editing the rendered table is forbidden by the tool. The deviation is recorded in `deferred-items.md` instead. Owner-visible: `WINDOWS.md` needs its row 48 regenerated.

---

**Total deviations:** 5 (1 plan assumption that did not hold and is deferred, 2 Rule 2 test-strength additions, 2 process or scope notes). **Impact on plan:** no lib scope change; the BRPIPE-02 required-lane half is complete, with one named gap (gallery duplicate ids) deferred and floored.

## Issues Encountered

None blocking. `mix coveralls.json` needs `MIX_ENV=test` (excoveralls is `only: :test`); CI sets it at the job level, so the plan's literal command without it fails with "task could not be found". The unrelated pre-existing warning `MailglassDemo.QuickViewScenarios is not included in any boundary` still prints on every compile (see `deferred-items.md` item 2).

## Known Stubs

None.

## Threat Flags

None. T-180-06 (theme cookie to `<html data-theme>`) is unchanged: `Theme.data_theme/1` still maps to a closed set. T-180-07 (iframe sandbox) is mitigated by the grep gate plus the `preview_live_test.exs` exact-attribute assertion, mutation C proves it. T-180-08 (inline style interpolation) is mitigated: the backdrop style value comes only from the boolean through `preview_frame_color_scheme/1`. T-180-09 (reintroduced nested owner) is mitigated by the required-lane scan and counts, mutations A, B1, B2.

## Follow-ups

- **Plan 180-03** must re-point the browser specs that read the deleted wrappers: `reference/demo_app/assets/e2e/phase178-stories.spec.js` (~130-138, the StatCard font-role test reading the gallery's nested `[data-theme="mailglass-${theme}"]`), `persona-screenshots.spec.js:203`, `flows.spec.js` frame-toggle assertions (~827-871), `structural.spec.js`, `gallery-matrix.spec.js`, `phase168-plan03-acceptance.spec.js`. It should also take the browser-pixel proof of the backdrop wrapper (D5).
- **Gallery duplicate ids:** `deferred-items.md` item 3; lower `@duplicate_id_floor` to 0 once the shared components accept a specimen id prefix.
- **WINDOWS.md** row 48 table/JSON mismatch blocks `gsd-tools windows append`; regenerate it.
- **CLAUDE.md "Things Not To Do" #6** still describes a CI git-diff of `priv/static` (Phase 183 docs pass, owner sign-off; carried from plan 180-01).

## Release effect

`fix(admin):` commits `750a3d99`, `40efc42d` and `aed2d578` touch `mailglass_admin/lib` and are release-visible: on merge to main Release Please proposes a `mailglass_admin` patch bump (the Preview backdrop scope is a visible admin change). The `test(admin):` commits are non-bump kinds listed in the release PR. The fail-closed `.planning/release-target.json` ledger and the `hex-publish` approval still apply unchanged; this phase initiates no release and edits neither the ledger nor any release config.

## Next Phase Readiness

- 180-03 (browser spec and e2e rework) can build on a root-only DOM: `[data-theme]` should equal `[document.documentElement]` for explicit modes and `[]` for system on every surface; the gallery specimen testid `gallery-{component}-{state}-system` is unchanged.
- 180-04 (catalog) captures on a tree where the BRPIPE-02 fix has landed (D-20); the manifest's `nested_theme_attr_count` should be 0, and the required-lane scan here already guarantees it for `mailglass_admin/lib`.
- After any `lib/` edit that adds text, run `mix mailglass_admin.assets.build --check` (P1); this plan's moduledoc and comment rewrites needed no regeneration.

---
*Phase: 180-reproducible-admin-bundle-and-before-catalog*
*Completed: 2026-11-15*

## Self-Check: PASSED

- Created and modified files exist on disk: `root_theme_ownership_contract_test.exs`, `admin_shell.ex`, `tabs.ex`, `gallery_live.ex`, `admin_shell_test.exs`, `preview_live_test.exs`.
- All six task commits are ancestors of HEAD: `750a3d99`, `26e0344f`, `40efc42d`, `6f6573f1`, `aed2d578`, `06a8ff24`.
- Plan acceptance greps hold (see Evidence); `--check` exits 0; `git diff --quiet 7a848162 -- brandbook mailglass_admin/priv/static mailglass_admin/lib/mailglass_admin/copy.ex` exits 0.
