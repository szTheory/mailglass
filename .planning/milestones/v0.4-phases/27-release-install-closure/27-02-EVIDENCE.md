# Phase 27 — REL-18 Rehearsal Evidence (Deferred Proof B)

**Proof selected:** B (deferred to v0.4.0 release-event ship)
**Date deferred:** 2026-05-02
**Forward-pointer:** v0.4.0 milestone-close ship phase will capture the
  auto-triggered release.published smoke run as the canonical proof.

## Why deferred
- The logic in `cron-guard` and `publish-hex.yml` is already correct and verified. Running Proof A against v0.3.2 would falsely fail `consumer-install` because v0.3.2 ships pre-REL-17.

## Pre-shipping confidence
- Workflow YAML comments hardened (Tasks 1+2 of plan 27-02).
- cron-guard JS branching unchanged (already verified correct in RESEARCH.md §B1, §B5).
- Concurrency-group key byte-identical (Task 1 acceptance criteria).

## At v0.4.0 ship, capture
- Run URL of the release.published-triggered post-publish-smoke run.
- cron-guard outputs (`version` matches v0.4.0).
- consumer-install exit 0 (REL-17 fix is live in v0.4.0 artifact).
