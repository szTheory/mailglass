# Phase 107: Inbound Replay-Modal A11y Parity (WR-03) - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-17
**Phase:** 107-inbound-replay-modal-a11y-parity-wr-03
**Mode:** assumptions
**Areas analyzed:** A11y Mechanism, Focus Fix (latent id), Scope & Honest Framing, Asset/CSS Bundle, Playwright Structural Assertion

## Assumptions Presented

### A11y Mechanism — Reuse Operator's Server-Side JS Commands (No JS Hook)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Port via `phx-key`+`phx-window-keydown="close_replay"` on the inbound dialog and a `phx-mounted={JS.focus_first}`/`phx-remove={JS.focus}` sibling span — no new `phx-hook`/JS file | Confident | operator `replay_modal.ex:28-29`, `operator_live.ex:499-503`; inbound dialog `inbound/replay_modal.ex:27-33` missing these; `close_replay` already at `inbound_live.ex:179-180`; `assets/` has no `js/` dir |

### Focus Fix — Give the inbound dialog a real `id`
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `id="inbound-replay-modal"` (and `id` on the trigger) so `JS.focus_first` resolves; do not copy the operator's broken selector | Likely | operator dialog div has only `data-testid`, no `id` (`operator/replay_modal.ex:23-32`) while `operator_live.ex:501` selects `#operator-replay-modal` — a latent no-op |

### Asset/CSS Bundle — No `priv/static` Change Expected
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Attributes-only change → no new Tailwind classes → `app.css` unchanged; run `:tailwind` build alias and confirm `git diff --exit-code priv/static/` clean | Confident | new attrs are not class names; `:focus-visible` rings already in `app.css` (`structural.spec.js:804-851`); `:tailwind` wrapper `mix.exs:99`, build alias `mix.exs:186`; CI gate per CLAUDE.md |

### Playwright Structural Assertion — New Test in `structural.spec.js`
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add a structural assertion (role/aria-modal, keydown attrs, Escape-closes) in the inbound describe block; no operator a11y test exists to mirror | Confident | `structural.spec.js` is the structural-assertion home (lines 263/552/808-851); `operator.spec.js:123-184` tests the replay flow not focus/Escape; inbound testids at `inbound/replay_modal.ex:28,56` |

### Scope & Honest Framing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Deliver focus-on-open + return-focus + Escape; frame as focus management parity, NOT WCAG / cyclic Tab-trap | Likely | `JS.focus_first` only sets initial focus; nothing in `operator_live.ex:499-503` or `app.css` prevents Tab leaving; Honest Surface Area lens; true trap needs custom JS |

## Corrections Made

No corrections — both flagged judgment calls confirmed with the recommended option.

### Focus Fix (latent id)
- **Assumption:** Add a real `id` to the inbound dialog so focus actually moves in.
- **User decision:** "Add a real id (Recommended)" — inbound only; do not fix the operator modal in this phase.
- **Reason:** Match the operator's intent (working focus), not its buggy literal; satisfies "modal traps focus" success criterion. Operator-modal fix deferred.

### Scope & Honest Framing
- **Assumption:** Focus-on-open + Escape parity, framed honestly (not WCAG / not cyclic Tab-trap).
- **User decision:** "Focus-on-open + Escape (Recommended)."
- **Reason:** No custom JS allowed (no-Node posture); Honest Surface Area lens; true Tab-trap exceeds a parity port.

## Methodology Lenses Applied
- **Decisive-By-Default Research Posture** — single decisive recommendation per area (minimal_decisive calibration).
- **Honest Surface Area** — drove D-06/D-07: no over-claim of WCAG conformance; name the exact mechanism.
- **Recommendation-First Synthesis** — recommendations led; user confirmed both forks.
- **Compatibility Contract Ergonomics** — no change to the inbound contract; pure additive a11y attributes.

## External Research
None performed — the operator modal + `structural.spec.js` fully demonstrate the pattern; analyzer flagged no gaps.
