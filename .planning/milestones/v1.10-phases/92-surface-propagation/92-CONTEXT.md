# Phase 92: Surface Propagation - Context

**Gathered:** 2026-06-12 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 92 propagates the sealed-flap identity to the repo surfaces that people
encounter before or while using the project: the root README, the repository
social preview image, and the running admin dashboard wordmark.

This phase owns SURF-01..03 only. It does not redesign the brand book, wire
HexDocs logos/favicon config, add SVG width/height attributes for ex_doc, or
harden release-please path behavior. Those remain Phase 93 work.

</domain>

<decisions>
## Implementation Decisions

### README header
- **D-01:** Add `brandbook/examples/readme-header.svg` as the first visible
  brand surface in the root `README.md`, while keeping the existing badges and
  product copy below it.
- **D-02:** Treat the header SVG as the canonical README asset. Do not create
  a new README banner, recompose the lockup, or substitute a raster export for
  the README.
- **D-03:** Preserve the README's current technical installation and product
  structure. Phase 92 is brand-surface propagation, not a README rewrite.

### Social preview PNG
- **D-04:** Export and commit only `brandbook/examples/og-card.png` from
  `brandbook/examples/og-card.svg` at 2400x1260 using the verified Playwright
  screenshot command:
  `npx playwright screenshot --viewport-size=2400,1260 "file://$PWD/brandbook/examples/og-card.svg" brandbook/examples/og-card.png`.
- **D-05:** Verify the committed PNG has 2400x1260 dimensions and stays under
  GitHub's 1 MB social-preview limit.
- **D-06:** Keep this PNG as the milestone's only binary addition. Do not add
  generated avatars, alternate social sizes, favicons, screenshots, or other
  raster collateral in Phase 92.

### GitHub upload documentation
- **D-07:** Document the manual GitHub social-preview upload path because
  there is no write API for setting the preview image.
- **D-08:** Put the durable upload instructions in `brandbook/README.md`
  alongside the export policy, and reconcile its current "PNGs are never
  committed" wording with the v1.10 exception for
  `brandbook/examples/og-card.png`.

### Admin wordmark
- **D-09:** Replace the v0.1 `mailglass_admin/priv/static/mailglass-logo.svg`
  placeholder during Phase 92 rather than deferring it. The placeholder is a
  live-text/font-dependent wordmark and explicitly says the brand book will
  supersede it.
- **D-10:** Do not copy `brandbook/assets/logo-primary.svg` verbatim into the
  admin package if it would render poorly on dark admin chrome. The admin
  surface supports both `mailglass-light` and `mailglass-dark`; the propagated
  identity must be acceptable in both.
- **D-11:** Prefer a theme-aware or monochrome/currentColor admin rendering
  strategy that follows the brand-book rule: primary lockup on light grounds,
  monochrome/currentColor or dark expression on dark grounds.
- **D-12:** Keep the admin asset path and serving contract stable unless the
  implementation proves a small component change is necessary:
  `mailglass_admin/priv/static/mailglass-logo.svg` is embedded by
  `MailglassAdmin.Controllers.Assets` and rendered by `Components.logo/1` at
  `<mount>/logo.svg`.

### Verification and scope
- **D-13:** If admin code or static assets change, run the existing
  `mailglass_admin` `mix verify.preview` gate so compile, tests, asset build,
  and `priv/static/` bundle drift are checked together.
- **D-14:** Verify README/SVG propagation with targeted checks that the README
  references `brandbook/examples/readme-header.svg` and that the header remains
  a portable outlined SVG.
- **D-15:** Keep HexDocs logo/favicon wiring, ex_doc SVG `width`/`height`
  preparation, and release hardening out of this phase. Phase 93 owns HEXD-01,
  HEXD-02, RELH-01, and RELH-02.

### the agent's Discretion
- Exact README placement details around the header and badges, as long as the
  header is the first brand signal and existing technical content remains
  intact.
