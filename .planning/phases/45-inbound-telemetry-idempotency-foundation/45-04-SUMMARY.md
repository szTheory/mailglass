---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 04
subsystem: testing
tags: [property-test, stream_data, idempotency, postgres, ecto, ci, mailglass_inbound, tdd]

# Dependency graph
requires:
  - phase: 45-01
    provides: MailglassInbound.TestRepo (Postgres-backed) + migration-running test_helper + inbound_test CI job
  - phase: 45-02
    provides: span-wrapped persist/execute write path (return shapes unchanged — confirmed)
provides:
  - MailglassInbound.Properties.InboundIdempotencyConvergenceTest (TELE-08 1000-run replay-convergence proof)
  - stream_data as an inbound test-only dep (unblocks future inbound property tests, Phases 46-49)
  - CI property gate ("mix test --only property") in the inbound_test Postgres job
affects: [TELE-08, Phase 46 Mailgun/SES ingress (idempotency now a tested invariant), Phase 49 replay tooling]

# Tech tracking
tech-stack:
  added: ["{:stream_data, \"~> 1.3\", only: [:test]} in mailglass_inbound (resolved 1.3.0, mirrors core pin)"]
  patterns:
    - "Inbound convergence proof mirrors outbound WebhookIdempotencyConvergenceTest: ExUnit.Case async:false + ExUnitProperties (NOT DataCase), start_owner! shared, TRUNCATE CASCADE between iterations, max_runs: 1000, timeout: :infinity"
    - "Drive Execution.execute/2 synchronously (NOT dispatch/2) so ExecutionRun counts are deterministic (D-45-10)"
    - "Count only `where: r.source == :fresh` on the shared ExecutionRun/ReplayRun table (RESEARCH Pitfall 4)"

key-files:
  created:
    - mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/mix.lock
    - .github/workflows/ci.yml

key-decisions:
  - "Added stream_data as a test-only inbound dep (Rule 3 blocking fix): ExUnitProperties is required for the planned property to compile; inbound had no property tests before, so the dep was absent. Pinned to ~> 1.3 (== core's resolution 1.3.0), test-only."
  - "Built the canonical %InboundMessage{} + handoff directly in the test (with fixed tenant_id + provider \"postmark\") rather than routing through a provider normalizer — keeps the proof focused on the persist/execute dedupe path and matches the locked RESEARCH skeleton."
  - "Supplied minimal evidence (%{raw_payload: payload}) in the handoff because Persist.persist/2 inserts an InboundEvidence row that ExecutionRun FKs to; no MIME/raw_mime needed for the postmark dedupe path."

patterns-established:
  - "Inbound property tests live under mailglass_inbound/test/mailglass_inbound/properties/ and are tagged @moduletag :property, gated separately in CI."

requirements-completed: [TELE-08]

# Metrics
duration: 5min
completed: 2026-05-22
---

# Phase 45 Plan 04: Inbound 1000-Replay Convergence Property (TELE-08) Summary

**A StreamData property that replays arbitrary Postmark-style inbound payloads 1000× through the REAL persist + execute write path and proves exactly one InboundRecord + one fresh ExecutionRun per unique `(tenant_id, provider, provider_message_id)` against a real Postgres DB — the inbound mirror of the shipped outbound webhook convergence proof, making idempotency a tested invariant the rest of v1.2 can build on.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-22T22:58:46Z
- **Completed:** 2026-05-22T23:03:59Z
- **Tasks:** 1 feature (RED → GREEN)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Created `MailglassInbound.Properties.InboundIdempotencyConvergenceTest` — a `max_runs: 1000` StreamData property that, for any generated list of payloads (MessageID drawn from a ≤4-id `member_of` pool) each replayed `integer(1..10)` times, drives the REAL `MailglassInbound.Ingress.Persist.persist/2` then `MailglassInbound.Execution.execute/2` (sync) and asserts convergence.
- The property **passes 1000 runs against a real Postgres database** (`MailglassInbound.TestRepo`, stood up in Plan 01) — ~46-55s wall time. The SQL trace confirms the real write path: SELECT-for-duplicate, INSERT into `mailglass_inbound_records` + `mailglass_inbound_evidence` + `mailglass_inbound_replay_runs` (source `:fresh`), and the final counts filter `WHERE source = 'fresh'`.
- The dedupe is anchored on the Postgres unique index `mailglass_inbound_records_postmark_idempotency_idx` — duplicate payloads return `:duplicate` from persist and `:skipped` from `execute/2`, inserting zero extra fresh ExecutionRun rows.
- Extended the `inbound_test` CI job with a dedicated `mix test --only property` gate that runs after the unit subset, against the same Postgres service.
- All 93 existing inbound unit tests still pass; the no-optional-deps compile lane stays green.

## Task Commits

TDD RED → GREEN sequence, each committed atomically:

1. **RED — failing convergence property** — `ca5cdfb` (test) — the property file alone; fails to compile (`ExUnitProperties is not loaded`) until stream_data is wired.
2. **GREEN — dep + CI gate** — `70e0ea4` (feat) — adds `stream_data` to inbound deps + lock and the CI property step; the 1000-run property passes.

**Plan metadata (this SUMMARY):** committed separately in worktree mode (STATE.md / ROADMAP.md excluded — the orchestrator owns those after wave merge).

## Files Created/Modified

