---
phase: 181-brand-v2-tokens-fonts-and-logo
plan: 02
subsystem: ui
tags: [brand-v2, fonts, woff2, brand-pin, compile-time-embed, tabular-nums, mailglass_admin]

requires:
  - phase: 181-brand-v2-tokens-fonts-and-logo
    provides: the rewritten token sources, the `superseded.json` marker pattern and the contrast contract (plan 01)
  - phase: 179-compatibility-policy-status-map-and-brand-pin
    provides: `scripts/brand_pin.exs` verify/update machinery and the sha256-pinned brand zip
provides:
  - "`scripts/brand_pin.exs extend --expect-sha256 <hex> [--zip <path>]`: idempotent, zip-hash-and-size-first extension of the pin"
  - "brandbook/brand.pin.json with 16 shipped entries across two owned dirs (`brandbook/v2`, `mailglass_admin/priv/static/fonts`)"
  - "the six brand v2 woff2 (52,508 bytes) and three OFL texts in `mailglass_admin/priv/static/fonts`; the two lockup SVGs and the favicon SVG pinned under `brandbook/v2`"
  - "`MailglassAdmin.Controllers.Assets` compile-time font map and `allowed_fonts/0`; any other name is a 404 with an empty body"
  - "rebuilt bundle: six `@font-face` rules, book font stacks, `--font-weight-bold: 600`, tabular numerals on `time, td`, ligatures off in code"
  - "font_assets_contract_test: the required-lane static D-12 proof with 17 teeth cases"
affects: [181-03, 181-04, 182, 183]

actuals:
  tokens: 110694
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "One verb is the only way new assets enter the pinned tree: extend checks the zip sha256 and size before reading any member, refuses before any write, writes assets first and the pin atomically"
    - "Fonts embedded like CSS and logo: explicit name list, `@external_resource` per file, name-to-bytes map; the allow-list is the map's keys"
    - "A contract of pure `(css, file names, tokens) -> [failure]` functions plus a named-failure teeth block, so a pass is never vacuous"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs
    - brandbook/v2/mailglass-lockup-light.svg
    - brandbook/v2/mailglass-lockup-dark.svg
    - brandbook/v2/favicon.svg
    - mailglass_admin/priv/static/fonts/a-display-600.woff2
    - mailglass_admin/priv/static/fonts/ui-400.woff2
    - mailglass_admin/priv/static/fonts/ui-600.woff2
    - mailglass_admin/priv/static/fonts/ui-400i.woff2
    - mailglass_admin/priv/static/fonts/a-mono-400.woff2
    - mailglass_admin/priv/static/fonts/a-mono-600.woff2
    - mailglass_admin/priv/static/fonts/OFL-FunnelDisplay.txt
    - mailglass_admin/priv/static/fonts/OFL-AtkinsonHyperlegibleNext.txt
    - mailglass_admin/priv/static/fonts/OFL-AtkinsonHyperlegibleMono.txt
  modified:
    - scripts/brand_pin.exs
    - test/scripts/brand_pin_test.exs
    - brandbook/brand.pin.json
    - brandbook/tokens.css
    - brandbook/tokens.json
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/test/mailglass_admin/bundle_test.exs
    - mailglass_admin/test/mailglass_admin/assets_test.exs
    - mailglass_admin/docs/design-system.md
    - mailglass_admin/scripts/check-conformance.sh
    - .planning/publish/mailglass_admin-files.expected
    - .planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json
    - scripts/check_phase174_evidence.cjs
    - scripts/check_phase174_evidence.test.cjs
    - scripts/check_phase175_evidence.cjs
    - scripts/check_phase175_evidence.test.cjs
  deleted:
    - mailglass_admin/priv/static/fonts/{inter-400,inter-700,inter-tight-400,inter-tight-700,ibm-plex-mono-400,ibm-plex-mono-700}.woff2

key-decisions:
  - "Verb `extend` with `@extension_manifest` (12 entries); `@required_assets` stays the four-asset `init` contract, so `init` still builds a pin `ensure_parses` accepts"
  - "extend also refuses a pin whose existing entry no longer equals its zip member (`shipped_member_mismatch`), so a hand-edited pin hash is refused rather than silently kept"
  - "`font-synthesis-weight: none` not added (F10): all three families ship a 600 face, so `font-bold` at 600 never synthesizes"
  - "Tabular numerals: a base rule `time, td` plus the existing Tailwind `tabular-nums` utility on the two mobile list `<ul>` containers; Tailwind's own `.tabular-nums` is not redefined; the preview sidebar scenario list is navigation with no numeric columns and is unchanged"
  - "design-system.md weight statements corrected in this plan under D-23 (see Design-system reason)"

