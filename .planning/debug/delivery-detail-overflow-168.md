---
status: diagnosed
trigger: "Phase 168 UAT: at actual 320 and 390 CSS px in the running operator demo, full Delivery detail page document.scrollWidth is 473px because the long Mailer value extends beyond the viewport; at 768/1440 it fits. In the 320px DOM, the offending element is `<p class=\"text-body text-secondary\">MailglassDemoWeb.Mailers.OperationsMailer.usage_alert</p>` under #delivery-detail-...."
created: 2026-10-08T12:04:59-04:00
updated: 2026-10-08T12:12:00-04:00
audit_acknowledged:
  milestone: v2.9
  at: 2026-10-26
  status: diagnosed
---

## Current Focus

bug_class: bohrbug (deterministic layout overflow)
hypothesis: The detail header emits the full Mailer identifier in a paragraph with normal wrapping only; because the identifier has no spaces and the paragraph has no break-anywhere rule, its unbreakable run paints beyond the available width at narrow viewports.
test: Compare the exact HEEx and its container constraints with the Phase 168 responsive contract, existing long-value wrapping patterns, and focused tests.
expecting: The Mailer paragraph lacks a wrap rule while adjacent long technical values use break utilities; tests check text presence but not rendered width.
next_action: Return root cause and minimal fix direction; diagnosis is source-backed and no source change or tests are authorized.

reasoning_checkpoint:
  hypothesis: "The Mailer paragraph in Operator.DetailHeader has no overflow-wrap rule, so the long no-space module path retains a 473px intrinsic text run and overflows at the reported 320/390px viewports."
  confirming_evidence:
    - "The live UAT observation reports document.scrollWidth=473px at 320 and 390 CSS px and identifies the p.text-body.text-secondary containing MailglassDemoWeb.Mailers.OperationsMailer.usage_alert; it fits at 768 and 1440."
    - "DetailHeader.detail_header/1 emits @delivery.mailable in a bare <p class=\"text-body text-secondary\">. Its outer flex child has min-w-0, but the mailable paragraph itself has no break utility or overflow-wrap rule."
    - "The Phase 168 UI-SPEC requires long labels and identifiers to wrap or expose the full value without hover; nearby technical-value components already use break-words, break-all, or [overflow-wrap:anywhere]."
  falsification_test: "At the same 320px reproduction, if computed styles already allow arbitrary breaking for the mailable text and its rendered line boxes stay inside the paragraph, this source hypothesis is false and the overflow must come from another descendant."
  fix_rationale: "Applying the existing project wrapping pattern to the mailable paragraph allows emergency breaks only when needed while preserving the complete visible identifier; no dependency or layout redesign is necessary."
  blind_spots: "The 473px measurement is supplied by the parent; I did not operate the browser or inspect computed styles. No code or browser tests were run, as requested. A stale asset mismatch is not evidenced and is unlikely because the missing behavior is not encoded in the HEEx class list."
  candidate_causes:
    - "code: the Mailer value paragraph has no overflow-wrap/break utility, unlike neighboring technical-value fields."
    - "data: the seeded fully-qualified module identifier is a long uninterrupted string."
    - "environment: at 320/390 CSS px the available inline size is narrower than that string's unbroken run; wide viewports mask the issue."
  and_gate: "yes — the visible overflow requires the no-break rendering behavior, a long no-space value, and a viewport narrower than the resulting text run; wider viewports do not reproduce it."

## Symptoms

expected: The full Delivery detail page fits within the viewport at 320 and 390 CSS px, with long values wrapping or clipping in an intentional, readable way.
actual: At actual 320 and 390 CSS px, document.scrollWidth is 473px; the Mailer value extends beyond the viewport. At 768 and 1440 CSS px it fits.
errors: None reported.
reproduction: Open the running operator demo's full Delivery detail page at 320 CSS px; inspect document.scrollWidth and the long Mailer value under #delivery-detail-.... Repeat at 390, 768, and 1440 CSS px.
started: Found during current Phase 168 UAT; introduction time unknown.

## Eliminated

## Evidence

- timestamp: 2026-10-08T12:04:59-04:00
  checked: Phase 168 UAT observation supplied by orchestrator
  found: At viewport widths 320 and 390 CSS px, document.scrollWidth is 473px and the offending descendant is a `p.text-body.text-secondary` containing `MailglassDemoWeb.Mailers.OperationsMailer.usage_alert`; at 768 and 1440 the detail page fits.
  implication: Deterministic narrow viewport overflow is localized to a long, uninterrupted module identifier in the Mailer value; inspect value rendering and layout constraints.

- timestamp: 2026-10-08T12:12:00-04:00
  checked: `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`, surrounding layout, and existing wrapping patterns
  found: `DetailHeader.detail_header/1` renders `@delivery.mailable` in a bare `p.text-body.text-secondary`. The paragraph has no `min-w-0`, `break-words`, `break-all`, or `[overflow-wrap:anywhere]`; the outer flex child does have `min-w-0`. Nearby exact values use explicit wrapping, including `operator/deliveries_list.ex`, `operator/quick_view.ex`, and `components.ex`.
  implication: The field's child text is the outlier: parent min-width is bounded, but the field is not instructed to break the no-space identifier when its text exceeds the bounded width.

- timestamp: 2026-10-08T12:12:00-04:00
  checked: Phase 168 responsive contract and relevant coverage
  found: `168-UI-SPEC.md` requires long labels and identifiers to wrap or expose their full value without hover. `168-02-PLAN.md` explicitly requires ordinary content to avoid page-level horizontal scrolling and long subjects/recipients/names/diagnostic IDs to expose full values. Existing `operator_live_test.exs` cases check Mailer/value rendering, but no targeted assertion checks a long Mailer value's actual narrow-viewport wrapping or document width.
  implication: The observed behavior violates the accepted plan/UI contract; current server-rendered assertions do not catch this layout regression.

## Resolution

root_cause: The operator detail header renders a full qualified Mailer identifier in a paragraph without an overflow-wrap rule. The value has no whitespace and exceeds the content width on narrow screens, so it overflows the document; the parent flex item's min-w-0 does not create break opportunities inside the paragraph.
fix: Add the existing arbitrary wrapping pattern, preferably `break-words [overflow-wrap:anywhere]` (with `min-w-0` for consistency), to the Mailer paragraph in `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`; retain the complete text. Add/extend a focused browser regression using a long no-space Mailer identifier at 320/390 CSS px and assert document width does not exceed viewport while full text remains present.
verification: Diagnosis confirmed by the supplied live-DOM measurement and source/contract review. No fix verification was attempted; parent explicitly prohibited editing source and running tests.
files_changed: []
