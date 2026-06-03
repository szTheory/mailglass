# Architecture Research: v1.7 Admin UI — IA & Design-System Polish

**Domain:** mailglass_admin — LiveView operator/preview dashboard polish
**Researched:** 2026-06-03
**Confidence:** HIGH (all claims mapped to concrete file:line; inferences flagged)

---

## System Overview

```
mailglass_operator_routes/2  (router.ex — STABLE SEAM, untouched)
  └─ live_session :mailglass_admin_operator
       ├─ live "/"         → MailglassAdmin.OperatorLive      (:index)
       │    └─ NEW action  → MailglassAdmin.OperatorLive      (:overview)  [see §1]
       └─ live "/inbound"  → MailglassAdmin.InboundLive       (:index)

Chrome layer (operator/shell.ex — internal, free to churn)
  ├─ Shell.shell/1  ← OperatorLive.render, InboundLive.render
  ├─ nav_link/1, nav_pill/1  (sidebar + mobile nav)
  ├─ tenant_chip/1
  ├─ theme_toggle/1
  └─ NEW: orientation_strip/1  (generalized function component — Phase 1)

Component atoms (components.ex — internal, free to churn)
  ├─ icon/1, logo/1, flash/1, badge/1  (existing)
  ├─ mask_recipient/1  (existing)
  └─ NEW: status_badge/1  (unified delivery+inbound status→color atom — Phase 2)

Operator surface submodules (operator/*.ex)
  ├─ deliveries_list.ex   badge_class/1 at line 80  → route through status_badge/1
  ├─ timeline.ex          badge_class/1 at lines 131-135 → route through status_badge/1
  └─ support_cards.ex     densest UX + token drift; health data via SupportSummary

Inbound surface submodules (inbound/*.ex)
  └─ records_list.ex      badge_class/1 at line 97  → route through status_badge/1

Health data seams (core lib, read-only)
  ├─ Mailglass.Operator.SupportSummary.summarize_tenant/1
  └─ Mailglass.Operator.Suppressions.get_delivery_suppression_state/2
```

---

## 1. Mount/Shell Architecture and Operator Overview Route

### How the shell provides chrome today

`MailglassAdmin.Operator.Shell.shell/1` (shell.ex:116) is a plain Phoenix function component. Both `OperatorLive.render/1` (operator_live.ex:227) and `InboundLive.render/1` (inbound_live.ex:248) wrap their body in `<MailglassAdmin.Operator.Shell.shell ...>`. The shell provides:

- Left sidebar with `nav_link/1` to Deliveries and (conditionally) Inbound (shell.ex:130-144)
- Mobile header with `nav_pill/1` (shell.ex:157-168)
- `tenant_chip` + `theme_toggle` in header (shell.ex:171-176)
- `h1`/subtitle from the `:title`/`:subtitle` attrs (shell.ex:181-184)
- Flash region (shell.ex:186)
- `render_slot(@inner_block)` — the surface body (shell.ex:188)

The shell is declared with `attr :active, :atom, values: [:deliveries, :inbound]` (shell.ex:102), making it aware of exactly two surfaces. The inner_block is the only slot (shell.ex:111).

### How the operator mount is wired through router.ex

`router.ex:mailglass_operator_routes/2` (line 247) expands via `quote bind_quoted` to a `live_session` block containing:

```
live "/",        MailglassAdmin.OperatorLive, :index   # router.ex:261
live "/inbound", MailglassAdmin.InboundLive,  :index   # router.ex:270 (conditional)
```

The `live_session` is named `:mailglass_admin_operator` (default) and carries `Operator.Mount` as the terminal on_mount hook (router.ex:255). The session callback is `__operator_session__/2` (router.ex:313). **This macro signature is the stable seam — do not touch it.**

### Where the new Operator Overview landing route slots in

**Recommendation: a new `:overview` action on `MailglassAdmin.OperatorLive`, NOT a sibling LiveView.**

