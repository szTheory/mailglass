---
created: 2026-10-28
source: Phase 177 (D-05 deferred ideas, plan 177-11)
status: open
---

# In-Operator Account switch does not re-run host authorization

The Account control on Health, Deliveries and Inbound switches Accounts with a
`push_patch` to the same LiveView (`Shell.tenant_switch_path/2`; `OperatorLive`
and `InboundLive` read `tenant_id` in `handle_params/3`). A patch re-runs
`handle_params/3` but not the `live_session` `on_mount` chain, so the host's
`authorize(:operator_access, ...)` callback, which receives `params["tenant_id"]`,
runs on arrival at the page and not on a later in-page switch.

This is pre-existing and Phase 177 did not change it. Phase 177 moved the control
and did not alter how a switch is authorized. Do not describe it as fixed. A
prohibition test in `phase177_prohibition_contract_test.exs`
("docs do not claim patch-time re-authorization") forbids any doc or moduledoc
from claiming that the switch re-runs host authorization.

## Risk

An operator who is allowed into the Operator surface but not into every Account
could change `tenant_id` in the switcher (or in the URL of a patch) and reach
reads for an Account the host would deny on arrival.

What limits it today: the options the switcher offers come from
`TenantSelector.list_tenants(actor, ...)`, reads stay scoped by
`Mailglass.Tenancy.scope/2`, and a full page load of a crafted URL is denied by
the host callback (covered by the `forbidden-account` sentinel tests). The gap is
the in-LiveView patch path: mailglass does not check a patched `tenant_id`
against that list (D-05 leaves Account authorization to the host).

## Options for a security-hardening slice

1. Replace the `push_patch` Account switch with a `push_navigate` (a full
   `on_mount` run) on every switch. Smallest change; costs one remount per switch.
2. Re-invoke the host `authorize(:operator_access, ...)` callback inside
   `handle_params/3` whenever `tenant_id` changes, and treat a denial the same as
   an arrival denial (redirect to `unauthorized_path`).
3. Optional mailglass-side allow-list on URL `tenant_id` (research alternative
   to D-05, not adopted in Phase 177): the router macro accepts an
   `:allowed_tenants` callback and the Operator rejects any other value. Revisit
   only together with 1 or 2, because it makes mailglass a second source of
   truth for Account access.

Preferred starting point: option 2, with a contract test that a denied Account
is refused after a patch as it is on arrival.

## Acceptance for the slice

- A host that denies Account X on arrival also denies it on an in-page switch.
- The behavior is documented in `docs/operator-trust.md` and
  `docs/api_stability.md` (router contract) only after the test above is green.
- The 2.x public router contract does not change unless option 3 is chosen.
