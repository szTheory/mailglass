---
phase: 01-foundation
plan: 05
subsystem: components
tags: [components, heex, phoenix-component, vml, mso, premailex, author-02, wave-3, d-14]

requires:
  - phase: 01-01
    provides: "Project scaffold + Wave 0 test stubs (vml_preservation_test.exs, button_test.exs, row_test.exs, img_no_alt_test.exs) ready to de-skip + premailex 0.3.20 + phoenix_live_view 1.1 + phoenix_html 4.1 in mix.lock"
  - phase: 01-03
    provides: "Mailglass.Config.get_theme/0 backed by :persistent_term — read at render time by Mailglass.Components.Theme.color/1 and .font/1 (D-19)"
  - phase: 01-04
    provides: "Message struct + OptionalDeps gateways — not directly consumed by Components but present in the module graph"
provides:
  - "Mailglass.Components.Theme — thin :persistent_term reader over Mailglass.Config.get_theme(); color/1 + font/1 with defaults for unknown tokens"
  - "Mailglass.Components.CSS — merge_style/2 helper combining base inline style with nil/binary/list overrides (D-20, no external class-composition library)"
  - "Mailglass.Components.Layout — email_layout/1 emits <!DOCTYPE html> + MSO OfficeDocumentSettings XML block (D-12) + light-only color-scheme metas (D-13)"
  - "Mailglass.Components — 11 HEEx function components (preheader, container, section, row, column, heading, text, button, img, link, hr) with per-component attr/slot API per D-16..D-25; brand tokens (tone/variant/bg) resolve via Components.Theme"
  - "test/fixtures/vml_golden.html — representative email with OfficeDocumentSettings + ghost-table + v:roundrect + <!--[if !mso]><!--> fallback; guards Premailex regressions (D-14)"
  - "test/mailglass/components/vml_preservation_test.exs — 4 real assertions: MSO conditional-comment survival, v:roundrect preservation, CSS inlining correctness, OfficeDocumentSettings preservation"
  - "test/mailglass/components/button_test.exs — 5 real assertions on v:roundrect + w:anchorlock + mso-hide:all + data-mg-plaintext=link_pair + href propagation"
  - "test/mailglass/components/row_test.exs — 5 real assertions on ghost-table + ghost-td + data-mg-column marker + width:N integer handling"
affects: [phase-01-plan-06-renderer, phase-3-outbound, phase-5-admin, phase-6-credo]

tech-stack:
  added:
    - "Phoenix.Component-based HEEx function components with slot + attr declarative API"
    - "Premailex-compatible VML golden-fixture test (D-14) as a first-class regression guard"
    - "Mailglass.Components.Theme as a thin :persistent_term reader — O(1) per component render"
  patterns:
    - "HEEx comment-interpolation workaround: ~H does NOT interpolate expressions inside <!-- --> comments. VML-bearing components pre-build MSO conditional blocks as Phoenix.HTML.raw/1 strings and embed them via {@mso_open} / {@mso_close} / {@vml_block} expressions — interpolation happens outside the comment scope. The <a> HTML fallback uses normal HEEx because `<!--[if !mso]><!-->` terminates the comment per HTML parser rules (HEEx respects that boundary)."
    - "Slot rendering to binary: Phoenix.Component.render_slot/2 is a macro that expects to run inside a ~H context (it references `var!(changed, Phoenix.LiveView.Engine)`). For one-shot server renders into raw strings we call the underlying Phoenix.Component.__render_slot__(nil, slot, nil) directly — the nil `changed` tracker is appropriate since we're not doing LiveView change-tracking, just rendering a static slot into HTML."
    - "Per-component attr block convention: attr :class, :any, default: nil + attr :rest, :global, include: @global_includes + enum variant attrs with values: for compile-time warnings. Content components (heading, text, link, button) exclude :style from :global (D-17). Link-bearing components (button, link) add href + target to their :global include list."
    - "Dynamic tag names via case statement: <.heading level={N}> dispatches to one of four ~H sigils (<h1>..<h4>) via a case on @level rather than Phoenix.HTML.raw on a dynamically-built open tag. Each branch has a full HEEx-validated template."
    - "Button variant/tone separation: :tone picks the brand color (glass/ink/slate); :variant picks how that color is applied (primary=fill, secondary=ice-tint, ghost=transparent+ink-text). Both resolve to concrete hex values before entering the VML block so classic Outlook doesn't see a dangling brand token."

