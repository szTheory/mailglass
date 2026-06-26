# Phase 112: App-Shell, Navigation & Tenant Seam - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix LiveView admin shell, tenant-scoped read models, theme persistence, navigation, pagination  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Tenant Selection And Listing

- **D-01:** Add tenant discovery as a **core operator read-model capability**, then consume it from
  the admin shell through the authenticated `operator_actor`. The admin shell must not query tenant
  rows directly, infer tenant choices from demo fixtures/session alone, or introduce a host-app
  tenant-management surface.

- **D-02:** Tenant listing must be scoped through `Mailglass.Tenancy.scope/2` from the authenticated
  actor context, matching the existing operator read-model pattern. The exact projection shape is a
  planning/research item: decide whether the core read model should use a distinct-tenant projection
  over existing mailglass records or a dedicated read model, but the seam must live in core and stay
  tenant-safe.

- **D-03:** Shell behavior follows the roadmap semantics: when exactly one accessible tenant exists,
  auto-select it and avoid rendering a pointless picker; when two or more accessible tenants exist
  and the surface is unscoped, show a tenant listing/switcher instead of the current "No tenant
  selected" dead end.

### Tenant Scope Persistence

- **D-04:** Keep `tenant_id` as durable URL state across operator surfaces and shell actions.
  Session tenant context may seed or constrain behavior, but it must not replace URL-carried tenant
  scope once a surface is mounted. Filters, detail selection, clear/back actions, surface switches,
  refreshes, and copied URLs must preserve the selected tenant where applicable.

- **D-05:** Build on the PR #86 / current shell path behavior rather than replacing it. Existing
  path builders already preserve `tenant_id`; Phase 112 should close the remaining shell/listing
  gaps and add regression proof for every navigation action that can lose scope.

### Theme Persistence And First Paint

- **D-06:** Preserve the locked tri-state theme contract from Phases 109-110. Explicit `light` and
  `dark` choices server-render `data-theme="mailglass-light"` or `data-theme="mailglass-dark"`;
  `system` is represented by no explicit theme attribute and resolves through CSS `prefersdark`.
  Never emit `data-theme="system"`.

- **D-07:** Add host-scoped theme persistence at the mount/root-layout seam with a namespaced
  cookie so the first response can render the explicit choice without FOUC. Do not add a client JS
  hook that forces system mode, do not use global host storage keys, and do not server-persist theme
  per user or per tenant.

- **D-08:** The Phase 110 `theme_picker` primitive remains the UI source. Phase 112 wires it to the
  persistence/root-theme behavior and keeps `system` as the absence of an explicit choice.

### Navigation And Pagination Honesty

- **D-09:** Active navigation should continue to use the shared `nav_link` and `nav_pill`
  primitives, but Phase 112 must make the non-color cue unambiguous at both nav levels and across
  desktop/mobile presentations. `aria-current` alone is not enough if the visible cue remains easy
  to miss under stress.

- **D-10:** Pagination must be backed by real read/display metadata. Current list reads are
  limit-only, so planning must add or expose result count and page boundary metadata before
  rendering pagination. Do not fake totals from truncated list length.

- **D-11:** Pagination chrome appears only when there is more than one page. Result count is always
  visible. Boundary previous/next controls are disabled, not hidden. Infinite scroll and always-on
  pagination bars remain out of scope.

### the agent's Discretion

- Exact tenant projection implementation, after light planning research resolves distinct-tenant
  query versus dedicated read model.
- Exact cookie name and assign names, provided they are host-scoped/namespaced and preserve the
  tri-state theme contract.
- Exact visible non-color active-state treatment for nav primitives, provided it reuses the shared
  component surface and remains accessible.
- Exact pagination metadata shape, provided counts and page boundaries are real and tenant-safe.

### Deferred Ideas (OUT OF SCOPE)

- Responsive table-to-card transforms for deliveries/inbound lists - Phase 113.
- Distinct empty/error/permission/stale data-display templates beyond the tenant shell seam -
  Phase 113.
