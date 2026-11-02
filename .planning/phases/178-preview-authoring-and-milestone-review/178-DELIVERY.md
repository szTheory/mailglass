# Phase 178 Cycle 06 delivery status

## Current status: blocked before owner preview

Cycle 06's single approved preview attempt for candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c` exited 1 during isolated demo startup. The candidate's lock pinned `nimble_options` 1.1.1 while Mix resolved 1.2.0; the Compose project did not become healthy. The retained exact-SHA CI lookup passed, but there is no live preview: no routes were checked, CSS identity was not checked, and page-marker checks did not run. The generated loopback URL `http://127.0.0.1:54666` is historical and unavailable.

Candidate evidence is retained at `reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/candidate-8e501960.json` (SHA-256 `444e8c576ab43fb447fd11da77581d60012ad2249550382635c4fb0b079c9380`) and `reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/candidate-8e501960.compose.log` (SHA-256 `b7ff3c2dc50db558e12c38ea7891a376dfba26677a556fa3557d6413657ec5c3`). Teardown completed at `2026-11-02T14:56:20.649Z`: the candidate Compose containers/network/volumes stopped, its worktree and run parent were removed, and its demo lock was restored to the candidate blob. The retained owner demo was untouched. The one attempt is consumed; no retry or relaunch is authorized by Cycle 06. See [178-CYCLE-06-SUMMARY.md](178-CYCLE-06-SUMMARY.md) and [178-RECOVERY-CYCLE-06.json](178-RECOVERY-CYCLE-06.json).

Plan 178-31 refreshed only the local demo lock entry from `nimble_options` 1.1.1 to 1.2.0. The locked dev dependency check and `mix compile --warnings-as-errors` passed. Hex's release metadata records 1.2.0 as inserted on 2026-11-02; the startup drift was separate from the unchanged `cowlib` 2.21.0 advisory ([Hex release metadata](https://hex.pm/api/packages/nimble_options/releases/1.2.0), [cowlib advisory](https://osv.dev/vulnerability/EEF-CVE-2026-43966)). The successful local repair does not change the candidate SHA, transfer the old hosted receipts to changed source, or renew preview authority. UIQ-08 remains open until a newly identified candidate has current exact-source CI and a fresh bounded approval for any preview attempt.

## Historical Cycle 04 delivery status

## Cycle 05 follow-up

Cycle 05 was approved for one exact-candidate attempt. The launcher exited 1 before Compose because it could not create the detached candidate worktree. No preview record or URL was produced, no candidate containers started, and no route/marker checks ran. The launcher's exit handler removed the temporary run parent; the owner demo was untouched. The one attempt is consumed. See [178-CYCLE-05-SUMMARY.md](178-CYCLE-05-SUMMARY.md) and [178-RECOVERY-CYCLE-05.json](178-RECOVERY-CYCLE-05.json). This remains a blocked handoff, not a review-ready preview.

**Status: blocked before owner preview.** The hosted candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c` passed the exact-SHA CI and cost gates. The single authorized isolated preview launch then exited 1 because one required route returned HTTP 302. The launcher attempt is consumed; no retry or relaunch was made. This is a failure record and handoff, not a review-ready preview or a ship recommendation.

## Candidate and hosted receipts

- Candidate: `8e501960bc975ed44b632ba5c74522e0c5d66f8c`.
- Draft PR: [#317](https://github.com/szTheory/mailglass/pull/317), still open/draft.
- Exact-SHA workflow dispatch: [CI run 41388571351](https://github.com/szTheory/mailglass/actions/runs/41388571351), attempt 1, success. CI Green, Demo Browser Evidence, Operator Browser Gate and Preview Capture Advisory passed.
- Pull request CI: [run 41386942453](https://github.com/szTheory/mailglass/actions/runs/41386942453), attempt 1, success. The PR Demo artifact identifies merge revision `ad7f7487023d863497dc49f09fd311805357dcb5`; the dispatch artifact identifies the exact candidate SHA.
- Cost and count evidence: [178-COST-DISPOSITION.json](./178-COST-DISPOSITION.json); reproducible output SHA-256 `1e3aa72678b2008e3249d42eada934ec2bda301c6f9732ed2e3d00403fc35665`. The supported D-12 overage applies only to this preapproved review cycle, with all gates and expected counts retained.

## Isolated preview result

The launcher ran once on 2026-11-02 against `http://127.0.0.1:53344`, using isolated project `mailglass-phase178-review-8e501960-20261102045729-58375`. The final record is `reference/demo_app/tmp/phase178_candidate/candidate-8e501960.json` (SHA-256 `29850312cdc0adb772d1541f9c81a9ee345f88b66e469464a2e535eb3f7cecf9`). It reports `ci_status=pass`, `final_status=fail`, and exit code 1.

These loopback addresses are historical and **are no longer serving**; candidate services were stopped after the failure:

| Route | Recorded result | Owner access |
|---|---|---|
| [`/dev/mail`](http://127.0.0.1:53344/dev/mail) | 200; redirected to `MailglassDemoWeb.Mailers.AccountMailer/invite_admin?width=768` | unavailable; candidate project removed |
| [`invite_admin`](http://127.0.0.1:53344/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin) | 200 | unavailable; candidate project removed |
| [`preview_authoring`](http://127.0.0.1:53344/dev/storybook/preview_authoring) | 200 | unavailable; candidate project removed |
| [`preview_chrome`](http://127.0.0.1:53344/dev/storybook/preview_chrome) | 200 | unavailable; candidate project removed |
| [`stat_card`](http://127.0.0.1:53344/dev/storybook/primitives/stat_card) | 200 | unavailable; candidate project removed |
| [`demo/login` return route](http://127.0.0.1:53344/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar) | **302; required route gate failed** | unavailable; reason/expected auth behavior not classified |

Built and served CSS hashes matched (`173fdd6fe2d7d06c322321796a6aba9a3e6508be4270fdc632dd7d4d364ff6b2`). Page-marker checks did not run after the route gate failed. The source CSS digest is retained separately in the candidate record.

## Resource and evidence disposition

- Candidate Compose containers, network and volumes: stopped/removed.
- Detached candidate worktree and run-parent directory: removed.
- `reference/demo_app/mix.lock`: restored to the candidate blob.
- Retained owner demo: not touched.
- Hosted logs and extracted evidence: preserved under ignored `reference/demo_app/tmp/phase178_candidate/recovery-cycle-04/`; no deletion or artifact-expiration claim is made here.
- Local candidate record: retained at the path above.
- Owner decision: none. No current preview is available to inspect and no aesthetic or ship/no-ship conclusion is inferred.

## Next actor

The Phase 178 owner/planner should inspect the `/demo/login` redirect contract and decide whether the preview setup should establish an authenticated session or whether this route's expected response needs clarification. Then create a scoped successor plan and obtain fresh approval for any new hosted or preview cycle. Cycle 04's one preview attempt is spent; do not rerun this candidate's launcher.
