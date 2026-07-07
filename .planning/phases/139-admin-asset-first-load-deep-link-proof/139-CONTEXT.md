# Phase 139: Admin asset first-load/deep-link proof - Context

**Gathered:** 2026-07-07 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove admin CSS/font asset URLs are mount-aware on first HTML load and hard refresh, including deep links and alternate mount roots, without redesigning the admin UI or adding public router options. The phase delivers AAU-01, AAU-02, AAU-03, AAU-04, and GATE-03 only: first-HTML stylesheet href assertions, direct browser CSS/font network proof, alternate mount proof, and token-backed computed-style assertions.

Out of scope for this phase: admin redesign, brand/token/component/layout/motion changes, screenshot or pixel-diff baselines, CDN/host asset pipeline changes, duplicate asset routes, `<base>` tags, redirects as the primary fix, public router macro options, and documentation/backlog reconciliation reserved for Phase 140.
</domain>

<decisions>
## Implementation Decisions

### Mount-Aware Asset Strategy
- **D-01:** Preserve the current computed mount-root asset URL path through `MailglassAdmin.MountPathHook` -> `MailglassAdmin.MountPath.base/1` -> `MailglassAdmin.Layouts.css_url/1`; Phase 139 may harden narrow edge cases found by proof, but must not replace the strategy with a new public router/config contract.
- **D-02:** Continue serving admin assets from the existing macro-scoped asset routes (`/css-:md5`, `/js-:md5`, `/fonts/:name`, `/logo.svg`) under each admin mount path. Do not add duplicate nested asset routes, CDN/host assets, `<base>`, or canonicalizing redirects unless implementation proves the current mount-aware strategy cannot satisfy AAU-01..04.

### Route Matrix Proof
- **D-03:** Expand fast Conn/LiveView first-HTML assertions across the required route matrix: preview index, preview scenario, preview render-error route, gallery, operator, inbound, query deep links, and arbitrary alternate mount roots.
- **D-04:** Prove alternate mount roots by reusing the existing router macros in test-only synthetic routes or endpoint/router support. Do not expose a new public router macro option for asset roots.
- **D-05:** The first-HTML checks must assert rooted stylesheet `href`s under the effective mount path and reject bare relative `css-...` hrefs.

### Browser Gate
- **D-06:** Add a targeted Playwright asset-loading proof that performs direct `page.goto` loads and fails on CSS/font request failures, non-200 responses, or unexpected content types.
- **D-07:** The browser proof must assert token-backed computed styles after direct loads so structurally rendered but unstyled HTML cannot pass.
- **D-08:** Keep the browser proof screenshot-free and pixel-diff-free. Network behavior plus computed styles are the required evidence.