- GOV.UK-style full page IA and tenant/permission/stale microcopy pass - Phase 115.
- Multi-tenant stress-fixture cohort and gallery stress specimens - Phase 116.
- Axe JSON baseline, interaction pillar, and full matrix re-score - Phase 116.
- Cross-tenant aggregate views, tenant CRUD/invites, tenant pins/favorites, server-persisted
  per-user/per-tenant theme, infinite scroll, and always-on pagination bars - out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHELL-01 | A sole tenant is auto-selected; tenant picker renders only when >=2 tenants exist. | Use core `Operator.Tenants.list_tenants/1`, then patch/redirect to URL state when exactly one tenant exists. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`] |
| SHELL-02 | Multi-tenant unscoped state shows tenant listing/switcher from core read model, scoped via `Mailglass.Tenancy.scope/2` through authenticated actor. | Add distinct tenant projection in core read model and consume through `operator_actor`, not admin Repo. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `lib/mailglass/tenancy.ex`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex`] |
| SHELL-03 | Tenant scope persists across every surface and navigation action. | Centralize path state so filters, detail selection, clear/back, surface nav, theme changes, and copied URLs preserve `tenant_id`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/shell.ex`] |
| SHELL-04 | Theme picker is wired through mount hook with host-scoped persistence and no FOUC. | Read explicit theme from namespaced cookie before first render; `system` clears/omits explicit theme and emits no `data-theme`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/lib/mailglass_admin/layouts.ex`, `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`] |
| SHELL-05 | Navigation active/current state has non-color cues at both nav levels. | Keep shared primitives and strengthen visible cue/tests for desktop `nav_link` and mobile `nav_pill`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`] |
| SHELL-06 | Pagination shows count always, chrome only when >1 page, boundary prev/next disabled. | Add real count/page metadata to outbound and inbound read models before rendering pagination. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`, `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`] |
</phase_requirements>

## Summary

Phase 112 should make the shell tenant-aware without creating a host-app tenant-management feature. Use a core distinct-tenant projection over existing delivery/read records as the first implementation, not a dedicated persisted read model. The current data model already stores `tenant_id` on delivery and inbound rows, and the shell only needs an ordered selector of accessible tenant ids. A dedicated read model would add migration/backfill/runtime-state risk without evidence of a planner-visible benefit for this phase. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]

Tenant choice should become a small shared shell state contract: normalize URL params, discover accessible tenants through `operator_actor`, auto-patch exactly one tenant into the URL, render a switcher only for two or more tenants, and preserve `tenant_id` through every path builder. Current code already carries tenant scope across top-level surface paths, but `clear_filters` drops tenant scope and private path builders still take a boolean `dark_chrome`, making theme and tenant state too easy to lose in later changes. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`]

Theme wiring should not rebuild the Phase 110 primitive. The repository already has a tri-state `theme_picker/1`, root layout can omit `data-theme`, and CSS has daisyUI `mailglass-dark` with `prefersdark`; Phase 112 should connect those with a namespaced cookie for explicit `light`/`dark`, clearing the cookie for `system`. Pagination must wait for real read-model metadata; the list components currently render arrays only, so totals cannot be inferred from length. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/lib/mailglass_admin/layouts.ex`, `mailglass_admin/assets/css/app.css`, `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`]

**Primary recommendation:** Implement a core scoped `Mailglass.Operator.Tenants.list_tenants/1` distinct projection, shared shell tenant/theme state helpers, real read-model pagination metadata, and targeted shell/LiveView/browser regression tests before changing visible chrome.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tenant discovery/listing | API / Backend | Database / Storage | Accessible tenants are a data-authorization question and must come through core read models plus `Tenancy.scope/2`; admin UI is only the consumer. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `lib/mailglass/tenancy.ex`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex`] |
| Tenant auto-select/switch | Frontend Server (LiveView) | API / Backend | LiveView owns URL patch/assign state, while the core read model owns the tenant list. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`] |
| Tenant persistence across navigation | Frontend Server (LiveView) | Browser / Client | LiveView path builders own durable URL state; copied URLs and browser back/forward use query params. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`] |
| Theme no-FOUC persistence | Frontend Server (SSR/root render) | Browser / Client | First paint depends on server-rendered root attributes from cookie/query; browser CSS handles system mode through `prefersdark`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/layouts.ex`, `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`, `mailglass_admin/assets/css/app.css`] |
| Navigation active state | Frontend Server (LiveView components) | Browser / Client | Shared Phoenix components emit ARIA and visible cue classes; Playwright validates computed output. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/e2e/structural.spec.js`] |
| Pagination count/boundaries | API / Backend | Frontend Server (LiveView) | Counts and page boundaries must be computed by tenant-scoped read models, then rendered by list components. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |

## Project Constraints

No `AGENTS.md` exists in the repository root, so no additional project-specific directives were found there. [VERIFIED: repo: `test -f AGENTS.md` returned no content in `/Users/jon/projects/mailglass`]

Other locked project constraints for this phase are admin/demo only, zero new runtime Hex dependencies, committed CSS bundle on class changes, no raw admin Repo access for tenant listing, no pixel-diff regression, and no `data-theme="system"`. [VERIFIED: repo: `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `.planning/research/v1.13/STACK.md`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]

## Standard Stack

### Core

