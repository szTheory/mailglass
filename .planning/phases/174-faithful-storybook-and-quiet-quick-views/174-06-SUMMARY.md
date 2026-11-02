---
phase: 174-faithful-storybook-and-quiet-quick-views
plan: "06"
subsystem: testing
tags: [playwright, phoenix-storybook, axe, github-actions, docker-compose, evidence]
requires:
  - phase: 174-01
    provides: Delivery quick view, Storybook route, and scenario evidence
  - phase: 174-02
    provides: Inbound quick view, scenario evidence, and projection checks
  - phase: 174-03
    provides: Shared Storybook hooks and connected client coverage
  - phase: 174-04
    provides: Story themes, production CSS/fonts, and responsive receipts
  - phase: 174-05
    provides: Selected Axe comparison and keyboard scroll access
provides:
  - Run-owned cold/warm browser evidence with exact source, scenario, case-count, and hosted-job identity
  - Fail-closed candidate CI artifact validation and independent full-job cost measurement
  - Current Phase 174 requirements, feedback dispositions, cost limits, and evidence boundaries
affects: [178]
actuals:
  tokens: 45938.5
  tasks: 2
  commits: 19
commits: 19
plan_head_before: 0d1f4953d0ccaaa1a5806dedb66b39301e180d6f
plan_head_after: 424d30b2e86754023c346ddf5218b5a8eaba38a0
tech-stack:
  added: []
  patterns:
    - Retain cold and warm runs in one isolated advisory Demo service with serial resets and one browser worker.
    - Validate hosted evidence against independent GitHub run/job REST metadata, exact source identity, steps, and job timestamps.
    - Compare added runner cost using a same-profile existing job while labelling the result observational.
key-files:
  created:
    - scripts/check_phase174_evidence.cjs
    - scripts/check_phase174_evidence.test.cjs
    - mailglass_admin/docs/phase174-review.md
    - reference/demo_app/assets/scripts/evidence-output-path.cjs
    - reference/demo_app/assets/scripts/evidence-output-path.test.cjs
  modified:
    - .github/workflows/ci.yml
    - scripts/run_demo_browser_evidence.sh
    - reference/persona_spec/quick_view_scenarios.json
    - reference/demo_app/assets/e2e/quick-views.spec.js
    - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
    - reference/demo_app/assets/e2e/storybook-hooks.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/playwright.config.cjs
    - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
    - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
    - .planning/publish/mailglass_admin-files.expected
key-decisions:
  - Keep the selected Phase 174 sweep in the existing advisory Demo Browser Evidence job; do not promote it to a protected required context.
  - Measure the full hosted job against a same-profile successful baseline; report the observed 14-second wall-budget overage without implying causality or critical-path latency.
  - Keep Axe violation approvals empty and retain incomplete findings as incomplete even when triage removes them from the untriaged count.
  - Keep Delivery's inert boundary and Inbound's native disabled-button boundary semantics distinct.
  - Leave non-Phase-174 feedback with its named Phase 175–178 owners; defer set-wide STORY-07 and zoom reconciliation to Phase 178.
