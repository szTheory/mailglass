# Adoption Mechanics — v1.10 Brand Adoption

**Scope:** ex_doc logo wiring, release-please trigger safety, GitHub social preview, SVG→PNG export, full reference sweep.
**Researched:** 2026-06-12
**Out of scope (already settled in v1.9 research — do not redo):** GitHub README SVG rendering rules, email HTML, brand/token/logo decisions.

---

## 1. ex_doc logo/assets config (pinned version: 0.40.1)

### Pinned version evidence

| Package | mix.exs constraint | Lockfile resolution |
|---|---|---|
| `mailglass` (root) | `{:ex_doc, "~> 0.40", only: :dev, runtime: false}` — `mix.exs:183` | 0.40.1 (`mix.lock`) |
| `mailglass_admin` | same — `mailglass_admin/mix.exs:114` | 0.40.1 (`mailglass_admin/mix.lock`) |
| `mailglass_inbound` | same — `mailglass_inbound/mix.exs:110` | 0.40.1 (`mailglass_inbound/mix.lock`) |

All three `docs:` configs exist already (root `mix.exs:355-461`, `mailglass_admin/mix.exs:214-240`, `mailglass_inbound/mix.exs:141-189`). **None sets `logo:`, `favicon:`, or `assets:` today.**

### Verified 0.40.1 option semantics (HIGH confidence — fetched from ex-doc.hexdocs.pm/0.40.1/ExDoc.html)

| Option | 0.40.1 behavior (verbatim from version-pinned docs) |
|---|---|
| `logo:` | "Must be PNG, JPEG or SVG." — **SVG is supported.** "The image will be shown within a 48x48px area. If using SVG, ensure appropriate width, height and viewBox attributes are present in order to ensure predictable sizing and cropping." Copied to output `assets/logo.EXTENSION`. |
| `favicon:` | **Exists in 0.40.1.** "Must be PNG, JPEG or SVG." Copied to output `assets/favicon.EXTENSION`. |
| `assets:` | "A map of source => target directories that will be copied as is to the output path. It defaults to an empty map." Not needed for logo/favicon — those auto-copy. |

### Critical gap found in the fable SVGs

`brandbook-fable/assets/logo-mark.svg` (root element: `viewBox="-12 32 164 156"`, **no `width`/`height` attributes**) and `brandbook-fable/assets/favicon.svg` (`viewBox="0 0 16 16"`, **no `width`/`height`**) both violate ex_doc 0.40.1's explicit SVG requirement. **The adoption milestone must add explicit `width`/`height` to whichever SVGs get wired into `logo:`/`favicon:`** (either on the canonical assets or on ex_doc-dedicated copies). The og-card and other examples are unaffected.

### Logo shape recommendation

Use the **square mark** (`logo-mark.svg`, ~164×156 viewBox — near-square) for `logo:`. The 48×48px display area makes the lockup (`logo-primary.svg`), typemark, and with-tagline variants illegible — anti-recommended. Use `favicon.svg` (purpose-drawn 16-unit grid) for `favicon:`.

### Path resolution for the sub-packages

