---
quick_id: 260617-oj1
slug: harden-publish-hex-yml-gate-ci-green-isa
date: 2026-06-17
---

# Quick Task: Classify "Demo Browser Evidence" as advisory in gate-ci-green

## Problem

`publish-hex.yml`'s `gate-ci-green` job accepts an overall-failed `ci.yml` run
only when every failing job is advisory, per `isAdvisory(jobName)`. That helper
matches two patterns:

1. `jobName` starts with an entry in the explicit `ADVISORY_LANES` list, or
2. `jobName` matches the `<name> Advisory (...)` convention via `/ Advisory \(/`.

The CI job `Demo Browser Evidence (Docker Compose / Chromium)` is a browser-based
lane that is **not** a branch-protection required check (the required set is
Compile No Optional Deps, Installer Host Smoke, Support Contract Core/Admin,
Trust Lane Repo Head). But its name predates the naming convention — it lacks the
" Advisory (" token — so a red Demo Browser Evidence lane would wrongly block a
Hex release, exactly like "Operator Browser Gate" would before it was listed
explicitly.

## Change

Add `'Demo Browser Evidence'` to the explicit `ADVISORY_LANES` array in
`gate-ci-green` (alongside `'Operator Browser Gate'`), and update the adjacent
comment to name both predates-convention lanes.

## Verification

- `python3 yaml.safe_load` parses `publish-hex.yml`.
- Node check of the `isAdvisory()` logic: `Demo Browser Evidence (Docker Compose
  / Chromium)` → advisory; required lanes (Compile No Optional Deps, Trust Lane
  Repo Head) → still blocking.
