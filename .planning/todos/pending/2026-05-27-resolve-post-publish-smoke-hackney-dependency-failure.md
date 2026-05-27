---
created: 2026-05-27T08:40:34.636Z
title: Resolve post-publish smoke hackney dependency failure
area: tooling
files:
  - .github/workflows/post-publish-smoke.yml
  - lib/mailglass/installer/templates.ex
  - test/mailglass/install/install_first_preview_smoke_test.exs
---

## Problem

Open issue #25 reports that fresh-host consumer install can fail during `mix mailglass.install` with a missing hackney dependency. The latest tracker issue #32 still shows this failing path on 2026-05-26 in post-publish smoke, so the install-trust proof remains noisy and unresolved.

This should not stay as an old dangling issue without structured planning context while v1.3 trust-proof planning is active.

## Solution

Treat this as a current-milestone tooling todo and resolve via the trust-proof CI/install path:

- Reproduce and confirm the current failure path in the consumer-install lane.
- Ensure installer/runtime configuration keeps Swoosh API client disabled by default in fresh hosts unless adopters explicitly opt into an HTTP API client.
- Align workflow and smoke tests so the install contract (`config :swoosh, :api_client, false`) is asserted in both CI and test mirror.
- Keep issue #32 as the live tracker signal for new failures; close issue #25 as superseded historical report once this todo is captured.
