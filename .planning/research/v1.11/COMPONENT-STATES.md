# COMPONENT-STATES — Research Dossier

**Milestone:** v1.11 mailglass_admin Design-System Uplift
**Requirement:** RESEARCH-03
**Downstream consumers:** Phase 97 (Component Layer + Gallery), Phases 98/99/100 (surface uplift), Phase 103 (Verification)
**Axis ownership (D-08):** COMPONENT-STATES owns *which states exist per archetype*. MOTION owns *how transitions between states animate* (see MOTION-LD-NN). DARK-MODE owns *how each state renders in the dark theme* (see DARK-LD-NN, forthcoming).

---

## 1. Archetype Inventory

Every archetype enumerated from the real codebase. Line references are to `mailglass_admin/lib/mailglass_admin/`.

### 1.1 Shared Components (`components.ex`)

| Archetype | Source file:line | Description |
|-----------|-----------------|-------------|
| `icon` | `components.ex:45-49` | Heroicon inline SVG via `hero-*` class; `aria-hidden="true"` |
| `logo` | `components.ex:62-89` | Sealed-flap SVG lockup, `currentColor`, `role="img"` |
| `flash` | `components.ex:102-111` | Toast-style alert; `role="status"` / `aria-live="polite"`; 4 kind variants |
| `badge` | `components.ex:129-141` | Sidebar status badge; 2 variants: `:warning`, `:stub` |
| `status_badge` | `components.ex:196-202` | Unified delivery/inbound/timeline status chip; 22 status atoms |

**Full status_badge atom set** (`components.ex:158-182`):
`:dispatched`, `:queued`, `:sent`, `:delivered`, `:deferred`, `:bounced`, `:failed`, `:rejected`, `:complained`, `:unsubscribed`, `:opened`, `:clicked`, `:autoresponded`, `:unknown`, `:accepted`, `:no_match`, `:ignore`, `:failed_ingest`, `:webhook_replay_requested`, `:webhook_replay_succeeded`, `:webhook_replay_failed`, `:reconciled` — plus a fallback clause for phantom atoms (`:suppressed`, `nil`) that yields `badge-outline` / `hero-question-mark-circle` / "Unknown" per the UI-SPEC Conflict 1 resolution (`components.ex:229-280`).

### 1.2 Operator — Shell (`operator/shell.ex`)

| Archetype | Source file:line | Description |
|-----------|-----------------|-------------|
| `shell` | `operator/shell.ex:116-193` | Full operator chrome: sidebar + header + main content slot |
| `nav_link` | `operator/shell.ex:201-219` | Sidebar `<.link>` with active border, icon, label |
| `nav_pill` | `operator/shell.ex:225-241` | Mobile-breakpoint tab pill (sibling of `nav_link`) |
| `tenant_chip` | `operator/shell.ex:245-256` | Read-only forensic tenant context chip |
| `theme_toggle` | `operator/shell.ex:260-274` | Ghost button; switches `?theme=dark` param |
| `orientation_strip` | `operator/shell.ex:314-367` | Persistent symptom-first guidance panel; per-surface copy |
| `flash_region` | `operator/shell.ex:278-301` | Inline flash area within operator surfaces |

### 1.3 Operator — Deliveries + Detail

| Archetype | Source file:line | Description |
|-----------|-----------------|-------------|
| `deliveries_list` (master) | `operator/deliveries_list.ex:13-66` | Master list; empty-state rendered inline; row button with `aria-current` / `aria-selected` |
| `detail_header` (detail) | `operator/detail_header.ex:15-95` | Selected delivery summary; replay CTA |
| `filters_form` | `operator/filters_form.ex:13-90` | 5-field filter panel (Tenant, Provider, Status, Event, Window) |
| `support_cards` | `operator/support_cards.ex:18-219` | Two-tier triage grid; Tier-1 full cards; Tier-2 compact row |
| `suppression_card` | `operator/suppression_card.ex:10-48` | Suppression state panel; `badge-outline` headline |
| `timeline` | `operator/timeline.ex:14-71` | Append-only event list; `motion-timeline`; empty-state prose |
| `replay_modal` | `operator/replay_modal.ex:15-109` | `role="dialog"` / `aria-modal="true"` replay confirmation |

### 1.4 Inbound — Records + Detail

| Archetype | Source file:line | Description |
|-----------|-----------------|-------------|
| `records_list` (master) | `inbound/records_list.ex:19-98` | Inbound master list; sibling design to `deliveries_list` |
| `inbound detail_header` | `inbound/detail_header.ex:23-96` | Inbound selected-record summary; replay button with disabled state |
| `inbound filters_form` | `inbound/filters_form.ex` | Inbound filter controls (not read in detail — sibling of operator form) |
| `routing_trace` | `inbound/routing_trace.ex:31-101` | Per-route clause diff; empty-state / passing / failing verdicts; first-failing highlight |
| `evidence_card` | `inbound/evidence_card.ex:29-113` | Raw provider source; 3 reveal states: `:redacted`, `:revealed`, `:denied` |

### 1.5 Preview

| Archetype | Source file:line | Description |
|-----------|-----------------|-------------|
| `device_frame` | `preview/device_frame.ex:26-58` | 3-button segmented control; `role="group"` / `aria-pressed` |
| `tabs` | `preview/tabs.ex:35-97` | Tab strip (HTML/Text/Raw/Headers); `role="tablist"` / `role="tab"` / `aria-selected` |
| `sidebar` | `preview/sidebar.ex:40-60` | Mailable list; `<details>/<summary>`; scenario links with active Glass left-border |

---

## 2. State Matrix

States are drawn from the canonical set: **rest, hover, focus, active, disabled, loading, empty, error**.

Legend for Implementation Method column:
- **IMPLEMENTED** — code exists and applies the correct treatment
- **PARTIAL** — code exists but is incomplete or missing a required sub-state
- **MISSING** — state is reachable in UX but no code exists for it
- **N/A** — state is not applicable to this archetype by design

### 2.1 `icon` (`components.ex:45-49`)

Display-only; always decorative (`aria-hidden="true"`). Interactive states are owned by the parent.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest | yes | `<span class={[@name, @class]} aria-hidden="true">` — IMPLEMENTED |
| hover | N/A | Decorative; parent owns hover |
| focus | N/A | Decorative; parent owns focus |
| active | N/A | Decorative; parent owns active |
| disabled | N/A | Inherits parent opacity |
| loading | N/A | Not a loader pattern |
| empty | N/A | Not applicable |
| error | N/A | Not applicable |

### 2.2 `logo` (`components.ex:62-89`)

Display-only brand mark. No interactive states.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest | yes | `currentColor` SVG inline — IMPLEMENTED |
| hover/focus/active/disabled | N/A | Decorative brand mark; no interaction |
| loading/empty/error | N/A | Not applicable |

### 2.3 `flash` (`components.ex:102-111`)

Transient notification; appears via `motion-reveal`; disappears. No persistent interactive states beyond the 4 kind variants.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest | yes | `.motion-reveal alert` with `alert-{kind}` class — IMPLEMENTED |
| hover | N/A | Read-only toast |
| focus | yes | Container has `role="status"` + `aria-live`; no visible focus ring on container itself — PARTIAL (no `focus-visible` ring on container; acceptable as container is not interactive) |
| active | N/A | Not interactive |
| disabled | N/A | Not applicable |
| loading | N/A | Not applicable |
| empty | N/A | Not rendered when no message |
| error | yes | `:error` kind handled via `alert_class(:error)` → `"alert-error"` — IMPLEMENTED |

### 2.4 `badge` (`components.ex:129-141`)

Display-only sidebar indicator. Two variants; no interaction.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest | yes | `:warning` → `badge badge-warning badge-sm gap-1`; `:stub` → `text-secondary text-label "—"` — IMPLEMENTED |
| hover/focus/active/disabled/loading/empty/error | N/A | Display-only |

### 2.5 `status_badge` (`components.ex:196-202`)

The most complex shared component. Display-only chip; rendered inside interactive parents (list rows, detail headers, timeline events). The chip itself carries no interaction — it communicates delivery/inbound status via icon + label + color class.

