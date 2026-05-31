---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Adopter Trust Proof
status: executing
last_updated: "2026-05-31T14:10:01.517Z"
last_activity: 2026-05-29 -- Phase 60 planning complete
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 13
  completed_plans: 13
  percent: 83
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-27 after v1.3 preflight lock)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 59 — ci-trust-lanes-checkpoint-evidence

## Current Position

Phase: 999.1
Plan: Not started
Status: Ready to execute
Last activity: 2026-05-29 -- Phase 60 planning complete

## v1.3 Milestone Intent

- Establish one maintained Phoenix reference host app demonstrating install -> preview -> send -> webhook ingest -> operator troubleshooting
- Add a clean-baseline CI journey plus published-version trust proof that validates that flow
- Keep docs explicit that the reference app demonstrates usage, while API contract truth remains in core contract docs/tests
- Require one deterministic trust runner and checkpoint artifacts shared by local, CI, and release proof paths
- Preserve release-cadence rule for milestone closeout and block trust claims if smoke reliability debt remains unresolved

## v1.3 Preflight Locks

- Hybrid trust model locked: one thin committed reference host app + one clean-baseline generated trust lane
- Out-of-scope lock: no provider-matrix broadening, no `gen_smtp` transport expansion, no `SEED-003` auto-promotion in v1.3
- Deterministic ingress/operator proof lock: signed verify-first webhook path + one scripted non-happy-path diagnosis
- Risk carry-forward lock: active post-publish smoke hackney dependency failure is an explicit milestone prerequisite, not deferred cleanup

## Decisions

- Phase 58 Plan 01 uses Postmark as the representative verify-first route proof path.
- Phase 58 Plan 01 keeps `trust_runner.v1` and existing stage names while adding bounded `webhook_ingest` evidence only on non-dry-run runs.
- Phase 58 Plan 01 preserves dry-run compatibility by skipping live route proof and evidence emission in dry-run mode.
- [Phase 58]: Phase 58 Plan 02 uses the admin inbound optional gateway explain_routes/2 path to derive no-match operator evidence.
- [Phase 58]: Phase 58 Plan 02 keeps checkpoint_sha256 scoped to ordered stage/status/fixture_id rows while validating evidence separately.
- [Phase 58]: Phase 58 Plan 02 retires deferred wording after signed Postmark and no-match operator evidence are deterministic.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 52 | Trust Scope Lock + Reference Host Baseline | Thin maintained host app and strict non-goals |
| 53 | Deterministic End-to-End Trust Journey | One reproducible runner with signed ingress + operator path |
| 54 | CI Trust Lanes + Checkpoint Artifacts | Required repo-head + clean-baseline trust gates |
| 55 | Docs Boundary + Contract Positioning | Usage proof vs contract truth enforcement |
| 56 | Drift Prevention + Release-Gate Integration | Published-version trust proof + smoke debt closure |

## Performance Metrics

**Velocity:**

- v1.1 plans completed: 17 (12 product across Phases 39-42, 5 audit-gap closure across Phases 43-44)
- v1.0 plans completed: 12 (across Phases 35-38)
- Total v1.1 milestone duration: single-day blitz on 2026-05-06 (audit re-pass on 2026-05-07)

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-26:

| Category | Item | Status |
|----------|------|--------|
| seed | 003-ecosystem-integrations | dormant |

**Guardrail:** do not auto-promote `SEED-003-ecosystem-integrations` at milestone open. Re-rank against adopter-impact wedges first.
| Phase 999.1 P1 | 5 min | 2 tasks | 84 files |
| Phase 58 P01 | 10min | 2 tasks | 7 files |
| Phase 58 P02 | 7min | 2 tasks | 8 files |
| Phase 60 P04 | 1 min | 2 tasks | 3 files |
| Phase 60 P03 | 9 min | 3 tasks | 3 files |

## Accumulated Context

### Pending Todos

- Resolve post-publish smoke hackney dependency failure (`#25` captured to `.planning/todos/pending/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md`; active CI signal remains `#32`)

## Pre-existing Cleanup Backlog (Not v1.2 Scope)

