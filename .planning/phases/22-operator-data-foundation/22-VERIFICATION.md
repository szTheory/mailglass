---
phase: 22-operator-data-foundation
verified: 2026-05-01T02:37:37Z
status: human_needed
score: 11/11 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Desktop/mobile operator layout"
    expected: "The two-pane desktop layout collapses cleanly on mobile, with the recent-deliveries list still acting as the first anchor and the selected-delivery detail stack preserving summary, timeline, and suppression-card order."
    why_human: "Visual layout quality and responsive flow cannot be fully verified from static code and string assertions."
  - test: "Selected-row semantics and read-only UX feel"
    expected: "Selecting a row clearly communicates the active delivery, the detail pane updates in place, and the screen exposes no replay or suppression-mutation affordances."
    why_human: "Tests prove the state transitions and copy, but they do not judge visual clarity, focus treatment, or overall operator UX quality."
---

# Phase 22: Operator Data Foundation Verification Report

**Phase Goal:** Expose the delivery, event-ledger, and suppression data needed for an operator-facing admin UI.
**Verified:** 2026-05-01T02:37:37Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

Roadmap contract note: the current root `.planning/ROADMAP.md` no longer contains Phase 22, so this verification anchored must-haves to the phase plans plus the explicit phase goal and requirement mapping in `.planning/REQUIREMENTS.md`.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A core operator query seam exists in `lib/mailglass/operator/*` instead of embedding Ecto queries in LiveView modules. | ✓ VERIFIED | `Mailglass.Operator.Deliveries`, `Timeline`, and `Suppressions` provide the read models in `lib/mailglass/operator/*.ex`; `MailglassAdmin.OperatorLive` consumes them instead of issuing raw Ecto queries directly (`lib/mailglass/operator/deliveries.ex:17`, `timeline.ex:16`, `suppressions.ex:17`, `mailglass_admin/lib/mailglass_admin/operator_live.ex:14-18`, `:201-232`). |
| 2 | Recent deliveries can be queried with tenant-aware filter primitives suitable for URL-backed admin state. | ✓ VERIFIED | `list_recent_deliveries/2` requires `tenant_id`, supports provider/status/event/window filters, orders by recency, and limits results (`lib/mailglass/operator/deliveries.ex:18-45`, `:51-91`). `OperatorLive` normalizes URL params and passes compact filters into the query seam (`mailglass_admin/lib/mailglass_admin/operator_live.ex:48-66`, `:186-207`). Backend and LiveView tests cover tenant filtering and URL-backed filter submission (`test/mailglass/operator/deliveries_test.exs`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs:32-81`). |
| 3 | A delivery timeline reads from the append-only ledger in stable chronological order. | ✓ VERIFIED | `list_delivery_events/2` queries `Mailglass.Events.Event` by `tenant_id` and `delivery_id`, ordered by `occurred_at`, `inserted_at`, and `id` (`lib/mailglass/operator/timeline.ex:17-39`). Tests prove selected-delivery isolation, tenant scoping, and stable chronology (`test/mailglass/operator/timeline_test.exs`). |
| 4 | Suppression state is projected into operator-facing visibility/reversibility data without mutation APIs. | ✓ VERIFIED | `get_delivery_suppression_state/2` reads `Mailglass.Suppression.Entry`, derives `reversibility`, and returns `Reversible in a later phase` or `Immutable by policy` without any write helpers (`lib/mailglass/operator/suppressions.ex:17-118`). Tests assert scope/reason/source visibility, immutable vs reversible policy, and absence of mutation exports (`test/mailglass/operator/suppressions_test.exs`). |
| 5 | The admin package gets a distinct operator LiveView rather than overloading `PreviewLive`. | ✓ VERIFIED | Router mounts `live "/operator", MailglassAdmin.OperatorLive, :index` alongside preview routes (`mailglass_admin/lib/mailglass_admin/router.ex:125-131`), and the implementation lives in its own module (`mailglass_admin/lib/mailglass_admin/operator_live.ex`). |
| 6 | Filters and selected delivery persist in URL params. | ✓ VERIFIED | `handle_event/3` uses `push_patch` for filter application, selection, and filter clearing (`mailglass_admin/lib/mailglass_admin/operator_live.ex:70-91`); `build_path/3` serializes current filters and `delivery_id` back into the URL (`:245-253`). LiveView tests assert the resulting patches (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:49-81`, `:111-124`). |
| 7 | The screen renders recent deliveries, selected-delivery summary, event timeline, and suppression card using the approved UI contract. | ✓ VERIFIED | `OperatorLive` composes `DeliveriesList`, `DetailHeader`, `Timeline`, and `SuppressionCard`, and renders required no-selection and error states (`mailglass_admin/lib/mailglass_admin/operator_live.ex:132-168`). Component files render the required copy for no recent deliveries, no timeline events, and suppression states (`mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `timeline.ex`, `suppression_card.ex`). LiveView tests assert the exact UI copy (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:13-30`, `:126-168`). |
| 8 | The Phase 22 screen remains read-only and introduces no replay or suppression-mutation actions. | ✓ VERIFIED | `OperatorLive` only exposes filter/select/clear events (`mailglass_admin/lib/mailglass_admin/operator_live.ex:70-91`) and renders no action controls for replay or suppression mutation. LiveView tests explicitly refute replay and suppression-removal affordances (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:138-141`). |
| 9 | The operator surface has first-party LiveView tests covering filter state, row selection, timeline rendering, suppression copy, and empty states. | ✓ VERIFIED | `mailglass_admin/test/mailglass_admin/operator_live_test.exs` contains coverage for default no-selection view, empty list, URL-backed filters, row selection, timeline rendering, and immutable/reversible suppression states (`:12-169`). |
| 10 | Tests assert the exact UI copy and interaction contract called out in `22-UI-SPEC.md`. | ✓ VERIFIED | Literal assertions cover `No recent deliveries`, `Select a delivery...`, `No delivery events...`, `Reversible in a later phase`, and `Immutable by policy` (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:20`, `:27-29`, `:129-168`). |
| 11 | Admin test support is extended through existing shared harness files rather than ad hoc helpers. | ✓ VERIFIED | `Mailglass.AdminCase` remains the primary shared harness and loads the shared `mailglass_admin/test/support/live_view_case.ex` support file rather than introducing a one-off operator harness (`test/support/admin_case.ex:25-76`). |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/operator/deliveries.ex` | recent-deliveries query seam | ✓ VERIFIED | `list_recent_deliveries/2` exists and shapes delivery list rows with tenant-aware filters (`:17-45`). |
| `lib/mailglass/operator/timeline.ex` | delivery timeline query seam | ✓ VERIFIED | `list_delivery_events/2` exists and reads event-ledger rows in chronological order (`:16-39`). |
| `lib/mailglass/operator/suppressions.ex` | suppression projection seam | ✓ VERIFIED | `get_delivery_suppression_state/2` exists and derives reversibility copy (`:17-118`). |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | operator list/detail LiveView | ✓ VERIFIED | `handle_params/3` drives URL-backed state and loads all three backend seams (`:47-66`, `:198-232`). |
| `mailglass_admin/lib/mailglass_admin/router.ex` | operator route wiring | ✓ VERIFIED | Operator route is mounted as a distinct LiveView (`:125-131`). |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | operator-surface interaction coverage | ✓ VERIFIED | Five interaction tests cover the planned user flows and required copy (`:12-169`). |
| `test/support/admin_case.ex` | shared admin test support | ✓ VERIFIED | Existing shared harness is extended and reused by operator tests (`:25-134`). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/mailglass/operator/deliveries.ex` | `lib/mailglass/outbound/delivery.ex` | delivery projection fields power recent-delivery rows | ✓ WIRED | Query selects `tenant_id`, `provider`, `status`, `last_event_type`, and `last_event_at` from `Mailglass.Outbound.Delivery` (`lib/mailglass/operator/deliveries.ex:23-44`). |
| `lib/mailglass/operator/timeline.ex` | `lib/mailglass/events/event.ex` | append-only event rows drive operator timeline | ✓ WIRED | Query sources the timeline from `Mailglass.Events.Event` and returns `type` and `occurred_at` (`lib/mailglass/operator/timeline.ex:23-38`). |
| `lib/mailglass/operator/suppressions.ex` | `lib/mailglass/suppression/entry.ex` | scope/reason/expiry become reversibility state | ✓ WIRED | Query reads `scope`, `reason`, `source`, and `expires_at`, then derives reversibility in `project_state/1` (`lib/mailglass/operator/suppressions.ex:26-52`, `:96-118`). |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `lib/mailglass/operator/deliveries.ex` | list pane consumes backend delivery seam | ✓ WIRED | `load_deliveries/1` calls `Deliveries.list_recent_deliveries/2` (`mailglass_admin/lib/mailglass_admin/operator_live.ex:198-207`). |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `lib/mailglass/operator/timeline.ex` | detail pane consumes backend timeline seam | ✓ WIRED | `load_timeline/2` calls `OperatorTimelineData.list_delivery_events/2` (`mailglass_admin/lib/mailglass_admin/operator_live.ex:211-221`). |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `lib/mailglass/operator/suppressions.ex` | suppression card consumes backend projection seam | ✓ WIRED | `load_suppression/2` calls `Suppressions.get_delivery_suppression_state/2` (`mailglass_admin/lib/mailglass_admin/operator_live.ex:225-232`). |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | `mailglass_admin/lib/mailglass_admin/operator_live.ex` | interaction tests cover params and selection behavior | ✓ WIRED | Tests mount the LiveView with `live/2`, submit filter forms, and click delivery rows (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:16`, `:49-81`, `:111-124`). |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | `22-UI-SPEC.md` | literal copy and contract assertions | ✓ WIRED | Tests assert the exact copy required by the plan and UI spec (`mailglass_admin/test/mailglass_admin/operator_live_test.exs:20`, `:27-29`, `:134-168`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `deliveries` | `Deliveries.list_recent_deliveries/2` -> `Mailglass.Outbound.Delivery` query -> `Repo.all()` | Yes | ✓ FLOWING |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `timeline_events` | `OperatorTimelineData.list_delivery_events/2` -> `Mailglass.Events.Event` query -> `Repo.all()` | Yes | ✓ FLOWING |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `suppression_state` | `Suppressions.get_delivery_suppression_state/2` -> `Mailglass.Suppression.Entry` query -> `Repo.one()` -> `project_state/1` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core operator query tests pass | `mix test test/mailglass/operator/deliveries_test.exs test/mailglass/operator/timeline_test.exs test/mailglass/operator/suppressions_test.exs --warnings-as-errors` | `10 tests, 0 failures` | ✓ PASS |
| Operator LiveView interaction tests pass | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | `5 tests, 0 failures` | ✓ PASS |
| Operator + preview harness compatibility holds | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | `11 tests, 0 failures` | ✓ PASS |
| Project still compiles after phase changes | `mix compile --warnings-as-errors` | `Generated mailglass app` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `ADMIN-02` | `22-01`, `22-02`, `22-03` | Operator can browse recent deliveries with tenant-aware filtering. | ✓ SATISFIED | Tenant-scoped recent-delivery query with provider/status/event/window filters (`lib/mailglass/operator/deliveries.ex:18-45`), URL-backed filter state in `OperatorLive` (`mailglass_admin/lib/mailglass_admin/operator_live.ex:48-91`, `:186-207`), and backend + LiveView tests (`test/mailglass/operator/deliveries_test.exs`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs:32-81`). |
| `ADMIN-03` | `22-01`, `22-02`, `22-03` | Operator can open a delivery and inspect a chronological event timeline derived from the append-only ledger. | ✓ SATISFIED | Timeline query uses `Mailglass.Events.Event` with chronological ordering (`lib/mailglass/operator/timeline.ex:17-39`), LiveView loads timeline for the selected delivery (`mailglass_admin/lib/mailglass_admin/operator_live.ex:211-221`), and tests assert event rendering and no-events copy (`test/mailglass/operator/timeline_test.exs`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs:83-168`). |
| `ADMIN-04` | `22-01`, `22-02`, `22-03` | Operator can view suppression entries and see whether each entry is removable or immutable, with the reason surfaced in the UI. | ✓ SATISFIED | Suppression projection derives reversibility and exposes scope/reason/source (`lib/mailglass/operator/suppressions.ex:96-118`), suppression card renders the policy state (`mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex`), and tests assert reversible and immutable copy (`test/mailglass/operator/suppressions_test.exs`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs:103-168`). |

