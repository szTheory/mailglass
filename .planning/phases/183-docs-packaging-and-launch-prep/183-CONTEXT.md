# Phase 183: Docs, Packaging and Launch Prep - Context

**Gathered:** 2026-11-16 (assumptions mode)  
**Status:** Ready for planning

<domain>
## Phase Boundary

Carry brand v2.0 through adopter-facing README and HexDocs surfaces, ship only the intended brand assets in the three Hex packages, document the design system, verify favicon legibility, and preserve the fail-closed trademark boundary. No backend feature, release, announcement, trademark claim, remote asset-tag push, or personal-avatar change is in scope.

</domain>

<decisions>
## Implementation Decisions

### README, Hex.pm and ExDoc
- **D-01:** Use two explicit light/dark lockup images with the renderer-specific `#gh-light-mode-only` and `#gh-dark-mode-only` fragments. Hex.pm strips `<picture>/<source>` and uses its own theme toggle, so an OS-based `<picture>` would render the wrong logo in dark Hex.pm. This is the evidence-backed recommendation; amend BRDOC-01's `<picture>` wording to require the correct theme-aware result across GitHub, Hex.pm and HexDocs.
- **D-02:** Pin the absolute `raw.githubusercontent.com` image URLs to the full commit SHA that introduced the pinned v2 assets, rather than creating and pushing a new `brand-v2.0` remote tag. A full SHA is strictly immutable and avoids a remote tag write outside this task's authorization. The README contract must bind the SHA and image bytes to the brand pin; the phase evidence must say the ref becomes reachable when the task-scoped commit is pushed.
- **D-03:** Keep the H1 and alt text lowercase `mailglass`; the tagline stays outside the logo. Do not ship the full `brandbook/` tree in any package.
- **D-04:** ExDoc uses the v2 `m` mark and favicon in all three packages. Custom CSS changes code colors only, uses no OS `prefers-color-scheme` query, and leaves ExDoc's Lato body face and class-driven theme toggle intact.
- **D-05:** Verify generated docs by running `mix docs` separately for core, admin and inbound, then inspect generated HTML, CSS, logo, favicon and README images. Verify each package's shipped file list and `mix mailglass.publish.check` result.

### Design guidance and name rules
- **D-06:** Keep `mailglass_admin/docs/design-system.md` as the implementation guide. Add a compact root `DESIGN.md` and `.impeccable/design.json` that cite `brandbook/v2/brand.json` and `brandbook/tokens.json`; a parity test guards the handwritten token frontmatter instead of adding a generator.
- **D-07:** Scope the current Inter font exception to `lib/mailglass/compliance/unsubscribe_html/**`, with a reason tied to the retired font in the v2 source and a tracked follow-up. Do not make the exception global.
- **D-08:** Lowercase prose claims while preserving public module/API spellings, historical changelogs, tests, pinned brand source text and explicitly approved exceptions. Test both detection and the exception boundaries.
- **D-09:** Draft CLAUDE.md and PRODUCT.md changes under `.planning/research/brand-v2-adoption/owner-signoff/`, clearly marked pending. Do not edit the canonical files before owner sign-off.

### Favicon and launch guard
- **D-10:** Add v2 favicon, avatar and social-card files through `scripts/brand_pin.exs update` and the declared extension manifest. Do not hand-edit the pin or ship v1 social-avatar assets.
- **D-11:** Capture the favicon at 16, 24 and 32 px in Chromium, Firefox and WebKit. Bind each unique capture catalog to the favicon SHA and recompute its legibility metrics from the PNG bytes in the required test. Cross-engine byte-identical goldens are not required. Treat real Safari tab-chrome behavior as unobserved; the manual checklist may mention it but it is not a deterministic acceptance gate.
- **D-12:** Write a repository-scoped GitHub social-preview upload checklist with complete URLs and a read-back check. Personal GitHub/Gravatar avatars are optional identity changes; skip them.
- **D-13:** Close Phase 179 WR-01/WR-02 before calling the announcement gate: require all named registers to be clear, reject future-dated and overlong validity windows, and disallow production `--today`/`--path` overrides. Scan public text and generated docs for trademark symbols/entities, exempting only the pinned brand JSON rule text; deny ® unconditionally and allow ™ only while the current record permits it.
- **D-14:** Keep the announcement draft under `.planning/research/brand-v2-adoption/` with an explicit blocked marker. Tests must prove the current `caution` record blocks announcement/TM text while `mix mailglass.publish.check` and code rollout remain allowed. Never make the trademark gate a prerequisite for a Hex publish job.

### Scope and plan budget
- **D-15:** The milestone has 18 completed plans and a hard cap of 20. Phase 183 gets exactly two plans; both together must cover BRDOC-01..06 without dropping evidence. If the checker cannot make two cohesive plans, stop for an owner decision rather than exceeding the cap.
- **D-16:** No social upload, tag push, package publish, release, announcement or trademark claim is authorized. The existing trademark/counsel search remains a human hand-off after the implementation is complete.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/brand.pin.json` and `scripts/brand_pin.exs` own the immutable book and extension workflow.
- `brandbook/v2/brand.json`, `brandbook/tokens.json` and `brandbook/status-marks.json` define current brand content.
- ExDoc 0.40.4 is already locked; the three package `mix.exs` files already define docs extras and custom asset hooks.
- The admin serves `priv/static/favicon.svg` through `MailglassAdmin.Controllers.Assets`; the file is currently the v2 SVG.
- Existing hermetic contract tests in `test/scripts/` provide patterns for mutation-backed source and packaging checks.

### Established Patterns
- Pin asset changes through `brand_pin.exs`; never update pin JSON by hand.
- Keep generated docs/bundles reproducible and validate them from the package's required test lane.
- Use unique evidence paths and a manifest bound to exact source bytes; don't overwrite earlier catalogs.
- Keep advisory browser re-runs separate from required deterministic tests.

### Integration Points
- Root `README.md`, `mailglass_admin/README.md`, `mailglass_inbound/README.md` and all three `mix.exs` docs configs.
- `mailglass_admin/docs/design-system.md`, root `DESIGN.md`, `.impeccable/`, and the `.impeccable` CLI config.
- Core/admin/inbound package file allowlists and `mix mailglass.publish.check`.
- `scripts/brand_trademark_gate.exs`, its tests, and the existing publish-check/report paths (without adding a publish dependency).
- `mailglass_admin/e2e/` for the favicon capture producer and `mailglass_admin/test/` for its independent evidence validator.

</code_context>

<specifics>
## Specific Ideas

- The corrected README header must remain legible in GitHub light/dark, Hex.pm light/dark, and ExDoc light/dark while using the v2 lockups.
- The social-card checklist should tell the owner exactly where to upload the repository card and how to verify that GitHub is using it.
- The announcement draft should be safe to paste only after the gate and human trademark decision allow it.
</specifics>

<deferred>
## Deferred Ideas

- Official USPTO, TMview and WIPO register searches, reverse image search and counsel review remain owner/counsel work; the current record must not be upgraded by an agent.
- Creating/pushing a remote `brand-v2.0` tag, changing personal GitHub/Gravatar avatars, uploading the social card, publishing packages, and sending an announcement remain outside this phase's authorization.
- Any remaining v1 unsubscribe-page inline CSS cleanup stays as a tracked follow-up rather than expanding this phase.
</deferred>
