---
phase: 138-schema-prefix-no-search-path-hardening
plan: 04
subsystem: testing
tags: [ecto, postgres, schema-prefix, credo, ci, advisory-matrix]

requires:
  - phase: 138-01
    provides: Hostile no-search-path runtime proofs for core replay and unsubscribe paths
  - phase: 138-02
    provides: Inbound raw-repo schema prefix contract proof
  - phase: 138-03
    provides: RawRepoPrefixContract static guard and strict Credo registration
provides:
  - Focused `mix verify.schema_prefix` lane for Phase 138 schema-prefix proof
  - Advisory matrix comments distinguishing broad canary coverage from fail-closed proof
  - Source-verifiable GATE-01 and GATE-02 closure
affects: [138-schema-prefix-no-search-path-hardening, 139-admin-asset-first-load-deep-link-proof, 140-verification-docs-reconciliation-and-closeout, schema-prefix, ci]

tech-stack:
  added: []
  patterns:
    - Focused verification aliases run hostile runtime tests, static guard tests, strict Credo, and sibling-package contract tests without full-suite expansion.
    - Dual-schema advisory matrix comments explicitly document canary semantics when the harness also sets search_path.

key-files:
  created:
    - .planning/phases/138-schema-prefix-no-search-path-hardening/138-04-SUMMARY.md
  modified:
    - mix.exs
    - .github/workflows/advisory-matrix.yml

key-decisions:
  - "Expose Phase 138 proof as `mix verify.schema_prefix`, a focused lane rather than a full dual-schema matrix or full-suite alias."
  - "Document the dual-schema advisory matrix as broad canary coverage because its harness aligns Config.schema/0 and connection search_path."
  - "Use `cmd mix test` for the second root ExUnit file in the alias so Mix task deduplication cannot skip the RawRepoPrefixContract test."

patterns-established:
  - "`verify.schema_prefix` runs hostile core schema-prefix tests, RawRepoPrefixContract tests, strict Credo, and the inbound schema prefix contract in that order."
  - "Workflow comments can carry CI semantics without changing triggers, matrix values, job names, package versions, or run commands."

requirements-completed: [GATE-01, GATE-02]

duration: 3 min
completed: 2026-07-07
status: complete
---

# Phase 138 Plan 04: Focused Verification Alias and Advisory Canary Summary

**`mix verify.schema_prefix` now runs the fail-closed schema-prefix proof, while the dual-schema advisory matrix is documented as broad canary coverage.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-07T14:07:25Z
- **Completed:** 2026-07-07T14:10:11Z
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments

- Added `verify.schema_prefix` to `mix.exs` preferred test envs.
- Added a focused alias that runs the hostile no-search-path runtime proof, `RawRepoPrefixContract` test, strict Credo, and inbound schema prefix contract test.
- Updated only comments in `.github/workflows/advisory-matrix.yml` so the core and inbound dual-schema jobs are clearly broad canaries, not the fail-closed proof.
- Preserved workflow triggers, matrix values, job names, package versions, and run commands.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add focused verify.schema_prefix alias** - `bf76db91` (`feat`)
2. **Task 2: Mark dual-schema advisory matrix as canary coverage** - `4bb553e5` (`docs`)

## Files Created/Modified

- `mix.exs` - Adds `verify.schema_prefix` preferred env and focused alias.
- `.github/workflows/advisory-matrix.yml` - Adds comment-only GATE-02 wording around core and inbound dual-schema advisory jobs.
- `.planning/phases/138-schema-prefix-no-search-path-hardening/138-04-SUMMARY.md` - Records plan completion evidence.

## Decisions Made

- Keep `mix verify.schema_prefix` focused on the hostile runtime proofs, static raw-repo guard, strict Credo, and inbound contract test rather than adding full-suite or advisory-matrix coverage.
- Name the advisory matrix a broad canary because the matrix harness aligns `Config.schema/0` and sets the connection `search_path`.
- Use a `cmd mix test ...` subprocess for the second root ExUnit proof file so Mix task deduplication cannot skip `test/mailglass/credo/raw_repo_prefix_contract_test.exs`.

## Verification

- `mix verify.schema_prefix` - passed after Task 1 and again after Task 2; final run executed 4 hostile runtime tests, 8 RawRepoPrefixContract tests, strict Credo with no issues, and 3 inbound contract tests.
- `mix run -e 'aliases = Mix.Project.config()[:aliases]; unless Keyword.has_key?(aliases, :"verify.schema_prefix"), do: raise("missing verify.schema_prefix alias")'` - passed.
- `rg -n "verify\\.schema_prefix|focused no-search-path|broad canary|search_path" .github/workflows/advisory-matrix.yml mix.exs` - passed and found the alias plus core/inbound canary comments.
- `diff -u <(git show HEAD:.github/workflows/advisory-matrix.yml | sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d') <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' .github/workflows/advisory-matrix.yml)` - passed with no output before the Task 2 commit, proving non-comment workflow lines were unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Forced the second root test through a Mix subprocess**
- **Found during:** Task 1 (Add focused verify.schema_prefix alias)
- **Issue:** The initial alias used two root `test ...` entries. `mix verify.schema_prefix` exited 0 but skipped `test/mailglass/credo/raw_repo_prefix_contract_test.exs` because Mix deduplicated the already-run root `test` task.
- **Fix:** Changed the second root proof to `cmd mix test test/mailglass/credo/raw_repo_prefix_contract_test.exs --warnings-as-errors`, preserving order while forcing a fresh Mix invocation.
- **Files modified:** `mix.exs`
- **Verification:** Final `mix verify.schema_prefix` output included the 8-test RawRepoPrefixContract suite and exited 0.
- **Committed in:** `bf76db91`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The fix made GATE-01 honest without widening the alias beyond the planned focused lane.

## Issues Encountered

- Existing non-blocking OTLP exporter warnings still print in test runs.
- Existing custom Credo module redefinition warnings still print while Credo loads `credo_checks/*.ex`; strict Credo exits 0.

## Known Stubs

None - no placeholder UI/data stubs were introduced.

## Threat Flags

None - this plan added no network endpoints, auth paths, file access patterns, schema changes, or new trust-boundary code.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 138 is complete and ready for Phase 139. The focused schema-prefix proof is executable from one command, and the broad advisory matrix is clearly documented as canary coverage.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/138-schema-prefix-no-search-path-hardening/138-04-SUMMARY.md`.
- Key files exist: `mix.exs`, `.github/workflows/advisory-matrix.yml`.
- Task commits exist: `bf76db91`, `4bb553e5`.
- Final plan verification passed: `mix verify.schema_prefix` and the required source assertion.

---
*Phase: 138-schema-prefix-no-search-path-hardening*
*Completed: 2026-07-07*