| Library / Module | Version / Shape | Purpose | Why Standard |
|------------------|-----------------|---------|--------------|
| Phoenix LiveView | `~> 1.1` | Server-rendered shell, URL patch state, root layout assigns. | Existing admin surfaces are LiveViews and tests already target LiveView URL-as-state behavior. [VERIFIED: repo: `mix.exs`, `mailglass_admin/mix.exs`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`] |
| `Mailglass.Tenancy.scope/2` | behaviour callback | Tenant scoping seam for Ecto queryables. | Existing operator read models apply explicit `tenant_id` predicates and `Tenancy.scope/2`. [VERIFIED: repo: `lib/mailglass/tenancy.ex`, `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |
| `Mailglass.Operator.*` read models | core modules | Delivery list, support summary, suppression reads, and new tenant projection. | Admin already consumes core read models and should not own raw data access. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `lib/mailglass/operator/deliveries.ex`] |
| `MailglassAdmin.Components` | public component module | Shared `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, `stat_card`. | Phase 110 promoted primitives here; shell and gallery already consume them. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `.planning/phases/110-primitives/110-CONTEXT.md`] |
| Playwright structural suite | `@playwright/test ^1.59.1` | Browser proof for system/no-FOUC, nav cues, focus, and shell state. | Existing e2e suite already proves structural behavior without screenshots. [VERIFIED: repo: `mailglass_admin/package.json`, `mailglass_admin/e2e/structural.spec.js`] |

### Supporting

| Library / Module | Version / Shape | Purpose | When to Use |
|------------------|-----------------|---------|-------------|
| daisyUI theme blocks | vendored, `prefersdark` configured | CSS-level system theme resolution. | Use by omitting explicit `data-theme` for `system`. [VERIFIED: repo: `mailglass_admin/assets/css/app.css`] |
| `MailglassAdmin.Operator.Mount` | LiveView `on_mount` hook | Assigns `:operator_actor` and auth metadata. | Use as the source of actor context for tenant discovery. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/mount.ex`] |
| `MailglassAdmin.OptionalDeps.MailglassInbound` | conditional runtime gateway | Calls inbound read models only when optional package is loaded. | Extend with pagination metadata only if inbound remains optional-gated. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Distinct tenant projection | Dedicated persisted tenant read model | Dedicated read model adds migration/backfill/runtime-state risk; choose it only if selector labels require host-owned metadata unavailable from existing records. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`, `lib/mailglass/operator/deliveries.ex`] |
| URL `tenant_id` as durable state | Session-only tenant | Session-only state breaks copied URLs and cross-surface route proof; current code already treats URL params as state. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`] |
| Namespaced cookie for explicit theme | Server-side user/tenant theme preference | Server persistence is out of scope and host-owned; cookie is the locked host-scoped preference seam. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`] |
| Count/page metadata from read model | Infer totals from list length | Current list reads are capped, so length cannot prove total result count. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |

**Installation:** No new package installation is recommended for Phase 112. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/research/v1.13/STACK.md`]

```bash
# none
```

## Package Legitimacy Audit

No external packages should be installed in Phase 112, so the package legitimacy gate is not applicable. The only milestone net-new package is reserved for Phase 116 (`@axe-core/playwright` test-only), not this phase. [VERIFIED: repo: `.planning/research/v1.13/STACK.md`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No install |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Operator request
  |
  v
Operator.Mount on_mount
  |-- Auth.session_actor(session) -> operator_actor
  |-- Auth.authorize(:operator_access, actor)
  v
LiveView handle_params(params, uri)
  |
  |-- theme_choice = URL theme OR namespaced cookie explicit choice
  |      |-- light/dark -> root data-theme mailglass-*
  |      `-- system -> no root data-theme
  |
  |-- Tenant seam
  |      v
  |   Mailglass.Operator.Tenants.list_tenants(operator_actor)
  |      |-- distinct tenant query over existing core records
  |      |-- explicit auth/actor context
  |      `-- Mailglass.Tenancy.scope(query, operator_actor-or-tenant-context)
  |
  |-- Decision
  |      |-- 0 tenants -> no-data/no-access tenant shell state
  |      |-- 1 tenant + no URL tenant_id -> push_patch/redirect with tenant_id
  |      |-- >=2 tenants + no URL tenant_id -> render switcher list
  |      `-- valid URL tenant_id -> load scoped surface data
  |
  v
Read model load
  |-- Deliveries.list_recent_deliveries_page(filters)
  |-- OptionalDeps.MailglassInbound.list_records_page(filters)
  `-- each returns %{entries, total_count, page, per_page, total_pages, has_previous?, has_next?}
  |
  v
Shell + list components
  |-- shared nav_link/nav_pill active cues
  |-- tenant chip/switcher
  |-- result count always
  `-- pagination controls only when total_pages > 1; boundary buttons disabled
```

### Recommended Project Structure

```text
lib/mailglass/operator/
├── tenants.ex          # new core tenant selector projection
├── deliveries.ex       # add paginated delivery list wrapper/metadata
└── ...                 # existing read models

mailglass_inbound/lib/mailglass_inbound/internal/operator/
└── records.ex          # add paginated records wrapper/metadata

mailglass_admin/lib/mailglass_admin/operator/
├── shell.ex            # tenant switcher + tri-state theme path helpers
└── mount.ex            # keep actor assignment; optionally seed theme assign if session carries cookie value

mailglass_admin/lib/mailglass_admin/
├── operator_live.ex    # shared tenant-state flow for deliveries surface
├── inbound_live.ex     # same tenant-state flow through optional inbound gateway
├── layouts.ex          # root explicit-theme mapping from cookie/query assign
└── layouts/root.html.heex
```

### Pattern 1: Core Distinct Tenant Projection

**What:** Add `Mailglass.Operator.Tenants.list_tenants(actor_or_context, opts \\ [])` returning small maps such as `%{id: tenant_id, label: tenant_id}` sorted by id or recency. Use existing record tables as the source and apply `Tenancy.scope/2`. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `lib/mailglass/tenancy.ex`]  
**When to use:** Use now, because shell needs accessible tenant ids only and no host-owned tenant profile metadata is in scope. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]  
**Example:**

