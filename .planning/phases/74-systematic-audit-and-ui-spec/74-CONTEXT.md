# Phase 74: Systematic Audit and UI-SPEC - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 74 is the **evidence-only gate** for milestone v1.7 (Admin UI — IA & Design-System Polish v2). It produces, with **zero lines of production code changed**:

1. A scored **gap register** covering the surface × theme (light/dark) × viewport (390/768/1440) × state matrix (AUDIT-01).
2. A **frozen UI-SPEC** with the canonical status→color taxonomy table, support-card hierarchy redesign, empty/error/loading state inventory, motion assignment matrix, and per-surface acceptance checklists (AUDIT-02).
3. A committed **before-baseline**: gitignored screenshot set + an assertion inventory of every demo/e2e heading and seed-count assertion that phases 75-78 will ripple (AUDIT-03).

These artifacts gate every build phase (75-79). The anti-churn contract makes the gap register the only gate: no build task in Phases 75-78 ships without citing a Phase 74 gap-register row at severity ≥ 3.

**In scope:** audit methodology, artifact authoring, evidence capture, recording (not resolving) open technical questions.
**Out of scope:** any production code change; resolving the three open technical questions; building anything from phases 75-79.
</domain>

<decisions>
## Implementation Decisions

### Artifact Format, Location & Freeze Mechanics
- **D-01:** The gap register, UI-SPEC, and assertion inventory are committed Markdown files in the Phase 74 directory (`.planning/phases/74-systematic-audit-and-ui-spec/`). The UI-SPEC is authored as the canonical `74-UI-SPEC.md` carrying GSD `status: approved` YAML frontmatter (mirrors repo precedent `22-UI-SPEC.md`, `65-UI-SPEC.md`; `components.ex:105` already cites a UI-SPEC section from source).
- **D-02:** Every gap-register row carries a **stable `GAP-NN` row ID**. This is the mechanism that makes the ROADMAP anti-churn citation gate (build tasks must cite a row at severity ≥ 3) mechanically enforceable. Unstable identifiers are forbidden — they degrade the gate to honor-system.
- **D-03:** "Frozen" is enforced by the UI-SPEC's `status: approved` frontmatter plus the stable `GAP-NN` IDs. Once approved, the taxonomy table, support-card layout, state inventory, and motion matrix are the locked source of truth every later phase consumes.

### Severity Rubric & Pillar Dimension
- **D-04:** The 1-5 severity rubric and the `pillar` dimension are defined **self-contained inside the UI-SPEC/gap-register header** (no external rubric file exists). Each row's `pillar` maps to one of the 6 conformance pillars already enumerated in `mailglass_admin/docs/design-system.md:104-121` (spacing/size, radius, color, type, elevation/stacking, motion + a11y). Do **not** invent a parallel pillar taxonomy.
- **D-05:** Severity is anchored to the Phase 79 closeout gate: **sev-4/5 = blocks closeout** ("zero open severity-4/5 gap-register rows" per ROADMAP Phase 79). This fixes the meaning of the top of the scale so the existing token/motion grep gates map cleanly back to rows.

### Before-Baseline Capture & Reconciliation
- **D-06:** "Committed before-baseline" = commit the **text assertion inventory** + gap-register PNG **path references** into the phase directory. The **PNG binaries stay gitignored** in `tmp/ui-audit/` (per `scripts/ui-audit.sh` `OUT` default and `.gitignore` `/tmp/`). The committed durable artifact is the inventory; the PNGs are reproducible evidence, never committed binaries.
- **D-07:** Screenshots are captured by **extending `scripts/ui-audit.sh`** (agent-browser CLI) across the full **390/768/1440 × light/dark × 3-surface** matrix — including the explicit 390px mobile pass (AUDIT-01). Never write screenshots under `priv/static/` (would trip the `git diff --exit-code priv/static/` bundle gate). The capture tooling stays local/ad-hoc; never promoted to CI (non-deterministic pixels).

