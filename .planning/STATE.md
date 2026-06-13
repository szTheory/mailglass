---
gsd_state_version: 1.0
milestone: v1.10
milestone_name: Brand Adoption
status: ready_to_plan
last_updated: 2026-06-13T14:51:18.711Z
last_activity: 2026-06-13
progress:
  total_phases: 11
  completed_phases: 5
  total_plans: 15
  completed_plans: 15
  percent: 45
stopped_at: Phase 93 complete (3/3) — ready to discuss Phase 999.1
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-12 — v1.10 "Brand Adoption" milestone section)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 999.1 — human readable code comments + gsd artifact cleanup

## Current Position

Phase: 999.1
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-13

Progress: [██████████] 100%

## v1.10 Milestone Intent

- Make the A/B-winning fable brand the project's one canonical identity
  everywhere it shows: adopt it as canonical `brandbook/` (deleting the codex
  book from the active tree; history preserves it at frozen baseline `09a84dd4`), propagate
  the sealed-flap identity to the root README and the repo social preview, and
  wire HexDocs/ex_doc logos for all three packages.

- Mostly mechanical adoption work — research pre-settled the mechanics
  (`.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`): ex_doc
  0.40.1 logo/favicon semantics, release-please trigger safety, the Playwright
  og-card export command, and an exhaustive reference sweep (CLAUDE.md +
  `mailglass_admin/docs/design-system.md` are the only tracked pointers).

- Release hardening rides along (RELH): release-please must never again cut a
  release from brand/planning-only commits, and the 1.6.x release aftermath
  gets reconciled to final version truth.

## v1.10 Scope Locks

- No Hex release is cut by this milestone's commits: brand/docs commits use
  non-release-triggering types (`docs:`, `chore:`, `test:`); the HexDocs
  wiring ships with the next natural release.

- The sealed-flap usage rules and constraints C-15/C-16
  (`.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`)
  are binding on every propagated surface.

- Binary additions limited to the single og-card PNG export.

- Planning archives (`.planning/milestones/`) are never edited.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 91 | Folder Adoption and Reference Reconciliation | fable artifacts adopted as canonical `brandbook/`, codex removal, CLAUDE.md + design-system.md pointer updates, gate.sh re-pass on the new path (FOLD-01..03) |
| 92 | Surface Propagation | README brand header, og-card PNG export (2400×1260) + Settings-UI upload doc, admin wordmark swap-or-defer disposition (SURF-01..03) |
| 93 | HexDocs Wiring and Release Hardening | SVG width/height attrs, ex_doc logo/favicon config ×3 + local `mix docs` proof, release-please path hardening, 1.6.x aftermath reconciliation (HEXD-01..02, RELH-01..02) |

**Critical path:** 91 → 92 → 93 (strictly linear)
**Sequencing notes:** Phases 92/93 reference the post-rename `brandbook/` paths, so 91 must land first. RELH-02 (1.6.x aftermath reconciliation) depends on the in-flight release train settling — potentially blocked-on-external at Phase 93 execution time; record the blocker rather than guessing final version truth.

## Decisions

- [92-01] Root README uses `brandbook/examples/readme-header.svg` directly as the first visible brand surface.
- [92-01] `brandbook/examples/og-card.png` is the only committed v1.10 binary exception for GitHub social preview upload.
- [92-01] GitHub social-preview upload remains manual because no documented write API exists.
- [92-02] Admin logo rendering uses inline `currentColor` SVG so the sealed-flap lockup inherits light/dark admin chrome color while the stable `logo.svg` route remains served.
- [92-02] The admin CSS bundle is committed when `mix verify.preview` rebuilds `priv/static/app.css`, because the gate requires bundle-clean output.
- [v1.10] Active brand voice and visual identity source is now `brandbook/brand-book.md`; prompt-era brand research remains preserved as provenance, not as an active source pointer.
- [v1.10] Research pre-settled (see `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`): ex_doc 0.40.1 supports SVG logo/favicon but requires explicit width/height attrs (fable SVGs are viewBox-only — must add); use relative paths into canonical `brandbook/` (no per-package copies, no `files:` allowlist change); `docs:`/`chore:` commits are release-safe under release-please defaults; GitHub social preview is Settings-UI-only (no write API); og-card export via `npx playwright screenshot --viewport-size=2400,1260`; CLAUDE.md + `mailglass_admin/docs/design-system.md:5` are the only tracked reference-sweep targets.
- [v1.10] HexDocs latency accepted: `logo:`/`favicon:` wiring is inert on hexdocs.pm until the next natural release of each package — this milestone does not force a release to make logos visible.
- [86-01] Dark feedback backgrounds decided and verified at first candidates: success-bg #142B22 (6.56), warning-bg #2B2314 (7.37), error-bg #2E1B1E (6.65), info-bg #11293A (11.18) — each `{kind}-text` >= 4.5:1 on its bg.
- [86-01] Worst-surface contrast figures recomputed against the SHIPPED surface set: `surface-selected` is the worst surface in both themes (dark text-muted 6.66 = AA there, AAA elsewhere); the 86-foundations-decisions.md matrix is authoritative over research worst-case quotes. border-input <3:1 on selected surfaces resolved as a usage rule (form controls never sit on selected rows).
- [v1.9] Research pre-settled in the fable brandbook research summary: DTCG-2025.10 token format (two tiers, hex strings), `--mg-*` CSS naming with `[data-theme="dark"]` reassignment, Glass #277B96 passes AA on white (4.82:1), six computed fix hexes for the four contrast failures, codex dark ramp adopted, font stacks honest about system-ui fallback, GitHub SVG rules (outlined paths, explicit hex fills, no bare currentColor in file assets).
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
- [Phase 87]: 87-01: one shared LOGO-CRAFT glyph library underpins all round-1 wordmarks; the eight concepts are independent
- [88-01]: favicon scale chips drawn inline with explicit fills — img obeys OS prefers-color-scheme, not the page toggle
- [88-01]: page marks drawn from live tokens (pane=text, seal=accent) reproducing the logo color program in both themes
- [Phase 89]: readme-header fills restricted to Glass+Slate — the only token pair >=3:1 on both GitHub grounds (computed 4.82/3.93, 5.47/3.46)
- [Phase 89]: Diagram labels use a purpose-built 14-glyph stencil set, not wordmark glyphs — label craft kept distinct from wordmark craft

