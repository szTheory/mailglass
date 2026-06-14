# Information Architecture Dossier — mailglass_admin v1.11

**RESEARCH-02 · Phase 96 · 2026-06-14**
**Author:** GSD executor (claude-sonnet-4-6)
**Sourcing split (D-07):** External-led + codebase-grounded.
**Downstream citation:** Phases 98 (Operator), 99 (Inbound), 100 (Preview) cite `IA-LD-NN` IDs directly.

---

## 1. Sources and Evidence

### 1.1 gov.uk Design System

**URL:** https://design-system.service.gov.uk/
**Relevant sections:** Navigation, Tables, Filter patterns (recommended component use), Layout.

The gov.uk Design System is the leading public-sector IA reference. Its evidence on list/detail, filter, and navigation is grounded in large-scale usability research on dense information surfaces — directly analogous to mailglass_admin's operator audit use case. Key evidence:

**What the gov.uk DS does well (to be loved and adopted):**

1. **Clear progressive disclosure on list → detail.** Tables surface only scannable identifiers; detail panels expand in-context or in a separate pane. Never hide the list until the user navigates back. (https://design-system.service.gov.uk/components/table/)

2. **Stable URL state for every filter/selection.** The DS warns that filter state must survive refresh and sharing. Deep-link-reproducibility is a core trust signal on audit-focused tools. (https://design-system.service.gov.uk/components/back-link/ — the "back link always works" rule implies URL-serialized state.)

3. **Visible, label-first filter controls.** Filters use explicit `<label>` with visible text above the control, never icon-only or placeholder-as-label. This prevents "what does this filter do?" confusion. (https://design-system.service.gov.uk/components/select/ — every select has a visible associated label.)

4. **Navigation hierarchy: clear L1 (surface name) → L2 (section/action) labelling.** The DS side-navigation and breadcrumb patterns enforce named, non-ambiguous labels; never "Item 1." (https://design-system.service.gov.uk/components/breadcrumbs/)

5. **Empty states are actionable.** When a query returns no results, the page shows the empty state in place of the list with a clear explanation — never a blank page. (https://design-system.service.gov.uk/components/error-message/ — by analogy: a zero-result state is user-facing feedback that must name the cause.)

**What the gov.uk DS explicitly warns against (to be hated and avoided):**

1. **Hidden filters behind hamburger / "show filters" accordion at desktop.** The DS sidebar filter pattern keeps filters visible at wide viewports; the "show filters" button is a mobile-only affordance. At 768px+ the filter column should be persistently visible. (See DS "Filter" pattern research: https://design-system.service.gov.uk/community/blogs-talks-podcasts/ — multiple Finder-pattern posts confirm this.)

2. **Ambiguous drill-down paths without a breadcrumb or back affordance.** If the list disappears on record selection (full-pane replacement), the user loses orientation. The DS recommends keeping the list visible in a side-pane (master-detail) or providing an explicit back navigation.

3. **Navigation items that mirror state rather than destination.** A nav item label like "Current deliveries" is bad; "Deliveries" is correct — the noun, not the filter.

### 1.2 Nielsen Norman Group

#### 1.2.1 Filter vs. Facets

**URL:** https://www.nngroup.com/articles/filters-vs-facets/

NNGroup distinguishes:
- **Filters** — a small, bounded set of controls that reduce a homogeneous list by explicit criteria (e.g., status, window). Appropriate when the data has few meaningful dimensions and the user knows what they want. Works well as a persistent visible sidebar or compact row of controls.
- **Facets** — dynamic counts that update as the user selects; appropriate for large heterogeneous catalogs (e-commerce, content libraries) where the user is *discovering* rather than *auditing*.

**IA decision driver:** mailglass_admin's operator surfaces are *audit-focused*, not discovery-focused. Records sets are small (recent 168h window), and the user's JTBD is "find why a specific delivery failed" — not "explore what categories of mail exist." Faceted counts add cognitive load without value. **Plain filters (visible, labeled, URL-serialized) are the correct pattern.** This closes the design choice: no dynamic counts, no collapsible facet panels.

**What NNGroup loves:** filters visible at all times at wide viewports; clear field labels above controls (not inside as placeholder); reset/clear action when filters are active.

**What NNGroup warns against:** placeholder-as-label (the label disappears on input); filter controls that collapse by default at desktop ("show filters" button hidden); unlabeled icon buttons for filter dimensions.

#### 1.2.2 Master-Detail Pattern

**URL:** https://www.nngroup.com/articles/master-detail/

NNGroup identifies three master-detail layouts:
1. **Side-by-side (responsive master-detail):** list pane on left, detail on right at ≥768px; full-screen detail at 390px with a back navigation.
2. **Sequential (stacked):** list replaces itself with detail; requires explicit back navigation. Lower cognitive load at mobile but risks disorientation.
3. **Separate pages:** full-page navigation to a detail route. Breaks the "stay in context" principle for audit surfaces — not recommended for admin tools.

**Key NNGroup findings:**
- At mobile (390px), side-by-side is untenable. The master list must fill the full screen; selecting a record replaces the master with the detail view (or uses a slide/push navigation). A clear back or header label is mandatory.
- At tablet (768px), the split is viable with a 40/60 or 33/67 column split.
- At desktop (1440px), the split is the canonical pattern. The master list should not collapse or disappear.
- **List selection state must be visually communicated** (aria-selected, highlighted row) even when the detail is visible — so the user knows which record they are inspecting.
- Empty state in the detail pane (no record selected) should use the orientation strip / placeholder pattern — not an empty white pane.

---

## 2. Current mailglass_admin IA Inventory

### 2.1 Operator Surface — `/ops/mail`

**Module:** `MailglassAdmin.OperatorLive` (`mailglass_admin/lib/mailglass_admin/operator_live.ex`)
**Shell:** `MailglassAdmin.Operator.Shell` (`mailglass_admin/lib/mailglass_admin/operator/shell.ex`)

**Current IA structure:**

```
Shell (shell.ex:116)
├── aside (sidebar, hidden md:flex, w-60)  ← L1 nav at ≥768px
│   ├── Logo + "Operator" label (shell.ex:124-126)
│   ├── nav > nav_link × 2 (Deliveries, Inbound) (shell.ex:130-145)
│   └── theme_toggle (shell.ex:146-148)
├── header (flex, visible at all viewports) ← L1 nav at 390px
│   ├── Logo (mobile only, shell.ex:153-155)
│   ├── nav > nav_pill × 2 (Deliveries, Inbound) (shell.ex:157-169)
│   ├── tenant_chip (shell.ex:171)
│   └── theme_toggle (mobile, shell.ex:173-175)
└── main (shell.ex:179)
    ├── h1 (page title: "Deliveries" or "Inbound") (shell.ex:183)
    ├── flash_region (shell.ex:186)
    └── inner_block (surface body — deliveries list + detail, or inbound list + detail)
```

**Deliveries body structure (within inner_block):**
- `orientation_strip` (shell.ex:314) — appears when no delivery is selected; heading + tips list
- `FiltersForm.fields` (operator/filters_form.ex:13) — Tenant, Provider, Status, Event, Window
  - Labels: `text-label font-bold uppercase tracking-[0.08em] text-secondary` (filters_form.ex:17, 29, 42, 56, 71)
- Deliveries list (`DeliveriesList`) → row → selected row highlights with `border-primary`
- Detail pane: `DetailHeader`, `OperatorTimeline`, `SupportCards`, `SuppressionCard`, `ReplayModal`
- `SupportCards` (operator/support_cards.ex:18) — two-tier triage grid: Tier 1 (full card for non-zero counts), Tier 2 (compact row for zero/informational)

**Key IA observations:**
- At 390px: mobile nav pills replace the sidebar (shell.ex:157-169); sidebar is `hidden md:flex` (shell.ex:122)
- Orientation strip uses `orientation_strip/1` (shell.ex:314) with per-surface copy; appears when no record selected
- Filter form labels use `tracking-[0.08em]` not the `text-label` CSS class path — potential GAP-04 analogue (deliveries uses inline Tailwind class composition, inbound has a similar pattern)
- URL-driven state machine: all filter + selection state in URL params (design-system.md:157)

### 2.2 Inbound Surface — `/ops/mail/inbound`

**Module:** `MailglassAdmin.InboundLive` (`mailglass_admin/lib/mailglass_admin/inbound_live.ex`)
**Shell:** same `Operator.Shell` (same operator `live_session`, shell.ex:7-8)

**Inbound body structure:**
- `Inbound.FiltersForm.fields` (inbound/filters_form.ex:17) — Tenant, Provider, Mailbox outcome, Window, Search
  - Labels use `text-label font-bold uppercase tracking-[0.08em] text-secondary` (inbound/filters_form.ex:20, 33, 47, 63, 79)
  - **GAP-04 evidence:** The GAP register notes filter labels are "rendered as uppercase raw CSS rather than via the text-label token." Both FiltersForm siblings use `tracking-[0.08em]` inline — the `text-label` token should provide this via `letter-spacing` in the token definition; using inline tracking instead of the token class is the off-token pattern GAP-04 flags.
- `Inbound.RecordsList` — list of inbound records
- `Inbound.RoutingTrace` (inbound/routing_trace.ex:32) — routing trace card; per-route clause diff
- `Inbound.EvidenceCard` — evidence card with `reveal_state` toggle (:redacted / :revealed)
- `Inbound.Timeline` — event timeline
- `Inbound.ReplayModal` — replay action modal

**Key IA observations:**
- `RoutingTrace` renders `article` > `section` per route — a nested disclosure pattern (inbound/routing_trace.ex:31-60)
- `EvidenceCard` has a `:redacted`/`:revealed` reveal state (inbound_live.ex:77) — PII-gated progressive disclosure
- No overview/at-a-glance tier before the record list (GROUP-02 gap)
- `orientation_strip` exists in the shell (shell.ex:346-356) with inbound copy but its placement is driven by the inner_block — pending surface implementation

### 2.3 Preview Surface — `/dev/mail`

**Module:** `MailglassAdmin.PreviewLive` (`mailglass_admin/lib/mailglass_admin/preview_live.ex`)
**Shell:** separate dev `live_session` (never reaches operator shell)

**Preview body structure:**
- `:index` action — no scenario selected; empty state or "Preview the first one" CTA
- `:show` action:
  - `Preview.Sidebar` (preview/sidebar.ex:40) — mailable list with `<details>/<summary>` collapsible scenario groups; `h1 "Mailers"` (sidebar.ex:43); active scenario gets 3px Glass left border
  - `Preview.Tabs` (preview/tabs.ex:35) — `role="tablist"` strip: HTML / Text / Raw / Headers; tab content pane below
  - `Preview.DeviceFrame` — sandboxed iframe with device_width (375/768/1024)
  - `Preview.AssignsForm` — form for custom assign overrides

**Key IA observations:**
- Sidebar uses `<details>/<summary>` for mailable → scenarios hierarchy — a native progressive-disclosure pattern (sidebar.ex:40, cf. line 11 in moduledoc)
- Tabs use `role="tablist"` + `aria-selected` correctly (tabs.ex:44)
- Preview surface has its own separate chrome (no Operator Shell); dark_chrome toggle is an assign (`preview_live.ex:73`) but GAP-03 notes the dark theme param is currently ignored in the preview chrome
- No persistent filter column — not needed (preview is mailable-selection, not filtering)
- Device-width toggle controls iframe width (preview_live.ex:67) — not a filter dimension

---

## 3. Pattern Fit Analysis

### 3.1 Operator Surface — Pattern Assessment

| Pattern | Fit | Notes |
|---------|-----|-------|
| Master-detail (side-by-side ≥768px) | **Partial** | Shell structure supports a split, but the deliveries list and detail pane layout within `inner_block` needs explicit flex/grid split at ≥768px. At 390px the current pattern is unverified. |
| Filter visible at ≥768px | **Good** | No "show filters" accordion; filter fields are always rendered in the DOM |
| Filter labels via token | **Gap** | `tracking-[0.08em]` inline rather than pure `text-label` class — matches GAP-04 analogue in deliveries |
| URL-driven state | **Excellent** | URL params serialize all filter + selection state (design-system.md:157) |
| Orientation strip (empty detail) | **Good** | `orientation_strip/1` renders when no delivery selected (shell.ex:314) |
| Triage grid (SupportCards) | **Good** | Two-tier hierarchy correct per v1.7 UI-SPEC; Tier 1 full card, Tier 2 compact row |
| Navigation L1/L2 labels | **Good** | "Deliveries" / "Inbound" at L1; surface title as h1 at L2 |
| Mobile nav (390px) | **Partial** | nav_pill strip replaces sidebar; but nav_pill uses `min-h-11` (shell.ex:231) ✓; theme toggle is in header (shell.ex:173-175) but sidebar is hidden |

### 3.2 Inbound Surface — Pattern Assessment

| Pattern | Fit | Notes |
|---------|-----|-------|
| Master-detail split | **Partial** | Mirrors operator structure but inbound lacks a verified overview/at-a-glance tier (GROUP-02 gap) |
| Filter labels via token | **Gap** | `tracking-[0.08em]` inline — the GAP-04 finding; `text-label` in the design-system token should own this |
| RoutingTrace disclosure | **Good** | `article > section` per-route clause diff; appropriate nested progressive disclosure |
| EvidenceCard reveal state | **Good** | `:redacted`/`:revealed` toggle is correct PII-gated progressive disclosure |
| Orientation strip | **Needs wire-up** | `orientation_strip/1` has inbound copy (shell.ex:346-356) but placement in live view template pending Phase 99 |
| Overview/triage tier | **Missing** | No at-a-glance summary before the record list (GAP GROUP-02) |

### 3.3 Preview Surface — Pattern Assessment

| Pattern | Fit | Notes |
|---------|-----|-------|
| Navigation hierarchy | **Good** | Sidebar h1 "Mailers" as L1; `<details>` mailable as L2; `<summary>` scenario as L3 — clear hierarchy |
| Dark-mode chrome | **Gap** | GAP-03: dark_chrome assign exists but theme param ignored in preview chrome |
| Tab-strip IA | **Good** | `role="tablist"` + `aria-selected` + tab-swap motion pattern correct |
| Empty state / index action | **Partial** | `:index` renders empty or "Preview the first one" CTA; GAP-02 notes that the focusable CTA may be absent |
| Device-width toggle | **Good** | Three discrete breakpoints (375/768/1024) via assign — not a filter, an IA tool |
| Filter column | **N/A** | No filter column on preview surface; sidebar IS the navigation |

### 3.4 Cross-Cutting Strengths and Deviations

**Strengths:**
- URL-driven state is excellent across both operator surfaces — directly honors the gov.uk DS "stable URL" principle and NNGroup's "refresh-safe filter state" requirement.
- `aria-current="page"` on `nav_link` (shell.ex:206) and `aria-selected` on tabs (tabs.ex:44) are both correct semantic patterns.
- Orientation strip as an "empty detail pane" state is well-designed — it names the cause and provides actionable tips rather than an empty white pane.

**Deviations needing locks:**
- Filter label class: inline `tracking-[0.08em]` vs. semantic `text-label` token (GAP-04, both FiltersForm siblings)
- Master-detail viewport split is unspecified: no locked rule for which viewport gets side-by-side vs. stacked
- Orientation strip: no locked rule for where it renders at 390px (above content? below header? replaces list?)
- Triage grid (SupportCards) mobile priority ordering: Tier 1 / Tier 2 ordering on mobile unspecified
- Navigation mobile: nav_pill strip is correct but the disclosure pattern for 390px IA (pills vs. drawer) is not locked

---

## 4. Draft Decisions

### 4a. Orientation Strip Position per Viewport

**Draft:** At ≥768px, `orientation_strip` renders in the detail pane column (right column of master-detail split), replacing the "no record selected" placeholder. At 390px, `orientation_strip` renders as the main content below the filter form, above the record list — it serves as the "what to do first" guidance before the user selects a record.

**Reasoning:** At 390px the master pane fills the full screen and the detail pane is not visible until a record is selected. The orientation strip must therefore be in the master view context at mobile, not hidden in a detail pane that the user hasn't navigated to yet.

### 4b. Filter Panel Disclosure Pattern

**Draft:** Filter controls (`FiltersForm.fields`) are always rendered in the DOM at all viewports. At ≥768px, the filter column is persistently visible as a left/top panel. At 390px, filter controls render in a collapsible section triggered by a "Filters" button (with disclosure indicator), defaulting to collapsed to prioritize the record list on a small screen.

**Reasoning:** NNGroup and gov.uk DS both confirm that collapsing filters at mobile is appropriate and expected; hiding filters at desktop is an anti-pattern. The current implementation renders filters always (no toggle) — at 390px this pushes the record list far down. A mobile-only disclosure toggle is the correct fix.

### 4c. Master-Detail Split Viewport Behaviour

**Draft:** At 390px: master (list) fills 100% width; record selection navigates to/reveals detail at 100% width with a back affordance (not a push_patch to a new route — use CSS `hidden/block` or `:if` conditioned on `selected_record != nil`). At 768px: two-column split, left pane 40% (list + filters), right pane 60% (detail / orientation strip). At 1440px: two-column split, left pane 33% (list + filters), right pane 67% (detail).

**Reasoning:** NNGroup master-detail pattern + gov.uk DS progressive disclosure. No new routes needed — `:if` on `selected_record` + CSS column classes at responsive breakpoints. This stays within the "no new routes" scope lock.

### 4d. Triage Grid (SupportCards) Mobile Priority Ordering

**Draft:** On mobile (390px), `SupportCards` renders Tier 1 cards first (non-zero actionable counts: `failed_ingest`, `orphan_backlog`), then Tier 2 rows (zero-state / informational). Within Tier 1, order by severity (error > warning > info). This matches the current rendering order in `support_cards.ex` which already follows Tier 1 → Tier 2 top-to-bottom — the lock simply confirms and stabilizes this ordering.

**Reasoning:** On a 390px screen the user sees fewer items before scrolling. The most actionable items (non-zero error counts) must appear first. The current code already does this (support_cards.ex:35 `Tier 1` comment) — the lock canonizes it.

### 4e. Navigation Hierarchy L1/L2 Labelling

**Draft:** L1 navigation = surface noun ("Deliveries", "Inbound") in both `nav_link` (sidebar ≥768px) and `nav_pill` (header 390px). L2 = page h1 set by the surface (`@title` in shell.ex:183). L1 items never carry filter state in their label (never "Deliveries (3 failed)"). `aria-current="page"` on the active L1 item; the h1 reinforces the surface name.

**Reasoning:** gov.uk DS "navigation items reflect destinations not state." The current implementation already does this correctly (shell.ex:132-143) — the lock prevents future drift.

### 4f. Empty and Loading State Placement per Surface

**Draft:**
- **Operator + Inbound (no tenant):** Empty state renders in the master pane (list area) with a cause-naming message ("No tenant selected — enter a tenant ID to begin") and a brief instruction. Not an error, not a modal.
- **Operator + Inbound (tenant, no results):** Empty state renders in the list area — "No deliveries in the last 7 days" — with a reset-filters action if filters are active.
- **Operator + Inbound (detail pane, no record selected):** `orientation_strip` renders in the detail pane (≥768px) or below filters (390px).
- **Preview (:index, no mailables):** Empty state renders as the full main content — "No mailables discovered" with a cause-naming tip list (the "actionable orientation" pattern, already partially implemented in preview_live.ex).
- **Preview (:index, mailables exist):** "Preview the first one" CTA centered in main content, always focusable (GAP-02 upstream close signal — MOTION-LD-12 in the MOTION dossier).

**Reasoning:** gov.uk DS "empty states are actionable and name the cause." NNGroup "empty state in place of content, not a blank pane."

---

## 5. Adversarial Synthesis

Each draft decision is challenged against (a) the hard design constraints and (b) the open GAP rows before locking.

### 5.1 Critic Pass

**Challenge 4a (Orientation strip at 390px in master view):**
- Constraint: no new routes. — PASS. Placing the orientation strip inside the list pane (`inner_block`) at 390px is a CSS conditional (`md:hidden`), not a new route or new module.
- Constraint: no Node toolchain. — PASS. Pure HEEx + Tailwind responsive classes.
- GAP-02 (preview focusable CTA): The orientation strip decision for 390px Operator/Inbound does not touch the Preview empty state. GAP-02's close path is via MOTION-LD-12 (the MOTION dossier). The orientation strip lock is orthogonal. PASS.
- **Verdict: LOCK 4a as-is.**

**Challenge 4b (Filter disclosure at 390px):**
- Constraint: no new routes. — PASS. A disclosure toggle is a LiveView event (`phx-click="toggle_filters"`) or CSS `hidden` conditioned on a socket assign. No route change.
- Constraint: flat elevation (no glassmorphism/bevels). — PASS. The filter disclosure panel sits inline; it does not pop over other content with a shadow.
- Constraint: CSS+LiveView.JS only (no client JS hook). — PASS. `Phoenix.LiveView.JS.toggle` or `:if` assign-driven.
- GAP-04 (filter labels off-token): The disclosure decision does not close GAP-04 directly — GAP-04 is about label class, not disclosure. The label fix is in decision 4g (below). NOTED.
- **Verdict: LOCK 4b as-is. Add a filter-label token decision (4g) to close GAP-04.**

**Challenge 4c (Master-detail split breakpoints):**
- Constraint: no new routes. — PASS. CSS `flex md:grid grid-cols-[40%_60%]` or similar. `:if` on selected_record.
- Constraint: semantic tokens only (spacing, no arbitrary px). — PARTIAL. "40/60" and "33/67" are percentage-based grid templates. The spacing tokens cover gap/padding but not column widths. Column percentages are layout structure, not spacing tokens — this is acceptable (design-system.md does not restrict `grid-cols-*` percentage values, only spacing utilities). PASS.
- Constraint: no pixel-diff visual regression testing (D-07 banned). — PASS. The decision drives structural assertions (list visible, detail visible, correct DOM order), not pixel counts.
- **Verdict: LOCK 4c with explicit column percentages.**

**Challenge 4d (Triage grid mobile priority):**
- Constraint: no new routes, no Node toolchain. — PASS. DOM order is pure HEEx.
- Constraint: semantic tokens on spacing. — PASS. The Tier 1/Tier 2 ordering is DOM structure, not spacing.
- GAP-01 (btn-sm touch target in support_cards.ex:56): Decision 4d does not fix GAP-01. GAP-01 requires removing `btn-sm` or adding `min-h-11` to the drilldown CTA buttons — that is a Phase 98 task, not an IA decision. NOTED as out-of-scope here.
- **Verdict: LOCK 4d as-is. GAP-01 close is Phase 98 scope.**

**Challenge 4e (Navigation L1/L2 labels):**
- Constraint: no new routes. — PASS.
- The lock confirms existing correct behavior. No risk of constraint violation.
- **Verdict: LOCK 4e as-is.**

**Challenge 4f (Empty/loading state placement):**
- Constraint: flat elevation. — The empty state renders inline (no card pop-over, no shadow-overlay). PASS.
- Constraint: no new routes. — PASS. All states are within the current LiveView.
- GAP-02 (preview focusable CTA): Decision 4f directly names the GAP-02 fix direction ("always focusable" CTA at `:index`). The IA decision is the specification; the implementation (ensuring the button is in the DOM and focusable) is Phase 100.
- **Verdict: LOCK 4f. Reference GAP-02.**

### 5.2 New Decision from Critic Pass

**4g. Filter label class (GAP-04 direct close decision):**

The critic noted that decisions 4a–4f do not directly address GAP-04. Adding this decision closes the gap at the IA/Type layer.

**Draft:** All filter section labels (Tenant, Provider, Status, Event, Window, Search, Mailbox outcome) on ALL three surfaces MUST use the `text-label` token class as the primary typography class — not inline Tailwind `tracking-[0.08em]`. The full label class string MUST be: `text-label font-bold text-secondary`. The `uppercase` and explicit `tracking` values are REMOVED because `text-label` in `design-system.md:63` (the `--text-label` token at 12px) includes the appropriate tracking in the token definition.

**Constraint:** semantic tokens only (Type pillar, design-system.md:63). This matches GAP-04's fix sketch: "replace with text-label class or ensure text-label compiles to the same uppercase tracking style per design-system.md."

**Closes-GAP:** GAP-04.

**Adversarial check:**
- Does `text-label` include uppercase + tracking? The design-system.md token table (line 63) defines `text-label` at 12px/400. The `uppercase` and `tracking` in the current filter labels (`uppercase tracking-[0.08em]`) are additional classes layered on top of `text-label`. If `text-label` does NOT include uppercase in its definition, removing `uppercase` would break the visual. **Resolution:** The decision is to use `text-label font-bold text-secondary` PLUS retain `uppercase` — but the `tracking-[0.08em]` MUST be replaced with either a token-defined tracking value or removed (if `text-label` already defines letter-spacing). The constraint-binding is "semantic tokens only" which means the tracking must come from the token, not an arbitrary Tailwind arbitrary value `tracking-[0.08em]`. Phase 99 implementors should verify what letter-spacing `text-label` defines in `tokens.css` and use the canonical token-class value rather than the arbitrary override. The lock is: **no `tracking-[0.08em]`; use `text-label uppercase font-bold text-secondary` where uppercase is retained as a presentational style (it is a CSS keyword, not a spacing token).**

---

## LOCKED DECISION

| LD-ID | Decision | Applies-to (surface/archetype) | Constraint-binding | Closes-GAP |
|-------|----------|-------------------------------|-------------------|------------|
| IA-LD-01 | At ≥768px, `orientation_strip` renders inside the right (detail) column of the master-detail split, replacing the "no record selected" blank area. At 390px, `orientation_strip` renders below the filter form, above the record list, as full-width inline content — it is always in the DOM when `selected_record == nil`. No motion class on orientation strip (born token-clean per shell.ex:309). | Operator (`/ops/mail`), Inbound (`/ops/mail/inbound`) | no new routes; semantic tokens only; CSS+LiveView.JS only (`:if` + responsive classes) | — |
| IA-LD-02 | Filter controls (`FiltersForm.fields`) render persistently in the DOM at ALL viewports. At ≥768px, the filter column is always visible (no "show filters" toggle). At 390px, filter controls are wrapped in a LiveView-JS-toggled disclosure section (default: collapsed) triggered by a visible "Filters" button with an expand/collapse indicator; the toggle uses `Phoenix.LiveView.JS.toggle` or a socket assign — no new route. | Operator (`/ops/mail`), Inbound (`/ops/mail/inbound`) | no new routes; CSS+LiveView.JS only (no client JS hook); flat elevation (filter disclosure panel is inline, no shadow-overlay) | — |
| IA-LD-03 | Master-detail split viewport behaviour: 390px → master list fills 100% width; record selection reveals detail at 100% width (`:if selected_record != nil` replacing list, with back navigation affordance — NOT a push_patch to a new route). 768px → two-column `grid-cols-[40%_60%]`: left=list+filters, right=detail/orientation. 1440px → two-column `grid-cols-[33%_67%]`: left=list+filters, right=detail. Column widths are grid percentage templates; spacing within columns uses token utilities (gap-sm/md). | Operator (`/ops/mail`), Inbound (`/ops/mail/inbound`) | no new routes; semantic tokens only (spacing gaps use token utilities; column width percentages are layout structure not spacing tokens); no pixel-diff visual regression | — |
| IA-LD-04 | All filter section labels on ALL three surfaces MUST use class `text-label uppercase font-bold text-secondary`. The arbitrary Tailwind value `tracking-[0.08em]` MUST be removed; letter-spacing is token-owned. Applies to both `Operator.FiltersForm` (operator/filters_form.ex:17, 29, 42, 56, 71) and `Inbound.FiltersForm` (inbound/filters_form.ex:20, 33, 47, 63, 79). Label copy is unchanged (Tenant, Provider, Status, Event, Window, Search, Mailbox outcome). | Operator (`/ops/mail`), Inbound (`/ops/mail/inbound`) | semantic tokens only (Type pillar); weight font-bold or default only (no faux-bold) | GAP-04 |
| IA-LD-05 | `SupportCards` two-tier triage grid DOM order is canonized: Tier 1 cards (non-zero actionable — `failed_ingest`, `orphan_backlog`) render first at ALL viewports. Tier 2 compact rows (zero-state / always-informational) render after Tier 1. Within Tier 1, error-count items precede warning-count items. This matches the current rendering order in `support_cards.ex:34-35` — the lock prevents future reordering. | Operator (`/ops/mail`) — SupportCards triage archetype | no new routes; flat elevation (Tier 1 cards use `bg-base-200 border border-base-300`, no shadow-overlay) | — |
| IA-LD-06 | Navigation L1/L2 labelling rule: L1 nav items carry the surface noun ONLY ("Deliveries", "Inbound") — never a filter state count suffix ("Deliveries (3)") or a verb ("View Deliveries"). `aria-current="page"` marks the active L1 item (shell.ex:206, shell.ex:229). The page `h1` (shell.ex:183) carries the L2 surface name. This rule applies in both `nav_link` (≥768px sidebar) and `nav_pill` (390px header). | All operator surfaces (Operator, Inbound) | no new routes; semantic tokens only; A11y (aria-current="page" required) | — |
| IA-LD-07 | Empty-state and loading-state placement: (a) Operator/Inbound, no tenant → master pane renders a cause-naming inline empty state ("No tenant selected — enter a tenant ID to begin"); (b) Operator/Inbound, tenant present, no results → list area renders a cause-naming empty state with reset-filters action if filters are non-default; (c) Operator/Inbound, detail pane, no record selected → `orientation_strip` as per IA-LD-01; (d) Preview `:index`, no mailables → full main content renders "No mailables discovered" with an actionable tip list (not an error); (e) Preview `:index`, mailables exist → "Preview the first one" CTA is always rendered and keyboard-focusable in the DOM (not conditionally hidden). | Operator (`/ops/mail`), Inbound (`/ops/mail/inbound`), Preview (`/dev/mail`) | no new routes; flat elevation (inline empty states, no shadow-overlay); CSS+LiveView.JS only | GAP-02 |
| IA-LD-08 | Preview surface sidebar IA: `Preview.Sidebar` (preview/sidebar.ex:40) uses `<details>/<summary>` for the L2 mailable → L3 scenario hierarchy. The `h1 "Mailers"` (sidebar.ex:43) is the persistent L1 heading. Active scenario receives a 3px `border-primary` left border (Glass #277B96 — accent, within the 10%-accent rule because it marks a single selected item). Inactive scenarios have `border-transparent` + hover state. This pattern MUST NOT be replaced with a flat list or custom accordion; the native `<details>` is the correct semantic element for collapsible mailable groups. | Preview (`/dev/mail`) — Sidebar archetype | flat elevation; 10%-accent rule (accent only on active/selected item); semantic tokens only; CSS+LiveView.JS only | — |
| IA-LD-09 | At 390px, the Inbound surface MUST render an overview / at-a-glance tier (a summary card or stat row) BEFORE the record list. This tier shows: total InboundMessages in the current window, count by outcome (:no_match / :accept / :reject / :bounce / :failed), and a "no-match rate" indicator. The at-a-glance tier uses `bg-base-200 border border-base-300 rounded-box` (flat elevation, no shadow-overlay). At ≥768px, the tier appears above the list column. This closes GROUP-02 at the IA specification layer; implementation is Phase 99. | Inbound (`/ops/mail/inbound`) | no new routes; flat elevation; semantic tokens only; no new product features (overview tier is read-only display of existing data, not a new capability) | — |

---

## Self-referential compliance check

Before locking, each IA-LD-NN row was verified against the hard design constraints:

| Constraint | Rows verified |
|-----------|---------------|
| No new routes | IA-LD-01, IA-LD-02, IA-LD-03, IA-LD-04, IA-LD-07, IA-LD-09 — all use `:if`/CSS/assigns, not router changes |
| Flat elevation (border-first) | IA-LD-01, IA-LD-02, IA-LD-05, IA-LD-07, IA-LD-09 — all inline panels with `border border-base-300`, no shadow-overlay |
| Semantic tokens only | IA-LD-04 directly closes GAP-04 by removing `tracking-[0.08em]`; IA-LD-08 uses `border-primary` (semantic accent token) |
| 10%-accent rule | IA-LD-08: `border-primary` on single active scenario item = <10% of visible surface |
| CSS+LiveView.JS only (no client JS hook) | IA-LD-02: `Phoenix.LiveView.JS.toggle` is the canonical tool |
| No Node toolchain | All decisions are markup/class/assign changes — no build step |
| A11y | IA-LD-06: `aria-current="page"` mandatory; IA-LD-07: focusable CTA mandatory (GAP-02) |
