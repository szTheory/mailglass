---
phase: "97"
plan: "02"
subsystem: mailglass_admin
tags: [component-uplift, focus-ring, typography, tracking, touch-target]
dependency_graph:
  requires: []
  provides: [STATE-LD-11, STATE-LD-12, STATE-LD-13, STATE-LD-14, GAP-01, GAP-04]
  affects:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
tech_stack:
  added: []
  patterns:
    - focus-visible:ring-inset for full-width row buttons (inset avoids li boundary clip)
    - text-heading token replacing banned text-xl raw Tailwind size class
    - Arbitrary tracking-[0.08em] removal (conformance gate compliance)
    - btn-sm removal + px-md/px-sm + min-h-11 for 44px touch-target floor
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
decisions:
  - ring-inset used on deliveries_list row button (not ring-offset) because the button spans full list item width — an offset ring clips at the li boundary
  - text-heading (20px Inter Tight token) replaces text-xl (banned raw Tailwind utility) per UI-SPEC Typography constraint
  - All five filters_form label spans updated uniformly; heading letter-spacing is handled by the global h1/h2/h3 rule in app.css, not per-element tracking
  - btn-sm removal from support_cards: tier-1 buttons get px-md for horizontal padding; tier-2 ghost gets px-sm (replaces arbitrary px-3); both get min-h-11 for the 44px floor
metrics:
  duration_seconds: 104
  completed_date: "2026-06-14"
  tasks_completed: 3
  files_modified: 5
---

# Phase 97 Plan 02: Wave-1 Component Uplifts Summary

**One-liner:** Row focus ring (ring-inset), text-heading token on both detail headers, tracking-[0.08em] removed from five filter labels, btn-sm removed from four support_cards CTA buttons with min-h-11 applied.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | deliveries_list row focus ring + detail_header text-xl fixes | b6e5ba5b | deliveries_list.ex, operator/detail_header.ex, inbound/detail_header.ex |
| 2 | Remove tracking-[0.08em] from all filters_form labels | 39e5f52d | filters_form.ex |
| 3 | Remove btn-sm from support_cards CTA buttons | 0e6c4b5c | support_cards.ex |

## What Was Built

**Task 1 — Focus ring + typography token fixes (3 files)**

- `deliveries_list.ex`: Appended `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset` to the row button's static class string. `ring-inset` chosen (not `ring-offset-1`) because the button fills the full `<li>` width — an offset ring would clip. `aria-current` and `aria-selected` attributes confirmed intact.
- `operator/detail_header.ex`: Replaced `text-xl` with `text-heading` on the recipient h2 (line 21). Banned raw Tailwind size class removed; `text-heading` resolves via `app.css @theme --text-heading` token (20px / Inter Tight).
- `inbound/detail_header.ex`: Same replacement at line 38. `Components.mask_recipient(...)` call confirmed intact.

**Task 2 — tracking-[0.08em] removal (1 file, 5 occurrences)**

- `filters_form.ex`: All five label `<span>` elements (Tenant, Provider, Status, Event, Window) had `tracking-[0.08em]` removed. Result class list: `mb-1 text-label font-bold uppercase text-secondary`. Heading-level letter-spacing is handled by the global `h1, h2, h3` rule in `app.css`; label spans are not headings and carry no explicit tracking.

**Task 3 — btn-sm removal + min-h-11 on support_cards (1 file, 4 buttons)**

- Lines 56, 102, 152 (tier-1 primary CTAs): `btn btn-sm btn-primary mt-sm` → `btn btn-primary px-md mt-sm min-h-11`. Removes btn-sm (32px floor) so `min-h-11` (44px) applies uncontested.
- Line 204 (tier-2 ghost CTA): `btn btn-ghost btn-sm px-3` → `btn btn-ghost px-sm min-h-11`. `px-3` (12px arbitrary) replaced with `px-sm` (8px token).

## Verification Results

All five post-execution checks passed:

1. `grep -c "focus-visible:ring-inset" deliveries_list.ex` = **1**
2. `grep -c "text-xl" operator/detail_header.ex inbound/detail_header.ex` = **0** (both files)
3. `grep -c "tracking-\[0.08em\]" filters_form.ex` = **0**
4. `grep -c "btn-sm" support_cards.ex` = **0**
5. `cd mailglass_admin && mix compile --warnings-as-errors` = **exit 0** (clean, "Generated mailglass_admin app")

## Deviations from Plan

None — plan executed exactly as written. All five target locations matched the documented line numbers and class strings in the plan context.

## Known Stubs

None. All changes are complete token/class substitutions with no placeholder values.

## Threat Flags

None. All changes are HEEx class string edits only. No user input processed, no new network endpoints, no auth path changes. aria-current/aria-selected on deliveries_list row and Components.mask_recipient in inbound/detail_header confirmed unmodified (T-97-02-01 acceptance condition met). phx-click handlers in support_cards not touched (T-97-02-02 acceptance condition met).

## Self-Check: PASSED

- [x] `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` contains `focus-visible:ring-inset` — verified
- [x] `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` contains `text-heading`, no `text-xl` — verified
- [x] `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` contains `text-heading`, no `text-xl` — verified
- [x] `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` has zero `tracking-[0.08em]`, five `text-label font-bold uppercase text-secondary` — verified
- [x] `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` has zero `btn-sm`, four `min-h-11` CTA buttons — verified
- [x] Commits b6e5ba5b, 39e5f52d, 0e6c4b5c exist in git log — verified
- [x] `mix compile --warnings-as-errors` clean — verified
