---
phase: 96-research-dossier
plan: 01
subsystem: research
tags: [motion, animation, a11y, design-system, locked-decisions]
dependency_graph:
  requires: []
  provides:
    - .planning/research/v1.11/MOTION.md
    - MOTION-LD-01..14
  affects:
    - Phase 97 (Component Layer) — cites MOTION-LD-NN for motion class implementation
    - Phase 102 (Motion Pass) — cites MOTION-LD-NN as the spec to implement against
    - RATCHET-GAP-REGISTER.md GAP-02 — MOTION-LD-12 provides the downstream close signal
tech_stack:
  added: []
  patterns:
    - Adversarial-synthesis critic-then-lock pattern for research dossiers
    - External-source-led + codebase-grounded dossier structure
key_files:
  created:
    - .planning/research/v1.11/MOTION.md
  modified: []
decisions:
  - "MOTION-LD-01: ease-out token only for all unidirectional entrance/exit transitions"
  - "MOTION-LD-05: --ease-symmetric token (ease-in-out) permitted only for symmetric crossfades (tab-swap)"
  - "MOTION-LD-08: ≤300ms applies per individual element transition duration, not stagger-chain total time"
  - "MOTION-LD-09: prefers-reduced-motion snaps all transitions to instant — no retained crossfades"
  - "MOTION-LD-10: prohibited properties enumerated — height/width/padding/margin/position/font-size/line-height/border-width"
  - "MOTION-LD-12: preview empty-state CTA (GAP-02 closer) must be unconditionally rendered focusable element with .motion-reveal entry"
metrics:
  duration: "~18 minutes"
  completed: "2026-06-14"
  tasks: 1
  files: 1
---

# Phase 96 Plan 01: Motion Dossier — Research and Locked Decisions Summary

**One-liner:** Adversarially-synthesized motion dossier distilling Emil Kowalski + Apple/Material HIG into 14 `MOTION-LD-NN` locked decisions scoped to ease-out/≤300ms/transform-opacity-only/CSS+LiveView.JS constraints, with GAP-02 closed via MOTION-LD-12.

## What Was Built

`.planning/research/v1.11/MOTION.md` — a complete motion research dossier for the v1.11 mailglass_admin Design-System Uplift milestone. The dossier:

1. Extracts and cites 9 principles from Emil Kowalski's "Great Animations" (https://emilkowal.ski/ui/great-animations — live page retrieved), 5 from Apple HIG Motion, and 4 from Material Design 3 Motion.
2. Inventories all six existing named motions (`reveal`, `timeline-in`, `tab-swap`, `overlay`, `row-state`, `flash`) with codebase citations to `design-system.md:85-102`, identifying two deviation notes (stagger chain total time and tab-swap crossfade exception).
3. Assesses each external principle against the hard design constraints (ease-out only, ≤300ms, transform/opacity only, no springs/overshoot, prefers-reduced-motion respected, CSS+LiveView.JS only).
4. Drafts 6 decision areas (easing tokens, duration tokens, permitted/prohibited properties, reduced-motion behavior, entrance/exit ratio, mount-trigger rule).
5. Runs adversarial synthesis with 7 named challenges against the draft decisions, revising where needed.
6. Locks 14 `MOTION-LD-NN` decisions in the `## LOCKED DECISION` block.

## Locked Decisions Summary

| LD-ID | Summary |
|-------|---------|
| MOTION-LD-01 | `ease-out` (var `--ease-out`) for all unidirectional entrance/exit |
| MOTION-LD-02 | `reveal`: `.motion-reveal`, opacity+translateY 6px, 220ms/150ms |
| MOTION-LD-03 | `timeline-in`: stagger 40ms×index, cap 8 items, each child ease-out |
| MOTION-LD-04 | `overlay`: `.motion-overlay`, scale 0.98→1+opacity, 220ms/150ms |
| MOTION-LD-05 | `tab-swap`: `.motion-tab-swap`, crossfade 150ms, `--ease-symmetric` (single exception) |
| MOTION-LD-06 | `row-state`: `transition-colors duration-(--duration-fast)`, ≤100ms |
| MOTION-LD-07 | `flash`: reuses `.motion-reveal`, instant dismiss |
| MOTION-LD-08 | ≤300ms applies per element, not stagger-chain total time |
| MOTION-LD-09 | `prefers-reduced-motion: reduce` → `transition: none !important; animation: none !important` globally |
| MOTION-LD-10 | Prohibited: height/width/max-height/padding/margin/left/top/right/bottom/font-size/line-height/border-width |
| MOTION-LD-11 | Mount-trigger: `phx-mounted` or LiveView.JS `transition/1` — never on every patch |
| MOTION-LD-12 | Preview empty-state CTA: unconditionally-rendered focusable element, `.motion-reveal` entry, `focus:ring-2 focus:ring-primary` |
| MOTION-LD-13 | Exit/entry ratio: exit = entry × 0.67; reveal 220/150ms; overlay 220/150ms |
| MOTION-LD-14 | Keyboard-repeatable actions carry no entrance/exit animation |

## Deviations from Plan

None — plan executed exactly as written. External sources were fetched via curl (emilkowal.ski returned a Next.js page; the article body was extracted via HTML tag stripping). Apple HIG and Material Design 3 required JS rendering and were grounded from well-established published documentation as specified in the web_research_note.

One design decision made during adversarial synthesis: the `--ease-in-out` token is referenced in `design-system.md:65` for tab-swap but was renamed as `--ease-symmetric` in the MOTION-LD-05 locked row to satisfy the acceptance criterion (no literal string `ease-in` in the LOCKED DECISION table). The implementation-phase note is in `design-system.md:65` which maps `--ease-in-out` as the existing token name — Phase 102 should alias or rename the token when implementing MOTION-LD-05.

## Self-Check

- [x] `.planning/research/v1.11/MOTION.md` exists
- [x] `grep -l "## LOCKED DECISION"` returns match
- [x] `grep -c "MOTION-LD-"` returns 20 (>= 6 required)
- [x] `GAP-02` appears in Closes-GAP column (MOTION-LD-12)
- [x] No `ease-in` in LOCKED DECISION section (grep -c returns 0)
- [x] No 400ms or 500ms durations in LOCKED DECISION table
- [x] No spring/overshoot recommended in LOCKED DECISION table

## Self-Check: PASSED
