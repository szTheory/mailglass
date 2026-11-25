---
phase: 181-brand-v2-tokens-fonts-and-logo
plan: 04
subsystem: ui
tags: [brand-v2, typemark, favicon, inline-svg, axe-baseline, wcag-contrast, daisyui, mailglass_admin]

requires:
  - phase: 181-brand-v2-tokens-fonts-and-logo
    provides: the token roles `--mg-logo-glass` and `--mg-logo-overlap`, the pinned lockup and favicon SVGs, the glyph contract, the contrast contract and the `superseded.json` marker pattern (plans 01 to 03)
provides:
  - "`Components.logo/1` draws the brand v2 typemark inline from the four pinned lockup paths: the word takes `currentColor`, the panes `.mg-logo-glass`, the overlap `.mg-logo-overlap`, so the logo follows `<html data-theme>` and never reads `prefers-color-scheme`"
  - "`.mg-logo-glass` and `.mg-logo-overlap` rules in the committed bundle; `priv/static/mailglass-logo.svg` (served at `/logo.svg`) and `priv/static/favicon.svg` are the pinned files byte for byte"
  - "`logo_assets_contract_test.exs` (29 tests, 15 of them teeth): byte identity, path identity, fill-to-token, safety, size floor, theme ownership, no `<img>` of the logo at the header or gallery"
  - "`:where(.label)` text colour override and a `contrast_contract_test` guard over every daisyUI text colour that mixes with transparent"
  - "v2 colour values, font names and the 600 weight in the advisory admin e2e specs and the demo storybook files"
  - "`docs/axe-baseline.json` regenerated once by the producer with no `color-contrast` rule; BRTOK-06 proven at phase scope"
affects: [182, 183]

actuals:
  tokens: 86533
  tasks: 3
  commits: 8

tech-stack:
  added: []
  patterns:
    - "Theme-following inline SVG: fixed outlines in the component, colours through classes that read token roles from the page theme block, so nothing in lib assigns or inverts a colour"
    - "Pinned asset identity in one required-lane file: byte compare of the shipped copy, path-data compare of the rendered component, fill-to-token compare of the pinned colours"
    - "A daisyUI component rule with an intrinsic alpha mix is either overridden in the utilities layer with `:where()` (zero specificity: beats the daisyUI sublayer, never an explicit text-* utility) or exempt with a reason, and a stale table entry fails"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs
    - .planning/phases/181-brand-v2-tokens-fonts-and-logo/deferred-items.md
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/priv/static/mailglass-logo.svg
    - mailglass_admin/priv/static/favicon.svg
    - mailglass_admin/test/mailglass_admin/assets_test.exs
    - mailglass_admin/test/mailglass_admin/contrast_contract_test.exs
    - mailglass_admin/e2e/admin-assets.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
    - reference/demo_app/assets/e2e/phase178-stories.spec.js
    - reference/demo_app/storybook/foundations.story.exs
    - reference/demo_app/storybook/quick_views/delivery.story.exs
    - reference/demo_app/storybook/quick_views/inbound.story.exs
    - mailglass_admin/docs/axe-baseline.json
    - .planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json

key-decisions:
  - "The typemark keeps the pinned `width=1000 height=205` attributes and viewBox `34.0 -840.0 5323.8 1092.0`; `h-6 w-auto` renders it 117 px wide (floor 96)"
  - "`bundle_test.exs` was not edited: its logo describe never named the old mark and stays green (`<text`, `font-family` and the size budget still hold)"
  - "The label contrast fix is a zero-specificity `:where(.label)` rule inside `@layer utilities`, not an unlayered `.label` rule: the daisyUI rule lives in `@layer utilities { @layer daisyui... }`, so an unlayered override would beat an explicit `text-error` on the same element"
  - "The `::placeholder` mix (about 3.1:1 light) is exempt with a reason and deferred, because the retired v1 palette measured 3.3:1 for the same rule and axe never counted it"
  - "The producer is not edited. A run that scanned a dialog mid fade-in was discarded and re-run; the cause and a suggested fix are in `deferred-items.md`"

