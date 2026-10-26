# Phase 170 — UI Review

**Audited:** 2026-10-09 (refreshed after latest UI fixes)
**Baseline:** Abstract six-pillar standards informed by the approved Phase 168 UI-SPEC, Phase 170 D-13/D-14, and applicable locked Phase 121 copy contracts; no Phase 170 UI-SPEC exists.
**Screenshots:** Existing Phase 170 Playwright screenshots are documented in `170-RENDERED.md` (Full detail at 320/390/768/1440 CSS px across Light/Dark/System, plus actual 200% zoom). The full Playwright suite has now passed. The separate audit CLI could not create captures because of sandbox restrictions; there is no new independent screenshot review of the changed Quick view and replay dialog overlays.
**Interaction captures:** off (workflow.ui_interaction_capture is false); connected and rendered Playwright coverage is recorded separately.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Phase 101/121 locked copy is preserved; changed visible/model copy and Quick view ARIA labels now use natural case. |
| 2. Visuals | 3/4 | Quick view controls and title are corrected; saved visual evidence does not independently show the changed overlay states. |
| 3. Color | 3/4 | Semantic theme colors and text-backed statuses are used; overlay surface balance was not rechecked in a new screenshot. |
| 4. Typography | 3/4 | Quick view uses heading type and the list heading was raised to body type; residual hierarchy is modest and not verified in a fresh overlay capture. |
| 5. Spacing | 4/4 | Reviewed inbound spacing follows named tokens; replay viewport bounds use a named CSS rule. |
| 6. Experience Design | 4/4 | Native disabled navigation controls, accessible names, 44px targets, and pending refresh announcement are present; the full Playwright suite passes. |

**Overall: 21/24**

## Top 3 Priority Fixes

1. **Capture the updated overlays in a rendered audit** — the Quick view arrow controls and replay dialog sizing changed after the saved screenshot pass — capture Quick view and replay review at narrow and desktop widths in light and dark themes, then inspect focus, wrapping, and contrast.
2. **Recheck overlay color balance and contrast from those captures** — source uses semantic tokens, but saved screenshots show Full detail rather than these changed overlays — verify text, borders, disabled-arrow contrast, and approximate surface balance in both themes.
3. **Confirm the list heading hierarchy visually** — the semantic `h2` now uses bold body type, which resolves the former label-scale mismatch — include it in the same screenshot pass and confirm it remains distinct from rows and metadata.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- Phase 101 COPY-LD-07 locks the subtitle “See why an InboundMessage routed the way it did — execution timeline, routing trace, and raw evidence.” It is intentionally retained (`inbound_live.ex:566`). Phase 121 also locks “No InboundMessages have been recorded yet.” (121-01 D-07 / 121-04 D-15), “Recent InboundMessages” (LD-16), the orientation-strip tip “InboundMessage didn't route as expected?” (LD-12 / D-08), and the no-selection helper. These strings are contractual, not generic or casing defects (`records_list.ex:419-420`; `inbound_live.ex:815-818,1073`; `operator/shell.ex:477-480`).
- The Account empty state matches the inherited copy contract (`records_list.ex:101-105`). Non-locked visible/model copy now uses natural case, including “Inbound messages” (`overview.ex:25-30`), “inbound message” in selection details (`inbound_live.ex:634-636`; `quick_view.ex:96-98,209-211`), and “Inbound message ID” (`replay_modal.ex:69-71`). Quick View ARIA labels are “Previous/Next inbound record” and list row names use “Open inbound message” (`quick_view.ex:63-67`; `records_list.ex:182-186`).
- **Finding supporting 4/4:** the identified PascalCase strings are retained by an explicit copy contract; the editable copy aligns with the product voice, Account language, and recovery semantics. The no-match, unavailable, and replay-state messages remain distinct (`records_list.ex:64-123`; `replay_modal.ex:47-52,129-150`).

### Pillar 2: Visuals (3/4)

- **WARNING** — Existing rendered evidence visually reviews Full detail at 320px and actual 200% zoom, with geometry checks across the 320/390/768/1440 CSS pixel and theme matrix (`170-RENDERED.md:18-34`). It does not provide an independent screenshot review of the changed Quick view arrows/title or replay dialog CSS sizing. The full Playwright suite passing adds structural and interaction evidence, but not a fresh visual inspection of those overlay states.
- Positive evidence: the Quick view title has heading-scale prominence and native previous/next controls now expose accessible names and 44×44px minimum targets (`quick_view.ex:58-76,168-192`). The replay dialog has a clear title, visible close/cancel controls, and its own scroll boundary (`replay_modal.ex:24-60`).

### Pillar 3: Color (3/4)

