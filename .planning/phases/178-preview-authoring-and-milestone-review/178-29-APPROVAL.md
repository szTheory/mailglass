# Phase 178 Cycle 05 Preview Approval

## Status

The user approved one attempt. It stopped before Docker Compose because Git could not create the detached candidate worktree. No retry is permitted under this approval.

## Candidate and evidence

- Candidate: `8e501960bc975ed44b632ba5c74522e0c5d66f8c`.
- Remote target: `gsd/v2.10-ui-repairs-storybook` at the same SHA; remote `main` remains `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`.
- PR #317 remains open and draft with the exact candidate at its head.
- The required exact-SHA CI contexts are green. The prior hosted and cost evidence remains bound to this exact candidate; cost disposition SHA-256 is `1e3aa72678b2008e3249d42eada934ec2bda301c6f9732ed2e3d00403fc35665`.
- Plan 29 fixed the local route probe: login runs first and every route shares a mode-0600 cookie jar inside a mode-0700 temporary directory. Both shell syntax checks and all 12 offline self-test checks passed. Independent review found no blockers.
- Launcher SHA-256: `e0ce9e159b69f7ee6289c040a6612520c18a70e8cc24ae2d0553535fae324d93`.

## The one operation requiring fresh approval

Cycle 04's one preview attempt is consumed. Its login route returned HTTP 302 because curl did not persist the synthetic session. Plan 29 fixes and locally verifies that issue. A new, exact-SHA local Docker preview is a separate one-time operation, so this checkpoint asks for direct approval before it runs.

```sh
bash scripts/check_phase178_candidate.sh --sha 8e501960bc975ed44b632ba5c74522e0c5d66f8c --require-ci --record reference/demo_app/tmp/phase178_candidate/recovery-cycle-05/candidate-8e501960.json
```

After a passing launch, I will fetch the documented Plan 178-23 review URLs from the loopback preview and verify their page markers and current CSS identity. The launcher’s `--require-ci` check is read-only; this operation authorizes no GitHub workflow or PR write.

## Resource and cleanup scope

- One candidate-scoped Docker Compose build and preview, with new loopback ports. A cache miss may download locked build inputs and use local CPU/disk; there is no new hosted runner spend or dollar estimate. The retained owner demo and unrelated containers, networks, and volumes remain untouched.
- On a passing result, keep the preview running for owner review and report the actual URL and teardown command.
- If the launch or any post-launch URL, marker, CSS, or CI check fails, preserve the record and run this candidate-bound teardown exactly once. A preflight failure before record creation has no candidate resources to clean up:

```sh
bash scripts/check_phase178_candidate.sh --teardown reference/demo_app/tmp/phase178_candidate/recovery-cycle-05/candidate-8e501960.json
```

- Teardown removes this candidate’s containers, network, volumes, worktree, and temporary run directory. It does not prune Docker images or global build cache. No machine-wide Docker cleanup will run.
- No push, PR edit, CI dispatch, retry, rerun, merge, release, publication, deployment, or change to remote `main` is included.

## Stop conditions

Recheck the candidate SHA, launcher hash, PR/head/base refs, required checks, release ledger, cost record, and Cycle 04 hash immediately before launch. If any value drifts, or if the single attempt or any required route, marker, CSS, or CI check fails, record the exact result and stop without retry.

## Decision

**Consumed; stopped before Compose.** The user approved one attempt and the exact command was invoked once. It exited 1 at detached worktree creation, before writing a candidate record or starting Compose. The temporary run parent was removed by the launcher's exit handler; no teardown invocation was needed. Cycle 05 does not authorize a retry.
