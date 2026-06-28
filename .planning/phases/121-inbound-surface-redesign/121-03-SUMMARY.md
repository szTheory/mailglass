---
phase: 121-inbound-surface-redesign
plan: 03
subsystem: mailglass_admin / replay confirmation modals
tags: [a11y, apg, focus-trap, double-submit, replay, modal, d-14]
requires:
  - "121-01 (inbound surface scaffolding) — shipped"
  - "Existing replay modal APG affordances (role=dialog, aria-modal, Escape, initial focus, focus-restore)"
provides:
  - "Tab/Shift+Tab focus-trap on both replay confirmation modals (inbound + operator)"
  - "Double-submit pending-lock (phx-disable-with=Replaying…) on both Confirm buttons"
  - "Stable boundary ids (#inbound-replay-close/#inbound-replay-confirm, #operator-replay-close/#operator-replay-confirm) usable as JS.focus targets"
affects:
  - "Plan 121-04 e2e (asserts Tab-wraps-last→first + Confirm-disabled-after-first-click on both surfaces)"
tech-stack:
  added: []
  patterns:
    - "Focus-sentinel spans (tabindex=0 + aria-hidden + phx-focus={JS.focus(to:)}) as a pure-LiveView.JS focus-trap — no client hook, no npm dep"
    - "phx-disable-with for render→click double-submit prevention on consequential ledger-appending actions"
key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
decisions:
  - "Focus-trap mechanism: focus-sentinel spans (not a scoped Tab keydown handler) — render-state-independent, pure LiveView.JS, byte-identical across both modals; end sentinel wraps unconditionally to Close (first), start sentinel wraps to Confirm id (last)."
  - "Operator's conditional Confirm (absent in unavailable/loading states): start sentinel targets #operator-replay-confirm; when absent JS.focus is a safe no-op (focus stays on Close), focus still never escapes the dialog."
metrics:
  duration: ~7 min
  completed: 2026-06-28
  tasks: 2
  files: 2
status: complete
---

# Phase 121 Plan 03: Replay-Modal APG Conformance (Focus-Trap + Double-Submit Lock) Summary

Closed the two genuine APG gaps on the replay confirmation modal — a Tab/Shift+Tab focus-trap and a double-submit pending-lock — applied identically across both lockstep sibling modals (`inbound/replay_modal.ex` + `operator/replay_modal.ex`) using pure Phoenix/LiveView.JS, no new npm dep, no Tailwind class, committed `app.css` byte-unchanged.

## What Was Built

**Task 1 — Tab/Shift+Tab focus-trap (commit `0317f9a9`).** Added identical focus-sentinel spans (`<span tabindex="0" aria-hidden="true" phx-focus={JS.focus(to: ...)}>`) at the dialog start and end of both modals. The start sentinel catches Shift+Tab off the first control and wraps focus to the last control (Confirm); the end sentinel catches Tab off the last control and wraps to the first control (Close). Stable boundary ids were added to the Close (`#inbound-replay-close` / `#operator-replay-close`) and Confirm (`#inbound-replay-confirm` / `#operator-replay-confirm`) buttons as the wrap targets. This is the one previously-unmet APG line item — `JS.focus_first` (in the LiveView span, untouched) sets initial focus but never contained Tab. All prior APG affordances (role=dialog, aria-modal, aria-labelledby, Escape via phx-key, initial focus, focus-restore, scrim, overscroll, reduced-motion) are preserved un-regressed.

**Task 2 — double-submit pending-lock (commit `c790704f`).** Added `phx-disable-with="Replaying…"` to both Confirm buttons so a second click after the first cannot re-fire `confirm_replay` — the render→click double-fire the code already worried about, which would append a duplicate replay run to the append-only ledger. The pending label "Replaying…" matches the UI-SPEC Copywriting Contract (NEW — D-14) exactly; the idle label "Confirm replay" and the `btn btn-error` class are unchanged (consequential-color question deferred to Phase 123+).

## Implementation Notes

- **Focus-trap choice (Claude's discretion per plan):** focus-sentinel spans over a scoped Tab keydown handler. Sentinels are render-state-independent and require no boundary-computation logic; the end sentinel wraps unconditionally to Close, so forward-Tab containment is always correct regardless of which controls render.
- **Operator's conditional Confirm:** in the `:unavailable` / loading branches the Confirm button is not rendered. The start sentinel still targets `#operator-replay-confirm`; when that element is absent `JS.focus(to:)` is a safe no-op (focus stays on Close) — focus never escapes the dialog. This keeps the mechanism byte-identical across both modals without special-casing.
- **Out of scope (untouched, per D-13):** the replay gate order (TENANT → CAPABILITY(:replay_inbound) → REPLAY), the `:no_match`-can-never-replay rule, and struct-matched error copy all live in `inbound_live.ex`'s confirm flow, not the modal. The initial-focus + focus-restore spans in `inbound_live.ex` / `operator_live.ex` were left untouched (they were already correct).

## Verification

- `cd mailglass_admin && mix compile --warnings-as-errors`: touched files (`inbound/replay_modal.ex`, `operator/replay_modal.ex`) compile with zero warnings. The only `--warnings-as-errors` failure in the tree is the pre-existing `operator_live.ex:505` `selected_delivery={nil}` warning inherited from Phase 120 — out of scope (that file was not modified). Plain `mix compile` succeeds.
- `grep -c 'Replaying…'` returns 1 for each modal; idle "Confirm replay" and `btn btn-error` preserved in both.
- `grep -c 'phx-focus={JS.focus'` returns 2 for each modal (start + end sentinel) — identical mechanism across both files.
- All APG attributes (`role="dialog"`, `aria-modal="true"`, `aria-labelledby`, `phx-key="Escape"`) present (1 each) in both modals — none removed.
- `git diff --stat priv/static/app.css`: empty (no new Tailwind utility, no assets.build — D-18).
- No `package.json` / `assets/vendor` change — focus-trap is pure Phoenix/LiveView.JS.

## Threat Mitigations

- **T-121-04 (Tampering, double-submit, medium):** mitigated — `phx-disable-with="Replaying…"` disables Confirm after the first click on both surfaces. Asserting guard: Plan 121-04 e2e "Confirm disabled after first click" + the Task 2 grep.
- **T-121-05 (Information Disclosure, focus-trap, low):** mitigated — Tab/Shift+Tab trap keeps keyboard focus inside the dialog; background controls are unreachable while the confirmation is open. Asserting guard: Plan 121-04 e2e "Tab wraps last→first".
- **T-121-06 (Tampering, replay gate, high):** accepted/untouched — the authorization flow lives in `inbound_live.ex` and is out of this plan's file scope (D-13).

## Deviations from Plan

None — plan executed exactly as written. Both tasks committed atomically; the focus-trap mechanism and pending-lock are present and identical across both modals.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` (focus sentinels + phx-disable-with)
- FOUND: `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` (focus sentinels + phx-disable-with)
- FOUND commit `0317f9a9` (Task 1 focus-trap)
- FOUND commit `c790704f` (Task 2 pending-lock)
