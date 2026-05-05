# Phase 27-02 Summary

- **Trigger Contracts Updated**: Both `.github/workflows/post-publish-smoke.yml` and `.github/workflows/publish-hex.yml` header comments were hardened to explicitly label the `release.published` event as the canonical version-source path, and `workflow_dispatch` as fallback-only, using version-agnostic phrasing.
- **Concurrency Key Preserved**: The concurrency-group key in `post-publish-smoke.yml` remains byte-identical to its pre-edit value.
- **Cron-Guard Logic Preserved**: The `cron-guard` JS branching logic was left completely untouched (only comments were updated).
- **Rehearsal Proof**: Captured deferred Proof B in `.planning/phases/27-release-install-closure/27-02-EVIDENCE.md`, forward-pointing to the v0.4.0 milestone-close ship phase as the canonical proof.