Rationale:
1. The router macro emits `live "/", MailglassAdmin.OperatorLive, :index` (router.ex:261). Phoenix LiveView actions allow a single LiveView to handle multiple actions via `handle_params` pattern-matching on the action assign. Adding an `:overview` action requires **zero router.ex changes** — the macro already emits `live "/"` with `:index`; a second `live "/"` clause with `:overview` would be a different URL. The correct slot is a path-level distinction, so:

   - `/` → `:overview` action (new Overview landing)
   - `/?delivery_id=...` or any filter param → `:index` action (existing Deliveries)

   This is done entirely within `OperatorLive.handle_params/3` by inspecting `socket.assigns.live_action`. **No router.ex change needed** if the action is named in `handle_params` rather than a new `live` route.

   **INFERENCE:** The cleanest zero-router-change mechanism is: `OperatorLive.handle_params` checks `socket.assigns.live_action`. If `:overview`, render the overview; if `:index`, render the deliveries screen. The shell nav link to "Deliveries" navigates to the base operator path (already `paths.deliveries` in shell.ex:135), so the overview is a transient landing, not a new persistent nav node.

   Alternative (also no router.ex change): treat overview as a conditional render within the existing `:index` action — if no filter params and no delivery_id are present on first mount, show overview content above the filter form. This avoids a new action entirely. The blueprint favors a "real landing route," but both approaches satisfy the stable-seam constraint.

2. The Overview does NOT need its own `live_session` or `Operator.Mount` gate — it is the same operator surface, same auth posture, mounted in the existing session.

3. The `shell` component's `:active` attr already accepts `:deliveries` — the Overview passes `active={:deliveries}` since it is the Deliveries surface root. No new `:overview` atom needed in shell.

**Concretely: `OperatorLive` gains a new clause in `handle_params` (operator_live.ex:71) and a new render branch (operator_live.ex:227) or a separate `render/1` override for `:overview` action. No new file.**

---

## 2. Generalized `orientation_strip` — Extraction Plan

### Current state

`orientation_strip/1` is a private `defp` at `operator_live.ex:362`. It renders a `hero-lifebuoy` icon, a bold heading, and a 3-item UL with Deliveries-specific copy ("Email never arrived?", "Replay changed nothing?", "Address keeps getting blocked?"). It is called once, unconditionally when `is_nil(@selected_delivery)`, at operator_live.ex:254-256.

`InboundLive` has no equivalent — it has only a plain empty-detail card (inbound_live.ex:329-339). `PreviewLive` has no equivalent.

### Recommended extraction

Move the component to `MailglassAdmin.Operator.Shell` (shell.ex) as a public function component `orientation_strip/1`. Shell is already the chrome module; orientation strips are chrome-level orientation, not surface-specific business logic. Placing it in shell.ex keeps it co-located with the other chrome elements (nav, tenant chip, flash region) and avoids a new file.

**Component signature (recommended):**

```elixir
# shell.ex — new public component
attr :icon, :string, default: "hero-lifebuoy"
attr :heading, :string, required: true
slot :tips, required: true  # one <:tips> per bullet item

def orientation_strip(assigns) do
  ~H"""
  <div
    class="rounded-box border border-base-300 bg-base-200 p-md"
    data-testid={@testid}
  >
    <div class="flex items-start gap-sm">
      <Components.icon name={@icon} class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
      <div class="min-w-0">
        <h2 class="text-body font-bold text-base-content">{@heading}</h2>
        <ul class="mt-2 grid gap-1 text-sm text-secondary">
          <%= for tip <- @tips do %>
            <li>{render_slot(tip)}</li>
          <% end %>
        </ul>
      </div>
    </div>
  </div>
  """
end
```

**Consumers:**

