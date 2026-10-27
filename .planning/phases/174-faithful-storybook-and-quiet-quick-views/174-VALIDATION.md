---
phase: "174"
slug: "faithful-storybook-and-quiet-quick-views"
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| Runtime | Cold/warm hosted condition wall: 355.489s / 158.321s; full job 536s. Pure Node checks remain separate from startup. |

Commands are from repository root unless an explicit `cd` appears. Browser checks require working pinned Elixir/OTP, PostgreSQL or Docker, existing npm lockfile dependencies, and Chromium. Execution selected the existing asdf OTP 27.3.4.13 / Elixir 1.18.4-otp-27 pins and the existing locked browser clients. No new testing dependency is required.

## Sampling Rate

- After each task, run its focused automated check and name its failure signal.
- After each wave, run the affected connected Admin/Demo checks and evidence comparator.
- Before phase verification, run the repository regression gate plus the selected fresh browser sweep; inspect expected/executed counts and receipts.
- Keep fast comparator tests separate from service startup. Measure latency instead of claiming an unmeasured sub-30s feedback loop.

## Requirement Verification Map

The following commands now target implemented checks. All six requirements are covered by passing focused tests and candidate CI 40491221303; the strict downloaded-artifact checker was rerun successfully during this audit. Admin/Demo commands use their tracked Playwright configs and existing locked dependencies; service startup may exceed 60s, while the pure Node comparator tests supply fast feedback. The inherited prior_verify_commands list was empty.

| Requirement | Test type | Automated command / assertion | Plan/task | Status |
| --- | --- | --- | --- | --- |
| UXF-11 | Connected + geometry | `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js --grep "Phase174 tracer\|Phase174 delivery\|Phase174 inbound"` | 174-01 tasks 1/2; 174-02 task 1 | COVERED — CI 40491221303 |
| STORY-03 | Generated navigation | `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js --grep "Phase174 tracer"` | 174-01 task 1 | COVERED — CI 40491221303 |
| STORY-04 | Asset/font/computed receipt | `npm --prefix reference/demo_app/assets run test:e2e -- storybook-fidelity.spec.js --grep "Phase174 fonts\|Phase174 widths"` | 174-04 task 2 | COVERED — CI 40491221303 |
| STORY-05 | Live OS/theme response | `npm --prefix reference/demo_app/assets run test:e2e -- storybook-fidelity.spec.js --grep "Phase174 themes"` | 174-04 task 1 | COVERED — CI 40491221303 |
| STORY-06 | Both clients + Storybook ownership | `npm --prefix reference/demo_app/assets run test:e2e -- storybook-hooks.spec.js --grep "Phase174 hooks"`; `npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase174 client hooks"` | 174-03 tasks 1/2 | COVERED — CI 40491221303 |
| UIQ-05 | Fresh producer + fail-closed comparator | `node --test mailglass_admin/e2e/support/storybook-axe.test.cjs`; `npm --prefix mailglass_admin run test:storybook-axe -- --grep "Phase174 selected axe"` | 174-05 tasks 1/2/3 | COVERED — CI 40491221303 |

Every command fails on nonzero exit or zero selected tests; detailed immediate `<fails_when>` siblings in the plans define missing/partial/stale/incorrect evidence signals. The axe command requires healthy STORYBOOK_BASE_URL and independent STORYBOOK_AXE_RUN_ID/STORYBOOK_SOURCE_REVISION/STORYBOOK_SOURCE_DIGEST; plan 06 provides them in the isolated wrapper. It must not silently default to an unrelated retained service.

Additional exact commands: `cd mailglass_admin && mix test test/mailglass_admin/quick_view_projection_test.exs` (174-02/2); `cd mailglass_admin && mix test test/mailglass_admin/assets_test.exs` (174-03/1); `cd mailglass_admin && mix mailglass_admin.assets.build && test -s priv/static/app.css` (174-04/2); `node --test scripts/check_phase174_evidence.test.cjs` (174-06/1); `bash scripts/run_demo_browser_evidence.sh --phase174` (174-06/1); `node scripts/check_phase174_evidence.cjs --evidence-dir "$PHASE174_CI_EVIDENCE_DIR" --pilot --require-ci`, `bash scripts/gsd-regression-gate.sh`, and `cd mailglass_admin && mix test test/mailglass_admin/axe_baseline_test.exs` (174-06/2). Nonzero exit, absent expected summary/artifact or zero expected execution fails each; pilot additionally requires cold and warm setup-inclusive cost records.

