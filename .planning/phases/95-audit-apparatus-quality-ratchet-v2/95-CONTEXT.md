# Phase 95: Audit Apparatus + Quality-Ratchet v2 - Context

**Gathered:** 2026-06-13 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Stand up the **idempotent quality-ratchet apparatus** for the v1.11 admin design-system
uplift and run it **once** to produce a fresh baseline against the now-correct (Phase 94)
brand. Four layers:

1. A committed per-`surface × pillar × theme` **score baseline** with a meet-or-beat
   (only-forward) closeout assertion.
2. A **single carried-forward GAP register** with stable `GAP-NN` IDs (status + run_id),
   idempotent re-run reopen/skip semantics, and the anti-churn sev≥3 citation gate.
3. A **Playwright structural-assertion layer** on machine-checkable pillar facts.
4. An **LLM-scored PNG matrix** (maintainer-run) writing committed baseline scores; PNGs
   gitignored (no pixel-diff).

**In scope:** the ratchet tooling/test/CI/doc artifacts only — the GAP register file, the
score-baseline JSON + its ExUnit assertion, the new Playwright structural spec wired into
the existing required browser lane, the LLM-scoring harness (screenshot generation +
scoring method + committed scores), and the .gitignore/CI wiring. Running the apparatus
**once** to seed the baseline + initial GAP rows.

**Out of scope:**
- Any **UI/markup fix** of the surfaces being measured (the visible refresh lands in
  Phases 97–103; this phase only *measures* and *records gaps*).
- The dev-only **component gallery** (`/dev/mail/gallery`) — built in Phase 97; its absence
  is recorded as a GAP, not a blocker here.
- The **re-run + sev-4/5 closeout + meet-or-beat regression enforcement** — that is Phase
  103 (this phase's baseline is the FIRST run, so there is nothing to "beat" yet).
- Conformance + motion grep gates (RATCHET-03 — already done in Phase 94).
- Any core/inbound functional code; any edit to `brandbook/`.

Requirements: RATCHET-01, RATCHET-02, RATCHET-04, RATCHET-05.
</domain>

<decisions>
## Implementation Decisions

Derived codebase-first (assumptions mode), grounded in the v1.7 gap-register precedent, the
existing Playwright required lane, the existing `ui-audit.sh` 18-cell definition, and the
Phase 94 gate/test discipline. Calibration: minimal_decisive (vendor_philosophy
`opinionated`). One genuinely strategic fork (the 6-pillar rubric identity) was escalated and
resolved by the owner.

### Canonical pillar rubric (RATCHET-01, RATCHET-05) — OWNER-DECIDED
- **D-01:** The canonical 6-pillar rubric is the **project's own `design-system.md` pillar
  set** — **Spacing / Radius / Color / Type / Elevation / Motion+A11y**
  (`mailglass_admin/docs/design-system.md:104-121`) — NOT the generic `gsd-ui-review` skill's
  pillars (Copywriting/Visuals/Color/Typography/Spacing/Experience). "The `gsd-ui-review`
  grade per cell" (RATCHET-01) is read as *the ui-review scoring method applied to the
  project's own pillars*. Both the score baseline (D-03) and the LLM matrix (D-06) key on this
  pillar set.
  - **Why:** RATCHET-04's machine-checkable facts (focus rings, ARIA, ≥44px, font-weight,
    accent-allowlist, reduced-motion) map cleanly onto these pillars; the v1.7 register,
    conformance scripts, and Playwright gates already use them. The committed
    `ui-baseline-scores.json` keys depend on this and are expensive to re-key once downstream
    phases cite them — so it was confirmed by the owner before locking.

