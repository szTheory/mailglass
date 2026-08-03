---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "09"
subsystem: outbound-runtime-proof
tags: [elixir, mix, optional-dependencies, oban, postgres, ci]
requires:
  - phase: 150-05
    provides: fail-closed selected-Oban public send contract
provides:
  - Direct isolated Elixir runtime proof with source-derived optional-app denylist
  - Public `deliver_later/2` typed dependency-unavailable and zero-effects probe
  - Required Postgres-backed CI execution of the no-optional-dependencies runtime proof
affects: [phase-151-dispatch, phase-153-generated-host-proof, ci]
tech-stack:
  added: []
  patterns: [allowlisted-ebin-runtime, source-derived-optional-denylist, zero-effect-public-api-probe]
key-files:
  created: [scripts/no_optional_deps_runtime_smoke.sh, test/runtime/no_optional_deps_public_send.exs]
  modified: [mix.exs, .github/workflows/ci.yml]
key-decisions:
  - "The proof process uses direct `elixir` from an empty directory, never Mix, and accepts only isolated artifact ebins."
  - "Optional applications are derived from the source-controlled dependency declaration so the denylist cannot silently drift."
requirements-completed: [ENVL-06]
metrics:
  duration: 20min
  completed: 2026-08-02
status: complete
---

# Phase 150 Plan 09: Oban-Free Public Runtime Proof Summary

**A direct production-graph Elixir runtime now proves selected-Oban `deliver_later/2` fails closed with a typed result and no durable, queue, provider, or Task fallback effects.**

## Accomplishments

- Added an executable harness that compiles Mailglass in `MIX_ENV=prod` into a temporary build path with `--no-optional-deps`, derives optional applications from `Mailglass.MixProject.project()[:deps]`, rejects optional build roots, and creates an allowlisted ebin manifest.
- Reuses only non-optional production dependency artifacts inside the temporary root, excluding maintainer/test tooling and preserving dependency compile-time assets without exposing normal build paths to the proof process.
- Launches the probe from an empty temporary directory through `elixir`, with Mix and Erlang path-injection variables unset.
- Audits code paths, optional application roots, and `Oban`/conditional Worker availability before configuration or Mailglass startup; the probe owns a local Ecto Repo configured from the test database credentials, then checks the exact public error and schema-qualified durable/Oban/Fake/Task observations before and after.
- Registered `mix verify.no_optional_runtime` and made it a required step in the existing Postgres-backed `support_contract_core` CI job.

## Task Commits

1. **Task 150-09-01 RED: add the no-optional runtime failure probe** — `9354794d` (`test`)
2. **Task 150-09-01 GREEN: execute the public proof and require it in CI** — `c1620847` (`feat`)
3. **Task 150-09-01 follow-up: run the proof from the production graph** — `2fab4008` (`fix`)

## Verification

- PASS — `bash -n scripts/no_optional_deps_runtime_smoke.sh`
- PASS — `mix format --check-formatted mix.exs test/runtime/no_optional_deps_public_send.exs`
- PASS — `elixir -e 'Code.string_to_quoted!(File.read!("test/runtime/no_optional_deps_public_send.exs"))'`
- PASS — `MIX_ENV=test mix help verify.no_optional_runtime` (alias registered)
- PASS — focused source-contract scan confirmed isolated `MIX_BUILD_PATH`, direct `elixir` launcher, cleared path-injection variables, source-derived denylist, absence checks, exact `dependency_unavailable` match, durable/queue/Fake/Task measurements, and CI step.
- PASS — `MIX_ENV=test mix verify.no_optional_runtime` compiled the production graph, launched the direct isolated runtime, and printed `no-optional-deps public send runtime proof passed`.
- PASS — `MIX_ENV=test mix verify.support_contract.core` completed 202 tests with 0 failures and 1 pre-existing skip.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Accept two- and three-element Mix dependency tuples when deriving the denylist**
- **Found during:** Task 150-09-01
- **Issue:** The controller assumed all `deps` entries used the three-element `{app, requirement, opts}` shape; required dependencies use two-element tuples.
- **Fix:** Filtered both valid Mix dependency tuple forms while deriving only `optional: true` application names.
- **Files modified:** `scripts/no_optional_deps_runtime_smoke.sh`
- **Verification:** Controller invocation succeeds and reaches isolated compilation.
- **Commit:** `c1620847`

**Total deviations:** 1 auto-fixed (Rule 1).

**2. [Rule 3 - Blocking harness issue] Compile the shipped production graph with a probe-local Repo**
- **Found during:** Task 150-09-01 verification
- **Issue:** The test artifact compiled maintainer-only `mix_audit -> yaml_elixir -> yamerl`; once that was removed, test-only `Mailglass.TestRepo` was no longer available to the direct process.
- **Fix:** Compile Mailglass under `MIX_ENV=prod`, copy only non-optional production dependency artifacts into the temporary root, and define/configure a probe-local Ecto Repo from the existing test database configuration.
- **Files modified:** `scripts/no_optional_deps_runtime_smoke.sh`, `test/runtime/no_optional_deps_public_send.exs`
- **Verification:** `MIX_ENV=test mix verify.no_optional_runtime` passed end-to-end.

**Total deviations:** 2 auto-fixed (Rule 1, Rule 3).

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the harness, runtime probe, Mix alias source, and CI workflow exist.
- Confirmed task commits `9354794d`, `c1620847`, and `2fab4008` exist.
