# Phase 22: Operator Data Foundation — Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/operator/deliveries.ex` | backend query | delivery list read model | `lib/mailglass/outbound/delivery.ex` schema + existing Ecto query usage in tests | strong |
| `lib/mailglass/operator/timeline.ex` | backend query | event-ledger read model | `lib/mailglass/events/event.ex` | exact domain seam |
| `lib/mailglass/operator/suppressions.ex` | backend projection | suppression state read model | `lib/mailglass/suppression/entry.ex` | exact domain seam |
| `test/mailglass/operator/deliveries_test.exs` | backend test | tenant/filter verification | existing schema-oriented tests under `test/mailglass/**` | strong |
| `test/mailglass/operator/timeline_test.exs` | backend test | ordering / tenant verification | `test/mailglass/events/reconciler_test.exs` fixture/query style | strong |
| `test/mailglass/operator/suppressions_test.exs` | backend test | policy projection verification | `test/mailglass/suppression/entry_test.exs` / suppression tests | strong |
| `mailglass_admin/lib/mailglass_admin/router.ex` | router | mount new operator route | same file’s preview route pattern | exact |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | LiveView page | list/detail operator surface | `mailglass_admin/lib/mailglass_admin/preview_live.ex` | exact mechanics |
| `mailglass_admin/lib/mailglass_admin/operator/*.ex` | UI components | list, filters, header, timeline, suppression card | preview component modules such as `preview/sidebar.ex`, `preview/tabs.ex`, `preview/device_frame.ex` | strong |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | LiveView test | render + interaction assertions | `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | exact |
| `test/support/admin_case.ex` | shared test support | admin LiveView test harness | same file | exact extension point |

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/router.ex`

**Analog:** existing preview mount pattern.

```elixir
live "/", MailglassAdmin.PreviewLive, :index
live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
```

**Apply in Phase 22:** add distinct operator routes and a new LiveView module instead of overloading `PreviewLive`.

### `mailglass_admin/lib/mailglass_admin/preview_live.ex`

**Analog:** param-driven LiveView state with `handle_params/3`, event handlers, and stable assigns initialization.

```elixir
def handle_params(%{"mailable" => mod_str, "scenario" => name_str}, _uri, socket) do
  ...
end
```

**Apply in Phase 22:** use the same mechanics for selected delivery and filter params so refresh/back preserve operator state.

### `mailglass_admin/test/mailglass_admin/preview_live_test.exs`

**Analog:** literal-string render assertions plus `render_click/3` and `render_change/3`.

```elixir
{:ok, view, _html} = live(conn, "/dev/mail/...")
after_change = render_change(view, "assigns_changed", %{"assigns" => ...})
```

**Apply in Phase 22:** test filter submission, delivery selection, no-selection copy, empty states, and suppression text using the same interaction style.

### `lib/mailglass/outbound/delivery.ex`

**Analog:** canonical source of recent-delivery projection fields such as `tenant_id`, `recipient`, `provider`, `status`, `last_event_type`, and `last_event_at`.

**Apply in Phase 22:** the list pane should source its summary rows from delivery projection columns instead of recomputing state from ledger rows.

### `lib/mailglass/events/event.ex`

**Analog:** append-only event ledger schema with `delivery_id`, `type`, `occurred_at`, `metadata`, and `normalized_payload`.

**Apply in Phase 22:** timeline queries should read directly from this schema ordered chronologically for a selected delivery.

### `lib/mailglass/suppression/entry.ex`

**Analog:** canonical suppression schema with `scope`, `stream`, `reason`, `source`, `expires_at`, and `metadata`.

**Apply in Phase 22:** compute a read-only suppression card from these fields and render reversibility as derived policy text.

### `test/support/admin_case.ex`

**Analog:** repo-sanctioned extension point for admin LiveView test support.

**Apply in Phase 22:** if new operator tests need helper imports or fixtures, extend this case rather than creating an unrelated harness.

## Sequencing Constraint

1. Establish backend operator query/projection modules and their tests first.
2. Add the operator LiveView and route wiring second.
3. Finish with interaction, empty/error, and copy-level UI tests once the data seam is stable.

This ordering keeps the admin screen from inventing data semantics before the core query contract exists.

## Notes for Planner

- The current admin package has a single preview surface; Phase 22 should avoid mixing preview-only and operator-only state in one LiveView.
- The UI spec is approved and should be treated as locked visual/interaction input even though `22-CONTEXT.md` is absent.
- Phase 23 depends on this work, so plan boundaries should leave a clean handoff for production mount/auth work rather than trying to solve those concerns now. [VERIFIED: .planning/ROADMAP.md]
