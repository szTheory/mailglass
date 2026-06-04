---
phase: 77
slug: motion-and-microinteraction-polish
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 77 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `77-RESEARCH.md` § Validation Architecture. Application-not-authorship phase —
> the headline regression (the `motion-reveal` re-fire bug, MOTION-01) is **invisible to
> ExUnit substring tests** (the heroicons-inline lesson) and is verifiable ONLY at the
> Playwright DOM id-presence layer. MOTION-02 (layout-thrashing) is guarded by a shell grep gate.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest (admin) · Playwright (operator browser) · shell grep gate · `git diff --exit-code` bundle gate |
| **Config file** | `mailglass_admin/test/test_helper.exs`, `mailglass_admin/playwright.config.cjs` (existing) |
| **Quick run command** | `cd mailglass_admin && npm run test:operator-browser` |
| **Full suite command** | `cd mailglass_admin && bash scripts/check_motion_conformance.sh && mix verify.preview` |
| **Estimated runtime** | ~quick: ~20–40s (Playwright) · full: ~60–120s (compile + ExUnit + bundle diff) |

---

## Sampling Rate

- **After every task commit:** `cd mailglass_admin && npm run test:operator-browser` (or `bash scripts/check_motion_conformance.sh` for the grep-gate task)
- **After every plan wave:** `cd mailglass_admin && bash scripts/check_motion_conformance.sh && mix verify.preview`
- **Before `/gsd:verify-work`:** Playwright green (id-presence + reduced-motion) **AND** `check_motion_conformance.sh` returns 0 violations **AND** `mix verify.preview` green (ExUnit + `git diff --exit-code priv/static/` clean)
- **Max feedback latency:** ~40 seconds (Playwright quick) / ~120 seconds (full)

---

## Per-Task Verification Map

> Task IDs finalize when PLAN.md lands. Mapping below is by requirement + verification layer.

| Requirement | Verifies (success criterion) | Verification Layer | Automated Command | Status |
|-------------|------------------------------|--------------------|-------------------|--------|
| MOTION-01 | Delivery detail pane carries `id="delivery-detail-<uuid>"`; id changes on new selection, old element gone (re-fire correctness) | Playwright DOM id-presence assertion (NOT ExUnit) | `npm run test:operator-browser` | ⬜ pending |
| MOTION-01 | Inbound detail twin carries `id="inbound-detail-<id>"` (`@detail.record.id`, per RESEARCH correction) | Playwright DOM id-presence — OR stubbed/skipped w/ comment if inbound not seeded in browser scenario | `npm run test:operator-browser` | ⬜ pending |
| MOTION-02 | `prefers-reduced-motion: reduce` suppresses motion; element still visible (not stuck at opacity:0) | Playwright `page.emulateMedia({reducedMotion:"reduce"})` | `npm run test:operator-browser` | ⬜ pending |
| MOTION-02 | Zero banned layout-thrashing tokens in `lib/` + `app.css`; zero `duration-300+`; zero `ease-in-out`/`ease-linear` Tailwind classes in `lib/` | Shell grep gate (Pass A both dirs; Pass B `lib/` only — `app.css:120` defines `--ease-in-out` token) | `bash scripts/check_motion_conformance.sh` | ⬜ pending |
| MOTION-02 | Asset bundle rebuilt & committed in same PR as HEEx/CSS change (may be no-op — verify, don't assume) | `git diff --exit-code priv/static/` via `verify.preview` alias | `cd mailglass_admin && mix verify.preview` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/check_motion_conformance.sh` — new conformance grep gate (D-06); CI-promotable, NOT inside `ui-audit.sh`; Pass A (lib/ + app.css), Pass B (lib/ only)
- [ ] `mailglass_admin/e2e/operator.spec.js` — extend with id-presence + reduced-motion tests (D-07)
- [ ] No framework install needed — ExUnit, Playwright, and the bundle-build toolchain all exist.

*Existing infrastructure (Playwright config, operator browser server, vendored `tailwind-macos-arm64`) covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Keyframes animate transform/opacity only (4 `@keyframes` in `app.css`) | MOTION-02 (sc4) | Source-read fact; stable design tokens, no CSS authored this phase (D-03/D-04) | Confirm `mg-reveal`/`mg-timeline-in`/`mg-fade-in`/`mg-overlay` use only `opacity`+`transform`; no-new-CSS rule guards regression |
| GAP-21 a11y attributes present | (out of scope — D-05) | Already satisfied by Phases 75/76 | One-line grep confirm only: `aria-current` (shell.ex), `aria-selected` (lists), `role="dialog"`+`aria-modal` (replay_modal.ex) — do not rebuild |

*All in-scope phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (conformance script + e2e extensions)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
