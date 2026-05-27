# Post-v1.2 Next-Step Assessment (2026-05-27)

**Status:** recommended next wedge  
**Recommendation owner:** maintainer assessment at milestone boundary  
**Scope intent:** milestone-candidate input for `/gsd-new-milestone` (no implementation code in this artifact)

## Summary

`v1.2` closed the inbound production-confidence milestone, so the next
highest-leverage move is **Adopter Trust Proof**: a maintained golden reference
Phoenix host app proving install -> preview -> send -> webhook -> operator flow
end to end.

This is a trust/adoption wedge, not a capability wedge.

## Why This Is Next

- Core and admin surfaces are already deep and shipped.
- Inbound runtime capability is already broad for `0.2.0`.
- The strongest remaining cross-adopter gap is proof posture fragmentation:
  tests/docs/release smoke exist, but there is no single canonical runnable host
  proving the full journey in one place.

## Ranked Wedges (current recommendation order)

1. **Adopter Trust Proof (golden reference host app)** - highest leverage now.
2. **Inbound Stability Lock** - align `mailglass_inbound` contract posture with
   shipped surface and harden compatibility/deprecation narrative.
3. **Synthetic inbound dev tooling** - high DX, but after trust + contract.
4. **Cloudflare forwarding recipe docs / narrow ecosystem slice** - pull-driven.
5. **`gen_smtp` listener transport class** - separate milestone only with strong
   adopter pull.

## Done-Enough Definition For The Recommended Next Milestone

- Add one maintained reference Phoenix host app (not fixture-only).
- Cover one complete representative flow: install -> preview -> send -> webhook
  ingest -> operator troubleshooting.
- Add one CI lane proving this reference journey on a clean baseline.
- Keep docs explicit: the reference host demonstrates usage and operations; API
  contract truth remains the stability/compatibility docs.
- Keep scope strict: no pseudo-product UI buildout, no broad provider matrix,
  no transport-class expansion.

## Explicit Overbuild Guardrails

- Do **not** bundle Cloudflare + `gen_smtp` listener + synthetic tooling into
  one milestone.
- Do **not** auto-promote `SEED-003-ecosystem-integrations`.
- Do **not** prioritize scheduled-send convenience before trust-proof and
  inbound contract-hardening wedges.

## Carry-Forward Into Next Phase Artifacts

When the next milestone is opened, copy the recommendation and guardrails from
this note into the first phase's `NN-CONTEXT.md` and `NN-PATTERNS.md` so the
execution wave stays aligned with this ranking.

## Evidence Anchors

- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/research/JTBD-COVERAGE.md`
- `README.md`
- `guides/jobs.md`
- `mailglass_inbound/README.md`
- `mailglass_inbound/docs/api_stability.md`
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex`
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