**22 status atoms + fallback:** All resolve to a specific `status_class/1` (lines 207-230) and `status_icon/1` (lines 232-255) and `status_label/1` (lines 257-280). Fallback clause covers phantom atoms and `nil`.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest | yes | All 22 atoms → deterministic `badge-{variant}` class — IMPLEMENTED |
| hover | N/A | Display-only; parent row owns hover |
| focus | N/A | Display-only; `aria-hidden` icon; no focus contract |
| active | N/A | Not interactive |
| disabled | yes (display variant) | Phantom/nil → fallback `badge-outline` — IMPLEMENTED |
| loading | MISSING | No `:loading` or `:pending` state representation. A delivery being dispatched shows `:dispatched`/`:queued` which are semantic states, not a loading spinner. A separate component-level loading state (e.g., spinner while status is unknown on initial load) is not implemented and is arguably not needed — status is always known at render time in the LiveView pattern. **Verdict: N/A by design.** |
| empty | N/A | Not applicable; always renders with a status atom |
| error | yes | `:failed`, `:bounced`, `:rejected`, `:complained`, `:failed_ingest`, `:webhook_replay_failed` all → `badge-error` — IMPLEMENTED |

**Missing:** No `size: :lg` variant exists (only `:sm` and `:md`). The `size: :md` is used in detail headers (`operator/detail_header.ex:23`, `inbound/detail_header.ex:40`) but the `:md` suffix yields only `badge-md` (a daisyUI native class) — no custom token-based size defined. Acceptable for now but worth noting for the gallery specimen.

### 2.6 `nav_link` / `nav_pill` (`operator/shell.ex:201-241`)

Interactive navigation controls. `nav_link` is the sidebar link (desktop); `nav_pill` is the mobile header tab.

| State | Applicable | nav_link implementation | nav_pill implementation |
|-------|-----------|------------------------|------------------------|
| rest (inactive) | yes | `border-transparent text-secondary` — IMPLEMENTED | `text-secondary` — IMPLEMENTED |
| rest (active) | yes | `border-primary bg-base-100 font-bold text-base-content` + `aria-current="page"` — IMPLEMENTED | `bg-primary/10 font-bold text-base-content` + `aria-current="page"` — IMPLEMENTED |
| hover | yes | `hover:bg-base-100/60 hover:text-base-content` — IMPLEMENTED | `hover:text-base-content` — IMPLEMENTED |
| focus | PARTIAL | Has `transition-colors` but NO explicit `focus-visible:ring-*` class — MISSING focus ring. WCAG 2.4.7 requires visible focus. The browser's default outline may appear but is not token-controlled. | Same issue — MISSING explicit focus ring |
| active | PARTIAL | No `:active` pseudo-class style; click triggers `navigate=` immediately — acceptable for link semantics | Same |
| disabled | N/A | Nav links are never disabled; unavailable routes are conditionally omitted | Same |
| loading | N/A | LiveView navigation shows the content region updating; no spinner on the nav item itself | Same |
| empty | N/A | Not applicable | N/A |
| error | N/A | Routing errors do not affect nav state | N/A |

**Gap:** Missing `focus-visible:ring-2 focus-visible:ring-primary` or equivalent on both `nav_link` and `nav_pill`. WCAG 2.1 SC 2.4.7 (visible focus). This is a conformance gap not yet in the RATCHET-GAP-REGISTER.

### 2.7 `tenant_chip` (`operator/shell.ex:245-256`)

Read-only forensic context chip. Not interactive; no click handler.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (with tenant) | yes | `border border-base-300 px-sm text-label text-secondary` + bold mono tenant value — IMPLEMENTED |
| rest (no tenant) | yes | "No tenant selected" fallback text — IMPLEMENTED |
| hover/focus/active | N/A | Read-only; `<span>` not `<button>` |
| disabled | N/A | Not applicable |
| loading | MISSING | When the LiveView has not yet resolved the tenant (async context), the chip shows "No tenant selected" — which is semantically misleading (it means unknown, not unselected). No loading state. **Minor gap.** |
| empty | yes | Falls back to "No tenant selected" — IMPLEMENTED (though semantically imprecise) |
| error | N/A | Not applicable |

### 2.8 `theme_toggle` (`operator/shell.ex:260-274`)

Ghost icon button. Interactive; triggers `"toggle_theme"` event.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (light mode) | yes | `btn btn-ghost btn-sm btn-square min-h-11`; `hero-moon` icon; `aria-label="Switch to dark theme"` — IMPLEMENTED |
| rest (dark mode) | yes | Same classes; `hero-sun` icon; `aria-label="Switch to light theme"` — IMPLEMENTED |
| hover | yes | daisyUI `btn-ghost` provides hover styles — IMPLEMENTED (via daisyUI) |
| focus | PARTIAL | daisyUI `btn` provides focus ring via `focus-visible`; depends on daisyUI version and token config — likely IMPLEMENTED via daisyUI defaults, but not verified in codebase as an explicit class |
| active | yes | daisyUI `btn` provides active press state — IMPLEMENTED (via daisyUI) |
| disabled | N/A | Toggle is always available |
| loading | N/A | Instant state change; no async |
| empty | N/A | Not applicable |
| error | N/A | Not applicable |

**Note:** `btn-sm` class is present. `min-h-11` (44px) is also present — these two are in tension. Per GAP-01's finding on `support_cards.ex`, `btn-sm` overrides `min-h-11` in practice. The `theme_toggle` uses `btn-sm btn-square min-h-11` — the same pattern. **Verify this is not the same GAP-01 violation.** A `btn-sm` in daisyUI v4 sets `min-h-8` (32px). Adding `min-h-11` as a utility AFTER `btn-sm` in the class list would override back to 44px IF the specificity is equal — but Tailwind utility specificity is equivalent, so last-wins applies during CSS generation (the class order in the DOM does not control specificity — the order in the compiled CSS does). This is a **potential GAP-01 extension** to `theme_toggle`. Flagged for the LOCKED DECISION.

### 2.9 `orientation_strip` (`operator/shell.ex:314-367`)

Read-only guidance panel. No interactive states. Rendered when no record is selected.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest | yes | `rounded-box border border-base-300 bg-base-200 p-md` with `hero-lifebuoy` icon — IMPLEMENTED |
| hover/focus/active/disabled/loading/error | N/A | Read-only informational panel |
| empty | N/A | The strip is itself the empty-state treatment; it is never "empty" |

**Axis note:** Which surface this renders on (deliveries vs. inbound vs. preview) is an IA concern (see IA-LD-05 for strip placement rules). The strip's own visual states are limited to rest.

### 2.10 `shell` (`operator/shell.ex:116-193`)

Layout container. States are largely structural + theme.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (light) | yes | `data-theme="mailglass-light"` + `flex min-h-screen bg-base-100 text-base-content` — IMPLEMENTED |
| rest (dark) | yes | `data-theme="mailglass-dark"` driven by `@dark_chrome` assign — IMPLEMENTED |
| loading | PARTIAL | No shell-level loading state (e.g., skeleton or progress bar). Individual content regions handle their own loading. Not currently a gap since the operator uses LiveView's phx-loading for individual patch cycles. |
| error | PARTIAL | `flash_region` handles `:error` flash (`border-error bg-error/10`). No shell-level 500-error state (would be a full page replacement). |
| hover/focus/active/disabled/empty | N/A | Layout container |

### 2.11 Master-Detail: `deliveries_list` + `detail_header`

#### `deliveries_list` (`operator/deliveries_list.ex:13-66`)

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (populated, no selection) | yes | `divide-y divide-base-300` list; each row `border-l-4 border-transparent bg-base-200 text-base-content` — IMPLEMENTED |
| rest (populated, selected) | yes | Selected row `border-l-4 border-primary bg-base-100` + `aria-current="true"` + `aria-selected="true"` — IMPLEMENTED |
| hover | yes | `hover:bg-base-100` on non-selected rows — IMPLEMENTED |
| focus | PARTIAL | Row is `<button>` — browser default focus ring applies; no explicit `focus-visible:ring-*` token class — PARTIAL |
| active | PARTIAL | daisyUI/browser default button active state; not explicitly styled — PARTIAL |
| disabled | N/A | Rows are always clickable when rendered |
| loading | MISSING | No skeleton rows or loading indicator while the list fetches. LiveView phx-loading CSS may show a generic loading bar on the page, but the list itself has no loading state. **Minor gap for gallery completeness.** |
| empty | yes | `flex min-h-64 flex-col items-center justify-center` with `hero-inbox-stack` icon + "No recent deliveries" heading + filter-clear instruction — IMPLEMENTED |
| error | MISSING | No error state if the query fails (e.g., DB connection error). Would typically show an error-state treatment. **Minor gap.** |

