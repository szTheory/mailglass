---
phase: 181-brand-v2-tokens-fonts-and-logo
reviewed: 2026-11-15T19:16:41Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - brandbook/brand.pin.json
  - brandbook/tokens.css
  - brandbook/tokens.json
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/assets/vendor/heroicons-inline.js
  - mailglass_admin/e2e/admin-assets.spec.js
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/scripts/check-conformance.sh
  - mailglass_admin/test/mailglass_admin/accessibility_test.exs
  - mailglass_admin/test/mailglass_admin/assets_test.exs
  - mailglass_admin/test/mailglass_admin/brand_test.exs
  - mailglass_admin/test/mailglass_admin/bundle_test.exs
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/contrast_contract_test.exs
  - mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs
  - mailglass_admin/test/mailglass_admin/glyph_contract_test.exs
  - mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs
  - mailglass_admin/test/mailglass_admin/operator/repair_state_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/support/contrast.ex
  - mailglass_admin/test/support/glyph_scan.ex
  - reference/demo_app/assets/e2e/outbound-replay.spec.js
  - reference/demo_app/assets/e2e/phase178-stories.spec.js
  - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
  - reference/demo_app/storybook/foundations.story.exs
  - reference/demo_app/storybook/quick_views/delivery.story.exs
  - reference/demo_app/storybook/quick_views/inbound.story.exs
  - scripts/brand_pin.exs
  - scripts/check_phase174_evidence.cjs
  - scripts/check_phase174_evidence.test.cjs
  - scripts/check_phase175_evidence.cjs
  - scripts/check_phase175_evidence.test.cjs
  - test/scripts/brand_pin_test.exs
findings:
  critical: 0
  warning: 6
  info: 5
  total: 11
  necessity: 0
status: issues_found
---

# Phase 181: Code Review Report

**Reviewed:** 2026-11-15T19:16:41Z
**Depth:** standard
**Files Reviewed:** 51
**Status:** issues_found

## Summary

Phase 181 adopts the brand v2 palette, six self-hosted woff2 faces and the typemark/favicon in
`mailglass_admin`, served from a compile-time allow-list and bound to a sha256 pin. I read every
listed file and then tried to break the claims instead of trusting them.

No critical or security defect was found in the areas flagged for attention:

- **`controllers/assets.ex` font route.** The route is `Map.fetch(@fonts, conn.params["name"])` against a
  compile-time map of six name-to-bytes pairs. No filesystem path is ever built from a request, so
  `..%2F..%2Fetc%2Fpasswd`, the OFL texts beside the fonts and the retired v1 names all return an
  empty 404. A `?name=` query param cannot widen the set (path params win, and the map is closed).
  The responses are public static bytes, consistent with the existing css/js routes.
- **`brand_pin.exs extend`.** Refusals all happen before any write: option shape, `--expect-sha256`
  equals the pin, zip sha256 and size equal the pin before any member is read, every member present,
  every existing entry still equals its zip member, no conflicting `to`. Member names come from the
  pin (`root <> from`), never from the archive, and `parse/1` rejects `..`, absolute, backslash, NUL
  and empty segments and requires every `to` to sit under an owned directory. `check_pinned_zip`
  hashes the exact bytes that are then read, so there is no check/use gap. The verb is idempotent.
- **CLAUDE.md "Things Not To Do".** No `compile_env`, no UPDATE/DELETE of events, no PII in telemetry,
  no `Swoosh.Mailer.deliver/1`, no tracking default. `mix mailglass_admin.assets.build --check`
  reports the committed bundle is byte-identical to a fresh build, so rule 6 holds.

Evidence gathered rather than assumed: the Phase 181 admin contract files (168 tests, also with
`--warnings-as-errors`), `test/scripts/brand_pin_test.exs` (76 tests), the two evidence-script node
suites (16 tests) and `brand_pin.exs verify` all pass; formatting is clean. I decoded the WOFF2 `cmap`
of all six faces and they each carry exactly the 170 code points `glyph_contract_test.exs` claims, so
the subset is real. I also fed `GlyphScan` twelve literal forms (plain, interpolated, `~s`, `~w`,
`~c`, `~S`, `~H` heredoc, `\u` and `\x{}` escapes, map keys, `attr default:`) and it caught all but
`<<0x2192::utf8>>`, which is contrived.

The weaknesses are in what the tests and the pin actually prove, and in cache policy. The six
warnings are test and contract gaps plus one behaviour risk; none breaks current behaviour.

