# Phase 139: Admin asset first-load/deep-link proof - Research

**Researched:** 2026-07-07
**Domain:** Phoenix LiveView mounted admin asset URLs, first HTML render, and Playwright browser asset proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md` [VERIFIED: codebase grep]

### Locked Decisions

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

### the agent's Discretion

The maintainer confirmed the assumption set with "sure." Planner/implementer may choose exact test file placement, helper names, route matrix factoring, and whether the browser checks live in a new focused spec or an existing Playwright spec, as long as the proof remains focused and satisfies D-03..D-08 without widening public surface.

### Deferred Ideas (OUT OF SCOPE)

- Phase 140 owns documentation/backlog reconciliation after the proof passes, including `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, and the relative-asset backlog item.
- Broader UI verification discipline remains future work outside v2.1.
- CDN/host asset pipelines, duplicate nested asset routes, `<base>` tags, redirects, and public router macro options remain rejected as primary fixes unless Phase 139 proves the narrower strategy cannot work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AAU-01 | First HTML for preview, preview scenario, preview error, gallery, operator, inbound, and query deep-link routes emits a stylesheet `href` rooted at the current admin mount path, never a bare relative path. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use ConnTest `get/2` full-document assertions across the route matrix; parse the root layout link with Floki or strict regex and reject `href="css-...` and nested-path hrefs. [VERIFIED: `mailglass_admin/test/mailglass_admin/preview_live_test.exs`] |
| AAU-02 | Hard refreshes and direct deep links for those routes load CSS and font assets with 200 responses and expected content types; nested routes do not request assets relative to their own path. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use direct Playwright `page.goto` and collect stylesheet/font `response` events by `request.resourceType()`; Playwright docs say HTTP 404s do not emit `requestfailed`, so status/content-type checks are mandatory. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed] [CITED: https://playwright.dev/docs/api/class-request#request-resource-type] |
| AAU-03 | The same asset proof passes for an arbitrary alternate mount path without adding public router macro options. [VERIFIED: `.planning/REQUIREMENTS.md`] | Extend the synthetic test router with alternate macro mounts and unique `live_session_name` values; LiveView rejects duplicate `live_session` names in one router. [VERIFIED: `mailglass_admin/test/support/endpoint_case.ex`] [VERIFIED: `mailglass_admin/deps/phoenix_live_view/lib/phoenix_live_view/router.ex`] |
| AAU-04 | A browser gate fails on CSS/font 404s and asserts token-backed computed styling after direct `page.goto` loads. [VERIFIED: `.planning/REQUIREMENTS.md`] | Reuse existing Playwright `getComputedStyle`/contrast helper patterns and add asset network assertions before/after direct navigations. [VERIFIED: `mailglass_admin/e2e/structural.spec.js`] [CITED: https://playwright.dev/docs/api/class-locator#locator-evaluate] |
| GATE-03 | Admin URL robustness has both fast LiveView/Conn-level assertions for generated hrefs and a serialized browser proof for network/computed-style behavior. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep fast ExUnit href checks separate from a focused serialized Playwright spec under `mailglass_admin/e2e`; current Playwright config and npm script already run with `--workers=1`. [VERIFIED: `mailglass_admin/playwright.config.cjs`] [VERIFIED: `mailglass_admin/package.json`] |
</phase_requirements>

## Summary

Phase 139 should be planned as a proof-hardening phase, not an asset architecture rewrite. The codebase already has the intended path: router macros emit asset routes inside each adopter mount, `MountPathHook` assigns `:mount_path`, `MountPath.base/1` strips LiveView-specific trailing segments, and `Layouts.css_url/1` joins `css-<hash>.css` under the mount path. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`] [VERIFIED: `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex`] [VERIFIED: `mailglass_admin/lib/mailglass_admin/mount_path.ex`] [VERIFIED: `mailglass_admin/lib/mailglass_admin/layouts.ex`]

The main planning risk is false confidence from structural browser tests. Playwright treats HTTP 404 responses as successful network completions, so `page.on("requestfailed")` alone cannot catch missing stylesheets/fonts. The browser gate must collect both failed requests and stylesheet/font responses, assert 200-level status and expected content types, and then assert a token-backed computed style after a direct `page.goto`. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed] [CITED: https://playwright.dev/docs/api/class-response] [VERIFIED: `mailglass_admin/e2e/structural.spec.js`]

**Primary recommendation:** preserve the existing `MountPathHook` -> `MountPath.base/1` -> `Layouts.css_url/1` implementation path, add explicit first-HTML href matrix tests, add test-only alternate macro mounts with unique live session names, and add a focused Playwright asset network/computed-style spec. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]

## Project Constraints (from CLAUDE.md)

- Keep the package/adopter contract no-Node: Node/Playwright are acceptable for dev/CI browser evidence only; do not add a shipped Node asset pipeline. [VERIFIED: `CLAUDE.md`] [VERIFIED: `mix.exs`]
- Do not redesign the admin UI, change brand tokens, component behavior, layout, motion, or screenshots for this phase. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]
- Do not write to `mailglass_admin/priv/static/` without committing a rebuilt bundle; this phase should not need CSS changes, but any accidental bundle change must be verified by `mix mailglass_admin.assets.build` and `git diff --exit-code priv/static/`. [VERIFIED: `CLAUDE.md`] [VERIFIED: `mailglass_admin/mix.exs`]
- Do not add public router macro options unless the phase proves the current mount-aware path cannot satisfy AAU-01..04. [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]
- Preserve operator auth/session boundaries; preview and operator/inbound routes live in separate LiveView sessions with distinct auth behavior. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`] [VERIFIED: `mailglass_admin/test/support/endpoint_case.ex`]
- No AGENTS.md file exists in the repo root; project-specific instructions came from `CLAUDE.md`. [VERIFIED: `rg --files -g 'AGENTS.md' -g 'CLAUDE.md'`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mount-aware stylesheet href generation | Frontend Server / SSR | API / Backend | The first HTML root layout is rendered by Phoenix LiveView over HTTP, and `Layouts.css_url/1` owns the emitted `<link>` href. [VERIFIED: `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`] |
| Effective mount-base recovery | Frontend Server / SSR | Browser / Client | `MountPathHook` receives the request URI in `handle_params` and assigns `:mount_path`; the browser only consumes the resulting absolute href. [VERIFIED: `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex`] |
| Asset bytes, content type, and cache headers | API / Backend | CDN / Static | `MailglassAdmin.Controllers.Assets` serves embedded CSS, JS, logo, and allowlisted font files under macro-scoped routes. [VERIFIED: `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`] |
| First-HTML href proof | Test / Frontend Server | Browser / Client | ConnTest catches generated HTML without launching a browser; it is the fast gate for AAU-01. [VERIFIED: `mailglass_admin/test/mailglass_admin/preview_live_test.exs`] |
| Hard-refresh/deep-link asset proof | Browser / Client | API / Backend | Only a browser resolves the stylesheet href, evaluates CSS `url('./fonts/...')`, requests fonts, and exposes computed styling after `page.goto`. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function] [CITED: https://playwright.dev/docs/api/class-page#page-goto] |
| Alternate mount proof | Frontend Server / SSR | Test Support | Synthetic router support can mount the same public macros at alternate prefixes without exposing new macro options. [VERIFIED: `mailglass_admin/test/support/endpoint_case.ex`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 / Mix 1.19.5 on OTP 28 | Compile and run ExUnit/Phoenix tests | Installed locally and used by all package aliases. [VERIFIED: `mix --version`] |
| Phoenix | `~> 1.8`, locked `1.8.8` in `mailglass_admin/mix.lock`; latest observed `1.8.9` | Router, controller, endpoint, root layout pipeline | Existing admin package dependency; no upgrade needed for this phase. [VERIFIED: `mailglass_admin/mix.exs`] [VERIFIED: `mix hex.info phoenix`] |
| Phoenix LiveView | `~> 1.1`, locked `1.1.28` in `mailglass_admin/mix.lock`; latest observed `1.2.6` | Live routes, `live_session`, `on_mount`, initial disconnected render | Existing route/session mechanism; plan against the locked admin package behavior, not only latest docs. [VERIFIED: `mailglass_admin/mix.exs`] [VERIFIED: `mix hex.info phoenix_live_view`] |
| Plug | `~> 1.18`, locked `1.20.2` in `mailglass_admin/mix.lock` | Conn/session/test routing and controller responses | Existing HTTP substrate for asset routes and ConnTest. [VERIFIED: `mailglass_admin/mix.lock`] |
| Floki | `~> 0.38`, locked `0.38.4` | HTML parsing in ExUnit tests | Existing dependency; use it for stylesheet link extraction instead of fragile broad string checks where practical. [VERIFIED: `mailglass_admin/mix.exs`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `@playwright/test` | locked `1.59.1`; latest observed `1.61.1` | Direct browser navigation, network response capture, computed style assertions | Use for AAU-02/AAU-04 browser proof; keep existing version unless a separate dependency phase upgrades it. [VERIFIED: `mailglass_admin/package-lock.json`] [VERIFIED: `npm view @playwright/test@1.59.1`] [WARNING: existing package flagged SUS by package-legitimacy seam; do not newly install or upgrade in this phase.] |
| Playwright managed Chromium | `chromium-1217` cached locally | Browser runtime for e2e specs | Use the managed browser path; local `/opt/homebrew/bin/chromium` shim is broken. [VERIFIED: `node -e "require('playwright').chromium.executablePath()"`] |
| Tailwind Mix task | existing `mix mailglass_admin.assets.build` | Rebuild committed CSS bundle if CSS changes | Phase should not edit CSS; run only if implementation touches CSS/static output. [VERIFIED: `mailglass_admin/package.json`] [VERIFIED: `mailglass_admin/mix.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Mount-aware `css_url/1` | `<base href>` | Rejected by phase context; can affect all relative URLs including LiveView/socket and font URL semantics. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`] |
| Macro-scoped asset routes | Duplicate nested asset routes | Rejected by phase context; masks wrong hrefs instead of proving correct mount-root URLs. [VERIFIED: `.planning/backlog/admin-relative-asset-url-styling.md`] |
| Playwright network + computed style | Screenshot or pixel-diff baseline | Explicitly out of scope; existing milestone wants screenshot-free proof. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Floki/ConnTest href checks | Browser-only checks | Browser-only checks are slower and can hide first-HTML regression localization; use both fast HTML and browser proof. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Installation:**
```bash
# No new package installation is recommended for Phase 139.
# Existing verification commands:
cd mailglass_admin
MIX_ENV=test mix test test/mailglass_admin/preview_live_test.exs:73 --warnings-as-errors
npm run test:operator-browser -- --grep "admin asset"
```

**Version verification performed:**
```bash
cd mailglass_admin
mix hex.info phoenix_live_view
mix hex.info phoenix
mix hex.info plug
npm view @playwright/test@1.59.1 version time.modified repository.url scripts.postinstall --json
npx playwright --version
```

## Package Legitimacy Audit

No new external package install should be planned for Phase 139. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Existing locked dev dependency; package modified 2026-07-07 | 42,534,093/week from legitimacy seam | `github.com/microsoft/playwright` | SUS by seam due `too-new` | Existing only; do not add install/upgrade task without human verification. [WARNING: flagged as suspicious by seam; package is already locked in repo.] |
| `@axe-core/playwright` | npm | Existing locked dev dependency; package modified 2026-06-30 | 5,130,370/week from legitimacy seam | `github.com/dequelabs/axe-core-npm` | SUS by seam due `too-new` | Not needed for this phase; no new install. [WARNING: flagged as suspicious by seam; package is already locked in repo.] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** `@playwright/test`, `@axe-core/playwright` by recency heuristic only; no installation is recommended. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
Direct HTTP GET / page.goto(route)
  |
  v
Synthetic adopter router scopes
  |-- /dev/mail -> mailglass_admin_routes("/mail")
  |-- /ops/mail -> mailglass_operator_routes("/mail")
  |-- alternate test-only root -> same public macros with unique live_session_name
  |
  v
LiveView initial disconnected render
  |
  v
MountPathHook.handle_params(uri)
  |
  v
MountPath.base(path)
  |-- preview scenario/error -> strip mailable + scenario/__error__
  |-- gallery/inbound -> strip gallery/inbound segment
  |-- mount root/query links -> keep mount root
  |
  v
Layouts.root.html.heex
  |
  v
<link rel="stylesheet" href="/effective/mount/css-<hash>.css">
  |
  v
Browser fetches stylesheet
  |
  v
CSS @font-face url('./fonts/*.woff2') resolves relative to stylesheet URL
  |
  v
/effective/mount/fonts/*.woff2 asset routes
  |
  v
Computed token-backed styling visible after direct load
```

### Recommended Project Structure

```text
mailglass_admin/
├── test/support/endpoint_case.ex                 # add alternate test-only macro mounts if needed
├── test/mailglass_admin/admin_asset_url_test.exs # recommended focused Conn/LiveView href matrix
├── e2e/admin-assets.spec.js                      # recommended focused Playwright network/style proof
└── package.json                                  # existing serialized browser gate command
```

### Pattern 1: First-HTML Stylesheet Matrix

**What:** Assert the root-layout `<link rel="stylesheet">` href for every required direct URL. [VERIFIED: `.planning/REQUIREMENTS.md`]

**When to use:** Use ConnTest for AAU-01 before browser proof, because it localizes href-generation regressions quickly. [VERIFIED: `mailglass_admin/test/mailglass_admin/preview_live_test.exs`]

**Example:**
```elixir
# Source: existing preview_live_test pattern + Floki dependency in mailglass_admin/mix.exs
defp stylesheet_href!(html) do
  {:ok, doc} = Floki.parse_document(html)

  doc
  |> Floki.find(~s(link[rel="stylesheet"]))
  |> Floki.attribute("href")
  |> List.first()
end

for {path, mount_root} <- [
      {"/dev/mail", "/dev/mail"},
      {"/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default", "/dev/mail"},
      {"/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__", "/dev/mail"},
      {"/dev/mail/gallery", "/dev/mail"},
      {"/ops/mail?tenant_id=test-tenant", "/ops/mail"},
      {"/ops/mail/inbound?tenant_id=test-tenant", "/ops/mail"}
    ] do
  html = conn |> maybe_operator_session(path) |> get(path) |> html_response(200)
  href = stylesheet_href!(html)

  assert href =~ ~r|^#{Regex.escape(mount_root)}/css-[0-9a-f]+$|
  refute String.starts_with?(href, "css-")
  refute String.contains?(href, "/inbound/css-")
  refute String.contains?(href, "/gallery/css-")
end
```

### Pattern 2: Alternate Mounts Reuse Existing Macros

**What:** Add synthetic test routes that call `mailglass_admin_routes/2` and `mailglass_operator_routes/2` at arbitrary alternate prefixes. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]

**When to use:** Use for AAU-03 without introducing public asset-root options. [VERIFIED: `.planning/REQUIREMENTS.md`]

**Example:**
```elixir
# Source: MailglassAdmin.TestAdopter.Router and Phoenix.LiveView.Router live_session duplicate-name guard
scope "/alt/dev" do
  pipe_through(:browser)

  mailglass_admin_routes("/console",
    live_session_name: :mailglass_admin_preview_alt,
    mailables: [
      :"Elixir.MailglassAdmin.Fixtures.HappyMailer",
      :"Elixir.MailglassAdmin.Fixtures.StubMailer",
      :"Elixir.MailglassAdmin.Fixtures.BrokenMailer"
    ]
  )
end

scope "/secure" do
  pipe_through(:browser)

  mailglass_operator_routes("/console",
    live_session_name: :mailglass_admin_operator_alt,
    auth: MailglassAdmin.TestOperatorAuth,
    session: [
      subject_id: "current_user_id",
      tenant_id: "tenant_id",
      auth_method: "auth_method",
      recent_auth_at: "recent_auth_at"
    ],
    unauthorized_path: "/login",
    inbound_router: MailglassAdmin.TestSupport.InboundTestRouter
  )
end
```

### Pattern 3: Browser Asset Network and Style Gate

**What:** Use direct `page.goto` routes, capture stylesheet/font failures and responses, assert status/content type, then assert computed style. [CITED: https://playwright.dev/docs/api/class-page#page-on-response] [CITED: https://playwright.dev/docs/api/class-request#request-resource-type]

**When to use:** Use for AAU-02 and AAU-04 because browser URL resolution and font requests are not visible to ConnTest. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function]

**Example:**
```javascript
// Source: Playwright docs + existing structural.spec.js computed-style helpers
async function assertAdminAssetsLoad(page, path, expectedMount) {
  const assetEvents = [];

  page.on("requestfailed", request => {
    const type = request.resourceType();
    if (type === "stylesheet" || type === "font") {
      assetEvents.push({
        kind: "failed",
        type,
        url: request.url(),
        error: request.failure()?.errorText
      });
    }
  });

  page.on("response", async response => {
    const request = response.request();
    const type = request.resourceType();
    if (type !== "stylesheet" && type !== "font") return;

    assetEvents.push({
      kind: "response",
      type,
      url: response.url(),
      status: response.status(),
      contentType: await response.headerValue("content-type")
    });
  });

  await page.goto(path);
  await expect(page.locator("body")).toBeVisible();

  const failures = assetEvents.filter(event => event.kind === "failed");
  expect(failures, `${path} stylesheet/font network failures`).toEqual([]);

  const badResponses = assetEvents.filter(event =>
    event.kind === "response" &&
    (event.status !== 200 ||
      (event.type === "stylesheet" && !String(event.contentType).includes("text/css")) ||
      (event.type === "font" && !String(event.contentType).includes("font/woff2")) ||
      !new URL(event.url).pathname.startsWith(`${expectedMount}/`))
  );
  expect(badResponses, `${path} bad stylesheet/font responses`).toEqual([]);

  const style = await page.locator("body").evaluate(el => {
    const computed = getComputedStyle(el);
    return {
      fontFamily: computed.fontFamily,
      color: computed.color,
      backgroundColor: computed.backgroundColor
    };
  });

  expect(style.fontFamily).toContain("Inter");
  expect(style.color).not.toBe("rgb(0, 0, 0)");
  expect(style.backgroundColor).not.toBe("rgba(0, 0, 0, 0)");
}
```

### Anti-Patterns to Avoid

- **Using only `requestfailed`:** Playwright treats HTTP 404 as a response, not a failed request, so CSS/font 404s can pass unless `response` status is checked. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed]
- **Testing only in-app navigation:** Live navigation keeps the existing root layout/head; this phase is about direct first loads and hard refreshes. [CITED: https://phoenix-live-view.hexdocs.pm/live-layouts.html]
- **Adding `<base>`:** Rejected by phase context and can change every relative URL, including CSS/font and LiveView-related references. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]
- **Adding duplicate nested asset routes:** Rejected by phase context and hides the wrong generated href. [VERIFIED: `.planning/backlog/admin-relative-asset-url-styling.md`]
- **Changing CSS tokens/components to make computed-style checks easier:** UI changes are out of scope; assert existing token-backed styles. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `mailglass_admin/assets/css/app.css`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML link extraction | Ad hoc substring parsing across all cases | Floki or a narrow existing regex | Floki is already a dependency and avoids false positives from escaped attributes or unrelated text. [VERIFIED: `mailglass_admin/mix.exs`] |
| Browser URL resolution simulation | Custom URL concatenation logic | Real browser `page.goto` plus network events | Browser behavior for document-relative hrefs and CSS `url()` is the thing under test. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/URL/URL] |
| CSS/font failure detection | Only `page.on("requestfailed")` | `requestfailed` plus `response.status()`/content-type checks | HTTP error statuses do not trigger Playwright request failures. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed] |
| Alternate mount behavior | New public asset root option | Test-only synthetic macro mounts | Existing macros already scope asset routes under the caller path. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`] |
| Font route security | Dynamic filesystem path handling | Existing `Controllers.Assets` allowlist | The controller already rejects non-allowlisted font names and serves `font/woff2`. [VERIFIED: `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`] |

**Key insight:** the bug class is not "CSS bytes missing"; it is "the first HTML document points the browser at the wrong URL." The plan should prove the generated href and then prove browser resolution from that href. [VERIFIED: `.planning/backlog/admin-relative-asset-url-styling.md`] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function]

## Common Pitfalls

### Pitfall 1: Relative Hrefs Depend on the Document URL
**What goes wrong:** `href="css-<hash>"` resolves differently for `/ops/mail`, `/ops/mail/`, `/ops/mail/inbound`, and deep preview scenario paths. [VERIFIED: `.planning/backlog/admin-relative-asset-url-styling.md`]
**Why it happens:** URL resolution uses the base URL directory up to the last slash, not string concatenation. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/URL/URL]
**How to avoid:** Assert the stylesheet href starts with the effective mount root for every direct URL. [VERIFIED: `.planning/REQUIREMENTS.md`]
**Warning signs:** A generated href lacks a leading `/` or includes nested LiveView segments before `css-`. [VERIFIED: `mailglass_admin/test/mailglass_admin/preview_live_test.exs`]

### Pitfall 2: CSS 404s Do Not Trigger `requestfailed`
**What goes wrong:** A Playwright test that listens only for failed requests can pass while CSS/font URLs return 404. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed]
**Why it happens:** Playwright defines HTTP error responses as completed responses from the network standpoint. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed]
**How to avoid:** Collect stylesheet/font responses and assert status/content type. [CITED: https://playwright.dev/docs/api/class-response]
**Warning signs:** The test has `page.on("requestfailed")` but never inspects `response.status()`. [VERIFIED: codebase grep]

### Pitfall 3: Duplicate `live_session` Names in Alternate Mounts
**What goes wrong:** Adding a second `mailglass_admin_routes/2` or `mailglass_operator_routes/2` invocation with default `live_session_name` can fail router compilation. [VERIFIED: `mailglass_admin/deps/phoenix_live_view/lib/phoenix_live_view/router.ex`]
**Why it happens:** LiveView router code rejects redefining a `live_session` name in the same router module. [VERIFIED: `mailglass_admin/deps/phoenix_live_view/lib/phoenix_live_view/router.ex`]
**How to avoid:** Pass unique existing `live_session_name:` values on test-only alternate macro mounts. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`]
**Warning signs:** Compile error mentioning redefined `live_session`. [VERIFIED: `mailglass_admin/deps/phoenix_live_view/lib/phoenix_live_view/router.ex`]

### Pitfall 4: Root Layout Head Is Not Updated by Live Navigation
**What goes wrong:** A test that starts at `/dev/mail` and then clicks to a deep route proves live navigation, not hard-refresh behavior. [CITED: https://phoenix-live-view.hexdocs.pm/live-layouts.html]
**Why it happens:** LiveView root layout content remains the same across live navigation except special title handling. [CITED: https://phoenix-live-view.hexdocs.pm/live-layouts.html]
**How to avoid:** Use direct `get/2` and direct `page.goto` for every route. [VERIFIED: `.planning/REQUIREMENTS.md`]
**Warning signs:** The only browser route loading happens after a previous page already loaded CSS. [VERIFIED: `mailglass_admin/e2e/operator.spec.js`]

### Pitfall 5: Font URL Proof Must Follow the Stylesheet URL
**What goes wrong:** Testing `/dev/mail/fonts/inter-400.woff2` directly proves the asset controller, not that CSS `url('./fonts/...')` resolves correctly. [VERIFIED: `mailglass_admin/test/mailglass_admin/assets_test.exs`]
**Why it happens:** CSS relative URLs resolve against the stylesheet URL, not the page URL. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function]
**How to avoid:** In the browser gate, capture `font` resource responses after loading a route whose stylesheet href is mount-rooted. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40font-face/src]
**Warning signs:** Font tests only call the controller path with ConnTest. [VERIFIED: `mailglass_admin/test/mailglass_admin/assets_test.exs`]

### Pitfall 6: Browser Environment Assumptions
**What goes wrong:** Planning assumes system Chromium is usable. [VERIFIED: environment probe]
**Why it happens:** `/opt/homebrew/bin/chromium` exists but points at a missing app locally. [VERIFIED: environment probe]
**How to avoid:** Use Playwright managed Chromium via existing `npx playwright install --with-deps chromium`; managed executable is present locally. [VERIFIED: environment probe] [VERIFIED: `.github/workflows/ci.yml`]
**Warning signs:** Commands invoke `chromium` directly instead of Playwright. [VERIFIED: `mailglass_admin/playwright.config.cjs`]

## Code Examples

Verified patterns from official sources and codebase:

### Route Matrix Data Shape
```elixir
# Source: .planning/REQUIREMENTS.md + mailglass_admin/test/support/endpoint_case.ex
@stylesheet_routes [
  preview_index: {"/dev/mail", "/dev/mail", :public},
  preview_query: {"/dev/mail?theme=dark", "/dev/mail", :public},
  preview_scenario:
    {"/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375&theme=dark",
     "/dev/mail", :public},
  preview_error:
    {"/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__?theme=light",
     "/dev/mail", :public},
  gallery: {"/dev/mail/gallery", "/dev/mail", :public},
  operator: {"/ops/mail?tenant_id=test-tenant", "/ops/mail", :operator},
  operator_query:
    {"/ops/mail?tenant_id=test-tenant&view=deliveries&status=failed", "/ops/mail", :operator},
  inbound:
    {"/ops/mail/inbound?tenant_id=test-tenant&provider=ses", "/ops/mail", :operator},
  alternate_preview:
    {"/alt/dev/console/MailglassAdmin.Fixtures.HappyMailer/welcome_default",
     "/alt/dev/console", :public},
  alternate_operator:
    {"/secure/console/inbound?tenant_id=test-tenant", "/secure/console", :operator}
]
```

### Browser Response Filtering
```javascript
// Source: Playwright Request.resourceType and Page.response docs
page.on("response", async response => {
  const request = response.request();
  if (!["stylesheet", "font"].includes(request.resourceType())) return;

  const contentType = await response.headerValue("content-type");
  expect(response.status(), `${request.resourceType()} ${response.url()}`).toBe(200);
  expect(contentType || "", response.url()).toMatch(
    request.resourceType() === "stylesheet" ? /text\/css/ : /font\/woff2/
  );
});
```

### Token-Backed Computed Style Assertion
```javascript
// Source: existing structural.spec.js getComputedStyle patterns
const styles = await page.getByTestId("preview-shell").evaluate(el => {
  const computed = getComputedStyle(el);
  return {
    fontFamily: computed.fontFamily,
    color: computed.color,
    backgroundColor: computed.backgroundColor
  };
});

expect(styles.fontFamily).toContain("Inter");
expect(styles.color).not.toBe("rgb(0, 0, 0)");
expect(styles.backgroundColor).not.toBe("rgba(0, 0, 0, 0)");
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bare relative stylesheet href such as `css-<md5>` | Mount-rooted href via `MountPathHook`/`MountPath.base/1`/`Layouts.css_url/1` | Active v2.1 Phase 139 scope on 2026-07-07 | Plan should prove and narrowly harden this path, not replace it. [VERIFIED: `.planning/backlog/admin-relative-asset-url-styling.md`] |
| Browser structural tests only | Network response checks plus computed style checks | Required by AAU-04/GATE-03 on 2026-07-07 | Prevents unstyled but structurally rendered HTML from passing. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Single preview first-HTML assertion | Explicit route matrix across preview/operator/inbound/gallery/error/query/alternate mounts | Required by AAU-01/AAU-03 on 2026-07-07 | Prevents one-route proof from masking deep-link regressions. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Deprecated/outdated:**
- Treating `requestfailed` as sufficient for CSS/font proof is outdated for this phase because HTTP 404s complete as responses in Playwright. [CITED: https://playwright.dev/docs/api/class-page#page-on-requestfailed]
- Treating the backlog limitation text as current product truth will become outdated after Phase 139 passes; Phase 140 owns docs/backlog reconciliation. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The planner can choose exact test filenames such as `admin_asset_url_test.exs` and `admin-assets.spec.js`. [ASSUMED] | Architecture Patterns | Low; CONTEXT grants file placement discretion, but existing naming conventions may prefer extending existing files. |
| A2 | `fontFamily` containing `Inter` is a stable enough computed-style signal for all target surfaces after fonts load. [ASSUMED] | Code Examples | Medium; if browser reports fallback stack before webfont activation, use color/background token checks or `document.fonts.ready` instead. |

## Open Questions

1. **Should the browser asset proof live in a new focused spec or an existing spec?**
   - What we know: CONTEXT allows either placement. [VERIFIED: `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md`]
   - What's unclear: Existing browser files are large, and a focused `admin-assets.spec.js` may be easier to grep and run. [VERIFIED: `npx playwright test --list`]
   - Recommendation: Use a new focused spec to keep GATE-03 legible and runnable with `--grep "admin asset"`. [ASSUMED]

2. **Which exact computed style should be the canonical token-backed assertion?**
   - What we know: existing specs already assert font weight, contrast, colors, and theme state through `getComputedStyle`. [VERIFIED: `mailglass_admin/e2e/structural.spec.js`]
   - What's unclear: Font loading can be asynchronous, so a font-family-only assertion may need `await page.evaluate(() => document.fonts.ready)`. [ASSUMED]
   - Recommendation: Assert at least one font-family signal and one color/background token signal; wait for `document.fonts.ready` before font assertions. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | ExUnit route matrix | yes | Elixir 1.19.5 / Mix 1.19.5 / OTP 28 | none needed. [VERIFIED: environment probe] |
| PostgreSQL | Admin test bootstrap and browser server DB | yes | `localhost:5432` accepting connections; psql 14.17 | none needed locally. [VERIFIED: `pg_isready`] |
| Node.js | Playwright browser gate | yes | 22.14.0 | none needed. [VERIFIED: environment probe] |
| npm | Playwright dependencies/script | yes | 11.1.0 | none needed. [VERIFIED: environment probe] |
| Playwright test runner | Browser gate | yes | 1.59.1 | `npm ci` from `mailglass_admin/package-lock.json`. [VERIFIED: `npx playwright --version`] |
| Playwright managed Chromium | Browser gate runtime | yes | cached `chromium-1217` | `npx playwright install --with-deps chromium`. [VERIFIED: environment probe] |
| System Chromium | Not required | no | shim points to missing app | Use Playwright managed Chromium. [VERIFIED: environment probe] |

**Missing dependencies with no fallback:** none for planning. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- System `chromium` binary is broken locally; Playwright managed Chromium is available and is what CI installs. [VERIFIED: environment probe] [VERIFIED: `.github/workflows/ci.yml`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix; Playwright Test 1.59.1 for browser proof. [VERIFIED: `mailglass_admin/mix.exs`] [VERIFIED: `mailglass_admin/package-lock.json`] |
| Config file | `mailglass_admin/playwright.config.cjs` for browser; Mix aliases in `mailglass_admin/mix.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs --warnings-as-errors` after new test file exists. [ASSUMED] |
| Existing baseline command | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/preview_live_test.exs:73 --warnings-as-errors` passed locally. [VERIFIED: command run] |
| Browser focused command | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset"` after focused spec exists. [ASSUMED] |
| Full suite command | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`. [VERIFIED: `mailglass_admin/mix.exs`] [VERIFIED: `mailglass_admin/package.json`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| AAU-01 | First HTML stylesheet href rooted at current mount path for required route matrix | ExUnit ConnTest | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs --warnings-as-errors` | no, Wave 0. [ASSUMED] |
| AAU-02 | Direct hard loads request CSS/fonts at mount-root URLs with 200 and expected content types | Playwright e2e | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset"` | no, Wave 0. [ASSUMED] |
| AAU-03 | Same href/network/style proof works under alternate mount roots | ExUnit + Playwright | Same focused commands after alternate routes are added | no, Wave 0. [ASSUMED] |
| AAU-04 | Browser gate fails on CSS/font 404s and proves token-backed computed styles | Playwright e2e | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset"` | no, Wave 0. [ASSUMED] |
| GATE-03 | Fast href assertions and serialized browser proof both exist | ExUnit + Playwright | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` | partial; existing one-route href test and browser harness exist. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** run the focused ExUnit file and focused Playwright grep once both exist. [ASSUMED]
- **Per wave merge:** run `cd mailglass_admin && mix verify.preview`; run focused Playwright asset grep. [VERIFIED: `mailglass_admin/mix.exs`] [ASSUMED]
- **Phase gate:** run `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`, or at minimum focused browser proof if full browser gate is too slow locally and CI owns the full gate. [VERIFIED: `mailglass_admin/package.json`] [ASSUMED]

### Wave 0 Gaps

- [ ] `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` - focused first-HTML route matrix for AAU-01/AAU-03. [ASSUMED]
- [ ] `mailglass_admin/test/support/endpoint_case.ex` - alternate test-only preview/operator mounts with unique `live_session_name` values. [VERIFIED: existing file]
- [ ] `mailglass_admin/e2e/admin-assets.spec.js` - focused direct-load network/computed-style proof for AAU-02/AAU-04. [ASSUMED]
- [ ] Optional helper extraction inside the new spec only; no shared browser helper module exists today. [VERIFIED: `mailglass_admin/e2e/flows.spec.js`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes for operator/inbound routes | Preserve existing `MailglassAdmin.Operator.Mount` and test operator auth; do not bypass auth in alternate operator mounts. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`] |
| V3 Session Management | yes for test login/session routes | Use existing browser login/reset support and session whitelist; do not pass whole Plug sessions. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`] [VERIFIED: `mailglass_admin/test/support/endpoint_case.ex`] |
| V4 Access Control | yes | Alternate operator mount must use `mailglass_operator_routes/2` with the same auth/session controls. [VERIFIED: `mailglass_admin/test/support/endpoint_case.ex`] |
| V5 Input Validation | yes | Route/query inputs are exercised as URLs; asset font names remain allowlisted in `Controllers.Assets`. [VERIFIED: `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`] |
| V6 Cryptography | no direct change | Do not alter CSRF/session crypto; root layout continues to emit existing CSRF meta tag. [VERIFIED: `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`] |

### Known Threat Patterns for Phoenix LiveView Admin Asset Proof

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated access via alternate operator mount | Elevation of privilege | Mount alternate operator proof through `mailglass_operator_routes/2` with existing auth/session options. [VERIFIED: `mailglass_admin/lib/mailglass_admin/router.ex`] |
| Font path traversal | Tampering / Information disclosure | Keep existing font allowlist and assert only expected `/fonts/*.woff2` routes are requested. [VERIFIED: `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`] |
| External/protocol asset URL injection | Information disclosure | Assert generated stylesheet hrefs are root-relative under expected mount roots, not external URLs. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Unstyled admin as availability/integrity failure | Denial of service / Tampering | Browser gate fails on CSS/font non-200, bad content type, or absent token-backed computed styles. [VERIFIED: `.planning/REQUIREMENTS.md`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md` - locked phase decisions, discretion, deferred scope. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - AAU-01..04 and GATE-03 acceptance criteria. [VERIFIED: codebase grep]
- `mailglass_admin/lib/mailglass_admin/mount_path.ex` - route-shape stripping rules. [VERIFIED: codebase grep]
- `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex` - `:mount_path` assignment via `handle_params`. [VERIFIED: codebase grep]
- `mailglass_admin/lib/mailglass_admin/layouts.ex` and `layouts/root.html.heex` - stylesheet href generation. [VERIFIED: codebase grep]
- `mailglass_admin/lib/mailglass_admin/router.ex` - macro-scoped asset routes and LiveView sessions. [VERIFIED: codebase grep]
- `mailglass_admin/test/support/endpoint_case.ex` - synthetic adopter router and browser support routes. [VERIFIED: codebase grep]
- `mailglass_admin/playwright.config.cjs` and `mailglass_admin/package.json` - serialized browser gate. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- https://playwright.dev/docs/api/class-page - `page.goto`, `requestfailed`, `response` behavior. [CITED: https://playwright.dev/docs/api/class-page]
- https://playwright.dev/docs/api/class-request - `request.resourceType()`. [CITED: https://playwright.dev/docs/api/class-request]
- https://playwright.dev/docs/api/class-response - response status/header APIs. [CITED: https://playwright.dev/docs/api/class-response]
- https://playwright.dev/docs/api/class-locator - `locator.evaluate`. [CITED: https://playwright.dev/docs/api/class-locator]
- https://developer.mozilla.org/en-US/docs/Web/API/URL/URL - relative URL base resolution. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/URL/URL]
- https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function - CSS `url()` relative-to-stylesheet behavior. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function]
- https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40font-face/src - `@font-face src` URL behavior. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40font-face/src]
- https://phoenix-live-view.hexdocs.pm/live-layouts.html - root layout initial render and live-navigation behavior. [CITED: https://phoenix-live-view.hexdocs.pm/live-layouts.html]
- https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#on_mount/1 - `on_mount` lifecycle hook. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#on_mount/1]

### Tertiary (LOW confidence)
- Filename recommendations and exact computed-style signal choice are marked `[ASSUMED]` because CONTEXT leaves placement/helpers to planner discretion. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `mix.exs`, lockfiles, package-lock, registry commands, and local version probes. [VERIFIED: command run]
- Architecture: HIGH - verified from local source and phase context. [VERIFIED: codebase grep]
- Pitfalls: HIGH for URL/Playwright/Phoenix behavior from official docs plus local tests; MEDIUM for exact computed-style signal choice. [CITED: https://playwright.dev/docs/api/class-page] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/url_function] [CITED: https://phoenix-live-view.hexdocs.pm/live-layouts.html] [ASSUMED]

**Research date:** 2026-07-07
**Valid until:** 2026-08-06 for codebase-local plan shape; re-check Playwright/Phoenix docs before dependency upgrades. [ASSUMED]
