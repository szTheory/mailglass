---
phase: "175"
slug: "delivery-investigation-and-safe-replay"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-27"
---

# Phase 175 — Validation Strategy

Executed validation map. Plans 175-01 through 175-05 retain their task summaries; Plan 175-06 adds current-source cold/warm receipts and closes the assigned requirement, edge and UI rows. Remaining Phase 178 ownership and descriptor-less flagged-unverified prohibitions are explicit.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing ExUnit, Phoenix LiveViewTest, Admin and demo Playwright |
| Config | `mailglass_admin/playwright.config.cjs`; `reference/demo_app/assets/playwright.config.cjs` |
| Quick run | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/auth_actions_contract_test.exs` |
| Focused components | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/components_test.exs test/mailglass_admin/inbound/components_test.exs` |
| Connected Admin | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 175"` |
| Persisted demo | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- --grep "outbound replay from the demo"` |
| Regression gate | `bash scripts/gsd-regression-gate.sh` |
| Runtime | Current-source P175 attributable incremental local wall: 42,290 ms (0.70483 min); hosted runner cost not observed; see 175-AUTOMATION.md |

Run commands from the repository root unless the command changes directory. Supply the existing test database/reset-token setup through the established browser harness; do not weaken auth or destructive-reset checks to make a test run. Preserve the existing demo replay grant and authorization-actions guard.

## Sampling Rate

- After each meaningful task: run its focused ExUnit/component or browser check.
- After a wave: run the affected domain tests and the selected connected checks.
- Before phase completion: run the existing regression gate and all phase acceptance checks against current source/assets.
- Each runnable command must fail on nonzero exit; selected browser runs also fail on zero expected cases, skips, or missing required evidence. Record expected/executed counts.
- Target focused feedback within 120 seconds; measure actual runtime before claiming this target is met. Keep long connected checks separate and bounded by existing harness timeouts.

## Requirement Verification Map

| Requirement | Required behavior | Boundary and existing test seam | Status | Current status and proof |
| --- | --- | --- | --- | --- |
| UXF-12 | Both full-detail pages expose grouped technical evidence without expansion, including long/missing values | Component + LiveView tests; connected DOM assertion in both domains | automated | automated — [technical evidence](175-AUTOMATION.md#technical-evidence-uxf-12) |
| OUTUX-07 | Real Account-scoped Refresh/Retry; ready/empty/stale/unavailable, external changes and expiry | Operator LiveView and scoped suppression read tests; connected action/state assertion | automated | automated — [suppression refresh](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| OUTUX-08 | Unknown expiry is not never; removal policy is explained without an invented mutation control | Suppression component/LiveView assertions and retained adverse-state story | automated | automated — [suppression policy](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| REPLAY-04 | Exact selected record can enter review from quick view or full detail in both domains | Both LiveView suites and selected connected flows preserving Account/filter/selection | automated | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-05 | Unavailable reason precedes dialog; stale/denied/changed selection never silently falls back | Existing stale/auth/revalidation server tests plus connected blocked-state assertions | automated | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06 | Identifiable request, shared concise shell, X named Close, Escape, trap and exact trigger return | Production component + Playwright keyboard/focus assertions in both entry surfaces/domains | automated | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-07 | Success closes dialog, announces accessible toast and refreshes actual new-work/no-change or distinct Inbound result | LiveView result assertions; existing persisted demo replay/audit E2E extended with toast | automated | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-08 | Failure stays visible in open dialog; safe retry/fresh review; duplicate/stale confirmation is safe | LiveView fault/auth seams plus connected error/re-review checks | automated | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| STORY-07 continuation | Complete early Delivery investigation/recovery path and relevant adverse states use production presentation | Existing scenario/manifest/projection tests, retained Storybook and connected job proof; final requirement remains Phase 178 | partial — final ownership in Phase 178 | automated — partial; [fidelity evidence](175-AUTOMATION.md#current-source-run-identity-and-coverage); final UIQ/STORY-07 ownership stays Phase 178 |

## Per-Task Verification Map

All plan tasks have retained automated execution records. Plan 175-06 current cold/warm receipts and the exact case inventory are indexed in 175-AUTOMATION.md. Existing infrastructure was reused; no framework/dependency Wave0 was required.

| Task | Wave | Automated command(s), from repository root | Required proof / Threat Ref | Status | Current status and proof |
| --- | --- | --- | --- | --- | --- |
| 175-01-01 | 1 | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 Delivery tracer"` | 175-01-01: Complete one scoped Delivery investigation and permitted replay / T-175-01–04 | automated | automated — [plan summary](175-01-SUMMARY.md) |
| 175-01-02 | 1 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/components_test.exs --only phase175 --trace` | 175-01-02: Expose exact Delivery quick-view replay and truthful unavailable states / T-175-01–02 | automated | automated — [plan summary](175-01-SUMMARY.md) |
| 175-02-01 | 2 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 suppression refresh"` | 175-02-01: Refresh one scoped suppression through failure and successful retry / T-175-05–06 | automated | automated — [plan summary](175-02-SUMMARY.md) |
| 175-02-02 | 2 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 suppression policy"` | 175-02-02: Explain expiry/removal and prove real changes remain scoped / T-175-05–07 | automated | automated — [plan summary](175-02-SUMMARY.md) |
| 175-03-01 | 2 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase175-inbound.spec.js --grep "Phase 175 Inbound full"` | 175-03-01: Complete and recover a recorded Inbound replay through the shared shell / T-175-08–11 | automated | automated — [plan summary](175-03-SUMMARY.md) |
| 175-03-02 | 2 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound/components_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase175-inbound.spec.js --grep "Phase 175 Inbound quick"` | 175-03-02: Expose Inbound quick replay and grouped full technical facts / T-175-08–10 | automated | automated — [plan summary](175-03-SUMMARY.md) |
| 175-03-03 | 2 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/components_test.exs test/mailglass_admin/inbound/components_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- structural.spec.js --grep "replay\ | Replay"` | 175-03-03: Reuse dialog presentation on Delivery and reconcile structural expectations / T-175-10 | automated | automated — [plan summary](175-03-SUMMARY.md) |
| 175-04-01 | 3 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 Delivery recovery\ | Phase 168 confirmation focus"` | 175-04-01: Recover a failed Delivery replay in the mounted dialog / T-175-12–15 | automated | automated — [plan summary](175-04-SUMMARY.md) |
| 175-04-02 | 3 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/auth_actions_contract_test.exs --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 Delivery safety"` | 175-04-02: Prove exact identity under stale, denied, duplicate and no-change outcomes / T-175-12–15 | automated | automated — [plan summary](175-04-SUMMARY.md) |
| 175-05-01 | 4 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/quick_view_projection_test.exs --only phase175 --trace`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- delivery-investigation.spec.js --grep "Phase 175 retained"` | 175-05-01: Retain the complete production Delivery job and reachable adverse cases / T-175-16 | automated | automated — [plan summary](175-05-SUMMARY.md) |
| 175-05-02 | 4 | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 175.*layout"`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- --grep "Phase 175 fidelity\ | Phase 175 retained"`<br>`ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:storybook-axe -- --grep "Phase 175"` | 175-05-02: Prove repaired rendering, keyboard and accessibility at real boundaries / T-175-17 | automated | automated — [plan summary](175-05-SUMMARY.md) |
| 175-06-01 | 5 | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- --grep "outbound replay from the demo"` | 175-06-01: Extend existing durable demo replay with accessible toast proof / T-175-03 | automated | automated — [current replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| 175-06-02 | 5 | `node --test scripts/check_phase175_evidence.test.cjs`<br>`bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot` | 175-06-02: Integrate scoped fail-closed evidence into existing lanes / T-175-18–20 | automated | automated — [current-source receipts](175-AUTOMATION.md#current-source-run-identity-and-coverage) |
| 175-06-03 | 5 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/auth_actions_contract_test.exs`<br>`node scripts/check_phase175_evidence.cjs --evidence-dir .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175 --pilot`<br>`bash scripts/gsd-regression-gate.sh` | 175-06-03: Close proved acceptance and publish reproduction/cost limits / T-175-18–20 | automated | automated — focused Admin/auth 353 tests, current retained receipt validates, and full regression gate passed; see 175-AUTOMATION.md |

