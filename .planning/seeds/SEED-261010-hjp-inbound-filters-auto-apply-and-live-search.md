---
id: SEED-261010-hjp
status: dormant
planted: 2026-10-10
planted_during: v2.9 / Phase 173 — Consistency and Delivery Evidence
trigger_when: after the inbound admin UI baseline is reviewed and accepted
scope: unknown
---

# SEED-261010-hjp: Auto-apply inbound filters and search as you type

## Why This Matters

The inbound records page currently requires an explicit Apply filters action after changing filter values. Once the broader inbound UI has reached an accepted baseline, revisit whether provider, mailbox outcome, and time-window selections should apply immediately and whether search should update as the user types. This could make investigation feel more direct and reduce an extra interaction, while keeping the current filters-first baseline focused and stable.

## When to Surface

**Trigger:** after the inbound admin UI baseline is reviewed and accepted, and the remaining UI work has moved beyond foundational cleanup.

Surface this seed during the next milestone that includes inbound admin usability or interaction polish.

## Scope Estimate

**Unknown** — decide after inspecting the then-current filter implementation and baseline.

## Breadcrumbs

- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — inbound list, URL-backed filters, and filter events.
- `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` — provider, mailbox outcome, and time-window controls.
- `.planning/phases/173-consistency-and-delivery-evidence/173-INBOUND-REFINEMENT.md` — current accepted refinement and filter semantics.

## Notes

At implementation time, compare immediate filter application with the current explicit-submit behavior. Consider debouncing free-text search, preserving shareable URL state and browser history, loading/error feedback, stale-request handling, keyboard/accessibility behavior, and the existing distinction between mailbox-outcome list filtering and summary counts. Keep the interaction simple; avoid adding a dependency unless the existing LiveView/browser primitives cannot support the chosen behavior cleanly.

Captured as a follow-up seed so this interaction change can wait until the rest of the inbound UI is a strong baseline.