## Plan dependency and creation map

| Wave | Plan | Needs | Creates/changes | Checkpoints |
|---|---|---|---|---|
| 1 | 174-01 | Existing production Delivery, pinned Storybook | Visible tracer, full prefix mount, Delivery story/spec, pure facts and small manifest/dispositions | none |
| 2 | 174-02 | 174-01 facts/story seam | Quiet Inbound, retained cases, representative persisted projection test | none |
| 2 | 174-03 | 174-01 routed review | Shared hook-only production source, Demo registration, both-client lifecycle proof | none |
| 3 | 174-04 | 174-02/03 retained surfaces/hooks | Local Demo theme adapter and font/CSS/theme/width receipts | none |
| 4 | 174-05 | 174-04 faithful renderings | Admin-targeted Demo axe runner, exact 18-case manifest/comparator and scoped production scroll-focus remediation | Conditional blocking decision only if fresh intentional residual debt exists |
| 5 | 174-06 | 174-05 complete comparison | Existing advisory CI integration, run-owned complete receipts, cold/warm pilot and review note | none |

Wave 2 file ownership is disjoint. Shared source/manifest/backend edits in later waves have explicit dependencies. All newly named paths/symbols/flags are declared in each plan's “Artifacts this phase produces” section. No source changes or runtime suite execution occurred during planning. Calibration: factor 1, sample_count 0, confidence low; estimates are uncalibrated raw projections.

## Multi-source coverage audit

| Source | Item | Plan(s) | Status |
|---|---|---|---|
| GOAL | Restrained both-collection quick views plus faithful navigable Storybook and fresh accessibility | 01–06 | COVERED |
| REQ | UXF-11 | 01,02,06 | COVERED |
| REQ | STORY-03 | 01,02,06 | COVERED |
| REQ | STORY-04 | 04,06 | COVERED |
| REQ | STORY-05 | 04,06 | COVERED |
| REQ | STORY-06 | 03,06 | COVERED |
| REQ | UIQ-05 | 05,06 | COVERED |
| RESEARCH | Root-scope full pinned mount, matching assets, browser/dev protections | 01 | COVERED |
| RESEARCH | Both production components, distinct disabled semantics, actual 44px geometry, focus/URL/Account | 01,02,03 | COVERED |
| RESEARCH | Source/build distinction, built/served parity, six successful font byte/face/weight/role receipts | 04 | COVERED |
| RESEARCH | Explicit System owner, both OS branches and live change | 04 | COVERED |
| RESEARCH | Shared production hooks, no duplicate bootstrap, both pinned clients, connected lifecycle | 03 | COVERED |
| RESEARCH | Existing Admin axe dependency scans external Demo without Demo dependency | 05,06 | COVERED |
| RESEARCH | Rule/target/scenario-state, independent approvals, nonempty expected/executed integrity, incomplete triage; known focusability defect reproduced/repaired/rescanned | 05 tasks 1–3 | COVERED |
| RESEARCH | Actual advisory disposition and initial setup-inclusive cold/warm pilot | 06 | COVERED |
| CONTEXT | No CONTEXT supplied: owner selected approved requirements/research; no inferred D-number decisions | all | COVERED |
| CONTINUING | Source dispositions/scenario IDs, pure/materializer separation and representative projection agreement start now | 01,02,06 | COVERED |
| CONTINUING | D-09 Account isolation, D-19 brand, D-41/D-45 gate integrity, D-52 automated acceptance | 01–06 | COVERED |
| EXCLUDED | Later replay/filter/Health/Preview repairs, real-zoom/final milestone reconciliation, broad catalogue/API/service growth | named owners 175–178 or deferred | outside phase; visible in manifest |

## Spec-less fallback and flagged assumptions

Original edge report: seven surfaced rows, zero initially resolved. Accounting below retains all seven (three partially/explicitly constrained and four unclassified assumptions); it does not auto-dismiss any row.

