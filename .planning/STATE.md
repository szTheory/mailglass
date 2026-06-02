---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Inbound 1.0 Release and Truth Lock
status: Ready to plan
last_updated: "2026-06-02T07:39:46.128Z"
last_activity: 2026-06-02
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 1
  completed_plans: 1
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-02 after v1.6 milestone initialization)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 72 — Contract Docs and Stale-Claim Guards

## Current Position

Phase: 72 — Contract Docs and Stale-Claim Guards
Plan: —
Status: Ready to plan
Last activity: 2026-06-02

## v1.6 Milestone Intent

- Publish and prove the selected `mailglass_inbound` `1.0.0` release line.
- Keep inbound on its own stable `1.0` contract through `mailglass_inbound/docs/api_stability.md`.
- Preserve the matched `mailglass` / `mailglass_admin` `1.x` sibling line without forcing a core/admin release.
- Reconcile stale public release wording around inbound version, install pins, compatibility posture, fallback path, smoke evidence, Hex, and HexDocs.
- End the milestone in quiet maintenance / adopter-pull posture, not feature-growth posture.

## v1.6 Scope Locks

- No matcher expansion, lifecycle callbacks, public replay API, provider extension API, synthetic inbound UI, `gen_smtp` listener, Cloudflare recipe docs, ecosystem integrations, demo app enhancements, screenshot workflow expansion, planning-directory cleanup, or broad source hygiene.
- Provider-live checks remain advisory unless a release claim explicitly depends on them.
- Release proof must be deterministic and tied to actual package/docs/workflow evidence.

## v1.5 Milestone Intent

- Keep the existing `reference/host_app` narrow and create a separate realistic demo app.
- Prove pre-adopter confidence through seeded B2B SaaS Ops scenarios and browser-driven evidence.
- Make local click-around setup easy through Docker Compose and short quickstart docs.
- Treat the demo as adoption evidence, not a new stable Mailglass API surface.

## v1.4 Milestone Intent

- Lock `mailglass_inbound` into the same adopter-safe contract posture as core/admin without expanding feature scope.
- Reconcile the stable/testing/internal/deferred inbound inventory against shipped behavior.
- Harden contract verification through compiled-doc metadata, docs drift checks, closed atom/type proof, and root `verify.stability_contract`.
- Align inbound adoption, compatibility/deprecation, operator, testing, and admin trust docs around one precise release-ready story.
- Make an explicit release-position decision: `mailglass_inbound` `1.0.0` if the lock is real; otherwise one final explicit `0.x` confidence release.

## v1.4 Preflight Locks

- This is a stability/release-position milestone, not a feature-growth milestone.
- No matcher expansion, lifecycle callbacks, public replay API, provider extension API, worker/queue contract, synthetic inbound dev UI, ecosystem integrations, or `gen_smtp` listener work.
- Stable provider posture is documented through `MailglassInbound.Ingress.Plug` semantics/options, not public provider module APIs.
- Operator CLI semantics may be stable; internal replay/prune/doctor modules stay internal.
- Admin UI semantics may be stable; DOM, LiveView modules, components, and CSS remain internal.
- Future sessions should assume convergence after this milestone unless a concrete adopter need or contract gap says otherwise.

## Decisions

