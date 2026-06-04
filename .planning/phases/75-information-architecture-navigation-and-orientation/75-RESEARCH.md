# Phase 75: Information Architecture, Navigation and Orientation — Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView frontend (mailglass_admin) + one additive core Elixir read-model function
**Confidence:** HIGH — all anchor claims verified against live source files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Extract `orientation_strip/0` defp (`operator_live.ex:362`) into public `Shell.orientation_strip/1`, placed after `flash_region/1` in `shell.ex`.
- D-02: Single `attr :surface, :atom, values: [:deliveries, :inbound, :preview]` discriminator with frozen per-surface copy baked in.
- D-03: Root testids `{surface}-orientation` per surface.
- D-04: Render triggers unchanged: Deliveries `is_nil(@selected_delivery)`, Inbound `is_nil(@detail)`, Preview `@mailables == []`.
- D-05: No motion on orientation strip (always-visible, not action-triggered).
- D-06: Orientation strip supplements (does not replace) `preview_live.ex:291-323` existing empty state. Preserve `preview-empty-mailables` testid and adopter router hint.
- D-07: Zero router change. Overview is a params-based branch inside `handle_params/3` at `operator_live.ex:71`. `live_action` stays `:index`.
- D-08: `?view=deliveries` query param discriminates Overview vs Deliveries list. Bare `/ops/mail/` → Overview. `?view=deliveries` → Deliveries list (set via `push_patch`). `tenant_id` stays orthogonal.
- D-09: No `tenant_id` → orientation strip + nudge "Select a tenant to see health at a glance."; with `tenant_id` → health-count row.
- D-10: Overview layout frozen: h1 "Operator overview" → orientation strip → h2 "Health" → 4 compact health-count cards → h2 (navigation) → 2 full-width navigation cards.
- D-11: Add `count_active_suppressions/1` to core `mailglass` at `lib/mailglass/operator/suppressions.ex`, mirroring active-entry filter.
- D-12: Suppression count read via runtime-module-indirection seam (like `support_summary_module/0`); degrades to neutral `—` on missing/error.
- D-13: Cross-package acknowledgment: Phase 79 release produces matched bumps. Expected.
- D-14: Existing surface titles conformant; new heading is Overview h1 "Operator overview".
- D-15: Heading assertion edits in `operator.spec.js` and `demo.spec.js` ship in the **same commit** as IA changes.
- D-16: Phase 75 a11y confined to new Overview: `aria-current="page"` on active nav + h1/h2 hierarchy. Do not front-run Phase 76 modal a11y.
- D-17: DEFER GAP-22 (deep-link unstyled CSS) to Phase 79 (VERIF-04). Documentation artifact only. GAP-22 held at severity 3.
- D-18: 390px acceptance via local screenshot→LLM-critique ritual + extend existing Playwright 390px structural test to assert orientation strip visible at 390px.

### Claude's Discretion
- Exact internal structure of per-surface copy table inside `orientation_strip/1` (case/map/function-clause).
- Precise HEEx markup of Overview health-count and navigation cards within locked layout and token rules.
- Whether `?view=deliveries` is query param vs sentinel filter value (query param recommended).
- Exact wording of any new Overview subtitle (within IA vocabulary + copywriting voice).

### Deferred Ideas (OUT OF SCOPE)
- Unified `status_badge/1` atom + 5 `badge_class/1` deletions — Phase 76.
- Support-card primary/secondary hierarchy restructure — Phase 76.
- Motion-reveal re-fire fix — Phase 77.
- Global token migration (type + spacing) + committed bundle — Phase 76.
- Robust deep-link asset fix — Phase 79.
- CI-promoted visual regression / LLM-critique automation — VR-NEXT-01.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IA-01 | Deliveries, Inbound, and Preview each render the **shared shell-level orientation strip** with per-surface content (generalized from the Deliveries-only original at `operator_live.ex`) | Anchor verified: private `defp orientation_strip/0` at `operator_live.ex:362`; `flash_region/1` placement anchor at `shell.ex:278`; inbound trigger `is_nil(@detail)` at `inbound_live.ex:330`; Preview `@mailables == []` at `preview_live.ex:291`. |
| IA-02 | Operator landing on `/ops/mail/` reaches a task-oriented **Operator Overview** (params-branch on existing OperatorLive, no router-macro change) surfacing at-a-glance health | `handle_params/3` at `operator_live.ex:71` confirmed; `support_summary_module/0` at `operator_live.ex:670` confirmed as indirection seam; `summarize_tenant/1` at `support_summary.ex:21` confirmed returning `failed_ingest` + `orphan_backlog`; `count_active_suppressions/1` confirmed ABSENT from `suppressions.ex` (only `get_delivery_suppression_state/2` exists). |
| IA-03 | Page titles, subtitles, and headings follow **one deliberate IA vocabulary** with `operator.spec.js` + demo specs updated in the **same change** | `operator.spec.js:19` heading assertion `"Deliveries"` confirmed; `demo.spec.js:28` `"Deliveries"` confirmed; `demo.spec.js:42` `"Inbound records"` confirmed; `operator.spec.js:32,34` `operator-empty-detail` testid confirmed as ripple casualty. Full ripple table in §Validation Architecture. |
| IA-04 | The deep-link-unstyled-CSS fix carries an **explicit, recorded in-scope/deferred decision** | Decision recorded: DEFER GAP-22 to Phase 79 (VERIF-04). Documentation deliverable only — no code change. GAP-22 held at sev 3. |
</phase_requirements>

---

## Summary

Phase 75 is the first build phase of v1.7. It has four deliverables: (1) generalize the private Deliveries-only `orientation_strip/0` into a public `Shell.orientation_strip/1` rendered on all three surfaces with frozen per-surface copy; (2) add an Operator Overview landing as a params-based branch inside the existing `handle_params/3`, plus one additive core `count_active_suppressions/1` function; (3) normalize IA vocabulary and update heading assertions in both e2e specs in the same commit; (4) record the deep-link GAP-22 deferral decision as a documentation artifact.

The CONTEXT.md and UI-SPEC are exceptionally well specified. Research focus is therefore on: (a) anchor verification (every file:line reference confirmed against live code), (b) the exact mechanics of the params-based Overview branch and same-commit e2e ripple, and (c) the Validation Architecture required for Nyquist Dimension 8.

