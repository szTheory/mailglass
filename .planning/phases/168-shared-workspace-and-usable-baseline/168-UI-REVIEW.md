# Phase 168 — UI Review

**Audited:** 2026-10-08  
**Baseline:** Approved `168-UI-SPEC.md` and the current source; authored Phase 168 screenshots were reviewed as historical evidence only.  
**Screenshots:** not captured (server answered on `localhost:8080`, but Playwright CLI capture failed at desktop 1440×900, mobile 375×812, and tablet 768×1024).  
**Interaction captures:** off (`workflow.ui_interaction_capture=false`)

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Shared Account chooser copy matches the contract, but the reusable stat card and overview fallback still offer generic or divergent empty-state copy. |
| 2. Visuals | 2/4 | The account chooser and stat values now wrap, but navigation, preview names, list fields, and one Inbound quick-view identifier still hide full values behind hover-only titles or truncation. |
| 3. Color | 2/4 | Semantic light/dark surfaces and active-row accents are established, yet primary accent colors informational icons, headings, and code beyond the contract's reserved roles. |
| 4. Typography | 3/4 | The four declared type tokens and 400/700 weights are present, but 12px status badges and controls persist below the essential-label floor. |
| 5. Spacing | 2/4 | The shared shell uses named 4px-grid tokens, while 114 hard-coded spacing utility occurrences remain across implementation files despite the no-off-grid rule. |
| 6. Experience Design | 2/4 | Strong theme, feedback, overlay, and action states exist, but the Account switcher lacks explicit busy/rejection behavior and browser proof for the contract's retained-scope guarantee. |

**Overall: 14/24**

## Top 3 Priority Fixes

1. **WARNING — Remove hover-only access to truncated labels and identifiers** — Keyboard and touch users can lose exact account, record, recipient, provider, and navigation values; wrap content where practical and offer a keyboard/touch-accessible full-value detail where not.
2. **WARNING — Replace remaining off-grid spacing utilities** — 114 numeric spacing utility occurrences violate the explicit 4px token contract; migrate spacing to named tokens or equivalent values on the 4px scale, and retain arbitrary values only for non-spacing constraints.
3. **WARNING — Complete Account-switch failure states** — The shared switcher currently patches directly to a new scope without visible pending or rejected-switch feedback; preserve the last committed Account and URL until success, announce failure, and capture delayed/rejected browser cases.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The canonical stat card still defaults to generic `No data yet` at [components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:434), and the Gallery supplies the same fallback at [gallery_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/gallery_live.ex:267). This component is reused on working screens; require a cause-specific `empty_text` or select copy by state and source.
- **WARNING:** The overview's no-account fallback uses “Choose an Account” with a distinct body and a “Go to Deliveries” CTA ([operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:925)). The contract's shared empty state says “Select an Account to see scoped operator data.” and offers selection when available. Align this branch with that shared state and avoid a navigation CTA where no data-selection action is represented.
- Shared chooser copy in [shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:370) and Delivery empty/error copy in [deliveries_list.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:58) match their specific purposes. Replay confirmation distinguishes pending and completion states.

### Pillar 2: Visuals (2/4)

- **WARNING:** The Account chooser itself has improved: the current row wraps the host label and renders `tenant_id` directly ([shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:396)). The previous report's chooser-truncation finding is stale and was not carried forward.
- **WARNING:** Navigation primitives still use `truncate` with `title` as their only full-label affordance ([components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:249), `:267`, `:285`, `:313`, `:329`, `:345`). `tenant_chip` also truncates the Account value and puts its detail only in `title` ([components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:362)). These fail the long-text and no-hover-only requirements.
- **WARNING:** Delivery rows truncate recipient, Account, and provider values with titles at [deliveries_list.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:178); the table variant additionally truncates the record ID. Inbound collection uses similar patterns. Inbound Quick view truncates its Record ID with a title ([quick_view.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex:132)); the full ID should wrap as in the Delivery Quick view.
- The main composition uses a bounded content frame, visible Account scope, responsive sidebar/mobile navigation, and consistent headings. Current source was audited without a fresh screenshot; authored captures from the plans cannot establish current rendering after later source edits.

### Pillar 3: Color (2/4)

