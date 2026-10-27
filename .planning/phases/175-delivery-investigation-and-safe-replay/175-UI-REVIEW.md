# Phase 175 — UI Review

**Audited:** 2026-10-27  
**Baseline:** Approved `175-UI-SPEC.md` and the Mailglass semantic design tokens  
**Screenshots:** Reviewed retained cold/warm Phase 175 captures from source `8cd973774c293cc3d95b1e8f9be489b5e4ca5caa` (digest `77fdd45e830c44b07e1062af584414eb4d2c07f2747a7607aa47866cbf81153b`); no new screenshots captured  
**Interaction captures:** off (`workflow.ui_interaction_capture=false`)

The current checkout is `42f7a3a6`; the intervening commits do not change the reviewed UI source. The visual review used the connected Delivery and Inbound captures at 1440px and 320px, plus the retained real-zoom and Storybook captures. Interaction notes below are code- and receipt-derived; no interaction state was newly captured.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Inbound full-detail CTA differs from the approved “Review inbound replay” label. |
| 2. Visuals | 3/4 | Strong information grouping, but the prominent Inbound replay CTA reads as an error action. |
| 3. Color | 2/4 | Three Inbound replay controls use the error color; the Storybook theme control also hardcodes an RGB shadow. |
| 4. Typography | 4/4 | Four distinct sizes and only 400/700 weights match the contract; all six font faces loaded. |
| 5. Spacing | 3/4 | Layout stays on the 4px grid, though some replay spacing bypasses the named tokens. |
| 6. Experience Design | 4/4 | Scoped states, recovery, focus, keyboard, and responsive behavior have current cold/warm proof. |

**Overall: 19/24**

## Top 3 Priority Fixes

1. **Use the primary accent for Inbound replay controls** — the red error treatment makes a normal review/confirm action look failed or destructive — replace `btn-error` with `btn-primary` in Inbound Quick view, Full detail, and replay confirmation.
2. **Match the Inbound full-detail CTA copy** — users see different labels from the quick and full entry points — change `Review replay` to `Review inbound replay`.
3. **Remove the Storybook helper’s raw RGB shadow** — the retained review surface escapes the semantic color system — use the existing semantic overlay/shadow token instead of inline `rgb(13 27 42 / 18%)`.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING** — [inbound/detail_header.ex:115](../../../mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:115) renders `Review replay`, while the approved CTA is “Review inbound replay” ([175-UI-SPEC.md:78](175-UI-SPEC.md:78)). Quick view already uses the approved wording at [inbound/quick_view.ex:172](../../../mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex:172), so operators encounter inconsistent labels when moving between entry points. Use the same approved text in full detail.
- The other inspected contract copy is aligned: Delivery empty-state headings/bodies match [175-UI-SPEC.md:79-81](175-UI-SPEC.md:79), suppression empty and failure copy matches lines 82-86, and mounted replay recovery provides the named “Review again” path.

### Pillar 2: Visuals (3/4)

- **WARNING** — The retained production captures show clear primary facts followed by grouped technical evidence, timeline, suppression, and replay sections; long IDs wrap in the 320px screenshots. In the Inbound Full detail capture, however, the solid red `Review replay` button is the strongest visual action in a normal accepted-record state. Its prominence and error-like treatment compete with the record status instead of reading as the primary review action ([inbound-1440.png](artifacts/phase175/phase175/cold/phase175-layout/inbound-1440.png), [inbound-320.png](artifacts/phase175/phase175/cold/phase175-layout/inbound-320.png)). Apply the primary accent styling described in the color contract.
- Delivery screenshots at 1440px and 320px keep subject/status first, use stable card grouping, and preserve readable ordering. No clipping or horizontal spill was visible in the reviewed route captures.

### Pillar 3: Color (2/4)

- **WARNING** — Three Inbound replay actions are assigned `btn-error`: Quick view at [inbound/quick_view.ex:170](../../../mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex:170), Full detail at [inbound/detail_header.ex:113](../../../mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:113), and confirmation at [inbound/replay_modal.ex:112](../../../mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex:112). The contract reserves the primary accent for eligible replay review/confirm actions and Crimson for error status only ([175-UI-SPEC.md:69-72](175-UI-SPEC.md:69)). Change these normal actions to `btn-primary`; keep semantic error styling on actual failure feedback.
- **WARNING** — The retained Storybook theme picker uses a hardcoded `rgb(13 27 42 / 18%)` shadow in HEEx at [delivery_investigation.story.exs:22](../../../reference/demo_app/storybook/delivery_investigation.story.exs:22), despite the contract’s semantic-token-only rule ([175-UI-SPEC.md:72](175-UI-SPEC.md:72)). Replace it with a semantic shadow token. The product surfaces otherwise use theme tokens, and the screenshots show the intended Paper/White distribution.
- Current cold/warm Axe receipts report **0 violations and 116 incomplete findings** per condition. Those incomplete findings have separate rendered triage and remain incomplete; they are not counted here as a clean Axe pass.

