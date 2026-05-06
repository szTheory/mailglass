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

Replay is an operator recovery action against one exact stored inbound receive
truth for one selected delivery.

- Replay is exact-target, not delivery-wide guessing.
- Replay stays tenant-scoped.
- Replay is ledger-audited as requested, succeeded, or failed facts.
- Replay runs after canonical and raw evidence truth already exists; it is not
  a fresh provider receipt.
- Replay can honestly end in `new work` or `no change`.

Fresh provider receipt and later execution are intentionally distinct. The
durable promise is the stored inbound receive truth. Execution may happen later
through Oban-backed durable jobs or, when Oban is unavailable, through a
bounded Task.Supervisor fallback with no automatic retry. Replay is the
recovery tool when operators need to rerun stored truth after best-effort
fallback loss or a previous failure.

Replay and reconcile are intentionally distinct. Replay reruns one exact stored
inbound target through local semantics and does not silently reroute to a
different mailbox. Reconcile is background-first backlog maintenance for
unmatched webhook rows and is not a delivery-detail replay tool.

Known replay failure cases are also part of the honest operator story:

- `no_prior_match` means fresh execution history only proves `:no_match`, so
  replay cannot safely infer a mailbox target.
- `execution_history_missing` means the record predates execution-lineage
  capture or lacks the stored facts replay needs to rerun mailbox execution.

When execution history is incomplete, replay fails explicitly rather than
guessing. The current failure vocabulary includes `:no_prior_match` for records
whose fresh history never matched a mailbox and `:execution_history_missing`
for records that predate execution-lineage capture.

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
