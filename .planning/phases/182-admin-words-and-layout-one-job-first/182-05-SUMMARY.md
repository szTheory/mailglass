---
phase: 182-admin-words-and-layout-one-job-first
plan: 05
subsystem: advisory-e2e-pins
tags: [e2e-pins, activity-admin-account, structural-title-assertion, mailer-row, advisory-lanes, demo-evidence]

requires:
  - phase: 182-04
    provides: the word map (Activity, Admin, Account, the provider-report sentence, the Mailer row) the advisory specs now pin
  - phase: 182-03
    provides: the compact zoned timestamps (a selected Event card now holds two of them)
  - phase: 182-02
    provides: the class badge and the collapsed Technical details the advisory specs had not yet followed
provides:
  - twelve admin e2e specs and seven demo e2e specs plus the demo navigation test reading the brand words, each run in its own advisory lane
  - the two vacuous count-0 "Operator" assertions in structural.spec.js replaced by positive title assertions (Activity, Admin, Inbound), mutation-checked
  - the Mailable pins in flows.spec.js and cohort.spec.js moved to the Mailer row
affects: [182-06 axe-baseline run and the after-catalog]

actuals:
  tokens: 21100
  tasks: 3
  commits: 3
plan_head_before: e1eb452639d1dcb47324cb6831d92e69b6428e6d
plan_head_after: d7c76421034bc7ad579143947621a9d0c05b2b44

tech-stack:
  added: []
  patterns:
    - "an advisory e2e helper opens the native Technical details disclosure (after the socket connects) before it reads an identifier"
    - "a Storybook assertion reads the specimen's own label from the story source, so a spec pins no screen word it does not own"
    - "a title assertion is positive and follows the screen: Activity on the Activity screen, Admin on the Health overview, Inbound on the Inbound list"

key-files:
  created: []
  modified:
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/e2e/phase170-journey.spec.js
    - mailglass_admin/e2e/phase176-filters.spec.js
    - mailglass_admin/e2e/phase177-account.spec.js
    - mailglass_admin/e2e/phase177-health.spec.js
    - mailglass_admin/e2e/phase178-real-zoom.spec.js
    - mailglass_admin/e2e/admin-assets.spec.js
    - mailglass_admin/e2e/judgment.spec.js
    - mailglass_admin/e2e/axe-baseline.spec.js
    - reference/demo_app/assets/e2e/cohort.spec.js
    - reference/demo_app/assets/e2e/delivery-investigation.spec.js
    - reference/demo_app/assets/e2e/demo.spec.js
    - reference/demo_app/assets/e2e/persona-screenshots.spec.js
    - reference/demo_app/assets/e2e/phase173-evidence.spec.js
    - reference/demo_app/assets/e2e/phase176-filters.spec.js
    - reference/demo_app/assets/e2e/quick-views.spec.js
    - reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs

key-decisions:
  - "The structural title assertion follows the screen, not the plan's single 'Admin' on the operator state: 182-04 made the document title follow the screen (Activity on the Activity screen, Admin on the overview), so the test asserts Activity after openOperator, then loads the Health overview and asserts Admin, then asserts Inbound. A single /Admin/ on the Activity screen would have failed on a correct product."
  - "Advisory drift that kept a spec from reaching its word pins was fixed in the spec, not recorded as pre-existing: the specs are in this plan's file list, every cause is a deliberate 182-02 or 182-03 change (collapsed Technical details, Activity gloss, second timestamp), and a red advisory lane the plan could have turned green is the silent drift it exists to prevent."
  - "The Mailable pins became Mailer-row pins on the visible identity (`operator-detail-mailer-identity`, mono, `break-words`) rather than on the trigger, because the trigger now holds the plain name and the long-value wrapping and zoom checks are about the full identity. The wrap assertion accepts `anywhere` or `break-word`, the two computed values a wrapping identity can carry."
  - "Storybook specimen labels stay as they are (spec and test files only): the Storybook assertions read the label from the story source, and the stale sample label is a deferred item."
  - "Files the plan did not list but its truth covers were edited: demo `delivery-investigation.spec.js` and `quick-views.spec.js` (182-04's list). The admin files 182-04 also listed (`phase168-plan03-acceptance`, `theme-ownership`, `support/real-zoom.cjs`) hold only code names (`loginOperator`, `OPERATOR_BASE_URL`, the 'Operator Browser Gate' lane name) and no screen word, so they stayed."

