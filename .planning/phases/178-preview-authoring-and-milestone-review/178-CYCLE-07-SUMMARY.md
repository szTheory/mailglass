# Phase 178 Cycle 07 Summary

Cycle 07 stopped on a required exact-SHA CI failure after the approved push and PR body update; no dispatch, cost disposition, or preview was performed.

## Candidate and approval

- Candidate: `13451885d680b0f28d80792518dcd1733c8ec0e6`.
- The owner reply was recorded at `2026-11-02T16:09:10Z`: “Okay, yeah, let's follow your recommendations.” It approved the listed hosted package and separately approved one isolated preview only if the hosted and cost gates passed.
- The final read-only snapshot still matches the approved candidate: remote `main` is `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`; target `gsd/v2.10-ui-repairs-storybook` and PR #317 head are the candidate SHA; PR #317 remains open and draft with base `main`; the prepared PR body SHA-256 is `a8b18d420a3ed8bffe68a6019bc59b452b8a0744f4691ceee809df496de7eeba`; release-ledger SHA-256 is `0818ee5db8ebfe737a7af89daeb79f01833929f72f58e918313c155df31f47a4`.

## Operations and hosted results

| Run | Event | Result | Evidence |
|---|---|---|---|
| [41478814538](https://github.com/szTheory/mailglass/actions/runs/41478814538) | `pull_request_target` — PR Title | success, attempt 1 | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478814538.raw.json) |
| [41478819174](https://github.com/szTheory/mailglass/actions/runs/41478819174) | `pull_request` — CI | **failure, attempt 1** | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478819174.raw.json) |
| [41478819194](https://github.com/szTheory/mailglass/actions/runs/41478819194) | `pull_request` — Guard Release Trigger | success, attempt 1 | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478819194.raw.json) |
| [41478819198](https://github.com/szTheory/mailglass/actions/runs/41478819198) | `pull_request` — Advisory Matrix | success, attempt 1 | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478819198.raw.json) |
| [41478819249](https://github.com/szTheory/mailglass/actions/runs/41478819249) | `pull_request` — Actionlint | success, attempt 1 | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478819249.raw.json) |
| [41478910346](https://github.com/szTheory/mailglass/actions/runs/41478910346) | PR body edit — Guard Release Trigger | success, attempt 1 | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478910346.raw.json) |
| [41478912737](https://github.com/szTheory/mailglass/actions/runs/41478912737) | PR body edit — PR Title | success, attempt 1 | [run JSON](../../../reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/run-41478912737.raw.json) |

The one non-forced push advanced the target from `8e501960bc975ed44b632ba5c74522e0c5d66f8c` to the candidate. The one PR #317 update changed only the body. The body edit produced the two expected `edited` workflows shown above. All seven runs used attempt 1 and the candidate SHA, within the eight-run limit.

The CI run completed with `Support Contract Admin` and `CI Green` failed. The required job log records 1,205 tests, two failures, and one excluded test. Both failures are in `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs`:

- “normal Inbound facts match the scoped production projection at position 3 of 6” expected `page.total_count == 6`, but got `0`.
- “Unicode Inbound facts stay exact and foreign Account rows remain excluded” expected one persisted entry, but `page.entries` was empty.

The log also reports that `inotify-tools` was unavailable to the FileSystem worker; the two assertions do not establish that warning as their cause. The `Demo Browser Evidence` job succeeded and its artifact was retained. The required Support Contract Admin failure stopped the cycle, so no `ci.yml` dispatch was issued.

## Cost and preview disposition

- Hosted operations spent: one push, one PR body update, zero dispatches, seven attempt-1 workflow runs. No retries or reruns occurred.
- Cycle 07 cost is `not_measured`; no `178-CYCLE-07-COST-DISPOSITION.json` was created. Reproducibility and identity binding remain false, the cost gate remains unevaluated, and preview eligibility is false.
- The separately approved preview remained conditional on passing hosted and cost gates. It was not launched; no local Docker or preview action occurred.
- UIQ-08 remains open. Plans 23 and 24 remain blocked.

## Retained evidence and next actor

Raw run, job, artifact metadata, and available job logs are retained under `reference/demo_app/tmp/phase178_candidate/recovery-cycle-07/`. The hosted evidence manifest has 255 entries (SHA-256 `d9b4320d0e5f5f0ef64e6dabf813eab2d183a21f57b10648ded8b0a1d48b372a`); the job-log manifest has 37 entries (SHA-256 `2e091620beb04f321d8ed2e4ea492a034a6527880bbb773ad0cf3bd1746bf4a8`); the downloaded CI artifact manifest has 192 entries (SHA-256 `41bc4701ee28f93324bf8e3c653b6592bff2c1ed5815d961b63d7aab70451fe4`). The failed-job log SHA-256 is `cb8b7d08dbb8d6570a25b1d56eaf36c2fc8ba19ab9ccbdc9c1ee38e05ae4a5ae`.

Next, the owner/planner should address the QuickViewProjection support-contract regression and prepare a new candidate and fresh bounded approval before any further hosted or preview operation. Cycle 07 authority is spent for the push and PR body update; its dispatch and preview conditions were not met.
