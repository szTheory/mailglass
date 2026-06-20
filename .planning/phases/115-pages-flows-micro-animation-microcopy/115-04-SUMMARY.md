---
phase: 115-pages-flows-micro-animation-microcopy
plan: 04
subsystem: mailglass_admin / e2e flow + structural proof
tags: [flows, e2e, playwright, responsive-320, motion, FLOW-01, FLOW-02, FLOW-03]
requires:
  - "115-01 (origin-aware overlay CSS + theme-switch suppression + state-layer utility)"
  - "115-02 (overscroll-contain on replay modals, centered-modal origin)"
  - "115-03 (VOICE-GATE + MOTION-GATE conformance)"
provides:
  - "e2e/flows.spec.js — 5-path x 3-surface walk at 320/system + overlay subset + light/dark/system contrast spot-check"
  - "structural.spec.js motion contract block (origin / theme-swap / state-layer / reduced-motion) + 390->320 floor lowering on the two touched master-detail responsive tests"
  - "320px overflow patches on the three live surfaces (header flex-wrap cluster, master-detail min-w-0, routing-trace mono break-all, preview H1/button-row wrap)"
affects:
  - "mailglass_admin operator/inbound/preview surfaces (320 overflow patches only — no IA re-architecture)"
tech-stack:
  added: []
  patterns:
    - "Deterministic Playwright flow-proof by seeded URL, zero new fixtures, no pixel-diff"
    - "min-w-0 grid-child / break-all mono / flex-wrap cluster as the 320 mobile-first overflow patch vocabulary (D-04)"
key-files:
  created:
    - "mailglass_admin/e2e/flows.spec.js"
  modified:
    - "mailglass_admin/e2e/structural.spec.js"
    - "mailglass_admin/lib/mailglass_admin/operator/shell.ex"
    - "mailglass_admin/lib/mailglass_admin/operator_live.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound_live.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex"
    - "mailglass_admin/lib/mailglass_admin/preview_live.ex"
    - "mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex"
    - "mailglass_admin/priv/static/app.css (rebuilt bundle — no source CSS change beyond Tailwind picking up new utility classes)"
key-decisions:
  - "Asserted the single dominant CTA per surface by stable testid + dominance class, NOT by the planner's prose label (live copy is 'Replay webhook' / 'Replay inbound' / 'Render preview', not 'Replay delivery' / 'Replay inbound message' / 'Render scenario')."
  - "The header-anchored-overlay top-edge transform-origin assertion is GUARDED and correctly SKIPS — Plan 02's real outcome is centered-modal-only; no overlay was fabricated to satisfy it (D-07, consistent with 115-02 Task 3)."
  - "The 320 floor was lowered ONLY in the two touched master-detail responsive tests; the 320 cell is NOT promoted into the ratchet baseline (D-04, Phase 116 owns that)."
  - "state-layer survival is proven on the focus-ring chrome (--duration-instant 90ms <= 0.1s); .mg-state-layer is defined in CSS but not applied to any rendered element yet, so the surviving state layer asserted is the focus-ring."
requirements-completed: [FLOW-01, FLOW-02, FLOW-03]
duration: ~70 min
completed: 2026-06-20
---

# Phase 115 Plan 04: Pages/Flows + Micro-Animation Structural Proof Summary

ONE new `e2e/flows.spec.js` walks the 5-path taxonomy (happy/error/boundary/edge/advanced) across the three live surfaces at the 320px floor with the system theme, plus an overlay interaction subset (panel-above-scrim, Escape, no scroll-chaining) and a light/dark/system AA-contrast spot-check — all deterministic, zero new fixtures, no pixel-diff. `structural.spec.js` gains a FLOW-03 motion-contract block (origin-aware overlays, theme-switch-never-animates, state-layer survival, reduced-motion snaps overlays to instant) and lowers the 390→320 mobile-cell floor in the two master-detail responsive tests. Proving the walk surfaced four genuine 320px overflow defects in live chrome, which were patched mobile-first per D-04.

## What was built

### Task 1 — `e2e/flows.spec.js` (new, 569 lines)
- **Full walk:** 15 tests = 3 surfaces × 5 paths at {320×900} / {system}. Each asserts the correct landmark/testid visible, exactly one `h1`, and `scrollWidth − clientWidth ≤ 1` on root AND master-detail; the happy path additionally asserts the single dominant CTA (by testid + dominance class) survives 320.
- **Overlay subset:** 2 tests = operator + inbound replay modal at 320 → `assertPanelAboveScrim` (elementFromPoint hit-test), Escape closes, background `scrollY` unchanged (scroll-chaining guard from the Plan 02 `mg-overscroll-contain`).
- **Theme-parity spot-check:** 6 tests = 1 happy + 1 overlay path × {light, dark, system} × 320 → `assertTextContrastAA` passes; `data-theme` read confirms the theme axis.
- Per-file login/open helpers duplicated from structural.spec.js (no shared module). Drives flows only by already-seeded URL params (`delivery_id=does-not-exist`, `status=queued`, `tenant_id=browser-empty`, scenario/error preview routes) — zero new fixtures.

### Task 2 — `structural.spec.js` additions
- **Motion contract block (FLOW-03 / D-09):** centered replay-modal `transformOrigin` resolves to geometric centre (unconditional); header-anchored top-edge origin assertion GUARDED (skips when no such overlay exists, never fabricated); theme-picker label `transitionProperty` excludes color/background-color; `getAnimations()` empty (no running) immediately after a `data-theme` swap (entrance animations awaited first so only swap-triggered motion is measured); focus-ring state-layer `transitionDuration ≤ 0.1s`; reduced-motion (`emulateMedia({ reducedMotion: 'reduce' })`) → opened overlay has no running animation and ~0 durations (FLOW-03 success criterion 3 / MOTION-LD-09), emulation reset afterward.
- **390→320 floor lowering:** the operator and inbound "master-detail grid follows …/768/1440 responsive contract" tests now exercise the mobile cell at 320 with added `scrollWidth − clientWidth ≤ 1` overflow patches; the 320 cell is NOT promoted to the ratchet baseline (D-04).

