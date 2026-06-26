# Deferred Items — Phase 116

Out-of-scope discoveries logged during execution (SCOPE BOUNDARY rule). Not fixed
in this phase; recorded for follow-up.

## Pre-existing operator-browser matrix failures (stale after the Phase 113 layout split)

**Found during:** Plan 116-06 Task 3, running the full `npm run test:operator-browser`
matrix as the plan's `<verification>` item (133 passed, 1 skipped, **16 failed**).

**Root cause (pre-existing, NOT caused by 116-06):** Phase 113 (`532a8b17`,
`feat(113-02): dual table+card delivery presentation`) split the deliveries list
into a desktop `<div data-testid="operator-deliveries-table" class="hidden md:block">`
and a mobile `<ul data-testid="operator-deliveries-list" class="md:hidden">`. The
`operator.spec.js` `openOperator` helper (last touched Phase 111, `b07036f8`) still
asserts `getByTestId("operator-deliveries-list")` (now the **mobile** `<ul>`) is
visible at the default 1280px desktop viewport, where it is `md:hidden` — so every
test routed through that helper fails with `Received: hidden`.

**Why out of scope for 116-06:** Plan 116-06 is a data-only + demo-spec plan. Its
three commits touched ONLY `reference/demo_app/assets/e2e/cohort.spec.js`,
`mailglass_admin/docs/ui-baseline-scores.json`, and
`mailglass_admin/docs/axe-baseline.json`. None touch `operator.spec.js`,
`structural.spec.js`, or any `lib/` source, so these failures cannot be a 116-06
regression. The plan's actual fail-closed gate — the three comparator ExUnit tests
(`ratchet_baseline_test`, `axe_baseline_test`, `bucket_a_coverage_test`) — is fully
green (22 tests, 0 failures), as is the new `cohort.spec.js` (4 passed) and the axe
producer (9 passed).

**Failing tests (16):**
- `operator.spec.js` — 13 tests routed through `openOperator` /
  `openOperatorInbound` helpers that assert the now-`md:hidden` mobile list at
  desktop width.
- `structural.spec.js:797 / :817` — touch-target floor tests (operator filter
  toggle / replay-modal controls) that open the operator surface via the same
  stale helper path.
- `structural.spec.js:1287` — preview admin-chrome / preview-frame toggle
  independence (same desktop-viewport surface-open dependency).

**Suggested fix (a future plan):** Update `operator.spec.js` `openOperator` to
assert the responsive container that is actually visible at the test viewport —
`operator-deliveries-table` at desktop (>=768px), or set the mobile viewport
before asserting `operator-deliveries-list`. Mirror the visibility-aware scoping
the 116-06 demo `cohort.spec.js` adopted (scope row/list assertions to the
viewport-appropriate container). This is an admin e2e-harness fix, not a fixtures
or ratchet concern.
