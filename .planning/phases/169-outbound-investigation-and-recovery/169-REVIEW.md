---
phase: 169-outbound-investigation-and-recovery
reviewed: 2026-10-08T03:23:56Z
depth: standard
files_reviewed: 50
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
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/group_nesting_test.exs
  - mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator_trust_doc_test.exs
  - mailglass_admin/test/mailglass_admin/persona_cohort_test.exs
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
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 169: Code Review Report

**Reviewed:** 2026-10-08T03:23:56Z  
**Depth:** standard  
**Files Reviewed:** 50  
**Status:** issues_found

## Summary

Reviewed the 50-file Phase 169 source scope, including the exact Account and Delivery reads, support evidence, timeline overflow path, replay confirmation and persistence path, Admin navigation, and changed test assertions. Two issues remain: focused support IDs can render same-Account records as the wrong evidence population, and replay target changes leave the current review stale with no in-view refresh path. No tests were run as part of this source review.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Exact support IDs can be presented as the wrong evidence population

**Classification:** BLOCKER  
**File:** `lib/mailglass/operator/support_summary.ex:76-88, 120-135`; `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex:343-345`

**Issue:** The exact lookup functions constrain the requested ID to the selected Account, but do not verify that the row belongs to the population named by the focus. `get_webhook_event/2` accepts any webhook status, and `get_unmatched_event/2` accepts any Event, including one already linked to a Delivery. The UI labels these results unconditionally as “Exact failed webhook” or “Exact unmatched Event.” A direct or stale URL with `support_focus=orphan_backlog` and a linked ordinary Event therefore renders that Event as unmatched; a non-failed webhook ID can similarly be labeled as failure evidence. Account scoping prevents cross-Account disclosure but does not preserve evidence semantics.

**Fix:** Make the focused lookup enforce the corresponding population (failed/dead status for failed ingest; unresolved unmatched predicate for unmatched backlog), or return an explicit population/membership result and render a neutral exact Account record label when the row is no longer a member. Preserve the requested ID and show a non-matching/unavailable state instead of claiming it is current evidence.

### Warnings

#### WR-01: A changed replay target cannot be refreshed from the rejection flow

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:584-592`

**Issue:** When the fresh replay candidate tuple differs from the reviewed snapshot, this branch clears `replay_pending?` and displays “Review the current request before replaying,” but leaves `replay_targets`, `replay_review_snapshot`, and `replay_review_consumed?` unchanged. Closing and reopening the modal snapshots the same stale candidates because `open_replay` uses the assigned `replay_targets` without rereading them. A subsequent confirmation repeats `:review_changed`; the operator must leave/reload the detail route to see the current candidate set.

**Fix:** On `:review_changed`, replace the assigned targets with the freshly loaded set, clear the old snapshot/consumed state, and require a new explicit selection/review against that set. If target resolution is unavailable, show that state and a refresh action that rereads the targets.

---

_Reviewed: 2026-10-08T03:23:56Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