- **WARNING** — Inbound implementation uses semantic theme colors; the primary/accent class scan finds three uses (selected-row edge and two primary CTAs), and HEEx contains no raw hex or `rgb()` values. Route match verdicts pair semantic success/error colors with explicit text (`routing_trace.ex:51-66`). The saved rendered captures do not independently show the newly changed Quick view/replay overlay colors, so their contrast and 60/30/10 screen balance remain unverified here.
- The light/dark palette remains in shared CSS theme tokens (`mailglass_admin/assets/css/app.css:29-87`). Replay eligibility uses textual status, and its confirmation uses the destructive color role (`replay_modal.ex:81-114`).

### Pillar 4: Typography (3/4)

- **WARNING** — The list-region title remains a semantic `h2` and now uses bold `text-body` (16px) instead of the previous 14px label treatment (`inbound_live.ex:815-818`). This restores a useful size distinction, though it remains below the 20px `text-heading` role; rendered inspection should confirm the title reads distinctly in the list/overlay composition.
- Positive evidence: Quick view and replay dialog titles use `text-heading`; field labels use `text-label`; weight classes follow the installed 400/700 set (`quick_view.ex:59-61`; `replay_modal.ex:47-49`; `app.css:152-185`). Inter Tight is assigned to headings and IBM Plex Mono to identifiers (`app.css:354-365`).

### Pillar 5: Spacing (4/4)

- Reviewed inbound padding and gaps now use the declared semantic scale: records list uses `px-md py-sm` and `px-md py-md` (`records_list.ex:59,251,355`); detail/filter layout uses `space-y-md`, `p-sm`, `p-md`, and `mt-lg` (`inbound_live.ex:615,645,659,664,746,810`); the replay dialog uses named spacing utilities (`replay_modal.ex:19,36,45-46,64-94`).
- Replay viewport bounds now live in `.mg-inbound-replay-dialog` rather than arbitrary Tailwind values (`app.css:295-298`). `p-0` is an intentional outer-card reset; no off-scale spacing value remains in the reviewed inbound modules.
- **Finding supporting 4/4:** the previous arbitrary panel bounds and repeated numeric spacing classes are resolved; current implementation aligns with the inherited scale.

### Pillar 6: Experience Design (4/4)

- **Finding supporting 4/4:** Previous/next controls use native links when available and native disabled buttons at collection boundaries. Both states have accessible names and 44×44px minimum dimensions (`quick_view.ex:63-76,168-192`), addressing the prior generic-span concern.
- Refresh history uses `phx-disable-with="Refreshing history…"`, `aria-live="polite"`, and `aria-atomic="true"` (`inbound_live.ex:677-686`). Phoenix LiveView applies pending text and disables the triggering element during a `phx-click` round trip (`deps/phoenix_live_view/assets/js/phoenix_live_view/view.js:1482-1497`); the LiveView test asserts these attributes (`inbound_live_test.exs:1520-1542`).
- Raw evidence uses a native disclosure button with synchronized expanded state, focus styling, and a persistent live status message (`evidence_card.ex:50-64,137-147`). Route trace uses native `<details>/<summary>` and labels current-router simulation (`routing_trace.ex:25-37`). Replay confirmation has a named modal, focus trap, Escape and visible close/cancel actions, eligibility-specific disabled state, and busy copy (`replay_modal.ex:24-42,54-61,94-116`).
- The full Playwright suite passes; Phase 170 summaries record 206 passed, one existing guarded skip, and zero failures (`170-08-SUMMARY.md:90-96`). The rendered report documents viewport/theme, zoom, reduced-motion, touch, keyboard disclosure, and focus-return checks (`170-RENDERED.md:18-34`). No manual UAT request is needed for the remaining screenshot evidence gap.

## Files Audited

- `mailglass_admin/lib/mailglass_admin/inbound_live.ex`
- `mailglass_admin/lib/mailglass_admin/inbound/{detail_header,evidence_card,filters_form,overview,quick_view,records_list,replay_modal,routing_trace,timeline}.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/assets/css/app.css`
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`
- `deps/phoenix_live_view/assets/js/phoenix_live_view/view.js`
- `.planning/milestones/v1.14-phases/121-inbound-surface-redesign/121-01-PLAN.md`
- `.planning/milestones/v1.14-phases/121-inbound-surface-redesign/121-04-PLAN.md`
- `.planning/milestones/v1.14-phases/121-inbound-surface-redesign/121-UI-SPEC.md`
- `.planning/milestones/v1.11-phases/101-microcopy-pass/101-01-PLAN.md`
- `.planning/milestones/v1.11-phases/101-microcopy-pass/101-01-SUMMARY.md`
- `.planning/milestones/v1.11-phases/101-microcopy-pass/101-VERIFICATION.md`
- `.planning/phases/170-inbound-investigation-and-recovery/170-RENDERED.md`
- `.planning/phases/170-inbound-investigation-and-recovery/170-08-SUMMARY.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`
- `mailglass_admin/docs/design-system.md`
- `mailglass_admin/docs/operator-trust.md`

