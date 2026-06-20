# Phase 116: Fixtures + Idempotent Ratchet-Arm - Context

**Gathered:** 2026-06-20 (assumptions mode + research-driven synthesis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 116 is the **keystone ratchet-arm** of milestone v1.13 (Admin Design-System Stress Test &
UX Uplift). Gates were tightened per-phase across 109–115; the **full pillar re-score happens ONLY
here**, after the multi-tenant stress fixtures land. Five requirements:

- **RATCHET-01** — realistic 2–3-tenant persona stress-fixture cohort (no-data / one / many /
  long-ID / non-ASCII / null / high-count / error edge data) in `reference/demo_app` seeds + gallery
  stress specimens, giving the tenant picker a reason to exist.
- **RATCHET-02** — widen the dev component-lab gallery to a component × state × {light,dark,system}
  × {320…wide} matrix.
- **RATCHET-03** — the ratchet gains an interaction pillar (panel-above-scrim hit-test,
  scroll-chaining, focus-restore-to-trigger, layout-jump) AND a WCAG 2.2 AA axe-violation JSON
  baseline — both screenshot-free, no pixel-diff.
- **RATCHET-04** — run the full matrix INCLUDING ≥1 run against rich `reference/demo_app` data,
  then promote `current → prior` and re-score with all gates green (meet-or-beat, zero regressions).
- **RATCHET-05** — close all 24 enumerated usability defects (PITFALLS Bucket A), each with a
  regression guard.

**Scope locks (inherited from v1.13):** Admin + demo only. No new product capability / providers /
transports / routes. Brandbook tokens are OUT (brand book is source of truth). Host-app-friendly:
tenant listing from the CORE read model scoped via `Mailglass.Tenancy.scope/2` through the
authenticated actor, never raw admin Repo. Zero-Node asset pipeline. NO pixel-diff regression — ever
(structural + axe-JSON + score-baseline only). Only net-new dependency is the test-only npm devDep
`@axe-core/playwright`; zero new Hex deps. The full pillar re-score happens ONLY in this phase.
</domain>

<decisions>
## Implementation Decisions

### A. Ratchet primitives — interaction pillar + axe baseline (RATCHET-02, RATCHET-03)

- **D-01:** The **interaction pillar is a separate *binary* pass/fail Playwright gate set**,
  extending the existing `assertPanelAboveScrim` precedent in `e2e/structural.spec.js` — NOT a 7th
  LLM-scored pillar. The four named invariants (panel-above-scrim hit-test, scroll-chaining /
  overscroll-contain, focus-restore-to-trigger, layout-jump / CLS) are each parameterized across
  deliveries/inbound/preview × light/dark/system. Rationale: these are true/false properties an LLM
  scoring a static PNG cannot observe and a 1–4 aesthetic rubric must not be able to trade away; the
  failing test name *is* the diagnosis.

- **D-02:** The scored matrix **stays at 54 cells (3 surfaces × 6 pillars × 3 themes),
  schema_version 3, untouched.** Phase 116 does NOT add a pillar or bump the score schema. It DOES
  perform the milestone's only full pillar re-score: regenerate `current`, promote prior→… per the
  existing `compare_baselines/2` meet-or-beat comparator, all 54 cells meet-or-beat (zero regression).

- **D-03:** The axe baseline is a **new, separate file `mailglass_admin/docs/axe-baseline.json`**
  (sibling to `ui-baseline-scores.json`, same `docs/` location reachable via the `__DIR__`-relative
  path trick), with `schema_version: 1`. **Format = hybrid:** per-surface × theme violation
  **counts (meet-or-beat / zero-new floor) + a rule-id → count breakdown** so a regression is
  diagnosable as e.g. `"inbound.dark: color-contrast 0 → 2 (REGRESSION)"`. Each `violations` block is
  `surface → theme → { total, rules }`; `[role=dialog]` overlay violations fold into the surface that
  opened them (3×3 = 9 cells per block). **Rejected:** node-fingerprint snapshots (brittle to
  v1.13's heavy DOM/class churn) and bare rule-id allowlists (false-green on new nodes under an
  allowlisted rule).

- **D-04:** The axe baseline comparator is **`mailglass_admin/test/mailglass_admin/axe_baseline_test.exs`,
  a near-clone of `ratchet_baseline_test.exs`** — assert `schema_version == 1`; all 9 surface×theme
  cells present in BOTH prior and current (fail closed on missing cell, never coerce to 0);
  `prior.run_id != current.run_id` (anti-vacuity); meet-or-beat per cell with a rule-id diff that
  fails closed when any rule's count rises OR a rule-id present in current is absent in prior (even if
  the total held flat).

