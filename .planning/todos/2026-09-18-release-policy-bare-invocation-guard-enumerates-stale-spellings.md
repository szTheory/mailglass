---
created: 2026-09-18T00:00:00.000Z
title: "release_policy.exs bare-invocation guard enumerates stale spellings instead of requiring cli/1"
area: release-engineering
files:
  - scripts/release_policy.exs (bare-invocation guard)
priority: later
origin: 166-REVIEW.md IN-01, carried via .planning/phases/166-*/deferred-items.md
---

## Problem

The guard only catches three known-stale flag spellings. Other bare
`elixir scripts/release_policy.exs <verb>` forms still **exit 0 without ever
invoking `cli/1`** — a silent green from a script that did nothing.

This is the same vacuity shape 166-06's executor hit in its own verify command
and worked around with `mix run -e cli(System.argv())`.

## Fix

Make the guard reject any invocation that does not reach `cli/1`, rather than
enumerating spellings that go stale.

## Severity

Latent, not live — no shipped code path depends on the bare form. But it is a
false-green generator aimed straight at whoever next verifies release policy
from a shell.
