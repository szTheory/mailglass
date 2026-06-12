---
phase: 85-research-and-differentiation-brief
plan: 01
subsystem: brand
tags: [brandbook, audit, differentiation, v1.9, planning-artifacts]
requires:
  - brandbook/ frozen at 09a84dd4 (codex A/B baseline)
  - .planning/research/v1.9-brandbook-fable/ (SUMMARY, BRAND-SYSTEMS, PITFALLS-PORTABILITY)
provides:
  - 85-codex-audit.md (BRIEF-01: 20 defect rows CDX-01..20, 9 strength rows CDX-S-01..09, 6 killed differentiator candidates)
  - 85-differentiation-brief.md (BRIEF-02: 12 locked differentiators DIF-01..12, Phase 88 section outline, kill-list, 21-file manifest with size budgets)
key-files:
  created:
    - .planning/phases/85-research-and-differentiation-brief/85-codex-audit.md
    - .planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md
  modified: []
key-decisions:
  - "Locked 12 differentiators (hard cap hit honestly: all 10 draft candidates validated, 2 added from audit-discovered rows CDX-11/CDX-18)"
  - "Brief + manifest folded into one document per CONTEXT discretion — downstream phases read exactly one file"
  - "Pitfall mappings referenced to PITFALLS-PORTABILITY.md, not duplicated, per CONTEXT discretion"
  - "Per-file manifest budgets sum to 489 KB so the 500 KB folder budget holds even at every ceiling"
requirements-completed: [BRIEF-01, BRIEF-02]
duration: 9m
completed: 2026-06-11
---

# Phase 85 Plan 01: Research and Differentiation Brief Summary

Forensic 20-defect/9-strength audit of the frozen codex brandbook (09a84dd4) plus a locked 12-differentiator brief with Phase 88 outline, kill-list, and a budgeted 21-file brandbook-fable/ manifest.

## Accomplishments

- **BRIEF-01 (85-codex-audit.md):** Row-addressable defect register CDX-01..20, every row file:line-verified against the frozen baseline (re-confirmed via `git diff --quiet 09a84dd4 -- brandbook/`). Re-confirmed and extended the three pre-verified defects (Avenir live `<text>` at logo-primary.svg:17, "Phase 84" leakage at tokens.json:70/75-76, dark tokens at tokens.css:108 unreachable from index.html). New strong findings include the dark block reassigning only 18 of ~70 roles (Mist-on-Mist invisible callout text under dark), the README header specimen repeating the Avenir wordmark verbatim, and the favicon being the full 80×80 mark re-served at 32px. Strengths register CDX-S-01..09 records what codex did well (semantic state group, callout/code roles, dark ramp, SVG accessibility, file:// self-containment, reduced-motion handling).
- **BRIEF-02 (85-differentiation-brief.md):** 12 differentiators DIF-01..12, each with a one-line "why it earns its bytes" and CDX/CDX-S evidence. Non-negotiables (7 loud rules), banned motif families (P-21..P-25 + named resemblances), compositional stance (left-aligned documentation-like), ownable axis (Ink/Glass/Ice + transparency-as-meaning), 9-section Phase 88 outline, 11-entry kill-list, 21-file manifest with the three hard budget lines, and per-phase pitfall mapping by reference.
- **Anti-derivative contract holds:** all Phase 85 artifacts live in `.planning/`; nothing exists under `brandbook-fable/`; the frozen baseline is untouched.

## Task Commits

| Task | Name | Commit |
|------|------|--------|
| 1 | Forensic codex-brandbook audit register (BRIEF-01) | 0573d6d9 |
| 2 | Lock the differentiation brief (BRIEF-02) | f7157738 |

## Files Created

- `.planning/phases/85-research-and-differentiation-brief/85-codex-audit.md` (94 lines)
- `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` (175 lines)

## Decisions Made

- **Differentiator count = 12** (cap, not padding): all 10 CONTEXT draft candidates survived audit validation; small-size-true favicon (DIF-11, from CDX-11) and the social-card template (DIF-12, from CDX-18) added because each carries its own audit-evidenced absence and its own shipped artifact.
- **Six killed differentiator candidates** locked in the audit (state-token existence, dark-mode existence, SVG a11y, self-containment, microcopy existence, reduced motion) — the brief restates the surviving honest forms only (demonstrated dark, copy breadth).
- **Single-document brief** (brief + manifest folded) and **pitfall mapping by reference** — both CONTEXT-discretion calls resolved toward minimum downstream reading surface.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- Task 1 automated gate: AUDIT-OK (header row present, 3 pre-verified citations present, 20 ≥ 10 defect rows, 9 ≥ 3 strength rows, every cited brandbook/ path exists on disk).
- Task 2 automated gate: BRIEF-OK (12 DIF rows within 6-12, all required headings, CDX citations, both budget strings, no brandbook-fable/).
- Plan-level: `git diff --quiet 09a84dd4 -- brandbook/` exits 0; `test ! -e brandbook-fable` passes; `git status --porcelain` clean after commits (changes only under `.planning/`).

## Self-Check: PASSED

- FOUND: .planning/phases/85-research-and-differentiation-brief/85-codex-audit.md
- FOUND: .planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md
- FOUND: commit 0573d6d9
- FOUND: commit f7157738
