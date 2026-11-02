# Phase 177 Health composition comparison (OUTUX-06, D-15)

Measured 2026-10-28 by plan 177-08 Task 2 against the production Health markup from plan 177-04, on LiveView 1.2.13 in Chromium.

Winner: A

## Protocol

- Candidates (exactly two). **A** is the shipped plan-177-04 composition: one left-aligned 42rem column (`.operator-health-column { max-width: 42rem }` inside the `.operator-health-layout` size container) with Recent activity below a hairline. **B** is A below a 56rem container; at or above it, `.operator-health-column` becomes `grid-template-columns: minmax(0, 42rem) 16rem` with `gap-xl` (`var(--spacing-xl)`), `justify-content: start`; the 42rem cap is lifted; observation and status stay in column 1; Recent activity becomes a content-sized aside in column 2, row 2 (top-aligned with the verdict, `bg-base-200 rounded-box p-md`, no hairline), and its inner Outbound/Inbound pair is forced to a column inside the 16rem aside.
- Viewports (seven): 320, 375, 390, 768, 1024, 1280, 1440. Themes: light and dark at **every** viewport. Scenarios (nine, UI-SPEC section A fixed set). That is 2 candidates x 9 scenarios x 7 viewports x 2 themes = 252 measurements, each followed by an AxeBuilder scan.
- Gates (any failure eliminates a candidate): G1 `scrollWidth - clientWidth <= 1` on the document; G2 DOM order equals visual order for observation, verdict, each issue, notices, activity (`compareDocumentPosition` agrees with bounding boxes; the next element must start below the previous one or in a later column); G3 period, timestamp and Refresh share one `[role=group]` ancestor, timestamp-to-Refresh gap <= 16px on a shared line or <= 8px vertically when wrapped; G4 every link and button in `operator-overview-health` >= 44px tall, except `.mg-field-help` triggers which must be >= 24x24; G5 the `{testid, count, href}` fingerprint (issue rows plus both activity links) is identical across candidates, widths and themes; G6 verdict text present and every row of a stale panel carries "Not refreshed" text plus the stale notice; G7 AxeBuilder (wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa) reports 0 violations inside `[data-testid="operator-overview-health"]`, after asserting the include selector matched at least one element, with the incomplete count recorded separately.
- Tie-breakers, in order: (1) scan path = observation top to last issue bottom (the verdict bottom when there are no issues), lower wins; (2) row slack = issue row width minus its content width, lower wins; (3) activity subordination = activity heading font-size below the verdict's, activity count font-size at most the issue count's, and activity top at or below the last issue bottom (A) or at or below the verdict top (B); (4) fewer layout rules and breakpoints (counted from the live stylesheets: production `.operator-health-*` layout rules plus the distinct `@[..]` container-query variants used in the Health region, plus B's injected rules and breakpoint blocks).
- Decision rule (D-15): a candidate failing any gate is eliminated; between survivors the first tie-breaker that differs decides; if all four tie and the residual choice is purely visual, the result is `owner-visual-tie`.

## Method versus D-15

D-15 asks for "a temporary story/spike". This run's realisation is a **real-route spike**: the production Health markup on the real operator route (`/ops/mail?tenant_id=...`), with candidate B injected as a `<style>` element (the effect of `page.addStyleTag`, inserted through `page.evaluate` so it can be removed between the A and B measurements of the same page; A gets none). The spike spec (`e2e/phase177-health-comparison.spec.js`) was temporary and was deleted before the task commit; it is not in git history. Using the real route means the container widths include the real 15rem sidebar and main padding, and the run does not depend on the unverified demo boot (A4).

D-15's container widths 288/358/480/736/1150 are produced by the viewports 320/390/768/1024/1440, plus 1280 for the real main width and 375 (container 343) so the REQUIREMENTS landmark set 320/375/768/1280/1440 is covered. The measured container widths are listed below, not assumed. Theme: light and dark were both measured at all seven viewports in the same loop (no dark narrowing; a superset of the UI-SPEC minimum "dark at 358 and 1152").

## Scenarios and widths

| scenario label | how it was produced | verdict observed |
|---|---|---|
| all-eight | `/ops/browser-reset?scenario=phase177-health-all` | Needs attention, 8 rows (counts 1..8) |
| one-issue | all-eight, every issue `li` except the first removed from the DOM before measuring (geometry only) | Needs attention, 1 row |
| none-active | `?scenario=accounts`, then `/ops/mail?tenant_id=northstar` (one delivered Delivery) | No issues found, 0 rows |
| default | `/ops/browser-reset` | Needs attention, 3 rows |
| stale-partial | `?scenario=phase169-health-partial`, `orphan_backlog` read fault armed, Refresh clicked | Needs attention, 2 rows, orphan row "Not refreshed", stale notice present |
| empty | `?scenario=accounts`, then `/ops/mail?tenant_id=helios-void` (the persona with zero Deliveries). `phase169-support-empty` was not used: this persona yields the exact verdict "No mail activity in this period" with no setup. | No mail activity in this period, 0 rows |
| unavailable | default seed; open Deliveries, arm a one-shot `failed_ingest` reader fault, then navigate to Health so the first Health read of that LiveView fails | notice `operator-health-unavailable-failed_ingest` present; Needs attention from the panels that did load |
| long-count | all-eight with every count cell rewritten to "123,456" in the DOM (geometry only) | Needs attention, 8 rows |
| fjordline-long-unicode | `?scenario=accounts`, then `/ops/mail?tenant_id=fjordline-aps` (long Unicode Account label in the scope-group header; G1 is measured on the whole document) | No issues found, 0 rows |

Measured container widths (width of `[data-testid="operator-health-layout"]`; identical in light and dark and in every scenario) and column widths:

| viewport | container px (measured) | A column px | B column px |
|---|---|---|---|
| 320 | 288 | 288 | 288 |
| 375 | 343 | 343 | 343 |
| 390 | 358 | 358 | 358 |
| 768 | 480 | 480 | 480 |
| 1024 | 736 | 672 | 672 |
| 1280 | 992 | 672 | 992 |
| 1440 | 1152 | 672 | 1152 |

The real Health container width at viewport 768 is **480 px** (measured, not predicted). B's grid only engages at containers of 56rem (896px) or more, that is viewports 1280 (992) and 1440 (1152) here; at 1024 the container is 736 and B renders identically to A. B's first grid track is `minmax(0, 42rem)`, so the column is the full 992 / 1152 px box (the grid) with its first track at most 672px.

## Gate results A

A passes G1-G7 in all 126 measurements (0 failures).

| candidate | scenario | viewport | theme | container px | column px | G1 overflow px | G2 order | G3 gap px (mode) | G4 small/targets+help | G5 | G6 | G7 violations/incomplete |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A | all-eight | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | all-eight | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | one-issue | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | one-issue | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| A | none-active | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | none-active | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | default | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | default | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | stale-partial | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| A | empty | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | empty | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | unavailable | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | unavailable | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| A | long-count | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | long-count | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 1280 | light | 992 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 1440 | light | 1152 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 1280 | dark | 992 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| A | fjordline-long-unicode | 1440 | dark | 1152 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |

## Gate results B

B passes G1-G7 in all 126 measurements (0 failures).

| candidate | scenario | viewport | theme | container px | column px | G1 overflow px | G2 order | G3 gap px (mode) | G4 small/targets+help | G5 | G6 | G7 violations/incomplete |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B | all-eight | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | all-eight | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | one-issue | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | one-issue | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/4+5 pass | pass | pass | 0/1 pass |
| B | none-active | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | none-active | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | default | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | default | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | stale-partial | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/5+7 pass | pass | pass | 0/1 pass |
| B | empty | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | empty | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | unavailable | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | unavailable | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/6+7 pass | pass | pass | 0/1 pass |
| B | long-count | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | long-count | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/11+12 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 320 | light | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 375 | light | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 390 | light | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 768 | light | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 1024 | light | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 1280 | light | 992 | 992 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 1440 | light | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 320 | dark | 288 | 288 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 375 | dark | 343 | 343 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 390 | dark | 358 | 358 | 0 pass | pass | wrap 4 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 768 | dark | 480 | 480 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 1024 | dark | 736 | 672 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 1280 | dark | 992 | 992 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |
| B | fjordline-long-unicode | 1440 | dark | 1152 | 1152 | 0 pass | pass | line 8 pass | 0/3+4 pass | pass | pass | 0/1 pass |

G5 detail: the normalised fingerprint (UUIDs in webhook and event ids replaced by `<uuid>`, because each reset mints new ids) has exactly one value per scenario across both candidates, all seven widths and both themes:

| scenario | distinct fingerprints | measurements | fingerprint sha1 (12) |
|---|---|---|---|
| all-eight | 1 | 28 | 2304bd5ca2b7 |
| one-issue | 1 | 28 | 8d9f80cf56c0 |
| none-active | 1 | 28 | 68d5d4ac634d |
| default | 1 | 28 | 9cd17b8d0a2d |
| stale-partial | 1 | 28 | 8c52cfd21db1 |
| empty | 1 | 28 | 0d25ff6b68b8 |
| unavailable | 1 | 28 | 9cd17b8d0a2d |
| long-count | 1 | 28 | 342e3f68ac7c |
| fjordline-long-unicode | 1 | 28 | 5d762925b0fe |

The all-eight fingerprint holds counts 1, 2, 3, 4, 5, 6, 7, 8 in the fixed order failed, bounced, rejected, delayed deliveries, failed inbound, unrouted inbound, failed webhooks, unmatched events with their filtered hrefs, plus the two activity links (10 deliveries updated, 11 messages received). Candidate B is CSS only, so G5 is structurally guaranteed; the measurement confirms it.

## Axe incomplete triage

Violations: 0 in all 252 scans. The include selector matched at least one element in every scan (minimum match count 1). Incomplete: **1 in each of the 252 scans** (252 of 252), always the same item:

| rule | element | axe message |
|---|---|---|
| color-contrast | the visible "Refresh health" label span (`.[.phx-click-loading_&]:invisible` inside `#operator-health-refresh`) | Element's background color could not be determined due to a background image |

Triage (resolved by a computed check, identical for A and B because B does not touch the button): the daisyUI `btn` pseudo background stack makes axe unable to resolve the background, and `getComputedStyle(button).backgroundImage` is "none, none" with a transparent background colour. Computing the label colour against the nearest opaque ancestor (page base) at 1280px: **light 5.26:1** (rgb(92,107,122) on rgb(248,251,253)), **dark 10.30:1** (rgb(184,202,212) on rgb(13,27,42)), both at 14px regular, so both meet the 4.5:1 AA threshold. Disposition: resolved by computed check, not reported as a pass of the axe rule. The retained "Phase 177 Health axe" test in plan 177-08 Task 3 repeats this computed check so the incomplete finding stays triaged. No other rule produced an incomplete result in any candidate, scenario, viewport or theme.

## Tie-breakers

Both candidates survived every gate, so the tie-breakers decide. Pairwise comparison over the 126 (scenario, viewport, theme) pairs:

| tie-breaker | A lower/better | B lower/better | equal |
|---|---|---|---|
| 1 scan path (px) | 0 | 0 | 126 of 126 |
| 2 row slack (px), pairs with issue rows | 0 | 0 | 84 of 84 |
| 3 activity subordination failures | 0 of 126 | 0 of 126 | both candidates satisfy all three conditions in every pair |
| 4 layout rules + breakpoints | 3 (2 rules + 1 breakpoint) | 8 (6 rules + 2 breakpoints) | A is lower |

(Rows 1 and 2 count the pairs in which that candidate's value is lower; a difference under 0.5px counts as equal.)

Sample, all-eight in light, per viewport:

| viewport | scan path A | scan path B | row slack A | row slack B | activity top A (limit) | activity top B (limit) |
|---|---|---|---|---|---|---|
| 320 | 564 | 564 | 16 | 16 | 1006 (limit 981) | 1006 (limit 553) |
| 375 | 536 | 536 | 68.8 | 68.8 | 978 (limit 953) | 978 (limit 553) |
| 390 | 536 | 536 | 83.8 | 83.8 | 978 (limit 953) | 978 (limit 553) |
| 768 | 488 | 488 | 246.0 | 246.0 | 701 (limit 676) | 701 (limit 276) |
| 1024 | 460 | 460 | 438.0 | 438.0 | 673 (limit 648) | 673 (limit 248) |
| 1280 | 460 | 460 | 438.0 | 438.0 | 673 (limit 648) | 248 (limit 248) |
| 1440 | 460 | 460 | 438.0 | 438.0 | 673 (limit 648) | 248 (limit 248) |

Tie-breaker 1 ties because Recent activity sits after the last issue in A and beside the verdict in B, so neither moves the observation-to-last-issue distance. Tie-breaker 2 ties because B's first track is capped at the same 42rem as A's column. Tie-breaker 3 ties because both satisfy the three conditions (B places the aside at the verdict top). Tie-breaker 4 differs: B needs a 56rem breakpoint, a grid rule, a column-1 placement rule, an aside rule and an inner-column override (4 extra rules, 1 extra breakpoint) on top of everything A needs.

## Winner

Winner: A

## Reason

No gate eliminated either candidate (0 failures in 126 A measurements and 126 B measurements, 0 axe violations in 252 scans), and tie-breakers 1, 2 and 3 are exact ties across all pairs, so tie-breaker 4 decides: A needs 3 layout rules and breakpoints, B needs 8. Because the decisive tie-breaker is a measured count, not a residual visual preference, the owner-visual-tie branch does not apply and no owner hand-off is required. A is already shipped by plan 177-04, so production is unchanged: no CSS, markup or bundle change in this task, no `layout`/`composition` attr in `health_overview.ex`, and no B code, story or toggle exists in the tree.

## Raw output

One JSON object per measurement (compact projection; keys: c candidate, s scenario, t requested theme, appTheme applied data-theme, vw viewport, container/column px, overflow px, g2 [domOrder, visualOrder], g3 [sameLine, gap px, ok], g4 [non-help targets, help triggers, small count], g5fp normalised fingerprint sha1, g6 [verdict, stale panels, notices, ok], issues, scan path px, slack px, sub [headingSmaller, countOk, topOk], rules total, g7 [include matches, violations, incomplete]).

```jsonl
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":564,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":564,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":68.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":68.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":83.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":83.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":246,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":246,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":564,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":564,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":68.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":68.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":83.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":83.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":246,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":246,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"all-eight","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"2304bd5ca2b7","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":438,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":71,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":71,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":86,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":86,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":173,"slack":285.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":173,"slack":285.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":71,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":71,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":86,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":221,"slack":86,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":173,"slack":285.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":173,"slack":285.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"one-issue","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[4,5,0],"g5fp":"8d9f80cf56c0","g6":["Needs attention","","",true],"issues":1,"scan":145,"slack":477.9,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"none-active","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"68d5d4ac634d","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":339,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":339,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":65.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":65.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":80.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":80.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":263,"slack":228.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":263,"slack":228.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":339,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":339,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":65.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":65.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":80.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":311,"slack":80.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":263,"slack":228.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":263,"slack":228.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"default","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"default","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","",true],"issues":3,"scan":235,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":341.59375,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":341.59375,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":50.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":50.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":65.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":65.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":246,"slack":192.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":246,"slack":192.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":341.59375,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":341.59375,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":50.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":50.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":65.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":318,"slack":65.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":246,"slack":192.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":246,"slack":192.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"stale-partial","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[5,7,0],"g5fp":"8c52cfd21db1","g6":["Needs attention","orphan_backlog","operator-health-stale-orphan_backlog",true],"issues":2,"scan":218,"slack":384.8,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":160,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"empty","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"0d25ff6b68b8","g6":["No mail activity in this period","","",true],"issues":0,"scan":84,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":391,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":391,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":65.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":65.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":80.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":80.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":291,"slack":228.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":291,"slack":228.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":391,"slack":16,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":391,"slack":16,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":65.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":65.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":80.1,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":363,"slack":80.1,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":291,"slack":228.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":291,"slack":228.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"unavailable","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[6,7,0],"g5fp":"9cd17b8d0a2d","g6":["Needs attention","","operator-health-unavailable-failed_ingest",true],"issues":3,"scan":263,"slack":420.4,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":624,"slack":14,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":624,"slack":14,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":61.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":61.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":76.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":76.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":222.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":222.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":624,"slack":14,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":624,"slack":14,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":61.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":61.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":76.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":536,"slack":76.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":222.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":488,"slack":222.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"long-count","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[11,12,0],"g5fp":"342e3f68ac7c","g6":["Needs attention","","",true],"issues":8,"scan":460,"slack":414.5,"sub":[true,true,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"light","appTheme":"mailglass-light","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":320,"container":288,"column":288,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":212,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":375,"container":343,"column":343,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":390,"container":358,"column":358,"overflow":0,"g2":[true,true],"g3":[false,4,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":188,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":768,"container":480,"column":480,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":140,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":1024,"container":736,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":1280,"container":992,"column":992,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
{"c":"A","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":672,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":3,"g7":[1,0,1]}
{"c":"B","s":"fjordline-long-unicode","t":"dark","appTheme":"mailglass-dark","vw":1440,"container":1152,"column":1152,"overflow":0,"g2":[true,true],"g3":[true,8,true],"g4":[3,4,0],"g5fp":"5d762925b0fe","g6":["No issues found","","",true],"issues":0,"scan":112,"slack":null,"sub":[true,null,true],"rules":8,"g7":[1,0,1]}
```
