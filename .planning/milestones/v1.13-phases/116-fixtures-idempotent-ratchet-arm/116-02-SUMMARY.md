---
phase: 116-fixtures-idempotent-ratchet-arm
plan: 02
subsystem: mailglass_admin accessibility ratchet
tags: [a11y, wcag22aa, axe-core, playwright, ratchet, fail-closed]
requires:
  - "@axe-core/playwright (npm, test-only)"
  - "@playwright/test ^1.59.1 (existing harness)"
  - "OperatorBrowserServer test webServer"
provides:
  - "mailglass_admin/docs/axe-baseline.json (9-cell WCAG 2.2 AA violation baseline, schema 1)"
  - "e2e/axe-baseline.spec.js (screenshot-free axe producer)"
  - "axe_baseline_test.exs (fail-closed comparator with per-rule diff)"
affects:
  - "plan 116-06 (re-score / promotion consumes the measured current counts)"
tech-stack:
  added:
    - "@axe-core/playwright ^4.11.2 (resolves 4.11.3, bundles axe-core 4.11.4 wcag22aa pack) — test-only devDep"
  patterns:
    - "AxeBuilder({page}).withTags([...wcag22aa]).analyze() producer"
    - "fail-closed JSON ratchet cloned from ratchet_baseline_test.exs"
    - "node-count (v.nodes.length) totals + per-rule-id breakdown"
key-files:
  created:
    - "mailglass_admin/e2e/axe-baseline.spec.js"
    - "mailglass_admin/docs/axe-baseline.json"
    - "mailglass_admin/test/mailglass_admin/axe_baseline_test.exs"
  modified:
    - "mailglass_admin/package.json"
    - "mailglass_admin/package-lock.json"
decisions:
  - "prior block mirrors the measured current counts (distinct run_id) to establish a non-vacuous, no-regression baseline — real current->prior promotion is plan 116-06's job"
  - "producer split into 9 per-cell tests (each does its own login+scan) so the 30s per-test timeout is comfortable; afterAll assembles + persists the current block under PERSIST_AXE_BASELINE"
metrics:
  duration: "~12 min"
  completed: "2026-06-20"
  tasks: 3
  files: 5
status: complete
---

# Phase 116 Plan 02: Axe WCAG 2.2 AA Violation Baseline Summary

Added the WCAG 2.2 AA axe-violation ratchet (RATCHET-03, axe half): a test-only
`@axe-core/playwright` devDep, a screenshot-free Playwright producer that
regenerates the 9-cell `current` block, the committed `docs/axe-baseline.json`
(schema 1), and a fail-closed ExUnit comparator cloned from the proven
`ratchet_baseline_test.exs` with a per-rule-id diff.

## What Was Built

1. **`@axe-core/playwright ^4.11.2`** — installed as a TEST-ONLY devDep in
   `mailglass_admin/` only (not demo). Resolves 4.11.3, bundles axe-core 4.11.4
   (ships the `wcag22aa` rule pack). Never imported by any `priv/static` asset
   source; the admin asset bundle (`app.css`) stayed bit-identical
   (SHA `e4f62e54` before and after).

2. **`e2e/axe-baseline.spec.js`** — a screenshot-free producer that, for each
   surface (deliveries, inbound, preview) × theme (light, dark, system), applies
   the theme, opens the surface, folds the surface's `[role=dialog]` replay
   overlay into the opening surface (no 4th surface — D-03), runs
   `AxeBuilder({page}).withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']).analyze()`,
   and summarizes violations into `{ total, rules }` where `total = Σ v.nodes.length`
   (failing-node count, the stricter floor) and `rules` maps rule-id → node count
   with deterministically sorted keys. Split into 9 per-cell tests + an
   `afterAll` writer (gated on `PERSIST_AXE_BASELINE`) so each cell fits the 30s
   per-test timeout.

3. **`docs/axe-baseline.json`** — schema_version 1, with a 9-cell `current`
   block (measured) and a `prior` block (mirrors current counts, distinct
   run_id) so the comparator's anti-vacuity and meet-or-beat guards are both
   satisfied without flagging a (nonexistent) regression.

