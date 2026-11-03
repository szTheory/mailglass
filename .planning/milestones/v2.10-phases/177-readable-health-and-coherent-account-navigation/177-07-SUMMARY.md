---
phase: 177-readable-health-and-coherent-account-navigation
plan: "07"
subsystem: testing
tags: [playwright, e2e, axe, accessibility, account-scope, reduced-motion]
status: complete

requires:
  - phase: 177-06
    provides: "e2e/support/account.cjs, the scope group markup, layout-suffixed Account ids"
provides:
  - "Every Account-control browser selector resolves through e2e/support/account.cjs (zero direct operator-account-* locators outside it)"
  - "Five new Phase 177 browser tests: keyboard order, Preview shows no Account identity, polite switch status, scope group axe, reduced motion"
affects: [177-09, 177-11]

plan_head_before: 75fecb252a689c4537d24dc63a4c34e6cf7a207b
plan_head_after: 01fb9498

actuals:
  tokens: 8100
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Account-control locators are scoped through the visible surface-nav-scope-group, not visibility-filtered themselves, so closed-menu href reads and hidden-until-clicked status spans still resolve"
    - "Axe scans assert the include selector matched before scanning and record incomplete separately from violations"

key-files:
  created:
    - .planning/phases/177-readable-health-and-coherent-account-navigation/177-07-migrated-titles.txt
  modified:
    - mailglass_admin/e2e/support/account.cjs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/e2e/inbound-layout.spec.js
    - mailglass_admin/e2e/phase170-journey.spec.js
    - mailglass_admin/e2e/phase175-inbound.spec.js
    - mailglass_admin/e2e/phase177-account.spec.js
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex

key-decisions:
  - "accountOption/accountSwitchStatus/accountId are scoped through the visible scope group; only the switcher, label and context are filtered by visibility directly"
  - "Removed aria-label=\"Account context\" from the role-less div (axe aria-prohibited-attr, incomplete on every Health scan); the group is already named by its header"

requirements-completed: ["UXF-09"]