### Open Technical Questions → RECORD, Don't Resolve
- **D-08:** Phase 74 **records** all three open technical questions and the deep-link bug; it does **not resolve** any of them (zero-code constraint). Resolution happens in build phases.
- **D-09:** **(a) Preview empty state already EXISTS** — `preview_live.ex:291` `@mailables == []` branch, testid `preview-empty-mailables`, copy "No mailables discovered". Recorded as **present**; no new trigger condition needed. (Resolves the SUMMARY "unread file" flag.)
- **D-10:** **(b) Tenant-scoped suppression count is ABSENT** — `Mailglass.Operator.Suppressions` exposes only `get_delivery_suppression_state/2` (per-delivery `limit(1)`); no count function. Recorded that **`count_active_suppressions/1` must be added as a small additive core function in a build phase (Phase 75)**. Phase 74 only records absent+required; the Phase-75-vs-dedicated-step sequencing is the planner's call.
- **D-11:** **(c) Deep-link unstyled-CSS bug** — filed as a gap row with **recommended disposition: explicitly deferred to Phase 79** (it touches the stable asset-serving seam, per `design-system.md:142-150`). Phase 75 owns the formal in-scope/deferred decision (IA-04); Phase 79 owns closure (VERIF-04). Phase 74 files the row at the correct severity so closeout has no un-filed blocker.

### Three-Way Badge Taxonomy Table Construction
- **D-12:** The canonical taxonomy table compares **all three `badge_class/1` copies side-by-side**, keyed by atom name + namespace, against the FEATURES canonical taxonomy as the single source of truth. It must surface **three** conflicts, not just the headline `:suppressed`:
  1. `deliveries_list.ex:83` maps a phantom `:suppressed`→Amber/warning with **no canonical row** (canonical equivalent is `:unsubscribed`→Amber).
  2. `records_list.ex:97-99` uses **singular** inbound atoms (`:accept`/`:reject`/`:bounce`) while canonical uses **past-tense** (`:accepted`/`:rejected`/`:bounced`).
  3. `timeline.ex:130-135` returns the **full** `"badge badge-outline …"` string (includes base `badge`) while the other two return only the modifier and let the call site prepend `"badge badge-sm"`.
- **D-13:** Every conflict is **explicitly resolved in the frozen table** against the FEATURES canonical taxonomy, and the table specifies whether the future unified atom returns the base `badge` class (standardizing the timeline divergence). This is the artifact that prevents Phase 76's silent-color-change (Pitfall 5) and JIT-dynamic-class (Pitfall 1) failures.

