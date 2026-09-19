---
created: 2026-09-18T00:00:00.000Z
title: "repo.hygiene status/1 ranks :cannot_check above :blocked — maintainer design call"
area: controls
files:
  - dev/mix/tasks/mailglass.repo.hygiene.ex:482-488 (status/1 aggregate)
  - test/mix/tasks/mailglass.repo.hygiene_test.exs:148 ("cannot-check takes precedence over a confirmed policy block")
priority: needs-decision
origin: 166-REVIEW.md WR-03, carried via .planning/phases/166-*/deferred-items.md
---

## The question

`status/1` resolves the aggregate to `:cannot_check` whenever any check is
unobservable, even when another check is a confirmed `:blocked`. The code
review read this as a confirmed alarm being masked by an unknown.

**This is not a bug report. It is a genuine fork, and it is yours to settle.**

Both readings are defensible:

- *Current:* "do not issue a verdict on a repository you could not fully observe."
- *Alternative:* "a confirmed alarm outranks an unknown."

## Why it was not flipped at phase close

1. Pre-existing Phase 162 behavior — not introduced by 166-06.
2. **Explicitly test-pinned**, and D-35 instructed 166-06's executor to pin
   current behavior, which it did. Flipping it silently would break a
   deliberate pin.
3. Not lossy — the text renderer and the JSON encoder both emit every
   individual check, so a `:blocked` finding stays fully visible. Only the
   one-line `reason/1` headline and the aggregate exit code prefer cannot-check.
4. Does not fail open either way: `:cannot_check` exits 2, `:blocked` exits 1.
   Both non-zero, so the workflow step fails identically.

Flipping a fail-closed control's semantics on review-agent initiative, against
a deliberate pin, is not a call to make at phase close.

## What a decision looks like

Either (a) confirm current precedence and add a comment at `status/1` recording
*why*, so the next reviewer does not re-litigate it; or (b) invert it, update
the pinned test and its name, and check whether any consumer keys off exit code
2 vs 1.