```elixir
# Source: repo pattern from lib/mailglass/operator/deliveries.ex
Delivery
|> where([delivery], not is_nil(delivery.tenant_id))
|> distinct([delivery], delivery.tenant_id)
|> order_by([delivery], asc: delivery.tenant_id)
|> select([delivery], %{id: delivery.tenant_id, label: delivery.tenant_id})
|> Tenancy.scope(actor_or_context)
|> Repo.all()
```

Planner note: if the configured `Tenancy.scope/2` only accepts tenant ids and not actor maps, wrap the actor into a documented selector context or use the actor's `:tenant_id` when present. This is an implementation compatibility concern, not permission for raw admin Repo access. [VERIFIED: repo: `lib/mailglass/tenancy.ex`, `mailglass_admin/lib/mailglass_admin/auth.ex`]

### Pattern 2: Tenant Decision Before Data Load

**What:** Resolve `{tenants, selected_tenant_id, tenant_state}` before calling delivery/inbound reads. [VERIFIED: repo: current data loads happen inside `handle_params/3` after filter normalization in `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]  
**When to use:** In both `OperatorLive.handle_params/3` and `InboundLive.handle_params/3`, before `assign_delivery_state/3` or `assign_inbound_state/3`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]  
**Example:**

```elixir
case tenant_state(operator_actor, filter_params["tenant_id"]) do
  {:auto_select, tenant_id} ->
    {:noreply, push_patch(socket, to: put_tenant_id(uri, tenant_id))}

  {:select_required, tenants} ->
    {:noreply, assign(socket, tenants: tenants, tenant_state: :select_required)}

  {:selected, tenant_id, tenants} ->
    socket
    |> assign(:tenants, tenants)
    |> assign(:filter_params, Map.put(filter_params, "tenant_id", tenant_id))
    |> assign_delivery_state(filter_params, delivery_id)
end
```

### Pattern 3: Theme Explicit Choice As Cookie, System As Absence

**What:** Treat `light` and `dark` as explicit preferences stored in a namespaced cookie and rendered by root layout; treat `system` as clearing/removing that explicit preference. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`, `mailglass_admin/lib/mailglass_admin/layouts.ex`]  
**When to use:** On `set_theme` events and root render. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/lib/mailglass_admin/components.ex`]  
**Example:**

```elixir
# Source: repo pattern from mailglass_admin/lib/mailglass_admin/layouts.ex
defp root_theme(%{admin_chrome_theme: theme}) when theme in [:dark, :light],
  do: explicit_theme_attr(Atom.to_string(theme))

defp root_theme(_assigns), do: nil
```

Planner note: LiveView event handlers cannot directly set Plug cookies after the websocket is established without a route/redirect seam. Prefer a same-origin controller endpoint or existing HTTP request seam to set/delete the cookie, then redirect/patch back. If a pure LiveView approach is chosen, verify it truly affects the first HTTP render after reload. [ASSUMED]

### Pattern 4: Pagination Metadata Is A Read-Model Contract

**What:** Return entries plus count/boundary metadata from the tenant-scoped read model; do not infer from `Enum.count(entries)`. [VERIFIED: repo: current list read models return only lists in `lib/mailglass/operator/deliveries.ex` and `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`]  
**When to use:** For deliveries and inbound list panes before rendering result counts and previous/next controls. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`]  
**Example:**

```elixir
%{
  entries: Repo.all(paged_query),
  total_count: Repo.one(count_query),
  page: page,
  per_page: per_page,
  total_pages: max(ceil(total_count / per_page), 1),
  has_previous?: page > 1,
  has_next?: page < total_pages
}
```

### Anti-Patterns to Avoid

