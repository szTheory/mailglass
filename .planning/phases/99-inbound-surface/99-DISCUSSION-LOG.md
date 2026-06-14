# Phase 99: Inbound Surface - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-14T22:11:07Z
**Phase:** 99-inbound-surface
**Mode:** assumptions
**Areas analyzed:** Scope / Contract, IA / Responsive, At-A-Glance Data, Component Uplift, Verification / Ratchet

## Assumptions Presented

### Scope / Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 99 stays on the existing `/ops/mail/inbound` surface and existing operator shell; no new route, no new operator capability, no public API. | Likely | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex`; `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` |

### IA / Responsive

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Mirror the Phase 98 Operator pattern: filter disclosure at 390px, master-detail grid `40/60` at 768 and `33/67` at 1440, mobile in-place detail reveal with a back affordance, and orientation strip when no record is selected. | Confident | `.planning/research/v1.11/SUMMARY.md` `IA-LD-01..03`; `mailglass_admin/lib/mailglass_admin/operator_live.ex`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex` |

### At-A-Glance Data

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add a narrow tenant-scoped internal operator summary seam behind `MailglassAdmin.OptionalDeps.MailglassInbound` for exact overview counts and no-match rate, instead of deriving counts from the current limited list. | Likely | `.planning/research/v1.11/SUMMARY.md` `IA-LD-09`; `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` `@default_limit 50` and `@max_limit 100`; `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` |

### Component Uplift

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Rework `RoutingTrace` and `EvidenceCard` in place: `RoutingTrace` remains read-only and no-match-only; `EvidenceCard` owns the locked/redacted/revealed/denied reveal model. Both get aligned scannable group layouts, mono chips on `surface-sunken`, and no arbitrary tracking. | Confident | `.planning/research/v1.11/SUMMARY.md` `STATE-LD-18/19`; `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex`; `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` |

### Verification / Ratchet

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 99 should clear the global advisory conformance leftovers and flip the advisory gate to hard-fail, including the one preview `text-xl` if still present, because the script itself assigns that flip to Phase 99. | Likely | `mailglass_admin/scripts/check-conformance-advisory.sh`; `.github/workflows/ci.yml`; `rg` over `mailglass_admin/lib` for `text-lg/xl` and `tracking-[...]` |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

No external research was performed. The Phase 96 research dossier is the canonical source for the relevant IA, state, motion, dark-mode, and microcopy decisions.
