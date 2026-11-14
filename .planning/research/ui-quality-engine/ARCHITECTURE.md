# Fractal Storybook architecture review

Date: 2026-10-26. Planning only; no product changes, dependency changes, milestone creation, or implementation proof. Evidence is the current checkout, including the installed **phoenix_storybook 1.2.0** source. Root `CLAUDE.md` is the only project agent/convention file found outside dependency/build directories. `PRODUCT.md` and current state outrank its stale release snapshot.

## Recommendation

Extend the existing demo-hosted PhoenixStorybook into the canonical maintainer review surface. Render the **same production function components** at every useful level, driven by deterministic scenario data. Keep LiveViews responsible for loading, authorization, URL state and commands. Preserve real routed tests for those responsibilities. First prove a complete Deliveries investigation slice; expand to Inbound and Preview after that slice is useful. Do not rewrite all LiveViews before obtaining a useful story.

## Measured inventory

| Surface | Evidence and count |
|---|---|
| Dependency | `reference/demo_app/mix.exs`: `{:phoenix_storybook, "~> 1.2", only: :dev}`; lockfile resolves 1.2.0. No published sibling declares this dependency. |
| Story root | One backend/root: `reference/demo_app/dev/mailglass_demo_web/storybook.ex` → `reference/demo_app/storybook/`. Five primitive component stories plus one Foundations page; zero group/area/screen stories. |
| Variations | **35** `%Variation{}` entries: nav_link 5, nav_pill 6, stat_card 13, tenant_chip 6, theme_picker 5. **Zero** `description:` fields and zero VariationGroups. Counted from the five `*.story.exs` sources. |
| Gallery | `mailglass_admin/lib/mailglass_admin/gallery_live.ex`: **1,428 lines**, **119** specimen tuples across **32** component/composition families; each is rendered in light/dark/system, yielding **357** specimen cells. The catch-all event handler intentionally does nothing; it is a visual inventory, not proof of action semantics. |
| Gallery migration burden | **87 matching source lines** for `/gallery` or `gallery-` across `mailglass_admin/e2e/**/*.js`. This counts reference lines, **not tests**. Demo `persona-screenshots.spec.js` also asserts Gallery/Storybook asset parity. |
| Controller/presentation concentration | OperatorLive **2,678** lines (`render/1` starts 651); InboundLive **1,913** (render 503); PreviewLive **1,144** (render 304). Most lower-level Operator/Inbound/Preview modules already use `Phoenix.Component`. |
| Shared persona data | `reference/persona_spec/personas.ex`: three personas, pure `spec/0` and constants, **plus persistence `seed!/2`** in the same module. Admin compiles that directory in test only; demo compiles it in dev/test **and other environments**. Current module is not a complete pure screen-fixture source. |

Commands used: recursive story-file enumeration; regex counts of `%Variation{}` and `description:`; gallery `@specimens` tuple count; `wc -l`; source inspection of render callbacks, package allowlists, theme helpers, router and iframe selector. These are static measurements, not a browser conformance result.

## Pinned Storybook capabilities and footguns

All paths in this section are under `reference/demo_app/deps/phoenix_storybook/` and were inspected directly.

