# Demo Preview UX Ratchet

## Decisions

- User-facing demo brand: AtlasDesk.
- Internal deterministic tenant id remains `northstar`.
- Individual preview pages show the rendered email before sample-data settings.
- Preview controls remain near the rendered email as a compact toolbar.
- `/dev/mail` shows all mailer scenarios by default; no show/hide affordance.

## Slice Order

1. Make preview navigation fully visible on `/dev/mail`.
2. Move preview content above assigns/settings on individual preview routes.
3. Rename visible demo brand and copy from Northstar Ops to AtlasDesk.
4. Add a shared AtlasDesk HTML email shell and apply it to demo mailers.
5. Capture only high-value follow-up copy issues here.

## Acceptance Checks

- `/dev/mail` exposes every healthy mailer scenario link without expanding groups.
- `/dev/mail/:mailable/:scenario` renders the preview pane before the assigns form.
- Demo dashboard and docs describe AtlasDesk, while demo operator URLs still use `tenant_id=northstar`.
- Demo email HTML is styled, branded, and email-safe enough for the iframe preview.
- The operations usage alert no longer presents heading/body text as a run-on phrase.

## High-Value Follow-Ups

- Consider replacing low-context reset copy with a clearer “Restore the demo to its starting state” flow.
- Consider adding a short `/dev/mail` start-page sentence that says “Pick any email on the left to see the rendered message first, then edit sample data below.”