## Wave 0 Requirements

Existing infrastructure covers the phase. No framework, dependency or generic fixture system is required. Add behavior assertions to existing suites in the same tasks that change behavior. New Phase 175 browser names must exist before filtered commands count as evidence. Preserve current successful replay E2E and the auth-actions contract guard.

## Security and Evidence

Test forged/cross-Account selection, stale exact target, access revoked between review and confirmation, duplicate submission/idempotent no-change, safe command/read failure and retained audit behavior. Share presentation, not Outbound/Inbound commands. Retain bounded escaped evidence and the existing sensitive-disclosure boundary.

Use Phase 174 CSS/font/theme/hook and fresh axe infrastructure for repaired surfaces. Cover normal/empty/long-Unicode content, relevant permission/failure states, light/dark/System, narrow widths, keyboard/focus, reduced motion and real 200% zoom. Stories prove rendering; connected tests prove actions, authorization and persistence. Record exact source, URL, asset identity, expected/executed counts and missing/failed evidence. Added cold/warm CI budgets remain provisional: at most five wall minutes and ten runner-minutes; measure before making a cost claim.

## Manual-Only Verifications

None planned. Follow `.planning/METHODOLOGY.md` D-52: machine-observable checks close their own acceptance rows. Missing wiring, layout review or an automation failure is engineering work, not an owner UAT checkpoint.