| Surface | File | Trigger condition | Content |
|---------|------|------------------|---------|
| Deliveries | operator_live.ex:254 | `is_nil(@selected_delivery)` | Existing 3-bullet delivery copy |
| Inbound | inbound_live.ex:~330 | `is_nil(@detail)` | New 3-bullet inbound copy ("Message didn't route?", etc.) |
| Preview | preview_live.ex | zero mailables state | Author-oriented copy ("No mailables found?", etc.) |

**INFERENCE on Preview:** PreviewLive's zero-mailables empty state is not confirmed from reading — I did not read `preview_live.ex`. The blueprint lists Preview as a consumer; verify the exact trigger condition before adding it.

**Call-site change to `operator_live.ex`:** Remove `defp orientation_strip/1` at line 362-392. Replace the call at line 255 with `<Shell.orientation_strip heading="...">`. The `mb-lg` wrapper div at line 254 can be kept or folded into the component.

---

## 3. Unified Status-Badge Atom in `components.ex`

### Current badge_class copies

| File | Lines | Input domain | DaisyUI classes produced |
|------|-------|-------------|--------------------------|
| `operator/deliveries_list.ex` | 80-84 | delivery `:status` atom | `badge-success`, `badge-warning`, `badge-error`, `badge-outline` |
| `operator/timeline.ex` | 131-135 | event `:type` atom (replay/reconcile) | `badge badge-outline badge-error`, `badge badge-outline badge-warning`, `badge badge-outline` |
| `inbound/records_list.ex` | 97-101 | inbound `:outcome` atom | `badge-success`, `badge-warning`, `badge-error`, `badge-outline` |

These three copies have diverging class sets: `deliveries_list` omits the `badge` prefix (line 49 applies `"badge badge-sm"` in the outer class list, so `badge_class/1` returns only the modifier); `timeline.ex` returns the full class string including `badge badge-outline`; `records_list.ex` omits `badge` for the same reason as deliveries_list.

### Recommended unified component

Add `status_badge/1` to `components.ex` (after existing `badge/1` at line 102). This is a function component, not just a helper function, so callers use `<Components.status_badge status={...} />` consistently.

**Recommended shape:**

```elixir
# components.ex — new public component
attr :status, :atom, required: true
attr :size, :atom, values: [:sm, :md], default: :sm
attr :class, :any, default: nil

@doc """
Unified delivery/inbound status badge atom consuming the canonical
taxonomy from the UI-SPEC. Replaces the three private badge_class/1
copies in deliveries_list.ex, timeline.ex, and records_list.ex.

Taxonomy covers delivery statuses, Anymail event types, inbound
outcomes, and replay/reconcile event markers.
"""
def status_badge(assigns) do
  ~H"""
  <span class={["badge", size_class(@size), status_class(@status), @class]}>
    {status_label(@status)}
  </span>
  """
end
```

The `status_class/1` and `status_label/1` private functions replace all three `badge_class/1` definitions and the separate `label/1` helpers. The UI-SPEC taxonomy table (produced in Phase 0) is the authoritative input for these mappings.

**IMPORTANT: the timeline.ex call site is structurally different.** `timeline.ex:52` wraps the badge in `:if={event_badge(event.type)}` — meaning the badge is conditionally rendered only for replay and reconcile event types (lines 131-135 show only those three clauses return a non-empty class). The unified component must support a `nil`/absent-status path that renders nothing, OR the caller retains the `:if` guard. Recommend retaining the `:if` guard at the call site and letting `status_badge` handle any status without branching.

**Migration order for call sites:**

1. `operator/deliveries_list.ex:49` — `class={["badge badge-sm", badge_class(delivery.status)]}` → `<Components.status_badge status={delivery.status} size={:sm} />`
2. `inbound/records_list.ex:55` — same pattern → `<Components.status_badge status={record_outcome(record)} size={:sm} />`
3. `operator/timeline.ex:52-53` — `<span :if={event_badge(event.type)} class={badge_class(event.type)}>` → `<Components.status_badge :if={event_badge(event.type)} status={event.type} />`