The single cross-package change — adding `count_active_suppressions/1` to `lib/mailglass/operator/suppressions.ex` — is confirmed additive (function is absent; only `get_delivery_suppression_state/2` exists). The active-entry filter pattern it will mirror is verified at lines 27-28 of that file.

**Primary recommendation:** Follow the CONTEXT.md D-01..D-18 decisions exactly. The highest-risk execution task is the same-commit e2e update: tests 1–5 all run `openOperator()` which asserts the `"Deliveries"` heading at line 19, so all five tests will fail if the heading assertion is not updated in the same commit as the IA change. The `operator-empty-detail` testid (line 32) is a secondary ripple.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Orientation strip UI | Frontend Server (LiveView) | — | HEEx function component in shell.ex; no data, pure chrome |
| Overview landing routing | Frontend Server (LiveView) | — | `handle_params/3` branch; same LiveView process, no new route |
| Health-count data (failed_ingest, orphan_backlog) | API / Backend (core read-model) | Frontend Server | `SupportSummary.summarize_tenant/1` in core; admin reads via indirection seam |
| Suppression count data | API / Backend (core read-model) | Frontend Server | New `count_active_suppressions/1` in core; admin reads via indirection seam (D-12 degradation) |
| e2e heading assertions | Frontend Server (Playwright) | — | Structural assertions; update in same commit as HEEx changes |
| GAP-22 disposition | Documentation | — | Decision artifact; no code tier |

---

## Standard Stack

No new packages in this phase. This is a pure application phase within the existing stack.

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| Phoenix LiveView | ~> 1.1 (1.1.x) | LiveView components, `handle_params/3`, `push_patch/2` | Already installed |
| Tailwind CSS standalone | 4.1.12 | JIT compilation; token utilities | Already installed |
| daisyUI 5 | 5.x vendored | `card`, `btn`, `btn-primary`, `rounded-box`, `border` | Already installed; classes verified against `assets/vendor/daisyui.js` |
| Heroicons | vendored | `hero-lifebuoy` (orientation strip leading icon) | Already installed |
| Playwright | (CI) | e2e structural assertions | Already installed |

**Installation:** none required.

## Package Legitimacy Audit

Not applicable — no new packages installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser: GET /ops/mail/                    Browser: GET /ops/mail/?view=deliveries
         (no ?view param)                            (?view=deliveries)
              |                                              |
              v                                              v
OperatorLive.handle_params/3  ──────────────────────────────┘
  |
  ├─ view == nil (or absent)  →  Overview branch
  │     |
  │     ├─ tenant_id blank?  →  orientation strip + "Select a tenant..." nudge
  │     └─ tenant_id set?    →  orientation strip
  │                              + call support_summary_module().summarize_tenant/1
  │                              + call suppression_count_module().count_active_suppressions/1
  │                              + health-count row (4 cards)
  │                              + navigation cards (push_patch to ?view=deliveries / navigate to /inbound)
  │
  └─ view == "deliveries"  →  existing Deliveries master-detail render
        |
        └─ orientation strip: Shell.orientation_strip surface={:deliveries}
                              (when is_nil(@selected_delivery))

InboundLive.render/1:
  └─ is_nil(@detail)?  →  Shell.orientation_strip surface={:inbound}

PreviewLive.render/1:
  └─ @mailables == []?  →  Shell.orientation_strip surface={:preview}
                           + preserved preview-empty-mailables empty state (D-06)

Core mailglass:
  Mailglass.Operator.Suppressions.count_active_suppressions/1  [NEW — additive]
  Mailglass.Operator.SupportSummary.summarize_tenant/1         [EXISTING — no change]
```

### Recommended Project Structure

No new files. All changes are within existing modules:

```
mailglass_admin/lib/mailglass_admin/
├── operator/shell.ex          ← ADD Shell.orientation_strip/1 (public) after flash_region/1
├── operator_live.ex           ← REMOVE defp orientation_strip/0 (line 362-392)
│                                 MODIFY handle_params/3 (line 71) — add ?view branch
│                                 ADD Overview render branch
├── inbound_live.ex            ← ADD Shell.orientation_strip call in empty-detail branch (line ~330)
├── preview_live.ex            ← ADD Shell.orientation_strip call alongside preview-empty-mailables
├── e2e/operator.spec.js       ← UPDATE heading assertions (same commit as IA change)
lib/mailglass/operator/
└── suppressions.ex            ← ADD count_active_suppressions/1 (additive, no change to existing)
reference/demo_app/assets/e2e/
└── demo.spec.js               ← UPDATE heading assertions (same commit as IA change)
```

### Pattern 1: params-based Overview branch in handle_params/3

The existing `handle_params/3` at `operator_live.ex:71` runs on every navigation. The Overview branch is added by inspecting `params["view"]`:

```elixir
# operator_live.ex handle_params/3 — add overview discriminator
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)
  support_state = normalize_support_state(params)
  view = params["view"]  # nil = Overview, "deliveries" = list

  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator")
   |> assign(:page_uri, uri)
   |> assign(:dark_chrome, MailglassAdmin.Operator.Shell.dark_chrome?(params))
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))
   |> assign(:support_state, support_state)
   |> assign(:view, if(view == "deliveries", do: :deliveries, else: :overview))
   |> assign_delivery_state_or_overview(filter_params, params, view)}
end
```

The render function branches on `@view`:

```elixir
# render — Overview branch (no @selected_delivery needed)
<%= if @view == :overview do %>
  <.overview_landing
    filter_params={@filter_params}
    support_summary={@support_summary}
    suppression_count={@suppression_count}
    paths={%{deliveries: build_path(@base_path, @filter_params, nil, @dark_chrome) <> "&view=deliveries",
              inbound: ...}}
  />
<% else %>
  ... existing Deliveries render ...
<% end %>
```

The "View Deliveries" CTA uses `push_patch` to `?view=deliveries` (preserving `tenant_id`).
[VERIFIED: operator_live.ex:71-84 — existing handle_params/3 structure confirmed]

### Pattern 2: Shell.orientation_strip/1 public component

Extracted from the private `defp orientation_strip/0` at `operator_live.ex:362-392`. Placed after `flash_region/1` (confirmed at `shell.ex:278`):

```elixir
# shell.ex — new public component, placed after defp flash_region/1
attr :surface, :atom, values: [:deliveries, :inbound, :preview], required: true

