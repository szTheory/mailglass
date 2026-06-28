---
phase: 122-preview-surface-redesign
fixed_at: 2026-06-28T19:48:00Z
review_path: .planning/phases/122-preview-surface-redesign/122-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 122: Code Review Fix Report

**Fixed at:** 2026-06-28T19:48:00Z
**Source review:** .planning/phases/122-preview-surface-redesign/122-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (Warning tier; the 4 Info findings IN-01..IN-04 are out of `critical_warning` scope)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: Render-error card wraps the full stacktrace `<pre>` inside a single `aria-live="polite"` region

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** fdfbc56b
**Applied fix:** Removed `role="status" aria-live="polite"` from the outer error-card
`<div>` (now `role="alert"`) and added a dedicated `sr-only` sibling span carrying
`role="status" aria-live="polite"` with a concise one-line announcement
("This Mailable raised while rendering the {@current_scenario} scenario."). This
mirrors the backdrop status region already present in the same file (and
`evidence_card.ex`), so assistive tech announces the error transition once instead
of reading the entire `Exception.format/3` stacktrace `<pre>` aloud. A
`role="status"` node remains in the card HTML, so `preview_live_test.exs:184` and the
e2e helper still pass (confirmed: 40 tests, 0 failures).

### WR-02: `preview_theme_path/2` silently falls back to a hard-coded `/dev/mail` when `@mount_path` is unset

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 2d57e5aa
**Applied fix:** Replaced all three `|| "/dev/mail"` literals in `preview_theme_path/2`
with a single resolved `mount_base`: `socket.assigns.mount_path ||
MailglassAdmin.MountPath.base(parsed.path)`. `MailglassAdmin.MountPath.base/1` already
exists (confirmed by reading `mount_path.ex`) and strips trailing live-action segments
to recover the absolute mount base from the current document path, returning `"/"`
for nil input rather than a wrong `/dev/mail`. The `return_to` `path` and the final
`/theme/<seg>` prefix now both derive from `mount_base`, so a relocated adopter mount
(e.g. `/admin/preview`) no longer 404s on the chrome-theme persistence round-trip.

### WR-03: `merge_assigns/2` second clause is missing — non-map params would raise inside the form handler

**Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
**Commit:** 602a05d7
**Applied fix:** Added the catch-all clause `defp merge_assigns(current, _params), do:
current` immediately after the existing `when is_map(params)` clause. A crafted
`assigns_changed` event binding `"assigns"` to a non-map (string/list) now no-ops
instead of raising `FunctionClauseError` and tearing down the LiveView, consistent
with the `set_tab`/`safe_*_atom` defensive style elsewhere in the module.

## Verification

- `mix compile` succeeds (the unrelated `selected_delivery` attr warning in
  `operator_live.ex:505` is pre-existing, not introduced by these fixes).
- Targeted suites green on the committed state:
  `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs`
  -> **40 tests, 0 failures, 1 excluded** (matches the documented baseline). The
  Postgrex disconnect log line is benign async test-teardown noise.
- `node --check e2e/flows.spec.js` and `node --check e2e/structural.spec.js` both parse.

## Skipped Issues

None.

---

_Fixed: 2026-06-28T19:48:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
