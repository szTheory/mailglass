---
phase: 181-brand-v2-tokens-fonts-and-logo
plan: 01
subsystem: ui
tags: [brand-v2, design-tokens, wcag-contrast, tailwind, daisyui, exunit, mailglass_admin]

requires:
  - phase: 180-reproducible-admin-bundle-and-before-catalog
    provides: the `assets.build --check` drift gate in the required admin lane, theme ownership on `<html>`, the live before-catalog the superseded marker binds to
  - phase: 179-compatibility-policy-status-map-and-brand-pin
    provides: the pinned brand v2.0 book (`brandbook/v2/brand.json`) the palette is cross-checked against
provides:
  - brandbook/tokens.json and tokens.css rewritten in place to brand v2.0 (39 colour roles + 2 logo roles per tier, three CSS blocks)
  - rebuilt mailglass_admin/priv/static/app.css (123 `--mg-*` hex declarations, no v1 value, Espresso shadows)
  - MailglassAdmin.TestSupport.Contrast (normalize_hex, luminance, ratio, composite, resolve_tokens) on the WCAG 2.2 sRGB threshold 0.04045
  - contrast_contract_test (book pairs, admin pairs, slot and designed-value coverage guards, never rules, teeth)
  - three-block token_parity_test with palette provenance and designed-composite recompute
  - before-catalog superseded.json bound to the new bundle sha256
  - REQUIREMENTS, ROADMAP and PROJECT.md wording that states the real contract (39 + 2 roles feeding 20 slots; six woff2)
affects: [181-02, 181-03, 181-04, 182, 183]

actuals:
  tokens: 100517
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Pure comparison functions over (css, tokens, brand) with an in-test teeth block, so a pass is never vacuous"
    - "Every palette entry carries machine-checked provenance: a brand.json path matched by name, or a designed {over, color, alpha} recomputed with Contrast.composite/3"
    - "Admin contrast pair table is a plain list of maps with a coverage guard, so later plans append rows"

key-files:
  created:
    - mailglass_admin/test/support/contrast.ex
    - mailglass_admin/test/mailglass_admin/contrast_contract_test.exs
    - .planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json
  modified:
    - brandbook/tokens.json
    - brandbook/tokens.css
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/token_parity_test.exs
    - mailglass_admin/test/mailglass_admin/brand_test.exs
    - mailglass_admin/test/mailglass_admin/accessibility_test.exs
    - mailglass_admin/docs/design-system.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/PROJECT.md

key-decisions:
  - "Role values follow the RESEARCH role map; every designed value (link-hover, overlay, selected, eight *-bg tints) is a two-book-hex composite under one rounding rule, Contrast.composite/3 with Elixir round/1, stored in tokens.json and recomputed by token_parity_test"
  - "Roles with no admin CSS consumer (surface-overlay, surface-selected, link-hover, link-active, the four *-bg) are still contrast-checked through role-level admin pairs, and their $description ends 'unreferenced by admin CSS; contrast-checked as <pair id>'; a test verifies the pair exists, involves the role, and that app.css and lib really never read the role"
  - "Logo roles live in a top-level tokens.json `logo` group (logo.<tier>.glass / overlap) emitted as --mg-logo-glass and --mg-logo-overlap, keeping the D-15 names 181-04 consumes"
  - "The admin pair table stays a plain list of maps; 181-03 Task 2 appends composite rows and the opacity-utility guard"

patterns-established:
  - "Mutation proof for every contract: lower one value, observe a red line naming the pair or block, restore"
  - "Bundle-moving change = rebuild, recompute the superseded.json sha256, run the lane, in that order"

requirements-completed: [BRTOK-01, BRTOK-02, BRTOK-05]

