# Phase 180: Reproducible Admin Bundle and Before-Catalog - Research

**Researched:** 2026-11-14 (source HEAD `4b05992f`, tree clean at start and at finish)
**Domain:** Elixir/Mix asset pipeline (standalone Tailwind 4.1.12 + vendored daisyUI 5.5.19), Phoenix LiveView root-layout theming, Playwright evidence capture on the Docker demo
**Confidence:** HIGH for BRPIPE-01 and BRPIPE-02 mechanics (every load-bearing claim below was run, not reasoned). MEDIUM for BRPIPE-03 (capture path proven on a 3-test subset; the full matrix, the 80-image/15 MB budget and the catalog-only seed were not executed).

Provenance tags used below: `[VERIFIED: run]` = a command or script I executed this session, output quoted; `[VERIFIED: path:lines]` = I opened that file this session, value quoted verbatim; `[CITED: url]` = official docs fetched this session; `[ASSUMED]` = not verified here (all collected in the Assumptions Log).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Reproducible generator and drift gate (BRPIPE-01)
- **D-01:** The only generated artifact is `mailglass_admin/priv/static/app.css`. `hooks.js`, `heroicons-inline.js`, `favicon.svg`, `mailglass-logo.svg` and `fonts/` are hand-authored committed sources with no generator (the admin has no esbuild). They stay out of `--check`. No new assembly script is written: the "uncommitted assembly script" premise in `LENS-FINDINGS.md` section B and the "raw-inline theme blocks" token-parity landmine memory are both stale and do not reproduce on current `main` (measured by two agents). The ROADMAP time-box fallback is not needed.
- **D-02:** Extend the existing `mix mailglass_admin.assets.build` (`mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex`) with `--check`. It builds with the pinned Tailwind (`4.1.12`, `mailglass_admin/config/config.exs`) and `--minify` to a **temp output** with the same input and `cwd` as the real build, then compares bytes to `priv/static/app.css`. On mismatch it `Mix.raise`s with both sizes, the first differing offset, and "run `mix mailglass_admin.assets.build` and commit". A missing or truncated committed file also fails. The task stays in `lib/mix/tasks`: it is an existing, documented (`mailglass_admin/docs/design-system.md:19`), allowlisted surface (`.planning/publish/mailglass_admin-files.expected:76`), so moving it would change the Hex tarball and the publish expectations for no adopter benefit. The planner may place the compare logic in a non-shipped module under `mailglass_admin/dev/` and have the task call it only if that keeps the publish lane green; otherwise keep it in the task. Do not use a committed hash manifest (it only proves nobody hand-edited the file).
- **D-03:** **The gate is already red at HEAD and this phase must resolve that first.** Phase 179's `mailglass_admin/lib/mailglass_admin/copy.ex` (gloss text, ~lines 85-106) contains the bare word "prose". Tailwind scans `lib/` as plain text, so a fresh build is 139,137 bytes against the committed 136,877 (18 extra daisyUI `.prose` rules). Fix with `@source not inline("prose");` in `mailglass_admin/assets/css/app.css` (tested by one agent; the analyzer proposed `@source not "../../lib/mailglass_admin/copy.ex"` instead). **Pick the inline form**: it covers any future file and leaves `priv/static` unchanged, so the first regeneration is churn-free. The plan must regenerate with the fix and assert the result is byte-identical to the committed file. Planner verifies the directive syntax against Tailwind 4.1.12 before relying on it.
- **D-04:** **Enforcement lane: the already-required `support_contract_admin` job, no new CI job.** Two coupled pieces, because an alias alone can be skipped and a test alone is not the `--check` mode the requirement names:
  1. Add `mailglass_admin.assets.build --check` as the first step of the `verify.support_contract.admin` alias (`mailglass_admin/mix.exs` ~213), which `ci.yml` (~946) already runs and `ci_green` already needs (`config/quality/ci_policy.exs` `active_required`).
  2. A new ExUnit contract test runs the same compare (in the `phase175_prohibition_contract_test.exs` style) so `mix test` inside that lane cannot pass with a drifted bundle either.
  A new required job would need about six registration surfaces (`ci_policy.exs`, `test/support/ci_lanes.ex`, `ci_green.needs`, `scripts/ci_green_policy.sh`, `publish-hex.yml` `REQUIRED_LANES`, `scripts/setup_branch_protection.sh`, live branch protection) and is rejected. Do **not** cite `operator_browser_gate` (advisory, `ci_policy.exs:145`) as proof: it rebuilds `app.css` on the runner and proves nothing about committed bytes.
- **D-05:** **Fix the false claims.** `verify.preview` has a `git diff --exit-code priv/static/` step that no workflow runs, and the `mailglass_admin/mix.exs` comment, the task `@moduledoc` and CLAUDE.md "CI runs `git diff --exit-code`" all say CI diffs the bundle. Re-point `verify.preview` at `--check`, correct the comment and moduledoc, and leave the CLAUDE.md line to the Phase 183 docs pass (record it as a follow-up; CLAUDE.md edits need owner sign-off per the milestone).
- **D-06:** **Proof tests (mutation protocol, METHODOLOGY).** New file `mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs` (new file: `config/test_exceptions.exs` is `file:line` keyed, so no `@tag :skip` and no edits above registered lines). Required cases:
  - Positive: the real check passes against the committed bundle.
  - Teeth, hermetic in a tmpdir: a one-byte flip, a truncated copy and a deleted copy each make the check fail and name the fix command.
  - Source-side teeth: a tmp copy of `app.css` source with an appended rule, built and compared to the committed bundle, reports drift. A utility-like token added to a `lib/` string also reddens the check (the ambient scan-input footgun).
  - Wiring: a static assertion that `ci.yml` runs `verify.support_contract.admin`, the alias has no file allow-list and contains the `--check` step, and `ci_green` needs the job. This is the "lane that never runs" footgun; it already happened once with `verify.preview`.
  - Fail closed: if the Tailwind binary cannot be fetched in CI the lane fails, never skips. No rescue of the download error into a pass.
  - Optional evidence: one throwaway draft PR with a drifted bundle showing `CI Green` red, never merged.
- **D-07:** **Cross-platform byte equality is unproven for the CI runner.** Two builds at different absolute paths and macOS-arm64 against Linux-arm64 (Docker) were byte-identical; Linux x64 (`ubuntu-latest`) was not testable locally. The first plan task is a throwaway ubuntu CI dry run of `--check` against the committed bundle. If bytes differ, the plan pins the check to the CI platform and records why. If you cache `_build/tailwind-*`, key it by Tailwind version and never cache the output. Also confirm whether a trailing `--output` overrides the config `--output` in `mix tailwind default ...` (analyzer flagged this unverified) before building the temp-output path on it.
- **D-08:** Real inputs the check depends on, to be listed in the task `@moduledoc`: `assets/css/app.css`, `assets/vendor/*.js` (vendored daisyUI 5.5.19), `lib/**` (scanner), `brandbook/tokens.css` (outside the package dir; Phase 181 edits it, and `changes` in `ci.yml` counts any path outside `.planning/` and `prompts/` as code, so a token edit triggers the lane), and the Tailwind binary version.
- **D-09:** Commit kinds (Phase 179 D-26 still applies): `mailglass_admin/lib` and `priv/static` changes are `fix(admin):` or `refactor(admin):` in their own commits; `ci.yml`, scripts and `app.css` source are `ci:`/`chore:` in separate commits (verify with Guard Release Trigger which kind an `assets/` edit is); `.planning` is `docs:`. One open PR at a time. Run `mix format --check-formatted` inside `mailglass_admin` locally (the CI format gate is root-only).

### `<html>` owns the theme (BRPIPE-02)
- **D-10:** **Architecture A: server-rendered `<html data-theme>` from the cookie, attribute absent for system, no client JS.** This is the current design: `MailglassAdmin.Layouts` is the router's `root_layout`, `root.html.heex:2` renders `data-theme` from `Layouts.root_theme/1`, theme changes are a full round trip (`operator_live.ex:274-279` redirects to `/theme/<segment>`, `router.ex:353`, `ThemeController` sets the cookie), and `Theme.data_theme(:system)` is `nil` so the daisyUI `@media (prefers-color-scheme: dark){:root:not([data-theme])}` rule applies. The admin owns its own `<html>`, never a host's, so the mounted-dashboard ownership problem does not exist. The Phoenix 1.8 JS-toggle pattern (inline script, localStorage, matchMedia) is rejected: it needs a CSP nonce for adopters, duplicates the cookie as a second source of truth and adds a transition-kill guard. Revisit only if round-trip toggling becomes a UX complaint.
- **D-11:** **Delete every nested `data-theme`.** Success criterion 3 says only `<html>` carries it, so all of these go (the analyzer proposed keeping the Preview and Gallery ones as "intentional scopes"; research refutes that because any nested `[data-theme]` re-declares the whole `--color-*` and `--mg-*` token set and repaints its own background, which is the defect):
  - `mailglass_admin/lib/mailglass_admin/admin_shell.ex:33` (`data-theme={@theme_attr}`), its `theme_attr` attr and both callers (`operator/shell.ex:198`, `preview_live.ex:318,740`). Keep `Theme.data_theme/1` for the root.
  - `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:66` (`preview_frame_data_theme_attr`) and its helper. The html/text panels forced `mailglass-light` whenever `preview_frame_dark_chrome` was false, including under admin dark or system-dark: that is the demonstrated shadowing.
  - `mailglass_admin/lib/mailglass_admin/gallery_live.ex:138,148` (explicit light and dark specimen columns).
- **D-12:** **Replacements, with no token re-declaration anywhere.**
  - Preview frame light/dark toggle: the email body already renders in an `<iframe srcdoc>` (`tabs.ex:106`), a separate document that custom properties never cross, so admin themes cannot leak in. Express the toggle as the CSS `color-scheme` property on the iframe element, never as `data-theme`, and do not swap tokens on the surrounding panel. The text, headers and raw-envelope tabs follow the admin theme. Keep `data-preview-frame-theme` only if an existing test or style needs it as a state marker; it must not select token sets.
  - Gallery: render one specimen per state in the current theme. The light/dark matrix moves to `e2e/gallery-matrix.spec.js` looping the modes. The theme-specimen test pins that exist must be reworked, not deleted without a replacement.
  - **A class that re-declares `--mg-*`/`--color-*` is the same bug under a new name.** Re-declaring only one of the two layers also desyncs, because `var()` in a custom property resolves where it is declared. A contract test (D-13) rejects both forms.
