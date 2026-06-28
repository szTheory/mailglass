# Phase 122: Preview surface redesign - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 6 modified (4 source + 4 test surfaces; persona spec is re-shoot-only)
**Analogs found:** 6 / 6 (all in-repo; this is an alignment-and-polish pass — every change mirrors an already-shipped sibling-surface pattern)

> **Phase type: ALIGNMENT-AND-POLISH (D-01), not a rebuild.** Every modified file copies a pattern
> that already ships on Deliveries/Inbound (119/120/121) or elsewhere in Preview. No new components,
> no new tokens, no new CSS. The job is to make Preview's chrome vocabulary and a11y match the
> now-cleaned operator surfaces while protecting the two-theme independence invariant (D-05).

---

## File Classification

| Modified File | Role | Change Type | Closest Analog | Match Quality |
|---------------|------|-------------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | LiveView (surface root) | adopt-component + a11y-attr + copy + new-handler | `operator/shell.ex:280-283` (theme_picker usage) + `operator_live.ex:191-196` (set_theme handler) + `inbound/evidence_card.ex:132-142` (aria-live) | exact (same component family) |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | function component | dead-attr deletion | n/a — pure removal (the attr has no live analog because it was never read) | n/a |
| `mailglass_admin/test/mailglass_admin/voice_test.exs` | ExUnit (copy grep) | string-assertion update | `voice_test.exs:48-68` itself (the block being edited) + `:106-112` operator orientation-grep block | exact |
| `mailglass_admin/e2e/flows.spec.js` | Playwright (flow) | copy-assertion update + new a11y assertions | `flows.spec.js:452-462` (two-theme lock, keep green) + `inbound` aria/disclosure blocks | exact |
| `mailglass_admin/e2e/structural.spec.js` | Playwright (structural) | verify-only (keep green) + optional start-branch assertSingleH1 | `structural.spec.js:827-831` (preview-orientation) | exact |
| `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | Playwright (screenshot) | re-shoot, NO new cells | `persona-screenshots.spec.js:70,98-109` (the single `preview` cell, already enumerated) | exact |

---

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/preview_live.ex` (LiveView, multi-change)

This is the surface. Four distinct seams, each with its own analog.

---

#### Seam A — Adopt `theme_picker` for admin chrome (D-02), routed through Preview's own path helper (D-05)

**Analog 1 — how the other three surfaces invoke the component** (`operator/shell.ex:280-283`):
```elixir
<div class="flex min-w-0 flex-wrap items-center justify-end gap-sm">
  <Components.tenant_chip tenant={@tenant} />
  <Components.theme_picker selected={@theme_choice} event="set_theme" />
</div>
```

**Analog 2 — the canonical component being adopted** (`components.ex:311-360`). Note the attr contract and that `phx-value-theme` carries the tri-state value (`"system" | "light" | "dark"`):
```elixir
attr :selected, :atom, values: [:system, :light, :dark], default: :system
attr :name, :string, default: "theme"
attr :disabled, :boolean, default: false
attr :event, :string, default: nil
attr :target, :any, default: nil
attr :rest, :global, default: %{}

def theme_picker(assigns) do
  ~H"""
  <fieldset class="inline-flex min-h-11 items-stretch gap-xs rounded-field border border-base-300 bg-base-200 p-xs text-body" disabled={@disabled} {@rest}>
    <legend class="sr-only">Theme</legend>
    <label :for={option <- theme_options()} class={["mg-focus-ring-within relative flex min-h-11 min-w-11 ...", theme_option_class(@selected == option.theme, @disabled)]}>
      <input type="radio" name={@name} value={option.value} checked={@selected == option.theme}
        phx-click={@event} phx-target={@target} phx-value-theme={if @event, do: option.value}
        class="absolute inset-0 m-0 cursor-pointer appearance-none rounded-field opacity-0 ..." />
      <span class="whitespace-nowrap">{option.label}</span>
    </label>
  </fieldset>
  """
end
```