| Decision | Pinned evidence | Recommendation / tradeoff |
|---|---|---|
| Tree and manifest | `lib/phoenix_storybook.ex` generates `leaves/0`, `find_entry_by_path/1`, `load_story/1`; entries recursively support folder indices. `load_story/1` returns `{:ok, module}` or errors; dev is lazy by default. | Generate a versioned manifest in the demo's **dev** environment. Enumerate actual compiled entries and reject failed loads; do not infer routes from filenames alone or try to invoke this dev-only dependency from admin's test environment. Avoid dependency upgrade as a prerequisite. |
| Bare test URL | `router.ex` mounts `/iframe/*story`; demo mounts backend at `/dev/storybook`. `live/story/component_iframe_live.ex` accepts `variation_id`, `theme`, `color_mode`. | Sweep `/dev/storybook/iframe/primitives/nav_link?variation_id=active_light` today. Fail if expected root/state is absent; HTTP 200 alone can hide an invalid variation. Use full browser viewport against the bare iframe route to avoid explorer sidebar widths. |
| Group addressability | `current_variation/3` in both iframe and explorer uses `Enum.find(story.variations(), ...)`, not a recursive flatten. Groups render all their child variations. | A group is addressable by **group ID**; an inner child ID has no independent URL in 1.2.0. Keep individually swept scenarios as top-level variations. Manifest may describe group members for completeness, but must not fabricate independent URLs. No custom runtime flattening framework. |
| Component vs screen story | `stories/story.ex`: component stories provide function + variations; page stories are free-form; example stories are child LiveViews, support mount/events, and cannot implement `handle_params/3`. | Prefer function-component stories even for areas/screens when only states are needed. Use a tiny example harness only for local interaction; one scenario per example file if independent URLs are required. Routed navigation/filter/auth/replay proof stays in actual app tests. |
| **Theme correction** | `guides/theming.md`, `helpers/theme_helpers.ex`, `views/layout_view.ex`: `themes_strategies: [data_attribute: "theme"]` sets `data-theme` natively. Default theme strategy and separate color-mode settings use classes. | Prior `storybook-fractal/RECOMMENDATIONS.md` and the backend moduledoc incorrectly claim Storybook is class-only. Configure named `mailglass-light` / `mailglass-dark` themes with the **data attribute strategy**, then validate actual CSS/computed styles and TokenParityTest before deduplicating hardcoded light/dark wrappers. No class-to-data-theme CSS alias is needed. Do not confuse explorer chrome color mode with component theme. |
| Hook fidelity | `guides/setup.md` and `guides/sandboxing.md`: configured `js_path` should supply `window.storybook.Hooks`; Storybook owns its LiveSocket. Current backend deliberately omits `js_path`. Production `controllers/assets.ex` privately defines Hooks including `ModalFocusTrap` inside its socket bootstrap. | Static stories cannot prove hook-dependent modal/quick-view focus. Plan a small production-shared hook export plus a dev Storybook adapter. Do not load the full production socket bootstrap into Storybook or copy the focus implementation. Compare hook behavior on story and routed page before moving assertions. |
| CSS fidelity | Demo backend reuses `/dev/mail/css-<md5>` and `.mg-admin-root`; package prebuilt assets remain canonical. | Keep this existing seam. No second Tailwind design build; stories should exercise shipped CSS. If story-only utility classes are introduced, ensure they actually exist in the shipped bundle rather than masking divergence with a review-only stylesheet. |

