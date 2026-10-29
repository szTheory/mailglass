# Phase 177 deferred items

## From plan 177-04 (out of scope, pre-existing)

- `mailglass_admin/e2e/axe-baseline.spec.js` "axe WCAG 2.2 AA baseline producer (RATCHET-03) > scan deliveries / light|dark|system" times out at `page.getByTestId("operator-replay-open").click()` (Full detail overlay, line 120 via `openOverlay`).
  Reproduced on the pre-plan tree (commit 5e1d605d, with the Health files checked out at that SHA), so it is not caused by the Health recomposition. The Health scans in the same spec pass. Whole operator browser run with plan 177-04 applied: 279 passed, 1 skipped, these 3 failed.
