# Brand-System Patterns: What World-Class OSS/Devtools Brand Books Ship

**Milestone:** v1.9 Brand Book Fable
**Researched:** 2026-06-11
**Mode:** Ecosystem (artifact patterns, not brand strategy)
**Overall confidence:** HIGH for pattern descriptions (fetched directly from live pages); MEDIUM where flagged.

## Summary

Ten systems studied: Tailwind CSS brand page, Stripe (Apps design docs + public design language), Supabase brand assets, Radix Colors, Linear (brand page + two redesign posts), Astro press kit, Vercel Geist, Oban brand assets, shadcn/ui theming, GitHub Primer Brand.

Three findings dominate:

1. **There are two distinct artifact genres, and the best examples never confuse them.** *Public brand/press pages* (Tailwind, Supabase, Linear, Astro, Oban) are deliberately tiny: logo variants per background, one or two colors with hex, a ZIP, and do/don't rules — typography and voice are *pointedly omitted* because external users don't need them. *Design-system docs* (Geist, Radix, shadcn, Primer Brand, Stripe Apps) are where color scales, semantic tokens, typography, and component states live, presented as engineer-operable tables and live specimens. A repo brand book like `brandbook-fable/` is the second genre with a thin layer of the first (logo kit + usage rules) folded in. The v1.8 codex's main structural risk is blending the genres into prose.

2. **Engineer credibility comes from operability, not eloquence.** The patterns that make these docs feel trustworthy are mechanical: every color step has a *named job* (Radix's 12 steps, Geist's 10), every token has a *role description in a table* (shadcn), the full theme is *copy-pasteable CSS at the bottom* (shadcn), every rule states *why* (Stripe), and dark mode is *demonstrated live via a page-level toggle that re-skins every specimen* (Geist), not described in prose.

3. **Dark mode is designed, then proven.** Radix designs dark scales independently (never auto-inverted); Geist and shadcn show both value sets side by side; Linear generates themes from 3 LCH variables with automatic high-contrast variants. Nobody world-class ships dark tokens without rendering them — which is exactly the v1.8 gap ("dark tokens exist but are undemonstrated").

All patterns below are implementable in a single self-contained offline HTML file with zero external requests.

## Pattern Catalog (by source)

### Tailwind CSS — `tailwindcss.com/brand`
- **Two-section minimalism:** Trademark Usage Agreement + Assets. That's the whole page.
- **Named permitted/forbidden examples** instead of abstract rules: "Tailwind Themes" forbidden; "ComponentStudio for Tailwind CSS" permitted. Rules taught by concrete instance.
- **Exactly two assets:** Mark (SVG) and Logotype (dark + white SVG variants, ZIP). No PNG clutter, no color section, no typography section.
- **Right-rail "On this page" anchor nav** + left sidebar — standard docs chrome reused for the brand page, so it feels like documentation, not marketing.
- **Omits:** color palette, type specimens, voice. (Genre: public trademark page.)

### Stripe — `docs.stripe.com/stripe-apps/design` (+ public design language)
- **Progressive disclosure:** philosophy → component taxonomy → contextual surfaces → anatomy diagram → implementation. Each layer links down rather than inlining everything.
- **Reasoned guardrails:** custom styling is "intentionally limited" and every constraint names its reason (consistency, accessibility, review speed). Compliance is framed as developer efficiency ("the fastest way"), never as policing.
- **Contextual specimens over component galleries:** screenshots show real Dashboard contexts; the anatomy diagram labels functional zones. The system is demonstrated *in situ*, not as isolated swatches.
- **Decision trees for ambiguity:** "Not sure which view?" callouts resolve the most common confusion inline.
- Stripe's broader identity (custom wordmark, indigo #635BFF / slate #0A2540, custom Camphor type) is conveyed *through the product surfaces themselves* — the live site is the brand book. (MEDIUM confidence on identity details; from secondary sources.)

