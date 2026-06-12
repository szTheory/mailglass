---
phase: 87-logo-tournament
verified: 2026-06-11T20:55:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 1
overrides:
  - must_have: "At most 2 refinement rounds (parameter-named variants) run on the pick(s) before promotion"
    reason: "A third refinement round (round 4) ran beyond the round-3 hard cap. It was a maintainer-DIRECTED exploration ('go above and beyond here plz 4th round'), not a rejection loop: the checkpoint records the authorization, a fallback winner (8F-1 color) locked before generation, a convergence guard (C-16), and rejection_count 0 throughout. The cap's purpose — stopping rejection thrash — was preserved."
    accepted_by: "maintainer (szTheory)"
    accepted_at: "2026-06-11"
---

# Phase 87: Logo Tournament Verification Report

**Phase Goal:** The maintainer selects the fable logo from a constraint-screened, evidence-rendered field, and the winner ships as a complete outlined-path asset system
**Verified:** 2026-06-11 (independent goal-backward verification; all gates re-run from the codebase, not summaries)
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Round 1 presents exactly 8 options, 2 per axis, each pre-screened before being shown (LOGO-05) | ✓ VERIFIED | `tournament/options/option-{1..8}.svg` exist (8 files, all substantive hand-drawn path SVGs, 3.6–4.1 KB, 9–11 paths each). `round-1.html` labels exactly 2 options per axis (grep: "Axis A/B/C/D — …" each ×2) and inlines all 8 (`o1-title`..`o8-title` each present, ×2 for light+mono cells). Pre-flight Round 1 = 112 data rows (8 × C-01..C-14), all PASS, screened before the 87-01 hard pause. |
| 2 | Every presented option passes the hard constraints (LOGO-06) | ✓ VERIFIED | 87-pre-flight.md: 326 total data rows across 4 rounds (112 + 90 + 60 + 64), zero non-PASS verdicts (the only non-PASS `\| ` rows are the 4 table headers). Independently spot-checked options 2, 5, 8 plus the full set: xmllint 8/8 pass; zero `<text>`/`font-family`; **zero `<rect>` elements at all** (no background plates possible); IDs `oN-`-prefixed and globally unique across all 8 files; every file has `<title>` + `<desc>` + `role="img"` + viewBox. |
| 3 | Maintainer explicitly selects from a rendered-evidence gallery at a hard pause; selection + rationale recorded (LOGO-07) | ✓ VERIFIED | Complete, explicit trail with no inferred defaults: 87-01-CHECKPOINT Selection — "Option 8 'the shared light'" + rationale + standing constraint from the option-2 rejection (no broken reads → C-15), dated. 87-02-CHECKPOINT — round 2 → 8F + round-3 request (verbatim directive: imagery + color); round 3 → "i like the 8F-1 color" recorded as standing fallback winner + round-4 envelope directive; round 4 → FINAL SELECTION "4D — the sealed flap" ("i like 4D, run with that"). Full history mirrored in 87-decision-record.md. rejection_count: 0 at every pause. Galleries round-{1..4}.html all self-contained (zero non-xmlns `https?://` refs). |
| 4 | At most 2 refinement rounds before promotion (LOGO-07) | ✓ PASSED (override) | Rounds 2 and 3 honored the protocol (6 parameter-named variants 90/90 PASS; 4 candidates 60/60 PASS at the documented hard cap). Round 4 exceeded the cap — explicitly authorized by the maintainer with a recorded fallback winner (8F-1 color), convergence guard C-16, and a logged protocol note ("this is not a rejection… the extension is authorized"); 64/64 PASS. Override accepted per the checkpoint record dated 2026-06-11. |
| 5 | Canonical assets ship in brandbook-fable/assets/ — 8 assets, outlined paths, zero font-family, accessible title/desc, unique IDs (LOGO-08) | ✓ VERIFIED | See artifact + gate tables below. All 8 CONTEXT-locked filenames present, all gates green, renders read correctly at 16/32 px on light and dark. |

