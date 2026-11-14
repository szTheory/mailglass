# Brand v2 compatibility policy

Brand v2 changes the words and visuals on screens and in docs. This policy
lists the public names that must not move while that happens, and a test reads
the table below to prove each one still exists in the code.

On-screen and docs words are glossed, never renamed: every public name in the table below stays.

## Names that stay

Each row is checked against the code by
`mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs`, which
parses this table and holds no second list. The columns are:

- **name**: the public name, exactly as written in code.
- **kind**: how the test verifies it. `module` is loaded, `macro` and `function`
  are exported at the stated arity, `enum` lists atoms that must remain members
  of the live enum, `schema_field` is a field of the Ecto schema, `topic` is the
  string the named function returns, `grep` is a literal found in the proof file.
- **package**: the Hex package that owns the name.
- **proof**: the module, function, atom list or repo-relative file the test uses.

<!-- compat-table:start -->
| name | kind | package | proof |
|------|------|---------|-------|
| `Mailglass.Operator.Deliveries` | module | mailglass | `Code.ensure_loaded?` |
| `Mailglass.Operator.Timeline` | module | mailglass | `Code.ensure_loaded?` |
| `Mailglass.Operator.ReplayHistory` | module | mailglass | `Code.ensure_loaded?` |
| `Mailglass.Operator.ReplayTargets` | module | mailglass | `Code.ensure_loaded?` |
| `Mailglass.Operator.Suppressions` | module | mailglass | `Code.ensure_loaded?` |
| `Mailglass.Operator.SupportSummary` | module | mailglass | `Code.ensure_loaded?` |
| `Mailglass.Operator.Tenants` | module | mailglass | `Code.ensure_loaded?` |
| `MailglassAdmin.Router.mailglass_operator_routes/1` | macro | mailglass_admin | `macro_exported?` |
| `MailglassAdmin.Router.mailglass_operator_routes/2` | macro | mailglass_admin | `macro_exported?` |
| `Mailglass.Operator.SupportSummary.read_orphan_backlog/1` | function | mailglass | `function_exported?` |
| `Mailglass.Outbound.Delivery.status` | enum | mailglass | `[:queued, :sent, :dispatched, :failed, :suppressed]` |
| `Mailglass.Events.Event.type` | enum | mailglass | `[:queued, :sent, :rejected, :failed, :bounced, :deferred, :delivered, :autoresponded, :opened, :clicked, :complained, :unsubscribed, :subscribed, :unknown, :dispatched, :suppressed, :reconciled, :webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed]` |
| `Mailglass.Events.Event.reject_reason` | enum | mailglass | `[:invalid, :bounced, :timed_out, :blocked, :spam, :unsubscribed, :other]` |
| `Mailglass.Outbound.Delivery.tenant_id` | schema_field | mailglass | `__schema__(:fields)` |
| `Mailglass.Events.Event.tenant_id` | schema_field | mailglass | `__schema__(:fields)` |
| `Mailglass.Suppression.Entry.tenant_id` | schema_field | mailglass | `__schema__(:fields)` |
| `mailglass:deliveries:#{tenant_id}` | topic | mailglass | `Mailglass.PubSub.Topics.deliveries/1` |
| `:operator_access` | grep | mailglass_admin | `mailglass_admin/lib/mailglass_admin/auth.ex` |
| `:orphan_backlog` | grep | mailglass | `lib/mailglass/operator/support_summary.ex` |
| `[:mailglass, :webhook, :orphan, :stop]` | grep | mailglass | `lib/mailglass/webhook/telemetry.ex` |
| `[:mailglass, :suppression, :pre_send_blocked, :stop]` | grep | mailglass | `lib/mailglass/suppression.ex` |
| `deliveries_path` | grep | mailglass_admin | `mailglass_admin/lib/mailglass_admin/router.ex` |
| `live_session_name` | grep | mailglass_admin | `mailglass_admin/lib/mailglass_admin/router.ex` |
| `account_labels` | grep | mailglass_admin | `mailglass_admin/lib/mailglass_admin/router.ex` |
| `"tenant_id"` | grep | mailglass_admin | `mailglass_admin/lib/mailglass_admin/router.ex` |
| `"tenant_id"` | grep | mailglass_admin | `mailglass_admin/lib/mailglass_admin/operator/mount.ex` |
<!-- compat-table:end -->

