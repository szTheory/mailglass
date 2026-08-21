---
phase: 159-raise-and-simplify-engineering-gates
plan: 06
status: complete
completed: 2026-08-18
requirements: [QUAL-03, QUAL-04, QUAL-05, QUAL-10]
---

# Plan 159-06 Summary

CI Green now aggregates every repaired deterministic proof through one
promotion-ready, bidirectional policy manifest. The manifest owns each required
job ID, public display name, behavior, and local-parity marker (or an explicit
CI-only reason); active and target inventories must remain exactly equal.

A stable `core_deterministic_suite` job runs the root suite with locked
dependencies on the supported Elixir 1.18 / OTP 27 floor. Root `mix ci` now also
reproduces the required inbound Dialyzer command. The unchanged public `CI Green`
check consumes all 19 required results and fails closed on missing, skipped,
failed, cancelled, unknown, renamed, or `continue-on-error` evidence.

Browser, demo, preview, provider-live, next-toolchain, clean-baseline,
branch-protection advisory, and publish-only identities remain visible and
explicitly excluded from merge inputs. Existing release-gating classification
remains an independent axis, so this promotion does not mutate release policy or
branch protection.

## Commits

- `551c8cc3` — promote deterministic proof lanes into CI Green

## Verification

- focused CI policy, required-check, local-parity, and lane-classification suite:
  79 tests, 0 failures
- `mix format --check-formatted` on every edited Elixir file: passed
- `actionlint .github/workflows/ci.yml`: passed
- `git diff --check`: passed

No admin/operator UI files or behavior were changed, and the public protected
check names remain `CI Green` and `Guard Release Trigger`.
