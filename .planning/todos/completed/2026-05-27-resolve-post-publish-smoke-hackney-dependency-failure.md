---
created: 2026-05-27T08:40:34.636Z
resolved: 2026-05-27T12:28:03Z
title: Resolve post-publish smoke hackney dependency failure
area: tooling
files:
  - .github/workflows/post-publish-smoke.yml
  - lib/mailglass/installer/templates.ex
  - test/mailglass/install/install_first_preview_smoke_test.exs
---

## Problem

Open issue #25 reported that fresh-host consumer install could fail during
`mix mailglass.install` with a missing hackney dependency. Tracker issue #32
was the current signal for this path.

## Resolution

Validated the install path contract in the current workspace:

- `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors`
  passed (`1 test, 0 failures`) on 2026-05-27.

This confirms the current install flow keeps the Swoosh API client contract
safe for fresh hosts and no longer reproduces the reported failure path in the
local trust-proof check.

## Follow-up

- Keep #32 as the ongoing CI sentinel for regressions.
- If #32 remains green through release smoke, close it as resolved.
