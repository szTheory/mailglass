# Pitfalls & Portability — v1.9 Brand Book Fable

**Scope:** SVG/HTML portability, email-client-safe HTML, AI-cliché screening for `brandbook-fable/`
**Researched:** 2026-06-11
**Downstream consumers:** Phase 85 differentiation brief, Phase 87-89 executors, Phase 90 quality gate
**Overall confidence:** HIGH on GitHub SVG behavior and email rules (multiple corroborating sources + prior v1.8 failure evidence); MEDIUM on Safari-specific SVG media-query behavior and Gmail dark-mode internals (client behavior churns).

## Summary

The three known v1.8 failures (live `<text>` with macOS-only font, planning-language in `tokens.json`, undemonstrated dark tokens) are all instances of one root cause: **artifacts that look correct in the authoring environment but were never verified in the consuming environment.** The consuming environments for this milestone are: GitHub's `<img>`-mode SVG sandbox (no external resources, no fonts, no scripts, `currentColor` resolves to black), a browser opening `index.html` from `file://` (no fetch, no modules, flaky localStorage), email clients (no SVG support at all, three incompatible dark-mode models), and social-card crawlers (no SVG support, period).

Four hard rules fall out of the research:

1. **Every SVG ships with outlined paths, a `viewBox`, no `font-family`, no `foreignObject`, no `url(#id)` refs that could collide, and explicit fills (never bare `currentColor` as the only color source).** This is the only way an SVG renders identically in GitHub READMEs, the GitHub blob viewer, `file://` HTML, and `<img>` embeds.
2. **`index.html` must be one file that needs zero fetches.** Tokens demonstrated in it must be inlined (duplicated from `tokens.css` and checked for drift by the Phase 90 gate, not loaded at runtime).
3. **The email specimen is a different universe:** tables, inline styles, web-safe fonts only (Inter will never load in email), no SVG images, `color-scheme` meta, and acceptance that Gmail will force-transform colors anyway.
4. **The OG card SVG is a source/template artifact, not a functional og:image.** No platform renders SVG og:images; ship it with a documented manual PNG export path (1200×630) and say so in the file's own comments and the brand book.

The honest font story: **Inter is not preinstalled on any major OS.** Most viewers of the brand book will see their system UI font. The stack must be written as `Inter (when available) → system-ui → platform fallbacks`, the design must not depend on Inter metrics, and the brand book should state this plainly rather than pretending Inter is guaranteed.

## Pitfall Register

Each entry: **warning sign → prevention → enforcing phase.** Phases: 85 (differentiation brief), 86 (foundations/tokens), 87 (logo tournament), 88 (standalone HTML brand book), 89 (collateral: email/OG/README/diagram SVGs), 90 (scripted quality gate).

### SVG portability

**P-01. Live `<text>` with a non-universal font (the v1.8 failure, generalized).**
- *Warning sign:* any `<text>`, `<tspan>`, or `font-family` attribute/property anywhere in a shipped SVG — even with a "safe" font, metrics differ per OS and break alignment.
- *Prevention:* winner logos and all specimen SVGs ship as **outlined paths only**. Where a specimen must show type (typography page SVGs), either outline it or accept system-font substitution and design with generous bounding boxes — never pixel-tight alignment around live text.
- *Enforce:* Phase 87 (produce outlined), Phase 90 gate: `grep -rl 'font-family\|<text' brandbook-fable/assets/` must return nothing for logo/icon assets; specimen SVGs that intentionally use live text are an explicit allowlist with rationale.

**P-02. `currentColor` as the only fill in an `<img>`-context SVG.**
- *Warning sign:* logo SVG uses `fill="currentColor"` expecting the page to tint it. In `<img>` context (which is how GitHub and `<img src>` in `index.html` render SVG files), the SVG cannot inherit the parent document's color — `currentColor` resolves to the initial value (black).
- *Prevention:* file-based SVG assets carry explicit hex fills. Ship explicit light-surface and dark-surface variants (e.g., `logo-primary.svg` + `logo-primary-dark.svg`) instead of one "adaptive" file. `currentColor` is fine **only** for SVG markup inlined directly into `index.html`.
- *Enforce:* Phase 87/89 authoring rule; Phase 90 gate greps standalone asset files for `currentColor`.

