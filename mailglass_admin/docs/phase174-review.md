# Phase 174 review: quick views and faithful Storybook evidence

## Automated UAT closure (2026-10-27)

The owner reaffirmed D-52: observable acceptance is automated, with zero routine owner UAT. The three former checkpoints now have executable coverage:

- `storybook-axe.spec.js` retains the unchanged 18-case scan and separate incomplete findings, then checks all 242 retained contrast targets using rendered foreground/background colors and both focus-sentinel wrap directions in every case. Unsupported paint fails closed; the brand's zero-sized noise layer paints no pixels. Contrast thresholds follow [WCAG contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html). These supplemental assertions do not relabel axe results or certify all accessibility.
- `scripts/phase174-review-claims.cjs` is called by the evidence checker. Its review summary requires complete successful execution and reports the actual advisory placement, `required_ci_proof: false`, and `owner_approval: false`. The wired Node tests reject incomplete execution and overstated authority; GSD independently proves red against a known-bad subject and green against the real implementation.
- Both story templates reserve a separate theme-control band above the production dialog. The existing 20-case width/theme matrix now asserts non-overlap and container bounds. Selected narrow captures have also been inspected by the agent; this is bounded review, without an owner aesthetic verdict.

The fast checker/comparator/review contract tests run in the existing Demo Browser Evidence job and local GSD regression gate. Browser assertions reuse the existing selected sweep and fidelity tests; no dependency, extra CI lane, or required-context change was introduced. The durable final results and replay command live in `.planning/phases/174-faithful-storybook-and-quiet-quick-views/174-UAT.md` and `174-AUTOMATION.md`. Those records supersede the former human-review queue.

The hosted candidate and cost figures below describe the earlier implementation revision. They remain historical evidence for that revision. Current automation repairs have fresh local source-digest-bound proof; they have not acquired hosted CI or owner-approval authority from the earlier run.

## Reproduce the selected evidence

Run the isolated cold/warm pilot from the repository root with the pinned local toolchain:

```sh
ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 \
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
  --evidence-dir reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1 \
  --pilot --require-ci
```

The `--require-ci` check rejects local or caller-labeled evidence. It requires a completed successful workflow and named evidence job, a matching candidate SHA/run/attempt/job/runner, completed required setup and evidence steps, and the full runner duration derived from the job timestamps.

## Historical hosted candidate evidence

