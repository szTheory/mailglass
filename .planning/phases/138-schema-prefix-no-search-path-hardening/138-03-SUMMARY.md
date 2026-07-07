---
phase: 138-schema-prefix-no-search-path-hardening
plan: 03
subsystem: database
tags: [ecto, postgres, schema-prefix, raw-repo, credo, tdd]

requires:
  - phase: 138-01
    provides: Core hostile runtime schema-prefix proofs and explicit raw callback prefix pattern
  - phase: 138-02
    provides: Inbound raw-repo schema_opts contract and tests
provides:
  - Explicit prefix opts for fake adapter and webhook reconciler projection Multi updates
  - Registered RawRepoPrefixContract Credo guard for production raw repo and projection Multi recurrence
  - Regression coverage for bad and allowed raw repo prefix call shapes
affects: [138-schema-prefix-no-search-path-hardening, schema-prefix, credo, raw-repo]

tech-stack:
  added: []
  patterns:
    - Projection Multi updates touching mailglass tables pass Repo.multi_opts() at the operation step.
    - Raw callback repo calls use explicit prefix opts through Repo.multi_opts(), schema_opts(), prefix:, or configured local opts helpers.
    - Custom Credo guards stay production-path scoped to avoid test, migration, and fixture noise.

key-files:
  created:
    - credo_checks/raw_repo_prefix_contract.ex
    - test/mailglass/credo/raw_repo_prefix_contract_test.exs
  modified:
    - lib/mailglass/adapters/fake.ex
    - lib/mailglass/webhook/reconciler.ex
    - test/mailglass/adapters/fake_test.exs
    - test/mailglass/webhook/reconciler_test.exs
    - .credo.exs

key-decisions:
  - "Treat projection Multi writes in the fake adapter and webhook reconciler as schema-prefix-sensitive operations requiring per-operation prefix opts."
  - "Scope RawRepoPrefixContract to production core/inbound paths and allow only explicit prefix contracts: Repo.multi_opts(), schema_opts(), prefix:, or configured local prefix opts helpers."

patterns-established:
  - "Source-contract tests can guard narrow TDD prefix requirements when runtime behavior may be masked by existing Ecto prefix metadata."
  - "RawRepoPrefixContract flags lowercase raw repo handles and projection Multi updates, while facade calls through Mailglass.Repo/MailglassInbound.Repo remain compliant."

requirements-completed: [SCHEMA-03]

duration: 10 min
completed: 2026-07-07
status: complete
---

# Phase 138 Plan 03: Raw Repo Prefix Guard Summary

**Fake adapter and webhook reconciler projection writes now pass explicit schema prefix opts, with a registered Credo guard blocking raw repo recurrence.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-07T13:50:33Z
- **Completed:** 2026-07-07T14:01:27Z
- **Tasks:** 2 completed
- **Files modified:** 7

## Accomplishments

- Added explicit `Mailglass.Repo.multi_opts()` to the fake adapter projection `Ecto.Multi.update/4`.
- Added explicit `Repo.multi_opts()` to both compiled webhook reconciler projection `Multi.update/4` branches.
- Added and registered `Mailglass.Credo.RawRepoPrefixContract` for production raw repo and projection Multi prefix enforcement.
- Added regression tests covering unprefixed raw update/read violations, projection Multi violations, and allowed `Repo.multi_opts()`, `schema_opts()`, facade, and out-of-scope file shapes.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Projection prefix contract tests** - `1dd78a76` (`test`)
2. **Task 1 GREEN: Prefix projection Multi updates** - `0e38af52` (`feat`)
3. **Task 2 RED: RawRepoPrefixContract regression tests** - `9416b221` (`test`)
4. **Task 2 GREEN: Raw repo prefix Credo guard** - `8e8ae96f` (`feat`)

## Files Created/Modified

