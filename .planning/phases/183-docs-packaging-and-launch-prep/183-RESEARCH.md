# Phase 183: Docs, Packaging and Launch Prep — Research

**Date:** 2026-11-16  
**Scope:** BRDOC-01 through BRDOC-06. Research synthesis resumed from the interrupted Claude session; original area notes remain in `.planning/research/brand-v2-adoption/PHASE-183-{A,C,D,E}-*.md`.

## Constraints

- The v2.11 roadmap caps the milestone at 20 plans. Phases 179–182 have 18 plans complete, leaving **two plans** for this phase.
- Do not add backend features or change the email defaults. Keep the compatibility policy and package API stable.
- The trademark record remains `overall: caution`, `register_checked: false`, `owner_override: null`. Docs and code rollout may proceed; an announcement and trademark claim remain blocked.
- `CLAUDE.md` and `PRODUCT.md` are owner-controlled. Produce review drafts only; do not apply them.
- Do not publish, release, deploy, upload the social preview, or push a new remote tag as part of this phase.

## Findings and recommendations

### README rendering and immutable asset references (BRDOC-01)

The area A report verified that Hex.pm sanitizes README HTML: `<picture>` and `<source>` are removed while their children are unwrapped, leaving only the light `<img>`. Hex.pm also derives its theme from its own toggle, so a `prefers-color-scheme` picture cannot choose the matching logo there. ExDoc 0.40.4 preserves `<picture>`, but its own Light/Dark toggle does not control a picture keyed to OS preference. See the detailed live/source evidence in `PHASE-183-A-readme-hexpm.md`.

**Recommended:** use separate light and dark logo images with the established `#gh-light-mode-only` / `#gh-dark-mode-only` fragments. Hex.pm rewrites those fragments into theme classes; ExDoc's bundled CSS selects them using its toggle; GitHub currently supports the same convention. Use lowercase `mailglass` text, keep the tagline outside the logo, and use only absolute `raw.githubusercontent.com` URLs.

The roadmap currently requires a `<picture>` and a tag URL. Those exact constraints conflict with the evidence: the picture displays the wrong logo in dark Hex.pm, and creating/pushing a new remote tag is a separate external write. The zero-risk fallback is a full commit-SHA URL, supported by the existing contract design and strictly immutable. The planner must record the requirement amendment if using this functional option; no remote tag should be created or pushed in this phase.

An offline contract test can parse the three package READMEs, require two correctly ordered light/dark images, validate the pinned ref, alt text and dimensions, confirm the source bytes against `brand.pin.json`, and include mutation cases. Avoid a network test in a required lane: the pinned GitHub ref is not available until its source commit is pushed.

### ExDoc output (BRDOC-02)

All three packages already include `README.md` as an ExDoc extra. Their `mix.exs` files still point at retired v1 `brandbook/assets/logo-mark.svg` and `favicon.svg` assets. The repository pins ExDoc 0.40.4 in `mix.lock`.

Local source inspection confirms `logo` and `favicon` copy `.svg` files, `assets` copies additional files into the generated output, and `before_closing_head_tag` can insert a stylesheet link. The installed HTML stylesheet uses Lato and class-based `.dark` selectors; it does not contain `prefers-color-scheme`. Add a small custom stylesheet for code colors only, with no OS dark-mode media query, and preserve the built-in Lato body font and ExDoc's own theme toggle. Point each package at the v2 mark and favicon. Verify by running `mix docs` in all three package roots and inspecting generated HTML/CSS/assets.

Primary reference: [ExDoc repository and documentation](https://github.com/elixir-lang/ex_doc); pinned implementation: `deps/ex_doc/lib/ex_doc/formatter.ex`, `deps/ex_doc/lib/ex_doc/formatter/html.ex`, `deps/ex_doc/lib/ex_doc/formatter/config.ex`, and `deps/ex_doc/formatters/html/dist/html-elixir-RXHHCTJW.css`.

### Design system, `.impeccable`, and owner drafts (BRDOC-03)

Area C found that `brandbook/v2/brand.json` and `brandbook/tokens.json` are the current authorities; root `brandbook/brand-book.md` is retired v1 material. Keep the package's `mailglass_admin/docs/design-system.md` as the implementation guide. Add a concise root `DESIGN.md` and `.impeccable/design.json` to serve design tooling, with a parity test against the pinned token source rather than a token generator. Scope the existing Inter exception to the unsubscribe template's remaining inline CSS and give the exception a tracked follow-up.

Write CLAUDE.md and PRODUCT.md changes under `.planning/research/brand-v2-adoption/owner-signoff/` with an explicit pending status. Do not modify the canonical files or place sign-off material under a phase archive path.

### Name lint and package allowlists (BRDOC-04)

Area D inventories adopter-facing `Mailglass` spellings and the package allowlists. Enforce lowercase prose while preserving public Elixir module names, required API spellings, changelog history, tests and pinned brand-book source text. Update each package's explicit file list only for the shipped v2 brand assets and their OFL texts; do not ship the full `brandbook/` directory or planning artifacts. Add mutation-backed tests for the lint and assert the actual package contents with `mix mailglass.publish.check` for each package.

### Favicon and social upload checklist (BRDOC-05)

The shipped v2 brand zip contains the favicon variants, 512px avatars and a 1280×640 PNG social card; the repo's currently tracked `brandbook/v2/` directory does not yet contain those files. Add assets only through `scripts/brand_pin.exs update` and the declared extension manifest. Keep the admin SVG route and add an offline favicon capture producer plus a required manifest/metric validator; capture at 16, 24 and 32 px in Chromium, Firefox and WebKit, in light and dark. Do not use byte-for-byte cross-engine screenshot goldens. Bind captures to the favicon SHA and recompute legibility from PNG bytes. An advisory browser re-run can be path-filtered to the favicon input.

Write a repository-scoped GitHub social preview upload checklist with full URLs and a machine-readable read-back step. Do not change the owner's personal GitHub or Gravatar avatar; that is optional and unrelated to the repository's brand surface.

### Trademark gate and announcement boundary (BRDOC-06)

Close Phase 179 warnings WR-01/WR-02 before depending on the gate: an `overall: clear` decision must require clear results from all required registers; future-dated records, excessive validity windows, and production CLI overrides must fail closed. Widen the claim scan to adopter-facing text and generated docs, including symbols/entities; keep ® denied unconditionally and allow ™ only when the current search record allows it. Preserve the explicit exclusion for the hash-pinned brand JSON rule text.

Add a blocked announcement draft and tests that prove the gate blocks announcements/trademark claims while allowing the code and package checks to pass. Never make the trademark gate a dependency of Hex publish jobs. Current record denies the announcement, which is the expected result; the required owner/counsel search remains a later manual hand-off.

## Suggested two-plan shape

1. **Published docs and package contracts:** README headers, ExDoc branding/CSS and favicon, lowercase-name lint, Hex asset allowlists, all-three-package docs and publish checks (BRDOC-01, 02, 04).
2. **Design and launch guardrails:** design-system and `.impeccable` artifacts, pending owner drafts, favicon capture/validation and social checklist, hardened trademark gate plus blocked announcement contract (BRDOC-03, 05, 06).

This is a planning constraint, not a reason to weaken acceptance criteria. If the checker cannot produce two coherent plans without losing required evidence, stop for an owner decision rather than exceeding the 20-plan cap.
