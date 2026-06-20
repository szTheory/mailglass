---
phase: 115-pages-flows-micro-animation-microcopy
plan: 01
subsystem: mailglass_admin
tags: [microcopy, flow, responsive, motion, voice-test, tenant-seam]
requires: []
provides:
  - "Locked FLOW-04 verbatim copy on deliveries/inbound data_state + shell tenant surfaces"
  - "320px header-cluster shrink patch (min-w-0 on right cluster)"
  - "Theme-picker label color-transition removal (D-08 inverted default)"
  - "voice_test state cases proving banned-free + verbatim-present + sole-tenant picker-absent"
affects:
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/test/mailglass_admin/voice_test.exs
tech-stack:
  added: []
  patterns:
    - "render_component forcing data_state/tenant_selector states for deterministic copy/voice assertions (no fixtures)"
    - "OperatorFixtures.seed_browser_scenario!(deny_reveal?: false) → single-tenant auto-select mount for picker-absent proof"
key-files:
  created:
    - .planning/phases/115-pages-flows-micro-animation-microcopy/115-01-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/mailglass_admin/voice_test.exs
key-decisions:
  - "Used render_component to force data_state :permission_denied/:stale and tenant 0/>=2 states deterministically (D-12) — zero new fixtures (D-13)"
  - "Proved sole-tenant picker-absent via a live /ops/mail mount seeded to exactly one tenant (deny_reveal?: false), since render_component cannot prove absence"
  - "Aligned inbound :no_tenant select-a-tenant body and gallery data_state specimens to the locked verbatim copy (Rule 1 consistency) to avoid cross-surface copy divergence"
requirements-completed: [FLOW-01, FLOW-02, FLOW-04]
duration: 8 min
completed: 2026-06-20
---

# Phase 115 Plan 01: Pages/Flows + Microcopy (FLOW-04 copy + FLOW-01/02 320px shell patches) Summary

Landed the FLOW-04 microcopy pass (cause-naming, thoughtful-maintainer voice, seven domain nouns) on the three live operator surfaces, removed the theme-picker's always-on color transition (D-08), shrink-patched the header cluster for 320px (D-04), and proved the new permission/stale/tenant states with extended `voice_test` cases asserting both banned-word-absence and locked-verbatim-presence — including a sole-tenant live mount proving the picker is absent under auto-select.

## What Changed

**Task 1 — deliveries + inbound list state copy (97282501):**
- `deliveries_list.ex`: load-error → cause-naming recovery form (D-11); `:permission_denied` → "You do not have access to this tenant's mail operations…"; `:stale` → "Showing Deliveries as of 14:32. Refresh to load the latest." (illustrative timestamp, no live trigger per D-05). The `Status` `<th>` left untouched.
- `records_list.ex`: error/permission/stale aligned to inbound-flavored locked copy; permission heading byte-identical to deliveries ("Access restricted"), sub-copy differs only by "inbound routing" vs "mail operations" — no existence leak (D-10).

**Task 2 — shell tenant copy + 320px + theme transition (b3ff46f8):**
- `shell.ex` tenant_selector: byte-identical locked copy (capital-M "Send a Message", capital-D "inspect its Deliveries"). Three tenant modes kept lexically distinct with their own templates/testids (D-06).
- `shell.ex` header: added `min-w-0` to the right cluster so the tenant chip truncates instead of forcing horizontal overflow at 320px (D-04). Header was already `flex flex-wrap`; mono ID/tenant cells already carried `min-w-0 truncate` + `title`.
- `components.ex` theme_picker label: removed `transition-colors ease-out duration-(--duration-fast)` so theme swaps never animate color (D-08 inverted default). State-layer `:hover` classes carry no transition either, so the swap is flash-free.
- `records_list.ex` `:no_tenant` body aligned to locked select-a-tenant copy (consistency).

