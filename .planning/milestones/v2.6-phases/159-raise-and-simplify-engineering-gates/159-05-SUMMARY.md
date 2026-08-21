---
phase: 159-raise-and-simplify-engineering-gates
plan: 05
status: complete
completed: 2026-08-18
requirements: [QUAL-07, QUAL-08]
---

# Plan 159-05 Summary

Inbound now has a package-local, required Dialyzer gate with an empty strict
ignore file. The first audit found 72 warnings across 21 shipped files; contract,
callback, reachability, migration, provider, MIME, Mix-task, and operator-record
types were corrected until the pinned Elixir 1.18.4 / OTP 27 run reported zero
errors, skipped warnings, and unnecessary skips.

Credo's nesting and cyclomatic checks are enabled. Existing measured complexity
is governed by a function/check/score/count ledger with ownership and expiry.
The independent strict-threshold run fails on new, increased, expired, duplicate,
or dead records. Existing root Dialyzer filters are likewise bidirectionally
registered and expiring; inbound cannot borrow the root ignore file or PLT.

## Commits

- `ead4aac0` — align inbound pipeline outcome contract
- `3dd7be50` — admit supported verification-facts callback
- `971d2201`, `05b412a5` — narrow the optional MIME analysis boundary
- `aa4348e6` — tighten inbound domain and migration types
- `d0f69ccf` — resolve provider, MIME, and optional dependency types
- `dcab1253` — add the static-analysis ledgers, CI jobs, and final root fixes

## Verification

- pinned inbound `mix dialyzer`: 0 errors, 0 skipped, 0 unnecessary skips
- pinned root `mix dialyzer`: passed, 16 matched skips, 0 unnecessary skips
- `mix credo --strict`: no issues
- `mix run scripts/check_static_analysis_exceptions.exs`: passed
- focused static-analysis and runtime tests: 42 tests, 0 failures
- focused inbound remediation suites: 156 tests, 0 failures
- `actionlint .github/workflows/ci.yml`: passed

No admin/operator UI files or behavior were changed.