def orientation_strip(assigns) do
  {heading, tips} = copy_for(assigns.surface)
  assigns = assign(assigns, heading: heading, tips: tips,
                   testid: "#{assigns.surface}-orientation")
  ~H"""
  <div
    class="rounded-box border border-base-300 bg-base-200 p-md"
    data-testid={@testid}
  >
    <div class="flex items-start gap-sm">
      <Components.icon name="hero-lifebuoy" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
      <div class="min-w-0">
        <h2 class="text-body font-bold text-base-content">{@heading}</h2>
        <ul class="mt-2 grid gap-1 text-label text-secondary">
          <%= for tip <- @tips do %>
            <li><%= tip %></li>
          <% end %>
        </ul>
      </div>
    </div>
  </div>
  """
end
```

Note: `text-label` replaces the existing raw `text-sm` at `operator_live.ex:372` — the shared component is born token-clean (per UI-SPEC § Typography carry-over). This is intentional and noted in the plan tasks.
[VERIFIED: operator_live.ex:362-392 — private defp confirmed; shell.ex:278 — flash_region/1 confirmed]

### Pattern 3: count_active_suppressions/1 in core suppressions.ex

```elixir
# lib/mailglass/operator/suppressions.ex — additive, after get_delivery_suppression_state/2
@spec count_active_suppressions(String.t()) :: non_neg_integer()
def count_active_suppressions(tenant_id) when is_binary(tenant_id) and tenant_id != "" do
  now = Clock.utc_now()

  Entry
  |> where([entry], entry.tenant_id == ^tenant_id)
  |> where([entry], is_nil(entry.expires_at) or entry.expires_at > ^now)
  |> Tenancy.scope(tenant_id)
  |> Repo.aggregate(:count, :id)
end
```

The active-entry filter pattern is directly mirrored from `get_delivery_suppression_state/2` lines 27-28 (confirmed: `entry.tenant_id == ^tenant_id` + `is_nil(entry.expires_at) or entry.expires_at > ^now`).
[VERIFIED: suppressions.ex:18-53 — existing function and filter pattern confirmed; count_active_suppressions/1 confirmed ABSENT]

### Pattern 4: runtime-module-indirection seam for suppression count

Mirror of `support_summary_module/0` at `operator_live.ex:670`:

```elixir
# operator_live.ex — add alongside support_summary_module/0
defp suppression_count_module, do: :"Elixir.Mailglass.Operator.Suppressions"

# In assign_overview_health/2:
suppression_count =
  try do
    apply(suppression_count_module(), :count_active_suppressions, [tenant_id])
  rescue
    _ -> nil  # degrades to "—" in render (D-12)
  end
