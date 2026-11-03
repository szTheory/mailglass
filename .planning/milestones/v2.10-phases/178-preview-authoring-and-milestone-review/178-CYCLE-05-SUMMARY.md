# Phase 178 Cycle 05: Preview attempt stop summary

**Status:** Stopped before Docker Compose. The approved one-attempt authorization is consumed; UIQ-08 remains open.

## Approval and preflight

- The user approved one local preview attempt for candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`, with bounded read-only URL and marker checks if launch passed.
- The preflight matched the candidate, draft PR #317, remote refs, required CI, cost disposition, Cycle 04 record, and launcher hash. Docker server 29.5.2 was available; the owner-demo project had zero containers; the host reported 240 GiB available.
- Approval, source hashes, and preflight are recorded in [178-RECOVERY-CYCLE-05.json](178-RECOVERY-CYCLE-05.json).

## Launch result

The exact approved command was invoked once:

```sh
bash scripts/check_phase178_candidate.sh --sha 8e501960bc975ed44b632ba5c74522e0c5d66f8c --require-ci --record reference/demo_app/tmp/phase178_candidate/recovery-cycle-05/candidate-8e501960.json
```

It exited 1 before Compose with `could not create detached worktree at 8e501960bc975ed44b632ba5c74522e0c5d66f8c`. The launcher redirects `git worktree add` stderr, so the underlying Git error was not captured. No candidate record, Compose project, or preview URL was created. Route, CSS, GitHub check-run, and page-marker verification did not run.

## Cleanup and scope

- The launcher’s exit handler removed the temporary run parent. A read-only `git worktree list` contained only the main checkout; no recent `mailglass-phase178.*` directory remained.
- No teardown command was run because no candidate record or Compose resources existed. The owner demo was untouched.
- No retry, relaunch, hosted workflow, PR edit, or product/dependency change occurred. The one approved invocation is consumed.
- Cycle 04’s earlier HTTP 302 result remains intact. Cycle 05 does not replace or erase that evidence.

## Diagnosis and next action

The most likely cause is the delegated executor's read-only `.git` boundary: its later scoped `git add` was denied while creating `.git/index.lock` with `Operation not permitted`. This matches the failed worktree metadata write, but the launcher's suppressed Git stderr means the exact cause is not confirmed. Do not retry under Cycle 05. Before any future run, preserve Git's error output, execute only from a context with Git metadata write permission, and obtain a new plan and fresh one-attempt approval. Stop before owner review; there is no running preview to inspect.
