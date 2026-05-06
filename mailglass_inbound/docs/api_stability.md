# API Stability — mailglass_inbound

This document is the canonical contract inventory for the `mailglass_inbound`
package foundation shipped in Phase 39.

It answers three questions:

1. Which surfaces are stable now.
2. Which reachable surfaces are internal implementation support.
3. Which capabilities are deferred to later phases.

Generated docs reachability is not the contract by itself. The contract is the
explicit inventory in this file.

## Contract Posture

### `stable`

These surfaces are the stable Phase 39 package contract:

- `MailglassInbound`
- `MailglassInbound.InboundMessage`
- `MailglassInbound.Router`
- `MailglassInbound.Mailbox`
- the documented storage boundary between canonical normalized rows and raw
  evidence used for replay and audit truth

Stable means adopters may rely on:

- one canonical `%MailglassInbound.InboundMessage{}` value object
- one router DSL with recipient, subject, and header matchers only
- one mailbox callback, `process/1`, with the documented outcomes only
- replay remaining distinct from fresh receive semantics

### `internal`

These surfaces may exist for package wiring, compile support, or future
execution work, but they are not part of the stable contract:

- `MailglassInbound.OptionalDeps`
- `MailglassInbound.OptionalDeps.Oban`
- package-local persistence modules under `MailglassInbound.InboundRecords.*`
- repo and schema helpers used to stamp package-owned storage

`MailglassInbound.OptionalDeps.Oban` is intentionally reachable so later plans
can add execution runners without hard-coupling Oban into the package.
Availability checks through this module are supported, but Oban-backed workers,
queue names, and direct `Oban` integration details are not part of the stable
contract.

### `deferred`

These capabilities are explicitly deferred beyond Phase 39:

- provider-specific Postmark ingress
- provider-specific SendGrid ingress
- execution implementations for inline, async, bounded fallback, or replay
  runners
- operator or UI surfaces
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

Documented field promises in Phase 39:

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
replay identifiers, mailbox outcomes, storage paths, and provider-only extras.

### `MailglassInbound.Router`

Stable router authoring seam with first-match-wins semantics.

Documented guarantees:

- routes are evaluated top to bottom
- multiple clauses on one route are logical `AND`
- exact string and regex support only
- no-match is explicit and non-exceptional

### `MailglassInbound.Mailbox`

Stable mailbox callback contract.

Documented guarantees:

- `process/1` is the only stable callback
- valid outcomes are `:accept`, `:ignore`, `{:reject, reason}`, and
  `{:bounce, reason}`
- raises, throws, and exits are execution failures handled by internal runners,
  not semantic mailbox outcomes
