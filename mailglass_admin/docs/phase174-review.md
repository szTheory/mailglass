# Phase 174 review: quick views and faithful Storybook evidence

**Review state:** the current-source local cold/warm pilot is complete. Candidate-specific hosted CI evidence is still required before this plan can close. This guide records that gap explicitly and does not treat local receipts as CI proof.

## Reproduce the selected evidence

From the repository root, run the isolated cold/warm pilot with the pinned local toolchain:

```sh
ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 \
  bash scripts/run_demo_browser_evidence.sh --phase174 --pilot
```

The wrapper prints its unique run directory. For local-only validation:

```sh
node scripts/check_phase174_evidence.cjs \
  --evidence-dir reference/demo_app/tmp/demo_browser_evidence/<run-id> \
  --pilot
node --test scripts/check_phase174_evidence.test.cjs
```

The local result is deliberately not accepted by `--require-ci`: a local `GITHUB_ACTIONS` label or elapsed time cannot establish GitHub job authority. That flag must reject a local run and must be used only with a downloaded, completed candidate job and independently captured `ci-job.json`.

## Current local candidate evidence

| Field | Measured result |
| --- | --- |
| Run | `mailglass-evidence-20261027092905-80235-20765` |
| Source revision | `b0ea598658595da577a6161e5c5c56f4c68d5814` |
| Selected-source digest | `8d5e0a48bd6635fc4a05e3ab89d56e9c95317f1a85efe3a275102cbf90e2a09e` |
| Cold / warm coverage | Each condition expected and executed 98 Demo + 6 hook + 26 fidelity + 18 Axe cases = 148/148; no failed, skipped, flaky, missing, or unfinished case |
| Axe | Each condition: 18/18 selected, 0 violations, 0 approved violations, 0 untriaged findings, 50 incomplete findings |
| Cold elapsed | 428,261 ms (7.14 min); setup 226,521 ms; scans/comparison 195,646 ms |
| Warm elapsed | 198,785 ms (3.31 min); setup 6,570 ms; scans/comparison 187,992 ms |
| Full local pilot | 630,715 ms (10.51 min), including run-owned Compose teardown; one local executor, hosted runner minutes unavailable |
| Browser clients | Demo Playwright 1.60.0 / Chromium 1223; Admin Playwright 1.59.1 / Chromium 1217; cold cache miss and warm cache hit for each, under `/cache/playwright` |

The local run retained all receipts and representative screenshots under `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261027092905-80235-20765/phase174/`. It used one run-owned Compose project, isolated ports and volumes, serial data resets and one Playwright worker. The browser cases used the same Demo service for the Demo sweep and Admin-owned Axe scan. The wrapper removed only that project's containers and volumes.

The six font receipts identify the exact served production CSS and Inter, Inter Tight, and IBM Plex Mono faces/weights. Story-local Light, Dark, and System behavior is owned by each quick-view story; live OS changes were exercised without changing the host preference. The iframe mount/remove/remount and focus-return receipts record production hook registration and real connected route cycles. Storybook documents were verified without an Admin bootstrap; the final `/ops/` documents retained the production Admin bootstrap.

### Setup and added-cost limits

Cold/warm local cost includes Demo lock audit and dependency restore, both browser installers, Demo/Postgres startup, Admin dependency restore, all selected browser/axe checks, comparison and teardown. The cold service startup was 123,286 ms; Demo dependency restore was 2,833 ms, Demo Chromium install 51,727 ms, Admin dependency restore 1,553 ms, Admin Chromium install 46,766 ms, Demo scan 153,475 ms, and Admin Axe scan 41,921 ms. Warm browser caches were hits (Demo install lookup 1,811 ms; Admin 1,019 ms); warm Demo scan was 149,986 ms and Axe scan 37,868 ms.

The provisional budget is an **added PR cost** of at most five wall minutes and ten runner minutes. The 10.51-minute local end-to-end pilot is useful setup-inclusive timing, but it is neither a GitHub runner measurement nor a same-profile baseline delta. Accordingly, added PR wall/runner cost is **unmeasured**, and budget compliance is **not established**. No scan-only timing is substituted for the complete job duration. A same-profile existing-lane comparison and actual hosted job timing are still needed to judge duplication and placement.

