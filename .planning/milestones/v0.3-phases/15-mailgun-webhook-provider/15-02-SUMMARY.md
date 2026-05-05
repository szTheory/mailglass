---
phase: 15-mailgun-webhook-provider
plan: 02
subsystem: webhook
tags: [mailgun, webhook, hmac, replay, testing]
requires:
  - phase: 15-mailgun-webhook-provider
    provides: replay-aware provider contract and supervised Mailgun replay cache from 15-01
provides:
  - Mailgun provider verification using JSON-body HMAC and replay cache lookup
  - Raw Mailgun webhook fixture corpus covering the D-09 lifecycle set
  - Fixture-driven Mailgun provider tests with runtime signature generation
affects: [webhook, mailgun, provider-ingest, plug-runtime, docs]
tech-stack:
  added: []
  patterns: [payload-only webhook fixtures, token-backed provider_event_id, conservative failed-event metadata retention]
key-files:
  created:
    - lib/mailglass/webhook/providers/mailgun.ex
    - test/support/fixtures/webhooks/mailgun/accepted.json
    - test/support/fixtures/webhooks/mailgun/delivered.json
    - test/support/fixtures/webhooks/mailgun/failed_temporary.json
    - test/support/fixtures/webhooks/mailgun/failed_permanent_bounce.json
    - test/support/fixtures/webhooks/mailgun/failed_permanent_rejected.json
    - test/support/fixtures/webhooks/mailgun/opened.json
    - test/support/fixtures/webhooks/mailgun/clicked.json
    - test/support/fixtures/webhooks/mailgun/complained.json
    - test/support/fixtures/webhooks/mailgun/unsubscribed.json
  modified:
    - test/support/webhook_fixtures.ex
    - test/mailglass/webhook/providers/mailgun_test.exs
key-decisions:
  - "Mailgun verification uses the webhook token as both the replay-cache key and normalized provider_event_id so fast-path dedupe and durable ingest identity stay aligned."
  - "Failed-event normalization stays conservative: temporary failures map to :deferred, bounce-family permanent failures map to :bounced or :rejected, and raw Mailgun fields remain in string-key metadata."
patterns-established:
  - "Mailgun fixtures stay payload-only on disk; tests inject the signature object at runtime so verification cases can vary timestamp and token deterministically."
  - "Mailgun provider metadata keeps raw provider keys like \"severity\", \"reason\", \"delivery-status\", and \"timestamp\" alongside normalized taxonomy decisions."
requirements-completed: [MAILGUN-01, MAILGUN-02, MAILGUN-03]
duration: 8min
completed: 2026-04-28
---

# Phase 15 Plan 02: Mailgun Webhook Provider Summary

**Mailgun HMAC verification, replay-aware token handling, raw lifecycle fixtures, and fixture-driven provider normalization tests**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-29T00:49:30Z
- **Completed:** 2026-04-29T00:57:43Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments
- Added the full raw Mailgun webhook fixture corpus needed for accepted, delivered, temporary failure, permanent failure, engagement, complaint, and unsubscribe coverage.
- Implemented `Mailglass.Webhook.Providers.Mailgun` with HMAC verification over `timestamp <> token`, timestamp skew checks via `Mailglass.Clock`, and ETS-backed replay detection returning `{:ok, :replay}`.
- Finished the Mailgun provider test suite and helper flow so tests sign fixtures at runtime and assert the normalization metadata contract directly.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the raw Mailgun webhook fixture set first** - `9d46822` (test)
2. **Task 2: Implement Mailgun verification and normalization** - `c52beac` (feat)
3. **Task 3: Add Mailgun fixture helpers and finish the provider test suite** - `5229a81` (test), `1c6549d` (feat)

## Files Created/Modified
- `lib/mailglass/webhook/providers/mailgun.ex` - Mailgun provider verification, replay check, and event normalization.
- `test/support/webhook_fixtures.ex` - Mailgun fixture loader and runtime signature helper.
- `test/mailglass/webhook/providers/mailgun_test.exs` - Full provider suite for verification, replay, skew, and lifecycle mapping.
- `test/support/fixtures/webhooks/mailgun/*.json` - Payload-only Mailgun fixture set covering the D-09 lifecycle matrix.

## Decisions Made
- Used signed payload JSON rather than synthetic headers for Mailgun tests because Mailgun’s verifier contract lives inside the body payload.
- Preserved Mailgun raw failure detail under its original string metadata keys so later ingest and debugging layers can inspect ambiguous provider semantics without reverse-mapping.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The initial red test assumed Mailgun signs the raw body. Mailgun signs `timestamp <> token`, so the failing case was corrected to tamper the signature value itself.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The provider layer is ready for Plan 15-03 to wire Mailgun into plug, router, and config handling.
- Replay behavior is now verified at the provider boundary, so the next plan can focus on HTTP status handling and route/runtime integration.

## Self-Check: PASSED
- Verified `.planning/phases/15-mailgun-webhook-provider/15-02-SUMMARY.md` exists on disk.
- Verified task commit hashes `9d46822`, `c52beac`, `5229a81`, and `1c6549d` exist in git history.

---
*Phase: 15-mailgun-webhook-provider*
*Completed: 2026-04-28*
