---
created: 2026-10-28
source: Phase 177 (D-05 deferred ideas, plan 177-11)
status: complete
completed: 2026-11-03
resolved_by: .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-16-SUMMARY.md
---

# In-Operator Account switch host authorization

The Account control on Health, Deliveries and Inbound uses `push_patch` in the
same LiveView (`Shell.tenant_switch_path/2`; `OperatorLive` and `InboundLive`
read `tenant_id` in `handle_params/3`). A patch still does not rerun the
`live_session` `on_mount` chain. Plan 176-16 closed the authorization gap by
attaching a shared `:handle_params` hook in `Operator.Mount`; when the exact
`tenant_id` parameter changes, it invokes the existing host-owned
`authorize(:operator_access, ...)` callback and applies the existing denial
behavior before either LiveView reads the proposed Account.

This was a pre-existing gap left open by Phase 177 D-05 and is now resolved.
The docs and prohibition contract say that a changed Account parameter reaches
the host callback; they continue to forbid claims that every patch rechecks
authorization or that `push_patch` reruns the full `on_mount` chain.

## Original Risk (resolved by the host callback check above)

An operator who is allowed into the Operator surface but not into every Account
could change `tenant_id` in the switcher (or in the URL of a patch) and reach
reads for an Account the host would deny on arrival.

The host callback remains the grant authority. Account options from
`TenantSelector.list_tenants(actor, ...)` are navigation data, and reads remain
scoped by `Mailglass.Tenancy.scope/2`. A connected denied patch now redirects
before any query on both Deliveries and Inbound. Hosts may still approve an
activity-free Account through their existing callback; Mailglass adds no
second Account allow-list.

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

Selected and implemented: option 2, with connected tests proving that a denied
Account is refused before reads on both routes. No router option, session key,
callback arity, Auth action, or result shape was added.

## Acceptance for the slice

- A host that denies Account X on arrival also denies it on an in-page switch.
- The behavior is documented in `docs/operator-trust.md` and
  `docs/api_stability.md` (router contract) only after the test above is green.
- The 2.x public router contract does not change unless option 3 is chosen.

## Resolution

Completed in Phase 176 plan 16 on 2026-11-03. The focused connected
authorization tests and Phase 177 documentation contract passed; the full
Admin suite passed with 1,210 tests, 0 failures, and 1 excluded. The deep code
review found no issues. See `176-16-SUMMARY.md` and `176-16-REVIEW.md`.
