---
phase: 102
slug: motion-micro-interaction-pass
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `102-RESEARCH.md` § Validation Architecture. MOTION-LD-01..14 (Phase 96) are binding.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (`@playwright/test`) for structural/browser facts |
| **Config file** | `mailglass_admin/mix.exs` (aliases), `mailglass_admin/e2e/` (Playwright) |
| **Quick run command** | `cd mailglass_admin && scripts/check-conformance.sh && scripts/check-conformance-advisory.sh` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview` (compile + scoped test + assets.build + `git diff --exit-code priv/static/`) |
| **Estimated runtime** | ~30–90s conformance; ~2–4 min verify.preview |

---

## Sampling Rate

- **After every task commit:** `cd mailglass_admin && scripts/check-conformance.sh && scripts/check-conformance-advisory.sh` (fast, no boot)
- **After every plan wave:** `cd mailglass_admin && npx playwright test e2e/structural.spec.js` (FACT 4 reduced-motion + new duration/asymmetry assertions)
- **Before `/gsd:verify-work`:** `cd mailglass_admin && mix verify.preview` green. Use scoped Playwright/conformance commands — NOT bare `mix test` (project memory: ~57 unrelated Oban failures + `voice_test` "Oops" dep-JS false positive in worktrees).
- **Max feedback latency:** ~90 seconds (conformance grep)

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | File Exists |
|-----|----------|-----------|-------------------|-------------|
| MOTION-01 | Token-named easing / transform-opacity only / no layout-property transitions | conformance grep (NEW MOTION-GATE) | `cd mailglass_admin && scripts/check-conformance.sh` | ⚠️ gate exists; MOTION-GATE rule ❌ W0 |
| MOTION-01 | Enter/exit asymmetry (exit class / `phx-remove` on detail/overlay; computed exit ≈150ms) | structural Playwright | `cd mailglass_admin && npx playwright test e2e/structural.spec.js` | ⚠️ spec exists; asymmetry assertion ❌ W0 |
| MOTION-01 | First-mount stagger (cap 8) intact | grep verify | `grep '.motion-timeline > \*:nth-child' mailglass_admin/assets/css/app.css` | ✅ `app.css:281-288` |
| MOTION-01 | Focus transition token applied (`--duration-instant`) | structural Playwright FACT 5 + grep | `npx playwright test e2e/structural.spec.js -g "focus"` | ✅ FACT 5 `structural.spec.js:779-824` |
| MOTION-01 | Loading skeleton = connection-state placeholder (opacity-only, no layout anim) | grep (`.mg-skeleton` opacity-only) + MOTION-GATE | `scripts/check-conformance.sh` (post-MOTION-GATE) | ❌ W0 |
| MOTION-01 | View Transitions = CSS-only `@view-transition`, reduced-motion gated | grep + single hard-load visual | `grep -A2 'no-preference' mailglass_admin/assets/css/app.css` | ❌ W0 |
| MOTION-02 | reduced-motion collapses ALL motion (computed duration ≈ 0) | structural Playwright (NEW, `emulateMedia`) | `npx playwright test e2e/structural.spec.js -g "reduced-motion"` | ⚠️ FACT 4 visibility-only; duration assertion ❌ W0 |
| MOTION-02 | conformance gate stays green | conformance grep (all gates) | `cd mailglass_admin && scripts/check-conformance.sh && scripts/check-conformance-advisory.sh` | ✅ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/check-conformance.sh` — add **MOTION-GATE**: ban `transition-(height|width|padding|margin|top|left|right|bottom|max-height)` and arbitrary `transition-[...]` of layout props; ban stray `ease-in\b` (except documented `--ease-symmetric`). Validate by RUNNING it, not by grep proof (project memory: validate-credo-by-running-it).
- [ ] `e2e/structural.spec.js` — extend FACT 4: under `emulateMedia({reducedMotion:"reduce"})`, assert computed `animationDuration`/`transitionDuration` ≤ ~0.05s on a `.motion-reveal` / `.motion-timeline > *` element (app.css uses `0.01ms !important`).
- [ ] `e2e/structural.spec.js` — add enter/exit asymmetry assertion (exit class or `phx-remove` attr present; or computed exit transition-duration = 150ms).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| View Transitions visual on a hard document navigation | MOTION-01 | `@view-transition { navigation: auto }` fires only on full-document loads; not reachable by LiveView WS patch, so no DOM assertion proves the visual cross-fade | Hard-reload `/ops/mail` → navigate by typing a sibling admin URL (full nav, not live_patch) with VT-capable browser; confirm cross-document fade and that `prefers-reduced-motion: reduce` disables it |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (MOTION-GATE, reduced-motion duration assertion, asymmetry assertion)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
