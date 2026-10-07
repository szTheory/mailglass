---
phase: 168-shared-workspace-and-usable-baseline
reviewed: 2026-10-07T21:24:33Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/surface_nav.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 168: Code Review Report

**Reviewed:** 2026-10-07T21:24:33Z  
**Depth:** standard  
**Files Reviewed:** 28  
**Status:** issues_found

## Summary

Reviewed the explicit Phase 168 source scope against the phase UI contract, including Account switching, query handling, Quick view, replay authorization presentation, feedback, theme tokens, and the generated stylesheet. No authorization bypass or cross-tenant data exposure was found in the reviewed paths. Two keyboard/accessibility defects remain in the Account option semantics and the replay dialog’s unavailable state.

## Narrative Findings (AI reviewer)

### WR-01: Account options lose link semantics in the accessibility tree

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:281-288`  
**Issue:** Each option is rendered as an anchor by `<.link>` but explicitly assigned `role="listitem"`. The explicit role replaces the anchor’s implicit `link` role, so assistive technology exposes these actionable Account choices as list items rather than links. This removes the expected link semantics from the Account switcher even though the controls remain clickable.
**Fix:** Put the link inside a list-item wrapper, or use a semantic list with unmodified anchors. For example:

```heex
<div role="listitem">
  <.link patch={tenant_switch_path(@page_uri, tenant.id)}>
    ...
  </.link>
</div>
```

### WR-02: Replay focus trap escapes when the action is unavailable

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:43-45`  
**Issue:** The start sentinel always sends focus to `#operator-replay-confirm`, but that button is conditionally absent when replay targets are unavailable or still loading (lines 112-123). In that state, opening the modal focuses Close; pressing Shift+Tab reaches the sentinel, whose focus target does not exist, so focus remains on the sentinel and the next Shift+Tab can leave the `aria-modal` dialog. This violates the dialog’s keyboard focus containment on a supported unavailable state.
**Fix:** Make the start sentinel wrap to the last rendered focusable control when Confirm is absent, or use a focus-trap implementation that derives its targets from the controls actually rendered. Keep the normal Confirm wrap when that control exists.

---

_Reviewed: 2026-10-07T21:24:33Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