## Validation Sign-Off

- [x] Final task numbering and commands match all plans.
- [x] Every task has automated verification and a concrete failing direction.
- [x] No three consecutive tasks lack automated verification; the eight descriptor-less prohibition-recall flags remain explicitly `flagged-unverified`.
- [x] New selected cases exist and required execution counts are nonzero.
- [x] Security, persisted outcomes and full connected Delivery path have current evidence.
- [x] Feedback/runtime measurements recorded.
- [x] `nyquist_compliant` and `wave_0_complete` are set from execution evidence.

**Execution closeout:** The current-source combined cold/warm run, retained receipt checker, focused Admin/auth suite and existing regression gate passed. The existing hosted Demo Browser Evidence job remains advisory; no hosted CI run or hosted runner-minute cost is asserted. Axe incompletes remain separately triaged, and descriptor-less prohibition flags remain flagged-unverified.

**Review-fix closeout (2026-10-27):** WR-01 through WR-03 and the listed UI review repairs are recorded in [175-REVIEW-FIXES.md](175-REVIEW-FIXES.md). Fresh combined run `mailglass-evidence-20261027205816-4815-29177` passed cold/warm with source revision `fc262b989c1c38ab86376437ff2dc4b1ef4ea9a8`, Phase 175 digest `0700f87bb124f955131e20fd8f69fcf87c0a50a499aa636d954b49dc9400eedb`, and Phase 174 digest `7ee933bd225c6f8ae0ddf04aaa6edf2c4b07ebb99cf7cede21972e6e970897ae`. The checker suite now passes 6/6, and the regression gate passes Node 41/41, Core 81/81, Admin 661 tests (1 excluded), Inbound 480 tests (3 excluded), and browser 31/31. No owner UAT is required for these observable criteria under D-52.

## Final Source Coverage Audit

Source audit concerns planned coverage, not executed evidence. No CONTEXT.md was requested; the owner approved roadmap/requirements/research as authority. D-52 remains binding and is cited in task actions.

