# Phase 22: Operator Data Foundation - Research

**Researched:** 2026-04-30
**Domain:** Operator-facing delivery, event-ledger, and suppression data foundation for `mailglass_admin`
**Confidence:** HIGH

<user_constraints>
## User Constraints (from available phase artifacts)

### Locked Decisions
- Phase 22 must expose only three operator data areas: recent deliveries, delivery event timeline, and suppression visibility/removability state. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]
- Phase 22 is read-only. It must not ship replay actions, suppression mutations, auth prompts, or production-safe mounting decisions; those belong to later phases. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md][VERIFIED: .planning/ROADMAP.md]
- The operator UI should extend the existing `mailglass_admin` LiveView stack and visual language rather than introduce a new frontend stack or custom JS state model. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md][VERIFIED: mailglass_admin/README.md]
- Selected delivery and active filters should persist in the URL, and the detail pane should update in place instead of navigating to a separate page. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]
- Suppression reversibility is informational only in this phase and must be expressed as state text, not a disabled mutation control. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]

### the agent's Discretion
- Exact module names and query API boundaries between core `mailglass` and `mailglass_admin`.
- Exact filter primitives, as long as they remain tenant-aware and compact.
- Exact projection shape returned to the LiveView, provided it can render timeline rows and suppression state without ad hoc business logic in templates.

### Missing Context Note
- No `22-CONTEXT.md` exists. Planning should treat `22-UI-SPEC.md`, the roadmap goal, and `ADMIN-02..04` as the authoritative input set for this phase. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADMIN-02 | Operator can browse recent deliveries with tenant-aware filtering. | Requires a query seam over `Mailglass.Outbound.Delivery` that exposes recent rows, tenant scoping, and compact filter primitives suitable for URL-backed LiveView state. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: lib/mailglass/outbound/delivery.ex] |
| ADMIN-03 | Operator can open a delivery and inspect a chronological event timeline derived from the append-only ledger. | Requires a read-only timeline query over `Mailglass.Events.Event`, filtered by tenant and `delivery_id`, preserving append-only ordering without mutating ledger semantics. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: lib/mailglass/events/event.ex] |
| ADMIN-04 | Operator can view suppression entries and see whether each entry is removable or immutable, with the reason surfaced in the UI. | Requires a read model over `Mailglass.Suppression.Entry` that explains scope, reason, and reversibility policy without exposing write actions. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: lib/mailglass/suppression/entry.ex] |
</phase_requirements>

## Summary

Phase 22 is the first operator-oriented data surface in the repo. The core domain seams already exist in `Mailglass.Outbound.Delivery`, `Mailglass.Events.Event`, and `Mailglass.Suppression.Entry`, while `mailglass_admin` already ships a router macro, a mountable LiveView entry point, shared components, and test helpers oriented around a single LiveView page. The missing piece is an operator read model and a new admin LiveView surface that can query those three data sources safely and present them inside the existing package. [VERIFIED: lib/mailglass/outbound/delivery.ex][VERIFIED: lib/mailglass/events/event.ex][VERIFIED: lib/mailglass/suppression/entry.ex][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/lib/mailglass_admin/preview_live.ex]

The planning-critical architectural choice is to keep business queries in core `mailglass` and keep `mailglass_admin` as a thin LiveView consumer. The admin package currently owns UI rendering and mount plumbing, but the authoritative schemas live in the core library. That argues for a phase split between: `1.` a core operator data/query seam and `2.` an admin LiveView that consumes it. This keeps tenant scoping, ledger ordering, and suppression policy interpretation centralized instead of duplicating them in the admin package. [VERIFIED: mailglass_admin/README.md][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: lib/mailglass/outbound/delivery.ex][VERIFIED: lib/mailglass/events/event.ex][VERIFIED: lib/mailglass/suppression/entry.ex]

The highest-risk area is tenant-safe querying. Existing schemas include `tenant_id`, but the research did not surface an already-shipped operator query module, so plans should force explicit read APIs and tests for tenant filtering, timeline ordering, and suppression-state derivation rather than letting the eventual executor assemble ad hoc Ecto queries inside the LiveView. [VERIFIED: lib/mailglass/outbound/delivery.ex][VERIFIED: lib/mailglass/events/event.ex][VERIFIED: lib/mailglass/suppression/entry.ex]