## Performance Metrics

**Velocity:**

- v1.9 phases completed: 6 (85-90), 7 plans — shipped 2026-06-12, gate 9/9 first run, maintainer A/B sign-off
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
| Phase 87 P01 | 49 minutes | 3 tasks | 12 files |
| Phase 88 P01 | 27min | 3 tasks | 4 files |
| Phase 89 P01 | 28min | 4 tasks | 10 files |
| Phase 91 P01 | 10 min | 2 tasks | 3 files |
| Phase 91 P02 | 3h 9m | 2 tasks | 71 files |
| Phase 91 P03 | 2 min | 2 tasks | 10 files |
| Phase 91 P04 | 1 min | 2 tasks | 1 files |
| Phase 92 P01 | 10 min | 3 tasks | 3 files |
| Phase 92 P02 | 38 min | 3 tasks | 4 files |

## Accumulated Context

### Roadmap Evolution

- 2026-06-12: v1.10 roadmap created. Phases 91-93, numbering continues from v1.9 (last phase 90). All 10 REQ-IDs (FOLD-01..03 → 91, SURF-01..03 → 92, HEXD-01..02 + RELH-01..02 → 93) mapped to exactly one phase, 100% coverage. Strictly linear critical path 91 → 92 → 93. RELH-02 flagged potentially blocked-on-external (in-flight release train must settle). Adoption mechanics pre-settled in `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`.
- 2026-06-11: v1.9 roadmap created. Phases 85-90, numbering continues from v1.8 (last phase 84). All 22 REQ-IDs (BRIEF/FOUND/LOGO-05..08/BOOK-04..07/COLL/COPY/GATE) mapped to exactly one phase, 100% coverage. Strictly linear critical path. Phase 87 carries a hard maintainer-selection pause with a two-rejection circuit breaker. Research pre-settled token format, contrast fixes, and SVG portability rules in the fable brandbook research summary.
- 2026-06-11: v1.8 closed superseded (audit verdict gaps_found, accepted). Residual gaps inherited by v1.9; `brandbook/` frozen at `09a84dd4` as the A/B baseline.
- 2026-06-03: v1.7 milestone opened. Roadmap created for Phases 74-79. Phase numbering continues from v1.6 (last phase 73). All 19 REQ-IDs mapped to exactly one phase with 100% coverage.
- 2026-06-03 convergence posture: after v1.7, default posture returns to maintenance/quiet unless concrete adopter pull or contract gap says otherwise. v1.8/v1.9 brand milestones are repo-artifact work, not product expansion.

### Pending Todos

- Refresh outbound admin UI look and feel (`.planning/todos/pending/2026-06-13-refresh-outbound-admin-ui-look-and-feel.md`) — follow-up design-system milestone candidate from Phase 92 human UAT.

## Pre-existing Cleanup Backlog (Not v1.10 Scope)

`.planning/phases/` still contains leftover backlog phase directories (999.1, 999.2) from earlier milestones. Run `/gsd-cleanup` before active phase execution if name-collision risk appears.

## Session Continuity