coverage:
  - id: D1
    description: "brandbook/tokens.json and tokens.css hold brand v2.0 values for 39 colour roles and 2 logo roles per tier; the compiled bundle carries them in the light, dark and system blocks"
    requirement: BRTOK-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/token_parity_test.exs#three-block parity of every role (D-04)"
        status: pass
      - kind: other
        ref: "grep -oE -- '--mg-[a-z-]+:#[0-9a-fA-F]{3,6}\\b' mailglass_admin/priv/static/app.css | wc -l  (prints 123)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every palette hex is a brand.json hex found by name or a recomputed two-hex composite; no hue outside the book"
    requirement: BRTOK-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/token_parity_test.exs#palette provenance (D-03, D-05)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The committed bundle is exactly what the pinned Tailwind builds, and the before-catalog marker is bound to its sha256"
    requirement: BRTOK-01
    verification:
      - kind: integration
        ref: "mix mailglass_admin.assets.build --check (Admin bundle matches a fresh build, 137027 bytes)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Static contrast contract: 12 book pairs per theme, the admin pair table, slot and designed-value coverage guards and the three book never rules, all with mutation teeth"
    requirement: BRTOK-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/contrast_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "brand_test, token_parity_test and accessibility_test are rewritten for v2 and use the shared 0.04045 helper"
    requirement: BRTOK-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/{brand,token_parity,accessibility}_test.exs"
        status: pass
    human_judgment: false
  - id: D6
    description: "REQUIREMENTS, ROADMAP and PROJECT.md state the real contract (39 + 2 roles feeding 20 slots, six woff2, static font proof) and design-system.md token rows name v2 values"
    requirement: BRTOK-01
    verification:
      - kind: other
        ref: "grep -c '36 admin theme slots\\|36-slot\\|seven woff2\\|seven bundled woff2\\|A browser network check shows' over the three planning files (prints 0); token_parity_test design-system assertion"
        status: pass
    human_judgment: false
  - id: D7
    description: "Required lanes at plan end: cold admin support_contract lane and the conformance gates"
    verification:
      - kind: integration
        ref: "MIX_BUILD_PATH=<cold> mix verify.support_contract.admin (1419 tests, 0 failures); check-conformance.sh, check_motion_conformance.sh, check-conformance-advisory.sh"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-11-15
status: complete
plan_head_before: 971123564c644f4285911d9a79a8a54a1fb8456d
plan_head_after: 27e71f5f16381fc7c6f3f2efe26b281c19b74b84
commits: 5
---

# Phase 181 Plan 01: Brand v2 Colour Tokens, Role Map and Static Contrast Contract Summary

**Brand v2.0 colours in the admin through a hand-maintained 41-role token map (39 colour + 2 logo roles) proven in all three compiled CSS blocks, plus a dependency-free WCAG 2.2 contrast contract with coverage guards and the three book `never` rules**

## Performance

- **Duration:** 16 min (wall clock from the commit ledger to the last gate; the cold admin lane dominated)
- **Started:** 2026-11-15T15:53:50Z
- **Completed:** 2026-11-15T16:09:54Z
- **Tasks:** 3 (Task 1 tracer, Task 2 TDD, Task 3 docs and gates)
- **Files modified:** 14 (3 created, 11 modified), plus this summary
- **Execute-start SHA:** `971123564c644f4285911d9a79a8a54a1fb8456d` (the BRTOK-06 phase base stays `9bd70fa5`; commits between them touch only `.planning` docs)

## Accomplishments

- `brandbook/tokens.json` and `tokens.css` are v2 in place (D-03, no generator). The palette takes v2 names; each entry records its source (`$extensions.mailglass.book` path into brand.json matched by name, or `designed` {over, color, alpha}). Two logo roles per tier are added and emitted in every block: the bundle carries exactly 123 `--mg-*` hex declarations and no v1 hex.
- `token_parity_test` now compares every one of the 41 roles against the tokens.json oracle in the light, dark and `prefers-color-scheme` system blocks, selected by exact selector with exactly one block of each kind, and rejects undeclared extras. Teeth mutate one value per block, remove or add a declaration, duplicate or drop a block, plant an off-book hex, a provenance-free entry, an unreproducible composite and a dangling alias.
- `contrast_contract_test` checks all 12 brand.json `contrastPairs` per theme through the tokens (>= minimum, within 0.02 of the published ratio, hexes equal to the book), 48 admin pairs per theme (X on X-content, text on both surfaces and on its own 10% tint, border-input and focus-ring at 3:1, logo glass at 3:1, role-level pairs for every designed or unconsumed role), a coverage guard over the 20 daisyUI slots (exempt: `base-300`, `text-disabled` role, each with a reason), a designed-value guard, and the Glass / Sand Line / Deep Glass `never` rules, each with a planted-violation test.
- `MailglassAdmin.TestSupport.Contrast` is pure (`mix.lock` unchanged) and uses the WCAG 2.2 threshold 0.04045; `accessibility_test` moved onto it, reads roles from tokens.json and keeps the intentionally sub-3:1 divider pins (light 1.32, dark 1.54).
- The before-catalog `superseded.json` binds to the new bundle sha256 (`5d49bcc5...`), `before_catalog_manifest_test` is green.
- REQUIREMENTS BRTOK-01/BRTOK-03, ROADMAP criteria 1 and 3 and PROJECT.md line 24 state the real contract; criterion 3 names `font_assets_contract_test` as the static proof with the browser run advisory.

## Task Commits

1. **Task 1 (tracer): v2 token sources, bundle, three-block parity, brand_test, design-system pins, catalog marker**
   - `ea24b0ef` chore(brand): rewrite brandbook tokens to brand v2.0
   - `8dd3d4df` feat(admin): adopt brand v2 colour tokens in the admin bundle
   - `175cc6cf` docs: mark the before-catalog superseded by the v2 colour bundle
