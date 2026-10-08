# Phase 169 — UI Review

**Audited:** 2026-10-08  
**Baseline:** Approved `169-UI-SPEC.md`, inherited Phase 168 system, current Mailglass brandbook  
**Screenshots:** Reviewed 20 existing after captures at 320, 390, 768, and 1440 CSS px. No new captures: the documented 4102 harness was not running; captures are from revision `e45aa8e1b82f97dd45e08c67c9cfe6fdd7f31d68`.  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

The existing images show actual connected Health, Deliveries, detail, Quick view, and replay-review states, with recorded source/built/served CSS parity. I compared those images with the current source. They predate the latest terminal replay write-failure repair, but that repair does not change the reviewed visual files. I did not treat test summaries as visual proof.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Health interval copy misses the contract's exact form and appears after the metric summary. |
| 2. Visuals | 2/4 | Health switches to three metric columns at `lg`; replay action also precedes the evidence it follows in the contract. |
| 3. Color | 3/4 | Semantic theme tokens and text/icon states are consistent; repeated Open delivery links use the reserved primary accent. |
| 4. Typography | 4/4 | Body, label, heading, and display roles use the declared 16/14/20/28px scale and 400/700 weights. |
| 5. Spacing | 4/4 | Inspected production spacing follows the 4px grid; 44px controls and readable reflow appear in captures. |
| 6. Experience Design | 3/4 | Exact-state behavior is strongly covered; the full manual zoom/theme/touch matrix and every state criterion were not independently exercised. |

**Overall: 18/24**

## Top 3 Priority Fixes

1. **Move Health's observation interval and check time before the metric cards, and render `Observed from {start} to {end} UTC ({hours} hours)`.** Operators currently see counts before their population's time basis, and the copy does not match the approved contract. See `operator_live.ex:866-870,2498-2505`.
2. **Replace the Health `lg:grid-cols-3` layout with the specified readable two-column desktop arrangement and one column below 768px.** At the `lg` threshold the sidebar reduces available main width, compressing five metric cards into three columns. See `operator_live.ex:698-699`.
3. **Move “Review webhook replay” below the timeline, current suppression, and Account support evidence.** The current DetailHeader places the consequential action directly below identity; the contract orders it after the evidence review. See `operator_live.ex:986-1022` and `operator/detail_header.ex:74-116`.

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING — Health interval copy and order diverge from the exact contract.** The rendered 1440px capture reads `Observation window: {ISO start} to {ISO end} UTC`, without the required `Observed from … to … UTC ({hours} hours)` form. The line is also below all five metric cards, although the contract requires the interval before the summary. Change `health_window_copy/1` and place the interval/check-time block between the heading and metrics. [operator_live.ex:695-699,866-870,2498-2505]
- **PASS — Scope and metric labels are generally precise.** “Active suppression records” identifies the unit; its hint distinguishes current Mailglass records from historical suppressed Delivery Events. Failed webhook and unmatched Event hints identify their populations. The hints remain available to assistive technology as screen-reader-only text. [operator_live.ex:714-729,746-761,779-797; components.ex:467-480]
- No generic “Submit”, “Click Here”, or “OK” CTA was found in the audited outbound UI. Primary actions use “Review webhook replay”, “Confirm replay”, “Apply filters”, “Clear filters”, and “Back to deliveries”.

### Pillar 2: Visuals (2/4)

- **WARNING — Health cards use three columns at `lg`.** `lg:grid-cols-3` activates at Tailwind's large breakpoint while the persistent sidebar still consumes horizontal space. The 1440px capture visibly has three columns; the 768px capture is one column. The contract calls for two readable columns and one below 768px. Use an explicit two-column desktop grid and retain the one-column narrow layout. [operator_live.ex:698-699; existing `health-1440.png`, `health-768.png`]
- **WARNING — Replay CTA interrupts the detail evidence hierarchy.** In the 768px full-detail capture, identity is followed immediately by a Webhook replay panel/button; the timeline, suppression, and Account support evidence follow it. The contract places the eligible action after those evidence groups. Move the CTA into a final action section after SupportCards. [operator_live.ex:986-1022; operator/detail_header.ex:74-116; existing `detail-768.png`]
- **PASS — Shared shell, selected Account, clear page heading, visible text labels, native collection semantics, and explicit “Open delivery” control are present.** The collection uses cards at 768px because available content is 528px, and a table at 1440px with 1200px content; this follows the content-width threshold rather than viewport width. [deliveries_list.ex:120-164,235-303; `169-BASELINE.md` after-capture width table]
- Icon-only shell controls inspected in the audited components carry accessible labels; decorative icons are hidden from assistive technology in the capture/test evidence. The current marked-up findings show no ARIA-grid substitution.

### Pillar 3: Color (3/4)

