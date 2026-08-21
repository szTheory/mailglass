---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 03
subsystem: webhook-providers
tags: [ses, mailgun, ets, lifecycle, security]
requires: []
provides:
  - Bounded shared SES certificate retrieval with finite cache lifetime
  - Bounded Mailgun replay-token admission and expiry
affects: [webhook-verification, inbound-ses-reuse]
tech-stack:
  added: []
  patterns: [owner-mediated ETS admission, serialized single-flight, lazy-and-scheduled expiry]
key-files:
  created: []
  modified:
    - lib/mailglass/webhook/providers/ses/cert_cache.ex
    - lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex
    - lib/mailglass/webhook/providers/ses.ex
    - lib/mailglass/webhook/providers/mailgun_replay_cache.ex
    - lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex
decisions:
  - Serialized SES cache-owner retrieval is the conservative global in-flight cap.
  - Live Mailgun replay tokens are never evicted to admit new attacker-controlled tokens.
metrics:
  duration: 5 minutes
  completed: 2026-08-17
status: complete
---

# Phase 157 Plan 03: Inbound Cache Lifecycle Hardening Summary

Shared SES certificate retrieval and Mailgun replay protection now use owned, finite ETS lifecycle controls that fail closed under hostile cardinality.

## Completed Tasks

1. Added TDD coverage and bounded shared SES certificate retrieval: one serialized cold fetch per owner, finite cache admission, negative result caching, expiry sweeps, finite HTTP timeout, and certificate response-size validation.
2. Added TDD coverage and bounded Mailgun replay admission: expired-token reclamation, finite live-token capacity, deterministic fail-closed overflow, and table recreation through the existing supervisor.

## Verification

- `mix test test/mailglass/webhook/providers/ses/cert_cache_test.exs test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/mailgun_test.exs --warnings-as-errors` — 53 tests, 0 failures
- `mix compile --no-optional-deps --warnings-as-errors` — passed
- `mix format` on changed source/tests and `git diff --check` — passed

## Commits

- `3ea41034` — `test(157-03): add failing bounded SES cache tests`
- `8a547ccf` — `feat(157-03): bound shared SES certificate fetches`
- `43952678` — `test(157-03): add failing Mailgun replay capacity test`
- `7fe55a77` — `feat(157-03): bound Mailgun replay cache lifecycle`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Replaced an invalid ETS match specification used for DateTime expiry.
- **Found during:** Task 1 verification
- **Issue:** ETS match specifications cannot compare a DateTime struct literal directly.
- **Fix:** Performed bounded owner-side expiry traversal before cache admission and during scheduled sweeps.
- **Files modified:** `lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex`
- **Commit:** `8a547ccf`

## Known Stubs

None.

## Self-Check: PASSED

- All five implementation files and all three focused test files exist.
- All four task commits are present in git history.
