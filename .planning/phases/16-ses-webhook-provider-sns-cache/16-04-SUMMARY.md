---
phase: 16-ses-webhook-provider-sns-cache
plan: "04"
subsystem: webhook
tags: [ses, sns, normalize, event-mapping, plug, router, application, supervision, docs]
dependency_graph:
  requires:
    - phase: "16-03"
      provides: "SES.verify!/3 fully implemented, normalize/2 stub"
    - phase: "16-02"
      provides: "CertCache + TrustPolicy + Supervisor/TableOwner OTP structure"
    - phase: "16-01"
      provides: "16 SNS/SES fixture files, RED-state ses_test.exs"
  provides:
    - "lib/mailglass/webhook/providers/ses.ex — normalize/2 fully implemented"
    - "lib/mailglass/webhook/plug.ex — :ses in @valid_providers, resolve_config!/2, provider_module/1, {:ok, :control_plane, outcome} branch"
    - "lib/mailglass/webhook/router.ex — :ses in @valid_providers (opt-in, not default)"
    - "lib/mailglass/application.ex — SES.CertCache.Supervisor in maybe_add chain"
    - "guides/webhooks.md — Amazon SES (via SNS) section"
  affects:
    - "Adopters mounting mailglass_webhook_routes with :ses in providers list"
tech_stack:
  added: []
  patterns:
    - "SNS double-decode normalization: decode SNS envelope, then decode Message JSON string"
    - "Fan-out per recipient (bouncedRecipients/complainedRecipients/recipients arrays)"
    - "Fan-out per mail.destination for single-recipient eventType events"
    - "Stable provider_event_id: sns_message_id:email (or :index fallback per D-16)"
    - "maybe_add/3 pattern in application.ex for optional supervisor wiring"
    - "control-plane short-circuit in do_call/3 — returns 200 before normalize/ingest"
key_files:
  created: []
  modified:
    - lib/mailglass/webhook/providers/ses.ex
    - lib/mailglass/webhook/plug.ex
    - lib/mailglass/webhook/router.ex
    - lib/mailglass/application.ex
    - guides/webhooks.md
    - test/mailglass/webhook/providers/ses_test.exs
    - test/mailglass/webhook/providers/ses/cert_cache_test.exs
    - test/mailglass/webhook/plug_test.exs
decisions:
  - "normalize/2 dispatches on notificationType (classic feedback) vs eventType (event publishing) to cover both SES delivery pipelines"
  - "Bounce Permanent with Suppressed/OnAccountSuppressionList/UnsubscribedRecipient subtypes map to :rejected/:blocked per AWS semantics"
  - "control-plane outcomes (:subscription_confirmed, :unsubscribe_confirmed) short-circuit before tenant resolution and ingest"
  - "test setup changed from start_supervised!(CertCache.Supervisor) to CertCache.reset() only — supervisor now started by Mailglass.Application"
metrics:
  duration: ~6 minutes
  completed_date: "2026-04-29"
  tasks_completed: 2
  files_created: 0
  files_modified: 8
---

# Phase 16 Plan 04: SES normalize/2 + Runtime Wiring Summary

SES event taxonomy mapping (normalize/2) with SNS double-decode, per-recipient fan-out, and full runtime wiring into the plug/router/application supervision tree — all 10 SES event types mapped to existing normalized atoms.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implement normalize/2 in ses.ex | 20df34f | lib/mailglass/webhook/providers/ses.ex |
| 2 | Wire SES into Plug, Router, Application, and webhooks guide | 3a3f3f9 | plug.ex, router.ex, application.ex, guides/webhooks.md, 3 test files |

## What Was Built

### Task 1: normalize/2 in ses.ex

Replaced the `normalize/2` stub with the full SNS double-decode normalization pipeline:

1. JSON-decode the SNS envelope (outer layer)
2. Verify `Type == "Notification"` — non-Notification types return `[]` with Logger.warning
3. JSON-decode the `Message` field (inner SES payload — double-encoded per AWS wire format)
4. Dispatch on `notificationType` (classic SES feedback) or `eventType` (SES event publishing)

**Classic feedback normalization (`notificationType`):**
- `"Bounce"` — fans out over `bouncedRecipients[]`; maps `Permanent/General -> :bounced/:bounced`, `Permanent/Suppressed -> :rejected/:blocked`, `Transient -> :deferred`, `Undetermined -> :deferred`
- `"Complaint"` — fans out over `complainedRecipients[]`, maps to `:complained`
- `"Delivery"` — fans out over `delivery.recipients[]`, maps to `:delivered`

**Event publishing normalization (`eventType`):**
- `"Bounce"` and `"Complaint"` — same fan-out and mapping as classic feedback, plus `ses_message_id` in metadata
- `"Delivery"` — fans out over `delivery.recipients[]`, maps to `:delivered`
- `"Send" -> :sent`, `"Reject" -> :rejected/:other`, `"Open" -> :opened`, `"Click" -> :clicked`, `"Rendering Failure" -> :failed`, `"DeliveryDelay" -> :deferred`
- All single-recipient types fan out over `mail.destination[]`

**Stable `provider_event_id` (D-16):** `"#{sns_message_id}:#{email}"` (email available) or `"#{sns_message_id}:#{idx}"` (index fallback).

**All metadata uses string keys and string/nil values** via `to_string_or_nil/1`.

### Task 2: Runtime Wiring

