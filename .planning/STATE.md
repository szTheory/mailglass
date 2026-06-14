---
gsd_state_version: 1.0
milestone: v1.11
milestone_name: mailglass_admin Design-System Uplift
status: executing
last_updated: "2026-06-14T06:37:01.120Z"
last_activity: 2026-06-14
progress:
  total_phases: 12
  completed_phases: 4
  total_plans: 19
  completed_plans: 14
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-13 — after v1.10 "Brand Adoption" close)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 96 — research-dossier

## Current Position

Phase: 96 (research-dossier) — EXECUTING
Plan: 2 of 6
Status: Ready to execute
Last activity: 2026-06-14

## v1.11 Milestone Intent

- Re-baseline the `mailglass_admin` UI onto the canonical fable brand tokens, then
  fractally audit-and-uplift every component, component-group, and page across the
  Operator, Inbound, and Preview surfaces to award-winning quality in light + dark and
  at every width (390/768/1440) — enforced by an idempotent, research-grounded quality
  ratchet that only moves quality forward.

- Root cause being fixed: the admin's `app.css` never consumes `brandbook/tokens.css`,
  every admin border is drawn in the *accent* color (`base-300`→Ice), cards sit one
  brand-role off (`base-200`→Mist instead of `surface-raised`), and dark muted text is
  below WCAG AA. This is the "UI feels off-brand / inbound looks ugly" perception.

- Adopter-visible-quality investment under the D-23 convergence rule (like v1.7, recorded
  as D-27) — NOT feature growth. The sanctioned follow-up to the Phase 92 human-UAT todo
  "refresh outbound admin UI look and feel," broadened to all three admin surfaces.

- Front-loaded research dossier (Phase 96): Emil Kowalski motion, gov.uk IA, component-state
  matrices, dark-mode pitfalls, "thoughtful maintainer" microcopy — each ending in an
  adversarially-synthesized LOCKED DECISION block the build phases consume.

## v1.11 Scope Locks

- **Admin UI only — 3 surfaces.** Core mailglass email-template HEEx components (what
  recipients see) and `brandbook/` HTML specimens are OUT. This milestone *consumes* the
  brand book; it does not edit it. `brandbook/tokens.css` is the source of truth.

- **No new product features / operator capabilities / routes** beyond the dev-only
  component gallery (`/dev/mail/gallery`, dev live_session only — never `/ops`).

- **No core/inbound *functional* code changes.** A `mailglass_admin` minor bump
  mechanically drags matched core + inbound version bumps via linked-version releases —
  expected, administrative.

- **Release posture: prepare-only** — stage the ceremony; decide whether to cut a real
  Hex release at milestone close (v1.7 precedent).

- **Hard design constraints bind every phase:** zero Node toolchain; standalone-binary
  Tailwind v4 + vendored daisyUI/heroicons; CSS bundle rebuilt + committed
  (`git diff --exit-code priv/static/`); motion ≤300ms, ease-out, transform/opacity only,
  `prefers-reduced-motion` respected, no springs/overshoot, CSS+LiveView.JS only (no client
  JS hook); type weights only 400/700; flat elevation (border-first, no glassmorphism/bevels);
  10%-accent rule; semantic tokens only; brand constraints C-15/C-16; PII minimization
  (`mask_recipient/1`) and multi-tenant safety preserved in seed/fixture work.

- **No pixel-diff visual regression** (D-07 banned). Structural assertions gate CI; LLM
  scores gate the milestone. The "Storybook lens" is a thin dev-only LiveView (no Node Storybook).

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 94 | Token Re-Baseline onto Canonical Brand | app.css consumes `brandbook/tokens.css --mg-*` as single source of truth; fix base-300→border + base-200→surface-raised + dark muted/error/primary-content; tighten conformance gates FIRST; rebuild+commit bundle; re-verify contrast (TOKEN-01..05, RATCHET-03) |
| 95 | Audit Apparatus + Quality-Ratchet v2 | idempotent ratchet: score baseline (meet-or-beat), carried-forward GAP-NN register, structural-assertion + LLM-score layers; run 18-cell matrix for fresh baseline (RATCHET-01/02/04/05) |
| 96 | Research Dossier | parallel-subagent dossiers → LOCKED DECISIONS for motion (Emil Kowalski), IA (gov.uk), component states, dark mode, microcopy (RESEARCH-01..05) |
| 97 | Cross-Surface Component Layer | Level-1 uplift of SHARED components + dev-only gallery `/dev/mail/gallery`; UI-SPEC before, UI-REVIEW after (COMP-01..03, GALLERY-01/02) |
| 98 | Operator / Deliveries Surface | group+page/IA+responsive+flow+a11y uplift of `/ops/mail`; seed data tuned; anchors cross-surface GROUP/PAGE/RESP/FLOW/A11Y; folds CR-01/02/03 (GROUP-01, PAGE-01/02, RESP-01, FLOW-01/02, A11Y-01/02) |
| 99 | Inbound Surface | heaviest lift: inbound overview tier + RoutingTrace/EvidenceCard rework + empty/loading + text-xl→token; re-applies cross-cutting reqs to `/ops/mail/inbound` (GROUP-02/03) |
| 100 | Preview Surface | group+page/IA+responsive uplift of `/dev/mail`; dark-mode for the preview chrome (independent of previewed-email toggle); re-applies cross-cutting reqs (PAGE-03) |
| 101 | Microcopy Pass | global "thoughtful maintainer" empty/error/loading/confirmation copy across all 3 surfaces (COPY-01) |
| 102 | Motion + Micro-interaction Pass | global motion uplift within hard constraints, sourced from the 96 dossier (MOTION-01/02) |
| 103 | Verification + Idempotent Closeout | re-run matrix; close sev-4/5 GAPs; assert score baseline meets-or-beats; all gates green; produce next-run baseline; stage release prepare-only; milestone audit |

