# Mailglass Logo Options

Status: Phase 82 review evidence. Final asset work is blocked until Plan 02 records the maintainer response.

This artifact closes the evidence gap named by `BRAND-GAP-04`, `BRAND-GAP-05`, and `BRAND-GAP-06`: one folded pane draft is not enough to approve a logo system, the favicon fold needs small-size review, and inline SVG use needs unique ID discipline.

The stable brand center stays unchanged: Mailglass makes email visible, mail you can see through, and glass is a metaphor, not a visual excuse. The mark should support that idea with flat panes, message structure, modest radius, and restrained Glass accent. It should not become a paper plane, mailbox, chat bubble, send arrow, glossy app icon, mascot, decorative gradient, blob, bevel, glassmorphism, or path-complexity exercise.

## Visual Evidence

| Direction | SVG evidence | Short read | Review status |
|---|---|---|---|
| Direction A - folded pane | `assets/options/option-a-folded-pane.svg` | Current folded pane draft with message lines and a lower fold. | Credible draft, but the fold is the main 16px and 32px ambiguity. |
| Direction B - simplified pane/message-lines | `assets/options/option-b-pane-lines.svg` | Flat pane and message-lines mark with no triangular fold. | Recommended default for final refinement because it is simpler at small sizes. |
| Direction C - inspection pane | `assets/options/option-c-inspection-pane.svg` | Pane-forward visible-email mark with an inspection edge and message lines. | Useful contrast direction if the maintainer wants more inspectable-email emphasis. |

## Comparison

| Criteria | Direction A - folded pane | Direction B - message-lines | Direction C - inspection pane |
|---|---|---|---|
| 16px clarity | Risk: lower folded corner can read as a document corner or send-arrow shape. | Strongest: no triangular fold, larger line rhythm, cleaner silhouette. | Moderate: inspection edge may hold, but the offset pane may compress. |
| 32px clarity | Good enough as a draft, but the fold still competes with message lines. | Strong: pane and message-lines stay readable without added detail. | Good: visible pane relationship remains, with slightly more structure. |
| wordmark-first fit | Fits the existing lockup; the mark remains secondary. | Fits best because the quiet geometry does not fight the wordmark. | Fits if kept compact; too much pane-forward structure could feel like a feature icon. |
| Brand-center alignment | Clear pane/message-fold metaphor, but closer to generic document logic. | Best match for visible email: a readable pane containing message structure. | Strong inspection cue; must retain message affordance to avoid abstraction. |
| forbidden trope avoidance | Mostly passes, but the fold is the only paper-plane/send arrow risk. | Passes: no paper plane, mailbox, chat bubble, send arrow, glossy app icon, mascot, gradient, or blob logic. | Passes if the inspection edge stays a pane edge, not a magnifier or scanner symbol. |
| monochrome/currentColor viability | Viable, though fold overlap adds small-shape complexity. | Best: simple strokes and border-first construction translate cleanly to currentColor. | Viable but needs careful simplification for a single-color stamp. |
| reversed/dark-background viability | Works with Ice and Paper fills, but fold detail can get noisy. | Strong: border, message lines, and pane structure reverse cleanly. | Good for social avatar use if the offset pane is restrained. |
| Path complexity and editability | Moderate; fold uses more line interactions. | Lowest complexity and easiest source edit path. | Moderate; extra pane relationship adds edit surface. |
| Accessible metadata and unique ID strategy | Option SVG uses `mg-option-a-title` and `mg-option-a-desc`. | Option SVG uses `mg-option-b-title` and `mg-option-b-desc`. | Option SVG uses `mg-option-c-title` and `mg-option-c-desc`. |

## Small-Size Notes

`BRAND-GAP-05` is about the triangular fold reading poorly at favicon sizes. The review rule is intentionally conservative: if a fold reads like a document corner, envelope, or send arrow at 16px or 32px, simplify the mark rather than adding detail.

Direction B is the cleanest small-size candidate because the pane outline and message-lines carry the metaphor without relying on a corner fold. Direction A remains useful evidence because it is the current draft. Direction C is worth comparing because the inspection pane can sharpen the "visible email" idea, but it should not become more abstract than the message itself.

## Recommended Final Refinement

Recommended final refinement: Direction B, the simplified pane/message-lines mark.

Rationale:

- It preserves the wordmark-first posture and keeps the mark secondary.
- It keeps "Mailglass makes email visible" in the asset itself: a pane containing readable message structure.
- It avoids the 16px and 32px triangular-fold ambiguity from `BRAND-GAP-05`.
- It should produce the cleanest monochrome/currentColor mark and the least noisy reversed/dark-background avatar.
- It follows Phase 81 token guidance without implying product admin UI consumption of `brandbook/tokens.json` or `brandbook/tokens.css`.

## Maintainer Review

Selected direction: pending Plan 02.

Plan 02 should record one explicit resume signal before final SVG files change:

- `approved option-b`
- `select option-a`
- `select option-c`
- `revise option-b: ...`

If the response is only `approved`, treat it as `approved option-b` because Direction B is the documented recommendation.
