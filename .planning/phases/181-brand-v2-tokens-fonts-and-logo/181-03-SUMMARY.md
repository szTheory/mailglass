---
phase: 181-brand-v2-tokens-fonts-and-logo
plan: 03
subsystem: ui
tags: [brand-v2, glyph-coverage, woff2-subset, heroicons, ast-scan, contrast, opacity-utilities, mailglass_admin]

requires:
  - phase: 181-brand-v2-tokens-fonts-and-logo
    provides: the six pinned woff2 (170-code-point subset), the contrast contract and `Contrast` helper, the `superseded.json` marker pattern (plans 01 and 02)
provides:
  - "`MailglassAdmin.TestSupport.GlyphScan` (`rendered_strings/2`, `offending/2`, `hero_names/1`): one AST-based scan of rendered admin text shared by the glyph contracts"
  - "`arrow-left` and `arrow-right` vendored heroicons (v2.2.0 24/outline) with bundle rules; the back link and both Open full detail links draw them; the gallery caption has no arrow"
  - "every rendered U+00B7 separator in admin lib is U+2022, including the root layout title suffix"
  - "`glyph_contract_test.exs`: arrow scan (no allow-list), 170-code-point subset scan with an exact reasoned allow-list, subset bound to the six woff2 sha256 values in brand.pin.json, every `hero-<name>` has a bundle rule, 17 teeth cases"
  - "contrast_contract_test opacity-utility guard: seven composite rows (28 pairs per theme), three reasoned decorative-edge exemptions, stale and dangling-reference detection, 9 teeth cases"
affects: [181-04, 182, 183]

actuals:
  tokens: 86770
  tasks: 3
  commits: 8

tech-stack:
  added: []
  patterns:
    - "One scan, several contracts: GlyphScan reads source text through the Elixir parser (literal_encoder), skips @doc/@moduledoc/@typedoc and HEEx comments, and returns exact lines; contracts differ only in the allowed? predicate"
    - "An allow-list is exact {file, code point, reason} and an entry the scan no longer finds is itself a failure, so it cannot rot"
    - "A font subset literal is bound to the pinned font bytes: the six sha256 values sit beside it and are compared with brand.pin.json and with the shipped files"
    - "Opacity-modified colour utilities are keyed by the utility string (never a line number) in two tables, composite rows expanded into the existing admin-pair machinery"

key-files:
  created:
    - mailglass_admin/test/support/glyph_scan.ex
    - mailglass_admin/test/mailglass_admin/glyph_contract_test.exs
  modified:
    - mailglass_admin/assets/vendor/heroicons-inline.js
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
    - mailglass_admin/test/mailglass_admin/contrast_contract_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/operator/repair_state_test.exs
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/operator.spec.js
    - reference/demo_app/assets/e2e/outbound-replay.spec.js
    - .planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json

key-decisions:
  - "GlyphScan returns one {line, text} pair per non-empty source line for both kinds (the interface said one string per file for :heex), so every finding names its exact line; HEEx comments are replaced by their newlines so later lines keep their numbers"
  - "`hero_names/1` returns names without the `hero-` prefix and never a trailing hyphen"
  - "The scan found U+000D in the gallery raw-MIME evidence specimen; allow-listed as an exact {file, code point, reason} entry rather than widening the 170-code-point literal with whitespace controls"
  - "Composite opacity rows are expanded into the existing `admin_pair_failures/3` machinery, so failures name utility, text colour, ground, theme, both hexes, ratio and threshold with no second ratio implementation"
  - "Each exempt edge is also asserted below 3:1 on both surfaces in both themes (1.57 to 2.51 measured), so an exemption cannot hide a requirement; a stale composite row is deliberately not red (a harmless extra check), only a stale exemption is"
  - "The heroicons header said `All 31` while the object already held 32; it now says 34 (32 plus the two new icons)"

patterns-established:
  - "Bundle-moving or root-layout-moving change = rebuild, `--check`, recompute the `superseded.json` bundle sha256 and root layout blob (used twice here: bf564d1e... then the blob c89fca34...)"
  - "Pin edits for a changed lib string: move lib-derived pins, leave fixture-derived pins (stored data) byte-identical, record the repo-wide re-grep"

