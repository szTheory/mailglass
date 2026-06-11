# Mailglass Logo Options

Status: historical review evidence. The selected logo direction now lives in
`logo-creative-brief.md` and `logo-concepts.md`.

This artifact records why the early folded-pane, wordmark-header, and UI-fragment
rounds were rejected. It also preserves the small-size and inline-SVG concerns
that shaped the final logo constraints.

The stable brand center stays unchanged: Mailglass makes email visible, mail you
can see through, and glass is a metaphor, not a visual excuse. This artifact is
now historical evidence of failed routes, not an active option set.

The active source of truth is the 07r no-i-dot 02 lockup:
`assets/concepts/concept-07r-no-idot-02-tighter-gap.svg`. Do not resume from
any A-R shape.

## Maintainer Reset

The option rounds did not pass maintainer review:

- A/B/C were rejected because the folded pane, simplified pane, and inspection pane all read too much like paper or a document card.
- D/E/F were rejected because they were still too narrow: wordmark aperture, `mg` header mark, and wordmark trace variations explored the same typographic-header territory rather than rethinking the mark from first principles.
- G-R were rejected because they became low-quality source snippets, UI fragments, infrastructure diagrams, or generic devtool marks rather than proper logos.

Do not continue iterating from these shapes. They are kept only to show what
was evaluated and rejected.

## Rejected Prior Rounds

| Direction | SVG evidence | Short read | Review status |
|---|---|---|---|
| Direction A - folded pane | `assets/options/option-a-folded-pane.svg` | Current folded pane draft with message lines and a lower fold. | Rejected: too close to paper/document geometry. |
| Direction B - simplified pane/message-lines | `assets/options/option-b-pane-lines.svg` | Flat pane and message-lines mark with no triangular fold. | Rejected: clearer than A, but still reads as a paper-like pane/card. |
| Direction C - inspection pane | `assets/options/option-c-inspection-pane.svg` | Pane-forward visible-email mark with an inspection edge and message lines. | Rejected: more inspectable, but still too object/card-like. |
| Direction D - wordmark aperture | `assets/options/option-d-wordmark-aperture.svg` | A custom `g`-like glass aperture with tiny email header cues inside the counter. | Rejected: too close to a typographic variation of the same idea. |
| Direction E - mg header mark | `assets/options/option-e-mg-header-mark.svg` | An `mg` monogram where the `g` counter becomes a glass inspection pocket with header lines. | Rejected: still a wordmark-header variant, not a first-principles mark. |
| Direction F - wordmark trace | `assets/options/option-f-wordmark-trace.svg` | A wordmark-adjacent treatment where the terminal `g` carries an inspectable header trace. | Rejected: lockup-led and insufficiently distinct as a standalone mark. |

## Superseded G-R Visual Evidence

| Direction | Family | SVG evidence | Short read | Review status |
|---|---|---|---|---|
| Direction G - header checksum | Email source | `assets/options/option-g-header-checksum.svg` | Header fields reduced to aligned source bars and verification ticks. | Rejected: reads as a small source/UI fragment, not an ownable logo. |
| Direction H - console row | Email source | `assets/options/option-h-console-row.svg` | A compact operator-console row with status, header token, and route tick. | Rejected: reads as interface chrome rather than a mark. |
| Direction I - inline source cursor | Email source | `assets/options/option-i-inline-source-cursor.svg` | A source cursor and `to:` token make email visible as editable infrastructure. | Rejected: too literal and text-dependent. |
| Direction J - negative at lens | Email source | `assets/options/option-j-negative-at-lens.svg` | An at-sign-adjacent loop with a clear inspection counter and header traces. | Rejected: generic `@`/lens risk and not distinctive enough. |
| Direction K - header stack | Email source | `assets/options/option-k-header-stack-mark.svg` | `from`, `to`, and `subj` source labels become the mark structure. | Rejected: source labels are product explanation, not logo identity. |
| Direction L - source diff | Email source | `assets/options/option-l-source-diff.svg` | Hidden versus visible message state becomes a small diff/alignment mark. | Rejected: generic code/diff notation. |
| Direction M - protocol brackets | Inspection tool | `assets/options/option-m-protocol-brackets.svg` | Parser-like brackets inspect a header token without using a pane. | Rejected: generic devtool syntax. |
| Direction N - transparent routing node | Infrastructure | `assets/options/option-n-transparent-routing-node.svg` | Inbound and outbound message flow passes through an observable center. | Rejected: diagrammatic and too close to routing/send logic. |
| Direction O - delivery timeline | Infrastructure | `assets/options/option-o-delivery-timeline.svg` | Render, deliver, and event lifecycle ticks form a small system mark. | Rejected: timeline/status diagram rather than a brand mark. |
| Direction P - normalized event pulse | Infrastructure | `assets/options/option-p-normalized-event-pulse.svg` | One message signal becomes normalized observable event ticks. | Rejected: observability icon, not Mailglass identity. |
| Direction Q - glass caliper | Inspection tool | `assets/options/option-q-glass-caliper.svg` | A precision instrument measures a visible email header line. | Rejected: tool illustration and not ownable enough. |
| Direction R - refraction line | Inspection tool | `assets/options/option-r-refraction-line.svg` | A flat source line changes alignment through a clear center. | Rejected: abstract effect sketch, not a proper logo. |

## Comparison

This comparison is retained only to show what was evaluated. Apparent strengths
in this table are superseded by the maintainer reset above; none of these rows
are active candidates.

