---
phase: 92
slug: surface-propagation
status: complete
researched: 2026-06-13
---

# Phase 92 Research — Surface Propagation

## RESEARCH COMPLETE

Phase 92 is a narrow propagation phase. The implementation should modify only
the root README, the brandbook social-preview documentation/export artifact,
and the existing admin logo surface needed for SURF-01..03. HexDocs logo
wiring, ex_doc SVG sizing, release-please hardening, and 1.6.x release
aftermath remain Phase 93 scope.

## Phase Scope

| Requirement | What must be planned | Explicit non-goals |
|---|---|---|
| SURF-01 | Add `brandbook/examples/readme-header.svg` as the first visible root README brand surface. | Do not rewrite README product/install sections or create a new banner asset. |
| SURF-02 | Export and commit `brandbook/examples/og-card.png` from `brandbook/examples/og-card.svg` at 2400x1260, under 1 MB, and document GitHub Settings upload. | Do not add avatars, alternate sizes, screenshots, favicons, or other binary collateral. |
| SURF-03 | Replace the shipped admin placeholder `mailglass_admin/priv/static/mailglass-logo.svg` with the sealed-flap identity and verify the admin bundle gate. | Do not restyle the admin UI beyond the wordmark surface unless a small component change is needed to make the logo theme-safe. |

## Findings

### README header

- `README.md` currently starts with a Markdown H1, tagline, and badges. It
  has no brand image yet.
- `brandbook/examples/readme-header.svg` is already purpose-built for this
  surface: it has `width="580"`, `height="192"`, accessible title/desc,
  outlined paths only, and fixed Glass/Slate fills selected for GitHub light
  and dark themes.
- The plan should place an image reference before the badge block so the SVG is
  the first visible brand signal while keeping existing technical copy intact.

Recommended README insertion:

```markdown
<p align="center">
  <img src="brandbook/examples/readme-header.svg" alt="mailglass — Email, made visible." width="580">
</p>
```

Using HTML is acceptable here because GitHub Markdown renders centered images
reliably and keeps the existing badge Markdown below it.

### Social preview PNG

- `brandbook/examples/og-card.svg` is the canonical source template with
  `viewBox="0 0 1200 630"` and Paper/Ink/Glass/Slate fills. It has no
  intrinsic `width`/`height`, so a Playwright page screenshot uses the viewport
  as the exported dimensions.
- Playwright is available locally: `npx playwright --version` reports `1.60.0`.
- The verified export command remains:

```bash
npx playwright screenshot --viewport-size=2400,1260 "file://$PWD/brandbook/examples/og-card.svg" brandbook/examples/og-card.png
```

- GitHub's current docs still specify PNG/JPG/GIF under 1 MB, with 1280x640
  recommended for best display. A 2400x1260 export exceeds that display floor
  while preserving the brandbook's locked 1200x630 source aspect.
- GitHub's docs still route social-preview changes through repository
  Settings > Social preview. No official write endpoint is documented. Treat
  upload as a manual Settings UI step, not an automatable `gh api` task.
- `brandbook/README.md` currently says PNG exports are never committed. Phase
  92 must reconcile that with the explicit v1.10 exception for exactly
  `brandbook/examples/og-card.png`.

### Admin wordmark

- `mailglass_admin/priv/static/mailglass-logo.svg` is still the v0.1
  placeholder. It uses live `<text>`, font-family fallback, letter spacing, and
  an inline comment saying the brand book will supersede it.
- The file is embedded at compile time by
  `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` and served as
  `<mount>/logo.svg`.
- `mailglass_admin/lib/mailglass_admin/components.ex` renders it as
  `<img src="logo.svg" alt="mailglass" class={@class} />`.
- The operator shell uses `<Components.logo class="h-6 w-auto" />` in both the
  sidebar and mobile header. The chrome supports `mailglass-light` and
  `mailglass-dark`.
- `brandbook/assets/logo-primary.svg` is the flagship light-surface lockup but
  would render poorly on dark chrome because its Ink paths disappear.
- `brandbook/assets/logo-monochrome.svg` is the safest implementation basis for
  the admin surface because it uses outlined paths with `currentColor`. As an
  external SVG loaded through `<img>`, `currentColor` will not inherit the host
  DOM text color. The plan should therefore either:
  - replace the admin SVG with a deterministic single-color asset using a
    fallback `color="#0D1B2A"` only if the admin chrome never needs dark logo
    contrast, or
  - make a small component/CSS change so the served logo can be colorized
    correctly in light and dark chrome.