requirements-completed: [BRADM-03, BRADM-04, BRADM-05]

coverage:
  - id: D1
    description: "operator.spec.js and structural.spec.js read Activity, Admin and the class word and run green in the operator browser lane"
    requirement: BRADM-03
    verification:
      - kind: e2e
        ref: "cd mailglass_admin && npm run test:operator-browser -- operator.spec.js structural.spec.js (135 passed, 1 skipped, exit 0; priv/static unchanged)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The vacuous negative Operator assertions are replaced by positive title assertions (Activity, Admin, Inbound), and the Admin one turns red when the overview title regresses to Operator"
    requirement: BRADM-04
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/structural.spec.js#Preview, Admin and Inbound use the shared admin topbar; mutation: page_title(_view) back to 'mailglass — Operator' failed at toHaveTitle(/Admin/) with received 'mailglass — Operator • mailglass', lib then restored"
        status: pass
    human_judgment: false
  - id: D3
    description: "The ten remaining admin e2e specs read the brand words and nine of them ran green in the lane; axe-baseline.spec.js is syntax-checked and runs in 182-06"
    requirement: BRADM-03
    verification:
      - kind: e2e
        ref: "cd mailglass_admin && npm run test:operator-browser -- phase176-filters judgment phase177-account phase169-journey phase170-journey admin-assets phase178-real-zoom flows phase177-health (137 passed, exit 0)"
        status: pass
      - kind: other
        ref: "node --check mailglass_admin/e2e/axe-baseline.spec.js"
        status: pass
    human_judgment: false
  - id: D4
    description: "The demo e2e specs and the navigation test read the brand words; the demo browser suite and the navigation test ran green"
    requirement: BRADM-05
    verification:
      - kind: e2e
        ref: "bash scripts/run_demo_browser_evidence.sh (exit 0, 'Demo browser evidence passed'; playwright-report.json: 111 expected, 0 unexpected, 0 flaky, 0 skipped)"
        status: pass
      - kind: integration
        ref: "reference/demo_app: mix test test/mailglass_demo_web/phase177_navigation_test.exs --seed 0 (9 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D5
    description: "No lib, priv or demo lib file changed, and no route, data-testid or selector id was renamed while the pins moved"
    requirement: BRADM-03
    verification:
      - kind: other
        ref: "git diff --name-only e1eb4526..HEAD -- mailglass_admin/lib mailglass_admin/priv lib reference/demo_app/lib prints nothing (0 lines); all 20 changed files are e2e specs or the one demo test"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-11-15
status: complete
---

# Phase 182 Plan 05: The advisory e2e and demo pins read the brand words, and each lane was run

**Twelve admin e2e specs, seven demo e2e specs and the demo navigation test now pin Activity, Admin, Account, the provider-report sentence, the class word and the Mailer row; the operator browser lane passed 135 and 137 tests, the demo browser suite passed 111 with no flake, and a mutation proves the new positive Admin title assertion bites.**

## Performance

- **Duration:** 20 min (start 2026-11-15T23:35Z, end 23:55Z)
- **Execute-start SHA (`<start>`):** `e1eb452639d1dcb47324cb6831d92e69b6428e6d`
- **Tasks:** 3 (1 tracer, 2 auto)
- **Commits:** 3, measured by `git rev-list --count e1eb4526..HEAD` = 3 (the summary and state commits come after)
- **Files changed:** 20 (19 e2e specs, 1 demo ExUnit file), 224 insertions and 175 deletions
- **Tokens (chars/4 over the realized diff):** about 21,100 against the plan's 70,000 estimate (low confidence; about 3.3x high, the fourth plan in a row more than 3x high)

