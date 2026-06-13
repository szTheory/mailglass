# Phase 94: Token Re-Baseline onto Canonical Brand - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-13
**Phase:** 94-token-re-baseline-onto-canonical-brand
**Mode:** assumptions → escalated to research-driven synthesis (user request)
**Areas analyzed:** token-consumption mechanism, token-parity test, conformance/motion gates, role remap + dark-mode contrast

## Assumptions Presented (assumptions-analyzer pass)

### Token-consumption mechanism (TOKEN-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Vendor-copy `brandbook/tokens.css` into `assets/`, import locally, daisyUI vars ref `var(--mg-*)` | Likely | `mix.exs:215` excludes assets/+brandbook/ from tarball; vendor precedent in `assets/vendor/`; cross-package import deemed fragile |

### Parity test strategy (TOKEN-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `brand_test.exs` (reads compiled bundle) to value-parity vs `tokens.json` oracle | Likely | `brand_test.exs:15-37`; stale-bundle landmine |

### Gate-tightening + ordering (RATCHET-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend two shell scripts in place + WIRE the dead `check-conformance.sh` into CI | Confident (escapes/dead-script); Likely (regex) | `check-conformance.sh` wired nowhere; TYPE-GATE omits lg/xl; motion script lacks `tracking-[` |

### Role remap + dark fixes + bundle (TOKEN-02/03/05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| base-200→surface-raised, base-300→border, dark error #D47368→#E29089, dark muted #5C6B7A→#B8CAD4; rebuild+commit | Confident | `app.css:24-25,69` vs `tokens.css:14,19,127-131`; current dark error off-palette |

**Needs research flagged:** standalone Tailwind v4 binary `@import` resolution above package/cwd root.

## User Redirect

User requested deep per-area research (pros/cons/tradeoffs, idiomatic Elixir/Phoenix, lessons
from comparable libs, DX, `prompts/` research) and a one-shot coherent recommendation set rather
than confirming the raw assumptions. Four parallel research subagents were spawned (one per area).

## Research Findings → Corrections

### Token-consumption mechanism — ASSUMPTION REVERSED
- **Original assumption:** vendor-copy (Likely).
- **Research result:** empirical spike proved the standalone Tailwind v4.1.12 binary resolves a
  direct cross-package `@import "../../../brandbook/tokens.css"` (above package root) and daisyUI
  forwards `var(--mg-*)` references verbatim. Adopted **Approach A (direct cross-package import)** —
  true single physical source of truth; brandbook is in-repo (not an external vendor artifact);
  drift caught by the existing `git diff --exit-code priv/static/` gate. (CONTEXT D-01.)

### Parity test — refined
- Reframed from "guard a vendored copy" to **compiled-bundle value-parity (resolving `var()`
  indirection) + structural no-raw-hex assertion**, oracle = `brandbook/tokens.json`, always-run in
  the required `support_contract_admin` lane. Byte-identity half dropped (no vendored copy under
  Approach A). (CONTEXT D-02.)

### Gates — confirmed + critical finding
- Confirmed `check-conformance.sh` is a **dead script** (wired nowhere); wiring it is the
  load-bearing part of RATCHET-03. Locked extend-in-place (not Credo port). Found the targeted
  escapes (`text-lg/xl` ×5, `tracking-[0.08em]` ×~45) **already exist in lib markup**, scheduled
  for fixing in Phases 98/99. (CONTEXT D-05..D-08.)

### Role remap + contrast — values verified
- Independently recomputed WCAG ratios: dark muted `#5C6B7A` on Ink = **3.18:1 (FAIL)** → `#B8CAD4`
  ≈10:1; dark error `#D47368` off-palette → `#E29089` ≈6–7:1. Border role intentionally <3:1
  (decorative, WCAG 1.4.11-exempt) — must not be "fixed". Prove via extending
  `accessibility_test.exs` (reuse its WCAG calc). (CONTEXT D-03, D-04.)

## Escalated Decision (genuinely strategic fork)

**Conflict discovered:** Phase 94 SC-3 ("gates fail on text-lg/xl + tracking-[ AND run in CI") vs
SC-4 ("no admin HEEx markup changes"), because those escapes already live in markup the roadmap
fixes in 98/99.

- **Options presented:** (A) advisory-now/hard-fail-at-99 [recommended]; (B) pull ~50 markup fixes
  into 94 (relax SC-4); (C) defer the gate-pattern additions to 98/99.
- **User chose:** **A — Advisory now, hard-fail at 99.** Wire the dead script + arm all token-layer
  gates fail-closed in 94; typography/tracking patterns run in CI but advisory until 98/99 flip
  them to hard-fail. (CONTEXT D-08.)

## Corrections Made

### Token-consumption mechanism
- **Original assumption:** vendor-copy `tokens.css` into `assets/`.
- **Correction (research-driven, not user):** direct cross-package `@import` (Approach A).
- **Reason:** empirical build spike proved feasibility; single source of truth; in-repo source;
  free drift detection.

## External Research
- Standalone Tailwind v4 binary import resolution: empirically resolves above-package-root imports;
  daisyUI passes `var()` through verbatim (research spike, repo left clean).
- Ecosystem precedent: Phoenix/`tailwind`/`esbuild` Hex wrappers, Petal, Salad UI treat compiled
  `priv/static` as the adopter contract with a single editable source — no second token copy.
- Dark-mode token best practice (Radix/Material/Primer/GOV.UK): elevation via rising lightness,
  borders never the accent, muted-text contrast floors; don't reuse light muted on dark.
- Design-system linting precedent (eslint-plugin-tailwindcss, stylelint, Tailwind blocklist):
  class-string matchers, not AST — supports the shell-gate (not Credo) decision.
</content>
