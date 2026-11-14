# Phase 178 Cycle 04 Approval Record

## Candidate and snapshot

- Candidate SHA: `8e501960bc975ed44b632ba5c74522e0c5d66f8c`.
- Parent: `de799da72b9ebbce45bd1f358f8527b0c894cbe1`.
- Candidate source: `mailglass_admin/e2e/flows.spec.js`.
- Source SHA-256: `8c70eb703b75e098c4a9d827c2853ad3807e13e10e6b39177e3c1033dfddae87`.
- Remote target before action: `gsd/v2.10-ui-repairs-storybook` at `a0a7450cc68afe84e25e69276c654d9e63422499`.
- Remote `main`: `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`.
- PR #317: open/draft, base `main`, head `gsd/v2.10-ui-repairs-storybook`; title `chore(ui): v2.10 UI repairs review candidate (do not merge)`.
- Current remote PR-body SHA-256: `db3a36974c9ca33c8790f7c3c33f42fae526620b3f4f19a7a225f3b0f5d0d498`.
- Prepared body: `.planning/phases/178-preview-authoring-and-milestone-review/178-27-pr-body.md`.
- Prepared body SHA-256: `100325412ab6bd182526ded71a29c81d4baff5edd12a1b62e664bed342df42d4`.
- Release ledger SHA-256: `0818ee5db8ebfe737a7af89daeb79f01833929f72f58e918313c155df31f47a4`.
- Delta from remote `main`: 428 commits, 698 files, 219504 insertions, 2169 deletions.
- Delta from current target: 5 commits, 4 files, 556 insertions.

## Approved one-time operations

1. Push exactly the candidate SHA to `refs/heads/gsd/v2.10-ui-repairs-storybook` once.
2. After all push-triggered workflows pass, update only PR #317's body once from the prepared file.
3. After both body-edit workflows pass, dispatch `ci.yml` once on the target branch.
4. Maximum eight total workflow runs, each attempt 1: five on push (CI, Guard Release Trigger, PR Title, Actionlint, Advisory Matrix), two on body edit (Guard Release Trigger, PR Title), one explicit `ci.yml` dispatch. No retry, rerun, cancellation, or extra workflow run.
5. After all exact-SHA hosted gates and a separately reproducible, identity-bound cost disposition pass, launch the isolated candidate preview once.

~~~sh
git push origin 8e501960bc975ed44b632ba5c74522e0c5d66f8c:refs/heads/gsd/v2.10-ui-repairs-storybook
gh pr edit 317 --body-file .planning/phases/178-preview-authoring-and-milestone-review/178-27-pr-body.md
gh workflow run ci.yml --ref gsd/v2.10-ui-repairs-storybook
bash scripts/check_phase178_candidate.sh --sha 8e501960bc975ed44b632ba5c74522e0c5d66f8c --require-ci --record reference/demo_app/tmp/phase178_candidate/candidate-8e501960.json
~~~

## Bounded runner usage and stop rules

Maximum eight workflows, all attempt 1. Estimated usage is 254.62 runner-minutes from previously observed durations. This is a runner-time estimate, not a dollar quote. The prior GitHub timing API response of zero billable milliseconds did not establish actual financial cost.

Stop before the next operation if a workflow fails, times out, is missing or unclassified; any event/SHA/attempt differs; any ref, PR field/body, or release-ledger hash drifts; the run count exceeds eight; or the outcome is ambiguous. Do not retry, rerun, cancel, force-push, merge, release, publish, deploy, or change remote `main`.

The preview is conditional on all hosted gates and a reproducible, identity-bound cost disposition for this exact SHA. It must use the existing isolated loopback launcher and preserve the retained owner demo. Any failed condition means no preview.

## User approval

The user said, “Yes, I approve. Approve all,” and asked to follow the recommendations for unblocking Phase 178. This authorizes the exact-candidate recovery package, its eight-workflow cap, and the conditional preview only after hosted and cost gates pass. The older Cycle 03 authorization was limited to a rerun against `a0a7450...` and is not reused here.

## Excluded actions

No PR merge, release, publication, deployment, remote `main` mutation, hosted retry/rerun/cancel, or unapproved extra workflow is authorized.