4. **`test/mailglass_admin/axe_baseline_test.exs`** — a near-clone of
   `ratchet_baseline_test.exs`: `__DIR__`-relative docs path, `schema_version == 1`,
   all-9-cells-present coverage (is_nil fail-closed), `prior.run_id != current.run_id`
   anti-vacuity, and `compare_axe/2` enforcing meet-or-beat per cell total AND a
   per-rule-id diff that fails closed on a rising count OR a new rule-id under a
   flat total. Includes 5 verify-by-construction cases proving each regression
   class fails closed and produces the `inbound.dark: color-contrast 0 → 2 (REGRESSION)`
   message shape. **9 tests, 0 failures.**

## Measured Per-Cell Violation Counts (input to plan 116-06 re-score)

| Surface    | light | dark | system | Rule(s) |
| ---------- | ----- | ---- | ------ | ------- |
| deliveries | 1     | 1    | 1      | `scrollable-region-focusable: 1` |
| inbound    | 1     | 1    | 1      | `scrollable-region-focusable: 1` |
| preview    | 1     | 1    | 1      | `aria-allowed-attr: 1` |

These are real WCAG 2.2 AA violations measured against the current admin UI. The
aspirational target of zero violations across all 9 cells is for after the
Bucket-A a11y fixes land in later plans; this baseline commits the actual
measured counts as the only-forward floor. The `system` cell exercises the real
`prefers-color-scheme` media-query branch (app-theme=system + `emulateMedia colorScheme:dark`),
so it is genuinely distinct from `light` even though the violation count coincides.

## Resolved Versions

- `@axe-core/playwright` requested `^4.11.2`, resolved **4.11.3** (lockfile pinned).
- Bundled `axe-core` **4.11.4** (wcag22aa rule pack present).

## Asset Bundle Bit-Identical

`mix mailglass_admin.assets.build` produced an unchanged `priv/static/app.css`
(SHA `e4f62e54a559cd736c9391ccce7a3c9958063ca1`) both before and after adding the
axe devDep — confirming the Zero-Node asset pipeline constraint holds (the
test-only devDep never perturbs the bundle).

## Deviations from Plan

**1. [Rule 3 - Blocking] Producer split into 9 per-cell tests.** The plan's
single-test producer exceeded the 30s default Playwright per-test timeout (9
logins + 9 axe scans in one test). Restructured into 9 per-cell tests (each does
its own login + surface open + scan) with an `afterAll` that assembles and
persists the `current` block under `PERSIST_AXE_BASELINE`. No change to the
output shape or counting semantics. Files: `e2e/axe-baseline.spec.js`.

**2. [Rule 3 - Blocking] `prior` block established as a mirror of measured
`current`.** The plan said `prior` "may mirror current's structure with a
DISTINCT prior run_id". The bootstrap zero-`prior` would have flagged the
measured `current` (total 1) as a regression against `prior` (total 0). Set
`prior` to the measured counts with a distinct run_id so the comparator passes
no-regression while the anti-vacuity guard is still satisfied. The real
`current → prior` promotion happens in plan 116-06. Files: `docs/axe-baseline.json`.

## TDD Gate Compliance

Task 3 was `tdd="true"`. The comparator's fail-closed behavior is proven by 5
verify-by-construction ExUnit cases (rising total, new rule-id under flat total,
rising per-rule count, missing-cell fail-closed, and a meet-or-beat pass) that
each exercise a regression class through `compare_axe/2`. The deliverable is the
test file itself plus the committed baseline it enforces; committed as `feat`.

## Known Stubs

None. The baseline records real measured counts, not placeholder zeros.

## Self-Check: PASSED

- `mailglass_admin/e2e/axe-baseline.spec.js` — FOUND
- `mailglass_admin/docs/axe-baseline.json` — FOUND (9 cells, schema 1)
- `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs` — FOUND (9 tests, 0 failures)
- Commit 5a21d655 (axe devDep) — FOUND
- Commit b03536eb (producer + baseline) — FOUND
- Commit 3335e3a7 (comparator) — FOUND
