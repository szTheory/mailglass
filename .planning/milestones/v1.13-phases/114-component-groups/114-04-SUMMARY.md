---
phase: 114-component-groups
plan: 04
subsystem: ui
tags: [phoenix, liveview, floki, exunit, playwright, mailglass_admin, composed-groups, structural-proof]

# Dependency graph
requires:
  - phase: 114-component-groups
    provides: "Plan 114-02 — three PUBLIC composed_*/1 fns (composed_support_triage/1, composed_routing_evidence/1, composed_detail_timeline/1) + gallery-composed-* specimens + data-region instrumentation"
  - phase: 114-component-groups
    provides: "Plan 114-03 — all 8 group shells swept through <.card> carrying data-group-card; support_cards box-prison fixed to section(shadow-raised) -> bg-base-100 inset (depth 2); conformance exits 0"
provides:
  - "group_nesting_test.exs — authoritative Floki top-down ancestor-depth proof: each composed group nests <=2 elevation surfaces within its data-region (GROUP-02)"
  - "Group: describe block in structural.spec.js — direct-sibling [data-group-card] x-equality (±1px) + computed padding-floor (no flush) + no-overflow at 320/1280 (GROUP-01/GROUP-03)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Floki ancestor-depth: recurse top-down over {tag, attrs, children}; count a node ONCE for ANY of bg-base-200|bg-base-100|shadow-raised (no Floki.parent — absent in 0.38.4, Pitfall 3)"
    - "Playwright composed-specimen geometry: scope to the cell's light theme wrapper then :scope > [data-region] > [data-group-card] (DIRECT siblings only — never a descendant sweep, D-08)"
    - "Gallery tri-column flex collapses each cell to ~56px at 320px; self-relative overflow there is a layout artifact — assert no descendant exceeds the VIEWPORT at narrow widths instead, standard self-relative check at 1280"

key-files:
  created:
    - "mailglass_admin/test/mailglass_admin/group_nesting_test.exs"
  modified:
    - "mailglass_admin/e2e/structural.spec.js"

key-decisions:
  - "Scoped the Playwright group geometry to each cell's data-theme=mailglass-light wrapper because the gallery renders every composed specimen three times (light/dark/system), making the inner gallery-composed-* testid non-unique on the page (strict-mode violation otherwise)."
  - "Narrow-width (<=768) overflow leg asserts no group descendant exceeds the viewport rather than the self-relative scrollWidth-clientWidth check: the gallery's three-column flex-wrap collapses each cell to ~56px at 320px, so self-relative overflow measures the gallery chrome, not the group (the live-page DATA-05 overflow test owns the real 320px contract on full-width operator/inbound pages)."
  - "Padding-floor pinned to --spacing-md (16px), the minimum padding any group shell uses (support_cards p-md; the other seven p-lg) — proves no flush-to-container edge without over-fitting to p-lg."

requirements-completed: [GROUP-01, GROUP-02, GROUP-03]

# Metrics
duration: ~5 min
completed: 2026-06-20
status: complete
---

# Phase 114 Plan 04: Render-Time Group Proofs (Floki depth + Playwright geometry) Summary

**Authored the two authoritative render-time proofs against the composed-group specimens: a Floki top-down ancestor-depth ExUnit test proving box-nesting <=2 within each data-region (GROUP-02), and a Playwright `Group:` block proving direct-sibling left-edge x-equality, computed padding-floor (no flush), and no horizontal overflow at 320/1280 (GROUP-01/GROUP-03) — all on the locked Phase 113 substrate, zero new dependency, zero-Node.**

## Performance
- **Duration:** ~5 min
- **Started:** 2026-06-20T13:42Z
- **Completed:** 2026-06-20T13:47Z
- **Tasks:** 2
- **Files created:** 1 · **Files modified:** 1

## Accomplishments
- **Task 1 (Floki depth, GROUP-02):** `group_nesting_test.exs` captures the three PUBLIC `composed_*/1` fns (plan 02) via `render_component` and asserts `max_elevation_depth(html) <= 2`. `max_elevation_depth/1` parses with `Floki.parse_fragment/1`, finds each `[data-region]`, then recurses `deepest_chain/1` TOP-DOWN over `{tag, attrs, children}` — incrementing once per node that carries ANY of `@elevation_classes ~w(bg-base-200 bg-base-100 shadow-raised)`. No `Floki.parent` (absent in 0.38.4, Pitfall 3). This is the depth authority; the GROUP-GATE grep (plan 01) is only a tripwire.
- **Task 2 (Playwright geometry, GROUP-01/03):** a `Group:` describe block in `structural.spec.js` drives all three composed specimens at 320 and 1280. For each it (1) locates group cards via `:scope > [data-region] > [data-group-card]` DIRECT siblings, asserts `count > 1` and `Math.round(box.x)` equality (±1px); (2) asserts computed left/right padding `>= 16px` (`--spacing-md` floor → no flush-to-edge); (3) asserts no horizontal overflow (no descendant wider than the viewport at narrow widths; self-relative at 1280). Measurement runs only after the gallery heading is visible (flake containment).

## Task Commits
1. **Task 1: Floki ancestor-depth proof** — `9c707736` (test)
2. **Task 2: Playwright Group geometry block** — `78001940` (test)