The two `"tenant_id"` rows are different names that happen to share a spelling:
the first is the session key the router writes, the second is the URL parameter
`MailglassAdmin.Operator.Mount` reads. The proof file tells them apart.

## Where each router option lives

These three options belong to `mailglass_operator_routes/2` in
`mailglass_admin/lib/mailglass_admin/router.ex`, but not at the same level:

- `deliveries_path` is nested. Pass it as `navigation: [deliveries_path: "/path"]`.
- `live_session_name` is a top-level option.
- `account_labels` is a top-level option.

## Telemetry note

`[:mailglass, :suppression, :pre_send_blocked, :stop]` is emitted by
`Mailglass.Suppression` in `lib/mailglass/suppression.ex` but is not yet listed
in `guides/telemetry.md`, so its proof is a source grep rather than a docs check.

## Gloss, don't rename

A gloss is a plainer word on a screen or in docs prose. The public name it
describes keeps working and keeps its spelling. The vocabulary:

<!-- gloss-table:start -->
| public name | on-screen word | gloss |
|-------------|----------------|-------|
| `Operator` | `Admin` | screen text and docs prose only; the public name stays |
| `Tenant` | `Account` | screen text and docs prose only; the public name stays |
| `Deliveries` | `Activity` | screen text and docs prose only; the public name stays |
| `orphan / unmatched` | `provider reports match no email` | screen text and docs prose only; the public name stays |
<!-- gloss-table:end -->

The gloss rule is enforced later, on an allowlist of screens and docs, not
across the whole repository. Some tests and docs deliberately keep the old
words; see "Tests that pin the current words" below.

## Not sent

Not sent is a pre-send block only. Mailglass never stores a suppressed send as a delivery.

- `Mailglass.Outbound.send/2` and `deliver_later/2` check suppression in
  `lib/mailglass/outbound/preflight.ex`, through `lib/mailglass/suppression.ex`,
  before any insert. A suppressed recipient returns
  `{:error, %Mailglass.SuppressedError{}}` and no Delivery or Event row is written.
- `deliver_many/2` returns an in-memory `:failed` Delivery built by
  `Mailglass.Outbound.Persistence.build_failed_delivery/2`. It is never inserted.
- No library code writes `Delivery.status :suppressed`. The enum member and the
  `:suppressed` event type are reserved and dormant; only test fixtures produce
  them. They still read Not sent if they ever appear.
- A send-time `:failed` reads Failed, never Not sent.
- "Not sent" for suppression belongs where the suppression card and entry are
  shown, not as a promise on an Activity row.

Proof: `test/mailglass/outbound/suppressed_not_persisted_test.exs` delivers to a
suppressed address through all three entry points and asserts zero Delivery rows
and zero Event rows, with a positive control so the zeros are not vacuous.

## Same atom, two meanings

The atoms `:rejected`, `:bounced` and `:failed` are also inbound mailbox
outcomes. There they describe what a mailbox did with a received message, not
what happened to a sent one. Inbound outcome badges must not adopt the delivery
words, and a rename keyed on the atom alone would relabel them by accident.

## Tests that pin the current words

These tests assert the current wording of operator and tenant terms. Later
screen and doc changes enforce the gloss on an allowlist of screens and docs and
leave these tests unedited:

- `mailglass_admin/test/mailglass_admin/operator_trust_doc_test.exs`
- `test/mailglass/docs_contract_test.exs`
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
- `mailglass_admin/test/mailglass_admin/stability_contract_test.exs`

## Related

This policy links to the stability inventories and does not restate them.

- [`docs/api_stability.md`](api_stability.md): core `mailglass` inventory.
- [`mailglass_admin/docs/api_stability.md`](../mailglass_admin/docs/api_stability.md): admin inventory.
- [`mailglass_inbound/docs/api_stability.md`](../mailglass_inbound/docs/api_stability.md): inbound inventory.
- [`guides/compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md): deprecation and support policy.

## Changing this file

Adding a row is always allowed. Removing a row requires the deprecation process
in `guides/compatibility-and-deprecations.md` and a major version.
