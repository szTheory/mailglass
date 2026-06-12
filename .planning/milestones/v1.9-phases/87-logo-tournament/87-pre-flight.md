# Phase 87 Round-1 Pre-Flight Screen

One row per option x constraint: 8 options x 14 constraints (C-01..C-14) = 112 rows.
An option failing any check is fixed or replaced before presentation — never shown failing.
Verdicts for C-05..C-08 were back-filled from the browser visual audit
(screenshots under `tmp/87-logo-tournament/round-1/`, rendered with Playwright
from `tournament/round-1.html` and read by eye before the checkpoint).

Constraint key: C-01 no background plate (no <rect> or rounded-rect path covering
>80% of the viewBox behind the mark/word; every rect-like figure recorded
numerically) | C-02 visible boundary-break at presentation size | C-03 tight
lockup (gap <= 0.75 x x-height; axis B also <= 0.4 x mark width; smaller bound
binds) | C-04 no subtitle | C-05 16px legibility | C-06 32px legibility |
C-07 mono/currentColor | C-08 dark theme | C-09 i dot untouched | C-10 banned
motif families | C-11 no v1.8 A-R/07r revival | C-12 SVG validity (xmllint,
viewBox, role, title+desc, oN- unique ids) | C-13 outlined paths only |
C-14 no Linear/Glassdoor/Gmail/envelope-category resemblance.

Fix-or-replace log (issues caught by the render audit BEFORE presentation):
option-5 first draft read as "q" (no hook) — hook added; option-6 bowl counter
had a winding bug (rendered solid) — reversed to counter-clockwise; the m's
inter-arch notch was an invisible cusp — opened to a visible V; the s spine
junctions kinked — tangent-matched; option-1 loop mouth widened for small-size
openness; option-6 lockup gap tightened 57->30u. No option needed replacement.