After migration: delete `defp badge_class/1` from all three files. The `event_badge/1` predicate in timeline.ex can remain as-is (it guards render, not styling).

---

## 4. At-a-Glance Health Data for the Overview Landing

### Existing seams to reuse

**`Mailglass.Operator.SupportSummary.summarize_tenant/1`** (lib/mailglass/operator/support_summary.ex:21)

This is already used by `OperatorLive.load_support_summary/2` (operator_live.ex:660-668) via the dynamic module call at line 670:

```elixir
defp support_summary_module, do: :"Elixir.Mailglass.Operator.SupportSummary"
```

The function signature is `summarize_tenant(%{tenant_id: tenant_id, window_hours: hours})` and returns a map with keys:
- `:failed_ingest` — `%{count: n, latest: ...}`
- `:orphan_backlog` — `%{count: n, oldest: ...}`
- `:replay_outcomes` — `%{counts: %{failed:, noop:, replayed:}, latest: ...}`
- `:reconcile_facts` — `%{reconciled_count:, still_unmatched_count:, latest_reconciled: ...}`

The Overview landing can call this directly using the same `support_summary_module()` pattern already in `OperatorLive`. The `:tenant_id` comes from filter params; the `:window_hours` defaults to 168 (7 days), matching `@default_window_hours`.

**`Mailglass.Operator.Suppressions`** (lib/mailglass/operator/suppressions.ex)

`get_delivery_suppression_state/2` is delivery-scoped (requires a recipient + stream). For the Overview, a suppression COUNT by tenant is more appropriate. **INFERENCE:** There may not be an existing `count_tenant_suppressions/1` in the Suppressions module — the Overview will need either a new read-model function in core (small, additive) or a count derived from a separate Repo query. Do not duplicate query logic in the admin layer; add `Suppressions.count_active_suppressions/1` to core if needed.

**No new data infrastructure is needed for `failed_ingest`, `orphan_backlog`, and `replay_outcomes`** — these come directly from `SupportSummary.summarize_tenant/1`. Only the suppression count requires confirming whether an existing read model supports it.

### Overview assign pattern

The Overview landing mounts via `handle_params` in `OperatorLive`. Since the Overview is tenant-context-free by default (operator has not yet filtered to a tenant), display aggregate health OR show an empty/zero state prompting tenant selection. The most practical approach:

- If `filter_params["tenant_id"]` is blank → show the orientation strip + a "Select a tenant to see health at a glance" nudge
- If `filter_params["tenant_id"]` is set → call `load_support_summary/2` (reusing line 660) and render at-a-glance counts

This reuses the EXACT existing `assign_delivery_state` pattern without adding new assigns.

---

## 5. Component Responsibilities

| Component | File | Responsibility | v1.7 Change |
|-----------|------|---------------|-------------|
| `MailglassAdmin.Operator.Shell` | operator/shell.ex | Chrome: sidebar, nav, tenant chip, theme toggle, flash | ADD `orientation_strip/1` public component |
| `MailglassAdmin.Components` | components.ex | Brand atoms: icon, logo, flash, badge, masking | ADD `status_badge/1` public component |
| `MailglassAdmin.OperatorLive` | operator_live.ex | Deliveries master-detail + handle_params + events | ADD `:overview` action render branch; REMOVE private `orientation_strip/1`; update `handle_params` |
| `MailglassAdmin.InboundLive` | inbound_live.ex | Inbound master-detail + handle_params + events | ADD `orientation_strip` call in empty-detail branch |
| `MailglassAdmin.Operator.SupportCards` | operator/support_cards.ex | 4-card support cues | MODIFY: primary/secondary grid hierarchy + token migration |
| `MailglassAdmin.Operator.DeliveriesList` | operator/deliveries_list.ex | Delivery row list + badges | MODIFY: replace `badge_class/1` with `status_badge/1` |
| `MailglassAdmin.Operator.Timeline` | operator/timeline.ex | Event timeline + badges | MODIFY: replace `badge_class/1` with `status_badge/1` |
| `MailglassAdmin.Inbound.RecordsList` | inbound/records_list.ex | Inbound record row list + badges | MODIFY: replace `badge_class/1` with `status_badge/1` |

