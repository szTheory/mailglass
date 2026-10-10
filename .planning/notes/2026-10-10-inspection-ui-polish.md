# Delivery and inbound inspection UI polish

Date: 2026-10-10
Scope: Delivery quick view, Inbound quick view, and both full detail pages.

## Patterns extrapolated from Jon's feedback

1. Lead with the operator's object and task: subject, recipient, outcome, then evidence.
2. Repetition is costly: omit a latest event when it only repeats the outcome; keep namespaces out of ordinary scanning.
3. Progressive disclosure: precise technical identifiers remain accessible and copyable without competing with message identity.
4. Explain domain terms where they occur: share the outcome and mailbox explanations used by the lists.
5. Intentional hierarchy: predictable metadata grids, consistent navigation, readable labels and actual content wrapping.
6. Scope must be truthful: message evidence, current routing rules, and account diagnostics are different things.
7. Empty, missing, stale and unavailable states need explicit meaning; an empty success box is misleading.
8. Responsive inspection includes overlays and tooltips, not just the underlying table.

## Implemented inventory

- Shared subject-first message identity for all four inspection views; blank and unrecorded subjects have explicit fallbacks.
- Recipient follows the subject and wraps without truncation, including the stress fixture's long address.
- Contextual outcome tooltips reused across quick view, full detail and timelines.
- Delivery latest event displayed only when distinct from its outcome.
- Shared short mailbox identity with full module tooltip; unrouted/missing execution/missing mailbox states retain their distinct icons and explanations.
- Technical details disclosures hold record, delivery, provider-message and execution/event identifiers. Existing copy actions retained, run ID copy added.
- Consistent quick-view headings and navigation affordances, with descriptive previous/next controls.
- Full-detail metadata aligned in responsive grids with consistent titlecase labels.
- Inbound full-detail back link accurately says Back to quick view for its existing destination.
- Empty inbound replay feedback removed; real command feedback still displays.
- Inbound refresh/snapshot state integrated into Execution timeline; failed history reads still report unavailable rather than empty history.
- Initial processing replaces the ambiguous Fresh timeline label.
- Delivery timeline identifiers disclosed; contextual event explanations provided without changing event evidence or audit markers.
- Current suppression scope explained in a tooltip; shorter absence and refresh language.
- Account diagnostics folded after message-specific delivery sections; automatically exposed when support evidence is selected.
- Inbound routing caveat clearly distinguishes today's rules from historical processing; short module tooltips and quieter failed-route styling.
- Raw-source evidence uses plain permission/redaction language and a flatter metadata layout.
- Hidden tooltips no longer contribute off-screen layout overflow. Entry animations release their transform containing blocks after completion, so viewport-positioned hints remain anchored after scrolling.

## Verification

- Demo application compiled and served the changed views.
- Shared/inbound component tests run in the demo test environment: **138 tests, 0 failures** (seed 864910).
- Browser inspection covered Delivery and Inbound quick/full views on desktop and a 390 x 844 mobile viewport, including long address/subject fixtures.
- Mobile full-detail document width: 390px for a 390px viewport in both domains.
- Open mobile suppression hint measured inside the viewport after scrolling: left 58, right 346, top 438, bottom 557.48.
- Timeline contextual hint checked after releasing animation transforms.
- Native technical disclosure and ID copy checked; timestamp click copied exact UTC string to clipboard.
- Inbound next-record navigation and Escape dismissal checked against actual URLs.
- Final desktop screenshots saved in /private/tmp/mailglass-{delivery,inbound}-detail-polished.png; temporary viewport override reset.
- git diff --check passed.

Full LiveView and E2E suites were not run in this pass. Their directly affected copy assertions were updated; the verified component suite and browser checks are the evidence for completion.

No new dependencies. Sender masking, raw-source authorization, replay confirmation/eligibility, tenant scope and append-only evidence behavior remain in place. Live filter/search and custom date range work remains deferred in SEED-261010-gad-operator-date-range-and-live-filters.md.
