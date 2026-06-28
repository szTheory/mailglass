# Phase 122: Preview surface redesign - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 122-preview-surface-redesign
**Mode:** assumptions (+ user-requested 3-area research synthesis)
**Areas analyzed:** Scope, Dual-theme toggle UX/a11y, IA/DX polish, State coverage, Microcopy, Paired-tests/persona/asset

## Method

Codebase-first assumptions analysis (gsd-assumptions-analyzer, 15 files read) surfaced the scope and
the gray areas. The user then directed a deeper research pass: spawn per-area research subagents
(pros/cons/tradeoffs, idiomatic Phoenix/LiveView, cross-tool lessons even cross-language, DX/UX +
creative-direction + JTBD lenses, design pillars, brandbook + `prompts/` research) and one-shot a
coherent recommendation set. Three `gsd-advisor-researcher` agents ran in parallel:
1. Dual-theme toggle UX + a11y
2. Email-preview dev-tool IA + DX polish
3. State coverage + microcopy/onboarding DX

Load-bearing facts were verified directly against the code before locking (theme_picker existence,
preview_theme_path frame-carry-through vs shell.set_theme_path, brandbook canonical copy strings).

## Assumptions Presented

### Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Light alignment-and-polish, NOT a structural port; orientation already empty-pane-only | Confident | preview_live.ex:362 (sole orientation_strip, in @mailables==[] branch); DEFECT-REGISTER:289,305 "no net-new headline defect"; no filters/data_state/@records |
| In-scope drifts: dead dark_chrome attr, spacing/heading token parity, Mailable noun | Likely | sidebar.ex:30,72 (declared, never read); preview_live.ex:368,410 (h1); brand-book.md:69 |

### Dual-theme toggle UX/a11y
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve the exact two-toggle wiring; carry-through must not break | Confident | preview_live.ex:589-638; flows.spec.js:454-458 |
| Adequate aria-label but missing aria-pressed state semantic — bounded polish | Likely | preview_live.ex:310-345 (no aria-pressed) |

### State coverage + paired-test trap
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No data_state needed; synchronous render + dev-only-no-auth | Confident | preview_live.ex:720-748 (try/rescue, struct-match); no Task.async/assign_async |
| Paired-test trap smaller than 121's (orientation already empty-only) | Confident | structural.spec.js:827-831 / flows.spec.js:60-61 assert only on empty route |

## Research Findings (merged into decisions)

### Dual-theme toggle (Agent A)
- **Recommendation: adopt canonical `Components.theme_picker` (components.ex:326) for admin chrome.**
  Preview is the lone surface reinventing the theme control as a bespoke binary button (drops the
  real tri-state light/dark/system). The other 3 surfaces use theme_picker via shell.ex:282. Adopting
  it makes the two theme controls *structurally distinct shapes* (segmented 3-way picker vs single
  button) — the least-surprise way to keep "App theme" vs "Email backdrop" un-confused (Storybook
  two-independent-controls lesson; WCAG 1.4.1 by form-factor, not icon+word alone).
- Keep email-backdrop as a single binary button + add `aria-pressed`; visible "Email backdrop" label;
  `aria-live=polite role=status sr-only` announce (121 D-11 precedent) for the remote-pane change.
- **GUARDRAIL:** theme_picker's `set_theme` event MUST route through Preview's `preview_theme_path/2`
  (preserves frame=dark), NOT shell's `set_theme_path/2` (no frame handling → would reset the email
  backdrop on every chrome flip). Verified: shell.ex:102 has no frame handling; preview_live.ex:589-638
  does the carry-through. flows.spec.js:454-458 locks it.
- Sources: W3C APG Switch/Button/Radio patterns (switch is binary-only → rules out role=switch for
  tri-state chrome); Storybook toolbars/globals + backgrounds addon.

### IA/DX polish (Agent B)
- **Recommendation: targeted alignment pass (Option A); reject porting operator machinery (Option B).**
- Confirmed dead `dark_chrome` attr (sidebar.ex:30,72 — never read; preview_live.ex never passes it).
- Coherence = shared chrome vocabulary, not shared structure. Preview already uses operator spacing
  scale, eyebrow+logo, single-h1, motion tokens, empty-pane-only orientation. Close the last gaps
  (brandbook copy, dead attr, noun/token normalize) and STOP.
- Big leave-alone list: tabs (role=tablist, matches Mailpit), device-frame (aria-pressed widths),
  assigns form (controls-above-canvas like Storybook args), iframe re-render, render pipeline.
- Cross-tool convergence (Storybook, react-email, Mailpit) validates Preview's existing explorer
  structure → honest scope is polish, not redesign.

### State coverage + microcopy (Agent C)
- **Confirmed: NO data_state import.** loading=phantom (synchronous in-process render), permission_denied
  (no tenant auth on /dev/mail), stale (no polling) — all structurally impossible. Importing it = dead UI.
- Four-branch cond covers every reachable state; invalid assigns-form input folds into render-error;
  discovery failure → sidebar warning badge; disconnect handled globally by LiveView.
- **Onboarding:** adopt brandbook Empty string verbatim ("No mailables discovered yet. Define one with
  `mix mailglass.gen.mailable`…"); surface generator as PRIMARY next step; demote module-marker/router
  checks to secondary.
- **Error card:** KEEP the inline exception `<pre>` (dev-only DX — Next 15.2 / Vite overlay convention;
  do NOT redirect to logs as the brandbook recipient-facing Error line implies); generalize headline
  "preview_props/0 raised" → "This Mailable raised while rendering"; name Mailable + scenario.
- Design pillars: single-h1 (enforced), focus/announce on error transition (121 D-11), motion-reveal on
  existing tokens (no new keyframes), responsive 320 (pre/code wrap), light/dark/system parity automatic.
- Sources: Storybook FAQ/error-boundary, Next.js 15.2 error overlay, Vite troubleshooting.

## Corrections Made

No corrections — the user requested deeper research rather than correcting assumptions. The research
confirmed and sharpened all Confident assumptions and resolved the two Likely items decisively:
- Toggle a11y "add aria-pressed" → upgraded to "adopt theme_picker for chrome + aria-pressed binary
  backdrop + aria-live announce" (a stronger, cross-surface-coherent answer the bare assumption missed).
- One reconciliation locked beyond the brandbook: the brandbook Error string ("…in your logs") is wrong
  for a dev-only preview tool — keep the inline `<pre>`, adapt only the voice.

## External Research

Performed via 3 parallel advisor-researcher subagents (see Research Findings above). Key external
sources: W3C APG (Switch/Button/Radio), Storybook (toolbars/globals, backgrounds, FAQ, error-boundary),
react-email preview server, Mailpit, Next.js 15.2 error overlay, Vite troubleshooting.