### Supabase — `supabase.com/brand-assets`
- **Single hard rule, repeated:** "Do not use any other color for the wordmark." One memorable constraint beats ten soft ones.
- Logo kit download + light/dark SVG variants + an OAuth "Connect Supabase" button asset (brand asset for a *specific integration surface* — interesting precedent for shipping per-surface collateral).
- Supabase also generates branded OG cards per docs page from a template (open-sourced og-image generation). The pattern: **OG imagery is a templated system, not a one-off asset.** (MEDIUM confidence — training data, repo `supabase/og-image`; the brand-assets page itself doesn't document it.)

### Radix Colors — `radix-ui.com/colors`
- **12-step scale where every step has a named job** (canonical docs mapping): 1 app background, 2 subtle background, 3–5 component backgrounds (rest/hover/active), 6–8 borders (subtle/default/hover), 9–10 solid fills (rest/hover), 11 low-contrast text, 12 high-contrast text. The use-case table *is* the documentation.
- **Dark scales are designed independently**, not derived by inversion; switching is "applying a class to a container" because the step semantics hold across modes.
- **Alpha variants for every scale** — for blending over tinted surfaces.
- **Accessibility as a stated property of the system** (APCA-informed contrast, P3 gamut), not an afterthought paragraph.
- Presentation: labeled swatch rows, numbered steps, grouped by function.

### Linear — `linear.app/brand` + redesign posts
- **Asset hierarchy with use-case per tier:** Wordmark (default reference), Logomark (constrained layouts), Icon (social/chips). Three assets, each with a stated *when*.
- **Two colors total** on the brand page: Mercury White #F4F5F8, Nordic Gray #222326. Extreme restraint as a credibility signal.
- **Sizing philosophy instead of pixel rules:** "Make them big or make them small, but give them room to breathe."
- **Consolidated ZIP at the top of the page**, per-asset downloads below.
- From the redesign posts (`/now/how-we-redesigned-the-linear-ui`, `/now/behind-the-latest-design-refresh`): themes generated from **3 variables (base, accent, contrast) in LCH** with automatic high-contrast variants; **surfaces organized by elevation** (background → panels → dialogs → modals); Inter Display for headings over Inter body. Credibility came from **process documentation and before/after comparisons**, acknowledged scope constraints, and technical specifics (LCH uniformity explained).
- **Omits** typography and voice from the public brand page entirely.

### Astro — `astro.build/press`
- **Logo gallery where each variant is shown on its intended background** ("Logo on light," "Logo on dark," "Gradient logo on dark") — the demonstration *is* the usage rule.
- **PNG + SVG per asset, plus one bulk ZIP.**
- **Explicit paired allowed/prohibited bullets** ("Don't use the Astro logo for your app or website's icon").
- **Minimum-size spec** (24px digital, 1/8" print) and clear-space requirements.
- **Historical comparison:** the 2023 refresh shows old vs new logo — before/after as credibility.
- Mascot (Houston) shown but explicitly restricted — scoping which brand elements are *not* for reuse.

### Vercel Geist — `vercel.com/geist`
- **Three-part IA: Foundations / Brands / Components.** Foundations = Colors, Typography, Materials; Brands = per-product (Vercel, Next.js, Turbo…) sub-guidelines.
- **10-step color scales grouped by job:** backgrounds (1–2), component states (3 levels: default/hover/active), borders (4–6, also stateful), high-contrast fills (7–8), text/icons (9–10 secondary/primary). Interaction states are *built into the scale semantics* — directly relevant to the v1.9 "interaction/feedback state roles" requirement.
- **Page-level theme selector (System/Light/Dark) in the header** that re-renders every swatch and specimen on the page. The single best dark-mode-demonstration pattern found.
- **"Right click to copy raw values"** on swatches — tokens are clipboard-operable.
- Typeface positioning as audience signal: Geist Sans/Mono "specifically designed for developers and designers"; the grid itself treated as a brand element.

### Oban (Elixir ecosystem precedent) — `oban.pro/brand-assets`
- **Dual logo systems for OSS vs commercial tiers**, each with horizontal/vertical lockups and a standalone mark, in light- and dark-background variants. SVG + PNG, one brand kit ZIP.
- **Parallel Do/Don't lists** ("Use the logo to indicate Oban support or integration" / don't distort, don't imply endorsement).
- **Colors demonstrated in situ through the logo renderings** rather than swatch grids — appropriate for a public assets page (the swatch grid belongs in the internal system).
- Trademark policy link + dedicated contact email — professional stewardship at OSS-library scale. This is the ecosystem bar mailglass's public-facing layer should clear.

### shadcn/ui — `ui.shadcn.com/docs/theming`
- **Background/foreground pairing convention:** every surface token (`primary`, `card`, `muted`, `accent`, `destructive`…) pairs with a `-foreground` token for what sits on it; the `-background` suffix is omitted on the surface token. A two-word convention that makes the whole token set self-explanatory.
- **Token table with role descriptions** — 15+ tokens, each row says what it's for, including utility tokens (`border`, `input`, `ring`), data-viz (`chart-1..5`), per-region namespaces (`sidebar-*`), and **`radius` as a first-class token**.
- **Light and dark values shown as parallel CSS blocks** (`:root` vs `.dark`) in OKLCH — the dual values are *visible in the source*, not described.
- **Full default-theme CSS scaffold at the end of the page** — the entire system is copy-pasteable as one block. This is the single strongest "engineers trust it" move: the doc terminates in working code.
- Companion page `ui.shadcn.com/colors`: every color in every format (HSL/RGB/OKLCH/hex), click-to-copy.

### GitHub Primer Brand — `primer.style/brand`
- **A separate design system for marketing surfaces**, distinct from product Primer — explicit recognition that brand-expression surfaces (landing pages, OG, README headers) need their own components ("River," "Breakout banner," "Comparison table") and looser rules than product UI. Relevant precedent for mailglass's collateral section (landing specimen vs admin UI vs email specimen are different surfaces with different rules).
- **Color modes as a dedicated theming guide** plus an **animation guide** — motion documented as part of brand.
- Getting Started → Guides → Primitives → Layout → Typography → Components → Forms ordering: foundations before components, with progressive "Learn more" pathways.

## Steal These

1. **Per-step / per-token job descriptions** *(Radix Colors, Geist, shadcn)* — every color and token row carries a one-line role ("hovered border," "low-contrast text," "focus ring"). For mailglass: the semantic token table should name interaction/feedback roles explicitly (rest/hover/active/focus/disabled, success/warn/danger/info), satisfying the v1.9 state-roles requirement the way Geist bakes states into scale steps 3–6.
2. **Background/foreground pairing convention + terminal copy-pasteable CSS block** *(shadcn/ui)* — name tokens as `surface` / `surface-foreground` pairs and end the foundations section with the complete `:root` / `[data-theme="dark"]` CSS, so the brand book's last word is working code.
3. **Page-level light/dark toggle that re-skins every specimen** *(Geist)* — one control in the sticky header flips a `data-theme` attribute; because all specimens are driven by the same custom properties, the entire book (logos, swatches, components, email specimen) demonstrates dark mode live. This single pattern closes the v1.8 "dark undemonstrated" gap.
4. **Logo variants demonstrated on their intended backgrounds, with a stated *when* per tier** *(Astro gallery; Linear's wordmark/logomark/icon hierarchy)* — render the winning mark on Paper, Mist, Ink, and Glass chips inline; label each lockup tier with its use case (README header, favicon/chip, docs sidebar, OG).
5. **Parallel Do/Don't lists taught by concrete named examples** *(Tailwind's permitted/forbidden naming, Astro's prohibitions, Oban's paired lists)* — and pair it with the brand book's existing say/don't-say voice examples in the same two-column format, so visual rules and voice rules read as one grammar.
6. **Reasoned guardrails — every rule states its why** *(Stripe Apps design docs)* — "No tracking pixels on auth mail *because* trust is the product" reads like mailglass; "don't do X" alone reads like legal. Also steal Stripe's *contextual specimen* move: show the system inside a realistic transactional-email render and a landing-page hero, not only as isolated chips.
7. **Dark scales designed independently, then proven with evidence** *(Radix; Linear's LCH + auto high-contrast)* — don't auto-invert; tune dark values, then render the computed WCAG contrast matrix as a table with ratios and pass/fail badges. The matrix is the brand book's equivalent of Linear's "engineering rigor" credibility.
8. **Click-to-copy token values** *(Geist "right click to copy"; shadcn colors page)* — a 10-line inline script on every swatch/hex; zero external requests, large DX payoff.
9. **Bulk download affordance at the top, per-asset paths below** *(Linear, Astro, Oban)* — for a repo artifact, this translates to a "where each file lives" asset index table (`assets/logo-primary.svg` …) at the top of the logo section, so the book doubles as the asset manifest.
10. **Surface-scoped collateral sections** *(Primer Brand's marketing-vs-product split; Supabase's per-integration button asset; Supabase's templated OG system)* — organize collateral by surface (README/docs/OG/email/landing), each with its own specimen and its own rules, rather than one generic "applications" section.

## Avoid These

1. **Vibes-only brand prose with no operable tokens.** The credibility pattern across all ten systems is hex values, CSS blocks, and labeled swatches; adjectives without values are the classic corporate-brand-book failure. (Counter-examples everywhere: Linear ships 2 hexes; shadcn ships the whole theme.)
2. **Auto-inverted or merely-asserted dark mode.** Radix designs dark scales separately; Geist demonstrates both live. Shipping a `.dark` block that no page renders is exactly the v1.8 gap — if the toggle doesn't re-skin every specimen, the dark system isn't real.
3. **Component galleries without interaction states.** Geist documents default/hover/active at the *scale* level; shadcn tokens include `ring`. Static screenshots of resting components hide half the system. Render real `:hover`/`:focus-visible`/`:disabled` CSS *and* a forced-state row (`.is-hover`, `.is-focus`, `.is-disabled` classes) so all states are visible without a mouse.
4. **Logo shown only on white / on a rectangular plate.** Astro, Oban, Supabase, and Tailwind all ship per-background variants and demonstrate them on those backgrounds. (Also a v1.9 scope lock: no background plates.)
5. **Trademark legalese as the center of gravity.** Tailwind's and Supabase's pages are mostly legal — correct for *their* genre (public trademark pages), wrong for an internal/repo brand book. Keep usage rules to one tight Do/Don't section; spend the page on the system.
6. **Unlabeled swatch grids** ("here are six nice colors"). Every studied system that presents color at all maps swatches to jobs. A palette without role assignments forces every consumer to re-decide semantics.
7. **Multi-page doc-site architecture with build tooling.** Geist/Primer/Radix can afford Next.js sites; a self-contained offline artifact cannot. Their *navigation* patterns (sticky header, anchor rail) port to a single file; their infrastructure does not.
8. **Live `<text>` elements / font dependencies inside logo SVGs.** Tailwind, Linear, Astro, and Oban all ship outlined-path marks (standard practice — MEDIUM confidence on each individually, HIGH on the norm). This is the v1.8 Avenir Next defect; v1.9 already locks zero `font-family` in assets — the quality gate should grep for it.
9. **Burying the one rule that matters.** Supabase repeats its single wordmark-color rule twice on a short page. If mailglass has non-negotiables (no tracking on auth mail, no glassmorphism, no PII), state them early and loudly rather than distributing them across sections.

## HTML Brand Book Guidance (single-file, offline, zero external requests)

**Architecture**
- One `index.html`; all CSS in one `<style>`, all JS inline (small), all imagery as **inline SVG** (not base64 PNG — keeps the file diffable and lets SVGs consume `currentColor`/`var(--token)` so they re-skin with the theme).
- **Sticky top bar:** wordmark, section anchor links, theme toggle (Geist header pattern). On wide screens add a right-rail "On this page" anchor list (Tailwind docs pattern); collapse to the top bar on mobile.
- **Section order (synthesized from Geist/Primer/shadcn):** Essence & non-negotiables → Logo system (asset index table + per-background demos + Do/Don't) → Color tokens (semantic table, light/dark columns) → Contrast matrix → Typography → Voice (say/don't-say) → Component gallery with states → Motion → Collateral specimens by surface (README/docs/OG/email/landing) → Usage rules. Foundations before applications, every section terminating in something operable.

**Theming mechanics**
- `:root { --ink: …; }` plus `[data-theme="dark"] { … }` overrides; toggle flips the attribute (3-line script; `localStorage` persistence is fine — it's local, not a network request). Honor `prefers-color-scheme` as the initial value, like Geist's System option.
- Name tokens semantically with shadcn's pairing convention (`--surface`, `--surface-foreground`, `--accent`, `--accent-foreground`, `--border`, `--ring`, `--success`, `--danger`…), mapped from the Ink/Glass/Ice/Mist/Paper/Slate seed. Include `--radius` and motion-duration tokens (Primer treats motion as brand).
- End the tokens section with the **complete copy-pasteable CSS block**, both themes (shadcn).

**Specimens**
- **Contrast matrix:** computable at runtime with ~20 lines of inline JS (WCAG relative luminance — no library needed), rendered as a table of fg×bg pairs with the ratio number and AA/AAA pass-fail badges, recomputed on theme toggle. Runtime computation means the matrix can never drift from the tokens — stronger than a hand-authored table.
- **Component gallery:** real HTML (buttons, inputs, badges, table rows, the status-badge taxonomy) styled purely from tokens; real pseudo-class CSS plus a forced-state row per component so hover/focus/disabled are visible statically.
- **Email specimen:** embed via `<iframe srcdoc="…">` — works fully offline and *isolates* the email's table-layout CSS from the book's CSS (email HTML and modern CSS must not bleed into each other). Landing specimen can be inline since it shares the token system.
- **Logo section:** render each lockup inline on Paper/Mist/Ink/Glass background chips; show minimum-size and clear-space as drawn diagrams (Astro's 24px spec made visual), and list every shipped asset path in a manifest table.

**Typography without embedded fonts (hard constraint)**
- No `@font-face`, no Google Fonts URL. Declare the canonical stack with graceful degradation: `font-family: "Inter Tight", Inter, system-ui, -apple-system, "Segoe UI", sans-serif` (and `"IBM Plex Mono", ui-monospace, "SF Mono", Menlo, monospace`). State plainly in the type section that Inter/IBM Plex Mono are canonical and the book renders with the nearest installed/system face — honest, thoughtful-maintainer framing of the constraint.
- Because the wordmark must be identical everywhere, it is **outlined paths in SVG only** — the one place type may never fall back.

**Quality gate hooks (matches the milestone's scripted gate)**
- Grep gates: zero `http://`/`https://` in `src`/`href`/`url()` (anchors exempt); zero `font-family` inside `assets/*.svg`; zero planning-language strings; file-size budget on `index.html` and per-SVG.
- Render gates: open with `data-theme="dark"` and at 16px root font; the runtime contrast matrix doubles as a self-test (any FAIL badge in either theme is a gate failure).

## Sources

| Source | URL | Confidence |
|---|---|---|
| Tailwind CSS brand page | https://tailwindcss.com/brand | HIGH (fetched) |
| Stripe Apps design docs | https://docs.stripe.com/stripe-apps/design | HIGH (fetched) |
| Stripe identity details (wordmark, #635BFF, Camphor) | secondary analyses via search | MEDIUM |
| Supabase brand assets | https://supabase.com/brand-assets | HIGH (fetched) |
| Supabase templated OG generation | training data / `supabase/og-image` | MEDIUM |
| Radix Colors | https://www.radix-ui.com/colors | HIGH (fetched; step-job mapping cross-checked against canonical docs) |
| Linear brand guidelines | https://linear.app/brand | HIGH (fetched) |
| Linear UI redesign (LCH, elevation, Inter Display) | https://linear.app/now/how-we-redesigned-the-linear-ui | HIGH (fetched) |
| Linear design refresh (token tooling) | https://linear.app/now/behind-the-latest-design-refresh | MEDIUM (search summary) |
| Astro press kit | https://astro.build/press | HIGH (fetched) |
| Vercel Geist (intro + colors) | https://vercel.com/geist/introduction, https://vercel.com/geist/colors | HIGH (fetched) |
| Oban brand assets | https://oban.pro/brand-assets | HIGH (fetched) |
| shadcn/ui theming | https://ui.shadcn.com/docs/theming | HIGH (fetched) |
| shadcn/ui colors page | https://ui.shadcn.com/colors | MEDIUM (search result) |
| GitHub Primer Brand | https://primer.style/brand/ | HIGH (fetched) |
