# Phase 112: App-Shell, Navigation & Tenant Seam - Context

**Gathered:** 2026-06-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Fourth implementation phase of milestone v1.13 (Admin Design-System Stress Test & UX Uplift).
Scope: the admin app shell fixes the lived multi-tenant dead end and shell-level rough edges:
sole-tenant auto-select, a scoped tenant listing/switcher when multiple tenants exist, tenant
scope preservation across all admin surfaces, no-FOUC tri-state theme persistence, active
navigation with non-color cues, and honest pagination affordances.

Hard scope line: Phase 112 does not own responsive table-to-card data display, distinct
empty/error/permission/stale templates beyond the tenant shell seam, page-level IA/microcopy
passes, the multi-tenant stress-fixture cohort, axe JSON baselining, or full matrix re-scoring.
Those remain in phases 113-116. Tenant listing is selector/shell infrastructure only: no
cross-tenant aggregate view, no tenant CRUD, no pin/favorite tenants, and no raw admin Repo access.

Requirements: SHELL-01, SHELL-02, SHELL-03, SHELL-04, SHELL-05, SHELL-06.
</domain>

<decisions>
## Implementation Decisions

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

### Claude's Discretion

- Exact tenant projection implementation, after light planning research resolves distinct-tenant
  query versus dedicated read model.
- Exact cookie name and assign names, provided they are host-scoped/namespaced and preserve the
  tri-state theme contract.
- Exact visible non-color active-state treatment for nav primitives, provided it reuses the shared
  component surface and remains accessible.
- Exact pagination metadata shape, provided counts and page boundaries are real and tenant-safe.

### Folded Todos

None - `todo.match-phase 112` returned no foldable matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 112 goal, success criteria, and research flag for tenant listing.
- `.planning/REQUIREMENTS.md` - SHELL-01..06 acceptance text and v1.13 scope locks.
- `.planning/PROJECT.md` - v1.13 milestone intent, scope locks, D-23/D-28/D-29, and no-scope-creep
  boundaries.
- `.planning/STATE.md` - current milestone state and carried decisions from phases 109-111.
- `.planning/METHODOLOGY.md` - decisive-by-default and recommendation-first methodology.
- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` - inherited token,
  z-layer, focus-ring, and system-theme decisions.
- `.planning/phases/110-primitives/110-CONTEXT.md` - inherited public primitive ownership and
  `theme_picker` / nav primitive decisions.
- `.planning/phases/111-forms/111-CONTEXT.md` - inherited form-surface boundary; confirms tenant,
  theme, nav, and pagination are Phase 112 scope.
- `.planning/research/v1.13/SUMMARY.md` - v1.13 research synthesis.
- `.planning/research/v1.13/ARCHITECTURE.md` - app-shell/tenant and ratchet architecture context.
- `.planning/research/v1.13/PITFALLS.md` - named tenant-scoping dead end, theme FOUC, and
  lived-experience pitfalls.
- `.planning/research/v1.13/STACK.md` - host-app-friendly and zero-Node asset boundaries.
- `lib/mailglass/operator/deliveries.ex` - existing core operator read-model scoping pattern.
- `lib/mailglass/tenancy.ex` - tenant scoping seam downstream planning must compose with.
- `mailglass_admin/lib/mailglass_admin/auth.ex` - `operator_actor` / session actor shape.
- `mailglass_admin/lib/mailglass_admin/operator/mount.ex` - admin mount hook assigns
  `:operator_actor`.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - shell navigation, surface paths,
  theme path helpers, and tenant chip integration.
- `mailglass_admin/lib/mailglass_admin/components.ex` - public primitives: `nav_link`, `nav_pill`,
  `tenant_chip`, `theme_picker`.
- `mailglass_admin/lib/mailglass_admin/layouts.ex` - root theme mapping for explicit light/dark
  versus system.
- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` - root `data-theme` rendering seam.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - operator surface tenant/filter/path
  integration and current no-tenant state.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - inbound surface tenant/filter/path
  integration.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - current delivery list display
  without count/pagination.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - current inbound list display
  without count/pagination.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` - current inbound
  operator read model limit-only shape.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - shell path/nav behavior tests.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - operator tenant-scope path
  regression tests.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.Components.nav_link/1` and `nav_pill/1` already centralize active nav semantics
  and should remain the only primitive implementation.
- `MailglassAdmin.Components.tenant_chip/1` provides the existing tenant display primitive, but
  currently supports a passive "No tenant selected" state rather than a listing/switcher workflow.
- `MailglassAdmin.Components.theme_picker/1` already models `:system`, `:light`, and `:dark`; Phase
  112 should wire persistence and first paint rather than rebuilding the primitive.
- `MailglassAdmin.Operator.Shell.surface_paths/4` and LiveView `build_path` helpers already carry
  `tenant_id` through many surface transitions.
- `MailglassAdmin.Layouts.root_theme/1` and `root.html.heex` already support server-rendered
  explicit light/dark and nil/system behavior.

### Established Patterns

- Operator reads belong in core read-model modules and apply tenant scoping; admin is a consumer,
  not a raw data owner.
- Shared admin primitives live in `MailglassAdmin.Components`; shell/page modules compose them.
- System theme is absence of explicit theme, not a third concrete `data-theme` value.
- Shell state that should survive refresh/copy-link uses URL params, especially `tenant_id`.
- Structural proof and deterministic tests are preferred over screenshots or pixel diffs.

### Integration Points

- Core tenant listing likely touches `lib/mailglass/operator/*` and composes with
  `Mailglass.Tenancy.scope/2`.
- Admin tenant selection/listing connects through `mailglass_admin/lib/mailglass_admin/operator/mount.ex`,
  `auth.ex`, `operator/shell.ex`, `operator_live.ex`, and `inbound_live.ex`.
- Theme persistence connects through mount/session/cookie handling plus `layouts.ex`,
  `root.html.heex`, and shell theme picker paths/events.
- Pagination requires read-model metadata changes before UI chrome can be honest.
- Regression proof should extend shell/component tests, operator/inbound LiveView tests, and the
  existing Playwright structural suite where browser behavior matters.
</code_context>

<specifics>
## Specific Ideas

- Treat tenant listing as a selector/switcher, not an admin tenant management feature.
- Prefer a scoped core `list_tenants` read model that returns only the fields needed for shell
  selection, such as tenant id and display label/count metadata if already available.
- Auto-select exactly one accessible tenant by patching or redirecting into the normal URL-scoped
  route so the visible/copyable URL matches the active tenant.
- Use a namespaced cookie key for explicit theme choice, and clear/delete that key for `system`.
- Keep pagination language honest: "N results" always, prev/next only when a real next/previous
  page exists.
</specifics>

<deferred>
## Deferred Ideas

- Responsive table-to-card transforms for deliveries/inbound lists - Phase 113.
- Distinct empty/error/permission/stale data-display templates beyond the tenant shell seam -
  Phase 113.
- GOV.UK-style full page IA and tenant/permission/stale microcopy pass - Phase 115.
- Multi-tenant stress-fixture cohort and gallery stress specimens - Phase 116.
- Axe JSON baseline, interaction pillar, and full matrix re-score - Phase 116.
- Cross-tenant aggregate views, tenant CRUD/invites, tenant pins/favorites, server-persisted
  per-user/per-tenant theme, infinite scroll, and always-on pagination bars - out of scope.

### Reviewed Todos (not folded)

None - `todo.match-phase 112` returned no foldable matches.
</deferred>