### Claude's Discretion
- Exact gap-register column ordering and Markdown table layout (within the `{surface, component:line, pillar, severity 1–5, evidence PNG, fix sketch}` schema from AUDIT-01).
- Whether the assertion inventory is a section of `74-UI-SPEC.md` or a sibling `74-ASSERTION-INVENTORY.md` — both satisfy AUDIT-03; planner picks for readability.
- The precise shell extension to `scripts/ui-audit.sh` for the viewport matrix.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.7-admin-ui-polish/SUMMARY.md` — HIGH-confidence synthesis; phase-by-phase deliverables and pitfalls. Read fully.
- `.planning/research/v1.7-admin-ui-polish/FEATURES.md` — **canonical status taxonomy table** (single source of truth for D-12/D-13) + empty-state copy rules.
- `.planning/research/v1.7-admin-ui-polish/ARCHITECTURE.md` — concrete file:line references for every structural change.
- `.planning/research/v1.7-admin-ui-polish/PITFALLS.md` — 17 pitfalls with phase-to-prevention mapping (esp. Pitfall 1 JIT, Pitfall 5 silent color change, Pitfall 16 deep-link).
- `.planning/research/v1.7-admin-ui-polish/STACK.md` — Tailwind/daisyUI/LiveView mechanics; daisyUI 5 class names must be verified against the installed plugin, not web search.
- `.planning/ROADMAP.md` — Phase 74 success criteria + cross-cutting anti-churn contract (severity ≥ 3 citation gate).
- `.planning/REQUIREMENTS.md` — AUDIT-01..03 acceptance criteria.
- `mailglass_admin/docs/design-system.md` — the **6 conformance pillars** (D-04), audit ritual mechanics, `tmp/ui-audit/` gitignore contract, deep-link limitation note.
- `mailglass_admin/scripts/ui-audit.sh` — audit tooling; extend for the 390/768/1440 viewport matrix (D-07).
- Prior UI-SPEC precedents: `.planning/milestones/v0.4-phases/22-operator-data-foundation/22-UI-SPEC.md`, `65-UI-SPEC.md` — `status: approved` frontmatter convention (D-01).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/ui-audit.sh`** — existing audit capture script; writes to gitignored `tmp/ui-audit/`. Extend (don't replace) for the viewport matrix.
- **`mailglass_admin/docs/design-system.md`** — already defines the 6 conformance pillars and audit ritual; the gap-register pillar dimension reuses these verbatim.
- **`components.ex` (~line 91-115)** — existing badge/atom structure; the future `status_badge/1` lands here, but Phase 74 only specifies it.
- **GSD UI-SPEC convention** — `gsd-ui-researcher`/`gsd-ui-checker` produce `{phase}-UI-SPEC.md` with `status: approved` frontmatter; the `workflow.ui_phase: true` flag is set, so `/gsd-ui-phase 74` is the intended authoring path for the UI-SPEC deliverable.

### Established Patterns
- **Three diverging `badge_class/1` copies** in `operator/deliveries_list.ex` (lines 80-84), `operator/timeline.ex` (lines 130-135), `inbound/records_list.ex` (lines 97-101). Confirmed to disagree on atom coverage, atom tense, and base-class string (D-12).
- **Stable seams (untouchable):** `mailglass_operator_routes/2` router macro, `MailglassAdmin.Auth` behaviour, replay semantics, operator session contract, asset-serving strategy.
- **Bundle gate:** `git diff --exit-code priv/static/` — never write audit artifacts there.

### Integration Points
- Operator Overview health data reuses `Mailglass.Operator.SupportSummary.summarize_tenant/1` (existing seam) — Phase 74 records this; no change.
- `Mailglass.Operator.Suppressions` — read-only confirmation that no tenant-scoped active count exists (D-10).
- `preview_live.ex:291` — existing zero-mailables empty state (D-09).
- e2e assertion surfaces: `mailglass_admin/e2e/operator.spec.js` + `reference/demo_app/assets/e2e/demo.spec.js` — assertion inventory source (AUDIT-03).
</code_context>

<specifics>
## Specific Ideas

- The gap register must include an **explicit 390px mobile pass** — AUDIT-01 calls it out, and Pitfall 15 (390px audit gap) is the failure mode.
- The taxonomy table is the **highest-risk artifact** in the milestone (SUMMARY: badge consolidation silently changes a status color unless all three copies are compared side-by-side first). Treat its construction as the phase's critical deliverable.
- Milestone scope note to carry into the UI-SPEC: linked-version release mechanics will produce matched version bumps across all three packages — administrative entries for core/inbound, expected and correct.
</specifics>

<deferred>
## Deferred Ideas

- **`count_active_suppressions/1` core function** — required for the Operator Overview suppression-count health number, but it is a code change → belongs to a build phase (Phase 75), recorded only here (D-10).
- **Deep-link unstyled-CSS robust fix** — recommended deferral to Phase 79; formal decision is IA-04 (Phase 75). Phase 74 only files the gap row (D-11).
- **CI-promoted visual regression / LLM-critique loop** — explicitly out of v1.7 scope (VR-NEXT-01); the screenshot→LLM-critique ritual stays local/ad-hoc.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 74 scope.
</deferred>
