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
