---
phase: 148-release-and-adoption-proof
plan: 05
subsystem: release-evidence
tags: [hex, consumer-smoke, trust-journey, release-proof]
requires:
  - phase: 148-04
    provides: protected core/admin 2.4.0 publication
provides:
  - Registry-backed clean-consumer proof for 2.4.0/2.4.0/2.1.1
  - Final release ledger with bounded artifact provenance
affects: [milestone-closeout, adopter-installation]
key-files:
  created:
    - .planning/phases/148-release-and-adoption-proof/148-05-SUMMARY.md
    - .planning/phases/148-release-and-adoption-proof/148-VERIFICATION.md
  modified:
    - .planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md
status: complete
completed: 2026-08-02
---

# Phase 148 Plan 05: Published Consumer Proof Summary

Verified the package family adopters actually install: core/admin 2.4.0 with
inbound 2.1.1. A fresh Phoenix host resolved all packages from Hex, compiled,
booted, served HTTP 200, and completed the published trust journey.

## Registry Proof

- `mix hex.info mailglass 2.4.0` — passed.
- `mix hex.info mailglass_admin 2.4.0` — passed.
- `mix hex.info mailglass_inbound 2.1.1` — passed.
- Exact Hex and GitHub checks for `mailglass_inbound` 2.4.0 — not found, as
  required.

## Consumer Proof

Canonical core release-event smoke run
[30727822861](https://github.com/szTheory/mailglass/actions/runs/30727822861)
used the exact release SHA and completed every job successfully:

- Hex/HexDocs readiness
- `DEP_MODE=hex`, core/admin 2.4.0, inbound 2.1.1 with inbound included
- fresh Phoenix dependency resolution, compilation, installer execution, boot,
  and `GET /dev/mail/ -> HTTP 200`
- five-stage published trust journey
- package retraction checks
- automatic closure of smoke tracker issue #179

## Evidence

- Release artifact file hash:
  `16fb0acf40b2c0136315c5f9b9ef8c0fd2e97fe24d39dd3f22b959053cd3885f`.
- Published trust checkpoint file hash:
  `24858ca83da8ba49e7c2a2b500bc4c5aae676134f408b7e2928ea0bf95b2e29a`.
- ASVS L1 unresolved high-severity findings: **0**.

## Scope Boundary

REL-01 is complete for Mailglass. External B2C launch gates remain outside
this phase, and Crosswake remains intentionally absent.