**Score:** 5/5 truths verified (1 via maintainer-accepted override)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook-fable/assets/logo-primary.svg` | Primary lockup, explicit brand hex fills | ✓ VERIFIED | 4,000 B (≤16 KB budget). Ink `#0D1B2A` pane + Glass `#277B96` seal, even-odd mark path, `<title>`+`<desc>`, `mg-fable-primary-` IDs. Rendered: legible at 120/32/16 px on light. |
| `brandbook-fable/assets/logo-typemark.svg` | Standalone outlined wordmark | ✓ VERIFIED | 3,522 B (≤12 KB). Path-only, currentColor-friendly. |
| `brandbook-fable/assets/logo-mark.svg` | Standalone mark, hex fills | ✓ VERIFIED | 791 B (≤8 KB). |
| `brandbook-fable/assets/logo-monochrome.svg` | currentColor with explicit root fallback | ✓ VERIFIED | 3,999 B (≤8 KB). `currentColor` ×10; root carries `color="#0D1B2A"` fallback. |
| `brandbook-fable/assets/logo-with-tagline.svg` | ONLY subtitle-bearing asset, tagline outlined | ✓ VERIFIED | 9,492 B (≤16 KB). `data-tagline="Email, made visible."` group of outlined paths in Slate `#5C6B7A`; `data-tagline` appears in this file and no other. (See Info note on tagline wording.) |
| `brandbook-fable/assets/favicon.svg` | Dedicated 16-grid redraw, ≤3 shapes | ✓ VERIFIED | 707 B (≤3 KB). `viewBox="0 0 16 16"`, exactly **2** shape elements, integer coordinates, embedded `prefers-color-scheme: dark` pane flip (Ink→Mist), Glass seal constant. Render-confirmed in both schemes at 64/32/16 px. |
| `brandbook-fable/assets/social-avatar.svg` | Square light canvas (documented plate exception) | ✓ VERIFIED | 819 B (≤6 KB). Paper `#F8FBFD` 240×240 rect, mark centered. |
| `brandbook-fable/assets/social-avatar-dark.svg` | Square dark canvas | ✓ VERIFIED | 805 B (≤6 KB). Ink `#0D1B2A` rect, Mist/Ice dark expression. |
| `.planning/phases/87-logo-tournament/87-decision-record.md` | Selection history, color program, usage rules, asset manifest | ✓ VERIFIED | Carries: winner 4D + geometry; token-only color program table (light/dark/mono); usage rules incl. **primary-never-on-dark** and favicon self-adaptation; the 8-file asset mapping table with the Phase 85 brief-name supersession note (`logo-mark-mono.svg`/`social-avatar-light.svg` → shipped names); 4-round history; standing constraints C-15/C-16; rejected-evidence index. Everything Phases 88–90 need. |

### Asset Gate Battery (re-run independently)

| Gate | Result |
|------|--------|
| xmllint --noout on all 8 assets | ✓ 8/8 valid |
| `<text>` / `font-family` anywhere in assets/ | ✓ 0 hits |
| Per-file duplicate IDs | ✓ none |
| Cross-file ID collisions (all 8 assets) | ✓ none |
| `<title>` / `<desc>` / `role="img"` on every asset | ✓ 0 files missing any |
| favicon shape count (`path\|circle\|rect\|ellipse\|polygon\|line`) | ✓ 2 (≤3) |
| `data-tagline` exclusivity | ✓ only logo-with-tagline.svg |
| monochrome currentColor + root fallback | ✓ `color="#0D1B2A"` |
| Gradients/filters/masks/`<script>`/on* attributes | ✓ 0 hits |
| Process vocabulary (phase/tournament/milestone/option/variant/REQ-) in brandbook-fable/ | ✓ 0 hits |
| Per-file size vs brief budgets | ✓ all within budget |
| Debt markers (TBD/FIXME/XXX) in phase files | ✓ 0 |

### Render Verification (Playwright, chromium, deviceScaleFactor 3)

Screenshots in gitignored `tmp/87-verification/` (rendered and read by the verifier):