### GAP register: fresh carried-forward register (RATCHET-02)
- **D-02:** Create a **new** single carried-forward GAP register at
  **`.planning/RATCHET-GAP-REGISTER.md`** (milestone-root, deliberately NOT phase-buried so it
  spans Phases 95→103). Stable `GAP-NN` IDs **restart at GAP-01** for the v1.11 brand
  baseline. Do **not** migrate or reopen the v1.7 `74-GAP-REGISTER.md` — it is frozen
  (`stable_ids: true`, line 5), its sev-4 rows are all CLOSED (`79-GAP-CLOSEOUT.md:143-151`),
  and it describes pre-rebaseline code.
  - **Schema:** reuse the proven v1.7 column shape
    (`74-GAP-REGISTER.md:26-36`: `GAP-NN | surface | component:line | pillar | sev | evidence
    PNG | fix sketch`) and **add the ratchet columns v1.7 lacked**: `status`
    (open/fixed/downgraded), `run_id`, `first_seen_run`. `pillar` uses the D-01 set.
  - **Idempotent re-run semantics (active from Phase 103, defined here):** a re-run compares
    the new run's per-cell finding/score against the register — a regressed cell **reopens**
    its `GAP-NN`; a settled (fixed) row is **skipped**; each touch stamps the current
    `run_id`. Stable IDs are the join key — never renumber.
  - **Anti-churn gate:** the v1.7 contract — "no build task ships without citing a register row
    at severity ≥ 3" (`74-GAP-REGISTER.md:17-22`) — is the literal continuation, re-targeted at
    this register for downstream Phases 98–103. Planner decides whether the citation gate is a
    checker script or a documented review rule; the register IS the gate.
  - **If the owner later wants one eternal register:** restart-at-GAP-01 would collide with
    v1.7's GAP-01..GAP-22 namespace; the cheap fix is `GAP-101+`, but only if caught before
    downstream phases cite the new IDs. Flagged; chosen path is fresh restart in a new file
    (no namespace overlap because it's a separate file).

### Score baseline storage + meet-or-beat (RATCHET-01)
- **D-03:** Committed score baseline at **`mailglass_admin/docs/ui-baseline-scores.json`**
  (admin package, alongside `design-system.md` — the pillar source), keyed
  `surface → pillar → theme → score` using the D-01 pillars. (Roadmap's literal
  `docs/ui-baseline-scores.json` string is honored as the admin-package `docs/`; the ExUnit
  reader path, the `.gitignore` PNG rule, and the harness output must all agree on this one
  path.)
- **D-04:** The meet-or-beat closeout is a **fail-closed ExUnit test** (e.g.
  `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs`) in the always-run,
  **required** `verify.support_contract.admin` lane — mirroring exactly how
  `token_parity_test.exs` was wired (94-CONTEXT D-02). Pure file I/O + Jason; no
  Postgres/Node/Playwright; never tag-excluded.
- **D-05:** **First-run semantics (this phase = establish-and-freeze).** On Phase 95 there is
  no prior committed baseline to beat, so the assertion's job is to **establish + validate
  self-consistency** (every `surface × pillar × theme` cell present, scores in the declared
  range, shape well-formed) — NOT a regression check. The only-forward meet-or-beat *teeth*
  and the reopen/skip idempotency become active at **Phase 103's re-run**. The test must be
  written so it is a real assertion now (shape/range/coverage) and the regression comparison
  switches on at 103 (planner: structure the test so 103 only adds the prior-vs-current diff,
  not a rewrite). Do NOT make a vacuous no-op "meets-or-beats nothing" gate.

### Playwright structural-assertion layer (RATCHET-04)
- **D-06 (Playwright):** Add a **new spec** (recommend `mailglass_admin/e2e/structural.spec.js`)
  to the **existing required Playwright lane** `operator_browser_gate`
  (`.github/workflows/ci.yml:645-716`, Node 22, `npm run test:operator-browser`). Do NOT spin
  up a new harness. The no-Node-lib constraint is **not** violated: Node lives only in the dev
  `mailglass_admin/` test harness and is excluded from the Hex tarball (same exclusion logic
  as `brandbook/`, 94-CONTEXT lines 51-53).
  - **Fact → assertion mapping** (all map onto patterns the suite already uses in
    `e2e/operator.spec.js`):
    - ARIA roles/states → `toHaveAttribute` (`aria-selected`/`aria-current`/`role="dialog"`,
      operator.spec.js:56-57)
    - ≥44px touch targets → `boundingBox().height >= 44`
    - `font-weight ∈ {400,700}` → `evaluate(getComputedStyle)`
    - reduced-motion collapses durations → `emulateMedia({reducedMotion:"reduce"})`
      (operator.spec.js:229)
    - visible focus rings → focus the element + assert computed `outline`/ring
    - accent-only-on-allowlist → assert accent color appears only on allowlisted selectors
  - **Scope to the 3 LIVE surfaces** that exist now (Operator `/ops/mail`, Inbound
    `/ops/mail/inbound`, Preview `/dev/mail`). Gallery-cell (`data-testid`) structural
    assertions are **deferred to Phase 97** (the gallery doesn't exist yet — asserting on its
    testids now would be a sequencing deadlock). Record the gallery absence as a GAP.

### LLM-scored PNG matrix (RATCHET-05)
- **D-07 (LLM scoring is maintainer-run local, NOT CI):** The LLM-scored PNG matrix is a
  **local maintainer/subagent step**, not a CI lane. Screenshots come from the **existing**
  `mailglass_admin/scripts/ui-audit.sh`, which already produces exactly the **18 cells**:
  **3 surfaces × 3 viewports (390/768/1440) × 2 themes** (`ui-audit.sh:7-12`). The maintainer
  (or a scoring subagent) scores each cell against the D-01 pillars; **only the resulting JSON
  (D-03) is committed; PNGs stay gitignored** (`ui-audit.sh:14-18`, D-07 pixel-diff ban — "do
  NOT promote to CI").
  - **"18-cell" reconciliation:** the existing 18 = surfaces × viewports × themes (the
    screenshot/PNG matrix). The *score baseline* (D-03) keys by `surface × pillar × theme`
    (pillars, not viewports). These are two intentionally different keyings: the PNG matrix is
    the *evidence-capture* grid; the baseline JSON is the *graded* grid. Planner should keep
    them distinct and document the relationship (a cell's PNGs across viewports inform its
    per-pillar score).
  - The roadmap phrase "18-cell live surfaces + gallery" is aspirational; the gallery (Phase
    97) is NOT a prerequisite. Phase 95's run targets the 3 live surfaces only.

### Commit ordering (apparatus-first, every commit green)
- **D-08:** Land the apparatus scaffolding before seeding it, each commit green (mirrors the
  Phase 94 gates-first discipline, D-10):
  1. GAP register file + schema + (if scripted) the citation/idempotency checker — empty or
     header-only, green.
  2. Score-baseline ExUnit assertion (D-04/D-05) shape-validating an initial committed
     `ui-baseline-scores.json` (D-03).
  3. Playwright `structural.spec.js` (D-06) wired into the existing lane, green on the 3 live
     surfaces.
  4. Run the apparatus once: generate PNGs via `ui-audit.sh`, LLM-score, commit the baseline
     JSON (D-07), and populate the initial `GAP-NN` rows (D-02).
  Planner decides exact split so each commit stays green.

### Claude's Discretion
- Exact GAP-register table markdown layout + whether the citation/idempotency check is a shell
  script vs an ExUnit checker vs a documented review rule (validate by running it, per the
  "validate credo by running it" convention applied to gates).
- Exact ExUnit test name/module and the score scale/range (align with the gsd-ui-review
  method's grade scale applied to the project pillars).
- Exact Playwright assertion selectors and how the accent-allowlist is expressed.
- Whether the LLM scoring is invoked via a documented `mix`/script wrapper or a GSD subagent —
  as long as it's local and only the JSON is committed.

### Folded Todos
- None folded. See Reviewed Todos below.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 95 goal + 4 success criteria; Phase 97 (gallery) and Phase
  103 (closeout) dependencies; critical path 94→95→…→103.
- `.planning/REQUIREMENTS.md` — RATCHET-01, RATCHET-02, RATCHET-04, RATCHET-05 (RATCHET-03 done).
- `.planning/STATE.md` — v1.11 milestone intent + scope locks (admin-UI-only, no pixel-diff,
  no new routes, prepare-only release posture, hard design constraints).
- `.planning/phases/94-token-re-baseline-onto-canonical-brand/94-CONTEXT.md` — predecessor;
  fail-closed ExUnit + required-lane wiring pattern (D-02), gates-first commit discipline
  (D-10), Hex-tarball exclusion logic.
- `mailglass_admin/docs/design-system.md` (≈104-121) — **the canonical 6 pillars (D-01)**:
  Spacing / Radius / Color / Type / Elevation / Motion+A11y.
- `.planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` —
  frozen v1.7 register; the column-shape precedent (26-36) + anti-churn sev≥3 contract (17-22)
  the new register continues. DO NOT reopen.
- `.planning/milestones/v1.7-phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`
  — closeout/idempotent-rerun precedent; confirms audit-matrix re-run is a local/ad-hoc step.
- `.planning/milestones/v1.8-phases/80-brand-audit-and-gap-register/` — additional
  gap-register phase precedent.
- `mailglass_admin/scripts/ui-audit.sh` — **existing 18-cell PNG matrix** (3 surfaces × 3
  viewports × 2 themes; PNGs gitignored, do-NOT-promote-to-CI). Source for D-07 screenshots.
- `mailglass_admin/e2e/operator.spec.js` + `mailglass_admin/playwright.config.cjs` — existing
  Playwright required suite; the assertion patterns + boot mechanism RATCHET-04 extends.
- `.github/workflows/ci.yml` (≈645-716 `operator_browser_gate`; `verify.support_contract.admin`)
  — the required lanes the structural spec + baseline test attach to.
- `mailglass_admin/test/mailglass_admin/token_parity_test.exs` — the fail-closed required-lane
  ExUnit pattern to mirror for the score-baseline assertion (D-04).
- `mailglass_admin/test/mailglass_admin/` (brand_test, accessibility_test, bundle_test) —
  test conventions + failure-message style.
- `mailglass_admin/mix.exs` — `verify.*` aliases mapped to required CI lanes; `jason` test dep.
- `~/.claude/get-shit-done/workflows/ui-review.md` (≈124-132) — the gsd-ui-review *method* /
  grade scale (applied to the D-01 project pillars, NOT its generic pillar list).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/ui-audit.sh`** already emits the exact 18-cell PNG matrix (3 surfaces × 3
  viewports × 2 themes), PNGs gitignored — directly reused for RATCHET-05 (D-07).
- **`e2e/operator.spec.js`** already asserts ARIA via `toHaveAttribute`, emulates
  reduced-motion (`emulateMedia`), and uses computed-style/bounding-box checks — the structural
  layer (RATCHET-04) extends these patterns, no new harness (D-06).
- **`token_parity_test.exs`** — the fail-closed, always-run, required-lane ExUnit template for
  the score-baseline assertion (D-04).
- **v1.7 `74-GAP-REGISTER.md`** — proven register column shape + anti-churn sev≥3 contract to
  continue (D-02).
- **Phase 94 gates-first commit discipline** — model for D-08 commit ordering.

### Established Patterns
- Required CI lanes are `mix.exs` `verify.*` aliases mapped to branch-protection jobs in
  `ci.yml`. Playwright (`operator_browser_gate`, Node 22) is already a required lane and
  coexists with the no-Node *shipped-lib* rule (Node is dev-harness-only, excluded from the
  Hex tarball).
- No pixel-diff (D-07 banned): structural assertions gate CI; LLM scores gate the milestone
  (Phase 103); the PNG matrix is a local/ad-hoc evidence step, never promoted to CI.
- Frozen-artifact precedent: completed registers/closeouts (Phase 73 release-record, Phase 79
  closeout, v1.7 register) are never reopened → new register is a fresh file.

### Integration Points
- New `structural.spec.js` → `operator_browser_gate` required lane (`ci.yml:645-716`).
- New `ratchet_baseline_test.exs` → `verify.support_contract.admin` required lane.
- `ui-audit.sh` PNGs → local LLM scoring → committed `mailglass_admin/docs/ui-baseline-scores.json`.
- `.planning/RATCHET-GAP-REGISTER.md` → cited (sev≥3) by downstream Phase 98–103 build tasks.
- `.gitignore` must cover the `ui-audit.sh` PNG output dir; the committed JSON path must match
  the ExUnit reader path.
</code_context>

<specifics>
## Specific Ideas

- The "18-cell" matrix is the EXISTING `ui-audit.sh` definition: **3 surfaces × 3 viewports ×
  2 themes** — NOT "surfaces + gallery". The gallery (Phase 97) is not a prerequisite.
- Two intentionally different keyings: PNG matrix = `surface × viewport × theme` (evidence);
  score baseline JSON = `surface × pillar × theme` (graded). Keep distinct, document the link.
- First run = establish-and-freeze. There is nothing to "meet-or-beat" yet; the regression
  teeth + reopen/skip idempotency turn on at Phase 103. Don't ship a vacuous no-op gate.
- Stable `GAP-NN` IDs are the join key across runs — never renumber. New register starts at
  GAP-01 in a NEW file (no collision with frozen v1.7 GAP-01..22).
- One path for the baseline JSON, agreed by all three consumers (harness writer, ExUnit
  reader, `.gitignore` PNG rule): `mailglass_admin/docs/ui-baseline-scores.json`.
</specifics>

<deferred>
## Deferred Ideas

- **Gallery-cell (`data-testid`) structural + LLM-score cells** — Phase 97 builds
  `/dev/mail/gallery`; its cells join the structural layer + matrix then. Recorded as a GAP
  here, not built.
- **Meet-or-beat regression enforcement + sev-4/5 GAP closeout + reopen/skip re-run** — Phase
  103 (the apparatus is stood up here; its teeth bite at closeout).
- **Hard-flip of advisory typography/tracking gates** — Phases 98/99 (per Phase 94 D-08),
  unrelated to this phase but adjacent in the ratchet story.

### Reviewed Todos (not folded)
- `2026-06-13-refresh-outbound-admin-ui-look-and-feel.md` (score 0.5) — reviewed, **not
  folded**. This is the milestone-level seed (already captured in STATE/PROJECT, broadened to
  all three admin surfaces across Phases 94–103). Phase 95 only *measures* and records gaps;
  the visible refresh lands across the fractal uplift phases (97–103), not here.
</deferred>
</content>