#### `detail_header` (`operator/detail_header.ex:15-95`)

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (delivery shown) | yes | Full card with metadata grid + replay CTA — IMPLEMENTED |
| rest (delivery absent) | yes | Detail pane shows `orientation_strip` (see `operator_live.ex`) — IMPLEMENTED via parent |
| hover | N/A | Card is read-only except the replay button |
| focus | PARTIAL | Replay `<button>` is interactive — needs focus-visible ring; daisyUI `btn` provides it by default |
| active | yes | daisyUI `btn btn-error` provides active state on replay button — IMPLEMENTED |
| disabled | N/A | Replay button is always enabled when delivery is shown (disabled logic is in `replay_modal`) |
| loading | PARTIAL | No loading skeleton for the detail card while the delivery is being fetched. Shown via parent's orientation_strip while nil |
| empty | yes | When `delivery` is nil, the parent `operator_live.ex` renders `orientation_strip` instead of `detail_header` — IMPLEMENTED via parent composition |
| error | MISSING | No error treatment when the delivery detail query fails |

### 2.12 `filters_form` (`operator/filters_form.ex:13-90`)

5-field form. Each field: label + input/select. Note: this is the **operator** filters form; an inbound sibling exists at `inbound/filters_form.ex`.

**GAP-04 context:** Per `RATCHET-GAP-REGISTER.md`, GAP-04 identifies "filter section labels rendered as uppercase raw CSS rather than via the text-label token." Looking at the actual code (`filters_form.ex:16-30`): the labels use `text-label font-bold uppercase tracking-[0.08em] text-secondary`. The `text-label` token IS present. However, the `tracking-[0.08em]` is an arbitrary value — not a token. GAP-04 references `inbound_live.ex` specifically. The operator `filters_form.ex` already uses `text-label`. The inbound surface may differ. This distinction is preserved below.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (field empty) | yes | `input input-bordered min-h-11 w-full` / `select select-bordered min-h-11 w-full` — IMPLEMENTED |
| rest (field filled) | yes | Value bound via form; no distinct filled-state styling — acceptable |
| hover | yes | daisyUI `input-bordered` / `select-bordered` provide hover styles — IMPLEMENTED (via daisyUI) |
| focus | yes | daisyUI `input-bordered` provides `:focus` ring — IMPLEMENTED (via daisyUI) |
| active | yes | daisyUI defaults — IMPLEMENTED |
| disabled | N/A | Filter fields are always enabled |
| loading | N/A | Filters apply on change; no async wait state at field level |
| empty | N/A | Empty value is valid ("Any status") |
| error | MISSING | No validation error state on filter inputs. Filter inputs are low-risk (no user data submitted), but a pattern for error state (e.g., invalid tenant_id format) is absent |

**Focus ring quality note:** daisyUI `input-bordered` provides a default focus ring, but its color may not use the `primary` token. Token conformance needs verification against `brandbook/tokens.css`. This is DARK-MODE dossier territory for dark-theme rendering (see DARK-LD-NN).

**Label token audit:**
- `filters_form.ex:16`: `text-label font-bold uppercase tracking-[0.08em] text-secondary` — uses `text-label` (token) + `tracking-[0.08em]` (arbitrary). The `tracking-[0.08em]` is not from the `@theme` block. GAP-04's fix direction ("replace with text-label class") suggests the inbound surface was using raw CSS instead of `text-label`. The operator form already has `text-label` but still uses the arbitrary tracking value. IA-LD-04 (already locked) specifies `text-label uppercase font-bold text-secondary, no tracking-[0.08em]`. The operator `filters_form.ex` needs to drop the arbitrary tracking to close GAP-04 fully.

### 2.13 `support_cards` (`operator/support_cards.ex:18-219`)

Two-tier triage grid. The critical archetype for **GAP-01** (btn-sm touch target).

**GAP-01 evidence:**
- Line 56: `class="btn btn-sm btn-primary mt-sm"` — "View failures" button
- Line 102: `class="btn btn-sm btn-primary mt-sm"` — "View backlog" button
- Line 152: `class="btn btn-sm btn-primary mt-sm"` — "Open replay audit" button
- Line 204: `class="btn btn-ghost btn-sm px-3"` — "Unmatched pressure" button

All four CTA buttons use `btn-sm` without `min-h-11`. Per `design-system.md:108`, touch targets must be `≥ min-h-11 (44px)`. `btn-sm` in daisyUI sets `min-h-8` (32px). No `min-h-11` override is present on these buttons.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (Tier-1 shown) | yes | Full card with count, exemplar, CTA button — IMPLEMENTED |
| rest (Tier-1 hidden, Tier-2 shown) | yes | Compact horizontal row — IMPLEMENTED |
| hover (CTA button) | yes | daisyUI `btn-primary` / `btn-ghost` provides hover — IMPLEMENTED |
| focus (CTA button) | PARTIAL | daisyUI `btn` provides focus ring; but `btn-sm` without adequate size may compromise usability — PARTIAL |
| active (CTA button) | yes | daisyUI `btn` active state — IMPLEMENTED |
| disabled | N/A | All Tier-1 cards are conditionally shown only when non-zero |
| loading | MISSING | No loading state for the support summary while it fetches |
| empty | yes | All Tier-1 zero-state: Tier-2 compact row shows "No failures" / "No orphan backlog" — IMPLEMENTED |
| error | MISSING | No error state if the support summary query fails |

**GAP-01 resolution:** Remove `btn-sm` from all four CTA buttons, or add explicit `min-h-11` override. The correct fix is to use `btn btn-primary` (without `btn-sm`) and ensure padding is `px-md` or token equivalent, giving ≥44px height from the base `btn` height (`min-h-11` is the daisyUI v4 default for `btn`).

### 2.14 `suppression_card` (`operator/suppression_card.ex:10-48`)

Read-only display card. Two content states (suppression present / absent).

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (suppression present) | yes | `badge-outline` headline badge + metadata grid — IMPLEMENTED |
| rest (suppression absent) | yes | "No active suppression entry matches this delivery." prose — IMPLEMENTED |
| hover/focus/active | N/A | Read-only card |
| disabled | N/A | Not applicable |
| loading | MISSING | No loading state while suppression data fetches |
| empty | yes | Absent suppression renders prose fallback — IMPLEMENTED |
| error | MISSING | No error state if suppression query fails |

### 2.15 `timeline` (`operator/timeline.ex:14-71`)

Chronological event list. Uses `motion-timeline` for staggered entrance.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (events present) | yes | `motion-timeline` list + event cards with dot, connector, container — IMPLEMENTED |
| rest (event highlighted) | yes | `border-primary ring-1 ring-primary/40` on highlighted event container — IMPLEMENTED |
| hover | N/A | Read-only; individual events are not clickable |
| focus | N/A | Not interactive |
| active | N/A | Not interactive |
| disabled | N/A | Not applicable |
| loading | MISSING | No skeleton or loading state |
| empty | yes | "No delivery events have been recorded for this item yet." prose — IMPLEMENTED |
| error | MISSING | No error state for failed event query |

**Axis note:** The `motion-timeline` entrance animation is owned by MOTION-LD-08 (staggered 40ms per item, capped at 8). Cross-reference MOTION-LD-08.

### 2.16 `replay_modal` (`operator/replay_modal.ex:15-109`)

Dialog with `role="dialog"` / `aria-modal="true"`. States driven by `@replay_targets` shape.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (closed) | yes | `<%= if @open? and @delivery do %>` — not rendered — IMPLEMENTED |
| rest (open, exact) | yes | Single target card + confirm button — IMPLEMENTED |
| rest (open, ambiguous) | yes | Multi-target radio selection + confirm button (enabled when target selected) — IMPLEMENTED |
| rest (open, unavailable) | yes | Warning box with availability label — IMPLEMENTED |
| rest (open, loading) | yes | "Replay target resolution is still loading" prose — IMPLEMENTED |
| hover (Close button) | yes | `btn-ghost` hover via daisyUI — IMPLEMENTED |
| hover (Cancel button) | yes | `btn-ghost` hover — IMPLEMENTED |
| hover (Confirm button) | yes | `btn-error` hover — IMPLEMENTED |
| focus (Close/Cancel/Confirm) | PARTIAL | daisyUI `btn` provides focus ring; `role="dialog"` does not trap focus automatically in LiveView without a JS hook — **Focus trap MISSING**. ARIA APG 2.1 Modal Dialog pattern requires focus to be trapped inside the modal. This is a significant a11y gap. |
| active | yes | daisyUI `btn` active state — IMPLEMENTED |
| disabled (Confirm, when no target selected) | yes | Confirm button is conditionally NOT rendered (`confirm_enabled?/2`) — IMPLEMENTED (via removal) |
| loading | PARTIAL | "still loading" prose state exists but is not a spinner/skeleton — PARTIAL |
| empty | N/A | Modal always has at minimum the replay_targets loading state |
| error | N/A | Errors are surfaced via the `:unavailable` branch |

