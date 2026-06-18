# Thread: Transport Expansion Watchlist

**Opened:** 2026-05-27
**Status:** open
**Priority:** watchlist (not next)
**Owner:** maintainer
**Last reviewed:** 2026-06-17 — all three items remain correctly UNPROMOTED. No adopter pull has
surfaced through v1.12 for Cloudflare Email Routing, synthetic inbound dev tooling, or a `gen_smtp`
listener. The 2026-06-17 post-v1.12 next-step assessment reaffirms these as flat-tail /
diminishing-returns and (with the onboarding wedge now closed) confirms they are the *only* remaining
expansion candidates — all pull-gated. Keep deferred; revisit only on explicit adopter pull.
Next review: next milestone-discovery pass.

## Question

When should transport-adjacent inbound expansion be promoted, and how should it
be split to avoid scope coupling?

## Items

- Cloudflare Email Routing support (prefer recipe/docs until first-party signed
  contract is compelling).
- Synthetic inbound dev tooling (high DX, but requires strict dev-only and
  tenant/provenance safety gates).
- `gen_smtp` listener ingress (separate transport class; evaluate only with
  strong pull).

## Promotion Rules

- Promote only with clear adopter pull and a narrow problem statement.
- Do not bundle all transport-adjacent items into one milestone.
- Preserve one-person maintainer sustainability over capability breadth.

## Exit Signal

This thread closes when each item is either:
- promoted into a specifically-scoped milestone, or
- explicitly deferred with an updated rationale and review date.
