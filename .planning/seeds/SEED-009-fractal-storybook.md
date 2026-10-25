---
id: SEED-009
status: planted
planted: 2026-10-25
planted_during: v2.9 close-out (PR #302)
trigger_when: next UI-focused milestone. The owner called this "the next major opportunity" to ramp up UI quality. Propose it first when the owner asks what's next.
scope: large
---

# SEED-009: Fractal Storybook as the UI quality engine

## The One-Line Version

Turn phoenix_storybook into the single review surface for the whole admin UI. It covers every level, from primitives through patterns, section areas and sections up to whole JTBD screens. Every state that really occurs gets a story. A generic Playwright sweep then checks every story at 320/375/768/1280/1440 in light and dark, for rendering, overflow, axe and target size. Unrealistic scenarios are pruned.

## Why

- Today storybook covers 5 primitives. The 1428-line gallery is a second inventory, and it ships to adopters.
- No section or page composition is storied, and neither is any replay or quick-view state.
- Stories are the fastest lane and the best surface for the owner's quality bar:
  - elegant typography and hierarchy, with nothing redundant;
  - light and dark both looking good;
  - user-facing microcopy;
  - a coherent journey and navigation;
  - mobile-first design.

## Plan shape

The full rationale and decisions are in `.planning/research/storybook-fractal/RECOMMENDATIONS.md`:

1. Refresh the JTBD coverage and personas.
2. Build DB-free persona fixtures with a realism-invariant test.
3. Add the story manifest and the generic sweep spec, standardising the viewports.
4. Story primitives and patterns, porting gallery specimens and pruning as we go.
5. Extract presentational page components from Operator, Inbound and PreviewLive, then add area and screen stories.
6. Run a rubric review per section and fix at the lowest tier.
7. Retire the gallery.

This supersedes Phase 173 D-02/D-03. It adds no new dependencies.