## Requirement and scenario evidence map

| Requirement | Current source and retained evidence | Evidence boundary |
| --- | --- | --- |
| UXF-11 | `MailglassAdmin.Operator.QuickView` and `MailglassAdmin.Inbound.QuickView`; connected `quick-views.spec.js` Delivery/Inbound navigation, boundary, keyboard, focus-return, scrolling, target-size, and theme cases. Feedback `fb-quiet-quick-view-arrows` now links these to the current run. | Enabled controls are named 44px ghost links. Delivery's unavailable boundary is an inert generic span with screen-reader text and no button/link semantics; Inbound retains its native disabled button. The adapters' different boundary semantics are intentional. |
| STORY-03 | `MailglassDemoWeb.StorybookRoutes`; `persona-screenshots.spec.js` generated-root/sidebar/deep-link and served-asset cases; quick-view tracer in `quick-views.spec.js`. | Retained paths remain under `/dev/storybook`, including root, Theme Picker, quick-view stories, and internal assets. |
| STORY-04 | `storybook-fidelity.spec.js` production CSS/font/role receipts and responsive matrix for both stories. | Verifies built and served CSS identity, font bytes/faces/weights, and UI/display/code roles at 320, 375, 768, 1280, and 1440 CSS-pixel viewports. The width cases assert both computed Light and Dark production themes. |
| STORY-05 | `storybook-fidelity.spec.js` story-owned Light/Dark/System cases for Delivery and Inbound. | Both initial System modes and live light↔dark OS changes are checked; explicit selection remains stable and the host preference is not mutated. |
| STORY-06 | `storybook-hooks.spec.js`; production `MailglassDemoWeb.Storybook.js_body/0` hook registration; the selected hook receipt. | Six cases cover Storybook mount/remount and connected Delivery/Inbound focus return; the receipt checks iframe lifecycle, socket frames, reduced motion, focus events, both independent locked clients, and real routes. |
| UIQ-05 | Admin-owned `storybook-axe.spec.js` and `storybook-axe.cjs`; cold/warm `axe.json` receipts and independent `storybook-axe-approved.json` triage. | Exact 18 selected executions in both conditions. There are no approved violation fingerprints. Zero violations and zero untriaged findings do **not** turn the 50 incomplete findings into passes; those machine-incomplete findings remain visible and need human interpretation. |

The retained scenario manifest accounts for the meaningful boundaries without implying persistence for story-only projections:

- Delivery normal, first, last, and single-Unicode states are rendered production stories; connected route cases separately prove operator navigation and focus. Inbound normal, first, last, single-Unicode, and unavailable/error states are rendered stories; connected routes prove reachable interactions.
- The persisted projection test is `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs`. The manifest marks `qv-delivery-single-unicode`, `qv-inbound-normal`, and `qv-inbound-single-unicode` as persisted projection checks. Normal/first/last/unavailable variants without persistence are explicitly story-rendered projection-agreement checks, not claims that their fixture rows were inserted.
- `qv-delivery-empty` and `qv-inbound-empty` are connected-real-route-only; they do not fabricate empty Storybook stories. The selected story Axe matrix is exactly nine rendered variants in Light and Dark (18 executions). The separate `helios-void` direct route stays an empty-account case, not a selectable delivery.
- The selected findings comparator uses the exact run/revision/source digest, scenario, state, theme, rule, and stable target. It rejects a stale, missing, partial, duplicate, failed, or vacuous report. A previous warm iframe-detachment retry in `quick-views.spec.js` was corrected by using Playwright's retrying property assertion while retaining the exact `SPAN` semantic requirement; the final candidate pilot had no flaky cases.

The bounded visual review used the retained warm Delivery Light/Dark captures plus Delivery and Inbound 320px boundary captures. The two themes retain clear subject, outcome, account/provider, position, and close hierarchy; narrow content wraps and continues vertically without horizontal spill. At 320px the Storybook review-theme control crowds the Storybook chrome at the top of the capture; that is review chrome, not quick-view content. This is a subjective restraint review, not a score. It covers selected Chromium states, not all browsers/devices or browser zoom. Real zoom and final milestone reconciliation remain Phase 178 work. The StatCard serif/catalogue feedback remains explicitly partial for Phase 178; descriptorless transparency prohibition remains flagged-unverified as recorded in Plan 174-05.

