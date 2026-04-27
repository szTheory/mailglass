---
gsd_state_version: 1.0
milestone: v0.2
milestone_name: Production-Credible Core
status: planning
stopped_at: Completed 10-05-PLAN.md
last_updated: "2026-04-27T21:25:21.559Z"
last_activity: 2026-04-27
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 16
  completed_plans: 16
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-26 — v0.2 "Production-Credible Core" started)

**Core value:** Email you can see, audit, and trust before it ships.
**Current focus:** Phase 08 — release-engineering-hardening

## Current Position

Phase: 9
Plan: Not started
Status: Ready to plan
Last activity: 2026-04-27

Progress: [██████████] 100%

## Milestone Spec (v0.2)

**Three pillars:**

- **API stability** — Mailable redesign hides Swoosh; native Message field setters; `update_swoosh/2` as documented escape hatch; `api_stability.md` v2; `mix mailglass.upgrade.v0_2` Igniter codemod; deprecation warnings on v0.1 paths.
- **Deliverability floor** — Stream separation enforced (compile + runtime); RFC 8058 List-Unsubscribe atomic header injection + signed-token controller; auto-suppression on bounce/complaint/unsubscribe + soft-bounce escalation; stream-aware Feedback-ID.
- **Release-engineering hardening** — Close 9 v0.1.2 TODOs; Tests gate halt-on-failure; Credo --strict; Dialyzer triage (remove --ignore-exit-status — subtraction, not addition).

**Phase shape:** 6 phases (8–13), ~37 plans.

## Accumulated Context

### Decisions

D-01..D-21 logged in PROJECT.md Key Decisions. v0.2 decisions pending:

- D-22: Mailable API public surface freeze policy (api_stability.md v2) — to be logged at Phase 9
- D-23: Stream policy enforcement boundary (compile + runtime both required per AF-V2-08) — Phase 10
- D-24: Auto-suppression idempotency (Multi.run inside webhook ingest, on_conflict: :nothing) — Phase 12
- Introduced Message.build/2 internally to sidestep the deprecation warning on Message.new/2.
- D-22: Replaced Swoosh.Email import with Mailglass.Message in the Mailable macro, restricting to 8 native setters to prevent namespace pollution.
- Used source code scanning instead of Code.Typespecs API for the stability script to reliably detect Swoosh.Email.t() leaks.
- Declared update_swoosh/2 as the official escape hatch for advanced Swoosh functionality.
- Promised 'freeze-until-vNext' for the v0.2 milestone.
- Valid streams are strictly closed to :transactional, :operational, and :bulk.
- Enforce stream atom validity at compile-time via new_from_use/2 and runtime via put_stream/2.
- Return {:error, %StreamPolicyError{}} for invalid streams instead of raising, enabling seamless integration into with macro pipelines.
- Mitigated T-10-02 by explicitly requiring a mailable for the :bulk stream to ensure auditability.

### Key Corrections (propagate into phase plans)

- **Dialyzer flag**: REMOVE `--ignore-exit-status` from CI. Do NOT add `--halt-exit-status` (does not exist in Dialyxir). Default `mix dialyzer` already halts on warnings.
- **Publish trigger**: Use `on: release: types: [published]`, NOT `on: push: tags:` (double-publish on rerun).
- **Multi ordering**: Event row MUST be FIRST in webhook ingest Multi; suppression insert follows (never precedes).
- **Unsubscribe controller**: Belongs in `mailglass` core (Phoenix.Controller is a hard dep); NOT in `mailglass_admin`.
- **Mailable injection site**: Single-line removal at `lib/mailglass/mailable.ex:129`.

### Blockers/Concerns

- **release-please-action v5.0.0** (released 2026-04-22): Elixir release-type continuity not yet confirmed (MEDIUM confidence) — evaluate on a branch in Phase 8.
- **SendGrid DKIM h= gap** (GitHub issue #893): `List-Unsubscribe-Post` historically omitted from `h=`; Phase 11 guide must cover per-ESP verification.
- **Soft-bounce event type**: Anymail maps soft bounces as `:deferred`, not `:bounced` with soft subtype — Phase 12 must audit v0.1 Postmark/SendGrid mappers before implementing escalation.
- **Downstream OSS deps about to pin**: `accrue` and other szTheory libs — Phase 9 (API redesign) is the highest-leverage phase; no breaking changes after v0.2.

## Roadmap Evolution

- 2026-04-26 — v0.1 milestone complete (8 phases, 61 plans, 2026-04-21 → 2026-04-26).
- 2026-04-26 — v0.2 milestone "Production-Credible Core" started; phase numbering continues 07.1 → Phase 8.
- 2026-04-26 — v0.2 roadmap created: 6 phases (8–13), ~37 plans, 38/38 REQ-IDs mapped.

## Session Continuity

Last session: 2026-04-27T21:25:21.555Z
Stopped at: Completed 10-05-PLAN.md
Resume: `/gsd-plan-phase 8`

**Planned Phase:** 08 (Release-Engineering Hardening) — 6 plans — 2026-04-27T02:26:05.655Z
