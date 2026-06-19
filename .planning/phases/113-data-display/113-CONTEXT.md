# Phase 113: Data-Display - Context

**Gathered:** 2026-06-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 113 owns the admin data-display layer for `mailglass_admin`: responsive delivery and inbound
record lists, KPI/stat-card consistency, status/severity encoding, distinct data-state templates,
and long-value handling. It builds on the fixed Phase 109-112 foundations, primitives, forms,
tenant, theme, navigation, and pagination work. It does not redesign composed component groups,
whole-page IA, motion, microcopy passes, live refresh, fixture-cohort expansion, release mechanics,
recipient-facing email templates, or `brandbook/` tokens.
</domain>

<decisions>
## Implementation Decisions

### Responsive Data Lists

- **D-01:** Deliveries and inbound records keep the existing master-detail URL and selection
  behavior, but their current list-only row markup is upgraded into semantic data tables at
  `>=768px` and card/list presentations below `768px`.
- **D-02:** The table/card implementation must preserve Phase 112 pagination behavior: result
  count always visible, pagination chrome only for multiple pages, and disabled boundary controls.
  Do not re-litigate or fake count/page metadata.

### Canonical KPI And Severity Encoding

- **D-03:** Phase 113 reuses `MailglassAdmin.Components.stat_card/1` and `status_badge/1` as the
  canonical KPI and status primitives. Planning should widen certification and migration coverage,
  not create new stat/status components.
- **D-04:** Severity/status remains icon + visible label + color. Color-only, icon-only, and bare
  placeholder states are regressions. "All clear" must render as a real, readable state.

### Distinct Data States

- **D-05:** DATA-03 is satisfied with distinct reusable data-state templates for no-data,
  unavailable/error, permission-denied, and stale-data. Current true-empty, filtered, and no-tenant
  branches can seed the no-data variants, but permission/stale/unavailable must not collapse into
  generic empty/error copy.
- **D-06:** Live-refresh mechanics are out of scope. Stale-data means the admin can honestly render
  a stale/unavailable state when the current read/display data is known to be stale or unavailable;
  it does not require polling, streams, or auto-refresh.

### Long Real-World Values And Proof

- **D-07:** Long values are handled with truncate + tooltip/title, expansion, wrapping, or another
  deterministic pattern chosen per field. UUIDs, tenant ids, provider ids, module/function names,
  URLs, subjects, non-ASCII names, and timestamps must never overflow, chop incoherently, or force
  horizontal scrolling.
- **D-08:** Proof stays inside existing repo-local lanes: component tests, gallery specimens,
  Playwright structural assertions, conformance gates, and realistic demo/test data. No pixel diff,
  screenshot baseline, runtime dependency, or new asset pipeline is introduced for this phase.

### Claude's Discretion

- Exact table column set and card field ordering, provided the operator can scan status, recipient
  or mailbox, tenant, provider, event/outcome, and timestamp without losing selection semantics.
- Exact shared component shape for data-state templates, if planning finds a small reusable helper
  cleaner than page-local markup.
- Exact tooltip/truncation implementation per field, provided accessible names and long-value proof
  hold across light/dark/system and mobile/desktop breakpoints.

### Folded Todos