**P-03. `prefers-color-scheme` media query inside an SVG treated as the GitHub dark-mode solution.**
- *Warning sign:* one SVG with `<style>@media (prefers-color-scheme: dark){...}</style>` and a README claim that it adapts on GitHub.
- *Reality:* it tracks the **OS** preference, not the user's chosen GitHub theme (a system-light user with GitHub dark theme gets the light artwork on a dark page); historically unreliable in Safari's `<img>` context. GitHub's supported mechanism is the `<picture>` element with `media="(prefers-color-scheme: dark)"` sources — which has the same OS-vs-GitHub-theme caveat but is the documented path. The old `#gh-dark-mode-only` fragment hack is dead; do not use it.
- *Prevention:* default all README-facing marks to a **single design that survives both light and dark backgrounds** (this is also a logo-quality forcing function); use `<picture>` two-variant swaps only where a single design genuinely can't work. Document the OS-vs-GitHub-theme caveat in the brand book usage section.
- *Enforce:* Phase 87 (dark/light survivability is a tournament judging axis), Phase 89 (README specimens use `<picture>` correctly), Phase 90 (render check on dark background per existing milestone gate).

**P-04. Unique-ID collisions when multiple SVGs are inlined into `index.html`.**
- *Warning sign:* two inlined SVGs both define `id="a"` / `id="grad1"` in `<defs>`; `url(#a)` resolves to the **first** matching ID in the whole document, so the second SVG silently renders with the first SVG's gradient/clip-path/mask. Classic with optimizer output (SVGO minifies IDs to `a`, `b`, `c`).
- *Prevention:* prefer flat explicit fills with **no `<defs>`/IDs at all** in brand marks (also kills the gradient-mesh cliché, see P-22). Where an ID is unavoidable, prefix it with the asset slug (`fable-logo-primary-clip1`). If any optimizer pass is used, configure deterministic prefixed IDs.
- *Enforce:* Phase 88 (inlining), Phase 90 gate: script extracts all `id=` values across `index.html` and fails on duplicates.

**P-05. Missing `viewBox` or hardcoded width/height only.**
- *Warning sign:* SVG with `width="200" height="60"` and no `viewBox` — it won't scale in `<img>` contexts, and GitHub/README sizing breaks.
- *Prevention:* every SVG has `viewBox`; width/height optional (useful as intrinsic size hints). Aspect ratio of `viewBox` matches the artwork bounds (no dead whitespace baked in — clearspace is documented, not encoded).
- *Enforce:* Phase 90 gate: assert `viewBox` present on every root `<svg>`.

**P-06. `foreignObject`, `<script>`, event handlers, or external refs (`<image href>`, `@import`, `xlink:href` to other files) in assets.**
- *Warning sign:* any of these in an asset file. In `<img>`/secure-static mode (GitHub README, `<img src>` anywhere) browsers disable scripts, block all external resource fetches (including fonts and stylesheets), and disable `foreignObject` content. The asset renders blank or partially.
- *Prevention:* assets are pure vector markup: paths, shapes, groups, internal `<style>` at most. Everything self-contained.
- *Enforce:* Phase 90 gate greps for `foreignObject|<script|href="http|@import|onload=` in `brandbook-fable/**/*.svg`.

**P-07. SVG accessibility omitted (or done in the wrong layer).**
- *Warning sign:* no `<title>`, no `role`, and README `<img>` tags without `alt`.
- *Prevention:* two layers. (a) In each SVG file: `role="img"` on root, `<title>` as **first child** with an `id`, `aria-labelledby` pointing at it; `<desc>` only for genuinely complex diagrams. (b) In every consuming context (`README` specimens, `index.html` `<img>`s): meaningful `alt` text — the `alt` is what GitHub actually exposes, the in-file title is what `file://`/direct-open exposes. Decorative inline SVGs in `index.html` get `aria-hidden="true"` instead.
- *Enforce:* Phase 87/89 authoring; Phase 90 gate asserts `<title` and `role="img"` in every named asset SVG.

