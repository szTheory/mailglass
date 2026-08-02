# Phase 149: First-Send Contract Foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `149-CONTEXT.md`; this log preserves the analysis.

**Date:** 2026-08-02
**Phase:** 149-first-send-contract-foundation
**Mode:** assumptions
**Areas analyzed:** Tenancy Contract, Envelope Preflight and Error Contract, Rendering and Published Configuration

## Assumptions Presented

### Tenancy Contract

| Assumption | Confidence | Evidence |
|---|---|---|
| Shared outbound preflight treats `SingleTenant` as implicit tenant `"default"`, while configured custom tenancy without a stamp remains fail-closed. | Confident | `lib/mailglass/tenancy.ex`; `lib/mailglass/tenancy/single_tenant.ex`; `lib/mailglass/outbound.ex`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/STATE.md` |

### Envelope Preflight and Error Contract

| Assumption | Confidence | Evidence |
|---|---|---|
| One shared pure gate validates exactly one total `to`/`cc`/`bcc` recipient and a supported non-empty HTML and/or plaintext body before every side effect. | Confident | `lib/mailglass/outbound.ex`; `lib/mailglass/renderer.ex`; `mailglass_admin/lib/mailglass_admin/preview_live.ex` |
| Invalid envelope/body shapes reuse `%Mailglass.SendError{type: :preflight_rejected}` with bounded non-PII context. | Likely | `lib/mailglass/errors/send_error.ex`; `lib/mailglass/error.ex`; `docs/api_stability.md` |

### Rendering and Published Configuration

| Assumption | Confidence | Evidence |
|---|---|---|
| `Mailglass.Renderer` owns body precedence and config behavior: preserve explicit plaintext, support text-only mail, conditionally generate plaintext for HTML-only mail, and honor `css_inliner: :none`. | Confident | `lib/mailglass/config.ex`; `lib/mailglass/renderer.ex`; `lib/mailglass/outbound.ex`; `mailglass_admin/lib/mailglass_admin/preview_live.ex`; `guides/authoring-mailables.md`; `guides/getting-started.md` |

## Corrections Made

No corrections — all assumptions confirmed.

