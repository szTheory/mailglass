# Phase 178 Plan 38 — Cycle 09 preview recovery

## Outcome

Completed exactly one newly authorized preview attempt for candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023` after attempt 2 stopped before Compose became healthy. The owner’s reply, “run once,” was recorded for attempt 3 only. Attempts 1 and 2 remain historical; their recorded objects and preserved evidence files still match their hashes.

The isolated preview started from the exact candidate SHA. The existing `desktop-linux` Docker builder remained selected and running through the dedicated temporary Buildx config. The launcher passed its six default route checks, its exact-SHA required-CI read, and the built-versus-served CSS check. A separate authenticated read verified all 17 planned review URLs and their page markers, with same-origin redirects and a 30-second cap per request.

## Resource disposition

- Preview: `http://127.0.0.1:65275`, loopback only; Compose project `mailglass-phase178-review-5ad5329a-20261102220948-70209` is running its `demo` and `demo_db` services for owner review.
- Owner demo: zero running containers before and after; its snapshot is unchanged. Unrelated services were not touched.
- Buildx: dedicated config removed after launch; the shared builder and cache were preserved.
- Evidence: launcher JSON and log were copied byte-for-byte into `reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/`. No Compose failure log was created.
- Clone and its candidate worktree are retained so Plan 24 can prepare the review checkpoint and use the same scoped teardown command.
- No workflow was dispatched, no CI was rerun, and no GitHub write, source edit, merge, release, publication, or deployment occurred.

## Handoff

The attempt-3 recovery record sets `plan24_eligible: true`. The preview remains running while Plan 24 creates the owner’s review checkpoint. The separate ship / no-ship / keep-running decision is still pending; this summary does not imply acceptance.
