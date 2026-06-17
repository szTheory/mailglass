# Thread: Inbound Stability Lock Prep

**Opened:** 2026-05-27
**Status:** resolved (2026-06-16)
**Priority:** —
**Owner:** maintainer

## Resolution (2026-06-16)

Closed by shipped milestones. **v1.4 Inbound Stability Lock** (2026-06-01) reconciled
`mailglass_inbound/docs/api_stability.md` into a canonical stable/testing/internal/deferred
inventory with executable docs-contract guards and selected the `1.0.0` candidate; **v1.6**
(2026-06-02) published `mailglass_inbound` `1.0.0` live on Hex on its own stable `1.0` contract
line. Inbound is now at **1.3.1**, carrying the same long-lived compatibility posture as
core/admin. The drift and exit-signal conditions below are all satisfied. No further action.

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
