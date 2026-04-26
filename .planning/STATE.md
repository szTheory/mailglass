---
gsd_state_version: 1.0
milestone: v0.2
milestone_name: Production-Credible Core
status: planning
stopped_at: "v0.2 milestone started — defining requirements"
last_updated: "2026-04-26T20:00:00.000Z"
last_activity: 2026-04-26
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-26 — v0.2 "Production-Credible Core" started)

**Core value:** Email you can see, audit, and trust before it ships.
**Current focus:** v0.2 — lock public API for downstream OSS deps + ship deliverability floor (RFC 8058 + auto-suppression) + close v0.1.1 release-engineering debt.

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-04-26 — Milestone v0.2 started

## Milestone Spec (v0.2)

**Goal:** Lock mailglass's public API for downstream OSS dependencies, ship the RFC 8058 + auto-suppression deliverability floor that makes "batteries-included" load-bearing, and close v0.1.1 release-engineering debt so the publish pipeline is trustworthy for sibling-version coordinated releases.

**Three pillars:**

- **API stability** — Mailable redesign hides Swoosh; native `Mailglass.Message` field setters; `update_swoosh/2` retained as documented escape hatch; `api_stability.md` v2; `mix mailglass.upgrade.v0_2` codemod; deprecation warnings on v0.1 paths.
- **Deliverability floor** — Message-stream separation enforced; RFC 8058 List-Unsubscribe runtime + signed-token unsub controller; auto-suppression on bounce/complaint/unsubscribe + soft-bounce escalation; stable Feedback-ID format.
- **Release-engineering hardening** — Close 9 v0.1.2 TODOs; re-tighten Tests gate to halt-on-failure; Credo `--strict`; Dialyzer `--halt-exit-status` triage budget.

**Phase shape:** 6 phases (Phase 8 → Phase 13), continuing numbering from v0.1's last phase 07.1. Plan count estimate: 30–40.

**Driving constraint:** Other OSS libraries (e.g. `accrue`) about to depend on mailglass. Locking public API NOW is the highest-leverage move.

## What's Live on Hex.pm (from v0.1)

- ✅ `mailglass` 0.1.0 — https://hex.pm/packages/mailglass/0.1.0
- ✅ `mailglass` 0.1.1 — https://hex.pm/packages/mailglass/0.1.1
- ✅ `mailglass_admin` 0.1.0 — https://hex.pm/packages/mailglass_admin/0.1.0
- ✅ `mailglass_admin` 0.1.1 — https://hex.pm/packages/mailglass_admin/0.1.1
- ✅ HexDocs at https://hexdocs.pm/mailglass/0.1.1/ and /mailglass_admin/0.1.1/

## v0.1 Milestone Archive

Full archive: [`.planning/milestones/v0.1-ROADMAP.md`](milestones/v0.1-ROADMAP.md)

Headlines:

- 8 phases (7 planned + 1 inserted), 61 plans
- 84/84 v1 REQ-IDs satisfied
- 319 commits, ~33k LOC of Elixir
- Timeline: 2026-04-21 → 2026-04-26 (6 days)
- Phase 07.1 inserted to close installer blockers G-1..G-5 + ship to Hex.pm

## Pending v0.1.2 TODOs (folded into v0.2 Phase 8 — Release-Engineering Hardening)

Captured in `.planning/todos/pending/`:

1. `2026-04-26-exclude-claude-md-from-hexdocs.md` — drop CLAUDE.md from `mix.exs:262` extras + `mix.exs:265` Overview group
2. `2026-04-26-add-installer-goldens-to-publish-check.md` — wire installer golden test into `mix mailglass.publish.check`
3. `2026-04-26-publish-hex-workflow-run-gate-cant-detect-tag-creation.md` — switch publish-hex.yml to tag-push trigger
4. `2026-04-26-post-publish-smoke-version-resolution-bug.md` — fix VERSION resolution; consolidates with #3
5. `2026-04-26-rename-verify-phase-nn-aliases-to-semantic-names.md` — `verify.phase_07` → `verify.installer` etc.
6. `2026-04-26-mailable-api-too-much-swoosh-leakage.md` — adopter feedback; **scoped into v0.2 Phase 9 (API redesign)**
7. `2026-04-26-release-please-extra-files-no-op-on-managed-mix-exs.md` — Path 2 sed step is the working mitigation; consolidate fix or document permanently
8. `2026-04-26-advisory-matrix-failing-db-setup-and-1-17-compat.md` — Advisory Matrix CI cell
9. `2026-04-26-strip-internal-decision-ids-from-public-guides.md` — internal D-NN/LINT-NN ID hygiene