- **Admin Repo tenant query:** Bypasses host-app friendliness and tenancy contract; use core read model only. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]
- **Session tenant replacing URL tenant:** Breaks copied URLs and back/forward behavior; use session only as seed/context. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]
- **`data-theme="system"`:** Violates locked system-theme contract; system is absence of explicit theme. [VERIFIED: repo: `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]
- **Pagination from truncated length:** `@default_limit`/`@max_limit` capping makes list length dishonest as total. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`]
- **Always-on pagination bar:** Explicitly out of scope; render controls only when more than one page exists. [VERIFIED: repo: `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tenant authorization | Browser-side filtering or admin Repo query | Core read model + `Mailglass.Tenancy.scope/2` | Existing read models already enforce tenant predicates and tenancy scope. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |
| Theme picker UI | New segmented control markup | Existing `Components.theme_picker/1` | Primitive already owns tri-state radio semantics. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`] |
| Active nav semantics | Page-local nav implementations | Existing `Components.nav_link/1` and `nav_pill/1` | Phase 110 centralized primitive ownership and tests. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Inbound package calls | Direct `MailglassInbound.*` references from LiveView | `MailglassAdmin.OptionalDeps.MailglassInbound` gateway | Optional-deps lane depends on runtime gateway elision. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`] |
| Pagination totals | Client-side `Enum.count(@entries)` total | `Repo.aggregate`/count query in read model | List entries are capped by read model limits. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |

**Key insight:** The shell should compose existing primitives and read models; custom shell-only data access or custom controls would recreate the exact drift v1.13 is eliminating. [VERIFIED: repo: `.planning/research/v1.13/SUMMARY.md`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Tenant Listing Widens Scope

**What goes wrong:** A tenant selector shows ids the authenticated operator should not access. [VERIFIED: repo: tenant listing risk is called out in `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]  
**Why it happens:** A distinct query is written in admin or over raw Repo without the adopter tenancy resolver. [VERIFIED: repo: `.planning/REQUIREMENTS.md`]  
**How to avoid:** Implement in core, apply `Tenancy.scope/2`, and call it with the authenticated actor/context assigned by `Operator.Mount`. [VERIFIED: repo: `lib/mailglass/tenancy.ex`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex`]  
**Warning signs:** `Repo.all` in `mailglass_admin/lib`, tenant selector data derived from session fixtures, or `scope: :unscoped`. [VERIFIED: repo: no recommended admin Repo seam exists in the phase context]

### Pitfall 2: Auto-Select Creates Invisible State

**What goes wrong:** The UI appears scoped but URL lacks `tenant_id`, so refresh/copy/back loses scope. [VERIFIED: repo: existing code documents URL-backed state in `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]  
**Why it happens:** Auto-select assigns `filter_params["tenant_id"]` without patching the route. [ASSUMED]  
**How to avoid:** Auto-select by redirect/push_patch to the canonical URL with `tenant_id`. [VERIFIED: repo: current selection uses `push_patch` path builders in `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]  
**Warning signs:** Tests assert assigns only, not URL patch. [ASSUMED]

### Pitfall 3: Clear Filters Drops Tenant Scope

**What goes wrong:** Clear returns to `base_path` plus theme only, losing `tenant_id`. [VERIFIED: repo: `clear_filters` in `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]  
**Why it happens:** Existing handlers use `socket.assigns.base_path <> theme_query(...)` and do not rebuild from default params with the active tenant. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]  
**How to avoid:** Build clear paths from default filter params merged with active `tenant_id` and current theme choice. [VERIFIED: repo: `default_filter_params/0` and `build_path/4` exist in both LiveViews]  
**Warning signs:** `assert_patch` for clear filters lacks `tenant_id`. [VERIFIED: repo: test grep shows current tests cover filter empty states but not clear preserving tenant]

### Pitfall 4: System Theme Becomes A Stored Concrete Theme