- Phase 58 Plan 01 uses Postmark as the representative verify-first route proof path.
- Phase 58 Plan 01 keeps `trust_runner.v1` and existing stage names while adding bounded `webhook_ingest` evidence only on non-dry-run runs.
- Phase 58 Plan 01 preserves dry-run compatibility by skipping live route proof and evidence emission in dry-run mode.
- [Phase 58]: Phase 58 Plan 02 uses the admin inbound optional gateway explain_routes/2 path to derive no-match operator evidence.
- [Phase 58]: Phase 58 Plan 02 keeps checkpoint_sha256 scoped to ordered stage/status/fixture_id rows while validating evidence separately.
- [Phase 58]: Phase 58 Plan 02 retires deferred wording after signed Postmark and no-match operator evidence are deterministic.
- [Phase 61]: Route trust-entry guarantee semantics to canonical api_stability inventories and mix verify.stability_contract. — Keep contract truth in canonical inventories and executable verification lanes.
- [Phase 61]: Allow internal names only with explicit implementation-detail framing in trust docs. — Preserves troubleshooting value without widening public API contract.
- [Phase 61]: Keep trust-entry docs enforcement in mailglass.docs.check with ExUnit pinning — Single deterministic seam for boundary drift.
- [Phase 61]: Allow internal names only with explicit non-contract framing in trust docs — Preserves troubleshooting value while preventing contract-overreach wording.
- [Phase 62]: Kept workflow topology unchanged; only corrected release-line truth and guard strictness. — Preserves Phase 60 clean-baseline and published-trust topology while closing the EVID-02/EVID-03 current-release proof gap.
- [Phase 62]: Accepted resolver-required lock churn for decimal, phoenix_live_view, and swoosh after scoped sibling update. — The scoped sibling update required these transitive lock updates; no workflow or product topology changed.
- [Phase 64]: Pinned inbound runtime since metadata to package release history (0.1.0/0.2.0) for compiled-doc proof truth.
- [Phase 64]: Scoped runtime seam metadata to direct adopter entrypoints only (read_body/2, __using__/1, route/2, process/1).
- [Phase 64]: Plan 64-04 enforces exact docs-to-code closed type-set parity for inbound MIME, Signature, and S3 errors.
- [Phase 64]: Plan 64-04 scopes over-claim checks to stable/adoption/unreleased prose while keeping deferred references explicitly allowed.
- [Phase 65]: README remains the canonical inbound adoption lane; inbound-install is explicitly subordinate.
- [Phase 65]: Inbound compatibility claims route through `mailglass_inbound/docs/api_stability.md` with explicit deprecation-DX inventory.
- [Phase 65]: Operator docs contract is command-semantics-only; worker/queue internals remain non-contract.
- [Phase 65]: Inbound test assertions are process-local and one-assertion-per-drive by contract wording.
- [Phase 65]: Phase 65 Plan 03 anchors compatibility routing at guides/compatibility-and-deprecations.md with inbound api_stability as stable claim source.
- [Phase 65]: Phase 65 Plan 03 keeps README as canonical inbound adoption authority and enforces install-guide subordination via docs checks.
- [Phase 65]: Plan 65-04 keeps trust-boundary enforcement in existing docs-contract and Tier 1 checker seams. — Avoids checker sprawl and preserves canonical enforcement seams.
- [Phase 65]: Plan 65-04 requires explicit replay negative-boundary wording for stored-truth/non-reroute/non-public semantics. — Prevents operator wording drift toward fresh-receive or public replay API claims.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 71 | Inbound Release Truth Preflight | Source/package truth and required-vs-advisory proof boundaries |
| 72 | Contract Docs and Stale-Claim Guards | Public wording and executable guards for inbound's own stable `1.0` contract |
| 73 | Inbound 1.0 Publish Evidence | Inbound-only publish path and Hex/HexDocs/smoke/release evidence |

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
| Phase 61 P02 | 3min | 2 tasks | 4 files |
| Phase 61 P03 | 6 min | 2 tasks | 3 files |
| Phase 62 P01 | 21 min | 2 tasks | 4 files |
| Phase 64 P01 | 2min | 2 tasks | 7 files |
| Phase 64 P04 | 18min | 2 tasks | 5 files |
| Phase 65 P02 | 24min | 2 tasks | 4 files |
| Phase 65 P03 | 26min | 2 tasks | 3 files |
| Phase 65 P04 | 13 min | 2 tasks | 3 files |
| Phase 71 P01 | 5 min | 3 tasks | 5 files |

## Accumulated Context

### Roadmap Evolution

- Phase 62 added: Close gap: EVID-02/EVID-03 — current-release trust proof
- 2026-05-31 convergence posture recorded: after the recommended inbound stability lock, default future planning should move toward maintenance / quiet release hygiene rather than broad feature expansion. See `.planning/threads/project-convergence-posture.md`.

### Pending Todos