| Option | Constraint | Verdict | Evidence |
|--------|------------|---------|----------|
| option-1 | C-01 | PASS | zero <rect> elements; no rect-like path behind the word — glyph paths only on raw background |
| option-1 | C-02 | PASS | g descender loop reaches y=179.5, 39.5u below the y=140 baseline of an otherwise flat word; visible in large render |
| option-1 | C-03 | PASS | single-unit typemark; no mark-to-word gap exists, word set on one advance chain (max inter-glyph gap 31u < 75u) |
| option-1 | C-04 | PASS | word only; no subtitle, slogan, or secondary text |
| option-1 | C-05 | PASS | 16px favicon crop (the g) legible, counters open — tmp/87-logo-tournament/round-1/option-1-favicon-zoom.png |
| option-1 | C-06 | PASS | 32px header crop legible, loop aperture visible — tmp/87-logo-tournament/round-1/option-1-favicon-zoom.png |
| option-1 | C-07 | PASS | all paths currentColor; mono cell renders single-color — tmp/87-logo-tournament/round-1/option-1-strip.png |
| option-1 | C-08 | PASS | dark cell + dark section render in Mist text token — tmp/87-logo-tournament/round-1/option-1-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-1 | C-09 | PASS | i dot is the shared literal path: circle d=25 (1.14xS) at (11,5.5), gap 22u above stem; untouched, same color as word |
| option-1 | C-10 | PASS | letterforms only; no glassmorphism/gradient/plane/mailbox/arrow/bubble/mascot/node motif present |
| option-1 | C-11 | PASS | open-loop descender is a LOGO-CRAFT candidate play; no A-R shape (header/console/checksum/etc.) or 07r envelope+pane reused |
| option-1 | C-12 | PASS | xmllint pass; viewBox -16 -16 801 212; role=img; title+desc with o1- prefixed ids, globally unique |
| option-1 | C-13 | PASS | 9 filled outline paths, one per glyph with data-glyph + advance comments; zero <text>, font-family, or live strokes |
| option-1 | C-14 | PASS | pure wordmark; no mark to collide with Linear slats, Glassdoor, Gmail, or any envelope-category shape |
| option-2 | C-01 | PASS | zero <rect> elements; sheared stem is two glyph subpaths, no plate behind the word |
| option-2 | C-02 | PASS | g descender to y=177 below baseline (natural break kept visible); shear adds a second visible discontinuity at y 70-78 |
| option-2 | C-03 | PASS | single-unit typemark; no mark-to-word gap exists (max inter-glyph gap 31u < 75u) |
| option-2 | C-04 | PASS | word only; no subtitle or slogan |
| option-2 | C-05 | PASS | 16px crop (l-g seam) legible; shear gap survives at 1px+ — tmp/87-logo-tournament/round-1/option-2-favicon-zoom.png |
| option-2 | C-06 | PASS | 32px crop crisp; displaced stem clearly deliberate — tmp/87-logo-tournament/round-1/option-2-favicon-zoom.png |
| option-2 | C-07 | PASS | all paths currentColor; mono cell renders single-color — tmp/87-logo-tournament/round-1/option-2-strip.png |
| option-2 | C-08 | PASS | dark cell + dark section legible — tmp/87-logo-tournament/round-1/option-2-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-2 | C-09 | PASS | i dot is the shared literal path, untouched; the shear touches only the l stem (a straight, never a curve) |
| option-2 | C-10 | PASS | one Gillette-pattern stroke shear; no banned motif family present |
| option-2 | C-11 | PASS | differs from v1.8 option-r (standalone refraction-line mark): here refraction is worked into ONE wordmark stem per the LOGO-CRAFT shear play; no A-R/07r shape reused |
| option-2 | C-12 | PASS | xmllint pass; viewBox -16 -16 801 212; role=img; title+desc with o2- ids, globally unique |
| option-2 | C-13 | PASS | paths only; shear gap 8u = 0.36xS (>= 0.35xS rule), displaced segment stays vertical (+8u shift) |
| option-2 | C-14 | PASS | pure wordmark; no envelope-category, Linear, Glassdoor, or Gmail resemblance |
| option-3 | C-01 | PASS | zero <rect> elements; pane is a 110x110u open frame path vs 1029x212 viewBox (10.7% width) — a mark, not a plate; nothing sits on it |
| option-3 | C-02 | PASS | pane bottom edge at y=145 crosses the y=140 baseline; bar escapes the pane left (-36) and right (146) |
| option-3 | C-03 | PASS | gap mark-to-word = 50u: <= 0.4 x mark width (0.4x182=72.8) and within 0.5-0.75 x x-height (50-75); mark optical center y=90 |
| option-3 | C-04 | PASS | mark + word only; no subtitle |
| option-3 | C-05 | PASS | 16px tab render: frame + bar both read — tmp/87-logo-tournament/round-1/option-3-favicon-zoom.png |
| option-3 | C-06 | PASS | 32px header render crisp — tmp/87-logo-tournament/round-1/option-3-favicon-zoom.png |
| option-3 | C-07 | PASS | mono cell: pane hex swapped to currentColor, single-color read holds — tmp/87-logo-tournament/round-1/option-3-strip.png |
| option-3 | C-08 | PASS | dark cells: accent maps Glass->Ice per token system — tmp/87-logo-tournament/round-1/option-3-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-3 | C-09 | PASS | wordmark i dot is the shared literal path, untouched |
| option-3 | C-10 | PASS | pane+bar geometry; no glassmorphism, gradients, planes, mailboxes, send arrows, bubbles, mascots, or node-graphs |
| option-3 | C-11 | PASS | no v1.8 shape: not 07r envelope+pane (no envelope, no tilt, no gradient), not option-i cursor or option-m brackets |
| option-3 | C-12 | PASS | xmllint pass; viewBox -48 -16 1029 212; role=img; title+desc with o3- ids, globally unique |
| option-3 | C-13 | PASS | paths only (pane frame, bar, 9 glyphs); zero <text>/font-family; draft strokes removed |
| option-3 | C-14 | PASS | portrait open frame with through-bar: no flap (not envelope), no parallel slats (Linear), no G-door (Glassdoor), no M (Gmail) |
| option-4 | C-01 | PASS | zero <rect> elements; pane-edge path is 12x132u (1.3% of 933u viewBox width) — an edge, not a plate |
| option-4 | C-02 | PASS | pane edge runs y 22-154: crosses the baseline and escapes the disc (38.4-137.6) top and bottom |
| option-4 | C-03 | PASS | gap mark-to-word = 40u: <= 0.4 x mark width (0.4x100=40) — smaller bound binds; mark optical center y=88 |
| option-4 | C-04 | PASS | mark + word only; no subtitle |
| option-4 | C-05 | PASS | 16px tab render: solid half + open ring + edge all read — tmp/87-logo-tournament/round-1/option-4-favicon-zoom.png |
| option-4 | C-06 | PASS | 32px header render crisp — tmp/87-logo-tournament/round-1/option-4-favicon-zoom.png |
| option-4 | C-07 | PASS | mono cell: edge hex swapped to currentColor; solid-vs-outline carries the idea in one color — tmp/87-logo-tournament/round-1/option-4-strip.png |
| option-4 | C-08 | PASS | dark cells: edge maps Glass->Ice; ring/disc in Mist — tmp/87-logo-tournament/round-1/option-4-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-4 | C-09 | PASS | wordmark i dot is the shared literal path, untouched |
| option-4 | C-10 | PASS | flat shapes; transparency carried by outline-vs-solid, not opacity or blur (no glassmorphism, no gradients) |
| option-4 | C-11 | PASS | no v1.8 shape reused; not option-j at-lens (no @, no header traces), not 07r |
| option-4 | C-12 | PASS | xmllint pass; viewBox -12 -16 933 212; role=img; title+desc with o4- ids, globally unique |
| option-4 | C-13 | PASS | paths only (disc, ring, edge, 9 glyphs); arcs for perfect circles; zero <text>/font-family |
| option-4 | C-14 | PASS | split disc + edge: not an envelope, not slats, not Glassdoor G, not Gmail M; differs from a11y-contrast icon (open ring, escaping edge) |
| option-5 | C-01 | PASS | zero <rect> elements; ring + stem only on raw background |
| option-5 | C-02 | PASS | stem+hook descends to y=174, 34u below baseline; hook sweeps left under the lens |
| option-5 | C-03 | PASS | gap mark-to-word = 30u: within 0.5-0.75 x small-wordmark x-height (25-37.5) and <= 0.4 x mark width (42.4) |
| option-5 | C-04 | PASS | monogram + small wordmark only; no subtitle |
| option-5 | C-05 | PASS | 16px tab render: ring + hooked stem = 2 shapes, counters open — tmp/87-logo-tournament/round-1/option-5-favicon-zoom.png |
| option-5 | C-06 | PASS | 32px header render crisp — tmp/87-logo-tournament/round-1/option-5-favicon-zoom.png |
| option-5 | C-07 | PASS | mono cell: ring hex swapped to currentColor; g still reads — tmp/87-logo-tournament/round-1/option-5-strip.png |
| option-5 | C-08 | PASS | dark cells: ring maps Glass->Ice — tmp/87-logo-tournament/round-1/option-5-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-5 | C-09 | PASS | small wordmark i dot is the shared literal path scaled as a unit, untouched |
| option-5 | C-10 | PASS | geometric ring + stroke; no banned motif family present |
| option-5 | C-11 | PASS | no v1.8 shape: not option-e mg-header-mark (no header lines in counter), not 07r; ring is a drawn glyph bowl, not a lens flare |
| option-5 | C-12 | PASS | xmllint pass; viewBox -12 -16 545 212; role=img; title+desc with o5- ids, globally unique |
| option-5 | C-13 | PASS | paths only; perfect circles via arc commands; zero <text>/font-family |
| option-5 | C-14 | PASS | reads as g first (Futura-pattern single-story); no envelope, slats, Glassdoor, or Gmail resemblance |
| option-6 | C-01 | PASS | zero <rect> elements; ligature paths only on raw background |
| option-6 | C-02 | PASS | g hook descends to y=177, 37u below the baseline the m sits on |
| option-6 | C-03 | PASS | gap mark-to-word = 30u: within 0.5-0.75 x small-wordmark x-height (25-37.5) and <= 0.4 x mark width (74.4) |
| option-6 | C-04 | PASS | monogram + small wordmark only; no subtitle |
| option-6 | C-05 | PASS | 16px tab render: mg reads, bowl counter open — tmp/87-logo-tournament/round-1/option-6-favicon-zoom.png |
| option-6 | C-06 | PASS | 32px header render crisp — tmp/87-logo-tournament/round-1/option-6-favicon-zoom.png |
| option-6 | C-07 | PASS | single-color by construction (all currentColor) — tmp/87-logo-tournament/round-1/option-6-strip.png |
| option-6 | C-08 | PASS | dark cells legible in Mist — tmp/87-logo-tournament/round-1/option-6-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-6 | C-09 | PASS | small wordmark i dot is the shared literal path scaled as a unit, untouched |
| option-6 | C-10 | PASS | letterform ligature; no banned motif family present |
| option-6 | C-11 | PASS | no v1.8 shape: not option-e mg-header-mark (no header lines, different construction: shared stem, no counter content) |
| option-6 | C-12 | PASS | xmllint pass; viewBox -12 -16 625 212; role=img; title+desc with o6- ids, globally unique |
| option-6 | C-13 | PASS | paths only (m, bowl+stem+hook, 9 small glyphs); zero <text>/font-family |
| option-6 | C-14 | PASS | two-letter ligature; no envelope, slats, Glassdoor, or Gmail resemblance |
| option-7 | C-01 | PASS | zero <rect> elements; one solid disc contour with the slot cut from it, on raw background |
| option-7 | C-02 | PASS | disc spans y 34-146, crossing the baseline; the slot void exits through the disc's right edge (figure boundary broken by absence) |
| option-7 | C-03 | PASS | gap mark-to-word = 44u: <= 0.4 x mark width (0.4x112=44.8) and within 50-75 tolerance band (smaller bound binds); optical center y=90 |
| option-7 | C-04 | PASS | mark + word only; no subtitle |
| option-7 | C-05 | PASS | 16px tab render: disc + slot crisp (slot 2.6px) — tmp/87-logo-tournament/round-1/option-7-favicon-zoom.png |
| option-7 | C-06 | PASS | 32px header render crisp — tmp/87-logo-tournament/round-1/option-7-favicon-zoom.png |
| option-7 | C-07 | PASS | single-color by construction (all currentColor); void does the work — tmp/87-logo-tournament/round-1/option-7-strip.png |
| option-7 | C-08 | PASS | dark cells legible in Mist — tmp/87-logo-tournament/round-1/option-7-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-7 | C-09 | PASS | wordmark i dot is the shared literal path, untouched |
| option-7 | C-10 | PASS | negative-space slot; no broken glass (clean cut, no shards), no banned motif family |
| option-7 | C-11 | PASS | no v1.8 shape: not option-q caliper, not option-o timeline; no A-R or 07r geometry reused |
| option-7 | C-12 | PASS | xmllint pass; viewBox -12 -16 949 212; role=img; title+desc with o7- ids, globally unique |
| option-7 | C-13 | PASS | paths only (single contour disc-with-slot + 9 glyphs); zero <text>/font-family |
| option-7 | C-14 | PASS | slot exits the edge and figure stays SemiBold-massive: not a centered minus badge, not envelope/Linear/Glassdoor/Gmail |
| option-8 | C-01 | PASS | zero <rect> elements; the 96x96u square IS the mark figure (9.8% of 975u viewBox width), drawn as a path with nothing on top of it |
| option-8 | C-02 | PASS | circle spans y 84-152, crossing the baseline and escaping the square's right edge (to x=130 vs square 96) |
| option-8 | C-03 | PASS | gap mark-to-word = 52u: <= 0.4 x mark width (0.4x130=52) and within 50-75; optical center y=90 band |
| option-8 | C-04 | PASS | mark + word only; no subtitle |
| option-8 | C-05 | PASS | 16px tab render: square + bite + half-disc all read — tmp/87-logo-tournament/round-1/option-8-favicon-zoom.png |
| option-8 | C-06 | PASS | 32px header render crisp — tmp/87-logo-tournament/round-1/option-8-favicon-zoom.png |
| option-8 | C-07 | PASS | single-color by construction (one even-odd path, currentColor) — tmp/87-logo-tournament/round-1/option-8-strip.png |
| option-8 | C-08 | PASS | dark cells legible in Mist — tmp/87-logo-tournament/round-1/option-8-strip.png, tmp/87-logo-tournament/round-1/full-dark.png |
| option-8 | C-09 | PASS | wordmark i dot is the shared literal path, untouched |
| option-8 | C-10 | PASS | overlap voided by even-odd winding — transparency as geometry, not opacity; no gradients, no glassmorphism |
| option-8 | C-11 | PASS | no v1.8 shape: not 07r (no envelope, no tilt, no gradient pane); no A-R geometry reused |
| option-8 | C-12 | PASS | xmllint pass; viewBox -12 -16 975 212; role=img; title+desc with o8- ids, globally unique |
| option-8 | C-13 | PASS | paths only (one even-odd mark path + 9 glyphs); zero <text>/font-family |
| option-8 | C-14 | PASS | square+circle exclusion: not two-circle Mastercard, not copy-icon (mixed shapes), not envelope/Linear/Glassdoor/Gmail |