key-files:
  created:
    - "lib/mailglass/components/theme.ex — O(1) :persistent_term theme reader; color/1 + font/1 with sensible fallbacks (Glass #277B96 / sans-serif)"
    - "lib/mailglass/components/css.ex — merge_style/2 with binary + list-of-binaries overload; handles nil and empty-string gracefully"
    - "lib/mailglass/components/layout.ex — email_layout/1 with MSO head XML, viewport meta, light-only color-scheme metas, CSS reset"
    - "lib/mailglass/components.ex — the 11 function components + private helpers (resolve_bg/2, heading_style/1, button_text_color/1, button_bg_color/2, render_slot_to_binary/2, escape_attr/1)"
    - "test/fixtures/vml_golden.html — golden fixture with OfficeDocumentSettings, ghost-table for 2 columns, v:roundrect button, <!--[if !mso]><!--> HTML fallback"
  modified:
    - "test/mailglass/components/vml_preservation_test.exs — @moduletag :skip removed; 4 real Premailex-vs-golden-fixture assertions"
    - "test/mailglass/components/button_test.exs — @moduletag :skip removed; 5 real assertions rendering <.button> via Phoenix.HTML.Safe.to_iodata"
    - "test/mailglass/components/row_test.exs — @moduletag :skip removed; 5 real assertions on <.row> + <.column> ghost-table patterns"

key-decisions:
  - "HEEx comment-interpolation workaround via raw-embedded MSO blocks. The naive `~H` template with `<!--[if mso]><v:roundrect ... fillcolor={@bg_color} ...><![endif]-->` emits the literal text `{@bg_color}` because HEEx treats comment contents as uninterpreted text. The fix: pre-build the VML / ghost-table / ghost-td conditional blocks as strings (concatenated with ordinary string interpolation), wrap with Phoenix.HTML.raw/1, and embed via {@mso_open}. HEEx sees those as normal expression holes and interpolates them. Documented inline in button/1 so the next author doesn't regress it."
  - "render_slot_to_binary/2 calls Phoenix.Component.__render_slot__/3 directly. The public render_slot/2 is a macro that requires being expanded inside a ~H block (it references the LiveView change tracker). For button/1's VML branch we need the slot as a binary to embed into the raw MSO block — so we call the underlying function with nil as the `changed` tracker. This is safe for server-rendered email because there is no LiveView change tracking to preserve."
  - "Button variant and tone are orthogonal. :tone picks the color (glass/ink/slate); :variant picks the rendering mode (primary=fill, secondary=tint, ghost=transparent). Both get resolved into concrete hex values before hitting the VML block — classic Outlook needs literal colors in the fillcolor/strokecolor VML attrs, it cannot resolve brand tokens."
  - "Heading levels use a case statement with four ~H branches rather than a dynamic tag name. HEEx can't build dynamic tag names, and using Phoenix.HTML.raw for the open/close tags loses the HEEx compile-time attribute validation on @style / @rest / data-mg-plaintext. Four branches is the cleanest option — each produces a statically-validated <h1>..<h4> template."
  - "img alt is required at compile time. Declaring `attr :alt, :string, required: true` means Phoenix.Component's compile-time check emits 'missing required attribute \"alt\"' whenever <.img> is rendered without :alt. Under --warnings-as-errors that warning becomes a compile error. Adopters who want decorative images must pass `alt=\"\"` explicitly — the accessibility floor cannot be bypassed by omission."
  - "Kept img_no_alt_test.exs @moduletag :skip. The compile-time check is verified by the attr declaration itself (confirmed via eval_string fixture during implementation — the warning fires as expected). The test stub exists as documentation of the contract, not as a runnable test — compiling a fixture inside the test suite would fail the whole suite. Plan 06 may revisit if a runnable compile-time-error test shape emerges."

