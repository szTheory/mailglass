---
milestone: v1.11
artifact: ratchet-gap-register
stable_ids: true
created: 2026-06-13
supersedes: .planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md
---

# RATCHET-GAP-REGISTER — v1.11 Design-System Uplift

> Fresh baseline as of Phase 95 (2026-06-13). IDs restart at GAP-01 in this new file;
> no namespace collision with the frozen v1.7 register (separate file, separate namespace).
>
> **DO NOT reopen or modify** `.planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`.
> That file is frozen. Its sev-4 rows are all closed (see `79-GAP-CLOSEOUT.md`), and it
> describes pre-rebaseline code. Row data does NOT migrate to this register.
>
> This register spans **Phases 95 → 103** (milestone-root location, deliberately not
> phase-buried so it is the single citation anchor for the entire v1.11 uplift).

---

## Anti-Churn Contract

Every build task in Phases 98–103 MUST cite a row from this register at **severity ≥ 3**.
No citation → no merge. Rows are never renumbered once assigned.

This is the mechanical enforcement of the stable-ID rule: each `GAP-NN` is permanent
once written. If a row is found not applicable after the fact, its `status` is set to
`downgraded` with a rationale comment — it is never deleted or renumbered.

---

## Idempotent Re-Run Semantics (active from Phase 103)

The Phase 103 re-run compares its findings against this register using the following rules:

- **Regression** — a cell that scored worse than the committed baseline reopens its `GAP-NN`
  row: update `status` to `open`, stamp `run_id` with the new run ID.
- **Confirmed fixed** — a row marked `fixed` whose finding is confirmed absent on re-run is
  **skipped** (no new row, no change). The `run_id` field is not updated.
- **Same open finding** — a row already marked `open` with the same finding on re-run is
  **skipped** (no duplicate rows created). The `run_id` is not updated.

The `run_id` field records the last touch (open or reopen). The `first_seen_run` field is
set on initial discovery and **never changes** — it is the stable anchor for tracing when
a gap was first introduced.

---

## Seed Run Procedure

The following steps produce a `run_id` for the first population of this register (Phase 95,
Plan 95-04). Future maintainers use the same procedure for the Phase 103 re-run.

**Step 1:** Boot the reference demo application.

```bash
cd reference/demo_app && mix phx.server
# Serves on port 4015 by default
```

**Step 2:** Run the 18-cell PNG capture matrix.

```bash
cd mailglass_admin && bash scripts/ui-audit.sh
# Writes: tmp/ui-audit/{surface}-{vp}-{theme}.png (18 files)
# Surface: deliveries | inbound | preview
# Viewport: 390 | 768 | 1440
# Theme: light | dark
# PNGs are gitignored — never committed (D-07)
```

**Step 3:** Score each surface × theme pair (6 pairs) against the D-01 six pillars using
the 1–4 scale. Use a multimodal subagent or manual review of the PNGs. The PNG evidence
grid (`surface × viewport × theme`, 18 cells) informs the score grid (`surface × pillar ×
theme`, 36 cells); these are two intentionally different keyings — keep them distinct.

**Step 4:** Write scores to `mailglass_admin/docs/ui-baseline-scores.json`.

**Step 5:** Commit ONLY the JSON. The PNGs are never committed.

The `run_id` format is `YYYY-MM-DD-phase-NN` (example: `2026-06-13-phase-95-baseline`).

---

## Column Schema

| Column | Description |
|--------|-------------|
| `GAP-NN` | Stable ID — never renumber once assigned |
| `surface` | `deliveries` / `inbound` / `preview` / `all` |
| `component:line` | Path relative to `mailglass_admin/lib/` (or `docs/`) and line number |
| `pillar` | One of the six D-01 conformance pillars (see below) |
| `sev` | 1–5 per severity rubric below |
| `evidence PNG` | `tmp/ui-audit/{surface}-{vp}-{theme}.png` (gitignored path reference — never committed) |
| `fix sketch` | Concise implementation direction |
| `status` | `open` / `fixed` / `downgraded` |
| `run_id` | Run ID of the last touch (format: `YYYY-MM-DD-phase-NN`) |
| `first_seen_run` | Run ID of initial discovery — **never changes once set** |

