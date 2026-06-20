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
- ✅ **v1.11 mailglass_admin Design-System Uplift** - Phases 94-103 (shipped 2026-06-16) - see [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md) and [milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.12 Adopter Onboarding & Day-2 Confidence** - Phases 104-108 (shipped 2026-06-17) - see [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md) and [milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)
- 🚧 **v1.13 Admin Design-System Stress Test & UX Uplift (v3)** - Phases 109-117 (in progress)

## Active Milestone — v1.13 Admin Design-System Stress Test & UX Uplift (v3)

**Opened 2026-06-18.** The third adopter-visible-quality admin pass (after v1.7 and v1.11) under
the D-23 convergence rule, distinguished by being **lived-experience / real-demo-driven** (D-29):
the v1.11 ratchet passed in the lab yet clicking the real `make demo` app still surfaced usability
traps (tenant-scoping dead-end, pointless single-tenant picker, clipped stat-card labels,
modal-behind-scrim, "kind of ugly" rough edges). This milestone systematically audits and uplifts
the `mailglass_admin` design system **fractally** (foundations → primitives → forms → app-shell →
data-display → component-groups → pages/flows → fixtures+ratchet) to award-winning, internally
coherent, on-brand quality in **light / dark / system** at every width, **WCAG 2.2 AA**, proven
against multi-tenant stress fixtures along real JTBD paths — then **ships to Hex** (D-28).

The build order is **dependency-ordered, bottom-up fractal** (research-converged, adversarially
grounded): each level inherits a fixed lower level, so fixing a primitive once means every page
inherits it. **Two binding sequencing constraints thread through everything:**

1. **Merge PR #86 before any uplift** (REL-01 — it carries the already-landed tenant-scope/theme
   fixes the rest builds on). This is the binding precondition gating the start of Phase 109.

2. **Tighten gates BEFORE re-baselining** (the v1.11 anti-trap — if you re-score first, the higher
   numbers become the floor and the looser gate can never be re-armed). Gates are tightened inside
   each phase; the full pillar re-score happens ONLY in the final ratchet-arm phase (116).

The multi-tenant stress-fixture cohort (RATCHET-01) is the **keystone dependency** — most
data-display/state features are only *provable* against it, so it lands late but gates the final
score.

**Scope locks:** Admin + demo only (recipient-facing email templates and `brandbook/` tokens are
OUT — the brand book is the source of truth). Host-app-friendly (no hijacking host
auth/theme/assets/Repo; no global CSS/JS collisions). Zero-Node **asset** pipeline (committed
`priv/static/app.css`); the only net-new dependency is one **test-only** npm devDep
`@axe-core/playwright`. No pixel-diff regression — ever. Tenant listing lives in the **core read
model** scoped via `Mailglass.Tenancy.scope/2`, never raw admin Repo. Release: ACTUALLY CUT at
close (D-28) — admin-minor bump drags matched core+inbound via linked-version releases; D-13
inbound exact-pin re-pin. Phases continue from 108 → 109+.

### Phases

- [x] **Phase 109: Foundations + Gate-Tightening** - Merge PR #86 precondition; semantic z-index/motion/elevation/focus/overlay tokens + system-theme plumbing in light/dark/system; tighten gates FIRST and prove green before any pillar re-score
- [x] **Phase 110: Primitives** - Promote inlined atoms to public components; canonical `stat_card` + 3-way theme-picker primitive; every primitive in every state, WCAG 2.2 AA + APG, 320→wide, 44×44 targets, icon-exists guard
- [ ] **Phase 111: Forms** - Unify the two `filters_form` copies into shared `filter_field`/`filter_section`; every control labeled, error-recoverable, never color-alone, focus-preserved across patches
- [ ] **Phase 112: App-Shell, Navigation & Tenant Seam** - Auto-select sole tenant + listing/switcher from the core read model (kills "No tenant selected"); tenant scope persists across surfaces; theme picker wired no-FOUC; honest pagination; non-color active nav
- [ ] **Phase 113: Data-Display** - Tables ≥768px → cards <768px; all KPIs on canonical `stat_card`; distinct empty/error/permission/stale templates; severity icon+label+color; long-value handling
- [ ] **Phase 114: Component Groups** - Coherent spacing/hierarchy across composed groups (support-cards, routing-trace+evidence, detail+timeline); box-nesting depth ≤2; x/y alignment discipline
- [ ] **Phase 115: Pages/Flows + Micro-Animation + Microcopy** - GOV.UK-style IA per surface; happy/error/boundary/edge/advanced paths in light/dark/system at every width; Emil Kowalski micro-animation deltas; permission/stale/tenant microcopy ("Oops" banned)
- [ ] **Phase 116: Fixtures + Idempotent Ratchet-Arm** - Land the 2-3-persona stress cohort + widen gallery to component×state×theme×viewport; interaction pillar + axe-JSON baseline; run full matrix incl. one run against demo_app data; promote current→prior, re-score all gates green; close all 24 usability defects
- [ ] **Phase 117: Release Cut + Milestone Closeout** - Cut the linked-version Hex release (admin-minor drags core+inbound); D-13 inbound exact-pin re-pin; Hex resolution + post-publish smoke green; milestone audited and archived