requirements-completed: [BRTOK-02, BRTOK-03, BRTOK-04]

coverage:
  - id: D1
    description: "No rendered admin lib text contains U+2190-U+2193: the back link and both Open full detail links draw hero-arrow-left / hero-arrow-right, the gallery caption is reworded, and an arrow scan with no allow-list proves it"
    requirement: BRTOK-04
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/glyph_contract_test.exs#arrow scan over admin lib (D-17, BRTOK-04)"
        status: pass
      - kind: integration
        ref: "mutation (b): leftwards arrow planted in root.html.heex -> 24 tests, 2 failures; restored -> 72 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "arrow-left and arrow-right are vendored (heroicons v2.2.0 24/outline) and have .hero-arrow-left / .hero-arrow-right rules in the committed bundle; every hero-<name> used in lib has a bundle rule"
    requirement: BRTOK-04
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/glyph_contract_test.exs#every hero icon used in lib has a rule in the compiled bundle"
        status: pass
      - kind: integration
        ref: "mix mailglass_admin.assets.build --check; bash mailglass_admin/scripts/check-conformance.sh (ICON-EXISTS-GATE); mutation (c) red then green"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every rendered U+00B7 separator in lib is U+2022 (six files, 20 occurrences, root layout title included); lib-derived ExUnit, e2e and demo pins follow; fixture-derived U+00B7 strings are byte-identical"
    requirement: BRTOK-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/{operator_live,components,preview_live}_test.exs, operator/repair_state_test.exs (461 tests with the contracts, 0 failures)"
        status: pass
      - kind: integration
        ref: "git diff --exit-code 9bd70fa5 -- ... mailglass_admin/test/support/operator_fixtures.ex (exit 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A contract fails on any rendered lib code point outside the 170-code-point font subset except exact {file, code point, reason} allow-list entries for the gallery worst-case fixtures; the subset is bound to the six woff2 sha256 values in brand.pin.json and to the shipped bytes"
    requirement: BRTOK-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/glyph_contract_test.exs#font subset over admin lib (D-13, BRTOK-03) and #the subset is bound to the pinned font bytes"
        status: pass
      - kind: integration
        ref: "mutation (a): middle dot planted in suppression_card.ex -> suppression_card.ex:141 U+00B7 is outside the font subset, 24 tests, 1 failure; restored -> 24 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every opacity-modified colour utility in admin lib is a contrast-checked composite row (seven text-on-tint grounds, base-content and secondary over base-100 and base-200, both themes, >= 4.5) or a reasoned decorative-edge exemption with an existing carrying pair; a stale exemption fails"
    requirement: BRTOK-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/contrast_contract_test.exs#opacity-modified colour utilities (D-06, D-07) and #opacity detectors have teeth"
        status: pass
    human_judgment: false
  - id: D6
    description: "The before-catalog marker is rebound after each bundle or root-layout move; the required cold-build admin lane, format, conformance trio, test-exception registry and icon_exists_gate_test are green at plan end"
    requirement: BRTOK-04
    verification:
      - kind: integration
        ref: "MIX_BUILD_PATH=<cold> mix verify.support_contract.admin (1485 tests, 0 failures, 1 excluded); mix test test/scripts/icon_exists_gate_test.exs (6 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-11-15
status: complete
plan_head_before: 30ac708d6adac01996a80ddac3e2d726761c7565
plan_head_after: ad5538e396f6abc8882ab3ab4e03bca8148d64e1
commits: 8
---

# Phase 181 Plan 03: Glyph Coverage, Arrow Icons and the Opacity-Utility Contrast Guard Summary

**The four rendered arrows become drawn heroicons or plain words, every rendered middle dot becomes a bullet, one AST scan proves admin lib text stays inside the 170-code-point subset of the six pinned woff2 (bound to their sha256 values), and every opacity-modified colour utility is now a contrast-checked composite or a reasoned exemption**

