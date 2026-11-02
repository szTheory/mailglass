---
created: 2026-10-28
source: Phase 177 code review fix (IN-04, 177-REVIEW-FIX.md)
status: open
---

# LiveViews treat a whitespace-only `tenant_id` as a selected Account

IN-04 made the shell's `blank_to_nil/1` (`operator/shell.ex`) treat
whitespace-only strings as blank, so the Account control in the header shows the
"Choose an Account" prompt for `?tenant_id=%20`. The LiveViews still have their
own narrower helper:

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` `blank_to_nil/1` (~line 2980)
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` `blank_to_nil/1` (~line 2255)

Both guard only `nil` and `""`. With `?tenant_id=%20`, the page body scopes to an
Account whose id is `" "`, which flows into queries and `Auth.authorize`, while
the header says no Account is selected. Header and body disagree.

Not fixed in the review pass because the helper has ~40 call sites per LiveView
(tenant scoping, `search`, `provider`, `delivery_id`/`inbound_id`, support event
ids, window hours). Trimming there changes tenant-scoping behaviour, not just
presentation.

## Suggested fix

Trim in both LiveView helpers (or route `tenant_id` through
`ReturnContext.valid_tenant_id?/1`), then add connected tests for
`?tenant_id=%20` on Health, Deliveries and Inbound. Check that a whitespace
`search` param dropping to "no search" is acceptable. It almost certainly is.