patterns-established:
  - "HEEx comment-escape pattern: whenever a component must emit literal MSO conditional comments with interpolated content (v:roundrect, ghost-table, ghost-td), build the block as a string outside the ~H sigil, wrap with Phoenix.HTML.raw/1, and embed via {@expr}. HEEx's refusal to interpolate inside comments is intentional (XSS defence) — the raw-embedded pattern is the sanctioned workaround when conditional comments carry data."
  - "Theme-backed brand tokens: per-component :tone / :variant / :bg attrs take a string from a closed values: list, then the component resolves the string to a hex color via Theme.color(String.to_atom(token)) before emitting. Keeps adopter-facing API stringly-typed (good for HEEx attribute syntax) while internal resolution stays atom-keyed (matches the theme map shape)."
  - "Slot-to-binary render path: render_slot_to_binary/2 (Phoenix.Component.__render_slot__ + Phoenix.HTML.Safe.to_iodata) is the general primitive for 'I need my slot rendered as a string to splice into a raw block.' Reused in button/1 today; future components that need dual rendering (HTML + VML, HTML + plaintext) can call the same helper."
  - "data-mg-plaintext strategy markers: each content component emits `data-mg-plaintext=\"<strategy>\"` on its root — `link_pair` for button/link, `text` for text/img, `divider` for hr, `heading_block_N` for heading level N, `skip` for preheader. Plan 06's Renderer.to_plaintext/1 custom Floki walker reads these to emit structured plaintext; a terminal Floki pass strips data-mg-* from the final wire HTML."

requirements-completed: [AUTHOR-02]

duration: 8min
completed: 2026-04-22
---

# Phase 1 Plan 5: Components HEEx Library Summary

**Eleven HEEx function components (preheader, container, section, row, column, heading, text, button, img, link, hr) with surgical VML support where classic Outlook genuinely needs it (`<v:roundrect>` button, ghost-table row/column), a mandatory D-14 Premailex golden-fixture regression guard, and three submodule helpers (Theme/CSS/Layout) — the email composition surface every adopter mailable will consume from Plan 06 onwards.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-22T15:14:29Z
- **Completed:** 2026-04-22T15:23:12Z
- **Tasks:** 3 / 3
- **Files created:** 5 (theme.ex, css.ex, layout.ex, components.ex, vml_golden.html)
- **Files modified:** 3 (vml_preservation_test.exs, button_test.exs, row_test.exs)

## Accomplishments

