---
phase: 175-delivery-investigation-and-safe-replay
reviewed: 2026-10-27T21:12:43Z
depth: standard
files_reviewed: 53
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
  - mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex
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
  - mailglass_admin/test/mailglass_admin/operator/repair_state_test.exs
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
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 175: Code Review Report

**Reviewed:** 2026-10-27T21:12:43Z
**Depth:** standard
**Files Reviewed:** 53
**Status:** issues_found

## Summary

Re-reviewed the previous 51-file scope and the two additional authorization files against the iteration-1 changes. WR-01 (stale-auth feedback), WR-02 (missing prior replay target), and the original WR-03 acceptance gap (arbitrary or misplaced screenshot files) are resolved in the current implementation. The screenshot checker now requires the three run-local PNGs and validates their PNG chunks and decoded scanlines, but it accepts a valid 1×1 PNG in each required capture slot without checking that the image dimensions match the declared 320px, 1440px, and real-zoom captures. One new warning remains.

The retained current-source proof records Demo 4/4, Admin 10/10, fidelity 10/10, Axe 26/26, and six layout cases per domain for cold and warm runs. Machine-observable acceptance is covered under D-52; eight descriptor-less prohibition flags remain `flagged-unverified`, and the 116 Axe incomplete findings remain incomplete rather than being described as passing labels.

## Narrative Findings (AI reviewer)

## Warnings

### WR-04: [WARNING] Screenshot validation does not enforce the required capture dimensions

**File:** `scripts/check_phase175_evidence.cjs:382-396,455-465`
**Issue:** `validatePng` only requires positive dimensions under a broad 32768px limit and then validates the decompressed scanline length. It never compares those dimensions with the capture represented by each inventory entry. The checker tests build `fixturePng()` as a valid 1×1 image and accept it for all three required screenshot paths (`scripts/check_phase175_evidence.test.cjs:32-52,251-258`). Thus a tiny placeholder can satisfy the responsive and real-zoom screenshot gate even though it cannot show any of the declared viewport layouts. The retained current run artifacts are 320×2153, 1440×1363, and 640×4316, but these widths are not enforced.
**Fix:** Return the parsed PNG dimensions from `validatePng` and compare each image against the expected capture width: 320px for the narrow capture, 1440px for the desktop capture, and the 320px effective viewport at 200% tab zoom for the zoom capture (640 screenshot pixels in the retained Chromium run). Add rejection cases for valid PNGs with incorrect dimensions.

---

_Reviewed: 2026-10-27T21:12:43Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