## Verification
- `mix test test/mailglass_admin/group_nesting_test.exs` → 3 tests, 0 failures (depth <=2 for all three composed groups).
- `npx playwright test --config=playwright.config.cjs e2e/structural.spec.js -g "Group"` → 4 passed (the 3 new composed-group geometry tests + the pre-existing "5 badge groups" test that also matches `-g "Group"`).
- `mix compile --warnings-as-errors` → clean (unused `import Phoenix.Component` removed from the Floki test before commit).
- `git status` after both commits: only `group_nesting_test.exs` + `structural.spec.js` touched. No `priv/static` bundle change (no CSS added — bundle `git diff` clean), no `mix.lock` drift, no `reference/` change.

## Decisions Made
- **Light-theme-wrapper scoping (Playwright):** the gallery renders every composed specimen three times (light/dark/system), so `getByTestId("gallery-composed-detail-timeline")` matched 3 elements (strict-mode violation). Scoped each measurement to the cell's `[data-theme="mailglass-light"]` wrapper to address a single instance, mirroring the existing `primitiveWrapper` theme-scoping idiom.
- **Narrow-width overflow contract:** the gallery's three-column `flex-wrap` collapses each specimen cell to ~56px usable width at 320px (probed: region clientWidth 56, intrinsic min-content ~211, no descendant > 320). Self-relative `scrollWidth - clientWidth` there measures the gallery layout, not the group. So at `<=768` the test asserts no group descendant exceeds the VIEWPORT (the genuine "no horizontal scrollbar" contract); the standard self-relative `assertNoElementHorizontalOverflow` runs at 1280. This matches the existing Phase 113 gallery-overflow note (320px gallery overflow is a documented layout artifact; the live-page DATA-05 test owns the real 320px contract).
- **Padding floor = `--spacing-md` (16px):** the minimum padding any group shell uses (`support_cards` `p-md`; the other seven `p-lg`), so the floor proves no flush-to-edge for every group without over-fitting to `p-lg`.

## Deviations from Plan

### Deviation 1: narrow-width overflow assertion form (Rule 1 — false-positive containment)
- **Found during:** Task 2
- **Issue:** The plan's `assertNoElementHorizontalOverflow(region, ...)` at 320 reported 155px overflow for the detail-timeline. Root cause: the gallery's tri-column flex layout collapses each specimen cell to ~56px at 320px, so the group's natural min-content (~211px) overflows the artificial gallery column — a layout artifact, not a group defect (no descendant exceeds the 320px viewport; the live-page DATA-05 test already proves the real 320px contract on full-width operator/inbound pages).
- **Fix:** At `<=768` the overflow leg asserts no group descendant is wider than the viewport (the genuine no-horizontal-scrollbar contract); the unchanged self-relative `assertNoElementHorizontalOverflow` runs at 1280. Honors the plan intent ("no horizontal overflow at 320 or 1280 for the composed groups") while measuring the group rather than the gallery chrome.
- **Verification:** `npx playwright test ... -g "Group"` → 4 passed.
- **Committed in:** `78001940`

### Deviation 2: scope to light theme wrapper (Rule 3 — blocking, strict-mode)
- **Found during:** Task 2
- **Issue:** The inner `gallery-composed-*` testid is rendered once per theme wrapper (light/dark/system), so `getByTestId` matched 3 elements and tripped Playwright strict mode.
- **Fix:** Scoped each measurement to the cell's `[data-theme="mailglass-light"]` wrapper (mirrors the existing `primitiveWrapper` idiom) before resolving the inner composed testid.
- **Verification:** spec resolves a single region per specimen; all legs pass.
- **Committed in:** `78001940`

**Total deviations:** 2 (1 overflow-form containment, 1 strict-mode scoping). No scope creep — only the new Floki test + the `structural.spec.js` `Group:` block touched (D-12 scope fence held; no production code, nav/auth/preview, or lists changed).

## Issues Encountered
- None beyond the two deviations above. No `render_component`-in-`mix run` macro limitation hit here (the Floki proof runs inside ExUnit where the macro resolves correctly, exactly as plan 02 predicted).

## User Setup Required
None — no external service configuration. Playwright's `webServer` auto-starts the test endpoint; no CSS bundle rebuild required (no styles added).

## Next Phase Readiness
- Phase 114 is complete: thin `<.card>` primitive + conformance gates (01), composed-group specimens + data-region (02), group-surface sweep + box-prison fix (03), and the two authoritative render-time proofs (04). GROUP-01/02/03 all proven in the fast `mix test` lane (Floki depth) + the Playwright structural lane (geometry).

## Self-Check: PASSED
- `mailglass_admin/test/mailglass_admin/group_nesting_test.exs` exists — FOUND.
- `mailglass_admin/e2e/structural.spec.js` modified (Group: block present) — FOUND.
- Commit `9c707736` (Floki test) — present in git log.
- Commit `78001940` (Playwright Group block) — present in git log.
- `mix test test/mailglass_admin/group_nesting_test.exs` → 3 tests, 0 failures.
- `npx playwright test ... -g "Group"` → 4 passed.
- `mix compile --warnings-as-errors` → clean.

---
*Phase: 114-component-groups*
*Completed: 2026-06-20*
