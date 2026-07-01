---
phase: 122-preview-surface-redesign
fixed_at: 2026-06-28T20:05:00Z
review_path: .planning/phases/122-preview-surface-redesign/122-REVIEW.md
iteration: 2
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 122: Code Review Fix Report

**Fixed at:** 2026-06-28T20:05:00Z
**Source review:** .planning/phases/122-preview-surface-redesign/122-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 7 (3 warning + 4 info)
- Fixed: 7
- Skipped: 0

All 7 findings are now resolved. The 3 Warning findings (WR-01..WR-03) were fixed in
iteration 1; the 4 Info findings (IN-01..IN-04) were fixed in this pass (iteration 2).

## Fixed Issues

### WR-01: Render-error card wraps the full stacktrace `<pre>` inside a single `aria-live="polite"` region

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** fdfbc56b (iteration 1)
**Applied fix:** Removed `role="status" aria-live="polite"` from the outer error-card
`<div>` (now `role="alert"`) and added a dedicated `sr-only` sibling span carrying
`role="status" aria-live="polite"` with a concise one-line announcement. This mirrors
the backdrop status region in the same file (and `evidence_card.ex`), so assistive tech
announces the error transition once instead of reading the entire `Exception.format/3`
stacktrace `<pre>` aloud. A `role="status"` node remains in the card HTML, so the
existing tests still pass.

### WR-02: `preview_theme_path/2` silently falls back to a hard-coded `/dev/mail` when `@mount_path` is unset

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 2d57e5aa (iteration 1)
**Applied fix:** Replaced all three `|| "/dev/mail"` literals in `preview_theme_path/2`
with a single resolved `mount_base`: `socket.assigns.mount_path ||
MailglassAdmin.MountPath.base(parsed.path)`. The `return_to` `path` and the final
`/theme/<seg>` prefix now both derive from `mount_base`, so a relocated adopter mount
(e.g. `/admin/preview`) no longer 404s on the chrome-theme persistence round-trip.

### WR-03: `merge_assigns/2` second clause is missing — non-map params would raise inside the form handler

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 602a05d7 (iteration 1)
**Applied fix:** Added the catch-all clause `defp merge_assigns(current, _params), do:
current` immediately after the existing `when is_map(params)` clause. A crafted
`assigns_changed` event binding `"assigns"` to a non-map now no-ops instead of raising
`FunctionClauseError` and tearing down the LiveView, consistent with the defensive
style elsewhere in the module.

### IN-01: Monospace utility class inconsistent (`mono` vs `font-mono`)

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 81494660 (iteration 2)
**Applied fix:** Replaced the three `class="mono ..."` onboarding code chips with the
canonical, Tailwind-idiomatic `font-mono` token already used by the error card and the
rest of the admin. Verified no `class="mono` occurrences remain in the file. (Review
cited lines 385/398/408; the actual chips were at 392/405/415 — adapted to current code.)

### IN-02: Start-page legend copy uses bare "Email" against domain-language guidance

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 9349792f (iteration 2)
**Applied fix:** Re-voiced the legend from "Toggle the App and Email preview themes
independently." to "Toggle the app chrome and the email backdrop independently.",
aligning with the now-canonical "Email backdrop" control label and CLAUDE.md
domain-language guidance. Confirmed this copy is NOT asserted in `voice_test.exs` (or
any test/spec), so no test update was needed; the `voice_test.exs` + `preview_live_test.exs`
suites remain green (40 tests, 0 failures).

### IN-03: `MountPathHook` and `PreviewLive.handle_params` both assign `:admin_chrome_theme` (double-source)

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 9067b34a (iteration 2)
**Applied fix:** Fixed via documentation (deliberate, low-risk choice). The review notes
this predates phase 122 and is "flagged for awareness only." Rather than refactoring
behavior (regression risk on a correct-but-fragile path), added a comment at the
`handle_params` assign site documenting the precedence contract: the MountPathHook seeds
`:admin_chrome_theme` from `?theme=`/cookie before `handle_params`; PreviewLive is the
authoritative writer and re-derives from the same `?theme=` param; both derivations key
off the same param and must change together. A second short comment marks the no-param
`handle_params` clause. No behavioral change, so no regression risk.

### IN-04: `theme_picker` rendered without an explicit `name`, relying on the `"theme"` default

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`,
`mailglass_admin/e2e/flows.spec.js`, `mailglass_admin/e2e/structural.spec.js`
**Commit:** edf17c92 (iteration 2)
**Applied fix:** Passed an explicit stable `name="preview_admin_theme"` to the preview
`theme_picker` (mirroring `gallery_live.ex`'s per-specimen name) so the radio group is
self-identifying and collision-proof. Updated all five `input[name="theme"]` selectors in
the e2e specs to the new name — two in `flows.spec.js` (lines 472, 476) and three in
`structural.spec.js` (lines 912, 1413, 1545). The review noted only one selector per file;
the broader search caught the additional references. Both specs pass `node --check`.

## Verification

- Targeted Elixir suites green on the committed state:
  `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs`
  -> **40 tests, 0 failures, 1 excluded** (matches the documented baseline; the Postgrex
  disconnect log line is benign async test-teardown noise).
- `node --check e2e/flows.spec.js` and `node --check e2e/structural.spec.js` both parse.
- No remaining `class="mono` in `preview_live.ex`; no remaining `name="theme"` in the
  two e2e specs.

## Skipped Issues

None — all 7 findings were fixed.

---

_Fixed: 2026-06-28T20:05:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
