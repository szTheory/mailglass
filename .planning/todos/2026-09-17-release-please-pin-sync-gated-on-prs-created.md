---
created: 2026-09-17T16:54:00.000Z
title: release-please pin sync only runs when the proposal PR is first created
area: release-engineering
files:
  - .github/workflows/release-please.yml:332-333 (Sync sibling package -> mailglass dep pin)
priority: next-release
---

## Problem

The step that syncs sibling dep pins onto the release-please branch is
gated on `steps.release.outputs.prs_created == 'true'`:

```yaml
- name: Sync sibling package -> mailglass dep pin on release-please branch
  if: ${{ steps.release-preflight.outputs.should_run == 'true' && steps.release.outputs.prs_created == 'true' }}
```

`prs_created` is true only on the run that *opens* the proposal. Every
later run sees an already-open PR, skips the sync, and reports
`success`. So a pin fix merged to main after the proposal opened can
never reach the proposal branch.

That is exactly what happened before 2.6.0: #273 fixed the root
README's inbound pin, and release-please reported `success` three times
without touching the already-open #264. The proposal had to be synced
by a hand-pushed commit (`713d71cf`).

## Fix

Gate on *whether the branch is out of sync*, not on whether the PR was
just created — the pins need syncing whenever they disagree, which is
the condition the step already computes.

## Why this wasn't fixed inline

Flipping the condition means the workflow will push commits to the
proposal branch on runs where it previously did nothing. That is real
blast radius on the branch a release is cut from, and it interacts with
the candidate-digest capture: a push to the proposal head after capture
voids the capture. It deserves its own PR with that interaction thought
through, not a one-line edit slipped into a release.
