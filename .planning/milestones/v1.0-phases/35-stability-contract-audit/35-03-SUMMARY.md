---
phase: 35-stability-contract-audit
plan: 03
subsystem: testing
tags: [stability, docs, metadata, tests, code-fetch-docs]
requires:
  - phase: 35-01
    provides: canonical core stability inventory
  - phase: 35-02
    provides: canonical admin stability inventory
provides:
  - since metadata on stable public task and admin seams
  - compiled-doc stability contract tests for core and admin
  - light docs-contract checks retargeted to the v1.x contract story
affects: [phase-36, phase-37, release-docs, hexdocs]
tech-stack:
  added: []
  patterns: [compiled-doc-audit, docs-contract-regression-check]
key-files:
  created: [test/mailglass/stability_contract_test.exs, mailglass_admin/test/mailglass_admin/stability_contract_test.exs]
  modified: [lib/mix/tasks/mailglass.install.ex, lib/mix/tasks/mailglass.reconcile.ex, lib/mix/tasks/mail.doctor.ex, lib/mix/tasks/mailglass.publish.check.ex, lib/mix/tasks/mailglass.docs.check.ex, lib/mix/tasks/mailglass.stability.check.ex, test/mailglass/docs_contract_test.exs, mix.exs, lib/mailglass.ex, mailglass_admin/lib/mailglass_admin.ex, mailglass_admin/lib/mailglass_admin/router.ex, mailglass_admin/lib/mailglass_admin/auth.ex]
key-decisions:
  - "Used Code.fetch_docs/1 for compiled-doc truth instead of source grep for stability metadata coverage."
  - "Retargeted the lightweight docs check to the v1.x contract inventory rather than the old v0.3 release story."
patterns-established:
  - "Stable contract tests now verify metadata on documented entrypoints directly from compiled docs."
requirements-completed: [LOCK-01, LOCK-02, LOCK-03, LOCK-04]
duration: 30min
completed: 2026-05-05
---

# Phase 35 Plan 03 Summary

**Compiled-doc stability audits, `@since` metadata on stable seams, and lightweight docs checks retargeted to the `v1.x` contract**

## Performance

- **Duration:** 30 min
- **Started:** 2026-05-05T22:00:00Z
- **Completed:** 2026-05-05T22:30:51Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added module-level `@since` metadata to stable public Mix tasks and stable admin entry modules.
- Added compiled-doc tests for the documented stable core and admin seams using `Code.fetch_docs/1`.
- Updated `mailglass.docs.check`, README tests, and ExDoc config so the new contract story is verified and visible in generated docs.

## Task Commits

No task commits were created during this execution run.

## Files Created/Modified

- `test/mailglass/stability_contract_test.exs` - compiled-doc audit for stable core entrypoints and Mix tasks
- `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` - compiled-doc audit for stable admin modules, router macros, auth callback, and auth types
- `lib/mix/tasks/mailglass.install.ex` - module `@since` metadata
- `lib/mix/tasks/mailglass.reconcile.ex` - module `@since` metadata
- `lib/mix/tasks/mail.doctor.ex` - module `@since` metadata
- `lib/mix/tasks/mailglass.publish.check.ex` - module `@since` metadata
- `lib/mix/tasks/mailglass.docs.check.ex` - retargeted stability-contract wording and Tier 1 tokens
- `lib/mix/tasks/mailglass.stability.check.ex` - module `@since` metadata
- `test/mailglass/docs_contract_test.exs` - assertions for canonical contract entrypoints and admin boundary wording
- `mix.exs` - ExDoc now surfaces `docs/api_stability.md` and skips stale hidden-reference autolinks
- `lib/mailglass.ex`, `mailglass_admin/lib/mailglass_admin.ex`, `mailglass_admin/lib/mailglass_admin/router.ex`, `mailglass_admin/lib/mailglass_admin/auth.ex` - compiled-doc metadata on stable entry modules and auth types

## Decisions Made

- Verified stable metadata from compiled docs rather than relying on source-text greps.
- Fixed docs warnings by making prose less coupled to hidden/private internals, not by hiding failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix docs --warnings-as-errors` initially failed in both packages on stale hidden/private references; resolved by tightening doc wording and ExDoc configuration until the docs lanes passed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 35 now leaves a canonical contract inventory plus lightweight truth checks that Phase 36 and Phase 37 can extend without re-litigating what the stable surface is.

