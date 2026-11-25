---
phase: 180-reproducible-admin-bundle-and-before-catalog
reviewed: 2026-11-15T02:41:10Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/dev/mailglass_admin/assets_check.ex
  - mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex
  - mailglass_admin/lib/mix/tasks/mailglass_admin.assets.watch.ex
  - mailglass_admin/mix.exs
  - mailglass_admin/lib/mailglass_admin/admin_shell.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs
  - mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs
  - mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs
  - mailglass_admin/e2e/support/theme.cjs
  - mailglass_admin/e2e/theme-ownership.spec.js
  - reference/demo_app/lib/mailglass_demo/catalog_seed.ex
  - reference/demo_app/assets/catalog/before-catalog.spec.js
  - reference/demo_app/assets/catalog/capture-before-catalog.cjs
  - reference/demo_app/assets/playwright.catalog.config.cjs
  - mailglass_admin/.gitattributes
  - mailglass_admin/.gitignore
findings:
  critical: 0
  warning: 5
  info: 9
  total: 14
  necessity: 0
status: issues_found
---

# Phase 180: Code Review Report

**Reviewed:** 2026-11-15T02:41:10Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Reviewed the reproducible-bundle gate (`AssetsCheck`, the `--check` task mode, the `mix.exs` alias wiring), the root-only theme ownership change (shell, tabs, gallery) and its three proof layers (ExUnit contract test, Playwright matrix, support helper), and the before-catalog pipeline (seed, capture spec, driver, manifest validator).

I did not stop at reading. I ran, against the checkout at `2b49c2fa`:

- `MIX_ENV=test mix mailglass_admin.assets.build --check` passes (136877 bytes).
- `bundle_reproducibility_contract_test.exs` + `before_catalog_manifest_test.exs`: 74 tests, 0 failures. The committed catalog reports LIVE.
- `root_theme_ownership_contract_test.exs`: 22 tests, 0 failures.
- Full admin suite `mix test --warnings-as-errors --seed 0`: 1389 tests, 0 failures.
- `e2e/theme-ownership.spec.js`: 37 passed. The `@smoke180` subset across all browser specs: 19 passed.
- `mix format --check-formatted` on the touched Elixir files: clean. `scripts/check_test_exceptions.sh`: OK.

The bundle drift gate itself is sound. I tried to find a false-green path (Tailwind failure becoming a pass, a stale or wrong-version binary, an output written inside `priv/static/`, an empty or truncated committed file, args divergence from the real build) and could not. Its fail-closed claims hold, and the "teeth" tests are real mutations.

No blockers. The weaknesses are all in the evidence layers built around the gate:

- The before-catalog validator can be satisfied by a partial catalog, and it is not enforced for the one kind of change (a `.planning`-only edit) that would tamper with it.
- The root-theme static scan has blind spots its own moduledoc says it covers.
- The Preview frame toggle became a silent no-op on the Text tab.
- The hashed text files are not LF-pinned.

Necessity (category 4) was assessed using `necessity-review.md`; I have no necessity findings. The one guard I looked at closely (the `build_args/2` no-`--output=` fallback) is unreachable code, so it is reported as dead code (IN-03), not as necessity.

## Warnings

### WR-01: `--only` capture runs are promoted into the committed catalog, and the validator has no completeness rule

