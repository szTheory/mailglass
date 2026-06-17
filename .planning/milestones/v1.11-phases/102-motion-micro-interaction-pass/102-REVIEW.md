---
phase: 102-motion-micro-interaction-pass
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - mailglass_admin/scripts/check-conformance.sh
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/test/mailglass_admin/brand_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 102: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Phase 102 is a tightly-scoped motion/micro-interaction pass. I verified the central correctness claims and they hold:

- **Exit-transition time↔duration sync is exact.** All six `JS.hide(time: 150, ...)` exits pair with a `duration-150` transition class (150ms == 150ms). No mismatch anywhere (grep-confirmed across `operator_live.ex`, `inbound_live.ex`, both `replay_modal.ex` files).
- **Exits animate transform/opacity only.** The detail-pane exit (`opacity-0 translate-y-1`) and modal exits (`opacity-0`, `opacity-0 scale-[0.98]`) touch no layout properties — MOTION-LD-10 honored.
- **Scope discipline held.** The 102-03 commit diff (`21e08367`) is purely presentational: `phx-remove` attributes + a `focus-visible:duration-(--duration-instant)` token. No event-handler, route, or data-flow changes leaked in. PII masking (`mask_recipient/1`) and tenant scoping are untouched.
- **Conformance gate passes clean** against the current `lib/` (`bash scripts/check-conformance.sh` → exit 0).
- **Brand glassmorphism guard is precise.** The refined `~r/backdrop-filter\s*:/` correctly skips Tailwind's `@layer properties` comma-list (the only `backdrop-filter` occurrence in the compiled bundle) and would still catch real `backdrop-filter:` usage.
- **`inbound_live_test.exs` masking assertions match `mask_recipient/1` output** (`alice@example.com` → `a****@e******.com`, verified against `components.ex` masking primitive).

The defects below are all in the supporting tooling (conformance gate logic, stale test comments/line-refs) and a pre-existing a11y asymmetry — none compromise the shipped motion behavior, but the gate weakness is a real regression-detection hole.

## Warnings

### WR-01: MOTION-GATE ease-in check reintroduces the line-level false-negative the script claims to have fixed

**File:** `mailglass_admin/scripts/check-conformance.sh:111-115`
**Issue:** The ease-in gate pipes through two `grep -v` line-level filters:
```sh
grep -rEn '\bease-in\b' "$LIB" --include="*.ex" | grep -v -- '--ease-symmetric' | grep -v 'ease-in-out'
```
Both filters drop the entire LINE, not just the allowed token. The TYPE-GATE comment (lines 38-44) explicitly documents fixing exactly this class of bug (WR-01: "filters at the LINE level — so a genuine violation sharing a line with the … class … was silently dropped"), yet MOTION-GATE Part 2 reintroduces it. I reproduced two concrete false negatives:
- `class="ease-in-out tab ease-in slide"` → **MISSED**
- `animation: x var(--ease-symmetric) both; ease-in slide` → **MISSED**

A stray `ease-in` on any line that also contains `ease-in-out` or `--ease-symmetric` slips past the gate undetected. Low exploitability today (no such line exists in `lib/`), but the gate is materially weaker than its own documentation asserts.
**Fix:** Use anchored negative matching consistent with the TYPE-GATE approach — exclude the allowed forms at the token level rather than the line level. For example, strip the allowed tokens before testing, or use a single pattern that matches `ease-in` only when NOT followed by `-out` and NOT preceded by `--`:
```sh
# ease-in as a whole token, not ease-in-out, not --ease-symmetric / var(--ease-...)
if grep -rEn '(^|[^a-z-])ease-in([^a-z-]|$)' "$LIB" --include="*.ex" 2>/dev/null \
   | grep -vE 'ease-in-out|--ease-' | grep -q .; then
  grep -rEn '(^|[^a-z-])ease-in([^a-z-]|$)' "$LIB" --include="*.ex" 2>/dev/null | grep -vE 'ease-in-out|--ease-'
  echo "FAIL: MOTION-GATE — stray ease-in found ..." >&2
  errors=$((errors + 1))
fi
```
Note: `ease-in-out` and `--ease-symmetric` should still be excluded, but at the token boundary so a same-line genuine violation is not masked.

### WR-02: Stale "fixme" comment contradicts a now-live structural test (un-skip claim never applied)

**File:** `mailglass_admin/e2e/structural.spec.js:938-962`
**Issue:** The FACT 7 block header says the test "is marked fixme pending Plan 102-03 … Un-skip in 102-03's closing task" (lines 943-944), but the test on line 948 is a live `test(...)`, not `test.fixme(...)`. Since 102-03 added the `phx-remove` to `operator_live.ex:469`, running the test live is correct — but the comment now actively misleads a maintainer into believing the test is skipped, inviting someone to "re-skip" it or doubt its enforcement. A comment asserting a guard is inert when it is in fact enforcing is a latent footgun.
**Fix:** Delete the "marked fixme pending Plan 102-03" / "Un-skip in 102-03's closing task" lines; replace with a one-line note that 102-03 landed the `phx-remove` and the assertion is now active.