**REPLACES the bespoke binary button** (`preview_live.ex:310-328`) — the current sun/moon ghost button
that silently drops `:system`:
```elixir
<button type="button" data-testid="preview-admin-theme-toggle"
  phx-click="toggle_theme"
  aria-label={if admin_chrome_dark?(@admin_chrome_theme), do: "Switch the app theme to light", else: "Switch the app theme to dark"}
  class="mg-focus-ring btn btn-ghost btn-sm min-h-11 gap-xs px-sm">
  <Components.icon name={if admin_chrome_dark?(@admin_chrome_theme), do: "hero-sun", else: "hero-moon"} class="w-5 h-5" />
  <span class="text-label font-bold">App</span>
</button>
```
Replace this whole block with `theme_picker` + a visible **"App theme"** caption (reuse `text-label text-secondary`).

**THE LOAD-BEARING EVENT-ROUTING DIFFERENCE (D-05 — single highest-risk item):**

The operator surfaces' `set_theme` handler routes through `Shell.set_theme_path/2`, which has **NO frame
handling** (`operator_live.ex:191-196`):
```elixir
def handle_event("set_theme", %{"theme" => theme}, socket) do
  {:noreply,
   redirect(socket,
     to: MailglassAdmin.Operator.Shell.set_theme_path(socket.assigns.page_uri, theme)  # <-- NO frame=dark
   )}
end
```
`Shell.set_theme_path/2` (`shell.ex:102-110`) builds `theme/<seg>?return_to=...` and strips only the
`theme` key — it knows nothing about `frame=dark`:
```elixir
def set_theme_path(uri, theme) when is_binary(uri) and is_binary(theme) do
  parsed = URI.parse(uri)
  path = parsed.path || "/"
  return_to = return_to_without_theme(path, parsed.query || "")
  root = operator_root(path, surface_from_path(path))
  path_join(root, "theme/" <> normalized_theme_segment(theme)) <>
    "?" <> URI.encode_query([{"return_to", return_to}])
end
```

**Preview MUST instead route through its OWN frame-aware helper.** The existing
`preview_theme_path/2` (`preview_live.ex:590-605`) is the load-bearing carry-through — it calls
`put_frame_query` to smuggle the live email-backdrop boolean through `return_to`:
```elixir
defp preview_theme_path(socket, currently_dark?) do
  page_uri = socket.assigns.page_uri || socket.assigns.mount_path || "/dev/mail"
  parsed = URI.parse(page_uri)
  path = parsed.path || socket.assigns.mount_path || "/dev/mail"

  return_to =
    path
    |> append_query_without_theme(parsed.query || "")          # strips prior theme AND frame
    |> put_frame_query(socket.assigns.preview_frame_dark_chrome) # re-adds frame=dark if backdrop dark

  theme = if currently_dark?, do: "system", else: "dark"        # <-- BINARY today
  mount_path = socket.assigns.mount_path || "/dev/mail"
  String.trim_trailing(mount_path, "/") <>
    "/theme/" <> theme <> "?" <> URI.encode_query([{"return_to", return_to}])
end

defp put_frame_query(path, true) do
  separator = if String.contains?(path, "?"), do: "&", else: "?"
  path <> separator <> "frame=dark"
end
defp put_frame_query(path, _not_dark), do: path

defp frame_from_params(%{"frame" => "dark"}, _socket), do: true
defp frame_from_params(%{"frame" => "light"}, _socket), do: false
defp frame_from_params(_params, socket), do: socket.assigns.preview_frame_dark_chrome
```

