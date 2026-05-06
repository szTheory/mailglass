# MailglassInbound

`mailglass_inbound` is the inbound sibling package for Mailglass.

Phase 39 establishes the package foundation only: one canonical normalized
inbound message contract, one router DSL, one mailbox behaviour, and one
 package-local storage boundary between canonical rows and raw evidence.

## Stable in Phase 39

- `MailglassInbound.InboundMessage` is the stable normalized value object used
  for routing and mailbox processing.
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

Replay is explicit execution against stored evidence. It is not presented as a
fresh inbound receive.

## Optional Oban Seam

Phase 39 keeps an optional Oban seam without making Oban mandatory.
`MailglassInbound.OptionalDeps.Oban` reports whether Oban is available so later
internal execution runners can branch cleanly. No queue configuration,
worker contract, or job-shaped return value is promised in this phase.

## Deferred Beyond Phase 39

These capabilities are intentionally deferred:

- provider-specific Postmark and SendGrid ingress implementations
- inline, async, and replay execution runners beyond the stable mailbox
  callback contract
- operator and UI surfaces
- expanded matcher surface beyond recipient, subject, and header clauses

That means no body matching, attachment matching, raw MIME matching,
multi-match routing, or mailbox lifecycle hooks are part of the package
contract yet.

## Contract Inventory

Use [`docs/api_stability.md`](docs/api_stability.md) as the canonical contract
inventory for what is stable now, what is internal, and what remains deferred.
