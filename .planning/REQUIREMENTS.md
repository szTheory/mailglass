# Requirements: mailglass v1.11 — mailglass_admin Design-System Uplift

**Defined:** 2026-06-13
**Core outcome:** The `mailglass_admin` UI (Operator, Inbound, Preview surfaces) is
re-baselined onto the canonical fable brand tokens and fractally uplifted — component,
component-group, and page/IA — to award-winning quality in light + dark and at every
width, enforced by an idempotent, research-grounded quality ratchet that only moves
quality forward.

**Scope locks (apply to every requirement):**

- **Admin UI only — 3 surfaces.** Core mailglass email-template HEEx components (what
  recipients see) and `brandbook/` HTML specimens/examples are OUT of scope. This
  milestone *consumes* the brand book, it does not edit it.
- **No new product features / no new operator capabilities / no new routes** beyond the
  dev-only component gallery.
- **No core/inbound *functional* code changes.** (A `mailglass_admin` minor bump
  mechanically drags matched core + inbound version bumps via linked-version releases —
  expected, administrative.)
- **Release posture: prepare-only** — stage the ceremony; decide whether to cut a real
  Hex release at milestone close (v1.7 precedent).
- **Hard design constraints bind every requirement:** zero Node toolchain; standalone-binary
  Tailwind v4 + vendored daisyUI/heroicons; CSS bundle rebuilt + committed (`git diff
  --exit-code priv/static/`); motion ≤300ms, ease-out, transform/opacity only,
  `prefers-reduced-motion` respected, no springs/overshoot, CSS+LiveView.JS only (no client
  JS hook); type weights only 400/700; flat elevation (border-first, no glassmorphism/bevels);
  10%-accent rule; semantic tokens only; brand constraints C-15/C-16; PII minimization
  (`mask_recipient/1`) and multi-tenant safety preserved in seed/fixture work.

## v1.11 Requirements

### TOKEN — Re-baseline onto Canonical Brand

- [x] **TOKEN-01**: `mailglass_admin` `assets/css/app.css` consumes the canonical
  `brandbook/tokens.css` `--mg-*` two-tier tokens as the single source of truth — daisyUI
  theme vars reference `var(--mg-*)`, with no duplicate hex literals.
- [x] **TOKEN-02**: The surface/border role mapping is corrected so the accent (Glass/Ice)
  appears only on the 10%-accent surfaces — borders use the border role (not the accent),
  cards use `surface-raised` (not Mist/`surface-sunken`).
- [x] **TOKEN-03**: Dark-mode token values are corrected and every changed value's contrast
  re-verified to WCAG AA on its actual surface (muted text, error, primary-content).
- [x] **TOKEN-04**: A fail-closed token-parity check (ExUnit) asserts the admin theme values
  equal the brandbook token values, so brand-token drift breaks the build.
- [x] **TOKEN-05**: The standalone-binary CSS bundle is rebuilt and committed bit-for-bit
  (`git diff --exit-code priv/static/` clean) after the re-baseline.

### RATCHET — Idempotent Quality Ratchet

- [x] **RATCHET-01**: A committed score baseline keyed by `component × pillar × theme` records
  the `gsd-ui-review` grade per cell; closeout asserts every cell meets-or-beats its prior
  committed value (only-forward, no regression).
- [x] **RATCHET-02**: One carried-forward GAP register with stable `GAP-NN` IDs (status
  open/fixed/downgraded + run_id); re-runs reopen regressed IDs and skip settled rows
  (idempotent pick-up-where-left-off), with the anti-churn sev≥3 citation gate.
- [x] **RATCHET-03**: The conformance + motion grep gates are tightened to close current
  escapes (`text-lg/xl/2xl`, arbitrary `tracking-[…]`, `ease-in`, layout-property
  transitions) and run in CI.
- [x] **RATCHET-04**: Playwright structural assertions enforce machine-checkable pillar facts
  (visible focus rings, ARIA roles/states, ≥44px touch targets, `font-weight ∈ {400,700}`,
  accent-only-on-allowlist, reduced-motion collapses durations).
- [x] **RATCHET-05**: An LLM-scored PNG matrix (18-cell live surfaces + gallery) against the
  6-pillar rubric produces committed baseline scores (`docs/ui-baseline-scores.json`); PNGs
  remain gitignored (no pixel-diff).

### RESEARCH — Front-loaded Decision Dossier

