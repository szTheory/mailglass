# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** - Phases 1-7 + 07.1 (shipped 2026-04-26) - see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** - Phases 8-13 (shipped 2026-04-28) - see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** - Phases 14-21 (shipped 2026-04-30) - see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** - Phases 22-27 (shipped 2026-05-02) - see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** - Phases 28-31 (shipped 2026-05-03) - see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** - Phases 32-34 (shipped 2026-05-05) - see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** - Phases 35-38 (shipped 2026-05-06) - see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** - Phases 39-44 (shipped 2026-05-06) - see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** - Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) - see [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Adopter Trust Proof** - Phases 52, 57-62 (shipped 2026-05-31) - see [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Inbound Stability Lock** - Phases 63-66 (shipped 2026-06-01) - see [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Demo Evidence and Click-Around Confidence** - Phases 67-70 (shipped 2026-06-02) - see [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Inbound 1.0 Release and Truth Lock** - Phases 71-73 (shipped 2026-06-02) - see [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 Admin UI - IA & Design-System Polish v2** - Phases 74-79 (shipped 2026-06-05) - see [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 Brand System and Repo-Ready Brandbook** - Phases 80-84 (closed superseded 2026-06-11; audit verdict gaps_found, accepted) - see [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md) and [milestones/v1.8-MILESTONE-AUDIT.md](milestones/v1.8-MILESTONE-AUDIT.md)
- ✅ **v1.9 Brand Book Fable — A/B Brand System** - Phases 85-90 (shipped 2026-06-12) - see [milestones/v1.9-ROADMAP.md](milestones/v1.9-ROADMAP.md)
- ✅ **v1.10 Brand Adoption** - Phases 91-93 (shipped 2026-06-13) - see [milestones/v1.10-ROADMAP.md](milestones/v1.10-ROADMAP.md) and [milestones/v1.10-MILESTONE-AUDIT.md](milestones/v1.10-MILESTONE-AUDIT.md)
- 🚧 **v1.11 mailglass_admin Design-System Uplift** - Phases 94-103 (active; opened 2026-06-13)

## Phases

### v1.11 mailglass_admin Design-System Uplift (Phases 94-103)

Re-baseline the admin UI onto the canonical fable brand tokens, then fractally
audit-and-uplift every component, component-group, and page across the Operator,
Inbound, and Preview surfaces to award-winning quality in light + dark and at every
width — enforced by an idempotent, research-grounded quality ratchet. Admin UI only
(3 surfaces); core email-template HEEx components and `brandbook/` specimens are OUT.
No new product features or routes (except the dev-only gallery). Release posture:
prepare-only.

- [x] **Phase 94: Token Re-Baseline onto Canonical Brand** - app.css consumes `brandbook/tokens.css --mg-*` as single source of truth; correct surface/border role mappings + dark fixes; tighten conformance gates FIRST so the re-baseline can't regress silently; rebuild + commit bundle; re-verify contrast. (completed 2026-06-13)
- [x] **Phase 95: Audit Apparatus + Quality-Ratchet v2** - stand up the idempotent ratchet (score baseline, carried-forward GAP-NN register, token-parity gate, structural-assertion + LLM-score layers); run the 18-cell matrix to produce a fresh baseline gap register against the now-correct brand. (completed 2026-06-14)
- [x] **Phase 96: Research Dossier** - parallel-subagent dossiers → locked decisions for motion (Emil Kowalski), IA (gov.uk), component states, dark mode, microcopy. (completed 2026-06-14)
- [x] **Phase 97: Cross-Surface Component Layer** - Level-1 uplift of SHARED components + dev-only component gallery (`/dev/mail/gallery`). UI-SPEC before, UI-REVIEW after. (completed 2026-06-14)
- [x] **Phase 98: Operator / Deliveries Surface** - group + page/IA + responsive + flow uplift of `/ops/mail`; seed data tuned for happy/error/boundary; anchors the cross-surface GROUP/PAGE/RESP/FLOW/A11Y requirements. (completed 2026-06-14)
- [ ] **Phase 99: Inbound Surface** - heaviest lift: add inbound overview tier, rework RoutingTrace + EvidenceCard, empty/loading states, text-xl→token fixes; re-applies cross-surface uplift to `/ops/mail/inbound`.
- [ ] **Phase 100: Preview Surface** - group + page/IA + responsive uplift of `/dev/mail`; add dark-mode support to the preview chrome.
- [ ] **Phase 101: Microcopy Pass** - global "thoughtful maintainer" microcopy across all 3 settled surfaces.
- [ ] **Phase 102: Motion + Micro-interaction Pass** - global motion uplift within hard constraints, sourced from the Phase 96 dossier.
- [ ] **Phase 103: Verification + Idempotent Closeout** - re-run matrix; close sev-4/5 GAP rows; assert score baseline meets-or-beats; all gates green; produce the baseline the next run must beat; milestone audit.