**What goes wrong:** Selecting system stores a resolved dark/light value and stops following OS changes. [VERIFIED: repo: Phase 109/112 contexts lock system as absence of explicit theme]  
**Why it happens:** Developers treat system as a third `data-theme` value or persist `system` as an explicit root theme. [ASSUMED]  
**How to avoid:** Delete/clear explicit theme cookie and query value for system; root layout returns `nil`. [VERIFIED: repo: `MailglassAdmin.Operator.Shell.set_theme_path/2` already removes theme for system, and `Layouts.root_theme/1` returns nil for non-explicit themes]  
**Warning signs:** `data-theme="system"`, `mailglass-system`, or root HTML with explicit data-theme under system tests. [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/components_test.exs` already rejects `data-theme="system"` in primitive output]

### Pitfall 5: Pagination Lies From Cap-Length

**What goes wrong:** UI says "50 results" because the read model returned 50 capped rows when actual total is larger. [VERIFIED: repo: read models have default/max limits in `lib/mailglass/operator/deliveries.ex` and `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`]  
**Why it happens:** UI counts entries instead of asking the database for count under the same filters. [ASSUMED]  
**How to avoid:** Generate a count query from the same tenant/filter pipeline before limit/offset. [VERIFIED: repo: existing filter pipeline functions can be reused in both read modules]  
**Warning signs:** Pagination tests seed 101 rows but display 50 as the total. [VERIFIED: repo: inbound test already proves summary is not derived from capped list in `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`]

## Code Examples

### Existing Tenant-Scoped Delivery Pattern

```elixir
# Source: lib/mailglass/operator/deliveries.ex
Delivery
|> where([delivery], delivery.tenant_id == ^tenant_id)
|> maybe_filter_provider(normalized[:provider])
|> maybe_filter_status(normalized[:status])
|> maybe_filter_event(normalized[:event] || normalized[:last_event_type])
|> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
|> order_by([delivery],
  desc: delivery.last_event_at,
  desc: delivery.inserted_at,
  desc: delivery.id
)
|> limit(^limit)
|> select([delivery], %{id: delivery.id, tenant_id: delivery.tenant_id})
|> Tenancy.scope(tenant_id)
|> Repo.all()
```

### Existing Theme Root Mapping

```elixir
# Source: mailglass_admin/lib/mailglass_admin/layouts.ex
defp root_theme(%{admin_chrome_theme: theme}) when theme in [:dark, :light],
  do: explicit_theme_attr(Atom.to_string(theme))

defp root_theme(_assigns), do: nil
```

### Existing Shell Theme Path Behavior

```elixir
# Source: mailglass_admin/lib/mailglass_admin/operator/shell.ex
def set_theme_path(uri, theme) when is_binary(uri) and is_binary(theme) do
  parsed = URI.parse(uri)
  path = parsed.path || "/"

  query =
    (parsed.query || "")
    |> URI.query_decoder()
    |> Enum.reject(fn {key, _value} -> key == "theme" end)
    |> maybe_append_theme(theme)

  case URI.encode_query(query) do
    "" -> path
    encoded -> path <> "?" <> encoded
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Binary dark toggle | Tri-state primitive with `:system`, `:light`, `:dark` | Phase 110 | Phase 112 should wire persistence/root behavior, not rebuild UI. [VERIFIED: repo: `.planning/STATE.md`, `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Shell-private nav primitives | Shared `Components.nav_link/1` and `nav_pill/1` | Phase 110 | Active cue changes belong in shared primitives and tests. [VERIFIED: repo: `.planning/phases/110-primitives/110-CONTEXT.md`, `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Cross-surface nav dropping tenant | `Shell.surface_paths/4` carries `tenant_id` and dark theme | PR #86 / Phase 109 baseline | Remaining work is selector, auto-select, clear/back/filter/detail persistence proof. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`] |
| Limit-only lists | Needed: paginated read metadata | Phase 112 target | UI cannot honestly paginate until read models return counts/boundaries. [VERIFIED: repo: `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |

**Deprecated/outdated:**

- `dark_chrome` boolean as the primary theme API is now too narrow; keep compatibility only while migrating to tri-state `theme_choice`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`]
- Read-only `tenant_chip` as the only tenant shell surface is insufficient for multi-tenant unscoped state. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`]
- "No tenant selected; add `?tenant_id=...`" copy is a dead-end for Phase 112 and should be replaced by auto-select/listing behavior. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `.planning/REQUIREMENTS.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | LiveView event handlers need an HTTP redirect/controller or equivalent seam to set a cookie that affects first reload. | Pattern 3 | Planner may choose an implementation that updates current DOM but does not provide no-FOUC on the next first paint. |
| A2 | Auto-select without URL patch would create invisible state. | Pitfall 2 | If ignored, SHELL-03 could pass assigns tests but fail copied URL/browser back behavior. |
| A3 | Developers commonly mis-implement system as a concrete stored theme. | Pitfall 4 | Verification must explicitly reject `data-theme="system"` and explicit root theme under system. |
| A4 | Client-side counting from entries is a likely pagination implementation trap. | Pitfall 5 | Pagination could render dishonest totals if planner does not require count-query tests. |

## Open Questions (RESOLVED)

1. **Exact actor-to-tenancy context shape**
   - What we know: `operator_actor` is assigned by `Operator.Mount`, includes `:subject_id` and optional `:tenant_id`, and `Tenancy.scope/2` accepts arbitrary context. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/mount.ex`, `mailglass_admin/lib/mailglass_admin/auth.ex`, `lib/mailglass/tenancy.ex`]
   - RESOLVED: The tenant selector accepts the authenticated `operator_actor` map as its context, documents extraction of `actor[:tenant_id]` when present, and passes that actor/context to `Mailglass.Tenancy.scope/2`. Tests use a custom tenancy resolver to prove scoping. The admin shell does not use raw Repo access. [RESOLVED: orchestrator repo inspection]

2. **Inbound tenant projection source**
   - What we know: Inbound rows live in `mailglass_inbound` behind an optional runtime gateway, while outbound/core deliveries live in `mailglass`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`]
   - RESOLVED: Phase 112 tenant discovery is a unified shell-accessible tenant selector, not outbound-only. The core selector includes distinct outbound tenant ids and unions inbound-only tenant ids through `MailglassAdmin.OptionalDeps.MailglassInbound` when `mailglass_inbound` is loaded. The admin shell consumes one seam and never references `MailglassInbound.*` directly; optional gateway functions may be added or extended as needed. [RESOLVED: orchestrator repo inspection]

3. **Cookie path derivation**
   - What we know: root layout has a mount-aware asset helper using `:mount_path`, and router/session machinery passes mount context. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/layouts.ex`]
   - RESOLVED: Use a namespaced admin theme cookie whose path is scoped to the host/mount path seam. System mode clears/deletes that explicit cookie and never emits `data-theme="system"`. Plans include mounted admin route tests such as `/ops/mail` where the repo's mount-path support is available. [RESOLVED: orchestrator repo inspection]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | ExUnit validation | Not probed in this research artifact | — | Planner can use existing project verification commands. [ASSUMED] |
| Node/npm | Existing Playwright validation | Existing config present | `@playwright/test ^1.59.1` | Structural tests can be skipped only with documented blocker. [VERIFIED: repo: `mailglass_admin/package.json`, `mailglass_admin/e2e/structural.spec.js`] |
| GSD research seam | Optional research-plan/cache | Not available | `gsd-tools.cjs` failed resolving `../../../package.json` | Continued with repo-local required reads; no planning blocker. [VERIFIED: repo/tool run] |

**Missing dependencies with no fallback:** none identified for Phase 112 implementation. [ASSUMED]  
**Missing dependencies with fallback:** GSD research seam unavailable; repo-local required files supplied enough context. [VERIFIED: repo/tool run]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus Playwright structural suite. [VERIFIED: repo: `mailglass_admin/test`, `test/mailglass`, `mailglass_inbound/test`, `mailglass_admin/e2e/structural.spec.js`] |
| Config file | `mix.exs`, `mailglass_admin/mix.exs`, `mailglass_admin/playwright.config.cjs`. [VERIFIED: repo] |
| Quick run command | `mix test test/mailglass/operator/deliveries_test.exs mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs` [ASSUMED] |
| Full suite command | `mix verify.preview` plus `cd mailglass_admin && npm run test:operator-browser` [VERIFIED: repo: `.planning/STATE.md`, `mailglass_admin/package.json`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SHELL-01 | Sole tenant auto-select patches canonical URL and hides picker. | LiveView integration | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs --seed 0` | Existing file; add cases. [VERIFIED: repo] |
| SHELL-02 | Multi-tenant unscoped state renders tenant switcher from core read model and does not query admin Repo. | Unit + LiveView integration | `mix test test/mailglass/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs` | New `tenants_test.exs` needed. [VERIFIED: repo: no file exists] |
| SHELL-03 | Tenant persists through filters, detail/back, clear, nav, theme, and surface switches. | LiveView integration + shell component | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | Existing files; add gaps. [VERIFIED: repo] |
| SHELL-04 | Explicit theme cookie renders root `data-theme` on first paint; system emits no root `data-theme`. | LiveView/root layout + Playwright | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs && cd mailglass_admin && npm run test:operator-browser -- structural.spec.js` | Existing files; add cases. [VERIFIED: repo] |
| SHELL-05 | Desktop and mobile active nav have non-color cue and `aria-current`. | Component + Playwright structural | `mix test mailglass_admin/test/mailglass_admin/components_test.exs mailglass_admin/test/mailglass_admin/operator/shell_test.exs` | Existing files; strengthen cases. [VERIFIED: repo] |
| SHELL-06 | Count always visible; pagination only when >1 page; prev/next disabled on boundaries. | Read-model unit + LiveView/component | `mix test test/mailglass/operator/deliveries_test.exs mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | Existing read-model files; add page metadata tests. [VERIFIED: repo] |

### Sampling Rate

- **Per task commit:** Run focused ExUnit file(s) touched by the task. [ASSUMED]
- **Per wave merge:** Run quick command plus targeted Playwright structural shell tests. [ASSUMED]
- **Phase gate:** Run `mix verify.preview`; run Playwright operator browser suite if shell/theme/pagination DOM changed. [VERIFIED: repo: `.planning/STATE.md`, `mailglass_admin/e2e/structural.spec.js`]

### Wave 0 Gaps

- [ ] `test/mailglass/operator/tenants_test.exs` — new core tenant projection tests for distinct tenants, ordering, blank/nil handling, actor/tenancy scope, and no duplicates. [VERIFIED: repo: file absent by `rg --files`]
- [ ] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — add sole-tenant auto-select, multi-tenant switcher, clear-filters tenant preservation, theme set preserving tenant, detail/back tenant preservation. [VERIFIED: repo: file exists]
- [ ] `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` — mirror tenant persistence and pagination metadata assertions through optional inbound gateway. [VERIFIED: repo: file exists]
- [ ] `mailglass_admin/e2e/structural.spec.js` — add browser proof for no-FOUC cookie/root theme and non-color active cues at both nav levels if not already covered by component tests. [VERIFIED: repo: file exists]
- [ ] `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs` — add paginated metadata/count tests if inbound pagination is implemented in inbound read model. [VERIFIED: repo: file exists]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Existing adopter-owned `MailglassAdmin.Auth` and `Operator.Mount` authorize access before shell reads. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/auth.ex`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex`] |
| V3 Session Management | yes | Theme cookie must be non-auth, namespaced, host-scoped; tenant remains URL state, not privileged session state. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`] |
| V4 Access Control | yes | Tenant listing and data reads use core read models plus `Tenancy.scope/2`; no cross-tenant aggregate view. [VERIFIED: repo: `lib/mailglass/tenancy.ex`, `.planning/REQUIREMENTS.md`] |
| V5 Input Validation | yes | Existing filter normalization allow-lists enums and windows; pagination params should use positive integer parsing and caps. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `lib/mailglass/operator/deliveries.ex`] |
| V6 Cryptography | no | No cryptographic feature in scope; do not add crypto for theme or tenant selector. [ASSUMED] |

### Known Threat Patterns for Phoenix LiveView Admin Shell

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tenant enumeration leak | Information Disclosure | Scope selector query through `Tenancy.scope/2` and actor context; test custom resolver denies foreign tenants. [VERIFIED: repo: `lib/mailglass/tenancy.ex`, `mailglass_admin/lib/mailglass_admin/operator/mount.ex`] |
| Query param tampering for tenant/detail id | Elevation of Privilege / Information Disclosure | Read models must filter by active `tenant_id`; detail not found outside tenant surfaces error and blocks actions. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`] |
| Pagination count widening | Information Disclosure | Count query must reuse same tenant/filter pipeline as entries query before limit/offset. [VERIFIED: repo: current filter pipelines in `lib/mailglass/operator/deliveries.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`] |
| Theme cookie collision with host | Spoofing / Tampering | Use namespaced cookie and path scope; never store auth or tenant authority in theme cookie. [VERIFIED: repo: `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`] |
| XSS through tenant label | Tampering / XSS | Keep tenant labels as HEEx-escaped text; do not render raw HTML labels. [VERIFIED: repo: current component text interpolation in `mailglass_admin/lib/mailglass_admin/components.ex`] |