- [ ] **RESEARCH-01**: A motion dossier distills Emil Kowalski (emilkowal.ski) + platform HIG
  into a locked easing/duration/property decision table within the hard constraints.
- [ ] **RESEARCH-02**: An IA dossier distills gov.uk Design System / Nielsen patterns into
  locked per-surface IA decisions (master-detail / filter / triage), with loved-vs-hated evidence.
- [ ] **RESEARCH-03**: A component-state dossier locks the canonical state matrix per component
  archetype.
- [ ] **RESEARCH-04**: A dark-mode dossier locks dark-mode pitfalls and decisions (elevation,
  desaturation, focus-ring contrast).
- [ ] **RESEARCH-05**: A microcopy dossier locks "thoughtful maintainer" voice patterns mapped
  to each surface's JTBD.

  *(Each dossier ends in an adversarially-synthesized LOCKED DECISION block; the main thread
  consumes only those blocks.)*

### COMP — Individual Component Quality

- [ ] **COMP-01**: Every shared component (icon, logo, flash, badge, status_badge, shell,
  orientation_strip, nav_link, theme_toggle, tenant_chip) is on-brand in light + dark for
  color, type, spacing, radius, and shadow.
- [ ] **COMP-02**: Every component renders correct, on-brand interaction states
  (rest/hover/focus/active/disabled/loading/empty/error) per the locked state matrix.
- [ ] **COMP-03**: `status_badge`/`badge` color + icon mappings are deterministic, on-token,
  and legible in both themes across every status/outcome atom.

### GALLERY — Storybook-lens Audit Surface

- [ ] **GALLERY-01**: A dev-only component gallery LiveView (`/dev/mail/gallery`, in the dev
  live_session only — never `/ops`) renders every component × every state × light/dark from an
  in-code specimen list (no DB).
- [ ] **GALLERY-02**: Each gallery cell carries a stable `data-testid` so it can be
  screenshotted/scored and structurally asserted (feeds the RATCHET layers).

### GROUP — Meta-component Composition

- [ ] **GROUP-01**: Component groups (filter cards, master-detail split, support-card triage
  grid, timeline, detail pane, modal) compose with consistent, on-brand inter-group spacing
  and visual rhythm on every surface.
- [ ] **GROUP-02**: An inbound overview / at-a-glance tier exists, mirroring the operator
  support-card triage pattern (closing the inbound "structurally thin" gap).
- [ ] **GROUP-03**: The inbound `RoutingTrace` and `EvidenceCard` are reworked into scannable,
  on-token group layouts (aligned clause grid + mono chips on `surface-sunken`; a clear
  locked/info reveal affordance).

### PAGE — Page-level Information Architecture

- [ ] **PAGE-01**: Each surface's information architecture follows principle-of-least-surprise
  (gov.uk-style), orienting both first-time and advanced operators on landing.
- [ ] **PAGE-02**: Each page lays out its happy path, primary error states, and boundary/edge
  states coherently and on-brand.
- [ ] **PAGE-03**: The Preview chrome gains full dark-mode support at parity with Operator and
  Inbound (the previewed email keeps its own independent dark-chrome toggle).

### RESP — Responsive

- [ ] **RESP-01**: Every surface is mobile-first responsive and legible/usable at 390/768/1440
  (master-detail stacks cleanly; dense layouts such as RoutingTrace stay scannable at 390px).

### FLOW — Flow-grounded Validation

- [ ] **FLOW-01**: Deterministic seed/fixture data exercises happy, error, boundary, and edge
  states for both operator and inbound surfaces (all statuses/outcomes, suppression-flagged,
  long-content truncation, empty tenant, many-item lists, missing evidence) — reachable by
  seeded URL.
- [ ] **FLOW-02**: Each uplifted surface is validated end-to-end against its real JTBD flow
  (audit-why-a-delivery-failed; why-did-inbound-not-route; preview-a-message-before-send).

### COPY — Microcopy

- [ ] **COPY-01**: Empty / error / loading / confirmation microcopy across all three surfaces
  is in the "thoughtful maintainer" voice and serves the surface's JTBD (plain language, names
  the cause, never "Oops").

### MOTION — Micro-interaction

- [ ] **MOTION-01**: Micro-animations are upgraded within the hard constraints (token-named
  easing, real enter/exit asymmetry, first-mount stagger, loading skeletons, focus transitions,
  View-Transitions progressive enhancement) — no springs/overshoot, no layout-property
  animation, no client JS hook.
