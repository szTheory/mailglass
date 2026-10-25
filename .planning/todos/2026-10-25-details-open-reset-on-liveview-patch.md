---
created: 2026-10-25T00:00:00.000Z
title: Operator <details> disclosures lose a user-set open state on LiveView patch and socket join
area: admin-ui
files:
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex (Components.technical_details id=delivery-detail-technical)
  - mailglass_admin/lib/mailglass_admin/operator_live.ex (Account diagnostics details, server-driven open={support_focus?/1})
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex (email picker menu details)
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex (tenant picker details, data-dismiss-outside)
  - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex (inbound-routing-disclosure)
priority: backlog
---

## Problem

A native `<details>` opened by the user carries a client-set `open` attribute that the server render does
not know about. Any LiveView DOM patch (the socket join after the dead render, a push_patch, or a
re-render of the surrounding component) morphs the element back to the server's attributes and drops
`open`. Operators see a disclosure snap shut under them. In phase 173.1 this was the root cause of a
flaky cohort e2e (`fjordline-aps edge values render ...`): the test clicked the "Technical details"
summary before the socket joined, and the join patch discarded `open`. CI recorded it as
retried-then-passed (run 40224464591, attempt 1). The test is fixed by waiting for connect; the product
behavior remains.

Per-site status (checked against the current files):

- `detail_header.ex` `delivery-detail-technical`: no server `open`, so any patch resets it. Affected.
- `preview/sidebar.ex` picker menu: no server `open`. Affected (transient menu, low impact).
- `operator/shell.ex` tenant picker: no server `open`, uses `data-dismiss-outside`. Affected (transient).
- `inbound/routing_trace.ex`: no server `open`. Affected.
- `operator_live.ex` Account diagnostics: `open` is server-driven by `support_focus?/1`, so the server
  re-asserts it; a user-opened state is still reset when the server value is false.

## Candidate fix

`Phoenix.LiveView.JS.ignore_attributes/1` exists in the pinned LiveView (1.2.12, `js.ex`
`ignore_attributes/1,2,3`). Add `phx-mounted={JS.ignore_attributes(["open"])}` to each persistent
disclosure so future server patches leave `open` alone. Caveat from the LiveView docs: `phx-mounted`
runs at LiveView mount, so it does NOT retain an attribute set on the client during the disconnected
render. Clicks before the socket joins can still be lost; closing that window needs either an
`open`-state round trip (phx-click toggle stored in assigns) or accepting the narrow pre-connect window.
For the server-driven Account diagnostics disclosure, ignoring `open` would stop `support_focus?/1`
from re-opening it, so that site needs a deliberate decision.

## Why deferred

This is a user-visible `fix(admin)` change, which bumps and ships a `mailglass_admin` release. It is out
of scope for the 173.1 debt-closure PR, which is deliberately non-bumping. Needs its own phase or quick
task with a browser test that opens the disclosure and then triggers a patch.
