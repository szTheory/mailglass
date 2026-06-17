---
phase: 96-research-dossier
plan: "03"
subsystem: mailglass_admin
tags: [research, component-states, design-system, a11y, v1.11]
dependency_graph:
  requires: []
  provides:
    - ".planning/research/v1.11/COMPONENT-STATES.md (22 STATE-LD-NN decisions)"
  affects:
    - "Phase 97 (Component Layer + Gallery) — gallery specimen list + state implementation spec"
    - "Phase 98/99/100 (surface uplift) — per-archetype state correctness requirements"
    - "Phase 103 (Verification) — ratchet baseline for state conformance"
tech_stack:
  added: []
  patterns:
    - "Codebase-led state matrix: enumerate from real .ex files, grounded at file:line"
    - "Adversarial synthesis: critic-then-lock against hard design constraints + GAP rows"
    - "STATE-LD-NN stable ID scheme (mirrors GAP-NN citation machinery)"
    - "Axis-ownership cross-referencing: COMPONENT-STATES / MOTION / DARK-MODE dossiers"
key_files:
  created:
    - ".planning/research/v1.11/COMPONENT-STATES.md"
  modified: []
decisions:
  - "[STATE-LD-01..04] Shared atoms (icon/logo/flash/badge): display-only archetypes have rest-only or kind-variant states; no interactive states needed"
  - "[STATE-LD-05] status_badge: display-only; all 22 atoms must resolve to deterministic status_class; fallback badge-outline for phantom/nil atoms"
  - "[STATE-LD-06] nav_link/nav_pill: add focus-visible:ring-2 ring-primary ring-offset-1 (WCAG 2.4.7 compliance — currently missing)"
  - "[STATE-LD-07] tenant_chip: rest-with-tenant / rest-no-tenant; read-only; no loading state (synchronous assignment)"
  - "[STATE-LD-08] theme_toggle: verify btn-sm + min-h-11 override in compiled bundle; drop btn-sm if min-h-11 does not win"
  - "[STATE-LD-09] orientation_strip: rest-only; parent owns conditional rendering; hero-lifebuoy accent within 10% rule"
  - "[STATE-LD-10] shell: rest-light / rest-dark; no shell-level loading skeleton; flash_region handles info/error states"
  - "[STATE-LD-11] deliveries_list/records_list: add focus-visible ring to row buttons; loading state deferred pending async assign decision"
  - "[STATE-LD-12] detail_header: replace text-xl with text-heading token in both operator and inbound variants"
  - "[STATE-LD-13] filters_form: drop tracking-[0.08em] from all label spans; use text-label uppercase font-bold text-secondary — closes GAP-04"
  - "[STATE-LD-14] support_cards: remove btn-sm from all 4 CTA buttons (lines 56/102/152/204); use base btn with token padding — closes GAP-01"
  - "[STATE-LD-15] suppression_card: rest-present / rest-absent; display-only; gallery shows both states"
  - "[STATE-LD-16] timeline: motion-timeline entrance; highlighted-event ring-primary/40 tint; empty prose state"
  - "[STATE-LD-17] replay_modal: add aria-labelledby + Escape key handler + JS.focus_first focus trap in Phase 97"
  - "[STATE-LD-18] routing_trace: no info-reveal state (D-09 conflation corrected); states = empty / populated-passing / first-failing"
  - "[STATE-LD-19] evidence_card: 4 reveal states (nil/redacted/revealed/denied); verify btn-sm + min-h-11 override for reveal button"
  - "[STATE-LD-20] device_frame: add min-h-11 alongside btn-sm; verify compiled output; aria-pressed already correct"
  - "[STATE-LD-21] tabs: add aria-controls/tabpanel roles; add empty-state placeholder for HTML tab with empty body; focus-visible ring"
  - "[STATE-LD-22] sidebar: assess border-l-[3px] vs border-l-2; add focus-visible ring to summary + scenario links"
metrics:
  duration: "35 minutes"
  completed: "2026-06-14"
  tasks_completed: 1
  files_created: 1
---

# Phase 96 Plan 03: Component-State Matrix Dossier Summary

**One-liner:** Component-state matrix from codebase-first archetype enumeration with 22 STATE-LD-NN LOCKED DECISIONS covering focus gaps, GAP-01 touch-target fix, GAP-04 label-token fix, and replay_modal a11y additions.

## What Was Built

Created `.planning/research/v1.11/COMPONENT-STATES.md` — the RESEARCH-03 dossier.

