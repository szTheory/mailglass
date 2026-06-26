# Requirements: v1.14 Operator IA & Lived-Experience Redesign

**Milestone goal:** Invert the admin-UI quality method to **top-down, JTBD/IA-led**, add a
**judgment-level adversarial persona-critic review loop**, and redesign the admin/operator surfaces
page-by-page (biggest-impact first) to ruthlessly de-duplicated, Apple-like deliberate IA — then ship
to Hex. Binding quality bar: `.planning/research/v1.14/STRESS-TEST-PROMPT.md` (do not dilute). Seed:
`.planning/research/v1.14/MILESTONE-SEED.md`.

## Cross-cutting acceptance criteria (apply to every surface requirement)

Every surface/redesign requirement below is only satisfied when it holds across the full matrix:
- **Themes:** light / dark / system (system = absence of explicit choice).
- **Viewports:** 320 / 375 / 768 / 1024 / 1440 / wide — mobile-first responsive, no squished tables
  (cards/lists < 768), no chopped content, no horizontal overflow.
- **States:** happy / empty / loading / error / permission-denied / boundary / disconnected-reconnect /
  long-and-ugly-real-data (UUIDs, long module names, non-ASCII, high counts, nulls).
- **A11y:** WCAG 2.2 AA + WAI-ARIA APG (keyboard-complete, visible/restored focus, never color-alone,
  44×44 targets, labeled controls, predictable dialogs).
- **Motion:** Emil-Kowalski-grade (transform/opacity only, origin-aware overlays, reduced-motion snaps
  instant, no theme-switch animation) within the v1.13 MOTION locks.
- **Microcopy:** on-brand thoughtful-maintainer voice, recovery-oriented errors, "Oops" banned,
  domain-consistent labels, no redundant boilerplate.
- **Idempotent / no regressions:** inherit the full v1.13 ratchet floor (~26 conformance gates,
  54-cell aesthetic baseline, 9-cell axe baseline, 24-item Bucket-A manifest, persona drift-guard);
  re-score only upward.
- **Scope:** admin + demo only; recipient-facing email HEEx templates and `brandbook/` tokens are OUT;
  host-app-friendly (no host auth/theme/assets/Repo hijack); zero-Node *shipped* asset pipeline.

## v1.14 Requirements

### Method & Audit (the method inversion)
- [x] **METHOD-01**: Adversarial persona/JTBD critic agents walk every admin surface (live `make demo`
      + the review surface) across the viewport×theme×state matrix and produce a prioritized,
      severity-ranked, **screenshot-backed defect register** (the hit-list driving the redesign).
- [x] **METHOD-02**: New judgment-level regression guards (nav-active-correctness; no nav-duplication
      on a populated page) are armed, green, and added to the inherited ratchet floor so the fixed
      issues cannot silently regress.

### Storybook / Review Surface
- [x] **STORY-01**: A dev-only `phoenix_storybook` surface renders admin primitives, component groups,
      and pages on-brand (sandbox stylesheet = the committed `app.css`) with stories spanning
      states/themes/viewports; it is `only: :dev` so adopters never install it (zero-Node guarantee
      intact).
- [x] **STORY-02**: The existing `/dev/mail/gallery` is retained as the structural-contract/ratchet
      surface with no drift-guard regression.

### App-Shell, Navigation & Overview (biggest-impact surface)
- [ ] **SHELL-01**: The sidebar nav shows the correct active item for the current surface
      (overview / deliveries / inbound) — never a false highlight.
- [ ] **SHELL-02**: The Overview is a **real triage destination**: redundant "Navigate" nav cards
      removed, the generic orientation strip shown only on genuine empty panes, health stats made
      actionable/drill-down, and Overview given its own nav identity.
- [ ] **SHELL-03**: Shell + overview microcopy is streamlined, on-brand, and non-redundant (no
      boilerplate labels; nothing duplicating the always-visible sidebar).

### Deliveries Surface
- [ ] **DELIV-01**: The Deliveries surface is redesigned for its core operator JTBD with a streamlined,
      non-info-dump IA — satisfying the cross-cutting matrix above.

### Inbound Surface
- [ ] **INB-01**: The Inbound surface is redesigned consistent with the cleaned-up Deliveries patterns —
      satisfying the cross-cutting matrix above.

### Preview Surface
- [ ] **PREV-01**: The Preview surface is redesigned consistent with the established patterns —
      satisfying the cross-cutting matrix above.

### Cross-Surface Coherence & Ratchet
- [ ] **COH-01**: All four surfaces are cross-surface coherent (spacing, hierarchy, IA, microcopy,
      motion); the storybook + gallery review surfaces are finalized and consistent.
- [ ] **COH-02**: The aesthetic ratchet baseline is re-scored **only-forward** (meet-or-beat, zero
      regressions) with all inherited gates + the new judgment gates green.

### Release & Closeout
- [ ] **REL-01**: A linked-version Hex release is cut (admin-minor drags matched core+inbound), the
      D-13 inbound exact-pin is re-pinned to the new core version, and Hex resolution + consumer +
      post-publish smoke are green.
- [ ] **REL-02**: The milestone is audited (`status: passed`) and archived.

## Future Requirements (deferred)

- Consolidating `/dev/mail/gallery` into `phoenix_storybook` (migrate ratchet testids) — only if the
  two surfaces prove redundant after STORY-01 lands.
- SEED-003 ecosystem integrations — remains dormant (re-rank against adopter pull, not auto-promoted).

## Out of Scope (explicit)

- **Product capability growth** — no new providers/transports/routes/features; this is quality only
  (D-23 convergence).
- **Recipient-facing email HEEx templates + `brandbook/` tokens** — the brand book is the source of
  truth; not touched.
- **Host-app theme/auth/assets/Repo changes** — mountable-library friendliness preserved.
- **Pixel-diff visual regression** — structural + axe-JSON + score-baseline only (no screenshot diffs).
- **A JS build toolchain in the *shipped* pipeline** — storybook is dev-only; the committed
  `app.css` (standalone tailwind) remains the adopter-facing asset pipeline.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| METHOD-01 | Phase 118 | Complete |
| METHOD-02 | Phase 118 | Complete |
| STORY-01 | Phase 118 | Complete |
| STORY-02 | Phase 118 | Complete |
| SHELL-01 | Phase 119 | Pending |
| SHELL-02 | Phase 119 | Pending |
| SHELL-03 | Phase 119 | Pending |
| DELIV-01 | Phase 120 | Pending |
| INB-01 | Phase 121 | Pending |
| PREV-01 | Phase 122 | Pending |
| COH-01 | Phase 123 | Pending |
| COH-02 | Phase 123 | Pending |
| REL-01 | Phase 124 | Pending |
| REL-02 | Phase 124 | Pending |

**Coverage: 14/14 requirements mapped to exactly one phase (118-124). No orphans, no duplicates.**
