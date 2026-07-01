---
phase: 122-preview-surface-redesign
reviewed: 2026-06-28T19:32:57Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/structural.spec.js
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 122: Code Review Report

**Reviewed:** 2026-06-28T19:32:57Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Adversarial per-file review of the preview-surface redesign (theme_picker adoption,
backdrop a11y hardening, re-voiced onboarding/error copy, dead-attr removal, paired
tests).

The load-bearing D-05 invariant holds: the new `set_theme` handler routes through
Preview's own frame-aware `preview_theme_path/2`, never the operator shell's
`set_theme_path/2`; `put_frame_query(@preview_frame_dark_chrome)` is preserved in the
`return_to`; and the carry-through is correctly proven by both the LiveView and e2e
suites (traced by hand against `set_device → set_theme` and `toggle_backdrop → set_theme`
sequences — both produce the asserted `frame=dark` / `width=` return_to). The closed
`theme_segment/1` guard plus the `ThemeController.sanitized_return_to/2` open-redirect
filter mean no untrusted value reaches the `/theme/<seg>` route or the redirect target.
`mix test` for the two changed Elixir suites is green (40 tests, 0 failures, 1 excluded),
and `node --check` parses both specs. No security defects found.

The findings below are quality / robustness issues, not correctness blockers. The
highest-value one is an over-broad `aria-live` region that will cause screen readers to
read an entire stacktrace aloud — an a11y regression against the phase's own intent.

## Warnings

### WR-01: Render-error card wraps the full stacktrace `<pre>` inside a single `aria-live="polite"` region

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:287-308`
**Issue:** The error card applies `role="status" aria-live="polite"` to the OUTER `<div>`
that contains the `<h1>`, the lead paragraph, AND the full `<pre><code>{@render_error}</code></pre>`
exception dump (`Exception.format/3` output, often dozens of lines). Because the entire
card is a live region, when the error arm renders, assistive tech will announce the whole
subtree — including the multi-line stacktrace — verbatim. The plan (D-08a) called for a
focus-move OR a *small* announce region "(reuse the Seam-B aria-live primitive)" mirroring
`evidence_card.ex`, where the live region is a dedicated `sr-only` status span, not the
whole content block. The backdrop status region in this same file (lines 345-352) does it
correctly (a separate `sr-only` span). The error card does not.
**Fix:** Move the live region off the content container onto a dedicated sibling status
node and let the card itself be a plain `<div role="alert">` (or no role) so the transition
is announced once, concisely, without dumping the stacktrace:
```elixir
<div data-testid="preview-render-error" class="motion-reveal rounded-box border border-error bg-base-200 p-lg">
  <span role="status" aria-live="polite" class="sr-only">
    This Mailable raised while rendering the {@current_scenario} scenario.
  </span>
  <div class="flex items-center gap-sm mb-md">
    <Components.icon name="hero-exclamation-circle" class="w-5 h-5 text-error" />
    <h1 class="text-heading font-bold text-base-content">This Mailable raised while rendering</h1>
  </div>
  ...
  <pre ...><code>{@render_error}</code></pre>
</div>
```
(Note: the existing tests assert `role="status"` is present in the card HTML — the fix
keeps a `role="status"` node, just scoped to the announce span, so `preview_live_test.exs:184`
and the e2e helper still pass.)

### WR-02: `preview_theme_path/2`, sidebar, and start-link silently fall back to a hard-coded `/dev/mail` when `@mount_path` is unset

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:623,625,633`
**Issue:** `@mount_path` is assigned `nil` in `mount/3` (line 75) and is never reassigned
inside `PreviewLive`; it is populated at runtime only by `MailglassAdmin.MountPathHook`'s
attached `:handle_params` hook. The new `set_theme` redirect builder hard-codes `"/dev/mail"`
as the fallback in three places. If the hook is ever absent, reordered, or the redirect is
exercised before a `handle_params` cycle populates `mount_path`, the chrome-theme redirect
silently builds `/dev/mail/theme/<seg>?...` — wrong for any adopter mounted at a different
base (e.g. `/admin/preview`), producing a 404 on the persistence round-trip. The whole point
of `preview_theme_path` being "mount-aware" is defeated by a literal default. The operator
equivalent (`shell.ex:set_theme_path/2`) derives the root from the URI with no such literal.
This is latent (the hook currently runs first, so the default is dormant), which is exactly
why it is dangerous — it will pass every `/dev/mail` test and only surface for a relocated mount.
**Fix:** Derive the fallback from `parsed.path` (already computed) instead of a literal, or
fail loudly if `mount_path` is nil:
```elixir
mount_path =
  socket.assigns.mount_path ||
    (page_uri |> URI.parse() |> Map.get(:path) |> MailglassAdmin.MountPath.base())
```
At minimum, replace the three `|| "/dev/mail"` literals with the resolved base so a
non-`/dev/mail` mount cannot be hard-broken.

