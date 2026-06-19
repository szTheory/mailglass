# Phase 112: App-Shell, Navigation & Tenant Seam - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-19T15:46:50-04:00
**Phase:** 112-App-Shell, Navigation & Tenant Seam
**Mode:** assumptions
**Areas analyzed:** Tenant Selection & Listing, Tenant Scope Persistence, Theme Persistence & First Paint, Navigation & Pagination Honesty

## Assumptions Presented

### Tenant Selection & Listing

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Tenant discovery should be added as a core operator read-model capability, then consumed by the admin shell through the authenticated `operator_actor`; the admin shell should not query tenant rows directly or infer tenant choices from admin fixtures/session alone. | Likely | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `lib/mailglass/operator/deliveries.ex`; `mailglass_admin/lib/mailglass_admin/operator/mount.ex`; `mailglass_admin/lib/mailglass_admin/auth.ex`; `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/lib/mailglass_admin/operator_live.ex` |

### Tenant Scope Persistence

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `tenant_id` remains URL state for operator surfaces and every shell/navigation action must preserve it; session tenant_id is useful input context but should not replace URL-carried tenant scope once a surface is mounted. | Confident | `mailglass_admin/lib/mailglass_admin/operator/shell.ex`; `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`; `mailglass_admin/lib/mailglass_admin/operator_live.ex`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex`; `mailglass_admin/test/mailglass_admin/operator_live_test.exs` |

### Theme Persistence & First Paint

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Theme wiring should preserve the locked tri-state contract: explicit `light`/`dark` server-render `data-theme="mailglass-light|mailglass-dark"`, while `system` is represented by no explicit theme attribute; Phase 112 should add host-scoped cookie persistence at the mount/root-layout seam rather than forcing system with client JS. | Confident | `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md`; `.planning/phases/110-primitives/110-CONTEXT.md`; `mailglass_admin/lib/mailglass_admin/layouts.ex`; `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`; `mailglass_admin/lib/mailglass_admin/operator/shell.ex`; `mailglass_admin/lib/mailglass_admin/components.ex` |

### Navigation & Pagination Honesty

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Active navigation should build on the shared `nav_link`/`nav_pill` primitives, but Phase 112 still needs to make the non-color cue unambiguous at both desktop and mobile levels; pagination needs new read/display state because current lists are limit-only and do not know total result count or page boundaries. | Likely | `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`; `lib/mailglass/operator/deliveries.ex`; `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`; `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`; `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` |

## Corrections Made

No corrections - all assumptions confirmed by the user.

## External Research

No external research was performed during discussion. Planning should lightly research the exact
core `list_tenants` projection shape: distinct-tenant query versus dedicated read model, and how
that projection composes with `Mailglass.Tenancy.scope/2` from `operator_actor`.