## Performance

- **Duration:** 17 min (wall clock from the commit ledger to the last gate; the cold admin lane was about 3 min of it)
- **Started:** 2026-11-15T16:27:33Z
- **Completed:** 2026-11-15T16:44:00Z
- **Tasks:** 3 (Task 1 tracer, Task 2 TDD contracts, Task 3 e2e and demo pins plus plan-end gate)
- **Files:** 24 changed (2 created, 22 modified), plus this summary
- **Execute-start SHA:** `30ac708d6adac01996a80ddac3e2d726761c7565`

## Accomplishments

- **Arrows (D-17):** `arrow-left` and `arrow-right` are in `heroicons-inline.js` (path data from the plan; same one-line SVG shape as `arrow-path`). `operator_live.ex` draws `hero-arrow-left` on the back link; both `Open full detail` links draw `hero-arrow-right` (`ml-xs h-4 w-4`); the gallery caption reads `reject_reason: nil, no badge`. The bundle has `.hero-arrow-left` and `.hero-arrow-right` (138,844 bytes, a one-line diff of the minified file). Accessible names did not change: the glyph was already `aria-hidden`.
- **Separators (D-13, F6):** 20 occurrences on 17 lines in six lib files (`components.ex`, `operator/repair_state.ex`, `operator/support_cards.ex`, `operator/suppression_card.ex`, `operator/timeline.ex`, `layouts/root.html.heex`) went from U+00B7 to U+2022 with the surrounding spaces untouched. The root layout title suffix changed too: the browser chrome draws it, not the bundled fonts, so this is for scan consistency and it moved the root layout blob (`132731a7...` to `c89fca34...`). `@moduledoc` text (F7), fixture data and Phase 182 copy were not touched.
- **`GlyphScan`:** pure scan, no file IO inside `rendered_strings/2` or `offending/2`. It parses `:ex` sources with `Code.string_to_quoted!/2` and a `literal_encoder`, collects binaries, interpolated fragments and sigil content (heredoc content starts on the line after the delimiter), skips `@doc`/`@moduledoc`/`@typedoc` bodies, and strips `<%!-- --%>` from `~H`. `:heex` files are scanned whole with comments removed.
- **`glyph_contract_test.exs`** (24 tests, 482 lines): arrow scan with no allow-list over every `.ex`/`.heex` under `lib`; font subset scan; hero-rule check (31 used icons, 31/31 have a rule; the RESEARCH baseline was 29/29); six sha256 values copied in full beside the subset literal and compared with `brand.pin.json` and with the shipped files. The scan's only subset findings are nine allow-listed `{gallery_live.ex, code point, reason}` entries: the four katakana of the non-ASCII tenant specimen, the four kanji of the non-ASCII display-name specimen, and U+000D in the raw-MIME evidence specimen.
- **Opacity-utility guard** in `contrast_contract_test.exs` (33 tests, +11): ten distinct utilities found in lib, seven composite rows (28 pairs per theme: seven utilities x two text colours x two grounds), three exemptions. Tightest composite: light `secondary` on `bg-error/10` over base-100, 5.19:1. Every exempt edge measured below 3:1 on both surfaces in both themes (1.57 to 2.51).
- Lib-derived pins follow: 12 ExUnit pins in four files, 10 e2e pins in three specs and one demo spec pin. Fixture-derived pins (`operator_fixtures.ex:472`, `operator_live_test` 675/690, `phase169-journey` 220, `flows.spec` 2211/2238/2255) are byte-identical.

## Task Commits

1. **Task 1 (tracer): vendored arrow icons -> call sites -> rebuilt bundle -> shared scan + arrow contract + hero-rule check**
   - `66ef70cd` feat(admin): draw back and detail arrows as icons
   - `fb796ce5` docs: rebind the before-catalog marker to the arrow-icon bundle