- **D-05:** The axe scan uses **`@axe-core/playwright ^4.11.2` (test-only npm devDep, the only
  net-new dependency)** via `.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])`,
  scanning deliveries/inbound/preview + opened `[role=dialog]` overlays in light/dark/system
  (`emulateMedia` for system). A producer spec (e.g. `e2e/axe-baseline.spec.js`) regenerates
  `current.violations` on demand. Screenshot-free; no pixel-diff.

### B. Stress-fixture cohort + gallery matrix (RATCHET-01, RATCHET-02, RATCHET-04)

- **D-06:** Define the cohort **once** as a declarative persona spec in
  `reference/demo_app/lib/mailglass_demo/personas.ex` (a list of persona maps: name + the 8 edge-case
  assignments + minimal Delivery/Event/InboundMessage payload), materialized by **three thin
  mechanical builders**: (1) demo seed — `DemoData.reset!` calls `Personas.seed!(Repo)`; (2) admin
  e2e — `mailglass_admin/test/support/operator_fixtures.ex` gains `seed_persona_cohort!/0` that
  materializes the SAME spec into `TestRepo`, reaching demo via a **test-only path dep**
  (`only: [:test]`); (3) gallery — mirror the long-ID/non-ASCII/null *values* as named static
  specimen states, library-pure. **Library lib code stays demo-free; only test support crosses the
  boundary.**

- **D-07:** A **drift-guard test** asserts the admin-side cohort materialization matches the
  `Personas` persona-name + edge-case set, so the three materializations cannot diverge (defeats the
  triplication-drift failure mode).

