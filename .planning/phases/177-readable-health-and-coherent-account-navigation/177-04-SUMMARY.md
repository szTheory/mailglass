---
phase: 177-readable-health-and-coherent-account-navigation
plan: "04"
subsystem: ui
tags: [phoenix-liveview, health, css-container-query, tailwind, floki, playwright]
status: complete

requires:
  - phase: 177-02
    provides: health_population_test.exs literal goldens (golden_commit 1676b15a)
provides:
  - "Health renders as one left-aligned 42rem reading column inside a size container"
  - "HealthOverview.observation/1, verdict/1, issue_list/1, notices/1, activity/1"
  - "Issue counts at body size, 44px issue and activity links, tertiary per-issue help"
  - "Persistent Health notices without role=status; Recent activity subordinate below a hairline"
affects: [177-05, 177-08, 177-11]

plan_head_before: 5e1d605dc5c2b2607409bdf95f760a99e9f83c39
plan_head_after: f5539fd3ea03d191657bcb36de461c5281ba1b6f

actuals:
  tokens: 14000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Named CSS classes (.operator-health-layout size container, .operator-health-column 42rem) beside .operator-deliveries-layout; never max-w-2xl (48px in this design system)"
    - "Stable-width loading button: both labels overlap in one grid cell, the inactive one is invisible so it is excluded from the accessible name"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs
    - .planning/phases/177-readable-health-and-coherent-account-navigation/deferred-items.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/health_overview.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/health_population_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/phase169-journey.spec.js

key-decisions:
  - "Status section keeps mt-md and Recent activity keeps mt-lg; the column is a plain block (not a grid with gap) so the hairline spacing is not doubled"
  - "Per-issue help stays a single field_help per row with the default trigger, after the label link (owner todo item 3); components.ex untouched"
  - "operator_live_test.exs: the two tests holding the p.mono assertions gained @tag :phase177 (existing @tag :g_168_10 retained)"

patterns-established:
  - "Health row count extraction goes through the <testid>-count testid, not a CSS class"

requirements-completed: ["OUTUX-06"]

coverage:
  - id: D1
    description: "Health is one column capped at 42rem with the observation group first; Refresh, period and Last checked stay together in DOM order"
    requirement: OUTUX-06
    verification:
      - kind: e2e
        ref: "playwright:phase169-journey.spec.js Phase 177 Health column stays capped at landmark widths (320/375/390/768/1024/1280/1440)"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs (13 tests, tag :phase177)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Issue rows: fixed taxonomy order, identical classes for reversed counts, body-size bold tabular counts, 44px links, tertiary per-issue help, no role=status"
    requirement: OUTUX-06
    verification:
      - kind: unit
        ref: "health_overview_test.exs#Phase 177 Health per-issue help is the tertiary element of each row and siblings"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/health_population_test.exs (goldens byte-identical to 1676b15a)"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-10-28
---

# Phase 177 Plan 04: Readable Health Column Summary

**Health is now one left-aligned 42rem reading column with a grouped observation block, fixed-order 44px issue rows with a tertiary per-issue help, adjacent notices and a subordinate Recent activity section; populations and every visible string are unchanged.**

## What was built

- Task 1 (tracer): `.operator-health-layout { container-type: inline-size }` and `.operator-health-column { max-width: 42rem }` in `assets/css/app.css`; `HealthOverview.observation/1` (role=group, aria-label "Health check period and freshness") holds the period with its help, "Last checked" and the Refresh button (`id="operator-health-refresh"`, accessible name exactly "Refresh health", both labels overlap in one grid cell). Observation markup moved out of `OperatorLive`; the helpers stay there. `phase169-journey.spec.js` asserts the column width instead of `metricColumns`, plus a new geometry-only test at 320/375/390/768/1024/1280/1440.
- Task 2: `overview/1` split into `verdict/1`, `issue_list/1`, `notices/1`, `activity/1`. Rows are `ul.divide-y > li`; counts use `text-body font-bold tabular-nums text-base-content` with a `<testid>-count` testid; issue and activity links are `inline-flex min-h-11`; the help trigger is the field_help default (`h-6 w-6 text-secondary`, 16px glyph, after the link); notices dropped `role="status"`; activity uses `mt-lg border-t border-base-300 pt-md`, h2 `text-label font-bold text-secondary`, items `flex-col gap-sm @[30rem]:flex-row @[30rem]:gap-xl`.

## Verification evidence

- Bundle precondition (revision W-8): on the clean tree, `mix mailglass_admin.assets.build && git diff --exit-code -- priv/static/` exited **0** before any CSS edit. Each rebuilt bundle was committed as emitted (no theme-block edits); TokenParityTest and AssetsTest pass; browser runs left the bundle byte-identical (cmp checked).
- Bundle forms: `.operator-health-column{max-width:42rem}` x1, `.operator-health-layout{container-type:inline-size}` x1, `@container (min-width:30rem)` x1 (`30rem` occurrences 0 -> 3).
- Golden comparison: `golden_commit` = `1676b15a54625f25222c414918b04008e979f2ab`; the `awk '/^  @[a-z_]+_golden \[/,/^  \]$/'` extraction at that SHA vs the working tree: empty diff (GOLDEN-IDENTICAL). `git diff 1676b15a -- health_population_test.exs` touches only the `row_count/1` body (now `[data-testid='<testid>-count']`).
- Word-bounded class gate on `health_overview.ex`: 1 after Task 1, **0** after Task 2. `role="status"` count 0, `mono` count 0, `operator-health-last-checked` in operator_live.ex 0 / health_overview.ex 1, `metricColumns` 0.
- Tests: health_overview_test 13/0 fail (13 "Phase 177 Health" tests incl. "per-issue help is the tertiary element of each row"); wave gate `health_population + health_overview + operator_live + persona_cohort + voice` = 218 tests, 0 failures (`--seed 0`); `operator_live_test --only phase177` 3 ran (171 excluded), 0 failures; token_parity, assets, bucket_a_coverage pass; `check-conformance.sh` clean; `mix format --check-formatted` clean on touched files.
- Browser: `rendered route matrix`, `Health keeps unaffected`, `health refresh retains`, `Phase 177 Health column stays capped...` = 4 passed. Full operator browser run: 279 passed, 1 skipped, 3 failed (see Deferred Issues). Measured column widths 288/358/480/672 at 320/390/768/1440; overflow 0.
- Credo `--strict`: 1 warning, 3 refactors, 2 readability, none in lines this plan touched (operator_live.ex:1665 `assign_delivery_state`, operator_live_test.exs:1945, test support files).

## Deviations from Plan

None - plan executed as written. Notes on judgment calls:
- The Playwright route-matrix test and the full operator suite rewrite archived screenshots under `.planning/milestones/v2.9-phases/{168,169}-*/artifacts`; these were restored with path-specific `git checkout` and never committed.
- A test-only wording fix: the "visible strings unchanged" test asserts "deliveries updated" and "messages received" separately because the count lives in its own span.

## Deferred Issues

- `e2e/axe-baseline.spec.js` "scan deliveries / light|dark|system" times out waiting for `operator-replay-open` in the Full detail overlay. Reproduced on the pre-plan tree (5e1d605d with the Health files and bundle checked out at that SHA), so it predates this plan and is unrelated to Health. Logged in `deferred-items.md`.

## Known Stubs

None.

## Threat Flags

None. Presentation-only; no new endpoints, auth paths or schema.

## Self-Check: PASSED

- FOUND: mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs
- FOUND commits: e073baae (Task 1), f5539fd3 (Task 2)
