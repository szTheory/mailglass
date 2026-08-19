---
phase: 160-certification-documentation-and-release
plan: 03
subsystem: release-baseline-reconciliation
tags: [release, hex, versions, manifests, changelog, fail-closed]
requires: [REL-03, REL-01]
provides:
  - credential-free live Hex versus repository reconciliation
  - exact three-package published baseline metadata
  - inactive version-neutral release target contract
affects: [release-certification, release-authorization, package-stability]
tech-stack:
  added: []
  patterns: [narrow source parsing, exact-schema validation, read-only live evidence]
key-files:
  created:
    - scripts/reconcile_release_versions.exs
    - test/scripts/reconcile_release_versions_test.exs
  modified:
    - .planning/release-target.json
    - .release-please-manifest.json
    - mix.exs
    - mailglass_admin/mix.exs
    - mailglass_inbound/mix.exs
    - CHANGELOG.md
    - mailglass_admin/CHANGELOG.md
    - mailglass_inbound/CHANGELOG.md
    - .planning/publish/mailglass-publish-summary.json
    - .planning/publish/mailglass_admin-publish-summary.json
    - .planning/publish/mailglass_inbound-publish-summary.json
key-decisions:
  - "Repository baselines reconcile only to versions already public on Hex: core/admin 2.4.1 and inbound 2.1.2."
  - "The reconciler never derives a next version and fails closed on incomplete, retired, malformed, duplicate, or disagreeing evidence."
  - "The release target is an exact inactive three-package schema with null candidates and identities, unauthorized authorization state, and no publication state transition."
requirements-completed: [REL-03]
completed: 2026-08-18
---

# Phase 160 Plan 03: Published Baseline Reconciliation Summary

Repository release truth now matches the three package versions already public
on Hex, backed by credential-free live metadata and the immutable historical
`mailglass-v2.4.1` tag. The release target is inactive and contains no inferred
or authorized candidate.

## Accomplishments

- Added a narrow, non-evaluating parser for the three Mix versions, the complete
  Release Please manifest package set, and the three sibling dependency
  constraints.
- Added credential-free HTTPS reads of each Hex package endpoint and exact
  release endpoint. Reconciliation checks stable versions, package identity,
  retirement, docs presence, checksums, source/manifest equality, core/admin
  linkage, and all live dependency constraints.
- Added fixture and source-mutation tests for missing, duplicate, unknown,
  malformed, prerelease, retired, conflicting, and constraint-mismatched
  evidence. Drift reports contain exact source/live values but never a
  candidate version.
- Reconciled source versions and Release Please state to public core/admin
  `2.4.1` and inbound `2.1.2` without advancing any package beyond live truth.
- Restored only the version-coupled historical changelog entries and publish
  summary fields proven by `mailglass-v2.4.1`; unrelated tagged source and
  artifact metadata were not copied.
- Replaced the old active two-package target with an exact inactive
  three-package schema. `candidate_versions`, proposal head/source SHAs,
  publishable-content digest, and final tag SHA are all null; authorization is
  `unauthorized` and publication is `not_started`.
- Added strict shared target and review schema validation that rejects missing
  or unexpected fields at every layer, including evidence endpoint/checksum/tag
  identifiers. Activation accepts only exact captured or authorized
  prepublication lifecycle state and still requires every automation-proposed
  package to advance its baseline.

## Commits

- `f3f3ce9d` — specify release baseline reconciliation (TDD red)
- `4b5db8d1` — add fail-closed release reconciliation (TDD green)
- `9182cf2f` — accept active Hex package summaries while retaining exact-release retirement authority
- `f17bbfb9` — require exact reconciled baseline metadata (Task 2 TDD red)
- `6c8ec1db` — reconcile published package baselines (Task 2 TDD green)
- `27ec9518` — expose activation schema bypasses (review TDD red)
- `1fa44e14` — enforce exact activation and reviewed-output schemas (review TDD green)

## Verification

- `mix run scripts/reconcile_release_versions.exs --check-live` — result
  `ok`, repository/live baselines equal at `2.4.1/2.4.1/2.1.2`, empty drift,
  and all three public checksums matched.
- `mix test test/scripts/reconcile_release_versions_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors`
  — 24 tests, 0 failures.
- `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors`
  — 5 tests, 0 failures.
- `cd mailglass_inbound && mix test test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors`
  — 8 tests, 0 failures.
- `mix run scripts/reconcile_release_versions.exs --validate-inactive-target .planning/release-target.json`
  — result `ok` with inactive, unauthorized, unpublished state.
- Scoped formatting, JSON parsing, and `git diff --check` passed.

## Deviations and Notes

### Hex package summaries omit active retirement fields

The first live check failed closed because the package-level Hex release summary
omits `retirement` for an active release. A test-first parser correction now
accepts an absent or null summary retirement field while keeping the exact
release endpoint authoritative. Any non-null summary retirement or exact
release retirement still fails closed.

### Historical metadata scope

The immutable historical tag proves the missing changelog entries and
version-coupled publish-summary fields. Existing file inventories, tarball
sizes, and other artifact metadata were deliberately preserved rather than
copying unrelated historical-tag source.

### Independent activation-schema review

Independent review found that the original activation validator checked
candidate identity but did not reuse the inactive target's exact base schema;
missing evidence and unknown target/review fields could therefore pass. The
review correction added mutation-first coverage for every target layer,
required endpoint/checksum/tag evidence, reviewed automation output, lifecycle
state, and the all-three advance rule. Both captured/unauthorized and
authorized prepublication targets validate only with exact nested schemas;
publication state remains `not_started`.

## Scope Confirmation

No candidate version was inferred or written. No release was captured,
authorized, tagged, published, or otherwise externally mutated. No credential,
workflow authorization, admin/operator UI code, route, LiveView, styling,
navigation, or browser behavior changed.

## Self-Check: PASSED

REL-03 has exact current public truth and an inactive, version-neutral release
target.