| Edge | Disposition in plans | Remaining flagged assumption |
|---|---|---|
| UXF-11 empty | Explicit truth in 01: no invented selected item, one-item both boundaries unavailable, nil position omitted; 01/02 connected checks | No new policy for impossible/null collection internals is inferred |
| UXF-11 encoding | Exact long/Unicode rendering checks in 01/02; exact values preserved | UNRESOLVED: requirement does not define Unicode equality/normalization or length metric; no new truncation/equality contract is introduced |
| STORY-03 unclassified | Prefix navigation tests implement approved acceptance | UNRESOLVED unclassified probe; not claimed auto-resolved |
| STORY-04 unclassified | Font/asset/role receipts implement approved acceptance | UNRESOLVED unclassified probe; not claimed auto-resolved |
| STORY-05 unclassified | Explicit owner plus OS flips implement approved acceptance | UNRESOLVED unclassified probe; not claimed auto-resolved |
| STORY-06 concurrency | Explicit 03 truth/tests: repeated/reconnect lifecycle has one trap/no stale return target | Bound to sequential run-owned host checks; no new cross-run shared reset guarantee; concurrency outside selected transition remains flagged |
| UIQ-05 unclassified | Exact execution/fingerprint comparator implements approved acceptance | UNRESOLVED unclassified probe; not claimed auto-resolved |

Prohibition recall was performed per requirement before precision filtering. Raw candidates, grouped by requirement: UXF-11 shrinking targets, hidden names, missing focus, broken boundaries, wrong position, broken Close, wrong Account, misleading selection, clipped Unicode, aesthetic approval by score; STORY-03 broken root/sidebar/deep links, wrong asset prefix, stale URLs, exposed production route, lost session, CSRF omission, hidden navigation error, arbitrary redirect, inferred route-removal authority; STORY-04 stale CSS, source/build conflation, failed font fetch, absent face, wrong weight, wrong role, fallback serif, copied fake renderer, customer capture, claimed fidelity without execution; STORY-05 missing owner, conflicting roots, wrong initial System, ignored OS change, explicit-mode drift, host-cookie mutation, selection loss, fake preview Account, misleading preference label, owner approval by score; STORY-06 duplicate socket, copied hooks, wrong client version, listener leak, stale target, failed update, failed close, broken reconnect, shared reset race, claimed static behavior as connected proof; UIQ-05 stale report, missing scan, failed scan, zero cases, partial expected set, flat-count target swap, quiet rebaseline, untriaged incomplete, raw node HTML, advisory claim presented as required approval.

Precision drops routine correctness/engineering candidates (geometry/names/URLs/fonts/lifecycle/count integrity) to their explicit task acceptance and edge/code-review owners. Canon-referral drops: exposed routes/auth/session/CSRF/injection/unsafe redirect and customer-PII/data retention are OWASP/privacy canon, owned by the per-plan ASVS L1 threat models and `$gsd-secure-phase`; no duplicate prohibition minted. One bespoke transparency/value constraint survives: “Review evidence must not present unexecuted or advisory checks as proof of required CI or owner approval.” Serialized with the installed probe-core.cjs `projectProhibitions` function into plan 05 must_haves.prohibitions as status unresolved, without any check_* descriptor. It remains flagged-unverified and cannot silently green. No second serializer or invented wired check was used.

Assumption-delta detector reported pluralization from “second socket.” Decision recorded in 01: no-change to primary production presentation; each legitimate host owns its socket, shared hook implementation is the general representation. No published contract/migration or irreversible gate was inferred from routine UI refactoring. Research Level 1 discovery used pinned installed PhoenixStorybook documentation/router API; no new dependency choice. Graph query returned disabled, so no graph context was claimed.

## Wave 0 Requirements

- [x] Name selected scenario IDs and their expected states before implementing the producer; normal/boundary production quick-view scenarios for both collections.
- [x] Add missing targeted assertions within existing runners, with no new package or generic fixture platform.
- [x] Select a working existing Admin axe dependency seam against Demo-hosted Storybook and prove it with one real scan before expansion.
- [x] Add comparator negative fixtures for missing report, missing/failed scan, zero cases, incomplete expected set, stale identity and changed rule/target/state despite unchanged counts.
- [x] Keep synthetic plain facts/builders separate from persistence materialization and check representative projection agreement where consumed.
- [x] Update this map with finalized plan/task IDs and runnable focused commands; no nonexistent file may be treated as an already passing check.

## Evidence and Cost

Receipts identify source revision, actual URL, scenario/state, asset/font/theme ownership, selected and executed cases, failure disposition and evidence limits. Do not store customer HTML or PII. Approved axe findings are reviewed inputs; a fresh failing report cannot silently become the baseline. An incomplete axe result is distinct from incomplete execution.

Record cold and warm setup-inclusive wall time and runner-minutes for the initial selected sweep, including dependency/browser/service startup and expected/executed counts. Provisional added-PR budgets are <=5 wall minutes and <=10 runner-minutes, not measured guarantees. Current browser jobs sit outside protected `CI Green`; preserve gates and state actual required/advisory placement. Reconfirm live protection before any placement claim.

