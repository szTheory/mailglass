# Phase 176 — UI Review

**Audited:** 2026-10-28
**Baseline:** `176-UI-SPEC.md` (approved 2026-10-28, checker 7/7) with `176-CONTEXT.md` D-01..D-32 as the locked decisions
**Screenshots:** not captured. Static code audit only, per the orchestrator constraint: no dev server started, no `mix` or `npm` run, no writes under `mailglass_admin/priv/static/`. Every visual claim below is derived from markup, class lists and CSS source. Nothing was rendered.
**Interaction captures:** off (`interaction_capture: false`)
**Gitignore gate:** not run. No captures were taken, and the orchestrator constraint limits writes to this report. `.planning/ui-reviews/` was not created.
**Registry audit:** skipped. No `components.json` at repo root or under `mailglass_admin/`; UI-SPEC `shadcn_initialized: false`.
**Advisory lanes:** the Playwright and axe results cited in the phase summaries were not re-run. Where a finding depends on runtime behaviour, it is marked as a static inference.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract strings match verbatim, but the stale state repeats the load time and a blank window shows a garbled "Custom period ( hours)" option |
| 2. Visuals | 3/4 | Hierarchy and icons hold, but the Inbound full-detail header shows the envelope recipient twice and a subject-less Quick view drops the recipient |
| 3. Color | 3/4 | No raw hex and accent confined as specified, but Clear, the toggles and every Retry fall back to the daisyUI focus ring instead of the brand ring |
| 4. Typography | 4/4 | Only the three contract roles and weights 400/700 appear in phase markup (grep-verified); no off-contract sizes |
| 5. Spacing | 3/4 | Token scale holds on the new surfaces; the Deliveries Clear wrapper keeps a raw `gap-2` where Inbound uses `gap-sm` |
| 6. Experience Design | 2/4 | BLOCKER: the Deliveries filter panel can be hidden at desktop width with no visible control; Retry focus rings clip; a critical axe finding ships unchanged |

**Overall: 18/24**

Scoring notes. Pillar 6 is held to 2 because a reachable state removes the entire filter surface, which is the feature this phase exists to deliver. Pillars 1, 2, 3 and 5 are held to 3 because each has at least one WARNING-level defect verified in code, and none of them is a score-1 failure. Pillar 4 is held to 4 because the contract's type scale is followed exactly and the only deviations are spec-approved.

---

## Top Priority Fixes

1. **Deliveries filter panel can vanish at desktop width (BLOCKER)** — The mobile toggle uses `JS.toggle` (`operator_live.ex:944-947`) on a panel classed `hidden md:block` (`operator_live.ex:960`). Closing the panel on a phone writes an inline `display:none`, which `md:block` cannot override. The toggle is `md:hidden` (`operator_live.ex:951`), so there is no control left to reopen the filters until reload. Reproduce by opening and closing the panel in portrait, then rotating to landscape (at least 768px). The Inbound panel avoids this with a class toggle (`inbound_live.ex:724-726`); `assets/css/app.css:373-374` documents the reason. **Fix:** mirror Inbound with `JS.toggle_class("mg-inbound-filters-open", to: "#operator-filter-panel")`. That class already ships in the committed bundle, so no CSS change is needed.

2. **Retry and empty-state focus rings are clipped and inconsistent (WARNING)** — The error and unavailable Retry buttons, and the empty-state Clear buttons, are the last child of an `overflow-hidden` results container with no bottom padding (`operator/deliveries_list.ex:59`, `89-96`, `122-129`; `inbound/records_list.ex:68`, `114-121`, `148-155`). The stale-state Retry is followed by rows and is not affected. The 4px `mg-focus-ring` outline is clipped at the bottom edge. Clear, the toggles and Retry also lack `mg-focus-ring` entirely (see Pillar 3). **Fix:** add `mg-focus-ring` to the Clear buttons (`operator_live.ex:981-983`, `inbound_live.ex:768-770`, `deliveries_list.ex:122-129`, `records_list.ex:148-155`), the toggles (`operator_live.ex:948-951`, `inbound_live.ex:728-731`) and the Retry buttons. Add bottom padding to the container, or move Retry outside it.

3. **Blank `window_hours` on Deliveries shows an error and a garbled option (WARNING)** — `normalize_window_filter` treats a present blank as an error (`operator_live.ex:2609-2613`, because `is_map_key/2` is true). `filter_draft_params` keeps the empty string (`operator_live.ex:1400-1406`). `window_options/2` then prepends `{"Custom period ( hours)", ""}` (`operator/filters_form.ex:72-80`), which the select shows as selected. Inbound avoids all three steps (`inbound_live.ex:2232-2233`, `1941-1947`). **Fix:** port Inbound's `nil when raw_string == ""` branch and its error-only draft retention to Deliveries.