2. **Task 2: static contrast contract on the shared 0.04045 helper** - `8cb62bbc` test(admin)
3. **Task 3: slot and woff2 wording amendments** - `27e71f5f` docs

**Plan metadata:** the `docs(181-01): complete ...` commit (SUMMARY, STATE, ROADMAP, REQUIREMENTS) follows this file.

Tracer gate: after the tracer commits the verify was re-run end to end (bundle `--check`, clean `git diff -- priv/static`, no stray `app.css?*`, four test files, 94 tests, 0 failures) and the 123-declaration count printed 123. Tracer verified end-to-end, then expanded.

## Files Created/Modified

- `brandbook/tokens.json`, `brandbook/tokens.css` - v2 palette, 39 colour roles x 2 tiers, `logo` group, three CSS blocks
- `mailglass_admin/assets/css/app.css` - v2 role comments, Espresso shadow tints (`rgb(42 29 23 / 0.06|0.18)`), header comment
- `mailglass_admin/priv/static/app.css` - rebuilt bundle (137,027 bytes, budget 150,000)
- `mailglass_admin/test/support/contrast.ex` - shared pure colour helper
- `mailglass_admin/test/mailglass_admin/{token_parity,brand,accessibility}_test.exs` - rewritten for v2
- `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` - new required-lane contract
- `mailglass_admin/docs/design-system.md` - token table rows and shadow sentence (false-value corrections only)
- `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json` - catalog marker
- `.planning/{REQUIREMENTS,ROADMAP,PROJECT}.md` - wording amendments

## Decisions Made

- Role values follow the RESEARCH role map; the designed set is exactly `#12526C` (25% Espresso over Deep Glass), `#362D27`, `#323535` and the eight `*-bg` tints (light `#E8F0EC #F3EEE6 #F7E9E9 #E7F0F3`, dark `#333228 #3D3022 #3E2D27 #313230`). All eleven reproduced under `Contrast.composite/3` and `round/1` when computed at execute start.
- The "unreferenced by admin CSS" claim is itself tested (app.css and `lib/` never read those roles), so the `$description` tags cannot silently rot; a later phase that adds a consumer must update the tag and the pair.
- The Sand Line never rule also checks the dark counterpart (Roast Line is never `border-input`/`border-strong`), since Roast Line is the dark divider colour.
- Lightning CSS emits every proposed value as hex (123 declarations), so assumption A6 (named-colour shortening) did not trigger.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The design-system.md status row named retired v1 colours**
- **Found during:** Task 1 (docs step)
- **Issue:** The plan lists six token-table rows, but the seventh row (`success / warning / error`) read `Pine / Amber / Crimson` and `Pine-bright / Amber-bright / Crimson-bright`, which the bundle no longer loads.
- **Fix:** Rewrote that one row to the v2 status hexes (Delivered `#1D6B3C` / `#7FCB9A`, Delayed `#855300` / `#E3B25C`, Failed `#B3261E` / `#F09A93`), still a false-value correction only (D-23).
- **Files modified:** `mailglass_admin/docs/design-system.md`
- **Committed in:** `8dd3d4df`

**2. [Rule 1 - Bug] The `@theme` elevation comment also named the retired tint**
- **Found during:** Task 1 (app.css edit)
- **Issue:** The rules comment above `@theme` said "faint Ink-tinted shadows" next to the shadow values the plan changes.
- **Fix:** Changed that comment to "Espresso-tinted" alongside the planned shadow-comment edit.
- **Files modified:** `mailglass_admin/assets/css/app.css`
- **Committed in:** `8dd3d4df`

---

**Total deviations:** 2 auto-fixed (2 Rule 1, both one-line false-value corrections)
**Impact on plan:** No scope creep; both keep text that would otherwise state v1 values.

## Issues Encountered

- **Cold-lane environment failure (recorded, not a pass).** Two cold runs of `mix verify.support_contract.admin` failed while compiling the `premailex` dependency: `could not read .../test/lib/premailex/priv/entities.txt`. Cause: `mktemp -d` returns a `/var/folders/...` path and macOS `/var` is a symlink to `/private/var`, so Mix's relative `priv` symlink in the cold build dir dangled. This was an environment issue, not a code defect (the same command succeeds with a cold dir created under a real path). The third run used a cold dir created under `/private/tmp` and passed; that run re-fetched the pinned Tailwind 4.1.12 binary over the network ("Downloading tailwind ... v4.1.12").
- `design-system.md` line 55 ("`primary`/Glass appears only on the selected-row border ...") and the `Type (400/700 only)` rows still use v1 wording. Left alone on purpose: D-23 limits this plan to false-value corrections; the weight rows change in 181-02 and the prose rewrite is Phase 183.

## Lane evidence

Required lane `support_contract_admin` (`mix verify.support_contract.admin`, cold `MIX_BUILD_PATH`, whole admin test directory):