```

The `nil` or error case renders as `—` in `text-secondary` on the Overview health card (D-12).
[VERIFIED: operator_live.ex:670 — support_summary_module/0 confirmed as indirection seam pattern]

### Anti-Patterns to Avoid

- **Adding `:overview` to `Shell.attr :active` values**: The Overview IS the Deliveries surface root — pass `active={:deliveries}`. Adding `:overview` creates a ghost nav concept. [VERIFIED: shell.ex:102 — attr :active, values: [:deliveries, :inbound]]
- **Touching the router macro**: `router.ex:261` is `live "/", MailglassAdmin.OperatorLive, :index`. Do not add a second `live "/"` route. [VERIFIED: router.ex:261-270]
- **Replacing `preview-empty-mailables`**: The Preview orientation strip supplements the existing empty state; `preview-empty-mailables` testid at `preview_live.ex:293` must survive. [VERIFIED: preview_live.ex:293]
- **Front-running GAP-13/14 support-card restructure**: Phase 75 only renders at-a-glance count numbers on compact health-count cards. No support-card hierarchy change.
- **Front-running GAP-19 motion**: No `motion-reveal` or `phx-mounted` on the orientation strip (D-05, always-visible).
- **Splitting e2e spec updates into a separate commit**: All five `operator.spec.js` tests will fail if `openOperator()` line 19 assertion is not updated in the same commit.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Active suppression count | Raw Repo query in admin layer | `Mailglass.Operator.Suppressions.count_active_suppressions/1` in core | Read-model boundary rule (operator_live.ex moduledoc: "all data access stays behind core operator read-model modules") |
| Module indirection for graceful degradation | try/rescue directly in render | Mirror `support_summary_module/0` pattern | Consistent seam; tested failure mode |
| Navigation path construction | Ad-hoc string building | `build_path/4` (already in operator_live.ex) | Existing tested path-builder; carries `dark_chrome` + `tenant_id` correctly |
| Flash region | New flash component | `Shell.flash_region/1` (already in shell.ex:278) | Already used; no duplication |

---

## Anchor Verification Report

Every file:line reference from CONTEXT.md verified against the live codebase as of the current `main` branch (1.4.5):

### operator_live.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| `defp orientation_strip/0` | line 362 | **CONFIRMED** | Lines 362-392. Private defp, no args (takes `assigns` implicitly via ~H). The current heading is **"Start from the customer symptom"** — this WILL be replaced with the frozen "Deliveries" heading per UI-SPEC. |
| Orientation render trigger | `is_nil(@selected_delivery)` at line 254 | **CONFIRMED** | Line 254: `<div :if={is_nil(@selected_delivery)} class="mb-lg">` |
| Orientation call site | `<.orientation_strip />` | **CONFIRMED** | Line 255 |
| `handle_params/3` | line 71 | **CONFIRMED** | Lines 71-85. Currently calls `normalize_filter_params`, `normalize_support_state`, then assigns state. No `view` discriminator present — must be added. |
| `support_summary_module/0` | line 670 | **CONFIRMED** | Line 670: `defp support_summary_module, do: :"Elixir.Mailglass.Operator.SupportSummary"` |
| `load_deliveries/1` | `%{"tenant_id" => ""} -> []` | **CONFIRMED** | Line 417: `defp load_deliveries(%{"tenant_id" => ""}), do: []` |
| `load_support_summary/2` | line 660 | **CONFIRMED** | Lines 660-668. Second clause (with selected_delivery) calls `apply(support_summary_module(), :summarize_tenant, [...])` |

**IMPORTANT DISCOVERY**: The orientation strip is `defp orientation_strip(assigns)` (takes `assigns` as a function component via HEEx `<.orientation_strip />`), not `defp orientation_strip/0` as the CONTEXT claims. The arity is 1 (assigns), consistent with Phoenix function components. This is a naming convention difference only; the extraction is straightforward.

**COPY CHANGE REQUIRED**: The live `operator_live.ex:362` heading is `"Start from the customer symptom"` with verbose bullets. The UI-SPEC mandates replacement with the terse `"Deliveries"` heading and frozen bullets. This is a content change, not a pure extraction.

**Existing testid**: The live `orientation_strip` has `data-testid="operator-orientation"` (line 367). This will be replaced with `data-testid="deliveries-orientation"` (D-03). The `74-ASSERTION-INVENTORY.md` confirms no e2e assertion currently references `operator-orientation` — this change is safe.

### shell.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| `attr :active` discriminator | line 102 | **CONFIRMED** | Line 102: `attr :active, :atom, values: [:deliveries, :inbound], required: true` |
| `flash_region/1` placement anchor | `defp flash_region/1` at shell.ex | **CONFIRMED** | Lines 278-302. `defp flash_region(assigns)`. The new `Shell.orientation_strip/1` goes AFTER this function (i.e., after line 302). |
| `aria-current="page"` in nav_link | shell.ex:205,229 (UI-SPEC claim) | **CONFIRMED** | Lines 205 and 229: both `nav_link/1` (line 205) and `nav_pill/1` (line 229) already carry `aria-current={@active && "page"}`. When Overview passes `active={:deliveries}`, the "Deliveries" nav item correctly resolves `aria-current="page"`. No change needed for D-16. |

### inbound_live.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| Empty-detail trigger `is_nil(@detail)` | line 330 | **CONFIRMED** | Line 330: `<% is_nil(@detail) -> %>` — this is inside the `cond do` block. The orientation strip call goes inside this branch, replacing/augmenting the existing empty-detail div at lines 331-338. |
| `title="Inbound records"` | inbound_live.ex:271 | **CONFIRMED** | Line 271 (in render): `title="Inbound records"` passed to Shell.shell. Unchanged. |

### preview_live.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| Empty state `@mailables == []` at line 291 | **CONFIRMED** | Line 291: `<% @mailables == [] -> %>` inside `cond do`. |
| `preview-empty-mailables` testid at line 291-323 | **CONFIRMED** | Line 293: `data-testid="preview-empty-mailables"`. The empty state spans lines 292-323. The orientation strip renders ALONGSIDE this (D-06 supplement, not replace). Render order: orientation strip first (above), then preserved empty state below — or interspersed. Planner's discretion. |

**NOTE**: The existing `preview-empty-mailables` heading is `"No mailables discovered"` (line 297), NOT `"No mailables found."` (frozen copy). The frozen blank-slate copy in UI-SPEC says "No mailables found." — this is a discrepancy. Phase 75 must NOT change the existing empty-state heading (D-06: preserve it). The frozen copy for the orientation strip bullets uses "No mailables found?" (question form) — distinct from the empty-state heading. No conflict: the orientation bullet is a question prompt; the preserved empty-state heading stays `"No mailables discovered"`.

### router.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| `live "/", OperatorLive, :index` at line 261 | **CONFIRMED** | Line 261: `live "/", MailglassAdmin.OperatorLive, :index` |
| `live "/inbound", InboundLive, :index` at line 270 | **CONFIRMED** | Line 270: `live "/inbound", MailglassAdmin.InboundLive, :index` (inside `if Code.ensure_loaded?...`) |
| No `:overview` action | **CONFIRMED** | Verified absent. Single `:index` action per LiveView. |

### suppressions.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| `get_delivery_suppression_state/2` at line 18 | **CONFIRMED** | Lines 17-53. The active-entry filter is at lines 27-28: `where([entry], entry.tenant_id == ^tenant_id)` + `where([entry], is_nil(entry.expires_at) or entry.expires_at > ^now)` |
| `count_active_suppressions/1` absent | **CONFIRMED** | The module contains only `get_delivery_suppression_state/2` and private helpers. No count function exists. |
| `Tenancy.scope/2` used in existing filter | **CONFIRMED** | Line 50: `|> Tenancy.scope(tenant_id)` |

**NOTE**: CONTEXT D-11 references `suppressions.ex:26-28` for the active-entry filter. The actual active-entry where clauses are at lines 27-28 in the live file. Line 26 is the `Entry` base query. Trivial line-number drift — the pattern is correct.

### support_summary.ex

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| `summarize_tenant/1` at line 29-34 | **CONFIRMED** (with offset) | `summarize_tenant/1` at line 21. Returns map with `:failed_ingest` → `%{count:, latest:}` and `:orphan_backlog` → `%{count:, oldest:, oldest_age_seconds:}`. CONTEXT claim of lines 29-34 refers to the return map definition inside the function, which aligns. |
| Returns `failed_ingest.count` + `orphan_backlog.count` | **CONFIRMED** | Both `:failed_ingest` and `:orphan_backlog` keys are present with `:count` fields. |

### operator.spec.js

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| Heading assertion `"Deliveries"` in `openOperator` | line 19 | **CONFIRMED** | Line 19: `await expect(page.getByRole("heading", { name: "Deliveries", exact: true })).toBeVisible();` — runs for ALL 5 tests. |
| `operator-empty-detail` testid visible | lines 32, 34 | **CONFIRMED** | Lines 32-34: `emptyDetail = page.getByTestId("operator-empty-detail")`, `await expect(emptyDetail).toBeVisible()`. |
| 390px structural test | lines 64-89 | **CONFIRMED** | Test 2: `page.setViewportSize({ width: 390, height: 844 })`, tests list-before-detail stacking. No orientation-strip assertion currently. |

### demo.spec.js

| Symbol | CONTEXT claim | Verified? | Actual location |
|--------|---------------|-----------|-----------------|
| `"Deliveries"` heading | line 28 | **CONFIRMED** | Line 27: `await expect(page.getByRole("heading", { name: "Deliveries", exact: true })).toBeVisible()` |
| `"Inbound records"` heading | line 42 | **CONFIRMED** | Line 41: `await expect(page.getByRole("heading", { name: "Inbound records", exact: true })).toBeVisible()` |
| `"Northstar Ops"` heading at line 15 | **CONFIRMED** | Line 15: host app's own dashboard heading — out of scope for IA-03 per D-15. |
| demo.spec.js navigates to `/ops/mail?tenant_id=northstar` before the Deliveries heading | **CONFIRMED** | Line 26: `await page.getByRole("link", { name: /outbound operator/i }).click()` + URL check — the URL includes `tenant_id=northstar`. With the Overview as the new landing, this navigation lands on the Overview, not the Deliveries list. The heading will be "Operator overview", not "Deliveries". The demo test must therefore either: (a) navigate further to `?view=deliveries` before asserting "Deliveries", OR (b) update the assertion to "Operator overview". Option (b) is simpler and correct given the test verifies the operator surfaces open. |

---

## Mechanics the Planner Must Get Right

### M-1: params-based Overview vs Deliveries branch

The branch lives entirely in `handle_params/3` (`operator_live.ex:71`). The `live_action` is `:index` throughout — no Phoenix action change. The discriminator is `params["view"]`:

- **Bare `/ops/mail/`** (no `view` param, no `delivery_id`) → `@view = :overview`
- **`/ops/mail/?view=deliveries`** (set by the Overview's "View Deliveries" CTA via `push_patch`) → `@view = :deliveries`
- **`/ops/mail/?delivery_id=X`** (deep link to specific delivery — normal existing flow) → `@view = :deliveries` (the Deliveries list handles `delivery_id` selection)

The Overview CTAs use:
```elixir
# "View Deliveries" CTA push_patch target
to: build_path(@base_path, @filter_params, nil, @dark_chrome) <> "&view=deliveries"
# OR: preserve tenant_id correctly:
to: "#{@base_path}?tenant_id=#{@filter_params["tenant_id"]}&view=deliveries"
```

The "View Inbound" CTA uses `navigate` (not `push_patch`) to `@inbound_path` — the existing inbound route.

**Key insight**: `tenant_id` must be orthogonal to `view`. An operator at `/ops/mail/?tenant_id=acme` is on the Overview for tenant `acme`; the health row renders. Clicking "View Deliveries" navigates to `/ops/mail/?tenant_id=acme&view=deliveries`. The `tenant_id` passes through.

### M-2: `assign_delivery_state` and the Overview

The existing `handle_params` calls `assign_delivery_state/3` which calls `load_deliveries/1` → returns `[]` when `tenant_id` is blank. For the Overview, the planner should conditionally skip `assign_delivery_state` (or call a new `assign_overview_state/2`) when `view != "deliveries"`. Loading deliveries on every Overview page load is wasteful. The existing `load_support_summary/2` at line 658 requires `_selected_delivery` to be non-nil — on the Overview, we call it directly with the `filter_params` (no `selected_delivery`).

**Existing `load_support_summary/2` signatures:**
- `defp load_support_summary(_filter_params, nil), do: nil` (line 658) — returns nil when no selected delivery
- `defp load_support_summary(filter_params, _selected_delivery)` (line 660) — calls summarize_tenant

For the Overview, we need the summary even without a selected delivery. The plan should call `summarize_tenant` directly on the Overview branch (not via the existing two-clause function), or add a third-clause match.

### M-3: Same-commit e2e ripple — all 5 tests affected

The `openOperator` helper at lines 13-21 is called at the start of EVERY test. It navigates to `/ops/mail?tenant_id=browser-tenant` and asserts `"Deliveries"` heading. After Phase 75, this navigation lands on the Overview (bare root with `tenant_id`), not the Deliveries list.

**Strategy for keeping all 5 tests green:**

Option A (recommended): Update `openOperator` to assert `"Operator overview"` heading on landing, then `push_patch` to `?view=deliveries` before proceeding with delivery-specific assertions in each test. Tests 3, 4, 5 (replay flows) require a delivery to be selected — they must navigate to Deliveries first.

Option B: After login, navigate explicitly to `?view=deliveries` in `openOperator` before asserting any heading.

The plan must specify the chosen strategy. Option A is cleanest: the helper reflects the real user journey (land on Overview → navigate to Deliveries).

**Specific assertion changes needed (same commit):**

| File:line | Current assertion | Required change |
|-----------|-------------------|-----------------|
| `operator.spec.js:19` | `"Deliveries"` heading in `openOperator` | Change to `"Operator overview"` on landing, then navigate to `?view=deliveries` for delivery-centric tests |
| `operator.spec.js:32-34` | `operator-empty-detail` visible on initial load | This testid moves: after navigating to `?view=deliveries` (no selection), `operator-empty-detail` still exists in the Deliveries detail column. The assertion stays valid IF the helper navigates to `?view=deliveries` first. |
| `demo.spec.js:27-28` | `"Deliveries"` heading after clicking "outbound operator" link | The link goes to `/ops/mail?tenant_id=northstar` → now lands on Overview. Either: (a) add a `?view=deliveries` param to the demo dashboard link, OR (b) update assertion to `"Operator overview"` + add navigation to Deliveries before asserting `operator-deliveries-list`. |
| `demo.spec.js:41-42` | `"Inbound records"` heading | Route is `/ops/mail/inbound?tenant_id=northstar`. This navigates to InboundLive which renders `title="Inbound records"` — UNCHANGED. No update needed unless the page `<h1>` is somehow affected. |

**GAP-register mis-tag note (from CONTEXT:76):** `74-GAP-REGISTER.md` line 193 summary row lists GAP-13/GAP-19 under IA-01. GAP-13 = Phase 76 (support-card restructure); GAP-19 = Phase 77 (motion re-fire). Phase 75 orientation/route work cites GAP-07, GAP-09, GAP-11, GAP-21, GAP-22 only. Do not pull GAP-13/GAP-19 tasks into Phase 75.

### M-4: runtime-module-indirection for suppression count

The indirection seam (`defp suppression_count_module, do: :"Elixir.Mailglass.Operator.Suppressions"`) is necessary so that if the `mailglass` core package is somehow unavailable or the function errors, the Overview degrades gracefully (renders `—`) rather than crashing the LiveView. The `try/rescue` block is the standard pattern for optional-dep graceful degradation in this codebase. Suppression health color is `text-secondary` (informational), so a neutral `—` is visually consistent.

### M-5: Bundle rebuild gate

Phase 75 introduces new HEEx classes on the Overview and orientation strip. All classes used must be already in the JIT scan scope or currently present. The key new classes:
- From the token scale (already in `@theme`): `gap-sm`, `gap-md`, `gap-lg`, `p-md`, `text-label`, `text-body`, `text-heading`, `text-display`
- From daisyUI 5 (already vendored): `card`, `btn`, `btn-primary`, `btn-sm`, `rounded-box`, `border-base-300`
- Color semantics (already in daisyUI theme): `text-error`, `text-warning`, `text-success`, `text-secondary`, `bg-base-200`

Since `lib/` is already a `@source` path in `app.css`, any new `.ex` file using these classes is auto-scanned. **The bundle must be rebuilt and the updated `priv/static/app.css` committed in the same PR** as any HEEx class change. Run `mix mailglass_admin.assets.build` from the `mailglass_admin/` directory.

`text-label` is new on the orientation strip (replacing `text-sm`). Confirm it is in the `@theme` token scale in `app.css` before using it. It is confirmed present per STACK.md.

---

## Common Pitfalls

### Pitfall 1: Splitting the e2e update from the IA commit

**What goes wrong:** The heading change in `operator_live.ex` and the `operator.spec.js`/`demo.spec.js` updates go into separate commits or PRs. Playwright CI fails between those commits because `openOperator()` asserts `"Deliveries"` but the landing now shows `"Operator overview"`.
**Why it happens:** The spec files are in different directories; it feels like "separate concerns."
**How to avoid:** IA-03 mandate: same commit. The plan must group the HEEx change + both spec updates into a single wave task.
**Warning signs:** A PR touching `operator_live.ex` handle_params that does not also modify `operator.spec.js` and `demo.spec.js`.

### Pitfall 2: `tenant_id` lost when navigating to Deliveries from Overview

**What goes wrong:** The "View Deliveries" CTA navigates to `?view=deliveries` without carrying the `tenant_id`. The operator arrives at the Deliveries list with no tenant selected, sees no deliveries.
**How to avoid:** The `push_patch` target for "View Deliveries" must preserve `tenant_id`: `?tenant_id=#{filter_params["tenant_id"]}&view=deliveries` or built via `build_path/4` with `view=deliveries` appended.

