# Phase 44 Deferred Items

Items discovered during Phase 44 execution that are out of scope but
should be tracked for follow-up.


## 2026-05-07 (Plan 44-02 execution)

- `mailglass_inbound/_build/` and `mailglass_inbound/deps/` show as
  untracked when the inbound package is built locally. The root
  `.gitignore` covers root-level `_build/` and `deps/` but not the
  per-package counterparts. Add a `mailglass_inbound/.gitignore` (or
  extend the root ignore with `**/_build/`, `**/deps/`) so test
  runs don't dirty the working tree. Pre-existing — not caused by
  this plan.
