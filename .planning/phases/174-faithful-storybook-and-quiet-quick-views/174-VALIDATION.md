---
phase: "174"
slug: "faithful-storybook-and-quiet-quick-views"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 174 — Validation Strategy

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing ExUnit, Playwright Test and Admin's locked axe adapter |
| Config files | `mailglass_admin/playwright.config.cjs`, `reference/demo_app/assets/playwright.config.cjs` |
| Quick comparator | `cd mailglass_admin && mix test test/mailglass_admin/axe_baseline_test.exs` |
| Admin connected suite | `cd mailglass_admin && npm run test:operator-browser` |
| Demo connected suite | `bash scripts/run_demo_browser_evidence.sh` |
| Repository regression gate | `bash scripts/gsd-regression-gate.sh` |
| Runtime | Unmeasured; cold startup can exceed 30s. Execution must establish focused feedback time and cold/warm setup-inclusive costs. |

Commands are from repository root unless an explicit `cd` appears. Browser checks require working pinned Elixir/OTP, PostgreSQL or Docker, existing npm lockfile dependencies, and Chromium. Research did not run these suites; local asdf shims did not resolve an active Elixir version. Fix environment selection without upgrading the pinned clients. No new testing dependency is required.

## Sampling Rate

- After each task, run its focused automated check and name its failure signal.
- After each wave, run the affected connected Admin/Demo checks and evidence comparator.
- Before phase verification, run the repository regression gate plus the selected fresh browser sweep; inspect expected/executed counts and receipts.
- Keep fast comparator tests separate from service startup. Measure latency instead of claiming an unmeasured sub-30s feedback loop.

## Requirement Verification Map

The planner must replace the provisional rows with concrete plan/task IDs and exact focused commands as plans are written.

| Requirement | Test type | Automated command / assertion | Existing file | Status |
| --- | --- | --- | --- | --- |
| UXF-11 | Connected browser + geometry | Admin suite: both collections, normal/first/last positions, names, disabled behavior, keyboard/hover/focus, Close and >=44px boxes | `mailglass_admin/e2e/flows.spec.js`, `structural.spec.js`; new focused assertions needed | pending |
| STORY-03 | Route + connected browser | Demo suite: root/sidebar/theme-picker/direct entry preserve configured prefix and respond successfully | `reference/demo_app/assets/e2e/persona-screenshots.spec.js`; new prefix coverage needed | pending |
| STORY-04 | Network/font/computed-style receipt | Demo suite: source/revision/URL, CSS byte digest equality, successful font assets, matching loaded faces/weights and UI/display/code roles | Existing CSS receipt; font assertions missing | pending |
| STORY-05 | Connected browser | Demo suite: explicit Light/Dark and System under both OS schemes, including OS changes while System remains selected; theme owner recorded | New retained story checks needed | pending |
| STORY-06 | Connected browser on both pinned clients | Admin and Demo suites: shared production hook mount/update/close/focus return; Storybook owns exactly one socket | Existing Admin focus assertions; Demo connected story coverage missing | pending |
| UIQ-05 | Fresh axe producer + negative comparator tests | Browser sweep plus focused comparator: rule/target/state findings; missing/failed/zero/partial/stale execution fails; incomplete findings separately triaged | `mailglass_admin/e2e/axe-baseline.spec.js`, `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs` | pending |

## Wave 0 Requirements

- [ ] Name selected scenario IDs and their expected states before implementing the producer; normal/boundary production quick-view scenarios for both collections.
- [ ] Add missing targeted assertions within existing runners, with no new package or generic fixture platform.
- [ ] Select a working existing Admin axe dependency seam against Demo-hosted Storybook and prove it with one real scan before expansion.
- [ ] Add comparator negative fixtures for missing report, missing/failed scan, zero cases, incomplete expected set, stale identity and changed rule/target/state despite unchanged counts.
- [ ] Keep synthetic plain facts/builders separate from persistence materialization and check representative projection agreement where consumed.
- [ ] Update this map with finalized plan/task IDs and runnable focused commands; no nonexistent file may be treated as an already passing check.

## Evidence and Cost

Receipts identify source revision, actual URL, scenario/state, asset/font/theme ownership, selected and executed cases, failure disposition and evidence limits. Do not store customer HTML or PII. Approved axe findings are reviewed inputs; a fresh failing report cannot silently become the baseline. An incomplete axe result is distinct from incomplete execution.

Record cold and warm setup-inclusive wall time and runner-minutes for the initial selected sweep, including dependency/browser/service startup and expected/executed counts. Provisional added-PR budgets are <=5 wall minutes and <=10 runner-minutes, not measured guarantees. Current browser jobs sit outside protected `CI Green`; preserve gates and state actual required/advisory placement. Reconfirm live protection before any placement claim.

## Manual-Only Verifications

| Behavior | Why human review remains | Instructions |
| --- | --- | --- |
| Restrained arrow hierarchy with coherent position and Close | Automated class/color/geometry checks do not establish aesthetic approval | Inspect retained production renderings and real quick views in light/dark at representative narrow/wide/container widths, keyboard focus and reduced motion; pair review with objective browser assertions. |

All machine-observable acceptance requires automated evidence under D-52. Manual review does not substitute for network, computed-font, URL, focus, lifecycle or axe checks. Final real-zoom reconciliation remains Phase 178; preserve continuing obligations now.

## Validation Sign-Off

- [ ] Final plan/task map and focused commands recorded.
- [ ] Every task has automated verification or an explicit earlier test-creation dependency.
- [ ] No three consecutive tasks lack automated feedback; no watch commands.
- [ ] Failure-path tests prevent vacuous accessibility passes.
- [ ] Selected connected checks and initial cost pilot completed with honest CI disposition.
- [ ] `nyquist_compliant` and `wave_0_complete` updated only after supporting evidence.

**Approval:** Pending execution evidence; draft strategy only.