**File:** `reference/demo_app/assets/catalog/capture-before-catalog.cjs:553-560` (also `:328-333`, `:77-89`) and `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs:131-137`, `:739-777`
**Issue:** `parseArgs` accepts `--only <ids|smoke>` and defaults `promote: true`. `validate` skips the tier A-E coverage check when `--only` is set (`full: !options.only`), but nothing stops the run reaching `fs.renameSync(staging, finalDir)` at line 559. So `node capture-before-catalog.cjs --only smoke` writes a 6-shot catalog (see `CATALOG_SMOKE_IDS`) under `.planning/research/brand-v2-adoption/before-catalog/before-<sha7>-<ts>/`. That directory is indistinguishable from a full catalog. The manifest has no `partial` field, and the manifest test only requires `manifest["captures"]` to be a non-empty list (`capture_shape_failures/1`, `:739`; the live test at `:133`). `cases.json` always lists all ten cases, so the case check also passes. A partial catalog therefore validates green in the required lane, and Phases 182-183 would cite it as "the before catalog". The directory is documented as immutable, so the recovery path is a second catalog, not an edit.
**Fix:** Make `--only` imply `--no-promote` in the driver, and enforce completeness in the validator so the invariant does not rest on operator discipline.
```js
// capture-before-catalog.cjs, parseArgs tail
if (options.only) options.promote = false; // a partial run is a smoke check, never a catalog
```
```elixir
# before_catalog_manifest_test.exs, in shape_failures/2
check(
  captures |> Enum.map(& &1["tier"]) |> Enum.uniq() |> Enum.sort() == ~w(A B C D E),
  "a catalog must hold captures for every tier A-E (a partial --only run is not a catalog)"
) ++
check(
  Enum.all?(@case_slugs, fn slug ->
    Enum.any?(captures, &(&1["case"] == slug))
  end),
  "every delivery case in cases.json needs at least one capture"
)
```

### WR-02: The "immutable evidence" validator does not run for `.planning`-only changes, and the catalog is not registered as append-only

**File:** `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs:6-9, 125-143`; `.github/workflows/ci.yml:25-47` (the `changes` gate); `.github/scheduled-controls.json` (`append_only_evidence_paths` has 1 entry, none under `brand-v2-adoption`)
**Issue:** The test is the only thing that makes the catalog more than an unverified claim (its own moduledoc says so), and it lives in `support_contract_admin`. The `changes` job classifies any PR whose files are all under `.planning/` as docs-only (`code=false`), and `support_contract_admin` has `if: needs.changes.outputs.code == 'true'`. `scripts/ci_green_policy.sh` accepts skipped lanes when `code=false`. A PR that edits a PNG, rewrites `manifest.json`/`cases.json`, adds a stray file, or deletes a capture under `.planning/research/brand-v2-adoption/before-catalog/` therefore skips the validator and merges. The moduledoc acknowledges the skip but only uses it to justify landing the test in the same PR as the catalog. It does not close the hole afterwards. `scripts/check_append_only_evidence.sh` (which runs in `changes` and does cover `.planning/`) would catch this, but only for paths listed in `scheduled-controls.json`.
**Fix:** Register the catalog tree as retained append-only evidence so edits and deletions fail in the `changes` job, which does run for docs-only PRs.
```jsonc
// .github/scheduled-controls.json
"append_only_evidence_paths": [
  /* existing entry */,
  ".planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/manifest.json",
  ".planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/cases.json"
  // plus the 80 PNG + 80 aria paths, generated by the driver on promote
]
```
Alternatively, make the `changes` filter treat `.planning/research/**/before-catalog/` as code. Either way, update the moduledoc so it does not imply the lane always runs.

### WR-03: The Preview frame toggle is now a silent no-op on the Text tab, and its state marker has no consumer

**File:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:63-65, 185-188`; `mailglass_admin/lib/mailglass_admin/preview_live.ex:505-547`
**Issue:** Before this phase the tab panel carried `data-theme` for both `:html` and `:text`, so toggling "Preview background: Dark" repainted the Text tab. The change removed `data-theme` and moved the effect to a `color-scheme`/`Canvas` wrapper that exists only in the `:html` branch of `tab_content/1` (`tabs.ex:107-121`). `preview_frame_theme_attr/2` still returns `"dark"`/`"light"` for `:text` (`when tab in [:html, :text]`), but no CSS selects `data-preview-frame-theme` (0 hits in `assets/css/app.css` and in the committed `priv/static/app.css`). The Text pane is a `<pre class="bg-base-200 ...">` that now ignores the toggle. Meanwhile the control stays enabled on every tab, and the `aria-live` status region announces "Preview backdrop: dark" even though nothing changed on screen. That is a regression for the Text tab and an announcement with no visible effect.
**Fix:** Either wrap the text tab in the same backdrop so the control keeps its documented meaning, or restrict the attribute and the control to the tab that honors them.
```elixir
# tabs.ex: only the :html tab has a backdrop to flip
defp preview_frame_theme_attr(:html, dark_chrome),
  do: if(dark_chrome, do: "dark", else: "light")