**Structure:**
1. **Archetype Inventory** — 22 archetypes enumerated from real codebase files with `file:line` citations. Covers all D-09 archetypes: icon, logo, flash, badge, status_badge (22 atoms), nav_link, nav_pill, tenant_chip, theme_toggle, orientation_strip, shell, deliveries_list, detail_header (operator + inbound), filters_form, support_cards, suppression_card, timeline, replay_modal, routing_trace, evidence_card, device_frame, tabs, sidebar.

2. **State Matrix** — Per-archetype table of {rest, hover, focus, active, disabled, loading, empty, error} applicability + current implementation status (IMPLEMENTED / PARTIAL / MISSING / N/A) with codebase rationale.

3. **External Best Practice** — WCAG 2.1 SC 2.4.7 (Focus Visible), SC 1.4.11 (Non-Text Contrast), ARIA APG Dialog + Tab + Combobox patterns. Codebase conformance assessed against each.

4. **Gap Analysis** — Priority-ordered: (1) Missing focus rings on nav_link/deliveries_list rows/sidebar, (2) replay_modal a11y failures (focus trap, aria-labelledby, Escape key), (3) GAP-01 btn-sm touch targets, (4) GAP-04 filter label tracking, (5) missing loading/error states with architecture-dependency caveat.

5. **Adversarial Synthesis** — 6 critic challenges: status_badge (passes), nav_link focus decision (passes), support_cards GAP-01 (passes), filters_form GAP-04 (passes), routing_trace state model (corrects D-09 conflation with evidence_card), evidence_card reveal model (flags btn-sm + min-h-11 tension for Phase 97 bundle verification).

6. **LOCKED DECISION block** — 22 STATE-LD-NN rows in a table with Decision / Applies-to / Constraint-binding / Closes-GAP columns. Self-contained literal state lists ready for Phase 97 citation without re-reading the body.

## Key Findings

**GAP-01 (btn-sm touch target):** Confirmed in `support_cards.ex` lines 56, 102, 152, 204. Also extended finding in `device_frame.ex` (dev-only, lower severity) and `theme_toggle` (btn-sm + min-h-11 tension requiring bundle verification). STATE-LD-14 locks the fix: remove btn-sm from support_cards CTA buttons.

**GAP-04 (filter label off-token):** The operator `filters_form.ex` uses `text-label` (token) but also `tracking-[0.08em]` (arbitrary). Drop the arbitrary tracking. Inbound `filters_form.ex` may differ — Phase 99 executor must verify. STATE-LD-13 locks the fix.

**D-09 conflation corrected:** The routing_trace archetype does NOT have a "locked/info reveal" state. That pattern belongs to evidence_card (`:redacted`/`:revealed`/`:denied`). STATE-LD-18 and STATE-LD-19 lock the correct state models.

**text-xl in detail_header:** Both `operator/detail_header.ex:21` and `inbound/detail_header.ex:38` use `text-xl` (raw Tailwind) instead of `text-heading` (our `@theme` token). STATE-LD-12 mandates the fix.

**replay_modal a11y:** Three additions required: `aria-labelledby` on the dialog, `phx-key="Escape"` handler, and `JS.focus_first` focus trap. STATE-LD-17 documents these.

## Deviations from Plan

None. Plan executed exactly as written.

**Clarification documented:** D-09's description of `routing_trace` as having "locked/info reveal" states is a documentation imprecision — that pattern belongs to `evidence_card`. STATE-LD-18 locks the correct model with this noted.

## Verification Results

All grep acceptance criteria passed:

```
grep -l "## LOCKED DECISION" COMPONENT-STATES.md  → match found
grep -c "STATE-LD-" COMPONENT-STATES.md            → 22 (≥10 required)
grep -c "status_badge|routing_trace|evidence_card|tenant_chip" → 28 matches
GAP-01 appears in STATE-LD-14 Closes-GAP column
GAP-04 appears in STATE-LD-13 Closes-GAP column
All 5 key status atoms present: dispatched, delivered, bounced, webhook_replay_succeeded, reconciled
ARIA and WCAG referenced in Section 3 (External Best Practice)
No STATE-LD row has empty Constraint-binding cell
```

## Self-Check: PASSED

- File exists: `.planning/research/v1.11/COMPONENT-STATES.md` — confirmed
- Commit exists: `917bbe34` — confirmed (`git log --oneline -1`)
- All acceptance criteria passed per grep verification above
- 22 STATE-LD-NN rows (well above the minimum 10 required)
- status_badge, routing_trace, evidence_card, tenant_chip all explicitly named in LOCKED DECISION block
- GAP-01 in STATE-LD-14 Closes-GAP; GAP-04 in STATE-LD-13 Closes-GAP
- Every row has a non-empty Constraint-binding cell (verified: no `| |` empty-cell pattern found)
