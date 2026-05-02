---
gsd_state_version: 1.0
milestone: v0.4
milestone_name: Operator Confidence
status: executing
last_updated: "2026-05-02T15:07:05.488Z"
last_activity: 2026-05-02 -- Phase --phase execution started
progress:
  total_phases: 8
  completed_phases: 5
  total_plans: 19
  completed_plans: 16
  percent: 84
---

# Project State

## Project Reference

**Core Value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current Focus:** Phase --phase — 26

## Current Position

Phase: --phase (26) — EXECUTING
Plan: 1 of --name
Status: Executing Phase --phase
Last activity: 2026-05-02 -- Phase --phase execution started

## Performance Metrics

- **Cycle Time:** v0.3 milestone two-day closeout (2026-04-29 start → 2026-04-30 archive)
- **Phase Completion:** 8 of 8
- **Requirement Coverage:** 10/10 — RESEND-01/02, MAILGUN-01/02/03, SES-01/02/03/04/05, DELIV-04 all Complete

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
- D-32: Phase 18 recovery pattern locked — when CI fails on a Release Please tagged commit, never re-point the tag; land `fix:` commits and let RP cut the next patch (orphan tags are acceptable historical records).

### Blockers

- (none active)

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-04-30:

| Category | Item | Status |
|----------|------|--------|
| verification | Backfill formal `VERIFICATION.md` artifacts for phases 14, 17, 18, 19, 20, and 21 | deferred |
| testing | Add plug-level SES `SubscriptionConfirmation` regression coverage | deferred |
| environment | Investigate intermittent `too_many_connections` and optional OTLP warning noise during local test runs | deferred |

### Carry-forward to next milestone

- **Issue #25** — post-publish-smoke fresh-host install crashes on missing `:hackney` (Swoosh ApiClient default in Phoenix 1.8). Recommended fix: `mix mailglass.install` writes `config :swoosh, :api_client, false` (or Finch). v0.4 candidate.
- **Issue #9** — chronic post-publish-smoke version-resolution bug. Sidestepped here via `workflow_dispatch tag=mailglass-v0.3.2`; structural fix still pending.

## Session Continuity

- v0.3 milestone started 2026-04-29.
- Phase 14 (Resend) implementation complete (plan 14-01 executed). Verification finalized by Phase 17 (plug wiring + test fix) and Phase 18 PR #20 (Plug-level integration coverage).
- Phase 15 (Mailgun) complete 2026-04-29 — all 4 plans executed and verified.
- Phase 16 (SES) complete 2026-04-29 — all 4 plans executed and verified.
- Phase 17 (Unblock & Verify Resend) complete 2026-04-29 — both plans executed.
- Phase 18 (Ship v0.3.x) complete 2026-04-29 — shipped as v0.3.2 after 3-cycle CI recovery (PRs #20, #22 → #21 / 0.3.1 orphan; #23 → #24 / 0.3.2 shipped). DELIV-04 marked Complete; smoke contract gap (Issue #25) tracked for v0.4.
- Phase 19 (SES ingest blocker closure) completed 2026-04-30 after the current full suite returned green (`20 properties, 913 tests, 0 failures, 6 skipped`).
- Phase 20 (config schema + installer surface) complete 2026-04-30.
- Phase 21 (SES-02 override paperwork closure) complete 2026-04-30.
- v0.4 Operator Confidence activated 2026-05-01.
- Phase 22 (operator data foundation) completed and verified 2026-05-01; deliveries, timeline, and suppression visibility are in place as the admin MVP foundation.
- Phase 23 (production admin mount + step-up auth) completed and verified 2026-05-01; preview and operator routes are split, the production operator mount is auth-aware, and the README now documents adopter-owned production mounting.

**Planned Phase:** 27 (release-install-closure) — 3 plans — 2026-05-02T15:07:05.474Z