None - `todo.match-phase 113` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 113 goal and success criteria.
- `.planning/REQUIREMENTS.md` - DATA-01..05 acceptance text and v1.13 scope locks.
- `.planning/PROJECT.md` - v1.13 milestone intent, scope locks, D-23/D-28/D-29, and release posture.
- `.planning/STATE.md` - current milestone state and carried decisions from phases 109-112.
- `.planning/METHODOLOGY.md` - decisive-by-default and recommendation-first methodology.
- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` - inherited token,
  focus-ring, z-layer, system-theme, and structural-gate decisions.
- `.planning/phases/110-primitives/110-CONTEXT.md` - inherited public primitive ownership,
  `stat_card`, `status_badge`, icon inventory, and gallery certification decisions.
- `.planning/phases/111-forms/111-CONTEXT.md` - inherited form/focus proof boundaries.
- `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md` - inherited tenant,
  theme, navigation, and pagination decisions.
- `.planning/research/v1.13/SUMMARY.md` - v1.13 research synthesis.
- `.planning/research/v1.13/ARCHITECTURE.md` - data-display/component-lab and ratchet context.
- `.planning/research/v1.13/PITFALLS.md` - lab-passes-but-ugly and usability-defect context.
- `.planning/research/v1.13/STACK.md` - zero-Node asset boundary and structural/axe proof context.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - current deliveries list,
  result count, pagination, empty branches, row selection, status rendering, and long-value handling.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - current inbound records list,
  result count, pagination, empty branches, row selection, outcome rendering, and long-value handling.
- `mailglass_admin/lib/mailglass_admin/components.ex` - public `stat_card/1`, `status_badge/1`,
  `icon/1`, and masking helpers.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - operator overview KPI usage,
  deliveries list integration, detail errors, and page metadata.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - inbound overview/list integration,
  detail errors, empty-state selection, and page metadata.
- `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` - inbound KPI/stat-card usage.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - component-lab specimens and long-value
  stress examples.
- `mailglass_admin/e2e/structural.spec.js` - responsive, overflow, target-size, system-theme,
  stat-card, and data-display structural proof machinery.
- `mailglass_admin/scripts/check-conformance.sh` - deterministic no-drift gate pattern.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - operator list/detail/state
  regression tests.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - inbound list/detail/state
  regression tests.
- `mailglass_admin/test/mailglass_admin/components_test.exs` - shared component contract tests.
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - realistic demo data and long-value stress
  inputs.
- `lib/mailglass/operator/deliveries.ex` - core operator delivery read model fields.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` - inbound operator read
  model fields.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.Components.stat_card/1` already exists and is consumed by operator and inbound
  overview surfaces.
- `MailglassAdmin.Components.status_badge/1` already renders status with icon, visible label, and
  semantic badge classes.
- Current deliveries and inbound list modules already centralize result count, pagination controls,
  selected-row state, empty branches, and row metadata.
- The gallery already contains long-label/stat specimens that can be widened for data-display
  coverage.

### Established Patterns

- Shared admin UI primitives live in `MailglassAdmin.Components`; page-local duplicate primitives
  are treated as drift.
- Verification is structural and deterministic: ExUnit component/live tests, Playwright structural
  assertions, conformance grep gates, and committed CSS bundle cleanliness.
- System theme remains absence of explicit `data-theme`; all Phase 113 proof should cover
  light/dark/system without introducing theme hooks.
- Pagination and tenant scope are URL-backed and already inherited from Phase 112.

### Integration Points

- `OperatorLive` passes deliveries, selected delivery, page metadata, and pagination paths into
  `Operator.DeliveriesList.deliveries_list/1`.
- `InboundLive` passes records, selected record, page metadata, pagination paths, and empty-state
  atom into `Inbound.RecordsList.records_list/1`.
- Data-state templates may plug into list components, detail error areas, and gallery specimens.
- Long-value proof should exercise real read-model fields from `Mailglass.Operator.Deliveries` and
  `MailglassInbound.Internal.Operator.Records`, plus demo stress data.
</code_context>

<specifics>
## Specific Ideas

- Use a breakpoint-only dual presentation: a desktop semantic table and a mobile card/list view,
  both fed by the same assigns and preserving the same LiveView events/patches.
- Keep selected/current row/card cues non-color-only, reusing the existing border/aria semantics
  where possible.
- Treat "Pending", "Unknown", "No match", "Tracked", and "All clear" as meaningful text states,
  not placeholders.
- Add title/tooltip or accessible expansion for record IDs, tenant labels, provider IDs, mailbox
  names, timestamps, and recipient/subject-like fields where truncation is used.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 113 scope.

### Reviewed Todos (not folded)

None.
</deferred>
