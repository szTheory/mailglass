---
created: 2026-04-26T17:43:00.000Z
title: publish-hex.yml workflow_run gate never matches — auto-publish on tag creation is dead code
area: release-engineering
files:
  - .github/workflows/publish-hex.yml:38-44 (broken gate condition)
priority: v0.1.2
---

## Problem

The `publish-hex.yml` workflow's `prepublish-summary` job conditional is:

```yaml
if: |
  github.event_name == 'workflow_dispatch' ||
  (github.event_name == 'workflow_run' &&
   github.event.workflow_run.conclusion == 'success' &&
   (startsWith(github.event.workflow_run.head_branch, 'mailglass-v') ||
    startsWith(github.event.workflow_run.head_branch, 'mailglass_admin-v')))
```

The intent (per STATE.md narrative for v0.1.0): "publish-hex.yml's
workflow_run trigger fires correctly now (gate fix from `217f93c` matches
`mailglass-v*` head_branch)" — i.e., when release-please creates the
`mailglass-v0.1.X` and `mailglass_admin-v0.1.X` tags after a release-PR
merge, publish-hex would auto-fire and pass the gate.

**This never works.** `workflow_run.head_branch` is the branch the
*triggering workflow* ran on. `release-please.yml` runs on `push: branches:
[main]`, so its `head_branch` is always literally `"main"` — not the tag
it just created. The `startsWith(..., 'mailglass-v')` check therefore
never matches, and every workflow_run-triggered publish-hex invocation
gets skipped (verified empirically across v0.1.0 and v0.1.1 cycles —
three skipped runs visible in the actions log on 2026-04-26).

**v0.1.0 and v0.1.1 only published because we manually invoked**
`gh workflow run publish-hex.yml --ref main -f tag=mailglass-v0.1.X -f package=both -f dry_run=false`
which goes through the `workflow_dispatch` arm of the conditional and
trivially passes.

The auto-fire-on-tag-creation path is dead code disguised as a feature.

## Why this matters for v0.1.2+

Two real costs:

1. **Maintainer overhead.** Every release ships requires a manual
   workflow_dispatch step that's not currently in the maintainer runbook
   except as a fallback. For a project that prides itself on shipping
   often, this is a needless papercut.
2. **Misleading STATE.md handoff.** The v0.1.1 resume sequence said "the
   whole publish flows from PR merge — you do not need to manually
   dispatch." That advice was wrong, and a future maintainer (or AI agent
   resuming work) would lose 10–30 minutes diagnosing the silence before
   realizing they need to dispatch.

## Solutions

### Option A: Switch publish-hex trigger to tag pushes directly

Replace the `workflow_run` trigger with `push: tags: ['mailglass-v*', 'mailglass_admin-v*']`:

```yaml
on:
  push:
    tags:
      - 'mailglass-v*'
      - 'mailglass_admin-v*'
  workflow_dispatch:
    # ... existing inputs ...
```

Then drop the `head_branch` startsWith check entirely. The trigger itself
guarantees the run is for a release tag.

Caveat: `gate-ci-green` (publish-hex.yml:80–105) currently resolves the
SHA from `context.payload.workflow_run?.head_sha` — needs to fall back
to `github.sha` (the tag's commit) for `push: tags`.

### Option B: Keep workflow_run, fix the gate to query tags pointing at head_sha

Replace the `head_branch` check with a step that queries
`https://api.github.com/repos/.../git/matching-refs/tags/mailglass-v` and
checks any tag points at `workflow_run.head_sha`. More complex but
preserves the current event topology.

### Option C: Add a sibling-group workflow_run watcher

The `release-please` action also creates a `mailglass-sibling-group-v*`
tag (per the linked-versions plugin's component name in
release-please-config.json). That tag has the right shape for a
`push: tags: ['mailglass-sibling-group-v*']` trigger. Could simplify by
gating on that single tag instead of two.

## Recommendation

**Option A.** Tag-push triggers are the standard pattern for Hex/npm
publish workflows; the indirection through `workflow_run` exists to
sequence after release-please completes successfully, but in practice
release-please's tag creation IS the success signal we care about — by
the time the tag exists on the repo, release-please has finished its
work. Skip the indirection.

The `gate-ci-green` job's CI-green check can stay as-is; it just needs
a small tweak to resolve the SHA from `github.sha` (the tag's commit)
rather than from `workflow_run.head_sha`.

## Acceptance criteria for the fix

- Push of v0.1.2 tags auto-fires publish-hex.yml without manual dispatch.
- Maintainer runbook updated to reflect the new flow (no manual
  workflow_dispatch step needed).
- STATE.md / .planning/ docs that reference the manual dispatch command
  are updated.

## Belt-and-suspenders

When fixing this, also add a self-check step at the start of publish-hex
that fails loudly if the trigger's effective tag doesn't match the tag
being published. e.g., `if [[ "$GITHUB_REF" != refs/tags/mailglass-v* ]];
then exit 1; fi`. Prevents silent regressions if the trigger is
restructured again later.