**A11y gap:** No focus trap and no `aria-labelledby` linking the `h2` ("Replay webhook for...") to the dialog container. These are both WCAG 4.1.2 and ARIA APG requirements.

### 2.17 `routing_trace` (`inbound/routing_trace.ex:31-101`)

The IADM-04 archetype. Per-route clause diff. States: empty (no routes), populated with pass/fail verdicts, with first-failing highlight.

Note: The plan mentions "locked/info reveal" as states for `routing_trace`, but inspecting the code at `routing_trace.ex:31-101`, there is NO info-reveal or locked state implemented in this component. The `evidence_card` owns the reveal pattern (`:redacted`/`:revealed`/`:denied`). The `routing_trace` only has empty vs. populated + first-failing highlight. The "locked/info reveal" description in D-09 appears to describe the `evidence_card`, not the `routing_trace`. This distinction is preserved in the LOCKED DECISION block.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (empty — no routes) | yes | "No inbound routes are declared, so there is nothing to trace." — IMPLEMENTED |
| rest (populated — all passing) | yes | Route cards with `hero-check-circle text-success` per clause — IMPLEMENTED |
| rest (populated — first failing) | yes | First-failing clause gets `border-l-4 border-error px-3`; `badge-outline badge-error` on route card — IMPLEMENTED |
| rest (populated — all failing) | yes | Each clause with `hero-x-circle text-error`; no route-level "fully passing" badge — IMPLEMENTED |
| hover | N/A | Read-only |
| focus | N/A | Not interactive |
| active | N/A | Not interactive |
| disabled | N/A | Not applicable |
| loading | MISSING | No loading/skeleton state while the trace computes |
| empty | yes | As above — IMPLEMENTED |
| error | N/A | Errors in the trace (no routes) show the empty-state prose |

### 2.18 `evidence_card` (`inbound/evidence_card.ex:29-113`)

Mono chips on `surface-sunken` (rendered as `bg-base-100` inside a `bg-base-200` card). Three reveal states.

**Reveal state model** (`evidence_card.ex:82-109`):
- `:redacted` (default) — mono placeholder prose, `border-base-300 bg-base-100 text-secondary`
- `:revealed` — `<pre>` scroll region with raw payload, `border-base-300 bg-base-100 text-base-content`
- `:denied` — warning box `border-warning bg-warning/10 text-base-content`

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (evidence nil) | yes | "No raw provider source has been stored" prose — IMPLEMENTED |
| rest (evidence present, redacted) | yes | Metadata grid + mono redacted placeholder — IMPLEMENTED |
| rest (evidence present, revealed) | yes | Metadata grid + `<pre>` scroll region — IMPLEMENTED |
| rest (evidence present, denied) | yes | Warning box prose — IMPLEMENTED |
| hover (Reveal button) | yes | `btn-ghost` hover via daisyUI — IMPLEMENTED |
| focus (Reveal button) | PARTIAL | daisyUI `btn` focus ring — PARTIAL (not token-explicit) |
| active (Reveal button) | yes | daisyUI `btn` active — IMPLEMENTED |
| disabled | N/A | Reveal button is conditionally not rendered when `@reveal_state == :revealed` |
| loading | MISSING | No loading state while the reveal capability is checked or the raw payload loads |
| empty | yes | No evidence → prose fallback — IMPLEMENTED |
| error | N/A | The `:denied` state serves the error-equivalent UX |

### 2.19 `device_frame` (`preview/device_frame.ex:26-58`)

3-button segmented control.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (inactive button) | yes | `btn btn-sm join-item btn-ghost` — IMPLEMENTED |
| rest (active button) | yes | `btn btn-sm join-item btn-primary` + `aria-pressed="true"` — IMPLEMENTED |
| hover | yes | daisyUI `btn-ghost` / `btn-primary` hover — IMPLEMENTED |
| focus | PARTIAL | daisyUI `btn` focus ring; `btn-sm` touch-target concern (same pattern as `support_cards` GAP-01) |
| active | yes | daisyUI `btn` active — IMPLEMENTED |
| disabled | N/A | All width options are always available |
| loading | N/A | Width change is instant |
| empty | N/A | Always renders 3 buttons |
| error | N/A | Not applicable |

**GAP-01 extension concern:** `device_frame` uses `btn btn-sm` without `min-h-11`. Same `btn-sm` touch-target issue as `support_cards`. Preview is a dev-only surface so this is lower severity than the operator surface, but still violates the 44px minimum.

### 2.20 `tabs` (`preview/tabs.ex:35-97`)

Tab strip + content pane. Uses `motion-tab-swap` for crossfade.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (inactive tab) | yes | `text-secondary hover:bg-base-200` — IMPLEMENTED |
| rest (active tab) | yes | `font-bold border-b-2 border-primary text-base-content` + `aria-selected="true"` — IMPLEMENTED |
| hover | yes | `hover:bg-base-200` on inactive tabs — IMPLEMENTED |
| focus | PARTIAL | Tab buttons — no explicit `focus-visible:ring-*`; browser default only — PARTIAL |
| active | yes | daisyUI/browser button active — IMPLEMENTED |
| disabled | N/A | All tabs always available |
| loading | N/A | Content switch is synchronous |
| empty | PARTIAL | Empty HTML body shows blank iframe; empty text/raw shows empty `<pre>`. No "no content" state per tab — MISSING for the HTML tab in particular (could show placeholder when `@html_body == ""`) |
| error | N/A | Not applicable at tab level |

**Axis note:** `motion-tab-swap` (crossfade 150ms) is the animation owned by MOTION-LD-06. Cross-reference MOTION-LD-06.

### 2.21 `sidebar` (`preview/sidebar.ex:40-152`)

Mailable list with `<details>/<summary>` disclosure.

| State | Applicable | Implementation |
|-------|-----------|----------------|
| rest (mailable, collapsed) | yes | `<details>` closed — IMPLEMENTED |
| rest (mailable, expanded) | yes | `<details open>` when `@current_mailable == @mod` — IMPLEMENTED |
| rest (scenario inactive) | yes | `border-l-[3px] border-transparent text-secondary hover:bg-base-200` — IMPLEMENTED |
| rest (scenario active) | yes | `border-l-[3px] border-primary bg-base-200 text-base-content font-normal` — IMPLEMENTED |
| rest (mailable error) | yes | Warning badge rendered; link to `/__error__` path — IMPLEMENTED |
| rest (mailable no_previews) | yes | Stub badge + "sr-only" prose — IMPLEMENTED |
| hover (summary) | yes | `hover:bg-base-200 rounded transition-colors` — IMPLEMENTED |
| hover (scenario link) | yes | `hover:bg-base-200` — IMPLEMENTED |
| focus (summary) | PARTIAL | `<summary>` is a native interactive element; browser focus ring applies; no explicit token focus ring — PARTIAL |
| focus (scenario link) | PARTIAL | `<.link>` renders `<a>` — browser focus ring; no explicit token ring — PARTIAL |
| active | yes | Browser default click/press state — IMPLEMENTED |
| disabled | N/A | Items are not disabled |
| loading | MISSING | No loading state while the mailable list discovers. Preview loads synchronously but a loading shimmer for the initial mount would be good gallery hygiene. |
| empty | MISSING | No "no mailables found" state inside the sidebar component itself. The outer `PreviewLive` shows `orientation_strip` when `@mailables == []`, but the sidebar component does not have its own empty-list treatment — relies on parent for empty state. |
| error | yes | `:error` variant mailable → warning badge + link — IMPLEMENTED |

---

## 3. External Best Practice Reference

### 3.1 WCAG 2.1 Conformance

**SC 2.4.7 — Focus Visible (AA):**
> "Any keyboard operable user interface has a mode of operation where the keyboard focus indicator is visible."

**Current codebase status:**
- `nav_link`, `nav_pill` — No explicit `focus-visible:ring-*` class. Rely on browser UA stylesheet. **Deviation.**
- `theme_toggle` — daisyUI `btn` provides `focus-visible` ring via its base styles. **Conforms** (via daisyUI).
- `device_frame` buttons, `tabs` buttons — daisyUI `btn` / `tab` variants provide focus ring. **Conforms** (via daisyUI).
- `deliveries_list` row buttons — `<button>` with no explicit focus ring class. Browser UA default. **Partial deviation.**
- `replay_modal` dialog — No focus trap. Focus can escape the dialog. **Failure** (ARIA APG 2.1).
- `sidebar` `<summary>` and `<.link>` — Browser UA focus ring. **Partial deviation.**

**SC 1.4.11 — Non-Text Contrast (AA):**
> "The visual presentation of the following have a contrast ratio of at least 3:1 against adjacent colors: User Interface Components, Graphical Objects."