4. **Envelope recipient duplicated in the Inbound full-detail header; subject-less Quick view drops it (WARNING)** — `message_identity` renders the recipient line only when a subject exists (`components.ex:576-580`). The full-detail header passes the envelope recipient into it (`inbound/detail_header.ex:38-44`) and then renders the same value again as the "Delivered to" row (`inbound/detail_header.ex:93-111`). **Fix:** render the recipient line whenever a context is present, and suppress it in the full-detail header when the contact row carries the value.

5. **Critical axe violation carried into the phase (WARNING, pre-existing, deferred)** — `aria-selected` sits on `<button>` row controls (`operator/deliveries_list.ex:199-201` and `263-265`). The 176-10 summary and `deferred-items.md` both record it as critical (`aria-allowed-attr`). The phase's axe acceptance is "no new violations" against a baseline that already contains it. **Fix:** remove `aria-selected` from the buttons and keep `aria-current`; update the coupled specs that assert it.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Verified against the contract (no deviation):**
- Event error: "Latest recorded event was not applied. Choose a listed event." (`operator_live.ex:53`).
- Inbound errors: "Mailbox outcome was not applied. Choose a listed outcome." and "Time window was not applied. Choose a positive listed time window." (`inbound_live.ex:52-53`).
- Draft note: "Showing results for your previous filters until the highlighted field is fixed." (`operator_live.ex:997`, `inbound_live.ex:784`).
- Read-failure copy: "Couldn't load deliveries for these filters" / "Couldn't load inbound messages for these filters", body "The read failed. Your filters are unchanged. Retry, or change a filter." (`operator/deliveries_list.ex:86-87`, `inbound/records_list.ex:111-112`).
- Empty copy: "No deliveries match the current filters." / "No messages match the current filters." / "No messages have been received yet." (`deliveries_list.ex:115`, `records_list.ex:477`, `479`).
- Contact copy: "No From header", "No To header", "Not recorded by provider", "Unparseable address", "Show {N} more", "Display name contains a different address.", "SMTP envelope recipient (RCPT TO), used for routing." (`inbound/detail_header.ex:59`, `79`, `105`, `222`, `207`, `238`, `108`).
- Raw source copy: "Reveal raw source" / "Hide raw source", "May contain personal information.", "No raw provider source was stored for this message.", "Provider sent an empty payload.", "You don't have permission to reveal raw source." (`inbound/evidence_card.ex:65`, `79`, `85`, `212`, `139`).
- Voice scan of the phase files: no "Oops", "Whoops", "Uh oh", "Something went wrong", "logged", exclamation marks or generic CTA labels.

**Deviations:**
- **WARNING — stale title adds " UTC" and an invented fallback.** `results_status.ex:38` appends "UTC"; `results_status.ex:40` returns "Showing earlier results; refresh failed" when no load time exists. The contract defines only "Showing results from {HH:MM}; refresh failed". Recorded as orchestrator decision 3, so amend the spec or accept it.
- **WARNING — the stale panel states the load time twice.** The title says "Showing results from 14:05 UTC" and a second line reads "Results loaded {full timestamp}" (`operator/deliveries_list.ex:66-72`, `inbound/records_list.ex:76-82`).
- **WARNING — window invalid note reworded.** The contract row reads "Showing results without the {Field} filter."; the code reads "Showing results for the default time window instead." (`operator_live.ex:1292`, `inbound_live.ex:1862`). The rewording is more truthful, since the window falls back rather than disappearing. It is still a deviation from the approved text.
- **WARNING — garbled option label.** A blank `window_hours` produces "Custom period ( hours)" (see Top Fix 3).
- **INFO — echoed input in a visible label.** The custom option label interpolates raw URL input with no length bound (`operator/filters_form.ex:78`, `inbound/filters_form.ex:85`). A long value renders a long option label.
- **INFO — terminology mismatch.** The Inbound list column reads "Recipient / Subject" (`inbound/records_list.ex:186-188`) while the detail view calls the same envelope value "Delivered to".
- **INFO — accessible name disagrees with visible text.** The timestamp's non-copyable `<time>` carries `aria-label="Recorded at …"` (`components.ex:1593`), while the stale line says "Results loaded" (`deliveries_list.ex:71`).

