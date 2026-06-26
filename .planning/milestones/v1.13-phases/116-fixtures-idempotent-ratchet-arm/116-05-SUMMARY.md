---
phase: 116-fixtures-idempotent-ratchet-arm
plan: 05
subsystem: mailglass_admin
status: complete
tags: [ratchet, bucket-a, usability-defects, playwright, conformance-gate, fail-closed-manifest, accountability-ledger]
requires:
  - "Phase 116-01 persona cohort (helios-void no-data surface; the browser-server-reachable no-data render is the shared empty-state path)"
  - "Phase 116-02 axe WCAG 2.2 AA baseline (axe-baseline.json + comparator + producer — backs the A16-system parity citation)"
  - "Phase 116-03 interaction pillar (CLS_THRESHOLD_PX, panel-above-scrim / scroll-chaining / focus-restore / layout-jump test titles, the A22 synchronous-mount precedent)"
provides:
  - "5 net-new Bucket-A Playwright guards in structural.spec.js (A3, A4/A23, A16-system, A21, A22) with stable, citeable test titles"
  - "A11 TABLE-OVERUSE-GATE in check-conformance.sh (count-must-not-increase floor = 3)"
  - "bucket_a_coverage_test.exs — executable, fail-closed manifest mapping all 24 defects A1..A24 -> {guard_kind, locator, status}, asserting each cited literal physically exists"
  - "BUCKET-A-LEDGER.md — human-readable mirror (marked NOT the source of truth)"
affects:
  - "Plan 116-06 (phase gate accounts for the 24-defect closure; no Bucket-A defect's SOLE guard lives in the 116-04 gallery matrix, so 116-05 stayed Wave 2 parallel to 116-04)"
tech-stack:
  added: []
  patterns:
    - "Executable fail-closed citation manifest: a test ASSERTS each cited guard literal physically exists in its file; a renamed/deleted guard fails the manifest (defeats silent ledger drift)"
    - "Count-must-not-increase grep inventory gate with comment-hygiene (match `<table` + whitespace excludes backtick @moduledoc `<table>` prose)"
    - "Binary/structural Playwright guards (elementFromPoint / getBoundingClientRect / computed style) — no screenshots, no pixel diff"
key-files:
  created:
    - "mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs"
    - ".planning/research/v1.13/BUCKET-A-LEDGER.md"
  modified:
    - "mailglass_admin/e2e/structural.spec.js"
    - "mailglass_admin/scripts/check-conformance.sh"
decisions:
  - "A11 table-count floor = 3 (deliveries_list.ex, records_list.ex, preview/tabs.ex — all genuinely tabular). The 2 other `<table>` grep hits are @moduledoc prose (backtick `<table>`); the gate matches `<table` + whitespace so doc text cannot inflate the count."
  - "A3 no-data surface is the browser-server-reachable shared empty-state render (tenant browser-empty). The helios-void persona resolves to the SAME empty-state path (UI-SPEC: tenant context is URL/session, copy is shared); the persona cohort is only in TestRepo, not the live OperatorBrowserServer."
  - "A16-system asserted as a Playwright-direct contrast-parity guard (system+colorScheme:dark holds the same AA contrast as explicit dark) — the live server can assert contrast directly, mirroring the axe system<=dark invariant (116-02) without reading the axe JSON at runtime."
  - "A21 cross-cites the 116-03 pillar CLS gate (CLS_THRESHOLD_PX) on a different settled region (inbound-overview) rather than duplicating the measurement; both the net-new A21 title and the 116-03 pillar title are cited in the manifest."
  - "Manifest carries cross-cite rows (A1b runtime, A16-system, A16-axe, A21b pillar, B-A1) beyond the canonical 24; the coverage assertion normalizes suffixes back to canonical A1..A24 and drops the bonus B-A1 row."
metrics:
  duration: "~7 min"
  completed: 2026-06-20
  tasks: 3
  files: 4
---

# Phase 116 Plan 05: Bucket-A Usability Defect Closure (RATCHET-05) Summary

