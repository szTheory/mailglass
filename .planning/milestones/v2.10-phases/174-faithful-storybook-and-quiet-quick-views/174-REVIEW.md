---
phase: 174-faithful-storybook-and-quiet-quick-views
reviewed: 2026-11-03T01:17:58Z
depth: standard
files_reviewed: 47
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
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs
  - reference/demo_app/assets/scripts/evidence-output-path.cjs
  - reference/demo_app/assets/scripts/evidence-output-path.test.cjs
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
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 174: Code Review Report

**Reviewed:** 2026-11-03T01:17:58Z  
**Depth:** standard  
**Files Reviewed:** 47  
**Status:** issues_found

## Summary

Re-reviewed the current Phase 174 source scope against its plans and the current code. The three findings in the previous review are resolved. One cross-tenant authorization gap remains in Inbound: a URL-supplied tenant is treated as selected without checking that the operator may access it, then passed into tenant-scoped reads.

## Narrative Findings (AI reviewer)

### CR-01: BLOCKER — Inbound URL accepts an operator-unapproved tenant ID

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:203-208`
**Issue:** `tenant_options` is collected for `operator_actor`, but `tenant_state/3` treats every non-nil `tenant_id` as `:selected` without checking it against the operator's authorized tenant scope. The `:selected` branch then calls `assign_inbound_state/4` with that URL value (`:251-257`); `load_inbound_records_page/1` passes it to the read model, which applies it as both the tenant filter and `Tenancy.scope/2` context (`:1652-1665`). An operator can therefore change `?tenant_id=` in a direct URL to another tenant and request that tenant's records or details. The form-event filter guard does not protect this path because `handle_params/3` accepts the initial URL independently.
**Fix:** Before any inbound read, authorize the requested tenant against the current operator through a host-owned tenant authorization check. Reject or render a non-disclosing unavailable state for unauthorized IDs, and fail closed if authorization cannot be established. Do not use the URL-supplied tenant ID itself as proof of authorization; add coverage for a direct URL naming a foreign tenant.

---

_Reviewed: 2026-11-03T01:17:58Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
