---
created: 2026-09-16T17:30:00.000Z
title: Enforce commit-type discipline for release-triggering paths
area: release-engineering
severity: minor
files:
  - release-please-config.json
  - .github/workflows/release-please.yml
  - CONTRIBUTING.md
---

## Problem

Two defects that `exclude-paths` cannot reach, both found while fixing the core
package's path claim (quick task `260916-i5g`, #263 → `ff52bb66`).

### 1. `feat:` on a docs-only change proposes a minor version

Closed proposal #222 offered `mailglass_inbound 2.3.0`. Its sole driving commit
was `d272e824`:

```
feat(164-03): clarify current package compatibility
 mailglass_inbound/README.md | 2 +-
```

A two-line README edit. It sits **inside** `mailglass_inbound/`, so it is a
genuine package-path change — `exclude-paths` correctly does not filter it, and
widening the inbound entry would wrongly exclude the package's own README.

The root cause is the commit **type**, not the path. release-please derives the
bump from the conventional-commit type alone and never inspects which files
changed. `feat:` means minor, whatever it touched. A README-only change should
be `docs:`.

There is no config-level fix. `changelog-sections` with `hidden: true` suppresses
an entry from the rendered changelog but still bumps the version, so it does not
solve this.

### 2. Literal `\n` escapes in commit subjects

Several phase-164 commits carry uninterpreted escape sequences in their subject
line — written as `-m "subject\n\n- bullet"` without `$'...'` or a heredoc, so
the shell passed `\n` through as two characters:

- `d272e824` — `feat(164-03): clarify current package compatibility\n\n- Mark each package README's...`
- `cb5020c7` — `feat(162-08): recover idle scheduled release control\n\n- Discover exact open...`
- `eff68923` — `fix(162-09): select CI by checkout SHA\n\n- Query ci.yml runs with...`

These render as one unbroken line in generated changelogs — visible in #222's
body before it was closed. Harmless to the build, but it would have shipped into
a public CHANGELOG entry on Hex.

## Solution

Three candidate arms; pick after deciding how much enforcement is warranted for
a quiet-maintenance repo.

1. **Document the rule.** `CONTRIBUTING.md` and `MAINTAINING.md` state that a
   change confined to READMEs, guides, or docs uses `docs:`, and that `feat:`
   and `fix:` are reserved for changes to shippable code. Cheapest arm; catches
   the honest mistake, not the automated one.

2. **Gate it in CI.** Extend the existing `Guard Release Trigger` job so a
   `feat:`/`fix:` commit whose diff touches no shippable path fails the check.
   "Shippable" is already enumerated by each package's `defp package` `files`
   allowlist in `mix.exs`, so the job can derive the set rather than hardcode
   it. This is the arm that actually prevents recurrence, including from agent
   -authored commits, which is where all three malformed subjects came from.

3. **Fix the message hygiene.** The `\n` escapes come from executors building
   `git commit -m` strings. Worth a guard in the GSD executor contract or a
   `commit-msg` hook rejecting a subject containing a literal backslash-n.

Note the interaction with squash-merge: the PR title becomes the commit subject,
and `Conventional PR Title` already lints that title. The three malformed
commits above bypassed it because they landed via direct push during phase
execution, not through a PR. Arm 2 should therefore run on push to `main`, not
only on `pull_request`.

## Open question

Whether arm 2 is proportionate. The repo is in quiet maintenance and the failure
mode is a wasted version number, not a broken release — #222 was caught by
reading it. Against that: it was caught by a human reading a 40-entry changelog,
which is exactly the review that does not scale.