Orphaned requirements check: none. `.planning/REQUIREMENTS.md` maps only `ADMIN-02`, `ADMIN-03`, and `ADMIN-04` to Phase 22, and all three appear in the phase plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/support/admin_case.ex` | 128 | Forbidden root-package reference warning when starting `MailglassAdmin.TestAdopter.Endpoint` | ⚠️ Warning | Verification lanes emit `warning: forbidden reference to MailglassAdmin.TestAdopter.Endpoint`; this does not block phase behavior, but it weakens the intended `Mailglass` -> `MailglassAdmin` package boundary. |

### Human Verification Required

### 1. Desktop/mobile operator layout

**Test:** Open the operator screen in a browser at desktop and mobile widths and exercise the default view, empty state, and a selected-delivery view.
**Expected:** The two-pane desktop layout collapses cleanly on mobile; the recent-deliveries list remains the first anchor; the detail pane preserves summary, timeline, and suppression-card order.
**Why human:** Static code and LiveView tests cannot judge visual hierarchy, spacing, or responsive quality.

### 2. Selected-row semantics and read-only UX feel

**Test:** Select different delivery rows and observe the active-row treatment and in-place detail updates.
**Expected:** The active row is visually obvious, the detail pane updates without navigation away from the page, and no replay or suppression-mutation affordances appear.
**Why human:** Programmatic tests prove the state transitions and copy, but not whether the UX is visually clear and confidence-inspiring for an operator.

### Gaps Summary

No implementation gaps were found against the phase goal, plan must-haves, or Phase 22 requirement IDs. The operator data seams, admin LiveView wiring, and interaction tests are all present and functioning. Remaining work is human verification of responsive layout and operator UX quality; one non-blocking harness warning should be cleaned up separately.

---

_Verified: 2026-05-01T02:37:37Z_
_Verifier: Claude (gsd-verifier)_
