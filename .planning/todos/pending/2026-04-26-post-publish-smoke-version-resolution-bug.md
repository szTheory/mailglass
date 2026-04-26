---
created: 2026-04-26T18:10:00.000Z
title: post-publish-smoke.yml resolves VERSION=main instead of the actual published version
area: release-engineering
files:
  - .github/workflows/post-publish-smoke.yml (the VERSION resolution step)
  - .github/workflows/publish-hex.yml:38-44 (related: same head_branch architectural bug)
priority: v0.1.2
---

## Problem

`post-publish-smoke.yml` is supposed to validate, after publish-hex
completes, that adopters can actually install the published package
(runs `mix mailglass.install` against a fresh Phoenix host, asserts the
installer succeeds, asserts `mix deps.get` resolves, etc.).

The job is correctly triggered by `workflow_run` on publish-hex
completion, BUT it resolves the version literal from
`${{ github.event.workflow_run.head_branch }}`, which is the BRANCH the
publish-hex workflow ran on — always `"main"` for our trigger pattern,
NEVER the tag (e.g. `mailglass-v0.1.1`).

Empirical evidence (v0.1.1 cycle, 2026-04-26):

```
env:
  VERSION: main
##[endgroup]
Waiting for Hex.pm to index mailglass main...
Waiting for Hex.pm to index mailglass main...
Waiting for Hex.pm to index mailglass main...
[5 minute timeout]
Smoke aborted: Hex.pm did not index mailglass main within 5 minutes.
```

Note the empty version literal in the auto-opened tracker comment too:
> "post-publish-smoke failure detected for v."

The package WAS published successfully (mailglass 0.1.1 + mailglass_admin
0.1.1 are live on Hex.pm + HexDocs returns 200). The smoke failure is a
false negative caused by VERSION resolution, not by an actual smoke
regression.

## Root cause

Same architectural pattern as the publish-hex gate bug captured in
`2026-04-26-publish-hex-workflow-run-gate-cant-detect-tag-creation.md`:
`workflow_run.head_branch` is the branch the upstream workflow's HEAD
commit lives on, not the ref the workflow was dispatched against. When
publish-hex.yml is triggered via `workflow_dispatch` with input `tag=
mailglass-v0.1.1`, the upstream workflow's `head_branch` is still
`main`.

## Fix options

### Option A — Resolve from publish-hex's input

If publish-hex.yml is the upstream, post-publish-smoke can read
publish-hex's `inputs.tag` from the workflow_run event payload:

```yaml
- name: Resolve version
  id: version
  run: |
    TAG="${{ github.event.workflow_run.head_branch }}"
    # Try inputs first if available
    if [ -n "${{ github.event.workflow_run.event.inputs.tag }}" ]; then
      TAG="${{ github.event.workflow_run.event.inputs.tag }}"
    fi
    VERSION=$(echo "$TAG" | sed -E 's/^mailglass(_admin)?-v//')
    echo "version=$VERSION" >> $GITHUB_OUTPUT
```

(Pseudocode — exact GitHub Actions syntax for nested `event.inputs.tag`
needs verification.)

### Option B — Switch publish-hex to push:tags trigger

If the publish-hex gate bug TODO is resolved by switching publish-hex
to `on: push: tags: ['mailglass-v*', 'mailglass_admin-v*']`, then
`workflow_run.head_branch` for post-publish-smoke would be the tag
itself (e.g. `mailglass-v0.1.1`), which is parseable. Both bugs collapse
into a single fix.

### Option C — Read version from .release-please-manifest.json on the tagged SHA

```yaml
- uses: actions/checkout@<sha>
  with:
    ref: ${{ github.event.workflow_run.head_sha }}
- name: Resolve version
  run: |
    VERSION=$(jq -r '.["mailglass_admin"]' .release-please-manifest.json)
    echo "VERSION=$VERSION" >> $GITHUB_ENV
```

This sidesteps both bugs by reading from the canonical version source
(the manifest at the tagged commit) rather than from event metadata.

## Recommendation

**Option B**, paired with the publish-hex gate fix. Switching publish-hex
to a tag-push trigger is the cleanest approach for both workflows and
matches the standard pattern for Hex/npm publish flows. After that
change, post-publish-smoke just parses the tag (`mailglass-v0.1.1` →
`0.1.1`) and the version-resolution code becomes trivial.

## Acceptance criteria

- post-publish-smoke for v0.1.2 publish reads `VERSION=0.1.2`, NOT
  `VERSION=main`.
- The "Wait for Hex.pm index" job completes (or times out) against the
  correct version literal.
- The auto-opened tracker issue, if any, includes the actual version in
  its body ("post-publish-smoke failure detected for v0.1.2", not "for v.").

## Belt-and-suspenders

Add an early validation step that fails fast if VERSION doesn't match
`^[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?$`:

```yaml
- name: Validate VERSION resolution
  run: |
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?$ ]]; then
      echo "::error::VERSION='$VERSION' is not a valid semver — refusing to run smoke."
      exit 1
    fi
```

Catches version-resolution drift in <1s instead of after a 5-minute
"Wait for Hex.pm index" timeout.