### WR-03: Inbound replay modal lacks the focus-trap and Escape-to-close the operator modal has

**File:** `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex:20-66` (and `inbound_live.ex` render, which omits the focus-trap span)
**Issue:** The operator modal pairs its `motion-tab-swap`/`motion-overlay` modal with a focus-trap span (`operator_live.ex:499-503`: `phx-mounted={JS.focus_first(...)}` + `phx-remove={JS.focus(to: "#replay-open-btn")}`) and an Escape handler (`replay_modal.ex:28-29`: `phx-key="Escape" phx-window-keydown="close_replay"`). The inbound modal has neither: no focus-first on open, no focus-return on close, no `phx-window-keydown` Escape close. This is an a11y/keyboard-parity gap on a dialog (`role="dialog" aria-modal="true"`). It is pre-existing (not introduced by 102-03), but both files are in this review's scope and the milestone is explicitly a motion/micro-interaction + a11y pass, so the asymmetry is in-scope to flag.
**Fix:** Mirror the operator pattern in inbound: add `phx-key="Escape" phx-window-keydown="close_replay"` to the inbound dialog div, and add a focus-trap span in `inbound_live.ex` guarded by `:if={@replay_modal_open?}` with `phx-mounted={JS.focus_first(to: "#inbound-replay-modal")}` and `phx-remove={JS.focus(to: "#...open-btn")}` (the inbound replay-open trigger needs a stable id to return focus to).

### WR-04: Detail-pane exit transition hard-codes `duration-150` instead of the `--duration-fast` token, bypassing the single source of truth

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:469`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex:392`, both `replay_modal.ex` `phx-remove` calls
**Issue:** `app.css:189-208` establishes `--duration-fast: 150ms` as the canonical "modal/flash exit" token and the gallery nav uses the token form `duration-(--duration-fast)` (`gallery_live.ex:174,198`). The new exit transitions instead inline the raw Tailwind `duration-150` literal. Behaviorally identical today (150ms == --duration-fast), but it forks the timing contract: a future re-tune of `--duration-fast` in `app.css` silently fails to propagate to these exits, and the codebase now has two conventions for the same signal. CLAUDE.md's design-system DNA (D-07, single source of truth) prefers the token.
**Fix:** Replace `"ease-out duration-150"` with `"ease-out duration-(--duration-fast)"` in the four `phx-remove` transition tuples, matching the gallery's token usage. (Verify the standalone Tailwind binary emits the `duration-(--duration-fast)` arbitrary-property utility — the gallery already proves it does.)

## Info

### IN-01: Reduced-motion exit is delayed (not animated) but still waits the full 150ms JS timer

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:469`, `inbound_live.ex:392`, both modals
**Issue:** Under `prefers-reduced-motion: reduce`, `app.css:342-350` forces `transition-duration: 0.01ms`, so the visual transition collapses correctly. However `JS.hide(time: 150, ...)` schedules the DOM removal via a JS `setTimeout(150)` that is independent of the CSS transition — so the element stays in the DOM, static, for 150ms before removal even under reduced motion. This is a near-imperceptible removal delay, not a vestibular-safety violation (no movement occurs), so it does not breach MOTION-LD-09. Noting for awareness; no fix required unless the reveal/remove latency is observed as janky.

### IN-02: Stale `app.css` line-number references in the reduced-motion structural test comment

**File:** `mailglass_admin/e2e/structural.spec.js:774-798`
**Issue:** The comment cites "app.css:292-300", "app.css:294", "app.css:297" for the reduced-motion block, but the actual `@media (prefers-reduced-motion: reduce)` block is at `app.css:342-350`. The assertions themselves (`parseFloat(duration) <= 0.05`) are correct and robust to the 0.01ms value; only the line refs are stale.
**Fix:** Update the three line-number citations to `app.css:342-350` (or drop the precise line numbers, which drift on every CSS edit).

### IN-03: `--duration-flash` token is defined but appears unused

**File:** `mailglass_admin/assets/css/app.css:207`
**Issue:** `--duration-flash: 200ms;` is declared with the comment "toast enter", but no `.motion-*` rule or HEEx class consumes it (toast/flash motion is driven inline via `JS.show/hide` with `duration-150` per the file's own note at lines 246-249). Dead token. Low priority — tokens are cheap — but it implies a flash-enter motion that isn't wired up, which could mislead.
**Fix:** Either wire a flash-enter motion to `duration-(--duration-flash)` or drop the token and its comment.

### IN-04: New motion test seeds a recipient it never asserts masking on

**File:** `mailglass_admin/test/mailglass_admin/inbound_live_test.exs:1061-1073`
**Issue:** The GAP-19/MOTION-01 test seeds `recipient: "motion@example.com"` but only asserts the record-keyed `id="inbound-detail-#{record.id}"` is present (the actual motion-reveal stable-id contract). The seeded recipient is incidental and its masking is not checked here. This is fine for a focused motion test (masking is exhaustively covered elsewhere), but the unused-looking recipient could invite a future maintainer to add a redundant assertion. No fix needed; noting for clarity that the omission is intentional, not a coverage gap.

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
