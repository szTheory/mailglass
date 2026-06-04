# Requirements: mailglass — v1.7 Admin UI: IA & Design-System Polish v2

**Defined:** 2026-06-03
**Core Value:** Email you can see, audit, and trust before it ships. (This milestone raises the *seeing/auditing* surface — the admin dashboard — to "v2 polish" without expanding the product boundary.)
**Milestone goal:** Take `mailglass_admin` to a consistent, brand-distinct, intuitive, joy-to-use design system where each reused component pays dividends, with information architecture that orients every persona on landing and seed data that fully expresses every screen state — by *applying the existing shipped design system more completely* (no new deps, no brand-book amendment).
**Research:** `.planning/research/v1.7-admin-ui-polish/` (STACK / FEATURES / ARCHITECTURE / PITFALLS / SUMMARY). Founding research at `.planning/research/*.md` is preserved untouched.
**Locked forks:** Fork A = in-library Operator Overview landing + generalized orientation strips. Fork B = within current brand book (motion + expressive seed + sharper hierarchy, not new visual loudness). See PROJECT.md D-24.

> **Anti-churn contract (gate):** No build task ships without citing a Phase-74 gap-register row of **severity ≥ 3**. The gap register is the gate. Every requirement below traces to a phase; every build task traces to a gap row.

## v1.7 Requirements

### Audit & UI-SPEC (Phase 74 — evidence gate, no code)

- [x] **AUDIT-01**: Maintainer can review a scored **gap register** covering the full surface × theme (light/dark) × viewport (390 / 768 / 1440) × state matrix, each row recording `{surface, component:line, pillar, severity 1–5, evidence PNG, fix sketch}` — including an explicit **390px mobile** pass.
- [x] **AUDIT-02**: A **frozen UI-SPEC** defines per-surface target end-state: the **canonical status→color taxonomy table** (resolving the three-way `badge_class/1` conflict, notably `:suppressed`), the support-card hierarchy redesign, the empty/error/loading state inventory, motion assignments, and per-surface acceptance checklists.
- [x] **AUDIT-03**: A committed **before-baseline** exists — gitignored screenshot set + an inventory of every demo/e2e heading and seed-count assertion later phases will ripple — so Phase 79 can diff against it.

### Information Architecture & Orientation (Phase 75)

- [x] **IA-01**: Deliveries, Inbound, and Preview each render the **shared shell-level orientation strip** with per-surface content (generalized from the Deliveries-only original at `operator_live.ex`).
- [x] **IA-02**: An operator landing on `/ops/mail/` reaches a task-oriented **Operator Overview** (a new `:overview` action on the existing OperatorLive, no router-macro change) that routes to Deliveries/Inbound and surfaces at-a-glance health (orphan backlog, recent failures, suppression count).
- [x] **IA-03**: Page titles, subtitles, and headings follow **one deliberate IA vocabulary** across surfaces, with `operator.spec.js` + demo specs updated in the same change.
- [x] **IA-04**: The deep-link-unstyled-CSS asset fix carries an **explicit, recorded in-scope / deferred decision** (it touches a stable asset-serving seam → gated decision).

### Design-System Hardening (Phase 76)

- [x] **DS-01**: One unified **`status_badge` atom** in `components.ex` renders every delivery/event/inbound status from the canonical taxonomy (icon + label, never color alone); the three private `badge_class/1` copies are deleted and all call sites route through it with no unintended color change.
- [x] **DS-02**: `support_cards.ex` and the operator/inbound render bodies use **only the v1 token scale** — zero raw `text-sm/base/xs`, zero faux-bold (`font-medium/semibold`), zero off-grid gaps in admin HEEx (grep-enforced).
- [x] **DS-03**: The dense 2×2 support-card grid is **restructured into a primary/secondary hierarchy** (actionable/non-zero cards prominent; zero-state demoted to a compact summary row) — restructure first, then tokenize.
- [x] **DS-04**: The admin asset bundle is **rebuilt and committed** so `git diff --exit-code priv/static/` is clean.

### Motion & Microinteraction (Phase 77)

- [ ] **MOTION-01**: The existing six-motion vocabulary is applied **only where the UI-SPEC assigns it**, with entrances firing on mount (record-keyed ids — fixes the `motion-reveal` re-fire on `operator_live.ex`) not on every LiveView patch.
- [ ] **MOTION-02**: Motion respects `prefers-reduced-motion`, animates **transform/opacity only** (no height/width), and stays **≤ 300ms** with exits faster than entrances.