## Verification

- **Command (per project e2e setup, `playwright.config.cjs` auto-starts the seeded `OperatorBrowserServer` on :4101):**
  - `npx playwright test --config=playwright.config.cjs e2e/flows.spec.js --workers=1` → **23 passed**.
  - `npx playwright test --config=playwright.config.cjs e2e/structural.spec.js --workers=1 -g "motion contract — Phase 115|master-detail grid follows 320"` → **7 passed, 1 skipped** (the guarded header-anchored origin assertion correctly skips).
  - Full `e2e/structural.spec.js` → **69 passed, 1 skipped, 4 failed** — all 4 failures are **pre-existing flakes confirmed on the clean baseline** (stash-verified): `:673` and `:693` touch-target tests (`operator-delivery-row .first()` resolves the hidden table row at the mobile cell — known pattern), `:1163` preview-toggle URL assertion, and `:976` inbound contrast (`assertNonTextContrastAA` mis-handles an `oklab(0 0 0 / 0)` focus background → 1.2073 ratio, reproduces identically on baseline). None are caused by this plan; the new motion + lowered-floor tests all pass.
- `grep -c toHaveScreenshot e2e/flows.spec.js` → **0**; `grep -c toHaveScreenshot e2e/structural.spec.js` → **0** (no pixel-diff, D-03).
- `grep -c transformOrigin / getAnimations / reducedMotion e2e/structural.spec.js` → 4 / 9 / 7 (all present).
- `mix.lock` unchanged (none committed); only `e2e/flows.spec.js` added as a new file under mailglass_admin.

## Deviations from Plan

### Auto-fixed Issues (Rule 1 — bug / Rule 3 — blocking the plan's own assertions)

Running the flows walk (which the plan mandates) surfaced four genuine 320px overflow defects in live chrome. The plan's own FLOW-02 invariant ("no horizontal overflow on root AND master-detail at 320") cannot pass without patching them, and D-04/D-13 explicitly scope "320 overflow patches" on the three surfaces + shell to this phase. All patches are mobile-first class additions (no new layout system, no token changes):

1. **[Rule 3] Header flex-wrap cluster overflow (90px, root).** `operator/shell.ex` header cluster (tenant-chip + 247px theme-picker fieldset) did not wrap at 320 → added `flex-wrap justify-end` to the cluster. This is the D-04 "header flex-wrap cluster" patch.
2. **[Rule 3] Master-detail grid-child overflow (operator 9px, inbound 81px).** Single-column grid items did not shrink → added `min-w-0` to the operator/inbound list-card asides, the inbound list-column wrapping div, and the operator/inbound detail-columns.
3. **[Rule 1] Inbound routing-trace + detail-header long mono content overflow (up to 116px).** Long mailbox patterns, `verdict.actual`/expected matcher chips, the first-failing reason copy, the recipient `h2`, and the record-id mono cell did not break → added `min-w-0 break-all` (mono chips/ids) / `break-words` (headings, reason) and `min-w-0` to the trace grid cells/clause `li`. (`routing_trace.ex`, `inbound/detail_header.ex`)
4. **[Rule 1] Preview scenario H1 + assigns button-row overflow (33px then 7px).** The `inspect(@current_mailable) · scenario` H1 and the two-button assigns row did not wrap → added `min-w-0 break-words` to the H1 and `flex-wrap` to the button row. (`preview_live.ex`, `preview/assigns_form.ex`)

Assets were rebuilt (`mix mailglass_admin.assets.build`) so the committed `priv/static/app.css` bundle picks up the new utility classes (CI runs `git diff --exit-code` on the bundle).

### Test-shape adjustments (within Claude's discretion per CONTEXT)

- Dominant-CTA assertions target stable testids (`operator-replay-open` / `inbound-replay-open` / the `btn-primary` in `preview-assigns-form`) and the dominance class, because the live CTA copy ("Replay webhook" / "Replay inbound" / "Render preview") differs from the planner's approximate prose labels. Documented inline in the spec.
- Inbound happy/edge tests use `detail-back` to return to the list between selections (the list-card is `max-md:hidden` once a record is selected at <768px) and assert the list-card overflow before selecting (it is hidden after).

**Total deviations:** 4 auto-fixed 320px overflow patches (2× Rule 3 grid/flex, 2× Rule 1 long-content break) + discretionary test-shape choices. **Impact:** the three live surfaces now hold the FLOW-02 320 floor with zero horizontal overflow on root + master-detail across all 5 paths × 3 surfaces; no IA re-architecture, no token changes, no new fixtures, no pixel-diff.

## Deferred / Out of scope (unchanged from plan)

- Live `:permission_denied` / `:stale` triggers (Phase 116 / product).
- The 4 pre-existing structural flakes (`:673`, `:693`, `:976`, `:1163`) — confirmed failing on clean baseline; not introduced here. `:976`'s root cause is an `oklab`-transparent blind spot in the shared `assertNonTextContrastAA` helper; left untouched to avoid changing a shared assertion contract outside this plan's scope.
- 320-cell ratchet baseline promotion / `current → prior` re-score / gallery matrix / axe baseline (Phase 116).