| SOURCE | ID | Scope item | Plan/tasks | Status |
| --- | --- | --- | --- | --- |
| GOAL |175 | Complete scoped Delivery investigation/recovery and equal Inbound replay quality |01–06 |COVERED |
| REQ |UXF-12 |Open full technical evidence in both domains |01-01,03-02,05-02 |COVERED |
| REQ |OUTUX-07 |Scoped refresh/retry, ready/empty/stale/unavailable, expiry/external change |02-01–02 |COVERED |
| REQ |OUTUX-08 |Unknown expiry and read-only removal policy language |02-02,05-01 |COVERED |
| REQ |REPLAY-04 |Exact quick/full entry in both domains |01-02,03-01–02,04-02 |COVERED |
| REQ |REPLAY-05 |Reason before unavailable dialog/no dead-end primary |01-02,03-02,04-02 |COVERED |
| REQ |REPLAY-06 |Shared concise accessible shell, identity, X/Escape/focus |01-01,03-01–03,05-02 |COVERED |
| REQ |REPLAY-07 |Actual result/toast/evidence, distinct domains |01-01,03-01,04-02,06-01 |COVERED |
| REQ |REPLAY-08 |Mounted inline error and safe fresh review |03-01,04-01–02 |COVERED |
| RESEARCH |Scope/ownership |Host LiveViews own params/read/auth/command; share presentation only |01,03,04 |COVERED |
| RESEARCH |Safety |Exact reread/snapshot/auth/idempotency/audit and bounded projections |01-02,03-01,04-02 |COVERED |
| RESEARCH |Suppression |Retained last-known facts separate from fresh read state; no mutation |02 |COVERED |
| RESEARCH |Composition |Early complete production-component Delivery job plus connected proof |01-01,05,06 |COVERED |
| RESEARCH |Reuse |Existing hooks/toast/test infrastructure and locked packages |01,03,05,06 |COVERED |
| RESEARCH |Safeguards |Keep completed demo grants/auth-actions guard/success E2E |01,04-02,06-01 |COVERED |
| RESEARCH |Evidence |Current-source expected/executed, assets/fonts/themes, widths/focus/zoom/motion, fresh axe |05-02,06 |COVERED |
| RESEARCH |Maintenance |Existing CI lanes, no weakened gates; measured incremental cold/warm limits |06-02–03 |COVERED |
| CONTEXT |Absent, approved |Proceed without new interview; approved scope and D-52 |all |COVERED |
| CONTEXT |D-52 |Automate machine-observable acceptance; zero owner UAT |01-01,05-02,06-03 |COVERED |

Exclusions: Phase176 auto-apply/ordinary addresses/Raw source, Phase177 Health/Account navigation, and Phase178 final STORY-07/UIQ reconciliation remain with their named owners. This phase supplies its complete early Delivery job and slice evidence now. No new external API/schema/provider/dependency is planned.

## Dependency, Ownership and Estimates

| Plan | Wave | Needs | Creates / user capability | Checkpoint |
| --- | --- | --- | --- | --- |
|175-01 |1 |174 shipped harness and current commands |Complete Delivery job, quick/full entry |none |
|175-02 |2 |175-01 selected job |Truthful scoped suppression refresh/policy |none |
|175-03 |2 |175-01 current presentation |Shared dialog, complete distinct Inbound review, open technical facts |none |
|175-04 |3 |175-02,175-03 |Mounted outbound failure recovery, adverse exact-target proof |none |
|175-05 |4 |175-04 (transitively02/03) |Retained full job/adverse scenarios, projection/fidelity/accessibility |none |
|175-06 |5 |175-05 |Durable demo toast proof, reproducible current evidence and CI/cost record |none |

Wave2 has no file overlap:02 owns OperatorLive/SuppressionCard/operator tests/flows;03 owns Components/Inbound/ReplayModal/component tests/structural/new Inbound spec. Later shared edits are sequential. Each task modifies at most5 explicit files. All decisions are reversible internal presentation/testing; no newly surfaced one-way decision/checkpoint. Calibration: factor1, sample_count0, confidence low. Raw and calibrated plan estimates are29k/19k/32k/24k/28k/25k tokens;14 tasks total.

Discovery: existing research and tracked pattern seams establish existing-stack work; no external dependency or architectural selection remains. Graphify is disabled; no semantic-graph assertion is claimed. Assumption detector matched “also”;175-01 records no-change existing scoped identities, with domain-specific commands preserved.

### Scope-warning disposition (revision1)

Both scope_sanity warnings are addressed by explicit per-task boundaries and context controls in the affected plans' scope_budget blocks.175-03 has six production presentation/host files plus five tests, with sequential5/5/3-file tasks and projected17k/10k/5k costs. Its final small task consumes the already-proved shell.175-06 has six executable/config files plus four evidence/doc/data files, with1/5/4-file tasks and projected3k/17k/5k costs; generated receipts are consumed by documentation closeout after the tested producer. Existing dependencies and disjoint Wave2 ownership remain unchanged. Both estimates include bounded reads/verification and keep calibration factor1, sample_count0, confidence low; they remain projections. Executors retain tested interface/case/source facts between tasks and avoid repeated broad source reads. No artificial split, scope reduction or human checkpoint was added.

