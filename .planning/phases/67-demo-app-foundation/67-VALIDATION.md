---
phase: 67
slug: demo-app-foundation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-01
---

# Phase 67 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Mix aliases, Docker Compose config validation, Playwright seed |
| Config file | `mix.exs`, `reference/demo_app/mix.exs`, `compose.demo.yml` |
| Quick run command | `mix test test/reference_host/scope_lock_contract_test.exs` |
| Full suite command | `mix verify.phase67` |
| Estimated runtime | 60-300 seconds depending on dependency cache state |

## Sampling Rate

- After every task commit: run the task's listed source assertions and the
  fastest relevant Mix/Compose command.
- After every plan wave: run `mix verify.phase67` once it exists.
- Before `$gsd-verify-work`: `mix verify.phase67` and `docker compose -f
  compose.demo.yml config` must be green.
- Max feedback latency: 5 minutes for cached checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 67-01-01 | 01 | 1 | DEMO-01 | T-67-01 | Rich demo stays outside `reference/host_app` | contract | `mix test test/reference_host/scope_lock_contract_test.exs` | yes | pending |
| 67-01-02 | 01 | 1 | DEMO-02 | T-67-02 | Hex mode resolves published package constraints | smoke | `cd reference/demo_app && MAILGLASS_DEMO_DEPS=hex mix deps.get --only prod` | yes | pending |
| 67-02-01 | 02 | 1 | DX-01 | T-67-03 | Demo readiness is health-gated before evidence starts | config/runtime | `docker compose -f compose.demo.yml config` | yes | pending |
| 67-02-02 | 02 | 1 | DX-02 | T-67-04 | Browser deps are installed from lockfile and cache volumes remain | source/config | `rg -n "npm ci|service_healthy|health" compose.demo.yml reference/demo_app` | yes | pending |
| 67-03-01 | 03 | 2 | DX-01 | T-67-05 | Reset path is deterministic and explicitly destructive | unit/source | `cd reference/demo_app && mix test` | yes | pending |
| 67-03-02 | 03 | 2 | DX-02 | T-67-06 | Phase 67 proof is runnable as one command | alias | `mix verify.phase67` | no | pending |

## Wave 0 Requirements

- Existing ExUnit infrastructure covers root and demo-app test execution.
- Plan 03 creates the reusable `mix verify.phase67` command.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Local click-around starts in a browser | DX-01 | Browser inspection is useful but not required for every task commit | Run `docker compose -f compose.demo.yml up --build demo`, open `http://localhost:4015`, and confirm dashboard links load. |

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit source assertions.
- [x] Sampling continuity has no 3 consecutive tasks without automated verify.
- [x] No watch-mode flags are required.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
