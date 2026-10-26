---
phase: 170-inbound-investigation-and-recovery
plan: "08"
subsystem: admin-ui
tags: [inbound, replay, rendered, accessibility, browser]
requires:
  - phase: 170-01
    provides: Exact inbound selection, safe evidence, and empty/unavailable states
  - phase: 170-03
    provides: Persisted routing explanation and safe evidence projections
  - phase: 170-04
    provides: Fresh record reads and outcome projection
  - phase: 170-05
    provides: Timestamped run history and explicit timeline refresh
  - phase: 170-06
    provides: Exact replay review and action-time authorization
  - phase: 170-07
    provides: Single-submit replay feedback and independently refreshed history
provides:
  - Connected browser coverage for the end-to-end inbound investigation/recovery task and negative paths
  - Rendered evidence with matching source, generated, and served asset provenance
  - Explicit preservation of the last successful run snapshot until native history refresh
affects: []
tech-stack:
  added: []
  patterns: [connected-liveview-journey, rendered-asset-provenance, explicit-history-refresh]
key-files:
  created:
    - .planning/phases/170-inbound-investigation-and-recovery/170-RENDERED.md
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/docs/operator-trust.md
    - mailglass_admin/e2e/axe-baseline.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/phase170-journey.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/voice_test.exs
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_inbound/test/mailglass_inbound/internal/operator/summary_test.exs
    - .planning/phases/170-inbound-investigation-and-recovery/170-08-red-evidence.json
decisions:
  - Keep a completed replay's command result separate from the selected history snapshot; Refresh history performs the next timeline read.
  - Persist the deterministic browser fixture's durable execution-route binding so connected replay tests exercise the product contract.
  - At actual 200% browser zoom, stack the shell actions and allow slight subpixel headroom for the 44px evidence disclosure.
  - Preserve the spec-less edge-probe status: INUX-01 through INUX-04 remain unclassified/unresolved; no taxonomy was assigned.
metrics:
  duration: 82m
  completed_date: 2026-10-09
  tasks: 2
  files: 17
  commits: 3
  commits: 3
plan_head_before: 017118f1c5a0013455658d9eeb9c247a1c662fa5
plan_head_after: 7146f69c7a1c959a084a1bdafdefd1c78624d0b1
status: complete
actuals:
  tokens: 78266
  tasks: 2
  commits: 3
---

# Phase 170 Plan 08: Connected Inbound Journey and Rendered Acceptance Summary

The operator can investigate an exact inbound record, review a permitted replay, and see truthful command feedback while the timestamped history remains a stable snapshot until explicit refresh.

## Completed Tasks

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 1 | Exercise the connected inbound investigation and recovery path | `901c341d` | `phase170-journey.spec.js`, fixture reset and focused regression coverage |
| 2 | Inspect and correct the rendered journey across inherited UI modes | `c4c47bbf`, `7146f69c` | Admin CSS/assets, rendered journey and interaction checks, `170-RENDERED.md` |

## Implementation

- Added connected Playwright coverage for Account/list/Quick view/detail/evidence/replay/return, exact foreign-ID nondisclosure, empty and no-match states, unavailable package/read states, stale/denied/busy/duplicate cases, explicit no-change, recorded failure, command failure, and failed history refresh.
- Added rendered checks at 320/390/768/1440 CSS pixels across Light/Dark/System, live OS color-scheme changes, reduced motion, keyboard reveal/re-redact with focus return, touch navigation, and actual Chromium 200% tab zoom.
- Enforced a strict 44×44 CSS pixel minimum for visible interactive controls. The evidence disclosure uses 44.1px minimum height because Chromium measured 43.99988px for a nominal 44px target under actual zoom scaling.
- At narrow CSS widths, including the 720px viewport produced by 200% zoom, the shell actions move below the logo and stack so Account and Appearance controls remain visible.
- Long mono values wrap, and the built Admin stylesheet is the one served by the browser. Source, built, and served CSS hashes are recorded in `170-RENDERED.md`.
- A successful replay updates command feedback without replacing `runs` or advancing the timeline-read timestamp. The new recorded run appears after the operator activates Refresh history.

## Verification