- **D-13:** **Two-layer proof, per the shift-left policy (the Playwright lane alone is advisory):**
  - Required lane, new file: a static contract test greps `mailglass_admin/lib/**/*.{ex,heex}` for `data-theme=`, allowing only `layouts/root.html.heex` (mutation-proven: plant a nested attribute and a token-redeclaring class, expect red), plus a LiveViewTest/render assertion over the operator, inbound and preview shells for light, dark and system that exactly one `data-theme` source exists. `admin_shell_test.exs:38` asserts `data-theme="mailglass-dark"` on the shell and must be reworked into the root-only assertion. Write the failing reproduction first and show it red on current code (the analyzer's "if wrong" requires this because `Phoenix.LiveViewTest` does not render the root layout).
  - Browser, new spec in `mailglass_admin/e2e/` (new file; reuse `applyThemeEmulation` from `e2e/structural.spec.js` and the `OperatorBrowserServer`): matrix of cookie {light, dark, absent} × `page.emulateMedia({colorScheme})` {light, dark} × {preview index, preview show with the pane, operator list and detail, gallery, one open modal}. Assert: `[...document.querySelectorAll('[data-theme]')]` equals `[documentElement]` for explicit modes and `[]` for system; `getComputedStyle(el).getPropertyValue('--color-base-100')` and `colorScheme` equal html's for `admin-shell`, `preview-pane`, `#mg-copy-toast` (it lives in the root layout outside `.mg-admin-root`, so a nested-only theme could never reach it) and the modal; luminance sanity (base-100 above 0.8 in light, below 0.2 in dark, compared against html's value, not hex literals). Drive the real picker light → dark → system and re-assert after a `push_patch` (select a scenario) and after the frame light/dark control. No-flash: with `javaScriptEnabled:false` the first response already carries the right attribute. iframe: its document has no `[data-theme]` and `--color-base-100` is empty inside it; assert isolation only, not canvas colour (Chrome and Firefox propagate `color-scheme` into the iframe's `prefers-color-scheme`, Safari does not, and the spec is under revision). Forced colors: with `forcedColors:'active'`, focused controls keep a non-`none` outline.
  - State the lane for each requirement. The Playwright spec runs in the advisory `operator_browser_gate`; do not claim it as the required proof. Existing `e2e/admin-assets.spec.js:299` already asserts `html[data-theme]` and must stay green.
- **D-14:** Known footguns to cover or note, not to over-engineer: bfcache can restore the old theme on back-navigation (add a `pageshow` reload when `persisted`, or `no-store`, only if a test shows it); `<dialog>`/popover top-layer children inherit from `<html>` but `::backdrop` inheritance is Chrome 122+, Firefox 120+, Safari 17.4+; elements JS appends to `<body>` inherit from `<html>`; do not set `forced-color-adjust:none`; keep focus rings as `outline`, not box-shadow; keep `.mg-admin-root` as a class because its `*:not(:hover)…{transition-property:transform,opacity}` rule makes theme swaps instant.
- **D-15:** The nested-light "defect" is demonstrated for the Preview html/text panels under admin dark or system-dark. A visible shell-versus-`<html>` disagreement was not found in the current render paths, so removing `admin_shell.ex:33` is a latent-defect fix. The plan summary must say which one each removal is, and must not claim a visible regression was fixed where none was reproduced.

### Before-catalog (BRPIPE-03)
- **D-16:** **Capture runs on the demo app, extending its existing Playwright spec family**, because the three personas and the screen routes already live there. `reference/demo_app/assets/e2e/persona-screenshots.spec.js` already reaches overview, deliveries, inbound, `/dev/mail`, `/dev/mail/gallery` and `/dev/storybook` for `northstar`, `fjordline-aps` and `helios-void` at 375/1440 and light/dark/system, using `POST /demo/evidence/reset`, `/demo/login` and `?tenant_id=<persona>`. The new capture spec reuses that routing but writes to a tracked path (D-17); the existing spec writes to a git-ignored `.cache/`. Run on the Docker demo (`make demo`, `make demo-e2e`); a committed re-runnable script, not a one-off. A capture script under `mailglass_admin/scripts/` (already excluded from the admin release) is the fallback if the demo harness cannot give the guarantees in D-19.
- **D-17:** **Storage: committed PNGs plus `manifest.json` at `.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/`**, not the phase directory. Reason: milestone archive MOVES `.planning/phases/NNN-*` and broke 58 path-coupled tests (v2.7); `research/` is stable, and Phases 182 and 183 cite `catalog_id` plus the manifest sha256. `.planning/` is outside every Hex `files:` list, in release-please `exclude-paths`, and `ci.yml` treats it as docs-only, so committed PNGs cause no package, release or heavy-lane effect. Precedent: about 250 tracked PNGs under `.planning/milestones/v2.10-phases/*/artifacts/`. Rejected: CI artifacts (retention expires before Phase 183), Git LFS (overkill below about 100 MB; clones without LFS get pointers), orphan branch (invisible to worktree-coupled tools), hosted visual-diff vendors (a token swap changes every pixel, so a diff flow is meaningless; also an account and a secret). Verify the path is not gitignored (the `.planning/research/**/.cache/` and `.planning/ui-reviews/` ignores must not catch it) and that `gsd-sdk commit` sweeping of dirty `.planning/` paths cannot commit a half-written capture: **stage into an ignored `.cache/` dir, validate, then promote** with a move that refuses to overwrite an existing `catalog_id`.
- **D-18:** **Unique path and identity.** `catalog_id = before-<sha7>-<UTCstamp>`; filenames are slugs `<screen>__<fixture-or-case>__<state>__<w>__<theme>.png`; per-file sha256 in the manifest. These are **evidence only, not a pixel-diff baseline** (root `.gitignore` already says screenshots are evidence-only attachments). Phase 182's reviewer judges semantically against the book and the catalog. Format: PNG at 1x CSS scale (`deviceScaleFactor 1`); not JPEG (lossy) and no WebP (a converter would be a new dependency).
- **D-19:** **Determinism, with the cheap check for each footgun:**
  - Dirty tree makes the SHA lie: refuse to run if `git status --porcelain --untracked-files=all` is non-empty (excluding the staging dir); record `git rev-parse HEAD`.
  - Stale server or post-rebuild bundle: fetch `app.css` and `hooks.js` over HTTP from the running server, hash the response bytes, and require equality with disk and with `git show <sha>:mailglass_admin/priv/static/app.css`. Record `server_started_at`.
  - Flaky pixels: capture one self-test shot twice and require identical PNG sha256; fail if DOM text matches `/\bago\b|just now/` (relative time). Seed fixtures at fixed absolute timestamps (LiveView renders server-side, so `page.clock.setFixedTime` only fakes browser `Date`); set `timezoneId:"UTC"` and `locale:"en-US"`.
  - Motion: `animations:"disabled"` plus `reducedMotion:"reduce"` (repo specs already use it) and the default `caret:"hide"`.
  - Fonts: assert `document.fonts.check("400 16px Inter")` and record the loaded faces (the admin CSS uses `font-display: swap`, so `document.fonts.ready` alone is not enough).
  - LiveView: wait for `.phx-connected` before each shot; never `networkidle`.
  - Theme: set the app's theme mechanism (cookie, per D-10) plus `emulateMedia`; record the resolved `<html data-theme>` per capture.
  - A manifest cannot contain the SHA of the commit that adds it: it records the source SHA, and the phase summary records the commit that added the catalog.
- **D-20:** **Capture timing: last in Phase 180, on a clean tree at the final source commit, after BRPIPE-01 and BRPIPE-02 land.** Both researchers disagreed (capture first and record the nested-attribute defect, versus capture last); decided here. The baseline the token swap is judged against should be the reproducible, gate-green bundle, and the data-theme fix touches no token. No token, font or logo change may precede the capture; the manifest records `nested_theme_attr_count` (expected 0) so the baseline is honest about which side of the BRPIPE-02 fix it sits on. The plan summary states that the "before" includes the BRPIPE-02 fix.
- **D-21:** **Bounded matrix, hard budget.** The two agents estimated 4-5 MB (about 40 shots) and about 30 MB (about 120 shots). `.git` is about 111 MB and PNGs do not delta-compress, so every recapture is permanent history. **Decision: fail the script past 80 images or 15 MB** (measured average about 266 KB per full-page PNG, so expect fewer than 56 full-page shots at the high end; reduce by cropping or by dropping Northstar/Helios extras first). Matrix: Fjordline (the stress fixture) × each screen × {375, 1440} × {light, dark}; Northstar and Helios on list and empty-state screens only (1440 light plus 375 dark); delivery cases on the timeline/detail screen at 375 × {light, dark} plus 1440 light. Add 768 only for a short list of screens whose layout changes at that breakpoint. The plan fixes the exact screen list and the shot count; if the budget forces a cut, cut fixtures before cutting the dark theme.
- **D-22:** **Delivery cases come from a catalog-only seed**, not from edits to `MailglassDemo.DemoData` or `reference/persona_spec/personas.ex` (the latter is guarded by `persona_drift_guard_test.exs` and counted by demo e2e specs). `DemoData` already seeds many lens cases on Northstar (bounced payment_failed and usage_alert, deferred, manual-reason suppressed, complained, rejected, queued, opened, clicked, unsubscribed, subscribed, unknown, long recipient `truncation_stress`). **Still missing per `LENS-FINDINGS.md` section C** (planner re-verifies against the file before seeding): a hard bounce to a typo domain, a bounce with nil `reject_reason`, a deferred row with no retry time, a send-time `:failed` with `last_error`, a delivered row with no open event, a sent row with no report, two emails to one customer with different subjects, a unicode recipient, and a long module name. A new module called only by the catalog run seeds them. Do not render "next try at…", "will retry" or cause text for a nil reason (milestone stop line); the catalog records what the screens say today, including their gaps.
- **D-23:** **Manifest schema (JSON), carrying the same identity fields as the demo evidence runner** (`run_id`, `source_revision`, `source_digest` in `scripts/run_demo_browser_evidence.sh`) so Phase 182 criterion 5 ("served SHA recorded after a server restart") consumes it unchanged: `schema`, `catalog_id`, `source {git_sha, dirty, branch}`, `served {assets[{url_path, sha256, matches_disk, matches_git_blob}], server_started_at}`, `tools {playwright, chromium, node, os, script_sha256}`, `determinism {tz, locale, fixed_time, reduced_motion, animations, dsf, fonts_loaded}`, `budget {image_count, total_bytes, cap_bytes}`, `captures[{id, file, sha256, bytes, w, h, screen, route, fixture, state, case, viewport, theme, root_theme_attr, tier, aria_file}]`. Optional `locator.ariaSnapshot()` text sidecars (tiny, git-diffable) let the Phase 183 reviewer compare copy and structure without pixels; include them if cheap, skip if they cost a day.
- **D-24:** The manifest and the script are validated by a required-lane test (new file; admin `support_contract_admin` or core, planner states which): manifest shape, every listed file exists with the recorded sha256 and no unlisted PNG exists in the directory, `git_sha` is a real 40-char commit that is an ancestor of HEAD, `dirty` is false, image count and bytes under the cap, and `nested_theme_attr_count` is 0. Mutation-prove it (flip a byte, add an unlisted file, set dirty true). Without this the catalog is an unverified claim.

### CI lanes (all three requirements)
- **D-25:** Everything required lands in `verify.support_contract.admin` (whole directory plus the alias step) and no new `ci.yml` job is added, so `CILanes` registration is not triggered and root `mix.exs` stays untouched. If the manifest test lives in core instead, it is picked up by the full `core_deterministic_suite` but not by the fast `verify.support_contract.core` allow-list (`mix.exs:321`); the plan must say which lane proves each requirement and never cite an advisory lane (`operator_browser_gate`, Playwright demo e2e) as proof.

### Claude's Discretion
- Exact file names beyond those named, the screen list inside the D-21 budget, the Preview iframe `color-scheme` mechanics, and whether the compare logic lives in `lib/mix/tasks` or `dev/` (D-02).
- Whether `ariaSnapshot()` sidecars are included (D-23).

### Deferred Ideas (OUT OF SCOPE)
- Zero-reload theme toggle with inline script and localStorage (Phoenix 1.8 pattern). Revisit only if round-trip toggling becomes a UX complaint.
- `light-dark()` token refactor to allow deliberate nested regions. Only if a real nested region is later required; touches the Phase 181 token pipeline.
- Correcting CLAUDE.md "CI runs `git diff --exit-code`" and the stale landmine/premise notes: Phase 183 docs pass (CLAUDE.md needs owner sign-off).
- Hashing and checking `hooks.js`, logo and fonts against a generator: they have none; Phase 181 extends the brand pin `shipped[]` for woff2 and logos.
- Hosted visual-diff or LFS storage: only if the catalog ever passes about 100 MB.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRPIPE-01 | The admin bundle is reproducible from a committed generator, with a `--check` drift gate that a required CI lane actually runs. | Gate is red at HEAD (139,137 vs 136,877, first diff at byte 74,051); `@source not inline("prose");` makes a fresh build byte-identical on macOS-arm64 and (emulated) Linux x86_64; a trailing `--output` does NOT override (F1), so the temp-output build must replace the profile's `--output=` arg; prototype compare code verified red/green plus 3 mutations; lane wiring and its blind spots mapped (Validation Architecture). |
| BRPIPE-02 | The theme attribute is owned by `<html>` only, and the nested `data-theme` shadowing defect is fixed. | Full inventory of every nested `data-theme` in lib (6 sites), every ExUnit and e2e pin to rework (tables below), measured before-counts per surface (red-first reproduction), measured browser reproduction of the defect, and a probe-verified replacement for the Preview backdrop toggle (F4). Bundle stays byte-identical after the removals (simulated). |
| BRPIPE-03 | A catalog of current admin screens on realistic fixtures (Northstar, Fjordline, Helios plus the delivery cases from the UX lens) is captured as before-screenshots at unique paths, before any token swap. | Capture path proven locally (demo up in 70 s on warm volumes, existing persona spec passes 3/3 against it, served CSS bytes equal disk and the git blob); determinism measured (same-state double capture byte-identical); seed gap list re-verified (only 4 cases truly missing); storage path confirmed not ignored; staging-dir ignore confirmed; shallow-clone, docs-only-skip and demo-lane-capture hazards identified. |
</phase_requirements>

## Summary

The bundle gate is real work but small and fully de-risked. At HEAD a fresh `mix tailwind` build of the admin differs from the committed `priv/static/app.css` (139,137 vs 136,877 bytes) because the word "prose" in `copy.ex` gloss strings makes the plain-text scanner emit daisyUI `.prose` rules (20 occurrences of `.prose` in the polluted build against 1 in the committed bundle; CONTEXT counts 18 rules). `@source not inline("prose");` removes exactly those, yields the committed bytes exactly, and was identical across macOS-arm64, Linux-arm64 and an emulated Linux x86_64 run of the official 4.1.12 binary (sha256 matched the published release sums). The alternative `@source not "<copy.ex path>"` is wrong: it also deletes four real classes (`badge-primary`, `hero-bell-slash`, `hero-envelope-open`, `hero-hand-thumb-up`) that exist only because `Copy` holds them as strings. The one structural surprise is F1: the pinned `tailwind` Hex runner appends extra args after the profile args, and the Tailwind CLI concatenates two `--output` flags into a single comma-joined path, so a trailing `--output` cannot redirect the build. The compare must replace the profile's own `--output=` entry and call the binary directly; a prototype of exactly that was run and gave red at HEAD, green with the fix, and correct failures for a flipped byte, a truncation and a missing file.

BRPIPE-02 is wider than CONTEXT implies. The lib change is six deletions (all measured; none changes the compiled bundle, which stays byte-identical), but five e2e spec files (four under `mailglass_admin/e2e`, one in the demo) and two ExUnit files (`admin_shell_test.exs`, `preview_live_test.exs`) pin the nested attributes or the three-column gallery matrix, and the Preview "dark backdrop" mechanic named in D-12 does not work as written: `color-scheme` on the iframe element does not move the email document's `prefers-color-scheme` in Chromium or WebKit, and a mismatch forces an opaque white canvas. A probe-verified replacement is a wrapper element with `color-scheme` plus the `Canvas` system colour, with the iframe pinned to `color-scheme: light`. The defect itself was reproduced in a real browser: with cookie dark, `preview-pane` resolves `--color-base-100` to `#f8fbfd` while `<html>` resolves `#0d1b2a`; and with no cookie under OS dark the pane is still `#f8fbfd`.

BRPIPE-03 is feasible on the existing demo harness without a new capture platform, with four planner-level hazards: the demo seed anchor is wall-clock `now`, so "fixed absolute timestamps" (D-19) cannot hold without touching `DemoData`; a new spec in the demo's `./e2e` directory is auto-run by the advisory demo lane; the required lane skips docs-only changes and uses a depth-1 checkout, so the catalog must land in the same PR as its validating test and an ancestry check needs a shallow guard; and only 4 of the 9 "missing" delivery cases are actually missing.

**Primary recommendation:** Land in this order: (1) `@source not inline("prose");` plus `--check` (built via `Tailwind.bin_path/0` with the profile's `--output=` swapped) plus the alias step and contract test, proving the lane red then green; (2) the six nested-`data-theme` deletions with the wrapper-based Preview backdrop, the root-only contract test and the e2e/ExUnit rework; (3) the catalog seed, capture script, manifest test and one capture on the clean final source commit, in the same PR as the manifest test.

## Research Findings That Contradict or Refine CONTEXT (read first)

| ID | CONTEXT claim | Finding (evidence) | Impact |
|----|---------------|--------------------|--------|
| F1 | D-07: "confirm whether a trailing `--output` overrides the config `--output`" | It does not. `Tailwind.run/2` does `System.cmd(args ++ extra_args, opts)` [VERIFIED: mailglass_admin/deps/tailwind/lib/tailwind.ex:302 `\|> System.cmd(args ++ extra_args, opts)`], and the CLI merges duplicate `--output` flags into one comma-joined path. [VERIFIED: run] `tailwindcss --input=assets/css/app.css --output=priv/static/app.css --minify --output=<scratch>/head_trailing.css` created the directory `priv/static/app.css,/private/tmp/.../head_trailing.css` (I moved the 139,137-byte result out and deleted the stray directory; tree clean). | `mix tailwind default --minify --output=<tmp>` (or `Mix.Task.run("tailwind", ...)` with a trailing output) is unusable and litters the shipped `priv/static/`. Replace the profile's `--output=` entry and call `System.cmd/3` on `Tailwind.bin_path/0` (Code Examples 1), or define a second profile. |
| F2 | D-07: Linux x64 "was not testable locally"; first task is a throwaway CI dry run | [VERIFIED: run] Official `tailwindcss-linux-x64` v4.1.12 (sha256 `5eeee66ea237eae9a160fa3314fd0cf76ab993551a99fafb16fa1db6c6b90289`, equal to the published `sha256sums.txt`) run in `docker run --platform linux/amd64 ubuntu:24.04` (`uname -m` = `x86_64`) on a copy of the inputs with the D-03 fix: 136,877 bytes, `cmp` identical to the committed bundle. Existing CI logs cannot answer it: `operator_browser_gate` only rebuilds (`mailglass_admin/package.json:5` `"test:operator-browser": "mix mailglass_admin.assets.build && playwright test ..."`) and nothing hashes or diffs the output. | The risk is largely retired. The real `ubuntu-latest` proof is the first PR run of the new lane itself (any admin code change sets `code=true`); a separate throwaway job is optional. Emulation caveat is in the Assumptions Log (A1). |
| F3 | D-13: "`Phoenix.LiveViewTest` does not render the root layout" | Wrong for the value `live/2` returns first. [VERIFIED: run] probe: `live_html_has_root=true` for the preview scenario; the existing tests `operator_live_test.exs:2760` and `inbound_live_test.exs:2665` already assert `<html lang="en" data-theme="mailglass-dark">` from `live(conn, ...)`, and `router_test.exs:198` does the same with `get/2`. Only `render(view)` after connect omits the root. Counts of `\sdata-theme=` measured (table in Architecture Patterns). | The required-lane render assertion needs no browser and no new harness: count attributes in the dead-render document. The "red on current code" reproduction is available today (2 to 4 occurrences where 1 is allowed). Gallery must use `get/2` (see P9). |
| F4 | D-12/D-13: toggle as `color-scheme` on the iframe element; "Chrome and Firefox propagate `color-scheme` into the iframe's `prefers-color-scheme`" | Not observed. [VERIFIED: run] Chromium (Playwright 1.59.1 build) and WebKit: with page `light`, iframe `color-scheme: dark`, the srcdoc document's `matchMedia("(prefers-color-scheme: dark)").matches` stayed `false`; with page `dark` it stayed `true` for every iframe `color-scheme`. A scheme mismatch between iframe element and document makes the canvas opaque white (pixel sample `FFFFFF` for `cs-dark`, `cs-dark+Canvas`, `cs-light+Canvas`; only `background:#0d1b2a` with matching schemes showed through as `0D1B2A`). Existing `e2e/flows.spec.js` asserts the pane background changes on toggle (`expect(afterBg).not.toBe(beforeBg)`, line 871). | `color-scheme` on the iframe element alone gives no visible toggle. Use a wrapper: `color-scheme: <frame>; background: Canvas` on a div around the iframe, iframe pinned `color-scheme: light` (transparent canvas). Pixel-verified in both engines: frame dark = `121212` (Chromium) / `1E1E1E` (WebKit), frame light = `FFFFFF`, independent of admin theme. Firefox was not testable here (A5). |
| F5 | D-19: "fetch `app.css` and `hooks.js` over HTTP from the running server" | `hooks.js` is not served by itself. Asset routes are `css-:md5`, `js-:md5`, fonts, logo, favicon [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex:342-346]; `@js` embeds hooks as `"\n" <> @hooks <> "\n" <> @live_socket_bootstrap` [VERIFIED: mailglass_admin/lib/mailglass_admin/controllers/assets.ex:315-316]. `app.css` is embedded at compile time (`@external_resource` + `File.read!`), so a running server serves the bytes it compiled. [VERIFIED: run] against the live demo: `/dev/mail/css-bb2156de84d3550bfa21a10048441e91` returned 136,877 bytes, sha256 prefix `173fdd6fe2d7d06c3223` equal to disk and to `git show HEAD:mailglass_admin/priv/static/app.css`; md5 equals the route digest. | Hash `app.css` via its `css-<md5>` URL; for the JS, hash the `js-<md5>` bundle and assert it contains the disk `hooks.js` bytes (or record `hooks.js` disk and git-blob sha256 only). The existing `persona-screenshots.spec.js` "working preview readiness" test already does the CSS served-vs-disk comparison (lines ~238-300) and is a reusable pattern. |
| F6 | D-19: "Seed fixtures at fixed absolute timestamps" | Not possible with the current seed. `reset!` does `Process.put(@anchor_key, DateTime.truncate(DateTime.utc_now(), :second))` [VERIFIED: reference/demo_app/lib/mailglass_demo/demo_data.ex:35] and Personas take the same anchor (`MailglassDemo.Personas.seed!(Repo, seed_anchor())`, line 55). The module comment explains why: a fixed past date "ages the seeded evidence out of the operator surfaces' recency windows", and both lists default to `@default_window_hours 168` [VERIFIED: operator_live.ex:48, inbound_live.ex:50]. Times render as `d.toLocaleString(undefined, FMT)` with `FMT` year/month/day/hour/minute [VERIFIED: controllers/assets.ex:113]. [VERIFIED: run] with `timezoneId:"UTC"`, `locale:"en-US"`: two captures of the same state are byte-identical (`a2936698041d`); a reset-and-recapture within the same wall minute is also identical; first times read `Nov 14, 2026, 3:40 PM`; `/\bago\b|just now/` matched nothing on the deliveries list. | Absolute times shift per capture minute. Decide: record the seed minute in the manifest and accept (recommended; the catalog is evidence, not a pixel baseline, D-18), or add an optional anchor override to `DemoData` (touches a guarded module, D-22) or mask `time[data-local-time]`. Keep the "capture twice, identical sha" self-test; it holds within one seeded state. |
| F7 | D-22: nine cases "still missing" | Re-verified against the file: five are already seeded. Bounce with nil `reject_reason`: `payment_failed` and `usage_alert` bounces call `event!/4`, which never sets `reject_reason` (demo_data.ex:159-163, 201-204, 749-768); also `rejected@northstar.example`. Deferred without retry time: `deferred@northstar.example`, `sg-demo-badge-deferred-001`. Delivered without open: `receipt_paid`, `stress_d`, and the Fjordline delivery. Two emails to one customer with different subjects: `billing@northstar.example` (`receipt_paid` + `payment_failed`) and `ops@northstar.example` (`usage_alert` + `incident_update`). Long module name: Fjordline `Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName`. **Truly missing (4):** hard bounce to a typo domain; send-time `status: :failed` with `last_error` (the schema has `field(:last_error, :map)`, delivery.ex:122, and no seed sets it); sent row with no report (no seed has `last_event_type: :sent`); unicode recipient (Fjordline's non-ASCII is in display-name metadata only; its recipient is `bjorn.hansen@fjordline-aps.example`). | The catalog-only seed is 4 deliveries, not 9. Seed them on Northstar so the screens read as the real "before"; record the seeded provider_message_ids in the manifest `fixture` fields. |
| F8 | D-24: "`git_sha` is a real 40-char commit that is an ancestor of HEAD" | `support_contract_admin` uses `actions/checkout` with no `fetch-depth` (job lines 886-946; the only `fetch-depth: 0` entries are at ci.yml:33, 258, 346, 422), so the checkout is depth 1 and `git merge-base --is-ancestor <older-sha> HEAD` cannot run in the required lane. The job also has `if: needs.changes.outputs.code == 'true'`, and `changes` treats `.planning/**` as docs-only [VERIFIED: ci.yml:23-70], so a PNG-only PR skips the lane. | Land the catalog in the same PR as its manifest test (the test file is non-`.planning`, so `code=true`). Validate the 40-hex shape unconditionally and ancestry only when `git rev-parse --is-shallow-repository` is `false`, or add `fetch-depth: 0` to that job (decision; the `changes` job already does it). |
| F9 | D-16: new spec "extending its existing Playwright spec family" in the demo | The demo config is `testDir: "./e2e"` and `test:e2e:ci` runs the whole directory then `check-demo-browser-evidence.cjs` [VERIFIED: reference/demo_app/assets/playwright.config.cjs:10; package.json `"test:e2e:ci": "playwright test --config=playwright.config.cjs && node scripts/check-demo-browser-evidence.cjs"`]. Any spec dropped in `assets/e2e/` runs inside the advisory `demo_browser_evidence` lane and `make demo-e2e`, with ~60 shots and a `.planning` write. | Put the catalog spec outside `./e2e` (e.g. `reference/demo_app/assets/catalog/before-catalog.spec.js` with its own `playwright.catalog.config.cjs`), or guard it with an explicit env opt-in. Invoke it host-side against `make demo` as I did for the existing spec (Environment Availability). |
| F10 | D-11: three sites plus callers | Complete list is in the BRPIPE-02 inventory below. Beyond CONTEXT: `reference/demo_app/assets/e2e/persona-screenshots.spec.js:203` selects `getByTestId("gallery-theme_picker-dark-selected").locator('[data-theme="mailglass-dark"]')` (a gallery nested wrapper that will not exist); `structural.spec.js` has 38 `primitiveWrapper(` occurrences (lines 449-3193, inside the Phase 111 and Phase 110 describe blocks), twin-wrapper assertions at 2465-2466 (Phase 97) and a nested light wrapper at 3467 (Phase 114), plus `gallery-matrix.spec.js` and `phase168-plan03-acceptance.spec.js` (six `-system` testid reads); `gallery_live.ex` moduledoc line 10 documents the wrappers. [VERIFIED: run] the gallery dead render has 182 distinct duplicated `id` values (three specimen columns reuse ids, e.g. `flash-error`), which is why `live/2` raises "Duplicate id found while testing LiveView: inbound-evidence-reveal-btn" on `/dev/mail/gallery`. | BRPIPE-02 e2e rework is the largest cost in the phase; budget a dedicated plan. Collapsing to one specimen per state also removes the duplicate ids (incidental fix; mention in the summary as such). |
| F11 | D-05: false CI-diff claims | More locations than listed: `mailglass_admin/.gitattributes:2` ("`git diff --exit-code priv/static/` CI gate (verify.phase_05 step 4)"), `mailglass_admin/.gitignore:21`, `lib/mix/tasks/mailglass_admin.assets.watch.ex:17`, and `mailglass_admin/docs/design-system.md:20-23` (ships in the Hex `docs` dir). `scripts/check_phase173_candidate.sh:245` does invoke `mix verify.preview`, and `scripts/test_check_phase173_candidate.sh:582` asserts the log contains `asdf exec mix verify.preview`. | Re-point `verify.preview` but keep its name. Edit all five prose locations; `token_parity_test.exs` asserts other `design-system.md` substrings (e.g. `"assets/css/app.css maps those values"`), so keep those lines intact. |
| F12 | D-09: "verify with Guard Release Trigger which kind an `assets/` edit is" | [VERIFIED: run] `guard_path_is_non_shippable` returns shippable for `mailglass_admin/assets/css/app.css`, `lib/**`, `priv/static/app.css`, `mix.exs`, `dev/**`, `e2e/**`, `scripts/**`, `.github/workflows/ci.yml`, `reference/**`; non-shippable only for `.planning/**`, `*.md`, `docs/`, `test/`. release-please `mailglass_admin` `exclude-paths` are `mailglass_admin/dev`, `/e2e`, `/package-lock.json`, `/package.json`, `/playwright.config.cjs`, `/scripts`, `/test` [VERIFIED: release-please-config.json read this session]. `mailglass_admin/assets/` is not excluded. | `chore(admin):` for the `app.css` source directive and `ci(admin)`/`chore(admin)` for `mix.exs`; `fix(admin):` only for `lib/` or `priv/static` behaviour. A `fix:` whose diff is only tests and `.planning` fails the guard; use `test:`. |
| F13 | D-03 alternative path form | [VERIFIED: run] `@source not "../../lib/mailglass_admin/copy.ex"` builds 132,985 bytes, not 136,877, and drops `badge-primary`, `hero-bell-slash`, `hero-envelope-open`, `hero-hand-thumb-up` (selector set diff). | Confirms CONTEXT's choice of the inline form and rules the path form out. Record the four classes so nobody retries it. |
| F14 | (not in CONTEXT) the bundle is rewritten by other entry points | `npm run test:operator-browser` and therefore `scripts/gsd-regression-gate.sh` (it calls that npm script) and `scripts/run_demo_browser_evidence.sh:350` (`... mix mailglass_admin.assets.build && \`) all rebuild `priv/static/app.css` in the working tree. At HEAD each leaves the tree dirty with the prose-polluted bundle (inference from the measured 139,137-byte fresh build). | D-03 must land before BRPIPE-03's "refuse to run if dirty" gate, or the capture's own harness dirties the tree it requires clean. After D-03 these are no-ops byte-wise. |
| F15 | D-06: `test_exceptions.exs` coupling | `scripts/check_test_exceptions.sh` greps only `test/mailglass` and `mailglass_inbound/test` [VERIFIED: scripts/check_test_exceptions.sh:19 `... test/mailglass mailglass_inbound/test`]; `config/test_exceptions.exs` has no `mailglass_admin` entries. | Admin test edits cannot break that registry. A manifest test placed in core (`test/mailglass/...`) WOULD be scanned (no `@tag :skip`, no `Process.sleep`). The no-skip, no-sleep rule is still good hygiene in admin. |
| F16 | D-12: "iframe isolation" | Confirmed. [VERIFIED: run] inside the srcdoc document `document.querySelectorAll("[data-theme]").length` is 0 and `--color-base-100` is the empty string under every frame/page scheme combination. | The isolation assertion in D-13 is valid as written. |

## Project Constraints (from CLAUDE.md)

- Run mix with `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` (`.tool-versions` pins `erlang 27.3.4.13`, not installed locally) [VERIFIED: run: `.tool-versions` = `erlang 27.3.4.13` / `elixir 1.18.4`; `~/.asdf/installs/erlang` has `27.3.4.15`]. Do not "fix" the tracked file.
- Shift-left, zero human UAT (D-52): every criterion here is machine-checkable; close rows `source: automated`; mutation-proven contract tests (template `phase175_prohibition_contract_test.exs`); owner hand-off only for ship/no-ship, brand/visual identity, secrets, `hex-publish` approval, physical devices.
- Errors and log messages follow the brand voice: specific and composed, never "Oops". The `--check` failure text is user-facing maintainer copy; state the cause and the exact fix command.
- Conventional Commits, squash-merge, one open PR at a time; `docs(state):` for STATE.md only.
- "Don't write to `mailglass_admin/priv/static/` without committing the rebuilt bundle (CI runs `git diff --exit-code`)" [CLAUDE.md "Things Not To Do" 6]. The "CI runs git diff" sentence is false today; fixing CLAUDE.md is deferred to Phase 183 (owner sign-off).
- Never hand-edit `.planning/release-target.json` or `.planning/STATE.md`; one-PR-at-a-time; do not touch `HEX_API_KEY` or release gates.
- No new dependency (user preference carried in CONTEXT; the milestone has no Node toolchain for adopters). This phase adds none.
- Custom Credo checks and the `:boundary` compiler apply to any new `lib/` or `dev/` module (see P11, P12).
- Memory-derived landmines that apply: token-parity bundle landmine (stale, see F-note below), path-coupled tests (keep the catalog under `research/`), admin lane is whole-directory, Mix build-lock stdout flake (do not byte-compare stdout of a nested `mix` invocation), Clock global async leak (do not mutate global Application env in an `async: true` test), `gsd-sdk query commit` sweeps every dirty `.planning/` path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Theme attribute on `<html>` (cookie to attribute) | Frontend Server (SSR): `Layouts.root_theme/1` in the router `root_layout` | Browser: CSS cascade resolves `[data-theme]` / `:root:not([data-theme])` | The server reads the cookie on the first response (no flash, no JS, no CSP surface). Verified: `root.html.heex:2` and `layouts.ex:70-86`. |
| Theme change | Frontend Server: `ThemeController.set/2` sets cookie, redirects to `return_to` | Browser: full navigation | Single source of truth is the cookie; picker is a radio group posting a LiveView event that redirects. |
| Preview email isolation and backdrop | Browser: `<iframe srcdoc>` is a separate document | Frontend Server: renders wrapper style from the `preview_frame_dark_chrome` assign | Custom properties never cross the iframe boundary (F16); backdrop is page-level framing, not email theming. |
| Bundle generation | Build/CI tooling (Mix task + pinned standalone Tailwind) | CDN/Static: committed `priv/static/app.css` | Generated at maintainer time, committed, embedded at compile time by `Controllers.Assets`. |
| Bundle drift gate | CI (`support_contract_admin` required lane) | Developer machine (alias `verify.support_contract.admin`, `verify.preview`) | One compare function, two entry points (alias step and ExUnit), so neither can be skipped alone. |
| Fixture seeding for the catalog | Database/Storage via demo app Mix code | API/Backend: `POST /demo/evidence/reset` | Catalog-only module adds the 4 missing cases after the destructive reset. |
| Screenshot capture and manifest | Browser (Playwright) driven from host | Database/Storage: committed PNGs under `.planning/research/` | Evidence only; validated by an ExUnit test in the required lane. |

## Standard Stack

No package is added in this phase. Everything below already exists in the repo [VERIFIED: run unless noted].

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Tailwind standalone binary | 4.1.12 (`config :tailwind, version: "4.1.12"`, config.exs:7) | CSS generation | Pinned by D-22 of the original design; binary lives at `mailglass_admin/_build/tailwind-<target>-4.1.12` |
| `tailwind` Hex package | 0.5.2 (`deps/tailwind/mix.exs:4` `@version "0.5.2"`) | Downloads and locates the binary; `Tailwind.bin_path/0`, `config_for!/1`, `install/0` | Already a dep (`mix.exs`: `{:tailwind, "~> 0.4", only: [:dev, :test], runtime: false}`) |
| daisyUI (vendored) | 5.5.19 (compiled banner `/*! daisyUI 5.5.19 */`) | Components and theme blocks | `assets/vendor/daisyui*.js` committed |
| ExUnit / Phoenix.LiveViewTest | Elixir 1.18.4 / OTP 27.3.4.15 | Required-lane contract tests | Existing admin suite |
| `@playwright/test` | 1.59.1 in `mailglass_admin`; 1.60.0 in `reference/demo_app/assets` | Browser proof and capture | Existing; browsers cached under `~/Library/Caches/ms-playwright` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | existing dep | Parse `manifest.json` in the ExUnit validator | manifest test |
| `:crypto` / `Base` | OTP | sha256 of PNGs and bundle | manifest and bundle tests |
| Docker + `compose.demo.yml` | Docker 29.5.2, Compose v5.1.3 | Run the demo for capture | BRPIPE-03 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `System.cmd` on `Tailwind.bin_path/0` with the profile's args and swapped `--output=` | A second `:tailwind` profile (`check`) with a fixed `_build/` output | Profile duplicates the input args in config (drift risk) and cannot be pointed at a tmp copy of the tree for the source-side teeth tests. Rejected. |
| Compare logic in `lib/mix/tasks/...` | Non-shipped `dev/` module called by the task | `lib/` code that references `Tailwind` warns for adopters (the dep is `only: [:dev, :test]`); `dev/` is compiled in `:dev` and `:test` only (mix.exs `elixirc_paths(:dev)`/`(:test)`). Recommended: `dev/` module plus a guarded `apply/3` from the shipped task (P11). |

**Installation:** none. **Version verification:** `deps/tailwind/mix.exs` 0.5.2 and `mix.lock` already present; no `npm view`/`pip index` step applies because nothing new is installed.

## Package Legitimacy Audit

No external packages are installed or added by this phase (CONTEXT specifics: "No new dependency is added in this phase"). The Tailwind standalone binary is fetched by the existing `tailwind` dep exactly as today; its checksum was cross-checked this session against the vendor's published `sha256sums.txt` (match), but note the Hex runner itself does not verify a checksum (Security Domain).

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | n/a | n/a | n/a | n/a | n/a | n/a |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
Theme ownership (BRPIPE-02) - target state
  Picker radio (Components.theme_picker) -> LiveView event set_theme
        |  push redirect /<mount>/theme/<system|light|dark>?return_to=...
        v
  ThemeController.set/2 -- put_resp_cookie "mailglass_admin_theme_v2" (http_only, Lax, 1y) --> redirect return_to
        v
  Router pipeline put_root_layout {MailglassAdmin.Layouts, :root}
        v
  Layouts.root_theme(conn) reads cookie -> Theme.data_theme/1 -> "mailglass-light" | "mailglass-dark" | nil
        v
  <html lang="en" data-theme={...}>         <-- the ONLY data-theme in the document (absent for system)
        v  CSS cascade (compiled bundle):
        |   [data-theme=mailglass-light] / [data-theme=mailglass-dark]   -> --mg-* and --color-* and color-scheme
        |   @media (prefers-color-scheme: dark){ :root:not([data-theme]) ... }   (system)
        v
  every descendant inherits; #mg-copy-toast (outside .mg-admin-root) inherits too
        v
  Preview html tab:  wrapper[color-scheme + Canvas] > iframe[color-scheme:light] srcdoc  (separate document, no tokens cross)

Bundle gate (BRPIPE-01)
  assets/css/app.css + assets/vendor/*.js + lib/** (plain-text scan) + ../brandbook/tokens.css + Tailwind 4.1.12
        |  System.cmd(Tailwind.bin_path(), profile args with --output=<tmp>, "--minify", cd: profile :cd)
        v
  fresh bytes ---compare byte-for-byte---> priv/static/app.css (committed)
        |  equal -> :ok     differ/missing/short -> Mix.raise(sizes, first offset, "run mix mailglass_admin.assets.build and commit")
        +--> alias step 1 of verify.support_contract.admin  (mix.exs aliases)
        +--> ExUnit bundle_reproducibility_contract_test.exs (same function, plus hermetic mutations)
                 both run by ci.yml job support_contract_admin (MIX_ENV=test, line 946) -> ci_green.needs (line 1445)

Catalog (BRPIPE-03)
  clean-tree + bundle-identity gates -> docker compose up demo (warm volumes ~70 s) -> POST /demo/evidence/reset
        -> catalog-only seed (4 cases) -> Playwright (UTC, en-US, reduced motion, animations off, wait .phx-connected)
        -> stage in .planning/research/brand-v2-adoption/before-catalog/.cache/<id>/ (git-ignored) -> validate budget + hashes
        -> promote (atomic rename, refuse existing id) -> <id>/{manifest.json,*.png,aria/*}
        -> ExUnit before_catalog_manifest_test (required lane) lands in the SAME PR
```

### Recommended Project Structure

```
mailglass_admin/
  assets/css/app.css                        # + `@source not inline("prose");` after line 14 (chore)
  lib/mix/tasks/mailglass_admin.assets.build.ex   # + --check flag, moduledoc inputs list (thin; guarded call into dev/)
  dev/mailglass_admin/assets_check.ex       # NEW non-shipped compare module (name discretionary); `use Boundary, classify_to: MailglassAdmin`
  mix.exs                                   # alias step 1 + verify.preview re-point + comment fix
  test/mailglass_admin/bundle_reproducibility_contract_test.exs     # NEW (BRPIPE-01)
  test/mailglass_admin/root_theme_ownership_contract_test.exs       # NEW (BRPIPE-02), names discretionary
  test/mailglass_admin/before_catalog_manifest_test.exs             # NEW (BRPIPE-03)
  e2e/theme-ownership.spec.js               # NEW (advisory browser lane)
reference/demo_app/
  lib/mailglass_demo/catalog_seed.ex        # NEW, called only by the catalog run (4 cases)
  assets/catalog/before-catalog.spec.js + assets/playwright.catalog.config.cjs   # NEW, outside ./e2e (F9)
.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/{manifest.json,*.png,aria/*.yml}
```

### Recommended plan and wave shape (budget about 4 plans)

1. **Plan 1 (BRPIPE-01):** `chore` directive, task `--check` + `dev/` compare, alias + `verify.preview` re-point, `bundle_reproducibility_contract_test.exs`, prose fixes (F11). Prove red-then-green (HEAD without the directive is red: `{:drift, 139137, 136877, 74051}`).
2. **Plan 2 (BRPIPE-02 lib + ExUnit):** failing reproduction first, then six deletions, wrapper backdrop, `root_theme_ownership_contract_test.exs`, ExUnit rework (`admin_shell_test.exs`, `preview_live_test.exs`). Re-run `--check` after the edits (bundle expected byte-identical).
3. **Plan 3 (BRPIPE-02 e2e):** `e2e/theme-ownership.spec.js`, rework of `structural.spec.js`, `flows.spec.js`, `gallery-matrix.spec.js`, `phase168-plan03-acceptance.spec.js`, demo `persona-screenshots.spec.js:203`; run `axe-baseline.spec.js` without `PERSIST_AXE_BASELINE` to confirm no regression.
4. **Plan 4 (BRPIPE-03):** catalog seed, capture spec + config, manifest test, one capture at the final source commit, promote, same-PR commit.

### Pattern 1: Temp-output compare (verified prototype, see Code Examples 1)
**What:** Read the `:default` profile with `Tailwind.config_for!/1`, rewrite only the `--output=` entry, run the pinned binary with `cd` from the profile, compare bytes, always delete the temp file.
**When:** the `--check` mode and every hermetic test.

### Pattern 2: Count `data-theme=` over the whole dead-render document
**What:** `live/2` (or `get/2` for the gallery) returns a document that includes the root `<html>`. Assert exactly one occurrence for an explicit cookie and zero for system, per surface.
**Example:** Code Examples 3.

### Pattern 3: One compare function, two entry points
**What:** The same function backs the Mix task and the ExUnit file. The alias step makes `mix verify.support_contract.admin` red even if someone deletes the test; the test makes `mix test` red even if someone deletes the alias step; a wiring assertion makes deleting either visible.

### Pattern 4: Hermetic mutation by copying the input tree
**What:** `File.cp_r!` `assets/` and `lib/` (852 KB + 388 KB) plus `brandbook/tokens.css` into a tmp tree that preserves `mailglass_admin/` and `brandbook/` relative paths (the CSS imports `../../../brandbook/tokens.css`), mutate the copy, build with `cd:` pointing at the copy. Verified manually: a copy at a different absolute path with the directive builds the committed bytes; adding `lib/zz_probe.ex` containing `"underline"` and `"tracking-widest"` produced 136,992 bytes. Use `tracking-widest` as the planted token: `.tracking-widest` is absent from the committed bundle (count 0), whereas `.underline` is present (count 1) so it would not prove anything.

### Anti-Patterns to Avoid
- **Trailing `--output` or `mix tailwind default --output=...`** (F1).
- **`@source not "<path>"` for the prose fix** (F13).
- **A class or inline style that sets `--color-*` or `--mg-*`**, or a nested `data-theme`, anywhere under `lib/`.
- **`color-scheme` on the iframe element as the only toggle mechanism** (F4).
- **Adding `compile --warnings-as-errors` to the new gate.** [VERIFIED: run] `MIX_ENV=test mix compile --force --warnings-as-errors` exits 1 at HEAD on an unrelated pre-existing warning (`MailglassDemo.QuickViewScenarios is not included in any boundary`, `reference/persona_spec/quick_view_scenarios.ex:0`), while `mix test --warnings-as-errors` exits 0 (it only governs test-file warnings). Do not couple the gate to a warnings-free compile; report the pre-existing warning to the owner as a separate finding (it also means `mailglass_admin` `ci.fast`/`ci` aliases fail on a cold compile today).
- **Comments containing both "system" and "data-theme"** (or `root_theme` and "system") in `layouts.ex`, `layouts/root.html.heex`, `operator_live.ex`, `inbound_live.ex`: `check-conformance.sh` greps `'mailglass-system|data-theme="system"|root_theme.*system|system.*data-theme'` over exactly those files and fails the required `conformance_gates` lane [VERIFIED: mailglass_admin/scripts/check-conformance.sh:416].
- **Putting the catalog spec in the demo's `./e2e`** (F9).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Locating/downloading the Tailwind binary | A curl/shell fetch | `Tailwind.bin_path/0` and `Tailwind.install/0` | Resolves target (`linux-x64`, `macos-arm64`, musl) and version; download errors `raise`, which gives fail-closed for free (tailwind.ex `fetch_body!` raises on non-200). |
| Slug/schema validation of the manifest | Ad hoc string parsing | `Jason.decode!/1` plus explicit key/type asserts and `:crypto.hash(:sha256, bytes)` | Already in admin; matches `CaptureManifest` precedent. |
| PNG validity | Trusting file extension | Check the 8-byte signature and IHDR width/height, as `MailglassAdmin.Preview.CaptureManifest` does (`@png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>`, `@max_png_dimension 32_768`) | Existing, tested precedent in `dev/mailglass_admin/preview/capture_manifest.ex`. |
| Destructive-reset safety for the capture | A new reset endpoint | `resetDisposableEvidence` in `reference/demo_app/assets/scripts/check-persona-reset-target.cjs` | Requires an explicit local `DEMO_BASE_URL`, a `DEMO_EVIDENCE_RUN_ID` matching `^mailglass-evidence-...`, and the `/health` project-id header; reuse it unchanged. |
| Atomic promote of the staged catalog | Copying files one by one into the tracked dir | `File.rename`/`fs.renameSync` of the whole staged directory to the final path, refusing if it exists | Prevents `gsd-sdk query commit` (it stages every dirty `.planning/` path) from committing a half-written catalog. |
| Theme state in the browser | Inline script, localStorage | The existing cookie round trip (D-10) | Deferred by decision. |

**Key insight:** the failures this phase guards against (a path concatenated into the output, a word that becomes a CSS rule, a nested attribute that re-declares tokens) are all silent. Each needs a mutation that goes red, not a passing happy path.

## Runtime State Inventory

(Included because BRPIPE-02 removes attributes and BRPIPE-01 changes how a generated file is validated. No rename or data migration.)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. The theme preference is a client cookie (`mailglass_admin_theme_v2`, plus a legacy `mailglass_admin_theme`), unchanged by this phase. No database key embeds a theme name. | None. |
| Live service config | None. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | `DEMO_EVIDENCE_RESET_TOKEN` (default `mailglass-dev-demo`, loopback-bound), `DEMO_EVIDENCE_RUN_ID`, `DEMO_EVIDENCE_PROJECT_ID`, `DEMO_BASE_URL` are read by the existing persona spec harness; the capture reuses them. Nothing is renamed. | Capture script must not write them into the manifest. |
| Build artifacts / installed packages | (1) `mailglass_admin/_build/tailwind-<target>-4.1.12` binaries (78 MB macOS-arm64, 114 MB linux-arm64, 123 MB linux-x64 files; git-ignored; `deps` is cached in CI but `_build` is not, so each CI run downloads the binary). (2) `Controllers.Assets` embeds `app.css` into the BEAM at compile time, so a running server (or a stale `_build`) serves old bytes after the file changes. (3) The Docker demo bind-mounts the repo and keeps its own `_build` volumes. | `--check` reads disk bytes, never the BEAM attribute. Capture must hash the served `css-<md5>` response and compare to disk and to `git show` (F5). |

**The canonical question** (after every file is updated, what runtime system still has the old thing cached?): a running dev or demo server with the previously compiled bundle, and browsers holding the immutable-cached `css-<md5>` URL (new bytes mean a new URL, so this self-heals).

## Common Pitfalls

### P1: A plain word becomes CSS
**What goes wrong:** The scanner treats every `lib/` string and comment as candidates. `prose` in `copy.ex` emitted 18 daisyUI `.prose` rules; any later gloss/copy text can do the same for a real utility word.
**How to avoid:** `@source not inline("prose");` for this case, and the `--check` gate for the general case. After every `lib/` edit that adds text, run `mix mailglass_admin.assets.build --check`. Note the inverse: `Copy` legitimately carries class strings; four classes exist only there (F13).
**Warning signs:** a fresh build that differs by a few hundred bytes; `--check` reporting a first-diff offset inside the utilities block.

### P2: Trailing flag concatenation (F1)
**How to avoid:** never pass `--output` after the profile; swap the `--output=` entry. **Warning signs:** a directory named `app.css,` (comma) under `priv/static/`.

### P3: The lane that does not run
**What goes wrong:** `support_contract_admin` is `if: needs.changes.outputs.code == 'true'`; a `.planning`-only PR skips it (F8). `verify.preview` already shipped a gate nobody ran.
**How to avoid:** the wiring assertion (D-06) and landing the catalog with its test. Also keep `verify.preview` in sync because `scripts/check_phase173_candidate.sh:245` invokes it.

### P4: Coverage ratchet is absolute
**What goes wrong:** `scripts/check_coverage_floor.sh:30` fails when `covered < base.covered_lines || relevant < base.relevant_lines || percentage < base.percentage`; `config/coverage_baselines/admin.json` records 3334/3992 (83.517034%, measured 2026-09-17). Deleting covered lines can reduce `covered` and `relevant`.
**How to avoid:** the baseline predates Phases 174-179, so there should be slack, but this was not measured (A4). New `dev/` module lines count as relevant and covered if tested. Plan a `mix coveralls.json` run before opening the PR.

### P5: Gallery duplicate ids and `live/2`
`/dev/mail/gallery` cannot be mounted with `live/2` today (duplicate ids from the three specimen columns); use `get/2` for the gallery count assertion. After the collapse to one specimen per state, re-check; if ids become unique, `live/2` works and a duplicate-id assertion is a cheap extra guard.

### P6: `applyThemeEmulation` is not importable
It is a file-local function at `e2e/structural.spec.js:828` (`if (theme === "system") { await page.emulateMedia({ colorScheme: "dark" }); } else { await page.emulateMedia({ colorScheme: null }); }`) and there is no `module.exports`. CONTEXT says "reuse"; the practical options are copying the six lines or extracting a `e2e/support/theme.cjs`. Note `loginOperator` calls `page.context().clearCookies()` (flows.spec.js:51), so add the theme cookie after login.

### P7: Frame-toggle e2e asserts a visible change
`e2e/flows.spec.js` (Preview a11y backdrop test) reads `pane` `backgroundColor` before and after the toggle and requires them to differ. The wrapper design puts the backdrop on a new wrapper, so give it its own `data-testid` (suggest `preview-frame-backdrop`) and move that assertion to it. Keep `data-preview-frame-theme` on the tabpanel (it is a state marker used by `preview_live_test.exs` and 12+ e2e lines).

### P8: Seeding order and tenant
`POST /demo/evidence/reset` truncates everything. Run the catalog seed after every reset, not once. Seed onto Northstar. Row ids are UUIDs: locate cases by recipient text (e.g. via the deliveries filter) rather than by id.

### P9: Time and relative text
No relative-time strings render (measured); absolute times follow the seed minute (F6). Do not promise cross-run pixel identity.

### P10: Dirty-tree self-inflicted
The harnesses in F14 rebuild the bundle; and the demo e2e writes `reference/demo_app/tmp/` (ignored). Run the gate `git status --porcelain --untracked-files=all` after `make demo` and before the first shot, excluding only the staging dir. After D-03 the rebuild is byte-identical so the tree stays clean.

### P11: Compile-time reference to `Tailwind` from `lib/`
`{:tailwind, ..., only: [:dev, :test], runtime: false}` means an adopter's compile of the shipped task would warn about an undefined `Tailwind` module. The existing task avoids it by using the string `Mix.Task.run("tailwind", ...)`. Keep `Tailwind.*` calls in `dev/` (compiled for `:dev` and `:test`), and have the shipped task `Code.ensure_loaded?` the dev module and raise a clear "maintainer-only" message otherwise; or add `@compile {:no_warn_undefined, Tailwind}` if the logic stays in the task. Either way add `use Boundary, classify_to: MailglassAdmin` (existing task line 2 does) or `--warnings-as-errors` fails on "not included in any boundary".

### P12: Alias first step compiles the project
Running `mailglass_admin.assets.build --check` as the first alias step relies on Mix compiling the project to find its own task. This is believed to work (Mix compiles when a task is missing) but was not run from a cold `_build` (A3). Verify once from a throwaway clone or with `MIX_BUILD_PATH` pointing at an empty directory (note: `Tailwind.bin_path` is `dirname(build_path)/tailwind-...`, so a custom path re-downloads the binary).

### P13: Do not byte-compare stdout of a nested `mix`
Memory: Mix's "Waiting for lock on the build directory" notice contaminates stdout under suite contention. Test the check function in-process and assert on the returned tuple or the raised message; if a test must shell out, assert exit status and `=~`, never equality.

### P14: Shallow clone and ancestry (F8)
Guard ancestry with `git rev-parse --is-shallow-repository`, or add `fetch-depth: 0` to the job.

## Code Examples

### 1. Temp-output compare (prototype run; outputs observed)

Values it depends on, quoted from `mailglass_admin/config/config.exs:6-14`:

```elixir
config :tailwind,
  version: "4.1.12",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]
```
and `deps/tailwind/lib/tailwind.ex:319` `Enum.into(env, %{"BROWSERSLIST_IGNORE_OLD_DATA" => "1"})`, `:221` `def bin_path(version \\ configured_version()) do`.

```elixir
# Source: prototype run this session (scratch, not committed). Observed:
#   HEAD (no fix):                {:error, {:drift, 139137, 136877, 74051}}
#   scratch copy WITH directive:  :ok
#   one byte flipped at 1000:     {:error, {:drift, 136877, 136877, 1000}}
#   truncated to 5000:            {:error, {:drift, 136877, 5000, 5000}}
#   deleted:                      {:error, {:committed_unreadable, :enoent}}
def check(opts) do
  cfg = Tailwind.config_for!(:default)
  cd = Keyword.get(opts, :cd, cfg[:cd])
  committed = Keyword.fetch!(opts, :committed)
  tmp = Path.join(System.tmp_dir!(), "mg_assets_check_#{System.unique_integer([:positive])}.css")

  args =
    Enum.map(cfg[:args], fn "--output=" <> _ -> "--output=" <> tmp; a -> a end) ++ ["--minify"]

  # No rescue around install: a failed download must raise (fail closed, D-06).
  unless File.exists?(Tailwind.bin_path()), do: Tailwind.install()

  {out, status} =
    System.cmd(Tailwind.bin_path(), args,
      cd: cd, env: %{"BROWSERSLIST_IGNORE_OLD_DATA" => "1"}, stderr_to_stdout: true)

  try do
    if status != 0, do: {:error, {:tailwind_failed, status, out}}, else: compare(File.read!(tmp), File.read(committed))
  after
    File.rm(tmp)
  end
end
```
The Mix task wraps the error tuple in `Mix.raise/1` with: sizes, first differing offset, and the exact command to run (`mix mailglass_admin.assets.build`) plus "commit priv/static/app.css". Parse the flag with `OptionParser.parse(argv, strict: [check: :boolean])`.

### 2. The directive (Tailwind docs syntax)

```css
@source "../css";
@source "../../lib";
@source not inline("prose");
```
[CITED: tailwindcss.com/docs/detecting-classes-in-source-files] "Use `@source not inline()` to prevent specific classes from being generated, even if they are detected in your source files". Placed after `@source "../../lib";` (app.css:13-14, `@import "tailwindcss" source(none);` at line 11). Verified on 4.1.12 with `source(none)`: 136,877 bytes, `cmp` identical to the committed bundle, and `.max-w-prose{max-width:65ch}` still emitted (five real uses in `preview_live.ex:574`, `components.ex:812,909`, `inbound/quick_view.ex:177`, `operator/health_overview.ex:75`).

### 3. Root-only render assertion (counts observed on current code)

Cookie name from `mailglass_admin/lib/mailglass_admin/theme.ex:6` `@cookie_name "mailglass_admin_theme_v2"` via `MailglassAdmin.Theme.cookie_name()` (as in `router_test.exs`'s `@theme_cookie MailglassAdmin.Theme.cookie_name()`).

```elixir
conn = Plug.Conn.put_req_header(conn, "cookie", "#{@theme_cookie}=dark")
{:ok, _view, html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")
assert length(Regex.scan(~r/\sdata-theme=/, html)) == 1     # root <html> only
# system (no cookie): == 0; gallery: use get/2 + html_response/2 (P5)
```
Observed counts of `\sdata-theme=` in the document returned by `live/2` (connected `render(view)` in parentheses) at HEAD:

| Surface (path) | cookie dark | cookie light | system |
|---|---|---|---|
| Preview show `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default` | 4 (3) | 4 (3) | 2 (2) |
| Operator `/ops/mail?tenant_id=test-tenant` | 2 (1) | 2 (1) | 0 (0) |
| Inbound `/ops/mail/inbound?tenant_id=test-tenant` | 2 (1) | 2 (1) | 0 (0) |
| Gallery `/dev/mail/gallery` via `get/2` | 245 | 245 | 244 |

Target after the change: 1 for dark and light, 0 for system, on every surface. The preview system-mode count of 2 is the defect in its purest form: the html and text panels force `mailglass-light` with no cookie at all.

### 4. Browser matrix skeleton (reproduction measured on current code)

```js
// cookie value strings are "light" | "dark"; absent cookie = system. Add AFTER login (loginOperator clears cookies).
await ctx.addCookies([{ name: "mailglass_admin_theme_v2", value: cookie, url: base }]);
await page.emulateMedia({ colorScheme: os });          // before navigation
const r = await page.evaluate(() => {
  const css = (el, p) => getComputedStyle(el).getPropertyValue(p).trim();
  const html = document.documentElement;
  return {
    themed: [...document.querySelectorAll("[data-theme]")].map(e => e.tagName.toLowerCase()),
    html: css(html, "--color-base-100"),
    pane: css(document.querySelector('[data-testid="preview-pane"]:not([hidden])'), "--color-base-100"),
    toast: css(document.querySelector("#mg-copy-toast"), "--color-base-100"),
  };
});
```
Measured at HEAD (admin `OperatorBrowserServer` on a spare port, Preview scenario page): cookie `dark` + OS `light`: html `#0d1b2a`, shell `#0d1b2a`, toast `#0d1b2a`, **pane `#f8fbfd`**; `[data-theme]` elements `html`, `preview-shell`, `preview-pane`, a hidden `div`. Cookie absent + OS `dark`: html `#0d1b2a`, **pane `#f8fbfd`**, `[data-theme]` = `preview-pane`, `div`. Cookie `light` + OS `dark` and absent + OS `light` agree (all `#f8fbfd`). The spec is red on current code in two of the four combinations.

### 5. Preview backdrop wrapper (probe-verified in a standalone page, Chromium and WebKit; not yet in the app)

```heex
<div data-testid="preview-frame-backdrop"
     style={"color-scheme: #{if @dark, do: "dark", else: "light"}; background: Canvas"}>
  <iframe srcdoc={@html_body} sandbox="allow-same-origin" style="color-scheme: light; ..." />
</div>
```
No `data-theme`, no token re-declaration, no new CSS rule (so the bundle is not touched by this edit; inline `style=` is how the iframe is already styled at `tabs.ex:106-111`). Sampled pixel through a transparent srcdoc: frame dark `121212` (Chromium) / `1E1E1E` (WebKit); frame light `FFFFFF`; identical under admin light and admin dark. The `HEX-GATE` in `check-conformance.sh` only flags `color[^#]*#RRGGBB` in `.ex`, so the `Canvas` keyword is clean. Text/headers/raw tabs follow the admin theme per D-12; the toggle then changes the HTML backdrop only (the control is already labelled "Preview background", with help text "Browser preview framing only. It does not establish email-client compatibility or dark-mode behavior." at `preview_live.ex` at line 534). The panel padding around the wrapper keeps admin tokens; the visible backdrop change moves from "whole panel" to "email stage", which the plan summary must name as a visible change.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Exclude a scanned file with `@source not "<path>"` | `@source not inline("<class>")` excludes a class wherever detected | Documented on the Tailwind docs page fetched this session (introduction version not stated there) | Right tool for an English word that collides with a utility. |
| Nested `data-theme` scopes for specimens | One theme owner on `<html>`; matrices via per-load theme | This phase | Removes token re-declaration shadowing; the `light-dark()` refactor for real nested regions is deferred. |

**Deprecated/outdated:** CLAUDE.md "CI runs `git diff --exit-code`" and the memory note "token-parity bundle landmine" (a fresh build only differs by the prose rules; with D-03 it equals the committed file and `TokenParityTest` passes against it).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The real `ubuntu-latest` x64 runner yields byte-identical output (evidence is an emulated `linux/amd64` container with the same official binary) | F2 | If bytes differ the lane is red on first run; plan must pin the check to the CI platform (D-07 fallback) |
| A2 | `support_contract_admin` runners can download the Tailwind binary from GitHub releases | BRPIPE-01 | `--check` fails closed (by design); mitigated by `operator_browser_gate` already doing the same download on its runner |
| A3 | `mix verify.support_contract.admin` with the new first step compiles the project cold and finds the task | P12 | Lane red on a cold CI checkout; verify before opening the PR |
| A4 | Net deletions do not breach the absolute coverage floor (baseline measured 2026-09-17, before Phases 174-179) | P4 | `Collect and enforce admin coverage floor` step fails; measure with `mix coveralls.json` |
| A5 | The wrapper `color-scheme` + `Canvas` backdrop behaves the same in Firefox (only Chromium and WebKit were run) | F4 | Visual difference only; no required-lane test depends on it |
| A6 | After the six deletions the dead-render counts become 1/1/0 on every surface (measured only before the change; bundle effect was simulated) | Code Examples 3 | A missed nested attribute would be caught by the new contract test itself |
| A7 | Storybook stories keep their own template-level `data-theme` (out of scope: they are a dev-only iframe harness; D-11 lists three admin lib sites) | BRPIPE-02 | If the owner wants them in scope the plan roughly doubles for that surface |
| A8 | Approximately 64 captures at the measured sizes fit 15 MB (mobile 375x900 dark overview = 49,934 B; 1440x1082 deliveries = 187,539 B; the existing 66-file ignored cache is 18 MB) | BRPIPE-03 | The script's own budget gate fails the run; trim fixtures first |

## Open Questions

1. **Storybook nested `data-theme`.** `reference/demo_app/dev/mailglass_demo_web/storybook.ex` and ~30 story-file lines use template-level `data-theme` and `data-theme-owner` by design (Phase 174 fidelity). Recommendation: out of scope; the criterion-3 browser matrix must not target `/dev/storybook`. Resolve by confirming in the plan.
2. **Timestamp determinism (F6).** Recommend record-the-seed-minute and no masking. Alternative needs an additive anchor seam in a guarded module.
3. **Ancestry check in the required lane (F8).** Recommend shape check always, ancestry only on a full clone; adding `fetch-depth: 0` is a one-line CI change if the planner wants it enforced.
4. **Where `Tailwind.install/0` failure surfaces in `--check`.** Recommend letting it raise; document in the moduledoc.
5. **`ariaSnapshot()` sidecars.** Not run here. Playwright 1.59/1.60 both expose `locator.ariaSnapshot()`; include them only if the capture loop stays under a day (Claude's discretion per CONTEXT).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | all mix work | yes | 1.18.4-otp-27 with Erlang 27.3.4.15 (export the two ASDF vars) | none needed |
| PostgreSQL | admin ExUnit suite, `OperatorBrowserServer` | yes | accepting on `/tmp:5432` | none |
| Tailwind 4.1.12 binary | `--check`, contract test | yes locally (`_build/tailwind-macos-arm64-4.1.12`, `-linux-arm64-4.1.12`) | 4.1.12 | CI downloads each run; fail closed if unreachable |
| Node | Playwright | yes | v26.10.0 locally (CI uses Node 22) | none |
| Playwright + Chromium + WebKit | e2e, capture | yes | 1.59.1 (admin), 1.60.0 (demo); browsers cached; Firefox not installed | WebKit/Chromium probes only |
| Docker + Compose | demo for capture; amd64 emulation check | yes | 29.5.2 / v5.1.3; warm `mailglass-demo_*` volumes | none |
| ImageMagick `magick` | probe pixel sampling only | yes | n/a | not needed in the product |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** Firefox (A5).

Measured timings: Tailwind build ~0.1-0.25 s; 7 affected admin test files 113 tests green in 8.6 s (`--seed 0`); one existing e2e spec 4 tests in 12.7 s against the auto-started `OperatorBrowserServer`; demo `up --build --wait` 69 s on warm volumes; persona spec subset (2 shots + readiness) 3.9 s.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18.4 / OTP 27) in `mailglass_admin`; Playwright 1.59.1 for browser (advisory) |
| Config file | `mailglass_admin/mix.exs` aliases; `mailglass_admin/playwright.config.cjs` |
| Quick run command | `cd mailglass_admin && mix mailglass_admin.assets.build --check && mix test test/mailglass_admin/<new_file>_test.exs --seed 0` |
| Full suite command | `cd mailglass_admin && mix verify.support_contract.admin` (alias = whole-directory `test --warnings-as-errors`; no file allow-list) |
| Browser | `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --workers=1 e2e/theme-ownership.spec.js` (auto-boots `OperatorBrowserServer`) |

Lane facts [VERIFIED: ci.yml:886-946, 1430-1445; config/quality/ci_policy.exs:9, 145-146]: `support_contract_admin` (MIX_ENV=test, ubuntu-latest, `if: code == 'true'`) is in `active_required` and `ci_green.needs`; `operator_browser_gate` and `demo_browser_evidence` are `advisory`.

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | Lane | File Exists? |
|--------|----------|-----------|-------------------|------|-------------|
| BRPIPE-01 | Fresh build equals committed bundle | unit/integration | `mix mailglass_admin.assets.build --check` (exit 0) and positive case in `bundle_reproducibility_contract_test.exs` | REQUIRED (alias step 1 + `mix test`) | Wave 0 |
| BRPIPE-01 | One flipped byte, truncation, missing file each fail and name `mix mailglass_admin.assets.build` | unit (hermetic tmp) | `mix test test/mailglass_admin/bundle_reproducibility_contract_test.exs --seed 0` | REQUIRED | Wave 0 |
| BRPIPE-01 | Source-side drift: appended rule in a tmp copy of `app.css`; planted `tracking-widest` in a tmp `lib/` copy; removing the `prose` directive | unit (tmp tree copy) | same file | REQUIRED | Wave 0 |
| BRPIPE-01 | Wiring: `ci.yml` runs `verify.support_contract.admin` (line 946); the alias has no file list and contains the `--check` step; `ci_green.needs` contains `support_contract_admin` (line 1445) | static | same file (reads `.github/workflows/ci.yml` via `Path.expand("../../../.github/workflows/ci.yml", __DIR__)`, `Mix.Project.config()[:aliases]`) | REQUIRED | Wave 0 |
| BRPIPE-01 | Fail closed when the binary cannot be installed | unit with an injected installer that raises | same file; assert the raise propagates, never `:ok` | REQUIRED | Wave 0 |
| BRPIPE-01 | Real `ubuntu-latest` bytes | CI | first PR run of `support_contract_admin`; optional throwaway draft PR with a drifted bundle showing `CI Green` red, never merged | REQUIRED (the lane); the draft PR is optional evidence | n/a |
| BRPIPE-02 | No `data-theme=` literal under `lib/**/*.{ex,heex}` except `layouts/root.html.heex`; no `--mg-`/`--color-` assignment in inline styles or Tailwind arbitrary-property classes | static grep over a directory argument | `mix test test/mailglass_admin/root_theme_ownership_contract_test.exs` | REQUIRED | Wave 0 |
| BRPIPE-02 | Document-level count: dark/light = 1, system = 0 for preview show, operator, inbound (`live/2`) and gallery (`get/2`), with the failing reproduction recorded red on current code first | integration | same file | REQUIRED | Wave 0 |
| BRPIPE-02 | `AdminShell.shell/1` renders no `data-theme` (rework of `admin_shell_test.exs`) | unit | `mix test test/mailglass_admin/admin_shell_test.exs` | REQUIRED | exists, rework |
| BRPIPE-02 | Preview frame toggle keeps `data-preview-frame-theme` and the aria-live text; no `data-theme` on panes (rework of `preview_live_test.exs`) | integration | `mix test test/mailglass_admin/preview_live_test.exs` | REQUIRED | exists, rework |
| BRPIPE-02 | Computed `--color-base-100` and `color-scheme` equal `<html>`'s on shell, pane, `#mg-copy-toast`, modal across the cookie x OS matrix; picker round trip; no-JS first response; iframe isolation; forced colors outline | browser | `npx playwright test ... e2e/theme-ownership.spec.js` | ADVISORY (`operator_browser_gate`) | Wave 0 |
| BRPIPE-03 | Manifest shape; each listed file exists with the recorded sha256 and valid PNG header; no unlisted file; `git_sha` 40-hex (ancestor when the clone is full); `dirty == false`; count <= 80 and bytes <= 15 MB; `nested_theme_attr_count == 0` | unit (reads the committed catalog dir) | `mix test test/mailglass_admin/before_catalog_manifest_test.exs` | REQUIRED, only if the catalog lands in the same PR (F8) | Wave 0 |
| BRPIPE-03 | Capture determinism self-test (same shot twice identical), clean-tree refusal, served-bytes equality | script self-checks inside the capture run | the committed capture script | the run itself is not CI; the manifest test is the required proof | Wave 0 |

### Mutation checks (each must be shown red, then restored)
- Delete `@source not inline("prose");` -> `--check` red with `{:drift, 139137, 136877, 74051}`.
- Flip one byte / truncate / delete the committed copy (hermetic) -> red naming the fix command.
- Plant `tracking-widest` in a tmp `lib/` copy -> red (136,992 bytes observed).
- Remove the `--check` step from the alias, or the job from `ci_green.needs` (tmp copy of the text) -> wiring assertion red.
- Plant `data-theme="mailglass-light"` in a tmp copy of a lib template, and a `style="--color-base-100: #fff"` / `[--mg-color-background:#fff]` class -> ownership grep red.
- Re-introduce `theme_attr` into `AdminShell` (scratch) -> the document-count test red.
- Manifest: flip a PNG byte, add an unlisted PNG, set `dirty: true`, exceed the byte cap -> red.

### Sampling Rate
- **Per task commit:** `mix mailglass_admin.assets.build --check` (about a second) and the touched contract file.
- **Per wave merge:** `cd mailglass_admin && mix verify.support_contract.admin`, then `mix format --check-formatted` inside `mailglass_admin` (the CI format gate is root-only; baseline is clean, exit 0).
- **Phase gate:** full suite green, then the advisory browser spec and the reworked e2e files locally (`npm run test:operator-browser -- e2e/theme-ownership.spec.js ...` also rebuilds the bundle; after D-03 that is byte-identical), then `bash scripts/gsd-regression-gate.sh`.

### Wave 0 Gaps
- [ ] `test/mailglass_admin/bundle_reproducibility_contract_test.exs` - BRPIPE-01
- [ ] `test/mailglass_admin/root_theme_ownership_contract_test.exs` - BRPIPE-02 (red first)
- [ ] `test/mailglass_admin/before_catalog_manifest_test.exs` - BRPIPE-03
- [ ] `e2e/theme-ownership.spec.js` (+ optional `e2e/support/theme.cjs`) - BRPIPE-02 browser
- [ ] `dev/mailglass_admin/assets_check.ex` (or inline in the task) - BRPIPE-01
- [ ] `reference/demo_app/lib/mailglass_demo/catalog_seed.ex` and the capture spec/config outside `./e2e` - BRPIPE-03
- No framework install needed.

### Rework inventory for BRPIPE-02 (planner reads this as the task list)

**lib (6 sites plus docs):** `admin_shell.ex:16` (`attr(:theme_attr, :string, default: nil)`) and `:33` (`data-theme={@theme_attr}`); `operator/shell.ex:198` (`theme_attr={Theme.data_theme(@theme_choice)}`); `preview_live.ex:318` (`theme_attr={admin_theme_attr(@admin_chrome_theme)}`) and `:740` (`defp admin_theme_attr(theme), do: MailglassAdmin.Theme.data_theme(theme)`); `preview/tabs.ex:66` (`data-theme={preview_frame_data_theme_attr(tab, @preview_frame_dark_chrome)}`) and helper lines 183-186; `gallery_live.ex:138` and `:148` plus moduledoc line 10. Keep `layouts/root.html.heex:2` (`<html lang="en" data-theme={root_theme(assigns)}>`), `theme.ex:51-53` (`def data_theme(:dark), do: "mailglass-dark"`, `def data_theme(:light), do: "mailglass-light"`, `def data_theme(_choice), do: nil`).
**ExUnit to rework:** `admin_shell_test.exs:17` (passes `theme_attr="mailglass-dark"`; an undeclared attr after removal is a compile warning, and CI runs `mix test --warnings-as-errors`) and `:38`; `preview_live_test.exs:96` (`preview_pane_attrs` reads `data-theme`), `:991`, `:1028-1043` (test named "does not mutate admin shell data-theme"), `:1056`, `:1065`, `:1069`, `:1072`. Stay green unchanged: `router_test.exs:198,207,216,227`, `operator_live_test.exs:2760,2777`, `inbound_live_test.exs:2665,2683`, `components_test.exs:953`, `brand_test.exs:77`, `token_parity_test.exs` (bundle selectors; the gallery moduledoc must keep the substring `/dev/mail/gallery`, token_parity_test.exs:200).
**e2e to rework:** `phase168-plan03-acceptance.spec.js:29,36,39,45,54,61` (shell attrs) and the six `-system` testid reads (81, 103, 105, 116, 118, 135); `flows.spec.js:827,831,863,869` (frame toggle), `:1296-1327` (picker asserts `.mg-admin-root`), `:1336-1380`, `:2343`; `structural.spec.js:446,453-465,1509-1522,1525-1536,1672-1691,1724-1730,1805-1809,2184,2465-2466,2505-2570,2990-3193,3467`; `gallery-matrix.spec.js` (the whole `themeWrapper` machinery, lines 16-18, 77-80, 128-148, 225-259); demo `persona-screenshots.spec.js:203`. Stay green: `admin-assets.spec.js:296-300` (`html` `data-theme` dark), `phase176-filters.spec.js:372` (`.first()` resolves to `<html>`), Storybook specs (own wrappers).
Recommended low-churn approach for the gallery specs: keep the single remaining specimen's existing `data-testid="gallery-{component}-{state}-system"` so those testids need no rename, and drive themes with an outer per-theme loop (cookie + `emulateMedia` + `goto`) instead of three wrappers in one page.

## Security Domain

`security_enforcement` is absent in `.planning/config.json`, so it is treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (capture logs in through the existing `/demo/login`; no new auth) | existing |
| V3 Session Management | marginal: theme cookie is `http_only`, `same_site: "Lax"`, `path: "/"` (theme.ex `cookie_opts`); unchanged | existing |
| V4 Access Control | no | existing operator auth |
| V5 Input Validation | yes: capture script env and URLs; manifest filenames | reuse `evidenceOrigin` allow-list (`127.0.0.1`, `localhost`, `demo`) and the run-id regex; filename slug regex `[a-z0-9_.-]+` and no path separators when promoting |
| V6 Cryptography | yes (integrity only): sha256 of PNGs and bundle | `:crypto.hash(:sha256, ...)` / Node `crypto`; do not hand-roll |
| V14 Configuration / supply chain | yes: standalone Tailwind binary is downloaded over HTTPS by the Hex runner without checksum verification | accept (existing posture); optional hardening is to compare against the vendor `sha256sums.txt`, which needs a pinned value and is a separate decision |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered or hand-edited committed bundle | Tampering | The byte-for-byte `--check` against a fresh pinned build (not a committed hash) |
| Poisoned Tailwind binary download | Tampering | Existing `verify_peer` TLS in `Tailwind.fetch_body!`; sha256 cross-check performed this session (match); fail closed on any fetch error |
| Destructive reset against a non-evidence demo | Tampering / DoS | `resetDisposableEvidence` guard (explicit loopback origin, project-id header match, token) |
| Catalog clobber or half-written commit | Tampering | stage in the git-ignored `.cache/`, validate, atomic rename, refuse existing `catalog_id` |
| Secrets or PII in evidence | Information disclosure | Fixtures are synthetic `*.example` addresses; the manifest must not record env values or the reset token; no telemetry metadata is touched (CLAUDE.md no-PII rule unaffected) |
| Path traversal through manifest `file` names | Tampering | validate slug filenames and confine reads to the catalog directory in the ExUnit validator |

## Sources

### Primary (HIGH confidence)
- Repository files read this session (paths and line ranges are cited inline): `mailglass_admin/{config/config.exs, mix.exs, assets/css/app.css, lib/mix/tasks/mailglass_admin.assets.build.ex, lib/mailglass_admin/{admin_shell,gallery_live,preview_live,theme,layouts}.ex, layouts/root.html.heex, preview/tabs.ex, controllers/assets.ex, router.ex, scripts/check-conformance.sh, package.json, e2e/*.spec.js, test/mailglass_admin/*}`, `mailglass_admin/deps/tailwind/lib/{tailwind.ex,mix/tasks/tailwind.ex}`, `.github/workflows/ci.yml`, `config/quality/ci_policy.exs`, `release-please-config.json`, `scripts/{check_test_exceptions.sh,check_coverage_floor.sh,guard_release_trigger.sh,run_demo_browser_evidence.sh,gsd-regression-gate.sh}`, `compose.demo.yml`, `Makefile`, `reference/demo_app/{lib/mailglass_demo/demo_data.ex,assets/e2e/persona-screenshots.spec.js,assets/playwright.config.cjs,assets/scripts/*}`, `reference/persona_spec/personas.ex`, `.planning/METHODOLOGY.md`, `.planning/research/brand-v2-adoption/LENS-FINDINGS.md`.
- Commands and probes run this session: Tailwind CLI and `mix run` builds in scratch copies; Linux amd64 container build; ExUnit probe counting `data-theme=`; Playwright probes of iframe `color-scheme` (Chromium, WebKit), of the before-state computed tokens, and of capture determinism; local demo up/health/served-CSS hashing; `git check-ignore -v`; `guard_path_is_non_shippable`; `mix compile --force --warnings-as-errors`.

### Secondary (MEDIUM confidence)
- [CITED: https://tailwindcss.com/docs/detecting-classes-in-source-files] `@source not` and `@source not inline()` syntax and semantics (fetched this session; introduction version not stated on the page).

### Tertiary (LOW confidence)
- None used.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new; versions read from config and deps.
- Architecture: HIGH for BRPIPE-01/02 (measured end to end); MEDIUM for BRPIPE-03 (subset run).
- Pitfalls: HIGH where marked VERIFIED; the alias cold-compile (P12), coverage slack (P4) and Firefox (A5) remain assumptions.

**Research date:** 2026-11-14
**Valid until:** 2026-11-28 (the bundle bytes, the `phase 179` copy strings and the e2e line numbers change with every UI commit; re-run the `--check` prototype and re-grep line numbers before planning if `main` moves).

Scratch artifacts (not in the repo): `/private/tmp/claude-501/-Users-jon-projects-mailglass/c2eb3208-4d12-4236-85e5-cfde43065f08/scratchpad/` (prototype `proto_check2.exs`, probes, built CSS variants). Working tree was clean before and after; the only change is this file. Not committed (the commit policy for this session is "only when asked").