| Direction | 16px / 32px clarity | Wordmark-first fit | Brand-center alignment | Forbidden trope risk | Monochrome / reversed viability | Path complexity and editability | Accessible metadata and unique ID strategy |
|---|---|---|---|---|---|---|---|
| G - header checksum | Strong: bars and ticks can collapse to a compact source verifier. | Strong as a mark before the wordmark; does not depend on lettering. | Strong: email headers become inspectable proof. | Low: no paper, envelope, pane, or card outline. | Strong: simple strokes and dots can become `currentColor`; reversed works on Ink. | Low: mostly strokes and circles. | Uses `mg-option-g-title` and `mg-option-g-desc`. |
| H - console row | Moderate: dense row details may need reduction for favicon use. | Strong for developer-facing lockups. | Strong: reads as operational email infrastructure. | Low: console row avoids mail-object tropes. | Strong if reduced to dot, row, and tick. | Low to moderate: several source-row strokes. | Uses `mg-option-h-title` and `mg-option-h-desc`. |
| I - inline source cursor | Moderate: `to:` may disappear at 16px, but cursor and line survive. | Strong for docs and source-native surfaces. | Strong: email is shown as editable source. | Low, though it may skew code-first instead of brand-first. | Moderate: live text should be converted for compact final assets. | Moderate because the source token uses text in draft form. | Uses `mg-option-i-title` and `mg-option-i-desc`. |
| J - negative at lens | Strong silhouette, moderate originality. | Good as a standalone mark, less wordmark-derived. | Moderate: email-native through at-sign, inspectable through counter. | Medium: `@` can feel generic. | Strong: loop and counter can reverse cleanly. | Moderate: circle/arc geometry needs tuning. | Uses `mg-option-j-title` and `mg-option-j-desc`. |
| K - header stack | Moderate: labels may not survive small sizes. | Strong beside wordmark if simplified to label rhythm. | Strong: direct source headers. | Low: no object metaphor. | Moderate: final compact version should reduce text labels to bars. | Moderate because draft uses live text. | Uses `mg-option-k-title` and `mg-option-k-desc`. |
| L - source diff | Strong: plus/minus and aligned bars survive. | Good for developer README/docs contexts. | Strong: makes before/after visibility explicit. | Low, but diff notation may feel too code-specific. | Strong: simple strokes and symbols. | Low to moderate: final compact version should shape-convert symbols. | Uses `mg-option-l-title` and `mg-option-l-desc`. |
| M - protocol brackets | Strong: bracket silhouette is compact. | Good: mark can prefix the wordmark without depending on it. | Strong: inspection boundary around source. | Low, unless brackets become generic devtool syntax. | Strong: currentColor-friendly strokes. | Low: simple bracket and header strokes. | Uses `mg-option-m-title` and `mg-option-m-desc`. |
| N - transparent routing node | Strong: node and route arrows survive. | Good for product/infrastructure story. | Strong: visible flow through a clear center. | Medium: arrows must not become send-arrow logic. | Strong with simplified route lines. | Moderate: arrowheads and center need tuning. | Uses `mg-option-n-title` and `mg-option-n-desc`. |
| O - delivery timeline | Strong as ticks; weaker as a unique favicon. | Good for lifecycle copy and docs. | Strong: render, deliver, event are visible states. | Low: no mail object, but timeline can feel generic. | Strong: circles and line are easy to reverse. | Low: simple line and ticks. | Uses `mg-option-o-title` and `mg-option-o-desc`. |
| P - normalized event pulse | Strong: waveform silhouette is distinctive. | Moderate: more observability than email. | Strong for normalized events and operator confidence. | Low: avoids email tropes completely. | Strong: stroke-only mark. | Moderate: pulse geometry needs exact simplification. | Uses `mg-option-p-title` and `mg-option-p-desc`. |
| Q - glass caliper | Strong: opposing bracket silhouette survives. | Good if paired with the wordmark as an inspection instrument. | Strong: inspect before sending. | Low, but can read as measurement tool more than email. | Strong: stroke-only, currentColor-friendly. | Low: caliper and header lines are simple. | Uses `mg-option-q-title` and `mg-option-q-desc`. |
| R - refraction line | Strong: offset line and center survive. | Good as abstract brand mark. | Strong for "see through" without visual glass effects. | Low, but may become too abstract. | Strong: line and center reverse cleanly. | Low: flat strokes and one center. | Uses `mg-option-r-title` and `mg-option-r-desc`. |

## Small-Size Notes From Failed Rounds

Small-mark ambiguity remains the review rule. If any mark reads like a
document, envelope, paper plane, send
arrow, mailbox, chat bubble, generic app card, UI fragment, or generic devtool
icon at 16px or 32px, reject the direction rather than adding detail.

Earlier notes treated G, M, Q, R, and P as relatively stronger small-size
candidates because they relied on clear stroke silhouettes rather than text
labels. That judgment is superseded. The maintainer review rejected the whole
G-R set as insufficiently logo-quality.

## Recommended Final Refinement

Recommended final refinement: none from A-R.

Use the selected 07r no-i-dot 02 lockup recorded in `logo-concepts.md`.

## Maintainer Review

Selected direction: `assets/concepts/concept-07r-no-idot-02-tighter-gap.svg`.
A-R are rejected evidence. Do not accept any of the old signals below as
sufficient:

- `select option-g`
- `select option-h`
- `select option-i`
- `select option-j`
- `select option-k`
- `select option-l`
- `select option-m`
- `select option-n`
- `select option-o`
- `select option-p`
- `select option-q`
- `select option-r`
- `revise option-<letter>: ...`

If the response is only `approved`, do not treat it as approval for any A-R
option. The selected direction is already recorded in `logo-concepts.md`.