patterns-established:
  - "Bundle-moving change = rebuild, `--check`, recompute the `superseded.json` bundle sha256 (used three times here: `139e6847...`, `8c57857f...` after the label rule; the root layout blob stayed `c89fca34...`)"
  - "Run the advisory browser specs before the producer: the structural spec's own axe cell caught the label regression the static pair table could not see"

requirements-completed: [BRTOK-03, BRTOK-04, BRTOK-05, BRTOK-06]

coverage:
  - id: D1
    description: "The header and gallery draw the brand v2 typemark inline: four pinned paths, `currentColor` word, `.mg-logo-glass` panes, `.mg-logo-overlap` overlap, no hex fill, no `prefers-color-scheme`, no `<img>` of the logo, 117 px wide at `h-6`"
    requirement: BRTOK-04
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs#the inline component draws the pinned typemark; #the theme owns the logo; #size and safety"
        status: pass
      - kind: integration
        ref: "mutation: one path coordinate changed in components.ex -> 'path 1 data differs from the pinned light lockup', 25 tests, 1 failure; restored -> 25 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "`priv/static/mailglass-logo.svg` and `priv/static/favicon.svg` are byte identical to `brandbook/v2/mailglass-lockup-light.svg` and `favicon.svg`; the `/logo.svg` route and the favicon route serve those bytes"
    requirement: BRTOK-04
    verification:
      - kind: unit
        ref: "logo_assets_contract_test.exs#the shipped logo and favicon are the pinned files byte for byte; assets_test.exs#GET /dev/mail/logo.svg serves the pinned light lockup byte for byte and #GET favicon.svg"
        status: pass
      - kind: integration
        ref: "mutation: one newline appended to priv/static/favicon.svg -> 'priv/static/favicon.svg: bytes differ from the pinned copy (791 bytes vs 790 pinned)', 40 tests, 2 failures; restored -> 40 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Host email defaults did not move: `git diff 9bd70fa5..HEAD` is empty for lib, test/mailglass, test/fixtures, test/support and the four lockfiles, and vml_preservation_test passes unedited"
    requirement: BRTOK-06
    verification:
      - kind: integration
        ref: "git diff --exit-code 9bd70fa5 -- lib test/mailglass test/fixtures test/support mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json (exit 0); mix test test/mailglass/components/vml_preservation_test.exs (4 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mutation: a comment line appended to lib/mailglass/components/theme.ex -> the phase-scope diff exits 1; restored -> exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "docs/axe-baseline.json is regenerated once by the producer as the phase's last code change, with a fresh `current.run_id`, the preserved `prior`, and no `color-contrast` rule"
    requirement: BRTOK-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/axe_baseline_test.exs (12 tests, 0 failures); the Task 3 axe gate prints 'axe provenance ok axe-2026-11-15T17-11-33-992Z'; git rev-list --count 9bd70fa5..HEAD -- mailglass_admin/docs/axe-baseline.json is 1; the persisted diff adds 0 color-contrast lines; nothing outside .planning changes after the axe commit"
        status: pass
    human_judgment: false
  - id: D5
    description: "No `color-contrast` regression ships: the light-theme page label text (a daisyUI 60% mix, 4.2:1 on Sand) now takes the secondary text role, and a contract guards every daisyUI text colour that mixes with transparent"
    requirement: BRTOK-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/contrast_contract_test.exs#daisyUI component text colours that mix with transparent (D-08) and #component alpha-text detector has teeth"
        status: pass
      - kind: integration
        ref: "mutation: the :where(.label) rule removed and the bundle rebuilt -> '.label mixes its text colour with transparent and its override ... is not in the bundle', 39 tests, 3 failures; restored -> 39 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D6
    description: "Advisory e2e and demo storybook files carry v2 colour values and the three v2 font families at weights 400 and 600; no v1 colour or retired font name remains outside the four reasoned exclusions"
    requirement: BRTOK-03
    verification:
      - kind: integration
        ref: "widened v1-colour gate over the seven advisory files (0), tree-wide retired-font gate with no deferral exclusions (0), weight-700 gate (0)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Required lanes at plan end: cold admin support_contract lane, root targeted contract files, publish allowlist, conformance trio, test-exception registry, node evidence tests, format in both roots"
    verification:
      - kind: integration
        ref: "MIX_BUILD_PATH=<cold> mix verify.support_contract.admin (1521 tests, 0 failures, 1 excluded); root mix test --warnings-as-errors --seed 0 (2370 tests, 1 environment failure, see Issues Encountered)"
        status: pass
    human_judgment: false

