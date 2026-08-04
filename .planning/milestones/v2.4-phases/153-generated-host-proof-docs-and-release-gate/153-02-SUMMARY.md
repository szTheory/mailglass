---
phase: 153
plan: 02
subsystem: generated-host-proof
tags: [phoenix, ecto, oban, postgres, async, privacy]
requires:
  - phase: 153-01
    provides: package-shaped generated Phoenix/Ecto migration tracer
provides:
  - normal-mode Oban sync/async provider-input parity proof
  - hashed durable settlement and payload-scrub checkpoint evidence
affects: [153-03, release-gate]
tech-stack:
  added: [Oban generated-host migration]
  patterns: [host-owned capture adapter, bounded queue polling, sanitized lifecycle checkpoint]
key-files:
  created:
    - test/generated_host/sync_async_parity_test.exs
  modified:
    - dev/mailglass/generated_host/host_template.ex
    - dev/mailglass/generated_host/journey.ex
    - dev/mailglass/generated_host/checkpoint.ex
    - scripts/generated_host_proof.sh
    - scripts/check_generated_host_proof.sh
decisions:
  - Equivalent sync and async inputs use distinct host mailable modules to avoid intentional idempotency convergence.
  - The generated host owns Oban schema installation and a per-run database before starting normal supervision.
requirements-completed: [ADOPT-02]
metrics:
  tasks_completed: 2
status: complete
---

# Phase 153 Plan 02: Normal Oban Async Parity Summary

The generated Phoenix host now proves wire-equivalent default-tenant sync and actively polled Oban async delivery, with durable success facts and private-payload scrubbed tombstone evidence.

## Tasks Completed

1. Created the RED/GREEN real-host oracle for normal-mode sync/async provider input parity.
2. Added durable settlement/scrub checkpoint validation with only counts, booleans, and hashes.

## Verification

- `mix test test/generated_host/sync_async_parity_test.exs --warnings-as-errors` — passed: 3 tests, 0 failures.
- `KEEP_HOST_ON_FAILURE=true WORK_DIR=/tmp/mailglass-plan15302-canonical CHECKPOINT_OUT=/tmp/mailglass-plan15302-canonical-export.json DEP_MODE=local bash scripts/generated_host_proof.sh --stage async-parity` — passed.
- `bash scripts/check_generated_host_proof.sh --checkpoint /tmp/mailglass-plan15302-canonical-export.json` — passed.
- The exported checkpoint records matching sync/async hashes, terminal job, sent delivery, scrubbed payload, and event/capture counts of 2 without message or provider content.

## Commits

- `989363e7` — RED normal Oban sync/async parity contract.
- `7d6a8c25` — normal Oban provider-input parity implementation.
- `1313cf24` — RED durable settlement scrub evidence contract.
- `3892827f` — durable lifecycle checkpoint validation.
- `37b1e7b4` — real generated-host parity runner completion fixes.
- `54215358` — remove successful disposable generated-host databases.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected generated-host runner and real-Oban bootstrap.
- **Found during:** Tasks 1 and 2.
- **Issue:** Phoenix install mode exited before the proof body; shared Hex state contended; Oban had no generated-host schema; and an unquoted dashed stage atom prevented the Journey from running.
- **Fix:** Used a no-install/no-assets host generation path, isolated transient tool state, emitted an Oban Ecto migration, created and cleaned up a per-run database, and mapped the shell stage name to an Elixir atom.
- **Files modified:** generated host template, Journey, and proof runner.
- **Verification:** Canonical retained local host proof and checkpoint validator passed.

2. [Rule 1 - Bug] Avoided intentional idempotency convergence while preserving provider parity.
- **Found during:** Task 1.
- **Issue:** Two byte-identical sends share Mailglass's delivery idempotency key, preventing the async request from enqueueing.
- **Fix:** Used distinct host-owned mailable modules with identical captured provider input.
- **Files modified:** generated host template and Journey.
- **Verification:** Canonical proof captured equal normalized input hashes and separately observed async job settlement.

**Total deviations:** 2 auto-fixed Rule 1 issues. Both were required to make the production-shaped proof truthful; no product API changed.

## Known Stubs

None.

## Self-Check: PASSED