**Required adaptation (planner action):** `theme_picker` fires `set_theme` with a **tri-state**
`%{"theme" => "system"|"light"|"dark"}`, but the current `handle_event("toggle_theme", ...)` and
`preview_theme_path(socket, currently_dark?)` are **binary** (`preview_live.ex:185-191`):
```elixir
def handle_event("toggle_theme", _params, socket) do
  {:noreply,
   redirect(socket,
     to: preview_theme_path(socket, admin_chrome_dark?(socket.assigns.admin_chrome_theme)))}
end
```
The planner must add a `handle_event("set_theme", %{"theme" => theme}, socket)` clause that builds the
redirect path from the **tri-state segment** while STILL passing through `put_frame_query` (mirror the
operator handler shape, but call a frame-aware path builder, not `Shell.set_theme_path/2`). The simplest
faithful adaptation: generalize `preview_theme_path` to accept a theme segment string instead of a
`currently_dark?` boolean (or add a sibling clause), keeping the `append_query_without_theme |>
put_frame_query` return_to construction verbatim. Whatever shape is chosen, the `return_to` MUST keep the
`put_frame_query(@preview_frame_dark_chrome)` call — that is the invariant `flows.spec.js:454-458` locks.

---

#### Seam B — Harden the binary email-backdrop button (D-03/D-04)

**Keep verbatim** (the `flows.spec.js:454-458` invariant — `data-testid` + `phx-click` must not change),
current code at `preview_live.ex:329-345`:
```elixir
<button type="button"
  data-testid="preview-frame-theme-toggle"
  phx-click="toggle_preview_frame_theme"
  aria-label={if @preview_frame_dark_chrome, do: "Switch the email preview backdrop to light", else: "Switch the email preview backdrop to dark"}
  class="mg-focus-ring btn btn-ghost btn-sm min-h-11 gap-xs px-sm">
  <Components.icon name={if @preview_frame_dark_chrome, do: "hero-sun", else: "hero-moon"} class="w-5 h-5" />
  <span class="text-label font-bold">Email</span>
</button>
```
**Changes (D-03):** add `aria-pressed={@preview_frame_dark_chrome}`; change the always-visible label
`"Email"` → **"Email backdrop"**; keep `min-h-11` + `mg-focus-ring` + the state-dependent `aria-label`.
The toggle handler stays as-is (`preview_live.ex:176-183`) — a pure in-memory boolean flip, no redirect:
```elixir
def handle_event("toggle_preview_frame_theme", _params, socket) do
  {:noreply, assign(socket, :preview_frame_dark_chrome, not socket.assigns.preview_frame_dark_chrome)}
end
```

**aria-live announce pattern — analog `inbound/evidence_card.ex:132-142` (the 121 D-11 precedent):**
```elixir
<%!-- Reveal-state change is announced in TEXT, never the warning border
      color alone (WCAG 1.4.1, D-11). The region is always present so the
      announcement is perceived on the :revealed -> :redacted collapse too. --%>
<p
  data-testid="inbound-evidence-status"
  role="status"
  aria-live="polite"
  class={["mt-sm text-body text-secondary", @reveal_state != :revealed && "sr-only"]}
>
  {reveal_status_text(@reveal_state)}
</p>
```
With its text helper (`evidence_card.ex:174-179`):
```elixir
defp reveal_status_text(:revealed), do: "Raw source revealed. This payload contains unredacted PII."
defp reveal_status_text(_redacted_or_denied), do: "Raw source re-redacted."
```
**Mirror for the backdrop (D-04):** add a `role="status" aria-live="polite" sr-only` region in the header
subtree announcing **"Email backdrop: dark" / "Email backdrop: light"**, driven by
`@preview_frame_dark_chrome`. Note: evidence_card keeps the region always-present and toggles `sr-only`;
Preview's announcement is purely sr-only (no visible affordance needed), so a small `<span class="sr-only"
role="status" aria-live="polite">` carrying a `backdrop_status_text(@preview_frame_dark_chrome)` helper is
the least-surprise adaptation.

---

#### Seam C — Empty-mailables onboarding copy (D-09)

Current code `preview_live.ex:361-402` (the `@mailables == []` arm). Keep the structure (icon + h1 +
lead + checklist + HexDocs link) and **the orientation strip at `:362` — DO NOT MOVE IT** (it is already
empty-pane-only; moving it is the only way to break `structural.spec.js:827-831`). Current copy to change:
```elixir
<h1 class="mb-sm text-heading font-bold text-base-content">
  No Mailables discovered