- Resolve post-publish smoke hackney dependency failure (`#25` captured to `.planning/todos/pending/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md`; active CI signal remains `#32`)

## Pre-existing Cleanup Backlog (Not v1.2 Scope)

`.planning/phases/` still contains 14 leftover phase directories from earlier milestones (28-38 from v0.5/v0.6/v1.0, plus `999.1-*` and `999.2-*` artifact-cleanup phases). These should have been moved into `.planning/milestones/v0.X-phases/` during their respective `/gsd-complete-milestone` runs but were not. Run `/gsd-cleanup` before active v1.3 phase execution to avoid name-collision risk.

## Session Continuity

- Phase 72 context gathered on 2026-06-02 in assumptions mode with subagent research. Resume from `.planning/phases/72-contract-docs-and-stale/72-CONTEXT.md`; next step is `$gsd-plan-phase 72`.
- Phase 71 context gathered on 2026-06-02 in assumptions mode. Resume from `.planning/phases/71-inbound-release-truth-preflight/71-CONTEXT.md`; next step is `$gsd-plan-phase 71`.
- Phase 69 context gathered on 2026-06-01 in assumptions mode. Resume from `.planning/phases/69-click/69-CONTEXT.md`; next step is `$gsd-plan-phase 69`.
- Phase 68 context gathered on 2026-06-01 in assumptions mode. Resume from `.planning/phases/68-realistic-b2b-saas-fixtures/68-CONTEXT.md`; next step is `$gsd-plan-phase 68`.
- Phase 65 context gathered on 2026-05-31 in assumptions mode. Resume from `.planning/phases/65-compatibility-docs-and-dx-lock/65-CONTEXT.md`; next step is `$gsd-plan-phase 65`.
- Phase 64 completed and verified on 2026-05-31. Plans `64-01` through `64-05` executed; `64-VERIFICATION.md` passed with 10/10 must-haves verified. Next step is `$gsd-discuss-phase 65` before planning compatibility/docs/DX lock work.
- Phase 63 context gathered on 2026-05-31 in assumptions mode. Resume from `.planning/phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md`; next step is `$gsd-plan-phase 63`.
- Phase 62 completed and verified on 2026-05-31. Plan `62-01` executed; `62-VERIFICATION.md` passed with 5/5 must-haves verified. v1.3 is now milestone_complete; next step is milestone audit/closeout.
- Phase 61 completed on 2026-05-31. Plans `61-01`, `61-02`, and `61-03` executed; `61-VERIFICATION.md` passed with 9/9 must-haves verified. v1.3 is now marked milestone_complete; next step is milestone audit/closeout, not re-executing Phase 61.
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
- 2026-05-31 post-v1.3 convergence decision:
  - **current read:** core/admin are effectively product-complete for the original thesis; inbound is feature-credible but not yet contract-stable enough for the same compatibility posture.
  - **next milestone pick:** inbound stability lock, scoped to public/internal API inventory, compatibility/deprecation posture, docs guarantees, and executable stability checks.
  - **after that:** make a release-position decision (`mailglass_inbound` `1.0.0` if the contract lock is real, otherwise one final explicit `0.x` confidence release) and default to maintenance / "silence on the wire" rather than more broad roadmap growth.
  - **guardrail:** do not reopen "are we done?" every milestone; future sessions should assume convergence unless a concrete adopter need or contract gap says otherwise.
- 2026-05-31 v1.4 milestone opened:
  - **milestone:** Inbound Stability Lock
  - **requirements:** LOCK-01..03, PROOF-01..03, DX-01..04, REL-01..03
  - **phases:** 63-66
  - **next step:** discuss/plan Phase 63 before editing inbound source/docs.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 50 P02 | 3 | 2 tasks | 2 files |
| Phase 50 P03 | 5 | 3 tasks | 4 files |
| Phase 50.5 P01 | 15min | 3 tasks | 8 files | Commit A: version force + allowlist refresh |
| Phase 50.7 P01 | 20min | 5 tasks | planning + hygiene | Reconciled release-state docs, triaged branch/PR backlog, kept publish-summary snapshots tracked |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
