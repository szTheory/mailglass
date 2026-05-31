# Phase 65: Compatibility, Docs, and DX Lock - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-05-31
**Phase:** 65-compatibility-docs-and-dx-lock
**Mode:** assumptions
**Areas analyzed:** Canonical Adoption Path Ownership, Compatibility And
Deprecation Contract Framing, Operator Semantics Trust Boundary, Testing DX
Contract Clarity

## Assumptions Presented

### Canonical Adoption Path Ownership

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `mailglass_inbound/README.md` should remain the single canonical inbound adoption lane, and other inbound guides should be subordinate/consistent references rather than parallel setup authorities. | Confident | `mailglass_inbound/README.md`; `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`; `lib/mix/tasks/mailglass.docs.check.ex` |

### Compatibility And Deprecation Contract Framing

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 65 should express compatibility rules by tying stable surfaces to explicit contract inventory (`api_stability`) and route breaking changes through deprecation bridge or major-version change; internal/deferred surfaces remain changeable without deprecation. | Likely | `mailglass_inbound/docs/api_stability.md`; `.planning/phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md`; `.planning/phases/64-contract-verification-hardening/64-CONTEXT.md`; `lib/mix/tasks/mailglass.docs.check.ex` |

### Operator Semantics Trust Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Operator docs should lock stable behavior at command semantics (`doctor/replay/prune` flags, exit semantics, tenant guard, confirmation tiers, replay-over-stored-truth), while keeping orchestration modules, worker/queue/job/UI details explicitly non-contractual. | Confident | `mailglass_inbound/docs/inbound-operator.md`; `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex`; `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex`; `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex`; `mailglass_inbound/docs/api_stability.md`; `mailglass_admin/docs/operator-trust.md`; `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` |

### Testing DX Contract Clarity

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Testing docs should center `MailboxCase` + `Test.Ingress` as the default harness, explicitly teach process-local capture semantics, and enforce one-assertion-per-drive as a hard rule. | Confident | `mailglass_inbound/docs/inbound-testing.md`; `mailglass_inbound/docs/inbound-install.md`; `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex`; `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex`; `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex`; `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` |

## Corrections Made

No corrections - all assumptions confirmed.
