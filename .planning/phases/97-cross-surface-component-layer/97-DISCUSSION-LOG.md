# Phase 97: Cross-Surface Component Layer - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-14
**Phase:** 97-cross-surface-component-layer
**Mode:** assumptions
**Areas analyzed:** Gallery LiveView Architecture; Component Uplift / CSS Bundle / Hero Icons; UI-SPEC-UI-REVIEW Gate & Ratchet Integration

## Methodology Lenses Applied

- **Decisive-By-Default Research Posture** + **Recommendation-First Synthesis** — the phase
  consumes a fully-locked research dossier (SUMMARY.md, 69 LD decisions) and established repo
  patterns; no open choice required escalation. Single decisive recommendations presented.
- **Honest Surface Area** — gallery is a dev-only, DB-free surface mounted in the dev
  `live_session` behind the adopter's `if dev_routes` wrap; no production-reachable route, no
  speculative knobs.

## Assumptions Presented

### Gallery LiveView Architecture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `MailglassAdmin.GalleryLive` mounted via one `live "/gallery"` line inside the dev preview `live_session :mailglass_admin_preview`; inherits `if dev_routes` wrap; never `/ops` | Confident | router.ex:219-225, 66-71, 257-272, 87-95 |
| In-code specimen list (`[{component, state, assigns}]` from STATE-LD matrix); no DB; no mailable scan | Confident | router.ex __preview_session__; SUMMARY.md STATE-LD rows |
| Both themes rendered side-by-side via twin `data-theme` wrappers per cell (not a toggle) | Confident | shell.ex:119, preview_live.ex:225 (DARK-LD-06) |
| `data-testid` = `gallery-{component}-{state}`; theme on wrapping ancestor, not in testid | Likely | structural.spec.js:29,41,421-428; shell.ex:320 |

### Component Uplift, CSS Bundle & Hero Icons
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Edit shared components in place per cited STATE-LD/DARK-LD/MOTION-LD; add missing nav focus rings (STATE-LD-06); resolve theme_toggle btn-sm/min-h-11 (STATE-LD-08) | Confident | shell.ex:206-213,230-237,266; SUMMARY.md |
| Rebuild + commit `priv/static/app.css`; gated by `git diff --exit-code` in verify.preview | Confident | mix.exs:183-188; CLAUDE.md asset rule |
| No new hero icon required (reuse embedded glyphs); unembedded `hero-*` renders invisibly with no failure | Confident | components.ex:232-255; heroicons-inline memory |

### UI-SPEC / UI-REVIEW Gate & Ratchet Integration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Un-skip reserved gallery block via no-auth `openGallery(page)` helper; flip GAP-05 → fixed | Likely | structural.spec.js:38-42,421-428; RATCHET-GAP-REGISTER.md:138 |
| Gallery is capture surface for the frozen 36-cell baseline; do NOT add a "gallery" surface to `@surfaces`/ui-baseline-scores.json | Likely | ratchet_baseline_test.exs:26-28,51-63 |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## Todo Disposition

- `2026-06-13-refresh-outbound-admin-ui-look-and-feel.md` (match 0.9): user chose **Record as
  Phase 98** — the outbound/operator surface refresh is Phase 98 scope, not the shared-component
  layer. Recorded as reviewed-not-folded in CONTEXT.md `<deferred>`.

## External Research

None performed — analyzer reported `Needs External Research: None`. The phase consumes the
fully-locked v1.11 SUMMARY (69 LD decisions) and builds on established repo patterns.