The historical hosted source candidate was `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5` on `gsd/phase-174-evidence`. The exact GitHub Actions run is [40498413906](https://github.com/szTheory/mailglass/actions/runs/40498413906), attempt 1, `workflow_dispatch`, completed/success at `2026-10-27T12:02:39Z` with all 26 jobs successful. The Demo evidence job [122170444350](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170444350), Operator Browser Gate [122170443965](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170443965), and Preview Capture Advisory [122170443973](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170443973) all completed successfully. The run-owned artifact is `demo-browser-evidence-40498413906-1`, retained under the existing 14-day policy through 2026-11-10.

This run is the fresh hosted proof after the source review repairs. An earlier post-review run, [40496672358](https://github.com/szTheory/mailglass/actions/runs/40496672358), had a successful Demo evidence job but its separate Preview Capture Advisory job [122163829378](https://github.com/szTheory/mailglass/actions/runs/40496672358/job/122163829378) failed its 90-iteration readiness window at `2026-10-27T11:34:55Z` while the cold server was still compiling and seeding fixtures (`stage=sandbox_owner_started`). Its log also records a transient PostgreSQL `role "root" does not exist` connection during startup. The run was later cancelled after the unchanged-candidate retry was queued; its Demo artifact, pre-dispatch and final raw run/job metadata, Preview job metadata, and failure log are retained under `reference/demo_app/tmp/demo_browser_evidence/ci/40496672358-attempt-1/`. The retry did not change the timeout, checker, or CI gate.

The earlier successful sample [40491221303](https://github.com/szTheory/mailglass/actions/runs/40491221303) targeted `fbf7d791f4f489db8a5d344455a33f0942a434d4` before the source review; it remains historical proof for that revision and is superseded by the current-source run above.

The successful artifact and independent GitHub run/job metadata are retained under `reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1/`. The original downloaded cost is preserved as `phase174/cost.downloaded.json`; enriched `phase174/cost.json`, `ci-job.json`, `github-run.raw.json`, and `github-jobs.raw.json` retain the exact run and job identity, runner, and timestamps. The strict hosted evidence checker returned `valid: true` for both conditions.

| Field | Hosted result |
| --- | --- |
| Selected source revision and digest | `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5`; `21542c6a5e3a10a8d6334b902c9cbfbecde06e210aca8ae9c333cbe3054ed1c2` |
| Source inputs and hash method | `phase174/execution.json#source` retains all 57 tracked input paths. Digest method: `sha256(sorted(path\0byte_length\0file_sha256\n))`. |
| Cold / warm coverage | Each condition expected and executed 98 Demo + 6 hooks + 26 fidelity + 18 Axe cases = 148/148. |
| Axe comparison | Each condition: 18/18 selected, 0 violations, 0 unapproved violations, 0 untriaged findings, 50 incomplete findings. |
| Cold phase wall | 354,054 ms (5m54.054s): 193,263 ms setup, 156,798 ms execution, 0 ms per-condition teardown. |
| Warm phase wall | 157,923 ms (2m37.923s): 2,972 ms setup, 152,708 ms execution, 11,716 ms run-owned teardown. |
| Pilot wall | 524,496 ms (8m44.496s) including the cold/warm wrapper and final run-owned cleanup. |
| Browser clients | Demo Playwright 1.60.0 / Chromium 1223; Admin Playwright 1.59.1 / Chromium 1217. Both caches missed cold and hit warm. |
| Browser install lookup | Demo: 11,390 ms cold / 1,046 ms warm. Admin: 9,248 ms cold / 415 ms warm. |

The run used one run-owned Compose project, `mailglass-evidence-40498413906-1`, with isolated ports 49581 and 47115, one Playwright worker, serialized cold/warm conditions and data resets, and the authenticated reset endpoint. It removed its own services and volumes after the warm run. The retained artifacts contain synthetic cohorts; the reset receipt records no token value.

The fidelity receipt proves that both Storybook stories use the production stylesheet: source CSS SHA-256 `0d964dcd2c911a642619531c6ce041f22a44d888bb1590fc8097535acb9887e5`; built and served CSS SHA-256 `b74a52501d325bc14e8201ab6fe94c77686d38c3d8ce6f4d674ec51a689e475b`, with served bytes matching the build. Twelve font responses cover Inter, Inter Tight, and IBM Plex Mono at weights 400 and 700 for both stories; all returned HTTP 200 with loaded faces. Twenty responsive cases cover 320, 375, 768, 1280 and 1440 CSS-pixel widths, normal/boundary states and both themes. Story-local Light/Dark/System behavior, live OS changes, explicit selection stability, iframe hook registration/removal/remount and connected Demo route focus return are recorded in the fidelity and hooks receipts. The independently locked Admin client’s connected browser checks passed in Operator Browser Gate job 122170443965 in the same successful workflow.

## Requirement and scenario evidence map

| Requirement | Current source and retained evidence | Evidence boundary |
| --- | --- | --- |
| UXF-11 | `MailglassAdmin.Operator.QuickView`, `MailglassAdmin.Inbound.QuickView`; connected checks in `reference/demo_app/assets/e2e/quick-views.spec.js` and the selected browser receipts. Scenarios: `qv-delivery-normal/first/last/single-unicode/empty`, `qv-inbound-normal/first/last/single-unicode/unavailable/empty`. | Enabled controls have accessible names, visible focus and at least 44px targets. Delivery's unavailable boundary is an inert generic span with screen-reader text and no link/button semantics; Inbound retains its native disabled button. Empty states are connected-route-only. |
| STORY-03 | `MailglassDemoWeb.StorybookRoutes`; selected `persona-screenshots.spec.js` and `quick-views.spec.js` cases. | Root, Theme Picker, sidebar, direct Delivery/Inbound stories and prefixed assets resolve below `/dev/storybook`. |
| STORY-04 | `storybook-fidelity.spec.js` and `phase174/fidelity.json`. | Built/served CSS identity, six font faces and UI/display/code roles are compared with production. Twenty cases cover the selected viewport/theme matrix; this is not a browser/device Cartesian grid. |
| STORY-05 | Story-owned Light/Dark/System controls in the Delivery and Inbound stories; theme receipt in `fidelity.json`. | Both System modes and live light↔dark OS changes are checked. Explicit choices stay selected and do not mutate the host preference. |
| STORY-06 | `storybook-hooks.spec.js`, production hook asset, Admin `flows.spec.js`, and `phase174/hooks.json`; Admin's connected proof is in Operator Browser Gate job 122170443965. | Storybook preview mount/patch/remove/remount and connected Demo Delivery/Inbound focus return are in the Demo hook receipt. Demo LiveView 1.1.33 and Admin LiveView 1.2.13 remain independently locked and both passed their connected checks. The explorer and isolated iframe retain their own sockets; the hook asset creates none. |
| UIQ-05 | Admin-owned `storybook-axe.spec.js` / `storybook-axe.cjs`, independent `storybook-axe-approved.json` triage, and cold/warm `axe.json` receipts. | Exact 18 selected cases run in each condition. Violation approvals remain empty. Zero violations and zero untriaged findings do not convert the 50 incomplete findings per condition into passes. |

The scenario manifest distinguishes pure scenario facts from persisted projection agreement. Persisted checks cover `qv-delivery-single-unicode`, `qv-inbound-normal` and `qv-inbound-single-unicode`; `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` reads the scoped production projections. Other normal/boundary/unavailable stories are explicit rendering-only checks. `qv-delivery-empty` and `qv-inbound-empty` represent real absence and remain connected-route-only; no empty story fabricates a selected record. The nine rendered stories produce the exact 18-case Light/Dark Axe set.

## Bounded visual review and remaining limits

I reviewed the retained candidate captures `phase174/cold/delivery-light.png`, `phase174/cold/delivery-dark.png`, `phase174/warm/delivery-320-boundary-dark.png`, and `phase174/warm/inbound-1440-boundary-dark.png`. Light and dark keep the subject, outcome, recipient, time, Account/provider and technical identifier in a clear hierarchy. The selected navigation and close controls read as quiet controls with visible boundaries. At 320px, the subject and timestamp wrap and the panel continues vertically without visible horizontal spill. At the wide Inbound capture, the panel remains a contained reading column. The Storybook review-theme control crowds its own chrome at the top of the narrow capture; that is review chrome rather than quick-view content. This is a bounded, subjective review of selected Chromium captures, not an aesthetic score or a statement about all browsers/devices.

The 50 Axe incomplete findings per condition are retained and matched against the independent triage record; they remain incomplete machine results, not passes. No violation fingerprint is approved. The descriptorless transparency prohibition remains flagged-unverified; this evidence does not infer an owner approval. The serif StatCard feedback and real browser zoom were closed in Phase 178: the StatCard font-role receipt, the actual-200% zoom cases and the replay commands are recorded in `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#storybook-fidelity-and-real-zoom-uiq-06`. This review's own limits (Chromium only, selected captures, no owner aesthetic verdict) are unchanged. Focus, reduced-motion, width, theme, hook and keyboard evidence for the current repair is not deferred.

## Feedback disposition

The manifest is `reference/persona_spec/quick_view_scenarios.json`; its `feedback` entries and scenario IDs remain the inventory. Phase 174 owned the first two rows. Every row now carries the status and `evidence_pointer` the manifest records, and the merge-blocking test "Phase 178 ledger: no feedback row is pending or partial" in `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` keeps the open set empty:

| Feedback | Requirement(s) | Current status, evidence and scope |
| --- | --- | --- |
| `fb-quiet-quick-view-arrows` | UXF-11 | Resolved. Evidence: `mailglass_admin/docs/phase174-review.md#feedback-disposition`. Delivery and Inbound connected routes and the scenario IDs above. Delivery unavailable navigation is inert; Inbound unavailable navigation is natively disabled. |
| `fb-storybook-fidelity` | STORY-03–07 | Automated. Evidence: `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#storybook-fidelity-and-real-zoom-uiq-06`. Routes/assets, production CSS/fonts, both themes, hooks, connected cases and strict Axe comparison from Phase 174, plus the Phase 178 StatCard font-role receipt, STORY-07 set-wide accounting and actual-200% zoom at 320 CSS px. |
| `fb-suppression-refresh` | OUTUX-07, OUTUX-08 | Automated. Evidence: `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08`. Ready, empty, stale and unavailable suppression evidence with truthful retry and expiry language. |
| `fb-replay-review` | REPLAY-04–08 | Automated. Evidence: `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#replay-path-replay-04-through-replay-08`. Permitted, unavailable, denied, success and retry outcomes. |
| `fb-technical-details` | UXF-12 | Automated. Evidence: `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#technical-evidence-uxf-12`. Production stories and connected full-detail evidence on both surfaces. |
| `fb-auto-apply-filters` | FILTER-01–04 | Automated. Evidence: `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#observable-truths-roadmap-success-criteria`. Connected URL/history and Back/Forward cases for both lists (`connected-real-route-only`). |
| `fb-raw-source-hierarchy` | INUX-06 | Automated. Evidence: `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#requirements-coverage`. Reveal authorization and the safe source allowlist in connected evidence. |
| `fb-inbound-addresses` | INUX-05 | Automated. Evidence: `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#requirements-coverage`. Authorized long/Unicode, missing and multiple-address cases. |
| `fb-health-crowding` | OUTUX-06 | Automated. Evidence: `.planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md#health-composition-outux-06`. Health hierarchy and filtered deep-link comparison. |
| `fb-account-context` | UXF-09, UXF-10 | Automated. Evidence: `.planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md#account-scope-and-preview-return-uxf-09-uxf-10`. Scoped Health/collection and host-approved Preview return-route evidence. |
| `fb-preview-reset` | PRVUX-05, PRVUX-06 | Automated. Evidence: `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#preview-authoring-prvux-05-prvux-06`. Authoring and Restore defaults behavior with parsing and validation preserved. |
| `fb-preview-identity` | PRVUX-07 | Automated. Evidence: `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#readable-scenario-selector-prvux-07`. Long/Unicode and narrow selector identity evidence. |

All 12 rows are closed; the record of the rule, its teeth and the final status table is `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#feedback-ledger-uiq-04`.

## CI placement and cost disposition

The existing `demo_browser_evidence` job in `.github/workflows/ci.yml` runs `bash scripts/run_demo_browser_evidence.sh --phase174 --pilot` and uploads run-owned evidence with the existing 14-day retention. It is advisory and is not a dependency of `CI Green`. The live `main` branch-protection query on 2026-10-27 returned `strict: true` with required contexts `CI Green` and `Guard Release Trigger`; no aggregate policy or protected context changed.

The defensible same-profile baseline is successful main CI run [40414024714](https://github.com/szTheory/mailglass/actions/runs/40414024714), head `e326da4dfb59c3a20942acff763d04a79ada974b`, event `push`, attempt 1. Its same Demo evidence job [121891818059](https://github.com/szTheory/mailglass/actions/runs/40414024714/job/121891818059) ran on `ubuntu-latest` / one GitHub-hosted runner from `2026-10-26T22:45:46Z` to `2026-10-26T22:49:27Z`: 221,000 ms (3m41s).

Current candidate job [122170444350](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170444350) ran on `ubuntu-latest` / one runner from `2026-10-27T11:46:29Z` to `2026-10-27T11:55:24Z`: 535,000 ms (8m55s, 8.917 runner minutes). The observed same-job delta is **+314,000 ms (5m14s, 5.233 runner minutes)**. The provisional added PR wall budget of five minutes is exceeded by 14 seconds; the ten runner-minute budget is within limit by 4.767 minutes. This is an observational single-job comparison, not a causal estimate or a guarantee about CI critical-path latency. It includes runner/setup variance; the full hosted job timestamps, rather than scan-only intervals, define the measured cost.

Recommendation: keep the Phase174 pilot integrated into the existing advisory Demo Browser Evidence job rather than add a second CI lane. One lane shares checkout, one isolated Demo/Postgres service, and the cold/warm browser caches while retaining all 148 cases in both conditions. Re-measure the 14-second wall overage on a later run; optimize shared setup before considering any scope adjustment, and preserve every acceptance case and all Phase 174 cases in both conditions. Keep the current required gates.

The exact run was not merged, published or deployed. The completed overall workflow and independent `--require-ci` check are the final candidate proof; CI placement remains advisory.


## Final Cost Receipt Reconciliation

The enriched `ci/40498413906-attempt-1/phase174/cost.json` now records `added_cost.status: measured` for the **observed** same-profile job comparison, the retained baseline/current raw metadata, +314,000ms / 5.233 runner-minute delta, and the explicit wall-over-by-14s / runner-within-budget disposition. This does not claim causal incremental PR cost. `cost.downloaded.json` remains byte-for-byte original; `cost.before-baseline.json` preserves the intermediate hosted-only enrichment. `cost-baseline-enrichment.json` records the input hashes; `174-COST-DISPOSITION.json` in the phase directory retains the derived disposition/provenance. The strict hosted checker passed again after reconciliation. No execution identity, browser result or measured condition timing changed.
