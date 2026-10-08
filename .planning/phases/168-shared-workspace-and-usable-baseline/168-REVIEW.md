---
phase: 168-shared-workspace-and-usable-baseline
reviewed: 2026-10-08T17:12:27Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
findings:
  critical: 2
  warning: 4
  info: 0
  total: 6
status: issues_found
---

# Phase 168: Code Review Report

**Reviewed:** 2026-10-08T17:12:27Z  
**Depth:** standard  
**Files Reviewed:** 26  
**Status:** issues_found

## Summary

Reviewed all 26 supplied files and traced the changed operator paths into their read models and shared LiveView components. Found two blockers: status badges no longer reflect downstream Delivery outcomes, and stale exact-support cache data can cross Account scopes after a transient read failure. Four warnings cover malformed support IDs, a nonfunctional Preview toast dismiss control, unhandled transient reads during replay confirmation, and stale health counts presented under a newly selected time interval. Tests were not run, per instruction.

## Narrative Findings (AI reviewer)

### Critical Issues

### CR-01: Delivery badges show the stored snapshot instead of the latest outcome

**Classification:** BLOCKER  
**File:** `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:173,243`; `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:25`; `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex:111`; contract in `mailglass_admin/lib/mailglass_admin/components.ex:1046-1070`  
**Issue:** The changed list, full-detail header, and Quick view pass `delivery.status` directly to the status badge. The component's existing `delivery_display_status/1` contract explains that `Delivery.status` is a dispatch snapshot that stops at `:sent`; downstream events such as `:delivered`, `:bounced`, and `:opened` must supersede it. A Delivery with a `:sent` snapshot and a `:delivered` latest event is therefore labeled Sent throughout the operator UI, even where the latest event is shown as Delivered.
**Fix:** Pass `Components.delivery_display_status(delivery)` to each badge and add rendered tests for a `:sent` snapshot with downstream outcomes.

### CR-02: Transient reads can display cached support evidence from another Account

**Classification:** BLOCKER  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:178,2386-2406`; rendered by `mailglass_admin/lib/mailglass_admin/operator_live.ex:1143-1147`  
**Issue:** `load_support_exact_evidence/3` decides whether cached evidence is the same request using only `focus` and record `id`; it does not include the `tenant_id`. When a URL changes the selected Account but retains the same support focus and ID, a transient read failure for the new Account returns `prior.record` as `:stale`. The selected Account has already been updated in `handle_params/3`, so `SupportCards` can render the previous Account's exact record under the new Account context.
**Fix:** Include the tenant ID in the cached evidence state and require it to match before reusing a stale record. Clear exact evidence when the selected tenant changes.

### Warnings

### WR-01: Malformed exact-support IDs crash the LiveView

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:2367-2377,2415-2420`; `lib/mailglass/operator/support_summary.ex:117-135`  
**Issue:** URL-provided `support_event_id` and `support_webhook_event_id` are copied into exact-evidence queries without UUID validation. The read models compare these values with UUID primary keys, which raises a query cast error for malformed IDs. `load_support_exact_evidence/3` re-raises that non-transient error, so a malformed or stale copied link fails the LiveView instead of rendering unavailable or not-found evidence.
**Fix:** Validate each ID as a UUID before building the query, or make the read-model functions return `nil` for invalid IDs.

### WR-02: Preview success flash cannot be dismissed

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/components.ex:172-176`; `mailglass_admin/lib/mailglass_admin/preview_live.ex:503-504`  
**Issue:** `Components.flash/1` uses its display `kind` as the `lv:clear-flash` key. Preview renders a success-styled component from `Phoenix.Flash.get(@flash, :info)`, so its dismiss button sends `key=success` while the stored flash key is `info`. LiveView clears only the requested key, leaving the visible Preview message in place.
**Fix:** Pass the backing flash key separately from the visual kind and use `info` for the Preview call.

### WR-03: Replay confirmation does not handle transient failures in its fresh reads

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:547-558`  
**Issue:** Before authorizing replay, the handler synchronously calls `Deliveries.get_delivery/2` and `ReplayTargets.list_delivery_targets/1` without rescuing transient database/connection errors. The same module explicitly recognizes these errors and renders unavailable or stale read states elsewhere, but an outage during either new confirmation read escapes the event handler and terminates the LiveView instead of returning actionable feedback.
**Fix:** Wrap both reads with the existing transient-read handling, return an unavailable result, and clear `replay_pending?` while keeping the user on the review modal.

### WR-04: Cached health counts can be shown for a different selected interval

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:1864-1874,1963-1971,1986-1993`  
**Issue:** The health cache is considered reusable whenever the Account matches, even if `window_hours` changed. If a read then fails, `read_health_panel/7` returns the prior value as stale. When any other panel read succeeds, `load_health_observations/2` publishes the new interval as the global `health_window`; the stale panel only shows its old check timestamp, not the interval its value covers. Operators can therefore read a count from the previous time range while the page labels the results with the newly selected range.
**Fix:** Include the time window in the health cache identity, or clear interval-scoped cached values on window changes. Preserve and display the actual interval alongside stale panel values.

---

_Reviewed: 2026-10-08T17:12:27Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