patterns-established:
  - "Bundle-moving change = rebuild, recompute the `superseded.json` sha256, run the lane (again used here, sha256 6ccf2295...)"
  - "A deliberate 404 probe for a retired asset name is held in `@retired_font_probe` so the retired-name gate can exclude exactly that marked line"

requirements-completed: [BRTOK-03]

coverage:
  - id: D1
    description: "The pin gains an idempotent `extend` verb: zip sha256 and size are checked against the pin before any member is read, every refusal happens before any write, and the pin lists 16 assets in two owned dirs"
    requirement: BRTOK-03
    verification:
      - kind: unit
        ref: "test/scripts/brand_pin_test.exs (extend procedure over an injected getter; extended pin shape; fonts-dir tamper cases; CLI extend cases)"
        status: pass
      - kind: integration
        ref: "mix run --no-start scripts/brand_pin.exs extend --expect-sha256 ed96bb25... (re-run changes nothing); mismatched all-zero probe exits 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Six v2 woff2 (52,508 bytes) and three OFL texts are the only files in the fonts dir, copied unchanged from the pinned zip; the retired six woff2 are deleted"
    requirement: BRTOK-03
    verification:
      - kind: integration
        ref: "mix run --no-start scripts/brand_pin.exs verify (brand pin ok)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/bundle_test.exs (fonts describe)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Controllers.Assets embeds the six fonts at compile time; allowed_fonts/0 is the map keys; a retired name, an OFL text and an encoded traversal return 404 with an empty body"
    requirement: BRTOK-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/assets_test.exs (GET /dev/mail/fonts/<name>)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The bundle declares the six faces with font-display swap, v2 stacks equal to tokens.json, Funnel Display on h1-h3 at 600, `font-bold` at 600 with no 700, ligatures off in code, tabular numerals on time and td and on both mobile list containers"
    requirement: BRTOK-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs"
        status: pass
      - kind: integration
        ref: "mix mailglass_admin.assets.build --check (Admin bundle matches a fresh build, 137361 bytes)"
        status: pass
    human_judgment: false
  - id: D5
    description: "No remote font or stylesheet URL is reachable from the admin bundle (no url(http, no url(//, no remote @import), with a teeth case per pattern"
    requirement: BRTOK-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs#detectors have teeth"
        status: pass
    human_judgment: false
  - id: D6
    description: "Coupled files are current: publish allowlist, evidence scripts and their tests, the before-catalog marker, design-system.md weights and the BOLD-GATE comment"
    requirement: BRTOK-03
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin (conflict=0); node --test of the four evidence contract files (42 pass); before_catalog_manifest_test"
        status: pass
    human_judgment: false
  - id: D7
    description: "Required lanes at plan end: cold admin support_contract lane, root targeted files, conformance gates, test-exception registry, format checks, lockfile and core-scope guards"
    verification:
      - kind: integration
        ref: "MIX_BUILD_PATH=<cold> mix verify.support_contract.admin (1448 tests, 0 failures, 1 excluded); mix test docs_contract icon_exists brand_pin (143 tests, 0 failures, 1 skipped)"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-11-15
status: complete
plan_head_before: 0ef4bb8766e2f1b24268be74bcc3773b0745f23b
plan_head_after: 554e2934fa955b1421a09b9faaca005e5bba48b2
commits: 6
---

# Phase 181 Plan 02: Brand v2 Fonts Through the sha256 Pin and a Compile-Time Allow-List Summary

**Six brand v2 woff2 and three OFL texts enter the admin only through a new idempotent `brand_pin.exs extend` verb, are embedded at compile time behind a closed allow-list, drive Funnel Display / Atkinson Hyperlegible Next / Atkinson Hyperlegible Mono with `font-bold` at 600, and are proven local, listed and pinned by a static required-lane contract**

## Performance

- **Duration:** 14 min (wall clock from the commit ledger to the last gate; the cold admin lane was 89 s of it)
- **Started:** 2026-11-15T16:13:16Z
- **Completed:** 2026-11-15T16:27:00Z
- **Tasks:** 3 (Task 1 tracer, Task 2 TDD contract, Task 3 evidence scripts and gates)
- **Files:** 39 changed in total (13 created, 20 modified, 6 retired woff2 deleted), plus this summary
- **Execute-start SHA:** `0ef4bb8766e2f1b24268be74bcc3773b0745f23b`