### Six Conformance Pillars (D-01 — `design-system.md:104-121`)

| # | Pillar | What it covers |
|---|--------|----------------|
| 1 | **Spacing** | Token utilities on the 4px grid; touch targets ≥ `min-h-11` (44px) |
| 2 | **Radius** | `rounded-box` / `rounded-field` only (theme-driven) |
| 3 | **Color** | Semantic tokens + opacity tints; no hex, no raw palette; accent ≤ 10% rule |
| 4 | **Type** | `text-label/body/heading/display`; weight `font-bold` or default only (no faux-bold) |
| 5 | **Elevation** | `border border-base-300`; `shadow-overlay` for modals only; z-index from named tiers |
| 6 | **Motion+A11y** | Named motion vocabulary; `prefers-reduced-motion` inherited; semantic roles; visible focus rings |

### Severity Rubric

| Sev | Meaning |
|-----|---------|
| 5 | Accessibility failure or brand violation visible to every user — **blocks Phase 103 closeout** |
| 4 | Major design-system violation affecting core UX — **blocks Phase 103 closeout** |
| 3 | Significant gap — the **anti-churn citation threshold** (minimum severity required to cite in a build-phase task) |
| 2 | Minor inconsistency — tracked but does not block closeout |
| 1 | Cosmetic / polish — noted only |

Phase 103 success criterion: **zero open severity-4/5 rows**. Every sev-4/5 row must be
either fixed or explicitly downgraded with rationale before closeout.

---

## Gaps

> Rows populated by Phase 95 seed run (Plan 95-04). See `run_id: 2026-06-13-phase-95-baseline`.

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch | status | run_id | first_seen_run |
|--------|---------|----------------|--------|-----|-------------|------------|--------|--------|----------------|
| GAP-01 | deliveries | mailglass_admin/operator/support_cards.ex:56 | Spacing | 3 | tmp/ui-audit/deliveries-390-light.png | Remove btn-sm from drilldown CTA buttons in support_cards.ex (lines 56, 102, 152) or add min-h-11 to meet 44px touch target; btn-sm overrides min-h-11 only when both are present without !important | open | 2026-06-13-phase-95-baseline | 2026-06-13-phase-95-baseline |
| GAP-02 | preview | mailglass_admin/preview_live.ex | Motion+A11y | 3 | tmp/ui-audit/preview-390-light.png | Preview orientation empty-state must expose at least one keyboard-focusable CTA; structural spec confirmed the browser-preview-empty route may have no focusable element when no mailables are loaded — ensure Preview the first one button is always rendered and focusable | open | 2026-06-13-phase-95-baseline | 2026-06-13-phase-95-baseline |
| GAP-03 | preview | mailglass_admin/preview_live.ex | Motion+A11y | 3 | tmp/ui-audit/preview-390-dark.png | Preview surface ignores the dark theme param — preview-*-dark PNGs are visually identical to light; implement dark-mode awareness in the preview chrome/shell so theme toggle affects preview surface | open | 2026-06-13-phase-95-baseline | 2026-06-13-phase-95-baseline |
| GAP-04 | inbound | mailglass_admin/inbound_live.ex | Type | 2 | tmp/ui-audit/inbound-390-light.png | Filter section labels (TENANT, PROVIDER, MAILBOX OUTCOME, WINDOW, SEARCH) are rendered as uppercase raw CSS rather than via the text-label token; replace with text-label class or ensure text-label compiles to the same uppercase tracking style per design-system.md | open | 2026-06-13-phase-95-baseline | 2026-06-13-phase-95-baseline |
| GAP-05 | all | mailglass_admin_web/router.ex | Motion+A11y | 2 | — | Phase 97 plan 08: gallery route created in router.ex; structural.spec.js gallery block un-skipped with 5 real assertions | fixed | 2026-06-13-phase-95-baseline | 2026-06-13-phase-95-baseline |