- **MANDATORY D-14 VML regression guard is green.** `test/mailglass/components/vml_preservation_test.exs` ships 4 real assertions running Premailex 0.3.20 against a representative golden fixture; all conditional-comment patterns (`<!--[if mso]>`, `<![endif]-->`, `<!--[if gte mso 9]>`, `<!--[if !mso]><!-->`, `<!--<![endif]-->`) survive, `<v:roundrect>` + `<w:anchorlock>` survive, CSS classes inline onto `<a>` correctly, and the `OfficeDocumentSettings` XML block survives. This test guards against any future Premailex bump that regresses conditional-comment preservation.
- **Eleven HEEx function components** in `lib/mailglass/components.ex` (≈420 lines) implementing D-10..D-25 verbatim. Every component ships `attr :class, :any, default: nil` + `attr :rest, :global, include: [...]`; content components exclude `:style` from `:global` (D-17); variant/tone enum attrs use `values:` for compile-time warnings (D-18).
- **`<.button>` is the surgical-VML flagship.** Emits a `<v:roundrect xmlns:v=... xmlns:w=... fillcolor=... strokecolor=...>` wrapped in `<!--[if mso]>`, with a `<!--[if !mso]><!--><a mso-hide:all>...</a><!--<![endif]-->` HTML fallback. Classic Outlook sees only the VML; every other client sees only the `<a>`.
- **`<.row>` / `<.column>` ghost-table pattern** — `<!--[if mso]><table role="presentation">...</table><![endif]-->` wrapping `display:inline-block` divs so classic Outlook aligns columns side-by-side instead of stacking them.
- **`<.img>` requires `:alt` at compile time** (D-18). Phoenix.Component's compile-time check emits "missing required attribute \"alt\"" on any call site without it — under `--warnings-as-errors` that's a hard failure.
- **`<.preheader>` with `data-mg-plaintext="skip"`** (D-15) — hidden inbox preview padded with zero-width chars; Renderer plaintext walker skips it entirely.
- **`Mailglass.Components.Theme.color/1` + `.font/1`** — O(1) `:persistent_term` reads backed by `Mailglass.Config.get_theme/0`. Unknown tokens fall back to Glass (#277B96) / sans-serif.
- **`Mailglass.Components.Layout.email_layout/1`** — full `<!DOCTYPE html>` wrapper with MSO `OfficeDocumentSettings` XML (D-12), light-only color-scheme metas (D-13), CSS reset.
- **`mix compile --warnings-as-errors`** and **`mix compile --no-optional-deps --warnings-as-errors`** both exit 0. **`mix test`** exits 0 with **1 property + 68 tests, 0 failures, 10 skipped** (down from 14 — the 4 unskipped are 2 VML + 1 button + 1 row tests, which now carry 4+5+5 assertions vs the old flunk stubs).

## Task Commits

1. **Task 1: VML preservation golden-fixture test (D-14 MANDATORY, implemented first)** — `721a811` (test)
2. **Task 2a: Theme + CSS + Layout helper modules** — `9b91399` (feat)
3. **Task 2b: 11 HEEx components + button/row tests** — `0a273c5` (feat)

Task 2b is marked `tdd="true"` in the plan. RED evidence: pre-implementation, `mix test test/mailglass/components/` passed only the VML preservation tests from Task 1; button_test.exs and row_test.exs were still `@moduletag :skip`. GREEN evidence: post-implementation, all 15 component tests (4 VML + 5 button + 5 row + 1 img_no_alt-stub-still-skipped) exit 0. The TDD gate is satisfied via the existing Wave 0 stubs from Plan 01-01 which acted as RED placeholders — the green implementation replaces the `flunk` bodies with real assertions.

## Files Created/Modified

| File | Purpose |
|------|---------|
| `lib/mailglass/components/theme.ex` | `get/0`, `color/1`, `font/1` — O(1) `:persistent_term` reader with Glass/#277B96 and sans-serif fallbacks |
| `lib/mailglass/components/css.ex` | `merge_style/2` — base-style + optional override (nil, binary, or list-of-binaries); nil/empty-string safe |
| `lib/mailglass/components/layout.ex` | `email_layout/1` — `<!DOCTYPE html>` + MSO `OfficeDocumentSettings` + light-only color-scheme + CSS reset |
| `lib/mailglass/components.ex` | 11 function components (preheader, container, section, row, column, heading, text, button, img, link, hr) + private helpers |
| `test/fixtures/vml_golden.html` | Golden fixture: `OfficeDocumentSettings` + ghost-table row/col + `<v:roundrect>` + `<!--[if !mso]><!-->` fallback |
| `test/mailglass/components/vml_preservation_test.exs` | 4 assertions: conditional-comment survival, v:roundrect survival, CSS inlining correctness, OfficeDocumentSettings survival |
| `test/mailglass/components/button_test.exs` | 5 assertions: v:roundrect + MSO conditionals, data-mg-plaintext=link_pair, mso-hide:all, label in both branches, href propagation |
| `test/mailglass/components/row_test.exs` | 5 assertions: ghost-table conditionals, slot rendering, ghost-td conditionals, data-mg-column marker, width:N integer handling |

## Decisions Made

- **HEEx comment-interpolation workaround** — `~H` does NOT interpolate `{...}` expressions inside `<!-- ... -->` HTML comments (verified empirically: naive templates emit literal `{@bg_color}` text). The fix: pre-build the VML / ghost-table / ghost-td conditional blocks as strings (with ordinary string interpolation), wrap with `Phoenix.HTML.raw/1`, and embed via `{@mso_open}` / `{@mso_close}` / `{@vml_block}` expressions. HEEx sees those as normal expression holes and interpolates them. Documented inline in `button/1` and `row/1` so the next author doesn't regress it. The `<a>` HTML fallback uses normal HEEx because `<!--[if !mso]><!-->` terminates the comment per HTML parser rules (HEEx respects that boundary).
- **`render_slot_to_binary/2` calls `Phoenix.Component.__render_slot__/3` directly.** The public `render_slot/2` is a macro that expands to a reference to `var!(changed, Phoenix.LiveView.Engine)` — it only works inside a `~H` block. For `button/1`'s VML branch we need the inner slot as a binary to splice into the raw MSO block, so we invoke the underlying function with `nil` as the `changed` tracker. Safe for one-shot server-rendered email where no LiveView patch-tracking is happening.
- **Button `:variant` and `:tone` are orthogonal.** `:tone` picks the brand color (glass/ink/slate); `:variant` picks how that color is applied (primary=fill, secondary=ice-tint with ink text, ghost=transparent with ink text). Both resolve to concrete hex values (`#277B96`, `#EAF6FB`, `transparent`, `#F8FBFD`, `#0D1B2A`) before reaching the VML block — classic Outlook cannot resolve brand tokens in VML attribute values.
- **Heading dispatches across four `~H` branches instead of dynamic tag names.** HEEx cannot build dynamic tag names, and using `Phoenix.HTML.raw` for the open/close tags would lose HEEx's compile-time validation of `@style` / `@rest` / `data-mg-plaintext`. Four branches with `case @level` is the cleanest option — each produces a statically-validated `<h1>`..`<h4>` template.
- **`img` `:alt` is required at compile time.** `attr :alt, :string, required: true` produces "missing required attribute \"alt\"" whenever `<.img>` is used without it — under `--warnings-as-errors` that's a hard failure. Verified via an `eval_string` fixture during implementation (warning fires as expected). The accessibility floor cannot be bypassed by omission.
- **Kept `img_no_alt_test.exs` `@moduletag :skip`.** The compile-time check is verified by the `attr :alt` declaration itself — the warning fires at compile time, not at test runtime. Making the test runnable would require compiling a fixture module inside the test suite, which would FAIL the entire suite (the compile error propagates). The stub exists as documentation of the contract. Plan 06 may revisit with a different test shape (e.g., `Code.eval_string` inside a `capture_io` block that asserts the warning text).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] HEEx does not interpolate expressions inside HTML comments**