defp preview_frame_theme_attr(_tab, _dark_chrome), do: nil
```
and in `preview_live.ex` render the toggle (or `disabled` plus an explanatory `aria-describedby`) only when `@active_tab == :html`. Add an ExUnit assertion for the Text tab so the behavior is pinned.

### WR-04: LF line endings are pinned for the bundle inputs but not for the text files whose bytes the catalog validator hashes

**File:** `mailglass_admin/.gitattributes:9-13`; `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs:788-799, 880-890, 1259-1263`
**Issue:** The file header rewritten in this phase says the attributes exist so the byte-for-byte gate does not false-positive on CRLF drift from a Windows maintainer. The new catalog validator has the same exposure and no protection. It sha256-hashes `cases.json` and every `aria/*.yml`, and it git-blob-hashes `lib/mailglass_admin/layouts/root.html.heex` from working-tree bytes. None of those paths has an `eol=lf` attribute (`git ls-files --eol` shows `attr/` empty for all three, and there is no repo-root `.gitattributes`). With Git for Windows' default `core.autocrlf=true`, the checkout rewrites them to CRLF, so the catalog goes red on cases/aria sha mismatches and flips to "SUPERSEDED, no marker" on the root layout blob. CI is Linux and unaffected, so this only bites Windows contributors, but it is exactly the failure class the header says it prevents.
**Fix:** Pin LF for the hashed text files.
```gitattributes
# mailglass_admin/.gitattributes
lib/mailglass_admin/layouts/root.html.heex text eol=lf
```
```gitattributes
# repo-root .gitattributes (new)
.planning/research/brand-v2-adoption/before-catalog/**/*.json text eol=lf
.planning/research/brand-v2-adoption/before-catalog/**/*.yml  text eol=lf
.planning/research/brand-v2-adoption/before-catalog/**/*.png  binary
```

### WR-05: The static theme-ownership scan has blind spots its moduledoc and teeth do not admit, plus one false positive

**File:** `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs:150-164, 229-238, 285-291`
**Issue:**
1. **JS is out of scope, but the teeth claim otherwise.** `lib_sources/0` globs `lib/**/*.{ex,heex}`. The admin's behavior bundle is `priv/static/hooks.js`, which the root layout inlines into every document. A hook that does `el.dataset.theme = "dark"` or `el.setAttribute("data-theme", ...)` is invisible to the required-lane scan, and the dead-render document counts cannot see runtime mutation. The teeth test at `:150-164` proves those JS spellings are flagged "in any file", but only when fed as a string. The first line of defense for a JS-set nested owner is the advisory Playwright lane. `hooks.js` is clean today (I grepped it), so this is a coverage hole, not a live defect.
2. **A token re-declaration through the DOM API passes.** `token_declaration/0` is `~r/--(?:mg|color)-[a-z0-9-]+\s*:/`, which needs a colon after the name. `el.style.setProperty("--color-base-100", "#000")` and `el.style["--mg-color-background"] = ...` have none, so they are not flagged. The clean-control list even blesses `setProperty("--mg-tooltip-arrow-x", ...)`, so the rule cannot simply be widened without an allow-list.
3. **A read is flagged as a write.** `~r/dataset\.theme\s*=/` also matches `dataset.theme === "dark"` (the first `=` of `===`). A legitimate read in any future `lib/` string will fail the lane with a misleading "sets the theme attribute" message.
**Fix:** Include the shipped JS in the scan and tighten the patterns.
```elixir
defp lib_sources do
  [@lib_dir |> Path.join("**/*.{ex,heex}"), Path.expand("../../priv/static/*.js", __DIR__)]
  |> Enum.flat_map(&Path.wildcard/1)
  |> Enum.sort()
  |> Enum.map(&{Path.relative_to(&1, Path.expand("..", @lib_dir)), File.read!(&1)})
