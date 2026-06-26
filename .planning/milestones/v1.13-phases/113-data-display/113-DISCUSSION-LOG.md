# Phase 113: Data-Display - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-19T21:43:25Z
**Phase:** 113-data-display
**Mode:** assumptions
**Areas analyzed:** Responsive Data Lists, Canonical KPI And Severity Encoding, Distinct Data States, Long Real-World Values And Proof

## Assumptions Presented

### Responsive Data Lists

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Deliveries and inbound records should keep the existing master-detail URL/selection behavior, but replace the current list-only row markup with a semantic table at `>=768px` and a card/list presentation below `768px`. | Confident | `.planning/ROADMAP.md`; `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`; `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`; `mailglass_admin/e2e/structural.spec.js` |

### Canonical KPI And Severity Encoding

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 113 should reuse `MailglassAdmin.Components.stat_card/1` and `status_badge/1` as the canonical primitives, widening certification rather than creating new stat/status components. | Confident | `.planning/phases/110-primitives/110-CONTEXT.md`; `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/lib/mailglass_admin/operator_live.ex`; `mailglass_admin/lib/mailglass_admin/inbound/overview.ex`; `mailglass_admin/scripts/check-conformance.sh` |

### Distinct Data States

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| DATA-03 should be modeled as distinct reusable state templates for no-data, unavailable/error, permission-denied, and stale-data, while keeping live-refresh mechanics out of scope. | Likely | `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md`; `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`; `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`; `mailglass_admin/lib/mailglass_admin/operator_live.ex`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex`; `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` |

### Long Real-World Values And Proof

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Long-value handling should be proven through existing gallery/structural/conformance lanes plus realistic demo/test data, not pixel diffs or a new asset pipeline. | Confident | `mailglass_admin/e2e/structural.spec.js`; `mailglass_admin/lib/mailglass_admin/gallery_live.ex`; `reference/demo_app/lib/mailglass_demo/demo_data.ex`; `lib/mailglass/operator/deliveries.ex`; `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` |

## Corrections Made

No corrections - all assumptions confirmed.
