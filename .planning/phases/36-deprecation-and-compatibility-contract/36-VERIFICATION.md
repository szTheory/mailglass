---
phase: 36-deprecation-and-compatibility-contract
verified: 2026-05-06T08:46:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
human_verification: []
---

# Phase 36: Deprecation & Compatibility Contract Verification Report

**Phase Goal:** Adopters can upgrade within `1.x` and from the latest `0.x` path using one narrow, explicit compatibility promise.
**Verified:** 2026-05-06T08:46:00Z
**Status:** passed
**Re-verification:** Yes - after audit artifact recovery

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Adopters can read one canonical `1.x` versioning and deprecation policy covering guarantees and security/correctness exceptions. | ✓ VERIFIED | [guides/compatibility-and-deprecations.md](/Users/jon/projects/mailglass/guides/compatibility-and-deprecations.md:1), [README.md](/Users/jon/projects/mailglass/README.md:230), and [mailglass_admin/docs/compatibility-and-deprecations.md](/Users/jon/projects/mailglass/mailglass_admin/docs/compatibility-and-deprecations.md:1) all point at the same policy. |
| 2 | Adopters can read one support matrix covering runtime floors, Phoenix/Postgres scope, sibling-package expectations, and optional-dependency lanes. | ✓ VERIFIED | The support matrix is defined in [guides/compatibility-and-deprecations.md](/Users/jon/projects/mailglass/guides/compatibility-and-deprecations.md:1) and mechanically checked by [test/mailglass/compatibility_contract_test.exs](/Users/jon/projects/mailglass/test/mailglass/compatibility_contract_test.exs:1). |
| 3 | Adopters can follow one canonical `0.x -> 1.0` upgrade guide that identifies legacy entrypoints, required code changes, and warning behavior. | ✓ VERIFIED | [guides/upgrading-to-v1_0.md](/Users/jon/projects/mailglass/guides/upgrading-to-v1_0.md:1) is the single upgrade authority and is pinned by [test/mailglass/docs_migration_smoke_test.exs](/Users/jon/projects/mailglass/test/mailglass/docs_migration_smoke_test.exs:1). |
| 4 | Maintainers can verify every still-supported deprecated path has a documented replacement and no planned removal before `v2.0`. | ✓ VERIFIED | Retained compatibility bridges are explicitly inventoried in [test/mailglass/compatibility_contract_test.exs](/Users/jon/projects/mailglass/test/mailglass/compatibility_contract_test.exs:1), and `mix verify.docs.migration` passed on 2026-05-06. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `guides/compatibility-and-deprecations.md` | Canonical compatibility and deprecation policy | ✓ VERIFIED | Exists and is linked from root, admin, maintainer, and stability docs. |
| `guides/upgrading-to-v1_0.md` | Canonical upgrade guide | ✓ VERIFIED | Exists and remains the single latest-`0.x` to `1.0` authority. |
| `test/mailglass/compatibility_contract_test.exs` | Compatibility inventory and support-matrix proof | ✓ VERIFIED | Passed in the 2026-05-06 root milestone bundle. |
| `test/mailglass/docs_migration_smoke_test.exs` | Upgrade-guide smoke proof | ✓ VERIFIED | Passed in the 2026-05-06 root milestone bundle and via `mix verify.docs.migration`. |
| `lib/mix/tasks/mailglass.docs.check.ex` | Tier 1 docs checks for compatibility and upgrade guides | ✓ VERIFIED | Present and exercised through the root docs/verification lanes. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `README.md` | `guides/compatibility-and-deprecations.md` | Tier 1 compatibility pointer | ✓ WIRED | Root README sends adopters to the canonical policy. |
| `README.md` | `guides/upgrading-to-v1_0.md` | canonical upgrade pointer | ✓ WIRED | Root README points to the canonical upgrade path. |
| `mailglass_admin/README.md` | `guides/compatibility-and-deprecations.md` | sibling compatibility pointer | ✓ WIRED | Admin README points to the shared compatibility contract. |
| `lib/mix/tasks/mailglass.docs.check.ex` | `guides/compatibility-and-deprecations.md` / `guides/upgrading-to-v1_0.md` | Tier 1 required tokens | ✓ WIRED | Docs drift checks treat both guides as release-blocking truth. |
| `test/mailglass/docs_migration_smoke_test.exs` | `guides/upgrading-to-v1_0.md` | canonical-guide assertions | ✓ WIRED | The smoke test enforces recommendation-first upgrade wording and proof commands. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Compatibility + upgrade bundle | `mix test test/mailglass/compatibility_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` | Included in the 2026-05-06 root milestone bundle; green | ✓ PASS |
| Strict upgrade proof alias | `mix verify.docs.migration` | `9 tests, 0 failures` | ✓ PASS |
| Core docs build | `mix docs --warnings-as-errors` | Succeeded | ✓ PASS |
| Admin docs build | `cd mailglass_admin && mix docs --warnings-as-errors` | Succeeded | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `COMPAT-01` | `36-01`, `36-03` | Adopter can read one canonical `1.x` versioning and deprecation policy. | ✓ SATISFIED | Canonical policy exists and is linked from Tier 1 docs. |
| `COMPAT-02` | `36-01`, `36-03` | Adopter can read one canonical support matrix. | ✓ SATISFIED | Support matrix exists in the compatibility guide and is enforced by compatibility proof tests. |
| `COMPAT-03` | `36-02`, `36-03` | Adopter can follow a canonical `0.x -> 1.0` upgrade guide. | ✓ SATISFIED | Canonical guide and migration smoke test both passed. |
| `COMPAT-04` | `36-02`, `36-03` | Maintainer can verify retained deprecated paths have replacement/warning/no removal before `v2.0`. | ✓ SATISFIED | Compatibility inventory proof and strict upgrade verification remain green. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No goal-blocking compatibility or upgrade drift was found in the verified phase surfaces. | ℹ️ Info | Phase 36 contract is fully backed by current docs and tests. |

### Gaps Summary

No Phase 36 goal-blocking gaps remain.

The prior audit gap was documentation-state drift only: the phase had shipped summary artifacts and passing proof lanes, but no phase-level verification report and stale requirement checkboxes. Those gaps are now closed.

---

_Verified: 2026-05-06T08:46:00Z_
_Verifier: Codex_