- **WARNING — The repeated row opener uses `text-primary`.** Every compact result card renders “Open delivery →” in the accent. This repeats the primary accent over the full collection, although the design contract reserves accent emphasis for replay review, selected/current cues, active navigation, and focus. Use the established link-role color for ordinary row links; keep the explicit replay CTA and selected/current accents. [operator/deliveries_list.ex:302,398; existing `deliveries-768.png`]
- The shell's light/dark palette and semantic status colors are token-based in `assets/css/app.css`; source classes use semantic roles rather than literal hex values. Failures have text/icon as well as color, no-match is neutral, and the suppression count is labeled “Tracked”. No universal green “healthy” state appears. [assets/css/app.css:31-86; components.ex:428-490; operator_live.ex:779-797]
- `text-primary` appears in a small set of component declarations (including the repeated row opener), while status/error/warning classes use semantic tokens. The issue is placement/frequency on repeated openers, not palette construction.

### Pillar 4: Typography (4/4)

- **PASS — Contract size roles are defined in the shipped CSS:** label 14px, body 16px, heading 20px, display 28px, each with the specified line-height. The audited operator templates use these role classes and `font-bold` alongside the normal inherited weight; identifiers use `mono`. [assets/css/app.css:119-126; operator_live.ex and `operator/*.ex`]
- The after-capture record reports 16px body and 14px labels at 320, 390, 768, and 1440px; image inspection confirms wrapping rather than reduced body text. I found no added font face or competing type scale in the phase UI.

### Pillar 5: Spacing (4/4)

- **PASS — Inspected app spacing follows the declared 4px scale.** Components use named `xs/sm/md/lg` values and Tailwind spacing values such as `p-6`/`gap-4` (24px/16px), which are on-grid. The arbitrary `[overflow-wrap:anywhere]` and `max-w-[18rem]` values set wrapping/width behavior, not off-grid spacing. [operator_live.ex:696-699; components.ex:456-490; operator/detail_header.ex:38-116]
- The 320/390/768/1440 capture evidence records zero page-level horizontal overflow. The responsive result cards retain an explicit opener, and the detail/replay action controls are at least 44px high in source and the recorded rendered checks. This score does not imply physical-device touch was tested.

### Pillar 6: Experience Design (3/4)

- **PASS — Exact identity and evidence states are treated distinctly in source.** Delivery back navigation drops selected Delivery/full mode/exact support focus while preserving committed Account/filter/page state; exact selected events outside the 100-event slice render separately. [operator_live.ex:955-956,2175-2178; operator/timeline.ex:117-146]
- **PASS — Loading, partial/unavailable/stale Health reads, exact support read failure, replay zero/one/many review, stale-target rejection, pending duplicate prevention, and command-versus-audit feedback have implementation and focused test coverage.** The final Back behavior matches UI-SPEC rather than the superseded expectation that exact support IDs remain after returning to the list. [operator_live.ex:866-901,2025-2046; `169-VALIDATION.md` and `169-05-SUMMARY.md`]
- **WARNING — Coverage is substantial but not a complete manual run of all 82 explicit UI criteria.** The 82 resolutions span E1–E11; the existing 20 screenshots cover the principal connected states at four widths, and the recorded automated totals include 2 rendered and 9 connected Phase 169 cases. The broad 197-pass/1-skip operator browser run predates the latest terminal-write repair; the latest focused evidence is 10 replay-core, 39 operator-core, and 104 Admin operator/replay tests. The full native 200% route/theme matrix, manual OS appearance switching, physical-device touch, and every zero/one/many/loading/error/overflow/long-value combination were not independently repeated in this audit. Do not describe the 82 criteria as all manually verified. [169-BASELINE.md, “After Evidence” and proof limits; 169-VALIDATION.md, “Manual-Only Verifications”]
- **Interaction capture status:** off by configuration. Interaction findings above are based on source and the pre-existing test/capture evidence; I did not create or claim a new post-interaction capture. The documented native Chrome 200% inspection covers one route family, not the complete matrix.

## Files Audited

- `.planning/phases/169-outbound-investigation-and-recovery/169-UI-SPEC.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-CONTEXT.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-01-PLAN.md` through `169-05-PLAN.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-01-SUMMARY.md` through `169-05-SUMMARY.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-BASELINE.md` and `169-VALIDATION.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`
- `brandbook/brand-book.md`, `brandbook/copy/microcopy.md`, `mailglass_admin/docs/design-system.md`
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- `mailglass_admin/lib/mailglass_admin/components.ex`
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex`
- `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex`
- `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/assets/css/app.css`
- Existing screenshots: 20 files under `.planning/phases/169-outbound-investigation-and-recovery/artifacts/after/`

Registry audit skipped: the approved contract declares no shadcn or third-party registry, and no `components.json` exists.
