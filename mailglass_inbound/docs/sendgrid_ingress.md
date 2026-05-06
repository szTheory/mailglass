# SendGrid Ingress

Phase 41 adds the second real inbound path: verified SendGrid ingress plus
truthful mailbox execution and replay posture.

## Mount Path

Mount the package-local plug on an obvious SendGrid route:

```elixir
forward "/inbound/:tenant_id/sendgrid",
  MailglassInbound.Ingress.Plug,
  provider: :sendgrid,
  router: MyApp.MailglassInboundRouter
```

The ingress plug is verify-first:

1. verify SendGrid basic auth
2. resolve tenant scope
3. normalize the raw MIME `email` part into `%MailglassInbound.InboundMessage{}`
4. persist one canonical row plus one raw evidence row
5. execute the matched mailbox only after durable persistence commits

## Configuration

Configure the shipped Phase 41 SendGrid seam through `:mailglass_inbound`:

```elixir
config :mailglass_inbound, :sendgrid,
  basic_auth: {"sendgrid-user", "sendgrid-pass"}
```

Phase 41 ships shared-secret basic auth only. Signed multipart verification did
not ship in this slice.

## Raw MIME Requirement

SendGrid must post the raw MIME `email` part. The package fails closed if
SendGrid only sends parsed multipart fields, because replay and duplicate truth
depend on the original MIME artifact.

## Persistence And Execution

Verified SendGrid ingress writes two truths before mailbox execution starts:

- one canonical normalized row in `mailglass_inbound_records`
- one linked raw evidence row in `mailglass_inbound_evidence`

Mailbox execution happens after persistence and records append-only internal
execution lineage. execution outcomes do not control provider retries; the
provider receives `200` once receive truth is safely committed.

## Duplicate Handling

SendGrid duplicate collapse is provider-specific. The package does not overload
`provider_message_id`, because SendGrid may omit it for raw MIME delivery.

Instead, duplicates collapse on:

`(tenant_id, provider, raw_mime_fingerprint)`

That fingerprint is derived from the stored raw MIME evidence, so retries and
manual resends with the same MIME do not create a second receive truth or a
second mailbox execution.

## Replay Honesty

Replay is an internal package capability that reruns the originally matched
mailbox against stored canonical plus raw evidence truth.

Replay is not:

- a fresh provider receive
- a re-ingest of provider payloads
- a silent reroute to a different mailbox
- a widened public provider surface

If the record predates execution-lineage capture, or if fresh history only
contains `:no_match`, replay fails with an explicit operator-facing error
instead of guessing a mailbox.