112 rows, 112 PASS. Options presented in `tournament/round-1.html`.

## Round 2

Six variants of the round-1 pick (option 8, "the shared light") screened against
C-01..C-14 plus a new standing constraint recorded at the round-1 checkpoint:

C-15 — no broken read: nothing may read as broken, severed, fractured, or
bitten; voids must read as LIGHT passing through (the option-2 rejection rule).
A lens position whose void reads as a bite out of the pane fails.

6 variants x 15 constraints = 90 rows. Verdicts for C-05..C-08 and C-15 were
back-filled from the browser visual audit (screenshots under
`tmp/87-logo-tournament/round-2/`, rendered with Playwright from
`tournament/round-2.html` and read by eye before the checkpoint; corner-straddle
variants additionally judged at 280px in `marks-closeup.png`).

Shared facts (every variant): wordmark is the round-1 option-8 glyph paths
VERBATIM (only the group translate-x changes); mark is ONE even-odd path
(pane subpath + lens-circle subpath), all currentColor with root fallback
color="#0D1B2A"; ids prefixed v8a-..v8f-, unique per file and across the
gallery page.

Design-exam-driven deviations (documented, not silent): 8C and 8E hold the
lockup gap at the baseline's 0.40 x mark-width RATIO (47u and 45u) because the
absolute 52u gap would exceed the C-03 bound once the mark narrows —
constraint-driven, not a second design parameter. 8F is the sanctioned SPINOFF
(maintainer: "variations AND spinoffs... improve it significantly") and
combines three families; it is labeled as such everywhere. One explored
construction was REJECTED before drawing: pane-as-outline-frame with a solid
lens — under even-odd geometry a solid lens crossing a solid frame bar always
voids at the crossing, splitting the lens into disconnected solid fragments
(a guaranteed C-15 severed read). Rounded pane corners were also rejected:
a solid rounded square enters badge/plate vocabulary (C-01 adjacency).

