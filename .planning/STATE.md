---
gsd_state_version: 1.0
milestone: v0.3
milestone_name: Webhook Coverage Complete
status: planning
last_updated: "2026-04-29T00:00:00.000Z"
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 5
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

**Core Value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current Focus:** Phase 16 — ses-webhook-provider-sns-cache

## Current Position

Phase: Not started (defining roadmap)
Plan: —
Status: Planning
Last activity: 2026-04-29 — Milestone v0.3 started

## Performance Metrics

- **Cycle Time:** N/A (Milestone just started)
- **Phase Completion:** N/A
- **Requirement Coverage:** 2/2 mapped (100%) — RESEND-01/02 pending verification

## Accumulated Context

### Architectural Decisions

- D-22: Webhook signature failures raise `Mailglass.SignatureError` - no recovery from forged webhooks.
- D-23: SES certificate fetching utilizes `:ets` caching via a GenServer to prevent synchronous network I/O per webhook.
- D-24: Resend signature verification uses a custom `CachingBodyReader` to preserve the raw request body.
- D-25: Mailgun replay handling stays at the provider contract boundary via `:ok | {:ok, :replay}`.
- D-26: Mailgun token replay defense uses a supervised ETS table-owner cache started from `Mailglass.Application`.
- D-27: Mailgun uses the webhook token as both replay-cache key and normalized `provider_event_id`.
- D-28: Mailgun failed-event normalization preserves raw `severity`, `reason`, `delivery-status`, and `timestamp` metadata keys alongside the normalized event type.
- D-29: Mailgun replay exits from `Mailglass.Webhook.Plug` as HTTP 200 before tenant resolution or ingest work begins.
- D-30: Mailgun is a valid webhook router provider only when adopters opt in explicitly; the default route surface stays Postmark plus SendGrid.
- D-31: `Mailglass.Webhook.Ingest` accepts Mailgun and derives durable provider event ids from the Mailgun token-backed metadata path.

### Blockers

- Full `mix test` is currently failing outside Phase 14 in `test/mailglass/tracking/endpoint_resolution_test.exs:32`

## Session Continuity

- v0.3 milestone started 2026-04-29.
- Phase 14 (Resend) implementation complete (plan 14-01 executed). Verification blocked by `test/mailglass/tracking/endpoint_resolution_test.exs:32` (unrelated to Resend).
- Phase 15 (Mailgun) complete 2026-04-29 — all 4 plans executed and verified.
- Phase 16 (SES) complete 2026-04-29 — all 4 plans executed and verified.
