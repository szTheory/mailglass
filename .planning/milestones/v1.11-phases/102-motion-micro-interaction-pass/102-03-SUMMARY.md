---
phase: 102-motion-micro-interaction-pass
plan: 03
subsystem: ui
tags: [motion, phoenix-live-view, liveview-js, phx-remove, heex, playwright, microcopy]

# Dependency graph
requires:
  - phase: 102-01
    provides: MOTION-GATE in check-conformance.sh; scaffolded (fixme) enter/exit-asymmetry structural assertion; reduced-motion computed-duration assertion
  - phase: 102-02
    provides: --ease-symmetric / --duration-instant tokens, .mg-skeleton, @view-transition PE; rebuilt bundle baseline
  - phase: 96-research-dossier
    provides: MOTION-LD-04 (overlay exit), MOTION-LD-06 (focus ≤100ms), MOTION-LD-10 (transform/opacity only), MOTION-LD-12 (preview CTA reveal), MOTION-LD-13 (exit=entrance×0.67=150ms)
provides:
  - phx-remove={JS.hide(time:150, opacity+translate-y exit)} on operator #delivery-detail-* and inbound #inbound-detail-* panes (MOTION-LD-13)
  - phx-remove scale(1→0.98)+fade exit on operator + inbound replay-modal .motion-overlay panels and backdrop fade (MOTION-LD-04)
  - focus-visible:duration-(--duration-instant) on gallery nav_link/nav_pill (MOTION-LD-06)
  - .motion-reveal entrance on the preview empty-state CTA (MOTION-LD-12); GAP-02/03 left intact (verify-only)
  - un-skipped FACT 7 enter/exit-asymmetry structural assertion (Playwright 41/41 green)
  - rebuilt priv/static/app.css bundle committed bit-clean
affects:
  - 103-verification-closeout (all conformance + structural + bundle-clean + verify.preview gates green; MOTION-01/02 mechanics complete)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Enter/exit asymmetry: entrances stay as .motion-reveal CSS keyframes; exits are JS-driven via phx-remove={JS.hide(time:N, transition:{...})} — NOT a reversed keyframe (Pitfall 5). time: literal int MUST equal CSS duration (Pitfall 3 desync)."
    - "Exit transition utilities are standard always-emitted Tailwind literals (opacity-0, translate-y-1, scale-[0.98], duration-150, ease-out) so the scanner never tree-shakes them (Pitfall 2)."
    - "Glassmorphism guard must match the property form (~r/backdrop-filter\\s*:/), not the bare substring: Tailwind v4 emits `backdrop-filter` inside @layer properties transition-property registration lists, which is not glassmorphism."

key-files:
  created:
    - .planning/phases/102-motion-micro-interaction-pass/102-03-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/brand_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

key-decisions:
  - "Exit tuples use opacity-100→opacity-0 + translate-y-0→translate-y-1 at 150ms ease-out (MOTION-LD-13); replay overlays add scale-100→scale-[0.98] (MOTION-LD-04). No layout-property transitions — MOTION-GATE enforces."
  - "Focus rings resolve through --duration-instant (90ms ≤100ms ceiling) on gallery nav_link/nav_pill; hover background stays on --duration-fast (MOTION-LD-06)."
  - "brand_test.exs glassmorphism guard refined from substring `css =~ \"backdrop-filter\"` to regex `~r/backdrop-filter\\s*:/`. The rebuilt Tailwind v4.1.12 bundle emits `backdrop-filter` ONLY inside the @layer properties transition-property registration list (`backdrop-filter,backdrop-filter,display,...`), never as a real `backdrop-filter:` declaration. The substring match was a false positive; the regex still bans real glassmorphism use. (Deviation — undeclared file, verified sound.)"
  - "inbound_live_test.exs:681,863 copy assertions aligned to locked COPY-LD-13 (\"this InboundMessage's timeline\"). This closed a latent Phase 101 verification gap: 101 applied COPY-LD-13 to the source (inbound_live.ex:219, commit 3f4c3403) and verified the source string, but never updated the two tests, which still expected the old phase-48 copy. Surfaced by Phase 102's closing gate; reproduced at pre-102 source, NOT a motion regression. (Deviation — undeclared file, cross-phase fix.)"

