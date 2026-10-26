---
phase: 173
status: gaps_found
candidate_sha: 8b4ce3e9643dd1b6a64cc5c96213245bb284512a
branch: gsd/phase-173-delivery-8b4ce3e9
run_id: 38064299090
attempt: 1
event: workflow_dispatch
run_status: completed
required_ci_green: failure
observed_at: 2026-10-10T16:21:57Z
---

# Phase 173 approved remote CI evidence

This records the original failed run for `8b4ce3e9`. The verified repairs and current candidate `cea2f46a` are recorded in `173-CI-REPAIRS.md`; current exact-SHA CI passed.

The user explicitly approved publishing exact candidate `8b4ce3e9643dd1b6a64cc5c96213245bb284512a` to a new branch and dispatching the existing CI workflow on that branch. The push and dispatch completed successfully. [CI run 38064299090](https://github.com/szTheory/mailglass/actions/runs/38064299090), attempt 1, confirms the exact SHA and branch above. It was created at 2026-10-10T15:36:31Z.

The required [`CI Green` aggregate](https://github.com/szTheory/mailglass/actions/runs/38064299090/job/114249978449) completed with **failure** at 2026-10-10T15:43:18Z. Its script rejected all nine failed required lanes listed below. Phase 173 and UIQ-03 remain incomplete. This replaces the earlier absence of CI evidence with an actual failed exact-SHA result; it does not invalidate the narrower passed local gate in `173-LOCAL-GATE.md`.

## Confirmed required failures

These causes come from the exact completed job logs, not inferred from the workflow's overall status.

| Required lane | Job ID | Confirmed cause |
|---|---|---|
| Format Check | 114248733355 | `mix format --check-formatted` rejects three test files: `test/mailglass/docs/unsubscribe_guide_test.exs`, `test/mailglass/docs_contract_test.exs`, and `test/mailglass/compliance/unsubscribe_controller_test.exs`. |
| Support Contract Core | 114248733384 | Stops at `Install demo deps`: `mix deps.get --check-locked` reports that the demo `mix.lock` is out of date. No core support tests ran in this job. |
| Core Deterministic Suite | 114248733549 | Also stops at `Install demo deps` with the same lockfile error; the full deterministic suite did not run. |
| Mix Task Tests | 114248733414 | 492 tests, three failures: test-exception registry line drift, plus two icon-gate fixtures inheriting the real conformance failures. |
| Support Contract Admin | 114248733662 | 605 tests, one failure and one exclusion. The preview-capture dry-run test uses explicit mailables rejected by the CI-only HappyMailer restriction. |
| Credo Strict | 114248733525 | Static-analysis ledger rejects a new CyclomaticComplexity exception for `Mailglass.Renderer.extract_heading_node` in `lib/mailglass/renderer.ex`. |
| Design System Conformance | 114248733492 | Missing vendored `hero-x-mark`; raw `z-20` and `focus:outline-none`; five arbitrary sizing classes. Motion conformance passes. |
| Docs Warnings as Errors | 114248733474 | `docs/api_stability.md` links to hidden functions `Deliveries.get_delivery/2`, `Timeline.get_delivery_event/3`, and `SupportSummary.read_failed_ingest/1`. ExDoc warnings fail the job. |
| Dialyzer | 114248733600 | `contract_supertype` warnings for `SupportSummary.get_webhook_event/2` and `get_unmatched_event/2`; the retry then fails because its removed PLT was not recreated. |

The stale registry entries are unsubscribe-controller lines 163/278 versus actual 192/337, and docs-contract line 746 versus actual 804. Formatting will move these lines further, so regenerate/check the registry after final formatting rather than preserving these intermediate numbers.

Conformance locations in this exact candidate:

- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`: identity max widths at lines 254/261; scope dropdown's redundant `z-20` and arbitrary width at line 279.
- `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex:28`: raw focus utility alongside the shared focus class.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:41`: arbitrary maximum width. The earlier inbound-path attribution was incorrect.
- `mailglass_admin/lib/mailglass_admin/components.ex:164`: arbitrary toast maximum width.

## Independent browser jobs

The demo browser evidence job (114248733575) failed because `baseline-dashboard-7e372023-375-light.png` was missing or invalid. The local candidate launcher explicitly validates and transfers six pinned baseline buffers before capture; the CI wrapper lacks that local preparation. This is a separate evidence-provisioning gap. Preserve baseline identity and validation when fixing it; regenerating arbitrary baselines is not equivalent evidence.

Preview Capture Advisory (114248733572) passed. Operator Browser Gate (114248733486) completed successfully at 2026-10-10T15:51:12Z: 210 passed and one guarded skip. The full workflow is now completed/failure. Neither independent browser job is a dependency of the current required `CI Green` aggregate.

## Bounded repair route

The user requested implementation of this bounded repair route. Work is in the isolated sparse worktree `/private/tmp/mailglass-phase173-ci-repair-lw4_w1ad/candidate`, based on exact original candidate `8b4ce3e9`, preserving the original workspace edits and both protected-path exclusions. Repairs and local verification are in progress; a changed candidate still requires fresh exact-SHA evidence.

1. Reconcile demo dependency requirements with its lockfile; preserve `--check-locked` and prove both workspace and isolated Hex modes.
2. Repair the design token/icon violations and preserve the existing conformance gates.
3. Format the three tests, then update the exception registry to the final line positions without adding exclusions or extending expired exceptions.
4. Correct the preview-capture test's CI environment contract while preserving the production restriction.
5. Reduce the renderer's flagged complexity and correct hidden-function doc references. The actual Dialyzer cause is the Repo facade's struct-only return specifications, which are incorrect for Ecto map/scalar selections. Correct those specifications, remove resolved stale ignore entries, and repair the retry so it actually rebuilds the PLT.
6. Supply CI's exact pinned baseline set with existing byte/manifest checks intact.
7. Run the affected checks and full candidate gate in the established sparse path-safe context. A changed candidate requires fresh exact-SHA local evidence and required CI, followed by authenticated owner acceptance.

This outline does not establish completion. Local and remote verification must finish before the changed candidate can be claimed as passing.

## Authorization and retained resources

The user's approval covers the completed exact-SHA branch push and CI dispatch. No merge, release, main write, branch-protection change, owner acceptance, or access to the two protected original demo files was performed. No product source or CI gate was changed during this operation. The retained preview remains at [http://127.0.0.1:63769/dev/mail](http://127.0.0.1:63769/dev/mail); its detached candidate and older retained previews were preserved.

All CI operations used `scripts/ci_monitor.cjs`. Because the repository monitor lacks dispatch and active-run job-log commands, an ephemeral copy at `/private/tmp/mailglass-phase173-ci-_pxlqc7v/ci_monitor.cjs` added the exact approved dispatch and read-only job-log API commands; the tracked script was unchanged.

Local observation files:

- `/private/tmp/mailglass-phase173-ci-inspect-38064299090.json`
- `/private/tmp/mailglass-phase173-ci-watch-1791646662224.log`
- `/private/tmp/mailglass-phase173-ci-green-38064299090-live.log`
- `/private/tmp/mailglass-phase173-ci-{format,design,demo-deps,docs,credo,mix-task,admin,dialyzer,browser-evidence}-38064299090-live.log`

The remote job URLs and exact SHA are the durable identities. Temporary local logs are diagnostic copies, and the completed local-gate JSON remains a historical snapshot of its own run.
