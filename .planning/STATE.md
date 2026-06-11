---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: Brand Book Fable — A/B Brand System
status: ready_to_plan
last_updated: "2026-06-11T16:20:00.000Z"
last_activity: 2026-06-11
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 2
  completed_plans: 2
  percent: 33
stopped_at: Phase 86 complete (1/1) — ready to plan Phase 87 (logo tournament)
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-11 — v1.9 "Brand Book Fable" milestone section)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 87 — logo tournament (Phase 86 foundations complete)

## Current Position

Phase: 86 of 90 (foundations — palette, type, voice, tokens) — COMPLETE
Plan: 01 of 01 (complete)
Status: Phase 86 complete — ready to plan Phase 87
Last activity: 2026-06-11

Progress: [██░░░░] 2/6 phases (v1.9: 85-90)

## v1.9 Milestone Intent

- Build a second, fully self-contained brand book at `brandbook-fable/` to A/B
  against the frozen codex `brandbook/` baseline (commit `09a84dd4`) — and
  beat it on craft, buildability, accessibility proof, and standalone polish.

- Research-grounded: forensic codex audit + differentiation brief before any
  fable artifact is authored.

- Bounded logo tournament with a maintainer hard pause (8 options, 4 axes,
  rendered evidence, ≤2 refinement rounds, circuit breaker after two
  consecutive full-set rejections).

- Fix the v1.8 root failures: live `<text>` wordmarks (outlined paths only),
  planning-language leakage (denylist grep), dark tokens undemonstrated
  (page-level toggle re-skins every specimen), contrast never validated
  (computed WCAG matrix, rendered + scripted).

## v1.9 Scope Locks

- Only `brandbook-fable/` is written. `brandbook/` is the frozen A/B baseline;
  `mailglass_admin`, `guides/`, and the root README are untouched.

- Text artifacts only: SVG, MD, JSON, CSS, HTML. No Node toolchain, no
  binaries, no embedded fonts, no external network requests in any HTML.

- Tournament galleries, audits, and decision records live in `.planning/`,
  never inside `brandbook-fable/`.

- Locked essence: "mail you can see through", thoughtful-maintainer voice,
  glass-as-metaphor-not-gimmick. Palette/typography/logo open to justified
  evolution.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 85 | Research and Differentiation Brief | Forensic codex audit + differentiation brief (≤12 differentiators, outline, kill-list); planning artifacts only |
| 86 | Foundations — Palette, Type, Voice, Tokens | Evolve-vs-keep records, DTCG tokens.json/tokens.css (light+dark), computed WCAG contrast matrix |
| 87 | Logo Tournament | 8 pre-screened options / 4 axes, evidence gallery, HARD MAINTAINER PAUSE, ≤2 refinement rounds, outlined-path assets |
| 88 | Brand Book Assembly | Self-contained index.html (light/dark toggle, live component gallery, contrast matrix, logo section), brand-book.md, README.md |
| 89 | Collateral, Specimens, and Copy Library | landing-page/email-template HTML, README/docs/OG/diagram SVGs, copy-blocks.md, microcopy.md |
| 90 | Quality Gate and Maintainer UAT | Scripted gate (parse/link/grep/size/render), browser evidence, A/B walkthrough sign-off |

**Critical path:** 85 → 86 → 87 → 88 → 89 → 90 (strictly linear)
**Sequencing notes:** Phase 87 needs Phase 86's locked palette/type; Phase 88 needs Phase 87's promoted assets; Phase 89 slots into Phase 88's shell. Phase 87 BLOCKS on maintainer selection by design (no auto-advance past the round-1 gallery).

## Decisions

- [86-01] Dark feedback backgrounds decided and verified at first candidates: success-bg #142B22 (6.56), warning-bg #2B2314 (7.37), error-bg #2E1B1E (6.65), info-bg #11293A (11.18) — each `{kind}-text` >= 4.5:1 on its bg.
- [86-01] Worst-surface contrast figures recomputed against the SHIPPED surface set: `surface-selected` is the worst surface in both themes (dark text-muted 6.66 = AA there, AAA elsewhere); the 86-foundations-decisions.md matrix is authoritative over research worst-case quotes. border-input <3:1 on selected surfaces resolved as a usage rule (form controls never sit on selected rows).
- [v1.9] Research pre-settled (see `.planning/research/v1.9-brandbook-fable/SUMMARY.md`): DTCG-2025.10 token format (two tiers, hex strings), `--mg-*` CSS naming with `[data-theme="dark"]` reassignment, Glass #277B96 passes AA on white (4.82:1), six computed fix hexes for the four contrast failures, codex dark ramp adopted, font stacks honest about system-ui fallback, GitHub SVG rules (outlined paths, explicit hex fills, no bare currentColor in file assets).
- [D-25] v1.8 brand-system work is a repo-artifact milestone, not product expansion: all artifacts stay under `brandbook/`, no API/package code changes, no binary-heavy collateral, and prompt-era brand strategy is preserved. `572f3eb2` is a draft artifact commit, not milestone completion evidence.
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
- [80-01] Existing `brandbook/` assets are draft inputs from commit `572f3eb2`, not approved Phase 81-84 outputs.
- [80-01] `BRAND-GAP-NN` rows are stable downstream citation anchors; severity 4-5 rows require explicit closure or documented deferral before Phase 84 closeout.
- [80-01] Phase 80 approves only the audit/register gate in `brandbook/brand-audit.md`; final tokens, logos, copy, specimens, package proof, and validation scripts remain downstream work.