Primary references: [Phoenix Component](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html) defines reusable assigns/slots contracts; [PhoenixStorybook theming source](https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/theming.md), [sandboxing source](https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/sandboxing.md), and [story source](https://github.com/phenixdigital/phoenix_storybook/blob/main/lib/phoenix_storybook/stories/story.ex) explain upstream mechanisms. Current online docs may describe a newer release; **the locally locked 1.2.0 source governs the capability claims above**. Versioned HexDocs/source fetches were unavailable through web browsing; no unverified newer API is assumed.

## Current rendered-fidelity defects: first delivery gate

The parent session opened the existing Storybook in an isolated demo host. It observed `/dev/storybook` redirecting to missing `/storybook/foundations`, sidebar links dropping `/dev`, and serif component text even though current admin uses Inter. Direct `/dev/storybook/foundations` and `/dev/storybook/primitives/stat_card` rendered. These are **parent-supplied browser observations**, separately corroborated by the source below; this agent did not run a browser.

1. **Mount prefix is wrong.** Pinned `router.ex` explicitly documents that `live_storybook` cannot be nested in a scope whose path differs from `/`. It stores the passed macro `path` directly as session `root_path`. The demo invokes `live_storybook("/storybook", ...)` inside `scope "/dev"`, so actual routes include `/dev` while its generated links/redirects do not. Recommended future fix: mount the full `"/dev/storybook"` from a root scope with the browser pipeline. Add direct-entry, root redirect, sidebar and bare-iframe route checks. Preserve assets under their independently configured mount.
2. **Serif is a sandbox override, not proof of missing admin CSS.** Pinned prebuilt `priv/static/css/phoenix_storybook.css` contains `.psb-sandbox{width:100%;margin:0;font-family:serif,system-ui,sans-serif}`. The admin bundle assigns Inter to `body`, which does not replace the sandbox element's explicit font declaration. Use the existing production font-role tokens at the sandbox root through a narrow review adapter/shared scope; do not duplicate the typography palette or make a second Tailwind build. Check actual loaded faces with `document.fonts`, network font URLs and computed body/display/mono roles at representative components.
3. **The startup CSS warning is not by itself a loading failure.** `phoenix_storybook.ex` tries to read `css_path` under the app's `priv/static` to compute an optional hash; an asset controller URL has no corresponding file, so `asset_hash(:css_path)` is nil. `templates/layout/root.html.heex` and `root_iframe.html.heex` still emit an inline `@import` of the configured URL in `layer(app)`. Consequently, `link[rel=stylesheet]` enumeration omits the imported admin stylesheet. Verify the imported sheet response, content digest, CSS rules and computed output. The admin URL already contains its own MD5. Suppress/resolve an optional hashing warning only after understanding it; do not replace a functioning content-addressed asset route with a divergent bundle.

**Acceptance before expanding stories:** all review navigation and deep links resolve; Storybook uses the same intended CSS bytes, fonts, tokens and hook implementation as production; light and dark are verified on the actual target; no console or asset errors are hidden. Theme configuration alone does not close this gate.

## Presentation seams and production fidelity

Use small feature-named components, not a parallel UI renderer or a universal schema-driven page engine. The desired graph is production LiveView → production page/area components → existing patterns/primitives, with Storybook calling those exact page/area components.

1. **Operator first.** Its render callback currently computes navigation paths and optional inbound availability before composing the shell, health or delivery surface, quick view, details and replay. Move environment/session/URL-derived facts into assigns prepared by the LiveView. Extract the delivery investigation area and replay presentation first; make the page component accept explicit paths, selection, filters, health/read states and action state. Preserve command correlation, review consumption, action-time re-read and host authorization in the existing controller/service seams.
2. **Inbound second.** Follow its existing read-result and child component boundaries. Stories must distinguish current-router simulation, durable binding/history, unavailable verification facts, permission denial and replay outcomes without bypassing raw-source reveal policy. Share genuine structural patterns with Operator, but keep different replay semantics explicit.
3. **Preview third.** Rendering stays in Renderer and existing Preview behavior. Expose the view of selected scenario, editor validation, pending/old output, HTML/Text/Raw/Headers tabs and device framing as plain assigns. Preserve HTML sandboxing and deferred iframe mounting. Do not embed application discovery/render execution in fixtures or claim browser snapshots certify recipient email clients.

Phoenix `attr/3` and `slot/3` provide a familiar contract with compile-time checks. Avoid passing the whole socket as a pseudo-component API or a single giant map that hides every dependency. Also avoid splitting every wrapper into its own module: extract a boundary when it isolates a real job/state family and becomes reusable in app and stories. Explicit event names/IDs must retain production semantics; harness-only click handlers must be labelled demonstrations, never represented as command proof.

## Fixtures across packages without shipping them

Extend the existing shared-directory technique instead of creating a package or an admin→demo dependency cycle. Define pure scenario data/builders with explicit time/IDs and no Repo calls in a repository-only support directory. Compile it only in the dev/test hosts that need it. Keep optional inbound types behind the same supported boundary; core-only tests should not require the inbound package merely to inspect a fixture.

Separate three responsibilities: persona/scenario declaration → pure domain/read-model projection → optional DB materialization for seeds or routed tests. Seed materializers can keep using real changesets/services for valid persistence, and produce the same observable facts as the pure read-model fixture. Do not claim one plain map is simultaneously an Ecto persistence contract, operator projection and page assigns; use thin named adapters and parity tests at those boundaries.

Existing package `files` allowlists exclude repository `reference/`, stories and test support (`mix.exs`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs`). Preserve and verify tarball exclusion rather than relying only on comments or `Mix.env()`. No `phoenix_storybook` import in shipped `lib`; no demo path dependency in any package; no production fixture route. Existing demo production compilation of the persona module is an inventory finding, not a precedent for new fixture placement. Source-only support remains available to the repository demo; an exact-Hex consumer must not acquire a dependency on repository-private modules.

## Gallery compatibility and locked decisions

Phase 173 explicitly recorded:

> D-02: Keep `MailglassAdmin.GalleryLive` as the comprehensive, interactive inventory of shared components and relevant states.

> D-03: Do not add a shared specimen framework, mirror a second stylesheet, move Gallery coverage into the demo package, or add a dependency unless implementation proves an existing maintenance problem that cannot be solved with a focused documentation/parity check.

The owner's current direction and methodology call for a single fractal review inventory and eventual retirement of a duplicate catalogue. The next proposal should explicitly supersede **the inventory split** for future work, retaining the existing no-extra-stylesheet/no-unjustified-dependency constraints. Existing 35 primitive variations versus 119 Gallery states, duplicated persona literals and lack of production screen stories establish the maintenance problem; this is not license for a generic specimen framework.

`mailglass_admin/docs/design-system.md` documents `/dev/mail/gallery`; `router.ex` mounts it through the stable preview macro, and the module currently ships because the Hex allowlist includes `lib`. API stability docs classify exact generated route shape and LiveView/DOM internals as internal, but removing an accessible documented route still has adopter impact. **Recommend migrate and parity-check scenarios first, retire Gallery as an actively maintained inventory second, and retain the published route during an explicit deprecation decision.** Final route removal is the strategic owner decision reserved by the methodology. Do not redirect a published library route into the demo's Storybook, which adopters do not have. Do not silently leave old browser tests asserting deleted fixtures.

## Adversarial pass

| Objection / failure mode | Response and stop condition |
|---|---|
| A beautiful story diverges from the real page. | Both invoke the identical presentation component, CSS and hook implementation; keep a small actual-route parity slice. Refuse duplicated markup or story-only behavior. |
| Refactoring all pages costs more than the tests save. | Start with one Deliveries job and its patterns; stop extraction when a boundary adds no independently reviewable state or reuse. Do not use line count alone as proof of bad design. |
| “DB-free” hides invalid business data. | Validate scenario enums, identity/scope, ordered facts and linkage, then cross-check representative pure projections against real persisted projections. Authorization/replay service behavior remains integration-tested. |
| Full matrix makes the fast lane slower than e2e. | Separate complete state coverage from orthogonal environment coverage; measure the first slice, prioritize changed/risky stories and reserve broad sweeps for an appropriate existing lane. Do not promise a runtime win from isolation alone. |
| Theme simplification hides light/dark coverage. | Assert `data-theme` and representative computed token values for both themes. Test System preference separately; avoid treating Storybook's own dark sidebar as evidence. |
| Storybook becomes a parallel application. | Tiny bounded harnesses only; no database, session auth simulator, router clone or replay service substitute. Complex wiring belongs in the actual host. |
| Single inventory forces a breaking gallery deletion now. | One canonical review inventory is a maintenance policy; public-route removal is a separate compatibility decision. Migration need not break adopters to deliver value. |

## Bounded order for the rolling proposal

1. **Foundation with one vertical job:** fix the measured mount-prefix and sandbox typography defects and prove CSS/font/JS fidelity; refreshed JTBD map; scenario/manifest contract; first realistic Deliveries area plus its existing primitives; native theme strategy and shared hook fidelity proved at a bare URL; no broad page rewrite.
2. **Operator investigation:** health/list/quick-view/detail/replay state families and full-job screens; owner feedback defects fixed at their owning tier in implementation work; actual replay/auth/URL integration checks retained.
3. **Inbound investigation:** same shared patterns with inbound-specific evidence/recovery semantics; explicit account isolation, missing history and raw-source states.
4. **Preview and recipient review:** discovery/editor/output frames and built-in GET states; distinguish admin, sender and email-client theme contracts.
5. **Consolidation and upkeep:** map every old Gallery state to kept/merged/pruned Storybook state, move relevant assertions with evidence, decide published-route deprecation, calibrate advisory design review and require story curation with each future UI change.

A deliverable slice is complete when its real job has reachable states, valid fixtures, both themes, narrow/wide review, machine-checkable behavior covered, and a retained route integration check. Story count or screenshot count alone is never acceptance.