## Sources

### Primary (HIGH confidence)

- `.planning/STATE.md` - milestone locks, Phase 109-111 carried decisions, shell/tenant/theme scope. [VERIFIED: repo]
- `.planning/ROADMAP.md` - Phase 112 success criteria and research flag. [VERIFIED: repo]
- `.planning/REQUIREMENTS.md` - SHELL-01..06 and out-of-scope constraints. [VERIFIED: repo]
- `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md` - locked phase decisions. [VERIFIED: repo]
- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` - system theme, no `data-theme="system"`, root behavior. [VERIFIED: repo]
- `.planning/phases/110-primitives/110-CONTEXT.md` - public primitive ownership and theme picker boundary. [VERIFIED: repo]
- `.planning/phases/111-forms/111-CONTEXT.md` - form boundary; confirms shell tenant/theme/pagination deferred to Phase 112. [VERIFIED: repo]
- `.planning/research/v1.13/SUMMARY.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `STACK.md` - milestone synthesis, tenant seam flag, pitfalls, stack constraints. [VERIFIED: repo]
- `lib/mailglass/operator/deliveries.ex`, `lib/mailglass/tenancy.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` - read model and tenancy implementation. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/auth.ex`, `operator/mount.ex`, `operator/shell.ex`, `components.ex`, `layouts.ex`, `root.html.heex`, `operator_live.ex`, `inbound_live.ex`, list components - shell implementation. [VERIFIED: repo]
- `test/mailglass/operator/deliveries_test.exs`, `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs`, `mailglass_admin/test/...`, `mailglass_admin/e2e/structural.spec.js` - test infrastructure and gaps. [VERIFIED: repo]

### Secondary (MEDIUM confidence)

- None used; external documentation lookup was not necessary for this repo-scoped planning research. [VERIFIED: repo]

### Tertiary (LOW confidence)

- Assumptions logged in `## Assumptions Log`, mainly around LiveView cookie-setting mechanics and expected implementation traps. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - Current versions and components were read directly from repo files. [VERIFIED: repo]
- Architecture: HIGH - All primary seams were inspected in source and tests. [VERIFIED: repo]
- Tenant projection recommendation: MEDIUM - Distinct projection is repo-grounded and lowest-risk, but exact adopter tenancy context shape still needs implementation proof. [VERIFIED: repo][ASSUMED]
- Theme no-FOUC mechanics: MEDIUM - Root/theme primitives are verified; cookie write/read implementation path needs a focused implementation decision. [VERIFIED: repo][ASSUMED]
- Pitfalls: HIGH - Pitfalls map to existing code and milestone locks. [VERIFIED: repo]

**Research date:** 2026-06-19  
**Valid until:** 2026-07-19 for repo-local architecture; revisit if Phase 116 fixture/routing changes land before execution. [ASSUMED]