## Warnings

### WR-01: `brand_pin_test.exs` CLI cases run `init`/`update`/`extend` against the real repository tree

**File:** `test/scripts/brand_pin_test.exs:1046-1078` (header claim at `:4-6`); `scripts/brand_pin.exs:512,533,945-946`
**Issue:** The file header says "every mutation writes only under its own ExUnit tmp_dir ... never the
repository tree". Three tests break that. `cli/2` reads the pin from `@repo_root` and `update/3` and
`extend/3` default `target_dir` to `@repo_root`, so:

- `extend against the real pin refuses a different zip` (`:1054`) calls `cli(["extend", "--expect-sha256", real_sha])` with a synthetic zip getter,
- `update against the real pin refuses a zip with the wrong hash` (`:1072`) does the same for `update`,
- `init against the real tree refuses because the pin exists` (`:1065`) does the same for `init`.

They pass today only because the refusal logic under test works. If `download/4`'s `sha256_hex(body)
== expect` guard regressed, the `update` case would proceed (the synthetic zip contains every pinned
member), run `write_all` with the real `@repo_root`, and overwrite `brandbook/brand.pin.json`, the
woff2 files and the lockups with synthetic bytes during a plain `mix test`. The only safeguard is a
`before_pin` comparison made after the damage and covering the pin file alone. A test for a
destructive verb should not be able to execute that verb on the working tree.
**Fix:** Make the CLI root injectable and point these tests at a temp copy, for example
`cli(args, getter \\ &http_get/1, root \\ @repo_root)` threaded into `read_pin/1` and the
`target_dir` option, then:

```elixir
test "update refuses a wrong --expect-sha256 before any write", %{tmp_dir: tmp_dir} do
  tmp_tree(tmp_dir)            # copy the real pin + owned dirs under tmp_dir
  args = ["update", "--commit", @new_commit, "--expect-sha256", String.duplicate("0", 64)]
  assert {1, output} = pin(:cli, [args, getter_returning(zip), tmp_dir])
  ...
end
```

The function-level `update`/`extend`/`init` tests already cover the same refusals with `target_dir:
tmp_dir`; dropping the three real-tree variants is also acceptable.

### WR-02: The merge-blocking `verify` proves internal consistency, not provenance, for 10 of 16 shipped assets

**File:** `test/scripts/brand_pin_test.exs:13-16,30-45`; `scripts/brand_pin.exs:358-380`
**Issue:** `verify/3` checks the tree against the hashes recorded in the same pin. The independent,
test-owned anchors are only `@expected_zip_sha256` (the whole zip) and the six woff2 hashes copied
into `glyph_contract_test.exs`. A PR that replaces a lockup SVG, an OFL text or `brand.json` and
edits that one entry's `sha256`/`bytes` in `brand.pin.json` passes `verify`, `brand_pin_test.exs` and
`logo_assets_contract_test.exs` (which only compares `priv/static` to `brandbook/v2`, both editable),
because the zip hash is unchanged and `@expected_shipped` lists paths, not hashes. Only the advisory
online `check` notices (the member no longer equals the pinned zip), after merge. The header's
"commit- and hash-pinned" claim is stronger than the required lane enforces.
**Fix:** Add a test-owned digest of the shipped `{to, sha256}` list, updated in the same
`chore(brand)` commit as the pin, next to `@expected_zip_sha256`:

```elixir
@expected_shipped_digest "<sha256 of the sorted \"to:sha256\\n\" lines>"

test "the shipped hashes are the ones the test owns" do
  lines = real_pin()["shipped"] |> Enum.map(&"#{&1["to"]}:#{&1["sha256"]}") |> Enum.sort()
  assert pin(:sha256_hex, [Enum.join(lines, "\n")]) == @expected_shipped_digest
