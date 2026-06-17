---
phase: 99-inbound-surface
plan: 03
subsystem: ui
tags: [phoenix-liveview, inbound, routing-trace, evidence-card, design-system]

requires:
  - phase: 99-inbound-surface
    provides: "Plan 99-01 inbound summary seam and Phase 99 design context"
provides:
  - "Responsive inbound RoutingTrace clause grid with masked actual values"
  - "Locked EvidenceCard reveal affordance with raw payload gated by reveal_state"
  - "Token-clean inbound filter labels and replay modal copy"
affects: [phase-99, phase-101, phase-103, inbound-surface]

tech-stack:
  added: []
  patterns:
    - "Inbound clause comparisons render as Dimension / Expected / Actual grids"
    - "Sensitive raw evidence remains absent unless reveal_state is :revealed"

key-files:
  created:
    - ".planning/phases/99-inbound-surface/99-03-SUMMARY.md"
  modified:
    - "mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex"
    - "mailglass_admin/test/mailglass_admin/inbound/components_test.exs"
    - "mailglass_admin/priv/static/app.css"

key-decisions:
  - "RoutingTrace keeps matcher verdict truth upstream and only changes presentation."
  - "EvidenceCard keeps raw payload bytes absent in redacted and denied states; :revealed is the only raw-rendering state."
  - "Admin CSS bundle is committed after class changes to preserve the bundle-clean gate."

patterns-established:
  - "Mono evidence and matcher chips use rounded-box border border-base-300 bg-base-100 px-2 py-1 text-label."
  - "Inbound labels use text-label uppercase font-bold text-secondary without arbitrary tracking."

requirements-completed: [GROUP-03]

duration: 5min
completed: 2026-06-15
---

# Phase 99 Plan 03: Inbound Routing and Evidence Group Uplift Summary

**Inbound routing and raw-evidence cards are now scannable, token-clean, and preserve PII/raw-payload boundaries by default.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-15T03:04:26Z
- **Completed:** 2026-06-15T03:08:42Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Reworked `RoutingTrace` into a responsive Dimension / Expected / Actual grid with mono expected/actual chips and the first failing clause emphasis intact.
- Reworked `EvidenceCard` around an explicit `Raw source locked` affordance, chip-based metadata/facts, and raw payload rendering only in the `:revealed` state.
- Cleaned inbound filter labels and replay modal copy/type controls to the Phase 96/99 token and copy locks.

## Task Commits

1. **Task 1 RED: RoutingTrace grid test** - `0cdb34c5` (test)
2. **Task 1 GREEN: RoutingTrace grid implementation** - `deec0ac5` (feat)
3. **Task 2 RED: Evidence reveal tests** - `78129e0a` (test)
4. **Task 2 GREEN: EvidenceCard locked affordance** - `c29ff571` (feat)
5. **Task 3 RED: Filter/replay token cleanup tests** - `01e3da3b` (test)
6. **Task 3 GREEN: Filter/replay token cleanup** - `1a99a20f` (feat)
7. **Generated bundle:** `1ff2c016` (chore)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex` - Responsive clause grid, token-clean labels, and mono expected/actual chips.
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` - Locked reveal affordance, evidence fact chips, no `btn-sm`, and no arbitrary tracking.
- `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` - `Time window` copy and token-clean filter labels.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` - `text-heading`, COPY-LD-13 body copy, and 44px close control.
- `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` - Component tests for routing masking, evidence reveal states, filter labels, and replay copy.
- `mailglass_admin/priv/static/app.css` - Rebuilt generated CSS bundle for the new class set.

## Decisions Made

- Routing matcher semantics remain reflected from upstream verdict tuples; the component does not recompute matching.
- Recipient actuals remain masked through `MailglassAdmin.Components.mask_recipient/1`.
- Raw payload bytes remain absent from redacted and denied evidence states and render only in the bounded read-only `<pre>` for `:revealed`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Rebuilt generated admin CSS bundle**
- **Found during:** Overall verification
- **Issue:** `mix mailglass_admin.assets.build` produced a `priv/static/app.css` diff after class changes.
- **Fix:** Committed the rebuilt bundle so `git diff --exit-code priv/static/` is clean.
- **Files modified:** `mailglass_admin/priv/static/app.css`
- **Verification:** `git -C mailglass_admin diff --exit-code priv/static/`
- **Committed in:** `1ff2c016`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope expansion; the bundle commit satisfies the existing Phase 99 static-asset cleanliness constraint.

## Issues Encountered

None beyond the expected TDD RED failures and generated CSS bundle update.

## Known Stubs

None. Stub-pattern scan only found legitimate input placeholders, documented redaction placeholder wording, and intentional empty-state handling.

## Authentication Gates

None.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` - PASS, 20 tests / 0 failures
- `rg -n 'tracking-\[|text-(lg|xl|2xl|3xl|4xl|5xl)\b' mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` - PASS, no matches
- `git -C mailglass_admin diff --exit-code priv/static/` - PASS

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

GROUP-03 is ready for later Phase 99 flow/browser verification and Phase 103 quality-ratchet closeout. The unrelated `.planning/v1.11-MILESTONE-AUDIT.md` file was left untracked and uncommitted.

## Self-Check: PASSED

- Files exist: all 6 modified files found.
- Commits exist: `0cdb34c5`, `deec0ac5`, `78129e0a`, `c29ff571`, `01e3da3b`, `1a99a20f`, and `1ff2c016` found in git log.

---
*Phase: 99-inbound-surface*
*Completed: 2026-06-15*