- **D-08:** **Three personas mapped to the 8 edge cases** (domain-true naming per
  `prompts/mailer-domain-language-deep-research.md` + the seven nouns + Anymail event taxonomy;
  additive over today's `northstar` / `empty-tenant`):
  - **`northstar`** (existing — keep as-is) → **many / high-count / error**: full lifecycle (all 14
    Anymail event types, delivered/bounced/deferred/complained/suppressed, replay/orphan/reconcile,
    failed_ingest WebhookEvent, `:bounced` with `reject_reason`). Selectable (has deliveries).
  - **`fjordline-aps`** (NEW — single Delivery) → **one / long-ID / non-ASCII / null**: recipient
    display names `"Bjørn Hansen"` / `"山田太郎"` (non-ASCII `from[].name`), a `del_01JXW…`-class
    long-ID, one event with **`reject_reason: nil`** (legitimate null branch on a `:delivered`,
    distinct from a populated `:rejected`), and a long Mailable module name to stress truncation.
  - **`helios-void`** (NEW — **zero deliveries**) → **no-data**: the load-bearing edge. Because
    `Mailglass.Operator.Tenants.list_tenants/2` keys off **distinct `Delivery.tenant_id`**, this
    persona asserts a no-data tenant is correctly *absent* from the switcher AND that its surface (if
    reached by direct URL) renders the empty/permission state, not a crash. Augments/replaces the bare
    `empty-tenant`.
  - With northstar + fjordline-aps + helios-void, **≥2 selectable tenants exist → the Phase-112
    picker has a real reason to render** (it only appears at ≥2 tenants).

- **D-09:** **Gallery matrix widening keeps the hand-enumerated specimen list as source of truth**
  (preserves the stable `data-testid="gallery-{component}-{state}"` contract the conformance
  awk-assertions + Playwright depend on). Theme stays the existing inline 3-wrapper (light/dark/
  system). **Viewport is a Playwright resize loop over the SAME stable testids** at 320/390/768/wide
  — never new specimen rows. **Rejected:** programmatic cartesian generation (breaks the testid
  contract + the 324-cell explosion SUMMARY §3a warns against).

- **D-10:** **RATCHET-04's "≥1 run against rich demo_app data" extends the already-existing
  `reference/demo_app/assets/e2e` Playwright suite** (config + `/demo/evidence/reset` token flow
  already shipped) with a cohort spec. **No new harness; do NOT bend `OperatorBrowserServer`** (it
  seeds `browser-tenant` against `TestRepo`, a different seam).

### C. Bucket-A closure — RATCHET-05

- **D-11:** Execute RATCHET-05 as an **audit (verify-and-lock), not author-all-24.** ~18 defects
  already shipped a green guard across phases 109–115 → cite the existing gate/test/fixture and prove
  it green. Author **net-new guards only for the ~6 cohort/interaction-dependent residue**:
  - **A3** hover-on-non-interactive-empty-state — Playwright on the **no-data fixture**: enumerate
    elements with a `hover:`-derived transition; assert each is `a,button,[role=button],[phx-click],
    [tabindex]`.
  - **A4 / A23** floating element overlaps a primary CTA — Playwright: for each open floating element
    (theme menu, tooltip, flash), assert its rect does NOT overlap any `btn-primary` rect.
  - **A16 (system)** dark contrast parity under **`theme=system`** — extend the contrast matrix to
    `prefers-color-scheme: dark` + system, asserting parity with explicit-dark.
  - **A21** loading-state CLS / layout-jump — Playwright: capture a region's
    `getBoundingClientRect().height` loading-vs-loaded; assert delta ≤ threshold.
  - **A22** skeleton overuse on synchronous surfaces — assert synchronous surfaces (inbound mount)
    show no skeleton; extends the existing "loading contract remains synchronous" test.
  - **A11** table-overuse justification — per-`<table>` audit row + a count-must-not-increase grep
    inventory.
  These 6 correctly land here because they depend on the RATCHET-01 cohort existing first.

- **D-12:** The durable closure artifact is an **executable manifest
  `mailglass_admin/test/.../bucket_a_coverage_test.exs`** mapping each `A-NN → {guard_kind, locator,
  status}` where `guard_kind ∈ {:grep_gate, :playwright_testid, :playwright_title, :axe, :fixture}`.
  The test **asserts the cited guard physically still exists** (gate name present in
  `check-conformance.sh`; `data-testid`/title string literal present in `e2e/*.spec.js`; fixture
  testid present) — so CI keeps the ledger honest and a stale citation fails closed (defeats the #1
  traceability-doc failure: silent drift). Governed by the same **stable-ID / never-delete /
  `downgraded`-not-deleted contract as `RATCHET-GAP-REGISTER.md`**; a regression *reopens* a row, the
  row is never removed. A thin `.planning/research/v1.13/BUCKET-A-LEDGER.md` mirrors it for humans
  (never the source of truth).

### Claude's Discretion

- Exact file names/locations for the new producer specs and the bucket-A coverage test may be
  refined at plan time, provided they honor D-03/D-04/D-12 (docs/-sibling axe JSON, ExUnit
  fail-closed comparator clone, executable manifest).
- The precise CLS delta threshold (D-11, A21) and the exact long-ID/non-ASCII literal values
  (D-08) are implementation details for the planner/executor, provided they are domain-true.

### Folded Todos

None — `todo.match-phase 116` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 116 detail + RATCHET-01..05; execution-order + research flags.
- `.planning/REQUIREMENTS.md` — RATCHET-01..05 acceptance text.
- `.planning/research/v1.13/PITFALLS.md` — **Bucket A: the full 24-defect list (A1..A24)**, each with
  a proposed Guard/test + the pitfall→fractal-level map (the RATCHET-05 source of truth).
- `.planning/research/v1.13/SUMMARY.md` — axe-JSON baseline open question + ratchet schema-v3 notes +
  the 324-cell-explosion warning (§3a) the gallery viewport decision (D-09) rests on.
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — the meet-or-beat comparator
  template `axe_baseline_test.exs` clones (schema_version, prior/current/run_id, `is_nil` fail-closed
  guard, `compare_baselines/2`).
- `mailglass_admin/docs/ui-baseline-scores.json` — the 54-cell score baseline (schema/shape template;
  how `system` was seeded in Phase 109).
- `mailglass_admin/docs/design-system.md` — the 1–4 pillar rubric + D-07 scoring procedure +
  established breakpoints.
- `mailglass_admin/e2e/structural.spec.js` — existing interaction assertions (`assertPanelAboveScrim`
  ~L528/1077, focus-keep-on-patch ~L1575, reduced-motion ~L2418) the interaction pillar (D-01)
  extends.
- `mailglass_admin/e2e/flows.spec.js`, `operator.spec.js`, `playwright.config.cjs` — existing
  Playwright harness + structural assertions (Bucket-A guard citations).
- `mailglass_admin/scripts/check-conformance.sh` (+ `check-conformance-advisory.sh`) — named gates
  (STATCARD-GATE, ICON-EXISTS-GATE, Z-INDEX-GATE, FOCUS-RING-GATE, PHASE112-SHELL-GATE, GAP-GATE,
  SPACE-GATE, GROUP-GATE, MOTION-GATE, DATA-STATE-GATE) cited by the Bucket-A manifest.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` — the in-code static specimen list + Coverage
  docstring + `data-testid="gallery-{component}-{state}"` contract (D-09).
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` + `reference/demo_app/priv/repo/seeds.exs` —
  current `northstar`/`empty-tenant` seed (D-06/D-08 build on this).
- `reference/demo_app/assets/playwright.config.cjs` + `reference/demo_app/assets/e2e/demo.spec.js` —
  the existing demo Playwright harness RATCHET-04 extends (D-10).
- `lib/mailglass/operator/tenants.ex` — `list_tenants/2` derives the switcher from distinct
  `Delivery.tenant_id` (the constraint behind helios-void / D-08).
- `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md` — the scoped core
  `list_tenants` read model the cohort must surface through; `PHASE112-SHELL-GATE`.
- `.planning/RATCHET-GAP-REGISTER.md` — the stable-ID / never-delete contract the Bucket-A manifest
  (D-12) mirrors.
- `prompts/mailer-domain-language-deep-research.md` — domain-true persona/recipient/event naming
  (D-08).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Meet-or-beat JSON + ExUnit comparator** (`ratchet_baseline_test.exs`) — the exact template for
  the new axe comparator (D-04): schema_version assertion, prior/current with distinct run_ids,
  `is_nil` fail-closed missing-cell guard, `compare_baselines/2`.
- **Existing binary interaction assertions** in `e2e/structural.spec.js` (`assertPanelAboveScrim`
  hit-test, focus-keep-on-patch, reduced-motion `getAnimations()`) — the interaction pillar (D-01)
  extends this seam rather than inventing one.
- **Existing demo Playwright harness** (`reference/demo_app/assets/playwright.config.cjs` +
  `e2e/demo.spec.js` + `/demo/evidence/reset`) — RATCHET-04 (D-10) adds a spec, not infra.
- **Existing static gallery** (`gallery_live.ex`) with stable `gallery-{component}-{state}` testids
  already carrying `non-ascii-tenant` / `long-value-stress` specimens — additive (D-09).
- **Named conformance gates** in `check-conformance.sh` already guarding ~18 Bucket-A defects — cited,
  not re-authored (D-11).

### Established Patterns
- Fail-closed JSON baseline validated by ExUnit; `prior.run_id != current.run_id` anti-vacuity guard;
  stable-ID / never-delete gap-register contract (`RATCHET-GAP-REGISTER.md`).
- Zero-Node committed `priv/static/app.css`; no pixel-diff regression ever.
- Library lib code never depends on demo; only test support may cross the boundary (test-only path
  dep).
- Tenant listing from the core read model scoped via `Mailglass.Tenancy.scope/2`, never raw admin Repo
  (`PHASE112-SHELL-GATE` enforces).

### Integration Points
- `list_tenants/2` (distinct `Delivery.tenant_id`) ↔ the persona cohort (helios-void zero-delivery
  edge).
- New axe devDep ↔ pinned `@playwright/test ^1.59.1`, single-worker `OperatorBrowserServer` model
  (compatibility is a light plan-phase verification item).
- `current → prior` score promotion ↔ the milestone's only full pillar re-score (RATCHET-04).
</code_context>

<specifics>
## Specific Ideas

- Persona names: `northstar` (keep), `fjordline-aps` (new), `helios-void` (new).
- Non-ASCII recipient display literals: `"Bjørn Hansen"`, `"山田太郎"`.
- Axe failure message shape: `"inbound.dark: color-contrast 0 → 2 (REGRESSION)"`.
- Three fail-closed primitives coexisting: 54-cell aesthetic matrix (schema 3, untouched) + binary
  interaction gates in `structural.spec.js` + 9-cell axe meet-or-beat baseline (schema 1).
</specifics>

<deferred>
## Deferred Ideas

- **Exact `@axe-core/playwright` 4.11.x `AxeResults.violations[]` wire shape** + confirming it
  composes with the pinned `@playwright/test ^1.59.1` single-worker harness and `emulateMedia` for
  system theme → **light `/gsd-plan-phase` research item** (ROADMAP already flags Phase 116 for this).
  The directional format (hybrid counts + rule-id breakdown, separate `docs/axe-baseline.json`) is
  LOCKED here; only the wire-level detail is deferred.
- No product-scope ideas surfaced — analysis stayed within the admin/demo/ratchet boundary.

### Reviewed Todos (not folded)
None — `todo.match-phase 116` returned 0 matches.
</deferred>