### Pitfall 3: `defp orientation_strip/0` name confusion

**What goes wrong:** The CONTEXT calls it `orientation_strip/0` but it is actually a Phoenix function component `defp orientation_strip(assigns)` (arity 1). The extraction produces `Shell.orientation_strip/1` — correct. The confusion is cosmetic but could lead to a misreported arity in plan task descriptions.
**How to avoid:** Use the correct arity `Shell.orientation_strip/1` (the `assigns` argument is implicit for function components but counts for `defp` arity).

### Pitfall 4: Front-running GAP-13 support-card restructure

**What goes wrong:** The Overview's 4 compact health-count cards look like they should share structure with the existing `support_cards.ex` support cards. A developer refactors `support_cards.ex` while building the Overview. Phase 76 then needs to restructure the same file again.
**How to avoid:** The Overview health-count cards are NEW, compact, read-only at-a-glance cards — they are NOT the Phase 76 support-card hierarchy. Do not touch `support_cards.ex` in Phase 75.

### Pitfall 5: `preview-empty-mailables` heading mismatch

**What goes wrong:** The UI-SPEC Copywriting Contract lists the blank-slate heading as `"No mailables found."`. The live code at `preview_live.ex:297` has `"No mailables discovered"`. A developer "fixes" this discrepancy during Phase 75 extraction, changing the existing heading.
**How to avoid:** D-06 says preserve the existing empty state verbatim. Only the orientation strip bullets use question-form copy. The existing `"No mailables discovered"` heading MUST NOT be changed in Phase 75. The UI-SPEC frozen copy for the blank-slate heading may refer to the orientation bullet, not the empty-state card heading.