### Phase Details

### Phase 109: Foundations + Gate-Tightening

**Goal**: The token substrate everything inherits is complete in light/dark/system with zero one-off values, system-theme plumbing exists at the CSS layer, and the conformance/structural gates are tightened and proven green on current code — all on top of the merged PR #86 baseline. No pillar re-score yet.
**Depends on**: Nothing in this milestone — **binding precondition: REL-01 (PR #86 merged into `main`)** must land first.
**Requirements**: REL-01 (precondition), FND-01, FND-02, FND-03, FND-04, FND-05
**Success Criteria** (what must be TRUE):

  1. PR #86 (operator/inbound theme repair + cross-surface tenant scope) is merged into `main`; main CI is green before any uplift commit lands.
  2. A formal z-index layer system (base / dropdown / overlay-scrim / overlay-panel / toast) exists as semantic tokens, every stacking context consumes it, and the Z-INDEX gate fails on any literal `z-*` in admin `lib/`.
  3. Motion, elevation, focus-ring, overlay, type-scale, spacing, radius, shadow, and border values are all semantic tokens resolving correctly in light/dark/system — the FOCUS-RING and type/spacing gates fail on any one-off hex or size literal in admin HEEx.
  4. System-theme plumbing exists at the token/CSS layer (daisyUI `prefersdark`; `system` emits no `data-theme`) with no client JS hook and no host-global CSS.
  5. The tightened gates (z-index, focus-ring, scope/isolation, WCAG 2.2 SC in the structural spec, ratchet schema bumped to include `system`) prove green on the current code BEFORE any pillar re-baseline.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 109-01-PLAN.md - REL-01 admin merge and post-merge main CI proof.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 109-02-PLAN.md - Semantic token/class consolidation for z layers, focus rings, isolation, and compiled CSS.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 109-03-PLAN.md - Hard conformance gates plus ratchet schema version 3 system cells.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 109-04-PLAN.md - Structural WCAG/system assertions and final no-scope-creep proof.

**UI hint**: yes

### Phase 110: Primitives

**Goal**: Every shared atom is a single public component (no copy-drift), renders correctly in every interaction state in light/dark/system at 320→wide meeting WCAG 2.2 AA + WAI-ARIA APG, and the canonical `stat_card` and 3-way theme-picker primitives exist — fixing every page once at the primitive level.
**Depends on**: Phase 109
**Requirements**: PRIM-01, PRIM-02, PRIM-03, PRIM-04, PRIM-05, PRIM-06, PRIM-07
**Success Criteria** (what must be TRUE):

  1. The gallery-inlined atoms (`nav_link` / `nav_pill` / `tenant_chip` / `theme_toggle`) are promoted to single public components rendered identically in the shell and gallery — a copy-drift grep gate passes.
  2. Every primitive renders correctly in every interaction state (hover/focus/active/pressed/disabled/loading/selected/error/empty/long-content) across light/dark/system at 320→wide, meeting WCAG 2.2 AA + WAI-ARIA APG; disabled controls are visually and programmatically distinct (no disabled-looking-enabled, no enabled-looking-disabled).
  3. A canonical `stat_card` primitive exists — label truncates with tooltip, value is `tabular-nums` and never wraps, severity is icon+label+color (never color alone) — enforced by a STATCARD gate.
  4. A 3-way system / light / dark theme-picker primitive exists (tri-state; `system` = absence of explicit choice), and interactive targets meet the 44×44 floor verified in the **compiled bundle** (the `btn-sm`/`min-h-11` tension resolved; dense-control 24px exceptions explicitly gate-now-or-GAP-recorded).
  5. Every `<.icon name="...">` in use renders a real embedded SVG (icon-exists guard), is semantically appropriate, and is never the sole carrier of meaning.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 110-01-PLAN.md - Public primitive API for nav_link, nav_pill, tenant_chip, theme_picker, and stat_card.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 110-02-PLAN.md - Real shell and overview consumers migrated to the public primitives.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 110-03-PLAN.md - Gallery primitive certification and expanded state matrix.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 110-04-PLAN.md - Primitive drift/stat-card/icon gates and compiled-browser structural proof.

**UI hint**: yes

### Phase 111: Forms

**Goal**: Form controls sit on the unified primitives — the two divergent `filters_form` copies become one shared `filter_field`/`filter_section` set, every control is fully labeled and recoverable, and focus survives LiveView patches.
**Depends on**: Phase 110
**Requirements**: FORM-01, FORM-02, FORM-03
**Success Criteria** (what must be TRUE):

  1. The two divergent `filters_form` copies are unified into shared `filter_field` / `filter_section` primitives (no duplicate copy remains).
  2. Every form control has a visible associated label, programmatically connected help/error text, recovery-oriented error copy, and validation state that never relies on color alone.
  3. Disabled and read-only form states are visually distinct, and focus is preserved (not lost) across LiveView patches.

**Plans**: 4 plans
**UI hint**: yes

### Phase 112: App-Shell, Navigation & Tenant Seam

**Goal**: The headline multi-tenant fix lands — auto-select the sole tenant, list/switch tenants from the core read model (killing the "No tenant selected" dead-end and the pointless single-tenant picker), persist scope across every surface, wire the theme picker no-FOUC, and make nav active-state and pagination honest.
**Depends on**: Phase 110 (picker primitive), Phase 111, and the core read-model listing.
**Requirements**: SHELL-01, SHELL-02, SHELL-03, SHELL-04, SHELL-05, SHELL-06
**Success Criteria** (what must be TRUE):

  1. A sole tenant is auto-selected (the single-tenant picker is gone); the tenant picker renders only when ≥2 tenants exist.
  2. When unscoped with ≥2 tenants, the operator sees a tenant listing/switcher sourced from the **core read model** (`list_tenants` scoped via `Mailglass.Tenancy.scope/2` through the authenticated actor, never raw admin Repo) instead of a dead-end — and tenant scope (`tenant_id`) persists across every surface and navigation action, building on PR #86.
  3. The theme picker is wired through the mount hook with host-scoped persistence and no FOUC on first paint (explicit choice server-rendered from a namespaced cookie; system resolved via `prefersdark`).
  4. Navigation shows an unambiguous active/current state with a non-color cue at both nav levels.
  5. Pagination shows the result count always and pagination chrome only when there is more than one page, with boundary prev/next disabled (not hidden).

**Plans**: TBD
**UI hint**: yes
**Research flag**: light `/gsd-plan-phase` research needed — resolve the exact shape of the core `list_tenants` projection (distinct-tenant query vs dedicated read model) and how it composes with `Tenancy.scope/2` + the `operator_actor` auth context. Must live in core, scoped, not raw admin Repo.

### Phase 113: Data-Display

**Goal**: The densest, most-differentiating level — tables-vs-cards discipline, all stat cards on the canonical primitive, distinct empty/error/permission/stale templates, severity-first encoding, and graceful long-value handling, all provable against realistic data.
**Depends on**: Phase 110
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):

  1. Deliveries and Inbound lists render as tables ≥768px and transform to a card/list layout <768px — no squished, unreadable columns.
  2. Every stat/KPI card across all surfaces uses the canonical `stat_card` — no clipped labels, no bare `—`/`___` placeholders, and "all clear" reads as a real state.
  3. Empty, error, permission-denied, and stale-data states are distinct templates (no-data ≠ unavailable ≠ permission-denied).
  4. Severity/status is encoded by icon+label+color (never color alone) and is scannable in a 5-second operator-under-stress test.
  5. Long real-world values (UUIDs, module/function names, URLs, non-ASCII names, timestamps) are handled gracefully — truncate+tooltip or expand, never overflow or chop.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 113-01-PLAN.md — Shared `Components.data_state/1` four-state primitive + embed data-state Heroicons + certify stat_card meaningful-text contract.