- `mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs` — the TELE-08 convergence proof (created)
- `mailglass_inbound/mix.exs` — added `{:stream_data, "~> 1.3", only: [:test]}`
- `mailglass_inbound/mix.lock` — resolved `stream_data` 1.3.0 (the ONLY lock change; checksum matches core's pin)
- `.github/workflows/ci.yml` — new "Run inbound convergence property (TELE-08)" step (`mix test --only property`) in the inbound_test job

## TDD Gate Compliance

- **RED gate present:** `ca5cdfb` `test(45-04): ...` — the property committed first, failing (`ExUnitProperties is not loaded`).
- **GREEN gate present:** `70e0ea4` `feat(45-04): ...` after RED — wires the dep + CI gate; property passes.
- REFACTOR: not needed (the implementation under test already existed and is correct; the proof's value is the 1000-run assertion holding).
- **Note on RED semantics:** This is a *proof* test over already-shipped persist/execute behavior, so the RED failure is infrastructural (missing test dep), not a behavioral red. The plan explicitly sanctions "GREEN on the first run because the dedupe is already correct" — the deliverable is the 1000-run invariant, which holds.

## Verification (plan `<verification>` block)

- `cd mailglass_inbound && mix test --only property` exits 0 — **1 property, 0 failures**, 1000 runs against real Postgres (~46-55s). PASS.
- The test uses `MailglassInbound.Execution.execute/2` (sync), never `dispatch/2`. PASS (confirmed in source + SQL trace).
- The ExecutionRun assertion filters `where: r.source == :fresh`. PASS.
- `.github/workflows/ci.yml` inbound job runs the property gate. PASS (YAML validated).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added stream_data as an inbound test-only dependency**
- **Found during:** the feature's RED run
- **Issue:** `use ExUnitProperties` failed with `module ExUnitProperties is not loaded and could not be found`. `mailglass_inbound` had no property tests before this plan, so `stream_data` (which provides `ExUnitProperties`) was not a dependency. The plan's artifact cannot compile or run without it.
- **Fix:** Added `{:stream_data, "~> 1.3", only: [:test]}` to `mailglass_inbound/mix.exs` and resolved it into the inbound lockfile. Pinned to the same version core uses (1.3.0); test-only scope.
- **Why not a package-legitimacy checkpoint:** `stream_data` is a first-party, widely-used Elixir property-testing library already vetted and pinned in the core lockfile at the identical version/checksum (`bde37905…` / `3cc552e2…`). The dep install succeeded; this is not a slopsquat/hallucinated-package risk.
- **Files modified:** mailglass_inbound/mix.exs, mailglass_inbound/mix.lock
- **Verification:** property compiles + passes 1000 runs; 93 unit tests still pass; no-optional-deps compile lane green.
- **Committed in:** 70e0ea4 (GREEN)

### Out-of-scope reverts (not committed)

- **Core mix.lock toolchain churn (same as Plan 01).** Running `mix deps.get` at the worktree root under the local Elixir 1.19/OTP 28 toolchain re-resolves several core deps to newer versions, rewriting the core `mix.lock`. This is out of scope for 45-04. The core lock was reverted to the phase base after every verification run; only `mailglass_inbound/mix.lock` (stream_data) is committed. Final tree confirmed: core `mix.lock == phase base`.

**Total deviations:** 1 auto-fixed (blocking dep wiring), 1 out-of-scope revert (core lock churn, not committed). No scope creep — the only file beyond the plan's `files_modified` list is the inbound `mix.exs` (required to declare the test dep the plan's artifact needs).

## Issues Encountered

- **Worktree toolchain rewrites core mix.lock** (inherited from Plan 01). Local Elixir 1.19/OTP 28 re-resolves core deps on `deps.get`; CI pins 1.18/OTP 27. Mitigated by reverting the core lock to the phase base before each commit; verification ran while the tree was internally consistent.
- **Noisy Ecto debug logging during the property run.** The 1000-run property emits substantial query debug output; this is cosmetic (test logging config), does not affect the assertion, and is filtered for clean verification. Not changed (out of scope; would touch shared test config).

## Threat Flags

None — no new security-relevant surface. This plan's threat register (T-45-14/15/16) is entirely *mitigation*: the property proves dedupe correctness (T-45-14) against the real unique index, respects the append-only trigger via INSERT + TRUNCATE CASCADE only (T-45-15), and filters `source == :fresh` so the shared ExecutionRun/ReplayRun table cannot miscount (T-45-16). All three mitigations are implemented and verified by the passing property.

## Known Stubs

None — the property exercises the real persist/execute write path against real Postgres; no mock data, no FakeRepo, no placeholder values.

## User Setup Required

None — CI provides Postgres via the existing service container; local runs need a reachable Postgres (existing project convention; the inbound test DB is created via `mix ecto.create -r MailglassInbound.TestRepo`).

## Next Phase Readiness

- TELE-08 is proven: inbound ingest is idempotent by construction, verified by a 1000-run property against a real DB. Phase 46 (Mailgun/SES ingress) and Phase 49 (replay tooling) can rely on this invariant rather than re-proving it.
- `stream_data` is now available test-only in `mailglass_inbound`, so future inbound property tests (e.g. provider-normalization round-trips) can be added without dep work.
- The inbound CI job now has a property gate; new `@property`-tagged inbound tests run automatically in the Postgres job.

## Self-Check: PASSED

- Created file present: `mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs` — FOUND.
- Both commits present in git history: `ca5cdfb` (RED test) FOUND, `70e0ea4` (GREEN feat) FOUND.
- `stream_data` present in `mailglass_inbound/mix.lock`; core `mix.lock` identical to phase base (no churn committed).
- Property verified: `mix test --only property` → 1 property, 0 failures (1000 runs, real Postgres).

---
*Phase: 45-inbound-telemetry-idempotency-foundation*
*Completed: 2026-05-22*