## Remediation verification — 2026-10-27

The findings above are the pre-repair audit. The repairs are now verified against fresh cold/warm browser evidence from source revision `fc262b989c1c38ab86376437ff2dc4b1ef4ea9a8` (Phase 175 digest `0700f87bb124f955131e20fd8f69fcf87c0a50a499aa636d954b49dc9400eedb`). The production Inbound quick-view, full-detail, and confirmation actions use `btn-primary`; genuine error feedback keeps semantic error colors; the full-detail copy matches “Review inbound replay”; and the Storybook theme helper uses `var(--shadow-overlay)`. The Theme picker’s inline and computed shadow are asserted in the current fidelity browser run.

The outbound replay modal now uses `mt-lg` and `p-md` where they equal the existing semantic spacing values. Its 12px `space-y-3` rhythm is retained as a deliberate `sm + xs` presentation gap; the exception is recorded in [175-UI-SPEC.md](175-UI-SPEC.md), with no new token. These repairs are covered by focused component tests, fidelity 10/10, and Axe 26/26 in each condition. The original pillar scores remain the pre-repair audit scores; this addendum records repair and automated evidence, not a new visual rescoring. Incomplete Axe findings remain incomplete.

### Pillar 4: Typography (4/4)

- **No deviation found.** The inspected UI uses `text-label` (14px), `text-body`/`text-base` (16px), `text-heading` (20px), and `text-display` (28px), matching the four contract roles. The loaded weight classes are `font-normal` and `font-bold` only, matching 400/700. The token definitions are in [app.css:118-126](../../../mailglass_admin/assets/css/app.css:118), and current-source fidelity receipts confirm all six Inter, Inter Tight, and IBM Plex Mono faces loaded. Identifiers use IBM Plex Mono and visibly wrap in the retained narrow captures.

### Pillar 5: Spacing (3/4)

- **WARNING** — The visual rhythm is consistent and the reviewed layouts remain on a 4px grid. Some replay wrapper spacing bypasses the contract’s named utilities: `space-y-3` (12px), `p-4` (16px), and `mt-6` (24px) appear in [operator/replay_modal.ex:52](../../../mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:52), [operator/replay_modal.ex:76](../../../mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:76), and [operator/replay_modal.ex:39](../../../mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:39). The spec lists named tokens and says there are no exceptions ([175-UI-SPEC.md:48-50](175-UI-SPEC.md:48)). Prefer the corresponding semantic aliases; if 12px is intentional, add it as an explicit approved token. No arbitrary pixel/rem spacing classes were found in these components.

### Pillar 6: Experience Design (4/4)

- **No task-flow defect found in the reviewed evidence.** Full-detail technical groups are open by default. Suppression distinguishes ready match, ready empty, stale retained evidence, and unavailable; replay distinguishes exact, ambiguous, and unavailable targets. Replay failures stay in the mounted dialog with fresh review available, while successful Delivery and Inbound results use their actual outcome copy. The shared dialog supplies `role="dialog"`, `aria-modal`, named Close, Escape, focus containment, and origin-trigger return ([components.ex:625](../../../mailglass_admin/lib/mailglass_admin/components.ex:625)).
- The source-bound cold/warm inventory records Demo 4/4, connected Admin 10/10, fidelity 10/10, Axe 26/26, and Delivery/Inbound layout 6/6 each, with no skips reported. Screenshots and layout receipts cover 320px, wider breakpoints, and real 200% Chromium zoom. The 116 Axe incomplete findings remain an explicit confidence limit despite separate triage and successful keyboard/focus assertions.

## Files Audited

- Design/acceptance: `175-UI-SPEC.md`, `175-AUTOMATION.md`, `175-VALIDATION.md`, `175-01` through `175-06` PLAN/SUMMARY files, `.planning/PROJECT.md`, `.planning/METHODOLOGY.md` D-52, `mailglass_admin/docs/phase175-review.md`.
- Production UI: `mailglass_admin/lib/mailglass_admin/components.ex`; Operator LiveView, Delivery detail/replay/suppression components; Inbound LiveView, detail/quick/replay components; `mailglass_admin/assets/css/app.css`; `brandbook/tokens.css`.
- Retained presentation: `reference/demo_app/storybook/delivery_investigation.story.exs`, `reference/persona_spec/quick_view_scenarios.ex` and `.json`.
- Current evidence reviewed: cold/warm Delivery and Inbound layout screenshots, real-zoom screenshots/layout receipts, Storybook captures, cold/warm fidelity and Axe reports, and `artifacts/phase175/phase175/execution.json`.