Older v0.1.1 polish items folded into v0.2 Phase 8:

- Sandbox + Task.Supervisor test isolation cleanup (re-tighten Tests gate from `continue-on-error: true` to halt-on-failure)
- Credo `strict: true` (currently false)
- Dialyzer `--halt-exit-status` (currently advisory; ~230 type findings)
- Managed-snippet drift detection in installer manifest (2 skipped install_idempotency tests)
- Re-batch the 6 closed Dependabot PRs

## Verification Commands (v0.1 + v0.2 targets)

```sh
# v0.1 (currently shipped)
mix hex.info mailglass 0.1.1
mix hex.info mailglass_admin 0.1.1
curl -fsI https://hexdocs.pm/mailglass/0.1.1/
curl -fsI https://hexdocs.pm/mailglass_admin/0.1.1/

# v0.2 (target — populated when Phase 13 ships)
# mix hex.info mailglass 0.2.0
# mix hex.info mailglass_admin 0.2.0
```

## Accumulated Context

### Decisions

D-01..D-21 logged in PROJECT.md Key Decisions table with v0.1 outcomes. D-21 (adapter call between Multi#1 and Multi#2) added during Phase 3 execution.

v0.2 will likely add:

- D-22: Mailable API public surface freeze policy (api_stability.md v2)
- D-23: Stream policy enforcement boundary (compile-time vs runtime)
- D-24: Auto-suppression idempotency strategy (Multi step inside webhook ingest vs separate worker)

D-14 amended once during v0.1: `:reconciled` is `@mailglass_internal_types` (audit-only), never emitted by provider mappers.

### Roadmap Evolution

- 2026-04-26 — v0.1 milestone complete (8 phases, 61 plans, 2026-04-21 → 2026-04-26).
- 2026-04-25 — Phase 07.1 inserted after Phase 7 to ship to Hex.pm + close installer blockers G-1..G-5.
- 2026-04-26 — v0.2 milestone "Production-Credible Core" started; phase numbering continues from 07.1 → Phase 8.

### Pending Todos

See `.planning/todos/pending/` directory (9 items, all folded into v0.2 Phase 8 except the Mailable-API-leakage TODO which is folded into Phase 9).

### Blockers/Concerns

- **Premailex (MEDIUM-confidence dep)**: last release Jan 2025, no credible replacement. Flag as "watch this dep" through v0.5; revisit at v0.5 retro.
- **`mailglass_inbound` deferred to v0.5+**: shares webhook plumbing with v0.5 deliverability work; intentionally not in v0.2 roadmap.
- **Downstream OSS deps about to pin**: `accrue` and other szTheory libs are about to depend on mailglass — public API breakage after v0.2 multiplies cost across pinners. Phase 9 (API redesign) is the highest-leverage v0.2 phase.

## Deferred Items (post-v0.2)

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Webhook coverage | DELIV-04 — Mailgun + SES + Resend webhook providers | Deferred to v0.3 | 2026-04-26 |
| Prod admin | DELIV-05 — prod-mountable admin LiveView | Deferred to v0.5 | 2026-04-26 |
| Deliverability tooling | DELIV-06 — `mix mail.doctor` (DNS checks) | Deferred to v0.5 | 2026-04-26 |
| Multi-ESP | DELIV-07 — per-tenant adapter resolver | Deferred to v0.5 | 2026-04-26 |
| Cluster ops | DELIV-08 — cluster-coordinated rate limit via `:pg` | Deferred to v0.5 | 2026-04-26 |
| Self-hosted SMTP | DELIV-09 — DKIM signing helper | Deferred to v0.5 | 2026-04-26 |
| Inbound | INBOUND-01..07 — `mailglass_inbound` sibling package | Deferred to v0.5+ | 2026-04-26 |

## Session Continuity

Last session: 2026-04-26T20:00:00Z
Stopped at: v0.2 milestone started — defining requirements
Resume file: None — continue with `/gsd-new-milestone` workflow (requirements + roadmap)

**Next action:** Define REQUIREMENTS.md, then run roadmapper for phases 8–13.