requirements-completed: [UXF-11, STORY-03, STORY-04, STORY-05, STORY-06, UIQ-05]
coverage:
  - id: D1
    description: Cold and warm hosted evidence exercises all selected Demo, hook, fidelity, and Axe cases.
    requirement: UIQ-05
    verification:
      - kind: e2e
        ref: "CI 40498413906, head 18c6cf32; --require-ci checker: cold 148/148, warm 148/148, Axe 18/18 each"
        status: pass
    human_judgment: false
    rationale: "2026-10-27 closure adds passing supplemental contrast/focus checks; 50 axe incomplete outcomes remain separate. Current local receipts are under artifacts/automated-uat; the hosted reference remains historical."
  - id: D2
    description: Delivery and Inbound quick views retain quiet, keyboard-usable navigation and truthful boundaries.
    requirement: UXF-11
    verification:
      - kind: e2e
        ref: "CI 40498413906; qv-delivery-* and qv-inbound-* selected scenarios plus connected quick-view cases"
        status: pass
    human_judgment: false
  - id: D3
    description: Storybook root, sidebar, Theme Picker, selected production stories, and prefixed assets resolve.
    requirement: STORY-03
    verification:
      - kind: e2e
        ref: "CI 40498413906; selected persona-screenshots.spec.js and quick-views.spec.js cases"
        status: pass
    human_judgment: false
  - id: D4
    description: Production CSS/fonts, responsive widths, and story-owned Light/Dark/System behavior match connected production.
    requirement: STORY-04
    verification:
      - kind: e2e
        ref: "CI 40498413906; phase174/fidelity.json, 20 responsive cases, and 12 loaded font receipts"
        status: pass
    human_judgment: false
  - id: D5
    description: Both quick-view stories own Light/Dark/System behavior and respond to live OS preference changes.
    requirement: STORY-05
    verification:
      - kind: e2e
        ref: "CI 40498413906; theme cases in phase174/fidelity.json"
        status: pass
    human_judgment: false
  - id: D6
    description: Storybook and connected Demo/Admin clients retain their own hook lifecycle and focus behavior.
    requirement: STORY-06
    verification:
      - kind: e2e
        ref: "CI 40498413906; phase174/hooks.json and Operator Browser Gate job 122170443965"
        status: pass
    human_judgment: false
  - id: D7
    description: Current-source review records a bounded visual judgment and all known evidence limits.
    verification:
      - kind: automated_ui
        ref: "174-AUTOMATION.md; artifacts/automated-uat/phase174/{cold,warm}/fidelity.json; current agent captures; mailglass_admin/docs/phase174-review.md"
        status: pass
    human_judgment: false
    rationale: "D-52 authorizes bounded agent review plus deterministic layout assertions; 174-AUTOMATION.md records current captures and limits. No owner approval, aesthetic score or all-browser/zoom claim."
metrics:
  duration: 5h32m
  completed: 2026-10-27
  files: 32
status: complete
---

# Phase 174 Plan 06: Cold/Warm Browser Evidence and Current-Source Review Summary

**The selected Demo and Admin browser evidence now has exact cold/warm hosted proof, a fail-closed CI artifact checker, and measured full-job cost against the existing advisory lane.**

## Performance

- **Duration:** 5h32m from the first Plan 174-06 task commit to the final Task 2 documentation commit; includes the repaired-source review and final hosted proof.
- **Completed:** 2026-10-27
- **Tasks:** 2
- **Plan files changed:** 32 (measured from the task-commit path list, including the guide and bounded audit appendices).
- **Task commits:** 14. The persisted plan ledger measures 19 commits since its recorded base, including interleaved metadata and audit commits; the final summary commit is excluded.

## Accomplishments

- Added --phase174 --pilot to the existing Demo Browser Evidence path. It runs a cold and warm selected sweep serially against one isolated run-owned Demo/Postgres project, keeps one Playwright worker and the run's browser caches, performs authenticated resets, and cleans only that project's services and volumes.
- Added execution, cost, fidelity, hooks, and Axe receipts with exact expected/executed IDs and candidate source digest. The final checker validates local evidence separately from actual hosted evidence and requires independent GitHub run/job metadata under --require-ci.
- Routed the Admin-owned Axe scan through Admin's locked Playwright 1.59.1 / Chromium 1217 while preserving Demo's separate Playwright 1.60.0 / Chromium 1223 installation. The ordinary Operator Browser Gate excludes only the Storybook-only Axe spec; the dedicated Axe config and scan remain intact.
- Recorded the successful candidate run, independent job metadata, complete cold/warm counts, full hosted job timing, same-profile baseline, feedback ownership, and evidence limits in mailglass_admin/docs/phase174-review.md.

## Hosted Evidence and Verification