## Accomplishments

- `extend` (pin, D-18): requires `--expect-sha256` to equal the pin, takes bytes from the pinned commit URL or a local `--zip` hashing to the same value, checks sha256 AND size before any member read, refuses a missing member, a pinned entry that no longer equals its member and a same-`to`-different-`from` conflict before any write, then writes assets first and the pin atomically. Run twice it is byte-identical. The pin now owns `brandbook/v2` and `mailglass_admin/priv/static/fonts` and lists 16 entries; `priv/static` itself is never owned.
- The six woff2 total 52,508 bytes (zip-sourced hashes, never `brand.json`'s TTF hashes) and the three OFL texts sit beside them; the six retired woff2 were removed in the same change, so `verify` reports `brand pin ok`.
- `Controllers.Assets` embeds the fonts like the CSS and logo (`@external_resource` per file, `@fonts` map, `@allowed_fonts` = sorted keys, `@doc false allowed_fonts/0`). The disk-reading clause is gone; the moduledoc "Font allowlist" paragraph is rewritten and records that a replaced font needs a new file name (T-181-08).
- `app.css`: six `@font-face` rules (relative `./fonts/` URLs, `font-display: swap`), book stacks for `--font-ui/--font-display/--font-mono`, Funnel Display on h1-h3, Atkinson Hyperlegible Next on body, Atkinson Hyperlegible Mono with `font-variant-ligatures: none` on code (and the `.mg-admin-root` mirrors), `--font-weight-bold: 600` in `@theme`, and `time, td { font-variant-numeric: tabular-nums }`. The two mobile email list `<ul>` containers carry the existing `tabular-nums` utility. `brandbook/tokens.css` and `tokens.json` carry the same stacks. The compiled bundle (137,361 bytes) has no `font-weight:700` and no remote URL.
- `font_assets_contract_test.exs` (24 tests, 17 of them teeth): disk == allow-list == `@font-face` URLs, the face table, `font-display: swap`, no remote url/protocol-relative url/remote `@import`, `wOF2` bytes, OFL texts, role stacks equal `tokens.json`, heading/code/body rules, tabular numerals in the CSS and in both list containers.
- Coupled files kept current in the same change: publish allowlist (9 font and license lines), `bundle_test`, `assets_test` (each allowed face returns 200 `font/woff2` with a `wOF2` body; retired name, OFL text and traversal are empty-body 404s), the before-catalog marker, and the Phase 174/175 evidence scripts and tests (six new names, families and weights).

## Task Commits

1. **Task 1 (tracer): pin `extend` -> fonts on disk -> compile-time map -> `@font-face` -> served and listed**
   - `7781b4b1` chore(brand): add the brand_pin extend verb and pin v2 fonts and logo files
   - `db7ceb74` feat(admin): serve brand v2 fonts from a compile-time allow-list
   - `54f942c8` docs: mark the before-catalog superseded by the v2 font bundle
2. **Task 2: static font contract (D-12) with teeth, weight statements**
   - `0c625680` test(admin): prove the admin fonts are local, listed and pinned
   - `ac70e88b` docs(admin): state the 400/600 type weights
3. **Task 3: evidence scripts, retired-font gate, plan-end lanes** - `554e2934` chore(brand)

**Plan metadata:** the `docs(181-02): complete ...` commit (SUMMARY, STATE, ROADMAP, REQUIREMENTS) follows this file.

Tracer gate: after the tracer commits `brand_pin.exs verify` printed `brand pin ok`, the bundle `--check` matched, `git diff -- priv/static` was clean and the four test files passed (79 tests, 0 failures). Tracer verified end-to-end, then expanded.

Zip source: **the pinned raw commit URL** (HTTP 200 at the precondition check; no `--zip` fallback and no `BRAND_ZIP` was needed). Output: `pin extended: 16 shipped assets in 2 owned directories`, then `brand pin ok`.

## Files Created/Modified

See the frontmatter lists. Key edit sites: `scripts/brand_pin.exs` (extend verb, `@extension_manifest`, `--zip`), `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` (compile-time font map), `mailglass_admin/assets/css/app.css` (font section, `@theme` weight), `mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs` (new contract).

## Decisions Made

- Verb name `extend`, constant `@extension_manifest`, option `--zip` (Claude's Discretion, D-18). Duplicate `from` is allowed by `entry_issues` (only duplicate `to` is rejected), so no relaxation was needed; the three OFL members ship to both `brandbook/v2` and the fonts dir and a test pins that.
- `extend` verifies every already-pinned entry against its zip member, not just the new ones. Without that, a pin whose recorded hash was edited by hand would be left as is while `write_assets` overwrote the file from the zip, and the BRTOK-03 "no hand edit of the pin" prohibition would rest on `verify` alone.
- Tabular numerals follow the plan's two-part design (see key-decisions). Re-grep of `data-testid="[a-z-]*-list"` over `mailglass_admin/lib` found exactly three: the two covered containers and `preview/sidebar.ex`'s scenario menu (navigation, no numeric columns, unchanged).
- `font-synthesis-weight: none` not added (F10).

## Design-system reason

`mailglass_admin/docs/design-system.md` weight statements (the `Type (400/600 only)` row and the `Type weights are exactly 400 and 600` paragraph) and the BOLD-GATE comment in `check-conformance.sh` are corrected in this plan, not deferred to Phase 183. Reason: D-23 (a sentence that states a value the change makes false is corrected in the plan that changes it) with D-09 truth-keeping and RESEARCH F1 (the shipped doc must state the weights the bundle actually loads in the same change that makes them true). The removed second sentence ("500/600 are NOT loaded, the browser synthesizes a fake bold") was false once the 600 face shipped. The BOLD-GATE grep itself is unchanged. The broader prose rewrite stays Phase 183.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] `extend` refuses a pinned entry that no longer matches its zip member**
- **Found during:** Task 1 (designing the refusals before any write)
- **Issue:** The plan's refusal list covers the zip hash, size, a missing member and a conflicting `to`, but not an already-pinned entry whose recorded sha256 or bytes were changed by hand. `write_assets` would overwrite the file from the zip while the pin kept the edited hash, which defeats the provenance gate the plan-end block relies on.
- **Fix:** `check_existing_entries/2` returns `{:error, {:shipped_member_mismatch, from}}` before any write; covered by an extend teeth test.
- **Files modified:** `scripts/brand_pin.exs`, `test/scripts/brand_pin_test.exs`
- **Committed in:** `7781b4b1`

**2. [Rule 1 - Bug] The wrong-origin font fixture would have tested the file name, not the origin**
- **Found during:** Task 3 (evidence tests)
- **Issue:** The plan says to put `ui-400.woff2` in the wrong-origin fixture URL "so it still tests origin, not name". With the six names in face-table order `fonts[0]` is `a-display-600.woff2`, so a literal `ui-400.woff2` URL would fail the `endsWith('/fonts/<path>')` clause too and the case would no longer isolate the origin.
- **Fix:** the fixture URL is built from `fonts[0].path` with the foreign origin, so only the origin is wrong. The test still passes through `/wrong-source/`.
- **Files modified:** `scripts/check_phase175_evidence.test.cjs`
- **Committed in:** `554e2934`

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 1)
**Impact on plan:** No scope creep; both keep an existing guarantee true.

