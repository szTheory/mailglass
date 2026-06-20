# Requirements: mailglass — v1.13 Admin Design-System Stress Test & UX Uplift (v3)

**Defined:** 2026-06-18
**Core Value:** Email you can see, audit, and trust before it ships — and the admin/operator surface that proves it must itself feel award-winning, coherent, and effortless to jump into.

> Scope: `mailglass_admin` (3 surfaces: Operator `/ops/mail`, Inbound `/ops/mail/inbound`, Preview `/dev/mail`) + the `reference/demo_app` fixtures. A **lived-experience / real-demo-driven**, fractal, research-per-decision, WCAG 2.2 AA, light/dark/**system**, idempotent design-system stress-test (D-29), shipped to Hex at close (D-28). EXTENDS the v1.11 LOCKED-DECISION dossiers — does not re-litigate them. Research: `.planning/research/v1.13/SUMMARY.md`.
>
> **Binding scope locks:** Admin + demo only (recipient-facing email templates and `brandbook/` tokens are OUT — brand book is the source of truth). Host-app-friendly (no hijacking host auth/theme/assets/Repo; no global CSS/JS collisions). Zero-Node **asset** pipeline (committed `priv/static/app.css`); the only net-new dependency is one **test-only** npm devDep `@axe-core/playwright`. No pixel-diff regression — ever. Tenant listing lives in the **core read model** scoped via `Mailglass.Tenancy.scope/2`, never raw admin Repo.

## v1 Requirements

Fractal, dependency-ordered (foundations → primitives → forms → app-shell → data-display → groups → pages/flows → fixtures+ratchet → release). Two binding sequencing constraints thread through: **merge PR #86 before any uplift**, and **tighten gates BEFORE re-baselining** (the v1.11 anti-trap).

### Foundations & Gate-Tightening (FND)

- [x] **FND-01**: A formal z-index layer system (base / dropdown / overlay-scrim / overlay-panel / toast) exists as semantic tokens and is consumed by every stacking context; no literal `z-*` values remain in admin `lib/` (fixes modal-behind-scrim).
- [x] **FND-02**: Motion, elevation, focus-ring, and overlay values are defined as semantic tokens (zero one-off values) with correct light / dark / system resolution.
- [x] **FND-03**: Type-scale, spacing, radius, shadow, and border token coverage is audited complete across admin HEEx — no one-off hex or size literals remain.
- [x] **FND-04**: System-theme plumbing exists at the token/CSS layer (daisyUI `prefersdark`; `system` emits no `data-theme`) with no client JS hook and no host-global CSS.
- [x] **FND-05**: Conformance/structural gates are tightened FIRST (z-index gate, focus-ring gate, scope/isolation gate, WCAG 2.2 success criteria in the structural spec, ratchet schema bumped to include `system`) and prove green on current code before any pillar re-baseline.

### Primitive Components (PRIM)

- [x] **PRIM-01**: The gallery-inlined atoms (`nav_link` / `nav_pill` / `tenant_chip` / `theme_toggle`) are promoted to single public components rendered identically in the shell and the gallery — no copy-drift.
- [x] **PRIM-02**: Every primitive renders correctly in every interaction state (hover/focus/active/pressed/disabled/loading/selected/error/empty/long-content) in light/dark/system at 320→wide, meeting WCAG 2.2 AA + WAI-ARIA APG patterns.
- [x] **PRIM-03**: Disabled controls are visually and programmatically distinct from enabled ones (no disabled-looking-enabled, no enabled-looking-disabled).
- [x] **PRIM-04**: A canonical `stat_card` primitive exists — label truncates with tooltip, value is `tabular-nums` and never wraps, severity is icon+label+color (never color alone).
- [x] **PRIM-05**: A 3-way system / light / dark theme-picker primitive exists (tri-state; `system` = absence of explicit choice).
- [x] **PRIM-06**: Interactive targets meet the 44×44 floor (the `btn-sm`/`min-h-11` tension resolved and verified in the **compiled bundle**); dense-control 24px exceptions are explicitly decided (gate-now vs GAP-record).
- [x] **PRIM-07**: Every `<.icon name="...">` in use renders a real embedded SVG (icon-exists guard), is semantically appropriate, and is never the sole carrier of meaning.

### Form Controls (FORM)

- [x] **FORM-01**: The two divergent `filters_form` copies are unified into shared `filter_field` / `filter_section` primitives.
- [x] **FORM-02**: Every form control has a visible associated label, programmatically connected help/error text, recovery-oriented error copy, and validation state that never relies on color alone.
- [x] **FORM-03**: Disabled and read-only form states are visually distinct, and focus is preserved (not lost) across LiveView patches.

### App-Shell, Navigation & Tenant Seam (SHELL)

- [x] **SHELL-01**: A sole tenant is auto-selected (killing the pointless single-tenant picker); the tenant picker renders only when ≥2 tenants exist.
- [x] **SHELL-02**: When unscoped with ≥2 tenants, the operator sees a tenant listing/switcher sourced from the core read model (scoped via `Mailglass.Tenancy.scope/2` through the authenticated actor, never raw admin Repo) instead of the "No tenant selected" dead-end.
- [x] **SHELL-03**: Tenant scope persists across every surface and navigation action (carrying `tenant_id`, building on PR #86).
- [x] **SHELL-04**: The theme picker is wired through the mount hook with host-scoped persistence and no FOUC on first paint (explicit choice server-rendered from a namespaced cookie; system resolved via `prefersdark`).
- [x] **SHELL-05**: Navigation shows an unambiguous active/current state with a non-color cue at both nav levels.
- [x] **SHELL-06**: Pagination shows the result count always and pagination chrome only when there is more than one page, with boundary prev/next disabled (not hidden).

### Data-Display Patterns (DATA)

- [ ] **DATA-01**: Deliveries and Inbound lists render as tables ≥768px and transform to a card/list layout <768px — no squished, unreadable columns.
- [x] **DATA-02**: Every stat/KPI card across all surfaces uses the canonical `stat_card` — no clipped labels, no bare `—`/`___` placeholders, and "all clear" reads as a real state.
- [x] **DATA-03**: Empty, error, permission-denied, and stale-data states are distinct templates (no-data ≠ unavailable ≠ permission-denied).
- [ ] **DATA-04**: Severity/status is encoded by icon+label+color (never color alone) and is scannable in a 5-second operator-under-stress test.
- [ ] **DATA-05**: Long real-world values (UUIDs, module/function names, URLs, non-ASCII names, timestamps) are handled gracefully — truncate+tooltip or expand, never overflow or chop.

### Component Groups / Meta-Components (GROUP)

- [ ] **GROUP-01**: Composed component groups (support-cards triage, routing-trace + evidence, detail + timeline) have coherent, intentional spacing and visual hierarchy that makes the next action obvious.
- [ ] **GROUP-02**: Card nesting depth is ≤2 (no accidental "box prison"); content has intentional breathing room (no accidental flush-to-container edges).
- [ ] **GROUP-03**: Elements align on a consistent x/y grid across each group (no accidental misalignment), holding together at narrow and wide widths.

### Pages, Flows, Motion & Microcopy (FLOW)

- [ ] **FLOW-01**: Each admin surface presents a GOV.UK-style information architecture following the principle of least surprise, with the top operator action immediately obvious and good onboarding for first-time, intermediate, and advanced users.
- [ ] **FLOW-02**: Every surface's happy / error / boundary / edge / advanced path works in light/dark/system at 320→wide — no broken scrolling, no scroll-chaining traps, no modal hidden behind the scrim, no floating element covering content.
- [ ] **FLOW-03**: A micro-animation pass applies the Emil Kowalski deltas (origin-aware overlays, theme-switch never animates, `prefers-reduced-motion` snaps to instant, transform/opacity only) within the v1.11 MOTION-LD locks.
- [ ] **FLOW-04**: A microcopy pass covers the new permission/stale/tenant surfaces — recovery-oriented errors, domain-consistent labels, "Oops" banned across all three surfaces.

### Fixtures & Idempotent Ratchet (RATCHET)

- [ ] **RATCHET-01**: A realistic 2–3-tenant persona stress-fixture cohort (with no-data / one / many / long-ID / non-ASCII / null / high-count / error edge data) lands in `reference/demo_app` seeds + gallery stress specimens — making multi-tenancy tangible and giving the picker a reason to exist.
- [ ] **RATCHET-02**: The dev-only component-lab gallery is widened to a component × state × {light, dark, system} × {320…wide} matrix.
- [ ] **RATCHET-03**: The ratchet gains an interaction pillar (hit-test panel-above-scrim, scroll-chaining, focus-restore-to-trigger, layout-jump) and an axe-violation JSON baseline (WCAG 2.2 AA) — both screenshot-free, no pixel-diff.
- [ ] **RATCHET-04**: The full matrix runs INCLUDING at least one run against rich `reference/demo_app` data (closing the "lab-passes-but-ugly" gap), then `current → prior` is promoted and re-scored with all gates green (meet-or-beat, zero regressions).
- [ ] **RATCHET-05**: All 24 enumerated usability defects (PITFALLS Bucket A) are closed, each with a regression guard (grep gate, Playwright structural assertion, axe scan, or fixture stress-case).

### Release & Closeout (REL)

- [x] **REL-01**: PR #86 (held adopter-facing fixes: operator/inbound theme repair, cross-surface tenant scope) is merged into `main` before uplift work begins — the binding precondition the rest builds on.
- [ ] **REL-02**: A linked-version Hex release is cut at close (admin-minor drags matched core + inbound), with the D-13 inbound exact-pin re-pinned to the new core version.
- [ ] **REL-03**: Hex resolution + post-publish smoke are verified green and the milestone is audited and archived.

## v2 Requirements

Deferred — differentiators tracked but not committed to this roadmap.

### Live Surfaces

- **LIVE-01**: Auto-refresh / polling of operator surfaces with an "as of HH:MM" stamp + manual refresh (stale STATE itself is covered by DATA-03; the live mechanism is the deferred part).
- **LIVE-02**: LiveView `streams` for live-append lists (perf optimization for high-volume tenants).

## Out of Scope

Explicitly excluded — documented to prevent scope creep (anti-features surfaced + adversarially confirmed in research).

| Feature | Reason |
|---------|--------|
| PhoenixStorybook | Imports a JS/esbuild build surface this zero-Node asset pipeline deliberately lacks, and imposes a second mountable surface a library shouldn't force; the in-house `/dev/mail/gallery` is the component-lab. |
| Recipient-facing email HEEx template uplift | Diminishing-returns, separate concern; this milestone is admin + demo only. |
| `brandbook/` token / specimen changes | The brand book is the source of truth (a newer brand book wins over older `prompts/`); admin only *applies* it. |
| Cross-tenant "all tenants" aggregate view | Data-leak risk; violates D-09 tenant isolation. |
| Tenant CRUD / create / invite in the picker | Host-app concern, not an admin-dashboard responsibility. |
| Pixel-diff visual regression (Percy / Chromatic / `toHaveScreenshot` / BackstopJS) | Violates the gitignored-PNG / no-pixel-diff precedent; regression stays structural + axe-JSON + score-baseline. |
| Server-persisted per-user / per-tenant theme | Theme is a host-scoped client preference; server-persistence hijacks host concerns. |
| Sortable/filterable mega-table-of-everything (Kaffy/AshAdmin-style auto-admin) | Wrong product shape; the surfaces are task-oriented operator views, not a generic data browser. |
| Always-on pagination bar / infinite scroll | Anti-pattern for bounded operator data; honest pagination (count-always, chrome-when->1-page) instead. |
| Color-only severity, illustration-heavy empty states, pin/favorite tenants | A11y + zero-asset + over-engineering constraints. |
| New Hex dependencies (runtime) | Zero new Hex deps; the only net-new dep is one test-only npm `@axe-core/playwright`. |

## Traceability

Final phase-number assignment (phases continue from v1.12's last phase 108 → 109+). Each requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 109 (precondition — merge PR #86) | Complete |
| FND-01 | Phase 109 | Complete |
| FND-02 | Phase 109 | Complete |
| FND-03 | Phase 109 | Complete |
| FND-04 | Phase 109 | Complete |
| FND-05 | Phase 109 | Complete |
| PRIM-01 | Phase 110 | Complete |
| PRIM-02 | Phase 110 | Complete |
| PRIM-03 | Phase 110 | Complete |
| PRIM-04 | Phase 110 | Complete |
| PRIM-05 | Phase 110 | Complete |
| PRIM-06 | Phase 110 | Complete |
| PRIM-07 | Phase 110 | Complete |
| FORM-01 | Phase 111 | Complete |
| FORM-02 | Phase 111 | Complete |
| FORM-03 | Phase 111 | Complete |
| SHELL-01 | Phase 112 | Complete |
| SHELL-02 | Phase 112 | Complete |
| SHELL-03 | Phase 112 | Complete |
| SHELL-04 | Phase 112 | Complete |
| SHELL-05 | Phase 112 | Complete |
| SHELL-06 | Phase 112 | Complete |
| DATA-01 | Phase 113 | Pending |
| DATA-02 | Phase 113 | Complete |
| DATA-03 | Phase 113 | Complete |
| DATA-04 | Phase 113 | Pending |
| DATA-05 | Phase 113 | Pending |
| GROUP-01 | Phase 114 | Pending |
| GROUP-02 | Phase 114 | Pending |
| GROUP-03 | Phase 114 | Pending |
| FLOW-01 | Phase 115 | Pending |
| FLOW-02 | Phase 115 | Pending |
| FLOW-03 | Phase 115 | Pending |
| FLOW-04 | Phase 115 | Pending |
| RATCHET-01 | Phase 116 | Pending |
| RATCHET-02 | Phase 116 | Pending |
| RATCHET-03 | Phase 116 | Pending |
| RATCHET-04 | Phase 116 | Pending |
| RATCHET-05 | Phase 116 | Pending |
| REL-02 | Phase 117 | Pending |
| REL-03 | Phase 117 | Pending |

**Coverage:**

- v1 requirements: 36 total (FND 5, PRIM 7, FORM 3, SHELL 6, DATA 5, GROUP 3, FLOW 4, RATCHET 5, REL 3 — REL-01 mapped to Phase 109 as the precondition gating its start)
- Mapped to phases 109–117: 36
- Unmapped: 0 ✓

**Phase grouping (fractal level → phase number):**

- A → Phase 109 (Foundations + Gate-Tightening): REL-01 precondition + FND-01..05
- B → Phase 110 (Primitives): PRIM-01..07
- C → Phase 111 (Forms): FORM-01..03
- D → Phase 112 (App-Shell, Nav & Tenant Seam): SHELL-01..06
- E → Phase 113 (Data-Display): DATA-01..05
- F → Phase 114 (Component Groups): GROUP-01..03
- G → Phase 115 (Pages/Flows + Motion + Microcopy): FLOW-01..04
- H → Phase 116 (Fixtures + Ratchet-Arm): RATCHET-01..05
- Closeout → Phase 117 (Release Cut + Milestone Closeout): REL-02..03

---
*Requirements defined: 2026-06-18*
*Last updated: 2026-06-18 — traceability finalized to phase numbers 109–117 (v1.13 roadmap created)*
