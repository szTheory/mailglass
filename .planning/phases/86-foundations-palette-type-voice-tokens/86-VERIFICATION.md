---
phase: 86-foundations-palette-type-voice-tokens
verified: 2026-06-11T19:05:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 86: Foundations — Palette, Type, Voice, Tokens — Verification Report

**Phase Goal:** The fable brand has a complete, contrast-proven token foundation for light and dark themes that every later artifact consumes
**Verified:** 2026-06-11T19:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

All evidence below was gathered independently from the artifacts (parse, grep, diff, and a fresh WCAG script at /tmp/verify86_contrast.py) — SUMMARY.md claims were not taken as evidence.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria merged with PLAN must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | (SC1/FOUND-01) Every seed palette/typography decision has an explicit evolve-vs-keep record with contrast math; six fix hexes + codex dark ramp adopted | ✓ VERIFIED | 86-foundations-decisions.md §1: KEEP rows (Ink/Glass/Ice/Mist/Paper/Slate/Pine/Crimson/Amber with ratios), EVOLVE rows for all six fix hexes each citing the failing seed ratio AND the passing computed ratios, ADOPT rows for the codex dark ramp (#0D1B2A/#152538/#1F3049/#0A1521/#1B3E55) with re-verified ratios, DECIDED rows for the four dark feedback bgs |
| 2 | (SC2/FOUND-02) tokens.json (DTCG-2025.10, two tiers) + tokens.css define palette → roles → interaction states → feedback states + type/space/radius/focus for light AND dark | ✓ VERIFIED | tokens.json parses; 136 `$value` entries; zero `"value":`/`"$schema"` legacy dialect; tier 1 `palette.*` (36 brand-named values, no numeric ramps) + tier 2 `color.light`/`color.dark` (39 roles each, identical key sets, all aliases resolve); states present: default/hover (`link-hover`)/active (`link-active`)/focus (`focus-ring`)/disabled (`text-disabled`)/selected (`surface-selected`); 4×5 feedback roles; font/text/space/radius/focus groups in both files |
| 3 | (SC3/FOUND-03) Computed WCAG matrix covers every text-role/surface-role pair in both themes with AA/AAA verdicts and a usage rule per pair; Glass on white 4.82 AA; tinted-surface accent text routes through glass-deep | ✓ VERIFIED | 192 hex-bearing matrix rows across both themes incl. on-solid pairs and SC 1.4.11 non-text checks; every row carries AA/AAA normal+large verdicts and a usage rule. Independently recomputed 22 ratios with a fresh script: 22/22 match (incl. Glass/white 4.82 PASS, Glass/Mist 4.37 FAIL anchor, rejected #D47368/overlay 4.09 FAIL) |
| 4 | (SC4/FOUND-04) No token name/description references planning, phases, milestones, the old brandbook, or process vocabulary | ✓ VERIFIED | `grep -riE "phase\|plan\|milestone\|codex\|gsd\|draft\|TBD" brandbook-fable/` → zero hits; extended denylist (`req-\|tournament\|option-\|baseline`) also zero hits |
| 5 | (PLAN) tokens.css yields complete light AND dark themes — every `--mg-color-*` role under :root reassigned under `[data-theme="dark"]` and mirrored in the media block | ✓ VERIFIED | 39 unique `--mg-color-*` properties, each declared exactly 3× (light, dark attr, dark media); zero missing dark roles |
| 6 | (PLAN) Six research fix hexes bound to their fixing roles in tokens.json | ✓ VERIFIED | #1D637A → light link/accent-text/info-text/info-solid; #174E61 → light link-hover/link-active; #96520E → light warning-text; #74909F → light border-input; #62809A → dark border-input/border-strong; #E29089 → dark error-text/border/solid — all confirmed by reading tokens.json role bindings |
| 7 | (PLAN) Decision record contains a script-computed matrix with ratio + AA/AAA verdicts + usage rule per pair, incl. Glass 4.82 and the glass-deep routing rule | ✓ VERIFIED | §2 anchors reproduced; explicit rule "Never normal-size text on Mist / selected / info surfaces … use accent-text (glass-deep)"; method section states formula (sRGB 8-bit, 0.04045 threshold) for identical recomputation |
| 8 | (PLAN) Evolve-vs-keep rows cover palette, typography (Inter-preinstalled-nowhere honesty + exact type scale), and voice | ✓ VERIFIED | Typography section records "Inter is preinstalled on no major OS … most viewers see the system fallback" + exact scale 44/36/30/24/16/14/14; Voice section keeps thoughtful-maintainer seeds and defers the full voice system to Phases 88/89 |
| 9 | (PLAN) Hygiene grep over brandbook-fable/ returns nothing | ✓ VERIFIED | Exit code 1 (no matches) on both the plan denylist and the extended denylist |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook-fable/tokens.json` | DTCG-2025.10-style two-tier tokens | ✓ VERIFIED | Parses; 136 `$value`; no legacy dialect; 14,140 bytes (≤ 16,384 budget); contains `"$value"` |
| `brandbook-fable/tokens.css` | Usable `--mg-*` properties, three-state toggle, honest font stacks | ✓ VERIFIED | Contains `[data-theme="dark"]`; `color-scheme` ×4 incl. light+dark; `prefers-color-scheme: dark` ×1; `system-ui` and `ui-monospace` present; zero `@font-face`, zero `@import`/`url(`; no Inter-then-bare-sans-serif stub stack; braces balanced; 5,759 bytes (≤ 10,240 budget) |
| `86-foundations-decisions.md` | Evolve-vs-keep records + full computed matrix | ✓ VERIFIED | Contains anchor "4.82"; 192 matrix rows; covers FOUND-01 + FOUND-03 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| tokens.css | tokens.json | hand-synced hex values | ✓ WIRED | Set-difference of unique hexes (css minus json) is empty; additionally every `--mg-color-*` value in both CSS theme blocks matches its alias-resolved tokens.json value role-by-role — zero mismatches |
| decisions.md | tokens.json | matrix computed from shipped hexes | ✓ WIRED | Only stray hex in decisions.md not present in tokens.json is `#D47368` — the documented rejected codex value cited as evidence (explicitly permitted by the plan) |
| tokens.css dark attr block | tokens.css :root block | identical `--mg-color-*` name set | ✓ WIRED | All 39 roles appear in all three blocks; dark attr block and dark media block normalize to identical 40-declaration sets (39 colors + color-scheme) |

### Independent Contrast Recomputation (Level 4 — data is real, not asserted)

Fresh WCAG relative-luminance script (/tmp, not committed). 22/22 recorded figures reproduce exactly:

| Pair | Computed | Recorded | Match |
|------|---------:|---------:|-------|
| Ink #0D1B2A on Paper #F8FBFD | 16.74 | 16.74 | ✓ |
| Glass #277B96 on white | 4.82 | 4.82 | ✓ |
| Glass on Mist (FAIL anchor) | 4.37 | 4.37 | ✓ |
| glass-deep #1D637A on Mist | 6.12 | 6.12 | ✓ |
| glass-deepest #174E61 on Paper | 8.79 | 8.79 | ✓ |
| amber-deep #96520E on Mist | 5.43 | 5.43 | ✓ |
| crimson-bright #E29089 on raised #152538 | 6.34 | 6.34 | ✓ |
| crimson-bright on overlay #1F3049 | 5.44 | 5.44 | ✓ |
| dark success #8BB77F on #142B22 | 6.56 | 6.56 | ✓ |
| dark warning #E0A955 on #2B2314 | 7.37 | 7.37 | ✓ |
| dark error #E29089 on #2E1B1E | 6.65 | 6.65 | ✓ |
| dark info #A6EAF2 on #11293A | 11.18 | 11.18 | ✓ |
| slate-soft #74909F vs Paper | 3.24 | 3.24 | ✓ |
| slate-soft vs Mist | 3.06 | 3.06 | ✓ |
| slate-soft vs light selected (recorded FAIL) | 2.91 | 2.91 | ✓ |
| slate-bright #62809A vs Ink | 4.20 | 4.20 | ✓ |
| slate-bright vs dark selected (recorded FAIL) | 2.72 | 2.72 | ✓ |
| rejected codex #D47368 on overlay (FAIL evidence) | 4.09 | 4.09 | ✓ |
| text-muted on light selected | 4.72 | 4.72 | ✓ |
| dark text-muted on selected | 6.66 | 6.66 | ✓ |
| glass-deep on Paper | 6.48 | 6.48 | ✓ |
| crimson-bright on dark selected | 4.60 | 4.60 | ✓ |

The record is honest about its FAILs: text-disabled rows marked FAIL/exempt (SC 1.4.3), accent-on-tinted rows marked FAIL with a routing rule, and border-input-on-selected marked FAIL with an explicit usage rule ("form controls are never placed on selected-row surfaces") in both themes — failing/conditional pairs all carry usage rules.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| FOUND-01 | 86-01 | ✓ SATISFIED | Truths 1, 8 |
| FOUND-02 | 86-01 | ✓ SATISFIED | Truths 2, 5, 6 |
| FOUND-03 | 86-01 | ✓ SATISFIED | Truths 3, 7 + independent recomputation |
| FOUND-04 | 86-01 | ✓ SATISFIED | Truths 4, 9 |

No orphaned requirements: REQUIREMENTS.md maps exactly FOUND-01..04 to Phase 86; the plan claims all four.

### Scope and Hygiene Checks

| Check | Result |
|-------|--------|
| brandbook-fable/ contains ONLY tokens.json + tokens.css | ✓ PASS (ls shows exactly two files) |
| Frozen brandbook/ untouched | ✓ PASS — `git diff --quiet 09a84dd4 -- brandbook/` clean (committed tree and working tree identical to baseline); phase commits e5a67a7d/7c039b6c/524d7bd9 touch only brandbook-fable/ + .planning/ |
| Process-vocabulary denylist (incl. extended) over brandbook-fable/ | ✓ PASS — zero hits |
| Debt markers (FIXME/XXX/HACK/PLACEHOLDER/lorem) in shipped files + record | ✓ PASS — zero hits |
| Throwaway scripts not committed | ✓ PASS — `git ls-files | grep -iE 'mg_(contrast|gate|matrix)'` empty |
| Size budgets | ✓ PASS — 14,140 / 5,759 bytes within 16,384 / 10,240 |

### Anti-Patterns Found

None.

### Human Verification Required

None. Every Phase 86 success criterion is mechanically verifiable (parse, parity, grep, computed math) and was verified here. Aesthetic judgment of the palette in rendered context is deliberately deferred by the roadmap to Phase 87 (maintainer hard pause) and Phase 90 (maintainer UAT) — those are later-phase gates, not Phase 86 gaps.

### Gaps Summary

No gaps. The phase goal — a complete, contrast-proven token foundation for light and dark themes — is achieved in the actual artifacts: full 39-role light/dark parity in both files, two-tier DTCG structure with no legacy dialect, all six research fix hexes bound to the roles they fix, the four dark feedback backgrounds decided and verified, a 192-row computed matrix whose figures reproduce exactly under independent recomputation, honest font fallbacks with no webfont machinery, and zero process vocabulary in the shipped folder.

---

_Verified: 2026-06-11T19:05:00Z_
_Verifier: Claude (gsd-verifier)_