2. **Task 2: bullet separators, subset contract bound to the font hashes, opacity-utility guard, ExUnit pins**
   - `27403d77` feat(admin): use bullet separators the brand fonts can draw
   - `79c0682e` test(admin): bind rendered admin text to the brand font subset
   - `9092caa1` test(admin): pair or exempt every opacity-modified admin colour utility
   - `d19c0c6f` docs: rebind the before-catalog marker to the bullet-separator layout
3. **Task 3: lib-derived e2e and demo pins, plan-end lanes, mutation proofs**
   - `44d7fe45` test(admin): expect bullet separators in browser specs
   - `ad5538e3` chore(demo): expect the bullet separator in the replay audit spec

**Plan metadata:** the `docs(181-03): complete ...` commit (this file) and a following state and roadmap commit.

Tracer gate: after the tracer commits `mix mailglass_admin.assets.build --check` matched, `git diff --quiet -- priv/static` was clean, `glyph_contract_test` + `before_catalog_manifest_test` + `bundle_test` passed (69 tests, 0 failures) and `check-conformance.sh` printed `OK`. Tracer verified end-to-end, then expanded.

## Files Created/Modified

See the frontmatter lists. Key edit sites: `mailglass_admin/test/support/glyph_scan.ex` (scan), `mailglass_admin/test/mailglass_admin/glyph_contract_test.exs` (arrow, subset, pin binding, hero rule, teeth), `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` (`@opacity_composites`, `@opacity_exemptions`, `opacity_utility_failures/3`), `mailglass_admin/assets/vendor/heroicons-inline.js`.

## Decisions Made

See `key-decisions`. Two worth restating:

- **U+000D is allow-listed, not folded into the subset.** The scan reported four CR characters in `gallery_live.ex` lines 1122-1125, the `\r\n` wire format inside the revealed raw-MIME specimen. The 170-code-point literal stays exactly the font's cmap; the CR is one exact `{file, 0x000D, reason}` entry, which is the mechanism the plan prescribes for a deliberate worst-case fixture.
- **No arrow remains anywhere in rendered lib text** (the arrow scan has no allow-list). The other U+2190-U+2193 occurrences in lib are in comments and `@doc` text (`router.ex`, `operator_live.ex` comment, `inbound_live.ex` comment, `pub_sub/topics.ex`, `controllers/assets.ex`, `components.ex` `@doc`), which the scan correctly ignores.

## Deviations from Plan

None - plan executed exactly as written.

Two small notes that are not deviations: the plan's interface said `rendered_strings(:heex)` returns the whole file as one string, and this returns the same text split per line so findings carry exact line numbers (see `key-decisions`); and the heroicons header comment said `All 31` while the object already held 32 entries, so it now says 34.

## Issues Encountered

- **The three-spec e2e run rewrites tracked PNGs.** `npm run test:operator-browser -- e2e/phase169-journey.spec.js ...` regenerated 20 tracked screenshots under `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/`. They were restored with `git checkout -- <that directory>` and none was committed (`git status` was clean afterwards). 181-04 should do the same after any e2e run.
- **One advisory e2e test flaked in the full run.** `e2e/flows.spec.js:2000 Phase 175 Delivery layout U1/U2/U3/U5/U6` timed out clicking the `fjordline-aps` account option (an account-switcher click before any string this plan changed). Run alone it passed (`1 passed`). 76 passed, 1 failed in the three-spec run. Advisory evidence only; not the required proof.

## Lane evidence

Required lane `support_contract_admin` (`mix verify.support_contract.admin`, cold `MIX_BUILD_PATH` under `/private/tmp/mg181_03_cold/...`, whole admin test directory):

```
Admin bundle matches a fresh build (138844 bytes).
...
1485 tests, 0 failures, 1 excluded      (RC=0)
```

Baseline before this plan was 1448 (181-02), so the plan adds 37 tests (glyph contract 24, contrast guard 11, plus the moved ExUnit pins which add none).

Required lane `conformance_gates` (the ICON-EXISTS-GATE is inside the first):