`mix docs` (and `mix hex.publish`'s doc build) resolves `logo:`/`favicon:` paths **relative to the cwd = the package directory**:

- Root package: `logo: "brandbook/assets/logo-mark.svg"`, `favicon: "brandbook/assets/favicon.svg"`
- `mailglass_admin` / `mailglass_inbound`: `logo: "../brandbook/assets/logo-mark.svg"` etc.

**Recommendation: relative paths into the canonical `brandbook/`, no per-package copies.** Rationale:
1. Docs are only ever built from the monorepo checkout (locally and in `publish-hex.yml`'s full-repo checkout) — `../` resolves fine at build time.
2. ex_doc copies the file into the doc output, so the Hex tarballs do **not** need the file; no `files:` allowlist change required (root `mix.exs:345-353`, admin `:210`, inbound `:137` all stay untouched).
3. This satisfies the standing brand-audit constraint "no broad `brandbook/` inclusion in packages, deliberate exact asset use only" (`brandbook/brand-audit.md:125`) with zero drift risk across three copies.
4. Known tradeoff (accepted): `mix docs` from an unpacked Hex tarball alone would fail to find `../brandbook/` — nobody builds docs that way for these packages; HexDocs ships the prebuilt output.

**Latency caveat for the roadmap:** HexDocs only re-renders on the next `hex.publish`. Wiring `logo:`/`favicon:` in mix.exs is inert on hexdocs.pm until the next release of each package (currently 1.5.1/1.5.1/1.3.0, quiet maintenance). If the milestone wants the logo *visible* on HexDocs, it needs a release — which drags the inbound exact-pin (paired inbound release) per the standard release gotchas. Otherwise the config simply rides the next natural release.

### Existing in-app admin logo (adjacent, decide explicitly)

The admin dashboard already ships a wordmark at `mailglass_admin/priv/static/mailglass-logo.svg`, compiled in at `mailglass_admin/lib/mailglass_admin/controllers/assets.ex:85-87` (`@logo File.read!`), served at `<mount>/logo.svg` (`router.ex:283`), rendered by `Components.logo/1` (`components.ex:58-61`) in the operator shell (`operator/shell.ex:124,154`). Swapping this to the fable identity is a natural part of "propagate the identity" but is a **package code change** (recompile + the `git diff --exit-code priv/static/` bundle gate in `verify.preview`, `mailglass_admin/mix.exs:183-188`) and only reaches adopters via a release. Planners should scope it in or explicitly defer it — don't let it fall through silently.

---

## 2. release-please trigger safety

### Config evidence

`release-please-config.json` (whole file read):
- Three packages: `"."` → mailglass, `"mailglass_admin"`, `"mailglass_inbound"`, all `"release-type": "elixir"`.
- One plugin: `linked-versions` grouping **mailglass + mailglass_admin only** (inbound unlinked).
- **No `changelog-sections`, no `bump-minor-pre-major`, no type overrides** → release-please defaults apply: only `feat` (minor), `fix` (patch), and any `!`/`BREAKING CHANGE` (major) propose version bumps. `docs:` and `chore:` are non-bumping and hidden from the changelog.

In-repo confirmation of that default, written by this project's own maintainers: `mailglass_inbound/mix.exs:119-123` — "Bumping this pin must land as a `fix(inbound):` commit — chore/docs commits do NOT trigger a Release Please inbound bump."

### Does the config "watch" mix.exs specially?

No. release-please attributes commits to packages purely by **file path prefix** (package directory); the elixir release-type then rewrites the `@version`/`version:` line in that package's mix.exs *when cutting a release PR*. There is no content-level watching of mix.exs — a commit touching only the `docs/0` private function is classified solely by its conventional-commit **type**. (Note: the root `"."` package path matches every file, so sub-package commits also attribute to core — irrelevant here because the type is non-bumping either way.)

### Verdict: release-safe

**A `docs:` or `chore:` commit adding `logo:`/`favicon:` to any of the three mix.exs files proposes no version bump and creates no release PR.** Supporting facts:

- `pr-title.yml:21-32` allowlists both `docs` and `chore` types (squash-merge → PR title becomes the commit message release-please parses).
- The release-please sed sync step (`release-please.yml:139-263`) only rewrites `{:mailglass, "== x.y.z"}` pin lines and README install pins — adding a `logo:` key cannot collide with its anchor regex (`release-please.yml:177-184`).
- `ci.yml:6-13` `paths-ignore` covers only `.planning/**` and `prompts/**` — brandbook/mix.exs/README changes **do** run CI normally (no silently-skipped-required-checks gotcha for this milestone's commits; the known gotcha only bites PRs touching *exclusively* `.planning`/`prompts`).

Recommended commit shapes: `docs: wire brandbook logo + favicon into ex_doc config` (mix.exs edits), `chore: adopt brandbook-fable as canonical brandbook` (the git mv), `docs(readme): adopt brand header` — all non-bumping.

---

## 3. GitHub repo social preview (verified 2026-06)

From the official GitHub doc (fetched): **PNG, JPG, or GIF; under 1 MB; "at least 640 by 320 pixels (1280 by 640 pixels for best display)"** — i.e. a 2:1 aspect target.

**Upload path: Settings UI only.** There is **no write API** — confirmed honestly: GitHub community discussions #52294 and #172072 both conclude no REST/GraphQL endpoint exists to *set* the social preview; the API surface is read-only (`openGraphImageUrl` / `usesCustomOpenGraphImage` via GraphQL, `social_preview_image_url` in some REST payloads). `gh api` cannot do it. The milestone should ship the PNG in-repo plus a documented manual upload step (PROJECT.md:17 already anticipates "documented GitHub social-preview upload steps" — that's the correct and only mechanization level).

**Aspect-ratio note for planners:** PROJECT.md:17 locks the og-card export at **1200×630** (the standard 1.91:1 OG size; `brandbook-fable/examples/og-card.svg` has `viewBox="0 0 1200 630"`). GitHub's "best display" is 2:1 (1280×640), so GitHub will scale/letterbox the 1.91:1 image very slightly. This is normal (most repos upload 1200×630) and not worth recomposing the card. To exceed the 1280×640 "best display" threshold while keeping the locked aspect, **export at 2x: 2400×1260** — still a small flat-vector PNG, comfortably under 1 MB, crisp at every downscale.

---

## 4. SVG→PNG export without Node toolchain (this machine, verified)

Tool availability checked in this environment:

| Tool | Status | Verdict |
|---|---|---|
| **Playwright (Chromium)** | **Installed — `npx playwright --version` → 1.60.0, no fetch needed** | **Recommended.** Browser-true rendering (exactly what GitHub/Twitter renderers see); already an established project dependency (preview capture, demo browser evidence). |
| `rsvg-convert` | Not installed (`brew install librsvg` would add it) | Best pure-CLI fidelity if you want a no-browser path; one new brew dep. Second choice. |
| ImageMagick `magick` | Installed (`/opt/homebrew/bin/magick`) but `magick -list format` shows SVG handled by the **internal MSVG/libxml renderer ("XML 2.9.13"), not the librsvg delegate** | Risky fidelity (known path/clip/filter bugs). Use only with visual verification. Third choice. |
| `sips` | Installed | **Not viable** — no SVG decoder. |
| `qlmanage` | Installed | **Not viable for exact dims** — thumbnail generator, fits-within-square sizing, no 1200×630 control. |

**Recommended reproducible command** (the og-card SVG has `viewBox` only, no intrinsic width/height, so as a top-level document it fills the Chromium viewport exactly — viewport size IS the export size):

```bash
# 2x export (2400×1260) — exceeds GitHub's 1280×640 "best display" floor
npx playwright screenshot --viewport-size=2400,1260 \
  "file://$PWD/brandbook/examples/og-card.svg" \
  brandbook/examples/og-card.png
```

(Use `--viewport-size=1200,630` if the milestone insists on literal 1200×630.) Font considerations: none — all v1.9 SVGs are outlined paths per LOGO-08, so Chromium-vs-librsvg font substitution is moot. Determinism note: the screenshot is pixel-stable for a given Chromium version; if the export is ever wrapped in a verification gate, compare dimensions + visual diff, not byte-hash, across Playwright upgrades.

Repo-policy check: "no Node toolchain anywhere" governs the shipped packages/build; the repo already invokes `npx playwright` for maintainer-side evidence capture (e.g. `verify.demo_browser_evidence`), so this is consistent, and the PNG is a committed artifact — adopters never run the export.

---

## 5. Reference sweep (exhaustive)

Method: `git ls-files` grep for `brandbook` across **all tracked files** outside `.planning/` and the two brandbook dirs → exactly **one file** matched (CLAUDE.md). Separate grep for the `prompts/mailglass-brand-book.md` source-of-truth pointer. Both spellings (`brandbook/`, `brandbook-fable/`) covered.

### Must touch

| File:line | Current content | Action |
|---|---|---|
| `CLAUDE.md:17` | Current-state paragraph: "brandbook-fable/ is the maintainer-approved A/B winner… Next milestone candidate: A/B winner adoption (fold brandbook-fable/ into canonical brandbook/…)" | Update — rewrite current-state at milestone close (standard practice). |
| `CLAUDE.md:62` | "Source of truth: `prompts/mailglass-brand-book.md`." (Brand & Voice section) | Update → `brandbook/brand-book.md` (locked by PROJECT.md:19). |
| `mailglass_admin/docs/design-system.md:5` | "…`prompts/mailglass-brand-book.md`; this doc covers the *mechanics*…" | Update pointer → `brandbook/brand-book.md`. NOTE: this file ships in the Hex tarball + HexDocs extras (`mailglass_admin/mix.exs:210,221`) — `docs:` commit is release-safe (§2); the change reaches HexDocs at next release. |
| `README.md` (root) | No brandbook reference today (text-only header, badges at lines 5-8) | **Add** `brandbook/examples/readme-header.svg` per PROJECT.md:17 (v1.9 already settled the SVG-rendering rules — don't re-research). |
| `brandbook-fable/` → `brandbook/` | **Zero self-references to either folder spelling inside `brandbook-fable/`** (grep verified) | Clean `git mv` — no internal path rewrites needed. Old codex `brandbook/` deleted (history preserves it at frozen baseline `09a84dd4`). |
| `mix.exs:355` (root `docs/0`), `mailglass_admin/mix.exs:214`, `mailglass_inbound/mix.exs:141` | No `logo:`/`favicon:` keys | Add per §1 (after adding width/height to the SVGs). |

### Decide explicitly (in-scope candidates, not pre-committed)

| File:line | What | Note |
|---|---|---|
| `mailglass_admin/priv/static/mailglass-logo.svg` + `controllers/assets.ex:85-87` + `components.ex:58-61` + `operator/shell.ex:124,154` | Shipped admin-UI wordmark | Swap-or-defer decision (§1, bundle-drift gate applies). |
| `.planning/PROJECT.md:458` (D-19) | Decision record locks brand identity to `prompts/mailglass-brand-book.md` | Supersede/amend D-19 to point at `brandbook/brand-book.md` as part of milestone bookkeeping. |

### Leave untouched

| Path | Why |
|---|---|
| `.planning/milestones/**` (v0.1, v1.4, v1.6–v1.9 phase archives, all hits listed in sweep) | Historical archives — explicitly out of scope. |
| `.planning/research/v1.9-brandbook-fable/**`, `v1.7-*/`, `v0.1-research/` | Historical research records. |
| `.planning/todos/completed/**` | Historical. |
| `prompts/mailglass-brand-book.md` itself | Stays as prompt-era historical source; only *pointers* move (PROJECT.md:19). |
| `mailglass_admin/doc/design-system.md` | Generated ex_doc output, **gitignored** (verified with `git check-ignore`). |
| `reference/host_app/deps/mailglass_admin/docs/design-system.md`, `reference/demo_app/deps/...` | Vendored Hex deps of the FROZEN deterministic baselines — only change on a coordinated baseline pin bump, never in this milestone. |
| `.planning/PROJECT.md`, `ROADMAP.md`, `STATE.md` brandbook-fable mentions | Managed by the GSD milestone process itself, not manual sweep targets. |

### Sweep guarantee

Outside `.planning/` and the brandbook folders, **CLAUDE.md is the only tracked file containing the string "brandbook"**, and `CLAUDE.md:62` + `mailglass_admin/docs/design-system.md:5` are the only tracked active-surface pointers to `prompts/mailglass-brand-book.md`. No workflow, script, Makefile, mix.exs, guide, or lib file references either brandbook path today — the rename has zero blast radius in code/CI.

---

## Confidence

| Area | Level | Basis |
|---|---|---|
| ex_doc 0.40.1 options | HIGH | Version-pinned hexdocs (ex-doc.hexdocs.pm/0.40.1/ExDoc.html) + lockfile evidence |
| release-please safety | HIGH | Actual config + workflow files read; defaults corroborated by in-repo maintainer comment (`mailglass_inbound/mix.exs:119-123`) |
| Social preview specs / no-API | HIGH (specs) / MEDIUM-HIGH (no write API — official doc silent, two community discussions concur; absence-of-feature claims capped) |
| SVG→PNG tooling | HIGH | Tools probed on this machine; Playwright 1.60.0 confirmed installed |
| Reference sweep | HIGH | `git ls-files`-based exhaustive grep, both spellings + prompts pointer |

## Sources

- https://ex-doc.hexdocs.pm/0.40.1/ExDoc.html (version-pinned `logo:`/`favicon:`/`assets:` semantics)
- https://ex-doc.hexdocs.pm/0.40.1/Mix.Tasks.Docs.html
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview
- https://github.com/orgs/community/discussions/52294 , https://github.com/orgs/community/discussions/172072 (no social-preview write API)
- Repo files: `mix.exs`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs`, three `mix.lock`s, `release-please-config.json`, `.github/workflows/release-please.yml`, `.github/workflows/pr-title.yml`, `.github/workflows/ci.yml`, `brandbook-fable/assets/*.svg`, `brandbook-fable/examples/og-card.svg`
