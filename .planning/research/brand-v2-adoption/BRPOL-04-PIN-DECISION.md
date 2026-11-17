# BRPOL-04 Pin Correction Decision

**Date:** 2026-11-17
**Status:** Approved correction recorded

## Decision

Use the owner-approved brand v2.0.1 archive as the current canonical pin for BRPOL-04. Its archive commit is `677b9d300e0da01abb199076b301bae36447d2da` and its SHA-256 is `3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56`.

The Phase 179 plan originally specified brand v2.0 at commit `240bdd214746b956162b8d4f2f82d4b178106eff`, SHA-256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`. Phase 183's approved correction replaces the small-size favicon source and records the v2.0.1 archive and favicon bytes in `183-02-SUMMARY.md`. The current manifest and pin test both use the v2.0.1 archive; the source and Admin-served favicon match SHA-256 `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5`.

The live BRPOL-04 requirement and Phase 179 roadmap criterion now name v2.0.1. The original Phase 179 context, plan, and summary remain unchanged as historical records. This is a documented correction to the requirement's current source of truth, not an override of the v2.0.1 correction and not a rollback to v2.0.

## Remediation Scope

On 2026-11-17 the owner authorized up to three gap-closure plans, one each in Phases 179, 182, and 183. This bounded authorization raises the plan count from 21 to at most 24 and leaves the five-phase roadmap unchanged. It supersedes Phase 183's earlier no-further-plan-expansion note for these three gap closures only.

The existing favicon-capture stop remains in effect until the producer-provenance failure is resolved. Preserve the accepted catalog and its PNGs; do not recapture, rewrite its manifest, loosen the producer check, or rerun the blocked alias. First authenticate the historical producer source recorded by the catalog. Keep the current producer digest check for future captures.

## Evidence

- `183-02-SUMMARY.md` records that the small-size favicon correction from commit `677b9d300e0da01abb199076b301bae36447d2da` was owner-approved, names the v2.0.1 archive hash, and reports the focused brand-pin contract passing.
- `179-VERIFICATION.md` identified the old-vs-current digest mismatch and recommended reconciling the live requirement or restoring the original source.
- The user approved following the recommendation and authorized the bounded three-plan gap-closure scope on 2026-11-17.
