# Phase 176 Deferred Items

## 176-04 (found 2026-10-28)

- `mailglass_admin/e2e/phase169-journey.spec.js:459` expects the replay review to contain "does not resend outbound mail or prove provider receipt". `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:35` has read "It does not resend mail or prove provider receipt." since Phase 175 (`a9670252`, `fix(175): align inbound replay presentation`). The Playwright case "Phase 169 rendered route matrix stays readable across widths and missing media" therefore fails on this copy alone. Plan 176-04 did not touch the replay modal. Fix: align the spec literal with the modal copy.

## 176-07 (found 2026-10-28)

- Browser cases red with plan 176-07's `inbound_live.ex` and `inbound/filters_form.ex` replaced by their pre-plan versions (`b4d8d2a9`), so not caused by this plan: `mailglass_admin/e2e/flows.spec.js:747` (waits for `.flex.flex-col.items-end` inside `inbound-evidence-card`, a reveal-stack layout the single Raw provider source disclosure from plan 176-03 replaced) and `mailglass_admin/e2e/operator.spec.js:80` (expects `operator-replay-open` in the Deliveries Quick view, absent after the Phase 176 Deliveries detail changes). A wider run of `flows.spec.js` and `operator.spec.js` also reported `flows.spec.js:538`, `:824`, `:1215` (replay modal contrast, three themes) and `operator.spec.js:194`, `:227`, `:264` (replay flow copy); those were not re-run against the baseline but all concern the Deliveries replay surface, which plan 176-07 does not touch. Fix: align the specs with the 176-03/176-04 markup.

## 176-10 resolution (2026-10-28)

All browser reds above were spec drift against Phase 175 or plan 176-03 markup and copy, not product bugs, and are fixed in plan 176-10 commit `25b3cdd0`. Evidence for "drift, not regression": `replay_action.ex` renders the replay button only for `:exact`, `:ambiguous` and the recoverable `:read_unavailable` target (Phase 175 REPLAY-05, covered by `phase175_prohibition_contract_test.exs`), so specs that selected the first, unlinked row and expected `operator-replay-open` could not have passed after Phase 175. The replay copy ("does not resend mail…", "Eligibility changed. Review the current request again.") is the Phase 175 modal text, and `technical_details` has been non-collapsible since `1e4aae4c` (Phase 175).

- `phase169-journey.spec.js:459`, `operator.spec.js:196` (copy literal): aligned.
- `operator.spec.js:80`, `:264`, `flows.spec.js:538`, `:1215` x3 (replay CTA on an unlinked row): select the seeded exact-replay delivery; unavailable targets assert no CTA.
- `operator.spec.js:229` (frozen-request copy): "Eligibility changed. Review the current request again."
- `flows.spec.js:747` (reveal stack): asserts the 4px heading-to-caption gap in the single header group.
- `flows.spec.js:824` and the real-zoom case (`#delivery-detail-technical > summary`): no summary exists; assert visibility.
- `structural.spec.js:947` (new in the final run): the filter Apply button it measured was removed by D-01; it now measures the replay action in the exact-replay Quick view.
- Gallery and `structural.spec.js` event-error copy: reworded in plan 176-10 task 3.

## Deferred by plan 176-10 (not caused by Phase 176, not fixed)

- `mix format --check-formatted` (mailglass_admin) lists 10 files no Phase 176 commit touches: `persona_drift_guard_test.exs`, `bucket_a_coverage_test.exs`, `preview/chromium_test.exs`, `inbound/replay_modal_test.exs`, `stability_contract_test.exs`, `mix_config_test.exs`, `brand_test.exs`, `lib/.../operator/timeline.ex`, `lib/.../operator/replay_modal.ex`, `lib/.../auth.ex`.
- `mix credo --strict` (mailglass_admin): 1 warning and 5 readability/refactor items, none in a file this plan added. `operator_live.ex` `assign_delivery_state/5` cyclomatic complexity is now 24 (23 when plan 176-01 measured it).
- Axe `aria-allowed-attr` (critical) on the Deliveries row buttons: `aria-selected` on a `<button>` (`deliveries_list.ex`, since Phase 113 `532a8b17`). Coupled specs assert `aria-selected`, so the markup was left alone; plan 176-10's axe cases compare each state against the neutral page of the same collection and theme, so they prove "no new violations", not "zero".
