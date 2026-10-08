---
phase: 168-shared-workspace-and-usable-baseline
reviewed: 2026-10-08T15:25:33Z
depth: standard
files_reviewed: 60
files_reviewed_list:
  - docs/api_stability.md
  - lib/mailglass.ex
  - lib/mailglass/operator/deliveries.ex
  - lib/mailglass/operator/replay_targets.ex
  - lib/mailglass/operator/support_summary.ex
  - lib/mailglass/operator/suppressions.ex
  - lib/mailglass/operator/timeline.ex
  - lib/mailglass/webhook/replay.ex
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/docs/api_stability.md
  - mailglass_admin/docs/operator-trust.md
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/gallery-matrix.spec.js
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_action.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/group_nesting_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator_trust_doc_test.exs
  - mailglass_admin/test/mailglass_admin/persona_cohort_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/test/support/operator_browser_server.ex
  - mailglass_admin/test/support/operator_fixtures.ex
  - test/mailglass/operator/deliveries_test.exs
  - test/mailglass/operator/replay_targets_test.exs
  - test/mailglass/operator/support_summary_test.exs
  - test/mailglass/operator/suppressions_test.exs
  - test/mailglass/operator/timeline_test.exs
  - test/mailglass/webhook/replay_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 168: Code Review Report

**Reviewed:** 2026-10-08T15:25:33Z  
**Depth:** standard  
**Files Reviewed:** 60  
**Status:** issues_found

## Summary

Reviewed the 60 unique source paths in the supplied scope. The evaluation-scope resolver was degraded (`no-task-commits-since`), so the review includes the related Phase 169 files as requested. The principal risk is that URL-selected Account IDs are treated as authorized on both operator surfaces without a server-side membership check; malformed support-evidence IDs can also turn a crafted URL into a failing LiveView request. No test files were reported as findings.

## Narrative Findings (AI reviewer)

### CR-01: URL Account selection bypasses the server-side permitted-account set

**Classification:** BLOCKER  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:153-162`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex:161-170`  
**Issue:** Both LiveViews compute `tenant_options` from the authenticated operator context, then classify every non-empty `tenant_id` query value as `:selected` without checking whether the operator may access it. The selected ID is then passed to tenant-scoped reads and used to subscribe to that tenant's event topic. An authenticated operator can therefore change the query string to another tenant ID and read its delivery/inbound records if that tenant exists in the host database. The mount-time `:operator_access` check authorizes entry to the operator surface; it does not bind subsequent reads to the returned actor's permitted tenant set.
**Fix:** Resolve the selected tenant against an authoritative, server-side authorization check before any reads or PubSub subscription. Preserve support for permitted IDs absent from activity-derived selector options by asking the host authorization seam for permission independently of that list; render a denied/empty state for an unpermitted ID.

### WR-01: Malformed support evidence IDs crash the operator page

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:2415-2419`; `lib/mailglass/operator/support_summary.ex:117-135`  
**Issue:** `support_event_id` and `support_webhook_event_id` are copied from URL params without UUID validation. The exact-evidence loader passes these strings to `get_unmatched_event/2` and `get_webhook_event/2`, whose queries compare them with UUID primary keys. A malformed value raises an Ecto query cast error; the LiveView rescue only converts transient database errors and re-raises this input error, so a malformed or stale copied link fails the page instead of showing unavailable/not-found evidence.
**Fix:** Validate UUIDs when normalizing support state and discard invalid IDs, or make the read-model functions cast IDs and return `nil` for invalid values before building the query.

### WR-02: Resend replay evidence omits its provider label

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:6,207-214`; `lib/mailglass/webhook/replay.ex:15-21`  
**Issue:** The replay command supports the `:resend` provider, but `RepairState.safe_provider/1` only accepts `mailgun`, `postmark`, `sendgrid`, and `ses`. Consequently, latest replay summaries and replay metadata summaries silently omit `RESEND`, making persisted evidence less identifiable for supported Resend requests.
**Fix:** Add `resend` to the presenter allowlist (or derive the provider allowlist from the same canonical provider registry used by replay).

---

_Reviewed: 2026-10-08T15:25:33Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