After the three source-review findings were repaired, the exact candidate was `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5` on `gsd/phase-174-evidence`. GitHub Actions run [40498413906](https://github.com/szTheory/mailglass/actions/runs/40498413906), attempt 1, completed/success at `2026-10-27T12:02:39Z`; all 26 jobs succeeded. The Demo Browser Evidence job [122170444350](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170444350), Operator Browser Gate [122170443965](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170443965), and Preview Capture Advisory [122170443973](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170443973) passed.

The exact downloaded artifact and independent metadata are retained in `reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1/`. The original artifact cost is preserved as `phase174/cost.downloaded.json`; enriched `phase174/cost.json`, `ci-job.json`, `github-run.raw.json`, and `github-jobs.raw.json` retain actual timestamps and runner identity.

The final strict hosted check passed:

~~~sh
node scripts/check_phase174_evidence.cjs --evidence-dir reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1 --pilot --require-ci
~~~

Result: `valid: true`; exact source revision and digest match; each cold/warm condition is 148/148 (98 Demo, 6 hooks, 26 fidelity, 18 Axe). Each Axe comparison is 18/18 successful with zero violations, zero unapproved violations, zero untriaged findings, and 50 incomplete findings retained.

The source receipt contains 57 input paths with digest `21542c6a5e3a10a8d6334b902c9cbfbecde06e210aca8ae9c333cbe3054ed1c2`; its method is `sha256(sorted(path\0byte_length\0file_sha256\n))`. Both conditions use the same run identity. Demo Playwright 1.60.0 / Chromium 1223 and Admin Playwright 1.59.1 / Chromium 1217 both missed cache cold and hit warm. Admin install lookup took 9,248 ms cold / 415 ms warm; Demo took 11,390 ms / 1,046 ms. The run-owned Compose project was `mailglass-evidence-40498413906-1`; warm teardown took 11,716 ms.

The earlier successful sample run `40491221303` on `fbf7d791` remains historical pre-review evidence and is superseded for current-source proof. The first post-review run `40496672358` had a successful Demo evidence job, but the separate Preview Capture Advisory job failed its 90-iteration readiness window at `11:34:55Z` while the cold server was compiling/seeding at `stage=sandbox_owner_started`; the runner log also records a PostgreSQL `role "root" does not exist` connection. The workflow was cancelled after the unchanged-candidate retry was queued. Its artifact, pre-dispatch and final run/job metadata, failed Preview job metadata, and log are preserved in `ci/40496672358-attempt-1/`. No timeout, checker, or gate was changed.

## Cost and Advisory Placement

| Measurement | Result |
| --- | --- |
| Cold condition | 354,054 ms wall: 193,263 ms setup, 156,798 ms execution |
| Warm condition | 157,923 ms wall: 2,972 ms setup, 152,708 ms execution, 11,716 ms final cleanup |
| Setup-inclusive pilot | 524,496 ms wall (8m44.496s) |
| Same-profile baseline | Run 40414024714, head e326da4d, successful Demo job 121891818059 on ubuntu-latest: 221,000 ms (3m41s) |
| Candidate full hosted job | 535,000 ms (8m55s; one runner; 8.917 runner minutes) |
| Observed added delta | +314,000 ms (5m14s wall; 5.233 runner minutes) |
| Provisional budgets | Wall exceeds the 5-minute limit by 14 seconds; runner use is within 10 minutes by 4.767 minutes |

The delta is an observational same-job comparison with one successful baseline sample; it includes runner and setup variance and is not a causal estimate or a CI critical-path guarantee. The full job timestamps define runner cost; scan-only times are not substituted.

The live `main` branch protection query remains strict with required contexts `CI Green` and `Guard Release Trigger`. Demo Browser Evidence remains advisory and is not a dependency of `CI Green`; no protected context or aggregate policy changed.

Recommendation: keep this pilot integrated into the existing advisory Demo Browser Evidence job rather than add a second lane. One lane shares checkout, the isolated service, and cold/warm caches while retaining all 148 cases in both conditions. Re-measure the 14-second wall overage before considering any scope adjustment; preserve every acceptance case, both Phase 174 conditions, and the current required gates.

## Requirement and Feedback Disposition

| Requirement | Evidence and disposition |
| --- | --- |
| UXF-11 | Connected Delivery/Inbound cases and the selected scenario families pass. Enabled controls remain named and at least 44px. Delivery unavailable navigation is an inert span; Inbound unavailable navigation is a native disabled button. |
| STORY-03 | Selected Storybook root, sidebar, Theme Picker, quick-view routes, and prefixed assets resolve below /dev/storybook. |
| STORY-04 | Production CSS and six font faces match; 20 selected responsive cases cover 320, 375, 768, 1280 and 1440px in both themes. |
| STORY-05 | Both stories own Light/Dark/System selection; live OS changes are checked without persisting the host preference. |
| STORY-06 | Storybook iframe lifecycle and connected Demo focus behavior pass; the Admin client passes the independent Operator Browser Gate. |
| UIQ-05 | Exact 18-case Axe set runs in both conditions. Zero violations/unapproved/untriaged results do not make 50 incomplete findings per condition passes. |

The production scenario manifest preserves pure-to-persisted boundaries: persisted projection checks cover qv-delivery-single-unicode, qv-inbound-normal, and qv-inbound-single-unicode; other selected story states are rendering-only; real empty Delivery and Inbound are connected-route-only. No empty record was fabricated.

fb-quiet-quick-view-arrows is resolved against connected evidence and the exact scenarios. fb-storybook-fidelity remains partial: current receipts cover routes, assets, themes, fonts, hooks, connected interactions, and Axe; STORY-07 set-wide reconciliation, serif StatCard/catalogue work and real zoom remain with Phase 178. Feedback rows for suppression/replay/technical details remain assigned to Phase 175, filters/raw-source/address work to Phase 176, Health/Account context to Phase 177, and Preview reset/identity to Phase 178.

## Visual Review and Evidence Limits

The bounded review inspected the current candidate's Delivery Light/Dark, 320px Delivery boundary, and wide Inbound boundary captures. Subject, outcome, recipient, timestamp, Account/provider and technical identity retain a clear hierarchy. Narrow text wraps and continues vertically without visible horizontal spill. The Storybook review-theme selector crowds the top of its own narrow chrome. This is qualitative inspection of selected Chromium captures, not an aesthetic score or cross-browser/device/zoom claim.

Fifty incomplete Axe findings remain machine-incomplete and retained for interpretation; no violation fingerprint is approved. The descriptorless transparency prohibition remains flagged-unverified and this plan makes no owner-approval claim. Real browser zoom and final STORY-07 reconciliation remain Phase 178 work. Focus, reduced motion, width, theme, hook, keyboard and connected interaction proof for this repair is current.

No new public endpoint, authentication path, persistence schema, or dependency was introduced. Run-owned reset/cleanup and artifact identity stay within T-174-16/17/18 and the existing lockfile/pinned-action supply-chain boundary.

## Task Commits

1. **Task 1: Run complete selected evidence in the existing advisory browser lane** — `a06a311b`, `d01f1b63`, `b0ea5986`, `1b4ace7a`, `95fe9b92`, `be87c9c6`, `e7553eee`, `bc52eac7`, `79f24834`, `d46e7e37`, `fbf7d791`.
2. **Task 1: Close reviewed evidence and focus gaps** — `18c6cf32`.
3. **Task 2: Record the cold/warm pilot and current-source review disposition** — `86a04b6b` (initial pre-review sample), `424d30b2` (current-source proof and audit refresh).

## Post-Review Repair

The phase code review found a symlink-parent escape in evidence paths, missing full-detail focus ownership in Inbound, and omitted route/story bytes in the local source digest. All three were repaired in `18c6cf32` with 24 passing Node checks and 3 passing connected operator cases; the focused independent `174-REVIEW-FIX.md` reports clean. Prior retained evidence is archived instead of recursively deleted, symlink components are rejected before writing, and checkpoint writes use no-follow flags. Inbound full detail now focuses its stable back link and returning focuses Quick view Close. Route, story `.exs`, fixture, asset and Admin flow bytes are explicitly included in source identity. The final exact-candidate proof is run `40498413906` and passes all 26 jobs plus the strict current-source evidence check. The first post-review attempt `40496672358` is retained as a failed readiness attempt followed by cancellation; its evidence and log are not presented as a successful workflow.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Made the hosted disposable evidence path respect run ownership and the Linux file boundary**
- **Found during:** Task 1 hosted setup and artifact handoff.
- **Issue:** Earlier attempts exposed reset identity/trust assumptions and a private-file permission failure when a Linux container handed receipts to the host.
- **Fix:** Use actual run-owned reset/project identities, process-scoped Git trust, bounded iframe readiness, and the established host-owned private-file handoff; validate cleanup and status preservation in a disposable image.
- **Files modified:** scripts/run_demo_browser_evidence.sh, Demo evidence scripts/controllers/tests, .github/workflows/ci.yml.
- **Verification:** Earlier run 40491221303 passed before the source-review repairs; exact current-source run 40498413906 and the independent `--require-ci` checker now pass.
- **Committed in:** 79f24834, d46e7e37.

**2. [Rule 3 - Blocking issue] Updated the package allowlist and in-progress CI timing contract**
- **Found during:** Task 1 package preflight and hosted checker tests.
- **Issue:** New Admin-owned assets were missing from the package allowlist, and the hosted producer needed to validate its measured producer timing before GitHub exposed completed job timing.
- **Fix:** Add only the required Admin asset paths and separate wrapper condition timing from independently fetched completed-job timing.
- **Files modified:** .planning/publish/mailglass_admin-files.expected, scripts/check_phase174_evidence.cjs, scripts/check_phase174_evidence.test.cjs.
- **Verification:** Full CI passed and final --require-ci check matched the completed job timestamps.
- **Committed in:** 95fe9b92, e7553eee.

**3. [Rule 1 - Bug] Kept the dedicated Storybook Axe scan out of the Operator Browser Gate**
- **Found during:** Task 1 candidate workflow run 40488505137.
- **Issue:** The default Playwright discovery also ran the Admin-only 18-case Axe spec without its required identity; a stale Delivery boundary assertion also expected the old button behavior.
- **Fix:** Exclude only the dedicated Storybook Axe spec from default discovery, leave its separate config unchanged, and assert Delivery's inert span boundary and target geometry.
- **Files modified:** mailglass_admin/playwright.config.cjs, mailglass_admin/e2e/flows.spec.js, related browser tests.
- **Verification:** Three focused cases passed; current CI run 40498413906 passed the Operator Browser Gate and dedicated Demo evidence lane.
- **Committed in:** fbf7d791.

**4. [Rule 1 / Rule 2 - Bug and security] Closed the three source-review findings**
- **Found during:** Post-task source review recorded in `174-REVIEW.md`.
- **Issue:** Evidence output paths could follow symlink parents, Inbound full-detail focus did not move to the newly visible view, and the source digest omitted changed route/story files.
- **Fix:** Reject symlink components before writes, preserve existing retained captures, use no-follow checkpoint writes, focus the stable Inbound back link and returned Quick view control, and hash the missing route/story inputs.
- **Files modified:** `reference/demo_app/assets/scripts/evidence-output-path.cjs`, its tests, Demo evidence checker/tests, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, Admin browser flow, phase174 checker/tests, and wrapper.
- **Verification:** 24 focused Node checks, 3 connected browser cases, independent clean review in `174-REVIEW-FIX.md`, and exact-candidate run 40498413906 with strict hosted checker passed.
- **Committed in:** `18c6cf32`.

**Total deviations:** 4 auto-fixed entries: two Rule 3 blockers, one Rule 1 bug, and one source-review entry covering a Rule 1 bug plus a Rule 2 security fix. No new dependency, required context, release action, or scope expansion was introduced.

## Issues Encountered

Earlier hosted attempts 40484284465 and 40486544710 exposed guard/Git trust and Linux permission failures; 40488505137 exposed incorrect Playwright lane discovery. The successful pre-review sample 40491221303 is retained as historical proof for `fbf7d791`, not as proof of the repaired source. Post-review run 40496672358 failed only its separate Preview Capture Advisory readiness window while the cold server was compiling/seeding; its Demo artifact and raw failure metadata/log were preserved, then the ineligible workflow was cancelled after the exact-candidate retry was queued. The unchanged candidate succeeded in run 40498413906. No CI timeout, checker, or gate policy changed.

## User Setup Required

None.

## Next Phase Readiness

Plan 174-06 completes its six assigned requirements and supplies current evidence to the phase-level verifier. Phase-level status remains `verifying` for the parent-owned verifier and transition. Phase 178 still owns STORY-07 reconciliation, real zoom, and the remaining Preview feedback. No merge, release, publication, or deployment was performed or authorized.

## Self-Check: PASSED

- Summary, checker, checker tests, review guide, validation audit, and security audit exist.
- All 14 listed task commits are reachable from HEAD.
- git diff --check passed.

---
*Phase: 174-faithful-storybook-and-quiet-quick-views*
*Completed: 2026-10-27*


## Final Cost Receipt Reconciliation

The enriched `ci/40498413906-attempt-1/phase174/cost.json` now records `added_cost.status: measured` for the **observed** same-profile job comparison, the retained baseline/current raw metadata, +314,000ms / 5.233 runner-minute delta, and the explicit wall-over-by-14s / runner-within-budget disposition. This does not claim causal incremental PR cost. `cost.downloaded.json` remains byte-for-byte original; `cost.before-baseline.json` preserves the intermediate hosted-only enrichment. `cost-baseline-enrichment.json` records the input hashes; `174-COST-DISPOSITION.json` in the phase directory retains the derived disposition/provenance. The strict hosted checker passed again after reconciliation. No execution identity, browser result or measured condition timing changed.


## Automated UAT Reconciliation — 2026-10-27

D-52 was reaffirmed by the owner. Former human-judgment flags in coverage are now closed by scoped agent review and executable layout, contrast, keyboard and evidence-authority checks. Historical execution and commit-window facts above are preserved; 174-AUTOMATION.md and the replayable artifacts/automated-uat receipts describe the current repairs. No owner approval or new hosted success is inferred.