**P-08. Trusting the GitHub blob-viewer preview as the rendering truth.**
- *Warning sign:* "looks right when I click the file on GitHub" used as sign-off. The blob viewer runs GitHub's HTML sanitizer over the SVG and has stripped layout-relevant attributes (e.g., `dominant-baseline`) in the past — it can render *differently* from the README `<img>` context.
- *Prevention:* verification contexts are (1) README-embedded `<img>` on github.com, (2) direct browser open from disk, (3) inlined in `index.html`. The blob preview is informational only. Outlined-path-only assets (P-01) make all four converge anyway.
- *Enforce:* Phase 90 verification protocol lists the three canonical contexts.

### Self-contained HTML (`index.html`)

**P-09. Pretending Inter renders when webfonts are banned.**
- *Warning sign:* `font-family: Inter, sans-serif` with the design reviewed only on a machine that has Inter installed (the v1.8 macOS-Avenir failure in CSS form). **Inter ships preinstalled on no major OS** — for almost every viewer, the page renders in their system font.
- *Prevention:* use the honest stacks (see "Self-Contained HTML Rules" below), state in the brand book that Inter is the brand face *when installed/embedded* and `system-ui` is the honest default, and review the page once with Inter deactivated (or in a VM/container without it).
- *Enforce:* Phase 86 (token definition uses the full stacks), Phase 88 (no-Inter render check), Phase 90 gate greps that no `font-family` declaration ends at `Inter` without the system chain, and that no `@font-face`/`fonts.googleapis` appears anywhere.

**P-10. Runtime `fetch()` of `tokens.json`/`tokens.css` breaks on `file://`.**
- *Warning sign:* `index.html` does `fetch('tokens.json')` or uses `<script type="module" src=...>`. On `file://`, fetch/XHR are blocked by opaque-origin CORS and ES-module loading from `file://` is blocked in Chromium. The page works on a dev server and breaks from disk.
- *Prevention:* `index.html` is fully self-contained: tokens inlined as CSS custom properties in a `<style>` block, all script inline classic `<script>` (no modules), all SVG inlined or referenced via relative `<img src>` (plain subresource loads — `<img>`, `<link rel=stylesheet>` with relative paths — do still work on `file://`; only programmatic fetch dies). If both `tokens.css` and inlined copies exist, the gate diffs them.
- *Enforce:* Phase 88 architecture decision; Phase 90 gate greps for `fetch(|XMLHttpRequest|type="module"` and runs the existing local-only-references check; verification protocol includes opening via `file://` path, not `localhost`.

**P-11. Dark-mode toggle and `prefers-color-scheme` fighting each other (and dark never demonstrated — the v1.8 gap).**
- *Warning sign:* either (a) only a manual toggle that ignores OS preference, (b) only a media query with no toggle, or (c) a toggle that sets classes which lose specificity battles against `@media` rules.
- *Prevention:* the standard three-state pattern, all in inline CSS/JS: tokens defined twice — once under `:root` (light), once under `:root[data-theme="dark"]` **and** under `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }`. Toggle cycles auto → light → dark by setting/removing `data-theme`. Because all colors flow through custom properties, the two dark definitions are one shared block. Persist with `localStorage` in a `try/catch` (localStorage on `file://` is flaky/partitioned in some browsers) and degrade to session-only without error. Set `color-scheme: light dark` on `:root` so form controls/scrollbars follow.
- *Enforce:* Phase 86 (token structure supports it), Phase 88 (implements it), Phase 90 dark render check **screenshots/audits the dark state explicitly** — dark tokens existing but undemonstrated is the named v1.8 failure.

**P-12. Page prints as a dark slab or with colors stripped.**
- *Warning sign:* no `@media print` rules; printing the brand book from a dark-mode browser yields black backgrounds across pages (ink disaster) or, conversely, browsers strip all background colors and the palette/contrast-matrix sections print as empty white boxes.
- *Prevention:* `@media print { :root { /* force light token values */ } }` plus `print-color-adjust: exact` on palette swatches, the contrast matrix, and component-gallery chips specifically (not globally). Avoid relying on `box-shadow` to delineate printed cards — add a 1px border fallback.
- *Enforce:* Phase 88; Phase 90 verification protocol includes one print-preview check (browser print-to-PDF, light output, swatches visible).

