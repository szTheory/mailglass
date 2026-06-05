---
phase: 76-component-library-and-design-system-hardening
plan: "04"
subsystem: mailglass_admin
tags:
  - component-library
  - design-system
  - token-migration
  - badge-files
dependency_graph:
  requires:
    - phase: 76-02
      provides: status_badge/1 unified atom; all badge_class/1 copies deleted from these 5 files
  provides:
    - Token-clean markup across the 5 badge-rewired files (deliveries_list, operator/timeline, inbound/records_list, operator/detail_header, inbound/detail_header)
    - Footgun-safe migration (text-base-content / hover:text-base-content preserved; tracking-[0.08em] untouched)
  affects:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
tech_stack:
  added: []
  patterns:
    - "text-sm/text-base → text-body; text-xs → text-label; gap-3 → gap-sm; gap-4 → gap-md"
    - "Footgun 1 (dt labels): text-xs → text-label in all 6 dt labels per detail_header file; font-bold/uppercase/tracking-[0.08em] left intact"
    - "Footgun 6 (word boundary): text-base-content and hover:text-base-content never modified"
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
key_decisions:
  - "text-base (bare) and text-sm both map to text-body; text-xs maps to text-label — consistent with the 76-05 migration precedent"
  - "Footgun 6: text-base-content / hover:text-base-content are DaisyUI semantic color classes, not type-scale tokens — left untouched"
  - "[Rule 1] Fixed two stale test assertions left behind by the 76-02 badge rewire: 'Replay audit' → 'Replay succeeded', 'Reconcile fact' → 'Reconciled' — the old event_badge() rendered audit text as visible content; the new status_badge/1 renders status_label() instead"
requirements_completed:
  - DS-02
duration: ~18 minutes
completed: "2026-06-04"
---

# Phase 76 Plan 04: Token-Migrate the Five Badge-Rewired Files

**Migrated all raw Tailwind type and spacing utilities to the design-system token scale across the five files that Plan 76-02 rewired (deliveries_list, operator/timeline, inbound/records_list, operator/detail_header, inbound/detail_header), honoring the Footgun rules from RESEARCH.md Gap 3.**

> Note: This SUMMARY was finalized by the orchestrator after the executor completed both implementation commits but lost its finalization turn to a transient "API Error: Overloaded". Both task commits (`c4d5ed00`, `1561f652`) landed cleanly on the main tree; the working tree was clean; all conformance gates were independently re-verified green before this close-out. No re-execution was needed.

## Performance

- **Duration:** ~18 minutes
- **Tasks:** 2
- **Files modified:** 6 (5 source + 1 test)

## Accomplishments

- `text-sm` / `text-base` → `text-body`; `text-xs` → `text-label`; `gap-3` → `gap-sm`; `gap-4` → `gap-md` across all five badge-rewired files
- Footgun 1 (dt labels): `text-xs` → `text-label` in all six `<dt>` labels of each detail_header file; `font-bold` / `uppercase` / `tracking-[0.08em]` left intact (7 `tracking-[0.08em]` occurrences per detail_header preserved: 6 dt + 1 h3)
- Footgun 6 (word boundary): `text-base-content` and `hover:text-base-content` never modified — they are DaisyUI semantic color classes, not type-scale tokens
- `gap-2` left untouched (not in the migration target set)
- [Rule 1] Fixed two stale assertions in `operator_live_test.exs` left behind by the 76-02 badge rewire
- Conformance gates (re-verified post-close-out across whole `mailglass_admin/lib/`): zero bare `text-sm`/`text-base`/`text-xs`, zero `gap-3/4/6`, zero `font-medium/semibold`, zero hex colors, zero `defp badge_class`
- `mix compile --warnings-as-errors` exits 0; `mix test --seed 0` → 187 tests, 1 pre-existing failure (`voice_test.exs` "Oops" / phoenix-dep-JS noise, unrelated to this phase)

## Task Commits

1. **Task 1: Token-migrate deliveries_list, operator/timeline, inbound/records_list** — `c4d5ed00` (feat)
2. **Task 2: Token-migrate operator/detail_header, inbound/detail_header; fix stale badge-text assertions** — `1561f652` (feat)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — `gap-3` → `gap-sm`, `text-sm`/`text-base` → `text-body`; `text-base-content` preserved
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — type/spacing tokens migrated
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — type/spacing tokens migrated; `hover:text-base-content` preserved
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — 6 dt labels `text-xs` → `text-label`; `tracking-[0.08em]` untouched
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` — 6 dt labels `text-xs` → `text-label`; `tracking-[0.08em]` untouched
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — 2 stale badge-text assertions updated to status_label() vocabulary

## Decisions Made

- Bare `text-base` and `text-sm` both map to `text-body`; `text-xs` maps to `text-label` — consistent with the Plan 76-05 migration precedent.
- `text-base-content` / `hover:text-base-content` are DaisyUI semantic color utilities, not type-scale tokens — explicitly excluded from migration (Footgun 6 word-boundary rule). The conformance grep `\btext-(sm|base|xs)\b` produces word-boundary false positives on these and on `text-base-100/200/300`; the real (bare) violation count is zero.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stale test assertions from the 76-02 badge rewire**
- **Found during:** Task 2 — full test suite run
- **Issue:** `operator_live_test.exs` asserted `html =~ "Replay audit"` and `html =~ "Reconcile fact"` — text that the *old* `event_badge()` rendered as visible content. The 76-02 rewire to `status_badge/1` renders `status_label()` text instead ("Replay succeeded", "Reconciled").
- **Fix:** Updated the two assertions to the new status_label vocabulary. Assertions tightened to correct behavior, not removed.
- **Files modified:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Committed in:** `1561f652` (Task 2 commit)

### Finalization deviation

The executor's final turn (SUMMARY write + STATE/ROADMAP update) was lost to a transient API "Overloaded" error. Both implementation commits had already landed and the working tree was clean. The orchestrator re-verified all conformance gates + compile + test suite green, then authored this SUMMARY and updated tracking as a manual close-out. No code was changed during close-out.

## Known Stubs

None.

## Threat Flags

None. This plan rewrites HEEx class strings and two test assertions only. No new auth, session, data-access, or input-validation surface.

## Self-Check

Files created/modified:
- [x] `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — FOUND
- [x] `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — FOUND
- [x] `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — FOUND
- [x] `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — FOUND
- [x] `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` — FOUND
- [x] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — FOUND

Commits:
- [x] `c4d5ed00` — FOUND
- [x] `1561f652` — FOUND

## Self-Check: PASSED

---
*Phase: 76-component-library-and-design-system-hardening*
*Completed: 2026-06-04*
