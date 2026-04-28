# Phase 13 Plan 04 Release Rehearsal

Date: 2026-04-28
Scope: Release Please v4 path, publish fallback semantics, smoke fallback semantics, and prepublish gate trustworthiness for `0.2.0`.

Rehearsal ref: mailglass-v0.1.1
Release Please run URL: https://github.com/szTheory/mailglass/actions/runs/24962941027
Publish rehearsal run URL: https://github.com/szTheory/mailglass/actions/runs/24963219717
Smoke evidence URL: https://github.com/szTheory/mailglass/actions/runs/24963360022
Outcome: workflow_dispatch-fallback-required
Fallback decision: workflow_dispatch for 0.2.0

## Evidence

- `gh release view v0.2.0` returned `release not found` on 2026-04-28. No `0.2.0` release exists yet.
- `gh run view 24963219717 --log` shows the successful rehearsal publish checked out `ref: mailglass-v0.1.1` in both `prepublish-summary` and `publish-core`, then published `mailglass 0.1.1` and `mailglass_admin 0.1.1`.
- `gh run view 24963360022 --log-failed` shows a downstream smoke failure on the older path where `VERSION=main`, leading to repeated `Waiting for Hex.pm to index mailglass main...` and eventual timeout.
- `gh run list --workflow publish-hex.yml` shows the last successful publish was `workflow_dispatch` run `24963219717` on 2026-04-26. Later downstream attempts were skipped `workflow_run` noise, not proof of a reliable automatic chain.
- `gh release list` shows the current package tags are `mailglass-v0.1.1` and `mailglass_admin-v0.1.1`, not `mailglass-sibling-group-v0.1.1`.

## Rehearsed Contract For 0.2.0

1. Stay on the pinned `googleapis/release-please-action` v4 workflow path for the real `0.2.0` cut.
2. Treat release PR diff review as mandatory before merge because the repo uses a custom dep-pin sync step for `mailglass_admin/mix.exs`.
3. If the GitHub Release fan-out triggers `publish-hex` automatically, proceed normally.
4. If the GitHub Release/tag exists but `publish-hex` does not trigger, dispatch `.github/workflows/publish-hex.yml` manually with:
   - `tag=mailglass-v0.2.0`
   - `package=both`
   - `dry_run=false`
5. If publish succeeds but smoke does not trigger, dispatch `.github/workflows/post-publish-smoke.yml` manually with:
   - `tag=mailglass-v0.2.0`
6. Do not dispatch either fallback from `main`. Use the reviewed release tag so the publish/smoke run is pinned to the same commit that Release Please tagged.

## Prepublish Gate Rehearsal

- `mix mailglass.publish.check --package mailglass` passed on 2026-04-28 after refreshing the stale allowlist for the real v0.2 tarball surface.
- `mix mailglass.publish.check --package mailglass_admin` passed on 2026-04-28 after fixing the local admin isolation path in `mailglass.publish.check` so temp compile/audit runs match published-mode dependency behavior.

## Residual Note For 13-05

The unresolved risk for the real cut is not GitHub auth or permissions; it is only whether the release event fans out automatically on the day. The canonical answer is now rehearsed: if fan-out is absent, use `workflow_dispatch` against `mailglass-v0.2.0` for publish and smoke.