**Primary recommendation:** plan Phase 22 as multiple executable slices: `22-01` core operator read model/query API, `22-02` admin LiveView route/screen shell with URL-backed selection/filter state, and `22-03` tests and polish for timeline/suppression rendering and empty/error states. [INFERENCE from codebase structure and phase scope]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Recent deliveries query | API / Backend | Database / Storage | Delivery data originates in `Mailglass.Outbound.Delivery`; query logic should stay near the schema and tenancy rules. [VERIFIED: lib/mailglass/outbound/delivery.ex] |
| Event timeline query | API / Backend | Database / Storage | The append-only ledger is represented by `Mailglass.Events.Event`; ordering and filtering belong in a read API, not template logic. [VERIFIED: lib/mailglass/events/event.ex] |
| Suppression visibility / reversibility projection | API / Backend | Database / Storage | Reversibility is policy-derived state over `Mailglass.Suppression.Entry`; the admin UI should consume a projection rather than infer policy ad hoc. [VERIFIED: lib/mailglass/suppression/entry.ex][VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md] |
| Operator screen rendering | Frontend Server (SSR) | API / Backend | `mailglass_admin` is already a Phoenix LiveView package with shared components and router mount points. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/lib/mailglass_admin/preview_live.ex] |
| URL-backed filter / selection state | Frontend Server (SSR) | API / Backend | LiveView can manage params and render state, but the filter semantics should remain constrained by backend query APIs. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview_live.ex][VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md] |
| Admin test harness | Frontend Server (SSR) | API / Backend | `Mailglass.AdminCase` and existing admin LiveView tests provide the shape for interactive rendering tests. [VERIFIED: test/support/admin_case.ex][VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs] |

## Standard Stack

### Core

| Library / Module | Purpose | Why Standard |
|------------------|---------|--------------|
| `Ecto` query layer over existing schemas | delivery, event, and suppression read APIs | The repo already models all required data in Ecto schemas; Phase 22 is a read-model phase, not a persistence redesign. [VERIFIED: lib/mailglass/outbound/delivery.ex][VERIFIED: lib/mailglass/events/event.ex][VERIFIED: lib/mailglass/suppression/entry.ex] |
| Phoenix LiveView | operator list/detail surface | `mailglass_admin` already ships a single LiveView page and supporting components, so Phase 22 should reuse that interaction model. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview_live.ex] |
| Existing `mailglass_admin` components + CSS | cards, badges, icons, spacing, flash states | The UI spec explicitly requires reuse of current admin primitives and forbids a second token system. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md][VERIFIED: mailglass_admin/lib/mailglass_admin/components.ex] |

### Supporting

| Library / Module | Purpose | When to Use |
|------------------|---------|-------------|
| `Mailglass.AdminCase` / LiveView tests | route, render, filter, selection, and state assertions | Use for every admin-facing slice so the new operator surface matches the existing testing style. [VERIFIED: test/support/admin_case.ex][VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs] |
| Existing preview LiveView patterns | param-driven `handle_params/3`, event handlers, shared assigns | Reuse for operator screen mechanics such as URL-backed state and in-place detail updates. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview_live.ex] |

## Recommended Project Structure

```text
lib/mailglass/
├── operator/                         # new read-model namespace
│   ├── deliveries.ex                 # recent delivery query + filters
│   ├── timeline.ex                   # delivery event timeline query
│   └── suppressions.ex               # suppression visibility/reversibility projection

mailglass_admin/lib/mailglass_admin/
├── router.ex                         # add operator route(s) without breaking preview
├── operator_live.ex                  # new operator LiveView surface
├── operator/
│   ├── filters_form.ex               # compact filter controls
│   ├── deliveries_list.ex            # list/row rendering
│   ├── detail_header.ex              # selected delivery summary
│   ├── timeline.ex                   # read-only event timeline rendering
│   └── suppression_card.ex           # suppression state card

mailglass_admin/test/mailglass_admin/
├── operator_live_test.exs            # primary UI interaction coverage

test/mailglass/operator/
├── deliveries_test.exs               # tenant-aware filtering
├── timeline_test.exs                 # chronological ordering + tenant scoping
└── suppressions_test.exs             # reversibility / immutability projection
```

