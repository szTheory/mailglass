# Phase 92: Surface Propagation - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 9 grouped targets
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.md` | documentation / project entry | transform | existing README top block | exact |
| `brandbook/README.md` | documentation / brand policy | transform | existing Export policy section | exact |
| `brandbook/examples/og-card.png` | generated binary artifact | SVG -> PNG export | `brandbook/examples/og-card.svg` | exact |
| `brandbook/examples/readme-header.svg` | static source asset | read-only input | existing README-ready SVG | exact |
| `mailglass_admin/priv/static/mailglass-logo.svg` | static admin asset | file-I/O / embedded asset | `brandbook/assets/logo-monochrome.svg` | strong |
| `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | static asset serving | compile-time embed | existing `@logo File.read!` route | exact |
| `mailglass_admin/lib/mailglass_admin/components.ex` | shared UI component | render | existing `Components.logo/1` | exact |
| `mailglass_admin/test/mailglass_admin/bundle_test.exs` | static bundle test | assert | existing logo size budget test | exact |
| `mailglass_admin/mix.exs` | verification entrypoint | command alias | existing `verify.preview` alias | exact |

## Pattern Assignments

### `README.md` (documentation / project entry)

**Analog:** Existing README heading, tagline, badges, and product introduction.

**Current top block:**

```markdown
# Mailglass

> *Mail you can see through.*

[![CI](...)](...)
```

**Implementation pattern:** Add only a centered image block for
`brandbook/examples/readme-header.svg` before the existing H1 so it is the
first visible brand signal. Keep the H1, badges, tagline, package description,
installation, and quickstart structure intact below it.

**Verification pattern:** Source assertion with `rg` is enough:

```bash
rg 'brandbook/examples/readme-header.svg' README.md
```

---

### `brandbook/README.md` (documentation / brand policy)

**Analog:** Existing "Export policy" section.

**Current policy issue:** It says PNG exports are "never committed," but Phase
92 creates the v1.10 exception for exactly `brandbook/examples/og-card.png`.

**Implementation pattern:** Amend the policy in place. Do not create a second
policy document. The amended section should still say SVG-first, no binaries
by default, and no committed avatars/favicons/screenshots. It should name
`brandbook/examples/og-card.png` as the single committed v1.10 exception and
document the GitHub Settings > Social preview upload flow.

---

### `brandbook/examples/og-card.png` (generated binary artifact)

**Analog:** `brandbook/examples/og-card.svg`.

**Export command:**

```bash
npx playwright screenshot --viewport-size=2400,1260 "file://$PWD/brandbook/examples/og-card.svg" brandbook/examples/og-card.png
```

**Verification pattern:**

```bash
identify -format '%wx%h' brandbook/examples/og-card.png
stat -f%z brandbook/examples/og-card.png
```

Expected values: `2400x1260` and less than `1048576` bytes.

---

### `mailglass_admin/priv/static/mailglass-logo.svg` (static admin asset)

**Analog:** `brandbook/assets/logo-monochrome.svg`.

**Current problem:** The admin static file is a v0.1 placeholder using live
`<text>`, font-family fallback, and letter spacing. It explicitly says the
brand book will supersede it.

**Implementation pattern:** Replace it with outlined sealed-flap paths. Use the
monochrome/currentColor lockup as the basis rather than the light-surface
primary asset. Add deterministic `width`/`height` for the admin asset route.
Do not introduce live text, font-family, external references, or gradients.

---

### `mailglass_admin/lib/mailglass_admin/components.ex` (shared UI component)

**Analog:** Existing `Components.logo/1`.

**Current component:**

```elixir
<img src="logo.svg" alt="mailglass" class={@class} />
```

**Implementation pattern:** If the executor confirms the external SVG cannot
inherit the admin `data-theme` color through `<img>`, make the smallest
component change needed for theme safety: render the sealed-flap lockup inline
with `fill="currentColor"` and preserve the caller-supplied `class`. Keep
`aria-label="mailglass"` or equivalent accessible naming. The asset route stays
available through `Controllers.Assets` for the stable `logo.svg` URL.

---

### `mailglass_admin/test/mailglass_admin/bundle_test.exs` (static bundle test)

**Analog:** Existing `priv/static/mailglass-logo.svg` size-budget test.

**Current test:** The logo must exist and stay under 20 KB.

**Implementation pattern:** Extend the same describe block with source
assertions that the logo SVG has no `<text>` and no `font-family`, while
keeping the existing under-20KB budget.

---

### `mailglass_admin/mix.exs` (verification entrypoint)

**Analog:** Existing `verify.preview` alias.

**Relevant alias:**

```elixir
"verify.preview": [
  "compile --no-optional-deps --warnings-as-errors",
  "test --warnings-as-errors --exclude flaky",
  "mailglass_admin.assets.build",
  "cmd git diff --exit-code priv/static/"
]
```

**Implementation pattern:** Do not create a new gate. The admin plan should run
`cd mailglass_admin && mix verify.preview` after static/logo/component changes.

## Non-Patterns

- Do not add schema migrations or database push tasks; no schema-relevant files
  are in scope.
- Do not add HexDocs `logo:`/`favicon:` config, ex_doc SVG width/height work
  for shared brand assets, or release-please hardening; these are Phase 93.
- Do not add generated avatars, screenshots, favicon rasters, or alternate
  social-preview sizes.