**Current codebase status:**
- Status badge icons (`aria-hidden="true"`) are decorative — SC 1.4.11 does not apply.
- `nav_link` left-border active state uses `border-primary` (Glass `#277B96` on Mist `#EAF6FB` sidebar) — needs contrast check. Glass vs. Mist: ~4.82:1 in light mode (per v1.9 research). **Conforms** at >3:1.
- Focus rings — where present, daisyUI uses `base-content` or `primary` tinted rings. Token conformance needed in dark mode (see DARK-LD-NN).

**SC 1.4.3 — Contrast Minimum (AA, text):**
- `text-secondary` (Slate `#5C6B7A`) on `base-100` (Paper `#F8FBFD`) — 4.75:1, AA pass.
- `text-secondary` on `base-200` (Mist) — lower; needs dark-mode verification (Phase 86 figures: `surface-selected` dark muted 6.66 AA pass). See STATE.md `[86-01]`.

### 3.2 ARIA Authoring Practices

**Combobox (filter selects):**
The `<select>` in `filters_form.ex` is a native HTML select — ARIA combobox pattern is not applicable. Native selects have their own a11y semantics. No deviation.

**Dialog (replay_modal):**
ARIA APG Dialog pattern requires:
1. `role="dialog"` + `aria-modal="true"` — IMPLEMENTED (`replay_modal.ex:23`)
2. `aria-labelledby` pointing to the dialog title — **MISSING** (h2 at line 27 has no `id`; dialog div has no `aria-labelledby`)
3. Focus trapped inside dialog on open — **MISSING** (no LiveView.JS or hook for focus trap)
4. Escape key closes dialog — **MISSING** (no `phx-key="Escape"` binding)

**Listbox / nav:**
`nav_link` uses `aria-current="page"` — correct ARIA pattern for navigation (not `aria-selected`, which is for listbox/tab items). `deliveries_list` rows use both `aria-current` and `aria-selected` — while slightly redundant, not harmful.

**Tab panel:**
`tabs.ex` uses `role="tablist"` / `role="tab"` / `aria-selected` per APG tab pattern. **Missing:** `aria-controls` linking tabs to panel divs, and panel divs need `role="tabpanel"` + `aria-labelledby`. Currently the content area (`div id="preview-tab-..."`) has no explicit role. **Minor deviation from APG tab pattern.**

---

## 4. Gap Analysis

### Priority 1 — Missing Focus States (WCAG 2.4.7 risk)

| Archetype | Gap | Impact |
|-----------|-----|--------|
| `nav_link` / `nav_pill` | No `focus-visible:ring-*` token class | WCAG AA violation risk; keyboard users cannot see focus position in the sidebar nav |
| `deliveries_list` row buttons | No `focus-visible:ring-*` | Keyboard users cannot see which delivery row is focused |
| `tabs` buttons | Depends on daisyUI defaults; not token-explicit | Medium risk |
| `sidebar` `<summary>` and scenario links | Browser UA only | Medium risk |

**Resolution:** Add `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` (or the token equivalent from design-system) to all interactive elements. MOTION dossier owns whether the focus ring itself animates (see MOTION-LD-NN); DARK-MODE dossier owns the dark-theme ring color (see DARK-LD-NN).

### Priority 2 — replay_modal A11y Failures

| Gap | ARIA Requirement | WCAG SC |
|-----|-----------------|---------|
| No focus trap inside dialog | APG Dialog 2.1 | 2.1.1 Keyboard |
| No `aria-labelledby` on dialog | APG Dialog 2.1 | 4.1.2 Name, Role, Value |
| No Escape key handler | APG Dialog 2.1 | 2.1.1 Keyboard |

These are correctness gaps for an accessible operator surface. Severity: sev-4 (major design-system violation affecting core UX). Not yet in the GAP register (registered in this dossier for Phase 97+ closure).

### Priority 3 — GAP-01: btn-sm Touch Targets

Confirmed in `support_cards.ex:56, 102, 152, 204` (operator) and `device_frame.ex:34, 41, 48` (preview). `btn-sm` sets `min-h-8` (32px); no `min-h-11` override. Resolution: remove `btn-sm` or add `min-h-11` per archetype role.

### Priority 4 — GAP-04: Filter Label Off-Token Tracking

`filters_form.ex:16` uses `tracking-[0.08em]` (arbitrary). Per IA-LD-04, the correct class is `text-label uppercase font-bold text-secondary` without arbitrary tracking. The `@theme` block does not define a `tracking` token — the `text-label` token at 12px with default tracking should be sufficient. Resolution: drop `tracking-[0.08em]` from both operator and inbound filter label spans.

### Priority 5 — Missing Loading/Error States

Multiple archetypes lack loading or error states:
- `deliveries_list` — no loading skeleton
- `detail_header` — no loading skeleton
- `support_cards` — no loading state
- `suppression_card` — no loading state
- `timeline` — no loading skeleton
- `routing_trace` — no loading state
- `evidence_card` — no loading state

These are all rendered in LiveView's synchronous mount path — loading states would only matter if these were pushed asynchronously (e.g., `assign_async`). If Phase 97 moves to async assigns, loading states become required. Flagged as architecture-dependency: if async assigns are not adopted, loading states are N/A; if they are, they become sev-3 gaps.

### Axis-Ownership Boundary Reminders

Per D-08:
- **How these states transition** (opacity animation when a list row is selected, modal overlay entrance) → MOTION dossier (see MOTION-LD-NN).
- **How each state renders in dark theme** (focus ring color in dark, badge contrast, surface-sunken bg in dark) → DARK-MODE dossier (see DARK-LD-NN, forthcoming).

---

## 5. Adversarial Synthesis

### Challenge 5.1: Does the `status_badge` state decision satisfy constraints?

**Draft decision:** `status_badge` states = {rest, disabled (via phantom/nil fallback)}; no hover/focus/active as it is display-only; all 22 status atoms plus fallback resolve to deterministic `status_class/1`.

**Critic challenges:**
- *Does the fallback clash with the hard constraint "semantic tokens only"?* The fallback uses `badge-outline` — a daisyUI semantic class, not a hardcoded color. **Passes.**
- *Does the `size: :md` variant cause font-weight issues?* `badge-md` is a daisyUI size modifier; it does not set font-weight. No `font-medium`/`font-semibold`. **Passes.**
- *Is the 22-atom set complete and correct?* Codebase at `components.ex:158-182` enumerates exactly 22 atoms plus the fallback. The inbound normalization function (`normalize_inbound_outcome/1`) maps `:accept`→`:accepted` etc. so the badge always receives a canonical past-tense atom. **Complete.**
- *Does the display-only characterization hold?* The `status_badge` `<span>` has no `phx-click`, no `navigate`, no interactive attributes. **Confirmed display-only.**

**Verdict:** Decision holds. Lock.

### Challenge 5.2: Does the `nav_link` focus decision satisfy WCAG and constraints?

**Draft decision:** Add `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` to `nav_link` and `nav_pill`.

**Critic challenges:**
- *Does `ring-primary` use a semantic token?* `primary` maps to Glass `#277B96` — a daisyUI semantic token. **Passes.**
- *Does `ring-offset-1` introduce an off-token spacing value?* `ring-offset-1` is `ring-offset-width: 1px` — Tailwind default, not our `@theme` spacing scale. This is a border/ring utility, not a spacing utility. The constraint is "spacing token utilities on the 4px grid" for padding/gap/margin, not ring offsets. **Acceptable.**
- *Does focus ring violate the flat-elevation constraint?* Ring is a box-shadow, not a z-stacked element. Flat-elevation refers to no `shadow-2xl`/`-xl`/drop shadows for cards. Focus rings are functional UI affordances, not decorative elevation. **Acceptable.**
- *Does focus ring color need to change in dark mode?* Yes — DARK-MODE dossier owns the dark-theme ring color. Cross-reference DARK-LD-NN.

**Verdict:** Decision holds. `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` is the correct token-anchored focus ring for interactive controls. Lock.

### Challenge 5.3: Does the `support_cards` touch-target resolution address GAP-01?

**Draft decision:** Remove `btn-sm` from all four CTA buttons in `support_cards.ex` (lines 56, 102, 152, 204). Use `btn btn-primary` (base) with token padding `px-md`.

