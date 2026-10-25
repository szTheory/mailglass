# Phase 172: Recipient Output and Built-in Pages - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `172-CONTEXT.md`; this log preserves the analysis.

**Date:** 2026-10-09
**Phase:** 172-recipient-output-and-built-in-pages
**Mode:** assumptions (`--auto`)
**Areas analyzed:** public email components, representative scenarios, plaintext authority, built-in unsubscribe pages

## Assumptions Presented

### Public email components
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Improve hierarchy and narrow/long-content behavior within existing public components and adopter themes. | Confident | `lib/mailglass/components.ex`; `lib/mailglass/components/theme.ex`; `lib/mailglass/components/layout.ex`; `test/mailglass/components/vml_preservation_test.exs` |

### Representative scenarios
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add a named public-component scenario alongside AtlasDesk-rendered scenarios with a consistent sender identity. | Likely | `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`; `billing_mailer.ex`; `operations_mailer.ex`; `atlas_desk_email.ex`; `guides/components.md` |

### Plaintext authority
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Validate generated renderer plaintext for both authoring paths, including nested and unmarked action links. | Confident | `lib/mailglass/renderer.ex`; `reference/demo_app/lib/mailglass_demo_web/mailers/atlas_desk_email.ex`; `test/mailglass/renderer_test.exs` |

### Built-in unsubscribe pages
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep valid GET informational; retain distinct 404/410 invalid/expired states, useful recovery, configured redirects, and existing POST semantics. | Confident | `lib/mailglass/compliance/unsubscribe_controller.ex`; `lib/mailglass/compliance/unsubscribe_html/confirm.html.heex`; `test/mailglass/compliance/unsubscribe_controller_test.exs`; `.planning/research/v2.9/SCOPE.md` |

## Corrections Made

No corrections — all assumptions were accepted under the user's instruction to follow the synthesized recommendations.

## Auto-Resolved

- The Likely scenario assumption was resolved in favor of adding a dedicated named public-component example alongside the existing AtlasDesk scenarios, rather than relying on a static guide example or converting all existing AtlasDesk output. This keeps both authoring paths inspectable and distinct.

## External Research

- Gmail's documented CSS support includes width, max-width, and screen-width media queries, while unsupported CSS may be ignored. Use fluid table/width fallbacks and do not rely on media queries alone. [Google: Gmail CSS support](https://developers.google.com/workspace/gmail/design/css)
- Microsoft documents Classic Outlook's Word-based renderer and spacing limitations, VML background sizing caveats, and mobile table reflow issues. Keep essential copy in ordinary HTML, use table-cell padding, and avoid fixed-height VML around dynamic content. [Microsoft: email rendering issues](https://learn.microsoft.com/en-us/troubleshoot/dynamics-365/customer-insights/journeys/email/email-troubleshoot-rendering)
- W3C guidance supports presentational semantics for layout tables, descriptive link purpose, and meaningful image alternatives. [Presentation role](https://www.w3.org/WAI/ARIA/apg/practices/hiding-semantics/), [link purpose](https://www.w3.org/WAI/WCAG21/Techniques/html/H30.html), [images tutorial](https://www.w3.org/WAI/tutorials/images/)
- Can I Email provides secondary client-test evidence for CSS `max-width`, word wrapping, and tables; these samples are not market-share weighted and some relevant tests date to 2019. Use it to target representative tests, not as a compatibility guarantee. [max-width](https://www.caniemail.com/features/css-max-width/), [word-wrap](https://www.caniemail.com/features/css-word-wrap/), [table](https://www.caniemail.com/features/html-table/)
- None of these sources verifies the actual delivered message through Mailglass's send path in current recipient clients. Generated markup and browser preview evidence remain bounded to their actual layer.
