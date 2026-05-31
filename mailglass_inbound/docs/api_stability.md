# API Stability - mailglass_inbound

This document is the canonical contract inventory for the shipped
`mailglass_inbound` slice.

For this package, stability is semantics-first. ExDoc visibility, generated
documentation reachability, and module reachability do not define the contract
by themselves. The contract is the explicit inventory in this file plus the
documented command, telemetry, error, and testing semantics named here.

It answers four questions:

1. Which runtime and operator semantics are stable now.
2. Which test helpers are adopter-facing testing support.
3. Which reachable modules are internal implementation details.
4. Which capabilities remain deferred and must not be inferred from source
   reachability.

## Contract Posture

### `stable`

These surfaces are part of the documented inbound adopter contract:

- `MailglassInbound` and `MailglassInbound.version/0`
- `MailglassInbound.InboundMessage`
- `MailglassInbound.Ingress.Plug`
- `MailglassInbound.Ingress.CachingBodyReader`
- `MailglassInbound.Router`
- `MailglassInbound.Mailbox`
- `MailglassInbound.PubSub.Topics`
- stable Mix task behavior for `mix mailglass.inbound.doctor`,
  `mix mailglass.inbound.replay`, and `mix mailglass.inbound.prune`
- PII-safe telemetry families under the `[:mailglass_inbound, ...]` names
  documented below
- stable structured errors `MailglassInbound.MIMEError`,
  `MailglassInbound.SignatureError`, and `MailglassInbound.S3FetchError`
- the documented storage boundary between canonical normalized rows and raw
  evidence used for replay and audit truth

Stable means adopters may rely on:

- one canonical `%MailglassInbound.InboundMessage{}` value object
- one explicit manual setup path with `Plug.Parsers` body-reader wiring
- `MailglassInbound.Ingress.Plug` provider semantics for
  `provider: :postmark | :sendgrid | :mailgun | :ses`
- verify before tenant resolution, tenant work, or persistence
- canonical normalized row plus raw evidence row persisted before mailbox execution
  is dispatched
- duplicate acknowledgement from durable receive truth rather than mailbox
  outcomes
- replay remaining distinct from fresh provider receipt semantics
- replay remaining distinct from fresh receive semantics
- Task.Supervisor fallback being bounded best-effort only when Oban is absent
- router matching by recipient, subject, and header only
- one mailbox callback, `process/1`, with the documented outcomes only
- operator tasks at the command-behavior level only
- telemetry stability at event-family and PII-safe metadata-shape level
- closed `:type` sets for the stable inbound error structs documented below

### `testing`

These surfaces ship in `lib/` for adopters to drive and assert inbound flows in
their own suites. They sit alongside the stable runtime contract as a distinct
testing surface; they are not internal and they are not runtime APIs:

- `MailglassInbound.Fixtures` - builders for canonical
  `%MailglassInbound.InboundMessage{}` values and raw provider payloads that
  round-trip through real provider verify/normalize seams.
- `MailglassInbound.Test.Ingress` - drives the real synchronous persist, route,
  and execute write path and captures the outcome in the test process. Drive
  routing through the `:router` option with a compiled `use
  MailglassInbound.Router` module. The internal
  `MailglassInbound.Router.Route` struct is not part of the testing contract.
- `MailglassInbound.TestAssertions` - `assert_inbound_*` matchers reading the
  captured outcome.
- `MailglassInbound.MailboxCase` - the `ExUnit.CaseTemplate` adopters `use`,
  which imports assertions, checks out the adopter repo sandbox, sets tenancy,
  and resets process-global fixture state.

### `internal`

These surfaces may be exported, visible in generated docs, reachable in source,
or used by first-party packages, but they are implementation details:

- `MailglassInbound.OptionalDeps`
- `MailglassInbound.OptionalDeps.Oban`
- `MailglassInbound.Execution`
- `MailglassInbound.Execution.Worker`
- `MailglassInbound.Ingress.Provider`
- `MailglassInbound.Ingress.Providers.Postmark`
- `MailglassInbound.Ingress.Providers.Sendgrid`
- `MailglassInbound.Ingress.Providers.Mailgun`
- `MailglassInbound.Ingress.Providers.SES`
- `MailglassInbound.Ingress.Persist`
- `MailglassInbound.Internal.Doctor`
- `MailglassInbound.Internal.Replay`
- `MailglassInbound.Internal.Prune`
- `MailglassInbound.Prune.Worker`
- `MailglassInbound.Router.Route`
- package-local persistence modules under `MailglassInbound.InboundRecords.*`
- repo and schema helpers used to stamp package-owned storage
- queue names, retry tuning, worker args, direct Oban job shapes, and direct
  `Oban` integration details
- Task.Supervisor startup and process wiring
- admin or operator UI implementation details, DOM, CSS, LiveView modules,
  components, assigns, route structs, and event names

`MailglassInbound.OptionalDeps.Oban` is intentionally reachable so the package
can branch on Oban availability without forcing direct `Oban` references into
adopter code. Availability checks through this module are supported, but worker
modules, Oban job structs, queue names, and enqueue internals are not part of
the stable contract. These details are not part of the stable contract.

`MailglassInbound.Ingress.Provider` and the
`MailglassInbound.Ingress.Providers.*` modules are provider implementation
support only. Provider support is stable through `MailglassInbound.Ingress.Plug`
options and behavior, not through provider module APIs.

Replay, doctor, and prune orchestration modules are also internal. The package
preserves the command semantics listed here, but internal modules, job structs,
queue contracts, and worker arguments remain maintainer-owned.

### `deferred`

These capabilities are explicitly deferred:

- public replay API and public replay rerouting controls
- public provider extension API
- public worker or queue contracts
- matcher expansion beyond recipient, subject, and header matching
- lifecycle callbacks beyond `process/1`
- multi-route fan-out
- synthetic inbound development UI
- `gen_smtp` listener support
- ecosystem integrations
- operator or admin UI APIs for inbound inspection and replay
- body matching, attachment matching, raw MIME matching, and boolean predicate
  combinators

Deferred means the package does not promise these capabilities in the current
contract, even if an internal name, TODO, test fixture, or first-party
implementation detail mentions adjacent work.

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

Stable first-party provider ingress seam for `provider: :postmark`,
`provider: :sendgrid`, `provider: :mailgun`, and `provider: :ses`.

Documented guarantees:

- verifies provider authenticity before tenant resolution or persistence
- resolves tenant scope only after verification succeeds
- normalizes only into the locked `%MailglassInbound.InboundMessage{}`
- persists a canonical row plus raw evidence row before mailbox execution is
  dispatched
- acknowledges provider retries from durable receive truth instead of mailbox
  outcomes
- treats duplicate receives as durable receive truth, not mailbox re-execution
- keeps replay distinct from fresh provider receipt
- maps explicit rejection, tenant failure, config failure, duplicate,
  control-plane, replay, and S3 fetch outcomes through documented response
  semantics
- keeps provider modules internal; adopters configure the plug, not
  `MailglassInbound.Ingress.Provider` or provider module APIs

Postmark and Mailgun signed payloads use verify-first request handling.
SendGrid raw MIME ingress uses basic auth and raw MIME parsing. SES SNS ingress
verifies SNS authenticity before persisting the canonical message and raw
evidence.

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
- recipient, subject, and header matching are the only stable matchers
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
- replay uses stored canonical and raw evidence truth, but replay
  orchestration remains internal rather than public API

### `MailglassInbound.PubSub.Topics`

Stable PubSub topic builder for inbound subscribers.

Documented guarantees:

- topic strings are derived through this module, never hand-built by adopters
- every topic carries the `mailglass:` prefix required by the project's
  PubSub-topic convention
- topics are tenant-scoped where the subscribed resource is tenant-owned

### Mix tasks

#### `mix mailglass.inbound.doctor`

Stable operator behavior:

- exit code `0` means the checked inbound wiring passes
- exit code `1` means findings were detected
- exit code `2` means the doctor could not complete because configuration or
  environment preconditions are missing