- 2026-06-13: RELH-02 reconciliation complete (93-03). Live Hex was authoritative at 1.6.2/1.6.2/1.3.1 (published 2026-06-12); the release-state memory was CORRECT; the in-repo state (1.6.1/1.6.1/1.3.0) was STALE. In-repo manifest + @version + dep pins advanced to 1.6.2/1.6.2/1.3.1 via non-bumping chore(release): commit. Remote 1.6.x tags fetched and kept (fetch+KEEP disposition; these are real published releases, do NOT delete). Harmless linked-version quirk: mailglass_admin-v1.6.1 tag exists on origin but admin 1.6.1 was never published to Hex (linked-version release PR tagged both; admin Hex publish failed/skipped; admin jumped 1.5.1 → 1.6.2). Current confirmed versions: mailglass 1.6.2 / mailglass_admin 1.6.2 / mailglass_inbound 1.3.1.
- 2026-06-13: Phase 93 context gathered in assumptions mode. Decisions captured in `.planning/phases/93-hexdocs-wiring-and-release-hardening/93-CONTEXT.md`; audit in the sibling `93-DISCUSSION-LOG.md`. Two judgment calls confirmed at recommended: RELH-01 hardens via an enforced CI commit-type lint (guarding `brandbook/`/`.planning/`/`prompts/`), RELH-02 investigates Hex live before reconciling (version truth contradictory: in-repo manifest+mix.exs+pin say 1.6.1/1.6.1/1.3.0, memory says 1.6.2/1.6.2/1.3.1, no local 1.6.x package tags). Mechanics pre-settled in ADOPTION-MECHANICS.md. Next: `/gsd-plan-phase 93`.
- 2026-06-13: Plan 92-02 completed. The admin placeholder wordmark is replaced with the sealed-flap outlined `currentColor` asset, `Components.logo/1` renders the lockup inline for theme-safe admin chrome, logo bundle tests ban live text/font dependencies, and `cd mailglass_admin && mix verify.preview` passed. Phase 92 is complete; next: plan/execute Phase 93 for HexDocs wiring and release hardening.
- 2026-06-13: Plan 92-01 completed. README now displays `brandbook/examples/readme-header.svg`, `brandbook/examples/og-card.png` is committed at 2400x1260 and 59,562 bytes, and `brandbook/README.md` documents the manual GitHub Settings > Social preview upload path. Next: execute 92-02 for the admin wordmark surface.
- 2026-06-13: Phase 92 UI-SPEC approved in `.planning/phases/92-surface-propagation/92-UI-SPEC.md`; 6/6 UI checker dimensions passed with no recommendations. Next: `/gsd-plan-phase 92`.
- 2026-06-12: Phase 92 context gathered in assumptions mode. Decisions captured in `.planning/phases/92-surface-propagation/92-CONTEXT.md`; discussion audit in `.planning/phases/92-surface-propagation/92-DISCUSSION-LOG.md`. Next: `/gsd-plan-phase 92`.
- 2026-06-12: Phase 91 planning complete. Research, validation, pattern map, and four executable plans were created under `.planning/phases/91-folder-adoption-and-reference-reconciliation/`; plan-checker passed after revisions for research resolution, validation map alignment, pattern references, and D-10 diff-scope proof. Next: `/gsd-execute-phase 91`.
- 2026-06-12: Phase 91 context gathered in assumptions mode with explicit subagent research. Decisions captured in `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-CONTEXT.md`; discussion audit in `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-DISCUSSION-LOG.md`. Next: `/gsd-plan-phase 91`.
- 2026-06-12: v1.10 roadmap created (Phases 91-93). `.planning/ROADMAP.md` rewritten for v1.10 (milestone history, v1.9 collapsed details, and 999.x backlog preserved), `.planning/REQUIREMENTS.md` traceability filled (10/10 → Phases 91-93), STATE updated. Next: `/gsd-plan-phase 91` (or `/gsd-discuss-phase 91` first).
- 2026-06-12: v1.9 shipped (Phases 85-90; gate 9/9 first run, maintainer A/B sign-off). v1.10 "Brand Adoption" opened; requirements defined (10 REQ-IDs); adoption mechanics researched under `.planning/research/v1.10-brand-adoption/`.
- 2026-06-11: v1.8 closed superseded; milestone audit `gaps_found` accepted. Archives at `.planning/milestones/v1.8-*`. `brandbook/` frozen at `09a84dd4` as the codex A/B baseline. v1.9 "Brand Book Fable" opened; requirements defined (22 REQ-IDs); research synthesized for the fable brandbook milestone.
- 2026-06-10: Phase 82 completed; maintainer selected `concept-07r-no-idot-02-tighter-gap` out-of-band; canonical assets promoted and brand docs rewritten around it.
- 2026-06-05: v1.7 shipped and archived (Phases 74-79, audit passed). Live versions as of 2026-06-05: `mailglass` 1.5.1 / `mailglass_admin` 1.5.1 / `mailglass_inbound` 1.3.0.
- v0.1 through v1.0 archived in `.planning/milestones/v0.1-*` through `.planning/milestones/v1.0-*`; v1.1-v1.8 likewise archived under `.planning/milestones/`.

## Operator Next Steps

- Plan or execute Phase 93 for HEXD-01, HEXD-02, RELH-01, and RELH-02.