- **Found during:** Task 2b GREEN verification — first `mix test test/mailglass/components/button_test.exs` run showed 2 failures.
- **Issue:** The naive templates in the plan's action blocks embed MSO conditional comments like `<!--[if mso]><v:roundrect fillcolor={@bg_color} href={@rest[:href]}>...<![endif]-->` inside `~H`. HEEx treats everything between `<!-- -->` as literal text and does NOT interpolate `{...}` expressions. Result: the VML branch emitted the literal text `{@bg_color}` and `{@rest[:href]}` instead of resolved values, and `render_slot(@inner_block)` emitted literally — meaning `<.button>Click me</.button>` produced an uninitialized VML block with an empty `<center>{render_slot(@inner_block)}</center>`. Tests failed on "label appears in both branches" and (for column) "width attribute on ghost-td".
- **Fix:** Rewrote `row/1`, `column/1`, and `button/1` to pre-build their MSO conditional blocks as strings (with ordinary string interpolation of all runtime values and slot content), wrap with `Phoenix.HTML.raw/1`, and embed via `{@mso_open}` / `{@mso_close}` / `{@vml_block}` expressions in `~H`. Added `render_slot_to_binary/2` helper that calls `Phoenix.Component.__render_slot__/3` directly to get slot content as a binary suitable for splicing into the raw MSO block. `<a>` HTML fallback stays in normal HEEx because `<!--[if !mso]><!-->` terminates the comment per HTML parser rules.
- **Files modified:** `lib/mailglass/components.ex` (row/1, column/1, button/1, + 2 new private helpers)
- **Verification:** `mix test test/mailglass/components/` now exits 0 with 15 tests green; direct output inspection confirms `fillcolor="#277B96"`, `href="https://example.com"`, `width="300"`, and "Click me" appearing in both VML and HTML branches.
- **Committed in:** `0a273c5` (Task 2b commit — single commit captures the discovery and fix together; attempting to commit the broken template separately would have yielded a red commit on main).

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug: HEEx comment-interpolation constraint).

