---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Admin UI — IA & Design-System Polish v2
status: ready_to_plan
last_updated: 2026-06-04T22:29:57.404Z
last_activity: 2026-06-04
progress:
  total_phases: 8
  completed_phases: 8
  total_plans: 28
  completed_plans: 34
  percent: 100
stopped_at: Phase 79 complete (4/4) — ready to discuss Phase 999.1
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-03 after v1.7 milestone opened)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 999.1 — human readable code comments + gsd artifact cleanup (backlog)

## Current Position

Phase: 999.1
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-04

**Progress bar:** ░░░░░░░░░░ 0% (0/6 phases)

## v1.7 Milestone Intent

- Take `mailglass_admin` to "v2 polish" by applying the existing shipped design system more completely — no new dependencies, no brand-book amendment.
- Fork A: Add an in-library Operator Overview landing (`:overview` action on existing `OperatorLive`, zero router-macro change) and generalize `orientation_strip` to all three surfaces.
- Fork B: Deliver pop/joy within the current brand book via consistent motion vocabulary, fully-expressive seed data, and sharper visual hierarchy.
- Harden design-system conformance: one unified `status_badge` atom replaces 3 disagreeing private copies; token migration off raw scale; support-card primary/secondary hierarchy.
- Self-verified closeout: screenshot→LLM-critique loop (local), structural e2e, conformance grep gate, bundle-clean gate — no human UAT.
- Release ceremony produces matched version bump across all three packages (admin-only work; core and inbound entries are administrative).

## v1.7 Scope Locks

- No new dependencies, no brand-book amendment.
- No changes to stable seams: `mailglass_operator_routes/2` router macro, `MailglassAdmin.Auth` behaviour, replay semantics, operator session contract.
- No bumping of `reference/host_app` or `reference/demo_app` mailglass version pins (frozen baselines — separate coordinated 5-file change).
- No CI-promoted visual-regression (non-deterministic pixels + unversioned `agent-browser` CLI); screenshot→LLM-critique loop stays local/ad-hoc.
- No new product/observability features in admin; this is a quality investment, not feature growth (D-23/D-24).
- Anti-churn gate: every build task (Phases 75-78) must cite a Phase 74 gap-register row at severity ≥ 3.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 74 | Systematic Audit and UI-SPEC | Evidence gate (no code): gap register, frozen UI-SPEC, canonical status-badge taxonomy, before-baseline, assertion inventory |
| 75 | Information Architecture, Navigation and Orientation | Shell-level orientation strip on all 3 surfaces; in-library Operator Overview landing; IA vocabulary; deep-link-fix decision |
| 76 | Component-Library and Design-System Hardening | Unified status_badge atom; delete 3 badge_class copies; token migration; support-card hierarchy redesign; committed bundle |
| 77 | Motion and Microinteraction Polish | Six-motion vocabulary per UI-SPEC; motion-reveal re-fire fix; reduced-motion discipline |
| 78 | Seed-Data Expressiveness | Demo seeds covering every screen state; e2e count assertions updated in same change |
| 79 | Verification and Visual-Regression Hardening | Full audit-matrix re-run vs baseline; extended e2e; conformance + bundle gates; deep-link disposition; release ceremony |

**Critical path:** 74 → 75 → 76 → 79
**Parallel:** Phase 77 (after Phase 76 structure settles); Phase 78 (parallel from Phase 74 state inventory onward)
**Sequencing note (cross-phase):** `status_badge/1` atom must land in Phase 76 before Phase 75 finalizes Inbound orientation to avoid re-touch of badge call sites.

## Decisions

