---
phase: 17-unblock-verify-resend
plan: "01"
subsystem: testing
tags: [resend, webhook, svix, hmac-sha256, plug, application-env, test-isolation]

requires:
  - phase: 14-resend-webhook-provider
    provides: "Resend provider implementation (Providers.Resend.verify!/3, sign_resend_payload/4, load_resend_fixture/1)"
provides:
  - ":resend in @valid_providers in plug.ex and router.ex"
  - "resolve_config!(:resend) clause in plug.ex wiring secret and timestamp_tolerance_seconds"
  - "provider_module(:resend) dispatch clause in plug.ex"
  - "WebhookCase @resend_secret_bytes and @resend_secret module attributes"
  - "WebhookCase setup installs and restores :resend Application env"
  - "mailglass_webhook_conn(:resend) arm building correctly signed Svix conn"
  - "stub_resend_fixture/1 exported from using macro"
  - "endpoint_resolution_test.exs fixed to async: false (no Application env race)"
affects: [17-02-resend-integration-tests, plan-02-integration-tests-that-use-WebhookCase-resend]

tech-stack:
  added: []
  patterns:
    - "Svix signature format: 'v1,' prefix + base64(HMAC-SHA256(svix_id.svix_timestamp.raw_body, secret_bytes))"
    - "whsec_ prefix stripping before Base64.decode! to get raw secret bytes for HMAC"
    - "svix_timestamp generated at call time (not compile time) to avoid timestamp-skew test failures"

key-files:
  created: []
  modified:
    - "lib/mailglass/webhook/plug.ex"
    - "lib/mailglass/webhook/router.ex"
    - "test/mailglass/tracking/endpoint_resolution_test.exs"
    - "test/mailglass/webhook/plug_test.exs"
    - "test/support/webhook_case.ex"

key-decisions:
  - "svix_timestamp must be generated fresh at call time inside mailglass_webhook_conn/3, not as a module attribute, to prevent timestamp-skew test failures"
  - "svix-signature header value must include 'v1,' prefix per Svix signature format"
  - "secret_bytes are decoded by stripping whsec_ prefix and Base64-decoding the remainder before HMAC"

patterns-established:
  - "Provider wiring pattern: @valid_providers list + resolve_config! clause + provider_module clause — three coordinated changes per new provider"
  - "WebhookCase provider lifecycle: capture prior env + put_env in setup + restore_env in on_exit"

requirements-completed:
  - RESEND-01

duration: 5min
completed: 2026-04-29
---

# Phase 17 Plan 01: Wire :resend into webhook dispatch chain and fix test isolation

**:resend wired into plug.ex and router.ex static dispatch (resolve_config!, provider_module, @valid_providers), WebhookCase extended with Svix-signed conn builder and symmetric Application env lifecycle, endpoint_resolution_test.exs fixed to async: false**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-29T12:17:00Z
- **Completed:** 2026-04-29T12:21:26Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Fixed the async race in endpoint_resolution_test.exs by changing `async: true` to `async: false` (Application.put_env tests must not run concurrently)
- Replaced the failing assert_raise test for :resend in plug_test.exs with a success assertion, mirroring the :postmark and :sendgrid patterns
- Wired :resend fully into plug.ex: `@valid_providers`, `resolve_config!(:resend)` (secret + timestamp_tolerance_seconds), and `provider_module(:resend)` pointing to Providers.Resend
- Added :resend to `@valid_providers` in router.ex (left @default_providers unchanged)
- Extended WebhookCase with `@resend_secret_bytes`/`@resend_secret` module attributes, symmetric env lifecycle (capture/put/restore), `mailglass_webhook_conn(:resend)` arm with correct Svix headers (svix-id, svix-timestamp, svix-signature with "v1," prefix), and `stub_resend_fixture/1`

## Task Commits

1. **Task 1: Fix async race and update plug_test :resend assertion** - `f65a7ee` (fix)
2. **Task 2: Wire :resend into plug.ex and router.ex static dispatch** - `eebf866` (feat)
3. **Task 3: Add :resend lifecycle to WebhookCase** - `396e940` (feat)

## Files Created/Modified

- `test/mailglass/tracking/endpoint_resolution_test.exs` - Changed async: true to async: false to prevent Application env race
- `test/mailglass/webhook/plug_test.exs` - Replaced assert_raise for :resend with success assertion "valid :resend provider opt survives init"
- `lib/mailglass/webhook/plug.ex` - Added :resend to @valid_providers, resolve_config!(:resend), provider_module(:resend)
- `lib/mailglass/webhook/router.ex` - Added :resend to @valid_providers
- `test/support/webhook_case.ex` - Added @resend_secret_bytes/@resend_secret, :resend env lifecycle in setup, mailglass_webhook_conn(:resend) arm, stub_resend_fixture/1, updated @spec and import list

## Decisions Made

- `svix_timestamp` generated fresh at call time inside `mailglass_webhook_conn/3` rather than as a module attribute — module attributes are compile-time constants and would cause timestamp-skew failures in production-like tolerance windows
- The `svix-signature` header value carries the `"v1,"` prefix per Svix specification; the base64 signature follows immediately after
- `secret_bytes` are derived by stripping the `"whsec_"` prefix and Base64-decoding the remainder — this is the raw HMAC key that `sign_resend_payload/4` expects

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The worktree did not have a `deps/` or `_build/` directory. Resolved by creating symlinks to the main project's `deps/` and `_build/` so `mix test` could run from the worktree. This is an infrastructure concern, not a code issue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 17-01 complete: :resend is fully wired into the dispatch chain and WebhookCase has the :resend fixtures and conn builder Plan 17-02 integration tests depend on
- `mix test test/mailglass/webhook/` passes 204 tests with 0 failures
- `mix compile --warnings-as-errors` exits clean
- Plan 17-02 (Resend integration tests) can proceed immediately

---
*Phase: 17-unblock-verify-resend*
*Completed: 2026-04-29*
