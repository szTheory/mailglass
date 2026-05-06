---
phase: 39-inbound-package-foundation
plan: "03"
subsystem: package
tags: [elixir, inbound, docs, package, optional-deps]
requires:
  - phase: 39-inbound-package-foundation
    provides: stable public inbound contract and storage foundation from Plans 39-01 and 39-02
provides:
  - sibling package linked-version scaffold for mailglass_inbound
  - package-local optional Oban gateway without mandatory runtime coupling
  - narrow README and API stability inventory guarded by docs-contract tests
affects: [Phase 40, Phase 41, mailglass_inbound]
tech-stack:
  added: []
  patterns:
    - linked-version sibling package dependency posture
    - package-local optional dependency gateway
    - inventory-shaped docs contract with deferred-scope regression coverage
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/optional_deps.ex
    - mailglass_inbound/README.md
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/lib/mailglass_inbound.ex
    - mailglass_inbound/test/test_helper.exs
    - mailglass_inbound/mix.lock
decisions:
  - "Keep Oban package-local and optional through MailglassInbound.OptionalDeps.Oban instead of sharing core optional-dep wrappers across package boundaries."
  - "Treat the docs lane as a contract proof: stable, internal, and deferred scope are explicit and regression-tested."
  - "Use a package-local test alias in mix.exs to force `config :swoosh, :api_client, false` before applications start."
metrics:
  duration: 51min
  completed: 2026-05-06
---

# Phase 39 Plan 03: Inbound Package Foundation Summary

**Sibling package scaffold, optional Oban seam, and narrow docs-contract proof for `mailglass_inbound`**

## Performance

- **Duration:** 51 min
- **Tasks:** 2
- **Files modified:** 8 in planned scope, plus `mailglass_inbound/mix.lock` as a verification scope exception

## Accomplishments

- Brought `mailglass_inbound` into the sibling-package linked-version posture used elsewhere in the repo, with a local path dependency during development and an exact `MIX_PUBLISH=true` pin for publish mode.
- Added `MailglassInbound.OptionalDeps.Oban` as the package-local seam for future execution work so later plans can branch on Oban availability without turning Oban into a required package dependency.
- Published a narrow `mailglass_inbound/README.md` and `mailglass_inbound/docs/api_stability.md` that name only the shipped Phase 39 contract: `MailglassInbound.InboundMessage`, `MailglassInbound.Router`, `MailglassInbound.Mailbox`, and the canonical-vs-raw-evidence storage split.
- Added `docs_contract_test.exs` as an automated regression check that fails if package docs overstate ingress, execution, UI, matcher, or mailbox lifecycle scope.

## Task Commits

1. **Task 1: Scaffold the sibling package and preserve package-local optional dependency seams** - `768b53b` (`feat`)
2. **Task 2 RED: Add failing docs-contract coverage and package-local test boot wiring** - `1d914b3` (`test`)
3. **Task 2 GREEN: Publish narrow foundation docs and lock the verification lane** - `9331e96` (`feat`)

## Decisions Made

- The inbound package owns its own optional dependency namespace instead of reaching into `Mailglass.OptionalDeps.*`, preserving a clean sibling-package boundary.
- The package test lane now configures Swoosh through a `mix test` alias in `mailglass_inbound/mix.exs` so docs-contract verification does not depend on `hackney` or any other API client package.
- The package docs stay inventory-shaped: stable, internal, and deferred scope are explicit rather than implied by module reachability.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Swoosh boot blocked the docs-contract verification lane**
- **Found during:** Task 2 RED
- **Issue:** `mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` started `Swoosh.Application`, which defaulted to Hackney and failed before the docs test could run.
- **Fix:** Added a package-local `test` alias in `mailglass_inbound/mix.exs` that sets `config :swoosh, :api_client, false` before the underlying Mix test task starts applications. Kept the helper-side env set in `test/test_helper.exs` as a harmless reinforcement.
- **Files modified:** `mailglass_inbound/mix.exs`, `mailglass_inbound/test/test_helper.exs`
- **Verification:** `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
- **Committed in:** `1d914b3`

**2. [Rule 3 - Blocking] Optional dependency lockfile had to match the new package scaffold**
- **Found during:** Task 2 GREEN verification
- **Issue:** After adding the package-local optional Oban declaration in `mailglass_inbound/mix.exs`, Mix refused the test lane when `mailglass_inbound/mix.lock` did not contain the resolved dependency graph.
- **Fix:** Regenerated and committed `mailglass_inbound/mix.lock` as a necessary package-local scope exception so compile and test verification use a consistent lockfile.
- **Files modified:** `mailglass_inbound/mix.lock`
- **Verification:** full plan verification commands below
- **Committed in:** `9331e96`

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact:** Both fixes were required to make the scoped verification lane honest and repeatable without changing the promised Phase 39 runtime contract.

## Scope Exceptions

- `mailglass_inbound/mix.lock` was modified and committed even though it was outside the original write list. This was necessary because the planned `mix.exs` change added an optional dependency declaration, and Mix would not run the package verification commands against a stale lockfile.

## Issues Encountered

- The generic workflow’s state and roadmap update steps were intentionally skipped because the approved write scope for this execution did not include `.planning/STATE.md`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md`.
- Generated verification artifacts under `mailglass_inbound/_build/` and `mailglass_inbound/deps/` were removed after verification and were not committed.

## Verification

- `cd mailglass_inbound && mix compile --warnings-as-errors`
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors`
- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/39-inbound-package-foundation/39-03-SUMMARY.md`.
- Task commits verified in git history: `768b53b`, `1d914b3`, `9331e96`.
- Verification rerun successfully with the exact plan commands listed above.

---
*Phase: 39-inbound-package-foundation*
*Completed: 2026-05-06*