**Critic challenges:**
- *Will removing `btn-sm` make the Tier-2 compact row buttons too large?* Line 204 is in the Tier-2 compact row (`btn btn-ghost btn-sm px-3`). The Tier-2 row is a horizontal flex row — removing `btn-sm` would give the ghost button a `min-h-11` (44px) height, which is correct for touch targets but may make the compact Tier-2 row less "compact." **Trade-off: a11y correctness wins over visual compactness.** Compact rows can still be visually lightweight via `btn-ghost` styling; `min-h-11` is a touch target, not a visual size constraint.
- *Does this close GAP-01 or only partially close it?* GAP-01 cites `support_cards.ex:56` specifically. The fix covers all four affected lines. `device_frame` also uses `btn-sm` — but it's a preview-surface dev tool at lower severity. GAP-01 is for the `support_cards` finding. `device_frame` is an additional discovery (not GAP-01 itself).
- *Hard design constraint check:* `btn btn-primary px-md` — `btn` is daisyUI semantic, `btn-primary` is semantic, `px-md` is our token. **Passes all constraints.**

**Verdict:** Decision holds. Remove `btn-sm` from `support_cards.ex` lines 56, 102, 152, 204. Lock. Closes GAP-01.

### Challenge 5.4: Does the `filters_form` state decision address GAP-04?

**Draft decision:** Drop `tracking-[0.08em]` from operator and inbound filter label spans. Retain `text-label font-bold uppercase text-secondary`.

**Critic challenges:**
- *Is the IA-LD-04 already locked decision contradicted?* IA-LD-04 specifies `text-label uppercase font-bold text-secondary, no tracking-[0.08em]`. The operator `filters_form.ex` currently has `tracking-[0.08em]`. Dropping it aligns with the locked IA decision. **No contradiction.**
- *Is `text-label uppercase font-bold` sufficient for visual hierarchy?* At 12px with `font-bold` (700 weight) and `uppercase`, the label communicates its tier clearly. The arbitrary tracking was providing extra letterspacing for the uppercase — removing it relies on browser default tracking for uppercase `text-label`. Acceptable; the brand does not specify custom tracking as a token.
- *Does the GAP-04 source (inbound filter labels using "uppercase raw CSS") differ from what this document inspects?* GAP-04 cites `inbound_live.ex` not `filters_form.ex`. The inbound surface may have its own filter label implementation (in `inbound/filters_form.ex`, not read here). The fix must be applied to BOTH the operator `filters_form.ex` and the inbound `inbound/filters_form.ex`. Phase 97/99 executors must check both files.

**Verdict:** Decision holds. Drop `tracking-[0.08em]` from all filter label spans in both `operator/filters_form.ex` and `inbound/filters_form.ex`. Closes GAP-04. Lock.

### Challenge 5.5: Does the `routing_trace` state model address Phase 99's scope?

**Draft decision:** `routing_trace` states = {rest-empty, rest-populated-passing, rest-populated-failing (with first-failing highlight)}. No "locked/info reveal" state — that belongs to `evidence_card`.

**Critic challenges:**
- *D-09 says "locked/info reveal" for `routing_trace` — is the state model incomplete?* Inspecting `routing_trace.ex:31-101`: there is no reveal/lock state. The component is fully read-only. The "locked/info reveal" description in D-09 appears to conflate `routing_trace` and `evidence_card`. `evidence_card` has the `:redacted`/`:revealed`/`:denied` reveal model. `routing_trace` is a flat clause-diff display with no interactive reveal. **Conclusion: D-09's "locked/info reveal" refers to `evidence_card`, not `routing_trace`. The state model for `routing_trace` is correct.**
- *Does the Phase 99 scope need a "loading" state?* Phase 99 is the Inbound Surface uplift. If inbound routes are computed synchronously, no loading state is needed. If Phase 99 adopts async assigns, a skeleton would be required. **Defer to Phase 99 — document as architecture-dependency.**
- *Constraint check:* No interactive states means no focus/hover/active tokens needed. Semantic-token-only color on the clause verdict icons (success/error) and the first-failing highlight (`border-error`). **Passes.**

**Verdict:** Decision holds. `routing_trace` states = {rest-empty, rest-populated-passing, rest-populated-first-failing}. No reveal state. Lock.

### Challenge 5.6: Does the `evidence_card` reveal model satisfy the hard constraints?

**Draft decision:** `evidence_card` states = {rest-nil, rest-redacted, rest-revealed, rest-denied}. Reveal button: {rest, hover, focus, active}. No disabled state — button is conditionally not rendered.

**Critic challenges:**
- *`rest-revealed` renders a `<pre>` with `max-h-80 overflow-auto` — does the arbitrary `max-h-80` violate the spacing-token rule?* `max-h-80` = `20rem` = `320px`. The `@theme` block defines spacing tokens at `4/8/16/24/32/48/64px`. 320px is not on this scale. **Minor violation.** However, this is a content-overflow utility, not a layout spacing utility. Similar to `ring-offset`, content-constraining max-height is arguably outside the "padding/gap/margin" token scope. **Accept as is; document as a known arbitrary value outside the spacing grid.**
- *Is `:denied` the correct pattern rather than an `:error` state?* `:denied` is an authorization decision, not a technical error. The warning treatment (`border-warning bg-warning/10`) correctly signals a permission boundary, not a failure. **Correct semantic treatment.**
- *Does the `Reveal raw source` button meet `min-h-11`?* `evidence_card.ex:40`: `class="btn btn-ghost btn-sm min-h-11 px-4"` — `btn-sm` + `min-h-11` is the same tension as `support_cards`. Here `min-h-11` IS explicitly present alongside `btn-sm`. In CSS, when both `min-h-8` (from btn-sm) and `min-h-11` appear in the class list, the higher specificity wins. In Tailwind v4, utility specificity is equal — last-in-CSS-output wins, which depends on the generated CSS order. If `min-h-11` is generated after `btn-sm`'s `min-h-8` override, it wins. If not, the button shrinks to 32px. **This is ambiguous and needs Phase 97 verification.** Flag for the LOCKED DECISION.

**Verdict:** Decision holds with the `btn-sm + min-h-11` tension flagged. `evidence_card` reveal states are locked. Recommend Phase 97 to verify the `min-h-11` override works in the compiled bundle.

---

## LOCKED DECISION

