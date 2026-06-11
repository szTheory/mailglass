# Logo & Custom Typemark Craft — Research for the v1.9 Logo Tournament

**Project:** mailglass v1.9 "Brand Book Fable"
**Researched:** 2026-06-11
**Consumer:** Phase 87 logo tournament executor (8 hand-authored SVG options across 4 axes)
**Overall confidence:** HIGH on type-design fundamentals and named-logo precedents; MEDIUM on specific devtool-brand internals (verified where possible)

Hard constraints honored throughout: no rectangular background plates, marks break boundaries, logotype tight to mark, no subtitle in main lockup, **the lowercase i dot is untouchable**, final assets are hand-editable outlined-path SVG with zero `font-family`.

---

## Summary

Excellent typemark craft has two halves that must both be present: **(1) a motif earned by the letterforms** — the modification reads as something the word was always hiding (FedEx arrow, Goodwill g, moz://a), never as decoration bolted onto type — and **(2) invisible typographic correctness** — consistent stems, real overshoot, managed joints, even rhythm. Viewers can't name the second half, but they instantly feel its absence; this is the #1 way AI-generated letterforms fail.

The honest ecosystem finding: **most successful devtool brands do NOT modify their wordmark letterforms.** Vercel, Linear, Figma, Supabase, and Stripe all pair a strong abstract mark with a restrained, near-stock wordmark, and win on type quality + tight lockup discipline instead. Integrated typemarks (Mozilla's `moz://a` is the standout devtool example) are rarer, higher-risk, higher-reward. Practical implication for the tournament: the 2 pure-typemark slots must clear a high craft bar or they will lose to well-executed mark+wordmark lockups — and that's a legitimate outcome, not a failure of the tournament.

For the word **mailglass** specifically, the letterform gift is the **l·g·l cluster at the exact seam between "mail" and "glass"**: two full-height ascenders flanking a round single-story g whose bowl is a natural lens/pane and whose descender is the word's only built-in baseline-breaker. Secondary opportunities: the terminal **ss** pair, the two **a**'s, and the kerning channel at the mail|glass seam. The i dot and anything resembling envelopes/planes/send-arrows are off the table.

---

## Typemark Precedents

### Canonical integrated typemarks (what the modification is, and why it works)

| Logo | Letterform move | Why it works | Confidence |
|---|---|---|---|
| **FedEx** (Lindon Leader, 1994) | Negative-space arrow in the counter between "E" and "x"; achieved by custom kerning + subtle reshaping of two mixed typefaces (Univers 67 + Futura Bold) | The arrow is *discovered*, not displayed — it means speed/direction and costs zero added ink. The wordmark is fully legible if you never see it. 40+ design awards; the design-school benchmark for "motif worked into letterforms." | HIGH (verified) |
| **Goodwill** | The lowercase **g** doubles as a cropped smiling face (the counter is the eye) | Counter-replacement done right: the g still reads as a g first; the second reading reinforces the brand promise. Directly relevant to mailglass's g. | HIGH (verified) |
| **Carrefour** | The letter C appears in negative space between two opposing arrows | Proof that negative-space letterwork survives decades at every size — but note it took years for most people to see the C; subtlety has a cost. | HIGH (verified) |
| **Mozilla `moz://a`** (Johnson Banks, 2017) | Replaces "ill" with the protocol characters `://` | The single best devtool precedent: the substitution is *semantically load-bearing* (Mozilla = the web), monospace-flavored, and works because the replaced glyphs still scan as the missing letters. Lesson for mailglass: substitution must preserve word-scan. | HIGH |
| **Sony VAIO** | "VA" drawn as an analog sine wave, "IO" as digital 1/0 | Motif worked *into* strokes rather than counters — the letterforms themselves become the diagram. The high-water mark for "the word is the concept." | MEDIUM (training data, widely documented) |
| **Pixar** | The "i" replaced by the Luxo Jr. lamp | Whole-glyph replacement precedent. (Noted for completeness only — i-manipulation is banned for mailglass.) | HIGH |
| **IBM** (Paul Rand, 1972) | Eight horizontal scanlines striped through all three letters | A *texture* motif applied uniformly across the wordmark — relevant if a "pane/scanline" treatment across mailglass letters is explored. Warning: striping destroys small-size legibility; IBM ships an unstriped version for small uses. | HIGH |
| **Braun** (Will Münch, 1934) | The "A" raised and given a semicircular arched crossbar, taller than its neighbors | The Bauhaus-era tradition: modify ONE letter geometrically, leave the rest disciplined. Herbert Bayer's universal alphabet is the same tradition — letterforms reduced to circle/line geometry. This restraint (one modified letter, everything else perfect) is the mailglass-appropriate dosage. | MEDIUM-HIGH |
| **Dell** | Tilted "E" | One-letter rotation as the entire identity. Works because everything else is rigid. | HIGH |
| **Gillette** | Razor-thin diagonal slice through the G | The named precedent for **stroke interruption** — a clean cut through a stroke reads as precision. (Gillette also slices the i dot; that half of the precedent is off-limits here.) | MEDIUM |

### Modern devtool wordmarks (what they actually do)

| Brand | Wordmark treatment | Lesson |
|---|---|---|
| **Vercel** | Plain Geist-style geometric sans wordmark; identity lives in the triangle mark; very tight, minimal lockup | Restraint + tight lockup is a winning devtool strategy. The triangle survives at 16px because it's one shape. | MEDIUM |
| **Stripe** | Near-plain wordmark; identity carried by type voice (Söhne, light weight, negative tracking) and gradient, not letter tricks | "Custom-feeling" can come from weight/tracking/terminal decisions alone — no motif required. | MEDIUM (typography details verified via design-system documentation) |
| **Linear** | Plain modern grotesque wordmark; the mark (slanted parallel strips in a rounded square) carries everything | The mark's "parallel slats" idea is adjacent to mailglass's pane language — useful as a quality bar, also a similarity hazard to check against. | MEDIUM |
| **Figma** | Lowercase geometric wordmark, unmodified; pen-nib stack mark | Lowercase geometric grotesque wordmark + abstract geometric mark = the category default. mailglass must be at least this clean to compete. | MEDIUM |
| **Supabase** | Plain wordmark + bolt mark; wins on color ownership (green) not letterforms | Differentiation can come from a non-letter axis. mailglass's equivalent ownable axis is the Ink/Glass/Ice palette + transparency-as-meaning. | MEDIUM |
| **Glassdoor** | Contains "glass" and "ss" like mailglass; keeps the wordmark plain and puts meaning in the mark | Direct evidence that "glass" words don't *require* letter tricks — and a name-collision-adjacent brand to deliberately not resemble. | MEDIUM |

**Synthesis for the tournament's 4 axes:**
- *Pure custom typemark* options should follow the **Braun/FedEx dosage**: exactly one earned modification (or one negative-space discovery), every other glyph flawless.
- *Mark + tight wordmark* options should follow the **Vercel/Linear discipline**: mark does the metaphor, wordmark does the craft, gap stays tight (see Small-Size Survival for the number).
- *Monogram/glyph* options: a single-shape "m" or "g" construction beats a multi-stroke one at favicon size (Vercel triangle lesson).
- *Negative-space* options: the FedEx rule — the mark must be 100% functional for viewers who never see the hidden figure.

---

## Letterform Opportunities in "mailglass"

Word anatomy: `m a i l g l a s s` — 9 letters, all lowercase. Vertical events: two ascenders (the l's), one descender (the g), one dot (the i — untouchable). Everything else lives between baseline and x-height. The word splits semantically at **mail | glass**, and that seam falls exactly at the **l–g** junction.

### Ranked opportunities

**1. The l·g·l cluster (letters 4–6) — the prime site.**
Two full-height vertical strokes flanking a round bowl: structurally this *is* a pane held in a frame, with zero added geometry. The seam between the two brand nouns sits inside it. Concrete plays:
- **Counter-as-lens (Goodwill-g pattern):** the g's bowl counter carries the glass motif — e.g., the counter left open/unfilled where every other counter is normal, or a single horizontal "horizon" line through the bowl (a pane edge seen on-axis). The g still reads as g first.
- **Negative-space pane between l and g (FedEx pattern):** tune the l-g sidebearings so the channel between the l stem and the g bowl forms a deliberate sliver — a pane edge in negative space. This is the subtlest option and the most FedEx-like.
- **Boundary-breaking, for free:** the g descender is the word's only natural baseline violation. Letting it hang visibly below an otherwise disciplined baseline satisfies "marks should break boundaries" with no contrivance. Extending or geometrizing the descender hook (e.g., a quarter-circle return that almost closes, leaving a visible aperture = "open system, inspectable") is a low-risk modification.

**2. Stroke interruption / refraction offset at the mail|glass seam.**
The brand idea "mail you can see through" supports one optical-physics move: a stroke that passes "behind glass" shifts laterally (refraction, like a straw in water). Executed as a clean horizontal shear of ONE stroke segment — best candidate is the **first l's stem** or the **g's stem** at the seam — with a hairline gap at the shear plane (Gillette-slice precedent). Rules: one interruption only; the displaced segment stays vertical (shear position, not angle); gap ≥ stroke-width × 0.35 so it survives reduction; never interrupt a curve (curves read as broken/erroneous when cut; verticals read as deliberate).

**3. The terminal ss pair.**
Double-s endings offer mirror/interlock plays: shared spine geometry, the second s's lead terminal nesting into the first's tail aperture, or the two counters aligned to suggest stacked panes. **Caution ranking: lowest.** The s is the hardest glyph in the word to draw well (see SVG section), counters are small, and at 24px wordmark height an interlocked ss turns to mud — the brand book already warns the "gla" cluster muddies first; a tricky "ss" makes a second mud site. If used, the modification must be *spacing/alignment-based*, not shape-based.

**4. The two a's (positions 2 and 7).**
The a appears in both halves of the word — a symmetry hook ("same letter, seen through glass on the other side"). A *tint* shift (second a in Glass #277B96 while the word sits in Ink) is a legitimate two-color play that needs zero letterform surgery. A *shape* shift (double-story a in "mail," single-story in "glass") is clever in description but reads as an error in practice — same-glyph-different-shape violates the consistency that makes wordmarks feel engineered. Recommend color/weight plays only on the a's, never structural ones.

**5. The m (position 1).**
Three stems = three stacked panes / three sibling packages, and it's the natural monogram glyph for the monogram axis. As a *wordmark* modification site it's weak (initial-letter tricks read as generic "logo design 101"), but as a standalone monogram, an m built from three vertical strokes with one pane-like crossing element is the strongest single-glyph candidate alongside a lens-g.

### Glyph-skeleton decisions (lock these before drawing)

Match the brand's display face (Inter Tight) skeleton so logo and type system cohere:
- **a: double-story** (Inter is a grotesque with double-story a). Single-story a is only correct if an option commits to full Futura-style geometry throughout.
- **g: single-story** (Inter's g is single-story — and the round bowl is the lens opportunity; a double-story g would forfeit it).
- **Terminals: horizontal/vertical cuts** (grotesque), not angled humanist cuts. Pick one terminal logic and apply it to a, g, s identically.
- **i dot: perfect circle, diameter ≈ 1.1–1.2× stem width, gap above stem ≈ 1 stem width. Drawn once, never modified, never colored differently, never replaced.**

---

## SVG Path-Authoring Discipline

### Grid and viewBox

Author on an integer grid scaled so every recurring measurement is a whole number:

```
x-height        = 100 units     (the module everything keys off)
baseline        y = 140
x-height line   y = 40
ascender top    y = 0      (l height = 140 = 1.4 × x-height, Inter-like)
descender floor y = 180    (g drops 40 below baseline = 0.4 × x-height)
overshoot       = 3 units  (round shapes cross baseline/x-height lines by 3)
```

ViewBox for the bare wordmark ≈ `0 0 980 180` (letter widths below sum to ~900 + tracking). Round all coordinates to integers or .5; two decimal places maximum, ever. A coordinate like `141.0327` is a bug, not precision.

### Stem weight and optical-correction recipe (the part AI output always gets wrong)

Pick ONE stem width `S` and derive everything (recommended: **S = 22** at this grid ≈ SemiBold, matching the brand's bold-display energy without clogging counters):

| Element | Width | Why |
|---|---|---|
| Vertical stems (m, i, l, a, g stems) | S = 22 | reference |
| Horizontals (s spine ends, a crossbar region) | 0.90–0.94 × S (20–21) | equal-width horizontals look *fatter* than verticals — under-cut them |
| Round strokes at E/W extremes (g bowl, a bowl sides) | 1.00–1.03 × S | curves look *thinner* than straights — match or slightly exceed |
| Round strokes at N/S extremes | 0.88–0.92 × S | top/bottom of bowls thin like horizontals |
| Branch joints (m shoulders, a bowl→stem, g bowl→stem) | thin the incoming branch 12–18% over the last ~1.5 S before the join | otherwise the joint visually clots ("joint thinning" — the failure AI never applies) |
| Overshoot | 3 units (≈3% of x-height) on every round/pointed extreme touching baseline or x-height | flat-only letters (i, l, m stem tops) get **zero** overshoot |

These corrections are the canon of type design (Frere-Jones, Scannerlicker, Karen Cheng's *Designing Type*): *we read with eyes, not rulers — when measurement and appearance conflict, appearance wins.* Verified against current optical-correction references (HIGH confidence).

### Per-glyph geometry for m a i l g s (advance widths at x-height = 100)

- **m** — width ≈ 150. Three stems; two arches whose shoulders spring from ~y 62 (just above vertical center of x-height); arch counters slightly **narrower** than an n's would be (≈ 30–34 units each) or the m looks bloated; shoulder strokes thin to ~0.85 S where they meet stems; flat stem tops, no overshoot.
- **a (double-story)** — width ≈ 92. Bowl occupies lower ~58 units of x-height; the upper hook/shoulder curves from the stem over the bowl; **bowl counter must stay ≥ 26 units wide** at this weight or it clogs at small sizes; aperture (the gap at lower right between bowl and stem) open by ≥ 0.5 S.
- **i** — stem width S, advance ≈ 22 + sidebearings. Dot per the locked spec above. No overshoot anywhere.
- **l** — bare stem, height 140, flat top, flat baseline foot. The easiest glyph — which means any wobble on it is maximally visible.
- **g (single-story)** — width ≈ 96. Bowl = full o-form (circle-derived, 3-unit overshoot top and bottom of x-height band); stem on the right runs from x-height down through baseline to y ≈ 177, then hooks left with a quarter-to-third circle; hook terminal cut horizontal; hook aperture stays open ≥ 0.6 S. The bowl-stem tangency at right is a joint-thinning site.
- **s** — width ≈ 84. The spine is the **thickest** stroke in the glyph (= S); top and bottom horizontals thin to ~0.88 S; **top counter visibly smaller than bottom counter** (≈ 90% — an evenly-split s looks top-heavy); overshoot 3 at both extremes; terminals cut horizontal; the spine's inflection point sits ON an on-curve node, never mid-segment. Draw the s last, after your eye is calibrated; it will take the most iterations.

**Spacing:** set sidebearings so the gap between two adjacent straight stems (i-l, l-l contexts) ≈ the m's inner counter width (~30–32 units); round-to-straight pairs ~10% tighter; round-to-round ~18% tighter. The brand's display tracking is negative (-2% at 72px), so bias tight — but verify the **l–g channel** and **a–s gap** by eye at 24px-equivalent zoom. There is no kerning table in hand-authored SVG: spacing IS the x-offsets you assign, so record each glyph's advance in a comment.

### Path construction rules

1. **Filled outline paths, not stroked skeletons, for finals.** Strokes can't express the thinning/overshoot table above (`stroke-width` is uniform). Skeleton-with-stroke is fine for roughing in proportions; finals are filled outlines. (Strokes are technically "outlined paths" too, but they lock you out of optical correction — and a monoline look at SemiBold weight clogs every joint.)
2. **Counters via subpath direction:** outer contour clockwise, counters counter-clockwise, default `fill-rule="nonzero"` — or `evenodd` if you prefer not to manage winding. Pick one convention for all 8 options.
3. **On-curve points at extrema only** (N/S/E/W of every curve), handles horizontal/vertical at those points. This is what keeps curves smooth AND keeps the file hand-editable — an editor can drag an extremum without lumping the curve.
4. **Circle-from-béziers constant:** a quarter-circle of radius r needs handle length **0.5523 × r** (e.g., g bowl outer radius 50 → handles ≈ 27.6 → round to 28). For a slightly "superelliptical" modern feel, push to 0.57–0.60 — but use ONE constant everywhere; mixing roundness constants between letters is instantly visible.
5. **No inflections inside a single cubic segment** (the s spine needs an on-curve node at its inflection). No handle longer than the distance to the next on-curve point. No handles crossing.
6. **One `<path>` per glyph**, `data-glyph="g"` attribute, an XML comment with its advance width, glyphs positioned by `transform="translate(x 0)"` during drafting (flatten translates into coordinates only at final export if desired — translated groups remain hand-editable and are fine to ship).
7. **Reuse identical glyphs** (l, a, s each appear twice): draft with `<use>`, but **ship duplicated literal paths** — `<use>` is where editability and some renderer/favicon toolchains get fragile, and the duplicate-letter pairs may want per-instance spacing nudges anyway.
8. **No gradients in marks** (brand book rule, and they muddy at 16px); flat `currentColor`/hex fills; no filters, no masks if a plain subpath can do the job (masks render inconsistently in some favicon pipelines).

### Known failure modes of AI-generated letterform paths (self-audit targets)

These are the specific defects to hunt for in your own output before showing anything:

- **Lumpy curves** — points not at extrema, handles at arbitrary angles → bowls with flat spots or bulges. Audit: zoom to 1600%, trace every curve junction.
- **Stem-width drift** — the m's stems at 22, 23, and 21; the second l thicker than the first. Audit: measure every vertical stem numerically (the coordinates are right there in the `d` attribute — subtract).
- **Missing overshoot** — round letters (a bowl, g bowl, both s's) sitting exactly on the guides → they look smaller and the baseline looks like it dips at flat letters. Audit: g/a/s extremes must read 137→143-style crossings, not 140.
- **Clotted joints** — full-weight branches meeting full-weight stems (m shoulders, a bowl, g bowl-stem) → dark knots at text size. Audit: blur test (squint or view at 10% zoom) — dark spots = clots.
- **Frankenword inconsistency** — terminals cut at different angles per letter, mixed roundness constants, an a from one "font" and an s from another. Audit: overlay all terminals; overlay both s's and both a's and both l's — duplicates must be geometrically identical.
- **Counter fill bugs** — wrong winding/fill-rule silently filling the g bowl or a counter solid. Audit: render, don't trust the math.
- **Baseline/x-height wobble** — letters individually fine but at slightly different heights. Audit: draw temporary guide `<line>`s at y=0/40/140/180 while drafting; delete before export.
- **Decimal soup** — 6-decimal coordinates that make hand-editing hopeless and bloat the file. Audit: grep the `d` attributes for `\.\d{3,}`.

---

## Small-Size Survival

### Design-time rules (not export-time fixes)

1. **The favicon is a redrawn artifact, not a scaled lockup.** Author it on a `viewBox="0 0 16 16"` grid with integer coordinates; strokes/stems ≥ 2 units (= 2px at 1x); 1–2 colors; zero gradients; counters ≥ 2 units. If the chosen mark can't be redrawn under those constraints, the mark is wrong, not the favicon.
2. **Pixel-grid alignment:** at 16px, geometry that straddles pixel boundaries antialiases to fog. Verticals/horizontals on integer x/y; circles centered on integer or .5 coordinates with integer-ish radii.
3. **One-shape marks win small.** Vercel's triangle and Linear's slats survive 16px because they're 1–3 strokes. Budget for marks: ≤ 3 distinct strokes/shapes at favicon scale. A lens-g monogram = 2 shapes (bowl ring + descender hook): viable. An interlocked ss = 4+ curve events in 16px: not viable.
4. **Negative-space motifs need surrounding mass.** FedEx's arrow works small because the letters around it are heavy. A negative-space pane between l and g survives only if the wordmark weight is SemiBold+; at Light weight the channel is just… spacing.
5. **Wordmark minimum size:** the brand book already flags the **gla cluster** as the first to muddy. Enforce: wordmark never rendered below the size where the a's bowl counter and g's bowl counter each subtend ≥ 2px — with the geometry above (counter ≈ 26–44 units on a 180-unit viewBox), that's roughly **wordmark x-height ≥ 8px ⇒ total height ≥ 14–16px** absolute floor, 20px+ recommended. Below that, use mark only.
6. **Stroke-interruption gaps** (refraction/slice motifs) must be ≥ 0.35 × stem width to survive; at favicon scale either re-proportion the gap to ≥ 1.5px or drop the interruption from the small variant entirely (precedent: IBM ships an unstriped small-size wordmark).
7. **Test matrix per option:** render at 16/24/32px on Paper #F8FBFD and on Ink #0D1B2A. The g descender and any boundary-breaking element must not collide with browser-tab cropping (keep ≥ 1px internal margin in the 16-grid even while "breaking" the visual boundary of the mark itself — break the *mark's* implied frame, not the viewBox).

### Lockup tightness (the "tight logotype" constraint, with a number)

Set the mark-to-wordmark gap at **0.5–0.75 × wordmark x-height** (at the grid above: 50–75 units), optically adjusted: round mark edges can sit tighter than flat edges. Vertically, align the mark's optical center to the wordmark's x-height midline (y = 90), not to cap/ascender midline — lowercase wordmarks read center-of-mass low. No subtitle in the lockup; no plate behind anything.

---

## Craft Failure Checklist

Self-screen every option against all items before it enters the tournament. Any ✗ = fix or kill the option.

**Constraint compliance**
- [ ] No rectangular (or rounded-rectangular) background plate behind mark or wordmark
- [ ] Mark breaks an implied boundary somewhere (descender, overshoot element, stroke escaping the mark's frame)
- [ ] Lockup gap ≤ 0.75 × x-height; no subtitle
- [ ] i dot untouched: perfect circle, standard size/position/color
- [ ] No envelope-flap-as-motif literalism, paper planes, mailboxes, send arrows, mascots, glassmorphism, gradients-in-marks, bevels

**Typographic correctness**
- [ ] All vertical stems measure identical (numeric check, not eyeball)
- [ ] Horizontals and curve-tops thinner than stems per the correction table
- [ ] Overshoot present on every round extreme (a, g, both s's), absent on every flat one (i, l, m)
- [ ] No clotted joints at 10% zoom / squint test
- [ ] Both l's identical; both a's identical; both s's identical (unless a *deliberate, motivated* asymmetry IS the concept — then it must be obviously intentional, not 4% off)
- [ ] One terminal logic, one roundness constant, one skeleton style across all 9 letters
- [ ] Even spacing rhythm: no dark l-g collision, no a-s gap hole; word reads as one texture at 25% zoom
- [ ] s's don't lean; top counters smaller than bottom

**Motif quality**
- [ ] The modification is discoverable but optional — the word reads perfectly for someone who never sees it (FedEx test)
- [ ] Exactly ONE modification idea per option (Braun dosage); no stacking tricks
- [ ] The motif means something specific to "mail you can see through" — could you caption it in ≤ 6 words without the word "clever"?
- [ ] No accidental resemblance to Linear's slats, Glassdoor, Gmail, or any envelope-category mark

**SVG hygiene**
- [ ] Filled outline paths; no `<text>`, no `font-family`, no live strokes in finals (draft strokes removed)
- [ ] Points at extrema; ≤ 2 decimal places; no handle crossings; counters render hollow
- [ ] One path per glyph with `data-glyph`; advance widths commented; guide lines deleted
- [ ] viewBox minimal (no dead margin beyond clear-space intent); `currentColor` or brand hexes only

**Small-size proof**
- [ ] Dedicated 16×16 redraw exists for the mark (integer grid, ≤ 3 shapes, 1–2 colors)
- [ ] Lockup tested at 24px height and 32px height on Paper and on Ink — motif either survives or has a documented small-size fallback
- [ ] No counter below 2px at the declared minimum size; "gla" cluster legible at the wordmark floor

---

## Sources

**Type design optical corrections (HIGH confidence — verified current):**
- [Logo Geek — Optical corrections every logo designer should know](https://logogeek.uk/logo-design/optical-corrections/)
- [Scannerlicker — The Art of Eyeballing III: Overshooting](https://learn.scannerlicker.net/2014/09/03/the-art-of-eyeballing-part-3-overshooting/) and [IV: The Stroke (Optics)](https://learn.scannerlicker.net/2014/10/25/the-art-of-eyeballing-iv-the-stroke-optics/)
- [Wikipedia — Overshoot (typography)](https://en.wikipedia.org/wiki/Overshoot_(typography))
- [Fast Company — Why all typefaces are optical illusions (Frere-Jones)](https://www.fastcompany.com/3042391/why-all-typefaces-are-optical-illusions)
- [TypeType — Designing basic lowercase characters](https://typetype.org/blog/universitty-lesson-10-designing-basic-lowercase-characters/)

**Named-logo precedents (HIGH confidence — verified):**
- [The FedEx logo and its hidden arrow (Lindon Leader, Univers 67 + Futura Bold)](https://www.designermurat.com/post/the-fedex-logo-a-masterclass-in-simplicity-and-hidden-genius); [Inkbot Design — FedEx logo history](https://inkbotdesign.com/history-of-the-fedex-logo-design/)
- [Fabrik Brands — Famous negative-space logos (Goodwill, Carrefour)](https://fabrikbrands.com/branding-matters/logofile/famous-logos-that-use-negative-space/); [The Branding Journal — logos with hidden meanings](https://www.thebrandingjournal.com/2023/04/logos-hidden-meanings/)
- Mozilla `moz://a` (Johnson Banks, 2017), Sony VAIO, IBM 8-bar, Braun raised-A (1934), Dell tilted-E, Gillette slice — training data, widely documented brand histories (MEDIUM-HIGH)

**Devtool brand systems (MEDIUM confidence — partially verified):**
- [Stripe design-system documentation (Söhne, weight 300, negative tracking)](https://awesome-design-md-visualizer.vercel.app/preview/stripe); [Supabase brand assets](https://supabase.com/brand-assets); [Setproduct — the Vercel aesthetic](https://www.setproduct.com/blog/complete-guide-to-blueprint-grid-design)

**Favicon/small-size (MEDIUM-HIGH confidence — multiple sources agree):**
- [10Web — Designing a favicon recognizable at 16×16](https://10web.io/blog/favicon-design/); [PremiumFavicon — logo-to-favicon adaptation guide](https://www.premiumfavicon.com/blog/how-to-make-favicon-from-logo)

**Project-internal:**
- `prompts/mailglass-brand-book.md` §7.2 (logo direction, "gla cluster" minimum-size warning, logo don'ts), §11 (visual don'ts)
- `.planning/PROJECT.md` Current Milestone (tournament constraints, outlined-path requirement)
- `brandbook/assets/logo-primary.svg` (frozen v1.8 baseline: live `<text>` Avenir Next wordmark — the exact dependency the v1.9 outlined-path requirement eliminates)