## Accomplishments

- **Words.** Every on-screen `Deliveries`, `Operator` and old denial sentence in a spec expectation, comment or test title now reads `Activity`, `Admin` and `... not authorized for this admin account.`; the status region and failed-read sentences follow Activity (`N emails match`, `No emails match the current filters`, `Couldn't load activity for these filters`); the demo empty states read `No activity in this time window` with `No emails have been recorded for this Account during the selected time window.`, `No activity matches the current filters` and `No activity on this page`; the Preview return link reads `Back to Activity`.
- **C-12.** The two `getByText("Operator", { exact: true })` count-0 assertions in the Preview topbar test are gone. The test now asserts `toHaveTitle(/Activity/)` on the Activity screen, `toHaveTitle(/Admin/)` on the Health overview and `toHaveTitle(/Inbound/)` on the Inbound list. Mutation: with `page_title(_view)` set back to `mailglass — Operator` the test fails with `Expected pattern: /Admin/`, `Received string: "mailglass — Operator • mailglass"`; the source was restored from a backup and `git diff -- mailglass_admin/lib mailglass_admin/priv` is empty.
- **Row badge.** The suppressed-row pin read `.badge-warning` "Suppressed"; it now reads the `not_sent` class mark "Not sent" with `Latest: Suppressed` beside it.
- **Mailer row.** Seven pins in `flows.spec.js` and the long-mailer test in `cohort.spec.js` moved from the old `#delivery-detail-mailable-trigger` and `#delivery-detail-mailable` to the Mailer row: the plain name "Transactional email with very long module name" as the help trigger (`#delivery-detail-mailer-trigger`), the full stored identity in `operator-detail-mailer-identity`, the hidden description `#delivery-detail-mailer` and the tooltip.
- **Lanes run.** Operator lane, Task 1: 135 passed, 1 skipped. Operator lane, Task 2: 137 passed. Demo navigation test: 9 passed. Demo browser suite: 111 expected, 0 unexpected, 0 flaky, 0 skipped, covering every edited demo spec (`cohort` 4, `delivery-investigation` 2, `demo` 5, `persona-screenshots` 68, `phase173-evidence` 5, `phase176-filters` 4, `quick-views` 8).

## Task Commits

1. **Task 1 (tracer):** `3360e2c3` test(admin): move operator and structural e2e pins to the brand words. Tracer gate: no `gate="blocking-human"`, auto mode off, `HUMAN_VERIFY_MODE` unset (end-of-phase) with an automated-only `<verify>`; the verify command was run end to end on the committed content (135 passed, exit 0, `priv/static` clean) and logged "Tracer verified end-to-end, expanding".
2. **Task 2:** `a4d7ca6e` test(admin): move the remaining admin e2e pins to the brand words.
3. **Task 3:** `d7c76421` test(demo): move demo e2e and navigation pins to the brand words.

## Lane results and pre-existing failures

No failure is left to attribute to an earlier commit: every lane ended green. The first runs were not: five advisory tests failed before they reached their pins (listed below). They were fixed in the spec rather than reproduced at the pre-182-04 sha (`3564297816c70e6d17339d9481888f8164bc9a3a`), so this summary does not claim they fail there; the cause of each is a named earlier commit.

| First-run failure | Cause | Fix |
|---|---|---|
| `structural.spec.js` per-state delivery cells: `.badge-warning` not found on the suppressed row | 182-02 (class badge): the row shows the `not_sent` mark and "Not sent" | pin the class mark and `Latest: Suppressed` |
| `flows.spec.js` Phase 168 Mailer wrapping and Phase 175 layout: `Copy Delivery ID` button not found | `11e909ed` (182-02) changed Technical details from `collapsible={false}` to `collapsible={true}` | `openTechnicalDetails/1` helper, called after every `selectDeliveryFull` that reads an identifier |
| `flows.spec.js` Phase 175 tracer: `#delivery-detail-technical` is `DETAILS`, not `DIV` | same commit | the pin says `DETAILS` |
| `phase169-journey.spec.js` 101st Event: two `time[data-local-time]`, expected one | `a604880c` (182-03) made the provider's own time a timestamp too | count 2, recorded time is the first |
| `flows.spec.js` 320 CSS px zoom: the text `Trace each delivery through its event history.` | 182-04 replaced that subtitle with the gloss | the pin reads `Every email your app sent, one row per delivery.` |

