---
phase: 85-research-and-differentiation-brief
verified: 2026-06-11T00:00:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 85: Research and Differentiation Brief — Verification Report

**Phase Goal:** The maintainer has a verified, row-addressable account of exactly where the codex brandbook falls short and a locked brief that defines what "beating it" means — before any fable artifact is authored.
**Verified:** 2026-06-11
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Merged from the four ROADMAP success criteria plus the two plan-only must-haves
(strengths register, file-manifest budgets).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Row-addressable defect/gap register exists, every weakness verified with file:line evidence against frozen 09a84dd4 | VERIFIED | 20 rows CDX-01..20 with exact `| ID | File:Line | Finding | Severity | Fable response |` header. `git diff --quiet 09a84dd4 -- brandbook/` exits 0. 15+ citations independently re-checked against actual file contents (see spot-check table below); zero mismatches. Path-existence loop over every `brandbook/...` citation: zero missing. |
| 2 | Audit records codex strengths so false differentiators die before the brief | VERIFIED | 9 strength rows CDX-S-01..09, all spot-checked real (state token group at tokens.json:60-73, dark ramp at tokens.css:108-129, SVG a11y at logo-primary.svg:1-3, file:// self-containment grep = 0 hits, currentColor fallback, reduced-motion block at tokens.css:136-143, real `mix` commands at readme-header.svg:27-28). `## Killed Differentiator Candidates` section kills 6 false claims; none reappears in the brief. |
| 3 | Brief locks at most 12 differentiators, each with a one-line "why it earns its bytes" | VERIFIED | Exactly 12 rows DIF-01..12 (`grep -c '^| DIF-'` = 12, within 6-12 gate). Every row has a non-empty single-line why-cell and an Evidence cell citing CDX/CDX-S rows. DIF-03/DIF-09 are the honest restatements the killed-candidates section permits (demonstrated dark, copy breadth), not the killed existence claims. |
| 4 | Brief contains the brand-book section outline and an explicit kill-list | VERIFIED | `## Brand-Book Section Outline` — 9 ordered sections with one-line content notes (Phase 88 implements verbatim). `## Kill-List` — 11 entries, each with a reason, covering all six CONTEXT seeds (personas, mission statements, mood boards, print/stationery, icon libraries, motion videos) plus codex-mistake/screenshot/binary/webfont extensions. |
| 5 | Brief defines the brandbook-fable/ file manifest with the three size budgets | VERIFIED | `## File Manifest` — 21 files across root/assets/examples/copy, each with purpose, per-file budget, and authoring phase (86-89). Budgets verbatim: folder <= 500 KB, index.html <= 150 KB, no single file > 100 KB; per-file ceilings sum to 489 KB. |
| 6 | Nothing exists under brandbook-fable/; all Phase 85 artifacts live in .planning/ | VERIFIED | `test ! -e brandbook-fable` passes (`ls` returns "No such file or directory"). Commits 0573d6d9 and f7157738 each touch exactly one file under `.planning/phases/85-*/`. `git diff --quiet 09a84dd4 -- brandbook/` exits 0 — frozen baseline untouched. |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/phases/85-research-and-differentiation-brief/85-codex-audit.md` | BRIEF-01 register + strengths, header row, min 80 lines | VERIFIED | 95 lines; exact header row present; Methodology cites 09a84dd4, defines severity scale 1-5 and exploit/fix/ignore taxonomy; 20 defect + 9 strength rows + killed-candidates section |
| `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` | BRIEF-02 differentiators/outline/kill-list/manifest, `## Kill-List`, min 100 lines | VERIFIED | 176 lines; all 8 required headings present (Differentiators, Non-Negotiables, Banned Motif Families, Compositional Stance, Ownable Axis, Brand-Book Section Outline, Kill-List, File Manifest, Pitfall Mapping) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| 85-codex-audit.md | brandbook/ @ 09a84dd4 | file:line citations in every defect row | WIRED | Citation pattern `brandbook/...:N` present in every non-absence row; absence gaps correctly use `brandbook/ (absent)` only for missing-file findings (CDX-16..20) |
| 85-differentiation-brief.md | 85-codex-audit.md | each DIF cites CDX/CDX-S rows | WIRED | All 12 Evidence cells carry CDX citations; three explicitly "beat" strength rows (CDX-S-02/03/08) |
| 85-differentiation-brief.md | research SUMMARY.md / PITFALLS-PORTABILITY.md | consumes settled decisions instead of re-deciding | WIRED | Lines 5, 53, 157, 164 reference both research files; settled values (token format, contrast fixes, dark ramp, GitHub SVG rules) delegated, not re-decided |

### Citation Spot-Checks (hostile re-check, 15 rows)

| Row | Citation | Re-checked content | Result |
|-----|----------|--------------------|--------|
| CDX-01 | logo-primary.svg:17 | `<text ... font-family="Avenir Next, Avenir, Helvetica Neue, sans-serif" ... letter-spacing="-1.6">mailglass</text>` | REAL |
| CDX-02 | logo-primary.svg:14 + brand-book.md:77 | gradient `fill="url(#mg-logo-primary-pane)"`; line 77 = "Avoid decorative gradients, blobs, lens flares, bevels, chrome, and fake depth." Gradient repeats at logo-mark.svg:14, favicon.svg:14, social-avatar.svg:15 | REAL |
| CDX-03 | tokens.json:70,75,76 | All three lines contain "Phase 84 contrast validation" / "Phase 84 validation" leakage | REAL |
| CDX-04 | tokens.css:108 + index.html | `[data-theme="dark"] {` at 108; zero `data-theme` occurrences in index.html; `.logo-box.dark {` at index.html:270 | REAL |
| CDX-05 | tokens.css:2 | `color-scheme: light;`; zero `prefers-color-scheme` hits anywhere in brandbook/ | REAL |
| CDX-06 | tokens.css:44,118 | `--mg-callout-info-bg: #eaf6fb;` at 44 stays light; dark block reassigns exactly 18 `--mg-` properties; `--mg-text: var(--mg-mist)` at 118 → Mist-on-Mist callout text | REAL |
| CDX-07 | brand-audit.md:153 | BRAND-GAP-08 row contains "research calculated 4.37:1"; tokens.css instructs "validate text pairs" — no computed matrix anywhere | REAL |
| CDX-08 | README.md:13-16 + brand-audit.md:5 | README links all four process docs; brand-audit.md:5 = "Phase 80 scope..."; assets/options/ = 18 files, assets/concepts/ = 11 files | REAL |
| CDX-09 | readme-header.svg:20 | Identical Avenir Next live `<text>` wordmark | REAL |
| CDX-10 | docs-page.svg:8, palette.svg:5, typography.svg:6 | Live `<text>`/`<g>` with Inter/Inter Tight stacks in all checked specimens | REAL |
| CDX-11 | favicon.svg:1,12-15 + brand-audit.md:150 | `width="32" viewBox="0 0 80 80"`; lines 12-15 geometry byte-identical to logo-mark.svg:12-15 (diff after id-normalization = empty); BRAND-GAP-05 flags fold ambiguity | REAL |
| CDX-13 | brand-book.md:142,146-158 + index.html:495-499 | "buildable UI, not mood boards" + 13-component list; index.html components are static `<img src="examples/*.svg">`; zero `<button>` elements in the page | REAL |
| CDX-14 | index.html:96-98,432 | Raw `rgb(234 246 251 / 0.8)` literals in hero gradient; line 432 instructs "do not copy raw hex into components" | REAL |
| CDX-15 | tokens.json:2 | `"$schema": "https://tokens.studio/schemas/tokens.json"`; zero `$type` keys in file | REAL |
| CDX-16..20 | brandbook/ (absent) | examples/ contains only 5 SVGs — no landing-page.html, no email-template.html, no og-card; no copy/ directory exists | REAL (absences confirmed) |

Zero straw men found. Every checked Finding matches the actual file content at the cited line.

### Behavioral Spot-Checks

Documentation-only phase — both plan automated gates re-executed by the verifier:

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Task 1 gate | freeze check + header + 3 pre-verified citations + row counts + path-existence loop | AUDIT-OK (20 >= 10 defects, 9 >= 3 strengths, 0 missing paths) | PASS |
| Task 2 gate | DIF count 6-12 + 5 heading greps + CDX citations + budget strings + `test ! -e brandbook-fable` | BRIEF-OK (N=12) | PASS |
| Frozen baseline | `git diff --quiet 09a84dd4 -- brandbook/` | exit 0 | PASS |
| Commit scope | `git show --stat 0573d6d9 / f7157738` | each touches exactly 1 file under .planning/ | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BRIEF-01 | 85-01 | Forensic row-addressable audit, every weakness verified against actual file contents | SATISFIED | 20-row register, 15 hostile spot-checks all real, strengths register, killed-candidates section |
| BRIEF-02 | 85-01 | Brief locks <=12 differentiators with why-lines, section outline, kill-list | SATISFIED | 12 DIF rows with one-line whys + evidence, 9-section outline, 11-entry kill-list, budgeted 21-file manifest |

No orphaned requirements: REQUIREMENTS.md maps only BRIEF-01/BRIEF-02 to Phase 85, and plan 85-01 claims both.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none (no TODO/TBD/FIXME/placeholder/debt markers in either artifact) | — | — |

### Standalone Consumability (anti-derivative check)

The brief's only `brandbook/` mention is the prohibition sentence itself ("never re-open any brandbook/ file"). Downstream phases get: differentiators with evidence carried by CDX ID, 7 non-negotiables, named banned-motif families, compositional stance, ownable axis, the verbatim Phase 88 outline, kill-list, per-phase pitfall ID mapping, and the full budgeted manifest with phase ownership. Settled technical values route to the research SUMMARY, not to codex files. PASS.

### Voice Check

Audit and brief language is specific and composed throughout — findings state file, line, and consequence ("callout body text on the callout background computes to 1:1, i.e. invisible"); strengths are credited without hedging; killed-candidates section actively prevents gloating; no subjective filler, no "Oops"-style copy. Consistent with the thoughtful-maintainer voice. PASS.

### Human Verification Required

None. Documentation-only phase; every success criterion is programmatically checkable and was checked. Maintainer A/B sign-off is deliberately deferred to Phase 90 per the roadmap.

### Gaps Summary

No gaps. All four roadmap success criteria plus both plan-only must-haves verified against the actual artifacts and the frozen brandbook baseline.

---

_Verified: 2026-06-11_
_Verifier: Claude (gsd-verifier)_
