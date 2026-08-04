---
phase: 153
plan: 06
subsystem: adopter-documentation
tags: [docs, generated-host, production, oban, privacy]
requires:
  - phase: 153-05
    provides: production preflight and authenticated operator readiness
provides:
  - executable 2.x fresh-adopter documentation contracts
  - production, compatibility, and package-boundary release guidance
affects: [153-07, release-gate]
tech-stack:
  added: []
  patterns: [marked executable documentation blocks, package-shaped docs proof]
key-files:
  created: []
  modified:
    - README.md
    - guides/getting-started.md
    - guides/authoring-mailables.md
    - guides/rate-limiting.md
    - guides/production-go-live-checklist.md
    - guides/multi-tenancy.md
    - guides/compatibility-and-deprecations.md
    - mailglass_admin/README.md
    - test/mailglass/docs_contract_test.exs
    - scripts/generated_host_proof.sh
    - dev/mailglass/generated_host/journey.ex
key-decisions:
  - "Adopter snippets are explicitly marked executable or syntax-only and parsed as a public documentation contract."
  - "The generated-host proof has a docs stage so package-shaped documentation verification cannot rely on repository context."
  - "Core and admin remain linked siblings while inbound is independent and optional."
requirements-completed: [ADOPT-06]
metrics:
  tasks_completed: 2
  files_changed: 11
  completed: 2026-08-03
status: complete
---

# Phase 153 Plan 06: Executable Adopter and Release Documentation Summary

Mailglass 2.x adoption and production docs now state the single-recipient,
unstamped-default-tenant, normal-Oban, payload-first lifecycle and prove the
primary documentation path in a disposable package-shaped Phoenix host.

## Tasks Completed

1. Added TDD documentation contracts and rewrote the primary fresh-host path in
   README, Getting Started, authoring, and rate-limit guidance.
2. Documented production preflight, signed feedback and one-click scope,
   suppression, maintenance, 2.x compatibility, authenticated operator routing,
   and linked-package boundaries.

## Verification

- `mix test test/mailglass/docs_contract_test.exs --seed 0` — passed: 41 tests,
  0 failures, 1 existing skipped test.
- `mix mailglass.docs.check` — passed.
- `DEP_MODE=local bash scripts/generated_host_proof.sh --stage docs` — passed:
  generated a fresh Phoenix host, built local package artifacts, resolved them
  into the host, migrated the disposable database, and booted the docs stage.

## Task Commits

1. Task 1 RED — `f30bbed4` `test(153-06): define adopter documentation contracts`
2. Task 1 GREEN — `5b0328a0` `docs(153-06): make adoption path executable`
3. Task 2 RED — `9900a2f4` `test(153-06): define production documentation contracts`
4. Task 2 GREEN — `37a90f88` `docs(153-06): align production and compatibility guides`

## Decisions Made

- Marked Elixir blocks distinguish executable examples from syntax-only API
  shapes; the contract test parses both and bans private test seams from marked
  examples.
- `mix mailglass.preflight` is the final go-live gate; the checklist makes the
  bounded failure classes and host-owned operator authentication explicit.
- `mailglass_admin` is installed for production operator use and consumes public
  core APIs; `mailglass_inbound` remains an independent optional package.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking issue] Added the generated-host `docs` proof stage.
- **Found during:** Task 1 verification.
- **Issue:** The planned verification command requested `--stage docs`, but the
  runner rejected that stage.
- **Fix:** Added the closed `docs` stage to the runner and mapped it to the
  package-shaped host boot proof.
- **Files modified:** `scripts/generated_host_proof.sh`,
  `dev/mailglass/generated_host/journey.ex`.
- **Commit:** `5b0328a0`.

2. [Rule 1 - Bug] Corrected marked authoring example structure.
- **Found during:** Task 1 documentation contract run.
- **Issue:** A prose explanation was inserted inside a marked Elixir block,
  making the syntax-only contract invalid.
- **Fix:** Moved the prose outside the code fence and reran the parser contract.
- **Files modified:** `guides/authoring-mailables.md`.
- **Commit:** `5b0328a0`.

## Known Stubs

None.

## Self-Check: PASSED

- All eleven documented files exist.
- Task commits `f30bbed4`, `5b0328a0`, `9900a2f4`, and `37a90f88` exist in git history.
