---
phase: 35-stability-contract-audit
verified: 2026-05-06T08:45:00Z
reverified: 2026-05-26T13:32:57Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
human_verification: []
---

# Phase 35: Stability Contract Audit Verification Report

**Phase Goal:** Adopters and maintainers can identify the exact stable `v1.x` contract across `mailglass` and `mailglass_admin`, including what remains internal.
**Verified:** 2026-05-06T08:45:00Z
**Status:** passed
**Re-verification:** Yes - after audit artifact recovery

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Adopters can find one canonical inventory of stable `mailglass` modules, behaviours, mix tasks, telemetry names, structs, and documented fields promised for `v1.x`. | ✓ VERIFIED | [docs/api_stability.md](/Users/jon/projects/mailglass/docs/api_stability.md:1), [README.md](/Users/jon/projects/mailglass/README.md:133), and [lib/mailglass.ex](/Users/jon/projects/mailglass/lib/mailglass.ex:1) all point at the same core contract surface. |
| 2 | Adopters can find one canonical inventory of stable `mailglass_admin` router, auth, and operator seams, with UI implementation details marked internal. | ✓ VERIFIED | [mailglass_admin/docs/api_stability.md](/Users/jon/projects/mailglass/mailglass_admin/docs/api_stability.md:1), [mailglass_admin/README.md](/Users/jon/projects/mailglass/mailglass_admin/README.md:16), [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:1), and [mailglass_admin/lib/mailglass_admin/auth.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/auth.ex:1) present the same narrow stable boundary. |
| 3 | Maintainers can classify exported-but-unsupported surfaces as internal or sibling-package-only without expanding the accidental public contract. | ✓ VERIFIED | Core and admin contract pages both distinguish stable, internal, and sibling-package-only surfaces in [docs/api_stability.md](/Users/jon/projects/mailglass/docs/api_stability.md:22) and [mailglass_admin/docs/api_stability.md](/Users/jon/projects/mailglass/mailglass_admin/docs/api_stability.md:7), while docs checks keep the wording pinned in [test/mailglass/docs_contract_test.exs](/Users/jon/projects/mailglass/test/mailglass/docs_contract_test.exs:1). |
| 4 | Generated docs show `@since` and deprecation metadata on stable public APIs so the contract is visible at the point of use. | ✓ VERIFIED | Compiled-doc assertions in [test/mailglass/stability_contract_test.exs](/Users/jon/projects/mailglass/test/mailglass/stability_contract_test.exs:1) and [mailglass_admin/test/mailglass_admin/stability_contract_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/stability_contract_test.exs:1) pass, and both docs builds completed with warnings as errors on 2026-05-06. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docs/api_stability.md` | Canonical core stability inventory | ✓ VERIFIED | Exists and is linked from the root adopter docs. |
| `mailglass_admin/docs/api_stability.md` | Canonical admin stability inventory | ✓ VERIFIED | Exists and defines the stable router/auth/operator seam while excluding UI internals. |
| `test/mailglass/stability_contract_test.exs` | Compiled-doc metadata proof for core stable surfaces | ✓ VERIFIED | Passed in the 2026-05-06 root verification bundle. |
| `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` | Compiled-doc metadata proof for admin stable surfaces | ✓ VERIFIED | Passed in the 2026-05-06 admin verification bundle. |
| `test/mailglass/docs_contract_test.exs` | Tier 1 docs contract for stability entrypoints | ✓ VERIFIED | Passed in the 2026-05-06 root verification bundle. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `README.md` | `docs/api_stability.md` | API Stability section | ✓ WIRED | Root README points adopters to the canonical contract page. |
| `mailglass_admin/README.md` | `mailglass_admin/docs/api_stability.md` | admin contract pointers | ✓ WIRED | Admin README points adopters to the canonical admin contract page. |
| `mix.exs` | `docs/api_stability.md` | ExDoc extras | ✓ WIRED | Core docs config surfaces the contract page in generated docs. |
| `mailglass_admin/mix.exs` | `mailglass_admin/docs/api_stability.md` | ExDoc extras | ✓ WIRED | Admin docs config surfaces the contract page in generated docs. |
| `test/mailglass/stability_contract_test.exs` | compiled docs | `Code.fetch_docs/1` | ✓ WIRED | Core compiled-doc truth is enforced against the documented stable surface. |
| `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` | compiled docs | `Code.fetch_docs/1` | ✓ WIRED | Admin compiled-doc truth is enforced against the documented stable surface. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Root stability/docs contract bundle | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` | Included in the 2026-05-06 root docs/contract run; `29 tests, 0 failures` across the milestone bundle | ✓ PASS |
| Admin stability contract bundle | `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors` | Included in the 2026-05-06 admin milestone bundle; green | ✓ PASS |
| Core docs build | `mix docs --warnings-as-errors` | Succeeded | ✓ PASS |
| Admin docs build | `cd mailglass_admin && mix docs --warnings-as-errors` | Succeeded | ✓ PASS |

### Phase 51 Bookkeeping Re-Verification

Per D-01, Phase 51 treats CLOSE-01 as bookkeeping repair only, but reran the
archived Phase 35 proof bundle before touching any Nyquist state.

| Rerun Date | Command | Result | Notes |
| --- | --- | --- | --- |
| 2026-05-26 | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors && mix docs --warnings-as-errors >/tmp/mailglass-admin-phase35-docs.log && rg -n "api_stability\|Stability\|Contract" doc/**/*.html doc/dist/search_data-*.js` | PASS | Root lane: `27 tests, 0 failures, 1 skipped`; admin lane: `5 tests, 0 failures`; docs build and grep proof passed after a narrow ExDoc hidden-xref wording fix in inbound moduledocs. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `LOCK-01` | `35-01`, `35-03` | Adopter can identify the exact stable `mailglass` core contract for `v1.x`. | ✓ SATISFIED | Canonical core inventory exists, is linked from adopter entrypoints, and stays verified by docs and compiled-doc tests. |
| `LOCK-02` | `35-02`, `35-03` | Adopter can identify the exact stable `mailglass_admin` router/auth/operator seams and what remains internal. | ✓ SATISFIED | Canonical admin inventory exists, is surfaced in admin docs, and keeps LiveView/UI internals out of contract scope. |
| `LOCK-03` | `35-01`, `35-02`, `35-03` | Maintainer can classify exported non-contract surfaces as internal or sibling-package-only. | ✓ SATISFIED | Stability docs and docs-contract tests keep the surface classification explicit and stable. |
| `LOCK-04` | `35-03` | Stable public APIs carry complete `@since` and deprecation metadata in generated docs. | ✓ SATISFIED | Compiled-doc truth tests and both docs builds passed on 2026-05-06. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `35-VALIDATION.md` | 5 | `wave_0_complete: false` remains in the validation artifact | ⚠️ Warning | The phase contract is verified now, but the Nyquist trail remains partial until that validation status is revisited. |

### Gaps Summary

No Phase 35 goal-blocking gaps remain.

Residual debt is limited to Nyquist bookkeeping: [35-VALIDATION.md](/Users/jon/projects/mailglass/.planning/phases/35-stability-contract-audit/35-VALIDATION.md:5) still reports `wave_0_complete: false`, so milestone-level Nyquist status remains partial even though the contract proofs are now present and passing.

---

_Verified: 2026-05-06T08:45:00Z_
_Verifier: Codex_