**plug.ex (4 changes):**
- `:ses` added to `@valid_providers`
- `resolve_config!(:ses, _conn)` reads `Application.get_env(:mailglass, :ses, [])` and returns `%{cert_cache_ttl_seconds: ...}`
- `provider_module(:ses)` dispatches to `Mailglass.Webhook.Providers.SES`
- `{:ok, :control_plane, outcome}` branch in `do_call/3` between `{:ok, :replay}` and `:ok` — returns 200 with `status: :control_plane` without calling normalize or ingest

**router.ex (2 changes):**
- `:ses` added to `@valid_providers`
- Moduledoc updated to reflect `:ses` as valid opt-in provider
- `@default_providers` remains `[:postmark, :sendgrid]` — SES requires explicit opt-in

**application.ex (1 change):**
- `SES.CertCache.Supervisor` added to `maybe_add` chain after `MailgunReplayCache.Supervisor`

**guides/webhooks.md:**
- Added "### Amazon SES (via SNS)" section with: setup steps (route providers, config, SNS topic, SES destination config), auto-confirmation description, duplicate-event warning (D-18), and supported events table (12 rows)

**Test fixes (Rule 1 auto-fixes):**
- `ses_test.exs` and `cert_cache_test.exs`: removed `start_supervised!(CertCache.Supervisor)` from setup — supervisor is now started by `Mailglass.Application`; tests use `CertCache.reset()` only (matching mailgun pattern)
- `plug_test.exs`: fixed "raises ArgumentError on unknown provider" test to use `:resend` instead of `:mailgun` (mailgun is now a valid provider)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test setup conflict: start_supervised! + application-started supervisor**
- **Found during:** Task 2 test run (29 failures with `{:already_started, #PID<...>}`)
- **Issue:** Plan 01 wrote `start_supervised!(CertCache.Supervisor)` in test setup because the application did not yet supervise it. Plan 04 adds it to `Mailglass.Application`, so the application starts the supervisor at test boot, and `start_supervised!` in setup then fails with `:already_started`.
- **Fix:** Removed `start_supervised!(CertCache.Supervisor)` from both `ses_test.exs` and `cert_cache_test.exs`; retained `CertCache.reset()` for test isolation. Matches the pattern used in `mailgun_test.exs`.
- **Files modified:** `test/mailglass/webhook/providers/ses_test.exs`, `test/mailglass/webhook/providers/ses/cert_cache_test.exs`
- **Commit:** 3a3f3f9

**2. [Rule 1 - Bug] plug_test.exs used :mailgun as "unknown provider" probe**
- **Found during:** Task 2 test run (1 regression in full webhook suite)
- **Issue:** `test "raises ArgumentError on unknown provider"` was using `provider: :mailgun` as the invalid provider. After adding `:mailgun` to `@valid_providers` (in Plan 15), this test stopped raising — mailgun is now valid.
- **Fix:** Changed probe to `provider: :resend` (a genuinely unknown provider atom).
- **Files modified:** `test/mailglass/webhook/plug_test.exs`
- **Commit:** 3a3f3f9

## Known Stubs

None — `normalize/2` stub replaced with full implementation. All prior stubs from Plan 03 are resolved.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. All threats from the plan's threat register are implemented:

| Threat ID | Mitigation | Status |
|-----------|------------|--------|
| T-16-04-02: PII in Logger.warning | Logger emits only event type strings and "Notification"/"SNS" context; no email addresses | Implemented |
| T-16-04-03: PII in Event.metadata | ses_message_id/sns_message_id are opaque; record_type/bounce_type are enum strings | Implemented |
| T-16-04-04: Control-plane masquerade | `{:ok, :control_plane, outcome}` branch returns 200 WITHOUT normalize or ingest | Implemented |
| T-16-04-06: :ses in @valid_providers + SubscribeURL | plug.ex wires SES module which uses D-07 constructed URL; SubscribeURL not followed | Implemented |

## Verification Results

```
mix test test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/ses/cert_cache_test.exs --warnings-as-errors
29 tests, 0 failures

mix test test/mailglass/webhook/ --warnings-as-errors
200 tests, 0 failures

mix compile --no-optional-deps --warnings-as-errors
Generated mailglass app (clean)

grep -c ":ses" lib/mailglass/webhook/plug.ex
4 (valid_providers, resolve_config!, provider_module, control-plane comment)

grep "@default_providers" lib/mailglass/webhook/router.ex
@default_providers [:postmark, :sendgrid]  # :ses not in defaults

grep "SES.CertCache.Supervisor" lib/mailglass/application.ex
2 matches (maybe_add with module + child_spec tuple)
```

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `lib/mailglass/webhook/providers/ses.ex` — normalize/2 implemented | FOUND |
| `lib/mailglass/webhook/plug.ex` — :ses in @valid_providers | FOUND |
| `lib/mailglass/webhook/plug.ex` — resolve_config!(:ses) | FOUND |
| `lib/mailglass/webhook/plug.ex` — provider_module(:ses) | FOUND |
| `lib/mailglass/webhook/plug.ex` — {:ok, :control_plane, outcome} branch | FOUND |
| `lib/mailglass/webhook/router.ex` — :ses in @valid_providers | FOUND |
| `lib/mailglass/webhook/router.ex` — :ses NOT in @default_providers | CONFIRMED |
| `lib/mailglass/application.ex` — SES.CertCache.Supervisor in maybe_add | FOUND |
| `guides/webhooks.md` — Amazon SES section | FOUND |
| Commit 20df34f (Task 1: normalize/2) | FOUND |
| Commit 3a3f3f9 (Task 2: wiring) | FOUND |
| 29 SES + CertCache tests pass | PASSED |
| 200 webhook tests pass (0 regressions) | PASSED |
| mix compile --no-optional-deps --warnings-as-errors exits 0 | PASSED |
