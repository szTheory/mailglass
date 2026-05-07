---
phase: "34"
plan: "03"
subsystem: "infra"
tags: ["ci", "github-actions", "support-contract", "docs-contract", "verification"]
requires: ["MAT-03"]
provides:
  - "repo-root-support-contract-script"
  - "three-bucket-required-ci-contract"
  - "required-vs-advisory-docs-contract"
affects:
  - "scripts/verify_support_contract.sh"
  - ".github/workflows/ci.yml"
  - ".github/workflows/advisory-matrix.yml"
  - "MAINTAINING.md"
  - "test/mailglass/docs_contract_test.exs"
tech_stack:
  added: []
  patterns:
    - "thin repo-root orchestrator over package-local verification"
    - "separate required and advisory GitHub checks"
    - "docs contract assertions for verification posture"
key_files:
  created:
    - "scripts/verify_support_contract.sh"
  modified:
    - ".github/workflows/ci.yml"
    - ".github/workflows/advisory-matrix.yml"
    - "MAINTAINING.md"
    - "test/mailglass/docs_contract_test.exs"
    - "lib/mailglass/webhook.ex"
decisions:
  - "Keep the repo-root entrypoint thin and delegate to package-local authorities."
  - "Rename CI truth to the three explicit required buckets: Support Contract Core, Support Contract Admin, and Compile No Optional Deps."
  - "Repurpose advisory-matrix into broad full-suite plus deterministic provider compatibility signal."
metrics:
  completed_at: "2026-05-05T19:46:54Z"
  duration: "during Phase 34 execution"
  tasks_completed: 2
  files_touched: 6
requirements-completed: [MAT-03]
---

# Phase 34 Plan 03: Verification Contract Wiring Summary

The repo now exposes one honest support-contract script, three explicit required CI buckets, and docs/tests that lock the required-versus-advisory verification story.

## Tasks Completed

### Task 1

- Created `scripts/verify_support_contract.sh` as the thin repo-root entrypoint for `mix verify.support_contract.core`, `cd mailglass_admin && mix verify.support_contract.admin`, and `mix compile --no-optional-deps --warnings-as-errors`.
- Reworked `.github/workflows/ci.yml` so the required contract is expressed as `Support Contract Core`, `Support Contract Admin`, and `Compile No Optional Deps`.
- Reworked `.github/workflows/advisory-matrix.yml` into `Core Full Suite Advisory` and `Provider Compatibility Advisory`.

### Task 2

- Updated `MAINTAINING.md` to describe the new required-versus-advisory posture in maintainer-facing language.
- Extended `test/mailglass/docs_contract_test.exs` to assert the exact support-contract and advisory names.

## Verification

- `bash scripts/verify_support_contract.sh`
- `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors`
- `actionlint .github/workflows/ci.yml .github/workflows/advisory-matrix.yml`
- `rg -n "Support Contract Core|Support Contract Admin|Compile No Optional Deps|Core Full Suite Advisory|Provider Compatibility Advisory|Provider Live Advisory|verify_support_contract\\.sh" .github/workflows/ci.yml .github/workflows/advisory-matrix.yml MAINTAINING.md test/mailglass/docs_contract_test.exs scripts/verify_support_contract.sh`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Required-gate integrity] Fixed an existing Boundary export violation exposed by the new compile bucket**
- **Found during:** Wave 2 verification
- **Issue:** `mix compile --no-optional-deps --warnings-as-errors` failed because `Mailglass.Operator.SupportSummary` referenced `Mailglass.Webhook.WebhookEvent` without that module being exported by the `Mailglass.Webhook` boundary.
- **Fix:** Exported `WebhookEvent` from `lib/mailglass/webhook.ex` so the required compile bucket reflects the intended module contract.
- **Files modified:** `lib/mailglass/webhook.ex`

## Issues Encountered

- The maintainer docs assertion initially failed because `not a merge blocker` wrapped across a line break; the prose was tightened to keep the phrase contiguous and testable.

## User Setup Required

- GitHub branch protection should require `Compile No Optional Deps (Elixir 1.18 / OTP 27)`, `Support Contract Core (Elixir 1.18 / OTP 27)`, and `Support Contract Admin (Elixir 1.18 / OTP 27)`.
- Remove any required status checks still pointing at `Tests (Elixir 1.18 / OTP 27)` or `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` if they are currently marked required.

## Self-Check: PASSED

- Verified the repo-root script exits successfully.
- Verified the workflow YAML passes `actionlint`.
- Verified the docs contract test locks the required-versus-advisory wording.
