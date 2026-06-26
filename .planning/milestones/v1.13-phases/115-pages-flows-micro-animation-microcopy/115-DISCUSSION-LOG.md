# Phase 115: Pages/Flows + Micro-Animation + Microcopy - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-20
**Phase:** 115-pages-flows-micro-animation-microcopy
**Mode:** assumptions + 4-area parallel advisor research (maintainer requested deep research over a direct fork question)
**Areas analyzed:** IA/Flow proof (FLOW-01/02), Permission/Stale/Tenant state scope, Micro-animation (FLOW-03), Microcopy + ban coverage (FLOW-04)

## Assumptions Presented (from gsd-assumptions-analyzer)

### Area 1 — IA/Flow
| Assumption | Confidence | Evidence |
|---|---|---|
| FLOW-01/02 = proof layer + 320 floor, not IA re-derivation | Confident | structural.spec.js:837-867 hardcoded 390; primitives only reach 320 (19-23) |
| `:permission_denied`/`:stale` are orphaned (never assigned live) | Likely | components.ex:410-464 + deliveries_list.ex:56-67; mount.ex assigns only :error/:empty |

### Area 2 — Micro-animation
| Assumption | Confidence | Evidence |
|---|---|---|
| `.motion-overlay` is center-origin; origin-awareness via `--mg-origin` custom prop, zero JS | Likely | app.css:312-335 fixed center scale; no transform-origin anywhere |
| theme-switch-never-animates is NOT yet enforced | Likely | components.ex:337 transition-colors; shell.ex:210 data-theme swap; no gate |

### Area 3 — Microcopy
| Assumption | Confidence | Evidence |
|---|---|---|
| Copy mostly follows voice; real work = polish + extend bans to new surfaces | Confident | voice_test.exs:25/105/138 surface gap; phoenix.mjs "noops" false-positive 32-35 |

## Decision: research before the fork

The maintainer declined the direct "how far to wire permission/stale" question and asked for
deep parallel research per gray area (pros/cons/tradeoffs, idiomatic Elixir/Phoenix, cross-ecosystem
lessons, DX/UX, JTBD/personas, brand book, design pillars) to one-shot a coherent recommendation
set. Four `gsd-advisor-researcher` agents were spawned in parallel, one per area.

## Research Outcomes (synthesized into CONTEXT decisions)

### Area B — Permission/Stale/Tenant scope → **Option (b) refined** (D-05/D-06)
- Researcher verdict: design-system + microcopy ONLY; do NOT wire live triggers.
  Permission-denied is a redirect-on-deny `on_mount` concern (mount.ex:52-62), not an in-page
  state (in-page denial leaks forbidden-resource existence — 403-vs-404 lesson). Stale needs a
  real freshness signal ("as of HH:MM" + refresh) that doesn't exist; a stale banner without a
  timestamp is worse than none (Datadog/Grafana/NN lesson). Tenant surfaces ARE live (Phase 112)
  → full microcopy + voice-test pass; keep no-tenant ≠ no-access ≠ no-tenants-exist distinct.

### Area C — Micro-animation (D-07/D-08/D-09)
- PART A origin-aware overlay: `transform-origin: var(--mg-origin, center)`, trigger sets inline
  `style` keyword (Radix `--radix-*-transform-origin` minus JS). Fixed intentional origin by role;
  centered modals stay center; never computed (zero-hook lock).
- PART B theme-switch suppression: **inverted default** — theme color transitions OFF by default,
  state layers opt-in. The next-themes `disableTransitionOnChange` reflow trick needs JS, so it's
  unavailable; inverting the default is the pure-CSS equivalent.
- Conformance: MOTION-GATE grep + Playwright getComputedStyle (transformOrigin, transitionProperty,
  getAnimations() empty post-swap); no pixel-diff.

### Area D — Microcopy + ban coverage (D-10/D-11/D-12)
- Extend COPY-LD-07 cause-naming; verbatim strings locked. Permission copy byte-identical / no
  existence leak. Fix the generic "There was a problem loading deliveries" string.
- Verification: rendered-HTML voice_test cases (render_component / LiveView nav) + a VOICE-GATE
  grep scoped to `*.ex` only (sidesteps phoenix.mjs false-positive); NO standalone
  Email/Status/Notification ban grep (Status is a real `<th>`) — enforce as positive assertions.

### Area A — IA/Flow proof + 320 floor (D-01/D-02/D-03/D-04)
- IA ~85% already locked (IA-LD-01..09) → verification checklist + thin gap-fill, no redesign.
- New `e2e/flows.spec.js`, 5-path taxonomy per surface by seeded URL, bounded matrix
  (full-walk at 320/system + overlay subset + light/dark/system spot-check), deterministic, no
  pixel-diff. 115 may lower 390→320 in touched tests but NOT promote the baseline (Phase 116 owns
  the re-score; re-baselining early erodes the floor — the v1.11 trap).
- 320 fixes: header flex-wrap cluster, mono ID cells (min-w-0/truncate/title),
  overscroll-behavior:contain on modal scroll, modal-above-scrim via z-tokens, ≥44px at 320.

## Reconciled Tension

Area D locked the stale copy *shape* with a live "as of {HH:MM}" + Refresh, while Area B said do
NOT ship a live stale trigger in 115. Resolution (D-05/D-10): lock the stale copy/affordance shape
as canonical, exercise it only in the gallery/component test with an illustrative timestamp, and
defer the live trigger + real timestamp/refresh wiring to Phase 116 / product.

## Corrections Made

No direct assumption corrections — the maintainer redirected the workflow to research-first, and
the research converged decisively on all four areas (no escalation needed).

## External Research

- next-themes `disableTransitionOnChange` (reflow trick is JS — unavailable zero-JS) —
  https://github.com/pacocoursey/next-themes
- Disable CSS transitions on color-scheme change (reflow footgun) —
  https://reemus.dev/article/disable-css-transition-color-scheme-change
- Radix Popover `--radix-popover-content-transform-origin` —
  https://www.radix-ui.com/primitives/docs/components/popover
- CSS Anchor Positioning + Popover API (rejected — browser support / fights LiveView open-state) —
  https://web.dev/learn/css/popover-and-dialog
- 403-vs-404 / don't-confirm-existence-to-unauthorized — Authress, MDN 403.
</content>