- [ ] **MOTION-02**: `prefers-reduced-motion` collapses all motion and the motion conformance
  gate stays green.

### A11Y — Accessibility (cross-cutting)

- [ ] **A11Y-01**: Interactive elements have visible focus rings, correct ARIA roles/states
  (`aria-current`, `aria-selected`, `role="dialog"` + `aria-modal`), semantic heading hierarchy
  (one `h1` per page), and ≥44px touch targets.
- [ ] **A11Y-02**: All text meets WCAG AA contrast in both themes on its *actual* surface
  (computed and verified).

## Future Requirements (deferred)

- Core mailglass **email-template HEEx component** design-system uplift (recipients' inboxes;
  email-client CSS constraints) — candidate future milestone.
- Promote backlog Phase 999.1 (human-readable code comments + GSD artifact cleanup) / 999.2
  (shift-left email screenshot + responsive preview workflow) via `/gsd-review-backlog`.
- Register `guard-release-trigger` as a required branch-protection check once a PR has
  exercised it (carried v1.10 follow-up).

## Out of Scope

- **Real Storybook / `phx_storybook`** — zero-Node hard rule forbids a Node-based Storybook;
  the "Storybook lens" is realized as a thin dev-only LiveView gallery (GALLERY-01).
- **Pixel-diff visual regression** — banned (D-07: fonts + relative-asset-URL + anti-aliasing
  flap). Structural assertions gate CI; LLM scores gate the milestone.
- **Brand-book / token *authoring*** — `brandbook/tokens.css` is the source of truth this
  milestone consumes; changing the brand is not in scope.
- **New product surface area** — no new operator capabilities, providers, or routes (except
  the dev gallery).
- **Forcing a Hex release** — release is prepare-only; the linked-version bump decision is made
  at close.

## Traceability

REQ-ID → Phase mapping for v1.11 (Phases 94–103). All 34 v1.11 requirements map to
exactly one phase — 100% coverage, no orphans, no double-maps.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOKEN-01 | Phase 94 | Complete |
| TOKEN-02 | Phase 94 | Complete |
| TOKEN-03 | Phase 94 | Complete |
| TOKEN-04 | Phase 94 | Complete |
| TOKEN-05 | Phase 94 | Complete |
| RATCHET-03 | Phase 94 | Complete |
| RATCHET-01 | Phase 95 | Complete |
| RATCHET-02 | Phase 95 | Complete |
| RATCHET-04 | Phase 95 | Complete |
| RATCHET-05 | Phase 95 | Complete |
| RESEARCH-01 | Phase 96 | Pending |
| RESEARCH-02 | Phase 96 | Pending |
| RESEARCH-03 | Phase 96 | Pending |
| RESEARCH-04 | Phase 96 | Pending |
| RESEARCH-05 | Phase 96 | Pending |
| COMP-01 | Phase 97 | Pending |
| COMP-02 | Phase 97 | Pending |
| COMP-03 | Phase 97 | Pending |
| GALLERY-01 | Phase 97 | Pending |
| GALLERY-02 | Phase 97 | Pending |
| GROUP-01 | Phase 98 | Pending |
| PAGE-01 | Phase 98 | Pending |
| PAGE-02 | Phase 98 | Pending |
| RESP-01 | Phase 98 | Pending |
| FLOW-01 | Phase 98 | Pending |
| FLOW-02 | Phase 98 | Pending |
| A11Y-01 | Phase 98 | Pending |
| A11Y-02 | Phase 98 | Pending |
| GROUP-02 | Phase 99 | Pending |
| GROUP-03 | Phase 99 | Pending |
| PAGE-03 | Phase 100 | Pending |
| COPY-01 | Phase 101 | Pending |
| MOTION-01 | Phase 102 | Pending |
| MOTION-02 | Phase 102 | Pending |

**Coverage:** 34/34 v1.11 requirements mapped to exactly one phase ✓

**Cross-cutting note:** GROUP-01, PAGE-01, PAGE-02, RESP-01, FLOW-01, FLOW-02, A11Y-01,
and A11Y-02 are introduced and anchored on the Operator surface (Phase 98) and then
**re-applied per-surface** on the Inbound surface (Phase 99) and Preview surface
(Phase 100). For single-phase traceability they are counted once at their anchor
(Phase 98); Phases 99 and 100 satisfy these same cross-cutting requirements for their
own surfaces as stated in their phase goals. Phase 103 (closeout) verifies all 34
REQ-IDs but anchors no net-new requirement.
