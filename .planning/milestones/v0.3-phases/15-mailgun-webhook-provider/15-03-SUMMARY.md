---
phase: 15-mailgun-webhook-provider
plan: 03
subsystem: webhook
tags: [mailgun, webhook, config, router, replay, testing]
requires:
  - phase: 15-mailgun-webhook-provider
    provides: Mailgun provider verification, replay cache, and fixture-driven provider tests from 15-02
provides:
  - Mailgun webhook runtime wiring in plug, router, config, and ingest
  - Replay-safe Mailgun plug responses that stop before tenant resolution on duplicate tokens
  - Regression coverage for explicit Mailgun routes and centralized Mailgun config validation
affects: [webhook, mailgun, provider-ingest, router, config, testing]
tech-stack:
  added: []
  patterns: [payload-only mailgun fixture signing in WebhookCase, replay short-circuit before tenant resolution]
key-files:
  created: []
  modified:
    - lib/mailglass/webhook/plug.ex
    - lib/mailglass/webhook/router.ex
    - lib/mailglass/config.ex
    - lib/mailglass/webhook/ingest.ex
    - test/support/webhook_case.ex
    - test/mailglass/webhook/plug_mailgun_test.exs
    - test/mailglass/webhook/router_test.exs
    - test/mailglass/config_test.exs
key-decisions:
  - "Mailgun replay exits from `Mailglass.Webhook.Plug` as HTTP 200 with duplicate metadata before tenant resolution or ingest."
  - "Mailgun is a valid router provider but remains off the default webhook mount surface unless adopters list it explicitly."
  - "Mailgun ingest uses the webhook token path as the durable provider event id so replay and DB dedupe stay aligned."
patterns-established:
  - "WebhookCase signs Mailgun payload-only fixtures at conn-build time instead of storing signatures on disk."
  - "Provider-level replay outcomes can flow through verify telemetry and stop the plug before tenant-scoped work begins."
requirements-completed: [MAILGUN-01, MAILGUN-02, MAILGUN-03]
duration: 8min
completed: 2026-04-28
---

# Phase 15 Plan 03: Mailgun Webhook Provider Summary

**Mailgun webhook runtime wiring with replay-safe plug responses, explicit router opt-in, and centralized Mailgun config validation**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-29T01:00:00Z
- **Completed:** 2026-04-29T01:07:37Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added Mailgun test support in `WebhookCase`, including runtime payload signing and default Mailgun test config setup.
- Wired Mailgun into the webhook plug, router, config schema, and ingest path without changing the default zero-arg route surface.
- Locked the behavior down with regression tests for valid Mailgun `200`, replay `200`, bad-signature `401`, explicit route mounting, and Mailgun config validation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend webhook test support and create the Mailgun plug test file first** - `ffa7cc4` (test), `9639da0` (feat)
2. **Task 2: Add Mailgun config schema and plug/router runtime wiring** - `2cc9948` (feat)
3. **Task 3: Finalize Mailgun plug, router, and config regression tests** - `c12b678` (test), `f7e8c18` (feat)

## Files Created/Modified
- `test/support/webhook_case.ex` - Snapshots/restores Mailgun config and signs Mailgun payload-only fixtures into webhook conns.
- `test/mailglass/webhook/plug_mailgun_test.exs` - Exercises valid, replay, bad-signature, and missing-config Mailgun plug paths.
- `lib/mailglass/webhook/plug.ex` - Accepts Mailgun as a valid provider and short-circuits replay to HTTP 200 before tenant resolution.
- `lib/mailglass/webhook/router.ex` - Validates `:mailgun` in explicit provider lists while keeping the default route set at Postmark and SendGrid.
- `lib/mailglass/config.ex` - Adds the validated Mailgun runtime config subtree with signing and replay/timestamp defaults.
- `test/mailglass/webhook/router_test.exs` - Proves explicit Mailgun route mounting and preserves the default two-route contract.
- `test/mailglass/config_test.exs` - Proves Mailgun subtree acceptance and invalid-key/type failures.
- `lib/mailglass/webhook/ingest.ex` - Accepts Mailgun requests in the ingest pipeline and derives provider event ids from the Mailgun token path.

## Decisions Made
- Kept Mailgun replay handling in the plug response matrix rather than treating replay as a signature failure, so duplicate requests converge to a non-retrying success path.
- Preserved the public router contract by expanding the valid provider list without changing `mailglass_webhook_routes("/webhooks")` defaults.
- Reused the Mailgun token for ingest dedupe so provider verification, replay cache behavior, and DB uniqueness all key off the same identifier.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Enabled Mailgun through the webhook ingest boundary**
- **Found during:** Task 3 (Finalize Mailgun plug, router, and config regression tests)
- **Issue:** Valid Mailgun plug requests still crashed in `Mailglass.Webhook.Ingest.ingest_multi/3` because the ingest guard only accepted `:postmark` and `:sendgrid`.
- **Fix:** Extended ingest to accept `:mailgun` and derive the durable provider event id from the Mailgun token-backed event metadata.
- **Files modified:** `lib/mailglass/webhook/ingest.ex`
- **Verification:** `mix test test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs test/mailglass/config_test.exs --warnings-as-errors`
- **Committed in:** `f7e8c18`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required for correctness after Mailgun was wired into the plug. No scope creep beyond making the planned runtime path executable.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Mailgun runtime behavior now matches the provider-layer replay contract and is covered by regression tests at the plug, router, and config seams.
- The next plan can build installer/docs output on top of the explicit `providers: [:mailgun]` routing contract and the centralized Mailgun config subtree.

## Self-Check: PASSED
- Verified `.planning/phases/15-mailgun-webhook-provider/15-03-SUMMARY.md` exists on disk.
- Verified commit hashes `ffa7cc4`, `9639da0`, `2cc9948`, `c12b678`, and `f7e8c18` exist in git history.

---
*Phase: 15-mailgun-webhook-provider*
*Completed: 2026-04-28*
