# Phase 114: Component Groups - Discussion Log (Assumptions Mode + Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-20
**Phase:** 114-component-groups
**Mode:** assumptions (with per-area research subagents)
**Areas analyzed:** Layout approach, Visual hierarchy / box-nesting, Proof machinery, Scope

## Assumptions Presented (initial, from gsd-assumptions-analyzer)

### Layout Approach
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Spacing-token discipline on existing markup, NO new shared layout primitive | Likely | `components.ex` has only `filter_section/1`; 8 surfaces share hand-rolled `card ... p-6` shell; conformance precedent = "discipline + grep gate" |

### Box-Nesting / Hierarchy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Only `support_cards` exceeds depth 2 (inner `bg-base-200` card-in-card); flatten inner to lighter treatment; confirm routing_trace ≤2 | Likely | `support_cards.ex:22,38,84,130` two same-tone bordered cards; other groups single-card |

### Proof Machinery
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend existing gates only: GROUP-NESTING grep + Playwright alignment/overflow + composed-group gallery specimens | Likely | `assertNoElementHorizontalOverflow` ~496, `boundingBox()` ~857-861, `PRIMITIVE_VIEWPORTS` ~19-23; gallery has only per-component specimens |

### Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Six group modules + two live-view compositions (incl. `space-y-4`) + gallery + gates only; not lists/overviews/nav/shell/preview | Confident | Phase goal names exactly three groups; other surfaces carry own locked gates |

## Research Performed (3 parallel gsd-advisor-researcher agents)

The user requested deep per-area research (pros/cons/tradeoffs, Elixir/Phoenix idiom, lessons
from successful libs cross-language, DX/UX, brand book, `prompts/` research, design pillars,
user-psychology/JTBD lenses) and a one-shot coherent recommendation set.

### Research 1 — Layout: tokens-only vs shared layout primitive
- **Finding:** Recommended a HYBRID — extract ONE thin `<.card>` shell into `Components` (Phase 110
  already locked "repeated hand-rolled primitive = drift"; card-component is idiomatic Phoenix,
  matches the module's own `stat_card`/`filter_section`/`data_state` precedent and LV best-practice
  research), AND apply token discipline. Boundary: extract only the shell (border+radius+surface+
  outer padding, one `padding` attr, one `<:inner_block>`, ≤20 lines); inter-card rhythm and internal
  grids stay as utilities (over-slotting a card into a layout engine = shadcn/GOV.UK footgun). Also
  surfaced ~190 raw off-grid tokens (`p-6`/`mt-1`/`space-y-1`/`gap-2`) that current gates miss →
  add a SPACE-GATE.
- **Source:** prompts/phoenix-live-view-best-practices, prompts/elixir-opensource-libs-best-practices,
  prompts/mailglass-engineering-dna; brandbook/brand-book.md; Phoenix 1.7 core_components / Petal /
  SaladUI / shadcn / GOV.UK precedent.
- **Confidence impact:** Revised assumption 1 from "no new primitive" (Likely) → thin shell primitive
  + token discipline (locked).

### Research 2 — Visual hierarchy without the box prison
- **Finding:** Confirmed and sharpened. Single rule: outer group `bg-base-200` raised + `shadow-raised`;
  nested = borderless `bg-base-100` sunken inset; never two `bg-base-200` in one stack. `support_cards`
  is the lone offender; reference groups (`evidence_card`, `routing_trace`, both timelines) already do
  it right. Primary/Secondary via content weight (display-bold colored count + one `btn-primary`),
  optional 3px status left-rule (brand Alert recipe), never color-alone.
- **Source:** brandbook/brand-book.md (surface-sunken/well ~108, Alert left-edge ~331, flat-first ~33),
  app.css surface tones; GOV.UK / Stripe / Linear / Material 3 surface-tone nesting practice; WCAG 1.4.1.
- **Confidence impact:** Confirmed assumption 2 (Likely → locked) with a precise, brand-grounded fix.

### Research 3 — Proof machinery
- **Finding:** Grep ALONE cannot count tree depth (line-oriented, multiline/composed HEEx). Decisive
  multi-mechanism strategy: GROUP-02 depth ≤2 → authoritative **Floki ExUnit ancestor-count** (Floki
  already in `shell_test.exs`, Node-free, flake-free) + grep tripwire (`p-6` + same-tone card-in-card)
  + Playwright padding-floor; GROUP-03 → Playwright scoped-sibling `boundingBox().x` equality (±1px) +
  overflow at 320/1280, scoped to `[data-group-card]` direct siblings only; GROUP-01 → Playwright
  padding-floor + sibling-x. Host both render-time proofs in new composed-group gallery specimens
  (data-free, stable testid), bound to reality by one live-view smoke assertion.
- **Source:** prompts/elixir-oss-lib-ci-cd-best-practices, prompts/phoenix-live-view-best-practices,
  .planning/research/v1.13/PITFALLS.md + STACK.md; structural.spec.js + shell_test.exs Floki precedent.
- **Confidence impact:** Revised assumption 3 (Likely) — added Floki ExUnit as the authoritative depth
  proof (grep demoted to tripwire); scoped-sibling alignment selector locked.

## Corrections Made

The user did not correct via the multiSelect path; instead requested research, then locked all four
researched recommendations ("Yes, lock all four"). Net deltas from initial assumptions:

- **Layout (D-01..03):** "no new primitive" → thin `<.card>` shell primitive + token sweep + SPACE-GATE.
- **Hierarchy (D-04..06):** confirmed + sharpened to the single tonal-inset rule + content-weight emphasis.
- **Proof (D-07..11):** added Floki ExUnit depth check as authoritative (grep → tripwire); scoped Playwright.
- **Scope (D-12):** confirmed unchanged.

## External Research

No web/library-version research was needed — this is internal design-system work grounded in the
repo, the brand book, and the `prompts/` research corpus.