### Pillar 2: Visuals (3/4)

**Passes:**
- Focal point: the results region carries the count and rows. The filter bar contains no `btn-primary`, and no accent sits on the filter controls (`operator_live.ex:938-1006`, `inbound_live.ex:718-793`).
- Icons: every `hero-*` referenced by phase markup is present in the committed bundle (`priv/static/app.css`). Spot-checked: `hero-information-circle`, `hero-chevron-down`, `hero-exclamation-circle`, `hero-clock`, `hero-inbox`, `hero-lock-closed`, `hero-minus-circle`, `hero-check-circle`, `hero-x-circle`, `hero-exclamation-triangle`.
- Contact `<dl>` order matches the contract: From, Reply-To (conditional), To, Cc (conditional), Delivered to, then Provider, Received, Mailbox, Account (`inbound/detail_header.ex:52-141`). Bcc is absent.
- Inline field error matches the contract: `role="alert"`, `text-error`, `hero-exclamation-circle`, "Action needed:" prefix, `aria-invalid` and `aria-describedby` (`components.ex:1069-1079`).

**Defects:**
- **WARNING — envelope recipient shown twice in the full-detail header.** The identity line shows "Delivered to {value}" without a copy control (`components.ex:576-578`, fed by `inbound/detail_header.ex:38-44`). The contact row shows the same value with a copy control (`inbound/detail_header.ex:93-111`). When the value is missing, both lines read "Not recorded by provider". See Top Fix 4.
- **WARNING — subject-less message loses its recipient.** The recipient line is gated on `not is_nil(@subject)` (`components.ex:576`). A message without a subject shows only "Subject not recorded" (`components.ex:580`) in both the full detail and the Quick view (`inbound/quick_view.ex:114-121`). The contract's "Not recorded by provider" missing copy never appears for that case.
- **INFO — static chevron.** The toggle chevron does not change with state (`operator_live.ex:957`, `inbound_live.ex:737`). Open and closed are indicated only by the panel and the label.
- **INFO — copy affordance.** The copyable address is a bare mono button with no icon or "Copy" text. The only cue is a native `title` (`components.ex:1611-1612`), which does not appear on touch devices.

### Pillar 3: Color (3/4)

**Passes:**
- No raw hex or `rgb()` in phase files (grep-verified).
- Status is never color alone: warnings carry text (`inbound/detail_header.ex:236` spoof cue; `inbound/evidence_card.ex:137` denied panel), and errors carry an icon plus text.
- Accent is confined to the uses the contract names. `border-primary` marks the selected row (`operator/deliveries_list.ex:439`, `inbound/records_list.ex:485`). `btn-primary` appears on the Replay action (`inbound/detail_header.ex:178`, quick view). Both are allowed by the contract.
- Contrast, computed from the contract's token hex values (not measured in a browser): Slate on Paper about 5.2:1; Crimson on white about 6.6:1; Amber `#A95F10` on white about 4.9:1. All pass AA for normal text.

**Defects:**
- **WARNING — brand focus ring applied inconsistently.** `mg-focus-ring` (outline in `var(--color-primary)`, `assets/css/app.css:257-261`) appears on the inputs and selects (`components.ex:1302`, `1320`), the field-help trigger (`components.ex:1120`) and the reveal button (`inbound/evidence_card.ex:77`). It is absent from Clear (`operator_live.ex:982`, `inbound_live.ex:769`), the mobile toggles (`operator_live.ex:951`, `inbound_live.ex:731`), all Retry buttons (`deliveries_list.ex:73-80`, `89-96`; `records_list.ex:83-90`, `114-121`), the empty-state Clear buttons (`deliveries_list.ex:122-129`, `records_list.ex:148-155`) and the replay button (`inbound/detail_header.ex:171-181`). Those controls fall back to the daisyUI default focus treatment, since nothing in `assets/css/app.css` overrides `.btn:focus-visible`. The contract's own class lists for Clear and Retry omit `mg-focus-ring`, so this is partly a spec gap; the Color section still names the focus ring as the accent's job.
- **Not verified:** the 60/30/10 split is not measured. The static distribution is consistent with it: surfaces are `base-100`/`base-200`, and accent is limited to focus, the selected row and Replay.

### Pillar 4: Typography (4/4)

