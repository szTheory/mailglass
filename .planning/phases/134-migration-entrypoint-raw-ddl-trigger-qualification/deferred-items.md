# Deferred Items — Phase 134

Out-of-scope discoveries logged during execution (not fixed — scope boundary).

## Pre-existing format drift (Phase 133 files)

- `test/mailglass/repo_test.exs` — `mix format --check-formatted` flags this file
  (blank-line + keyword-list bracket-style drift). Last touched by commit `c7d7cd97`
  (`test(133-01)`), NOT by any Phase 134 change. Out of scope.
- `lib/mailglass/outbound.ex` — same: flagged by `mix format --check-formatted`,
  last touched by `a3abe87f` (`feat(133-01)`). Out of scope.

These do not block Phase 134's own files (all Phase-134-modified files are format-clean).
A follow-up `/gsd-quick` `mix format` sweep should clean them.

## Pre-existing credo `--strict` warning (Plan 134-03)

- `mailglass_inbound/lib/mailglass_inbound/application.ex:12` — `NoPlanningArtifactComments`
  flags a `D-15` planning-artifact token in a comment. This file was NOT touched by any
  Phase 134 change; the warning pre-exists. Out of scope for Plan 134-03 (whose credo work
  is the new `NoSchemaPrefixAttribute` guard, which is clean). A follow-up should rewrite
  the comment to behavior-focused rationale (drop the `D-15` token).