coverage:
  - id: D1
    description: "All 24 direct operator-account-* locators migrated to account.cjs; no test title renamed"
    requirement: UXF-09
    verification:
      - kind: e2e
        ref: "playwright: the 7 edited tests listed in 177-07-migrated-titles.txt (7 passed); full 8-spec gate 193 passed"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs (9 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Keyboard order, Preview scope chrome, polite switch status, scope group axe (light/dark, 1280/390) and reduced motion proven in Chromium"
    requirement: UXF-09
    verification:
      - kind: e2e
        ref: "playwright: e2e/phase177-account.spec.js#Phase 177 (8 passed)"
        status: pass
    human_judgment: false
---

# Phase 177 Plan 07: Account selector migration and scope group browser proof Summary

**Every Account-control browser selector now resolves the visible copy through one helper, and the scope group's keyboard order, Preview chrome, switch status, axe result and reduced-motion behavior are proven in Chromium.**

## Accomplishments

- `e2e/support/account.cjs` gained `accountContext`, `accountId`, `accountSwitchStatus` and `switchStatusIdPattern`; `accountOption` is now scoped through the visible scope group. It is the only spec file that names an `operator-account-*` testid (grep count 0 across the five migrated specs, baseline 24).
- Migrated call sites, all titles unchanged:
  - `flows.spec.js`: "Phase 168 Delivery Mailable wrapping" (switch, zoom-time switch, topbar-controls zoom list), "Phase 168 Account scope" (id reads, option href reads, pending-status locator, id regex), "Phase 175 Delivery layout U1/U2/U3/U5/U6: ..." (switch, replay-modal Account context read in both places).
  - `structural.spec.js`: "multi-tenant selector preserves surface state and inbound pagination uses real boundaries" (switcher x2, option x2).
  - `inbound-layout.spec.js`: "account menu closes when the operator clicks outside it".
  - `phase170-journey.spec.js`: "responsive themes, touch, focus, reduced motion, and current evidence at each viewport" (switcher bounding box).
  - `phase175-inbound.spec.js`: "Phase 175 Inbound layout U1/U2/U3/U5/U6: Unicode subject, Mailbox and replay at real zoom" (Account context text).
  - `phase168-plan03-acceptance.spec.js` and `flows.spec.js` Health/Preview role lookups: re-verified, no edit needed (they passed in the final gate).
- Five new tests in `phase177-account.spec.js`: scope group keyboard order, Preview shows no Account identity (320 and 1280), Account switch shows a polite status (held websocket reply; status visible, `role=status`, `aria-live=polite`, never "Switched"; header then shows the new Account with the `details` closed), scope group axe, scope chrome honors reduced motion.

## Assertions that changed meaning

- `flows.spec.js` switch-status id regex: `^operator-account-switch-status-\d+$` became `switchStatusIdPattern` (`...-(sidebar|mobile)-\d+$`) because 177-06 layout-suffixed the ids. Same intent (safe numeric token independent of the Account id).
- `flows.spec.js` "Phase 168 Account scope" `pendingSwitch`: the locator now scopes through the visible scope group, so `toHaveCount(1)` counts the visible layout's status only (previously one element, now would be two).
- `flows.spec.js` replay-modal Account context reads (two sites) moved out of `document.querySelector(...)` inside `evaluate` to `accountContext(page).textContent()`; the first matching element could have been the hidden layout copy. Content assertion (`toContain("browser-tenant")`) unchanged.
- No assertion encoded the old topbar second-row placement in the five migrated specs (grep for `admin-shell-actions`, `mg-scope-identity` outside `phase177-account.spec.js`: none).

## Commands and results

- Task 1 verify (`flows.spec.js --grep "Phase 168 Delivery Mailable wrapping|Phase 168 Account scope"`): 2 passed. `bucket_a_coverage_test.exs --seed 0`: 9 tests, 0 failures.
- Task 2 verify (titles file through `--grep` across the six specs): 7 passed. Direct-selector grep: 0.
- Task 3 verify (`phase177-account.spec.js --grep "Phase 177"`): 8 passed. `docs/axe-baseline.json` diff is empty.
- Mix after the one `shell.ex` edit: shell_test + phase177_account_scope_test + voice_test + token_parity_test + assets_test + bucket_a_coverage_test, `--seed 0` -> 85 tests, 0 failures, 1 excluded. `mix format --check-formatted` on `shell.ex` clean. The CSS bundle is unchanged (no class changed; `assets_test`/`token_parity_test` pass, `priv/static` clean).
- Wave gate (flows, structural, inbound-layout, phase170-journey, phase175-inbound, phase168-plan03-acceptance, phase177-account, axe-baseline): **193 passed, 3 failed, 1 skipped (7.2m)**.
  - 3 failed: `axe-baseline.spec.js` "scan deliveries / light|dark|system", timing out at `operator-replay-open` (the known deferred item). **Determined pre-existing**: they fail identically in a scratch worktree at pre-phase commit `03e2cc35` (before any 177 execution), with deps/_build/node_modules/tailwind copied in. Worktree removed afterwards.
  - 1 skipped: `structural.spec.js:3246` `test.skip(true, ...)` "No header-anchored overlay present", a pre-existing conditional skip (not added here).
  - The Health and Preview axe baseline cells in that spec passed; baseline file unchanged.

## Axe receipts (scope group, `nav[aria-label="Mailglass sections"]`, both nav copies included)

Include selector matched 2 elements in every scan (guard: `toBeGreaterThanOrEqual(1)` before each scan). WCAG tags wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa.

| Page | Theme | Width | Include matches | Violations | Incomplete |
|------|-------|-------|-----------------|------------|------------|
| Health | light | 1280 | 2 | 0 | 0 |
| Health | light | 390 | 2 | 0 | 0 |
| Health | dark | 1280 | 2 | 0 | 0 |
| Health | dark | 390 | 2 | 0 | 0 |
| Preview | light | 1280 | 2 | 0 | 0 |
| Preview | light | 390 | 2 | 0 | 0 |
| Preview | dark | 1280 | 2 | 0 | 0 |
| Preview | dark | 390 | 2 | 0 | 0 |

Triage of the first run (before the fix): every Health scan reported `incomplete = 1`, rule `aria-prohibited-attr` on `<div data-testid="operator-account-context" aria-label="Account context">` ("aria-label is not well supported on a div with no valid role"). This was a real defect, not a needs-review: the label was inaudible and redundant (the group is already named by its header via `aria-labelledby`). Resolved by removing the attribute from `shell.ex`; re-run shows incomplete 0 everywhere, and the test now fails if `aria-prohibited-attr` returns. Preview scans were 0 incomplete in both runs. A whole-page scan (outside the include scope) on Health still lists `color-contrast` as incomplete (1 node); that is outside the scope group, not part of this plan, and is covered by the axe-baseline matrix.

## Keyboard order (measured, 1280)

- /ops/mail with 2 Accounts: Appearance control (topbar, global) -> Account summary -> Health -> Deliveries -> Inbound -> Preview -> page content ("Help for observation period" ...). Nav stops asserted exactly; the stop after Preview is outside nav and topbar.
- Preview with a valid context: Appearance -> Back to Health -> Health -> Deliveries -> Inbound -> Preview -> page content.
- Every stop has a computed non-none outline (`solid 2px`; the Appearance radio input reports `auto 1px`).

## Reduced-motion measurements (input for the 177-AUTOMATION.md row in plan 177-11)

Under `reducedMotion: "no-preference"` the Account chevron computes `transition-duration > 0` (teeth). Under `reduce`, every measured element computed `transition-duration = 1e-05s` and `animation-duration = 1e-05s` (the global `@media (prefers-reduced-motion: reduce)` block forces 0.01ms), all <= 0.001s:

- Account summary (`operator-account-switcher`), chevron closed and open
- all 33 elements inside the visible scope group, closed and open (header, context, details, summary, label spans, menu `ul`/`li`/option links, id and switch-status spans, scope items and their links, description)
- `#operator-health-refresh` on /ops/mail
- `preview-return-link` and all 11 elements of the Preview scope group

The guard did not fire, so no `motion-safe:` gate and no CSS rebuild were needed (the four conditional source/CSS files other than `shell.ex` are untouched).

## Deviations from Plan

**1. [Rule 1 - Bug] Delivery ID edge check at 1280 failed after the 177-06 layout change**
- **Found during:** Task 2 verify ("Phase 175 Delivery layout U1/U2/U3/U5/U6").
- **Issue:** `assertZoomReadableValue` failed `top edge >= 0` by 0.22px at 1280. Deterministic (2 of 2 runs); passes with the pre-177-06 source and the old spec. After the 177-06 layout change, the scroll offset carried over from the 768 iteration leaves the Delivery ID button a fraction of a pixel above the viewport, and `scrollIntoViewIfNeeded` does not move an element it already counts as in view.
- **Fix:** the helper recenters an element whose rect is outside the viewport before measuring. Top and bottom checks are unchanged, so no tolerance was loosened.
- **Files modified:** `mailglass_admin/e2e/flows.spec.js`. **Commit:** 6460e81a.

**2. [Rule 2 - Missing critical] Role-less `aria-label` on the Account context div**
- **Found during:** Task 3 (axe incomplete triage). See the axe section. Removed `aria-label="Account context"` from `account_context/1`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex`. **Commit:** 01fb9498.

**3. [Process] Task 1 commit holds the whole `flows.spec.js` migration**
- Task 1 is scoped to the Fjordline switch, but all `flows.spec.js` call sites share the same helper changes, so they were migrated and committed together in c84c8b52. Task 2 then covered the other four specs and the titles file.

**4. [Scope] First attempt at `accountOption` filtered the option by visibility**
- Reading `href` on an option inside the closed menu failed ("Phase 168 Account scope"). Fixed in the same task by scoping through the visible group.

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical), 2 notes. **Impact:** none on scope; the one product change is an attribute removal.

## Known Stubs

None.

## Threat Flags

None. T-177-16 is mitigated: `docs/axe-baseline.json` diff is empty, `PERSIST_AXE_BASELINE` was not set, and the new scans assert zero violations.

## Notes for later plans

- Plan 177-11 should record the reduced-motion row from this summary and the receipts above in 177-AUTOMATION.md.
- `axe-baseline.spec.js` "scan deliveries" x3 is a confirmed pre-existing failure (reproduced at `03e2cc35`); it is the only remaining red in the 8-spec gate besides the pre-existing conditional skip.
- Browser runs rewrite `.planning/milestones/v2.9-phases/168-*/artifacts/review-fix/*.png` and `priv/static/app.css`; both were restored with path-specific `git checkout` and never committed.

## Self-Check: PASSED

- Created/modified files exist: `177-07-migrated-titles.txt`, `account.cjs`, `phase177-account.spec.js` (FOUND).
- Commits reachable from HEAD: c84c8b52, 6460e81a, 01fb9498 (FOUND).
- `git rev-list --count 75fecb25..HEAD` = 3 before this SUMMARY commit.
- `git status --short mailglass_admin/priv/static mailglass_admin/docs` is empty.