**Verified by grep across the eleven phase files:**
- No `text-xs`, `text-sm`, `text-lg`, `text-xl` or `text-2xl`. The three `text-base` matches are all `text-base-content`, a color token.
- Roles in use are `text-label` (14px), `text-body` (16px) and `text-heading` (20px, subject only, `components.ex:570`), matching the contract.
- Weights are 700 (`font-bold`) and 400 (`font-normal`). `font-normal` appears only on the "(N applied)" parenthetical (`operator_live.ex:954`, `inbound_live.ex:734`), which the contract requires.
- Inputs and selects use `text-body` at 16px (`components.ex:1302`, `1320`), which prevents iOS focus zoom.
- Mono is reserved for IDs, `copy_value` addresses and the revealed `<pre>` (`inbound/evidence_card.ex:131`, `components.ex:1613`).

**Observations, not deducted:** `copy_value` addresses render at `text-label` (14px) mono (`components.ex:1613`), smaller than the 16px `dd` role. The contract approves this explicitly ("keeps existing component sizing"). The flat hierarchy between error titles and section headings (both `text-body` bold) follows the contract's card-heading rule.

### Pillar 5: Spacing (3/4)

**Passes:**
- New surfaces use semantic tokens throughout: `gap-sm`, `gap-md`, `mt-xs`, `mt-sm`, `space-y-sm`, `space-y-lg`, `px-md`, `min-h-11`, and `Components.card padding={:lg}`. No arbitrary `px` or `rem` values appear in phase files.
- The facts grid, contact grid and form grid match the contract breakpoints (`sm:grid-cols-2`, `lg:grid-cols-3`, `lg:grid-cols-4`, `xl:grid-cols-4`, `xl:grid-cols-[minmax(0,1fr)_auto]`).

**Defects:**
- **WARNING — raw spacing in the Deliveries filter bar.** The Clear wrapper is `flex flex-wrap gap-2` (`operator_live.ex:978`). The Inbound equivalent uses `gap-sm` (`inbound_live.ex:765`), and the contract asks for semantic utilities. This is pre-existing in the diff, but it sits on the surface this phase rewrote.
- **INFO — other raw numerics, all pre-existing and outside the phase diff.** `py-2` in `filter_display_class` (`components.ex:1336`). `px-4 py-4` on list items (`operator/deliveries_list.ex`). `space-y-4`, `p-6` and `mt-6` in the Deliveries detail column (`operator_live.ex`). `w-40`, `w-52` and `w-32` table widths in both lists.
- **INFO — stacked timestamp.** The stale block stacks a title with a time, then a separate timestamp line (see Pillar 1). The extra line adds vertical noise without adding information.

### Pillar 6: Experience Design (2/4)

**Passes (credited):**
- Retry is patch-free, so it adds no history entry (`operator_live.ex:432-441`, `inbound_live.ex:433-441`).
- Stale and error are separated by query key. A same-query failure keeps rows under a stale panel; a new-query failure shows no rows and no count (`deliveries_list.ex:55-56`, `records_list.ex:63-64`).
- The count is hidden unless the read is ready (`deliveries_list.ex:55-56`, `records_list.ex:63-64`).
- Clear is never disabled (no `disabled` attribute on either Clear button).
- No loading, dimming or spinner treatment applies to filter commits. The only `phx-*-loading` selector in the touched files is an unrelated "Refreshing…" label (`operator_live.ex:763-764`).
- Raw reveal is synchronous with a single persistent disclosure, and the denied copy sits in `role="status"` (`inbound/evidence_card.ex:74-80`, `134-140`).
- Search carries `phx-debounce="300"` only; selects carry none (`operator/filters_form.ex:33`, `inbound/filters_form.ex:38`).

**BLOCKER:**
- **Deliveries filter panel hidden at desktop width (Top Fix 1).** Reproduction (static trace, not browser-verified): portrait phone, open Filters, close Filters, rotate to landscape. The panel keeps the inline `display:none` and the toggle stays `md:hidden`, so filters are unreachable until reload. Inbound's class-based toggle does not have this defect.

**WARNING:**
- **Focus clipping on Retry and empty-state actions (static inference).** See Top Fix 2. The 4px outline extends below each button and is clipped by `overflow-hidden` on the container (`deliveries_list.ex:59`, `records_list.ex:68`).
- **Help-trigger hit area is 24px.** The field-help trigger uses `h-6 w-6` (`components.ex:1123`). It appears on all four filter fields in each collection, eight targets in total. The contract says "interactive controls keep the existing 44px minimum target (`min-h-11`)" and requires "all controls reach 44px" at 360px. The triggers meet WCAG 2.2 AA 2.5.8 (24px) but not the contract.
- **Toggle height is fixed.** The toggles use `!h-11` (`operator_live.ex:951`, `inbound_live.ex:731`), which forces `height: 2.75rem !important`. A label that wraps at 200% zoom is clipped, not grown. The contract's row "wraps within the 44px-min button ... without clipping" cannot be satisfied by this markup. Unverified in a browser.
- **Critical axe finding carried forward (Top Fix 5).** The phase's accessibility acceptance is relative to a baseline that already contains it.
- **Focus gating differs from the contract.** `FilterSearchSync.updated()` applies the committed value whenever a popstate is pending and does not check `document.activeElement` (`priv/static/hooks.js:131-139`). The contract says "with focus in Search". The effect is benign because the input reflects the URL, so this is INFO in practice. The "with focus" browser case cannot distinguish the two behaviours.