patterns-established:
  - "Phase 102's mix verify.preview closing gate is the cross-phase regression net that catches prior-phase source/test drift (here: a Phase 101 microcopy gap) before milestone closeout."

# Execution notes
execution-notes:
  - "Plan executed across two executor agents + orchestrator finish. Task 1 committed cleanly by the first executor (21e08367). The first executor then died with a transient API 500 mid-Task-2, and a continuation executor also hit a 500 after 2 tool uses. The orchestrator verified the partial Task-2 working-tree edits were sound (un-skipped asymmetry test, motion-reveal CTA, deterministic rebuilt bundle, the brand_test.exs false-positive fix) and completed Task 2 inline: ran all gates, fixed the surfaced Phase 101 test-copy gap, and committed."
  - "Known noise per project memory NOT touched: voice_test 'Oops' dep-JS false positive and the ~57 Oban failures live outside the verify.preview scoped suite, which is fully green (235 tests, 0 failures)."
---

## What shipped

Closing motion plan of Phase 102. The HEEx layer now consumes the tokens landed in
Plan 02 to deliver the remaining MOTION-01 mechanics and prove the MOTION-02 posture
end-to-end:

- **Enter/exit asymmetry (MOTION-LD-13).** Operator `#delivery-detail-*` and inbound
  `#inbound-detail-*` panes fire a real 150ms ease-out exit (`opacity-100 → opacity-0`,
  `translate-y-0 → translate-y-1`) via `phx-remove={JS.hide(time: 150, ...)}` before
  LiveView removes them. Entrances remain `.motion-reveal` keyframes — exits are
  JS-driven transitions, never a reversed keyframe.
- **Replay-modal overlay exit (MOTION-LD-04).** Both operator and inbound replay-modal
  `.motion-overlay` panels fire a 150ms `scale(1→0.98)` + fade exit; backdrops fade out
  at 150ms.
- **Focus transition (MOTION-LD-06).** Gallery `nav_link`/`nav_pill` focus rings resolve
  through `--duration-instant` (90ms); hover background stays on `--duration-fast`.
- **Preview CTA reveal (MOTION-LD-12).** The preview empty-state CTA carries
  `.motion-reveal`; it remains an unconditionally-focusable `.link` (GAP-02, fixed in
  Phase 100 — verify-only). GAP-03 and `RATCHET-GAP-REGISTER.md` untouched.
- **Verify-only.** First-mount stagger (cap 8, `app.css` nth-child(8)) and the
  reduced-motion `@media` collapse confirmed intact via grep — not rebuilt.

## Gates

- `scripts/check-conformance.sh` + `scripts/check-conformance-advisory.sh` — exit 0
  (MOTION-GATE clean: no layout-property transition, no stray `ease-in`).
- `npx playwright test e2e/structural.spec.js` — **41/41 pass**, including the now
  un-skipped FACT 7 enter/exit-asymmetry assertion and the reduced-motion
  computed-duration assertion.
- `mix verify.preview` — **exit 0** (compile + scoped test 235/0 + assets.build +
  `git diff --exit-code priv/static/` clean).

## Deviations

1. **`brand_test.exs` glassmorphism guard refined** (undeclared file). Tailwind v4's
   rebuild surfaced `backdrop-filter` inside the `@layer properties` registration list,
   a false positive for the substring ban. Tightened to `~r/backdrop-filter\s*:/` —
   still bans real glassmorphism. Verified: the bundle contains zero real
   `backdrop-filter:` declarations.
2. **`inbound_live_test.exs` copy assertions aligned to COPY-LD-13** (undeclared file).
   Closed a latent Phase 101 verification gap (source updated + verified, tests left
   stale). Pre-existing — reproduced at pre-102 source — not a motion regression.

## Self-Check: PASSED