</h1>
<p class="text-body text-secondary">
  Preview scans loaded modules that use Mailglass.Mailable. Nothing was found yet.
</p>
```
**Brandbook-canonical string (`brandbook/copy/microcopy.md:17`, Mailable/Empty) — use VERBATIM** as the
headline + lead (voice_test will grep it):
> No mailables discovered yet. Define one with `mix mailglass.gen.mailable` and it will appear here, ready to preview.

Surface `mix mailglass.gen.mailable` as the PRIMARY next step (a `mono` `<code>` chip MAY carry
`text-primary` per UI-SPEC Color reserved-list #6). **Demote** the existing two `<li>` recovery checks
(the `use Mailglass.Mailable` compiled-and-loaded check `:380-384` + the explicit `mailables:` router list
`:386-394`) to a secondary checklist. Keep the "Read preview setup" HexDocs link (`:396-401`) verbatim.
Verify the long router-snippet `<code>` block wraps/scrolls at 320px (`overflow-auto`/`whitespace-pre-wrap`).

---

#### Seam D — Error card copy + transition a11y (D-10/D-08a)

Current code `preview_live.ex:284-301` (the `@render_error` arm):
```elixir
<div data-testid="preview-render-error" class="rounded-box border border-error bg-base-200 p-lg">
  <div class="flex items-center gap-sm mb-md">
    <Components.icon name="hero-exclamation-circle" class="w-5 h-5 text-error" />
    <h1 class="text-heading font-bold text-base-content">
      preview_props/0 raised an error          {/* <-- too narrow; CHANGE (D-10) */}
    </h1>
  </div>
  <p class="text-body text-secondary">
    Fix the error in <code class="font-mono text-label">{inspect(@current_mailable)}</code>
    and save the file to reload.
  </p>
  <pre class="mt-md font-mono text-label text-error whitespace-pre-wrap overflow-auto max-h-80 ..."><code>{@render_error}</code></pre>
</div>
```
**Changes (D-10):**
- Headline `"preview_props/0 raised an error"` → **"This Mailable raised while rendering"** (render-time
  template raises land here too, not just `preview_props/0`). This is the error arm's single `<h1>`.
- Name BOTH the Mailable (`inspect(@current_mailable)`) and the scenario (`@current_scenario`) in the lead.
- Recovery-oriented lead in brandbook voice, e.g. **"Fix it in {Mailable} and save to reload — the full
  error is below."** (exact wording is discretion).
- **KEEP the inline scrollable `<pre>`** — do NOT adopt the brandbook recipient-facing Error line
  ("…in your logs.", `microcopy.md:16`); that is wrong for a dev tool (D-10). The `<pre>` is the correct DX.
- "Oops" stays banned. Struct-matching stays correct (`preview_live.ex:738-740`):
  ```elixir
  {:error, %Mailglass.TemplateError{} = err} ->
    # Match by struct — never by message string (CLAUDE.md pitfall #7).
    assign(socket, :render_error, Exception.message(err))
  ```
- **Transition a11y (D-08a):** apply `motion-reveal` (existing token) on error-card entry, and move focus
  to the card OR announce via `role="status"`/`aria-live="polite"` — reuse the same Seam B aria-live
  primitive (mirror `evidence_card.ex:132-142`). Honor the existing reduced-motion neutralizer; no new CSS.

---

### `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` (function component, dead-attr deletion)

**Analog:** none needed — pure removal. The `dark_chrome` attr is declared twice and threaded once but
**never read** in any `mailable_entry/1` clause (`:78-125`) or `mailable_label/1`; `preview_live.ex` never
passes it (it passes `mailables`/`current_mailable`/`current_scenario`/`device_width`/`admin_chrome_theme`/
`mount_path` only, `:258-280`).

Delete these three sites:
```elixir
# Line 30 — sidebar/1 attr declaration:
attr(:dark_chrome, :boolean, default: false)

# Line 56 — pass-through inside sidebar/1 -> <.mailable_entry ...>:
dark_chrome={@dark_chrome}