### WR-03: `merge_assigns/2` second clause is missing — non-map params would raise inside the form handler

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:718-728` (caller `158-161`)
**Issue:** `merge_assigns/2` is defined only with a `when is_map(params)` guard. The caller is
`handle_event("assigns_changed", %{"assigns" => params}, socket)` — `params` is whatever the
client sends under the `"assigns"` key. A LiveView form normally sends a map, but the event
name and payload shape are client-controllable on a dev surface; a crafted
`assigns_changed` event with `"assigns"` bound to a string/list (e.g. `phx-value` push) reaches
`merge_assigns/2` with a non-map and raises `FunctionClauseError`, tearing down the LiveView.
There is no fallback clause. This is dev-only (no tenant/PII exposure) so it is a robustness
defect rather than a security one, but a single malformed event killing the preview session is
avoidable.
**Fix:** Add a catch-all clause that ignores malformed payloads (consistent with the
`set_tab`/`safe_*_atom` defensive style already used elsewhere in the module):
```elixir
defp merge_assigns(current, params) when is_map(params), do: ...
defp merge_assigns(current, _params), do: current
```

## Info

### IN-01: Monospace utility class is inconsistent (`mono` vs `font-mono`) within the same render

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:385,398,408` (`mono`) vs `300,304,307` (`font-mono`)
**Issue:** The onboarding arm uses `class="mono ..."` for code chips while the error arm (and
the rest of the admin) uses `font-mono`. Both resolve (`.mono` is defined in
`assets/css/app.css:291` and ships in the built bundle), so there is no visual bug — but the
mixed convention is a maintenance smell and risks a future "dead class" if `.mono` is ever
pruned while `font-mono` is kept (or vice-versa).
**Fix:** Standardize on one (`font-mono` is the more common, Tailwind-idiomatic token used by
the error card and components) across the onboarding chips.

### IN-02: Start-page legend copy uses bare "Email" against the domain-language guidance

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:448-450`
**Issue:** The legend tile reads "Toggle the App and Email preview themes independently."
CLAUDE.md "Domain Language" says to avoid bare "Email" in core (prefer Message/Delivery/
Mailable), and the phase explicitly re-voiced the backdrop control to "Email backdrop". The
legend's "Email preview themes" is slightly off-vocabulary versus the now-canonical "Email
backdrop" label it describes.
**Fix:** Align to the control's own noun, e.g. "Toggle the app chrome and the email backdrop
independently."

### IN-03: `MountPathHook` and `PreviewLive.handle_params` both assign `:admin_chrome_theme` (double-source)

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:112,129,152` (cooperates with `mount_path_hook.ex:67`)
**Issue:** The attached hook sets `:admin_chrome_theme` (from `?theme=` else cookie) BEFORE
`PreviewLive.handle_params`, which then re-derives and overwrites it from the same `?theme=`
param via `normalize_capture_url_state`/`parse_admin_chrome_theme`. The two derivations agree
today (both key off the same param, and PreviewLive's no-param fallback reads the value the
hook just set), so behavior is correct — but two independent sources of truth for one assign is
fragile: a future change to one parser silently diverges from the other. This predates phase
122 and is not introduced here; flagged for awareness only.
**Fix:** Consider letting `PreviewLive` trust the hook-provided `:admin_chrome_theme` rather than
re-parsing it, or document the precedence contract in a comment at the handle_params assign site.

### IN-04: `theme_picker` rendered without an explicit `name`, relying on the component's `"theme"` default

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:319-322`
**Issue:** The preview invokes `<Components.theme_picker selected={...} event="set_theme" />`
with no `name`, depending on the component default `name: "theme"` (`components.ex:312`). The
e2e specs select the radios by `input[name="theme"]` (`flows.spec.js:472`, `structural.spec.js:1413`).
This works because there is exactly one theme_picker on the scenario page and no other
`name="theme"` radio group. It is brittle: if a second theme_picker (or any `name="theme"`
control) is ever added to the preview header, the `toHaveCount(3)` assertion and the radio
selectors become ambiguous. The gallery already passes an explicit per-specimen `name`
(`gallery_live.ex:246`) precisely to avoid radio-group collisions — the preview does not.
**Fix:** Pass an explicit, stable `name` (e.g. `name="preview_admin_theme"`) and update the two
e2e selectors to match, so the control is self-identifying and collision-proof.

---

_Reviewed: 2026-06-28T19:32:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