### Pitfall 6: `aria-current="page"` on Overview — it is already handled

**What goes wrong:** A developer adds custom `aria-current` logic to the Overview render, duplicating what `nav_link/1` and `nav_pill/1` already do.
**How to avoid:** Shell's `nav_link/1` (line 205) and `nav_pill/1` (line 229) already emit `aria-current={@active && "page"}`. When the Overview passes `active={:deliveries}`, the "Deliveries" nav item automatically gets `aria-current="page"`. No custom aria work needed for D-16 beyond the h1/h2 hierarchy.

### Pitfall 7: GAP-register line-193 mis-tag causing scope creep

**What goes wrong:** The GAP-register summary at line 193 maps GAP-13/GAP-19 to IA-01. A planner reading only the summary pulls GAP-13 (support-card hierarchy) and GAP-19 (motion re-fire) into Phase 75 scope.
**How to avoid:** Only GAP-07, GAP-09, GAP-11 (390px orientation readability), GAP-21 (a11y), GAP-22 (deep-link disposition) are Phase 75 rows. GAP-13 and GAP-19 are Phase 76 and Phase 77 respectively. The plan must NOT cite GAP-13 or GAP-19 as justification for Phase 75 tasks.

---

## Validation Architecture

`workflow.nyquist_validation: true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework (Elixir) | ExUnit (mix test) |
| Framework (e2e) | Playwright (operator.spec.js + demo.spec.js) |
| Config | `mailglass_admin/test/` for ExUnit; `mailglass_admin/e2e/playwright.config.js` for Playwright |
| Quick run command (ExUnit) | `mix test test/mailglass_admin/ --seed 0` |
| Quick run command (e2e) | `npx playwright test mailglass_admin/e2e/operator.spec.js` |
| Full suite command | `mix test --seed 0` (note: scope per-package to avoid inbound flake) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| IA-01 | `Shell.orientation_strip/1` exists as a public function component in `shell.ex` | Structural ExUnit / conformance grep | `mix test test/mailglass_admin/operator/shell_test.exs` (Wave 0 gap — test file may not exist) | Also: `grep -n "def orientation_strip" mailglass_admin/lib/mailglass_admin/operator/shell.ex` |
| IA-01 | Deliveries orientation strip renders with `deliveries-orientation` testid when `is_nil(@selected_delivery)` | LiveView ExUnit + Playwright structural | `mix test test/mailglass_admin/operator_live_test.exs` + `npx playwright test operator.spec.js` | Playwright test 2 (390px) should be extended to assert `deliveries-orientation` testid visible |
| IA-01 | Inbound orientation strip renders with `inbound-orientation` testid when `is_nil(@detail)` | LiveView ExUnit | `mix test test/mailglass_admin/inbound_live_test.exs` | Confirm inbound_live_test.exs exists; add testid assertion |
| IA-01 | Preview orientation strip renders with `preview-orientation` testid when `@mailables == []` | LiveView ExUnit | `mix test test/mailglass_admin/preview_live_test.exs` | Add orientation strip assertion alongside preserved `preview-empty-mailables` |
| IA-01 | Existing `preview-empty-mailables` testid is preserved | LiveView ExUnit | `mix test test/mailglass_admin/preview_live_test.exs -t "preview-empty-mailables"` | Regression: confirm testid still present after adding orientation strip |
| IA-01 | Per-surface copy is verbatim frozen copy | Conformance grep | `grep -n "Email never arrived" mailglass_admin/lib/mailglass_admin/operator/shell.ex` + analogous for inbound + preview | Verify exact frozen copy strings present |
| IA-01 | `text-label` used on tip bullets (not raw `text-sm`) | Conformance grep | `grep -n "text-sm" mailglass_admin/lib/mailglass_admin/operator/shell.ex` → expect 0 hits on new component | Token-clean check |
| IA-02 | Bare `/ops/mail/` renders Overview (h1 "Operator overview") | Playwright structural | `npx playwright test operator.spec.js` after openOperator update | Updated `openOperator` helper asserts "Operator overview" |
| IA-02 | Overview with no `tenant_id` shows orientation strip + nudge "Select a tenant to see health at a glance." | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t "overview no tenant"` (Wave 0 gap) | New test case needed |
| IA-02 | Overview with `tenant_id` shows 4 health-count cards | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t "overview health counts"` (Wave 0 gap) | New test case; mock `SupportSummary` via runtime indirection seam |
| IA-02 | Suppression count degrades to `—` when `count_active_suppressions/1` errors | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t "overview suppression degradation"` (Wave 0 gap) | Test: send error from suppression count module; assert `—` rendered in `text-secondary` |
| IA-02 | `count_active_suppressions/1` returns integer count for a tenant | ExUnit (core) | `mix test test/mailglass/operator/suppressions_test.exs` | Confirm test file exists; add test for new function |
| IA-02 | "View Deliveries" CTA push_patches to `?view=deliveries` preserving `tenant_id` | LiveView ExUnit / Playwright | `npx playwright test operator.spec.js` | `openOperator` helper should include navigation to Deliveries after landing on Overview |
| IA-02 | `aria-current="page"` resolves on Deliveries nav when on Overview (`active={:deliveries}`) | LiveView ExUnit | `mix test test/mailglass_admin/operator/shell_test.exs -t "aria-current"` (Wave 0 gap if test not present) | Shell's `nav_link/1` already emits `aria-current={@active && "page"}` — regression check only |
| IA-03 | No raw `text-sm` on the new orientation strip component | Conformance grep | `grep -n "text-sm" mailglass_admin/lib/mailglass_admin/operator/shell.ex` | Zero hits expected on new component definition |
| IA-03 | All 5 `operator.spec.js` tests green with updated `openOperator` helper | Playwright | `npx playwright test mailglass_admin/e2e/operator.spec.js` | Same-commit requirement; must be green before merge |
| IA-03 | All 3 `demo.spec.js` tests green with updated heading assertions | Playwright | `npx playwright test reference/demo_app/assets/e2e/demo.spec.js` | Same-commit requirement |
| IA-03 | `operator.spec.js:32-34` `operator-empty-detail` still asserted correctly (in Deliveries view) | Playwright | `npx playwright test operator.spec.js` (test 1) | After helper navigates to Deliveries, `operator-empty-detail` should still be visible on initial load |
| IA-03 | 390px structural test extended to assert `deliveries-orientation` visible at 390px | Playwright | `npx playwright test operator.spec.js --grep "mobile stacks"` | Extend test 2 (lines 64-89) with orientation-strip testid assertion |
| IA-04 | GAP-22 deferral decision recorded | Documentation | Manual: confirm `docs/design-system.md` near line 141-150 has a deferral note referencing Phase 79 | No automated test; plan-checker Dimension 7 verifies decision is documented |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass_admin/ --seed 0` + `npx playwright test operator.spec.js`
- **Per wave merge:** Full `mix test --seed 0` (scope to per-package for inbound flake; see `project_inbound_suite_flake.md` memory) + both e2e specs
- **Phase gate:** All tests green + conformance greps pass + `git diff --exit-code priv/static/` clean before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/mailglass_admin/operator/shell_test.exs` — needs `Shell.orientation_strip/1` public component test (rendered testids, per-surface copy, token-clean class)
- [ ] `test/mailglass_admin/operator_live_test.exs` — needs Overview branch test cases (no-tenant nudge, with-tenant health counts, suppression degradation, `?view=deliveries` navigation)
- [ ] `test/mailglass/operator/suppressions_test.exs` — needs `count_active_suppressions/1` test cases (confirms count, confirms active-only filter)
- [ ] Extended Playwright test 2 (`operator.spec.js` lines 64-89) — add `deliveries-orientation` testid assertion at 390px

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Phoenix LiveView | LiveView components | ✓ | ~> 1.1 | — |
| Tailwind v4 standalone binary | Bundle rebuild | ✓ | 4.1.12 | — |
| daisyUI 5 vendored | Component classes | ✓ | 5.x | — |
| Playwright | e2e structural tests | ✓ | (CI-managed) | — |
| `mix mailglass_admin.assets.build` | Bundle rebuild gate | ✓ | via `tailwind` hex 0.4.1 | — |
| `agent-browser` CLI | 390px screenshot audit | local-only, not CI | ad-hoc | Manual screenshot via browser DevTools |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `agent-browser` — required for the local screenshot→LLM-critique ritual (D-18 acceptance). Not available in CI. Fallback: manual screenshot via browser DevTools at 390px. This is acceptable per the "local-only" policy (VR-NEXT-01 is out of scope).