## Issues Encountered

- **Mutation (a) is a compile-time red, not an assertion red.** Renaming `ui-400.woff2` makes the compile-time embed fail (`could not read file ".../fonts/ui-400.woff2"`, `assets.ex:352`), which is a stronger guard than the contract assertion. A failed compile leaves `MailglassAdmin.Controllers.Assets` unbuilt, so after restoring the file the next test run reported 18 `UndefinedFunctionError` failures until `touch lib/mailglass_admin/controllers/assets.ex` forced a recompile (the mtime-preserving `mv` back looked unchanged to Mix). The assertion-level rename case is covered by the pure teeth tests ("an extra font file on disk or in the allow-list is named").
- Cold lane directory created under `/private/tmp/...` (not bare `mktemp -d`), per the 181-01 note about the macOS `/var` symlink; the Tailwind 4.1.12 binary was re-downloaded into the cold path as before.

## Lane evidence

Required lane `support_contract_admin` (`mix verify.support_contract.admin`, cold `MIX_BUILD_PATH`, whole admin test directory):

```
Admin bundle matches a fresh build (137361 bytes).
...
Finished in 22.8 seconds (6.3s async, 16.4s sync)
1448 tests, 0 failures, 1 excluded      (RC=0)
```

Baseline before this plan was 1419 tests (181-01), so the plan adds 29.

