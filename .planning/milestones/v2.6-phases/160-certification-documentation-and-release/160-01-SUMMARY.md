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
    - test/reference_host/webhook_operator_path_test.exs
    - dev/mailglass/reference_host/webhook_operator_proof.ex
    - .github/workflows/ci.yml
    - mix.exs
key-decisions:
  - "Certification uses public core and inbound generators in a disposable Phoenix host, never repo-local TestRepo or hand-written package DDL."
  - "Core and inbound use separate configured repositories and non-public prefixes in both installation orders."
  - "Every emitted checkpoint consumes a closed sanitized attestation computed only after runtime/database assertions pass."
  - "Repo-head trust uses explicit prepublication provenance: verified workspace core and inbound beams plus the established published Admin compatibility gate; exact all-published certification remains Plan 06 work."
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
- Added a forced, named Oban CHECK-constraint failure and proved the enclosing
  transaction leaves zero delivery rows, zero event rows, and zero jobs before
  the successful enqueue path proceeds.
- Added deterministic custom Repo, tenancy, adapter, and mailable fixtures that
  are compiled and exercised by the running generated host.
- Certified `Host.Repo` and `Host.InboundRepo` independently against the
  `mailglass_core` and `mailglass_inbound` prefixes, including independent
  migration sources. The public generators and initial migrations now actually
  execute in opposite order, with a host-owned database audit recording
  `core,inbound` and `inbound,core` rather than inferring order from later work.
- Proved upgrade generation from applied anchors, invalid concurrent-index
  recovery, both rollback orders, idempotent up/down reruns, and preservation
  of baseline package relations plus a host-owned marker table.
- Reduced the final evidence artifact to an exact sanitized 20-row manifest:
  fresh install, sync send, atomic enqueue, worker run, persisted outcome,
  custom modules, multi-repo/prefixes, upgrade, rollback, and idempotent rerun
  for each installation order.
- Added executable positive and negative attestation mutations for every stage,
  plus an anchored scratch-database namespace validator that rejects hyphen,
  encoded slash, control-character, prefix, trailing, and empty suffix variants.

## Commits

- `31516871` — require durable host checkpoints (TDD red)
- `f764b090` — prove durable generated-host delivery (TDD green)
- `c69172d2` — require generated-host boundary matrix (TDD red)
- `ac54c511` — certify generated-host boundaries (TDD green)
- `60d08f5e` — load trust-runner pipeline collaborators
- `547ada0d` — expose generated-host review gaps (review TDD red)
- `1e8d39be` — close generated-host review gaps (review TDD green)
- `e4dddce1`, `59e5972b`, `315154b9` — correct runtime proof-harness failures
- `50049e4c` — honor isolated core build paths
- `23d035b7` — separate host migration timestamps
- `6704ce85` — make certification provenance and scratch scope explicit
- `6c083cac` — retain two migration connections for pinned rollback probes
- `ef03b0bb` — expose the pinned rollback shutdown timeout (review TDD red)
- `f8f6507c` — bound temporary Repo shutdown during idempotency probes

## Verification

- Local focused generated-host and trust-runner contract suite passed with 24
  tests and 0 failures after the final review fix.
- Pinned Phase 159 toolchain: `bash scripts/generated_ecto_host_proof.sh`
  against
  `mailglass_generated_ecto_host_phase16001_review_final_pinned3` completed both
  disposable-host journeys and emitted all 20 exact ordered `passed`
  checkpoints followed by `Generated Ecto host proof passed.`
- Local review proof against `mailglass_generated_ecto_host_phase16001_review4`
  completed all 20 checkpoints, including distinct database-attested initial
  order, atomic rollback/commit attestations, and repeated `Migrations already
  down` idempotency probes.
- `bash -n scripts/generated_ecto_host_proof.sh`, scoped formatting, and
  `git diff --check` passed.

The pinned container needed its test-script prerequisites (`python3` and
`ripgrep`) supplied at verification time and used
`host.docker.internal` for the host PostgreSQL service. A transient Hex timeout
fetching `phx_new` passed on retry with conservative Hex timeout/concurrency
settings; the complete certification then ran cleanly.

## Deviations and Notes

### Coherent prepublication trust provenance

Independent review rejected the first trust-runner workaround because it mixed
published inbound beams with individually loaded workspace-private modules.
That workaround is removed. Repo-head CI and Plan 01 tests now explicitly
select `prepublication` mode and provide both core and inbound workspace ebin
paths. The helper verifies exact beam provenance for every required core and
inbound module before routing; an omitted mode fails closed. Admin remains the
existing published compatibility gate. Exact all-published family proof is not
claimed here and remains Phase 160 Plan 06 responsibility.

### Harness corrections found by the end-to-end proof

The production-shaped run also exposed and corrected generated-host-only
assumptions around Phoenix application indentation, runtime Repo discovery,
UUID capture amid Mix logs, async mailable rehydration, and inclusive Ecto
rollback targets. Review reruns additionally exposed Ecto/Postgrex application
startup requirements for the order-audit Repo, one-second migration-version
collisions, injected-constraint exception shape, and slow pinned connection-pool
shutdown. The final idempotency probes now use the same public Ecto migrator
path with an explicit 30-second supervised Repo shutdown instead of Ecto's
hard-coded five-second temporary-Repo stop. Each correction stays inside the
certification harness or its fixture and is covered by the final journey.

## Scope Confirmation

No admin/operator UI, route, LiveView, styling, package version, release target,
tag, publication workflow, credential, or shipped migration changed.

## Self-Check: PASSED

REL-01 is production-shaped, non-vacuous, ordered, sanitized, and verified on
the pinned gating toolchain.
