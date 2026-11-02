# Phase 178 Cycle 06 Preview Approval

## Status

Prepared for review. No Cycle 06 preview has been launched and no new authority is recorded.

## What happened and what changed

- Cycle 04's approved preview returned HTTP 302 because the route probe did not persist the synthetic login cookie. Plan 29 fixed that with a private shared cookie jar and passed its offline test/review.
- Cycle 05 was separately approved, but its only launcher invocation stopped before Compose at detached worktree creation. It created no candidate record or Docker resources, and its one-shot authority is consumed.
- The delegated executor later received `Operation not permitted` creating `.git/index.lock` in its read-only Git sandbox. That makes the sandbox a likely cause of the worktree failure, though the original Git error was hidden.
- Plan 30 now preserves Git's diagnostic on a future failure; both shell syntax checks and all 13 offline checks pass, and independent review found no blockers.

## Candidate and live preflight

- Candidate remains `8e501960bc975ed44b632ba5c74522e0c5d66f8c`; remote `main` and target refs are unchanged.
- PR #317 is open/draft at the exact candidate SHA. The required `CI Green` and `Guard Release Trigger` checks are completed successfully.
- The existing exact-candidate cost disposition is unchanged; no new hosted workflow or runner spend is included.
- Docker server 29.5.2 is available, the owner-demo project has zero containers, and the host reports 239 GiB available.
- Updated launcher SHA-256: `d876cb1ac3cdc2aad5c49e0368c35f591dbd9c430adf2c0027680c3780aacee7`.

## The one operation requiring fresh approval

Cycle 05 is consumed. If you approve this new checkpoint, I will run exactly once from the primary agent context (not the delegated read-only Git sandbox):

```sh
bash scripts/check_phase178_candidate.sh --sha 8e501960bc975ed44b632ba5c74522e0c5d66f8c --require-ci --record reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/candidate-8e501960.json
```

The updated launcher will include Git's underlying error if worktree creation fails again. If launch passes, I will fetch the documented Plan 178-23 URLs from the loopback preview, verify their page markers and current CSS identity, and leave the preview up for your review. The required CI lookup is read-only.

## Resources and cleanup

- The launch builds and starts one candidate-scoped Docker Compose project on loopback-only ports. A cache miss may download locked inputs and use local CPU/disk; there is no dollar estimate or new hosted runner cost.
- On any failure after a candidate record exists, preserve the result and run the record-bound teardown exactly once:

```sh
bash scripts/check_phase178_candidate.sh --teardown reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/candidate-8e501960.json
```

- If it fails before writing the record, the launcher exit trap removes its temporary run directory. Do not retry.
- Teardown removes this candidate's containers, network, volumes, worktree, and run directory. It leaves Docker images and global build cache alone.
- No push, PR edit, workflow dispatch, retry, rerun, merge, release, publication, deployment, global Docker prune, or owner-demo change is included.

## Decision

**Pending direct user approval.** Approving authorizes only the exact one-time local preview and bounded read-only URL/marker verification described here. Cycle 05's approval cannot be reused.
