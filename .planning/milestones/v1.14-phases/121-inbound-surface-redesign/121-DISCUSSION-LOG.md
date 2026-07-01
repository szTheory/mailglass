# Phase 121: Inbound surface redesign - Discussion Log (Assumptions Mode + Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 121-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 121-inbound-surface-redesign
**Mode:** assumptions → research synthesis (user requested deep per-area research)
**Areas analyzed:** Empty-state IA / JTBD · PII raw-payload reveal UX · Replay modal a11y ·
Cross-surface design-system coherence + ratchet/paired-test engineering

## Assumptions Presented (initial, codebase-only)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| (A) Mirror 120's no-data/no-match/populated `cond`; orientation empty-pane-only; withhold filters/CTA/health in no-data; `:no_tenant` upstream | Confident | inbound_live.ex:382-533, empty_state_for/2 :659, filters_active? :672, operator_live.ex:489-509 |
| (B) Preserve PII/raw-payload reveal invariants + replay gate order as hard guardrails | Confident | inbound_live.ex:100/565/584 reveal reset, :944 authorize_reveal, :274-322 replay gate, structural.spec.js:1176-1177 |
| (C) Cross-cutting matrix via existing capabilities; paired-test update operator.spec.js:462-476; add inbound judgment gate; re-shoot personas | Confident | operator.spec.js:462-476, records_list.ex data_state, persona-screenshots.spec.js |

## User Direction

User did not accept the codebase-only assumptions as-is; requested deep research per area
(pros/cons/tradeoffs, idiomatic Elixir/Phoenix, lessons from comparable tools, DX/UX, JTBD lenses,
design pillars, current brandbook) to one-shot a coherent recommendation set. Four parallel
`gsd-advisor-researcher` agents were spawned (one per area).

## Research Findings (synthesized)

- **Area A (Empty-state IA):** Confirm-mirror-120 + the D-05 delta (remove orientation from the
  `is_nil(@detail)` branch → empty-pane-only) + withhold the health strip in no-data. Detail-column
  forensic density is legitimate (selection-gated, progressively disclosed), not info-dump. Lessons:
  Sentry/Stripe/Postmark calm-empty + dense-detail; reject Django-admin full-toolbar-over-empty.
  Microcopy noun fix "records" → "InboundMessages".
- **Area B (PII reveal):** Keep all invariants; add bounded a11y polish (ARIA disclosure,
  aria-expanded/controls, live-region announce, "Re-redact" collapse, focus-ring) + PII-free
  telemetry count. Reject sticky reveal (PII-leak footgun), per-field reveal (storage shape),
  confirm-modal-on-every-reveal (over-friction). **Strategic flag:** durable persisted reveal-audit
  vs ephemeral telemetry.
- **Area C (Replay modal):** Keep full-modal confirmation weight (reject inline/undo/type-to-confirm
  — append-only ledger has no real undo). Add two APG fixes (Tab focus-trap + double-submit
  pending-lock) on BOTH surfaces. Defer background `inert` + btn-error-color.
- **Area D (Cross-surface):** Biggest latent finding — `data_state` built into `RecordsList` but
  NEVER wired in `inbound_live.ex` (error/permission/stale = dead code); wire it. Inbound is the
  "before" picture of Deliveries. Paired-test seam operator.spec.js:462-476 + new judgment gate +
  persona re-shoot (no new cells) + TokenParity-safe procedure. Copy fix confirmed.

## Decisions Made (user-facing forks)

### Scope ambition
- **Original (mechanical):** mirror 120 empty-state IA + paired tests only.
- **User chose:** "Mirror + in-scope a11y/correctness fixes" — also wire dormant `data_state`,
  reveal disclosure a11y + re-redact, replay-modal focus-trap + double-submit on both surfaces.
- **Reason:** roadmap success-criterion 3 explicitly demands WCAG 2.2 AA + APG + predictable replay
  dialog, so the a11y work is in-scope, not creep.

### Reveal audit durability
- **Options:** PII-free telemetry count (rec) / durable persisted audit row / no audit.
- **User chose:** PII-free telemetry count (`[:mailglass_admin, :inbound, :reveal_raw, :stop]`,
  tenant_id/record_id/outcome only).
- **Reason:** observable without touching storage/retention contract; reversible; durable audit
  deferred as its own trust-posture decision.

## External Research

Performed via 4 parallel `gsd-advisor-researcher` agents (not WebSearch). No library-version gaps
surfaced — the ROADMAP flags surface-redesign phases 120-122 to plan directly with no research;
this phase inherits established Phase 119/120 patterns onto a deliberate clone-sibling surface.