- Exact wording and formatting of the GitHub Settings UI upload instructions.
- Exact implementation form for the admin theme-aware logo, as long as it
  removes the text/font placeholder and works in light and dark chrome.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` - Phase 92 goal, dependency on Phase 91, success
  criteria, and strict sequencing before Phase 93.
- `.planning/REQUIREMENTS.md` - SURF-01..03 and v1.10 scope locks, including
  the single-binary limit.
- `.planning/STATE.md` - v1.10 current position, pre-settled decisions, and
  adoption mechanics memory.
- `.planning/PROJECT.md` - v1.10 milestone intent and project-level brand
  source-of-truth context.

### Brand assets and rules
- `brandbook/brand-book.md` - active brand source of truth, surface usage
  table, logo rules, and export policy.
- `brandbook/README.md` - brand folder contents and export policy that must be
  reconciled with the committed OG PNG exception.
- `brandbook/examples/readme-header.svg` - canonical README header asset.
- `brandbook/examples/og-card.svg` - canonical source for the committed social
  preview PNG.
- `brandbook/assets/logo-primary.svg` - light-surface flagship lockup.
- `brandbook/assets/logo-monochrome.svg` - currentColor-friendly lockup for
  dark or hostile contexts.
- `.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`
  - sealed-flap winner, C-15 no broken reads, C-16 envelope-by-light-only, and
  asset usage constraints.

### Adoption mechanics
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md` - verified
  Playwright PNG export command, GitHub social-preview constraints, no write
  API finding, admin logo serving path, and release-safe commit guidance.

### Admin integration points
- `mailglass_admin/priv/static/mailglass-logo.svg` - current shipped v0.1
  placeholder to replace or rework.
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` - embeds and
  serves `mailglass-logo.svg`.
- `mailglass_admin/lib/mailglass_admin/components.ex` - `Components.logo/1`
  renders `<mount>/logo.svg`.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - renders the logo in
  light/dark operator chrome.
- `mailglass_admin/assets/css/app.css` - source admin theme tokens, including
  `mailglass-light` and `mailglass-dark`.
- `mailglass_admin/mix.exs` - `verify.preview` alias and bundle-drift gate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/examples/readme-header.svg` is already purpose-built for README
  usage: outlined paths, explicit `width`/`height`, accessible title/desc, and
  Glass/Slate fills selected for GitHub light and dark page themes.
- `brandbook/examples/og-card.svg` is the canonical 1200x630 source template;
  Phase 92 should produce the 2400x1260 PNG export from it.
- `brandbook/assets/logo-monochrome.svg` is the best reusable basis for dark or
  theme-aware admin rendering because it uses `currentColor`.
- `mailglass_admin/priv/static/mailglass-logo.svg` is already the stable admin
  asset filename served by the package; replacing its contents can preserve the
  public asset URL.

### Established Patterns
- Brand artifacts are text-first SVG/HTML/MD/CSS/JSON, with this phase's OG
  PNG as the explicit v1.10 exception.
- The admin package embeds static assets at compile time with
  `@external_resource`, so static SVG changes require normal admin verification
  rather than a separate runtime asset pipeline.
- Admin chrome has first-class light/dark theme support through
  `data-theme="mailglass-light"` and `data-theme="mailglass-dark"`.
- Release safety remains commit-type based in this milestone; use non-release
  commit types for docs/brand work and leave release-hardening implementation
  to Phase 93.

### Integration Points
- Root `README.md` top matter for the README header.
- `brandbook/README.md` export-policy and upload-instruction documentation.
- `brandbook/examples/og-card.png` as the only new binary artifact.
- `mailglass_admin/priv/static/mailglass-logo.svg` and
  `mailglass_admin/lib/mailglass_admin/components.ex` / `operator/shell.ex` if
  theme-aware rendering requires component support.
- `mailglass_admin` `mix verify.preview` for admin propagation proof.

</code_context>

<specifics>
## Specific Ideas

- If possible, preserve the admin logo URL (`logo.svg`) and swap the underlying
  identity rather than introducing a second served asset path.
- The admin logo should not rely on installed fonts; the v1.9 outlined-path
  constraint applies just as strongly to the running dashboard as it does to
  README and social surfaces.
- The brandbook export policy should name `brandbook/examples/og-card.png` as
  the one committed v1.10 exception so future agents do not treat it as a new
  general raster policy.

</specifics>

<deferred>
## Deferred Ideas

- HexDocs `logo:`/`favicon:` config for all three packages - Phase 93.
- Adding explicit SVG `width`/`height` attributes for ex_doc-wired logo assets
  - Phase 93.
- Release-please path hardening or commit-type lint for brand/planning-only
  commits - Phase 93.
- 1.6.x release aftermath reconciliation - Phase 93.

None beyond items already assigned to Phase 93.

</deferred>

---

*Phase: 92-surface-propagation*
*Context gathered: 2026-06-12*
