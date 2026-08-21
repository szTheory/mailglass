# Phase 159 Plan 04: Measured coverage floors

## Delivered

- Established canonical coverage cohorts: core `test/mailglass` and inbound `test/mailglass_inbound`.
- Recorded pinned-toolchain measurements in immutable baseline metadata:
  - core: 5,357 / 8,469 lines (63.254221%)
  - inbound: 1,891 / 2,410 lines (78.464730%)
- Added a fail-closed checker for missing reports/baselines, wrong Elixir/OTP, lower covered or relevant line counts, and lower percentage.
- Kept `test/scripts`, reference-host, and release-recovery checks in `config/critical_path_manifest.json`, outside percentage accounting.
- Wired the existing core and inbound CI lanes to collect and enforce their respective reports.

## Measurement environment

- Image: `hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250520-slim`
- Toolchain: Elixir 1.18.4 / OTP 27
- Commands and SHA-256 report identities are recorded in each baseline JSON.

## Verification

- `mix test test/scripts/coverage_floor_contract_test.exs --warnings-as-errors`
- `actionlint .github/workflows/ci.yml`
- `git diff --check`

## Commit

- `047009e7 test(159-04): enforce measured package coverage floors`