# Line 72 — mailable_entry/1 attr declaration:
attr(:dark_chrome, :boolean, default: false)
```
**Keep** the discovery-failure warning badge (`sidebar.ex:113-125`, icon + `sr-only` text — a correct
non-color-alone cue) and the active-entry accent (`scenario_classes`) untouched. Pure dead-code removal,
no visual change.

---

### `mailglass_admin/test/mailglass_admin/voice_test.exs` (ExUnit copy grep — MANDATORY same-phase, D-11)

**Analog:** the block being edited itself (`voice_test.exs:48-68`). The error-card grep at `:67` goes RED
the instant the D-10 headline changes:
```elixir
# Error-card heading appears ONLY when BrokenMailer is loaded
assert html =~ "preview_props/0 raised an error"   # <-- MUST become "This Mailable raised while rendering"
```
And the brandbook Empty string (D-09) must be added so the grep matches verbatim (mirror the operator
orientation-grep block at `:106-112`, which greps a canonical brandbook string):
```elixir
# (new) empty-mailables canonical brandbook Empty line (microcopy.md:17) — grep verbatim
assert html =~ "No mailables discovered yet. Define one with `mix mailglass.gen.mailable`"
```
The banned-words block (`:30-45`, with the `strip_scripts/1` dep-JS guard — see project memory
"voice_test 'Oops' is dep-JS noise") stays as-is; "Oops" remains absent.

---

### `mailglass_admin/e2e/flows.spec.js` (Playwright flow — MANDATORY same-phase, D-11)

**Analog 1 — the two-theme independence lock that MUST stay green against the theme_picker swap**
(`flows.spec.js:452-462`, D-05):
```javascript
test("Preview advanced: frame theme differs from admin theme without overflow at 320", async ({ page }) => {
  await openPreviewScenario(page, "theme=light");
  await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
  await page.getByTestId("preview-frame-theme-toggle").click();
  await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "dark");
  // Frame theme diverges from admin theme — admin chrome stays light.
  await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
  await assertSingleH1(page, "preview advanced");
  ...
});
```
This selects the backdrop button by `data-testid="preview-frame-theme-toggle"` (unchanged) and asserts
`preview-pane[data-preview-frame-theme]` flips while `preview-shell[data-theme]` stays — re-confirm it
passes after the `theme_picker` adoption. **Add NEW assertions** (D-11b) in the preview block (~409-462):
- admin `theme_picker` present + tri-state (assert the `<fieldset>` with three radios; `:system` reachable);
- backdrop `aria-pressed` reflects state (click → `aria-pressed="true"`);
- the `aria-live`/`role="status"` region announces "Email backdrop: dark/light".

**Analog 2 — copy assertions touching changed onboarding/error copy.** The empty/error fixtures are loaded
via helpers (`flows.spec.js:58-82`): `openPreviewEmpty` (`/ops/browser-preview-empty`), `openPreviewError`
(`BrokenMailer/__error__`). Any string assertion on the changed copy must be updated here too. The
boundary/error tests (`:426-440`) currently assert only `data-testid` visibility, so they survive — but
verify no copy-string assertion elsewhere greps the old headline.

---

### `mailglass_admin/e2e/structural.spec.js` (Playwright structural — verify-only, keep green)

**Analog:** `structural.spec.js:827-831` — asserts `preview-orientation` on the already-empty route:
```javascript
test("Preview: preview-orientation testId exists on browser-preview-empty route", async ({ page }) => {
  await openPreviewEmpty(page);
  await expect(page.getByTestId("preview-orientation")).toBeVisible();
});
```
Stays green **as long as the orientation strip stays in the `@mailables == []` branch (D-11a) — DO NOT
MOVE IT.** Optionally add `assertSingleH1` coverage on the start branch if not already covered (D-11c).

---

### `reference/demo_app/assets/e2e/persona-screenshots.spec.js` (Playwright screenshot — re-shoot, NO new cells, D-12)

**Analog:** the single `preview` cell already enumerated (`persona-screenshots.spec.js:70`):
```javascript
{ id: "preview", kind: "dev-open", route: "/dev/mail", priority: 3 },
```
expanded via `cellsFor` (`:98-109`) to `{375,1440} × {light,dark}` (priority>2 → anchor square only).
**Re-run the producer in one pass** — that delta IS the only-forward evidence. **Adding any new cell fires
the persona drift-guard (D-12)** — re-shoot only. (See project memory: `PERSIST_AXE_BASELINE`/persona
producers run locally end-to-end with node_modules + Chromium present.)

---

## Shared Patterns

### Two independent theme controls — structurally distinct shapes (WCAG 1.4.1 by form-factor)
**Source:** `components.ex:326-360` (`theme_picker`, segmented 3-way `<fieldset>`) vs the binary
`<button aria-pressed>` (Seam B). **Apply to:** the Preview header only. The segmented picker (App theme)
and the single button (Email backdrop) are deliberately different shapes + separately captioned so they
are never confused — satisfied by form-factor, not icon+word alone (D-02).

### aria-live announce for a remote-pane / color-only change
**Source:** `inbound/evidence_card.ex:132-142` + `:174-179` (the 121 D-11 precedent).
**Apply to:** the email-backdrop toggle (Seam B) and the error-card transition (Seam D). `role="status"
aria-live="polite" sr-only` with a text helper — never signal state by color alone.

### Frame-aware theme redirect (the load-bearing carry-through)
**Source:** `preview_live.ex:590-638` (`preview_theme_path` → `append_query_without_theme` →
`put_frame_query` → `frame_from_params`). **Apply to:** the new `set_theme` handler (Seam A). This is the
ONLY frame-aware path builder; the operator `Shell.set_theme_path/2` (`shell.ex:102-110`) is the WRONG one
to call — it drops `frame=dark`. This is the single highest-risk item; call it out in the plan.

### Struct-matched render error (never message-string)
**Source:** `preview_live.ex:738-740`. **Apply to:** Seam D — keep matching `%Mailglass.TemplateError{}`;
the copy change is presentation-only, the match logic does not change (CLAUDE.md pitfall #7).

### Paired-test green-only-forward (Pitfall-2)
**Source:** `voice_test.exs:48-68` + `flows.spec.js` preview block. **Apply to:** every copy/structure
change ships its test update in the SAME phase. Brandbook Empty string grepped verbatim; error headline
grep updated; backdrop a11y assertions added; two-theme lock re-confirmed.

### No `mix assets.build` (TokenParity landmine — D-13)
**Source:** project memory "Token-parity bundle landmine" + UI-SPEC §Asset pipeline. **Apply to:** all
changes — they reuse classes the operator surfaces already ship (`theme_picker`, `sr-only`, `text-label`,
`motion-reveal`). Confirm `priv/static/app.css` is untouched before committing. A naive rebuild emits
raw-inline daisyUI 5.5.19 theme blocks that BREAK TokenParityTest.

---

## No Analog Found

None. Every change has an in-repo precedent (this is an alignment-and-polish pass — that is the point).
The closest thing to "no analog" is the `set_theme` tri-state handler for Preview: the *event-handler
shape* is copied from `operator_live.ex:191-196`, but the *path builder* it calls must be Preview's own
frame-aware `preview_theme_path` (adapted from binary to tri-state), NOT the operator's `set_theme_path`.
That adaptation (binary `currently_dark?` → tri-state segment, keeping `put_frame_query`) is the one place
the planner writes genuinely new glue rather than copying verbatim.

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/` (preview_live, components, operator/shell,
operator_live, inbound_live, preview/sidebar, inbound/evidence_card), `mailglass_admin/test/`,
`mailglass_admin/e2e/`, `reference/demo_app/assets/e2e/`, `brandbook/copy/microcopy.md`.
**Files scanned:** 11 source/test files read; ~8 grep sweeps.
**Pattern extraction date:** 2026-06-28