end
```

### WR-03: `immutable` one-year caching on un-fingerprinted font and logo URLs; `update` rewrites bytes under the same names

**File:** `mailglass_admin/lib/mailglass_admin/controllers/assets.ex:42-45,407,422-428`; `mailglass_admin/assets/css/app.css` (`@font-face` URLs); `scripts/brand_pin.exs:770-786`
**Issue:** `serve/3` sends `cache-control: public, max-age=31536000, immutable` for every route. For
`css-<md5>`, `js-<md5>` and `favicon.svg?v=<md5>` that is correct, because the URL changes with the
bytes. The fonts are referenced as `./fonts/ui-400.woff2` and the logo as `/logo.svg`, with no
fingerprint, and the CSS md5 does not cover them. The moduledoc itself states the consequence ("a
replaced font needs a new file name rather than new bytes under an old one") but nothing enforces
it: `brand_pin.exs update` (`rewrite_pin/5`) keeps each `to` path and swaps the bytes, and the only
gate is the glyph contract's hash table, which forces re-deriving the subset, not renaming. After
such an update a browser that has cached a face keeps the old bytes for a year. The same applies
today to `/logo.svg`: this phase changed its bytes from the v1 sealed flap to the v2 lockup behind an
unchanged, immutable URL, so any external embed that fetched it earlier will not see v2.
**Fix:** Keep `immutable` only for fingerprinted URLs. For the font and logo routes use a revalidating policy, for example:

```elixir
defp serve(conn, body, content_type, cache \\ "public, max-age=31536000, immutable") do
  conn
  |> put_resp_header("content-type", content_type)
  |> put_resp_header("cache-control", cache)
  |> put_resp_header("etag", ~s("#{Base.encode16(:crypto.hash(:sha256, body), case: :lower)}"))
  |> send_resp(200, body)
  |> halt()
end

