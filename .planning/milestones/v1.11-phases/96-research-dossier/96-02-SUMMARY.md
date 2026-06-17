---
phase: 96
plan: 02
subsystem: mailglass_admin — research dossiers
tags: [ia, information-architecture, research, locked-decisions, ux]
dependency_graph:
  requires: [96-01-SUMMARY.md]
  provides: [IA.md, IA-LD-01..09]
  affects: [phases 98 (Operator), 99 (Inbound), 100 (Preview)]
tech_stack:
  added: []
  patterns:
    - gov.uk Design System IA patterns (filter, master-detail, navigation)
    - Nielsen Norman Group filter-vs-facet and master-detail frameworks
key_files:
  created:
    - .planning/research/v1.11/IA.md
  modified: []
decisions:
  - "IA-LD-01: orientation_strip in detail pane at >=768px; in master pane below filters at 390px"
  - "IA-LD-02: filter controls always in DOM; mobile-only disclosure toggle (default collapsed) via LiveView.JS"
  - "IA-LD-03: master-detail split — 390px full-width stacked (no new route), 768px grid-cols-[40%_60%], 1440px grid-cols-[33%_67%]"
  - "IA-LD-04: filter labels use text-label uppercase font-bold text-secondary — no tracking-[0.08em] arbitrary value (closes GAP-04)"
  - "IA-LD-05: SupportCards Tier 1 before Tier 2 at all viewports; error counts before warning counts in Tier 1"
  - "IA-LD-06: L1 nav labels are surface nouns only (Deliveries, Inbound) — no state-count suffixes; aria-current=page required"
  - "IA-LD-07: empty/loading state placement per surface; Preview focusable CTA always in DOM (references GAP-02)"
  - "IA-LD-08: Preview sidebar uses native <details>/<summary> for mailable->scenario hierarchy; border-primary on active scenario"
  - "IA-LD-09: Inbound surface MUST render overview/at-a-glance tier (stat row) before the record list at all viewports (GROUP-02 IA spec)"
metrics:
  duration: "~22 minutes"
  completed: "2026-06-14"
  tasks_completed: 1
  files_created: 1
---

# Phase 96 Plan 02: IA Research Dossier Summary

**One-liner:** gov.uk DS + Nielsen NN IA patterns distilled into 9 LOCKED DECISIONS (IA-LD-01..09) covering master-detail viewport split, filter disclosure, orientation strip placement, filter label tokenization (GAP-04), and inbound overview tier spec (GROUP-02).

## What Was Built

Created `.planning/research/v1.11/IA.md` — a 341-line information-architecture research dossier with:

1. **Sources and Evidence** — gov.uk Design System (navigation, table, filter patterns) and Nielsen NN Group (filter-vs-facet, master-detail) synthesized with explicit URL citations and "loved vs. avoided" pattern distinctions.

2. **Current mailglass_admin IA Inventory** — all three admin surfaces mapped to their existing HEEx structure with `file:line` citations:
   - Operator: `shell.ex:116` shell chrome, `filters_form.ex:13` filter fields, `shell.ex:314` orientation strip, `support_cards.ex:18` triage grid
   - Inbound: `inbound/filters_form.ex:17` filter fields, `inbound/routing_trace.ex:32` routing trace, `inbound_live.ex:77` reveal state
   - Preview: `preview/sidebar.ex:40` `<details>` sidebar, `preview/tabs.ex:35` tablist, `preview_live.ex:73` dark_chrome assign

3. **Pattern Fit Analysis** — per-surface tables assessing master-detail, filter disclosure, navigation, orientation strip, and URL-state against best-practice patterns.

4. **Draft Decisions (4a–4g)** — seven draft decisions covering all identified deviations.

5. **Adversarial Synthesis** — each draft decision challenged against hard design constraints and open GAP rows before locking. Decision 4g (filter label tokenization) was added by the critic as a direct GAP-04 close signal.

6. **LOCKED DECISION block** — 9 rows (IA-LD-01 through IA-LD-09) with all required columns: `LD-ID | Decision | Applies-to | Constraint-binding | Closes-GAP`.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Additional Decision Added by Critic

**Decision IA-LD-09 (Inbound overview tier):** The adversarial synthesis pass identified that no draft decision addressed the GROUP-02 gap (inbound overview/at-a-glance tier missing). Decision 4g (filter label) was added to close GAP-04. IA-LD-09 was added to the LOCKED DECISION block as the IA specification for the GROUP-02 requirement — providing Phase 99 with a concrete structural spec.

## Acceptance Criteria Verification

| Check | Status |
|-------|--------|
| `.planning/research/v1.11/IA.md` exists | PASS |
| File contains `## LOCKED DECISION` | PASS |
| `grep -c "IA-LD-"` >= 6 (actual: 17) | PASS |
| Every LOCKED row has non-empty Constraint-binding | PASS |
| `GAP-04` in at least one Closes-GAP cell | PASS (IA-LD-04) |
| All three surfaces (Operator, Inbound, Preview) named | PASS |
| gov.uk Design System and Nielsen Norman cited as sources | PASS |
| `## LOCKED DECISION` appears exactly once | PASS (count=1) |

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This is a docs-only research phase; the only artifact is a markdown file under `.planning/research/`.

## Self-Check: PASSED

- `.planning/research/v1.11/IA.md` confirmed created (341 lines)
- Commit `280e9647` verified in `git log`
- All grep acceptance criteria passed before commit