Best plan direction: keep the public `logo.svg` URL stable, replace the static
SVG with an outlined monochrome sealed-flap lockup, and update the admin logo
rendering only as much as needed to make light/dark contrast verifiable. The
executor should read the current `Components.logo/1`, operator shell, and
theme CSS before deciding whether an inline SVG component or CSS mask is the
least invasive theme-aware strategy.

### Verification commands

- README/SVG checks should be source-level and portable:
  - `README.md` references `brandbook/examples/readme-header.svg`.
  - `brandbook/examples/readme-header.svg` has no `<text`, no `font-family`,
    and no external `href=` / `url(` references.
- PNG checks should use dimensions and size:
  - `identify -format '%wx%h' brandbook/examples/og-card.png` prints
    `2400x1260`.
  - `stat -f%z brandbook/examples/og-card.png` is less than `1048576`.
- Admin checks:
  - `mailglass_admin/priv/static/mailglass-logo.svg` has no `<text` or
    `font-family`.
  - The file contains sealed-flap path geometry or is generated from
    `brandbook/assets/logo-monochrome.svg` semantics.
  - Run `mix verify.preview` from `mailglass_admin` after admin static/code
    changes, because the package has a bundle-clean gate.

## Existing Patterns

| New/changed file | Closest local pattern | Notes |
|---|---|---|
| `README.md` | Existing README top block | Keep badges and product copy, add only the brand image above them. |
| `brandbook/README.md` | Existing export policy section | Amend the policy rather than adding a separate policy source. |
| `brandbook/examples/og-card.png` | `brandbook/examples/og-card.svg` | PNG is generated output, but this phase explicitly commits it as the only binary. |
| `mailglass_admin/priv/static/mailglass-logo.svg` | `brandbook/assets/logo-monochrome.svg` | Use outlined paths/no live text; preserve the served asset path. |
| `mailglass_admin/lib/mailglass_admin/components.ex` | Existing `Components.logo/1` | Modify only if needed for theme-safe rendering. |
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` | Existing light/dark shell classes | Read before touching; it owns the logo's rendered contexts. |
| `mailglass_admin/assets/css/app.css` | Existing `mailglass-light` / `mailglass-dark` tokens | Add only minimal logo color/mask CSS if the chosen implementation requires it. |

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| README becomes a marketing rewrite instead of a propagation edit. | Plan a source-only insertion of the canonical SVG above existing badges; no product-copy edits except mechanical spacing if required. |
| PNG export adds more binary collateral than allowed. | Plan only `brandbook/examples/og-card.png`; verify `git diff --name-only --diff-filter=A` has no other binary additions. |
| GitHub preview upload is implied to be automated. | Document Settings UI upload steps and state that no write API is available; do not plan `gh api` automation. |
| Admin logo disappears on dark chrome. | Prefer a theme-aware monochrome strategy and require light/dark operator-shell verification. |
| Admin asset change leaves stale bundle output. | Run `cd mailglass_admin && mix verify.preview`; require bundle-clean gate to pass. |
| Phase drifts into HexDocs or release hardening. | Put HexDocs/ex_doc/release-please references in plan `out_of_scope` or `must_haves` so the executor does not pick them up. |

## Validation Architecture

This phase is validation-light but not validation-free. The plan should use
source assertions, file metadata checks, and the existing admin preview gate.

Required validation matrix:

| Surface | Automated proof |
|---|---|
| README | `rg 'brandbook/examples/readme-header.svg' README.md` and `rg '<text|font-family|url\\(|href=' brandbook/examples/readme-header.svg` returns no prohibited matches except accessibility title/desc markup where expected. |
| OG PNG | Playwright export command exits 0, `identify` reports `2400x1260`, and `stat -f%z` is below `1048576`. |
| Brandbook docs | `brandbook/README.md` names the single committed PNG exception and Settings > Social preview upload path. |
| Admin wordmark | Static SVG contains no live text/font dependency, the sealed-flap identity is present, and `cd mailglass_admin && mix verify.preview` exits 0. |

Manual validation remains limited to the actual GitHub Settings upload because
GitHub exposes this as a web UI action, not a documented write API.

## Sources

- `.planning/phases/92-surface-propagation/92-CONTEXT.md`
- `.planning/phases/92-surface-propagation/92-UI-SPEC.md`
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `README.md`
- `brandbook/README.md`
- `brandbook/brand-book.md`
- `brandbook/examples/readme-header.svg`
- `brandbook/examples/og-card.svg`
- `brandbook/assets/logo-primary.svg`
- `brandbook/assets/logo-monochrome.svg`
- `mailglass_admin/priv/static/mailglass-logo.svg`
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`
- `mailglass_admin/lib/mailglass_admin/components.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/assets/css/app.css`
- GitHub Docs: Customizing your repository's social media preview, checked 2026-06-13.
