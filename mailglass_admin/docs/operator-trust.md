# Operator Trust

`mailglass_admin/docs/operator-trust.md` is the canonical admin trust doc for
the stable operator surface. It documents the semantic seams adopters can rely
on without treating LiveView, component, or DOM details as stable.

## Stable seams

The stable admin seams are:

- `MailglassAdmin.Router.mailglass_admin_routes/2` and
  `MailglassAdmin.Router.mailglass_operator_routes/2` as the documented mount
  macros
- the `MailglassAdmin.Auth` `authorize/2` callback as the adopter-owned
  authorization seam
- the explicit operator session contract for `subject_id`, optional
  `tenant_id`, optional `auth_method`, and optional `recent_auth_at`
- mount-time authorization through `:operator_access`
- action-time authorization through `:destructive_action`

These are semantic promises. They describe what adopters can mount, authorize,
and reason about. They do not freeze the implementation that renders the UI.

## Session contract

`mailglass_operator_routes/2` takes an explicit `:session` whitelist. The
operator session contract includes:

- required `subject_id`
- optional `tenant_id`
- optional `auth_method`
- optional `recent_auth_at`

`MailglassAdmin.Router` copies only those explicit keys into the operator
LiveView session. It does not pass through the entire Plug session, and it does
not promise any internal assign names beyond the documented actor semantics.

## Authorization timing

Authorization is split across two stable moments:

- `:operator_access` runs at mount time to decide whether the operator surface
  can be entered at all.
- `:destructive_action` runs at action time immediately before a sensitive
  operation such as replay.

This means mount-time access is not treated as blanket approval for later
destructive actions. Adopters keep ownership of the policy through
the `MailglassAdmin.Auth` `authorize/2` callback.

## Replay semantics

Replay is an operator action against one exact stored webhook event for one
selected delivery.

- Replay is exact-target, not delivery-wide guessing.
- Replay stays tenant-scoped.
- Replay is ledger-audited as requested, succeeded, or failed facts.
- Replay reuses the existing local ingest and idempotency path.
- Replay can honestly end in `new work` or `no change`.

Replay and reconcile are intentionally distinct. Replay reruns one exact stored
webhook target through local semantics. Reconcile is background-first backlog
maintenance for unmatched webhook rows and is not a delivery-detail replay
tool.

## Intentionally internal

The following remain intentionally internal for `v1.x`:

- LiveView modules
- component modules
- DOM/CSS shape
- event names
- modal details and layout
- internal assign names
- internal mount-hook and implementation wiring

Adopters should not depend on those details even if they are visible in source,
tests, or generated docs.