| Check | Result |
|-------|--------|
| logo-primary on light (Paper) at 120/32/16 px | ✓ Mark reads as envelope-of-light at all three sizes; wordmark crisp, counters hollow, no clots; lockup tight |
| favicon on light scheme at 64/32/16 px | ✓ Ink pane + light flap + Glass seal legible at all sizes incl. 16 px |
| favicon with emulated `prefers-color-scheme: dark` at 64/32/16 px | ✓ Pane flips Ink→Mist, Glass seal holds — mark fully legible on dark; OS-dark adaptation works as the decision record claims |
| logo-primary on dark (informative) | Confirms the documented usage rule: the Ink-pane light expression is not for dark surfaces (decision record routes dark to monochrome/dark expressions) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| 87-01-CHECKPOINT Selection | round-2 variants | variants derive only from the recorded pick | ✓ WIRED | All 6 round-2 files are `variant-8-*` (option 8 was the sole pick); each names its changed parameter family |
| Tournament winner (4D) | brandbook-fable/assets/*.svg | fresh promotion, not file copy | ✓ WIRED | Assets carry `mg-fable-*` ID namespace and 4D geometry (landscape pane 140×96, flap-of-light, seal r36); no tournament file names/IDs in assets; tournament exhaust 100% confined to .planning/ (find for option/variant/round under brandbook-fable: 0) |
| Assets | Phase 88 brand book | decision-record manifest | ✓ WIRED | Manifest table maps all 8 shipped filenames + brief-name supersession so BOOK-04..07 reference real paths |
| SUMMARY commit hashes | git history | commit existence | ✓ VERIFIED | All 9 documented hashes exist; assets at `b65335ac`, favicon dark fix at `7f077067` |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|------------|--------|----------|
| LOGO-05 | 87-01 | ✓ SATISFIED | Truth 1 |
| LOGO-06 | 87-01 | ✓ SATISFIED | Truth 2 |
| LOGO-07 | 87-01 + 87-02 | ✓ SATISFIED | Truths 3–4 (round-4 extension maintainer-authorized) |
| LOGO-08 | 87-02 | ✓ SATISFIED | Truth 5 + gate battery + renders |

No orphaned Phase 87 requirements in REQUIREMENTS.md.

### Scope Verification

| Check | Result |
|-------|--------|
| Frozen codex brandbook untouched: `git diff --quiet 09a84dd4 -- brandbook/` | ✓ clean |
| Tournament artifacts confined to .planning/ | ✓ brandbook-fable/ contains only assets/, tokens.css, tokens.json; zero option/variant/round files outside .planning/ |
| brandbook-fable/ git status | ✓ clean (all committed) |

### Anti-Patterns Found

None blocking.

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| brandbook-fable/assets/logo-with-tagline.svg | Tagline text is "Email, made visible." where plan 87-02 Task 3 specified "Mail you can see through" | ℹ️ Info | Not a gap: the roadmap SC locks only that with-tagline is the sole subtitle-bearing asset (true). "Email, made visible." is a canonical tagline from `prompts/mailglass-brand-book.md` (lines 51, 701 — the brand source of truth), and the decision record documents the shipped wording, so Phases 88–90 have a consistent reference. |
| .planning/REQUIREMENTS.md | LOGO-07/LOGO-08 checkboxes still unchecked ("Pending") | ℹ️ Info | Both are satisfied in the codebase; executors deliberately left REQUIREMENTS.md to the orchestrator per the known dirty-planning-tree convention. Orchestrator housekeeping, not a goal gap. |

### Human Verification Required

None. The phase's inherently human judgment — aesthetic selection — was exercised by the maintainer across all four recorded pauses (the selection trail IS the human verification), and the remaining checks (rendering, dark adaptation, constraint gates) were self-verified programmatically and visually by the verifier per the project's self-verify convention.

### Gaps Summary

No gaps. The phase goal is achieved end-to-end in the codebase: a constraint-screened 8-option field (2 per axis, 112/112 pre-flight) was presented in a self-contained rendered-evidence gallery at a hard pause; the maintainer's explicit selections drove three bounded refinement rounds (the third extension maintainer-authorized with a recorded fallback winner, rejection_count 0 throughout); and the winner 4D "the sealed flap" ships as a complete 8-asset outlined-path system in `brandbook-fable/assets/` — every gate green, renders verified on light and dark including the favicon's prefers-color-scheme adaptation, with a decision record carrying the usage rules, color program, and asset manifest that Phases 88–90 consume.

---

_Verified: 2026-06-11T20:55:00Z_
_Verifier: Claude (gsd-verifier)_