### Seed-Data Expressiveness (Phase 78)

- [ ] **SEED-01**: Demo seed data makes **every screen state reachable by a seeded URL** — each delivery status, each inbound outcome (accept/no_match/reject/bounce/ignore), a failed-ingest row, an orphan-backlog row, each replay outcome (failed/noop/replayed), reconciled + unmatched facts (both support-card branches), an empty-result tenant, and long recipient/subject truncation stress.
- [ ] **SEED-02**: Demo reset tests + `demo.spec.js` seed-count assertions are updated in the **same change** as the seed expansion (no broken specs across the commit boundary).

### Verification & Visual-Regression (Phase 79 — closeout)

- [ ] **VERIF-01**: The full audit matrix is re-run with a **before/after PNG diff vs the Phase-74 baseline**, leaving **zero open severity-4/5 gap rows**.
- [ ] **VERIF-02**: `operator.spec.js` is extended and **inbound/preview structural coverage** added for new IA/testids; e2e is green (structural, not pixel-based).
- [ ] **VERIF-03**: The final **conformance grep gate** (zero raw type tokens; exactly one status→color definition) and **bundle-clean gate** pass, and the screenshot→LLM-critique loop is documented as a repeatable local ritual.
- [ ] **VERIF-04**: The deep-link bug is **resolved or explicitly deferred** with recorded rationale (closes the AUDIT-01 row so closeout's zero-sev-4/5 criterion holds).

## v2 Requirements

Deferred to future iteration. Tracked, not in this roadmap.

### Brand expression

- **BRAND-NEXT-01**: Any brand-book *amendment* for additional visual expressiveness (Fork B explicitly chose to stay within the current brand book for v1.7).

### Visual regression automation

- **VR-NEXT-01**: Promote the local screenshot→LLM-critique loop into a deterministic, CI-runnable visual-regression check (v1.7 keeps it local/ad-hoc by design — Node-free + non-deterministic pixels make CI promotion a separate effort).

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New dependencies / tools | This is *application* of the shipped Tailwind v4 / daisyUI 5 / LiveView system; research verified no additions are needed. |
| Brand-book amendment / new visual loudness | Fork B locked: pop/joy comes from motion + seed + hierarchy within the restrained palette (flat, ≤10% Glass-accent, weights 400/700). |
| Changes to stable seams | Router macros, `MailglassAdmin.Auth` behaviour, replay semantics, operator session contract are untouchable. DOM/CSS/LiveView internals are free to churn. |
| Bumping `reference/host_app` / `demo_app` mailglass version pins | Frozen deterministic baseline — that is the separate coordinated 5-file change, not this milestone. Editing demo seed *data* is in scope. |
| CI-promoted visual-regression / LLM critique | Non-deterministic pixels + unversioned `agent-browser` CLI; the LLM-critique loop stays local. CI stays Node-free + deterministic (structural e2e + grep + bundle diff). |
| New product/observability features in the admin | Convergence posture (D-23): this is a quality investment, not feature growth. No new data surfaces beyond the Overview's at-a-glance reuse of existing summaries. |
| Single global library "home" dashboard | The two-mount split (Author vs Operator) deliberately enforces progressive disclosure; the cross-mount task-home lives in the demo app, not the library. |

## Traceability

Phase mapping derived from the locked blueprint; the roadmapper validates 100% coverage and finalizes. Continuing phase numbering from v1.6 (last phase 73).

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIT-01 | Phase 74 | Complete |
| AUDIT-02 | Phase 74 | Complete |
| AUDIT-03 | Phase 74 | Complete |
| IA-01 | Phase 75 | Complete |
| IA-02 | Phase 75 | Complete |
| IA-03 | Phase 75 | Complete |
| IA-04 | Phase 75 | Complete |
| DS-01 | Phase 76 | Complete |
| DS-02 | Phase 76 | Complete |
| DS-03 | Phase 76 | Complete |
| DS-04 | Phase 76 | Complete |
| MOTION-01 | Phase 77 | Pending |
| MOTION-02 | Phase 77 | Pending |
| SEED-01 | Phase 78 | Pending |
| SEED-02 | Phase 78 | Pending |
| VERIF-01 | Phase 79 | Pending |
| VERIF-02 | Phase 79 | Pending |
| VERIF-03 | Phase 79 | Pending |
| VERIF-04 | Phase 79 | Pending |