**Impact on plan:** Scope unchanged. The public component API (attr declarations, slot signatures, variant enums) matches the plan's `<interfaces>` spec verbatim. The internal implementation of the three VML-bearing components differs from the plan's suggested `~H` blocks — the workaround is documented inline in the code and in Decisions Made above, and is the sanctioned way to emit conditional comments with runtime-interpolated content in HEEx.

## Issues Encountered

- **Pre-existing OTLP exporter warning at test boot.** `OTLP exporter module opentelemetry_exporter not found` continues from Plans 01-04 predecessors. Not a compile warning; `--warnings-as-errors` unaffected. Adopters who want OTLP export add `{:opentelemetry_exporter, "~> 1.7"}` to their own deps.

## Self-Check

- File verification:
  - FOUND: `lib/mailglass/components/theme.ex`
  - FOUND: `lib/mailglass/components/css.ex`
  - FOUND: `lib/mailglass/components/layout.ex`
  - FOUND: `lib/mailglass/components.ex`
  - FOUND: `test/fixtures/vml_golden.html`
  - FOUND: `test/mailglass/components/vml_preservation_test.exs` (de-skipped)
  - FOUND: `test/mailglass/components/button_test.exs` (de-skipped)
  - FOUND: `test/mailglass/components/row_test.exs` (de-skipped)
- Commit verification:
  - FOUND: `721a811` (Task 1 — VML golden-fixture test)
  - FOUND: `9b91399` (Task 2a — Theme + CSS + Layout helpers)
  - FOUND: `0a273c5` (Task 2b — 11 components + tests)
- Gate verification:
  - PASSED: `mix compile --warnings-as-errors` exits 0
  - PASSED: `mix compile --no-optional-deps --warnings-as-errors` exits 0
  - PASSED: `mix test --warnings-as-errors` exits 0 (1 property + 68 tests, 0 failures, 10 skipped)
  - PASSED: `grep -q "v:roundrect" lib/mailglass/components.ex`
  - PASSED: `grep -q "data-mg-plaintext" lib/mailglass/components.ex`
  - PASSED: `grep -q "o:OfficeDocumentSettings" lib/mailglass/components/layout.ex`
  - PASSED: `<.img>` without `:alt` emits "missing required attribute \"alt\"" (verified via eval_string fixture)

## Self-Check: PASSED

## Next Phase Readiness

- **Plan 01-06 (Renderer)** can now call the 11 components via `apply(Mailglass.Components, :button, [assigns])` or embed them in adopter HEEx templates via `<Mailglass.Components.button href="...">...</Mailglass.Components.button>`. The `data-mg-plaintext` markers are in place for the custom Floki walker, and the `data-mg-*` strip pass has a clean target set (`data-mg-plaintext`, `data-mg-column`). Premailex preservation is guarded — render pipeline changes can regress the golden fixture if they break the Premailex lane.
- **Phase 3 (Outbound)** consumes rendered `Mailglass.Message` structs from Plan 06's Renderer; the components themselves are not directly called at send time.
- **Phase 5 (Admin dev preview LiveView)** will render adopter mailables through `Mailglass.Renderer` and display the HTML in an iframe; the components are client-rendered email HTML, so preview is visually accurate to actual email clients.
- **Phase 6 (Credo checks)** will add `NoTrackingOnAuthStream` scanning mailable source for open/click tracking on auth-context heuristics. Not related to component internals but nearby in the render pipeline.

---
*Phase: 01-foundation*
*Completed: 2026-04-22*