```
OK: design-system conformance clean.            (mailglass_admin/scripts/check-conformance.sh)
OK: motion conformance clean.                   (scripts/check_motion_conformance.sh)
OK: advisory design-system conformance clean.   (mailglass_admin/scripts/check-conformance-advisory.sh)
OK: test exception registry is complete and unexpired.   (scripts/check_test_exceptions.sh)
```

Required lane `core_deterministic_suite` file (`mix test test/scripts/icon_exists_gate_test.exs --warnings-as-errors --seed 0`): `6 tests, 0 failures` (it copies `heroicons-inline.js`, which this plan edits).

Other gates: `mix format --check-formatted` exit 0 in `mailglass_admin` and in the root; `git diff --exit-code 9bd70fa5 -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json lib test/mailglass test/fixtures test/support mailglass_admin/test/support/operator_fixtures.ex` exit 0 (no dependency, no core change, no fixture change); `git diff --exit-code 9bd70fa5 -- .planning/release-target.json` exit 0. Final committed bundle sha256 `bf564d1ef48fda2fd9d3e03600f4c5c344964b33c94486b12addc8d9bc46ac70`, root layout blob `c89fca348193f24ea614f0d48e8ff29187d7b519`, both equal to `superseded_by` in the marker.

ADVISORY evidence (never cited as proof): the three admin e2e specs, `cd mailglass_admin && npm run test:operator-browser -- e2e/phase169-journey.spec.js e2e/flows.spec.js e2e/operator.spec.js`: `76 passed, 1 failed` (the flake above, passes alone), then `git diff --exit-code priv/static/app.css` exit 0 (the build did not move the bundle). The demo `outbound-replay.spec.js` edit was syntax-checked with `node --check` and not run (the demo stack is not up).

**gsd regression gate browser subset.** `scripts/gsd-regression-gate.sh` runs a browser subset unconditionally: `e2e/phase170-journey.spec.js e2e/flows.spec.js e2e/structural.spec.js --grep 'Phase 170|Phase 171|Preview:|Preview (happy|error|boundary|edge|advanced)'`. This plan edits `e2e/flows.spec.js` pins (lines 1995 and 2306) and the subset exercises that file. The subset is run as advisory evidence in 181-04's plan-end gate, after `structural.spec.js` has moved too. This plan does not cite it as proof.

## Repo-wide U+00B7 re-grep

`git grep -n "$(printf '\302\267')" -- . ':!.planning' ':!brandbook' ':!prompts' ':!*.md' ':!*.png' ':!mailglass_admin/lib'` after the last pin edit:

```
Makefile:94:	@printf '\n  Stop: make demo-down · Reset data: make demo-reset · Browser evidence: make demo-e2e\n\n'
mailglass_admin/e2e/flows.spec.js:2211:    await expect(card).toContainText("operator review · Ångström");
mailglass_admin/e2e/flows.spec.js:2238:    await expect(card).toContainText("operator review · Ångström");
mailglass_admin/e2e/flows.spec.js:2255:    await expect(card).not.toContainText("operator review · Ångström");
mailglass_admin/e2e/phase169-journey.spec.js:220:    await expect(current).toContainText("operator review · Ångström");
mailglass_admin/test/mailglass_admin/glyph_contract_test.exs:67:  @middot "·"
mailglass_admin/test/mailglass_admin/operator_live_test.exs:675:      long_source = "東京·Ångström-" <> String.duplicate("配信·é·", 40) <> "<script>alert(1)</script>"
mailglass_admin/test/mailglass_admin/operator_live_test.exs:690:      assert long_unicode_html =~ "東京·Ångström-"
mailglass_admin/test/support/operator_fixtures.ex:472:              source: "operator review · Ångström",
reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:108:              <p class="kicker">Mailglass demo · sample Phoenix app</p>
test/mailglass/operator/timeline_test.exs:189:      assert Enum.map(rows, &replay_summary_for(&1)) == ["requested", "completed · no change"]
test/mailglass/operator/timeline_test.exs:274:    do: "completed · new work"
test/mailglass/operator/timeline_test.exs:277:    do: "completed · no change"
```

Why each remaining hit stays:

- `Makefile:94`: make help text, not admin lib text.
- `flows.spec.js` 2211/2238/2255 and `phase169-journey.spec.js:220`, `operator_live_test.exs` 675/690, `test/support/operator_fixtures.ex:472`: fixture data stored in the database and the specs that pin it (F8). It renders through the fallback face on purpose as a worst case. `operator_fixtures.ex` has 1 occurrence at HEAD and still 1 (`grep -c` before and after: 1 and 1).
- `glyph_contract_test.exs:67`: the `@middot` constant the teeth cases plant into synthetic sources; it is test data, not lib text.
- `reference/demo_app/.../page_controller.ex:108`: demo-app page copy, not admin lib text and not pinned by any spec.
- `test/mailglass/operator/timeline_test.exs` (189/274/277): a core test whose helper builds its own replay-summary strings with U+00B7 from core `Mailglass.Operator.Timeline`, which itself has no U+00B7; it is not lib-derived from the admin, and BRTOK-06 forbids editing `test/mailglass/**`.

Admin lib itself: the only U+00B7 left are the two `@moduledoc` mentions (F7, `inbound/records_list.ex:12` and the doc text the scan ignores).

## Opacity-utility re-grep

`git grep -nE '(bg|border|ring|text|outline|divide|fill|stroke|from|via|to|shadow|decoration|placeholder|caret|accent)-(primary|secondary|accent|neutral|base-100|base-200|base-300|base-content|info|success|warning|error)(-content)?/[0-9]+' -- mailglass_admin/lib` found 10 distinct utilities on 17 lines (the plan recorded 14 lines; the ten utilities are the same, no new one): `bg-base-100/60`, `bg-base-100/70`, `bg-error/5`, `bg-error/10`, `bg-primary/5`, `bg-success/10`, `bg-warning/10`, `border-error/40`, `border-primary/30`, `ring-primary/40`. Seven are composite rows, three are exemptions, none beyond the plan's. The acceptance command (every utility named in `contrast_contract_test.exs`) prints `0`.

Measured ratios (Role Map hexes, 0.04045 helper): composites range 5.19 (light `secondary` on `bg-error/10` over base-100) to 15.39:1; `base-content` is at least 12.51 on `bg-primary/5` (dark, base-200) and at least 11.09 on the 10% tints (dark `bg-warning/10`, base-200), so the exemption reasons that cite "base-content >= 12.5" and ">= 11.0" are true. Exempt edges: `border-primary/30` 1.57 to 1.96, `border-error/40` 1.97 to 2.36, `ring-primary/40` 1.86 to 2.51. The carrying pair for `ring-primary/40`, `text-primary` on base-100 and base-200, is 5.85 / 6.58 light and 9.27 / 8.24 dark.

## Mutation proofs

All three run against the committed tree and restored; each red line and the restored green run are quoted.

- **(a) U+00B7 planted in a lib string** (`operator/suppression_card.ex:141`, `"Address • Account-local"` to `"Address · Account-local"`): `glyph_contract_test` red, `mailglass_admin/operator/suppression_card.ex:141 U+00B7 is outside the font subset`, `24 tests, 1 failure`. Restored with `git checkout -- lib/mailglass_admin/operator/suppression_card.ex`; `24 tests, 0 failures`.
- **(b) leftwards arrow planted in a HEEx template** (`layouts/root.html.heex` title suffix to `" ← mailglass"`): red twice, `mailglass_admin/layouts/root.html.heex:7 U+2190 is outside the font subset` (subset scan) and `arrow glyphs in rendered admin text (the brand fonts cannot draw them; use a hero-arrow-* icon): mailglass_admin/layouts/root.html.heex:7 U+2190` (arrow scan), `24 tests, 2 failures`. Restored with `git checkout --`; `glyph_contract_test` + `before_catalog_manifest_test`: `72 tests, 0 failures`.
- **(c) `arrow-left` removed from the vendored plugin and the bundle rebuilt:** the rebuilt bundle kept only `.hero-arrow-right`; hero-rule test red, `hero icons used in lib with no bundle rule (they render invisibly; embed the SVG in assets/vendor/heroicons-inline.js and rebuild): ["arrow-left"]`, `24 tests, 1 failure`; ICON-EXISTS-GATE red as well (`FAIL: ICON-EXISTS-GATE — admin hero-* usage is absent from heroicons-inline.js`). Restored with `git checkout -- assets/vendor/heroicons-inline.js priv/static/app.css`, rebuilt, `Admin bundle matches a fresh build (138844 bytes).`, `git diff --exit-code -- priv/static/app.css assets/vendor/heroicons-inline.js` exit 0, `72 tests, 0 failures`.

