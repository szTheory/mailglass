---
phase: 170-inbound-investigation-and-recovery
reviewed: 2026-10-09T05:49:26Z
depth: standard
files_reviewed: 45
files_reviewed_list:
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/docs/operator-trust.md
  - mailglass_admin/e2e/axe-baseline.spec.js
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/phase170-journey.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/overview.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/read_result.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
  - mailglass_admin/mix.exs
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/test/support/operator_fixtures.ex
  - mailglass_admin/test/support/inbound_test_router.ex
  - mailglass_inbound/docs/api_stability.md
  - mailglass_inbound/docs/inbound-operator.md
  - mailglass_inbound/lib/mailglass_inbound/execution.ex
  - mailglass_inbound/lib/mailglass_inbound/inbound_records.ex
  - mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex
  - mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
  - mailglass_inbound/lib/mailglass_inbound/mailbox.ex
  - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
  - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs
  - mailglass_inbound/test/mailglass_inbound/internal/operator/summary_test.exs
  - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/mailbox_test.exs
  - mailglass_inbound/test/mailglass_inbound/replay_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 170: Code Review Report

**Reviewed:** 2026-10-09T05:49:26Z  
**Depth:** standard  
**Files Reviewed:** 45  
**Status:** clean

## Summary

Refreshed the standard-depth review across 45 in-scope files, including the latest natural-case copy, heading, disabled navigation controls, E2E selectors, and regression assertions. The native disabled Quick view boundary buttons retain accessible names and test IDs; the list heading remains an `h2`, and the locked Phase 121 wording remains unchanged. The inbound subtitle now exactly matches its Phase 121 frozen text. The latest `RoutingTrace` derives route labels from clause verdicts; the outside-results message is gated on a successful list read; and the history refresh announces its waiting state. The earlier tenant-authorization claim is not a vulnerability under the approved stable contract: `:operator_access` grants access within the host's configured persistence scope, and Account options are navigation. Read and replay paths continue to carry the selected tenant, with explicit `tenant_id` predicates and `Tenancy.scope/2` at inbound persistence seams. No current findings remain.

The prior WR-01 remains closed. `latest_matched_fresh_run/3` includes failed runs that retain a non-empty Mailbox identity, while replay still refuses to resolve that legacy module name. The added DB-backed regression covers both eligibility and replay outcomes. WR-02 is closed: the page subtitle has been restored to the exact locked Phase 121 copy. Tests were not run for this review.

## Narrative Findings (AI reviewer)

No current findings. The initial review's tenant-authorization claim was adjudicated against `operator-trust.md` and omitted as intended behavior; the contract grants global operator access within host persistence scope. The earlier `RoutingTrace`, outside-results guard, and WR-01 closure remain verified.

---

_Reviewed: 2026-10-09T05:49:26Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
