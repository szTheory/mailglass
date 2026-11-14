---
phase: 175-delivery-investigation-and-safe-replay
reviewed: 2026-11-03T01:35:03Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/priv/static/hooks.js
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - reference/demo_app/storybook/delivery_investigation.story.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 175: Code Review Report

**Reviewed:** 2026-11-03T01:35:03Z  
**Depth:** standard  
**Files Reviewed:** 10  
**Status:** issues_found

## Summary

Reviewed the current Phase 175 source scope, including Delivery replay review and recovery, suppression refresh state, the retained Storybook composition, and the connected browser coverage. The replay path keeps the selected Delivery and target server-side, rereads both before confirmation, and authorizes immediately before calling the existing command. One pre-existing authorization gap remains in the Account-switch path: a LiveView patch can change the tenant without rerunning the host's mount authorization.

## Critical Issues

### CR-01: BLOCKER — In-Operator Account switch skips host authorization

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:159-220`
**Issue:** `handle_params/3` accepts `tenant_id` from the URL and uses it to load operator-scoped data. The Account control changes that query with a LiveView `patch`, which reruns `handle_params/3` but does not rerun the `live_session` `on_mount` authorization hook. An operator admitted to the Operator surface but denied access to another Account can therefore switch to its `tenant_id` in the existing LiveView and reach reads for that Account. A fresh full-page arrival is host-checked, but that does not protect the in-session patch path. This risk predates Phase 175 and remains explicitly deferred by Phase 177 D-05; it is tracked in `.planning/todos/2026-10-28-operator-account-switch-skips-host-auth.md` and is not fixed here.
**Fix:** Reinvoke the host's `authorize(:operator_access, ...)` seam whenever `tenant_id` changes in `handle_params/3`, and fail closed on denial before tenant-scoped reads. The existing follow-up also lists a full `push_navigate` as an alternative that reruns mount authorization. Do not add a Mailglass-side tenant allow-list without reopening the Phase 177 D-05 decision.

---

_Reviewed: 2026-11-03T01:35:03Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