In-test teeth (all named failures): leftwards arrow in a plain string, an interpolated string, a multi-line `~H` heredoc (reported on its exact line) and a `.heex` template; docs and `#` and HEEx comments are not scanned; middot in `~H`, plain string and `.heex`; an allow-list entry covers exactly its file and code point; a stale allow-list entry; a changed recorded font hash and an unrecorded pinned font; a dropped `.hero-arrow-left` rule; and, for the opacity guard, an unpaired planted `bg-info/10` (file and line), four other prefixes, a removed exemption, a removed composite row, a stale exemption, a reasonless exemption plus dangling and empty carrying pairs, an exempt edge at or above 3:1, `text-disabled` on `bg-error/10` (3.36:1, below 4.5) and a lightened `text-muted` turning every `secondary` composite red.

## Release effect

`66ef70cd` and `27403d77` are `feat(admin):` commits and are release-visible for `mailglass_admin` (the arrow icons and the bullet separators change what the dashboard renders); Release Please will fold them into the same proposed minor bump as 181-02's `feat(admin):` commit. The `test`, `docs` and `chore(demo)` commits are not release-visible. No release is initiated and `.planning/release-target.json` is untouched.

## Known Stubs

None.

## Threat Flags

None. No network endpoint, auth path or trust-boundary schema was added. T-181-09 (vendored icon data) is mitigated as planned: path data is the heroicons v2.2.0 family the file already vendors, the hero-rule test proves every used icon has a bundle rule, and the SVG strings contain no script or URL. T-181-10 (the "glyph gone from every screen" claim) is mitigated: the scan is AST-based over every lib source with teeth and an exact reasoned allow-list. T-181-SC: no package installed, lockfiles untouched (diff exit 0).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **181-04** (logo, advisory-file cleanup): the arrow and separator work is done and bound to the required lane. Any later `app.css` or `lib/` change must recompute the `superseded.json` bundle sha256 (currently `bf564d1e...`) and, for a root layout change, the blob (currently `c89fca34...`). The three advisory e2e specs were run here and the demo replay spec edit was only syntax-checked. 181-04 should run the gsd regression gate browser subset named above after `structural.spec.js` has moved, restore the archived v2.9 PNGs that `phase169-journey.spec.js` rewrites, and carry no U+00B7 or arrow into any new lib text (the glyph contract will fail it).
- Phase 182 copy changes in admin lib are now guarded: any new character outside the 170-code-point subset, any arrow, any hero icon without a bundle rule and any new opacity-modified colour utility fails the required lane until it is replaced, drawn, vendored or paired.

---
*Phase: 181-brand-v2-tokens-fonts-and-logo*
*Completed: 2026-11-15*

## Self-Check: PASSED

- Both created files (`mailglass_admin/test/support/glyph_scan.ex`, `mailglass_admin/test/mailglass_admin/glyph_contract_test.exs`) exist on disk.
- Commits `66ef70cd`, `fb796ce5`, `27403d77`, `79c0682e`, `9092caa1`, `d19c0c6f`, `44d7fe45`, `ad5538e3` are ancestors of HEAD; `git rev-list --count 30ac708d6adac01996a80ddac3e2d726761c7565..HEAD` is 8, matching `commits: 8`.
- The committed bundle sha256 (`bf564d1e...`) and root layout blob (`c89fca34...`) equal `superseded_by`; every task acceptance criterion and the Plan-end gate were re-run green.
