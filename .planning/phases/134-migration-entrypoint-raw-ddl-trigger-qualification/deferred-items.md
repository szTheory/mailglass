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
