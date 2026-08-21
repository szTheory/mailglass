---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 05
subsystem: inbound-persistence
tags: [elixir, ecto, postgres, sha256, replay, ses]
requires:
  - phase: 157-01
    provides: explicit authenticated inbound request handoff
  - phase: 157-02
    provides: bounded SES S3 fetch and closed retry classification
provides:
  - additive inbound V02 SHA-256 and terminal-evidence expansion
  - mixed legacy/new MIME dedupe with a resumable serialized backfill
  - committed authenticated permanent-failure evidence before provider acknowledgement
  - end-to-end terminal recovery through the existing replay execution path
affects: [inbound, migrations, replay, lifecycle-hardening]
tech-stack:
  added: []
  patterns:
    - dual-read and dual-write digest transition
    - advisory-locked keyset backfill
    - exact signed-request evidence
    - post-commit provider acknowledgement
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v02.ex
  modified:
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
key-decisions:
  - "Scope the SHA-256 unique index to MIME-dedup providers so Postmark retains provider-message-id semantics."
  - "A transient S3-not-ready result remains a 500 with no terminal evidence; only authenticated s3_fetch_failed evidence may produce a 2xx acknowledgement."
  - "Serialize backfill batches with a schema-specific advisory transaction lock and compute SHA-256 inside PostgreSQL so MIME bodies never accumulate in BEAM memory."
requirements-completed: [INB-04, DATA-01, DATA-02]
coverage:
  - id: D1
    description: Mixed V01/V02 rows dedupe and bounded SHA-256 batches resume deterministically without editing V01.
    requirement: DATA-01
    verification:
      - kind: integration
        ref: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: New digest queries directly compare stored SHA-256 state and gate the legacy stored fingerprint on null SHA state.
    requirement: DATA-02
    verification:
      - kind: integration
        ref: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Authenticated permanent evidence persists exact request bytes before 2xx and replays through refetch, normalize, update, route, and execute.
    requirement: INB-04
    verification:
      - kind: integration
        ref: mailglass_inbound/test/mailglass_inbound/replay_test.exs
        status: pass
      - kind: integration
        ref: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-08-17
status: complete
---

# Phase 157 Plan 05: SHA-256 Transition and Replayable Terminal Evidence Summary

**Inbound persistence now upgrades MIME identity without a dedupe gap and never stops authenticated SES redelivery until permanent-failure evidence is durably replayable.**

## Accomplishments

- Added append-only V02 fields for SHA-256, exact signed requests, and closed terminal-failure context while leaving V01 byte-identical.
- Dual-wrote SHA-256 for new MIME evidence and directly queried it first, falling back to the stored legacy MD5 fingerprint only while SHA-256 is null.
- Added a bounded, advisory-serialized, keyset-resumable backfill that hashes in PostgreSQL, returns a deterministic cursor, reports real remaining work, and rejects concurrent runners without advancing.
- Preserved Postmark's provider-message-id identity by limiting the new digest uniqueness rule to SendGrid, Mailgun, and SES.
- Stored only the closed authenticated permanent S3 class, JSON-safe request headers, the verified envelope/facts, and byte-exact signed request before returning the provider-stopping 2xx acknowledgement.
- Extended internal replay so terminal SES evidence refetches content, normalizes it, transactionally fills the placeholder canonical/evidence rows, binds the current route, and executes through the existing replay path.

## Task and Review-Fix Commits

1. **Contract-first V02 coverage** — `eef6e2f2` (`test`)
2. **Additive SHA-256 transition and dispatcher** — `d39b9f90` (`feat`)
3. **Initial terminal evidence-before-ack path** — `4a452cec` (`feat`)
4. **Review remediation and end-to-end recovery proof** — `7c2da6ef` (`fix`)

## Review Findings Resolved

- Kept `:s3_object_not_ready` retryable at HTTP 500 with no terminal row and changed committed authenticated permanent failures to the actual SNS-stopping 2xx response.
- Rejected incomplete or open-ended terminal evidence instead of acknowledging an unreplayable row.
- Cast request-header tuples to a JSON-safe, duplicate-preserving lowercase multimap.
- Persisted the exact signed request in V02 and proved byte equality through real PostgreSQL storage and replay.
- Replaced the placeholder replay claim with real refetch, normalization, transactional update, routing, and existing execution-path proof.
- Restricted SHA uniqueness so equal Postmark MIME with different provider IDs remains two records.
- Made the backfill bounded in rows and memory, deterministic in cursor order, rerunnable, and safe under concurrent runners.
- Made V02 index creation retryable after interrupted concurrent builds and idempotent on the transactional path.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/migrations_test.exs --warnings-as-errors` — 79 tests, 0 failures.
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` — passed.
- Targeted `mix format --check-formatted` for every modified implementation/test file — passed.
- `git diff --check` — passed.
- V01 git object proof: HEAD and worktree both `6c31ea5fac4105968d0e733d3e6e2aa8aa13ca08`.

## Deviations from Plan

### Auto-fixed Review Issues

The initial implementation stored insufficient terminal material, used a non-stopping 422 response, allowed transient evidence persistence, exposed Postmark to a new MIME uniqueness rule, and returned a non-resumable/concurrency-unsafe backfill count. All were corrected before completion, with real PostgreSQL and end-to-end replay regressions added.

## User Setup Required

None beyond running the generated V02 host migration. Generated non-transactional wrapper policy and host proof remain owned by Plan 157-09.

## Self-Check: PASSED

- All implementation commits exist in git history.
- V01 is byte-identical.
- Real persistence and terminal replay proofs pass without an admin/operator UI change.