---

## 6. New vs Modified File Inventory

### NEW files

| File | Phase | Reason |
|------|-------|--------|
| `.planning/research/v1.7-admin-ui-polish/ARCHITECTURE.md` | Pre-work | This document |
| `mailglass_admin/e2e/inbound.spec.js` (inferred) | Phase 5 | Structural e2e for inbound surface (blueprint mentions extending coverage) |

**No new Elixir source files are required for the core v1.7 structural changes.** All additions are new function components or new render branches inside existing modules. This is a deliberate constraint — zero new compilation units, zero new public module names in the stable boundary.

### MODIFIED files (by phase)

**Phase 0 (Audit — no code):**
- `mailglass_admin/docs/design-system.md` — append gap register + UI-SPEC
- `mailglass_admin/e2e/operator.spec.js` — inventory all heading/testid assertions before any changes

**Phase 1 (IA + Orientation):**
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — ADD `orientation_strip/1` public component (lines appended after existing `flash_region/1`)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — REMOVE private `orientation_strip` defp (line 362-392); ADD `:overview` action branch in `handle_params` and `render`; update call site at line 255
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — ADD `orientation_strip` call in empty-detail branch (~line 329-339)
- `mailglass_admin/e2e/operator.spec.js` — update heading assertions for new Overview landing
- `reference/demo_app/assets/e2e/demo.spec.js` — update IA-ripple assertions (new landing heading)

**Phase 2 (Component Hardening):**
- `mailglass_admin/lib/mailglass_admin/components.ex` — ADD `status_badge/1` component + private `status_class/1`, `status_label/1`
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — REMOVE `badge_class/1` (line 80-84); replace call site at line 49; token-migrate raw `text-sm/base` + off-grid gaps
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — REMOVE `badge_class/1` (lines 131-135); replace call site at line 52; token-migrate
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — REMOVE `badge_class/1` (lines 97-101); replace call site at line 55; token-migrate
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — redesign 2×2 grid into primary/secondary hierarchy (`:failed_ingest` + `:orphan_backlog` as primaries); token-migrate all raw `text-sm/base/xs` + `gap-3/6` + `font-medium` off-grid
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — token-migrate render body (line 254 area)
- `mailglass_admin/priv/static/app.css` — rebuilt after any class change

**Phase 3 (Motion — parallel):**
- Various HEEx files — apply motion vocabulary consistently; no structural changes

**Phase 4 (Seed data — parallel):**
- `reference/demo_app/priv/repo/seeds.exs` — expand to cover all states
- `reference/demo_app/assets/e2e/demo.spec.js` — update seed-count assertions

**Phase 5 (Verification):**
- `mailglass_admin/e2e/operator.spec.js` — extend coverage for new IA/testids
- `mailglass_admin/priv/static/app.css` — final bundle-clean gate

---

## 7. Dependency-Ordered Build Sequence

