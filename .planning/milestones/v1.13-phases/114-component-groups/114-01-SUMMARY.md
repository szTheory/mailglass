---
phase: 114-component-groups
plan: 01
subsystem: ui
tags: [phoenix-component, daisyui, conformance-gate, design-system, heex, bash, tdd]

# Dependency graph
requires:
  - phase: 110-primitives
    provides: stat_card/1 + PRIMITIVE-DRIFT-GATE shape mirrored by card/1
  - phase: 111-filter-wrappers
    provides: FORM-DRIFT FILTER_WRAPPERS file-scoped-array idiom copied for GROUP_SURFACES
provides:
  - MailglassAdmin.Components.card/1 — thin group-surface shell primitive (border + radius + bg-base-200 + outer padding only)
  - SPACE-GATE conformance gate (off-grid spacing ban, file-scoped to 8 group surfaces)
  - GROUP-GATE conformance gate (same-tone card-in-card tripwire)
  - card/1 enforced as a PRIMITIVE-DRIFT-GATE primitive
  - GROUP_SURFACES explicit 8-file array scoping the new spacing/depth gates
affects: [114-02-component-gallery-specimens, 114-03-group-surface-sweep, 114-04-floki-depth-proof]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Thin shell primitive (≤20 lines): one closed :padding knob, :global rest, single required slot, no layout-engine slots (D-01/D-02)"
    - "File-scoped conformance gate: explicit module-path array (GROUP_SURFACES) instead of recursive $LIB grep (Pitfall 1 / D-12)"
    - "Word-boundary-anchored spacing regex: leading (^|[^a-z-]) + trailing ([^0-9.a-z-]|$) rejects min-h-11/border-l-4/mt-0.5/gap-3xl while catching mt-1/p-6/space-y-1/gap-2"
    - "Cheap tripwire gate vs. depth authority: GROUP-GATE is a grep tripwire; Floki ExUnit (plan 04) owns real elevation-depth"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/scripts/check-conformance.sh

key-decisions:
  - "Dropped the decorative leading `card` DaisyUI class from the shell (RESEARCH Open Question 2 — no DaisyUI card layout is relied on); gate signatures match the dropped-class shape"
  - "card/1 owns no header/footer/grid slots and no inter-card rhythm; shadow-raised / data-group-card stay at call sites (plan 03), not baked into the shell (D-02)"
  - "card/1 added to PRIMITIVE-DRIFT-GATE as a standalone def-check, NOT in the gallery render_specimen awk loop (composed specimens register differently — plan 02)"
  - "SPACE-GATE and GROUP-GATE scope to an explicit 8-file GROUP_SURFACES array, never $LIB recursion (17 other lib files share the numerics — Pitfall 1)"

patterns-established:
  - "Pattern 1: Enforcement substrate before the code it enforces — gates land in Wave 1 so the plan-03 sweep/plan-04 proof can run them green"
  - "Pattern 2: Validate gates by RUNNING the script (plant + remove a token), never by regex inspection (project MEMORY)"

requirements-completed: [GROUP-01, GROUP-02]

# Metrics
duration: 6min
completed: 2026-06-20
status: complete
---

# Phase 114 Plan 01: Component Groups — Enforcement Substrate Summary

**Thin `<.card>` group-surface shell primitive (≤20 lines, one :padding knob) plus SPACE-GATE + GROUP-GATE + card PRIMITIVE-DRIFT conformance gates, file-scoped to the 8 group surfaces and validated by running the script.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-20T13:11:27Z
- **Completed:** 2026-06-20T13:17:04Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Extracted `MailglassAdmin.Components.card/1` — a deliberately thin group-surface shell (border + radius + `bg-base-200` + outer padding only), mirroring the `stat_card/1` attr/slot/`@doc since`/def shape. 7-line body, one `:padding` attr (`:md`/`:lg`, default `:md`) with a `card_padding/1` dispatch helper, one `:global` rest, one required `inner_block`. No header/footer/grid slots; no `shadow-raised`/`data-group-card` baked in.
- Added three conformance gates to `check-conformance.sh`: a `GROUP_SURFACES` 8-file array, the SPACE-GATE (word-boundary-anchored off-grid spacing ban), the GROUP-GATE (same-tone card-in-card tripwire), and `card` as a PRIMITIVE-DRIFT-GATE primitive.
- Validated the SPACE-GATE empirically by running the script against a planted-then-removed `mt-7`, and proved the false-positive guard set (`mt-0.5`, `min-h-11`, `h-3`, `border-l-4`, `gap-3xl`, `preview_live.ex`) all stay green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract the thin `<.card>` shell (TDD)** — `242c3592` (test) → `63c8e4ab` (feat)
2. **Task 2: Add SPACE-GATE + GROUP-GATE + card PRIMITIVE-DRIFT entry** — `b6c95a07` (feat)
3. **Task 3: Validate SPACE-GATE by running the script** — no permanent code change (regex was correct; validation only, no fix needed)