## Architecture Patterns

### Pattern 1: Core Query Seam, Thin LiveView Consumer

**What:** Put recent-delivery, timeline, and suppression read logic in core `mailglass` modules and have the admin LiveView consume shaped structs/maps.

**When to use:** For every Phase 22 data fetch path.

**Why:** This preserves tenant filtering and domain-policy logic outside the UI package and makes the data foundation reusable by later phases like production mounting and replay/suppression actions. [INFERENCE from phase dependencies][VERIFIED: .planning/ROADMAP.md]

### Pattern 2: URL-Backed List/Detail LiveView

**What:** Use a single LiveView with param-backed filters and selected delivery state, following the existing `handle_params/3` pattern from `PreviewLive`.

**When to use:** For list selection, filter submission, refresh/back behavior, and in-place detail updates.

**Example analog:** `MailglassAdmin.PreviewLive` already uses route params, assigns, and event handlers to keep one page live while changing internal state. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview_live.ex]

### Pattern 3: Read-Only Projection for Suppression Reversibility

**What:** Derive a UI-facing suppression state object that carries `reason`, `scope`, and a boolean or enum for reversibility, then map that to the required copy in the LiveView.

**When to use:** Whenever the UI needs to say `Reversible in a later phase` vs `Immutable by policy`.

**Why:** The schema itself stores scope/reason/expiry, but the UI contract needs policy language, not raw DB semantics. [VERIFIED: lib/mailglass/suppression/entry.ex][VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]

## Anti-Patterns to Avoid

- Do not embed raw Ecto queries directly inside the LiveView event handlers. That would couple UI flow to tenant/data policy and make later actions harder to secure.
- Do not mutate deliveries, events, or suppressions in this phase. The roadmap and UI contract make this read-only groundwork. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]
- Do not invent a separate JS state layer or custom client runtime for row selection and filters. The existing package is LiveView-first. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md][VERIFIED: mailglass_admin/README.md]
- Do not infer suppression removability from copy alone in templates; compute it once in a backend projection and render the result consistently.
- Do not let timeline ordering drift between query order and visual order. The UI contract explicitly requires DOM and visible chronology to match. [VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]

## Common Pitfalls

### Pitfall 1: Leaking tenant scope into UI code

**What goes wrong:** The LiveView builds ad hoc filters over delivery/event tables and quietly bypasses tenant constraints.

**How to avoid:** Centralize every Phase 22 query behind explicit core functions that require tenant-aware inputs and are covered by backend tests.

### Pitfall 2: Treating the event ledger like a mutable status feed

**What goes wrong:** The UI or query layer tries to synthesize timeline order from delivery projection columns instead of reading the append-only `mailglass_events` rows.

**How to avoid:** Build timeline data from `Mailglass.Events.Event` ordered by occurrence and backed by the ledger, then use delivery projection fields only for the list/header summary. [VERIFIED: lib/mailglass/events/event.ex][VERIFIED: lib/mailglass/outbound/delivery.ex]

### Pitfall 3: Mixing preview-only and operator routes carelessly

**What goes wrong:** Router changes destabilize the preview mount or overload the existing `PreviewLive` route contract.

**How to avoid:** Add a distinct operator LiveView route/module rather than stretching `PreviewLive` into two unrelated surfaces. [INFERENCE from existing admin route shape]

### Pitfall 4: UI tests that only assert happy-path rendering

**What goes wrong:** Empty states, no-selection copy, and missing timeline/suppression cases drift from the approved copy contract.

**How to avoid:** Include literal-string assertions for empty states, selection prompts, and suppression state text in admin LiveView tests, matching the style of existing preview tests. [VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs][VERIFIED: .planning/phases/22-operator-data-foundation/22-UI-SPEC.md]

## Validation Focus

- Backend tests must prove tenant-aware recent-delivery filtering, stable timeline ordering, and suppression reversibility derivation.
- LiveView tests must prove URL-backed selection/filter state, desktop/mobile-safe rendering structure, selection semantics, and required empty/error copy.
- Plans should keep preview behavior green; router and shared component changes must not regress the existing preview surface. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs]

