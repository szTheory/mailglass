---
phase: 176-direct-filters-and-useful-inbound-evidence
reviewed: 2026-11-03T02:51:05Z
depth: standard
files_reviewed: 40
files_reviewed_list:
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/inbound-layout.spec.js
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/phase170-journey.spec.js
  - mailglass_admin/e2e/phase175-inbound.spec.js
  - mailglass_admin/e2e/phase176-filters.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/address_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/priv/static/hooks.js
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/address_list_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs
  - mailglass_admin/test/mailglass_admin/operator/results_status_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs
  - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
  - mailglass_admin/test/support/inbound_fixtures.ex
  - mailglass_admin/test/support/operator_fixtures.ex
  - reference/demo_app/assets/e2e/inbound-evidence.spec.js
  - reference/demo_app/assets/e2e/phase176-filters.spec.js
  - reference/demo_app/dev/mailglass_demo_web/storybook.ex
  - reference/demo_app/storybook/inbound_evidence.story.exs
  - reference/persona_spec/quick_view_scenarios.ex
  - reference/persona_spec/quick_view_scenarios.json
findings:
  critical: 1
  warning: 4
  info: 0
  total: 5
status: issues_found
---

# Phase 176: Code Review Report

**Reviewed:** 2026-11-03
**Depth:** standard
**Files Reviewed:** 40
**Status:** issues_found

## Summary

Reviewed the resolved Phase 176 source scope at current HEAD, including the phase summaries and the related LiveView, component, browser-spec, and Storybook code. The in-LiveView Account switch authorization gap remains open and was deliberately deferred by Phase 177 D-05; it is tracked in `.planning/todos/2026-10-28-operator-account-switch-skips-host-auth.md` and is not fixed. I also found a stale status-region defect, a nonfunctional theme control in the new evidence story, fragile browser timing checks, and a misleading payload-size label. No tests were run.

## Narrative Findings (AI reviewer)

### Critical Issues

### CR-01: Account changes in the LiveView bypass the host authorization callback

**Severity:** BLOCKER

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:169-199,232-239,1180`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex:189-232,527-533,1057`

**Issue:** Both LiveViews accept a non-empty `tenant_id` from `handle_params/3` and classify it as `:selected` without checking it against the accounts returned by `TenantSelector.list_tenants/2`. The Account control changes the ID with `push_patch`, which re-runs `handle_params/3` but does not re-run the host's `live_session` `on_mount` authorization callback. An operator admitted to the surface but denied access to a particular account can therefore patch to that account and trigger tenant-scoped reads that would have been denied on a fresh page load. The Phase 177 D-05 todo explicitly records this as an open, pre-existing host-authorization gap; it must not be described as resolved.

**Fix:** Re-run the host authorization callback whenever the patched account changes, or switch with navigation that causes the host `on_mount` authorization to run again. Add a contract check that a denied account is refused after an in-page switch, as it is on arrival. Keep account authorization host-owned, consistent with D-05.

### Warnings

### WR-01: Background refresh can leave the status region describing a different result state

**Severity:** WARNING

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:1207-1220`

**Issue:** `refresh_visible_state/1` refreshes the visible rows and then always restores the old `results_status_text`. Suppressing a new count announcement for a ready-to-ready PubSub update is intentional under D-16, but the same freeze applies when the read changes from ready to stale/error, stale/error to ready, or empty to non-empty. In those cases the persistent `role="status"` region continues to announce the prior state while the displayed list or state panel has changed. The visible data-state panel has no live-region semantics to announce the transition.

**Fix:** Preserve the old text for ready-to-ready background refreshes, but recompute the region when the settled read class changes or the result crosses between empty and non-empty. Cover a state transition in the status-region contract.

### WR-02: Inbound evidence Storybook theme controls are not connected to the theme adapter

**Severity:** WARNING

**File:** `reference/demo_app/dev/mailglass_demo_web/storybook.ex:44-47,66-85`; `reference/demo_app/storybook/inbound_evidence.story.exs:14-22`

**Issue:** The new story declares owner `inbound-evidence-story` and radios named `inbound-evidence-review-theme`, but the adapter only scans quick-view and delivery-investigation owners. Even if the root is initialized, the adapter chooses the quick-view radio name for every owner except delivery-investigation. The story therefore stays on its hardcoded light theme, and its Light/Dark/System controls do not change the theme or follow the operating-system preference.

**Fix:** Add the inbound-evidence owner to the adapter and map each owner to its own radio-group name. Initialize the system preference from the current media query.

### WR-03: Browser timing checks can pass or fail before debounced and reconnect behavior settles

**Severity:** WARNING

**File:** `mailglass_admin/e2e/phase176-filters.spec.js:419-420,440-444,546-560,811-823`; `reference/demo_app/assets/e2e/phase176-filters.spec.js:53-58,102-109`

**Issue:** Several specs use fixed sleeps to prove that a pending debounce will not later commit or add history. Their result depends on browser timer scheduling and the current debounce duration. The reconnect case calls `disconnect()` and `connect()` back-to-back, then checks only that `.phx-connected` is visible; that selector can already be visible before the disconnect is processed, so the test may not exercise reconnection recovery at all.

**Fix:** Wait for an observed disconnected transition before reconnecting, then wait for the resulting recovery event/state. Replace fixed sleeps with assertions on the relevant URL/history state over an explicitly bounded settle window or controlled debounce timing.

### WR-04: “Payload size” measures the displayed re-encoding rather than provider payload bytes

**Severity:** WARNING

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:112,173-184,208-210`

**Issue:** For map-backed evidence, the displayed number is the UTF-8 byte size of `Jason.encode(payload, pretty: true)`, including formatting whitespace. It is not the original provider payload size; those bytes are not stored. The source code documents this distinction, but operators only see the fact label “Payload size,” which can be read as the size of the stored or received payload.

**Fix:** Rename the fact to describe the measured value (for example, “Displayed source size”) or add visible explanatory copy that map-backed evidence is measured from the pretty-printed representation shown below.

---

_Reviewed: 2026-11-03_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