## Files Created/Modified

Admin e2e (`mailglass_admin/e2e/`): `operator`, `structural`, `flows`, `phase169-journey`, `phase170-journey`, `phase176-filters`, `phase177-account`, `phase177-health`, `phase178-real-zoom`, `admin-assets`, `judgment`, `axe-baseline` (`.spec.js`). Demo (`reference/demo_app/`): `assets/e2e/{cohort,delivery-investigation,demo,persona-screenshots,phase173-evidence,phase176-filters,quick-views}.spec.js` and `test/mailglass_demo_web/phase177_navigation_test.exs`. Nothing else.

## Evidence locations

- Demo evidence directory: `/Users/jon/projects/mailglass/reference/demo_app/tmp/demo_browser_evidence` (git-ignored by `reference/demo_app/.gitignore`; never staged). Report `playwright-report.json`, checkpoint `checkpoint.json` (status `passed`, candidate `a4d7ca6e`, dirty true because the demo specs were uncommitted while it ran). The run's compose project (`mailglass-evidence-20261115235059-32541-30162`) was torn down by the script's cleanup; no evidence container is left running.
- Operator lane logs and the mutation log live in the executor scratchpad, not the repository.

## Decisions Made

See `key-decisions`. In short: the title assertion follows the screen; drift that blocked a spec from its pins was fixed in the spec; the Mailer pins target the visible identity; Storybook sample labels stay and the demo spec reads them from source.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in plan] One `/Admin/` title on the operator state cannot hold**
- **Found during:** Task 1
- **Issue:** the plan asks for `toHaveTitle(/Admin/)` "on the operator state (`mailglass — Admin`, 182-04)". 182-04 made the document title follow the screen, so after `openOperator` (the Activity screen) the title is `mailglass — Activity`; `Admin` is the overview and mount default.
- **Fix:** Activity on the Activity screen, then `page.goto` to the Health overview and `toHaveTitle(/Admin/)`, then `toHaveTitle(/Inbound/)`. The acceptance greps (`toHaveTitle(/Admin/)` and `toHaveTitle(/Inbound/)` each present once, zero `getByText("Operator", { exact: true })`) hold.
- **Files:** `structural.spec.js`. **Commit:** `3360e2c3`

**2. [Rule 1 - Bug] The old row-badge pin**
- **Found during:** Task 1 verify (first run, 1 failure)
- **Fix:** see the table above. **Files:** `structural.spec.js`. **Commit:** `3360e2c3`

**3. [Rule 3 - Blocking] The Mailable row is gone, and the specs that pinned it could not reach their other pins**
- **Found during:** Task 2 reading `flows.spec.js`, then the demo `cohort.spec.js`
- **Issue:** 182-04 replaced the `Mailable` row of Technical details with the Mailer row (new ids); the long-value wrapping and zoom checks read the old trigger's shortened text.
- **Fix:** the pins target the Mailer row as described above; `overflowWrap` accepts `anywhere` or `break-word`. **Files:** `flows.spec.js`, `cohort.spec.js`. **Commits:** `a4d7ca6e`, `d7c76421`

**4. [Rule 3 - Blocking] Advisory drift from 182-02 and 182-03 stopped five tests short of their pins**
- **Fix:** the table above. The demo `cohort.spec.js` had the same collapsed-details drift (`summary` count 0, "non-collapsible section") and was fixed the same way. **Files:** `flows.spec.js`, `phase169-journey.spec.js`, `cohort.spec.js`. **Commits:** `a4d7ca6e`, `d7c76421`