```
Phase 0: Audit + UI-SPEC (blocks all)
  └─ Outputs: gap register, canonical status-badge taxonomy table, empty/error state inventory
       ↓
Phase 1: IA + Orientation
  ├─ Prerequisite: Phase 0 gap register + IA decisions locked
  ├─ Step 1a: Add Shell.orientation_strip/1 (shell.ex)
  ├─ Step 1b: Remove private orientation_strip in OperatorLive; add overview action + render
  ├─ Step 1c: Add orientation_strip call in InboundLive empty-detail
  ├─ Step 1d: Update operator.spec.js + demo.spec.js assertions
  └─ Step 1e: Decide deep-link-unstyled fix scope (gate explicit)
       ↓
Phase 2: Component Hardening  (RESTRUCTURE-THEN-TOKENIZE order within phase)
  ├─ Step 2a: ADD status_badge/1 to components.ex  ← MUST land before any badge_class deletion
  ├─ Step 2b: Migrate deliveries_list.ex badge_class → status_badge
  ├─ Step 2c: Migrate records_list.ex badge_class → status_badge  ← MUST complete before Phase 1 "finalize Inbound"
  ├─ Step 2d: Migrate timeline.ex badge_class → status_badge
  ├─ Step 2e: Redesign support_cards.ex primary/secondary grid
  ├─ Step 2f: Token-migrate support_cards.ex (raw text-sm/base/xs → text-label/body/heading)
  ├─ Step 2g: Token-migrate operator_live.ex render body
  ├─ Step 2h: Token-migrate inbound_live.ex render body
  └─ Step 2i: Rebuild + commit priv/static/app.css
       ↑
       Note: 2a → 2b/2c/2d is a strict dependency chain.
             2e/2f/2g/2h are parallelizable after 2a.
  ↓           ↓
Phase 3      Phase 4   (parallel, 3 after 2's structure settles, 4 from Phase 0)
  ↓           ↓
Phase 5: Verification (depends on all prior)
  ├─ Full audit matrix re-run
  ├─ Before/after PNG diff vs Phase 0 baseline
  ├─ Extend operator.spec.js + inbound structural coverage
  ├─ Conformance grep gate (zero raw text-sm/base/xs, zero faux-bold, zero off-grid gaps)
  └─ Bundle clean gate (git diff --exit-code priv/static/)
```

**Critical dependency constraints:**
1. `status_badge/1` in `components.ex` (Phase 2 Step 2a) must land **before** deleting any `badge_class/1` copy and **before** Phase 1 finalizes Inbound orientation (the blueprint states "badge atom before Phase 1 finalizes Inbound to avoid re-touch")
2. Taxonomy table from Phase 0 is the input to `status_badge/1`'s mapping functions — freeze IA + taxonomy at Phase 0 end
3. `restructure-then-tokenize` within Phase 2: support_cards grid redesign (2e) before token migration (2f) so layout decisions don't require re-tokenizing
4. `operator.spec.js` assertion inventory in Phase 0 must precede any heading/testid changes in Phase 1

---

## 8. Stable Seams Confirmed Untouched

| Seam | File | Status | Evidence |
|------|------|--------|---------|
| `mailglass_operator_routes/2` macro | router.ex:247 | UNTOUCHED | New Overview is an action on existing `OperatorLive`, not a new `live` route |
| `mailglass_admin_routes/2` macro | router.ex:209 | UNTOUCHED | Preview changes are within PreviewLive only |
| `MailglassAdmin.Auth` behaviour | auth.ex | UNTOUCHED | No new auth surfaces; replay + reveal gates reuse existing seam |
| Replay semantics | operator_live.ex:174-224, inbound_live.ex:186-233 | UNTOUCHED | No replay logic changes |
| Operator session contract | router.ex:313 | UNTOUCHED | `__operator_session__/2` unchanged |
| `live "/", MailglassAdmin.OperatorLive, :index` | emitted by router.ex:261 | UNTOUCHED | `:overview` action handled in `handle_params`, not a new `live` route |

---

## 9. Data Flow

### Overview Landing Load

```
Browser → GET /ops/mail/
    ↓
OperatorLive.handle_params(%{}, uri, socket)  [operator_live.ex:71]
    ↓  live_action == :overview (or :index with no params)
    ↓
load_support_summary(filter_params, _)  [operator_live.ex:660]
    ↓  calls support_summary_module().summarize_tenant/1
Mailglass.Operator.SupportSummary.summarize_tenant(%{tenant_id:, window_hours:})
    ↓  returns %{failed_ingest:, orphan_backlog:, replay_outcomes:, reconcile_facts:}
assign(:support_summary, ...)  [reuses existing assign]
    ↓
render — Overview branch: orientation_strip + at-a-glance health cards
```

