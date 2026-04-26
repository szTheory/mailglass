---
created: 2026-04-26T17:30:00.000Z
title: release-please `extra-files` generic updater silently no-ops on mix.exs (lessons-learned doc)
area: release-engineering
files:
  - .github/workflows/release-please.yml (current Path 2 fix lives here)
  - release-please-config.json (extra-files briefly added then reverted on main)
  - mailglass_admin/mix.exs:74-95 (comment block now references the workflow sed, not extra-files)
priority: documentation / lessons-learned
---

## What we learned during the v0.1.1 cycle

`mailglass_admin/mix.exs` declares `{:mailglass, "== 0.1.0"}` (Phase 7 D-03 /
DIST-01: sibling packages must move in lockstep). When release-please bumps
both packages to a new version, `@version` updates automatically (elixir
release-type built-in), but the strict `==` pin literal does **not**.

We tried the documented fix — adding `extra-files` with a `generic` updater
plus an `# x-release-please-version` annotation:

```json
"mailglass_admin": {
  "release-type": "elixir",
  "extra-files": [{ "type": "generic", "path": "mailglass_admin/mix.exs" }]
}
```

Two attempts (inline trailing comment AND standalone-line annotation form)
both **silently no-op'd**. release-please re-ran on each push, regenerated
the PR, and the `@version` line bumped — but the annotated `==` pin line
was untouched. No error, no log, no diff.

## Inferred root cause (not authoritatively confirmed)

The `elixir` release-type already claims `mix.exs` for `@version` updates.
When that same file is also listed under `extra-files`, the generic
updater appears to be silently skipped — likely to avoid double-managing
the file. We did not find this caveat in release-please docs; it surfaced
only by empirical test.

## Path 2 (what we actually shipped)

A post-step in `.github/workflows/release-please.yml` runs after the
`googleapis/release-please-action`, checks out
`release-please--branches--main`, reads the new version from
`.release-please-manifest.json`, runs `sed -E` on the dep pin literal in
`mailglass_admin/mix.exs`, and pushes a sync commit if the file changed.
Idempotent. Recursion-safe (GITHUB_TOKEN-authed pushes don't retrigger
workflows).

## Future work (not blocking)

1. **Confirm root cause with release-please maintainers.** Open an issue
   on googleapis/release-please asking whether `extra-files` generic
   updates on a release-type-managed file are intentionally suppressed
   and, if so, whether the docs can call this out.
2. **Re-evaluate Path 1 (separate version file)** in v0.2 if the workflow
   sed becomes brittle. A `mailglass_admin/.core-version` text file read
   by `mix.exs` would let release-please own it cleanly.
3. **Watch for release-please-action upgrades** that might fix this — if
   a future v4.x release supports cross-component version refs (issue
   #2655), the workflow sed becomes redundant.

## Why this matters

The workflow sed adds ~30 lines of YAML to `release-please.yml` and
couples the lockstep invariant to a regex that scans `mailglass_admin/mix.exs`.
It works, but it's a maintenance burden that didn't exist before — so when
someone adds a SECOND inter-package pin (e.g. `mailglass_inbound` arrives
in v0.5), they need to extend the sed step rather than just updating the
release-please config. Document this so future-us doesn't reinvent it.
