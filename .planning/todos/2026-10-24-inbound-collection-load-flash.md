---
created: 2026-10-24T00:00:00.000Z
title: Inbound collection briefly shows "Choose an Account" or no rows right after load
area: admin-ui
files:
  - mailglass_admin/lib/mailglass_admin/inbound/ (collection mount/handle_params)
  - mailglass_admin/e2e/ (row-reading helpers now wait for rows as a mitigation, 6af0e4f1)
priority: backlog
---

## Problem

Right after the "Inbound records" heading renders, the page can momentarily show "Choose an
Account" even with `tenant_id` in the URL, or render with no rows yet. Reproduced at HEAD with the
PR #302 browser fixes stashed (1 of 6 runs), so it predates them. The e2e helpers now wait for rows;
the product flash itself is unfixed. Operators can see a wrong "no account" state on deep links.
