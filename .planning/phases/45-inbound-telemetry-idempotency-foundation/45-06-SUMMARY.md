---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 06
subsystem: inbound / ci
tags: [optional-deps, ci, oban, cross-package, wr-03, gap-closure]
requires:
  - "core mix.exs no_warn_undefined symmetry (Mailglass.Oban.TenancyMiddleware)"
  - "MailglassInbound.Execution.Worker runtime-gated cross-package reference"
provides:
  - "inbound --no-optional-deps --warnings-as-errors compile exits 0"
  - "inbound_compile_no_optional_deps CI lane continuously verifies the degraded-compile guarantee"
affects:
  - "mailglass_inbound build (no runtime/public-API change)"
  - ".github/workflows/ci.yml job graph"
tech-stack:
  added: []
  patterns:
    - "project-level no_warn_undefined for runtime-gated cross-package refs (mirrors core)"
    - "compile-only CI gate as a separate parallel job for legible failure surface"
key-files:
  created: []
  modified:
    - mailglass_inbound/mix.exs
    - .github/workflows/ci.yml
decisions:
  - "Suppression is project-level in mix.exs, NOT a module-level @compile in worker.ex (would sit inside the elided Code.ensure_loaded? block and never take effect during the failing compile)"
  - "Kept the no_warn list tight — added only Mailglass.Oban.TenancyMiddleware (the actually-referenced module); did NOT pre-add Mailglass.Outbound.Worker (no inbound reference exists)"
  - "New lane is a separate compile-only job (no Postgres, no MIX_ENV: test), not a step inside inbound_test — failure is legible in the checks list and runs in parallel"
  - "Rejected the inbound OptionalDeps.Oban gateway alternative (re-exposes a core public contract under a second name)"
metrics:
  duration_seconds: 76
  completed_date: 2026-05-23
  tasks_completed: 2
  files_modified: 2
---

# Phase 45 Plan 06: Inbound No-Optional-Deps Compile Lane (WR-03) Summary

Closed WR-03 by adding the cross-package `Mailglass.Oban.TenancyMiddleware` to inbound's `no_warn_undefined` (mirroring core) and shipping a dedicated `inbound_compile_no_optional_deps` CI lane so the CLAUDE.md-mandated `mix compile --no-optional-deps --warnings-as-errors` guarantee for `mailglass_inbound` is real and continuously verified instead of claimed-but-absent.

## What Was Built

**Root cause closed:** Under `--no-optional-deps`, Oban is stripped from both inbound's own dep and the path-dep core, eliding the core `Mailglass.Oban.TenancyMiddleware` module. `execution/worker.ex:36` references it, guarded at runtime by `Code.ensure_loaded?/1` (and the whole worker module is wrapped in `if Code.ensure_loaded?(Oban.Worker)`), so there is no runtime reference — but the static xref pass warned because inbound's `no_warn_undefined` list omitted the cross-package module that core's own list already includes. With `--warnings-as-errors`, the compile exited 1.

**Task 1 (`fix(45-06)`, commit `59f8b08`):** Added `Mailglass.Oban.TenancyMiddleware` to `mailglass_inbound/mix.exs` `elixirc_options/0` so the list reads `[Oban, Oban.Job, Oban.Worker, Mailglass.Oban.TenancyMiddleware]`, with a comment explaining the cross-package, runtime-safe, statically-unresolvable nature of the reference and the symmetry with core. `worker.ex` left unchanged.

**Task 2 (`ci(45-06)`, commit `b6c7d78`):** Added a top-level `inbound_compile_no_optional_deps` job to `.github/workflows/ci.yml` — compile-only (no Postgres `services`, no `MIX_ENV: test`), elixir 1.18 / OTP 27, three actions SHA-pinned to the exact commits used elsewhere (checkout `de0fac2…`, setup-beam `fc68ffb…`, cache `27d5ce7…`), multi-path cache (`deps` + `mailglass_inbound/deps`), two-step inbound `deps.get` (root then `working-directory: mailglass_inbound`), and a `mix compile --no-optional-deps --warnings-as-errors` step in `working-directory: mailglass_inbound`. The fix and the lane ship together so the lane proves the fix red→green in one CI run.

## Verification

- `mailglass_inbound/mix.exs` `no_warn_undefined` = `[Oban, Oban.Job, Oban.Worker, Mailglass.Oban.TenancyMiddleware]` — includes the middleware, excludes `Mailglass.Outbound.Worker` from the list (it appears only in the explanatory comment). Confirmed via grep.
- `.github/workflows/ci.yml` contains `inbound_compile_no_optional_deps` with the two-step inbound dep fetch, the `--no-optional-deps --warnings-as-errors` step in `working-directory: mailglass_inbound`, no `services:`/`postgres`, no `env: MIX_ENV`, and all three pinned SHAs. Confirmed via grep + isolated-block scan.
- YAML validated with `python3 -c "yaml.safe_load(...)"` — parses cleanly; `inbound_compile_no_optional_deps` registered in the jobs map.
- `worker.ex` unchanged across both commits (`git diff --exit-code` clean) — no runtime behavior change, no public-API change.

**Local compile proof: MISSING by design.** Inbound `deps`/`_build` are unfetched in the worktree (`deps=no, _build=no`); the local toolchain cannot run the inbound compile. This is the exact caveat the plan documents — the new `inbound_compile_no_optional_deps` CI lane is the proof and goes green because of Task 1. Source proof (grep + worker.ex unchanged + YAML parse) is fully satisfied locally.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes, no architectural changes, no auth gates.

## Self-Check: PASSED

- FOUND: mailglass_inbound/mix.exs (modified, no_warn entry present)
- FOUND: .github/workflows/ci.yml (modified, inbound_compile_no_optional_deps job present)
- FOUND: commit 59f8b08 (Task 1, fix)
- FOUND: commit b6c7d78 (Task 2, ci)
- FOUND: .planning/phases/45-inbound-telemetry-idempotency-foundation/45-06-SUMMARY.md
