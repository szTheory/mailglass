# Codex Brandbook Audit — Defect/Gap Register (BRIEF-01)

Forensic audit of the codex `brandbook/` baseline. Consumed by the Phase 85
differentiation brief; Phases 86-90 cite rows here by ID and never re-read the
codex files.

## Methodology

- **Audit target:** `brandbook/` frozen at commit `09a84dd4`. Verified before
  auditing: `git diff --quiet 09a84dd4 -- brandbook/` exits 0, so the working
  tree is identical to the frozen baseline and all line numbers below are valid
  against both.
- **Verification rule:** every finding was checked against actual file
  contents at the cited line. No paraphrased claims, no straw men. Absence
  gaps (a file or capability that does not exist) use `brandbook/ (absent)` in
  the File:Line column; everything else points at a real line the auditor read.
- **Severity scale:** 1 = cosmetic; 2 = craft/quality debt; 3 = weakens a
  launch surface or adopter touchpoint; 4 = undermines a core claim the
  artifact makes about itself; 5 = undermines the artifact's purpose.
- **Fable-response taxonomy:** `exploit` = fable does this visibly better and
  the A/B walkthrough should show it; `fix` = fable simply avoids the mistake,
  no need to showcase; `ignore` = real but not worth bytes in v1.9.
- **Pitfall IDs** (P-01..P-28) reference
  `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md` where a
  defect instantiates a registered pitfall.

## Defect Register