| LD-ID | Decision | Applies-to (surface/archetype) | Constraint-binding | Closes-GAP |
|-------|----------|-------------------------------|-------------------|-----------|
| STATE-LD-01 | `icon`: states = {rest only}. Display-only; `aria-hidden="true"` always set. No hover/focus/active/disabled states — interactive parent owns all interaction states. Gallery specimen shows icon in rest within a button parent. | Shared / `icon` (`components.ex:45-49`) | semantic tokens only (color via parent class); no interactive tokens needed | — |
| STATE-LD-02 | `logo`: states = {rest only}. `currentColor` SVG, `role="img"`, `aria-label="mailglass"`. No interactive states. Gallery specimen: inline in shell header, correct viewport scaling via `class` attribute. | Shared / `logo` (`components.ex:62-89`) | `currentColor` inherits from `text-base-content`; no accent tokens | — |
| STATE-LD-03 | `flash`: states = {rest, error-kind, info-kind, success-kind, warning-kind}. `motion-reveal` applies on mount (see MOTION-LD-05). No persistent interactive states — flash is transient and read-only. `role="status"` + `aria-live="polite"` required on container. | Shared / `flash` (`components.ex:102-111`) | semantic tokens only (`alert-{kind}` daisyUI classes); `motion-reveal` bounded ≤220ms ease-out; no springs/overshoot | — |
| STATE-LD-04 | `badge` (sidebar variant): states = {rest-warning, rest-stub}. `:warning` → `badge badge-warning badge-sm gap-1` + exclamation icon. `:stub` → `text-secondary text-label "—"`. Both are display-only; no interactive states. | Shared / `badge` (`components.ex:129-141`) | `badge-warning` = semantic daisyUI token; `text-secondary` = semantic; `text-label` = `@theme` token | — |
| STATE-LD-05 | `status_badge`: states = {rest, disabled-via-fallback}. Display-only chip; no hover/focus/active. All 22 status atoms must resolve to a non-default class via `status_class/1`: `:dispatched`/`:queued`/`:sent` → `badge-primary`; `:delivered`/`:opened`/`:clicked`/`:accepted`/`:webhook_replay_succeeded` → `badge-success`; `:deferred`/`:unsubscribed`/`:no_match`/`:reconciled` → `badge-warning`; `:bounced`/`:failed`/`:rejected`/`:complained`/`:failed_ingest`/`:webhook_replay_failed` → `badge-error`; `:autoresponded`/`:unknown`/`:ignore`/`:webhook_replay_requested` → `badge-outline`. Phantom atoms (`:suppressed`, `nil`) → fallback `badge-outline`. `size: :sm` default for list rows; `size: :md` for detail headers. | Shared / `status_badge` (`components.ex:196-280`) | semantic tokens only (`badge-{variant}` daisyUI classes); no hex; no raw palette; font-weight 400/700 only (badge text inherits); 10%-accent rule — `badge-primary` is accent, used for in-flight statuses only | — |
| STATE-LD-06 | `nav_link` and `nav_pill`: states = {rest-inactive, rest-active, hover, focus, active-press}. **Inactive rest:** `border-transparent text-secondary`. **Active rest:** `border-primary bg-base-100 font-bold text-base-content` + `aria-current="page"`. **Hover:** `hover:bg-base-100/60 hover:text-base-content` (nav_link) / `hover:text-base-content` (nav_pill). **Focus:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` — WCAG 2.4.7 compliance; currently missing and must be added by Phase 97. **Active-press:** browser default (no explicit class needed for `<a>` link semantics). Transition: `transition-colors duration-(--duration-fast)` already present. Dark-mode ring color: see DARK-LD-NN. | Operator / `nav_link` (`operator/shell.ex:201-219`), `nav_pill` (`operator/shell.ex:225-241`) | semantic tokens only; `ring-primary` is semantic; `min-h-11` already set (44px touch target met); font-weight 400/700 only (`font-bold` for active); flat elevation (no shadow) | — |
| STATE-LD-07 | `tenant_chip`: states = {rest-with-tenant, rest-no-tenant}. Read-only `<span>`. **With tenant:** `border border-base-300 px-sm text-label text-secondary` + bold mono tenant value `font-bold text-base-content`. **No tenant:** "No tenant selected" in `text-secondary`. No hover/focus/active/disabled. A "loading" state is NOT added (no async; the chip reflects LiveView assigns synchronously). Gallery specimen: show both states. | Operator / `tenant_chip` (`operator/shell.ex:245-256`) | `border-base-300` semantic; `text-label` `@theme` token; `px-sm` `@theme` token; `min-h-11` already set (44px, read-only so not a touch-target gap) | — |
| STATE-LD-08 | `theme_toggle`: states = {rest-light-mode, rest-dark-mode, hover, focus, active-press}. **Light rest:** `hero-moon` icon, `aria-label="Switch to dark theme"`. **Dark rest:** `hero-sun` icon, `aria-label="Switch to light theme"`. `btn btn-ghost btn-square`. **Touch target:** `btn-sm` + `min-h-11` — `btn-sm` may override `min-h-11` in the compiled CSS. **Decision:** Replace `btn-sm` with `btn-xs` for icon sizing ONLY if daisyUI provides a size-specific icon-button class; otherwise drop `btn-sm` and let base `btn` height apply (min-h-11 = 44px). Phase 97 executor must verify the compiled min-height. Hover/active: daisyUI `btn-ghost` provides both. Focus: daisyUI `btn` provides `focus-visible` ring by default. | Operator / `theme_toggle` (`operator/shell.ex:260-274`) | `min-h-11` = 44px touch target (hard constraint); `btn-ghost` = semantic daisyUI; no arbitrary pixel heights | — |
| STATE-LD-09 | `orientation_strip`: states = {rest only}. Read-only guidance panel; one state per surface. Surfaces: `:deliveries` / `:inbound` / `:preview`. Conditionally rendered by parent when no record is selected — strip is the empty-state treatment for the detail pane. No hover/focus/interactive states. `hero-lifebuoy` icon uses `text-primary` accent — within 10%-accent rule (single icon, not a background fill). See IA-LD-05 for strip placement across viewports. | Operator + Preview / `orientation_strip` (`operator/shell.ex:314-367`) | `rounded-box` radius; `border-base-300` semantic; `bg-base-200` semantic; `text-primary` accent within 10% rule; no interactive states | — |
| STATE-LD-10 | `shell` (operator): states = {rest-light, rest-dark}. Theme driven by `data-theme="mailglass-light"` / `data-theme="mailglass-dark"` on the root div. `flash_region` provides `:info` and `:error` flash states within the shell. No loading skeleton at shell level — LiveView phx-loading handles page-level loading via CSS. Sidebar is `hidden md:flex` (desktop only). Mobile layout uses `flex flex-wrap` header nav. | Operator / `shell` (`operator/shell.ex:116-193`) | `bg-base-100` semantic; `data-theme` drives daisyUI theme switching; no hardcoded hex; flat elevation (sidebar `border-r border-base-300`); no `shadow-*` on layout containers | — |
| STATE-LD-11 | `deliveries_list` (master) and `records_list` (inbound master): states = {rest-populated-unselected, rest-populated-selected, hover, focus, empty}. **Selected row:** `border-l-4 border-primary bg-base-100` + `aria-current="true"` + `aria-selected="true"`. **Unselected row:** `border-l-4 border-transparent bg-base-200`. **Hover (unselected):** `hover:bg-base-100`. **Focus:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset` to row buttons — currently missing. **Empty:** icon + heading + filter-clear instruction (`min-h-64` centering). `loading` state is deferred to Phase 97 IF async assigns are adopted; for synchronous mount, N/A. Transition: `transition-colors` already present; see MOTION-LD-07 for row-state animation spec. | Operator / `deliveries_list` (`operator/deliveries_list.ex:13-66`), Inbound / `records_list` (`inbound/records_list.ex:19-98`) | `border-primary` = semantic accent (single active row border — within 10%-accent rule); `bg-base-100`/`bg-base-200` semantic; `min-h-11` already set on row buttons; `focus-visible:ring-primary` semantic token | — |
| STATE-LD-12 | `detail_header` (operator + inbound): states = {rest-shown, rest-absent (parent shows orientation_strip), focus on replay button, active on replay button}. Detail card is read-only except the replay button. **Replay button:** `btn btn-error min-h-11 px-5` — min-h-11 is correctly set (no btn-sm). daisyUI `btn` provides hover/active/focus for the replay button. **Inbound variant:** replay button has `disabled={replay_disabled?(@outcome)}` + `btn-disabled` class when outcome is `:no_match` — IMPLEMENTED. `h2` heading uses `text-xl` — this is NOT a token class (should be `text-heading` per design-system). **Decision:** Phase 97 executor must replace `text-xl` with `text-heading` in both `operator/detail_header.ex:21` and `inbound/detail_header.ex:38`. | Operator / `detail_header` (`operator/detail_header.ex:15-95`), Inbound / `inbound/detail_header.ex:23-96` | `text-heading` = `@theme` token (20px); NOT `text-xl` (raw Tailwind); `btn-error` = semantic; `min-h-11` = 44px touch target; `px-5` = not a token (`px-lg` = 32px token, or use `px-md`+) | — |
| STATE-LD-13 | `filters_form` (operator): states = {rest-empty, rest-filled, hover, focus}. Label token: `text-label font-bold uppercase text-secondary` (drop `tracking-[0.08em]` — arbitrary value, not a token). Controls: `input-bordered min-h-11 w-full` / `select-bordered min-h-11 w-full`. `min-h-11` meets the 44px touch target for inputs/selects. daisyUI `input-bordered` / `select-bordered` provide hover + focus ring by default. No error or disabled states needed (filter fields are always active; invalid values simply return empty results). Inbound `filters_form` sibling must apply the same label token fix (GAP-04). See IA-LD-04 for the IA specification of label hierarchy. | Operator / `filters_form` (`operator/filters_form.ex:13-90`), Inbound / `inbound/filters_form.ex` | `text-label` = `@theme` token; no `tracking-[0.08em]`; `min-h-11` = 44px; `input-bordered` / `select-bordered` = daisyUI semantic | GAP-04 |
| STATE-LD-14 | `support_cards` (triage grid): states = {rest-tier1-shown, rest-tier1-hidden (Tier-2 visible), empty (all zero → Tier-2 only)}. **CTA buttons (Tier-1):** Remove `btn-sm` from lines 56, 102, 152 — use `btn btn-primary` with `px-md` (or `px-lg`) token padding. `min-h-11` must be the effective height (44px touch target). **CTA button (Tier-2 compact row, line 204):** Remove `btn-sm` — use `btn btn-ghost` with `px-sm`. Drilldown detail disclosure toggle: states = {rest-closed, rest-open}; implemented via `:if={focused?}` conditional rendering (no animation needed; info-reveal is synchronous). Tier-1 card hover/focus: card containers are `<article>` (not interactive); CTAs within are `<button>` with daisyUI hover/active/focus via `btn`. | Operator / `support_cards` (`operator/support_cards.ex:18-219`) | `min-h-11` = 44px hard constraint (removes GAP-01 btn-sm violation); `btn-primary` = daisyUI semantic; `px-md`/`px-sm` = `@theme` tokens; flat elevation (card `border border-base-300`, no shadow) | GAP-01 |
| STATE-LD-15 | `suppression_card`: states = {rest-present, rest-absent}. Display-only. **Present:** metadata grid + reversibility copy. `badge-outline` headline badge (neither accent nor semantic status — neutral). **Absent:** "No active suppression entry" prose. No hover/focus/active states. No loading state at this time (synchronous assignment). Gallery specimen: show both states. | Operator / `suppression_card` (`operator/suppression_card.ex:10-48`) | `badge-outline` = semantic daisyUI; `rounded-box` radius; `border-base-300` semantic; no hex | — |
| STATE-LD-16 | `timeline`: states = {rest-populated, rest-highlighted-event, rest-empty}. Entrance animation via `motion-timeline` (staggered, 40ms per item, cap 8) — see MOTION-LD-08. **Highlighted event:** `border-primary ring-1 ring-primary/40` — uses `ring-primary/40` opacity tint; within 10%-accent rule (single highlighted row). **Timeline dot classes:** `:webhook_replay_failed` → `bg-error`; `:webhook_replay_requested`/`:webhook_replay_succeeded` → `bg-warning`; `:reconciled` → `bg-accent`; all other → `bg-primary`. **Empty:** prose "No delivery events have been recorded for this item yet." No loading state (synchronous). | Operator / `timeline` (`operator/timeline.ex:14-71`) | `motion-timeline` CSS animation bounded ≤300ms total; `bg-primary`/`bg-error`/`bg-warning` = semantic; `ring-primary/40` = opacity tint (within semantic token rule); no arbitrary colors; `prefers-reduced-motion` via global media query | — |
| STATE-LD-17 | `replay_modal`: states = {rest-closed, rest-open-exact, rest-open-ambiguous, rest-open-unavailable, rest-open-loading}. **A11y additions required by Phase 97:** (1) Add `id` to `h2` heading and `aria-labelledby` on `role="dialog"` container; (2) Add `phx-key="Escape" phx-window-keydown="close_replay"` for keyboard dismissal; (3) Focus trap: use `Phoenix.LiveView.JS.focus_first` on modal open and `JS.focus` back to the trigger on close. **Confirm button disabled state:** rendered via conditional (`confirm_enabled?/2`) — button is absent (not present but greyed) when disabled. This is acceptable for the operator pattern — absent = not reachable by keyboard. **Overlay entrance:** `motion-overlay` (scale 0.98→1 + opacity, 220ms) already applied; see MOTION-LD-09. | Operator / `replay_modal` (`operator/replay_modal.ex:15-109`) | `role="dialog"` + `aria-modal="true"` required; `shadow-overlay` for modal only (meets flat-elevation exception); `motion-overlay` ≤220ms ease-out; no springs; `btn-error`/`btn-ghost` semantic | — |
| STATE-LD-18 | `routing_trace`: states = {rest-empty, rest-populated-all-passing, rest-populated-first-failing}. No info-reveal or locked state — D-09's "locked/info reveal" refers to `evidence_card` not `routing_trace`. **First-failing highlight:** `border-l-4 border-error px-3` on the failing clause `<li>`. **Route-level badge:** `badge-outline badge-error` when any verdict fails. No interactive states — fully read-only. Loading state: deferred to Phase 99 if async assigns are adopted. Gallery specimen: show all three states (empty trace, trace with all-pass route, trace with first-failing clause). | Inbound / `routing_trace` (`inbound/routing_trace.ex:31-101`) | `border-error` = semantic; `badge-outline badge-error` = daisyUI semantic; `text-label` for dimension labels; no interactive tokens; `rounded-box` radius | — |
| STATE-LD-19 | `evidence_card`: states = {rest-no-evidence, rest-redacted, rest-revealed, rest-denied, hover-reveal-btn, focus-reveal-btn, active-reveal-btn}. **Redacted placeholder:** `mono rounded-box border border-base-300 bg-base-100 p-3 text-label text-secondary` on `surface-sunken` (`bg-base-100` inside `bg-base-200` card). **Revealed:** `<pre>` with `max-h-80 overflow-auto rounded-box border border-base-300 bg-base-100 text-label text-base-content` — `max-h-80` is an arbitrary height; accepted as content-overflow utility (not a layout spacing violation). **Denied:** `border-warning bg-warning/10 p-3 text-body text-base-content`. Reveal button: `btn btn-ghost btn-sm min-h-11 px-4` — `btn-sm` + `min-h-11` tension requires Phase 97 bundle verification. Decision: if `min-h-11` does not override `btn-sm` in the compiled CSS, drop `btn-sm`. Verification facts: mono key-value chips on `bg-base-200`. | Inbound / `evidence_card` (`inbound/evidence_card.ex:29-113`) | `bg-base-100` = semantic `surface-sunken` within `bg-base-200` card; `text-label` = `@theme` token; `border-base-300` semantic; `border-warning` semantic; `min-h-11` = 44px (verify against btn-sm); no hex; no raw palette | — |
| STATE-LD-20 | `device_frame` (preview segmented control): states = {rest-inactive-btn, rest-active-btn, hover, focus, active-press}. **Active:** `btn btn-sm join-item btn-primary` + `aria-pressed="true"`. **Inactive:** `btn btn-sm join-item btn-ghost` + `aria-pressed="false"`. `btn-sm` touch-target concern: preview is a dev-only surface (severity lower than operator). Decision: ADD `min-h-11` to all three buttons alongside `btn-sm` — same resolution as theme_toggle. Phase 97 executor must verify `min-h-11` overrides `btn-sm` in the compiled bundle. `role="group"` + `aria-label="Preview device width"` already implemented — compliant. Hover/active/focus: daisyUI `btn` provides. | Preview / `device_frame` (`preview/device_frame.ex:26-58`) | `min-h-11` = 44px hard constraint; `btn-primary`/`btn-ghost` = daisyUI semantic; `join-item` = daisyUI layout utility; `aria-pressed` = correct ARIA attribute for toggle buttons | — |
| STATE-LD-21 | `tabs` (preview): states = {rest-inactive-tab, rest-active-tab, hover, focus, content-empty}. **Active tab:** `font-bold border-b-2 border-primary text-base-content` + `aria-selected="true"`. **Inactive tab:** `text-secondary hover:bg-base-200` + `aria-selected="false"`. **Focus:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset` to tab buttons. **Tab strip a11y additions (Phase 97):** each `role="tab"` button needs `aria-controls="{panel-id}"`; each content div needs `role="tabpanel"` + `aria-labelledby="{tab-id}"`. **Content empty:** HTML tab with empty `@html_body` shows blank iframe — NO explicit empty-state treatment. Decision: add a "No HTML body" placeholder inside the HTML tab pane when `@html_body == ""`. Tab-swap animation: `motion-tab-swap` (crossfade 150ms) — see MOTION-LD-06. | Preview / `tabs` (`preview/tabs.ex:35-97`) | `border-primary` = semantic accent (active tab underline, within 10%-accent rule); `text-label` = `@theme` token (table headers); `min-h-10` on tabs (currently 40px — below 44px threshold; tabs are not primary touch targets, they are a supplemental control at the top of a preview pane; acceptable at 40px given no mobile-first requirement for the preview surface which is dev-only) | — |
| STATE-LD-22 | `sidebar` (preview): states = {rest-mailable-collapsed, rest-mailable-expanded, rest-scenario-inactive, rest-scenario-active, rest-mailable-error, rest-mailable-no-previews, hover-summary, hover-scenario}. **Active scenario:** `border-l-[3px] border-primary bg-base-200 text-base-content font-normal`. Note: `border-l-[3px]` is an arbitrary value — `border-l-2`/`border-l-4` are Tailwind defaults; `border-l-[3px]` deviates from the token rounding pattern but is minor. Decision: assess whether `border-l-[3px]` → `border-l-2` (2px) or `border-l-4` (4px) in Phase 97; 2px is closer to the brand's border-width discipline. **Focus:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` to both `<summary>` and scenario `<.link>` elements. **Empty list:** parent `preview_live.ex` renders `orientation_strip` when `@mailables == []`; sidebar component itself has no empty-list treatment — acceptable (parent owns empty state). Loading: synchronous discovery; N/A. | Preview / `sidebar` (`preview/sidebar.ex:40-152`) | `border-primary` = semantic; `bg-base-200` = semantic; `text-label` via parent classes; `focus-visible:ring-primary` semantic; `<details>/<summary>` native disclosure = no JS animation; collapsed/expanded state is native HTML — no MOTION dossier dependency | — |
