---
phase: 158-simplify-architecture-without-breaking-adopters
plan: 03
subsystem: core-inbound-boundaries
tags: [architecture, boundary, pubsub, optional-dependencies]
requires:
  - phase: 158-01
    provides: runtime/config ownership tracer
provides:
  - core-owned safe PubSub and sender-suppression capability ports
  - inbound-owned adapter for the narrow core capabilities it needs
  - inbound-local GenSMTP gateway and job-tenancy adapter
affects: [158-04, 159-engineering-gates]
tech-stack:
  added: []
  patterns: [consumer-owned port adapter, package-local optional dependency gateway]
key-files:
  created:
    - lib/mailglass/ports/pub_sub.ex
    - lib/mailglass/ports/suppression.ex
    - mailglass_inbound/lib/mailglass_inbound/ports/core.ex
    - mailglass_inbound/test/mailglass_inbound/architecture_port_test.exs
  modified:
    - lib/mailglass/pub_sub.ex
    - lib/mailglass/outbound/projector.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
key-decisions:
  - "Safe broadcasts are owned by Mailglass.PubSub and exposed through the narrow Mailglass.Ports.PubSub boundary."
  - "Raw sender suppression lookup is core-owned through Mailglass.Ports.Suppression; inbound retains degrade-open policy."
  - "Inbound keeps GenSMTP and Oban integration local while consuming only narrow core tenancy and capability ports."
patterns-established:
  - "Static production-edge tests strip documentation/comments before rejecting sibling implementation imports."
requirements-completed: [ARCH-03, ARCH-06]
duration: 18m
completed: 2026-08-17
---

# Phase 158 Plan 03: Core/Inbound Capability Boundaries Summary

Core owns shared safe PubSub and raw suppression checks, while inbound owns its local adapters, optional integrations, workers, and application configuration.

## Commits

- `29d03388` — `feat(158): establish narrow core integration ports`
- `ab803620` — `refactor(158): isolate inbound core integrations`

## Delivered

- Extracted best-effort PubSub error/exit handling from `Outbound.Projector` into `Mailglass.PubSub`; both outbound and inbound use the declared narrow port instead of copied implementation code.
- Added a core sender-suppression port which obtains the configured store through the Runtime-backed `Mailglass.Config.suppression_store/0` accessor. Inbound still treats lookup failures as non-blocking.
- Replaced inbound’s core Oban middleware import with a local Core-port tenancy wrapper, and removed its obsolete warning suppression.
- Moved MIME parsing and doctor availability checks to an inbound-owned GenSMTP gateway.
- Added executable production-edge inventory and negative controls for sibling implementation imports.

## Verification

- Passed: core and inbound `mix compile --no-optional-deps --warnings-as-errors`.
- Passed: focused inbound architecture, mailbox execution, persistence, MIME, and doctor suite — 54 tests, 0 failures.
- Passed: core and inbound compile-connected xref cycle checks.
- Passed: formatter checks for every Plan 03-owned file and `git diff --check`.
- Repository-wide inbound `mix format --check-formatted` remains blocked by pre-existing formatting differences outside this plan’s ownership.
- Passed after updating the Plan 03 Plug fixture to invalidate Runtime after test-only tenancy configuration: core architecture plus inbound architecture/Plug suite — 32 tests, 0 failures.

## Deviation

The plan’s listed files did not include a core sender-suppression capability, although eliminating inbound’s direct core app-env/store access requires one. Root approved the narrow `Mailglass.Ports.Suppression` addition and its `Mailglass` Boundary export; it uses the stable Runtime-backed config accessor, not a broad façade or sibling app-env read.
