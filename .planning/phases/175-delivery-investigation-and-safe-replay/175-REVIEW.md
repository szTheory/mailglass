---
phase: 175-delivery-investigation-and-safe-replay
reviewed: 2026-10-27T20:38:59Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - .github/workflows/ci.yml
  - mailglass_admin/docs/phase175-review.md
  - mailglass_admin/docs/storybook-axe-approved.json
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/phase170-journey.spec.js
  - mailglass_admin/e2e/phase175-inbound.spec.js
  - mailglass_admin/e2e/storybook-axe.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/support/storybook-axe-supplement.cjs
  - mailglass_admin/e2e/support/storybook-axe.cjs
  - mailglass_admin/e2e/support/storybook-axe.test.cjs
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_action.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/priv/static/hooks.js
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
  - reference/demo_app/assets/e2e/cohort.spec.js
  - reference/demo_app/assets/e2e/delivery-investigation.spec.js
  - reference/demo_app/assets/e2e/outbound-replay.spec.js
  - reference/demo_app/assets/e2e/quick-views.spec.js
  - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
  - reference/demo_app/dev/mailglass_demo_web/storybook.ex
  - reference/demo_app/storybook/delivery_investigation.story.exs
  - reference/persona_spec/quick_view_scenarios.ex
  - reference/persona_spec/quick_view_scenarios.json
  - scripts/check_phase174_evidence.cjs
  - scripts/check_phase174_evidence.test.cjs
  - scripts/check_phase175_evidence.cjs
  - scripts/check_phase175_evidence.test.cjs
  - scripts/gsd-regression-gate.sh
  - scripts/run_demo_browser_evidence.sh
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 175: Code Review Report

**Reviewed:** 2026-10-27T20:38:59Z  
**Depth:** standard  
**Files Reviewed:** 51  
**Status:** issues_found

## Summary

Reviewed the 51 scoped implementation, test, evidence-checker, and CI files. Exact replay scope and action-time authorization are re-read before execution, but the outbound authorization error path loses the distinction between stale authentication and denied access. The recovery dialog also misstates a first-time target review as a changed request, and the fidelity receipt checker accepts arbitrary nonempty files as screenshots.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: [WARNING] Stale outbound authentication is reported as an access denial

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:651-652`  
**Issue:** `DestructiveAction.authorize/4` returns auth failures with their message, including the supported `"Recent authentication is required."` response (`operator/destructive_action.ex:26-27`, `auth.ex:19-25`). This handler discards that message and maps every auth failure to `:denied`, whose dialog tells the operator to ask an Account administrator to review access (`operator/repair_state.ex:129-134`). An operator whose recent-auth check expired is given the wrong recovery step.
**Fix:** Preserve the normalized auth reason through `DestructiveAction.authorize/4` and route stale-auth failures to the existing `RepairState.authorization_feedback/1` copy (or add a dedicated `:stale_auth` dialog feedback branch); retain the generic denial copy for unauthorized responses.

### WR-02: [WARNING] First successful re-review falsely says the exact request changed

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:2070-2071`  
**Issue:** If opening replay failed to read targets, the prior selected target is `nil`. When `Review again` later finds one exact candidate, `reviewed_replay_selection/2` still returns `nil` (`operator_live.ex:2120-2122`), and the exact-target modal branch renders “This exact request changed” whenever the candidate ID differs from that nil selection (`operator/replay_modal.ex:45-47`). No exact request had been selected before, so the recovery message is false and can confuse the operator while requiring them to choose the candidate.
**Fix:** Distinguish “no prior target was available” from a previously selected target that disappeared or changed. Show the ordinary exact-request review prompt for the former while keeping explicit target selection, and use the changed-request copy only when a prior target ID exists and no longer matches.

### WR-03: [WARNING] Fidelity checker accepts arbitrary files as retained screenshots

**File:** `scripts/check_phase175_evidence.cjs:232-238,292-293`  
**Issue:** `safeWorkspaceFile` only checks that a path resolves lexically inside the workspace and names a nonempty regular file. The fidelity check then accepts that file as a screenshot without validating image content, requiring it to be under the run's evidence directory, or requiring any responsive screenshots (`detail.screenshots || []`). A receipt can point `zoom.screenshot` at a text file such as `CLAUDE.md` and still satisfy the screenshot check, so a missing or malformed capture can pass the retained-evidence validation.
**Fix:** Require the expected screenshot artifacts in the run evidence directory and validate their image format (for example, PNG signature plus successful decode); reject symlinked path components as well as symlinked leaf files.

---

_Reviewed: 2026-10-27T20:38:59Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
