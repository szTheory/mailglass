# MailglassInbound

`mailglass_inbound` is the inbound sibling package for Mailglass.

Phase 41 ships the first honest multi-provider inbound slice: one canonical
normalized inbound message contract, one shared ingress plug for Postmark and
SendGrid, one router DSL, one mailbox behaviour, one package-local storage
boundary between canonical rows and raw evidence, and one append-only internal
execution lineage for fresh runs and replay.

## Stable in Phase 41

- `MailglassInbound.InboundMessage` is the stable normalized value object used
  for routing and mailbox processing.
- `MailglassInbound.Ingress.Plug` is the stable first-party Postmark and
  SendGrid ingress entrypoint for verified inbound requests.
- `MailglassInbound.Ingress.CachingBodyReader` is the stable `Plug.Parsers`
  `:body_reader` helper required by the Postmark ingress path.
- `MailglassInbound.Router` is the stable adopter-owned routing DSL with
  recipient, subject, and header matching.
- `MailglassInbound.Mailbox` is the stable mailbox callback contract with the
  four documented outcomes.
- Canonical storage and raw evidence storage are distinct on purpose:
  canonical rows hold normalized adopter-facing truth, raw evidence preserves
  replay and audit material that does not belong on the public struct.

## Storage Posture

The package stores two kinds of truth:

- canonical normalized rows for stable routing and mailbox inputs
- raw evidence for provider payloads, raw MIME, verification facts, attachment
  bytes, and replay support

Fresh ingress persists canonical plus raw evidence truth before any mailbox
execution runs. Provider retries are acknowledged from receive truth; mailbox
outcomes do not drive provider retry semantics.

Replay is explicit rerun execution against stored canonical plus evidence truth.
It is not presented as a fresh inbound receive, and it does not silently
reroute to a different mailbox.

## Ingress Now

Phase 41 adds two honest inbound paths through the same plug:

- mount `MailglassInbound.Ingress.Plug` behind your Phoenix route for Postmark
  or SendGrid
- configure `Plug.Parsers` with
  `body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}`
- set `config :mailglass_inbound, :postmark, basic_auth: {user, pass}` for
  verify-first basic auth
- set `config :mailglass_inbound, :sendgrid, basic_auth: {user, pass}` for
  verify-first basic auth
- for SendGrid, enable the raw MIME `email` part; the package fails closed if
  SendGrid only posts parsed multipart fields
- expect verify-first request handling, explicit rejection or duplicate
  outcomes, canonical-plus-evidence persistence before mailbox execution, and post-commit mailbox
  execution for newly inserted records only

The ingress plug verifies provider credentials before tenant resolution,
normalizes into `%MailglassInbound.InboundMessage{}`, persists one canonical row
plus one raw evidence row, and returns explicit `inserted` or `duplicate`
success outcomes. When a new record matches a mailbox, execution happens after
durable persistence and is recorded as internal execution lineage.

See [`docs/postmark_ingress.md`](docs/postmark_ingress.md) for the concrete
Postmark path and [`docs/sendgrid_ingress.md`](docs/sendgrid_ingress.md) for
the SendGrid path, duplicate semantics, and replay posture.

## Optional Oban Seam

Phase 39 keeps an optional Oban seam without making Oban mandatory.
`MailglassInbound.OptionalDeps.Oban` reports whether Oban is available so later
internal execution runners can branch cleanly. No queue configuration,
worker contract, or job-shaped return value is promised in this phase.

## Deferred Beyond Phase 41

These capabilities are intentionally deferred:

- broader provider parity beyond Postmark and SendGrid
- public replay API, inline/async execution configuration, and operator-facing
  replay tooling
- operator and UI surfaces
- expanded matcher surface beyond recipient, subject, and header clauses

That means no body matching, attachment matching, raw MIME matching,
multi-match routing, or mailbox lifecycle hooks are part of the package
contract yet. Provider internals and replay internals remain package-local.

## Contract Inventory

Use [`docs/api_stability.md`](docs/api_stability.md) as the canonical contract
inventory for what is stable now, what is internal, and what remains deferred.