**Critical path:** 94 → 95 → 96 → 97 → {98, 99, 100 parallel} → {101, 102 parallel} → 103
**Sequencing notes:** Phase 94 tightens conformance gates FIRST so the token re-baseline can't
regress silently. Phases 98/99/100 are independent per-surface uplifts that can run in parallel
once 97 lands the shared component layer + gallery. 101 (microcopy) and 102 (motion) are global
passes that both depend on all three surfaces being settled, and can run in parallel. 103 is the
single closeout gate.

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
- [Phase ?]: [94-01] Advisory TYPE-lg/xl and TRACK-[ gates run in CI with continue-on-error until Phase 98/99 cleans known violations (D-08, RATCHET-03)
- [Phase ?]: [95-02] D-08 commit 2 satisfied: ExUnit shape/range baseline assertion green in verify.support_contract.admin before Playwright structural spec (95-03). if-false guard pattern used to keep compare_baselines/2 as defp without triggering --warnings-as-errors
- [Phase ?]: Phase 95 baseline: Radius/Color/Elevation all score 4 across all surfaces — token discipline from Phase 94 holding
- [Phase ?]: Phase 95 baseline: Preview Motion+A11y scored 2 — dark-mode absence (theme param ignored) tracked as GAP-03 sev=3
- [Phase ?]: MOTION-LD-01..14 locked: ease-out only ≤300ms per element transform/opacity only prefers-reduced-motion snaps to instant GAP-02 closes via MOTION-LD-12 focusable CTA

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

Items acknowledged and deferred at the v1.10 milestone close on 2026-06-13:

| Category | Item | Status |
|----------|------|--------|
| todo | refresh-outbound-admin-ui-look-and-feel (2026-06-13) | deferred — follow-up design-system milestone candidate (out of v1.10 scope) |
| uat | Phase 92 — 92-HUMAN-UAT.md | resolved (0 pending scenarios) |
| Phase 87 P01 | 49 minutes | 3 tasks | 12 files |
| Phase 88 P01 | 27min | 3 tasks | 4 files |
| Phase 89 P01 | 28min | 4 tasks | 10 files |
| Phase 91 P01 | 10 min | 2 tasks | 3 files |
| Phase 91 P02 | 3h 9m | 2 tasks | 71 files |
| Phase 91 P03 | 2 min | 2 tasks | 10 files |
| Phase 91 P04 | 1 min | 2 tasks | 1 files |
| Phase 92 P01 | 10 min | 3 tasks | 3 files |
| Phase 92 P02 | 38 min | 3 tasks | 4 files |
| Phase 94 P01 | 10 minutes | 2 tasks | 3 files |
| Phase 94 P02 | 5min | 1 tasks | 1 files |
| Phase 94 P03 | 6 | 3 tasks | 5 files |
| Phase 95 P02 | 10 minutes | 2 tasks | 3 files |
| Phase 95 P03 | 15 minutes | 1 tasks | 1 files |
| Phase 95 P04 | 600 | 3 tasks | 3 files |
| Phase 96 P01 | 18 | 1 tasks | 1 files |

## Accumulated Context

### Roadmap Evolution

- 2026-06-13: v1.11 roadmap created. Phases 94-103, numbering continues from v1.10 (last phase 93). All 34 REQ-IDs mapped to exactly one phase, 100% coverage (TOKEN-01..05 + RATCHET-03 → 94; RATCHET-01/02/04/05 → 95; RESEARCH-01..05 → 96; COMP-01..03 + GALLERY-01/02 → 97; cross-surface GROUP-01/PAGE-01/02/RESP-01/FLOW-01/02/A11Y-01/02 anchored on operator → 98; GROUP-02/03 → 99; PAGE-03 → 100; COPY-01 → 101; MOTION-01/02 → 102; 103 is closeout-only). Critical path 94 → 95 → 96 → 97 → {98,99,100 parallel} → {101,102 parallel} → 103. Cross-cutting GROUP/PAGE/RESP/FLOW/A11Y reqs counted once at their operator anchor (98) and re-applied per-surface on 99/100. Phase 94 tightens conformance gates FIRST (tighten-then-re-baseline) so the token re-baseline can't regress silently. Release prepare-only; admin-minor bump drags matched core+inbound via linked-version releases.
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

- 2026-06-14: Phase 96 Plan 01 completed. MOTION.md dossier created at `.planning/research/v1.11/MOTION.md` with 14 MOTION-LD-NN locked decisions (MOTION-LD-01..14). Decisions lock: ease-out only for unidirectional transitions, ≤300ms per element, transform/opacity only (color permitted at fast token for state layers), prefers-reduced-motion snaps all transitions to instant, mount-trigger via phx-mounted/LiveView.JS only. MOTION-LD-12 provides the GAP-02 downstream close signal (preview empty-state focusable CTA). RESEARCH-01 marked complete. Next: execute 96-02 (IA dossier).
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

- Start the next milestone with /gsd-new-milestone