- [D-24] v1.7 admin UI polish is a sanctioned adopter-visible-quality investment under D-23 convergence rule; delivered within the brand book (Fork B) by applying the shipped design system more completely, with a real in-library Operator Overview landing + generalized orientation (Fork A).
- [v1.7] Anti-churn contract: no build task ships without citing a Phase 74 gap-register row at severity ≥ 3. The gap register is the gate.
- [v1.7] Linked-version release mechanics: admin minor bump mechanically produces matched releases for core + inbound (no API change — administrative only). Acknowledged in milestone scope, not a surprise.
- [v1.7] Fork A locked: Operator Overview as a `:overview` action on existing `OperatorLive` (zero router-macro change), not a sibling LiveView. Orientation strip generalized into `Shell.orientation_strip/1`.
- [v1.7] Fork B locked: pop/joy via consistent motion + expressive seed data + sharper hierarchy within the current brand book. No brand-book amendment. No new visual loudness.
- [76-01] status_badge/1 renders icon+label with literal-string-only defp helpers for JIT safety; normalize_inbound_outcome/1 is public for cross-module import (admin-side adapter, never touches mailglass_inbound locked 1.0 schema)
- [Phase ?]: Fallback clauses added to status helpers for phantom atoms (suppressed, nil) — badge-outline per UI-SPEC Conflict 1
- [76-06] heroicons-inline.js: self-contained standalone-binary-compatible Tailwind plugin replaces Node.js-dependent heroicons.js; 12 outline SVGs embedded inline; wired via @plugin in app.css
- [77-04] Bundle-clean gate (D-08, GAP-19): mix verify.preview exits 0; priv/static/ confirmed no-op / bit-identical after Phase 77 HEEx id-attribute changes; citext_probe.ex Boundary declaration + voice_test script-strip fixed pre-existing verify.preview blockers
- [79-01] check-conformance.sh TYPE-GATE requires grep -v text-base-content (Footgun-6: DaisyUI semantic color token, not a type-scale violation; without exclusion every file using text-base-content produces a false failure)
- [79-02] replay timeline badge text: event_badge/1 returns "Replay audit" as a truthy sentinel (controls badge rendering), not the visible text; status_label(:webhook_replay_succeeded) = "Replay succeeded" is what the DOM contains; replay_event_label(:webhook_replay_succeeded) = "Webhook replay completed" is the row title
- [79-02] preview-orientation e2e: preview-orientation only renders when @mailables == []; use /ops/browser-preview-empty test route (sets mailables=[] in session) to reach this state in a test server that has explicit fixture mailables configured
- [79-03-A] Textual audit finding derived from code review; agent-browser available but demo boot causes swoosh lock drift (Pitfall 5); durable artifact is textual per D-01
- [79-03-B] GAP-22 reconfirmed permanent v1.7 DEFERRED at severity 3 per design-system.md lines 152-159; no code change
- [79-03-C] 74-GAP-REGISTER.md NOT modified; all closure evidence in 79-GAP-CLOSEOUT.md per frozen-artifact pattern

## Performance Metrics

**Velocity:**

- v1.7 phases in progress: Phase 76 all 6 plans complete (awaiting human verification checkpoint); Plans 01-06: badge component, rewire, support-card Tier1/Tier2, token migration (5 files), token migration (15 files + hex fix), bundle rebuild + heroicons-inline plugin
- v1.6 phases completed: 3 (71-73), 6 plans, 5 tasks
- v1.5 phases completed: 4 (67-70), 8 plans, 14 tasks
- v1.4 phases completed: 4 (63-66), 12 plans, 22 tasks

## Deferred Items

Items acknowledged and deferred at previous milestone close:

| Category | Item | Status |
|----------|------|--------|
| seed | 003-ecosystem-integrations | dormant |

**Guardrail:** do not auto-promote `SEED-003-ecosystem-integrations` at milestone open. Re-rank against adopter-impact wedges first.
| Phase 76-component-library-and-design-system-hardening P02 | 20 | 2 tasks | 7 files |
| Phase 77 P04 | 7 | 1 tasks | 2 files |
| Phase 79 P01 | 8 | 2 tasks | 2 files |
| Phase 79-verification-and-visual-regression-hardening P03 | 420 | 1 tasks | 1 files |
| Phase 79 P04 | 10min | 2 tasks | 1 files |

## Accumulated Context

### Roadmap Evolution

- 2026-06-03: v1.7 milestone opened. Roadmap created for Phases 74-79. Phase numbering continues from v1.6 (last phase 73). Blueprint from `/Users/jon/.claude/plans/mailglass-context-handoff-serene-noodle.md` (Fork A/B locked, anti-churn contract, stable seam constraints) mapped to ROADMAP phases. All 19 REQ-IDs mapped to exactly one phase with 100% coverage.
- 2026-06-03 convergence posture: v1.7 is the sanctioned adopter-visible-quality investment; after v1.7, default posture returns to maintenance/quiet unless concrete adopter pull or contract gap says otherwise.
- Phase 74 is an evidence-only gate: no code changes until the gap register, frozen UI-SPEC, canonical status-badge taxonomy, before-baseline screenshots, and assertion inventory are complete. All build phases (75-78) are blocked by Phase 74.
- Three open technical questions to resolve during Phase 74 execution: (1) `preview_live.ex` zero-mailables empty state trigger condition; (2) `Mailglass.Operator.Suppressions` tenant-scoped active count API availability; (3) deep-link unstyled bug explicit in/out-of-scope decision.

### Pending Todos

- Resolve post-publish smoke hackney dependency failure (`#25` captured to `.planning/todos/pending/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md`; active CI signal remains `#32`)

## Pre-existing Cleanup Backlog (Not v1.7 Scope)

`.planning/phases/` still contains leftover phase directories from earlier milestones. These should have been moved into `.planning/milestones/vX.X-phases/` during their respective `/gsd-complete-milestone` runs but were not. Run `/gsd-cleanup` before active phase execution to avoid name-collision risk.

## Session Continuity