## Manual-Only Verifications

| Behavior | Why human review remains | Instructions |
| --- | --- | --- |
| Restrained arrow hierarchy with coherent position and Close | Automated class/color/geometry checks do not establish aesthetic approval | Inspect retained production renderings and real quick views in light/dark at representative narrow/wide/container widths, keyboard focus and reduced motion; pair review with objective browser assertions. |

All machine-observable acceptance requires automated evidence under D-52. Manual review does not substitute for network, computed-font, URL, focus, lifecycle or axe checks. Final real-zoom reconciliation remains Phase 178; preserve continuing obligations now.

## Validation Sign-Off

- [x] Final plan/task map and focused commands recorded.
- [x] Every task has automated verification or an explicit earlier test-creation dependency.
- [x] No three consecutive tasks lack automated feedback; no watch commands.
- [x] Failure-path tests prevent vacuous accessibility passes.
- [x] Selected connected checks and initial cost pilot completed with honest CI disposition.
- [x] `nyquist_compliant` and `wave_0_complete` updated only after supporting evidence.

**Audit:** Verified 2026-10-27 from the six execution summaries, actual test sources and current candidate receipts. This is test-coverage sign-off, not owner aesthetic approval.


## Revision 1 — checker resolutions

- Research Open Questions 1–4 are marked RESOLVED for design with exact selected plans; runtime measurements remain pending.
- 174-05 now has three tasks. Task 3 reproduces fresh scrollable-region-focusable rule/target/scenario/state, applies the smallest accessible production repair to the actual quick-view scroll panel, and reruns keyboard/focus/navigation plus all 18 selected scans. The empty approval input no longer implies zero findings. Existing broader nine-cell baseline remains intact.
- The added connected command is `npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase174 scroll access|Phase174 client hooks"`; nonzero exit, zero cases, missing either surface or broken scroll/focus/navigation fails. The normal selected axe command still fails on any unapproved residual finding.
- Intentional residual debt has a conditional execution-time checkpoint:decision with gate=blocking-human, no auto_select, only after an exact fresh evidence packet exists. The executor must pause for scoped repair versus named-fingerprint acceptance and record reviewer/source/date/reason before any approval-file change; a clean result skips it. No unconditional checkpoint or pre-approved rebaseline is introduced. Frontmatter autonomous remains true for the normal repair path; the executor emits the actual blocking checkpoint if that evidence-dependent branch occurs.
- 174-06 task 1 explicitly provisions Admin's Chromium with `/workspace/mailglass_admin/node_modules/.bin/playwright install chromium` after the existing Admin lockfile restore, before its scan, under the same PLAYWRIGHT_BROWSERS_PATH. Record Admin 1.59.1 CLI/browser revision/cache hit/miss/install time separately from Demo 1.60.0 and include both cold/warm setup cost.
- The actual existing advisory demo_browser_evidence job invokes `bash scripts/run_demo_browser_evidence.sh --phase174 --pilot`; it records hosted run/attempt/head/job/runner identifiers and retains both conditions. The existing PR trigger or `gh workflow run ci.yml --ref "$PHASE174_CANDIDATE_REF"` executes the candidate during implementation, never during planning. Required aggregate policy is unchanged.
- Final CI proof uses independently downloaded artifacts and completed run/jobs metadata: `node scripts/check_phase174_evidence.cjs --evidence-dir "$PHASE174_CI_EVIDENCE_DIR" --pilot --require-ci`. Nonzero exit, missing/local/forged/stale identity, absent completed ci-job.json, head/job mismatch, missing condition/setup/browser/case accounting or unapproved findings fails. Local elapsed time is not CI runner evidence.
- Plan-05 task 1 explicitly creates test:storybook-axe, then re-resolves package script/config/spec and lists 18 cases before its runnable verification; script_missing is a planned-production warning until creation, never an accepted runtime omission.


## Execution Coverage Audit — 2026-10-27

No missing or partial automated requirement coverage remains. All 13 tasks have automated checks; no generated test duplicates were needed. The initial connected proof against a reused local seed in Plan 03 is superseded by the isolated hosted cold/warm run.