Required lane `core_deterministic_suite` files (`mix test test/mailglass/docs_contract_test.exs test/scripts/icon_exists_gate_test.exs test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0`): `143 tests, 0 failures, 1 skipped`; `brand_pin_test.exs` alone: `76 tests, 0 failures`.

Required lane `mix_task_tests` allowlist: `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` -> `Allowlist check result for mailglass_admin: create=2 update=1 unchanged=2 conflict=0`.

Required lane `conformance_gates`:

```
OK: design-system conformance clean.            (mailglass_admin/scripts/check-conformance.sh)
OK: motion conformance clean.                   (scripts/check_motion_conformance.sh)
OK: advisory design-system conformance clean.   (mailglass_admin/scripts/check-conformance-advisory.sh)
OK: test exception registry is complete and unexpired.   (scripts/check_test_exceptions.sh)
```

gsd gate (`node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs`): `tests 42, pass 42, fail 0`.

Other gates: `mix format --check-formatted` exit 0 in `mailglass_admin` and in the root; `git diff --exit-code 9bd70fa5 -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json lib test/mailglass test/fixtures test/support` exit 0 (no dependency, no core change); `git diff --exit-code 9bd70fa5 -- .planning/release-target.json` exit 0. No advisory lane is cited as proof.

Retired-font gate (tracked files under `mailglass_admin/{test,e2e,lib,priv/static,assets,docs}`, `reference/demo_app`, `scripts`, `brandbook/tokens.*`, with the plan's exclusions): prints `0`. Exclusions used, each with its reason: (a) `before_catalog_manifest_test.exs`, captured historical catalog fixture; (b) `reference/demo_app/assets/catalog/before-catalog.spec.js`, frozen Phase 180 capture instrument for the v1 before-catalog; (c) `phase174-review.md`, `phase175-review.md`, immutable historical receipts; (d) lines matching `retired[-_]font[-_]probe` (the one marked `@retired_font_probe` in `assets_test.exs`; `grep -ciE` over that file prints 2); (e) deferred to 181-04 Task 2, advisory and read by no required or gsd lane: `mailglass_admin/e2e/admin-assets.spec.js`, `reference/demo_app/assets/e2e/phase178-stories.spec.js`, `reference/demo_app/assets/e2e/storybook-fidelity.spec.js`, `reference/demo_app/storybook/foundations.story.exs`. No exclusion was added beyond the plan's.

### Provenance re-run (BRTOK-03: no hand edit of the pin, no asset bypassed `brand_pin.exs`)

Same zip source as Task 1 (the pinned raw URL; no `--zip`):

```
$ mix run --no-start scripts/brand_pin.exs extend --expect-sha256 ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b
pin extended: 16 shipped assets in 2 owned directories        (exit 0)
$ git diff --exit-code -- brandbook/brand.pin.json brandbook/v2 mailglass_admin/priv/static/fonts     (exit 0, empty)
$ git status --porcelain -- brandbook/brand.pin.json brandbook/v2 mailglass_admin/priv/static/fonts   (empty)
$ mix run --no-start scripts/brand_pin.exs extend --expect-sha256 0000...0000
extend refused: {:expect_sha256_not_pinned, "0000000000000000000000000000000000000000000000000000000000000000"}   (exit 1)
$ mix run --no-start scripts/brand_pin.exs verify
brand pin ok
```

## Mutation proofs

All four run against the committed tree and restored; each red line and the restored green run are quoted.

- **(a) rename `ui-400.woff2` to `ui-400-renamed.woff2`:** red at compile time, `** (File.Error) could not read file ".../priv/static/fonts/ui-400.woff2": no such file or directory` at `lib/mailglass_admin/controllers/assets.ex:352`. Restored by renaming back and `touch`ing `assets.ex` (see Issues); `font_assets_contract_test`: `24 tests, 0 failures`.
- **(b) copy a font to the retired name `inter-400.woff2` in the fonts dir:** `font_assets_contract_test` red (`24 tests, 2 failures`: `woff2 files on disk [... "inter-400.woff2" ...] differ from allowed_fonts [...]` and `@font-face URL files [...] differ from woff2 files on disk [...]`) AND `brand_pin.exs verify` red: `asset_unlisted: mailglass_admin/priv/static/fonts/inter-400.woff2` (exit 1). Restored by `rm`; contract `24 tests, 0 failures`, `verify` `brand pin ok`.
- **(c) flip the last byte of `ui-600.woff2`:** `brand_pin.exs verify` red: `asset_hash_mismatch: mailglass_admin/priv/static/fonts/ui-600.woff2` (exit 1). Restored with `git checkout -- .../ui-600.woff2`; `brand pin ok`.
- **(d) change one font url in the compiled bundle (`url(./fonts/ui-600.woff2)` -> `url(./fonts/ui-400.woff2)`):** contract red (`24 tests, 3 failures`), including `face Atkinson Hyperlegible Next normal 600 points at "ui-400.woff2", expected ui-600.woff2` and the URL-set difference. Restored with `git checkout -- priv/static/app.css`; `24 tests, 0 failures` and `Admin bundle matches a fresh build (137361 bytes).`

In-test teeth (all named failures): wrong-file face, missing face, extra file on disk and in the allow-list, face missing from the allow-list, missing `font-display: swap`, remote url, protocol-relative url, remote `@import` (url and bare forms), stack drift from `tokens.json`, heading rule without Funnel Display, code rule without ligatures off, non-woff2 bytes, missing and unlicensed OFL text, removed `time, td` rule, `tabular-nums` stripped from each list container, absent list container. `brand_pin_test` extend teeth: hash mismatch, size mismatch, differing and malformed `--expect-sha256` before any download, missing member before any write, drifted pinned entry, conflicting `to`, unreadable and mismatched `--zip`, hostile archive member ignored, twice byte-identical.

## Release effect

The `feat(admin):` commit (`db7ceb74`) is release-visible for `mailglass_admin`: Release Please will propose a minor bump when this reaches `main` (the retired woff2 files also leave the published tarball and the new fonts and OFL texts enter it). No release is initiated here and `.planning/release-target.json` is untouched. The `chore(brand):` and `docs` commits are not release-visible.

## Known Stubs

None.

## Threat Flags

None. No network endpoint, auth path or trust-boundary schema was added. The `extend` verb adds one zip download, which is the existing pinned-zip boundary (T-181-04) and is mitigated as planned: sha256 and size before any member read, `--expect-sha256` must equal the pin, tamper teeth, and `verify` asserts `asset_hash_mismatch` and `asset_unlisted`. T-181-05 (`/fonts/:name`: closed compile-time map, empty-body 404), T-181-06 (remote URL refutation with teeth) and T-181-07 (three OFL texts pinned, listed in the allowlist and asserted present) are mitigated as planned; T-181-08 is accepted and recorded in the `Assets` moduledoc; T-181-SC: no package installed, lockfiles untouched.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **181-03** (glyph subset): the six woff2 sha256 values are pinned in `brandbook/brand.pin.json`; do not re-subset, re-encode or rename them. The subset still lacks `·`, `✓`, `←`, `→` (D-13).
- **181-04 Task 2** owns the advisory files that still name the retired fonts (`mailglass_admin/e2e/admin-assets.spec.js`, `reference/demo_app/assets/e2e/phase178-stories.spec.js`, `reference/demo_app/assets/e2e/storybook-fidelity.spec.js`, `reference/demo_app/storybook/foundations.story.exs`), the 700 weight pins in `e2e/structural.spec.js` (`font-bold` is now 600), the advisory D-12 browser run, and a re-run of the retired-font gate without exclusion (e). Its 404 probe should carry the `retired-font-probe` marker.
- **181-04** (logo): `brandbook/v2/mailglass-lockup-light.svg`, `-dark.svg` and `favicon.svg` are pinned but NOT yet copied to `mailglass_admin/priv/static/`; the `assets_test` favicon assertions (`viewBox="0 0 16 16"`) are untouched and are its job.
- Any later `app.css` or `lib/` change must recompute the `superseded.json` sha256 (currently `6ccf2295...`) after the last build.

---
*Phase: 181-brand-v2-tokens-fonts-and-logo*
*Completed: 2026-11-15*

## Self-Check: PASSED

- All 13 created files (the contract test, three SVGs, six woff2, three OFL texts) exist on disk; the six retired woff2 are gone.
- Commits `7781b4b1`, `db7ceb74`, `54f942c8`, `0c625680`, `ac70e88b`, `554e2934` are ancestors of HEAD; `git rev-list --count 0ef4bb8766e2f1b24268be74bcc3773b0745f23b..HEAD` is 6, matching `commits: 6`.
- The committed bundle sha256 (`6ccf2295...`) equals `superseded_by.bundle_sha256`; every task acceptance criterion and the Plan-end gate were re-run green.