- `--strict`, `--format json`, and `--verbose` are documented command options
- JSON output is for operator automation; internal module shapes remain private

#### `mix mailglass.inbound.replay`

Stable operator behavior:

- requires `--tenant`
- replays stored canonical and raw evidence truth
- uses `[y/N]` confirmation unless `--yes` is supplied
- never treats replay as a new provider receipt
- does not promise public replay API, public rerouting controls, worker args,
  queue names, or job struct contracts

#### `mix mailglass.inbound.prune`

Stable operator behavior:

- requires typed `yes` confirmation unless `--yes` is supplied
- performs destructive retention cleanup according to documented options
- runs synchronously with or without Oban
- treats `MailglassInbound.Prune.Worker` as optional scheduling support and
  internal implementation detail

### Telemetry families

The stable telemetry contract is event-family and metadata-shape based:

- `[:mailglass_inbound, :ingress, :request, :start | :stop | :exception]`
- `[:mailglass_inbound, :route, :match, :start | :stop | :exception]`
- `[:mailglass_inbound, :persist, :record, :start | :stop | :exception]`
- `[:mailglass_inbound, :execution, :run, :start | :stop | :exception]`
- `[:mailglass_inbound, :ingress, :rate_limit, :start | :stop | :exception]`
- `[:mailglass_inbound, :ingress, :suppression_flag, :start | :stop | :exception]`
- `[:mailglass_inbound, :prune, :sweep, :start | :stop | :exception]`

Telemetry remains stable at the documented event-name family and PII-safe
metadata level. Helper functions, internal emitters, handler wiring, and UI
consumers are not promoted to stable API. Metadata must not include raw
payloads, body text, HTML, headers, sender or recipient addresses, subject
lines, or other PII.

### `MailglassInbound.MIMEError`

Stable structured error for raw MIME parse failures, matched by struct and
`:type`, never by message string.

Closed `:type` set:

- `:inbound_mime_invalid`
- `:gen_smtp_unavailable`

Documented guarantees:

- raised or returned when raw MIME source cannot be parsed into a canonical
  `%MailglassInbound.InboundMessage{}`
- carries a closed, documented `:type` set so callers pattern-match on the
  struct rather than the message
- does not leak raw MIME bytes or recipient PII in its message

### `MailglassInbound.SignatureError`

Stable, no-recovery structured error for inbound provider signature
verification failures, matched by struct and `:type`, never by message string.

Closed `:type` set:

- `:bad_signature`
- `:missing_header`
- `:malformed_header`
- `:timestamp_skew`
- `:subscribe_url_untrusted`

Documented guarantees:

- raised when an inbound Mailgun HMAC or SES SNS X.509 signature fails to
  verify, or when an SNS `SubscribeURL` or `SigningCertURL` fails trust-policy
  validation
- the ingress plug maps it to a 401 with no recovery path
- excludes `:cause` and `:provider` from serialized `Jason.Encoder` output so
  signing secrets and raw payload fragments never leak
- is package-local and does not implement the core `Mailglass.Error` behaviour

### `MailglassInbound.S3FetchError`

Stable structured error for AWS SES inbound S3-object fetch failures, matched
by struct and `:type`, never by message string.

Closed `:type` set:

- `:s3_object_not_ready` - bounded `GetObject` retry exhausted; transient, SNS
  redelivers because the handler does not ack
- `:s3_fetch_failed` - non-retryable S3 error

Documented guarantees:

- raised or returned when a SES receipt-rule S3 action object cannot be fetched
  for MIME parsing
- carries a closed, documented `:type` set so callers pattern-match on the
  struct rather than the message
- excludes `:cause` from serialized `Jason.Encoder` output so raw S3 or error
  fragments never leak
- is package-local and does not implement the core `Mailglass.Error` behaviour

## Inventory Notes

- Stable does not mean everything ExDoc renders.
- Exported does not mean stable.
- Hidden docs do not make a surface private.
- Module reachability is not a compatibility promise.
- If a new inbound seam is meant to be stable for adopters, add it here and add
  matching docs-contract assertions.
