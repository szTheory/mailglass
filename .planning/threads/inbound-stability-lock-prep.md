# Thread: Inbound Stability Lock Prep

**Opened:** 2026-05-27  
**Status:** open  
**Priority:** high (next after trust-proof milestone)  
**Owner:** maintainer

## Question

What must be locked for `mailglass_inbound` to move from broad 0.x capability
to a clearer long-lived stability posture?

## Initial Focus

- Reconcile `mailglass_inbound` contract docs with shipped `0.2.0` behavior.
- Define inbound compatibility/deprecation posture without weakening core
  `mailglass` + `mailglass_admin` `1.x` clarity.
- Add/upgrade contract verification lanes for inbound surfaces.

## Known Drift To Resolve

- `mailglass_inbound` runtime is broader than parts of current stability framing.
- Public docs should avoid under-claiming shipped behavior while preserving
  strict stable/internal/deferred boundaries.

## Exit Signal

This thread closes when a scoped inbound stability milestone is selected with
explicit non-goals and verification criteria.