**Wave 2** *(blocked on Wave 1; 02 and 03 run in parallel — disjoint files)*

- [x] 113-02-PLAN.md — Deliveries dual table+card presentation, four data-states, long-value handling, operator KPI stat_card certification.
- [x] 113-03-PLAN.md — Inbound records dual table+card presentation (synchronous-only), four data-states, long-value handling, inbound KPI stat_card certification.

**Wave 3** *(blocked on Wave 2)*

- [x] 113-04-PLAN.md — Gallery specimens + Playwright responsive/overflow/status/data-state proof (legacy testids migrated) + STATUS-BADGE/DATA-STATE conformance gates + single bit-clean CSS bundle commit.

**UI hint**: yes

### Phase 114: Component Groups

**Goal**: Coherence across composed component groups — intentional spacing/hierarchy that makes the next action obvious, bounded box-nesting, and consistent x/y alignment at narrow and wide widths.
**Depends on**: Phases 110-113
**Requirements**: GROUP-01, GROUP-02, GROUP-03
**Success Criteria** (what must be TRUE):

  1. Composed component groups (support-cards triage, routing-trace + evidence, detail + timeline) have coherent, intentional spacing and visual hierarchy that makes the next action obvious.
  2. Card nesting depth is ≤2 (no accidental "box prison"); content has intentional breathing room (no accidental flush-to-container edges).
  3. Elements align on a consistent x/y grid across each group (no accidental misalignment), holding together at narrow and wide widths.

