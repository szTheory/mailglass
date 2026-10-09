# Operator Trust

`mailglass_admin/docs/operator-trust.md` is the canonical admin trust doc for
the stable operator surface. It documents the semantic seams adopters can rely
on without treating LiveView, component, or DOM details as stable.

Stable guarantees for this package are inventory-defined in
[`mailglass_admin/docs/api_stability.md`](./api_stability.md). When this page
references core or inbound-adjacent semantics, canonical contract truth lives
in [`docs/api_stability.md`](../../docs/api_stability.md) and
[`mailglass_inbound/docs/api_stability.md`](../../mailglass_inbound/docs/api_stability.md),
with executable contract enforcement in `mix verify.stability_contract`.

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

`:operator_access` is a global grant to the Mailglass operator data available
through the host's configured persistence scope. An authorized operator may
select any `tenant_id` in that scope; the actor's optional `tenant_id` and the
activity-derived Account options do not form a per-account membership list.
Account options help operators navigate, while each read and live-update
subscription remains scoped to the selected `tenant_id`. Hosts that need
per-account operator membership must enforce it at their own boundary; the
current stable auth contract does not provide a separate Account-selection
authorization action.

## Replay semantics

Replay is an operator recovery action against one exact stored outbound webhook
request for one selected Delivery. It reprocesses that request through current
normalization, which can add Events and update Delivery or suppression records
for multiple Deliveries in the selected Account. It does not resend outbound
mail or prove that a provider received or accepted a message.

- Replay is exact-target, not delivery-wide guessing.
- Replay stays tenant-scoped.
- Host authorization and recent-auth policy are evaluated immediately before
  the local replay command.
- Replay is ledger-audited as requested, succeeded, or failed facts. A requested
  fact means the command was recorded as requested; it does not mean completion
  was recorded or that the command is still running.
- Local command feedback reports only the normalized Event row count returned
  by that command: new work means newly normalized Event rows, and no change
  means zero newly normalized rows. A no-change result is not a
  failure and not proof that the Delivery or audit history was unchanged.
- A terminal persisted result is shown only when the scoped audit read supplies
  that fact. If that read is unavailable, command feedback remains separate and
  the persisted evidence is labeled unavailable.

The stored provider request and later local replay are distinct. Outbound replay
reprocesses the existing request synchronously through the local command; it is not a fresh provider receipt.

Replay and reconcile are intentionally distinct. Replay reruns one exact stored
outbound webhook request through local normalization and does not silently
substitute another request. Reconcile is background-first backlog maintenance
for unmatched webhook rows and is not a delivery-detail replay tool.

Replay command semantics are stable at the operator level, but this does not
create a public replay runtime API. Internal replay orchestration modules,
worker/queue internals, and admin execution wiring remain implementation detail.

### Inbound mailbox recovery

Inbound mailbox execution may happen later through Oban-backed durable jobs or,
when Oban is unavailable, through a bounded Task.Supervisor fallback with no
automatic retry. Inbound replay supports recovery after fallback loss or an
earlier mailbox execution failure. Its execution-history requirements include:

- Fresh receipt resolves a mailbox using the router deployed at receipt time.
  Replay uses the durable mailbox binding from that execution; it does not silently reroute through current router rules. When the Task.Supervisor fallback is active, the scheduling path is best-effort and recovery may require an operator replay.
- The selected execution timeline is a timestamped snapshot for the current
  Account and InboundMessage. Replay command feedback remains separate from
  that snapshot; an operator uses Refresh history to request a new scoped read.

- `no_prior_match` means fresh execution history only proves `:no_match`, so
  replay cannot safely infer a mailbox target.
- `execution_history_missing` means the record predates execution-lineage
  capture or lacks the stored facts replay needs to rerun mailbox execution.

These mailbox-history errors belong to inbound recovery. Outbound webhook replay
uses the selected stored provider request and its Account-scoped audit evidence.

## Intentionally internal

The following remain intentionally internal implementation detail for `v1.x`:

- LiveView modules
- component modules
- DOM/CSS shape
- event names
- modal details and layout
- internal assign names
- internal mount-hook and implementation wiring

Adopters should not depend on those details even if they are visible in source,
tests, or generated docs.