**5. [Rule 2 - Missing] Two demo specs the plan did not list**
- **Issue:** `delivery-investigation.spec.js` and `quick-views.spec.js` pinned `No deliveries ...` headings and bodies (182-04's list named them); the plan's truth covers every demo e2e spec.
- **Fix:** moved with the others. **Commit:** `d7c76421`

**6. [Rule 1 - Bug in plan] A literal pin the plan's grep forbids but the product still shows**
- **Issue:** `persona-screenshots.spec.js` asserts the Storybook nav_link specimen text `Deliveries`, which comes from `reference/demo_app/storybook/primitives/nav_link.story.exs` (a sample label), not from an Admin screen. Editing the story is outside this plan (spec and test files only); keeping the literal fails the plan's own `Deliveries` grep.
- **Fix:** the three assertions read the label from the story source (`STORY_NAV_LABEL`); the Gallery nav assertion (an Admin screen) now reads `Activity`. The four stale story labels are in `deferred-items.md`. **Commit:** `d7c76421`

**Total deviations:** 6 (2 bugs in the plan text, 1 bug found by the lane, 2 blocking drifts, 1 missing site). **Impact on plan:** none on scope; every plan truth holds, and the advisory lanes are green rather than excused.

## Issues Encountered

- **Lane runs rewrite tracked, archived screenshots.** `structural.spec.js` (4 PNGs under the v2.9 phase 168 `review-fix` directory), `phase169-journey.spec.js` (20 PNGs under the v2.9 phase 169 `after` directory) and the demo evidence run (2 PNGs under the v2.9 phase 172 `browser-evidence` directory) overwrite them. They were restored with `git checkout -- <paths>` after each run and never staged; `git status --porcelain -- . ':!.planning/config.json'` is empty after the final commit (T-182-16). Logged in `deferred-items.md`.
- `Phase164RepositoryTruthTest` ("git runtime rules do not conceal the retired finalize-phase extension paths") still fails in a root core run because of the untracked `.gsd/.gitignore` (logged by 182-01). This plan did not run core.
- `reference/demo_app/mix.lock` was restored after the demo `mix test` run (`git checkout -- mix.lock`); it never appears in the diff.

## Known Stubs

None. These are test files; nothing renders an empty or placeholder value.

## Threat Flags

None. T-182-16: the evidence stayed in the git-ignored `reference/demo_app/tmp/demo_browser_evidence`, and the final `git status --porcelain` excluding the owner's `.planning/config.json` is empty. No route, `data-testid` or selector id was renamed (`git diff --name-only e1eb4526..HEAD` over `mailglass_admin/lib`, `mailglass_admin/priv`, `lib` and `reference/demo_app/lib` is empty); the spec selectors that changed point at ids 182-04 already shipped (`delivery-detail-mailer*`, `operator-detail-mailer*`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 182-06 owns the single axe run: `axe-baseline.spec.js` has its word pins and passes `node --check`, but was not run here (D-23).
- Verification at plan end: `bash scripts/check_test_exceptions.sh` "OK: test exception registry is complete and unexpired."; `phase178_prohibition_contract_test` (P7 scans every e2e spec), `bucket_a_coverage_test` (pins e2e titles) and `feedback_ledger_test` 75 tests, 0 failures; `node --check` over every admin and demo e2e file clean; demo `mix format --check-formatted` on the edited test clean. Core, admin lib and inbound are untouched, so their suites were not run.
- BRADM-03, BRADM-04 and BRADM-05 are copied above verbatim from the plan; this is the last plan declaring them.

## Self-Check: PASSED

All three task commits (`3360e2c3`, `a4d7ca6e`, `d7c76421`) are ancestors of HEAD; the 20 changed files exist; no uncommitted change outside the owner's `.planning/config.json`; the plan-scope diff over `mailglass_admin/lib`, `mailglass_admin/priv`, `lib` and `reference/demo_app/lib` is empty.

---
*Phase: 182-admin-words-and-layout-one-job-first*
*Completed: 2026-11-15*