### Badge Unification Data Flow

```
delivery.status atom
    ↓
<Components.status_badge status={delivery.status} />  [components.ex]
    ↓  status_class/1 maps atom → daisyUI modifier class
    ↓  status_label/1 maps atom → display string
<span class="badge badge-sm badge-success">Delivered</span>
```

---

## 10. Anti-Patterns to Avoid

### Anti-Pattern 1: New `live` route for the Overview

**What:** Adding `live "/overview", MailglassAdmin.OperatorOverviewLive, :index` to the router macro body.
**Why wrong:** Requires modifying the stable router macro — even if the macro is internal-implementation, adding a route changes the URL surface and operator.spec.js test URLs.
**Do this instead:** Use a new `:overview` action on `OperatorLive` via `handle_params` branching.

### Anti-Pattern 2: Duplicating `SupportSummary` query logic in the Overview

**What:** Writing a new Repo query in `OperatorLive` to fetch orphan/failure counts.
**Why wrong:** Violates "errors/data as a public API contract" — the read model owns tenancy scoping and query logic.
**Do this instead:** Call `Mailglass.Operator.SupportSummary.summarize_tenant/1` via the existing `support_summary_module()` indirection (operator_live.ex:670).

### Anti-Pattern 3: Adding `:overview` to Shell's `attr :active` values list

**What:** Extending `attr :active, :atom, values: [:deliveries, :inbound, :overview]` in shell.ex:102.
**Why wrong:** The Overview IS the Deliveries surface root — its active nav node is `:deliveries`. Adding `:overview` creates a third nav concept where none exists in the IA model.
**Do this instead:** Pass `active={:deliveries}` from the Overview render branch, same as the Deliveries list.

### Anti-Pattern 4: Placing `orientation_strip` in `components.ex` instead of `shell.ex`

**What:** Adding orientation_strip to the brand-atoms module.
**Why wrong:** `components.ex` is for reusable brand atoms (icon, logo, flash, badge, mask). Orientation strips are chrome-level, surface-oriented content with specific copy — they belong with the other chrome in `shell.ex`.
**Do this instead:** Public function component in `shell.ex`, after `flash_region/1` (line 276).

### Anti-Pattern 5: Merging `deliveries_list.ex` and `records_list.ex` into one module

**What:** Unifying the two list modules to eliminate structural duplication.
**Why wrong:** The `inbound_live.ex` module doc (line 7) explicitly calls out "Sibling of `MailglassAdmin.Operator.DeliveriesList` (clone, not a refactor)" — this is a deliberate design choice to keep concerns isolated and avoid cross-surface compile coupling.
**Do this instead:** Route both through the shared `Components.status_badge/1` atom without merging the list modules.

---

## Sources

All claims in this document are derived directly from reading the following files at the commit state recorded in the git status header (main, clean, 1.4.5):

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — lines 71, 227, 254-256, 362-392, 660-670
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — lines 102-111, 116-193, 276
- `mailglass_admin/lib/mailglass_admin/components.ex` — lines 91-115
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — full file (flat 2×2 grid, token drift confirmed)
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — lines 49, 80-84
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — lines 52-53, 131-135
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — lines 55, 97-101
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — lines 248-357
- `mailglass_admin/lib/mailglass_admin/router.ex` — lines 247-275, 313-328 (stable seam confirmed)
- `lib/mailglass/operator/support_summary.ex` — lines 21-35 (health data seams confirmed)
- `/Users/jon/.claude/plans/mailglass-context-handoff-serene-noodle.md` — decisions, phase breakdown, weak spots

**Inferences flagged above:** Preview orientation_strip trigger condition (preview_live.ex not read); suppression count API availability (Suppressions module read partially); `:overview` action approach is the recommended pattern but the specific `handle_params` dispatch implementation is not yet written.

---

*Architecture research for: mailglass_admin v1.7 Admin UI — IA & Design-System Polish*
*Researched: 2026-06-03*