end

# a write, not a comparison
~r/dataset\.theme\s*=(?!=)/
# an inline token assignment through the DOM API, minus the one allowed tooltip variable
~r/setProperty\(\s*["']--(?:mg|color)-(?!tooltip-arrow-)/
```
Add planted-violation and clean-control cases for each new pattern so the teeth stay honest.

## Info

### IN-01: `--check` prints the size of a cwd-relative path, while the compare uses the Tailwind profile's `:cd`

**File:** `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex:82-84`
**Issue:** `AssetsCheck.run_check!/1` resolves the committed bundle via `profile[:cd]` (`assets_check.ex:62-63`), but the task then calls `File.stat!("priv/static/app.css")` relative to the process cwd. Run from any directory other than the package root (for example `mix cmd --cd`), the gate passes and the task then crashes with `File.Error`. It fails closed, so this is not a false green, but the message is misleading and the two paths can diverge.
**Fix:** Reuse one path. Have `run_check!/1` return `{:ok, %{bytes: size}}` (or expose `committed_path/1`) and print from that, instead of re-deriving the path in the task.

### IN-02: `AssetsCheck` re-implements parts of `Tailwind.run/2` and can drift from the real build

**File:** `mailglass_admin/dev/mailglass_admin/assets_check.ex:77-83`
**Issue:** The real build goes through `Tailwind.run/2`, which merges the profile's `:env`, normalizes the Windows drive letter on `:cd`, and appends `extra_args` (`deps/tailwind/lib/tailwind.ex`, `run/2`). The check hard-codes `env: %{"BROWSERSLIST_IGNORE_OLD_DATA" => "1"}` and uses `cd` verbatim, so if the `:default` profile ever gains an `:env` key (a plausible Tailwind tuning knob), the check and the build would produce different bytes and the gate would go red with no code change to blame.
**Fix:** Merge the profile env (`Map.merge(Map.new(profile[:env] || %{}), %{"BROWSERSLIST_IGNORE_OLD_DATA" => "1"})`) and add a one-line comment that any new profile key must be mirrored here, or add a test that asserts the profile has no keys other than `:args` and `:cd`.

### IN-03: `build_args/2` carries a branch for a profile with no `--output=` that cannot occur

**File:** `mailglass_admin/dev/mailglass_admin/assets_check.ex:132-140`
**Issue:** The `replaced?` false branch (`args ++ ["--output=" <> tmp, "--minify"]`) is unreachable. The sole `:default` profile (`mailglass_admin/config/config.exs:7-12`) always carries `--output=priv/static/app.css`, `check/1` accepts no profile override (its options are `:cd`, `:committed`, `:bin_path`, `:installer`), and no test exercises the branch. It is dead code, not a necessity finding, because it never runs.
**Fix:** Delete the fallback, or make it raise so a missing output flag is loud instead of silently building to a different layout.
```elixir
defp build_args(profile_args, tmp) do
  unless Enum.any?(profile_args, &String.starts_with?(&1, "--output=")),
    do: raise(ArgumentError, "the :default Tailwind profile must set --output=")

  Enum.map(profile_args, fn
    "--output=" <> _ -> "--output=" <> tmp
    arg -> arg
  end) ++ ["--minify"]
end
```

### IN-04: `@source not inline("prose")` silently disables a real `prose` utility for the whole package

**File:** `mailglass_admin/assets/css/app.css:15`
**Issue:** The exclusion fixes the scanner picking up the English word in `copy.ex` gloss text, and it does not affect `max-w-prose` (the bundle still contains `max-w-prose{max-width:65ch}`). But any future `class="prose"` in HEEx now compiles to no CSS with no error, and nothing in the lane would notice. The contract test proves the exclusion is load-bearing, but not that `prose` stays unused.
**Fix:** Add a test line to `root_theme_ownership_contract_test.exs` or `bundle_reproducibility_contract_test.exs` that fails if `lib/` contains `class="...\bprose\b..."`, and put that reason in the `app.css` comment. Optionally reword the `copy.ex` gloss ("screen text and docs prose only") so the exclusion can be dropped.

### IN-05: Stale gate description in `CLAUDE.md`

**File:** `CLAUDE.md:138` ("Things Not To Do" item 6)
**Issue:** It still says "CI runs `git diff --exit-code`" for `mailglass_admin/priv/static/`. This phase replaced that gate with `mix mailglass_admin.assets.build --check` (and the `mix.exs` comment notes the old gate never ran in a required lane). `prompts/mailglass-engineering-dna-from-prior-libs.md:477,678,701` carry the same claim.
**Fix:** Update item 6 to "...(the required `support_contract_admin` lane runs `mix mailglass_admin.assets.build --check`)".

### IN-06: Credo cyclomatic complexity 18 (max 17) in the new manifest test

**File:** `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs:1143` (`seeded_case_failures/1`)
**Issue:** `mix credo --strict` reports one refactoring finding here. CI's `credo_strict` job runs from the repo root, and the admin package already has other credo findings (for example `operator_live.ex:1666`), so this does not fail CI today. It would fail the admin-local `ci.fast` alias.
**Fix:** Split the three `check(...)` groups for `typo-bounce`, `send-failed` and `manual-suppressed` into small helpers, each taking `cases[slug] || %{}`.

### IN-07: E2E theme helpers are duplicated, and the shared module exports dead code

**File:** `mailglass_admin/e2e/support/theme.cjs:20-26, 53`; `mailglass_admin/e2e/theme-ownership.spec.js:42, 128`; `mailglass_admin/e2e/flows.spec.js:254-269`; `mailglass_admin/e2e/phase168-plan03-acceptance.spec.js:20-29`
**Issue:**
- `applyThemeEmulation` is exported from `theme.cjs` and imported nowhere. `structural.spec.js` keeps its own copy.
- `theme-ownership.spec.js` redeclares `THEME_COOKIE_NAME` although `theme.cjs` exports `THEME_COOKIE`.
- Three near-identical "root owns the theme" assertions now exist (`expectRootOwnsTheme`, and two copies of `expectRootTheme`).

**Fix:** Move `expectRootTheme` into `support/theme.cjs`, import `THEME_COOKIE`, and drop the unused export.

### IN-08: Two catalog provenance fields claim more than they check

**File:** `reference/demo_app/assets/catalog/before-catalog.spec.js:58, 425-446`; `capture-before-catalog.cjs:361-363, 439, 505`
**Issue:**
- `determinism.double_capture_identical: true` reads as a statement about the whole catalog, but only `preview-index__any__default__1440__light` is captured twice, and the manifest does not record which screen it was. That screen is a dev-preview page with no seeded data, so it is the weakest probe of the operator screens where volatility would show.
- `validate` compares `served.revision` to `source.git_sha`, but the driver passes `DEMO_CANDIDATE_REVISION: source.git_sha` into the spec (`:505`), which reports that same value back. The check cannot fail. The real protection is the served-bytes-versus-git-blob comparison, which does work.

**Fix:** Record `self_test_id` in `manifest.determinism` (rename the field or document the scope), and either drop the tautological revision check or have the spec resolve `git rev-parse HEAD` independently of the env var.

### IN-09: The seeded-metadata stop-line guard only matches quoted keys

**File:** `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs:1108`
**Issue:** `~r/"(reason|cause|retry_at|next_retry_at)"/` over `catalog_seed.ex` catches `%{"reason" => ...}` but not the atom-key spelling `%{reason: ...}`, which Ecto stores identically. The committed `cases.json` is immutable and is not recomputed, so after the capture this regex is the only live guard on the seed source.
**Fix:** Also match `\b(reason|cause|retry_at|next_retry_at):\s` (and add a planted case to the "planted metadata keys" teeth test).

---

_Reviewed: 2026-11-15T02:41:10Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