## Feedback disposition

- `fb-quiet-quick-view-arrows` is resolved against the connected Delivery and Inbound routes and the exact distinct boundary semantics above.
- `fb-storybook-fidelity` remains **partial**. Current sources now include the router, `MailglassDemoWeb.Storybook.js_body/0`, both production quick-view stories and components, Admin asset controller, and `Storybook.Primitives.StatCard`. Current receipts cover prefix/navigation, production assets/fonts, both themes, hooks, connected cases, and Axe triage. The StatCard/catalogue work and real-zoom reconciliation remain owned by Phase 178.
- Other feedback rows remain with their existing owners and phases (175–178); this plan does not mark them resolved.

## CI placement and hosted-proof gate

The existing `.github/workflows/ci.yml` job `Demo Browser Evidence (Docker Compose / Chromium)` now runs `bash scripts/run_demo_browser_evidence.sh --phase174 --pilot` and uploads its run-owned outputs with the existing 14-day retention. It is advisory and runs when the workflow's code detector selects it. It is not a dependency of `CI Green`; `scripts/ci_green_policy.sh` explicitly rejects an advisory lane presented as required evidence. The live `main` branch-protection snapshot observed on 2026-10-27 had strict required contexts `CI Green` and `Guard Release Trigger`. No aggregate policy or protected context was changed.

**Hosted proof is still open.** This local pilot has no GitHub run/job identity (`job_id: local`, `runner_minutes: null`) and cannot satisfy `--require-ci`. No candidate-specific successful hosted job exists yet. At the time of this review, local candidate `b0ea5986` was not published; `origin/main` was still `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`, and `gh run list --workflow ci.yml --commit b0ea598658595da577a6161e5c5c56f4c68d5814` returned no run. Do not substitute that stale remote-main state or infer CI authority from the local receipt.

After the final candidate commits are available on a verified remote ref, use the ordinary code-changing PR workflow or run `gh workflow run ci.yml --ref "$PHASE174_CANDIDATE_REF"` against that explicit candidate ref. Set the variable only after verifying the published ref contains the final candidate. Record and verify the actual run head SHA/ref before downloading anything. For that exact run:

1. Set `PHASE174_CANDIDATE_REF` to the verified published candidate branch/ref and `PHASE174_CI_RUN_ID` to its actual completed workflow run. Check `gh run view "$PHASE174_CI_RUN_ID" --json headSha,status,conclusion,jobs,url`; confirm the head SHA equals the candidate commit and the job is `demo_browser_evidence`, named `Demo Browser Evidence (Docker Compose / Chromium)`.
2. Download artifact `demo-browser-evidence-$PHASE174_CI_RUN_ID-$GITHUB_RUN_ATTEMPT` into a new run-owned `reference/demo_app/tmp/demo_browser_evidence/ci/<run-id>/` directory. Set `PHASE174_CI_EVIDENCE_DIR` to the downloaded content root containing `phase174/`.
3. Save an independent `ci-job.json` beside `phase174/`, schema `phase174-ci-job.v1`, from the actual GitHub run/job metadata: workflow run and attempt, repository, head SHA, URL/status/conclusion/timestamps, actual job database ID/name/status/conclusion, runner name/OS/architecture, and the completed successful `Checkout`, `Audit demo browser lockfile`, `Test pinned baseline provisioning`, and `Run demo browser evidence` steps. Derive full runner duration from the actual job `started_at` and `completed_at`; do not derive it from the local cold/warm intervals.
4. Verify the job and artifact refer to the same candidate SHA, run/attempt, job, runner, and source digest, then run:

   ```sh
   node scripts/check_phase174_evidence.cjs \
     --evidence-dir "$PHASE174_CI_EVIDENCE_DIR" --pilot --require-ci
   ```

Only a successful checker result for that actual completed candidate job closes this gate. Until then, hosted runner cost, added-cost delta, and the five-wall/ten-runner-minute budget disposition remain unmeasured.

The local synthetic evidence has no customer payloads or auth secrets. Failure outputs from the earlier flaky run are retained under `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261027090617-56275-17045/`; the successful current-source run is retained separately. Historical Phase 172 screenshot artifacts were not overwritten.