**INFO:**
- **Collapsed `aria-controls` target missing.** The reveal button points `aria-controls="inbound-evidence-raw"` at an element that renders only when revealed (`inbound/evidence_card.ex:75`). The contract specifies this, and axe permits it while `aria-expanded="false"`.
- **Dead `:error` branch.** `records_list.ex:93-98` renders "Record data unavailable" with "Refresh the page" copy and no Retry. `records_data_state/1` never returns `:error` (`inbound_live.ex:1818-1821`), so the branch is unreachable.
- **Test scaffolding in production markup.** Empty-state branches emit `data-testid-override` and hidden `style="display:none"` divs carrying test ids (`deliveries_list.ex:116-121`, `137-140`; `records_list.ex:137`, `147`, `158`, `167`). They are invisible to users and screen readers, but they are not production markup.
- **Reveal has no confirmation.** Per the contract, reveal is a reversible disclosure with the risk stated in the caption. Noted, not deducted.

---

## Out of Scope (observed, not scored)

- `gallery_live.ex` still carries masked-looking recipients on Operator Delivery specimens (lines 532, 771, 780, 795, 804, 821, 1233, 1242, 1264) and on the routing-trace specimen (line 1118). Phase 176 D-32 scopes the gallery replacement to Inbound, and plan 176-08 kept these out deliberately. They are still visible in the gallery.
- `operator_live.ex:800` uses a primary button in the no-Account onboarding pane. It sits outside the filter bar and predates the phase.

## Contract Conformance Summary

**Verified as conforming:** no Apply, submit or `disable-with` in either filter form (grep count zero); no `filters_tenant_id` in either LiveView; `phx-debounce` on Search only; Clear always rendered and enabled; the status region renders from first paint in both collections; the draft note sits outside the collapsible panel; the Inbound contact `<dl>` order and conditional rows; "To" bound only to the header list; Bcc omitted; spoof cue as text; the overflow `<details>`; unparseable originals escaped; one persistent disclosure on the raw card; five facts in one list; unknown size and count render "Unavailable"; empty-payload and not-stored copy; denied copy in `role="status"`; the `<pre>` is focusable with an `aria-label`; no new icons, colors or animations.

**Deviations (summary):** stale title "UTC" and fallback (Pillar 1); window note reworded (Pillar 1); help triggers at 24px against 44px (Pillar 6); `mg-focus-ring` missing from Clear, toggles and Retry (Pillar 3); focus gating in the hook (Pillar 6); blank-window handling on Deliveries diverges from Inbound (Pillar 1).

## Verification Limits

- Static audit only. No dev server, screenshot, axe run, Playwright run or `mix` command was executed.
- Git was used read-only for attribution (`git diff` and `git show` against `c96c8a4f`), to separate Phase 176 changes from pre-existing code.
- The phase summaries claim green ExUnit, Playwright and axe results. This review did not re-run them and does not confirm them.
- Contrast ratios were computed from the contract's token values, not measured.

---

## Files Audited

- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound_live.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/filters_form.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/results_status.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex` (read for commit semantics only)
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/address_list.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex`
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/gallery_live.ex` (masked-fixture scan)
- `/Users/jon/projects/mailglass/mailglass_admin/priv/static/hooks.js` (`FilterSearchSync`)
- `/Users/jon/projects/mailglass/mailglass_admin/priv/static/app.css` (utility presence spot-check)
- `/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css` (`mg-focus-ring`, `mg-inbound-filters-open`, button focus)
- `/Users/jon/projects/mailglass/.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-UI-SPEC.md`
- `/Users/jon/projects/mailglass/.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-CONTEXT.md`
- `/Users/jon/projects/mailglass/.planning/phases/176-direct-filters-and-useful-inbound-evidence/deferred-items.md`
- Plan and summary files `176-01` through `176-10` (required reading)