| ID | File:Line | Finding | Severity | Fable response |
|----|-----------|---------|----------|----------------|
| CDX-01 | brandbook/assets/logo-primary.svg:17 | The wordmark is live `<text>` with `font-family="Avenir Next, Avenir, Helvetica Neue, sans-serif"` — a macOS-only primary face with `letter-spacing="-1.6"` tuned to its metrics. GitHub's `<img>` sandbox loads no fonts at all, and Avenir is absent on Windows/Linux/Android, so nearly every viewer sees a substituted face with wrong spacing in the primary brand asset. (P-01, P-09) | 5 | exploit |
| CDX-02 | brandbook/assets/logo-primary.svg:14 | The mark's pane is filled with a three-stop translucent gradient `url(#mg-logo-primary-pane)` (defined at brandbook/assets/logo-primary.svg:5, white→Mist→Ice with stop-opacity 0.94→0.5). brandbook/brand-book.md:77 forbids exactly this: "Avoid decorative gradients, blobs, lens flares, bevels, chrome, and fake depth." The low-opacity white-overlay stack is also the glassmorphism warning sign, and the mark cannot pass a single-color test with the gradient doing form work. Same gradient repeats in brandbook/assets/logo-mark.svg:14, brandbook/assets/favicon.svg:14, and brandbook/assets/social-avatar.svg:15. (P-22, P-25) | 4 | exploit |
| CDX-03 | brandbook/tokens.json:70 | Token description reads "...unless Phase 84 contrast validation approves a normal body-text pair" — planning-process vocabulary in a shipped artifact, referencing a validation that never ran. Repeated at brandbook/tokens.json:75 ("until Phase 84 contrast validation approves body text usage") and brandbook/tokens.json:76 ("before Phase 84 validation"). (P-15) | 4 | exploit |
| CDX-04 | brandbook/tokens.css:108 | A dark token set exists (`[data-theme="dark"]` block, lines 108-129) but is never demonstrated: brandbook/index.html contains no theme toggle and never sets `data-theme` anywhere. The only "dark" in the page is the static `.logo-box.dark` CSS class at brandbook/index.html:270, a fixed Ink swatch behind the avatar. Dark mode is defined, claimed, and unreachable. (P-11) | 5 | exploit |
| CDX-05 | brandbook/tokens.css:2 | `:root` hard-codes `color-scheme: light` and no `prefers-color-scheme` media query exists anywhere in brandbook/ (verified by grep). A viewer whose OS prefers dark gets light, always — the dark tokens cannot activate by any path. (P-11) | 3 | exploit |
| CDX-06 | brandbook/tokens.css:108-129 | The dark block reassigns only 18 custom properties of the ~70 roles defined in `:root`. All eight callout roles keep light values: under dark, `--mg-callout-info-bg` stays `#eaf6fb` (brandbook/tokens.css:44) while `--mg-text` becomes Mist `#EAF6FB` (line 118) — callout body text on the callout background computes to 1:1, i.e. invisible. `--mg-state-hover`, `--mg-state-active`, `--mg-state-disabled`, and `--mg-state-selected` likewise keep light-surface values on dark backgrounds. | 4 | fix |
| CDX-07 | brandbook/tokens.css:43 | Every contrast claim is asserted or deferred, never computed. The CSS comment instructs "validate text pairs before body copy use"; brandbook/tokens.json:70 defers to a validation that never ran; no contrast matrix, ratio table, or pass/fail record exists anywhere in brandbook/. The only computed number in the folder (4.37:1) sits in the process audit at brandbook/brand-audit.md:153 — and that number documents a failing AA pair left in the shipped tokens. | 4 | exploit |
| CDX-08 | brandbook/README.md:13-16 | Process and tournament artifacts ship inside the reader-facing folder, and the README directs readers to them: `logo-concepts.html`, `logo-concepts.md`, `logo-creative-brief.md`, and `logo-options.md` ("historical rejected A-R evidence"), plus brandbook/brand-audit.md (a phase-process gap register: "Phase 80 scope..." at brandbook/brand-audit.md:5), 18 rejected-option SVGs under brandbook/assets/options/, and 11 variant SVGs under brandbook/assets/concepts/. Roughly half the folder by file count is process exhaust, not brand system. (P-15 at folder scale) | 4 | fix |
| CDX-09 | brandbook/examples/readme-header.svg:20 | The README header specimen — the single most GitHub-facing surface — repeats the live Avenir Next wordmark verbatim (`font-family="Avenir Next, Avenir, Helvetica Neue, sans-serif"` with tuned negative letter-spacing). The root failure ships in exactly the context where it breaks hardest. (P-01) | 5 | exploit |
| CDX-10 | brandbook/examples/docs-page.svg:8 | All five specimens use live `<text>` throughout (also brandbook/examples/palette.svg:5, brandbook/examples/typography.svg:6, brandbook/examples/ui-primitives.svg:5, brandbook/examples/readme-header.svg:22-34) with Inter-family stacks and fixed pixel coordinates. Inter is preinstalled on no major OS, so layouts assume metrics most viewers don't have; multi-line code blocks and pill labels sit in pixel-tight boxes that can overflow under substitution. (P-01 specimen class, P-09) | 3 | fix |
| CDX-11 | brandbook/assets/favicon.svg:1 | The favicon is not a redrawn small-size artifact: it declares `width="32"` over the same `viewBox="0 0 80 80"` and the identical four-stroke geometry as the full mark (brandbook/assets/favicon.svg:12-15 matches brandbook/assets/logo-mark.svg:12-15 path-for-path), gradient included. Four overlapping strokes plus a rotated translucent pane at 16-32px is detail soup; the codex's own audit flagged the fold ambiguity at small sizes (brandbook/brand-audit.md:150, BRAND-GAP-05) and the asset shipped unchanged. (P-26) | 3 | exploit |
| CDX-12 | brandbook/assets/logo-mark.svg:11-15 | All marks are stroke-built (`stroke-width` 4-5 on an 80-unit grid) and never converted to outlined fills. Stroke rendering varies at small raster sizes and stroke scaling is the registered craft tell; shipped assets should be filled outlines. Applies to all four asset SVGs. (P-26) | 2 | fix |
| CDX-13 | brandbook/brand-book.md:142 | The book promises "buildable UI, not mood boards" and lists thirteen core components (brandbook/brand-book.md:146-158: buttons, links, cards, alerts, badges, tabs, code blocks, terminal blocks, feature grids, comparison rows, install snippets, diagrams, states) — but brandbook/index.html demonstrates components only as static SVG pictures (brandbook/index.html:495-499). No live HTML button, input, tab, alert, or badge with working hover/focus/disabled states exists anywhere in the folder. (P-14) | 4 | exploit |
| CDX-14 | brandbook/index.html:96-98 | The hero background is a decorative gradient written in raw `rgb()` literals (`rgb(234 246 251 / 0.8)`), bypassing the token system on the same page that instructs "do not copy raw hex into components" (brandbook/index.html:432) and contradicting brandbook/brand-book.md:77. The literals are light-theme-only, so the hero would break under the dark theme if it were ever reachable. | 2 | fix |
| CDX-15 | brandbook/tokens.json:2 | The token file declares the legacy Tokens Studio schema (`$schema: https://tokens.studio/schemas/tokens.json`) and uses pre-DTCG `value`/`description` keys with no `$type` anywhere — tooling cannot infer token types, and aliases use the nonstandard `{palette.x.value}` form instead of `{palette.x}`. The format predates the first stable Design Tokens spec (DTCG 2025.10). | 2 | exploit |
| CDX-16 | brandbook/ (absent) | No landing-page specimen exists. examples/ covers palette, typography, UI primitives, README header, and a docs page — there is no deployable landing blueprint despite the brand book naming "landing pages" as a primary logo surface (brandbook/brand-book.md:124). | 3 | exploit |
| CDX-17 | brandbook/ (absent) | No email-template specimen exists. The brand book for a transactional **email** framework contains zero branded email — no table-layout specimen, no client-safe HTML, no dark-mode email guidance. The product's core artifact is the one surface the brand system never touches. | 4 | exploit |
| CDX-18 | brandbook/ (absent) | No OG/social-card template exists. brandbook/assets/social-avatar.svg is a 512×512 square avatar; there is no 1200×630 social-card source nor any documented PNG export path for link-preview surfaces. | 3 | exploit |
| CDX-19 | brandbook/ (absent) | No per-surface copy library exists. Microcopy is four strings in brandbook/brand-book.md:212-228 (error/empty/success/warning); there is no paste-ready GitHub About, Hex.pm description, HexDocs intro, launch-post, or release-note copy, and the microcopy is not keyed to the seven domain nouns (Mailable, Message, Delivery, Event, InboundMessage, Mailbox, Suppression). | 3 | exploit |
| CDX-20 | brandbook/ (absent) | No diagram-language spec exists. brandbook/brand-book.md:157 lists "diagrams" as a core component to keep aligned, but no node-shape, stroke-weight, arrowhead, or pane-motif specification appears anywhere in the folder. | 2 | exploit |

