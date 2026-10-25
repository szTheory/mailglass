---
created: 2026-10-24T00:00:00.000Z
title: Delivery "Open delivery" buttons carry aria-selected, which buttons do not support
area: accessibility
files:
  - mailglass_admin/lib/mailglass_admin/ (delivery row open button)
  - mailglass_admin/e2e/operator.spec.js
priority: backlog
---

## Problem

When 6ea8321c moved selection from the `<tr>` to a native button, `aria-selected` moved with it.
`aria-selected` is invalid on `button`; selection is now asserted via `data-selected` on the row and
`aria-current` on the button (inbound 170-08 rule). Remove the stray attribute and update the unit
tests and operator.spec.js that still read it.