# fonts and logo: serve(conn, bytes, "font/woff2", "public, max-age=86400, must-revalidate")
```

Alternatively fingerprint the font URLs at bundle time and add a test that fails when a pinned
font's hash changes without its file name changing.

### WR-04: Token parity never checks that the "system" block sits inside `@media (prefers-color-scheme:dark)`

**File:** `mailglass_admin/test/mailglass_admin/token_parity_test.exs:97-101,508-523,688-694` (claim at `:8-18`)
**Issue:** The moduledoc says all three compiled blocks are compared and that the
`@media (prefers-color-scheme:dark)` system block "matters: Phase 180 D-10 relies on it for the
OS-dark default". The test selects the block by its inner selector only
(`:root:not([data-theme=light]):not([data-theme=mailglass-light])`); `rules/1`'s
`([^{}]+)\{([^{}]+)\}` regex deliberately skips the wrapper, so the media query is never inspected.
I confirmed the real bundle has the wrapper (`...@media (prefers-color-scheme:dark){:root:not(...`),
but removing it, or changing it to `light`, would leave the dark values applying to every unthemed
page (or never) and every parity test would stay green. The "teeth" tests mutate values, duplicate
and rename the block, never the wrapper.
**Fix:** Assert the wrapper explicitly and add a tooth for it:

```elixir
defp system_block_wrapped?(css) do
  Regex.match?(
    ~r/@media\s*\(prefers-color-scheme:\s*dark\)\s*\{\s*:root:not\(\[data-theme=light\]\):not\(\[data-theme=mailglass-light\]\)\s*\{/,
    css
  )
end
# in parity_failures/2: add "system block: not inside @media (prefers-color-scheme:dark)" when false
# tooth: String.replace(css, "@media (prefers-color-scheme:dark){:root:not", "@media (prefers-color-scheme:light){:root:not")
```

### WR-05: `tokens.json` claims a parity proof that covers colours and font stacks only

**File:** `brandbook/tokens.json:4`; `mailglass_admin/test/mailglass_admin/token_parity_test.exs:711-715`
**Issue:** `meta.notes` (new this phase) says `token_parity_test.exs` "proves this file equals
tokens.css, the compiled admin bundle and brand.json". The test only reads `--mg-color-*` and
`--mg-logo-*` declarations (`declared_tokens/1`), and `font_assets_contract_test.exs` separately
covers the three font stacks. The `text`, `space`, `radius` and `focus` sections of `tokens.json`
(`--mg-text-*`, `--mg-space-*`, `--mg-radius-*`, `--mg-focus-ring-*` in `tokens.css`) are compared
by nothing: I confirmed they match today, but changing `--mg-space-md` in `tokens.css` alone fails
no test. The equality to `tokens.css` is also only transitive (through the bundle's `@import`).
**Fix:** Either extend `parity_failures/2` to the dimension roles in the `:root` block, or narrow the note.

```elixir
# dimension roles from tokens.json -> "--mg-text-h1" => "36px", compare with the light block's declarations
```

### WR-06: A known WCAG 1.4.3 failure is exempted inside the contrast contract

**File:** `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs:298-303`; `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex:34`; `.planning/phases/181-brand-v2-tokens-fonts-and-logo/deferred-items.md` item 1
**Issue:** daisyUI draws `::placeholder` as the text colour at 50%. I recomputed it with the test's own
composite rule: Espresso at 50% over Sand is `#908780`, **3.13:1** on the page; over White it is
**3.23:1**, both below the 4.5:1 text floor that the same file enforces for every other pair. The
phase builds a "static contrast contract" and then carries a reasoned `::placeholder` exemption for a
rendered control hint ("Subject or recipient"). It is tracked for Phase 182 and was no better under
v1 (about 3.3:1), so this is not a regression, but it is a known accessibility defect shipped with
the contract that claims to rule such things out.
**Fix:** The deferred item already names the fix; it is one rule and removes the exemption:

```css
@layer utilities {
  :where(input, textarea)::placeholder { color: var(--color-secondary); }
}
```

then drop the `"::placeholder"` entry from `@component_alpha_text` (the staleness check will force it).

## Info

### IN-01: The demo storybook foundations page still draws an arrow the brand fonts lack

**File:** `reference/demo_app/storybook/foundations.story.exs:36`
**Issue:** `class&rarr;data-theme` renders U+2192 through a fallback face; the brand fonts have no arrow glyphs
(the reason three arrows in admin `lib` were replaced with icons). Recorded as deferred item 2. The
glyph contract scans `mailglass_admin/lib` only, and HTML entities in a `~H` string are not decoded by
`GlyphScan`, so nothing would catch a new `&rarr;` anywhere.
**Fix:** Write `class to data-theme`, and consider decoding `&name;` entities in `GlyphScan.rendered_strings/2`.

### IN-02: `document.fonts.check` passes when the face was never declared

**File:** `mailglass_admin/e2e/admin-assets.spec.js:295-296`
**Issue:** Per the CSS Font Loading spec, `check()` returns `true` when no face in the set matches the
family. `atkinsonBody`/`funnelHeading` therefore stay truthy if the `@font-face` rules were dropped.
The static `font_assets_contract_test.exs` is the real proof, and the spec only has to be advisory,
but the assertion reads as stronger than it is.
**Fix:** Assert a loaded face: `[...document.fonts].some(f => f.family.replace(/["']/g, "") === "Funnel Display" && f.weight === "600" && f.status === "loaded")`.

### IN-03: `CLAUDE.md` Brand & Voice still states the retired v1 palette and typography

**File:** `CLAUDE.md:68-72`
**Issue:** It lists Ink/Glass/Ice/Mist/Paper/Slate, "Inter / Inter Tight / IBM Plex Mono" and names
`brandbook/brand-book.md` as the source of truth. After this phase the admin ships Sand/Espresso/Deep
Glass, Funnel Display / Atkinson Hyperlegible, and the pinned book lives in `brandbook/v2/`. Agents
following the file would reintroduce v1 values. (`lib/mailglass/config.ex:61` also still defaults a
mono stack to IBM Plex Mono for the core email theme; out of this phase's scope, noted for the owner.)
**Fix:** Update the palette, typography and source-of-truth lines to brand v2.

### IN-04: Byte-pinned text assets have no `.gitattributes` guard

**File:** repo root (no `.gitattributes`); pinned: `brandbook/v2/*.svg`, `brandbook/v2/*.txt`, `brandbook/v2/brand.json`, `mailglass_admin/priv/static/fonts/OFL-*.txt`
**Issue:** `brand_pin_test.exs` (c2) tests that a CRLF rewrite of a pinned text file is detected, but
nothing prevents one: a checkout with `core.autocrlf=true` converts the pinned `.txt`/`.svg`/`.json`
files and `verify` plus the byte-identity tests then fail for a reason unrelated to tampering.
**Fix:** Add `.gitattributes` with `brandbook/v2/** -text`, `mailglass_admin/priv/static/fonts/** -text`, `mailglass_admin/priv/static/*.svg -text`.

### IN-05: `Assets` moduledoc says `extend` adds a new face; it only processes a fixed manifest

**File:** `mailglass_admin/lib/mailglass_admin/controllers/assets.ex:42-45`; `scripts/brand_pin.exs:49-65`
**Issue:** "A new face enters through `scripts/brand_pin.exs extend`" is not accurate: `extend` copies only
the 12 entries hard-coded in `@extension_manifest`. Adding a face means editing that list in the script,
`@font_files` here, the face table and `@expected_*` constants in two test files, and the glyph
contract's hash table; `extend` alone does nothing for a name it does not know.
**Fix:** Reword to list the places that change, or point at a short "adding a face" checklist.

---

_Reviewed: 2026-11-15T19:16:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
