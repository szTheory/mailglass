---
created: 2026-10-25T00:00:00.000Z
title: Preview iframe reloads once on every page load (render_nonce re-minted on socket join)
area: admin-ui
files:
  - mailglass_admin/lib/mailglass_admin/preview_live.ex (render_nonce mint in mount and in the render success path)
  - mailglass_admin/lib/mailglass_admin/preview/tabs.ex (iframe id preview-iframe-<nonce>)
priority: backlog
---

## Problem

The dead render and the connected mount each mint `System.unique_integer` for `render_nonce`, so the
`phx-update="ignore"` preview iframe (id `preview-iframe-<nonce>`) is replaced when the socket joins.
That causes a visible flash, a wasted render, and the e2e race closed in phase 173.1 (the spec's inline
320px width was discarded by the replacement, producing "Received: 373").

## Candidate fix

A content-derived stable nonce, for example a hash of the HTML body plus device width. It must stay
compatible with `set_device`, which depends on a changed id to force the iframe to re-render. It needs a
non-feat admin commit and ships in the next admin release.

## Why deferred

It is a product change beyond the 173.1 debt closure. The demo spec now waits for LiveView connect
(`gotoPreview`) either way, so the fix is not needed for green evidence.
