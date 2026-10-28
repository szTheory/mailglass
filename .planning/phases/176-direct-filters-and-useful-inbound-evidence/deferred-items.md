# Phase 176 Deferred Items

## 176-04 (found 2026-10-28)

- `mailglass_admin/e2e/phase169-journey.spec.js:459` expects the replay review to contain "does not resend outbound mail or prove provider receipt". `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:35` has read "It does not resend mail or prove provider receipt." since Phase 175 (`a9670252`, `fix(175): align inbound replay presentation`). The Playwright case "Phase 169 rendered route matrix stays readable across widths and missing media" therefore fails on this copy alone. Plan 176-04 did not touch the replay modal. Fix: align the spec literal with the modal copy.

## 176-07 (found 2026-10-28)

- Browser cases red with plan 176-07's `inbound_live.ex` and `inbound/filters_form.ex` replaced by their pre-plan versions (`b4d8d2a9`), so not caused by this plan: `mailglass_admin/e2e/flows.spec.js:747` (waits for `.flex.flex-col.items-end` inside `inbound-evidence-card`, a reveal-stack layout the single Raw provider source disclosure from plan 176-03 replaced) and `mailglass_admin/e2e/operator.spec.js:80` (expects `operator-replay-open` in the Deliveries Quick view, absent after the Phase 176 Deliveries detail changes). A wider run of `flows.spec.js` and `operator.spec.js` also reported `flows.spec.js:538`, `:824`, `:1215` (replay modal contrast, three themes) and `operator.spec.js:194`, `:227`, `:264` (replay flow copy); those were not re-run against the baseline but all concern the Deliveries replay surface, which plan 176-07 does not touch. Fix: align the specs with the 176-03/176-04 markup.