duration: 26min
completed: 2026-11-15
status: complete
plan_head_before: 9070f773b692683f4651f26f2a86b7e00b2b3345
plan_head_after: 644412c3d92a604e95848ae66e9139d8328e7cf1
commits: 8
---

# Phase 181 Plan 04: Brand v2 Typemark and Favicon, Advisory Pins, BRTOK-06 Proof and the Once-Only Axe Baseline Summary

**The admin draws the pinned brand v2 typemark inline so it follows the page theme, ships the pinned logo and favicon byte for byte, fixes the one contrast regression the colour swap caused (daisyUI's 60% label text), proves host email defaults did not move, and regenerates the axe baseline once with no `color-contrast` rule**

## Performance

- **Duration:** 26 min (wall clock from the commit ledger to the axe commit; the root full suite was about 5 min and the cold admin lane about 3 min of it)
- **Started:** 2026-11-15T16:46:36Z
- **Completed:** 2026-11-15T17:12:17Z (axe commit; this summary follows)
- **Tasks:** 3 (Task 1 tracer, Task 2 favicon and advisory pins, Task 3 close-out)
- **Files:** 17 changed (1 test file created, 16 modified), plus this summary and `deferred-items.md`
- **Execute-start SHA:** `9070f773b692683f4651f26f2a86b7e00b2b3345`

## Accomplishments

- **Typemark (D-15):** `Components.logo/1` is one inline `<svg>` with the pinned viewBox, `role="img"`, `aria-label="mailglass"` and four paths whose `d` values were copied by script from `brandbook/v2/mailglass-lockup-light.svg` (never typed). `.mg-logo-glass` and `.mg-logo-overlap` in `app.css` read `--mg-logo-glass` and `--mg-logo-overlap`, which live in the three theme blocks, so an explicit dark theme on a light OS draws the dark logo. The `@doc` and the moduledoc describe colours by role name only (HEX-GATE).
- **Pinned files (D-16, D-18):** `mailglass-logo.svg` and `favicon.svg` are `cp` copies; both are compared byte for byte in the required lane, and the `/logo.svg` and favicon routes are compared to the pinned bytes.
- **`logo_assets_contract_test.exs`** (476 lines, 29 tests): byte identity (logo and favicon), path identity against the light and dark lockups, fill-to-token for both tiers, paint classes, theme ownership, `img_logo_failures/1` over the rendered component and the real `admin_shell.ex` and `gallery_live.ex` sources (with an anti-vacuity check that both still contain `<Components.logo`), the width floor, and active-content refutation on the pinned lockups, favicon, shipped copies and the component. 15 teeth cases include an altered coordinate, an appended byte on each file, a hex fill, a missing class, a `prefers-color-scheme` string, both `<img>` variants and nine kinds of active content.
- **Advisory pins (D-09, D-12, F11):** the seven advisory files carry v2 colours, the three v2 families and weights 400 and 600; `admin-assets.spec.js` keeps its same-origin font check and gains a 404 probe held in `RETIRED_FONT_PROBE`; every title cited by `bucket_a_coverage_test` and every `test.setTimeout` anchor in `structural.spec.js` is byte-identical; `foundations.story.exs` uses `&bull;`.
- **BRTOK-06 (D-21):** the phase-scope diff from `9bd70fa5` is empty for core lib, core tests, fixtures, `test/support` and the four lockfiles; `vml_preservation_test` passes unedited; the `theme.ex` mutation turns the diff red.
- **Axe baseline (D-19):** one persisted regeneration, one commit, producer-written `current.run_id`, `prior` preserved, no `color-contrast` rule. See "Axe producer" below.

## Task Commits

1. **Task 1 (tracer): pinned lockup -> inline `Components.logo/1` -> `.mg-logo-*` rules -> rebuilt bundle -> logo contract**
   - `52130038` feat(admin): render the brand v2 typemark inline
   - `bd9cb2bb` docs: rebind the before-catalog marker to the typemark bundle
2. **Task 2: pinned favicon, advisory colour, font and weight pins**
   - `02fc4d2a` feat(admin): ship the brand v2 favicon
   - `e6ad72a7` test(admin): expect brand v2 colours, fonts and the 600 weight in browser specs
   - `add59e0f` chore(demo): use brand v2 colours and font names in storybook stories and specs
   - `2fae6975` fix(admin): keep form labels at 4.5:1 on the brand v2 page (deviation 1)
   - `5a41d299` docs: rebind the before-catalog marker to the label colour bundle
3. **Task 3: close-out**
   - `644412c3` test(admin): regenerate the axe baseline once for brand v2 (the single axe commit, nothing but `.planning` after it)

**Plan metadata:** the `docs(181-04): complete ...` commit (this file, `deferred-items.md`) and a following state and roadmap commit.

Tracer gate: after the tracer commits `mix mailglass_admin.assets.build --check` matched (138,465 bytes at the time), `git diff --quiet -- priv/static` was clean, `logo_assets_contract_test` + `bundle_test` + `before_catalog_manifest_test` + `root_theme_ownership_contract_test` + `glyph_contract_test` passed (127 tests, 0 failures), `check-conformance.sh` printed `OK`, and `cmp` of the logo copy printed 0. Tracer verified end-to-end, then expanded.

## Files Created/Modified

See the frontmatter lists. Key edit sites: `mailglass_admin/lib/mailglass_admin/components.ex` (logo), `mailglass_admin/assets/css/app.css` (logo rules, label override), `mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs` (new), `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` (component alpha-text guard).

## Decisions Made

See `key-decisions`. One worth restating: the label fix is a layered, zero-specificity rule. The compiled bundle nests daisyUI as `@layer utilities { @layer daisyui.l1.l2.l3 { ... } }`, and the repo's hand-authored classes (for example `.mg-focus-ring`) are unlayered. An unlayered `.label { color: ... }` would have beaten an explicit `text-error` on any element that also carries `label`. `:where(.label)` in `@layer utilities` wins against the daisyUI sublayer and loses to any utility. A scratch Chromium check on the compiled bundle measured: `.label` resolves to `rgb(102, 88, 80)` light and `rgb(185, 173, 163)` dark (the secondary role), `.label.text-error` still resolves to `rgb(179, 38, 30)` and `rgb(240, 154, 147)`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] daisyUI's 60% label text fell below 4.5:1 on the Sand page (D-08 fallback fired)**
- **Found during:** Task 2 (the advisory `structural.spec.js` run: `Preview: Phase 178 axe cell matches the committed baseline` reported `color-contrast: 3`), confirmed by a discarded producer probe (preview / light: `color-contrast` 3)
- **Issue:** daisyUI draws `.label` as `color-mix(in oklab, currentcolor 60%, transparent)`. Espresso at 60% over Sand is 4.17:1 (the retired v1 palette measured 4.52 for the same mix), so the Preview assigns form labels failed axe in the light theme. The static pair table and the 181-03 opacity-utility guard could not see it because `.label` is a daisyUI rule, not a utility in lib.
- **Fix:** `:where(.label) { color: var(--color-secondary); }` inside `@layer utilities` in `app.css` (the book pairs the secondary role with Sand and White); a new guard in `contrast_contract_test.exs` that scans the compiled bundle for every `color: color-mix(... transparent)` rule and requires an override present in the bundle or a reasoned exemption, with six tests and teeth (an unlisted 40% rule, a passing 90% rule, a removed override, a stale entry, a reasonless exemption, a dangling carrying pair, and the 4.1x reproduction of the original defect). The `::placeholder` rule is the one exemption (see `deferred-items.md`). Bundle rebuilt, marker rebound, lane re-run, producer probe re-run clean.
- **Files modified:** `mailglass_admin/assets/css/app.css`, `mailglass_admin/priv/static/app.css`, `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` (not in the plan's `files_modified`; D-08 names this table), the marker
- **Verification:** `contrast_contract_test` 39 tests, 0 failures; mutation (below) red then green; producer probe shows `preview light` back to `aria-allowed-attr: 1` only; advisory `Preview: Phase 178 axe cell matches the committed baseline` passes in the gate subset
- **Committed in:** `2fae6975`, `5a41d299`

---

**Total deviations:** 1 auto-fixed (1 Rule 1)
**Impact on plan:** The fix is the plan's own D-08 fallback (never persist a contrast regression). It changed one CSS rule and added one guard; no scope creep, and the token map was not touched (the cause was a component rule, not a designed role).

## Issues Encountered

- **One root test fails on this machine for an environment reason, not a Phase 181 change.** `mix test --warnings-as-errors --seed 0` in the repo root: `2370 tests, 1 failure, 27 excluded, 7 skipped`. The failure is `Mailglass.Scripts.Phase164RepositoryTruthTest` ("git runtime rules do not conceal the retired finalize-phase extension paths", `test/scripts/phase_164_repository_truth_test.exs:261`): `refute ignored?(".gsd/extensions/finalize-phase/index.ts")` got true. `git check-ignore -v` names the rule: `.gsd/.gitignore:1:*`. That file is untracked (`git ls-files .gsd` is empty), has content `*` and an mtime of Oct 7, long before this phase, so a clean checkout (CI) has no such rule. No Phase 181 commit touches `.gitignore` or `.gsd`. Recorded here, not fixed (scope boundary); the other 2369 root tests pass. The cold admin lane and every other gate are green.
- **The axe producer measured a dialog mid fade-in once.** Run 3 of the producer showed `inbound / system: color-contrast 5` (dialog title and identity `dt` labels at ratios near 1.2). A scratch probe spec (created, run and deleted, never committed) scanned the inbound cell 12 times, immediately and after `document.getAnimations()` settled: immediate scans reported 3 to 6 nodes in 6 of 12 runs, settled scans reported 0 in all 12. That is a scan-timing artifact of `e2e/axe-baseline.spec.js` (it analyses right after `expect(modal).toBeVisible()`), not a contrast defect. Per the plan the producer scan is not changed; the discarded run was not persisted and the producer was re-run. The suggested hardening is in `deferred-items.md` item 3.
- **The advisory e2e runs rewrite tracked PNGs** under `.planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts/review-fix/` (four files after the full structural run). They were restored with `git checkout --` and none was committed; `git status` was clean afterwards.
- **Cold lane directory** was created under `/private/tmp/mg181_04_cold` (not bare `mktemp -d`) and removed afterwards.

## Axe producer (BRTOK-05)

Command: `cd mailglass_admin && PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js`. It was run four times; only the last was persisted.

| Run | Result | Disposition |
|-----|--------|-------------|
| 1 (probe, label regression present) | `9 passed`; `preview / light` `color-contrast: 3` | discarded with `git checkout -- docs/axe-baseline.json`; D-08 fallback, label fix |
| 2 (probe, after the fix) | `9 passed (10.2s)`; no `color-contrast` | discarded (the plan orders the Plan-end gate before the persisted run) |
| 3 (final-position run) | `9 passed (11.9s)`; `inbound / system` `color-contrast: 5` (transient fade-in) | discarded; see Issues Encountered |
| 4 (persisted) | **`9 passed (11.3s)`**; no `color-contrast` | committed as `644412c3` |

- **`current.run_id` written by the producer and committed:** `axe-2026-11-15T17-11-33-992Z` (the committed value equals it; `prior.run_id` stays `axe-2026-06-21T15-51-22-195Z`).
- **Persisted cells:** deliveries and inbound `total: 0` in light, dark and system; preview `aria-allowed-attr: 1` in all three themes. Deliveries and inbound dropped from the committed `scrollable-region-focusable: 1` to 0, which the only-forward ratchet allows. `git diff --exit-code priv/static/app.css` was clean after the producer, the persisted diff adds 0 `color-contrast` lines, and `axe_baseline_test` passes (12 tests, 0 failures).
- **D-08 fallback fired** (the label fix above). "Once, last" therefore holds for the persisted baseline only: one commit, nothing but `.planning` after it. `docs/storybook-axe-approved.json` did not change: the producer does not write it and no approval was required.

## Lane evidence

Required lane `support_contract_admin` (`mix verify.support_contract.admin`, cold `MIX_BUILD_PATH` under `/private/tmp`, whole admin test directory):

```
Admin bundle matches a fresh build (138509 bytes).
...
1521 tests, 0 failures, 1 excluded      (RC=0)
```

Baseline before this plan was 1485 (181-03), so the plan adds 36 tests (logo contract 29, contrast guard 6, `assets_test` +1).

Required lane `core_deterministic_suite`: root `mix test --warnings-as-errors --seed 0`: `23 properties, 2370 tests, 1 failure, 27 excluded, 7 skipped` (the one failure is the environment case above); targeted contract files `mix test test/scripts/brand_pin_test.exs test/scripts/timeout_evidence_ci_contract_test.exs test/scripts/icon_exists_gate_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 0`: `146 tests, 0 failures, 1 skipped`; `vml_preservation_test`: `4 tests, 0 failures`.

Required lane `mix_task_tests`: `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` -> `Allowlist check result for mailglass_admin: create=2 update=1 unchanged=2 conflict=0`; `mix run --no-start scripts/brand_pin.exs verify` -> `brand pin ok`.

Required lane `conformance_gates`:

```
OK: design-system conformance clean.            (mailglass_admin/scripts/check-conformance.sh)
OK: motion conformance clean.                   (scripts/check_motion_conformance.sh)
OK: advisory design-system conformance clean.   (mailglass_admin/scripts/check-conformance-advisory.sh)
OK: test exception registry is complete and unexpired.   (scripts/check_test_exceptions.sh)
```

Node evidence tests (`node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs`): `tests 42, pass 42, fail 0`.

Other gates: `mix format --check-formatted` exit 0 in the root and in `mailglass_admin`; `git diff --exit-code 9bd70fa5 -- lib test/mailglass test/fixtures test/support mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json` exit 0 (no dependency, no core change); `git diff --exit-code 9bd70fa5 -- .planning/release-target.json` exit 0. Retired-font gate tree-wide with no deferral exclusions: `0` (was 85); widened v1-colour literal gate over the seven advisory files: `0` (was 21); weight-700 gate: `0` (was 11). Exclusions used by the font gate, each with its reason: the captured catalog fixture `before_catalog_manifest_test.exs`, the frozen v1 capture spec `before-catalog.spec.js`, the immutable receipts `phase174-review.md` and `phase175-review.md`, and lines matching `retired[-_]font[-_]probe` (the `RETIRED_FONT_PROBE` constant in `admin-assets.spec.js` and `@retired_font_probe` in `assets_test.exs`). The final bundle sha256 `8c57857f51b9a3ed457e6693341609daebf89a45f8e5b3b09a2bc7ccb024b89b` equals `superseded_by.bundle_sha256`; the root layout blob `c89fca348193f24ea614f0d48e8ff29187d7b519` is unchanged.

### Advisory evidence

Never cited as proof.

- `cd mailglass_admin && npm run test:operator-browser -- admin-assets.spec.js`: `13 passed (5.5s)`, including the same-origin font check for 12 routes and the retired regular UI font returning 404 with an empty body.
- Full `structural.spec.js`: `113 passed, 1 failed, 1 skipped (1.7m)`. The one failure was `Preview: Phase 178 axe cell matches the committed baseline` (`color-contrast: 3`), which is deviation 1. The accent-allowlist titles passed with the Deep Glass value (Open Question 2: links did not match the allowlisted check, so no allowlist change). The weight tests expect 600 and pass.
- gsd regression gate browser subset (`npm run test:operator-browser -- e2e/phase170-journey.spec.js e2e/flows.spec.js e2e/structural.spec.js --grep 'Phase 170|Phase 171|Preview:|Preview (happy|error|boundary|edge|advanced)'`, run after the label fix and before the producer): `37 passed (26.7s)`, `browser subset exit: 0`, `git diff --exit-code priv/static/app.css` exit 0 (the bundle did not move).
- Demo specs and stories (`storybook-fidelity.spec.js`, `phase178-stories.spec.js`, `foundations.story.exs`, the two quick-view stories): not run (advisory; the demo stack is not up). The two specs were syntax-checked with `node --check`.

## Acceptance-to-test table

| Requirement | Proven by | Required lane |
|-------------|-----------|---------------|
| BRTOK-01 (v2 tokens in all three blocks) | `token_parity_test.exs`, `brand_test.exs`, `mix mailglass_admin.assets.build --check` (181-01) | `support_contract_admin` |
| BRTOK-02 (contrast pairs, guards) | `contrast_contract_test.exs` (book pairs, admin pairs, opacity utilities, component alpha-text guard), `accessibility_test.exs` | `support_contract_admin` |
| BRTOK-03 (fonts) | `font_assets_contract_test.exs`, `glyph_contract_test.exs`, `assets_test.exs`, `bundle_test.exs`; `brand_pin_test.exs`, `docs_contract_test.exs` | `support_contract_admin`, `core_deterministic_suite`; `mix mailglass.publish.check --allowlist-only` in `mix_task_tests` |
| BRTOK-04 (logo, favicon, arrows) | `logo_assets_contract_test.exs`, `glyph_contract_test.exs`, `assets_test.exs`; `icon_exists_gate_test.exs` | `support_contract_admin`, `core_deterministic_suite`; `check-conformance.sh` in `conformance_gates` |
| BRTOK-05 (ratchet, no contrast regression) | `axe_baseline_test.exs`, the producer provenance gate, `contrast_contract_test.exs` | `support_contract_admin` |
| BRTOK-06 (host email defaults) | phase-scope `git diff 9bd70fa5`, `vml_preservation_test.exs`, the root suite | `core_deterministic_suite` |

Advisory only: `operator_browser_gate` specs (admin-assets, structural, the gate subset, the axe producer run) and the demo browser specs.

## Mutation index (plans 01 to 04)

- **BRTOK-01 (181-01):** `text-muted` aliased to another palette key -> `token_parity_test` red; system-block `--mg-color-text` changed and rebuilt -> red; both restored.
- **BRTOK-02 (181-01, 181-03, 181-04):** dark `text-muted` darkened -> `contrast_contract_test` red; a middle dot in a lib string -> glyph contract red; **the `:where(.label)` rule removed and the bundle rebuilt -> `.label mixes its text colour with transparent and its override :where(.label){color:var(--color-secondary)} is not in the bundle`, 39 tests, 3 failures; restored with `git checkout -- assets/css/app.css priv/static/app.css`, `--check` matched, 39 tests, 0 failures.**
- **BRTOK-03 (181-02):** renamed font (compile-time red), copied retired name (set equality and `brand_pin verify` red), flipped font byte (`asset_hash_mismatch`), changed a CSS `url(...)`; each restored.
- **BRTOK-03/04 glyph (181-03):** middle dot in a lib string, left arrow in a HEEx template, `arrow-left` removed from the vendored plugin; each restored.
- **BRTOK-04 (181-04):** **one `d` coordinate changed in `components.ex` -> `path 1 data differs from the pinned light lockup (3417 vs 3417 chars)` and the dark one, 25 tests, 1 failure; restored with `git checkout --`, 25 tests, 0 failures. One newline appended to `priv/static/favicon.svg` -> `priv/static/favicon.svg: bytes differ from the pinned copy (791 bytes vs 790 pinned)` plus the served-bytes assertion, 40 tests, 2 failures, while the `favicon_hash` equality assertion stayed green (the byte-identity test is the one that catches it); restored with `git checkout --` and a `touch` of `assets.ex` to force the compile-time embed to refresh, 40 tests, 0 failures.**
- **BRTOK-06 (181-04):** **a comment line appended to `lib/mailglass/components/theme.ex` -> `git diff --exit-code 9bd70fa5 -- lib test/mailglass test/fixtures test/support` exit 1; restored with `git checkout --`, exit 0.**

## Release effect

`52130038` (typemark), `02fc4d2a` (favicon) and `2fae6975` (`fix(admin)`, the label contrast) are release-visible for `mailglass_admin`: Release Please will fold them into the same proposed minor bump as the `feat(admin):` commits of plans 01 to 03. The `test`, `docs` and `chore(demo)` commits are not release-visible. No release is initiated and `.planning/release-target.json` is untouched (diff from `9bd70fa5` is empty). Phase 183 follow-ups: ICO and PNG favicons with the 16, 24 and 32 px browser check, ExDoc logo and CSS, README brand assets (`mix.exs` still points ExDoc at the v1 `brandbook/assets/favicon.svg`), `.impeccable/config.json` and the CLAUDE.md typography lines.

## Known Stubs

None.

## Threat Flags

None. No network endpoint, auth path or trust-boundary schema was added. T-181-11 (inlined and served SVGs) is mitigated as planned: byte and path identity to the sha256-pinned files, with active-content refutation (`<script`, event handlers, `<foreignObject`, `<image`, `href`, remote `url(`) on the pinned lockups, favicon, shipped copies and the rendered component, each with a tooth. T-181-12 (shipped copies) is mitigated by the byte-identity tests, which `brand_pin verify` anchors to the zip. T-181-13 (axe ratchet) is mitigated: the contrast regression found by the producer was fixed before persisting, the persisted diff adds no `color-contrast` line, one commit regenerates the file and the provenance gate checks its `run_id` and `prior`. T-181-14 (host email defaults) is mitigated by the phase-scope diff and the unedited `vml_preservation_test`. T-181-SC: no package installed, the four lockfiles are unchanged (diff exit 0).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Phase 182** (copy and layout, visual judgment): the admin now carries the v2 typemark, favicon, tokens and fonts, and every colour pair, glyph and opacity utility is guarded by the required lane. Open items it may take: the `::placeholder` contrast exemption and the demo arrow entity (`deferred-items.md` items 1 and 2), and hardening the axe producer to scan the settled page (item 3). Any new text-colour mix in a daisyUI component or any new `/NN` colour utility fails the required lane until it is paired, overridden or exempted with a reason.
- **Phase 183:** ICO and PNG favicons, ExDoc and README assets, `design-system.md` prose beyond the false-value corrections, the CLAUDE.md typography lines and `.impeccable` config.
- Any later `app.css` or `lib/` change must recompute the `superseded.json` bundle sha256 (currently `8c57857f...`) and, for a root layout change, the blob (currently `c89fca34...`).

---
*Phase: 181-brand-v2-tokens-fonts-and-logo*
*Completed: 2026-11-15*

## Self-Check: PASSED

- The created files (`mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs`, `.planning/phases/181-brand-v2-tokens-fonts-and-logo/deferred-items.md`) and the replaced assets (`priv/static/mailglass-logo.svg`, `priv/static/favicon.svg`, `docs/axe-baseline.json`) exist on disk; the two SVG copies are byte identical to `brandbook/v2`.
- Commits `52130038`, `bd9cb2bb`, `02fc4d2a`, `e6ad72a7`, `add59e0f`, `2fae6975`, `5a41d299`, `644412c3` are ancestors of HEAD; `git rev-list --count 9070f773b692683f4651f26f2a86b7e00b2b3345..HEAD` is 8, matching `commits: 8`.
- The committed bundle sha256 (`8c57857f...`) equals `superseded_by.bundle_sha256`; every task acceptance criterion and the Task 3 verify commands were re-run green after the axe commit.
