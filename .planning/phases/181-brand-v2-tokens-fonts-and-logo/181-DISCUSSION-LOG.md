# Phase 181: Brand v2 Tokens, Fonts and Logo - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-11-14
**Phase:** 181-brand-v2-tokens-fonts-and-logo
**Mode:** assumptions
**Areas analyzed:** Token source/role map/parity; Static contrast test; Fonts; Logo/favicon/arrows; Asset provenance, sequencing and BRTOK-06 proof

## Assumptions Presented

### Token source, role map and parity
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| "36 slots" is really 39 roles + 20 daisyUI slots + 2 logo roles; amend wording | Confident | brandbook/tokens.json, mailglass_admin/assets/css/app.css, token_parity_test.exs |
| Rewrite v1 tokens.json/tokens.css in place; no generator | Likely | app.css:9, 180-CONTEXT D-08, 179-CONTEXT D-17 |
| Extend parity to the system-dark media block | Confident | token_parity_test.exs extract_mg_token_value/3 |
| Unsourced slots built only from book hexes/composites | Likely | brandbook/v2/brand.json color.*, never |

### Static contrast test
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Book pairs + admin-rendered pair table, coverage guard, never-rules, mutation proof, 0.04045 threshold | Likely | accessibility_test.exs, brand.json contrastPairs |

### Fonts
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Six woff2, not seven | Confident | unzip -l of pinned zip, fonts.css |
| `--font-weight-bold: 600` override, call sites unchanged | Likely | check-conformance.sh BOLD-GATE, 168 font-bold uses |
| Compile-time embedding + static required-lane proof, browser check advisory | Confident | assets.ex, 180-CONTEXT D-04/D-13 |
| Update mailglass_admin-files.expected in this phase | Confident | ci.yml mix_task_tests, ci_policy.exs |

### Logo, favicon and arrows
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Inline typemark following html data-theme; /logo.svg byte-exact | Likely | components.ex:64, brand.json logo rules |
| Favicon verbatim from zip; ICO/PNG deferred to 183 | Likely | layouts/root.html.heex:10 |
| Replace all U+2190-2193 arrows with hero icons | Confident | brand.json type.license, heroicons-inline.js |

### Provenance, sequencing, BRTOK-06
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Assets only via scripts/brand_pin.exs; owned_dirs extended | Likely | brand.pin.json, scripts/brand_pin.exs |
| Four-plan split; superseded.json marker with every bundle change; axe last | Confident / Likely | before_catalog_manifest_test.exs, axe_baseline_test.exs |
| BRTOK-06 proven by phase-scope diff, no permanent byte-pin | Likely | config.ex, theme.ex have own hexes |

## Corrections Made

No corrections — all assumptions confirmed.

## External Research

- Tailwind 4.1.12 + daisyUI 5.5.19: `--font-weight-bold: 600` overrides `.font-bold` with a one-line output diff; daisyUI hardcodes 600 (not 700) on `.btn`, table thead, titles. (Source: scratch build with pinned binary)
- Browser synthesis: a 600 face requested at 700 gets no faux bold in Chromium 147 and WebKit 26.4 (Firefox not verified); `font-synthesis-weight: none` disables synthesis for 400-only families. (Source: Playwright render comparison; CSS Fonts 4)
- Glyph coverage: all six woff2 subset to 170 codepoints; `·`, `✓`, `←`, `→` and non-Latin text are missing. `·` appears in about 17 rendered places. Resolution (Claude's call, confirmed with the rest): replace `·` with `•`, scan rendered text for out-of-subset characters. (Source: fontTools cmap check of the pinned zip)