Closed all 24 enumerated Bucket-A usability defects (A1..A24) as an **audit
(verify-and-lock)**, not author-all-24: ~18 cite an existing green guard from
phases 109–115; **6 are net-new** (A3, A4/A23, A16-system, A21, A22, A11). The
durable artifact is an **executable, fail-closed manifest** that asserts each
cited guard literal physically exists — a renamed/deleted guard fails the manifest
rather than passing vacuously. "All 24 closed" is now CI-checkable, not a prose claim.

## What Was Built

### Task 1 — 5 net-new Playwright guards (`structural.spec.js`, commit `81b088c8`)

A new `test.describe("Bucket-A net-new guards — A3 A4/A23 A16-system A21 A22")` block,
each with a **stable, citeable test title** (the manifest asserts these literals exist):

- **A3** — on the no-data empty-state surface, every element carrying a hover-derived CSS
  transition must be interactive (`a/button/[role=button]/[phx-click]/[tabindex]`); decorative
  empty-state elements must NOT have hover transitions (false-affordance ban).
- **A4 / A23** — for the open replay overlay, assert its rect does not intersect any visible
  `btn-primary` rect that lives OUTSIDE the overlay (a CTA inside the overlay is allowed).
- **A16-system** — system theme (`prefers-color-scheme:dark`, no `?theme=`) holds the same AA
  text contrast as explicit dark on the inbound overview (Playwright mirror of axe `system ≤ dark`).
- **A21** — inbound-overview region height loading-vs-settled delta ≤ `CLS_THRESHOLD_PX` (4px),
  measured at networkidle + animation-settle (cross-cites the 116-03 pillar CLS gate).
- **A22** — synchronous inbound mount renders zero `.mg-skeleton` in the settled DOM.

**Result: 5 passed** (`npm run test:operator-browser -- --grep "Bucket-A A3|A4|A16|A21|A22"`).
Bundle bit-clean (`priv/static/` unchanged after the test:operator-browser prebuild).

### Task 2 — A11 TABLE-OVERUSE-GATE (`check-conformance.sh`, commit `89d62d9a`)

A named `TABLE-OVERUSE-GATE` counting `<table>` element-open tags in `lib/` and failing if the
count rises above **`TABLE_FLOOR=3`**. The match pattern `<table` + whitespace catches the 3
genuinely-tabular element-open tags and **excludes the backtick `@moduledoc` `<table>` prose**
(comment-hygiene: header/doc text cannot inflate the count; never a bare `==0` on an unfiltered
file). Negative-tested: injecting a 4th `<table` trips the gate; full script still exits 0.

### Task 3 — Executable manifest + human ledger (`bucket_a_coverage_test.exs` + `BUCKET-A-LEDGER.md`, commit `2e70e63f`)

`bucket_a_coverage_test.exs` (9 tests) enumerates all 24 defects with their guard mapping and
**asserts each cited literal physically exists** by reading the cited file:

- `:grep_gate` → gate name present in `check-conformance.sh`
- `:playwright_title` → test-title literal present in `e2e/structural.spec.js`
- `:axe` → `axe-baseline.json` + comparator + producer exist; axe ref present in `axe_baseline_test.exs`
- `:fixture` → persona literal present in `personas.ex`

A stale citation **fails closed** — verified by a negative scenario (breaking the A20
`ICON-EXISTS-GATE` citation to a nonexistent literal produced the exact `STALE CITATION (A20)`
failure; reverting restored 9/0). `BUCKET-A-LEDGER.md` mirrors the 24 rows, clearly marked
NOT the source of truth.

## Final A-NN → Guard Map

~18 cite existing green guards (phases 109–115); **6 net-new** (bold):

