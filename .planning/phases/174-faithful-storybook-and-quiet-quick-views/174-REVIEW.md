---
phase: 174-faithful-storybook-and-quiet-quick-views
reviewed: 2026-10-27T11:23:52Z
depth: standard
files_reviewed: 45
files_reviewed_list:
  - .github/workflows/ci.yml
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/docs/phase174-review.md
  - mailglass_admin/docs/storybook-axe-approved.json
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/storybook-axe.spec.js
  - mailglass_admin/e2e/support/storybook-axe.cjs
  - mailglass_admin/e2e/support/storybook-axe.test.cjs
  - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/package.json
  - mailglass_admin/playwright.config.cjs
  - mailglass_admin/playwright.storybook.config.cjs
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/priv/static/hooks.js
  - mailglass_admin/test/mailglass_admin/assets_test.exs
  - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/support/inbound_fixtures.ex
  - mailglass_admin/test/support/operator_fixtures.ex
  - reference/demo_app/assets/e2e/demo.spec.js
  - reference/demo_app/assets/e2e/phase173-evidence.spec.js
  - reference/demo_app/assets/e2e/quick-views.spec.js
  - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
  - reference/demo_app/assets/e2e/storybook-hooks.spec.js
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs
  - reference/demo_app/assets/scripts/evidence-output-path.cjs
  - reference/demo_app/dev/mailglass_demo_web/storybook.ex
  - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
  - reference/demo_app/lib/mailglass_demo_web/router.ex
  - reference/demo_app/storybook/primitives/theme_picker.story.exs
  - reference/demo_app/storybook/quick_views/delivery.story.exs
  - reference/demo_app/storybook/quick_views/inbound.story.exs
  - reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs
  - reference/persona_spec/quick_view_scenarios.ex
  - reference/persona_spec/quick_view_scenarios.json
  - scripts/check_phase174_evidence.cjs
  - scripts/check_phase174_evidence.test.cjs
  - scripts/prepare_phase173_baselines.cjs
  - scripts/run_demo_browser_evidence.sh
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 174: Code Review Report

**Reviewed:** 2026-10-27T11:23:52Z  
**Depth:** standard  
**Files Reviewed:** 45  
**Status:** issues_found

## Summary

Reviewed the 45 source and evidence files in the canonical Phase 174 scope. The evidence output guard can follow a symlink outside its intended directory and delete that target's `retained` directory. Inbound focus restoration also runs on the transition to full detail, and the evidence source digest omits changed route and Storybook inputs.

## Narrative Findings (AI reviewer)

### CR-01: BLOCKER — Symlinked evidence path can delete data outside the evidence root

**File:** `reference/demo_app/assets/scripts/evidence-output-path.cjs:7-10`  
**Issue:** `resolveEvidenceOutputPath` checks only the lexical `path.resolve()` prefix. If a directory under `reference/demo_app/tmp/demo_browser_evidence` (or the evidence root itself) is a symlink to another location, the candidate still passes this check. The checker then follows that symlink when creating the checkpoint and staging retained captures; after valid evidence is collected, `check-demo-browser-evidence.cjs:371` recursively removes `<candidate>/retained`. A symlinked candidate can therefore cause the checker to delete an unrelated `retained` directory outside the intended evidence tree.
**Fix:** Resolve and validate the candidate against the canonical evidence root, reject symlinked path components (including the root), and reject a symlinked `retained` target before any write or recursive removal. Use no-follow directory operations for the final write/delete boundary.

### WR-01: WARNING — Inbound full-detail transition returns focus to a hidden row

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:797-804`  
**Issue:** When `Open full detail` changes `@full_detail?` to true, the quick-view focus-return span is removed. Its `phx-remove` handler unconditionally focuses `@quick_view_focus_return_id`, which points to a row opener. The full-detail branch hides the list (`:592-595`), so that target no longer exists; focus is lost from the removed quick-view control instead of moving into the newly displayed full-detail view. The same handler is appropriate when closing the overlay, but this removal also occurs during the full-detail transition.
**Fix:** Distinguish closing the quick view from opening full detail. Return focus to the row only on close; on the full-detail transition, move focus to a stable control or heading in `inbound-detail-column` (for example, `#inbound-detail-back`).

### WR-02: WARNING — Source digest omits changed route and story inputs

**File:** `scripts/check_phase174_evidence.cjs:149-165`  
**Issue:** `selectedSourcePaths` hashes `SOURCE_REQUIRED` plus Demo `*.spec.js` and Storybook files ending in `.ex` or `.heex`. The changed Storybook definitions end in `.story.exs`, so the extension filter excludes both quick-view stories and the theme-picker story. The changed inbound route implementation (`inbound_live.ex` and `inbound/records_list.ex`) is also not listed in `SOURCE_REQUIRED`. Locally generated evidence can therefore retain the same `source_digest` after edits to those tested inputs while `source_revision` remains at the same HEAD; the digest does not identify the sources that produced those local results.
**Fix:** Add the changed route and story source files to the explicit input list, and match the intended `.story.exs` suffix (for example, `/\.story\.(?:ex|heex)$/`). Add a check that the input set includes every source file whose content the Phase 174 evidence exercises.

---

_Reviewed: 2026-10-27T11:23:52Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