```
Admin bundle matches a fresh build (137027 bytes).
...
Finished in 18.3 seconds (4.9s async, 13.3s sync)
1419 tests, 0 failures, 1 excluded      (exit 0)
```

Baseline before this plan was 1389 tests, so the plan adds 30. (Two earlier cold attempts failed on the environment issue above and were re-run.)

Required lane `conformance_gates`:

```
OK: design-system conformance clean.            (mailglass_admin/scripts/check-conformance.sh)
OK: motion conformance clean.                   (scripts/check_motion_conformance.sh)
OK: advisory design-system conformance clean.   (mailglass_admin/scripts/check-conformance-advisory.sh)
```

`core_deterministic_suite` files that read this plan's edits (`mix test test/mailglass/docs_contract_test.exs test/scripts/icon_exists_gate_test.exs test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0`): `121 tests, 0 failures, 1 skipped`.

Other gates: `bash scripts/check_test_exceptions.sh` -> `OK: test exception registry is complete and unexpired.`; `mix format --check-formatted` exit 0 in `mailglass_admin` and in the root; lockfile and core-scope guard `git diff --exit-code 9bd70fa5 -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json lib test/mailglass test/fixtures test/support` exit 0 (no dependency, no core file change); `git diff --exit-code 9bd70fa5 -- .planning/release-target.json` exit 0. No advisory lane is cited as proof.

## Mutation proofs

- **BRTOK-01, tokens.json level:** `color.light.text-muted` aliased to `{palette.espresso}`: `token_parity_test` red, `light block: --mg-color-text-muted is #665850 but tokens.json (light) says #2a1d17`; restored with `git checkout -- brandbook/tokens.json`, `13 tests, 0 failures`.
- **BRTOK-01, rebuild level:** system-block `--mg-color-text` in `brandbook/tokens.css` changed `#F3EEEA` to `#F3EEEB`, bundle rebuilt: `token_parity_test` red, `system block: --mg-color-text is #f3eeeb but tokens.json (dark) says #f3eeea`; restored with `git checkout -- brandbook/tokens.css mailglass_admin/priv/static/app.css`, rebuilt, `Admin bundle matches a fresh build (137027 bytes).` and `13 tests, 0 failures`.
- **BRTOK-02 (D-07):** `color.dark.text-muted` aliased to the darker `{palette.control-edge-dark}`: `contrast_contract_test` red, lines `descriptor (dark): text-muted #8b7d72 on background #1d1713 is 4.45:1, below the 4.5:1 minimum` and `descriptor (dark): 4.45:1 is not within 0.02 of the published 8.08:1`; restored with `git checkout -- brandbook/tokens.json`, `20 tests, 0 failures`.
- **In-test teeth:** per-block value change (light, dark, system x colour and logo role), removed and extra declaration, duplicated and missing block, named-colour emission, off-book hex, bare palette entry, bad composite, dangling alias, unknown book pair, mutated published ratio, dropped X-content pair, dropped `info-text-on-info-bg`, a pair below its ratio, and a planted violation per `never` rule.

## Release effect

The `feat(admin):` commit (`8dd3d4df`) makes Release Please propose a `mailglass_admin` minor bump when this reaches `main`. No release is initiated here and `.planning/release-target.json` is untouched.

## Known Stubs

None. (The only `placeholder` hits in changed files are pre-existing connection-state skeleton comments in `app.css`.)

## Threat Flags

None. No network endpoint, auth path, file-access pattern or trust-boundary schema was added; the new test code only reads repository files. T-181-01 and T-181-02 are mitigated as planned (palette cross-check with off-book teeth; `--check` byte compare plus three-block parity plus the sha256-bound marker); T-181-03 is covered by the static contrast contract (the axe ratchet follows in 181-04).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 181-02 can swap fonts: `--mg-font-*` stacks and the `@theme` weight comment were left untouched on purpose, and the `Type (400/700 only)` doc rows are its to fix. The bundle marker must be rewritten again after any `app.css` or `lib/` change.
- 181-03 can append composite and opacity-utility rows to the plain-list admin pair table in `contrast_contract_test.exs`.
- 181-04 consumes the `--mg-logo-glass` / `--mg-logo-overlap` roles, which now exist in all three blocks.
- Phase 182's reviewer owns visual judgment of the designed values (assumption A2); they are contrast-verified composites of book hexes.

---
*Phase: 181-brand-v2-tokens-fonts-and-logo*
*Completed: 2026-11-15*

## Self-Check: PASSED

- All 11 created or modified files listed above exist on disk.
- Commits `ea24b0ef`, `8dd3d4df`, `175cc6cf`, `8cb62bbc`, `27e71f5f` are ancestors of HEAD; `git rev-list --count 971123564c644f4285911d9a79a8a54a1fb8456d..HEAD` is 5, matching `commits: 5`.