| Variant | Constraint | Verdict | Evidence |
|--------|------------|---------|----------|
| 8A lens40 | C-01 | PASS | zero <rect>; one even-odd mark path + 9 glyph paths on raw background; nothing sits on the pane |
| 8A lens40 | C-02 | PASS | lens r40 at (96,118) crosses the pane's right edge and dips 20u below pane bottom (158 vs 138); clearly visible at presentation size |
| 8A lens40 | C-03 | PASS | gap 52u: <= 0.4 x mark width (0.4x136=54.4) and <= 0.75 x x-height (75); mark optical center y=90 |
| 8A lens40 | C-04 | PASS | mark + word only; no subtitle |
| 8A lens40 | C-05 | PASS | 16px tab: void half-lens still subtends ~4px and reads — tmp/87-logo-tournament/round-2/variant-8A-favicon-zoom.png |
| 8A lens40 | C-06 | PASS | 32px header crisp; the larger lens is the best small-size survivor of the field — same zoom file |
| 8A lens40 | C-07 | PASS | all paths currentColor; mono cell single-color — variant-8A-strip.png |
| 8A lens40 | C-08 | PASS | dark cell + dark section render in Mist text token — variant-8A-strip.png, full-dark.png |
| 8A lens40 | C-09 | PASS | i dot is the round-1 literal path, untouched (d=24.5 circle at (11,5.5), 22u above stem) |
| 8A lens40 | C-10 | PASS | square+circle geometry; no glassmorphism/gradient/plane/mailbox/arrow/bubble/mascot/node motif |
| 8A lens40 | C-11 | PASS | derives only from round-1 option 8; no A-R or 07r shape |
| 8A lens40 | C-12 | PASS | xmllint pass; viewBox -12 -16 981 212; role=img; title+desc; v8a- ids unique |
| 8A lens40 | C-13 | PASS | filled outline paths only; zero <text>/font-family/live strokes |
| 8A lens40 | C-14 | PASS | not Mastercard (one circle), not Linear slats, not Glassdoor/Gmail/envelope |
| 8A lens40 | C-15 | PASS | void = pane-lens overlap only; solid outer half completes the circle gestalt; pane edge reads as a chord through the lens, not a cut — marks-closeup.png |
| 8B corner | C-01 | PASS | zero <rect>; one even-odd mark path + 9 glyph paths on raw background |
| 8B corner | C-02 | PASS | lens r34 centered ON the bottom-right corner (96,138) breaks TWO edges: 34u right and 34u below; the strongest boundary-break in the field |
| 8B corner | C-03 | PASS | gap 52u: <= 0.4 x mark width (0.4x130=52, exact bound) and <= 75; mark optical center y=90 |
| 8B corner | C-04 | PASS | mark + word only; no subtitle |
| 8B corner | C-05 | PASS | 16px tab: square + corner-dot silhouette distinct; void quarter visible — variant-8B-favicon-zoom.png |
| 8B corner | C-06 | PASS | 32px header: quarter-light read clear — same zoom file |
| 8B corner | C-07 | PASS | all currentColor; mono cell single-color — variant-8B-strip.png |
| 8B corner | C-08 | PASS | dark cell + dark section legible — variant-8B-strip.png, full-dark.png |
| 8B corner | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8B corner | C-10 | PASS | square+circle geometry only; no banned motif family |
| 8B corner | C-11 | PASS | derives only from round-1 option 8; no A-R or 07r shape |
| 8B corner | C-12 | PASS | xmllint pass; viewBox -12 -16 975 212; role=img; title+desc; v8b- ids unique |
| 8B corner | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8B corner | C-14 | PASS | not Mastercard/Linear/Glassdoor/Gmail/envelope; corner-overlap composition is distinct |
| 8B corner | C-15 | PASS | judged at 280px in marks-closeup.png: three quarters of the lens stay solid so the circle never reads cut; the pane corner reads LIT (bounded by both shapes' edges), not bitten — the solid circle mass wraps the corner from outside |
| 8C portrait | C-01 | PASS | zero <rect>; one even-odd mark path + 9 glyph paths on raw background |
| 8C portrait | C-02 | PASS | lens r34 at (84,120) crosses the right edge and dips 14u below pane bottom (154 vs 140); visible at presentation size |
| 8C portrait | C-03 | PASS | gap 47u: <= 0.4 x mark width (0.4x118=47.2, ratio held from baseline) and <= 75; pane center y=90 |
| 8C portrait | C-04 | PASS | mark + word only; no subtitle |
| 8C portrait | C-05 | PASS | 16px tab: portrait silhouette + lens bump read — variant-8C-favicon-zoom.png |
| 8C portrait | C-06 | PASS | 32px header crisp; window read (taller than wide) survives — same zoom file |
| 8C portrait | C-07 | PASS | all currentColor; mono cell single-color — variant-8C-strip.png |
| 8C portrait | C-08 | PASS | dark cell + dark section legible — variant-8C-strip.png, full-dark.png |
| 8C portrait | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8C portrait | C-10 | PASS | rectangle+circle geometry only; no banned motif family |
| 8C portrait | C-11 | PASS | derives only from round-1 option 8; portrait pane is NOT the 07r envelope (no flap, no tilt, no gradient) |
| 8C portrait | C-12 | PASS | xmllint pass; viewBox -12 -16 958 212; role=img; title+desc; v8c- ids unique |
| 8C portrait | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8C portrait | C-14 | PASS | portrait pane flush to type band: not a folder tab, not Linear/Glassdoor/Gmail/envelope |
| 8C portrait | C-15 | PASS | void = overlap only; solid outer half completes the circle; pane edges flush to x-height line (y40) and baseline (y140) read as registration, not cropping — marks-closeup.png |
| 8D gap40 | C-01 | PASS | zero <rect>; mark identical to the approved baseline |
| 8D gap40 | C-02 | PASS | identical to baseline: lens dips 14u below pane bottom (152 vs 138) |
| 8D gap40 | C-03 | PASS | gap 40u: <= 0.4 x mark width (52) with margin and <= 75; tightest legal lockup of the field |
| 8D gap40 | C-04 | PASS | mark + word only; no subtitle |
| 8D gap40 | C-05 | PASS | 16px tab identical to approved baseline mark — variant-8D-favicon-zoom.png |
| 8D gap40 | C-06 | PASS | 32px header identical to approved baseline mark — same zoom file |
| 8D gap40 | C-07 | PASS | all currentColor; mono cell single-color — variant-8D-strip.png |
| 8D gap40 | C-08 | PASS | dark cell + dark section legible — variant-8D-strip.png, full-dark.png |
| 8D gap40 | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8D gap40 | C-10 | PASS | square+circle geometry only; no banned motif family |
| 8D gap40 | C-11 | PASS | mark is round-1 option 8 verbatim; only the lockup gap changed |
| 8D gap40 | C-12 | PASS | xmllint pass; viewBox -12 -16 963 212; role=img; title+desc; v8d- ids unique |
| 8D gap40 | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8D gap40 | C-14 | PASS | same exclusions as the approved baseline |
| 8D gap40 | C-15 | PASS | mark geometry unchanged from the approved baseline; no new void introduced |
| 8E pane80 | C-01 | PASS | zero <rect>; one even-odd mark path + 9 glyph paths on raw background |
| 8E pane80 | C-02 | PASS | lens r34 at (80,110) crosses the right edge and dips 14u below pane bottom (144 vs 130); visible at presentation size |
| 8E pane80 | C-03 | PASS | gap 45u: <= 0.4 x mark width (0.4x114=45.6, ratio held from baseline) and <= 75; pane center y=90 |
| 8E pane80 | C-04 | PASS | mark + word only; no subtitle |
| 8E pane80 | C-05 | PASS | 16px tab: near-equal square and lens both read; best mass balance at small size — variant-8E-favicon-zoom.png |
| 8E pane80 | C-06 | PASS | 32px header: lens reads as co-star, void wide open — same zoom file |
| 8E pane80 | C-07 | PASS | all currentColor; mono cell single-color — variant-8E-strip.png |
| 8E pane80 | C-08 | PASS | dark cell + dark section legible — variant-8E-strip.png, full-dark.png |
| 8E pane80 | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8E pane80 | C-10 | PASS | square+circle geometry only; no banned motif family |
| 8E pane80 | C-11 | PASS | derives only from round-1 option 8; no A-R or 07r shape |
| 8E pane80 | C-12 | PASS | xmllint pass; viewBox -12 -16 952 212; role=img; title+desc; v8e- ids unique |
| 8E pane80 | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8E pane80 | C-14 | PASS | lens/pane = 85% approaches two-equal-shapes: checked against Mastercard (two circles — not this) and copy-icon (two same shapes — not this, mixed square+circle) |
| 8E pane80 | C-15 | PASS | void = overlap only; solid outer half completes the circle gestalt — marks-closeup.png |
| 8F synthesis | C-01 | PASS | zero <rect>; one even-odd mark path + 9 glyph paths on raw background |
| 8F synthesis | C-02 | PASS | lens r36 ON the bottom-right corner (84,140) breaks two edges: 36u right and 36u below to y176, landing beside the g descender's y177 |
| 8F synthesis | C-03 | PASS | gap 40u: <= 0.4 x mark width (0.4x120=48) and <= 75; pane center y=90 |
| 8F synthesis | C-04 | PASS | mark + word only; no subtitle |
| 8F synthesis | C-05 | PASS | 16px tab: portrait pane + corner lens silhouette distinct — variant-8F-favicon-zoom.png |
| 8F synthesis | C-06 | PASS | 32px header: quarter-light read clear, descender echo visible — same zoom file |
| 8F synthesis | C-07 | PASS | all currentColor; mono cell single-color — variant-8F-strip.png |
| 8F synthesis | C-08 | PASS | dark cell + dark section legible — variant-8F-strip.png, full-dark.png |
| 8F synthesis | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8F synthesis | C-10 | PASS | rectangle+circle geometry only; no banned motif family |
| 8F synthesis | C-11 | PASS | derives only from round-1 option 8; not 07r (no flap/tilt/gradient) |
| 8F synthesis | C-12 | PASS | xmllint pass; viewBox -12 -16 953 212; role=img; title+desc; v8f- ids unique |
| 8F synthesis | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8F synthesis | C-14 | PASS | not Mastercard/Linear/Glassdoor/Gmail/envelope; corner-overlap on a portrait pane is distinct |
| 8F synthesis | C-15 | PASS | judged at 280px in marks-closeup.png: three quarters of the lens solid, circle never reads cut; the lit corner is bounded by both shapes' edges and reads as shared light, not a bite |

90 rows, 90 PASS. Variants presented in `tournament/round-2.html` after the
round-1 baseline.

## Round 3 (final — pick or stop)

Four candidates on the locked 8F direction (portrait pane 84x100 at (0,40),
lens r36 on the bottom-right corner (84,140), gap 40, wordmark verbatim),
screened against C-01..C-15. Per the round-2 directive the round varies the
IMAGERY in the mark and introduces the COLOR PROGRAM; mono was a constraint
test, not the identity.

Color rules screened in addition to the constraint table: fills are Phase 86
tokens ONLY (Ink #0D1B2A, Glass #277B96, Ice #A6EAF2, Mist #EAF6FB; glass-deep
#1D637A permitted but unused) — verified by hex extraction over all 12 files;
zero gradients, masks, filters, url() refs, or opacity anywhere; every
candidate ships a mono single-path even-odd master (currentColor, root
fallback color="#0D1B2A") as the canonical fallback, and both color versions
are layered paths over the mono master's EXACT geometry (the color union
reproduces the mono silhouette identically).

4 candidates x 15 constraints = 60 rows. Verdicts for C-05..C-08 and C-15 were
back-filled from the browser visual audit (screenshots under
`tmp/87-logo-tournament/round-3/`: pre-draw design-exam closeups
`exam-8F[1-4].png` at 280px in mono + color-light + color-dark, gallery strips,
favicon zooms at 16/32px in color AND mono, full-page light + dark, darkland).

Shared facts (every candidate): wordmark is the round-1 option-8 glyph paths
VERBATIM at translate(160 0); ids prefixed r38f[1-4][mcd]-, unique per file and
across the gallery; files named variant-8F{N}-{name}-{mono,color-light,
color-dark}.svg in `tournament/round-3/`.

| Candidate | Constraint | Verdict | Evidence |
|--------|------------|---------|----------|
| 8F-1 as-is | C-01 | PASS | zero <rect>; mono is one even-odd path; color is two layered paths (notched pane + three-quarter lens) on raw background |
| 8F-1 as-is | C-02 | PASS | 8F verbatim: lens breaks two pane edges, 36u right and 36u below to y176 beside the g descender's y177 |
| 8F-1 as-is | C-03 | PASS | gap 40u: <= 0.4 x mark width (0.4x120=48) and <= 75; pane center y=90 |
| 8F-1 as-is | C-04 | PASS | mark + word only; no subtitle |
| 8F-1 as-is | C-05 | PASS | 16px tab in COLOR and mono: pane/lens split read holds, Ink + Glass distinct — cand-8F1-favicon-zoom.png |
| 8F-1 as-is | C-06 | PASS | 32px header in color crisp; the two-tone split makes lens-vs-pane read FASTER than mono — same zoom file |
| 8F-1 as-is | C-07 | PASS | mono master is the canonical fallback, all currentColor, single even-odd path — cand-8F1-strip.png |
| 8F-1 as-is | C-08 | PASS | dark mono in Mist; dark color expression pane Mist + lens Ice — cand-8F1-strip.png, darkland.png, full-dark.png |
| 8F-1 as-is | C-09 | PASS | i dot is the round-1 literal path, untouched, same color as its word in every version |
| 8F-1 as-is | C-10 | PASS | flat token fills only; transparency stays geometric (even-odd void), zero opacity/gradient/glassmorphism |
| 8F-1 as-is | C-11 | PASS | geometry is round-2 8F verbatim; no A-R or 07r shape |
| 8F-1 as-is | C-12 | PASS | xmllint pass x3 files; viewBox -12 -16 953 212; role=img; title+desc; r38f1m-/r38f1c-/r38f1d- ids unique |
| 8F-1 as-is | C-13 | PASS | filled outline paths only; zero <text>/font-family; <= 2 decimals |
| 8F-1 as-is | C-14 | PASS | same exclusions as 8F (not Mastercard/Linear/Glassdoor/Gmail/envelope); color pair Ink+Glass is the brand palette, not a category collision |
| 8F-1 as-is | C-15 | PASS | judged at 280px in exam-8F1.png (mono + both color expressions): lit corner bounded by both shapes' edges; in color the Glass lens completes the circle even more explicitly — no cut/bite read |
| 8F-2 lit lens | C-01 | PASS | zero <rect>; mono one even-odd path; color is three layered paths (notched pane + three-quarter lens + lit quarter) on raw background |
| 8F-2 lit lens | C-02 | PASS | geometry unchanged from 8F: two-edge corner break to y176 |
| 8F-2 lit lens | C-03 | PASS | gap 40u: <= 0.4 x mark width (48) and <= 75 |
| 8F-2 lit lens | C-04 | PASS | mark + word only; no subtitle |
| 8F-2 lit lens | C-05 | PASS | 16px color tab: silhouette holds, Ice quarter reads as a bright corner glint — cand-8F2-favicon-zoom.png |
| 8F-2 lit lens | C-06 | PASS | 32px header: Ice light clearly visible between Ink pane and Glass lens — same zoom file |
| 8F-2 lit lens | C-07 | PASS | mono collapse verified: the Ice light collapses back to the even-odd void; mono master byte-identical geometry to 8F — cand-8F2-strip.png |
| 8F-2 lit lens | C-08 | PASS | works on Paper, Mist-adjacent surfaces and dark: dark expression pane Mist + lens Glass + light Ice; Glass lens recedes on Ink by design (noted in the gallery exam) — darkland.png |
| 8F-2 lit lens | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8F-2 lit lens | C-10 | PASS | the light is a flat Ice fill, not a gradient/glow/flare; zero opacity tricks |
| 8F-2 lit lens | C-11 | PASS | geometry is 8F verbatim; only the fill program differs; no A-R or 07r shape |
| 8F-2 lit lens | C-12 | PASS | xmllint pass x3; viewBox -12 -16 953 212; role=img; title+desc; r38f2m-/r38f2c-/r38f2d- ids unique |
| 8F-2 lit lens | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8F-2 lit lens | C-14 | PASS | filled-overlap two-circle-family check: NOT Mastercard (square+circle, single overlap, corner placement) |
| 8F-2 lit lens | C-15 | PASS | judged at 280px in exam-8F2.png: with the quarter filled Ice nothing is voided at all in color — the strongest possible no-bite read; mono identical to 8F's passing geometry |
| 8F-3 message line | C-01 | PASS | zero <rect>; bar is a path subpath voided from the pane (mono) / a layered path (color); no plate behind anything |
| 8F-3 message line | C-02 | PASS | corner lens break unchanged (two edges, to y176); bar is internal and breaks nothing |
| 8F-3 message line | C-03 | PASS | gap 40u: <= 0.4 x mark width (48) and <= 75 |
| 8F-3 message line | C-04 | PASS | the bar is abstract content, not text: no subtitle, no glyphs |
| 8F-3 message line | C-05 | PASS | 16px tab: bar simplifies toward a notch BY DESIGN (documented in the gallery); silhouette + lens still read — cand-8F3-favicon-zoom.png |
| 8F-3 message line | C-06 | PASS | 32px header: bar visible as a line of content; not clutter (one bar, 42x14u, margins >= 14u) — same zoom file |
| 8F-3 message line | C-07 | PASS | mono master: bar void via even-odd in the single path; reads as light through the pane — cand-8F3-strip.png |
| 8F-3 message line | C-08 | PASS | dark mono in Mist; dark color pane Mist + line Glass + lens Ice — darkland.png, full-dark.png |
| 8F-3 message line | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 8F-3 message line | C-10 | PASS | abstract bar, not an envelope flap/plane/arrow; flat fills only |
| 8F-3 message line | C-11 | PASS | derives only from 8F; bar-in-pane is not the v1.8 option-k header-stack nor option-h console-row (single bar, no stack, no chrome) |
| 8F-3 message line | C-12 | PASS | xmllint pass x3; viewBox -12 -16 953 212; role=img; title+desc; r38f3m-/r38f3c-/r38f3d- ids unique |
| 8F-3 message line | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8F-3 message line | C-14 | PASS | screened against minus/remove-badge vocabulary: bar is left-aligned (x 14-56 in an 84-wide pane), not centered, and paired with the corner lens; document-icon adjacency noted in the exam and anchored by the lens |
| 8F-3 message line | C-15 | PASS | judged at 280px in exam-8F3.png: bar is fully internal (margins 14/28/24/26u), reads as a lit line of content, never as a cut — no severed read; corner light unchanged from 8F's pass |
| 8F-4 through-light | C-01 | PASS | zero <rect>; mono one even-odd path (pane + lens + echo); color is three layered paths on raw background |
| 8F-4 through-light | C-02 | PASS | strongest break of the field: lens breaks two edges at the bottom-right corner AND the echo r20 breaks two edges at the top-left corner (to x-20, y20) |
| 8F-4 through-light | C-03 | PASS | gap 40u: <= 0.4 x mark width (0.4x140=56, width now includes the echo) and <= 75 |
| 8F-4 through-light | C-04 | PASS | mark + word only; no subtitle |
| 8F-4 through-light | C-05 | PASS | 16px tab: echo simplifies to a corner dot BY DESIGN; main pane/lens read intact — cand-8F4-favicon-zoom.png |
| 8F-4 through-light | C-06 | PASS | 32px header: both lights read; diagonal in-out axis visible — same zoom file |
| 8F-4 through-light | C-07 | PASS | mono master single even-odd path; both lit corners void — cand-8F4-strip.png |
| 8F-4 through-light | C-08 | PASS | dark mono in Mist; dark color pane Mist + entry lens Ice + exit light Glass — darkland.png, full-dark.png |
| 8F-4 through-light | C-09 | PASS | i dot is the round-1 literal path, untouched (echo sits at the MARK's corner, 160u left of the wordmark) |
| 8F-4 through-light | C-10 | PASS | two circles + rectangle, flat fills; no banned motif family |
| 8F-4 through-light | C-11 | PASS | derives only from 8F; twin corner lights are not any A-R or 07r geometry |
| 8F-4 through-light | C-12 | PASS | xmllint pass x3; viewBox -24 -16 965 212 (widened for the echo); role=img; title+desc; r38f4m-/r38f4c-/r38f4d- ids unique |
| 8F-4 through-light | C-13 | PASS | filled outline paths only; zero <text>/font-family |
| 8F-4 through-light | C-14 | PASS | hierarchy r36:r20 keeps it off Mastercard's two equal circles; not Linear/Glassdoor/Gmail/envelope |
| 8F-4 through-light | C-15 | PASS | judged at 280px in exam-8F4.png: each lit corner is bounded by both shapes' edges and wrapped by its circle's solid three-quarter from outside — both read as light passing through, neither as a bite |

60 rows, 60 PASS. Candidates presented in `tournament/round-3.html` after the
8F mono baseline. This is the protocol's final round: the next pause is
pick-or-stop, no round 4.

## Round 4 (maintainer-directed extension — the envelope in light)

Four candidates on the 8F-1 color program, screened against C-01..C-15 plus a
new constraint from the round-4 directive and convergence guard:

C-16 — the envelope is SUGGESTED through composition and light only: no drawn
envelope outlines, no zigzag or stroke flap lines, no mailbox/paper-plane; no
convergence on codex's literal envelope+pane mark (stroke rectangle + stroke
V flap + rotated gradient pane). An envelope read may be weak — weakness is
recorded honestly in the gallery — but a LITERAL drawing fails.

4 candidates x 16 constraints = 64 rows. Verdicts for C-05..C-08, C-15, and
C-16 were back-filled from the browser visual audit (screenshots under
`tmp/87-logo-tournament/round-4/`: pre-draw design-exam closeups
`exam-{8F1,4A,4B,4C,4D,4A-alt}.png` at 280px in mono + color-light +
color-dark, gallery strips, favicon zooms at 16/32px, NEW tiny in-situ zooms
at 16/20/32px, full-page light + dark, darkland).

Design-exam-driven decisions (documented, not silent): the 4A flap was drawn
two ways before shipping — a V crease BAND of light reads as a download
chevron, not a fold (exam-4A-alt.png), so the flap ships as a lit inset
REGION (triangle) instead. 4B's wordmark moves to translate(116) and 4D's to
translate(180) because C-03's 0.4 x mark-width bound tightens as the mark
narrows (84u and 140u wide respectively) — constraint-driven, not a second
design parameter. 4D is the sanctioned spinoff of the round-4 brief
(flap-as-light + landscape + seal position combined) and is labeled as such.

Shared facts (every candidate): wordmark is the round-1 option-8 glyph paths
VERBATIM (only the group translate-x changes); mono master is ONE even-odd
path, currentColor, root fallback color="#0D1B2A"; color fills are Phase 86
tokens ONLY (verified by hex extraction over all 12 files: Ink #0D1B2A,
Glass #277B96, Ice #A6EAF2, Mist #EAF6FB; glass-deep #1D637A permitted but
unused); zero gradients, masks, filters, url() refs, or opacity; ids prefixed
r44[a-d][mcd]-, unique per file and across the gallery; files named
variant-4{A-D}-{name}-{mono,color-light,color-dark}.svg in
`tournament/round-4/`.

| Candidate | Constraint | Verdict | Evidence |
|--------|------------|---------|----------|
| 4A flap light | C-01 | PASS | zero <rect>; mono one even-odd path; color is two layered paths (notched+flapped pane, three-quarter lens) on raw background |
| 4A flap light | C-02 | PASS | 8F break unchanged: lens crosses two pane edges, 36u right (x120) and 36u below (y176) beside the g descender's y177 |
| 4A flap light | C-03 | PASS | gap 40u: <= 0.4 x mark width (0.4x120=48) and <= 75; pane center y=90 |
| 4A flap light | C-04 | PASS | mark + word only; no subtitle |
| 4A flap light | C-05 | PASS | 16px tab: silhouette holds; flap survives as a small notch of light — cand-4A-favicon-zoom.png, cand-4A-insitu-zoom.png |
| 4A flap light | C-06 | PASS | 32px header: flap + lit corner both read; envelope read arrives — same zoom files |
| 4A flap light | C-07 | PASS | mono master single even-odd path, all currentColor — cand-4A-strip.png |
| 4A flap light | C-08 | PASS | dark mono in Mist; dark color pane Mist + lens Ice, flap void shows Ink — darkland.png, full-dark.png |
| 4A flap light | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 4A flap light | C-10 | PASS | flat token fills; the flap is voided geometry, not a gradient/glow; no banned motif family |
| 4A flap light | C-11 | PASS | derives only from 8F; the lit-region flap is NOT the 07r envelope (no stroke outline, no tilt, no gradient) |
| 4A flap light | C-12 | PASS | xmllint pass x3; viewBox -12 -16 953 212; role=img; title+desc; r44a[mcd]- ids unique |
| 4A flap light | C-13 | PASS | filled outline paths only; zero <text>/font-family; <= 2 decimals |
| 4A flap light | C-14 | PASS | not Gmail M (no M strokes), not Linear/Glassdoor; checked against generic mail icons: flap inset + made of light, never corner-to-corner drawn lines |
| 4A flap light | C-15 | PASS | judged at 280px in exam-4A.png: flap void fully internal (12u side, 14u top, 26u below-apex margins), bounded by pane mass on all sides — reads as light where the fold sits, never a crack; crease-BAND alternative rejected for chevron read (exam-4A-alt.png) |
| 4A flap light | C-16 | PASS | envelope suggested by one lit region + composition; zero drawn lines; honest in-situ verdict recorded (envelope at 20px+) |
| 4B sealed light | C-01 | PASS | zero <rect>; mono one even-odd path; color is two layered paths (seal-notched pane, solid lower-half lens) on raw background |
| 4B sealed light | C-02 | PASS | lens r36 at the seal position (42,140) dips 36u below the bottom edge, through the y=140 baseline, to y176 |
| 4B sealed light | C-03 | PASS | gap 32u at translate(116): <= 0.4 x mark width (0.4x84=33.6, ratio bound binds) and <= 75 |
| 4B sealed light | C-04 | PASS | mark + word only; no subtitle |
| 4B sealed light | C-05 | PASS | 16px tab: pane + seal-bump silhouette distinct — cand-4B-favicon-zoom.png, cand-4B-insitu-zoom.png |
| 4B sealed light | C-06 | PASS | 32px header: lit upper half + Glass lower half both read — same zoom files |
| 4B sealed light | C-07 | PASS | mono master single even-odd path, all currentColor — cand-4B-strip.png |
| 4B sealed light | C-08 | PASS | dark mono in Mist; dark color pane Mist + seal Ice — darkland.png, full-dark.png |
| 4B sealed light | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 4B sealed light | C-10 | PASS | square+circle geometry only; no banned motif family |
| 4B sealed light | C-11 | PASS | derives only from 8F (lens repositioned); no A-R or 07r shape |
| 4B sealed light | C-12 | PASS | xmllint pass x3; viewBox -12 -16 909 212; role=img; title+desc; r44b[mcd]- ids unique |
| 4B sealed light | C-13 | PASS | filled outline paths only; zero <text>/font-family; <= 2 decimals |
| 4B sealed light | C-14 | PASS | not a drawn seal/badge (no ring), not Mastercard/Linear/Glassdoor/Gmail/envelope-icon |
| 4B sealed light | C-15 | PASS | judged at 280px in exam-4B.png: upper half voids, solid lower half completes the circle (the round-1 option-8 edge-straddle precedent); the pane edge reads as a chord, not a cut |
| 4B sealed light | C-16 | PASS | composition only, zero new elements; the honest verdict (does NOT read envelope without flap context) is recorded in the gallery in-situ row — weak read, no literal drawing |
| 4C landscape | C-01 | PASS | zero <rect>; pane is a 140x96 path (the mark figure, 13.9% of the 1009u viewBox), nothing sits on it |
| 4C landscape | C-02 | PASS | lens r36 at (140,140) breaks two edges: 36u right (x176) and 36u below (y176), crossing the baseline |
| 4C landscape | C-03 | PASS | gap 40u at translate(216): <= 0.4 x mark width (0.4x176=70.4) and <= 75; lockup total 985u stays within one strip cell |
| 4C landscape | C-04 | PASS | mark + word only; no subtitle |
| 4C landscape | C-05 | PASS | 16px tab: landscape silhouette + corner dot read — cand-4C-favicon-zoom.png, cand-4C-insitu-zoom.png |
| 4C landscape | C-06 | PASS | 32px header: lit quarter visible, proportion reads — same zoom files |
| 4C landscape | C-07 | PASS | mono master single even-odd path, all currentColor — cand-4C-strip.png |
| 4C landscape | C-08 | PASS | dark mono in Mist; dark color pane Mist + lens Ice — darkland.png, full-dark.png |
| 4C landscape | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 4C landscape | C-10 | PASS | rectangle+circle geometry only; no banned motif family |
| 4C landscape | C-11 | PASS | derives only from 8F (proportion changed); not 07r (no flap, no tilt, no gradient, no strokes) |
| 4C landscape | C-12 | PASS | xmllint pass x3; viewBox -12 -16 1009 212; role=img; title+desc; r44c[mcd]- ids unique |
| 4C landscape | C-13 | PASS | filled outline paths only; zero <text>/font-family; <= 2 decimals |
| 4C landscape | C-14 | PASS | no folder regression (no tab), no credit-card read (no chip; lens breaks the frame); not Linear/Glassdoor/Gmail |
| 4C landscape | C-15 | PASS | judged at 280px in exam-4C.png: lit corner bounded by both shapes' edges, three quarters of the lens solid — identical pass condition to 8F |
| 4C landscape | C-16 | PASS | proportion alone; nothing drawn; the honest verdict (envelope-adjacent, ambiguous alone) is recorded in the gallery in-situ row |
| 4D sealed flap | C-01 | PASS | zero <rect>; mono one even-odd path (pane + flap + seal); color is two layered paths on raw background |
| 4D sealed flap | C-02 | PASS | lens r36 at the seal position (70,140) dips 36u below the bottom edge, through the y=140 baseline, to y176 |
| 4D sealed flap | C-03 | PASS | gap 40u at translate(180): <= 0.4 x mark width (0.4x140=56) and <= 75 |
| 4D sealed flap | C-04 | PASS | mark + word only; no subtitle |
| 4D sealed flap | C-05 | PASS | 16px tab: flap AND seal both survive — the only candidate reading envelope at favicon size — cand-4D-favicon-zoom.png, cand-4D-insitu-zoom.png |
| 4D sealed flap | C-06 | PASS | 32px header: unambiguous sealed-envelope read — same zoom files |
| 4D sealed flap | C-07 | PASS | mono master single even-odd path, all currentColor — cand-4D-strip.png |
| 4D sealed flap | C-08 | PASS | dark mono in Mist; dark color pane Mist + seal Ice, flap void shows Ink — darkland.png, full-dark.png |
| 4D sealed flap | C-09 | PASS | i dot is the round-1 literal path, untouched |
| 4D sealed flap | C-10 | PASS | flat token fills; flap and seal are voided geometry, not gradients/glows; no banned motif family |
| 4D sealed flap | C-11 | PASS | spinoff of the round-4 brief on 8F geometry; NOT 07r: zero strokes, zero tilt, zero gradient — every envelope cue is a void or a proportion |
| 4D sealed flap | C-12 | PASS | xmllint pass x3; viewBox -12 -16 973 212; role=img; title+desc; r44d[mcd]- ids unique |
| 4D sealed flap | C-13 | PASS | filled outline paths only; zero <text>/font-family; <= 2 decimals |
| 4D sealed flap | C-14 | PASS | screened against generic sealed-envelope icons: those draw flap LINES corner-to-corner and a solid seal ON the body; here the flap is an inset lit region and the seal is the brand lens straddling the edge |
| 4D sealed flap | C-15 | PASS | judged at 280px in exam-4D.png: flap void fully internal (14u margins, 12u solid between apex y92 and seal void top y104); seal's solid lower half completes the circle — nothing severs, both voids read as light |
| 4D sealed flap | C-16 | PASS | the closest candidate to literal, held on the right side of the line: composition + light only, no drawn outline or flap stroke; explicitly compared against codex's stroke-drawn mark — zero shared construction |

64 rows, 64 PASS. Candidates presented in `tournament/round-4.html` after the
8F-1 color baseline (the recorded fallback winner). The next pause is the
genuinely final pick-or-default: `winner 8F-1` promotes the fallback.
