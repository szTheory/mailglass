# Mailglass Logo Options

Status: Phase 82 review evidence. Final asset work is blocked until Plan 02 records a selection from the fresh option round.

This artifact closes the evidence gap named by `BRAND-GAP-04`, `BRAND-GAP-05`, and `BRAND-GAP-06`: one folded pane draft is not enough to approve a logo system, the favicon fold needs small-size review, and inline SVG use needs unique ID discipline.

The stable brand center stays unchanged: Mailglass makes email visible, mail you can see through, and glass is a metaphor, not a visual excuse. The mark should support that idea with inspectable email header cues, source-native geometry, and restrained Glass accent. It should not become a piece of paper, paper plane, mailbox, chat bubble, send arrow, glossy app icon, mascot, decorative gradient, blob, bevel, glassmorphism, or path-complexity exercise.

## Maintainer Reset

The first option round did not pass maintainer review. The critique was direct: A/B/C all read more like a piece of paper than email or glass. That rejects the folded-pane and pane-card territories as final candidates, even where the SVG source was technically valid.

The fresh direction is wordmark-native: make the mark feel owned by Mailglass, and make "email" read through compact header cues rather than document or envelope geometry.

## Rejected First Round

| Direction | SVG evidence | Short read | Review status |
|---|---|---|---|
| Direction A - folded pane | `assets/options/option-a-folded-pane.svg` | Current folded pane draft with message lines and a lower fold. | Rejected: too close to paper/document geometry. |
| Direction B - simplified pane/message-lines | `assets/options/option-b-pane-lines.svg` | Flat pane and message-lines mark with no triangular fold. | Rejected: clearer than A, but still reads as a paper-like pane/card. |
| Direction C - inspection pane | `assets/options/option-c-inspection-pane.svg` | Pane-forward visible-email mark with an inspection edge and message lines. | Rejected: more inspectable, but still too object/card-like. |

## Fresh Visual Evidence

| Direction | SVG evidence | Short read | Review status |
|---|---|---|---|
| Direction D - wordmark aperture | `assets/options/option-d-wordmark-aperture.svg` | A custom `g`-like glass aperture with tiny email header cues inside the counter. | Recommended default fresh candidate. |
| Direction E - mg header mark | `assets/options/option-e-mg-header-mark.svg` | An `mg` monogram where the `g` counter becomes a glass inspection pocket with header lines. | Strong owned-mark candidate, but less compact than D. |
| Direction F - wordmark trace | `assets/options/option-f-wordmark-trace.svg` | A wordmark-adjacent treatment where the terminal `g` carries an inspectable header trace. | Useful if the final system should stay lockup-led rather than icon-led. |

## Comparison

| Criteria | Direction D - wordmark aperture | Direction E - mg header mark | Direction F - wordmark trace |
|---|---|---|---|
| 16px clarity | Strongest fresh candidate: the `g` aperture can collapse to a recognizable mark plus one header line. | Moderate: the `mg` idea may need simplification to avoid tiny letter clutter. | Weakest as a favicon because the full wordmark relationship is too wide. |
| 32px clarity | Strong: aperture, descender, and header cues remain readable. | Good: monogram reads, but header pocket needs careful spacing. | Good for lockup preview, less useful as a standalone mark. |
| wordmark-first fit | Strong: the mark can sit before the wordmark and feel derived from the `g`. | Strong: explicitly wordmark-native through the `mg` monogram. | Strongest lockup fit because it keeps the wordmark as the primary visual. |
| Brand-center alignment | Best match for visible email through a glass aperture containing header cues. | Strong owned identity, with email visible inside the counter. | Strong for source lockups; less independent as a mark. |
| forbidden trope avoidance | Passes: no paper, envelope, plane, mailbox, chat bubble, send arrow, mascot, or glossy app-icon logic. | Passes if the monogram stays typographic and not badge-like. | Passes, though the trace must stay header-like rather than decorative circuitry. |
| monochrome/currentColor viability | Strong: one aperture outline, descender, and a small set of header strokes. | Moderate: monogram text may require path refinement later for compact assets. | Moderate: wordmark-led use is less useful for single-color stamps. |
| reversed/dark-background viability | Strong: aperture outline can use Ice on Ink with header cues in Glass/Mist. | Good: monogram can reverse, but needs breathing room. | Good for primary lockup contexts, not the best social avatar seed. |
| Path complexity and editability | Low: simple circle, descender, and header strokes. | Moderate: live `mg` text is editable but future compact conversion may need hand tuning. | Moderate: live wordmark plus trace is easy to edit, but not icon-minimal. |
| Accessible metadata and unique ID strategy | Option SVG uses `mg-option-d-title` and `mg-option-d-desc`. | Option SVG uses `mg-option-e-title` and `mg-option-e-desc`. | Option SVG uses `mg-option-f-title` and `mg-option-f-desc`. |

## Small-Size Notes

`BRAND-GAP-05` is about the triangular fold reading poorly at favicon sizes. The reset removes fold geometry entirely from the active candidates. The review rule remains conservative: if any active mark reads like a document, envelope, paper plane, or generic app card at 16px or 32px, simplify the mark rather than adding detail.

Direction D is the cleanest small-size candidate because the aperture and descender can survive as a compact wordmark-derived mark while a single header stroke keeps the email cue. Direction E is promising if the monogram remains legible. Direction F is best treated as lockup exploration, not a favicon-first mark.

## Recommended Final Refinement

Recommended final refinement: Direction D, the wordmark aperture mark with header cues.

Rationale:

- It moves the mark away from paper/card geometry while preserving "Mailglass makes email visible."
- It makes the logo feel owned by the Mailglass wordmark rather than generic email iconography.
- It uses email header cues as the email signal, avoiding envelopes, paper planes, mailboxes, chat bubbles, and send arrows.
- It should produce the cleanest 16px/32px favicon, monochrome/currentColor mark, and reversed/dark-background avatar among the fresh options.
- It follows Phase 81 token guidance without implying product admin UI consumption of `brandbook/tokens.json` or `brandbook/tokens.css`.

## Maintainer Review

Selected direction: pending Plan 02 fresh-option review.

Plan 02 should record one explicit resume signal before final SVG files change:

- `approved option-d`
- `select option-e`
- `select option-f`
- `revise option-d: ...`

If the response is only `approved`, treat it as `approved option-d` because Direction D is the documented fresh recommendation.