- Connected Phase 170 cases passed: `BROWSER_SERVER_PORT=4102 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec npm run test:operator-browser -- --grep "Phase 170 connected"` — the final suite includes connected stale, denied, and rapid-repeat replay confirmation checks.
- Rendered Phase 170 case passed on final revision `7146f69c`: `BROWSER_SERVER_PORT=4102 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec npm run test:operator-browser -- --grep "Phase 170 rendered"` — 1 passed. The actual 200% screenshot was opened and visually reviewed after the final CSS correction.
- Final full operator browser suite after closeout security coverage: `BROWSER_SERVER_PORT=4102 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec npm run test:operator-browser` — 206 passed, 1 existing guarded skip, 0 failed (2.8m).
- Admin package suite: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test --seed 1` — 575 tests, 0 failures, 1 excluded.
- Inbound package suite: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test --seed 1` — 3 properties, 479 tests, 0 failures.
- Final CSS token-parity and bundle checks: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` — 10 tests, 0 failures.
- Full browser suite's one skip is the pre-existing guarded centered-modal outcome at `mailglass_admin/e2e/structural.spec.js:2852`; its assertion applies only when a header-anchored overlay exists. No Plan 08 check was skipped or left for owner UAT.

## Deviations from Plan

### Phase Security Audit Closure

The phase security audit identified two gaps in the declared controls. The outcome filter previously matched any stored run even though the row showed only the latest fresh outcome; it now filters through the same tenant-scoped latest-fresh subquery, with a regression for older fresh and replay outcomes. Connected browser coverage now asserts stale confirmation is rejected before authorization, denied confirmation adds no run, and a rapid repeated confirmation adds at most one run. The security audit closed all 21/21 threats with `threats_open: 0`; full package and browser results are recorded above.

### Auto-fixed Issues

**1. [Rule 1 - Cross-plan behavior correction] Preserve history snapshot after replay completion**
- **Found during:** Task 1 connected journey
- **Issue:** Replay completion implicitly read the selected timeline, replacing the timestamped snapshot despite D-12/D-18 requiring command feedback and explicit history refresh to remain separate.
- **Fix:** Keep the last successful `runs` and read timestamp through command completion; add a regression asserting the old snapshot and feedback remain until Refresh history, then the new run appears after refresh.
- **Files modified:** `inbound_live.ex`, `inbound_live_test.exs`, `phase170-journey.spec.js`
- **Commit:** `c4c47bbf`

**2. [Rule 2 - Test fixture correctness] Bind deterministic accepted fixtures to the durable execution route**
- **Found during:** Task 1 connected replay
- **Issue:** The existing browser fixture had no eligible accepted record under the product's required durable route binding.
- **Fix:** Update only the deterministic reset/fixture route to persist the same `mailglass_execution_route` binding used by production eligibility; correct the foreign-ID assertion to the safe non-disclosing copy.
- **Files modified:** `test/support/endpoint_case.ex`, `test/support/operator_fixtures.ex`, `phase170-journey.spec.js`
- **Commit:** `901c341d`

**3. [Rule 1 - Rendered accessibility] Keep actions visible and targets at least 44×44 under actual zoom**
- **Found during:** Task 2 screenshot inspection
- **Issue:** The original screenshot clipped the shell Account/Appearance action group at 200% zoom. After stacking those controls, strict measurement also found a 43.99988px disclosure target caused by subpixel scaling.
- **Fix:** Stack actions below the logo at narrow CSS widths; add bounds assertions and 0.1px of minimum-height headroom for the disclosure. Rebuild assets and rerun rendered/full-browser checks.
- **Files modified:** `assets/css/app.css`, `priv/static/app.css`, `phase170-journey.spec.js`
- **Commit:** `7146f69c`

**4. [Rule 1 - Stale browser/test expectations] Align existing checks with current responsive and copy contracts**
- **Found during:** Task 1/2 acceptance validation
- **Issue:** Several inherited tests assumed desktop-only row labels, stale `aria-selected` state, obsolete status badge classes, prior replay copy, or an old no-change summary shape.
- **Fix:** Make helpers inspect the visible table/card control and its exact record ID, apply the theme through the existing preference cookie without losing Account scope, navigate overlay-only checks to the exact detail, and update expectations/docs to the current visible contract. Preserve the Plan 06/07 eligibility, auth, status, single-submit, and timestamped-history behavior.
- **Files modified:** existing Playwright helpers/specs, focused tests, and `docs/operator-trust.md` listed in frontmatter.
- **Commit:** `c4c47bbf`

## Auth Gates

None.

## Known Stubs

None found in files created or modified by this plan.

## Threat Surface Scan

No new network endpoint, authorization path, file access pattern, or trust-boundary schema was introduced. The browser fixture remains test-only; replay authorization still uses the existing tenant-scoped host path.

## User Setup Required

None. Machine-observable acceptance is covered by automated browser and package checks; no routine owner UAT remains.

## Next Phase Readiness

Plan 08 is complete. Phase-level verification can proceed with rendered provenance, all package suites, and the final full-browser result recorded above.

## Self-Check: PASSED

- `170-08-SUMMARY.md`, `170-RENDERED.md`, and current rendered provenance exist.
- Task commits `901c341d`, `c4c47bbf`, and `7146f69c` exist and are ancestors of the checkout.
- The measured plan commit count is 3 from `plan_head_before` through `plan_head_after`.

## Phase Closeout Follow-Up (2026-10-09)

The post-plan review fixed the inbound route trace so each route's displayed state follows its clause verdicts, and limited the outside-results hint to successful list reads. Replay eligibility now treats a failed run with persisted Mailbox identity as a matched-but-unsafe legacy binding and refuses it without resolving stored module text. Regression tests cover these cases.

The UI audit follow-up replaced numeric spacing utilities with semantic tokens, brought the Quick view title and list heading into the shared typography scale, matched Account empty-state wording, added a pending announcement for Refresh history, improved non-locked labels/copy, and rendered unavailable Quick view navigation as accessible native disabled buttons. Earlier byte-frozen Phase 101/121 copy remains unchanged.

Final closeout evidence:

- Full Admin suite: **577 tests, 0 failures, 1 excluded**; focused final copy and Inbound UI suites after restoring the locked subtitle: **130 tests, 0 failures, 1 excluded**.
- Full inbound suite: **3 properties + 480 tests, 0 failures**.
- Full connected browser suite: **206 passed, 1 existing guarded skip, 0 failed**; focused Phase 170 connected/rendered suite after final locked-copy restoration: **7 passed, 0 failed**.
- CSS build and token-parity/bundle checks passed (**10 tests, 0 failures**); final source, generated, and served asset hashes are in `170-RENDERED.md`.
- Refreshed security audit: **21/21 threats closed**. Refreshed code review: **45 files, clean, 0 findings**. Refreshed UI review: **21/24**, with only a documented screenshot evidence limitation for the updated overlays; no machine-observable acceptance remains for owner UAT.