---

## Security Domain

This phase introduces no new authentication surfaces, no new data inputs from untrusted sources, no cryptographic operations, and no new API endpoints. The Operator Overview renders aggregate counts only (never PII — `:to`, `:from`, `:subject` are explicitly excluded per CLAUDE.md). No ASVS categories are implicated beyond what already applies to the operator surface.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Existing only | `MailglassAdmin.Operator.Mount` (unchanged stable seam) |
| V5 Input Validation | `params["view"]` | Pattern-match to `:overview` vs `:deliveries` atom; ignore unexpected values |
| PII in telemetry | yes | Health counts are aggregate integers — no recipient/address/subject in any new assign |

---

## State of the Art

| Old State | Current State | Phase 75 Change |
|-----------|---------------|-----------------|
| Bare `/ops/mail/` → immediate Deliveries list (no orientation) | Bare `/ops/mail/` → Operator Overview with health + navigation | New in Phase 75 |
| `orientation_strip` private, Deliveries-only, with verbose verbose heading "Start from the customer symptom" | `Shell.orientation_strip/1` public, all 3 surfaces, frozen terse symptom-first copy | New in Phase 75 |
| `count_active_suppressions/1` absent from core | Present at `lib/mailglass/operator/suppressions.ex` | New in Phase 75 |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `demo.spec.js` navigates to `/ops/mail?tenant_id=northstar` — with Overview as new landing, the heading is "Operator overview" not "Deliveries" | Mechanics M-3 | If the demo dashboard "outbound operator" link somehow bypasses the Overview (e.g., carries `?view=deliveries`), the heading assertion update strategy changes |
| A2 | `operator-empty-detail` testid remains reachable in Phase 75 after navigating to `?view=deliveries` (no selection) | Validation Architecture | If the Deliveries render no longer shows the empty-detail card on initial load, test 1's assertion needs a more explicit flow |
| A3 | The `preview-empty-mailables` heading discrepancy ("No mailables discovered" vs frozen "No mailables found.") is not a Phase 75 concern — the existing heading is preserved verbatim | Anchor Verification | If the UI-SPEC frozen copy is intended to replace the existing heading, Phase 75 must change it — but D-06 says preserve |