- `lib/mailglass/adapters/fake.ex` - Fake adapter projection update now passes `Mailglass.Repo.multi_opts()`.
- `lib/mailglass/webhook/reconciler.ex` - Both Oban-present and fallback reconciler projection updates pass `Repo.multi_opts()`.
- `credo_checks/raw_repo_prefix_contract.ex` - New production-path scoped static guard for lowercase raw repo handles and projection Multi updates.
- `test/mailglass/credo/raw_repo_prefix_contract_test.exs` - Guard regression suite for bad and compliant call shapes.
- `test/mailglass/adapters/fake_test.exs` - Source-contract assertion for fake adapter projection prefix opts.
- `test/mailglass/webhook/reconciler_test.exs` - Source-contract assertion for both reconciler projection prefix opts.
- `.credo.exs` - Registers `Mailglass.Credo.RawRepoPrefixContract` with core and inbound schema modules.

## Decisions Made

- Keep append-only reconciliation semantics unchanged: append the reconciled event, update only the delivery projection, and broadcast only after transaction completion.
- Enforce the recurrence guard through Credo rather than a shell grep, following the repo's existing custom-check pattern.
- Keep guard diagnostics structural and non-payload-bearing; messages name only the call shape and source location.

## Verification

- `mix test test/mailglass/adapters/fake_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors` - 25 tests, 0 failures.
- `mix test test/mailglass/credo/raw_repo_prefix_contract_test.exs --warnings-as-errors` - 8 tests, 0 failures.
- `mix test test/mailglass/credo/checks_have_tests_test.exs --warnings-as-errors` - 2 tests, 0 failures.
- `mix credo --strict` - exits 0; no issues found. Existing custom-check module redefinition warnings still print while Credo loads `credo_checks/*.ex`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Test Functionality] Added Task 1 source-contract tests**
- **Found during:** Task 1 RED
- **Issue:** Task 1 was marked `tdd="true"` but named only source files. Without a failing contract test, the prefix change could be made without a RED gate.
- **Fix:** Added focused source-contract assertions to the existing fake adapter and reconciler tests before changing source.
- **Files modified:** `test/mailglass/adapters/fake_test.exs`, `test/mailglass/webhook/reconciler_test.exs`
- **Verification:** RED run failed on the missing prefix opts; final focused tests passed.
- **Committed in:** `1dd78a76`, `0e38af52`

**2. [Rule 1 - Bug] Allowed compliant local prefix opts helper variables**
- **Found during:** Task 2 strict Credo verification
- **Issue:** The initial guard flagged `Events.append_multi/3` even though it uses a local `insert_opts/1` helper that returns `prefix: Mailglass.Config.schema()`.
- **Fix:** Added a `prefix_helper_functions` contract and recognized variables assigned from configured prefix helper calls when used as final opts.
- **Files modified:** `credo_checks/raw_repo_prefix_contract.ex`
- **Verification:** `mix credo --strict` then exited 0 with no issues.
- **Committed in:** `8e8ae96f`

---

**Total deviations:** 2 auto-fixed (1 missing critical test functionality, 1 guard false-positive bug)
**Impact on plan:** Both fixes stayed inside SCHEMA-03 and made the guard more fail-closed without widening product behavior.

## Issues Encountered

- The test commands still print the existing non-blocking OTLP exporter warning.
- `mix credo --strict` prints existing module-redefinition warnings while loading custom checks from `credo_checks/*.ex`; the command exits 0.

## Known Stubs

None - no placeholder UI/data stubs were introduced.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commits present: `1dd78a76`, `9416b221`
- GREEN commits present after RED: `0e38af52`, `8e8ae96f`
- REFACTOR commits: none needed

## Next Phase Readiness

Ready for `138-04-PLAN.md`. SCHEMA-03 is satisfied, leaving the focused `mix verify.schema_prefix` alias and advisory-canary documentation for the next plan.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/138-schema-prefix-no-search-path-hardening/138-03-SUMMARY.md`.
- Key files exist: `lib/mailglass/adapters/fake.ex`, `lib/mailglass/webhook/reconciler.ex`, `credo_checks/raw_repo_prefix_contract.ex`, `test/mailglass/credo/raw_repo_prefix_contract_test.exs`, `.credo.exs`.
- Task commits exist: `1dd78a76`, `0e38af52`, `9416b221`, `8e8ae96f`.
- Final plan verification passed: affected fake/reconciler tests, RawRepoPrefixContract tests, checks-have-tests meta-test, and `mix credo --strict`.

---
*Phase: 138-schema-prefix-no-search-path-hardening*
*Completed: 2026-07-07*
