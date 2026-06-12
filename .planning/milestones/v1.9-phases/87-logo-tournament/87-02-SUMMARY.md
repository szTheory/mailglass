---
phase: 87-logo-tournament
plan: 02
subsystem: brand-system
tags: [brandbook-fable, logo, tournament, color-program, svg]
requires:
  - phase: 87-logo-tournament
    provides: round-1 field, maintainer selection of option 8 (plan 87-01)
  - phase: 86-foundations-palette-type-voice-tokens
    provides: token palette consumed by the color program
provides:
  - Canonical 8-asset logo system in brandbook-fable/assets/ (winner 4D, the sealed flap)
  - Two-expression color program (light/dark) + currentColor mono master
  - Tournament decision record with usage rules and standing constraints C-15/C-16
affects: [phase-88-book-assembly, phase-89-collateral, phase-90-quality-gate]
tech-stack:
  added: []
  patterns:
    - maintainer-directed tournament rounds with recorded fallback winner
    - even-odd single-path mono master + layered color fills over identical geometry
    - prefers-color-scheme adaptive SVG favicon
key-files:
  created:
    - brandbook-fable/assets/logo-primary.svg
    - brandbook-fable/assets/logo-typemark.svg
    - brandbook-fable/assets/logo-mark.svg
    - brandbook-fable/assets/logo-monochrome.svg
    - brandbook-fable/assets/logo-with-tagline.svg
    - brandbook-fable/assets/favicon.svg
    - brandbook-fable/assets/social-avatar.svg
    - brandbook-fable/assets/social-avatar-dark.svg
    - .planning/phases/87-logo-tournament/87-decision-record.md
    - .planning/phases/87-logo-tournament/tournament/round-2.html
    - .planning/phases/87-logo-tournament/tournament/round-3.html
    - .planning/phases/87-logo-tournament/tournament/round-4.html
  modified:
    - .planning/phases/87-logo-tournament/87-02-CHECKPOINT.md
    - .planning/phases/87-logo-tournament/87-pre-flight.md
key-decisions:
  - "Winner: 4D 'the sealed flap' — landscape envelope pane with flap and seal drawn entirely in light; selected through rounds 2-4 (8F synthesis → 8F-1 color → envelope exploration)."
  - "Round 4 was a maintainer-directed extension beyond the round-3 cap, authorized because it carried a recorded fallback winner (8F-1 color) — not a rejection loop; rejection_count stayed 0."
  - "Color program is token-only: Ink+Glass on light, Mist+Ice on dark, currentColor mono master for hostile contexts; primary never sits on dark surfaces (usage rule in the decision record)."
  - "Favicon self-adapts to OS dark mode via an internal prefers-color-scheme style — the one surface where the page cannot control contrast."
  - "Standing constraints C-15 (no broken reads) and C-16 (envelope by light only, no codex convergence) are binding on all future brand work."
patterns-established:
  - "Single-parameter variant rounds with evidence strips keep maintainer feedback mappable to geometry."
  - "Every presented option pre-screened (pre-flight table) and browser-audited before showing."
requirements-completed: [LOGO-07, LOGO-08]
duration: 4 rounds across one session (incl. one executor crash recovered from committed state)
completed: 2026-06-11
---

# Phase 87 Plan 02: Refinement Tournament and Asset Promotion Summary

**The maintainer selected 4D "the sealed flap" through a four-round
evidence-rendered tournament, and the winner now ships as a complete
8-asset, two-expression, mono-safe logo system in `brandbook-fable/assets/`.**

## Accomplishments

- Round 2: six variants of option 8 (five single-parameter, one spinoff);
  maintainer direction → 8F.
- Round 3: four candidates introducing the token-only color program;
  maintainer direction → 8F-1 color + envelope exploration.
- Round 4 (maintainer-directed extension with fallback winner): four
  envelope-in-light candidates with honest per-size envelope-read verdicts;
  winner 4D.
- Promotion: 8 canonical assets, all outlined paths, zero `<text>`, zero
  `font-family`, unique IDs, title/desc in brand voice, favicon redrawn on a
  16-grid with 2 shape elements and OS-dark adaptation.
- 87-decision-record.md: full history, color program spec, usage rules,
  asset mapping for Phases 88-90, rejected-evidence index.

## Task Commits

1. `5ea4732b` / `403584d5` / `3101ba69` — round-2 field + pre-flight + pause
2. `b1e0beb8` / `c738ee5f` — round-3 field + pause
3. `45c6aeff` / `052001e2` — round-4 field + pause
4. `187dd85e` — final winner recorded (4D)
5. `b65335ac` — canonical asset promotion (8 files)
6. favicon OS-dark adaptation committed separately after post-crash visual audit

## Deviations from Plan

1. **Round 4 beyond the round-3 hard cap** — maintainer-directed exploration
   with a recorded fallback winner; authorized and logged in the checkpoint.
   The cap's purpose (stopping rejection thrash) was preserved:
   rejection_count 0.
2. **Executor crash during promotion** — the promotion executor lost its
   connection after committing the assets (`b65335ac`) but before writing
   the decision record and this summary. The orchestrator re-ran the full
   gate suite independently (all PASS), performed the visual audit, found
   and fixed one defect the crashed agent had not addressed (favicon
   invisible on OS-dark tabs), and wrote the remaining documents.

## Verification

- xmllint: 8/8 assets pass. `<text>`: 0. `font-family`: 0. Process
  vocabulary in brandbook-fable/: 0 hits. Favicon shape count: 2 (≤3).
  Tagline confined to logo-with-tagline.svg. title+desc on every asset.
- Playwright render audit on light and dark pages (tmp/87-logo-tournament/
  promotion/check.png): all assets read correctly; favicon dark behavior
  fixed and re-validated.
- Frozen `brandbook/` untouched (`git diff --quiet 09a84dd4 -- brandbook/`).

## Next Phase Readiness

Phase 88 consumes the canonical assets and the decision record's usage
rules (especially: mono/currentColor on dark, the color program table, and
the shipped asset filenames).

## Self-Check: PASSED

- All assets exist on disk and are committed.
- Gates re-run independently post-crash: all green.
- Requirement IDs match the plan frontmatter.

---
*Phase: 87-logo-tournament*
*Completed: 2026-06-11*
