---
milestone: v1.13
artifact: bucket-a-ledger
source_of_truth: false
mirror_of: mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs
created: 2026-06-20
stable_ids: true
---

# BUCKET-A-LEDGER — v1.13 Usability Defect Closure Mirror

> **This file is a HUMAN-READABLE MIRROR, never the source of truth.**
>
> The source of truth is the executable, fail-closed manifest
> `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs`. That test
> ASSERTS each cited guard literal physically exists (gate name in
> `check-conformance.sh`; test title in `e2e/structural.spec.js`; axe reference;
> persona literal) and FAILS CLOSED on a stale citation (RESEARCH Pitfall 4). If
> this mirror and the manifest ever disagree, the manifest wins — update this file.
>
> Stable-ID / never-delete contract (mirrors `.planning/RATCHET-GAP-REGISTER.md`):
> every A-NN row is permanent. A regression DOWNGRADES a row's status; the row is
> never removed.

## The 24 Bucket-A Defects — Guard Coverage

`~18` of the 24 cite an EXISTING green guard from phases 109–115; **6 are net-new**
in plan 116-05 (A3, A4/A23, A16-system, A21, A22, A11). All ship `live` at the
Phase-116 baseline.

| A-NN | Defect | Guard kind | Cited guard literal | Status |
|------|--------|-----------|---------------------|--------|
| A1  | Modal/drawer behind the scrim | grep_gate | `Z-INDEX-GATE` | live |
| A1 (runtime) | Panel is top hit-test target above scrim | playwright_title | `panel above scrim — deliveries replay dialog` | live |
| A2  | Scroll bugs / nested-scroll traps | playwright_title | `scroll-chaining contained — deliveries replay dialog` | live |
| **A3** | Hover on non-interactive empty state | playwright_title | `Bucket-A A3: hover affordance only on interactive elements (no-data empty state)` | live (net-new) |
| **A4** | Floating element overlap of primary CTA | playwright_title | `Bucket-A A4/A23: floating elements do not overlap a primary CTA outside the overlay` | live (net-new) |
| A5  | Misaligned elements | playwright_title | `direct-sibling left-edge alignment, padding-floor, and no overflow at 320/1280` | live |
| A6  | Awkward padding / content chopped off | playwright_title | `overflow: list containers do not exceed their parent aside width at 320px and 768px (DATA-05)` | live |
| A7  | Inconsistent / off-grid spacing | grep_gate | `SPACE-GATE` | live |
| A8  | Elements flush inside containers | playwright_title | `direct-sibling left-edge alignment, padding-floor, and no overflow at 320/1280` | live |
| A9  | Cards nested in cards (box prison) | grep_gate | `GROUP-GATE` | live |
| A10 | Squished / unreadable table columns | playwright_title | `responsive: operator-deliveries-table visible at 768px; operator-deliveries-cards visible at 390px (DATA-01)` | live |
| **A11** | Table overuse | grep_gate | `TABLE-OVERUSE-GATE` (floor = 3) | live (net-new) |
| A12 | Inconsistent stat-card design | grep_gate | `STATCARD-GATE` | live |
| A13 | Disabled looks enabled / vice-versa | playwright_title | `interactive primitive hover, focus, disabled, and target-size contracts hold` | live |
| A14 | Weird focus / hover states | playwright_title | `visible focus rings` | live |
| A15 | Unreadable button text | playwright_title | `Inbound: WCAG AA contrast matrix covers light/dark themes at 390/768/1440` | live |
| A16 | Poor dark-mode contrast | playwright_title | `Preview: WCAG AA contrast matrix covers light/dark themes at 390/768/1440` | live |
| **A16-system** | System theme dark parity | playwright_title | `Bucket-A A16-system: system theme contrast parity with explicit dark` | live (net-new) |
| A16 (axe) | WCAG 2.2 AA axe baseline (system ≤ dark) | axe | `axe-baseline.json` (+ comparator + producer) | live |
| A17 | No system/light/dark picker | playwright_title | `theme_picker keeps native three-radio semantics without pressed-button state` | live |
| A18 | Tabs not showing selected state | playwright_title | `aria-selected=true set on clicked row in both table (desktop) and card (mobile) presentations (DATA-04)` | live |
| A19 | Weird pagination when nothing to paginate | playwright_title | `sole tenant canonicalizes, …, and pagination boundaries are honest` | live |
| A20 | Icons that don't semantically read | grep_gate | `ICON-EXISTS-GATE` | live |
| **A21** | Loading states that jump layout (CLS) | playwright_title | `Bucket-A A21: loading-state CLS height delta within threshold` | live (net-new) |
| A21 (pillar) | layout-jump/CLS within threshold (116-03) | playwright_title | `layout-jump/CLS within threshold — deliveries list region` | live |
| **A22** | Skeleton overuse on synchronous surfaces | playwright_title | `Bucket-A A22: synchronous inbound mount renders no skeleton` | live (net-new) |
| **A23** | Toasts obscuring controls (shares A4 guard) | playwright_title | `Bucket-A A4/A23: floating elements do not overlap a primary CTA outside the overlay` | live (net-new) |
| A24 | Bare "—"/"___" placeholder cards | grep_gate | `do: "—"` (STATCARD-GATE bans the bare em-dash) | live |
| B-A1 | Focus not restored to trigger on close | playwright_title | `focus restore to trigger — deliveries replay modal` | live |

## A11 Table Inventory (TABLE-OVERUSE-GATE floor = 3)

Each of the 3 genuinely-tabular `<table>` elements has a justification row in the
manifest (`bucket_a_coverage_test.exs`):

| Table | File | Justification |
|-------|------|---------------|
| Deliveries list | `operator/deliveries_list.ex` | multi-column delivery list — tabular |
| Inbound records list | `inbound/records_list.ex` | multi-column inbound record list — tabular |
| Preview headers | `preview/tabs.ex` | rendered-headers key/value comparison — tabular |

A 4th `<table>` (or any layout-device misuse) trips `TABLE-OVERUSE-GATE` and must
add a justification row + bump `TABLE_FLOOR`, or use cards/lists.

## Downgrades

None at the Phase-116 baseline. All 24 defects ship `live`. A future regression
downgrades the affected row's `status` here AND in the manifest — the row is never
deleted (stable-ID contract).