**Task 3 — voice_test state cases (6b3ad726):**
- New `data_state` describe: `:permission_denied`/`:stale` for deliveries + inbound via `render_component`, each asserting `@banned_words`-absent AND locked verbatim heading/body present.
- New tenant describe: 0 (`state: :none`) and ≥2 (`state: :select_required`, 2 options) via `render_component` asserting locked copy + per-tenant "Select tenant" link; 1 (sole-tenant) via live `/ops/mail` mount seeded to a single tenant, asserting the `tenant-selector` picker testid is **absent** (auto-select proven, D-06).
- Domain nouns enforced as positive assertions only; no standalone `Status` ban grep (D-12).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Consistency] Synced gallery data_state specimens to locked FLOW-04 copy**
- **Found during:** plan-level verification (`grep -r "There was a problem loading" lib/`).
- **Issue:** `gallery_live.ex` (~1130) rendered the pre-FLOW-04 error/permission/stale specimen copy, contradicting the now-updated live deliveries/inbound surfaces.
- **Fix:** Updated the three `:data_state` specimen bodies to the locked verbatim strings. Copy-only; did not add the component×state×theme×viewport matrix or touch the ratchet/baseline (D-13 Phase-116 boundary respected).
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Verification:** `grep -rqF "There was a problem loading" lib/` now returns nothing; full admin test suite for affected files green.
- **Commit:** 678bba5c

**2. [Rule 1 - Consistency] Aligned inbound `:no_tenant` select-a-tenant body to locked copy**
- **Found during:** Task 2.
- **Issue:** `records_list.ex` `:no_tenant` branch (inline + `empty_body/1`) used lowercase "deliveries", diverging from the locked select-a-tenant string (capital-D "Deliveries").
- **Fix:** Capitalized to match the locked verbatim copy in two places.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`
- **Commit:** b3ff46f8 (folded into Task 2)

**Total deviations:** 2 auto-fixed (2 Rule 1 consistency). **Impact:** copy-only; brings every surface and the gallery specimen onto the single locked FLOW-04 copy source, no behavior change.

## Known Stubs

None. The `:permission_denied`/`:stale` states remain render-only (no live trigger) by explicit plan design (D-05) — the live triggers and real `{HH:MM}`/refresh wiring are deferred to Phase 116/product. The illustrative `14:32` timestamp and inert recovery shape are the locked, intentional placeholders, not accidental stubs.

## Verification Results

- `mix compile --warnings-as-errors` (mailglass_admin) — **PASS** (clean).
- `mix test test/mailglass_admin/voice_test.exs` — **PASS** (16 tests, 0 failures, 1 excluded `@tag :skip`).
- `mix test test/mailglass_admin/voice_test.exs test/mailglass_admin/components_test.exs` — **PASS** (106 tests, 0 failures).
- `mix test test/mailglass_admin/mount_path_test.exs test/mailglass_admin/group_nesting_test.exs` — **PASS** (12 tests, 0 failures).
- All 8 locked verbatim strings present via `grep -F`; generic "There was a problem loading" offender absent from `lib/`.
- Theme-picker label has no `transition-colors`.
- Pre-existing `voice_test` "noops"/phoenix.mjs false-positive: not encountered — existing `strip_scripts/1` neutralizes it; all banned-word loops green.
- mix.lock: no drift (verified before each commit; nothing to revert).

## Commits

- 97282501 — feat(115-01): replace deliveries + inbound list state copy with locked verbatim strings
- b3ff46f8 — feat(115-01): align shell tenant copy verbatim, patch 320px header, remove theme-picker transition
- 6b3ad726 — test(115-01): extend voice_test with permission/stale/tenant state cases
- 678bba5c — fix(115-01): sync gallery data_state specimens to locked FLOW-04 copy

## Next Phase Readiness

Ready for 115-02. The live `:permission_denied`/`:stale` triggers, the full gallery matrix, the axe baseline, and the 320-cell ratchet promotion remain Phase-116 work (deferred per D-04/D-05/D-13).

## Self-Check: PASSED

- SUMMARY.md created at `.planning/phases/115-pages-flows-micro-animation-microcopy/115-01-SUMMARY.md` — FOUND.
- Commits 97282501, b3ff46f8, 6b3ad726, 678bba5c — all FOUND in `git log`.
- All modified key-files exist on disk and compile clean.