**Plans**: 4 plans
**Wave 1**

- [x] 114-01-PLAN.md — Thin `<.card>` shell + SPACE-GATE/GROUP-GATE conformance gates (substrate, Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 114-02-PLAN.md — Composed-group gallery specimens + `data-region`/`data-group-card` wiring + live-view smoke binding (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 114-03-PLAN.md — Box-prison fix + shell swap + ~93-token semantic sweep across the 8 group surfaces; green the gates (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 114-04-PLAN.md — Floki depth proof + Playwright `Group:` geometry (sibling-x, padding-floor, no-overflow at 320/1280) (Wave 3)

**UI hint**: yes

### Phase 115: Pages/Flows + Micro-Animation + Microcopy

**Goal**: Whole-surface information architecture and lived flows sit on top of every fixed primitive/group — GOV.UK-style IA per surface, every JTBD path working in light/dark/system at every width, a micro-animation pass within the v1.11 motion locks, and a microcopy pass covering the new permission/stale/tenant surfaces.
**Depends on**: Phases 109-114
**Requirements**: FLOW-01, FLOW-02, FLOW-03, FLOW-04
**Success Criteria** (what must be TRUE):

  1. Each admin surface presents a GOV.UK-style information architecture following the principle of least surprise, with the top operator action immediately obvious and good onboarding for first-time, intermediate, and advanced users.
  2. Every surface's happy / error / boundary / edge / advanced path works in light/dark/system at 320→wide — no broken scrolling, no scroll-chaining traps, no modal hidden behind the scrim, no floating element covering content.
  3. A micro-animation pass applies the Emil Kowalski deltas (origin-aware overlays, theme-switch never animates, `prefers-reduced-motion` snaps to instant, transform/opacity only) within the v1.11 MOTION-LD locks.
  4. A microcopy pass covers the new permission/stale/tenant surfaces — recovery-oriented errors, domain-consistent labels, "Oops" banned across all three surfaces.

**Plans**: TBD
**UI hint**: yes

### Phase 116: Fixtures + Idempotent Ratchet-Arm

**Goal**: The keystone closes here — land the multi-tenant stress-fixture cohort (the proving substrate), widen the gallery to the full matrix, add the interaction pillar and axe-JSON baseline, run the full matrix INCLUDING at least one run against rich `demo_app` data, then promote `current → prior` and re-score with all gates green (meet-or-beat, zero regressions), closing all 24 usability defects.
**Depends on**: Phases 109-115
**Requirements**: RATCHET-01, RATCHET-02, RATCHET-03, RATCHET-04, RATCHET-05
**Success Criteria** (what must be TRUE):

  1. A realistic 2-3-tenant persona stress-fixture cohort (no-data / one / many / long-ID / non-ASCII / null / high-count / error edge data) lands in `reference/demo_app` seeds + gallery stress specimens — making multi-tenancy tangible and giving the picker a reason to exist.
  2. The dev-only component-lab gallery is widened to a component × state × {light, dark, system} × {320…wide} matrix.
  3. The ratchet gains an interaction pillar (hit-test panel-above-scrim, scroll-chaining, focus-restore-to-trigger, layout-jump) and an axe-violation JSON baseline (WCAG 2.2 AA) — both screenshot-free, no pixel-diff.
  4. The full matrix runs INCLUDING at least one run against rich `reference/demo_app` data (closing the "lab-passes-but-ugly" gap), then `current → prior` is promoted and re-scored with all gates green (meet-or-beat, zero regressions).
  5. All 24 enumerated usability defects (PITFALLS Bucket A) are closed, each with a regression guard (grep gate, Playwright structural assertion, axe scan, or fixture stress-case).

**Plans**: TBD
**UI hint**: yes
**Research flag**: light `/gsd-plan-phase` research needed — decide the axe-JSON baseline format (per-surface counts vs rule-id allowlist, matching the existing score-baseline ergonomics) and the `ratchet_baseline_test.exs` schema-v3 cell-count (add `system` as a 3rd theme → 54 cells vs keeping viewport structural-only).

### Phase 117: Release Cut + Milestone Closeout

**Goal**: Ship the uplift to adopters — cut the linked-version Hex release (admin-minor drags matched core+inbound), re-pin the D-13 inbound exact-pin to the new core version, verify Hex resolution + post-publish smoke green, then audit and archive the milestone.
**Depends on**: Phase 116
**Requirements**: REL-02, REL-03
**Success Criteria** (what must be TRUE):

  1. A linked-version Hex release is cut at close (admin-minor drags matched core + inbound), with the D-13 inbound exact-pin re-pinned to the new core version.
  2. Hex resolution + post-publish smoke are verified green.
  3. The milestone is audited (`status: passed` on all 36 requirements) and archived.

**Plans**: TBD

### Execution Order

Phases execute in numeric order: 109 → 110 → 111 → 112 → 113 → 114 → 115 → 116 → 117.
REL-01 / PR #86 merge is the binding precondition gating the start of 109. Gates are tightened
inside each phase; the full pillar re-score happens only in 116.

## Phases (Shipped — Archived)

All milestones through v1.12 are shipped and archived. Per-milestone phase detail,
success criteria, and plan breakdowns live in `.planning/milestones/vX.Y-ROADMAP.md`.

<details>
<summary>✅ v1.12 Adopter Onboarding & Day-2 Confidence (Phases 104-108) — SHIPPED 2026-06-17</summary>

Friction-removal + the first real linked-version Hex release since 1.6.2 → **mailglass 1.7.0 /
mailglass_admin 1.7.0 / mailglass_inbound 1.4.0 live on Hex**. Installer fail-closed + webhook
doctor (104), onboarding docs + learning arc (105), day-2 guides (106), inbound replay-modal a11y
parity (107), release cut + closeout (108). Audit `status: passed` — 13/13 requirements, 5/5
phases. Full detail: [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md).

</details>

<details>
<summary>✅ v1.11 mailglass_admin Design-System Uplift (Phases 94-103) — SHIPPED 2026-06-16</summary>

Re-baseline the admin UI onto the canonical fable brand tokens, then fractally
audit-and-uplift every component, component-group, and page across the Operator,
Inbound, and Preview surfaces — enforced by an idempotent, research-grounded quality
ratchet. Admin UI only (3 surfaces). Release posture: prepare-only (no Hex release cut).
Audit `status: passed` — 34/34 requirements, 10/10 phases, 16/16 integration, 7/7 flows.
Full detail: [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md).

- [x] Phase 94: Token Re-Baseline onto Canonical Brand (3/3 plans) — completed 2026-06-13
- [x] Phase 95: Audit Apparatus + Quality-Ratchet v2 (4/4 plans) — completed 2026-06-14
- [x] Phase 96: Research Dossier (6/6 plans) — completed 2026-06-14
- [x] Phase 97: Cross-Surface Component Layer (8/8 plans) — completed 2026-06-14
- [x] Phase 98: Operator / Deliveries Surface (4/4 plans) — completed 2026-06-14
- [x] Phase 99: Inbound Surface (5/5 plans) — completed 2026-06-15
- [x] Phase 100: Preview Surface (3/3 plans) — completed 2026-06-15
- [x] Phase 101: Microcopy Pass (2/2 plans) — completed 2026-06-16
- [x] Phase 102: Motion + Micro-interaction Pass (3/3 plans) — completed 2026-06-16
- [x] Phase 103: Verification + Idempotent Closeout (4/4 plans) — completed 2026-06-16

**Critical path:** 94 → 95 → 96 → 97 → {98, 99, 100 parallel} → {101, 102 parallel} → 103

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 109. Foundations + Gate-Tightening | v1.13 | 4/4 | Complete    | 2026-06-18 |
| 110. Primitives | v1.13 | 4/4 | Complete    | 2026-06-18 |
| 111. Forms | v1.13 | 3/4 | In Progress|  |
| 112. App-Shell, Nav & Tenant Seam | v1.13 | 6/6 | Complete    | 2026-06-19 |
| 113. Data-Display | v1.13 | 4/4 | Complete    | 2026-06-20 |
| 114. Component Groups | v1.13 | 4/4 | Complete   | 2026-06-20 |
| 115. Pages/Flows + Motion + Microcopy | v1.13 | 0/TBD | Not started | - |
| 116. Fixtures + Ratchet-Arm | v1.13 | 0/TBD | Not started | - |
| 117. Release Cut + Milestone Closeout | v1.13 | 0/TBD | Not started | - |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