## Performance Metrics

**Velocity:**

- v1.9 phases completed: 2 (85-86), 2 plans; 86-01: 3 tasks, ~25min, 3 files
- v1.8 phases completed: 3 through GSD (80-82), 5 plans; phases 83-84 closed superseded 2026-06-11
- v1.7 phases completed: 6 (74-79), 22 plans — admin UI IA & design-system polish v2; audit passed (19/19 reqs, 7/7 seams, 3/3 flows); shipped 2026-06-05
- v1.6 phases completed: 3 (71-73), 6 plans, 5 tasks
- v1.5 phases completed: 4 (67-70), 8 plans, 14 tasks
- v1.4 phases completed: 4 (63-66), 12 plans, 22 tasks

## Deferred Items

Items acknowledged and deferred at the v1.7 milestone close on 2026-06-05:

| Category | Item | Status |
|----------|------|--------|
| seed | 003-ecosystem-integrations | dormant |
| uat | Phase 76 — 76-HUMAN-UAT.md (4 browser-visual scenarios) | resolved-downstream |
| verification | Phase 76 — 76-VERIFICATION.md | resolved-downstream |

Items inherited at the v1.8 close-superseded on 2026-06-11 (now owned by v1.9):

| Category | Item | Status |
|----------|------|--------|
| asset | `brandbook/` wordmark is live `<text>` in macOS-only Avenir Next | superseded-by-v1.9 (LOGO-08: outlined paths only) |
| tokens | `brandbook/tokens.json` planning-language leakage | superseded-by-v1.9 (FOUND-04, GATE-01 denylist grep) |
| a11y | contrast validation never ran in v1.8 | superseded-by-v1.9 (FOUND-03, BOOK-06, GATE-01) |
| dark | dark tokens exist but undemonstrated | superseded-by-v1.9 (BOOK-04 toggle re-skins every specimen) |

**Guardrail:** do not auto-promote `SEED-003-ecosystem-integrations` at milestone open. Re-rank against adopter-impact wedges first.

## Accumulated Context

### Roadmap Evolution

- 2026-06-11: v1.9 roadmap created. Phases 85-90, numbering continues from v1.8 (last phase 84). All 22 REQ-IDs (BRIEF/FOUND/LOGO-05..08/BOOK-04..07/COLL/COPY/GATE) mapped to exactly one phase, 100% coverage. Strictly linear critical path. Phase 87 carries a hard maintainer-selection pause with a two-rejection circuit breaker. Research pre-settled token format, contrast fixes, and SVG portability rules (`.planning/research/v1.9-brandbook-fable/SUMMARY.md`).
- 2026-06-11: v1.8 closed superseded (audit verdict gaps_found, accepted). Residual gaps inherited by v1.9; `brandbook/` frozen at `09a84dd4` as the A/B baseline.
- 2026-06-03: v1.7 milestone opened. Roadmap created for Phases 74-79. Phase numbering continues from v1.6 (last phase 73). All 19 REQ-IDs mapped to exactly one phase with 100% coverage.
- 2026-06-03 convergence posture: after v1.7, default posture returns to maintenance/quiet unless concrete adopter pull or contract gap says otherwise. v1.8/v1.9 brand milestones are repo-artifact work, not product expansion.

### Pending Todos

- Resolve post-publish smoke hackney dependency failure (`#25` captured to `.planning/todos/pending/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md`; active CI signal remains `#32`)

## Pre-existing Cleanup Backlog (Not v1.9 Scope)

`.planning/phases/` still contains leftover phase directories from earlier milestones. These should have been moved into `.planning/milestones/vX.X-phases/` during their respective `/gsd-complete-milestone` runs but were not. Run `/gsd-cleanup` before active phase execution to avoid name-collision risk.

## Session Continuity

- 2026-06-11: v1.9 roadmap created (Phases 85-90). `.planning/ROADMAP.md` rewritten for v1.9 (milestone history + 999.x backlog preserved), `.planning/REQUIREMENTS.md` traceability filled (22/22 → Phases 85-90), STATE updated. Next: `/gsd-plan-phase 85` (or `/gsd-discuss-phase 85` first).
- 2026-06-11: v1.8 closed superseded; milestone audit `gaps_found` accepted. Archives at `.planning/milestones/v1.8-*`. `brandbook/` frozen at `09a84dd4` as the codex A/B baseline. v1.9 "Brand Book Fable" opened; requirements defined (22 REQ-IDs); research synthesized under `.planning/research/v1.9-brandbook-fable/`.
- 2026-06-10: Phase 82 completed; maintainer selected `concept-07r-no-idot-02-tighter-gap` out-of-band; canonical assets promoted and brand docs rewritten around it.
- 2026-06-05: v1.7 shipped and archived (Phases 74-79, audit passed). Live versions as of 2026-06-05: `mailglass` 1.5.1 / `mailglass_admin` 1.5.1 / `mailglass_inbound` 1.3.0.
- v0.1 through v1.0 archived in `.planning/milestones/v0.1-*` through `.planning/milestones/v1.0-*`; v1.1-v1.8 likewise archived under `.planning/milestones/`.

## Operator Next Steps

- Plan the first v1.9 phase: `/gsd-plan-phase 85` (or `/gsd-discuss-phase 85` first for context-gathering)
