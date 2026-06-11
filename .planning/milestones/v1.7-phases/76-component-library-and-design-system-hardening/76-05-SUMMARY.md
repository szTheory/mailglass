---
phase: 76-component-library-and-design-system-hardening
plan: "05"
subsystem: mailglass_admin
tags: [token-migration, design-system, css, heex, admin-ui]
dependency_graph:
  requires: [76-01]
  provides: [DS-02-partial]
  affects: [mailglass_admin/lib]
tech_stack:
  added: []
  patterns: [design-system-tokens, footgun-1-dt-labels, footgun-2-font-mono, footgun-5-label-text, footgun-6-word-boundary]
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
    - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex
    - mailglass_admin/lib/mailglass_admin/inbound/timeline.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
decisions:
  - "[D-09] operator_live.ex:279-362 (Phase 75 Overview/orientation) excluded from migration — those lines are already token-clean"
  - "[D-08] Token mapping applied: text-sm/base → text-body; text-xs → text-label; gap-3 → gap-sm; gap-4 → gap-md; gap-6 → gap-lg"
  - "[Footgun 1] dt/dd uppercase label patterns: text-xs → text-label only; font-bold/uppercase/tracking-[0.08em] untouched"
  - "[Footgun 2] font-mono text-xs in Preview pre/code/table: text-xs → text-label; font-mono left unchanged"
  - "[Footgun 5] label-text text-sm font-normal: text-sm → text-body; font-normal retained"
  - "[tabs.ex] Inline style background: #ffffff replaced with var(--color-base-100) — the only hex color in lib/"
metrics:
  duration: 20m
  completed: "2026-06-04"
  tasks_completed: 2
  files_modified: 15
---

# Phase 76 Plan 05: Token Migration (Remaining 15 Admin Files) Summary

Token-migrated all 15 remaining admin HEEx files from raw Tailwind type/spacing utilities to the design-system token scale, and fixed the single hex color violation in preview/tabs.ex.

## What Was Done

All 15 files listed in the plan's `files_modified` now have zero raw `text-sm`, `text-base`, `text-xs`, `gap-3`, `gap-4`, or `gap-6` class strings. The single `#ffffff` inline style in `preview/tabs.ex:113` was replaced with `var(--color-base-100)`.

### Task 1: Inbound sub-components and core files (commit bfff1f1c)

Files: `components.ex`, `inbound/evidence_card.ex`, `inbound/filters_form.ex`, `inbound/replay_modal.ex`, `inbound/routing_trace.ex`, `inbound/timeline.ex`, `inbound_live.ex`

Key changes:
- `components.ex`: `flash` alert `text-sm` → `text-body`; `badge/1` stub `text-xs` → `text-label`
- `inbound/evidence_card.ex`: Full dt/dd grid migration; verification_facts labels; pre element text-xs → text-label; gap-3 → gap-sm throughout. Also updated docstring example from `text-xs` to `text-label` to stay in sync.
- `inbound/filters_form.ex`: 5x `text-xs font-bold uppercase tracking-[0.08em]` → `text-label font-bold uppercase tracking-[0.08em]` (Footgun 1 dt label pattern — tracking unchanged)
- `inbound/replay_modal.ex`: gap-4 → gap-md; gap-3 → gap-sm; text-sm → text-body
- `inbound/routing_trace.ex`: text-base/sm/xs → text-body/text-label throughout; dt label tracking-[0.08em] untouched
- `inbound/timeline.ex`: text-base/sm/xs → text-body/text-label; gap-3 → gap-sm
- `inbound_live.ex`: gap-3 → gap-sm; gap-6 → gap-lg; text-sm/base → text-body (only true text-base, not text-base-content)

### Task 2: Operator sub-components, operator_live.ex lines 363+, preview files (commit 439cc16d)

Files: `operator/filters_form.ex`, `operator/replay_modal.ex`, `operator/suppression_card.ex`, `operator_live.ex`, `preview/assigns_form.ex`, `preview/sidebar.ex`, `preview/tabs.ex`, `preview_live.ex`

Key changes:
- `operator/filters_form.ex`: 5x text-xs labels → text-label (Footgun 1)
- `operator/replay_modal.ex`: gap-4 → gap-md; gap-3 → gap-sm; text-sm/xs → text-body/text-label; dt label tracking-[0.08em] untouched
- `operator/suppression_card.ex`: text-base/sm/xs → text-body/text-label; gap-3 → gap-sm
- `operator_live.ex`: **D-09 boundary enforced** — only lines 363+ modified (pre-existing Deliveries `:else` branch); lines 279-362 (Phase 75 Overview/orientation) untouched
- `preview/assigns_form.ex`: `label-text text-sm` → `label-text text-body` (Footgun 5); `font-mono text-xs` → `font-mono text-label` (Footgun 2); gap-3 → gap-sm
- `preview/sidebar.ex`: text-base/sm → text-body on all navigation items
- `preview/tabs.ex`: **hex fix** — `background: #ffffff` → `background: var(--color-base-100)`; 4x tab buttons text-sm → text-body; font-mono text-xs → text-label on pre/th/td (Footgun 2)
- `preview_live.ex`: text-base/sm/xs → text-body/text-label; gap-3/4 → gap-sm/md; font-mono text-xs → text-label

## Verification Results

1. **15-file token gate**: Zero `text-sm`, `text-base`, `text-xs`, `gap-3`, `gap-4`, `gap-6` in all 15 plan files — CLEAN
2. **Hex gate**: `grep -rE '#[0-9a-fA-F]{3,6}\b' lib/ --include="*.ex"` — HEX-CLEAN
3. **tabs.ex hex fix confirmed**: `background: var(--color-base-100)` present in preview/tabs.ex
4. **D-09 boundary**: operator_live.ex lines 279-362 untouched — zero violations below line 363
5. **Compile**: `mix compile --warnings-as-errors` — exits 0, 15 files compiled cleanly
6. **Tests**: 187 tests, 1 pre-existing failure (voice_test "oops" from Phoenix dep JS — tracked in user memory `project_voice_test_noops_dep_js.md`, unrelated to this plan)

**Note on overall lib/ gate**: The overall `grep -rE ... lib/` check shows violations in files from Plans 76-03 and 76-04 (`operator/support_cards.ex`, `operator/detail_header.ex`, `operator/timeline.ex`, `operator/deliveries_list.ex`, `inbound/detail_header.ex`, `inbound/records_list.ex`). These are NOT this plan's scope — they belong to Plans 76-03/76-04 which run in parallel (Wave 4). The overall zero-violation gate will be achieved when all Phase 76 plans complete.

## Deviations from Plan

None - plan executed exactly as written. All footgun rules honored, D-09 boundary respected, hex fix applied.

## Known Stubs

None — this is a pure CSS class rename with one inline style value replacement. No data stubs introduced.

## Threat Flags

None — pure HEEx token migration with one inline CSS value replacement. No new network endpoints, auth paths, or data flows introduced.

## Self-Check: PASSED

Files exist:
- [x] mailglass_admin/lib/mailglass_admin/components.ex — FOUND
- [x] mailglass_admin/lib/mailglass_admin/preview/tabs.ex — FOUND (hex fix confirmed)
- [x] mailglass_admin/lib/mailglass_admin/operator_live.ex — FOUND (D-09 boundary confirmed)

Commits exist:
- [x] bfff1f1c — FOUND (Task 1)
- [x] 439cc16d — FOUND (Task 2)