- 2026-06-04: Phase 79 Plan 03 executed. 79-GAP-CLOSEOUT.md created — all five sev-4 rows (GAP-01/03/05/06/13) CLOSED with resolving commit SHAs; GAP-22 reconfirmed DEFERRED at severity 3; textual 6-pillar before/after audit finding; zero-open-sev-4/5 declaration. 74-GAP-REGISTER.md NOT modified. Commit: f202f1e0. VERIF-01 and VERIF-04 satisfied.
- 2026-06-04: Phase 79 Plan 02 executed. operator.spec.js extended to 10 tests (all green): fixed pre-existing "exact replay flow" failure (wrong badge text "Replay audit" → "Webhook replay completed"/"Replay succeeded" + { timeout: 10000 }); fixed operator_fixtures.ex jsonb[] cast bug blocking server boot; added operator-overview-health, operator-overview-nav, inbound-orientation, preview-orientation structural coverage; added /ops/browser-preview-empty test route for preview empty-mailables state. Commits: 629c91b0, ab14422e. VERIF-02 satisfied.
- 2026-06-04: Phase 79 Plan 01 executed. check-conformance.sh (5-gate: BADGE/TYPE/BOLD/GAP/HEX) created at mailglass_admin/scripts/; exits 0 on current codebase. design-system.md audit-loop section expanded with explicit before/after LLM-critique ritual (Phase 74 baseline, 4 GAP rows, 6-pillar rubric, /ops/mail/ IA note). 189 tests, 0 failures. Commits: 8c28352a, ef660f27. VERIF-03 satisfied.
- 2026-06-04: Phase 77 Plan 04 (last plan) executed. mix verify.preview exits 0 (189 tests, 0 failures, 2 excluded). Bundle rebuild confirmed no-op — priv/static/ bit-identical to Phase 76-06 baseline. Two pre-existing test blockers fixed: citext_probe.ex Boundary declaration, voice_test script-strip. check_motion_conformance.sh exits 0. Commit: 3390b8fe. Phase 77 complete.
- 2026-06-04: Phase 76 Plan 06 executed (awaiting human verification). All 5 conformance grep gates pass (zero real violations). heroicons-inline.js created as standalone-binary-compatible plugin; @plugin wired in app.css. Bundle rebuilt at 81780 bytes; badge-primary + all 12 hero-* icons confirmed present. 187 tests, 1 pre-existing voice_test failure. Commit: 232b4ead.
- 2026-06-04: Phase 76 Plan 03 executed. support_cards.ex Tier1/Tier2 restructure — flat xl:grid-cols-2 eliminated; Tier 1 full cards for failed_ingest (text-error), orphan_backlog (text-warning), replay outcomes (nonzero); Tier 2 compact border-t row for zero-state and suppression count. attr :suppression_count wired. Test assertions updated for new labels. 1174 tests, 1 pre-existing failure. Commits: 08c4b403, ca9c393a.
- 2026-06-04: Phase 76 Plan 05 executed. Token migration of 15 remaining admin HEEx files (components.ex, 5 inbound sub-components, inbound_live.ex, 3 operator sub-components, operator_live.ex lines 363+, 3 preview files, preview_live.ex). Hex #ffffff in preview/tabs.ex:113 replaced with var(--color-base-100). D-09 boundary enforced (operator_live.ex:279-362 untouched). 187 tests, 1 pre-existing failure. Commits: bfff1f1c, 439cc16d.
- 2026-06-04: Phase 76 Plan 01 executed. Components.status_badge/1 and Components.normalize_inbound_outcome/1 added to components.ex; 24-atom regression test created at test/mailglass_admin/components_test.exs. 30 tests, 0 failures.
- 2026-06-03: v1.7 roadmap created. Phase 74 is the next step. Run `/gsd-plan-phase 74` (or `/gsd-discuss-phase 74` first) to begin the audit + UI-SPEC evidence gate.
- NOTE: Phase 74 should consider using `/gsd-ui-phase` to produce the UI-SPEC deliverable inside the phase. The `workflow.ui_phase: true` config flag is set.
- Phase 73 completed and verified on 2026-06-02. v1.6 milestone complete. `mailglass_inbound` 1.0.0 live on Hex.
- Phase 72 completed and verified on 2026-06-02. Plans `72-01`/`72-02`/`72-03` executed.
- v0.1 through v1.0 archived in `.planning/milestones/v0.1-*` through `.planning/milestones/v1.0-*`.
- v1.1 archived in `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`, and the per-phase tree under `.planning/milestones/v1.1-phases/`.
- v1.2 shipped live on 2026-05-26 via Phase 50.5. v1.3 shipped 2026-05-31. v1.4 shipped 2026-06-01. v1.5 shipped 2026-06-02. v1.6 shipped 2026-06-02. Live versions as of 2026-06-03: `mailglass` 1.4.5 / `mailglass_admin` 1.4.5 / `mailglass_inbound` 1.1.5.

## Operator Next Steps

- 2026-06-04: Phase 79 Plan 04 executed. mailglass_inbound exact-pin updated == 1.4.5 → == 1.5.0 in mix.exs MIX_PUBLISH branch; all four Phase 79 gates confirmed green simultaneously (check-conformance.sh exits 0, Playwright 10/10, GAP-CLOSEOUT has 9 CLOSED rows, mix verify.preview 189/0/2excluded); release-ceremony posture: prepare-only, pipeline owns hex.publish. Commit: 144e037d. VERIF-04 satisfied.
- Phase 79 ALL PLANS COMPLETE. v1.7 milestone ready for /gsd-complete-milestone.
