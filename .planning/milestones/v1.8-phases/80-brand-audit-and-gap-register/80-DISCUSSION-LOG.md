# Phase 80: Brand Audit and Gap Register - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-05
**Phase:** 80-brand-audit-and-gap-register
**Mode:** assumptions + user-requested subagent/web research
**Areas analyzed:** audit posture, brand center, visual system, tokens, logo, surface stress tests, repo hygiene, DX, external ecosystem lessons

## Assumptions Presented

### Phase Boundary
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 80 should audit and frame the gap register, not finish the whole brandbook milestone. | Likely | `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` |

### Draft Artifact Treatment
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Existing `brandbook/` files are useful draft inputs, not approved outputs. | Likely | `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `brandbook/*` |

### Audit Shape
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The audit needs a stricter gap-register layer with stable, actionable findings. | Confident | `.planning/REQUIREMENTS.md`, `brandbook/brand-audit.md`, Phase 74 register precedent |

### Brand Strategy
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Preserve "Mailglass makes email visible" and "glass is a metaphor, not a visual excuse." | Confident | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `prompts/mailglass-brand-book.md`, `brandbook/brand-book.md` |

### Product/Admin Boundary
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Brandbook work must not change package code, public APIs, or the implemented admin design system. | Confident | `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `mailglass_admin/docs/design-system.md` |

### Logo Posture
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Current SVG logo set should be audited as one draft direction, not approved final logo system. | Likely | `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `brandbook/assets/*.svg` |

### Repo Hygiene
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep brand artifacts source-control-native and self-contained under `brandbook/`. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `brandbook/README.md` |

### External Research
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| No broad external brand research is needed for Phase 80; exact claim checks and ecosystem best-practice checks are enough. | Likely | `.planning/REQUIREMENTS.md`, prompt research, web scan |

## Corrections Made

No correction round was needed. The maintainer requested a deeper one-shot
recommendation pass using subagents, web research, local prompts, ecosystem
examples, graphic design/branding principles, UI/UX/DX analysis, and then said
they would follow the recommendations. The confirmed recommendation set is
captured in `80-CONTEXT.md`.

## Subagent Research

### Local Codebase And Prompts

Recommendation: Phase 80 should lock the audit posture and register shape, not
approve generated assets. Preserve the brand center, canonical product story,
voice/domain language, palette/type direction, source-native repo posture, and
admin-design-system boundary. Treat current SVGs as a candidate direction only.

Notable risks surfaced:

- Draft audit language can overclaim completion.
- Current specimens may need domain review where generic `phx_new` or
  "Delivered" language weakens Mailglass specificity.
- Prompt-era package or suite language must not resurrect marketing/campaign
  scope.

### Brand/Design-System Lessons

Recommendation: Keep the core brand, use a strict register rubric, tighten
tokens around semantic roles, make accessibility part of the brand promise,
lock dark/light/system behavior as token behavior, keep developer-docs energy,
and keep repo hygiene/artifact policy as audit outcomes.

Tradeoff: A small, restrained system is less visually dramatic than fashionable
developer-tool branding, but it is more credible for senior Phoenix maintainers
and easier to keep consistent.

### Logo And Visual Identity

Recommendation: Treat `brandbook/assets/*.svg` as one draft direction among
several. Keep wordmark-first identity and pane/message-fold semantics, but defer
final mark choice to Phase 82.

Specific footguns:

- Repeated `title`/`desc` IDs collide when multiple SVGs are inlined.
- Live SVG text is editable but font-dependent.
- `currentColor` in standalone image use may not behave as intended.
- Transparent marks need dark/reversed variants.
- The current triangular fold may read as document corner, envelope, or send
  arrow at small sizes.

### Repo Hygiene And OSS DX

Recommendation: Keep `brandbook/` direct-open, source-native, small, and outside
Hex package tarballs by default. Defer validation gates to Phase 84, but name
expected checks in Phase 80.

Suggested gates:

- `tokens.json` parses and token groups match expected semantics.
- CSS token names line up with semantic groups.
- Key contrast pairs pass normal-text AA with margin.
- SVG XML parses and rejects script, external refs, raster embeds, and unsafe
  constructs.
- HTML local refs work from disk.
- Artifact file sizes stay bounded.

## External Research

- W3C WCAG 2.2: treat accessibility criteria as testable, technology-neutral
  requirements; WCAG 2.2 adds focus and target-size guidance and remains
  backward-compatible with 2.1/2.0.
  Source: https://www.w3.org/TR/WCAG22/
- IBM Carbon: role-based color tokens, theme values, sparse accent use, and
  focus states on interactive elements with contrast requirements.
  Source: https://carbondesignsystem.com/elements/color/overview/
- GitHub Primer: base color tokens should feed functional/component tokens;
  base tokens should not be consumed directly in UI.
  Source: https://primer-docs-preview.github.com/product/getting-started/foundations/color-usage/
- Atlassian Design: design tokens are the single source of truth for repeatable
  decisions and support light/dark/high-contrast theming.
  Source: https://atlassian.design/foundations/design-tokens
- GOV.UK Design System and content guidance: use reusable components, clear
  coded examples, direct copy, single-purpose headings, and avoid relying on
  color/shape/location alone.
  Sources: https://design-system.service.gov.uk/components/ and https://www.gov.uk/service-manual/design/writing-for-user-interfaces
- Shopify Polaris: reusable accessible components help consistency, but
  integrations still need task-flow testing; default/native interactions reduce
  barriers.
  Source: https://polaris-react.shopify.com/foundations/accessibility
- Hex/ExDoc/Elixir docs: Hex builds docs through `mix docs`; ExDoc supports
  responsive docs, extras, logos/favicon, search, source links, and night mode;
  Elixir treats documentation as an API contract.
  Sources: https://hex.pm/docs/publish, https://ex-doc.hexdocs.pm/readme.html, https://elixir.hexdocs.pm/writing-documentation.html
- Tailwind/daisyUI: Tailwind v4 theme variables map design tokens to utility
  APIs; daisyUI semantic colors/theme variables support themeable UI.
  Sources: https://tailwindcss.com/docs/theme and https://daisyui.com/docs/colors/
- `Mailglass Lite` public presence: current web signal confirms the prompt-era
  naming-collision note should remain a logged risk, not a Phase 80 rename.
  Source: https://at.linkedin.com/company/htd-solutions

## Auto-Resolved

Not applicable. This was not `--auto`; the maintainer explicitly requested and
accepted recommendation-first defaults.