### Claude's Discretion
The maintainer confirmed the assumption set with "sure." Planner/implementer may choose exact test file placement, helper names, route matrix factoring, and whether the browser checks live in a new focused spec or an existing Playwright spec, as long as the proof remains focused and satisfies D-03..D-08 without widening public surface.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` - Active v2.1 phase scope, Phase 139 goal, success criteria, and explicit preservation of the current `MountPathHook`/`MountPath`/layout strategy.
- `.planning/REQUIREMENTS.md` - AAU-01..04 and GATE-03 acceptance requirements; exclusions for pixel diffs and broad UI work.
- `.planning/PROJECT.md` - Milestone-level locked decisions and scope locks for v2.1.
- `.planning/backlog/admin-relative-asset-url-styling.md` - Origin of the admin relative-asset issue, selected approach A, rejected alternatives B-D, and acceptance notes.

### Current Asset Implementation
- `mailglass_admin/lib/mailglass_admin/mount_path.ex` - Mount-base recovery for preview scenario/error, gallery, inbound, and alternate mount paths.
- `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex` - LiveView lifecycle hook that assigns `:mount_path` and admin chrome theme from request URI/query/cookie data.
- `mailglass_admin/lib/mailglass_admin/layouts.ex` - `css_url/1`, mount-aware asset URL construction, and legacy `@conn` fallback.
- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` - Root layout stylesheet emission.
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` - Embedded CSS/JS/logo/font serving, cache headers, content types, font allowlist.
- `mailglass_admin/lib/mailglass_admin/router.ex` - Public preview/operator router macros and internal asset/theme route emission.
- `mailglass_admin/assets/css/app.css` - Self-hosted font `url('./fonts/...')` behavior that relies on the CSS URL being rooted at the mount path.

### Existing Verification Harness
- `mailglass_admin/test/support/endpoint_case.ex` - Synthetic adopter router/endpoint, browser support routes, preview and operator macro mounts.
- `mailglass_admin/test/mailglass_admin/mount_path_test.exs` - Pure `MountPath.base/1` coverage for route-shape stripping.
- `mailglass_admin/test/mailglass_admin/assets_test.exs` - Asset controller content-type/cache/font allowlist coverage.
- `mailglass_admin/test/mailglass_admin/router_test.exs` - Router macro route emission and root-layout theme behavior.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` - Current first-HTML stylesheet assertion and preview scenario link assertions.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Operator LiveView/root layout patterns and authenticated test setup.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - Inbound LiveView/root layout patterns and inbound query/deep-link setup.
- `mailglass_admin/playwright.config.cjs` - Serialized browser gate server config.
- `mailglass_admin/test/support/operator_browser_server.ex` - Browser server bootstrap, DB setup, and fixture seeding for Playwright.
- `mailglass_admin/e2e/structural.spec.js` - Existing Playwright helpers and `getComputedStyle` patterns.
- `mailglass_admin/e2e/operator.spec.js` - Existing operator browser login/navigation helpers.
- `mailglass_admin/e2e/gallery-matrix.spec.js` - Existing direct gallery browser route coverage patterns.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassAdmin.MountPath.base/1`: already handles index, preview mailable/scenario, preview `__error__`, gallery, inbound, single-segment mounts, and arbitrary multi-segment mounts.
- `MailglassAdmin.MountPathHook`: attaches a `:handle_params` hook and assigns `:mount_path` from the parsed request URI, which is the load-bearing value available to LiveView root layouts.
- `MailglassAdmin.Layouts.css_url/1`: joins `css-<hash>.css` to the socket `:mount_path`; this is the center of the first-HTML proof.
- `MailglassAdmin.Controllers.Assets`: already serves CSS and fonts with stable content types, immutable caching, and an allowlisted font set.
- `MailglassAdmin.TestAdopter.Router` and `MailglassAdmin.TestAdopter.Endpoint`: can be extended with test-only alternate preview/operator mounts without changing public macros.
- Existing Playwright support: `playwright.config.cjs`, `OperatorBrowserServer.run!/0`, and helper patterns in `structural.spec.js`/`operator.spec.js` can host a focused browser network/computed-style gate.

### Established Patterns
- Router macros emit asset routes inside the adopter-selected mount `scope`, preserving mount-path portability without adopter endpoint edits.
- Tests prefer focused, fail-closed assertions over broad rewrites: Conn/LiveView for generated HTML shape, Playwright for browser-only network/computed-style behavior.
- Admin browser gates are serialized (`--workers=1`) because fixture reset endpoints and seeded DB state are shared.
- The project deliberately avoids screenshot/pixel-diff visual proof for this milestone; computed CSS token values are the honest signal.

### Integration Points
- First-HTML assertions should connect to the root layout rendered through LiveView routes, not only isolated component rendering.
- Browser network assertions should monitor stylesheet and font requests during direct `page.goto` loads to preview/operator/inbound/gallery URLs.
- Alternate mount proof should exercise the same `mailglass_admin_routes/2` and `mailglass_operator_routes/2` macro paths with different test-only prefixes, ensuring the public API remains unchanged.
</code_context>

<specifics>
## Specific Ideas

- Use the current `MountPathHook`/`MountPath`/layout `css_url` mechanism as the default; this is an implementation proof phase, not an architecture redesign.
- Browser proof should inspect network responses for `/css-...` and `/fonts/...` and check computed styles tied to mailglass tokens, such as font family, foreground/background color, border/focus token values, or theme-driven root styling.
- Keep the route matrix explicit enough that future regressions show which surface failed: preview index, preview scenario, preview error, gallery, operator, inbound, query deep link, alternate preview mount, and alternate operator/inbound mount.
</specifics>

<deferred>
## Deferred Ideas

- Phase 140 owns documentation/backlog reconciliation after the proof passes, including `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, and the relative-asset backlog item.
- Broader UI verification discipline remains future work outside v2.1.
- CDN/host asset pipelines, duplicate nested asset routes, `<base>` tags, redirects, and public router macro options remain rejected as primary fixes unless Phase 139 proves the narrower strategy cannot work.
</deferred>

---

*Phase: 139-admin-asset-first-load-deep-link-proof*
*Context gathered: 2026-07-07*
