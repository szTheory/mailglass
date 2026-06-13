---
created: 2026-06-13T06:35:12.755Z
title: Refresh outbound admin UI look and feel
area: ui
files:
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/docs/design-system.md
---

## Problem

During Phase 92 human visual verification, the sealed-flap logo itself was accepted on the admin surfaces, but the outbound operator UI at `/ops/mail?tenant_id=northstar` was judged visually poor. This is not a Phase 92 logo-adoption blocker, but it should become a future look/feel milestone so the production admin surface applies the project design system coherently.

## Solution

Plan a focused follow-up milestone for the outbound admin dashboard visual and UX pass. Use the shipped design system rather than a new brand direction; inspect the operator shell, deliveries overview/detail states, spacing, hierarchy, color usage, and light/dark behavior. Keep this separate from Phase 92 brand propagation and avoid changing package APIs unless a concrete UI bug requires it.