- Light/dark semantic palettes map Paper/Ink grounds and raised surfaces as specified in [app.css](/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css:32). Active navigation, selected rows, focus rings, and primary controls use accent tokens in contract-aligned roles.
- **WARNING:** Accent is also used for informational/support icons and informational headings, including chooser/help icons ([shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:367)), the “Email previews” label and selected check ([sidebar.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:52)), and instructional checks/code in preview ([preview_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview_live.ex:453)). The contract reserves accent for selection, primary CTA, active navigation/timeline cue, and keyboard focus. Use semantic info or neutral tones for informational content.
- There are 24 source lines containing `text-primary`, `bg-primary`, `border-primary`, or `ring-primary` across the implementation; several lines contain multiple elements. No hard-coded hex/RGB values were found in HEEx/Elixir implementation files. This is a source-use check, not a rendered 60/30/10 area measurement.

### Pillar 4: Typography (3/4)

- The stylesheet defines the contract's 14/16/20/28px rem tokens and loads only 400/700 for the UI font roles ([app.css](/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css:117)). Source class tokens use `text-label`, `text-body`, `text-heading`, and `text-display`; weights are predominantly `font-bold`/`font-normal` (400/700 mapping per the project font setup).
- **WARNING:** Status badge variants still use daisyUI's `badge-sm`, e.g. [components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:209); the size utility can reduce visible status text below the 14px label floor. The contract requires essential labels and status to stop using 12px text. Explicitly size essential compact badges and verify computed styles.
- Copy areas and supporting metadata mostly use declared 14px labels or 16px body. The source class scan found no explicit `text-xs`, `text-sm`, or `text-lg` utility tokens in HEEx/Elixir, though third-party utility variants may still set smaller computed type.

### Pillar 5: Spacing (2/4)

- Named tokens exist at 4/8/16/24/32/48/64px in [app.css](/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css:109), and the shared shell mostly uses them.
- **WARNING:** A source scan found 114 occurrences of hard-coded numeric spacing utilities in `mailglass_admin/lib/mailglass_admin` files. Examples: `mt-2`, `gap-1`, `space-y-4`, `mt-6`, `px-4`, `py-3`, and `p-6` in [shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:438), [operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:970), and [replay_modal.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:41). Some happen to equal 4px-grid values, but they bypass the declared named scale and include off-grid values such as `mt-6` (24px in Tailwind's scale is on-grid, while `mt-0.5` and `gap-0.5` are 2px and violate it). Convert 2px values and use consistent token intent for all spacing.
- **WARNING:** Arbitrary dimension classes such as `max-w-[18rem]` and viewport-bounded menu widths are constraints rather than spacing and can remain; arbitrary margins/paddings/gaps should not.

### Pillar 6: Experience Design (2/4)

- Theme preference uses visible native radios; system preference and OS changes, persistent explicit selection, reduced motion, feedback, and repeated patches have focused browser evidence in Plan 03/04 summaries. Quick view and replay confirmation cover named overlays, pending/disabled action, exact-target review, keyboard dismissal, focus return, and authorization-sensitive outcomes.
- **WARNING — behavior contract gap:** The shared Account option is a direct LiveView `patch` link ([shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:280)); the component has no local busy state or switch-specific status. Existing flash regions exist, but source does not provide the contract's “Account was not changed. Try choosing it again.” failure path for a rejected scope load. Add explicit loading/rejection state that preserves the committed Account and data until the new selection succeeds.
- **WARNING — rendered evidence gap:** The plan 04 summary reports Account switching coverage, but the fresh audit could not capture browser states because Playwright produced no images from the responding server. The UI-SPEC specifically calls for delayed and rejected switching plus retained prior scope. Existing test artifacts are evidence of prior behavior only; ensure those cases remain exercised in current browser acceptance.
- Loading, empty, unavailable, stale, and validation state patterns exist across shared data components and operator screens. A fresh 320/390/768/1440, zoom, keyboard/touch, and theme matrix was not recaptured in this audit.

## Files Audited

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-01-SUMMARY.md` through `168-04-SUMMARY.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-01-PLAN.md` through `168-04-PLAN.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md`
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex`
- `mailglass_admin/lib/mailglass_admin/components.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- `mailglass_admin/lib/mailglass_admin/operator/{deliveries_list,quick_view,replay_modal,detail_header}.ex`
- `mailglass_admin/lib/mailglass_admin/inbound/{quick_view,detail_header,records_list}.ex`
- `mailglass_admin/lib/mailglass_admin/preview/{sidebar,device_frame,tabs}.ex`, `preview_live.ex`
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex`
- `mailglass_admin/assets/css/app.css`