| A-NN | Guard | Kind |
|------|-------|------|
| A1 | `Z-INDEX-GATE` + `panel above scrim — deliveries replay dialog` | gate + title |
| A2 | `scroll-chaining contained — deliveries replay dialog` | title |
| **A3** | `Bucket-A A3: hover affordance only on interactive elements (no-data empty state)` | title (net-new) |
| **A4/A23** | `Bucket-A A4/A23: floating elements do not overlap a primary CTA outside the overlay` | title (net-new) |
| A5 / A8 | `direct-sibling left-edge alignment, padding-floor, and no overflow at 320/1280` | title |
| A6 | `overflow: list containers do not exceed their parent aside width … (DATA-05)` | title |
| A7 | `SPACE-GATE` | gate |
| A9 | `GROUP-GATE` | gate |
| A10 | `responsive: operator-deliveries-table … cards visible at 390px (DATA-01)` | title |
| **A11** | `TABLE-OVERUSE-GATE` (floor 3) | gate (net-new) |
| A12 | `STATCARD-GATE` | gate |
| A13 | `interactive primitive hover, focus, disabled, and target-size contracts hold` | title |
| A14 | `visible focus rings` | title |
| A15 | `Inbound: WCAG AA contrast matrix …` | title |
| A16 | `Preview: WCAG AA contrast matrix …` | title |
| **A16-system** | `Bucket-A A16-system: system theme contrast parity with explicit dark` + axe `axe-baseline.json` | title (net-new) + axe |
| A17 | `theme_picker keeps native three-radio semantics …` | title |
| A18 | `aria-selected=true set on clicked row in both table (desktop) and card (mobile) … (DATA-04)` | title |
| A19 | `sole tenant canonicalizes, …, and pagination boundaries are honest` | title |
| A20 | `ICON-EXISTS-GATE` | gate |
| **A21** | `Bucket-A A21: loading-state CLS height delta within threshold` + pillar `layout-jump/CLS within threshold — deliveries list region` | title (net-new) |
| **A22** | `Bucket-A A22: synchronous inbound mount renders no skeleton` | title (net-new) |
| A24 | `do: "—"` (STATCARD-GATE bans the bare em-dash) | gate |
| B-A1 | `focus restore to trigger — deliveries replay modal` | title |

## Table-Count Floor

**`TABLE_FLOOR = 3`** — the genuinely-tabular tables: `operator/deliveries_list.ex`,
`inbound/records_list.ex`, `preview/tabs.ex`. Each has a per-table justification row in the manifest.

## Downgraded Guards

**None.** All 24 defects ship `status: :live` at the Phase-116 baseline. No row is downgraded,
so plan 116-06's phase gate accounts for a full 24/24 live closure.

## Deviations from Plan

**None — plan executed as written.** Two reachability adjustments stayed within the plan's
authorized `read_first` guidance (not deviations):

- A3's "helios-void no-data fixture (direct URL)" is realized via the browser-server-reachable
  shared empty-state path (tenant `browser-empty`) — the helios-void persona is TestRepo-only and
  not in the live `OperatorBrowserServer`; the UI-SPEC explicitly states the empty-state copy/path
  is shared and tenant context comes from the URL/session. The guard still runs on a real no-data render.
- A16-system was asserted as a Playwright-direct contrast-parity guard (the live server measures
  contrast directly) plus an `:axe` manifest citation of the 116-02 baseline — both the structural
  guard and the axe ratchet back the system≤dark claim, exactly as the UI-SPEC describes.

## Threat Surface

No new network endpoints, auth paths, file access, or schema changes — test-only + gate-script
additions. T-116-10 (stale Bucket-A citation) is now mitigated: the manifest fails closed on any
renamed/deleted guard literal. T-116-11 (table-count tamper) is mitigated: the A11 gate bakes a
count floor and filters comment/doc prose so header text cannot self-invalidate the inventory.

## Known Stubs

None. Every guard runs against live admin surfaces (real persona-cohort / browser-scenario data)
or asserts a real gate/JSON artifact.

## Self-Check: PASSED

- `mailglass_admin/e2e/structural.spec.js` — FOUND (modified, +173 lines, 5 guards pass)
- `mailglass_admin/scripts/check-conformance.sh` — FOUND (modified, TABLE-OVERUSE-GATE; full script exits 0)
- `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs` — FOUND (9 tests, 0 failures; fail-closed verified)
- `.planning/research/v1.13/BUCKET-A-LEDGER.md` — FOUND
- Commits `81b088c8`, `89d62d9a`, `2e70e63f` — FOUND in git log