`.planning/phases/` still contains 14 leftover phase directories from earlier milestones (28-38 from v0.5/v0.6/v1.0, plus `999.1-*` and `999.2-*` artifact-cleanup phases). These should have been moved into `.planning/milestones/v0.X-phases/` during their respective `/gsd-complete-milestone` runs but were not. Run `/gsd-cleanup` before active v1.3 phase execution to avoid name-collision risk.

## Session Continuity

- v0.1 through v1.0 archived in `.planning/milestones/v0.1-*` through `.planning/milestones/v1.0-*`.
- v1.1 archived in `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`, `.planning/milestones/v1.1-MILESTONE-AUDIT.md`, `.planning/milestones/v1.1-MILESTONE-AUDIT-CLOSEOUT.md`, and the per-phase tree under `.planning/milestones/v1.1-phases/`.
- v1.1 product behavior shipped on 2026-05-06: `mailglass_inbound` opened with canonical `%InboundMessage{}`, narrow router DSL, mailbox behaviour with locked outcomes, first-party Postmark + SendGrid ingress, tenant-safe replayable persistence of normalized + raw provider source, Oban-backed async execution with bounded `Task.Supervisor` fallback, canonical adoption docs, and repo-root release-proof coverage.
- v1.1 audit chain restored on 2026-05-06 across Phase 43 (recovered 39/40/41 verification, added 41 validation) and Phase 44 (recovered 42 verification, reconciled bookkeeping); audit re-ran with `status: passed`.
- v1.2 milestone opened on 2026-05-06 with 5-agent parallel research and synthesis at `.planning/research/milestone-candidates/SYNTHESIS.md`. Milestone shape: 7 phases (45-51), goal of bringing `mailglass_inbound` to outbound-equivalent production maturity — Mailgun + SES ingress, admin LiveView, DX parity (TestAssertions/MailboxCase/generators), runtime tooling (`mailglass.inbound.{doctor,replay,prune}` + ingress rate limiting + telemetry foundation), documentation, and v1.0 carry-forward debt closeout. Cloudflare Email Routing and `gen_smtp` listener deferred to v1.3 / own milestone (different transport class).
- v1.2 roadmap drafted on 2026-05-07 by `gsd-roadmapper`. All 58 v1.2 REQ-IDs mapped to exactly one phase. Note: REQUIREMENTS.md previously stated "53 total" — that was a counting error in the source; actual checkbox count is 58, now corrected.
- Conductor-style synthetic-inbound dev tool deferred to v1.2.1 (security design pass needed for dev-only enforcement and tenant-scoping on synthetic stamps).
- v1.2 shipped live on 2026-05-26 via Phase 50.5: `mailglass` 1.2.0, `mailglass_admin` 1.2.0, `mailglass_inbound` 0.2.0. Ceremony record: `.planning/phases/50.5-v1-2-release-ceremony/50.5-RELEASE-RECORD.md`.
- Phase 50.7 ran immediately after the live publish to restore planning truth, audit branch/PR backlog, and settle the publish-summary policy: `.planning/publish/*-publish-summary.json` remains tracked because `test/mailglass/stability_contract_test.exs` reads it directly.
- 2026-05-27 post-v1.2 next-step assessment recommendation:
  - **single next milestone pick:** Adopter Trust Proof (golden reference host app)
  - **ranking after that:** inbound stability lock -> synthetic inbound dev tooling -> Cloudflare forwarding recipe docs / narrow ecosystem slice -> re-evaluate `gen_smtp` listener only with clear adopter pull
  - **diminishing-returns read:** major expansion should slow after trust proof + inbound contract posture hardening
- Next step: `/gsd-new-milestone` to open the post-v1.2 planning cycle using the recommended ordering above.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 50 P02 | 3 | 2 tasks | 2 files |
| Phase 50 P03 | 5 | 3 tasks | 4 files |
| Phase 50.5 P01 | 15min | 3 tasks | 8 files | Commit A: version force + allowlist refresh |
| Phase 50.7 P01 | 20min | 5 tasks | planning + hygiene | Reconciled release-state docs, triaged branch/PR backlog, kept publish-summary snapshots tracked |