---

## Open Questions

1. **`openOperator` helper strategy for `demo.spec.js:26`**
   - What we know: The demo test clicks an "outbound operator" link which navigates to `/ops/mail?tenant_id=northstar`. After Phase 75, this lands on the Overview.
   - What's unclear: Does the demo app dashboard have a direct "outbound operator → deliveries" link (passing `?view=deliveries`) or a plain `/ops/mail` link?
   - Recommendation: In the same-commit e2e update, navigate explicitly to `?view=deliveries` in the test (or update the demo dashboard link to include `?view=deliveries`). The plan should specify which approach to take.

2. **`load_support_summary/2` refactor for Overview**
   - What we know: The existing `load_support_summary(filter_params, nil)` returns `nil` (no selected delivery). For the Overview, we need the summary even without a selected delivery.
   - What's unclear: Should the planner add a new `load_overview_health/1` or extend the existing `load_support_summary/2` with a third-clause?
   - Recommendation: Add `defp load_overview_health(filter_params)` calling `summarize_tenant` directly, and a separate function for the suppression count. Keeps concerns separate from the delivery-scoped load.

---

## Sources

### Primary (HIGH confidence — verified against live source files)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — lines 71-85 (`handle_params/3`), 254-256 (orientation render trigger), 362-392 (`defp orientation_strip`), 658-670 (`load_support_summary`, `support_summary_module/0`)
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — lines 102 (`attr :active`), 205/229 (`aria-current` in nav_link/nav_pill), 278-302 (`defp flash_region`)
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — lines 271 (`title="Inbound records"`), 330 (`is_nil(@detail)`)
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — lines 291-323 (zero-mailables empty state, `preview-empty-mailables` testid at 293)
- `mailglass_admin/lib/mailglass_admin/router.ex` — lines 261/270 (single `:index` routes confirmed)
- `lib/mailglass/operator/suppressions.ex` — full file (active-entry filter at lines 27-28; `count_active_suppressions/1` confirmed absent)
- `lib/mailglass/operator/support_summary.ex` — lines 21-35 (`summarize_tenant/1` confirmed returning `failed_ingest` + `orphan_backlog`)
- `mailglass_admin/e2e/operator.spec.js` — full file (all 5 tests + `openOperator` helper; heading assertion line 19 confirmed; 390px test lines 64-89 confirmed)
- `reference/demo_app/assets/e2e/demo.spec.js` — full file (heading assertions lines 27, 41 confirmed)

### Secondary (HIGH confidence — planning artifacts, cross-validated)
- `.planning/phases/75-information-architecture-navigation-and-orientation/75-CONTEXT.md` — D-01..D-18 decisions
- `.planning/phases/75-information-architecture-navigation-and-orientation/75-UI-SPEC.md` — frozen build contract
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — anti-churn citation gate; line-193 mis-tag confirmed
- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — ripple-risk assertions confirmed
- `.planning/research/v1.7-admin-ui-polish/ARCHITECTURE.md` — data flow diagrams + file inventory
- `.planning/research/v1.7-admin-ui-polish/PITFALLS.md` — Pitfalls 2, 4, 10, 15, 16 applied
- `.planning/research/v1.7-admin-ui-polish/STACK.md` — Tailwind v4/daisyUI 5 mechanics, bundle gate mechanics
- `.planning/REQUIREMENTS.md` — IA-01..IA-04 acceptance criteria

---

## Metadata

**Confidence breakdown:**
- Anchor verification: HIGH — all symbols/patterns confirmed in live files; no symbol missing; line-number drift is minor and noted
- Validation architecture: HIGH — maps directly to confirmed ripple-risk assertions and confirmed code structures
- Mechanics: HIGH — params-based branch mechanics derived from confirmed handle_params/3 structure
- Pitfalls: HIGH — grounded in confirmed code state + existing PITFALLS.md research

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable milestone; line numbers may drift with incremental maintenance commits)
