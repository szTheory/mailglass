# Phase 174 review: quick views and faithful Storybook evidence

## Reproduce the selected evidence

Run the isolated cold/warm pilot from the repository root with the pinned local toolchain:

```sh
ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 \
  bash scripts/run_demo_browser_evidence.sh --phase174 --pilot
```

The wrapper prints its unique evidence directory. A local receipt can be checked without claiming hosted CI authority:

```sh
node scripts/check_phase174_evidence.cjs \
  --evidence-dir reference/demo_app/tmp/demo_browser_evidence/<run-id> --pilot
node --test scripts/check_phase174_evidence.test.cjs
```

For the hosted run, use the exact artifact root and independent GitHub job metadata:

```sh
node scripts/check_phase174_evidence.cjs \
  --evidence-dir reference/demo_app/tmp/demo_browser_evidence/ci/40491221303-attempt-1 \
  --pilot --require-ci
```

The `--require-ci` check rejects local or caller-labeled evidence. It requires a completed successful workflow and named evidence job, a matching candidate SHA/run/attempt/job/runner, completed required setup and evidence steps, and the full runner duration derived from the job timestamps.

## Current candidate evidence

Candidate source is `fbf7d791f4f489db8a5d344455a33f0942a434d4` on `gsd/phase-174-evidence`. The exact GitHub Actions run is [40491221303](https://github.com/szTheory/mailglass/actions/runs/40491221303), attempt 1, `workflow_dispatch`, with the Demo evidence job at [122145432926](https://github.com/szTheory/mailglass/actions/runs/40491221303/job/122145432926). Its run-owned artifact is `demo-browser-evidence-40491221303-1`, retained under the existing 14-day policy through 2026-11-10.

The evidence job completed successfully at `2026-10-27T10:56:49Z`. The full workflow completed/success at `2026-10-27T11:03:56Z` with all 26 jobs successful, including Operator Browser Gate and Core Deterministic Suite. Independent run/job metadata and successful setup/evidence steps are retained in `ci-job.json`, `github-run.raw.json`, and `github-jobs.raw.json`. The final hosted evidence check returned `valid: true` for both cold and warm conditions with matching candidate identity.

| Field | Hosted result |
| --- | --- |
| Selected source digest | `36ce0049cc50c1e33e5a35f203c99c771a12d55f016d1a830ed24f948e335004` |
| Source inputs and hash method | `phase174/execution.json#source` retains all 45 tracked input paths. Digest method: `sha256(sorted(path\0byte_length\0file_sha256\n))`. |
| Cold / warm coverage | Each condition expected and executed 98 Demo + 6 hooks + 26 fidelity + 18 Axe cases = 148/148. |
| Axe comparison | Each condition: 18/18 selected, 0 violations, 0 unapproved violations, 0 untriaged findings, 50 incomplete findings. |
| Cold phase wall | 355,489 ms (5m55.489s): 194,562 ms setup, 156,293 ms execution, 0 ms per-condition teardown. |
| Warm phase wall | 158,321 ms (2m38.321s): 2,957 ms setup, 153,281 ms execution, 11,466 ms run-owned teardown. |
| Pilot wall | 525,889 ms (8m45.889s) including the cold/warm wrapper and final run-owned cleanup. |
| Browser clients | Demo Playwright 1.60.0 / Chromium 1223; Admin Playwright 1.59.1 / Chromium 1217. Both caches missed cold and hit warm. |
| Browser install lookup | Demo: 12,597 ms cold / 985 ms warm. Admin: 9,142 ms cold / 422 ms warm. |

The run used one run-owned Compose project, `mailglass-evidence-40491221303-1`, with isolated ports 44005 and 43899, one Playwright worker, serialized cold/warm conditions and data resets, and the authenticated reset endpoint. It removed its own services and volumes after the warm run. The retained artifacts contain synthetic cohorts; the reset receipt records no token value.

The fidelity receipt proves that both Storybook stories use the production stylesheet: source CSS SHA-256 `0d964dcd2c911a642619531c6ce041f22a44d888bb1590fc8097535acb9887e5`; built and served CSS SHA-256 `b74a52501d325bc14e8201ab6fe94c77686d38c3d8ce6f4d674ec51a689e475b`, with served bytes matching the build. Twelve font responses cover Inter, Inter Tight, and IBM Plex Mono at weights 400 and 700 for both stories; all returned HTTP 200 with loaded faces. Twenty responsive cases cover 320, 375, 768, 1280 and 1440 CSS-pixel widths, normal/boundary states and both themes. Story-local Light/Dark/System behavior, live OS changes, explicit selection stability, iframe hook registration/removal/remount and connected Demo route focus return are recorded in the fidelity and hooks receipts. The independently locked Admin client’s connected browser checks passed in Operator Browser Gate job 122145432867 in the same successful workflow.

## Requirement and scenario evidence map

| Requirement | Current source and retained evidence | Evidence boundary |
| --- | --- | --- |
| UXF-11 | `MailglassAdmin.Operator.QuickView`, `MailglassAdmin.Inbound.QuickView`; connected checks in `reference/demo_app/assets/e2e/quick-views.spec.js` and the selected browser receipts. Scenarios: `qv-delivery-normal/first/last/single-unicode/empty`, `qv-inbound-normal/first/last/single-unicode/unavailable/empty`. | Enabled controls have accessible names, visible focus and at least 44px targets. Delivery's unavailable boundary is an inert generic span with screen-reader text and no link/button semantics; Inbound retains its native disabled button. Empty states are connected-route-only. |
| STORY-03 | `MailglassDemoWeb.StorybookRoutes`; selected `persona-screenshots.spec.js` and `quick-views.spec.js` cases. | Root, Theme Picker, sidebar, direct Delivery/Inbound stories and prefixed assets resolve below `/dev/storybook`. |
| STORY-04 | `storybook-fidelity.spec.js` and `phase174/fidelity.json`. | Built/served CSS identity, six font faces and UI/display/code roles are compared with production. Twenty cases cover the selected viewport/theme matrix; this is not a browser/device Cartesian grid. |
| STORY-05 | Story-owned Light/Dark/System controls in the Delivery and Inbound stories; theme receipt in `fidelity.json`. | Both System modes and live light↔dark OS changes are checked. Explicit choices stay selected and do not mutate the host preference. |
| STORY-06 | `storybook-hooks.spec.js`, production hook asset, Admin `flows.spec.js`, and `phase174/hooks.json`; Admin's connected proof is in Operator Browser Gate job 122145432867. | Storybook preview mount/patch/remove/remount and connected Demo Delivery/Inbound focus return are in the Demo hook receipt. Demo LiveView 1.1.33 and Admin LiveView 1.2.13 remain independently locked and both passed their connected checks. The explorer and isolated iframe retain their own sockets; the hook asset creates none. |
| UIQ-05 | Admin-owned `storybook-axe.spec.js` / `storybook-axe.cjs`, independent `storybook-axe-approved.json` triage, and cold/warm `axe.json` receipts. | Exact 18 selected cases run in each condition. Violation approvals remain empty. Zero violations and zero untriaged findings do not convert the 50 incomplete findings per condition into passes. |

The scenario manifest distinguishes pure scenario facts from persisted projection agreement. Persisted checks cover `qv-delivery-single-unicode`, `qv-inbound-normal` and `qv-inbound-single-unicode`; `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` reads the scoped production projections. Other normal/boundary/unavailable stories are explicit rendering-only checks. `qv-delivery-empty` and `qv-inbound-empty` represent real absence and remain connected-route-only; no empty story fabricates a selected record. The nine rendered stories produce the exact 18-case Light/Dark Axe set.

## Bounded visual review and remaining limits

I reviewed the retained candidate captures `phase174/cold/delivery-light.png`, `phase174/cold/delivery-dark.png`, `phase174/warm/delivery-320-boundary-dark.png`, and `phase174/warm/inbound-1440-boundary-dark.png`. Light and dark keep the subject, outcome, recipient, time, Account/provider and technical identifier in a clear hierarchy. The selected navigation and close controls read as quiet controls with visible boundaries. At 320px, the subject and timestamp wrap and the panel continues vertically without visible horizontal spill. At the wide Inbound capture, the panel remains a contained reading column. The Storybook review-theme control crowds its own chrome at the top of the narrow capture; that is review chrome rather than quick-view content. This is a bounded, subjective review of selected Chromium captures, not an aesthetic score or a statement about all browsers/devices.

The 50 Axe incomplete findings per condition are retained and matched against the independent triage record; they remain incomplete machine results, not passes. No violation fingerprint is approved. The descriptorless transparency prohibition remains flagged-unverified; this evidence does not infer an owner approval. The serif StatCard/catalogue feedback and real browser zoom/final milestone reconciliation remain Phase 178 work. Focus, reduced-motion, width, theme, hook and keyboard evidence for the current repair is not deferred.

## Feedback disposition

The manifest is `reference/persona_spec/quick_view_scenarios.json`; its `feedback` entries and scenario IDs remain the inventory. The two Phase 174 rows link to this guide and to the current retained evidence:

| Feedback | Requirement(s) | Current disposition and evidence |
| --- | --- | --- |
| `fb-quiet-quick-view-arrows` | UXF-11 | Resolved for Delivery and Inbound connected routes and the scenario IDs above. Delivery unavailable navigation is inert; Inbound unavailable navigation is natively disabled. |
| `fb-storybook-fidelity` | STORY-03–07 | Partial. Current receipts cover routes/assets, production CSS/fonts, both themes, hooks, connected cases and strict Axe comparison. STORY-07 set-wide reconciliation, serif StatCard/catalogue work and real zoom remain with Phase 178. |
| `fb-suppression-refresh` | OUTUX-07, OUTUX-08 | Pending Phase 175; retain ready/empty/stale/unavailable suppression evidence and truthful retry/expiry language. |
| `fb-replay-review` | REPLAY-04–08 | Pending Phase 175; retain permitted, unavailable, denied, success and retry outcomes. |
| `fb-technical-details` | UXF-12 | Pending Phase 175; retain production stories and connected full-detail evidence on both surfaces. |
| `fb-auto-apply-filters` | FILTER-01–04 | Pending Phase 176; retain connected URL/history and Back/Forward cases for both lists. |
| `fb-raw-source-hierarchy` | INUX-06 | Pending Phase 176; keep reveal authorization and the safe source allowlist in connected evidence. |
| `fb-inbound-addresses` | INUX-05 | Pending Phase 176; retain authorized long/Unicode, missing and multiple-address cases. |
| `fb-health-crowding` | OUTUX-06 | Pending Phase 177; retain Health hierarchy and filtered deep-link comparison. |
| `fb-account-context` | UXF-09, UXF-10 | Pending Phase 177; retain scoped Health/collection and host-approved Preview return-route evidence. |
| `fb-preview-reset` | PRVUX-05, PRVUX-06 | Pending Phase 178; retain authoring/reset behavior while preserving parsing and validation. |
| `fb-preview-identity` | PRVUX-07 | Pending Phase 178; retain long/Unicode and narrow selector identity evidence. |

Later rows remain pending with their assigned owners; this plan does not mark them resolved.

## CI placement and cost disposition

The existing `demo_browser_evidence` job in `.github/workflows/ci.yml` runs `bash scripts/run_demo_browser_evidence.sh --phase174 --pilot` and uploads run-owned evidence with the existing 14-day retention. It is advisory and is not a dependency of `CI Green`. The live `main` branch-protection snapshot observed on 2026-10-27 remains strict with required contexts `CI Green` and `Guard Release Trigger`; no aggregate policy or protected context changed.

The defensible same-profile baseline is successful main CI run [40414024714](https://github.com/szTheory/mailglass/actions/runs/40414024714), head `e326da4dfb59c3a20942acff763d04a79ada974b`, event `push`, attempt 1. Its same Demo evidence job [121891818059](https://github.com/szTheory/mailglass/actions/runs/40414024714/job/121891818059) ran on `ubuntu-latest` / one GitHub-hosted runner from `2026-10-26T22:45:46Z` to `2026-10-26T22:49:27Z`: 221,000 ms (3m41s).

Candidate job 122145432926 ran on `ubuntu-latest` / one runner from `2026-10-27T10:47:53Z` to `2026-10-27T10:56:49Z`: 536,000 ms (8m56s, 8.933 runner minutes). The observed same-job delta is **+315,000 ms (5m15s, 5.25 runner minutes)**. The provisional added PR wall budget of five minutes is exceeded by 15 seconds; the ten runner-minute budget is within limit. This is an observational single-job comparison, not a causal estimate or a guarantee about CI critical-path latency. It includes runner/setup variance; the full hosted job timestamps, rather than scan-only intervals, define the measured cost.

Recommendation: keep the Phase174 pilot integrated into the existing advisory Demo Browser Evidence job rather than add a second CI lane. One lane shares checkout, one isolated Demo/Postgres service, and the cold/warm browser caches while retaining all 148 cases in both conditions. Re-measure the 15-second wall overage on a later run; only consider reducing repeated baseline execution after proving every acceptance case still runs at least once and all Phase174 cases remain in both conditions. Preserve the current required gates.

The exact run was not merged, published or deployed. The completed overall workflow and independent `--require-ci` check are the final candidate proof; CI placement remains advisory.