**Critical path:** 94 → 95 → 96 → 97 → {98, 99, 100 parallel} → {101, 102 parallel} → 103

## Phase Details

### Phase 94: Token Re-Baseline onto Canonical Brand

**Goal**: `mailglass_admin/assets/css/app.css` consumes the canonical `brandbook/tokens.css` `--mg-*` two-tier system as the single source of truth, with the surface/border role mapping corrected (`base-300`→border not accent, `base-200`→`surface-raised` not Mist) and dark-mode values fixed (muted/error/primary-content) — all behind tightened conformance gates landed FIRST so the re-baseline cannot regress silently. No component markup changes; bundle rebuilt + committed; contrast re-verified.
**Depends on**: Nothing (critical-path root)
**Requirements**: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, RATCHET-03
**Success Criteria** (what must be TRUE):

  1. Every admin border draws in the border role and the accent (Glass/Ice) appears only on the 10%-accent allowlist surfaces — no border or card is rendered in the accent color.
  2. Admin cards sit on `surface-raised` and dark-mode muted text, error, and primary-content all pass WCAG AA on their actual surface (computed and shown).
  3. A fail-closed token-parity ExUnit test breaks the build if any admin theme value drifts from the brandbook token value; the conformance + motion grep gates now fail on `text-lg/xl/2xl`, arbitrary `tracking-[…]`, `ease-in`, and layout-property transitions and run in CI.
  4. `git diff --exit-code priv/static/` is clean after the rebuilt bundle is committed; no admin HEEx markup changed in this phase.

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 94-01-PLAN.md — Wire + tighten design-system conformance gates (gates-first, Wave 1)
- [x] 94-02-PLAN.md — Add fail-closed token-parity test + extend accessibility/brand tests (Wave 1, parallel with 94-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 94-03-PLAN.md — Re-baseline app.css onto brandbook tokens + rebuild + commit bundle (Wave 2)

**UI hint**: yes

### Phase 95: Audit Apparatus + Quality-Ratchet v2

**Goal**: Stand up the idempotent quality ratchet — committed per-`component × pillar × theme` score baseline (meet-or-beat), a single carried-forward `GAP-NN` register with stable IDs and run-ids, Playwright structural-assertion layer, and the LLM-scored PNG matrix — then run the 18-cell matrix once to produce a fresh baseline gap register against the now-correct brand.
**Depends on**: Phase 94
**Requirements**: RATCHET-01, RATCHET-02, RATCHET-04, RATCHET-05
**Success Criteria** (what must be TRUE):

  1. A committed `component × pillar × theme` score baseline exists and a closeout assertion can confirm every cell meets-or-beats its prior committed value (only-forward).
  2. One carried-forward GAP register with stable `GAP-NN` IDs records open/fixed/downgraded + run_id; re-runs reopen regressed IDs, skip settled rows, and enforce the sev≥3 citation gate.
  3. Playwright structural assertions pass/fail on machine-checkable pillar facts (visible focus rings, ARIA roles/states, ≥44px touch targets, `font-weight ∈ {400,700}`, accent-only-on-allowlist, reduced-motion collapses durations).
  4. An LLM-scored 18-cell PNG matrix against the 6-pillar rubric writes committed baseline scores to `docs/ui-baseline-scores.json` with PNGs gitignored (no pixel-diff).

**Plans**: 4 plans

**Wave 1**

- [x] 95-01-PLAN.md — Create RATCHET-GAP-REGISTER.md schema + anti-churn contract (header-only, Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 95-02-PLAN.md — Add ratchet_baseline_test.exs + placeholder ui-baseline-scores.json + wire verify.support_contract.admin (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 95-03-PLAN.md — Add structural.spec.js to operator_browser_gate lane — 6 pillar facts × 3 surfaces (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 95-04-PLAN.md — Seed run: capture PNGs via ui-audit.sh, LLM-score, commit real baseline JSON, populate initial GAP-NN rows (Wave 4)

**UI hint**: yes

### Phase 96: Research Dossier

**Goal**: Produce parallel-subagent research dossiers under `.planning/research/v1.11/`, each ending in an adversarially-synthesized LOCKED DECISION block the main thread consumes — covering motion (Emil Kowalski + platform HIG), IA (gov.uk / Nielsen), component-state matrices, dark-mode pitfalls, and "thoughtful maintainer" microcopy — all bounded by the hard design constraints.
**Depends on**: Phase 95
**Requirements**: RESEARCH-01, RESEARCH-02, RESEARCH-03, RESEARCH-04, RESEARCH-05
**Success Criteria** (what must be TRUE):

  1. A motion dossier locks an easing/duration/property decision table within the ≤300ms / ease-out / transform-opacity-only constraints.
  2. An IA dossier locks per-surface IA decisions (master-detail / filter / triage) with loved-vs-hated evidence; a component-state dossier locks the canonical state matrix per archetype.
  3. A dark-mode dossier locks elevation/desaturation/focus-ring-contrast decisions and a microcopy dossier locks voice patterns mapped to each surface's JTBD.
  4. Every dossier ends in a self-contained LOCKED DECISION block; downstream phases can cite a locked decision without re-reading the research body.

**Plans**: 6 plans

**Wave 1** *(all parallel — fan-out)*

- [x] 96-01-PLAN.md — MOTION.md dossier: Emil Kowalski + platform HIG → locked easing/duration/property table (RESEARCH-01)
- [x] 96-02-PLAN.md — IA.md dossier: gov.uk Design System / Nielsen → locked per-surface IA decisions (RESEARCH-02)
- [x] 96-03-PLAN.md — COMPONENT-STATES.md dossier: full D-09 archetype inventory → locked state matrix (RESEARCH-03)
- [x] 96-04-PLAN.md — DARK-MODE.md dossier: existing dark tokens + Phase 86 figures → locked elevation/focus/preview-chrome decisions (RESEARCH-04)
- [x] 96-05-PLAN.md — MICROCOPY.md dossier: thoughtful-maintainer voice → per-surface JTBD copy patterns (RESEARCH-05)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 96-06-PLAN.md — SUMMARY.md: axis-ownership reconciliation + verbatim hoist of all five LOCKED DECISION blocks (RESEARCH-01..05)

### Phase 97: Cross-Surface Component Layer

**Goal**: Level-1 uplift of the SHARED components (`components.ex`, `operator/shell.ex`, shared modal + timeline patterns) so every shared component is on-brand in light + dark across color/type/spacing/radius/shadow and renders the full locked interaction-state matrix — and stand up the dev-only component gallery LiveView (`/dev/mail/gallery`, dev live_session only) as the exhaustive audit + visual-regression surface. UI-SPEC before, UI-REVIEW after.
**Depends on**: Phase 96
**Requirements**: COMP-01, COMP-02, COMP-03, GALLERY-01, GALLERY-02
**Success Criteria** (what must be TRUE):

  1. Every shared component (icon, logo, flash, badge, status_badge, shell, orientation_strip, nav_link, theme_toggle, tenant_chip) is on-brand in both themes for color, type, spacing, radius, and shadow.
  2. Every shared component renders correct, on-brand rest/hover/focus/active/disabled/loading/empty/error states per the locked state matrix, and `status_badge`/`badge` color+icon mappings are deterministic, on-token, and legible in both themes for every status/outcome atom.
  3. A dev-only gallery at `/dev/mail/gallery` (never `/ops`) renders every component × every state × light/dark from an in-code specimen list with no DB access.
  4. Each gallery cell carries a stable `data-testid` so it can be screenshotted/scored and structurally asserted by the ratchet layers.

**Plans**: 8 plans

**Wave 1** *(plans 01-05 parallel — no file overlap)*

- [x] 97-01-PLAN.md — shell.ex uplift: nav_link/nav_pill focus rings, theme_toggle verify, orientation_strip copy (COMP-01/02, COPY-LD-11/12)
- [x] 97-02-PLAN.md — Operator component fixes: deliveries_list focus ring, detail_headers text-xl, filters_form tracking removal, support_cards btn-sm (COMP-01/02)
- [x] 97-03-PLAN.md — replay_modal a11y: aria-labelledby, Escape dismiss, focus trap, h2 text-heading, COPY-LD-13 sub-copy (COMP-02)
- [x] 97-04-PLAN.md — components.ex verify (icon/logo/flash/badge/status_badge) + timeline/routing_trace/evidence_card verify+fix (COMP-01/02/03)
- [x] 97-05-PLAN.md — Preview components: device_frame min-h-11, tabs ARIA+focus+empty-pane, sidebar focus ring+border-l-2 (COMP-01/02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 97-06-PLAN.md — GalleryLive + router: new gallery_live.ex, live "/gallery" route in preview live_session (GALLERY-01/02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 97-07-PLAN.md — Bundle rebuild + commit + verify.preview gate + ratchet test guards (COMP-01)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 97-08-PLAN.md — Structural spec un-skip: openGallery helper + 5 real gallery assertions + GAP-05 flip to fixed (GALLERY-02)

**UI hint**: yes

### Phase 98: Operator / Deliveries Surface

**Goal**: Group + page/IA + responsive + flow uplift of `/ops/mail` (OperatorLive) — composing the uplifted components into coherent, on-brand groups, an IA that orients first-time and advanced operators on landing, full happy/error/boundary state coverage, mobile-first 390/768/1440 responsiveness, accessibility, and seed data tuned for every state. This phase anchors the cross-surface GROUP/PAGE/RESP/FLOW/A11Y requirements introduced here and re-applied on Phases 99 and 100. Folds in the pre-existing CR-01/02/03 nil-guard tech debt.
**Depends on**: Phase 97
**Requirements**: GROUP-01, PAGE-01, PAGE-02, RESP-01, FLOW-01, FLOW-02, A11Y-01, A11Y-02
**Success Criteria** (what must be TRUE):

  1. Operator component groups (filter cards, master-detail split, support-card triage grid, timeline, detail pane, modal) compose with consistent, on-brand inter-group spacing and visual rhythm; the IA orients both first-time and advanced operators on landing (gov.uk-style least surprise).
  2. The Operator surface lays out its happy path, primary error states, and boundary/edge states coherently and on-brand, and is legible/usable at 390/768/1440 (master-detail stacks cleanly).
  3. Deterministic seed/fixture data exercises every operator state (all statuses, suppression-flagged, long-content truncation, empty tenant, many-item lists) reachable by seeded URL, and the audit-why-a-delivery-failed JTBD flow validates end-to-end.
  4. Interactive elements have visible focus rings, correct ARIA roles/states, one `h1` per page, ≥44px touch targets, and all text meets WCAG AA contrast in both themes on its actual surface.

**Plans**: 4 plans
Plans:

**Wave 1**

- [x] 98-01-PLAN.md — Seed sev>=3 GAP anchors (GAP-06..09) + fold CR-01/02/03 nil-guards (minimal in-place idiom)

**Wave 2** *(blocked on Wave 1; 02 and 03 parallel — no file overlap)*

- [x] 98-02-PLAN.md — IA-LD-03 master-detail grid + 390px reveal-with-back + JS.toggle filter disclosure + COPY-LD-01/02 empty-state signal + group testids
- [x] 98-03-PLAN.md — Token-clean the operator in-pane components (drop tracking-[0.08em] from suppression_card/support_cards/replay_modal) + COPY-LD-14 copy

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 98-04-PLAN.md — Extend single seed for all states (URL-reachable, row-index stable) + Playwright per-state/responsive/a11y assertions + rebuild & commit bundle

**UI hint**: yes

### Phase 99: Inbound Surface

**Goal**: Apply the same group + page/IA + responsive + flow + a11y treatment to `/ops/mail/inbound` (InboundLive) — the heaviest lift because the surface is structurally thin: add an inbound overview / at-a-glance tier mirroring the operator triage pattern, rework `RoutingTrace` and `EvidenceCard` into scannable on-token group layouts (aligned clause grid + mono chips on `surface-sunken`, clear locked/info reveal affordance), add empty/loading states, and fix `text-xl`→token violations. Also satisfies the cross-cutting GROUP-01/PAGE-01/02/RESP-01/FLOW-01/02/A11Y-01/02 requirements for the inbound surface (re-applied from Phase 98).
**Depends on**: Phase 97
**Requirements**: GROUP-02, GROUP-03
**Success Criteria** (what must be TRUE):

  1. An inbound overview / at-a-glance tier exists, mirroring the operator support-card triage pattern, closing the inbound "structurally thin" gap.
  2. `RoutingTrace` and `EvidenceCard` are reworked into scannable, on-token group layouts (aligned clause grid + mono chips on `surface-sunken`) with a clear locked/info reveal affordance, and stay scannable at 390px.
  3. The inbound surface gains coherent empty/loading/error states, all `text-xl` and off-token type are fixed, and the why-did-inbound-not-route JTBD flow validates end-to-end (happy/error/boundary/missing-evidence reachable by seeded URL).
  4. The inbound surface meets the same a11y + responsive + WCAG-AA bar as the operator surface in both themes at 390/768/1440.

**Plans**: 5 plans
Plans:

**Wave 1**

- [x] 99-01-PLAN.md - Internal inbound summary seam + optional gateway.
- [ ] 99-03-PLAN.md - RoutingTrace/EvidenceCard group layout and token cleanup.

**Wave 2** *(blocked on 99-01 completion)*

- [ ] 99-02-PLAN.md - Summary-backed overview tier, responsive inbound IA, and empty states.

**Wave 3** *(blocked on 99-02 and 99-03 completion)*

- [ ] 99-04-PLAN.md - Single-seed inbound browser reachability plus responsive/JTBD assertions.

**Wave 4** *(blocked on 99-04 completion)*

- [ ] 99-05-PLAN.md - Fail-closed type/tracking conformance gate and rebuilt bundle.
**UI hint**: yes

### Phase 100: Preview Surface

**Goal**: Group + page/IA + responsive uplift of `/dev/mail` (PreviewLive) and — the headline addition — full dark-mode support for the preview chrome at parity with Operator and Inbound, while the previewed email retains its own independent dark-chrome toggle. Also satisfies the cross-cutting GROUP-01/PAGE-01/02/RESP-01/FLOW-02/A11Y-01/02 requirements for the preview surface (re-applied from Phase 98).
**Depends on**: Phase 97
**Requirements**: PAGE-03
**Success Criteria** (what must be TRUE):

  1. The Preview chrome gains full dark-mode support at parity with Operator and Inbound; toggling the admin theme re-skins the preview chrome correctly in both themes.
  2. The previewed email keeps its own independent dark-chrome toggle, distinct from the admin chrome theme (no coupling).
  3. The Preview surface composes its component groups with consistent on-brand rhythm, follows least-surprise IA on landing, and is legible/usable at 390/768/1440.
  4. The preview-a-message-before-send JTBD flow validates end-to-end, with empty/loading states on-brand and a11y + WCAG-AA met in both themes.

**Plans**: TBD
**UI hint**: yes

### Phase 101: Microcopy Pass

**Goal**: A global "thoughtful maintainer" microcopy pass across all three settled surfaces — empty, error, loading, and confirmation copy in plain language that names the cause and serves each surface's JTBD, never "Oops".
**Depends on**: Phase 98, Phase 99, Phase 100
**Requirements**: COPY-01
**Success Criteria** (what must be TRUE):

  1. Every empty/error/loading/confirmation string across Operator, Inbound, and Preview is in the "thoughtful maintainer" voice and serves the surface's JTBD.
  2. No surface shows "Oops" or generic placeholder copy; error states name the cause specifically (e.g. "Delivery blocked: recipient is on the suppression list").
  3. The microcopy decisions trace to the Phase 96 microcopy LOCKED DECISION block, and a conformance/voice check stays green.

**Plans**: TBD
**UI hint**: yes

### Phase 102: Motion + Micro-interaction Pass

**Goal**: A global motion uplift within the hard constraints, sourced from the Phase 96 motion dossier — token-named easing, real enter/exit asymmetry, first-mount stagger, loading skeletons, focus transitions, and View-Transitions progressive enhancement — with no springs/overshoot, no layout-property animation, no client JS hook, and `prefers-reduced-motion` collapsing all motion.
**Depends on**: Phase 98, Phase 99, Phase 100
**Requirements**: MOTION-01, MOTION-02
**Success Criteria** (what must be TRUE):

  1. Micro-animations across all three surfaces use token-named easing with real enter/exit asymmetry, first-mount stagger, loading skeletons, focus transitions, and View-Transitions progressive enhancement — all CSS + LiveView.JS only (no client JS hook).
  2. No motion uses springs/overshoot, layout-property transitions, or exceeds 300ms ease-out, and the tightened motion conformance gate stays green in CI.
  3. `prefers-reduced-motion` collapses all motion to no-ops and the structural reduced-motion assertion passes.

**Plans**: TBD
**UI hint**: yes

### Phase 103: Verification + Idempotent Closeout

**Goal**: Re-run the full 18-cell matrix, close all sev-4/5 GAP rows, assert the score baseline meets-or-beats its prior committed value across every cell, confirm all gates (token-parity, conformance, motion, structural, bundle-clean) are green, produce the committed baseline the next run must beat, stage the linked-version release ceremony prepare-only, and run the milestone audit.
**Depends on**: Phase 101, Phase 102
**Requirements**: (closeout — verifies all v1.11 REQ-IDs; no net-new requirement anchored here)
**Success Criteria** (what must be TRUE):

  1. The full audit matrix re-runs and every `component × pillar × theme` score cell meets-or-beats its prior committed baseline (only-forward); the committed baseline is updated to the new floor the next run must beat.
  2. Every sev-4/5 GAP row is closed (fixed or documented-downgraded with citation) and the carried-forward register is left in a clean idempotent state.
  3. All gates are green in CI — token-parity, tightened conformance + motion grep, Playwright structural assertions, LLM-score floor, and `git diff --exit-code priv/static/` bundle-clean.
  4. The linked-version release ceremony is staged prepare-only (admin minor bump mechanically drags matched core + inbound) and the milestone audit passes.

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 94. Token Re-Baseline onto Canonical Brand | 3/3 | Complete    | 2026-06-13 |
| 95. Audit Apparatus + Quality-Ratchet v2 | 4/4 | Complete    | 2026-06-14 |
| 96. Research Dossier | 6/6 | Complete   | 2026-06-14 |
| 97. Cross-Surface Component Layer | 8/8 | Complete    | 2026-06-14 |
| 98. Operator / Deliveries Surface | 4/4 | Complete    | 2026-06-14 |
| 99. Inbound Surface | 1/5 | In Progress|  |
| 100. Preview Surface | 0/? | Not started | - |
| 101. Microcopy Pass | 0/? | Not started | - |
| 102. Motion + Micro-interaction Pass | 0/? | Not started | - |
| 103. Verification + Idempotent Closeout | 0/? | Not started | - |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