## Strengths Register

What codex did well. False differentiators die here: the brief may not claim
any of the following as fable advantages, and where fable competes on the same
ground it must match or beat the cited bar.

| ID | File:Line | Finding | Severity | Fable response |
|----|-----------|---------|----------|----------------|
| CDX-S-01 | brandbook/tokens.json:60-73 | A full semantic state group exists — default/hover/active/focus/disabled/selected plus success/warning/error/info/subtle/muted — and every role carries a usage description that warns against color-only meaning. | — | match: fable's role descriptions must be at least this disciplined. |
| CDX-S-02 | brandbook/tokens.json:74-94 | Dedicated callout and code role tokens: four callout kinds with background/border pairs, and a nine-role code group (background, surface, border, text, muted, accent, string, warning, error). | — | beat: keep the role coverage and ship every pair contrast-computed, which codex never did (CDX-07). |
| CDX-S-03 | brandbook/tokens.css:108-129 | A coherent dark token set exists with a verified-clean dark ramp (Ink #0D1B2A → #152538 → #1F3049, Mist text, Ice accents) — the ramp the v1.9 research adopted. | — | beat: complete the role coverage (CDX-06) and demonstrate it live with a toggle (CDX-04). |
| CDX-S-04 | brandbook/assets/logo-primary.svg:1-3 | Every asset SVG ships `role="img"`, a first-child `<title>` plus `<desc>`, `aria-labelledby`, and asset-prefixed unique IDs (`mg-logo-primary-*`, `mg-favicon-*`, ...). The earlier repeated-`id="title"` collision flagged in the codex's own audit was actually fixed. | — | match: same accessibility layer on every fable asset. (P-07 cleared by codex) |
| CDX-S-05 | brandbook/index.html:8 | index.html is genuinely self-contained: relative stylesheet/favicon links only, zero `http` references, no `fetch()`, no ES modules, no `@font-face` (verified by grep). It opens correctly from `file://`. | — | match: fable must equal this while adding the live gallery and toggle on top. (P-10 cleared by codex) |
| CDX-S-06 | brandbook/assets/logo-monochrome.svg:1 | The currentColor marks carry an explicit `color="#0D1B2A"` fallback on the root element, so `<img>`-context rendering resolves to Ink rather than black. | — | match: fable's adaptive marks need the same explicit-fallback discipline. (P-02 cleared by codex) |
| CDX-S-07 | brandbook/tokens.css:136-143 | `prefers-reduced-motion: reduce` collapses every duration token to 1ms, and motion tokens cap at 300ms (brandbook/tokens.css:101-105) per the brand's own motion rule. | — | match. |
| CDX-S-08 | brandbook/brand-book.md:205-228 | The voice section is concrete and on-brand: paired say/don't examples in real product language, plus four-state microcopy using domain nouns ("Delivery blocked: recipient is on the suppression list."). | — | beat: extend to a per-surface copy library and seven-noun microcopy coverage (CDX-19), keeping this quality bar. |
| CDX-S-09 | brandbook/examples/readme-header.svg:27-28 | The README specimen's install snippet uses real product commands (`mix deps.get`, `mix mailglass.install`) — the earlier generic `phx_new` snippet its own audit flagged was actually replaced. | — | match: fable specimens use real domain flows, never generic scaffolding. |

## Killed Differentiator Candidates

Draft differentiators the strengths register disproves or forces to be
restated honestly. None of these may appear in the brief as written:

1. **"Codex has no semantic state tokens"** — FALSE. It has a twelve-role
   state group with usage descriptions (CDX-S-01). There is no token-existence
   differentiator; the honest axis is contrast-computed tokens (CDX-07) and
   complete dark coverage (CDX-06).
2. **"Codex has no dark mode"** — FALSE as stated. A defined dark set with a
   research-validated ramp exists (CDX-S-03). The honest claim is
   *demonstrated* dark mode: codex's dark tokens are unreachable (CDX-04,
   CDX-05) and incomplete (CDX-06).
3. **"Codex SVGs lack accessibility metadata / have colliding IDs"** — FALSE.
   Every asset has role/title/desc/aria-labelledby with prefixed unique IDs
   (CDX-S-04). Fable matches; it cannot differentiate here.
4. **"Codex's index.html needs a server or external resources"** — FALSE. It
   is fully self-contained and file://-safe (CDX-S-05). The honest
   differentiator is what the page *does* (live component gallery, toggle,
   computed matrix), not that it opens.
5. **"Codex has no microcopy or voice guidance"** — FALSE. It ships a strong
   voice section and four microcopy strings (CDX-S-08). The honest claim is
   breadth: per-surface copy library and seven-noun coverage (CDX-19).
6. **"Codex ignores reduced motion"** — FALSE (CDX-S-07). Not a
   differentiator at all.