| Task | Automated behavior/evidence | Result |
|---|---|---|
| 174-01/1 | Delivery tracer, full-prefix navigation, actual target geometry | COVERED |
| 174-01/2 | Normal/boundary/single/Unicode/empty scenarios and feedback manifest | COVERED |
| 174-02/1 | Connected Inbound navigation, Account, focus return, boundaries | COVERED |
| 174-02/2 | Independent persisted projection agreement and foreign Account negative | COVERED — 4 ExUnit tests |
| 174-03/1 | Shared hook definitions, served bytes and single socket ownership | COVERED — assets contract and hosted hooks |
| 174-03/2 | Repeated patch/remount/reconnect/removal on both locked clients | COVERED — Demo and Operator Browser Gate |
| 174-04/1 | Light/Dark/System ownership, both initial OS modes and live changes | COVERED |
| 174-04/2 | Real CSS/font responses, loaded roles, five widths in both themes | COVERED |
| 174-05/1 | Exact nonempty selected Axe producer, real rendered states | COVERED — 18 cases per condition |
| 174-05/2 | Negative report/comparison fixtures and independent triage | COVERED — 18 Node comparator tests |
| 174-05/3 | Keyboard scroll/focus and distinct accessible navigation boundaries | COVERED — 3 focused cases and full Operator gate |
| 174-06/1 | Isolated runner, malformed/stale/local/partial receipt rejection | COVERED — checker negative controls and actual pilot |
| 174-06/2 | Independent completed CI metadata, cost and advisory disposition | COVERED — strict --require-ci checker |

Evidence root: `reference/demo_app/tmp/demo_browser_evidence/ci/40491221303-attempt-1/`. Exact candidate `fbf7d791f4f489db8a5d344455a33f0942a434d4`, digest `36ce0049cc50c1e33e5a35f203c99c771a12d55f016d1a830ed24f948e335004`. Cold and warm each execute 148/148 cases (98 Demo, 6 hooks, 26 fidelity, 18 Axe); both have zero violations/unapproved/untriaged, with 50 explicitly triaged incomplete findings. Incomplete findings are not passes.

Fresh final local regression: 81 core tests, 642 Admin tests, 480 Inbound tests plus 3 properties, and 31 connected browser cases passed. Existing nine-cell Axe baseline: 12/12 tests. Final exact-candidate workflow and both browser jobs completed successfully. Original downloaded cost and independent raw GitHub metadata remain retained.

Observed same-profile added cost is 315s versus a 221s prior successful job: 15s over the provisional wall budget and within the 10 runner-minute budget. This is a measured disposition, not a test failure hidden by scope reduction. Manual aesthetic judgment and Phase178 real zoom remain bounded as above. The descriptorless transparency prohibition remains flagged-unverified; no invented check descriptor or owner approval was added.

## Validation Audit 2026-10-27

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |


## Post-Review Reconciliation

The independent source review identified three concrete gaps that the initial audit had missed. Commit `18c6cf32` adds symlink-component rejection, no-follow checkpoint writes and preservation of prior retained evidence (CR-01/T-174-16/18); full-detail focus ownership and a connected regression (WR-01); and omitted route/story inputs plus dirty-byte digest controls (WR-02/T-174-17). All 24 focused Node checks and 3 browser cases passed, with an independent clean re-review in `174-REVIEW-FIX.md`. The initial report is retained and all three dispositions are fixed. Current exact-candidate CI proof is tracked separately from these focused checks; no risk acceptance or gate reduction occurred.

## Fresh post-review hosted proof — 2026-10-27

The repaired exact candidate `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5` passed GitHub Actions run [40498413906](https://github.com/szTheory/mailglass/actions/runs/40498413906), attempt 1, with all 26 jobs successful. Demo Browser Evidence job [122170444350](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170444350), Operator Browser Gate [122170443965](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170443965), and Preview Capture Advisory [122170443973](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170443973) completed successfully. The strict `--pilot --require-ci` checker passed against the independently enriched artifact at `reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1/`.

The current source manifest has 57 inputs and digest `21542c6a5e3a10a8d6334b902c9cbfbecde06e210aca8ae9c333cbe3054ed1c2`. Cold and warm each executed 148/148 selected cases; each Axe comparison executed 18/18 with 0 violations, 0 unapproved findings, 0 untriaged findings, and 50 incomplete findings retained as incomplete. The prior successful run `40491221303` remains historical pre-review evidence and is superseded for current-source proof.

The first post-review dispatch, `40496672358`, had a successful Demo evidence job but failed its separate Preview Capture Advisory readiness window while the cold server was compiling/seeding at `sandbox_owner_started`. The workflow was cancelled after the retry was queued; its artifact, raw run/job metadata, and failure log remain preserved under the run-owned `40496672358-attempt-1` directory. The unchanged retry passed without a timeout or gate change.
