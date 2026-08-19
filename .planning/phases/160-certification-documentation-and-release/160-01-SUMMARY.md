---
phase: 160-certification-documentation-and-release
plan: 01
subsystem: generated-host-certification
tags: [phoenix, ecto, postgres, oban, migrations, certification]
requires: [REL-01]
provides:
  - production-shaped core and inbound generated-host certification
  - durable synchronous and Oban-backed asynchronous delivery evidence
  - fail-closed ordered checkpoints across install, upgrade, rollback, and rerun boundaries
affects: [release-certification, generated-host-adoption, package-stability]
tech-stack:
  added: []
  patterns: [mutation-tested checkpoints, disposable generated host, database-derived evidence]
key-files:
  created:
    - test/fixtures/generated_host/custom_modules.exs
  modified:
    - scripts/generated_ecto_host_proof.sh
    - test/scripts/generated_ecto_host_proof_test.exs
    - test/reference_host/trust_runner_command_contract_test.exs
    - test/reference_host/trust_runner_checkpoint_contract_test.exs
    - dev/mailglass/reference_host/webhook_operator_proof.ex
key-decisions:
  - "Certification uses public core and inbound generators in a disposable Phoenix host, never repo-local TestRepo or hand-written package DDL."
  - "Core and inbound use separate configured repositories and non-public prefixes in both installation orders."
  - "The emitted artifact is an exact 20-row sanitized manifest derived from runtime and database state."
requirements-completed: [REL-01]
completed: 2026-08-18
---

# Phase 160 Plan 01: Generated-Host Certification Summary

REL-01 now has one production-shaped, one-command certification journey. A
disposable Phoenix/Ecto/Postgres host installs core and inbound from their
public generators, proves durable synchronous delivery and real Oban-backed
asynchronous execution, and traverses the required configuration and migration
boundaries in both package orders.

## Accomplishments

- Added mutation-first contract tests that remove, duplicate, reorder, or give
  equal order to required evidence and prove the checkpoint validator fails
  closed.
- Replaced inline-only async evidence with an actual Oban queue, atomic enqueue,
  worker completion, and persisted delivery/event outcome queried through the
  generated host's configured repositories.
- Added deterministic custom Repo, tenancy, adapter, and mailable fixtures that
  are compiled and exercised by the running generated host.
- Certified `Host.Repo` and `Host.InboundRepo` independently against the
  `mailglass_core` and `mailglass_inbound` prefixes, including independent
  migration sources and both core-first and inbound-first installation orders.
- Proved upgrade generation from applied anchors, invalid concurrent-index
  recovery, both rollback orders, idempotent up/down reruns, and preservation
  of baseline package relations plus a host-owned marker table.
- Reduced the final evidence artifact to an exact sanitized 20-row manifest:
  fresh install, sync send, atomic enqueue, worker run, persisted outcome,
  custom modules, multi-repo/prefixes, upgrade, rollback, and idempotent rerun
  for each installation order.

## Commits

- `31516871` — require durable host checkpoints (TDD red)
- `f764b090` — prove durable generated-host delivery (TDD green)
- `c69172d2` — require generated-host boundary matrix (TDD red)
- `ac54c511` — certify generated-host boundaries (TDD green)
- `60d08f5e` — load trust-runner pipeline collaborators

## Verification

- Pinned Phase 159 toolchain (`Elixir 1.18.4`, `OTP 27`): focused generated-host
  and trust-runner contract suite passed with 17 tests and 0 failures.
- Pinned Phase 159 toolchain: `bash scripts/generated_ecto_host_proof.sh`
  completed both disposable-host journeys and emitted all 20 exact ordered
  `passed` checkpoints followed by `Generated Ecto host proof passed.`
- Local final proof against
  `mailglass_generated_ecto_host_phase16001_final` also completed all 20
  checkpoints, including repeated `Migrations already down` idempotency probes.
- `bash -n scripts/generated_ecto_host_proof.sh`, scoped formatting, and
  `git diff --check` passed.

The pinned container needed its test-script prerequisites (`python3` and
`ripgrep`) supplied at verification time and used
`host.docker.internal` for the host PostgreSQL service. A transient Hex timeout
fetching `phx_new` passed on retry with conservative Hex timeout/concurrency
settings; the complete certification then ran cleanly.

## Deviations and Notes

### Trust-runner collaborator loading

The existing reference host publishes an older inbound package while its proof
helper loads the current workspace Plug. That Plug now depends on the private
Phase 158 pipeline and core-port collaborators, so the helper failed before the
generated-host journey could establish evidence. The authorized scoped
deviation in `dev/mailglass/reference_host/webhook_operator_proof.ex` now loads
those two workspace collaborators before the Plug, matching its existing
verified-request loading pattern. This changes proof harness loading only; no
runtime package or UI behavior changed.

### Harness corrections found by the end-to-end proof

The production-shaped run also exposed and corrected generated-host-only
assumptions around Phoenix application indentation, runtime Repo discovery,
UUID capture amid Mix logs, async mailable rehydration, and inclusive Ecto
rollback targets. Each correction stays inside the certification harness or its
fixture and is covered by the final journey.

## Scope Confirmation

No admin/operator UI, route, LiveView, styling, package version, release target,
tag, publication workflow, credential, or shipped migration changed.

## Self-Check: PASSED

REL-01 is production-shaped, non-vacuous, ordered, sanitized, and verified on
the pinned gating toolchain.
