# API Stability — mailglass_inbound

This document is the canonical contract inventory for the shipped
`mailglass_inbound` slice.

It answers three questions:

1. Which surfaces are stable now.
2. Which reachable surfaces are internal implementation support.
3. Which capabilities are still deferred.

Generated docs reachability is not the contract by itself. The contract is the
explicit inventory in this file.

## Contract Posture

### `stable`

These surfaces are the stable package contract:

- `MailglassInbound`
- `MailglassInbound.InboundMessage`
- `MailglassInbound.Ingress.Plug`
- `MailglassInbound.Ingress.CachingBodyReader`
- `MailglassInbound.Router`
- `MailglassInbound.Mailbox`
- `MailglassInbound.PubSub.Topics`
- `MailglassInbound.MIMEError`
- the documented storage boundary between canonical normalized rows and raw
  evidence used for replay and audit truth

Stable means adopters may rely on:

- one canonical `%MailglassInbound.InboundMessage{}` value object
- one explicit manual setup path with `Plug.Parsers` body-reader wiring
- one Postmark ingress mount path and one SendGrid ingress mount path
- one SendGrid raw MIME path with basic auth verification
- one router DSL with recipient, subject, and header matchers only
- one mailbox callback, `process/1`, with the documented outcomes only
- canonical and raw evidence persistence happening before mailbox execution is
  dispatched
- Oban-backed execution being the durable path when Oban is present
- Task.Supervisor fallback being bounded best-effort only when Oban is absent
- replay remaining distinct from fresh receive semantics

### `internal`

These surfaces may exist for package wiring or async execution support, but they
are not part of the stable contract:

- `MailglassInbound.OptionalDeps`
- `MailglassInbound.OptionalDeps.Oban`
- `MailglassInbound.Execution`
- `MailglassInbound.Execution.Worker`
- `MailglassInbound.Ingress.Provider`
- `MailglassInbound.Ingress.Providers.Postmark`
- `MailglassInbound.Ingress.Providers.Sendgrid`
- `MailglassInbound.Ingress.Persist`
- `MailglassInbound.Internal.Replay`
- package-local persistence modules under `MailglassInbound.InboundRecords.*`
- repo and schema helpers used to stamp package-owned storage
- queue names, retry tuning, worker args, and direct `Oban` integration details
- Task.Supervisor startup and process wiring

`MailglassInbound.OptionalDeps.Oban` is intentionally reachable so the package
can branch on Oban availability without forcing direct `Oban` references into
adopter code. Availability checks through this module are supported, but worker
modules, Oban job structs, queue names, and enqueue internals are not part of
the stable contract.

Replay orchestration is also internal. The package preserves replay over stored
truth, but the replay command surface is not promised as stable here, and no
adopter-facing worker surface or operator dashboard surface is promised.

### `deferred`

These capabilities are explicitly deferred:

- public replay API, replay command surface, or replay rerouting controls
- operator or UI surfaces for inbound inspection and replay
- public worker hooks, public queue configuration, or Oban job struct contracts
- providers beyond Postmark and SendGrid
- matcher expansion beyond recipient, subject, and headers

Deferred means the package does not yet promise:

- body matching
- attachment matching
- raw MIME matching
- boolean predicate combinators
- multi-route fan-out
- mailbox lifecycle hooks beyond `process/1`

## Stable Inventory

### `MailglassInbound`

Stable root helper for package identity.

- `version/0`

### `MailglassInbound.InboundMessage`

Stable canonical normalized inbound value object.

Documented field promises in this slice:

- tenant scope
- provider provenance
- provider message reference
- RFC `Message-ID`
- envelope recipient
- normalized sender and recipient fields
- subject
- normalized headers
- sent and received timestamps
- normalized text and HTML body fields
- normalized attachment manifest without attachment bytes

The stable struct intentionally excludes raw evidence, verification facts,
replay identifiers, worker metadata, storage paths, and provider-only extras.

### `MailglassInbound.Ingress.Plug`

Stable first-party Postmark and SendGrid ingress seam.

Documented guarantees:

- verify before tenant resolution or persistence
- return explicit rejection, tenant failure, config failure, and duplicate
  outcomes
- normalize only into the locked `%MailglassInbound.InboundMessage{}`
- persist canonical row plus raw evidence row before mailbox execution is
  dispatched
- acknowledge provider retries from durable receive truth instead of mailbox
  outcomes

### `MailglassInbound.Ingress.CachingBodyReader`

Stable package-local `Plug.Parsers` helper used by the ingress plug.

Documented guarantees:

- stores exact bytes in `conn.private[:raw_body]`
- remains path-local and opt-in
- supports verify-first request handling for provider ingress
- is required for Postmark raw-body verification and not required for SendGrid
  raw MIME delivery

### `MailglassInbound.Router`

Stable router authoring seam with first-match-wins semantics.

Documented guarantees:

- routes are evaluated top to bottom
- multiple clauses on one route are logical `AND`
- exact string and regex support only
- `:no_match` is explicit and non-exceptional

### `MailglassInbound.Mailbox`

Stable mailbox callback contract.

Documented guarantees:

- `process/1` is the only stable callback
- valid outcomes are `:accept`, `:ignore`, `{:reject, reason}`, and
  `{:bounce, reason}`
- raises, throws, and exits are execution failures handled by internal runners,
  not semantic mailbox outcomes
- replay uses stored canonical and raw evidence truth, but replay orchestration
  remains internal rather than public API

### `MailglassInbound.PubSub.Topics`

Stable PubSub topic builder for inbound subscribers (admin LiveView and operator
tooling subscribe through it rather than hardcoding topic strings).

Documented guarantees:

- topic strings are derived through this module, never hand-built by adopters
- every topic carries the `mailglass:` prefix required by the project's
  PubSub-topic convention
- topics are tenant-scoped where the subscribed resource is tenant-owned

### `MailglassInbound.MIMEError`

Stable structured error for raw MIME parse failures (matched by struct, never by
message string — consistent with the project's "errors as a public API
contract" posture).

Documented guarantees:

- raised or returned when raw MIME source cannot be parsed into a canonical
  `%MailglassInbound.InboundMessage{}`
- carries a closed, documented `:type` set so callers pattern-match on the
  struct rather than the message
- does not leak raw MIME bytes or recipient PII in its message