**P-13. Relative links written for a web server, not a file tree.**
- *Warning sign:* links like `href="examples/"` (directory, needs index serving), root-relative `href="/brandbook-fable/..."`, or links to `.md` files expecting GitHub-style rendering.
- *Prevention:* every internal link is document-relative and points at a concrete file (`examples/landing.html`, not `examples/`). Links to `.md` companions are labeled as source documents ("opens as plain text locally; rendered on GitHub").
- *Enforce:* Phase 90 gate: link extractor asserts every `href`/`src` is relative and the target file exists (the milestone's local-only-references check, extended to existence).

**P-14. Interaction states claimed but not actually wired.**
- *Warning sign:* the component gallery shows "hover/focus/disabled" as **static painted swatches** only, or shows real states that don't match the painted ones.
- *Prevention:* gallery components are real HTML elements with real `:hover/:focus-visible/:disabled` CSS driven by the same tokens, **plus** a frozen row showing each state forced (e.g., a `.force-hover` class applying identical declarations) so states are visible without interaction and in print. Both rows derive from the same custom properties so they can't drift.
- *Enforce:* Phase 88; Phase 90 gate greps that `:hover`/`:focus-visible`/`:disabled` selectors exist and reference token variables.

### Token / language hygiene

**P-15. Planning-language leakage into shipped artifacts (the v1.8 `tokens.json` failure).**
- *Warning sign:* strings like "phase", "GSD", "REQ-", "TODO", "option-g", "tournament", "codex", "baseline", internal decision IDs, or planning file paths inside `tokens.json`, CSS comments, SVG metadata (`<metadata>`, editor-generated `<!-- -->` comments, `inkscape:`/`sodipodi:` attributes), or HTML comments.
- *Prevention:* artifacts are written reader-facing from the start; descriptions in `tokens.json` describe *usage* ("primary action background"), not provenance.
- *Enforce:* Phase 90 gate (already a milestone target feature): denylist grep over all of `brandbook-fable/` — include SVG editor-metadata patterns in the denylist, not just prose words.

**P-16. Token names that encode raw values or codex-era roles instead of semantic + state roles.**
- *Warning sign:* `--glass-500`, `--color-blue`, or light-only roles with dark "variants" bolted on as `--ink-dark-mode`.
- *Prevention:* semantic roles (`--surface`, `--surface-raised`, `--text-primary`, `--accent`, `--accent-hover`, `--border-focus`, `--feedback-danger`...) whose **values** change per theme while names stay constant — this is what makes P-11's architecture possible and is already a milestone target feature. Raw palette values may exist one layer below as private refs.
- *Enforce:* Phase 86 design; Phase 90 gate asserts the documented role list exists in both light and dark blocks with no role missing from either (set-difference check).

### Email specimen

**P-17. Putting SVG in the email template.**
- *Warning sign:* `<img src="logo.svg">` or inline `<svg>` in the email specimen. Gmail, Outlook (all variants), and Yahoo do not render SVG in email; inline SVG markup is stripped by sanitizers.
- *Prevention:* the email specimen uses **no SVG at all**. Logo slot is either styled live text in web-safe fonts (acceptable: email is the one surface where the wordmark may be system text by necessity — document this exception in the brand book) or a documented PNG placeholder path with proper `alt`. Note in-file that production senders should host a PNG/JPG logo.
- *Enforce:* Phase 89 authoring; Phase 90 gate: `grep -i 'svg' brandbook-fable/examples/email*.html` returns nothing.

**P-18. Modern CSS layout in the email instead of tables.**
- *Warning sign:* flexbox/grid/`max-width`-only layout, external `<style>` reliance, rem units, CSS shorthand hex (`#fff`), or web fonts. Classic Outlook on Windows (Word rendering engine, still in market through at least 2029) ignores nearly all of it; Gmail clips >102KB and strips `<style>` in forwarded/embedded contexts.
- *Prevention:* the 2026-stable recipe — see "Email HTML Rules" below. The repo already practices this (HEEx + MSO VML fallbacks); the specimen must meet the same bar.
- *Enforce:* Phase 89; Phase 90 gate: assert `role="presentation"` tables present, no `display:flex|grid`, six-digit hex only, total file ≤100KB.

**P-19. Email dark mode handled like web dark mode.**
- *Warning sign:* one `@media (prefers-color-scheme: dark)` block and an assumption it covers Gmail/Outlook.
- *Reality (2025-2026 client landscape):* **Apple Mail/iOS Mail** honors `color-scheme`/`supported-color-schemes` meta + media queries (best behaved). **Gmail** ignores the media query and **force-transforms colors** with its own inversion heuristics — you cannot opt out, only design to survive it. **Outlook.com / new Outlook** applies its own transform; targeted overrides via `[data-ogsc]`/`[data-ogsb]` prefixed selectors. **Classic Outlook Windows** does a partial invert influenced by the color-scheme meta.
- *Prevention:* include both meta tags + `:root{color-scheme: light dark;}`; design the light version with mid-tones that survive inversion (the mailglass palette helps: Ink #0D1B2A on Mist #EAF6FB, never pure #000/#FFF); add the `prefers-color-scheme` block for Apple Mail; treat Gmail's result as approximate and verify the specimen doesn't depend on exact brand colors for meaning (e.g., don't encode status only in color).
- *Enforce:* Phase 89; Phase 90 gate greps for both meta tags and bans `#000000`/`#FFFFFF` literals in the email file.

### OG / social card

**P-20. Shipping an SVG og:image and believing it works.**
- *Warning sign:* `og-card.svg` referenced in any `<meta property="og:image">` example, or brand-book copy implying the SVG is directly usable.
- *Reality:* **no platform renders SVG og:images** — Facebook, X/Twitter, LinkedIn, Discord, Slack all require raster (PNG/JPEG/WebP), 1200×630 recommended, absolute HTTPS URL.
- *Prevention:* ship `og-card.svg` explicitly labeled as the **source template**; document the local export path in an adjacent note (open in browser → screenshot at 1200×630, or any local vector tool — no Node/toolchain commitment, no binary committed per scope lock). Any `og:image` snippet in docs shows a `.png` filename with a comment pointing at the SVG source.
- *Enforce:* Phase 89 (labeling + export doc); Phase 90 gate: no `og:image` content ending in `.svg` anywhere in `brandbook-fable/`.

### AI-cliché / craft screening (logo tournament + collateral)

**P-21. Rounded-rect badge plate behind the mark.** The #1 AI-logo tell (and already banned by the milestone: "no rectangular background plates"). Warning sign: any container shape whose only job is to hold the mark. *Enforce:* Phase 85 brief names it; Phase 87 judging axis; Phase 90 spot-check.

**P-22. Gradient meshes / multi-stop gradients as the identity.** Gradients hiding weak form; also creates `<defs>`/ID baggage (P-04) and degrades in monochrome/print. Prevention: marks must pass a **single-color test** — the brand already requires a monochrome variant. *Enforce:* Phase 87 (every option submitted with a monochrome version); Phase 90 gate may grep `linearGradient|radialGradient` in logo assets.

**P-23. Generic "nodes and connections" / circuit / hexagon / brain iconography.** The default AI-era visual for anything technical; says "tech" but not "mail you can see through." *Enforce:* Phase 85 brief lists banned motif families; Phase 87 diversity-by-axis selection excludes them.

**P-24. Blue-purple SaaS gradient sameness.** LLM training-data default. mailglass's locked palette (Ink/Glass/Ice/Mist) is teal-cyan on near-navy — any drift toward violet is a regression flag. *Enforce:* Phase 90 gate: palette extraction from assets vs. token values (no non-token hex in shipped assets).

**P-25. Fake glassmorphism.** Frosted-blur cards, transparency stacks, lens flares — explicitly banned by the brand book ("glass as metaphor, not gimmick") and doubly tempting given the name. Warning sign: `backdrop-filter`, low-opacity white overlays, `feGaussianBlur`. *Enforce:* Phase 88/89 authoring; Phase 90 grep for `backdrop-filter|feGaussianBlur` plus visual review.

**P-26. Craft tells: inconsistent stroke weights and unsnapped geometry.** Warning signs: a mark mixing 1.5px/2px/2.3px strokes; path coordinates with arbitrary precision (`d="M3.0012,7.9987"`); strokes not converted to outlines (stroke scaling breaks at small sizes); mathematically-centered marks that read off-center optically. Prevention: pick one stroke unit and a small multiple set; build on a grid; convert strokes to fills in shipped assets; do an optical-centering pass at 16px and 32px (the milestone's 16px render check exists for this). *Enforce:* Phase 87 refinement rounds; Phase 90 16px render check.

**P-27. Centered-everything layouts in collateral.** AI default composition: hero-centered, symmetric, every section center-aligned. The thoughtful-maintainer voice reads better left-aligned, asymmetric, documentation-like. *Enforce:* Phase 85 brief sets the compositional stance; Phase 89 specimens follow it.

**P-28. Generic microcopy in specimens.** "Lorem ipsum", "Welcome to our platform", "Get started today" filler — wastes the specimen's chance to demonstrate the domain-noun copy library (Mailable/Delivery/Suppression vocabulary), and reads as AI filler. Prevention: specimens use real mailglass domain copy from the copy library deliverable. *Enforce:* Phase 89; Phase 90 grep for `lorem|ipsum` and a small generic-phrase denylist.

## GitHub SVG Rules (verified summary)

How GitHub actually handles SVG, by context:

1. **README/markdown image reference (`![..](x.svg)` or `<img src="x.svg">`)** — the dominant context. Served through GitHub's camo proxy / raw content host and rendered by the browser in **`<img>` secure-static mode**: scripts disabled, event handlers disabled, `foreignObject` interactive content disabled, and **all external resource fetches blocked** — external stylesheets, `@import`, images, and **fonts** (both GitHub CSP and the `<img>` sandbox independently block font loading). `currentColor` cannot inherit from the page (resolves to black). Internal `<style>` and SMIL/CSS animation inside the file do work. Confidence: HIGH.
2. **Inline `<svg>` markup written directly in README markdown** — stripped entirely by GitHub's HTML sanitizer. Not an option. Confidence: HIGH.
3. **Blob/file viewer preview** — GitHub renders a *sanitized* preview that has historically stripped layout-relevant presentation attributes (e.g., `dominant-baseline`), so it can differ from contexts 1 and 2. Don't use it as sign-off. Confidence: MEDIUM (documented incidents; sanitizer rules unversioned).
4. **Dark mode** — GitHub officially supports the `<picture>` element in markdown: `<source media="(prefers-color-scheme: dark)" srcset="dark.svg">` + light fallback `<img>`. Caveat: the media query follows the **OS** preference, so a user whose GitHub theme differs from their OS theme gets the "wrong" variant on purpose. A `prefers-color-scheme` `<style>` block **inside** the SVG also evaluates in `<img>` mode in Chromium/Firefox but has been unreliable in Safari and has the same OS-vs-site-theme mismatch — prefer `<picture>`, and prefer single designs that survive both backgrounds. The legacy `#gh-dark-mode-only` URL-fragment hack is removed; never use it. Confidence: HIGH for `<picture>` support and OS-preference behavior; MEDIUM for current Safari in-SVG media-query status.

**What guarantees identical rendering everywhere:** outlined paths (no text, no fonts), `viewBox` present, explicit hex fills, no `foreignObject`, no scripts, no external refs, no `<defs>` IDs (or asset-prefixed IDs), self-contained single file. An SVG meeting that spec renders identically in GitHub READMEs, the blob viewer, `file://` pages, `<img>` embeds, and inline HTML.

**Accessibility:** `role="img"` + first-child `<title id>` + `aria-labelledby` in the file; meaningful `alt` on every consuming `<img>` (the `alt` is what GitHub users actually get); `aria-hidden="true"` on decorative inline copies.

## Self-Contained HTML Rules

**The honest font stacks** (recommend for `tokens.css`/`tokens.json` and `index.html`):

```css
/* UI / body — Inter when installed; honest system default otherwise */
--font-sans: Inter, system-ui, -apple-system, "Segoe UI", Roboto,
             "Helvetica Neue", "Noto Sans", Arial, sans-serif;

/* Display — Inter Tight is rarer than Inter; same honest chain */
--font-display: "Inter Tight", Inter, system-ui, -apple-system,
                "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;

/* Code */
--font-mono: "IBM Plex Mono", ui-monospace, "SF Mono", SFMono-Regular,
             Menlo, Consolas, "Liberation Mono", monospace;
```

What viewers actually see without Inter installed: macOS → San Francisco (via `system-ui`), Windows → Segoe UI, Android/ChromeOS → Roboto, Linux → varies (Cantarell/Ubuntu/Noto/DejaVu). These are all competent neo-grotesques near Inter's voice — but **metrics differ**, so: no hand-tuned letter-spacing that only works in Inter, no pixel-perfect text alignment, and the brand book's typography page should explicitly state "Inter is the brand face; `system-ui` is the honest default when Inter is not installed" rather than implying Inter is guaranteed. Verify once with Inter deactivated. (`font-size-adjust`/`size-adjust` fallback-tuning requires `@font-face`, which is banned here — so tolerance, not tuning.)

**file:// survival rules:** no `fetch`/XHR (blocked by opaque-origin CORS), no `<script type="module">` (blocked in Chromium from `file://`), `localStorage` wrapped in try/catch and treated as optional, every link document-relative to a concrete filename, plain subresource loads (`<img>`, `<link>`) with relative paths are fine. Net recommendation: **inline everything into `index.html`** and let the Phase 90 gate diff inlined tokens against `tokens.css`.

**Theme model:** `color-scheme: light dark` on `:root`; light tokens in `:root`; dark tokens defined once and applied via both `:root[data-theme="dark"]` and `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) }`; toggle cycles auto/light/dark. Dark state must be *demonstrated* (screenshot/audit), not just defined — the named v1.8 gap.

**Print:** `@media print` forces light tokens; `print-color-adjust: exact` scoped to swatches/contrast-matrix/state-chips; 1px border fallbacks where shadows carry structure.

## Email HTML Rules (2025-2026 client landscape)

The stable recipe for the transactional-email specimen — matching what mailglass core already does (HEEx + MSO VML fallbacks):

- **Layout:** nested `<table role="presentation" cellpadding="0" cellspacing="0" border="0">`; 600px max width; single column preferred. Classic Outlook for Windows (Word engine) remains in market (supported into 2029) and ignores flex/grid/max-width — tables are still mandatory in 2026.
- **Styles:** inline `style=""` on every element as the source of truth; `<style>` in `<head>` only for media queries and dark-mode overrides (Gmail supports head styles but strips them in forward/embed contexts and **clips messages over ~102KB** — keep the specimen well under).
- **Values:** six-digit hex only; explicit px units; avoid CSS shorthand for Outlook; `mso-line-height-rule: exactly` where line-height matters; bulletproof buttons via padded `<a>` with border + optional VML wrapper for Outlook.
- **Fonts:** web-safe only — `Arial, Helvetica, sans-serif` (or Georgia for serif accents). **Inter will not load in email clients**; webfont `<link>`/`@import` works only in Apple Mail and isn't worth the divergence in a specimen. This is the one brand surface where the wordmark may legitimately be styled system text.
- **Images:** no SVG (unsupported in Gmail/Outlook/Yahoo). Specimen should be image-free or use a documented PNG placeholder with `alt` and explicit width/height.
- **Dark mode:** both metas (`color-scheme`, `supported-color-schemes` = `light dark`) + `:root{color-scheme: light dark}`; `@media (prefers-color-scheme: dark)` block for Apple Mail/iOS/Outlook-desktop-2019+; `[data-ogsc]`/`[data-ogsb]` prefixed duplicates for Outlook.com if precise control is wanted; accept that **Gmail force-transforms colors with no opt-out** — design the light version to survive inversion: no `#000000`/`#FFFFFF` literals, mid-tone brand colors (Ink #0D1B2A / Mist #EAF6FB are inherently safer than pure black/white), meaning never carried by color alone.
- **Hygiene:** preheader text span (hidden), `lang` attribute, `alt` on all images, real domain copy (no lorem), unsubscribe-header note consistent with mailglass's RFC 8058 stance.

## AI-Cliché Screening Checklist

For the Phase 85 brief and Phase 87 tournament judging; Phase 90 spot-checks the winners. Reject or flag any option exhibiting:

**Motif clichés**
- [ ] Rounded-rect/squircle badge plate behind the mark (banned by milestone scope)
- [ ] Nodes-and-connections / network graph / circuit traces
- [ ] Hexagons, isometric cubes, abstract "brain" or orbit rings
- [ ] Chat-bubble, paper-plane, or envelope-with-swoosh defaults (envelope is on-domain but the *swoosh* treatment is the cliché)
- [ ] Literal broken glass, lens flare, magnifying-glass-as-search confusion (brand book bans)

**Color/render clichés**
- [ ] Blue→purple gradient or any violet drift off the locked teal/ink palette
- [ ] Multi-stop gradient or gradient mesh as the primary identity device
- [ ] Fake glassmorphism: frosted blur, stacked transparency, `backdrop-filter`, `feGaussianBlur`
- [ ] Glows/drop-shadows doing the work of form

**Craft tells**
- [ ] Inconsistent stroke weights (mixed units; not from one small multiple set)
- [ ] Strokes not outlined in shipped assets; geometry not grid-snapped (arbitrary-precision coordinates)
- [ ] Mathematically centered but optically off (no optical pass at 16px/32px)
- [ ] Fails the single-color (monochrome) test
- [ ] Fails the 16px favicon test (detail soup at small size)
- [ ] Mark only works on one background (no light/dark survivability)

**Layout/copy tells (collateral)**
- [ ] Centered-everything symmetric composition throughout
- [ ] Three-icon-columns hero formula with generic value-prop copy
- [ ] Lorem ipsum or "Welcome to our platform"-grade filler instead of domain-noun copy
- [ ] Overused-default typography presented as a choice without rationale (using Inter is fine — it's locked brand — but the brief should *say why* and pair it with distinctive use, since "Inter + generic layout" is itself the AI default)

## Sources

**GitHub SVG behavior**
- https://github.com/github/markup/issues/1160 (blob-viewer sanitizer altering SVG layout)
- https://github.com/excalidraw/excalidraw/issues/4855 (fonts blocked for SVGs in GitHub markdown/raw)
- https://github.com/orgs/community/discussions/59781 (camo proxy / CSP restrictions on SVG)
- https://driesvints.com/blog/investigating-dark-mode-for-svgs-in-github-readmes (in-SVG prefers-color-scheme: Chrome/Firefox yes, Safari no; OS-pref vs GitHub theme)
- https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax (`<picture>` element officially supported)
- https://www.w3.org/wiki/SVG_Security and https://www.w3.org/TR/SVG2/conform.html (secure static mode: no scripts, no external refs, foreignObject disabled in img context)
- https://github.com/WICG/proposals/issues/50 (currentColor does not inherit into img-embedded SVG)

**Fonts / self-contained HTML**
- https://github.com/system-fonts/modern-font-stacks (neo-grotesque + system-ui stacks)
- https://systemfontstack.com/ (per-OS system font mapping)
- https://almanac.httparchive.org/en/2025/fonts (system-ui adoption; Inter not preinstalled, web-delivered)
- https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme

**Email HTML 2025-2026**
- https://www.litmus.com/blog/the-ultimate-guide-to-dark-mode-for-email-marketers (client dark-mode matrix: Apple honors media queries; Gmail force-transforms; Outlook partial-invert + data-ogsc)
- https://www.litmus.com/blog/coding-emails-for-dark-mode (meta tags, :root color-scheme, [data-ogsc] technique)
- https://www.emailonacid.com/blog/article/email-development/dark-mode-for-email/ (no pure black/white; inversion-survivable design)
- https://www.enchantagency.com/blog/dark-mode-email-design-best-practices-css-guide-2026 (2026 client landscape confirmation)

**OG image**
- https://opengraphdebug.com/posts/og-image-requirements (PNG/JPEG/WebP only; 1200×630; absolute URL)
- https://blog.termian.dev/posts/twitter-og-image-svg/ and https://fransdejonge.com/2018/03/twitter-and-facebook-dont-support-svg-yet/ (SVG og:image unsupported, longstanding)
- https://www.getrediate.com/blog/og-image-size-guide (2026 per-platform sizes)

**AI-cliché screening**
- https://prg.sh/ramblings/Why-Your-AI-Keeps-Building-the-Same-Purple-Gradient-Website (training-data bias → purple gradients, three-column heroes)
- https://www.jackpearce.co.uk/notes/purple-gradient-ai-aesthetics/ (purple-gradient provenance)
- https://velvetshark.com/ai-company-logos-that-look-like-buttholes (circular-gradient central-focal-point sameness in AI branding)
- https://www.designrush.com/best-designs/logo/trends/logo-design-prompts (node/network/hexagon/brain motif clichés)
