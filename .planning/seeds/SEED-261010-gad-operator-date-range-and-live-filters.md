---
id: SEED-261010-gad
status: dormant
planted: 2026-10-10
planted_during: ad-hoc operator UI refinement
trigger_when: after the operator UI has a strong visual baseline, when planning filtering and incident investigation improvements
scope: Deliveries and Inbound filtering
audit_acknowledged:
  milestone: v2.9
  at: 2026-10-26
  status: dormant
---

# SEED-261010-gad: Custom date ranges and live operator filtering

## Why This Matters

Investigating an email incident often means finding records during a specific historical interval. Relative presets alone require guesswork. Requiring Apply filters after each selection also adds friction; the user explicitly deferred live filtering until the visual baseline is ready.

## When to Surface

After the remaining operator UI reaches a strong baseline; revisit when planning filtering or incident investigation work.

## Scope and Direction

- Keep Last 24 hours / 7 days / 30 days presets and add Custom range with From/To controls on both Deliveries and Inbound.
- Show the timezone used for date entry. Convert bounds to UTC for URL/query storage; define end-bound inclusion consistently and test timezone/DST edges.
- Keep URL state shareable, tenant scoping enforced, pagination reset on a changed range, and counts aligned with the same filters.
- Preserve each list's existing meaning of time filtering (delivery activity vs inbound receipt) and explain it in the field tooltip.
- Apply select filters on change and debounce search input. Resolve stale responses, validation, clear/reset, and browser Back behavior before removing Apply filters.
- Use existing components and native controls where practical; avoid a new date-picker dependency unless requirements justify it.

## Breadcrumbs

- `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex`
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex`
- `lib/mailglass/operator/deliveries.ex`
- User discussion on 2026-10-10: custom date ranges for debugging, plus earlier explicit request to plant instant filtering/search as a future GSD seed.
