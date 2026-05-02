---
phase: 26-runtime-per-tenant-adapter-resolution
plan: "03"
subsystem: docs
tags: [tenant, docs, routing, regression]
requires: [26-01, 26-02]
provides:
  - public multi-tenancy guide for runtime adapter routing
  - runtime config example with named adapter refs
  - docs contract coverage for the shipped routing terms and examples
affects: [guides, runtime-config, readme, docs-tests]
tech-stack:
  added: []
  patterns: [compile-checked docs example, explicit scope-boundary assertions]
key-files:
  created: []
  modified:
    - guides/multi-tenancy.md
    - config/runtime.exs
    - README.md
    - test/mailglass/docs_contract_test.exs
key-decisions:
  - "Document the shipped surface around named `adapter_ref` routes and the tenancy callback, not around deferred registry or failover ideas."
  - "Keep the single-tenant path prominent so advanced routing does not look mandatory."
  - "Pin both positive routing terms and negative scope boundaries in the docs contract suite."
patterns-established:
  - "Docs examples show different ESP, different credentials, and different stream/domain routes with the real runtime APIs."
  - "README wording now uses the same public terms the code ships: tenancy callbacks and adapter_ref routes."
requirements-completed: [TENANT-01, TENANT-02, TENANT-03]
duration: 6min
completed: 2026-05-01
---

# Phase 26 Plan 03: Docs Summary

**Honest runtime-routing docs, runtime config examples, and contract tests that pin the shipped API terms**

## Performance

- **Duration:** 6 min
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Rewrote `guides/multi-tenancy.md` around the real Phase 26 runtime routing contract: single-tenant default, named `adapter_ref` registry, tenancy callback, and queue semantics.
- Refreshed `config/runtime.exs` with reusable named route examples and added a concise README mention of tenancy callbacks plus named route refs.
- Expanded `test/mailglass/docs_contract_test.exs` so the new guide example parses and the public wording cannot drift into failover or registry-process claims.

## Task Commits

Both documentation tasks landed in the same docs commit:

1. **Task 1: Update the multi-tenancy guide, runtime config example, and README for the shipped routing surface** - `9437430`
2. **Task 2: Lock the docs against API drift with contract coverage** - `9437430`

## Verification

- `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors`

## Issues Encountered

- The docs contract suite initially asserted lowercase phrasing while the guide used title-cased headings. The assertion was corrected to pin the actual rendered heading text instead of a different casing.