_Note: Task 1 used TDD — a failing test commit (RED) followed by the implementation commit (GREEN). No refactor commit was needed (the 7-line shell was already minimal)._

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/components.ex` — added `card/1` thin shell + `card_padding/1` helper (`:md`->`p-md`, `:lg`->`p-lg`)
- `mailglass_admin/test/mailglass_admin/components_test.exs` — added `card/1` describe block (4 tests: md/lg padding, default, `:global` passthrough) + `card_body/0` slot helper
- `mailglass_admin/scripts/check-conformance.sh` — `GROUP_SURFACES` array, SPACE-GATE, GROUP-GATE, `card` PRIMITIVE-DRIFT def-check

## Decisions Made
- **Dropped the leading decorative `card` DaisyUI class** from the shell class list (RESEARCH Open Question 2 — no DaisyUI card layout is relied on). The gate signatures (GROUP-GATE, PRIMITIVE-DRIFT) were written to match this dropped-class shape.
- **card/1 stays a pure shell** — no header/footer/grid slots, no `dl`/`ol`/routing-well spacing absorbed (the documented premature-abstraction footgun, D-02). `shadow-raised` and `data-group-card` are applied at call sites in plan 03.
- **card PRIMITIVE-DRIFT enforcement is a standalone `def card(` check**, not added to the gallery `render_specimen` awk dispatcher loop — composed group specimens (plan 02) register differently from the Phase 110 single-primitive dispatchers (per RESEARCH).
- **Test slot passthrough idiom:** `render_component/3` with a slot-function third arg collides with the `:router` options position, so the inner_block is passed via the assigns map (`%{inner_block: [%{inner_block: fn _, _ -> ... end}]}`) using a module-level `card_body/0` helper.

## Deviations from Plan

None — plan executed exactly as written. The SPACE-GATE regex from RESEARCH Pitfall 1 was correct as specified; Task 3 validation exposed no flaw, so no permanent code change beyond Tasks 1-2 was needed.

## Issues Encountered
- **`~H` slot-function signature in tests:** the initial test used `render_component(&card/1, assigns, fn _assigns -> ~H|...| end)`. `~H` requires a variable literally named `assigns`, and the 3-arg `render_component` treats the 3rd arg as options (`:router`), not a slot. Resolved by passing `inner_block` through the assigns map via a `card_body/0` helper returning `[%{inner_block: fn _, _ -> "card body" end}]`. All 90 component tests green.

## Gate Validation Evidence (Task 3)
- **Planted `mt-7`** in `operator/timeline.ex` → SPACE-GATE caught it (`timeline.ex:21 ... mt-7`); removed → `git diff --quiet` clean.
- **Guard set stays GREEN** (isolated regex proof): `mt-0.5`, `min-h-11`, `h-3 w-3`, `border-l-4`, `gap-3xl`, `w-px h-full` → no-match; `mt-1`, `p-6`, `space-y-1`, `gap-2`, `px-3` → match.
- **`preview_live.ex`** (out-of-scope file) never appears in SPACE-GATE output — file-scope fence (D-12) confirmed.
- **Current `bash scripts/check-conformance.sh` exits 1** — this is the EXPECTED pre-sweep state: SPACE-GATE + GROUP-GATE fire on the un-swept 8 group surfaces (93 raw spacing tokens + 3 same-tone card-in-card signatures). Plan 03 sweeps them to GREEN; plan 04 adds the Floki depth proof. The `card` PRIMITIVE-DRIFT check passes (card/1 now exists).

## Next Phase Readiness
- Substrate is complete: `Components.card/1` is the single shell source, and SPACE-GATE/GROUP-GATE are armed and proven file-scoped.
- **Plan 02** (gallery specimens) can register composed group specimens against the new card shell.
- **Plan 03** (group-surface sweep / box-prison) must drive SPACE-GATE + GROUP-GATE to GREEN by replacing the raw off-grid numerics and routing the 8 surfaces through `Components.card/1`.
- **Plan 04** (Floki depth proof) owns real elevation-depth enforcement; GROUP-GATE remains a cheap tripwire only.
- No group module or live view was touched in this plan (scope fence D-12 held).

## Self-Check: PASSED

All claimed artifacts verified on disk and in git history:
- Files present: `components.ex`, `check-conformance.sh`, `components_test.exs`, `114-01-SUMMARY.md`
- `def card(assigns)` present in `components.ex`; `SPACE-GATE` present in `check-conformance.sh`
- Commits present: `242c3592` (test), `63c8e4ab` (feat card), `b6c95a07` (feat gates)

---
*Phase: 114-component-groups*
*Completed: 2026-06-20*