The29 UI truth strings and corresponding29 table cells below have had a trailing Markdown delimiter removed; acceptance wording and mappings are unchanged.

## Deterministic Edge Acceptance Map

All31 provided edge strings are lifted verbatim to the plan frontmatter truths. Current status and proof-family anchors are added per row; exact selected/executed case IDs and source receipts are in 175-AUTOMATION.md.

| Requirement/category | Plan truth and task proof | Boundary | Current status and exact proof pointer |
| --- | --- | --- | --- |
| UXF-12/adjacency | 175-01 /01-01–02;05-02 | Tagged server/component and connected visible state | automated — [technical evidence](175-AUTOMATION.md#technical-evidence-uxf-12) |
| UXF-12/empty | 175-01 /01-01–02;05-02 | Tagged server/component and connected visible state | automated — [technical evidence](175-AUTOMATION.md#technical-evidence-uxf-12) |
| UXF-12/encoding | 175-01 /01-01–02;05-02 | Connected browser geometry/escaping/zoom plus component tests | automated — [technical evidence](175-AUTOMATION.md#technical-evidence-uxf-12) |
| UXF-12/ordering | 175-01 /01-01–02;05-02 | Tagged server/component and connected visible state | automated — [technical evidence](175-AUTOMATION.md#technical-evidence-uxf-12) |
| OUTUX-07/idempotency | 175-02 /02-01–02;04-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [suppression refresh](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| OUTUX-07/concurrency | 175-02 /02-01–02;04-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [suppression refresh](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| OUTUX-08/empty | 175-02 /02-01–02;05-02 | Tagged server/component and connected visible state | automated — [suppression policy](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| OUTUX-08/encoding | 175-02 /02-01–02;05-02 | Connected browser geometry/escaping/zoom plus component tests | automated — [suppression policy](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| OUTUX-08/idempotency | 175-02 /02-01–02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [suppression policy](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| OUTUX-08/concurrency | 175-02 /02-01–02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [suppression policy](175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08) |
| REPLAY-04/adjacency | 175-01 /01-02;03-02;04-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-04/empty | 175-01 /01-02;03-02;04-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-04/ordering | 175-01 /01-02;03-02;04-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-04/idempotency | 175-01 /01-02;03-02;04-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-04/concurrency | 175-01 /01-02;03-02;04-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-05/empty | 175-01 /01-02;04-02;05-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-05/encoding | 175-01 /01-02;04-02;05-02 | Connected browser geometry/escaping/zoom plus component tests | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-05/idempotency | 175-01 /01-02;04-02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-05/concurrency | 175-01 /01-02;04-02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06/adjacency | 175-03 /03-01–03;04-02;05-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06/empty | 175-03 /03-01–03;04-02;05-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06/encoding | 175-03 /03-01–03;04-02;05-02 | Connected browser geometry/escaping/zoom plus component tests | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06/ordering | 175-03 /03-01–03;04-02;05-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06/idempotency | 175-03 /03-01–03;04-02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-06/concurrency | 175-03 /03-01–03;04-02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-07/idempotency | 175-03 /01-01;03-01;04-02;06-01 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-07/concurrency | 175-03 /01-01;03-01;04-02;06-01 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-08/empty | 175-04 /04-01–02;05-02 | Tagged server/component and connected visible state | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-08/encoding | 175-04 /04-01–02;05-02 | Connected browser geometry/escaping/zoom plus component tests | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-08/idempotency | 175-04 /04-01–02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |
| REPLAY-08/concurrency | 175-04 /04-01–02;05-02 | Server exact-state/auth/domain effects, with selected connected controls | automated — [replay proof](175-AUTOMATION.md#replay-path-replay-04-through-replay-08) |

## UI Consideration Acceptance Map

All29 approved element/category acceptance strings remain independently mapped to their element. Current status and the predicate-specific proof matrix are linked per row in 175-AUTOMATION.md.

| UI predicate | Plan/task | Required proof | Current status and exact proof pointer |
| --- | --- | --- | --- |
| U1/empty |175-01/01-01–02;05-01 | Use the Copywriting Contract heading/body/action for each Delivery-list empty state; an empty suppression read retains Refresh and states Account-local scope; an absent replay identity cannot enable confirmation. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/loading |175-04/04-01;05-02 | Keep current content and focus stable during reads/navigation/review; show an in-flight control label and suppress duplicate confirmation until the result arrives. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/error |175-04/04-01 | Show the safe error and next action on the affected surface; replay errors remain inside the open dialog and suppression failure is stale with retained facts or unavailable without them. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/populated |175-01/01-01–02 | Keep selected Delivery primary facts and exact identity readable; expose technical groups and eligible review action through production components. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/partial |175-04/04-01;02-02 | Represent missing technical fields with existing bounded empty-value treatment; retained suppression facts after failure are stale and unknown expiry is explicitly not recorded. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/overflow |175-05/05-02 | Wrap bounded technical/request values without page horizontal overflow; dialog body scrolls with Close and primary action reachable while underlying page context is preserved. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/zero-one-many |175-01/01-02;05-01 | Zero/one/many list and evidence results retain truthful count, empty, selection and pagination states; ambiguous exact replay targets require deliberate choice. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U1/long-text |175-05/05-02 | Long Unicode labels, IDs and Mailbox identity wrap at narrow widths and real 200% zoom, keeping readable action labels and 44px controls. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U2/overflow |175-05/05-02 | Wrap bounded technical/request values without page horizontal overflow; dialog body scrolls with Close and primary action reachable while underlying page context is preserved. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U2/long-text |175-05/05-02 | Long Unicode labels, IDs and Mailbox identity wrap at narrow widths and real 200% zoom, keeping readable action labels and 44px controls. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/empty |175-02/02-01–02 | Use the Copywriting Contract heading/body/action for each Delivery-list empty state; an empty suppression read retains Refresh and states Account-local scope; an absent replay identity cannot enable confirmation. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/loading |175-02/02-01 | Keep current content and focus stable during reads/navigation/review; show an in-flight control label and suppress duplicate confirmation until the result arrives. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/error |175-02/02-01 | Show the safe error and next action on the affected surface; replay errors remain inside the open dialog and suppression failure is stale with retained facts or unavailable without them. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/populated |175-02/02-01 | Keep selected Delivery primary facts and exact identity readable; expose technical groups and eligible review action through production components. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/partial |175-02/02-02 | Represent missing technical fields with existing bounded empty-value treatment; retained suppression facts after failure are stale and unknown expiry is explicitly not recorded. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/overflow |175-05/05-02 | Wrap bounded technical/request values without page horizontal overflow; dialog body scrolls with Close and primary action reachable while underlying page context is preserved. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/zero-one-many |175-02/02-02;05-01 | Zero/one/many list and evidence results retain truthful count, empty, selection and pagination states; ambiguous exact replay targets require deliberate choice. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U3/long-text |175-05/05-02 | Long Unicode labels, IDs and Mailbox identity wrap at narrow widths and real 200% zoom, keeping readable action labels and 44px controls. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U4/loading |175-03/03-01 | Keep current content and focus stable during reads/navigation/review; show an in-flight control label and suppress duplicate confirmation until the result arrives. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U4/error |175-03/03-01 | Show the safe error and next action on the affected surface; replay errors remain inside the open dialog and suppression failure is stale with retained facts or unavailable without them. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U4/long-text |175-03/03-02;05-02 | Long Unicode labels, IDs and Mailbox identity wrap at narrow widths and real 200% zoom, keeping readable action labels and 44px controls. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U5/empty |175-04/04-02 | Use the Copywriting Contract heading/body/action for each Delivery-list empty state; an empty suppression read retains Refresh and states Account-local scope; an absent replay identity cannot enable confirmation. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U5/loading |175-03/03-01 | Keep current content and focus stable during reads/navigation/review; show an in-flight control label and suppress duplicate confirmation until the result arrives. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U5/error |175-03/03-01;04-01 | Show the safe error and next action on the affected surface; replay errors remain inside the open dialog and suppression failure is stale with retained facts or unavailable without them. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U5/partial |175-03/03-01 | Represent missing technical fields with existing bounded empty-value treatment; retained suppression facts after failure are stale and unknown expiry is explicitly not recorded. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U5/overflow |175-05/05-02 | Wrap bounded technical/request values without page horizontal overflow; dialog body scrolls with Close and primary action reachable while underlying page context is preserved. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U5/long-text |175-05/05-02 | Long Unicode labels, IDs and Mailbox identity wrap at narrow widths and real 200% zoom, keeping readable action labels and 44px controls. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U6/overflow |175-05/05-02 | Wrap bounded technical/request values without page horizontal overflow; dialog body scrolls with Close and primary action reachable while underlying page context is preserved. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |
| U6/long-text |175-05/05-02 | Long Unicode labels, IDs and Mailbox identity wrap at narrow widths and real 200% zoom, keeping readable action labels and 44px controls. | automated — predicate-specific case in [UI proof matrix](175-AUTOMATION.md#ui-acceptance-proof-matrix) |

## Descriptor-less Prohibition Recall (Flagged-Unverified)

The spec-less recall ran per exact requirement, then a precision pass dropped routine engineering and referred canonical injection/access/privacy concerns to the STRIDE/security review rather than minting duplicate prohibitions. Raw candidate groups are retained below; eight bespoke intent items survive, one per requirement. Each was projected through the installed `projectProhibitions` serializer into its owning plan's `must_haves.prohibitions`. Independent source and negative-path review upheld all eight as resolved/judgment; no wired-check descriptor was added because these are judgment-tier constraints. The autonomous result remains `unverified-prohibition — human review recommended`; no fabricated mechanical enforcement or automatic dismissal is claimed.

| Requirement | Raw recall candidates (~10, terse) | Precision outcome |
| --- | --- | --- |
|UXF-12 |provider-proof implication, wider raw disclosure, hidden group, wrong order, truncation, missing fields, XSS, copy mismatch, bad contrast, broken wrapping |keep evidence-authority intent; encoding/security canon referred; routine UI covered by edges |
|OUTUX-07 |global-clearance claim, stale-current claim, removed Refresh, phantom empty, scope leak, expiry ignored, duplicate read, stuck focus, unreadable state, wrong recipient |keep current/all-store transparency; auth canon referred; routine state handled in02 |
|OUTUX-08 |unknown-permanence claim, invented removal, coercive policy, wrong reason, malformed time, missing value, mutation leak, unreadable copy, jargon, stale policy |keep expiry/read-only policy honesty; routine mapping covered in02 |
|REPLAY-04 |resend framing, silent target replacement, scope bypass, neighbor default, duplicate ID, missing action, wrong trigger, stale selection, raw payload, broken route |keep exact recovery intent; auth/privacy canon referred; identity/navigation edges covered |
|REPLAY-05 |operator blame, bypass suggestion, dead-end action, hidden reason, wrong status, empty evidence, stale eligibility, implicit default, broken focus, raw error |keep non-coercive policy language; routine availability covered |
|REPLAY-06 |domain command conflation, resend consequence, raw request disclosure, hidden Close, broken Escape, focus leak, unlabeled confirm, clipping, long ID, missing Mailbox |keep distinct domain consequence; privacy/security canon referred; keyboard/layout covered |
|REPLAY-07 |invented Event, resent-mail claim, provider-delivery claim, wrong count, stale evidence, missing toast, no close, duplicate audit, lost context, raw result |keep actual-result transparency; routine result/audit/UI covered |
|REPLAY-08 |automatic retry pressure, success-like failure, concealed error, lost identity, stuck confirm, duplicate side effect, exception leak, auth bypass, flicker, stale retry |keep safe explicit recovery intent; auth/error canon referred; routine transitions covered |

Owning plans: UXF-12/REPLAY-04/05 →01; OUTUX-07/08 →02; REPLAY-06/07 →03; REPLAY-08 →04. All eight remain surfaced and descriptor-less as required by the fallback. Canon breadcrumb: injection, authorization bypass and general private-data disclosure are owned by the existing security controls/phase threat audit, not newly minted probe checks.

## Validation Audit 2026-10-27

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
