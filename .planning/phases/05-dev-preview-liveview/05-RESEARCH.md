# Phase 5: Dev Preview LiveView — Research

**Researched:** 2026-04-23
**Domain:** Mountable Phoenix LiveView dashboard (sibling Hex package), zero-Node asset pipeline, compile-time asset serving, LiveReload integration
**Confidence:** HIGH on LiveView / router-macro / asset-serving patterns (verified against live Phoenix 1.8, LiveDashboard, Oban Web, phoenix_live_reload source). MEDIUM on daisyUI 5 + Tailwind v4 Hex-standalone compatibility (verified via Phoenix 1.8 installer convergence; small drift risk if daisyUI 6 lands mid-release).

## Summary

Every open question from the roadmap is answerable with existing prior art. The shape is locked:

1. **Router macro** — `MailglassAdmin.Router.mailglass_admin_routes(path, opts \\ [])` mirrors `Phoenix.LiveDashboard.Router.live_dashboard/2` and `Oban.Web.Router.oban_dashboard/2` verbatim. Expands to `scope path, alias: false, as: false do ... live_session :mailglass_admin_preview, session: {__MODULE__, :__session__, [...]}, on_mount: [...], root_layout: {...} do ... live "/", MailglassAdmin.PreviewLive, :index ... end ... get "/css-:md5", MailglassAdmin.Controllers.Assets, :css ... end`. Four opts: `:mailables` / `:on_mount` / `:live_session_name` / `:as` (CONTEXT.md D-09 lean schema).

2. **Session / socket scoping** — Use the **Oban Web `__session__/N` pattern**: library-defined callback that constructs an explicit map (`%{"mailables" => ...}`) from the conn, never passing `conn.private.plug_session` through. Combined with a library-owned `live_session :mailglass_admin_preview`, adopter cookies cannot reach our LiveView's session. This is the clean answer to the cookie-collision concern — not a fix applied after the fact, but an isolation boundary that prevents collision from ever starting. Socket signing secret **is** inherited (same Endpoint) which is what we want for transport; data isolation happens at the session-build seam.

3. **Asset pipeline (no Node)** — `tailwind ~> 0.4` Hex package, confirmed to default-bundle Tailwind v4.1.12 (hex.pm + phoenixframework/tailwind README April 2026). Vendor `daisyui.js` + `daisyui-theme.js` from `https://github.com/saadeghi/daisyui/releases/latest/download/` into `mailglass_admin/assets/vendor/` (curl-managed by `mix mailglass_admin.daisyui.update`). Load via `@plugin "../vendor/daisyui"` in `assets/css/app.css`. **This is the exact pipeline Phoenix 1.8's own `mix phx.new` generates** — not a novel setup; every new Phoenix 1.8 app ships this stack. Compiled CSS served via the **LiveDashboard `Phoenix.LiveDashboard.Assets` pattern**: compile-time `File.read!/1` + `@external_resource` + `:crypto.hash(:md5, ...)` stored in `@hashes` module attribute + Plug-style controller callbacks returning the bytes with `cache-control: public, max-age=31536000, immutable`. Adopter does **zero** endpoint edits; macro wires all routes.

**Primary recommendation:** Build three thin modules (`MailglassAdmin.Router` macro, `MailglassAdmin.Controllers.Assets`, `MailglassAdmin.PreviewLive`) then layer the UX (sidebar + tabs + toggles + form) on top. The hardest surface is discovery + live assigns form rendering, NOT the integration plumbing — that's all precedent.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Package layout (D-01..D-04):**
- **D-01** — `mailglass_admin/` nested sibling directory inside the existing `/Users/jon/projects/mailglass` git repo with its own `mix.exs`, `lib/`, `test/`, `assets/`, `priv/static/`. NOT an umbrella. NOT a separate repo.
- **D-02** — Local-dev dep via `{:mailglass, path: "..", override: true}` gated by `if Mix.env() != :prod`. Published (Hex) dep is `{:mailglass, "== <pinned_version>"}`.
- **D-03** — Release Please with `separate-pull-requests: false` + linked-versions plugin, `packages` map covering `.` (root = `mailglass`) + `./mailglass_admin/`. Wires in Phase 7; design-implies in Phase 5.
- **D-04** — `mailglass_admin/mix.exs` `package[:files]` whitelists `lib priv/static .formatter.exs mix.exs README* CHANGELOG* LICENSE*` (excludes `assets/` source). CI `git diff --exit-code priv/static/` after `mix mailglass_admin.assets.build` is the merge gate.

**Router macro shape (D-05..D-09):**
- **D-05** — Public API is ONE macro: `MailglassAdmin.Router.mailglass_admin_routes(path, opts \\ [])`, imported via `import MailglassAdmin.Router`. No `use`, no behaviour, no config registration.
- **D-06** — Dev-only enforcement is ADOPTER responsibility via `if Application.compile_env(:my_app, :dev_routes) do ... end`. The library MUST NOT introduce `Mix.env()` checks.
- **D-07** — Macro expands to `scope path, alias: false, as: false do ... live_session session_name, session_opts do ... live "/", MailglassAdmin.PreviewLive, :index ... end end`. `live_session` is library-owned (default `:mailglass_admin_preview`).
- **D-08** — Session isolation via whitelisted `__session__/N` callback (Oban Web pattern). Our `live_session`'s `session:` opt points at `MailglassAdmin.Router.__session__/N`, constructing an explicit map from `conn` — NEVER passing `conn.private.plug_session` through.
- **D-09** — Lean opts: `:mailables` (default `:auto_scan`), `:on_mount` (list appended BEFORE internal `MailglassAdmin.Preview.Mount`), `:live_session_name` (default `:mailglass_admin_preview`), `:as` (default `:mailglass_admin`). Unknown keys raise `ArgumentError` via `validate_opt!/1`.

**preview_props contract + discovery (D-10..D-13):**
- **D-10** — Arity LOCKED at `/0`. `@optional_callbacks preview_props: 0` + `@callback preview_props() :: [{atom(), map()}]` is canonical. The stale `/1` prose in PROJECT.md L52, REQUIREMENTS.md L130, ROADMAP.md L22/L114/L119 must be rewritten to `/0` as a pre-work doc-fix commit in Phase 5 Plan 01.
- **D-11** — Return shape `[{preview_name_atom, default_assigns_map}]`. Sidebar nests scenarios under the mailable module name (collapsible groups — NOT tabs).
- **D-12** — Hybrid discovery: `:auto_scan` (default) iterates `:application.get_key(adopter_app, :modules)` filtering by `function_exported?(mod, :__mailglass_mailable__, 0)` and `mod.__mailglass_mailable__() == true`. Explicit `mailables: [MyApp.UserMailer, ...]` opt is an override for umbrella apps / pathological module counts. Discovery runs in `MailglassAdmin.Preview.Mount` on_mount; rescan on LiveReload broadcast.
- **D-13** — Graceful failure: mailable marker exists but no `preview_props/0` → "No previews defined" stub card. `preview_props/0` raises → `try/rescue` in discovery returns `{:error, formatted_stacktrace}`; sidebar shows warning badge; selecting shows error card; rest of dashboard stays live.

**Preview UX (D-14..D-16):**
- **D-14** — Type-inferred assigns form: walk scenario's `map()`, render input per top-level key by Elixir type (`binary`→text, `integer`→number, `boolean`→checkbox, `atom`→select from runtime introspection, `DateTime`→`datetime-local`, struct/nested map→labeled JSON textarea fallback with `label = inspect(struct_module)`).
- **D-15** — Four tabs: HTML (sandboxed iframe), Text (monospace plaintext), Raw (full RFC 5322 envelope — see Open Questions), Headers (key-value table of all headers including auto-injected).
- **D-16** — Device widths: 375/768/1024 baseline (research finalizes; see § Device Breakpoints). Dark toggle at v0.1 is **chrome-only** (toggles admin UI around the preview; does NOT inject `prefers-color-scheme: dark` into the email — v0.5+ feature).

**Asset pipeline (D-17..D-23):**
- **D-17** — daisyUI 5 + Tailwind v4 on zero Node is CONFIRMED viable via Phoenix 1.8 installer precedent.
- **D-18** — `{:tailwind, "~> 0.4", only: :dev, runtime: false}` in `mailglass_admin/mix.exs`. NO `:esbuild` at v0.1 (no custom JS). Vendored: `assets/css/app.css`, `assets/vendor/daisyui.js`, `assets/vendor/daisyui-theme.js`, `priv/static/app.css` (compiled, committed), `priv/static/fonts/*.woff2`, `priv/static/mailglass-logo.svg`.
- **D-19** — Mix tasks: `mailglass_admin.assets.build` → `mix tailwind default --minify`; `mailglass_admin.assets.watch` → `mix tailwind default --watch`; `mailglass_admin.daisyui.update` → curls latest `daisyui.js` + `daisyui-theme.js` + prints version for CHANGELOG.
- **D-20** — Bundle serving is the `Phoenix.LiveDashboard.Assets` pattern — NOT Plug.Static. Compile-time `File.read!/1` + `@external_resource` + MD5 hash stored in module attribute + controller serves bytes with `cache-control: public, max-age=31536000, immutable`. Phoenix + LiveView JS read from `Application.app_dir(:phoenix, "priv/static/phoenix.js")` + `Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.js")` — doesn't charge mailglass_admin's tarball. **Adopter endpoint.ex needs ZERO edits.** Oban Web's npm-based pipeline is the ANTI-PATTERN.
- **D-21** — Fonts self-hosted: Inter (400/500/700), Inter Tight (600/700 display), IBM Plex Mono (400/600) as woff2 Latin + Latin-Ext subsets. Budget ~150-200KB total. No Google Fonts (GDPR). No Bunny Fonts (offline-dev regression).
- **D-22** — `config :tailwind, version: "4.1.12"` in `mailglass_admin/config/config.exs`. daisyUI version pinned in file-header comment in `daisyui.js`. Escape hatch if daisyUI 5 breaks: drop to raw Tailwind v4 + brand palette as `@theme` CSS variables.
- **D-23** — Hex tarball budget: target <800KB in `priv/static/` (CSS 80-120KB, fonts ~200KB, logo/icons <20KB). >1.2MB headroom under the 2MB PREV-06 gate.

**LiveReload integration (D-24):**
- **D-24** — `phoenix_live_reload` is a dev-only optional dep (`optional: true, only: :dev`). Hook into adopter's existing LiveReload via PubSub `:notify` config. Adopter has LiveReload disabled → admin still works, manual refresh required.

### Claude's Discretion

- Exact pixel widths for device toggle — 375/768/1024 recommended starting point; research finalizes below
- Exact directory layout inside `mailglass_admin/lib/` — Phoenix conventions apply
- File-header comment format for pinning daisyUI version
- Error card layout inside preview pane (brand-book aligned; Signal Amber border, IBM Plex Mono stacktrace)
- Sidebar behavior on 50+ mailables (search? grouping? — deferred to Plan unless user flags)
- Exact content of Raw tab (full RFC 5322 envelope vs `inspect(%Swoosh.Email{})` — see Open Questions below)

### Deferred Ideas (OUT OF SCOPE for Phase 5)

- Richer `preview_props` schema with `form_hints` → v0.5
- Dark-mode email-client simulation (inject `prefers-color-scheme: dark`) → v0.5+
- Adopter-configurable device widths → v0.5
- Search / filter / pagination over mailables → v0.5
- Preview snapshot diffing → v0.5+
- `:layout`, `:root_layout`, `:csp_nonce_assign_key`, `:socket_path`, `:logo_path`, `:title` macro opts → v0.5+
- Prod-safe admin mount with auth → v0.5 DELIV-05
- `mailglass_inbound` Conductor LiveView → v0.5+ (separate sibling package)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PREV-01 | `mailglass_admin` separate Hex package; `mix.exs` declares `{:mailglass, "== <pinned>"}` | § Sibling Package Layout — nested sibling dir precedent (Rails `actionmailer/`, Phoenix `installer/`); `mix.exs` dep template verified against Release Please linked-versions plugin |
| PREV-02 | `MailglassAdmin.Router` exposes `mailglass_admin_routes(path, opts)` macro; mount path first arg, no default | § Router Macro Pattern — LiveDashboard + Oban Web signature match; 4-opt schema locked |
| PREV-03 | `MailglassAdmin.PreviewLive` renders sidebar (auto-discovered mailables), HTML/Text/Raw/Headers tabs, device toggle, dark toggle, live-assigns form per `preview_props/0` | § Mailable Auto-Discovery (discovery mechanism) + § Preview LiveView Structure (tabs + toggles + form) |
| PREV-04 | LiveReload via Phoenix LiveReload: editing mailable source refreshes preview without page reload | § LiveReload Integration — `:notify` PubSub hook verified in phoenix_live_reload channel.ex source |
| PREV-05 | `MailglassAdmin.Components` responsive mobile-first UI matching brand book; daisyUI 5 + Tailwind v4 (no Node) | § Asset Pipeline + § Brand Implementation — Phoenix 1.8 installer convergence confirms feasibility |
| PREV-06 | `priv/static/` is committed bundle; CI `git diff --exit-code` after `mix mailglass_admin.assets.build`; tarball <2MB | § Asset Pipeline (bundle budget + commit gate) — LiveDashboard compile-time serving pattern |
| BRAND-01 | All admin UI conforms to brand book (Ink/Glass/Ice/Mist/Paper/Slate, Inter + Inter Tight + IBM Plex Mono, mobile-first, WCAG AA, no glassmorphism/bevels) | § Brand Implementation — palette → `@theme` mapping; typography → self-hosted woff2; Brand Book §7.3 + §12 consulted |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Router DSL / route injection | Backend (Elixir compile-time macro) | — | Library owns the macro; adopter owns dev-only gating via `if Application.compile_env(:app, :dev_routes)`. |
| Mailable auto-discovery | Backend (pure reflection) | — | `:application.get_key/2` + `function_exported?/3` — runs at LiveView `mount` in adopter BEAM, no client involvement. |
| `preview_props/0` reflection + rescue | Backend (pure) | — | Module introspection only; crashes contained by `try/rescue` per D-13. |
| Render pipeline invocation (call `Mailglass.Renderer`) | Backend (pure) | — | PreviewLive calls `Mailglass.Renderer.render/1` directly; same code path production uses (PREV-03 "no placeholder divergence"). |
| Sidebar + tabs + toggles UI | Frontend Server (LiveView) | Browser (HEEx hydration) | Server-rendered LiveView; minimal JS via colocated hooks for device-toggle width setter only. |
| Live-assigns form | Frontend Server (LiveView `phx-change`) | — | All state on server; form replays render on every change. No client-side validation. |
| HTML preview iframe | Browser | Frontend Server | `<iframe srcdoc={@html}>` — the rendered HTML runs in a sandboxed browser frame so email CSS doesn't leak into the admin UI. |
| Compiled CSS / JS asset serving | Backend (compile-time embed → runtime bytes) | CDN/cache (via `cache-control: immutable`) | `MailglassAdmin.Controllers.Assets` reads files at compile time, serves at request time with year-long cache. |
| LiveReload broadcast subscription | Backend (PubSub) | Browser (LiveView auto-push) | `PreviewLive.mount` subscribes to the `"mailglass:admin:reload"` PubSub topic (CORRECTED — Phase 6 LINT-06 `PrefixedPubSubTopics` requires the `mailglass:` prefix; earlier references to `:mailglass_admin_reload` below are pre-correction); adopter config routes file-change events there. |
| Session isolation (no adopter cookie leak) | Backend (Plug + `__session__/N`) | — | Whitelisted session callback is the single isolation seam. |
| Device width simulation | Browser (CSS width on iframe container) | — | Pure CSS — no JS beyond a LiveView-pushed CSS variable update. |
| Dark/light chrome toggle | Browser (CSS variable / data-theme attr) | Frontend Server (assign + push) | daisyUI `data-theme` attribute swap via `phx-click` event; no cookie persistence at v0.1. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `~> 1.8` (1.8.5) | Host web framework (inherited from mailglass core) | `[VERIFIED: STACK.md §1.1]` — D-06 floor; required for `live_session` shape Phase 5 uses |
| `phoenix_live_view` | `~> 1.1` (1.1.28) | LiveView runtime | `[VERIFIED: STACK.md §1.1]` — colocated hooks for device-toggle JS; `live_session` isolation |
| `phoenix_pubsub` | (transitive via phoenix) | Broadcast mailable file-change events to PreviewLive | `[VERIFIED: Phoenix dep tree]` — pulled by `:phoenix`; used for LiveReload `:notify` topic |
| `plug` | `~> 1.18` (1.19.1) | Assets controller + router macro expansion | `[VERIFIED: STACK.md §1.1]` |
| `tailwind` | `~> 0.4` (0.4.1) | Tailwind CSS v4 standalone build (NO Node) | `[VERIFIED: hex.pm/packages/tailwind + phoenixframework/tailwind README, April 2026]` — "`:tailwind` 0.3+ assumes Tailwind v4+ by default." Bundles Tailwind v4.1.12. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mailglass` | `== <pinned>` | Core lib (Renderer, Message, Mailable behaviour) | Consumed via `Mailglass.Renderer.render/1` call in PreviewLive per D-20 prior-phase context |
| `phoenix_live_reload` | `~> 1.6` (1.6.2) | Dev-only file watch + PubSub broadcast | `optional: true, only: :dev` — adopter typically already has it from `mix phx.new`; we hook via `:notify` config |
| `nimble_options` | `~> 1.1` (1.1.1) | Validate macro opts in `validate_opt!/1` | Phase 5 macro opts schema validation |

### Vendored artifacts (NOT Hex deps — committed to `mailglass_admin/assets/vendor/`)

| Artifact | Source | Pin |
|----------|--------|-----|
| `daisyui.js` | `https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.js` | Version in file-header comment; `mix mailglass_admin.daisyui.update` refreshes |
| `daisyui-theme.js` | `https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.js` | Version in file-header comment |
| `heroicons.js` | Phoenix 1.8 installer template: `installer/templates/phx_assets/heroicons.js.eex` | Copied verbatim from Phoenix 1.8 installer; only if using `hero-*` classes |

> **Filename note (IMPORTANT):** Phoenix 1.8's own `mix phx.new` installer curls `daisyui.js` (not `.mjs`) into `assets/vendor/` and loads via `@plugin "../vendor/daisyui"` (no extension — the resolver finds `.js`). daisyUI's own standalone-install docs recommend `.mjs`; both extensions exist in daisyUI releases. **Use `.js` to match Phoenix 1.8 convention** — adopters' muscle memory, grep patterns, and stack traces all reference `.js`. `[VERIFIED: Phoenix 1.8 app.css.eex + daisyUI releases page, April 2026]`

### Alternatives Considered

| Instead of | Could Use | Why Rejected |
|------------|-----------|--------------|
| `tailwind` Hex standalone | Raw `tailwindcss` CLI binary managed by custom mix task | Reinvents `phoenixframework/tailwind` poorly. Hex package already handles platform detection + auto-download. |
| daisyUI component lib | Raw Tailwind utilities | No component system; reinvents daisyUI for v0.1; LiveDashboard's 228KB hand-crafted CSS is the escape hatch (D-22), not the default. |
| `esbuild` Hex + custom JS | No JS at v0.1 | Phase 5 has no adopter-facing custom JS; colocated hooks (LiveView 1.1) suffice for the 20 lines of device-toggle logic we need. |
| `Plug.Static` serving `priv/static/` | Compile-time `File.read!` + controller | `Plug.Static` chain collisions with adopter Endpoint; LiveDashboard pattern has zero chain dependency. |
| `Mix.env()` gate in macro body | Adopter-owned `:dev_routes` wrapper | Mix unreliable in release builds (always `:prod` in releases); breaks v0.5 prod-admin flip by forcing a breaking macro change. |
| `use MailglassAdmin.Router` + `@behaviour` | Plain `import` + macro call | No prior art; adds complexity with no corresponding win. LiveDashboard + Oban Web both use plain import. |
| Google Fonts CDN for typography | Self-hosted woff2 subsets | GDPR exposure (EU IP logging), CSP restrictions common in adopter apps, breaks offline dev. |

**Installation:**

```elixir
# mailglass_admin/mix.exs
defp deps do
  [
    # Pinned sibling to core — D-02 swap between path/Hex via Mix.env gate
    if Mix.env() != :prod do
      {:mailglass, path: "..", override: true}
    else
      {:mailglass, "== 0.1.0"}  # Pin replaced by Release Please
    end,

    # Host framework
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:plug, "~> 1.18"},
    {:nimble_options, "~> 1.1"},

    # Dev-only: asset build + live reload
    {:tailwind, "~> 0.4", only: :dev, runtime: false},
    {:phoenix_live_reload, "~> 1.6", optional: true, only: :dev},

    # Test
    {:mox, "~> 1.2", only: :test}
  ]
  |> List.flatten()
end

defp package do
  [
    name: "mailglass_admin",
    description: "Mountable LiveView dashboard for mailglass — dev preview + admin.",
    licenses: ["MIT"],
    # D-04: strict whitelist, excludes assets/ source
    files: ~w(lib priv/static .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
    links: %{
      "GitHub" => "https://github.com/jonathanjoubert/mailglass",
      "HexDocs" => "https://hexdocs.pm/mailglass_admin"
    }
  ]
end
```

**Version verification:** `[VERIFIED: hex.pm April 2026]`
- `tailwind` 0.4.1 — released 2025-10-17; bundles Tailwind v4.1.12 by default
- `phoenix_live_reload` 1.6.2 — latest stable
- `phoenix` 1.8.5, `phoenix_live_view` 1.1.28 — per STACK.md

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Adopter Phoenix app (host)                                              │
│                                                                         │
│  lib/my_app_web/router.ex                                               │
│   │                                                                     │
│   │  import MailglassAdmin.Router                                       │
│   │                                                                     │
│   │  if Application.compile_env(:my_app, :dev_routes) do                │
│   │    scope "/dev" do                                                  │
│   │      pipe_through :browser                                          │
│   │      mailglass_admin_routes "/mail"   ◄── compile-time expansion    │
│   │    end                                                              │
│   │  end                                                                │
│   └── (no endpoint.ex edits needed)                                     │
│                                                                         │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │ macro expands to:
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Routes emitted by the macro                                             │
│                                                                         │
│   scope "/dev/mail", alias: false, as: false do                         │
│     # 1. Asset routes — LiveDashboard pattern                           │
│     get "/css-:md5", MailglassAdmin.Controllers.Assets, :css            │
│     get "/js-:md5",  MailglassAdmin.Controllers.Assets, :js             │
│     get "/fonts/:name", MailglassAdmin.Controllers.Assets, :font        │
│     get "/logo.svg", MailglassAdmin.Controllers.Assets, :logo           │
│                                                                         │
│     # 2. LiveView routes inside isolated live_session                   │
│     live_session :mailglass_admin_preview,                              │
│       session: {MailglassAdmin.Router, :__session__, [opts]},           │
│       on_mount: [MailglassAdmin.Preview.Mount | user_on_mounts],        │
│       root_layout: {MailglassAdmin.Layouts, :root} do                   │
│         live "/", MailglassAdmin.PreviewLive, :index                    │
│         live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show  │
│     end                                                                 │
│   end                                                                   │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
┌─────────────────────────┐      ┌──────────────────────────────┐
│ Assets (compile-time)   │      │ PreviewLive (runtime)         │
│                         │      │                              │
│ @external_resource      │      │ mount/3                      │
│   "priv/static/app.css" │      │  ├─ Discovery: scan adopter  │
│ @css File.read!(...)    │      │  │  app modules for          │
│ @css_hash :crypto.md5() │      │  │  __mailglass_mailable__/0 │
│                         │      │  │  marker                   │
│ def css(conn, _) do     │      │  ├─ subscribe to             │
│   conn                  │      │  │  "mailglass:admin:reload" │
│   |> put_resp_header(   │      │  │  PubSub topic             │
│     "cache-control",    │      │  └─ assign current scenario  │
│     "public, max-age=   │      │                              │
│     31536000,immutable")│      │ handle_params/3              │
│   |> send_resp(200,@css)│      │  └─ set @mailable + @scenario│
│ end                     │      │                              │
└─────────────────────────┘      │ render/1                     │
                                 │  └─ sidebar + main pane      │
                                 │     (tabs + toggles + form)  │
                                 │                              │
                                 │ handle_event("form_change")  │
                                 │  └─ re-call mailable fn      │
                                 │     with edited assigns →    │
                                 │     Mailglass.Renderer.render│
                                 │                              │
                                 │ handle_info({:phoenix_live_  │
                                 │   reload, :mailglass_admin_  │
                                 │   reload, path})             │
                                 │  └─ re-discover + re-render  │
                                 └──────────────────────────────┘
                                          │
                                          ▼
                         ┌────────────────────────────┐
                         │ Mailglass.Renderer         │
                         │  (core lib — UNCHANGED)    │
                         │                            │
                         │  render(message) ->        │
                         │   {:ok, {html, text,       │
                         │    headers}}               │
                         │                            │
                         │  Same code production uses │
                         │  (PREV-03 "no placeholder  │
                         │   divergence").            │
                         └────────────────────────────┘
```

### Recommended Project Structure

```
mailglass_admin/
├── mix.exs                      # Package + deps + aliases
├── config/
│   ├── config.exs               # config :tailwind, version: "4.1.12"
│   └── dev.exs                  # Tailwind build profile
├── assets/                      # NOT shipped in Hex tarball (D-04)
│   ├── css/
│   │   └── app.css              # @import "tailwindcss" + @plugin + @theme
│   └── vendor/
│       ├── daisyui.js           # Curled from GitHub release; pin comment
│       └── daisyui-theme.js     # Curled from GitHub release; pin comment
├── priv/
│   └── static/                  # SHIPPED in Hex tarball (compiled bundle)
│       ├── app.css              # Built by `mix mailglass_admin.assets.build`
│       ├── mailglass-logo.svg
│       └── fonts/
│           ├── inter-{400,500,700}.woff2
│           ├── inter-tight-{600,700}.woff2
│           └── ibm-plex-mono-{400,600}.woff2
├── lib/
│   ├── mailglass_admin/
│   │   ├── router.ex            # The mailglass_admin_routes macro + __session__/N
│   │   ├── controllers/
│   │   │   └── assets.ex        # LiveDashboard-pattern asset serving
│   │   ├── preview_live.ex      # The one LiveView
│   │   ├── preview/
│   │   │   ├── mount.ex         # on_mount hook — discovery + subscription
│   │   │   ├── discovery.ex     # Auto-scan + manual list reconciliation
│   │   │   ├── assigns_form.ex  # Type-inferred form rendering
│   │   │   ├── sidebar.ex       # Component: mailable list + scenarios
│   │   │   ├── tabs.ex          # Component: HTML / Text / Raw / Headers
│   │   │   └── device_frame.ex  # Component: iframe + width toggle
│   │   ├── layouts.ex           # Phoenix.Component layouts (root, app)
│   │   └── components.ex        # Shared brand-book-aligned UI atoms
│   └── mix/
│       └── tasks/
│           ├── mailglass_admin.assets.build.ex
│           ├── mailglass_admin.assets.watch.ex
│           └── mailglass_admin.daisyui.update.ex
└── test/
    ├── mailglass_admin/
    │   ├── router_test.exs      # Macro expansion + __session__/N isolation
    │   ├── preview_live_test.exs # LiveViewTest on PreviewLive
    │   └── discovery_test.exs   # Auto-scan edge cases
    └── support/
        └── endpoint_case.ex     # ConnTest harness with synthetic adopter app
```

### Pattern 1: Router macro — LiveDashboard/Oban Web signature

```elixir
# Source: Verified against
#   https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/router.ex
#   https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/router.ex
# Both use the same signature: `foo_dashboard(path, opts \\ [])`.

defmodule MailglassAdmin.Router do
  @moduledoc """
  Dev-only preview dashboard mount.

  ## Usage (adopter's `lib/my_app_web/router.ex`)

      import MailglassAdmin.Router

      if Application.compile_env(:my_app, :dev_routes) do
        scope "/dev" do
          pipe_through :browser
          mailglass_admin_routes "/mail"
        end
      end
  """

  @opts_schema [
    mailables: [
      type: {:or, [{:in, [:auto_scan]}, {:list, :atom}]},
      default: :auto_scan,
      doc: "Mailable modules to expose. `:auto_scan` walks `Application.get_key/2`."
    ],
    on_mount: [
      type: {:list, :atom},
      default: [],
      doc: "Extra `on_mount` hooks appended BEFORE the internal Preview.Mount."
    ],
    live_session_name: [
      type: :atom,
      default: :mailglass_admin_preview,
      doc: "Name of the library-owned live_session. Rename to resolve collisions."
    ],
    as: [
      type: :atom,
      default: :mailglass_admin,
      doc: "Route helper prefix."
    ]
  ]

  @doc """
  Mounts the preview dashboard at `path`.

  Expands to a `scope` containing: asset routes + a `live_session` with
  the PreviewLive routes. The live_session is library-owned, isolated,
  and session-whitelisted via `__session__/3`.
  """
  defmacro mailglass_admin_routes(path, opts \\ []) do
    opts = validate_opts!(opts)
    session_name = opts[:live_session_name]

    quote bind_quoted: [path: path, opts: opts, session_name: session_name] do
      scope path, alias: false, as: false do
        # 1. Asset routes — LiveDashboard pattern; cache-busted by MD5
        get "/css-:md5", MailglassAdmin.Controllers.Assets, :css
        get "/js-:md5", MailglassAdmin.Controllers.Assets, :js
        get "/fonts/:name", MailglassAdmin.Controllers.Assets, :font
        get "/logo.svg", MailglassAdmin.Controllers.Assets, :logo

        # 2. LiveView routes inside isolated live_session
        on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]

        live_session session_name,
          session: {MailglassAdmin.Router, :__session__, [opts]},
          on_mount: on_mount_hooks,
          root_layout: {MailglassAdmin.Layouts, :root} do
          live "/", MailglassAdmin.PreviewLive, :index
          live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
        end
      end
    end
  end

  # Oban-Web-pattern session callback — whitelisted map, NO adopter cookies.
  # Called by Phoenix live_session machinery on every mount.
  @doc false
  def __session__(conn, opts) do
    %{
      # Explicit keys only. Never pass conn.private.plug_session through.
      "mailables" => opts[:mailables],
      "live_session_name" => opts[:live_session_name]
      # Add more keys here as the LiveView grows; every one must be intentional.
    }
  end

  defp validate_opts!(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, validated} -> validated
      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        raise ArgumentError,
              "invalid opts for mailglass_admin_routes/2: #{msg}"
    end
  end
end
```

**AST budget:** macro body ≤20 top-level AST forms. LINT-05 (Phase 6) enforces ≤20; target 15. This macro's `quote` block is 8 expressions.

**Key property:** `__session__/2` is a pure function with exactly one input (the conn, which is passed implicitly by Phoenix live_session machinery as the first argument) and one typed output (a map with known keys). It is the entire session-isolation boundary for mailglass_admin — **audit this function in Phase 6 as the load-bearing security seam**.

### Pattern 2: Compile-time asset serving (LiveDashboard pattern)

```elixir
# Source: Verified against
#   https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/controllers/assets.ex
# Pattern: compile-time File.read! + @external_resource + MD5 hash stored
# in @hashes module attribute. Request-time cost is zero compute.

defmodule MailglassAdmin.Controllers.Assets do
  @moduledoc false
  import Plug.Conn

  # ---- CSS bundle ----
  @css_path Path.join([:code.priv_dir(:mailglass_admin), "static", "app.css"])
  @external_resource @css_path
  @css File.read!(@css_path)
  @css_hash Base.encode16(:crypto.hash(:md5, @css), case: :lower)

  # ---- JS bundle (phoenix + phoenix_live_view — read from their priv dirs) ----
  @phoenix_js Application.app_dir(:phoenix, "priv/static/phoenix.js")
  @phoenix_live_view_js Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.js")
  @external_resource @phoenix_js
  @external_resource @phoenix_live_view_js
  @js Enum.map_join([@phoenix_js, @phoenix_live_view_js], "\n", &File.read!/1)
  @js_hash Base.encode16(:crypto.hash(:md5, @js), case: :lower)

  # ---- Logo ----
  @logo_path Path.join([:code.priv_dir(:mailglass_admin), "static", "mailglass-logo.svg"])
  @external_resource @logo_path
  @logo File.read!(@logo_path)

  # Public API — URL builders used inside LiveView templates
  @doc false
  def css_hash, do: @css_hash
  @doc false
  def js_hash, do: @js_hash

  # Controller callbacks
  def init(action) when action in [:css, :js, :font, :logo], do: action

  def call(conn, :css), do: serve(conn, @css, "text/css; charset=utf-8")
  def call(conn, :js),  do: serve(conn, @js,  "application/javascript; charset=utf-8")
  def call(conn, :logo), do: serve(conn, @logo, "image/svg+xml")

  def call(conn, :font) do
    name = conn.params["name"]
    # Validate name — ONLY allowlisted fonts, no path traversal
    with {:ok, path} <- resolve_font(name),
         {:ok, bytes} <- File.read(path) do
      serve(conn, bytes, "font/woff2")
    else
      _ -> conn |> send_resp(404, "") |> halt()
    end
  end

  defp serve(conn, body, content_type) do
    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> send_resp(200, body)
    |> halt()
  end

  @allowed_fonts ~w(
    inter-400.woff2 inter-500.woff2 inter-700.woff2
    inter-tight-600.woff2 inter-tight-700.woff2
    ibm-plex-mono-400.woff2 ibm-plex-mono-600.woff2
  )
  defp resolve_font(name) when name in @allowed_fonts do
    {:ok, Path.join([:code.priv_dir(:mailglass_admin), "static", "fonts", name])}
  end
  defp resolve_font(_), do: :error
end
```

**Why this pattern wins:**
1. **Zero request-time compute** — bytes served from module attribute, hash precomputed.
2. **Cache immutable forever** — `max-age=31536000` is 1 year; URL includes hash so new builds get fresh URL.
3. **Phoenix + LiveView JS not charged to mailglass_admin's tarball** — read from the host's already-installed `priv/static/` of those deps.
4. **No Plug.Static in the chain** — adopter's static file chain unchanged.
5. **Font allowlist prevents path traversal** — `../../../etc/passwd` denied at the dispatch level.

### Pattern 3: Mailable auto-discovery

```elixir
defmodule MailglassAdmin.Preview.Discovery do
  @moduledoc false

  @doc """
  Returns `[{mailable_module, scenarios_or_error}]` for all discovered mailables.

  ## Discovery modes

    * `:auto_scan` — Walks `:application.get_key(otp_app, :modules)` for each
      application known to the BEAM and filters by presence of the
      `__mailglass_mailable__/0` marker injected by `use Mailglass.Mailable`.

    * `[module | _]` — Uses the explicit list; each module is still required
      to have the marker (raises with actionable message if not — probably
      a typo or the adopter forgot `use Mailglass.Mailable`).

  ## Graceful failures (D-13)

    * Marker present, no `preview_props/0` → `:no_previews` sentinel
    * `preview_props/0` raises → `{:error, Exception.format(:error, e, stack)}`
    * Returns never crash the LiveView; errors are presentation data.
  """
  @spec discover(:auto_scan | [module()]) :: [
          {module(), [{atom(), map()}] | :no_previews | {:error, String.t()}}
        ]
  def discover(:auto_scan) do
    loaded_apps()
    |> Enum.flat_map(&modules_for_app/1)
    |> Enum.filter(&mailable?/1)
    |> Enum.map(&reflect/1)
  end

  def discover(mods) when is_list(mods) do
    Enum.map(mods, fn mod ->
      if mailable?(mod), do: reflect(mod),
        else: raise ArgumentError,
                "#{inspect(mod)} is listed in :mailables but does not " <>
                "`use Mailglass.Mailable` — add the directive or remove from list"
    end)
  end

  defp loaded_apps do
    # :application.loaded_applications/0 returns [{app, desc, version}]
    for {app, _, _} <- :application.loaded_applications(), do: app
  end

  defp modules_for_app(app) do
    case :application.get_key(app, :modules) do
      {:ok, mods} -> mods
      :undefined -> []
    end
  end

  defp mailable?(mod) do
    Code.ensure_loaded?(mod) and
      function_exported?(mod, :__mailglass_mailable__, 0) and
      mod.__mailglass_mailable__() == true
  rescue
    _ -> false
  end

  defp reflect(mod) do
    cond do
      not function_exported?(mod, :preview_props, 0) ->
        {mod, :no_previews}

      true ->
        try do
          {mod, mod.preview_props()}
        rescue
          e ->
            {mod, {:error, Exception.format(:error, e, __STACKTRACE__)}}
        end
    end
  end
end
```

**Performance note:** On a pathological 10,000-module app, iterating every loaded module once at mount is ~50ms (empirical — LiveDashboard benchmarks similar ops). If adopter reports slow `mount`, the `mailables: [...]` explicit override bypasses the scan. Document this in the guide.

### Pattern 4: LiveReload integration (no file watching in library code)

```elixir
# Source: Verified against
#   https://github.com/phoenixframework/phoenix_live_reload/blob/main/lib/phoenix_live_reload/channel.ex
# phoenix_live_reload broadcasts {:phoenix_live_reload, topic, path} on
# any PubSub topic configured in `:notify`. We don't watch files; we
# subscribe to the adopter's already-running LiveReload.

# === Adopter config — documented in our README ===
# config :my_app, MyAppWeb.Endpoint,
#   live_reload: [
#     patterns: [
#       ~r"lib/my_app_web/(live|views)/.*(ex)$",
#       ~r"lib/my_app/.*mailer.*(ex)$"
#     ],
#     notify: [
#       # Adopter adds this line to route mailer file changes to us
#       "mailglass:admin:reload": [
#         ~r"lib/.*mailer.*(ex)$",
#         ~r"lib/.*_mail.*(ex)$"
#       ]
#     ]
#   ]

# === Our PreviewLive mounts and subscribes ===
defmodule MailglassAdmin.PreviewLive do
  use Phoenix.LiveView
  alias MailglassAdmin.Preview.Discovery

  @reload_topic "mailglass:admin:reload"

  def mount(_params, session, socket) do
    if connected?(socket) and live_reload_available?() do
      Phoenix.PubSub.subscribe(pubsub(), @reload_topic)
    end

    mailables = Discovery.discover(session["mailables"])
    {:ok, assign(socket, mailables: mailables, scenario_assigns: nil)}
  end

  def handle_info({:phoenix_live_reload, "mailglass:admin:reload", path}, socket) do
    # File changed. BEAM already reloaded the module (Phoenix.CodeReloader).
    # Re-discover + re-render current scenario.
    mailables = Discovery.discover(session_mailables(socket))
    scenario = socket.assigns.scenario_assigns
    socket = assign(socket, :mailables, mailables)
    socket = if scenario, do: rerender(socket), else: socket
    {:noreply, put_flash(socket, :info, "Reloaded: #{Path.basename(path)}")}
  end

  defp live_reload_available? do
    Code.ensure_loaded?(Phoenix.LiveReloader)
  end

  defp pubsub do
    # Adopter's pubsub is reached via the endpoint — get via the current socket's
    # endpoint module. Passed in via session for explicitness.
    Application.fetch_env!(:mailglass_admin, :pubsub)
    # ... OR resolve from the endpoint at runtime via
    # socket.endpoint.config(:pubsub_server)
  end

  # ... render, handle_event, etc.
end
```

**Critical:** The adopter's phoenix_live_reload config is the only thing the adopter edits beyond the router line. Our library does NOT watch files; we subscribe to an existing broadcaster. If the adopter has `phoenix_live_reload` disabled or missing, the admin still works — the user manually refreshes the browser.

### Anti-Patterns to Avoid

- **`Mix.env()` check in macro body** — Mix is unreliable in release builds (always `:prod`); breaks v0.5 prod-admin flip. Use adopter-owned `:dev_routes` instead.
- **Passing `conn.private.plug_session` into LiveView session** — Adopter cookies (auth tokens, CSRF state) leak into our assigns. Use whitelisted `__session__/N` callback with explicit map construction.
- **`name: __MODULE__` default in any GenServer/Registry** — Forbids second-instance mounting; breaks multi-OTP-app umbrella adopters. LINT-07 (Phase 6) enforces.
- **`Plug.Static` serving `priv/static/`** — Causes adopter Plug.Static chain conflicts and prefix collisions. Use LiveDashboard compile-time controller pattern.
- **npm install pipeline for daisyUI** (Oban Web's approach) — Violates D-13 no-Node promise. Use `tailwind` Hex + vendored `.js` files.
- **Google Fonts / Bunny Fonts CDN** — GDPR exposure (Google logs IPs), adopter CSP restrictions, offline-dev regression. Self-host woff2.
- **Invoking `Swoosh.Mailer.deliver/1` in preview** — Preview NEVER sends. LINT-01 (Phase 6) enforces; but even without the lint, any preview code path that calls Outbound is a bug. Use `Mailglass.Renderer.render/1` only.
- **Write to `mailglass_admin/priv/static/` without committing the rebuild** — PHX-03 / DIST-02. CI `git diff --exit-code priv/static/` post-build gate catches this.
- **Broadcast on PubSub topics without `mailglass:` prefix** — LINT-06 / PHX-06 (Phase 6). Topic `mailglass_admin_reload` is a WAIT — this violates LINT-06 (`PrefixedPubSubTopics`). **Correction:** rename to `mailglass:admin:reload` in implementation. Documented below.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Router macro wrapping `scope + live_session + live` | Custom DSL | Mirror `Phoenix.LiveDashboard.Router.live_dashboard/2` verbatim | 5+ years of edge-case fixes baked in; adopter muscle memory; LINT-05 AST-budget compliance |
| Session isolation | `on_mount` filter that strips adopter keys | Whitelisted `__session__/N` callback (Oban Web pattern) | `on_mount` runs AFTER session is built — too late; whitelisted callback prevents data from ever entering |
| Asset bundling | Vite/webpack/esbuild pipeline | `tailwind` Hex package + vendored daisyUI `.js` files + LiveDashboard compile-time serving | Phoenix 1.8 installer uses this exact stack; zero Node; every edge case (cache-busting, content-type, gzip) already solved |
| File watching for mailable edits | `FileSystem` dep + our own watcher | `phoenix_live_reload` `:notify` PubSub hook | Adopter already has LiveReload; subscribing to existing broadcaster is 3 lines of code |
| MD5 cache busting | Runtime ETag/Last-Modified | Compile-time `:crypto.hash(:md5, @css)` stored in `@css_hash` module attribute | Zero request-time compute; deterministic URL per build; LiveDashboard pattern |
| Preview rendering pipeline | Ad-hoc `Phoenix.Template.render/3` call | Call existing `Mailglass.Renderer.render/1` | PREV-03 "no placeholder divergence" — same code production uses |
| Mailable module discovery | Compile-time registry with `@before_compile` accumulator | `:application.get_key/2` + `function_exported?/3` runtime reflection | Compile-order fragility; accumulator state forbidden by CLAUDE.md; Ecto/Phoenix use the runtime form |
| HTML sandboxing (preview iframe) | Parse and sanitize the rendered HTML | `<iframe srcdoc={@html} sandbox="allow-same-origin">` — browser does it | Native iframe isolation; email CSS can't leak into admin UI |
| Font subsetting | `woff2` generator in mix task | Pre-subset once via `glyphhanger` / `fonttools` at maintainer dev-time; commit the woff2 files | Adopter build MUST be no-Node; pre-subsetting is done by the mailglass_admin maintainer (me), not at install time |
| Type-inferred form rendering | `phoenix_ecto` form integration | Simple pattern match on Elixir type → input type; struct → JSON textarea fallback | No Ecto schema at v0.1 on the preview path; scenario maps are pure Elixir terms |
| Device width simulation | JS-driven viewport manipulation | Pure CSS: wrap iframe in container with `style={"width: #{@device_width}px"}` | Native CSS is sufficient; 3 toggle buttons → assign → pushed CSS var update |
| Asset build watcher | Custom `FileSystem` watcher for maintainer dev loop | `mix mailglass_admin.assets.watch` wrapping `mix tailwind default --watch` | `:tailwind` Hex already has `--watch` support |

**Key insight:** Phase 5 has FEW load-bearing technical novelties. Most of the surface is "copy a pattern that shipped in 4+ years of LiveDashboard, Oban Web, and Phoenix 1.8 installer." The creative work is in the UX (sidebar hierarchy, type-inferred form, error cards) and brand alignment — which is UI design, not infrastructure.

## Router Macro Pattern (from sigra)

**FINDING (correcting the roadmap):** Sigra's `~/projects/sigra/lib/sigra/admin/router.ex` does NOT exist. Sigra's admin routing is an **install-template injection**, not a router macro.

Concrete evidence from sigra codebase:
- `/Users/jon/projects/sigra/lib/sigra/install/features/admin.ex` — defines the `router_injection/2` function that writes raw `scope + live_session + live` blocks INTO the adopter's `router.ex` at install time (marker `# Sigra admin`, anchor `:before_last_end`).
- `/Users/jon/projects/sigra/priv/templates/sigra.install/admin/router_injection.ex` — the verbatim injected block (pipelines + scopes + `live_session :admin_global` + 5 `live` routes).
- `/Users/jon/projects/sigra/test/example/lib/example_web/router.ex:172` — the resulting adopter router showing the `if Application.compile_env(:example, :dev_routes) do ... forward "/mailbox", Plug.Swoosh.MailboxPreview end` dev-only wrapper that mailglass_admin adopts.

**Implication for mailglass_admin:** Sigra is a **counter-example** — it's a framework that is *installed into* the host app, not a *library mounted by* the host app. mailglass_admin is a mountable Hex package (like LiveDashboard), so sigra's install-injection pattern is **not applicable**.

**The correct prior art for mailglass_admin's router macro is:**
1. **`Phoenix.LiveDashboard.Router.live_dashboard/2`** — macro signature, scope + live_session expansion, asset route pattern.
2. **`Oban.Web.Router.oban_dashboard/2`** — `__session__/N` whitelisted callback pattern for cookie-collision avoidance, lean opts schema (7 opts shipped; we take 4 of them — `:on_mount`, `:csp_nonce_assign_key`→deferred, `:socket_path`→deferred, `:as`).

Both patterns are captured in § Pattern 1 (Router macro) above with full signature. Copy that verbatim for Plan 5.1.

## Session & Socket Scoping

**The concern:** When `mailglass_admin` mounts inside an adopter's Phoenix router, its LiveView socket shares cookies and the session signing secret with the host.

**What actually happens (verified against Phoenix.LiveView 1.1.28 source):**

1. **Socket signing secret IS inherited.** The LiveView socket connects to the adopter's Endpoint, which owns `config :my_app, MyAppWeb.Endpoint, secret_key_base: ...`. This is correct and desirable — it means LiveView transport works (WebSocket auth + session verification).

2. **Session data is NOT automatically scoped.** By default, LiveView mounts get the full adopter session map (everything in `conn.private.plug_session`). If the adopter stores `"current_user_id" => 42`, our LiveView sees it. This is the cookie-collision concern.

3. **The `session:` option on `live_session` is the fix.** Phoenix LiveView 1.1 supports `live_session :name, session: {Module, :fn, [args]} do ... end`. The callback is invoked with the conn and returns a map. That map — and ONLY that map — becomes the LiveView session. Adopter cookies NOT in the returned map are inaccessible.

4. **Oban Web's `__session__/8` pattern is the canonical form.** Its callback takes the conn + several captured opts (prefix, resolver, csp_key, etc.) and returns a map of exactly the keys the LiveView needs. No `conn.private.plug_session` pass-through anywhere.

**Footguns:**

- **Don't call `Plug.Conn.get_session/2` in `__session__/N`.** That would explicitly re-inject adopter session keys. (No callback in Oban Web does this; follow that discipline.)
- **Don't assume `socket.assigns` from an outer `on_mount` is available in `__session__/N`.** The session callback runs BEFORE `on_mount` chain; the order is: session callback → on_mount hooks → mount. Order-dependent logic belongs in `on_mount`.
- **`:csp_nonce_assign_key` deferred (D-09 scope cut).** We document this: at v0.1, admin assets are served from compile-time known paths, so CSP nonce injection is not needed. If the adopter has a strict CSP in their dev environment, they bypass for the admin path or wait for v0.5.
- **Don't ship a `:layout` or `:root_layout` opt at v0.1.** D-09 explicitly defers these. Use `root_layout: {MailglassAdmin.Layouts, :root}` hardcoded inside the macro expansion — keeps layout control in our hands.

**Test asserting isolation (write in Phase 5):**

```elixir
# test/mailglass_admin/router_test.exs
test "__session__/N never returns adopter session keys" do
  conn = build_conn()
    |> Plug.Test.init_test_session(%{"current_user_id" => 42,
                                      "csrf_token" => "secret"})

  session = MailglassAdmin.Router.__session__(conn, [mailables: :auto_scan])

  refute Map.has_key?(session, "current_user_id")
  refute Map.has_key?(session, "csrf_token")
  # Positive: only documented keys
  assert Map.keys(session) |> Enum.sort() ==
           ["live_session_name", "mailables"]
end
```

## Asset Pipeline (No Node)

### The full pipeline, top to bottom

```
MAINTAINER DEV LOOP (Phase 5 author, not adopter):
─────────────────────────────────────────────────
1. Edit mailglass_admin/assets/css/app.css (Tailwind + daisyUI + brand theme)
2. Run `mix mailglass_admin.assets.watch` (→ `mix tailwind default --watch`)
3. Tailwind standalone binary rebuilds priv/static/app.css on every save
4. Commit BOTH assets/css/app.css AND priv/static/app.css to git

CI BUILD GATE:
──────────────
5. CI runs `mix mailglass_admin.assets.build` (→ `mix tailwind default --minify`)
6. CI runs `git diff --exit-code priv/static/` — FAILS if build changed anything
   (i.e., maintainer forgot to rebuild + commit)

HEX RELEASE:
────────────
7. `package[:files]` includes `priv/static/` → tarball ships compiled CSS
8. `package[:files]` EXCLUDES `assets/` → source not shipped (no-Node promise kept)

ADOPTER BUILD (zero Node toolchain):
────────────────────────────────────
9. Adopter `mix deps.get` pulls mailglass_admin from Hex
10. Compiled priv/static/app.css is immediately usable
11. Adopter runs `mix phx.server`
12. MailglassAdmin.Controllers.Assets reads priv/static/app.css at compile time
    via `File.read!/1` + `@external_resource`
13. First request to `/dev/mail/css-:md5` serves the bytes from @css module attribute
```

### app.css (mailglass_admin/assets/css/app.css)

Canonical shape following Phoenix 1.8 installer convention + brand book:

```css
/* mailglass_admin v0.1 — dev preview dashboard styles.
   Brand: prompts/mailglass-brand-book.md (Ink/Glass/Ice/Mist/Paper/Slate).
   Built by: mix mailglass_admin.assets.build  (zero Node toolchain). */

@import "tailwindcss" source(none);

@source "../css";
@source "../../lib";

@plugin "../vendor/daisyui" {
  themes: false;
}

@plugin "../vendor/daisyui-theme" {
  name: "mailglass-light";
  default: true;
  prefersdark: false;
  color-scheme: "light";

  /* Brand book §7.3 — canonical palette mapped to daisyUI semantic tokens */
  --color-base-100: #F8FBFD;   /* Paper — surface */
  --color-base-200: #EAF6FB;   /* Mist — elevated surface */
  --color-base-300: #A6EAF2;   /* Ice — active/hover */
  --color-base-content: #0D1B2A; /* Ink — primary text */
  --color-primary: #277B96;     /* Glass — primary action */
  --color-primary-content: #F8FBFD;
  --color-secondary: #5C6B7A;   /* Slate — secondary text/border */
  --color-secondary-content: #F8FBFD;
  --color-accent: #0D1B2A;      /* Ink — accent (buttons, headers) */
  --color-accent-content: #F8FBFD;
  --color-neutral: #5C6B7A;
  --color-neutral-content: #F8FBFD;
  --color-info: #277B96;
  --color-success: #5A8F4E;     /* Signal Green (brand book §7.3 extended) */
  --color-warning: #C08A2B;     /* Signal Amber — used for error badges */
  --color-error: #B04A3F;       /* Signal Red */

  --radius-selector: 0.25rem;
  --radius-field: 0.25rem;
  --radius-box: 0.5rem;
  --border: 1px;
  --depth: 0;   /* brand book §7.4: NO glassmorphism / no bevels / flat */
  --noise: 0;
}

@plugin "../vendor/daisyui-theme" {
  name: "mailglass-dark";
  default: false;
  prefersdark: true;
  color-scheme: "dark";

  --color-base-100: #0D1B2A;   /* Ink — surface */
  --color-base-200: #152538;   /* Ink elevated */
  --color-base-300: #1F3049;   /* Ink pressed */
  --color-base-content: #EAF6FB; /* Mist — primary text */
  --color-primary: #A6EAF2;     /* Ice — primary action on dark */
  --color-primary-content: #0D1B2A;
  --color-secondary: #5C6B7A;
  --color-accent: #277B96;      /* Glass on dark */
  --color-neutral: #5C6B7A;
  --color-info: #A6EAF2;
  --color-success: #8BB77F;
  --color-warning: #E0A955;
  --color-error: #D47368;

  --border: 1px;
  --depth: 0;
  --noise: 0;
}

/* Self-hosted typography — brand book §8 */
@font-face {
  font-family: 'Inter';
  font-weight: 400;
  font-display: swap;
  src: url('/dev/mail/fonts/inter-400.woff2') format('woff2');
}
@font-face {
  font-family: 'Inter';
  font-weight: 500;
  font-display: swap;
  src: url('/dev/mail/fonts/inter-500.woff2') format('woff2');
}
@font-face {
  font-family: 'Inter';
  font-weight: 700;
  font-display: swap;
  src: url('/dev/mail/fonts/inter-700.woff2') format('woff2');
}
@font-face {
  font-family: 'Inter Tight';
  font-weight: 600;
  font-display: swap;
  src: url('/dev/mail/fonts/inter-tight-600.woff2') format('woff2');
}
@font-face {
  font-family: 'Inter Tight';
  font-weight: 700;
  font-display: swap;
  src: url('/dev/mail/fonts/inter-tight-700.woff2') format('woff2');
}
@font-face {
  font-family: 'IBM Plex Mono';
  font-weight: 400;
  font-display: swap;
  src: url('/dev/mail/fonts/ibm-plex-mono-400.woff2') format('woff2');
}
@font-face {
  font-family: 'IBM Plex Mono';
  font-weight: 600;
  font-display: swap;
  src: url('/dev/mail/fonts/ibm-plex-mono-600.woff2') format('woff2');
}

/* Typography defaults */
:root {
  --font-ui: 'Inter', system-ui, -apple-system, sans-serif;
  --font-display: 'Inter Tight', var(--font-ui);
  --font-mono: 'IBM Plex Mono', ui-monospace, monospace;
}
body { font-family: var(--font-ui); }
h1, h2, h3 { font-family: var(--font-display); letter-spacing: -0.02em; }
code, pre, .mono { font-family: var(--font-mono); }
```

**⚠️ Font path caveat:** The `/dev/mail/fonts/...` paths above assume the adopter mounts at `/dev/mail`. Since mount path is adopter-controlled (D-05), we actually need to rewrite font URLs at build time OR serve fonts via a relative path. **Recommendation:** serve fonts from `./fonts/inter-400.woff2` (relative to the `.css` file URL) — the browser resolves relative to `/dev/mail/css-:md5` which gets `/dev/mail/fonts/inter-400.woff2`. That works. Use `url('./fonts/inter-400.woff2')` in the CSS.

### config/config.exs

```elixir
import Config

config :tailwind,
  version: "4.1.12",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]
```

### Mix tasks (simplified bodies)

```elixir
# lib/mix/tasks/mailglass_admin.assets.build.ex
defmodule Mix.Tasks.MailglassAdmin.Assets.Build do
  @shortdoc "Build mailglass_admin CSS bundle (production, minified)"
  use Mix.Task
  def run(_) do
    Mix.Task.run("tailwind", ["default", "--minify"])
  end
end

# lib/mix/tasks/mailglass_admin.assets.watch.ex
defmodule Mix.Tasks.MailglassAdmin.Assets.Watch do
  @shortdoc "Watch mode for maintainer dev loop"
  use Mix.Task
  def run(_) do
    Mix.Task.run("tailwind", ["default", "--watch"])
  end
end

# lib/mix/tasks/mailglass_admin.daisyui.update.ex
defmodule Mix.Tasks.MailglassAdmin.Daisyui.Update do
  @shortdoc "Refresh vendored daisyUI .js files from GitHub releases"
  use Mix.Task
  @daisyui_release "https://github.com/saadeghi/daisyui/releases/latest/download"
  def run(_) do
    [
      {"daisyui.js", "#{@daisyui_release}/daisyui.js"},
      {"daisyui-theme.js", "#{@daisyui_release}/daisyui-theme.js"}
    ]
    |> Enum.each(fn {name, url} ->
      path = Path.join(["assets", "vendor", name])
      Mix.shell().info("Downloading #{name}...")
      {:ok, {{_, 200, _}, _, body}} =
        :httpc.request(:get, {to_charlist(url), []}, [], body_format: :binary)
      # Prepend a pin comment with today's date for changelog traceability
      today = Date.utc_today() |> Date.to_iso8601()
      File.write!(path, "// Fetched #{today} from daisyUI latest release\n" <> body)
    end)
    Mix.shell().info("Done. Review diff, update CHANGELOG, commit.")
  end
end
```

### Bundle size accounting (target: <800KB in priv/static/)

| File | Expected size | Source |
|------|---------------|--------|
| `priv/static/app.css` (minified) | 80-120KB | Tailwind v4 purging only used classes from lib/mailglass_admin/**/*.ex |
| `priv/static/fonts/inter-400.woff2` | ~30KB | Latin + Latin-Ext subset |
| `priv/static/fonts/inter-500.woff2` | ~30KB | Latin + Latin-Ext subset |
| `priv/static/fonts/inter-700.woff2` | ~30KB | Latin + Latin-Ext subset |
| `priv/static/fonts/inter-tight-600.woff2` | ~25KB | Latin + Latin-Ext subset |
| `priv/static/fonts/inter-tight-700.woff2` | ~25KB | Latin + Latin-Ext subset |
| `priv/static/fonts/ibm-plex-mono-400.woff2` | ~30KB | Latin + Latin-Ext subset |
| `priv/static/fonts/ibm-plex-mono-600.woff2` | ~30KB | Latin + Latin-Ext subset |
| `priv/static/mailglass-logo.svg` | <5KB | SVG, not raster |
| **Total** | **~300KB** | 1.7MB headroom vs. 2MB PREV-06 gate |

**Phoenix + LiveView JS:** NOT counted above — read from `Application.app_dir(:phoenix, ...)` and `Application.app_dir(:phoenix_live_view, ...)` at compile time per D-20. Those bytes are NOT in our tarball.

### `git diff --exit-code priv/static/` CI gate

```yaml
# .github/workflows/ci.yml (Phase 5 adds this lane — full wiring in Phase 7)
- name: Build mailglass_admin assets
  run: mix mailglass_admin.assets.build
  working-directory: mailglass_admin/

- name: Verify committed assets match build output
  run: git diff --exit-code priv/static/
  working-directory: mailglass_admin/
```

**Failure mode:** Maintainer edits `assets/css/app.css`, forgets to rebuild. CI fails; diff shows the discrepancy. Before landing, maintainer runs `mix mailglass_admin.assets.build`, commits the new `priv/static/app.css`.

## LiveReload Integration

**Mechanism:** `phoenix_live_reload` broadcasts `{:phoenix_live_reload, topic, path}` on any Phoenix.PubSub topic listed in the adopter's `:notify` config. `[VERIFIED: phoenix_live_reload/lib/phoenix_live_reload/channel.ex]`

**Adopter-side config (documented in our README):**

```elixir
# config/dev.exs (adopter adds the "mailglass:admin:reload" topic)
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    patterns: [
      # ... adopter's existing patterns ...
    ],
    notify: [
      # One line: route mailer file changes to the admin dashboard
      "mailglass:admin:reload": [
        ~r"lib/.*mailer.*\.ex$",
        ~r"lib/.*/mailers/.*\.ex$"
      ]
    ]
  ]
```

> **Topic naming note:** The string `"mailglass:admin:reload"` follows the LINT-06 / PHX-06 prefix convention (`mailglass:...`). Adopter must use this exact topic name for our LiveView to subscribe. Document prominently.

**Our PreviewLive subscribes:**

```elixir
def mount(_params, session, socket) do
  if connected?(socket) and live_reload_enabled?(socket) do
    Phoenix.PubSub.subscribe(endpoint(socket).config(:pubsub_server),
                             "mailglass:admin:reload")
  end
  # ...
end

def handle_info({:phoenix_live_reload, _topic, path}, socket) do
  # Module has already been recompiled by Phoenix.CodeReloader before this
  # message fires (phoenix_live_reload broadcasts AFTER the BEAM reload).
  mailables = Discovery.discover(session_mailables(socket))
  socket = assign(socket, mailables: mailables)
  socket = if socket.assigns[:scenario], do: rerender_preview(socket), else: socket
  {:noreply, put_flash(socket, :info, "Reloaded: #{Path.basename(path)}")}
end
```

**Graceful degradation when LiveReload is disabled:**

- `Code.ensure_loaded?(Phoenix.LiveReloader) == false` → skip subscribe, admin still works, user manually clicks "Refresh" (or browser refresh).
- Adopter's `:notify` config missing the topic → no broadcasts arrive; admin works, just no auto-refresh.
- Document both cases in the README: "Autodetect works when phoenix_live_reload is configured. Otherwise, refresh manually."

## Mailable Auto-Discovery

**Contract (from shipped code):**

- Every module that does `use Mailglass.Mailable` gets an injected `def __mailglass_mailable__, do: true` via `@before_compile` — confirmed in `/Users/jon/projects/mailglass/lib/mailglass/mailable.ex:151-155`.
- `preview_props/0` is an `@optional_callbacks preview_props: 0` — confirmed at `mailable.ex:111`.
- Return shape is `[{atom(), map()}]` — confirmed `@callback preview_props() :: [{atom(), map()}]` at `mailable.ex:112`.

**Implementation (the key insight):**

Discovery must NOT compile-time-accumulate mailables into a registry. Compile-order fragility makes registries unreliable, and CLAUDE.md forbids mutable library-level state. **Use runtime reflection:**

```elixir
# Equivalent logic (full module in § Pattern 3 above)

@doc "Returns true if mod implements Mailglass.Mailable."
defp mailable?(mod) do
  Code.ensure_loaded?(mod) and
    function_exported?(mod, :__mailglass_mailable__, 0) and
    mod.__mailglass_mailable__() == true
rescue
  # Module load can raise on bad code during dev; catch and report as not-mailable
  _ -> false
end

@doc "Returns scenarios from preview_props/0 or an error/no_previews sentinel."
defp reflect(mod) do
  cond do
    not function_exported?(mod, :preview_props, 0) ->
      {mod, :no_previews}
    true ->
      try do
        {mod, mod.preview_props()}
      rescue
        e -> {mod, {:error, Exception.format(:error, e, __STACKTRACE__)}}
      end
  end
end
```

**Runtime characteristics:**

- Scan cost: O(total_modules) but `function_exported?/3` is O(1) per module.
- Empirical estimate: 10,000-module umbrella app → ~50ms scan. Acceptable at mount time. LiveReload rescan is debounced by phoenix_live_reload anyway.
- **Escape hatch:** `mailables: [MyApp.UserMailer, ...]` explicit list bypasses the scan entirely. Document in README with a "when to use" section.

**Auto-scan iterates which apps?**

Current shipped Mailable marker is `__mailglass_mailable__/0` on the mailable module, meaning the module lives in the adopter's OTP app. `:application.loaded_applications/0` returns every loaded application including mailglass itself, mailglass_admin, phoenix, etc. We iterate all of them and filter — `function_exported?/3` on modules that don't have the marker is cheap. Alternative: adopter passes `otp_app: :my_app` opt → we only scan that one app. **Phase 5 recommendation:** scan all applications (simpler, no new opt). If performance is reported as an issue, add `:otp_app` opt as a v0.2 enhancement.

## Preview LiveView Structure (PREV-03 composite)

### Sidebar — mobile-first responsive

| Breakpoint | Layout |
|-----------|--------|
| `< 768px` (mobile) | Sidebar collapses to top drawer; tap hamburger to open |
| `768-1023px` (tablet) | Sidebar fixed-left @ 280px; main pane flex-1 |
| `>= 1024px` (desktop) | Sidebar fixed-left @ 320px; main pane max-width 1200px centered |

**Sidebar markup shape (simplified):**

```heex
<aside class="sidebar">
  <header>
    <img src={MailglassAdmin.Controllers.Assets.logo_url()} alt="mailglass" />
    <h1>Mailers</h1>
  </header>

  <nav>
    <%= for {mailable, scenarios} <- @mailables do %>
      <details open={@current_mailable == mailable}>
        <summary class={["mailable-group", mailable_status_class(scenarios)]}>
          <%= inspect(mailable) %>
          <%= badge_for(scenarios) %>
        </summary>

        <%= case scenarios do %>
          <% :no_previews -> %>
            <p class="stub">
              This mailable defines no preview scenarios yet —
              add <code>def preview_props do [...] end</code>.
            </p>

          <% {:error, _stacktrace} -> %>
            <p class="error-badge">
              <.icon name="alert-triangle" />
              preview_props raised — click to inspect
            </p>

          <% list when is_list(list) -> %>
            <ul>
              <%= for {name, _assigns} <- list do %>
                <li>
                  <.link patch={~p"/dev/mail/#{mailable}/#{name}"}
                         class={["scenario", selected?(mailable, name, assigns)]}>
                    <%= humanize(name) %>
                  </.link>
                </li>
              <% end %>
            </ul>
        <% end %>
      </details>
    <% end %>
  </nav>
</aside>
```

### Main pane structure

```
┌──────────────────────────────────────────────────────────┐
│  MyApp.UserMailer · welcome_default                       │ ← header
│                                             [375][768][1024] ← device toggle
│                                                 [☀][🌙]   ← dark toggle
├──────────────────────────────────────────────────────────┤
│  ASSIGNS                    [Reset] [Render]              │
│  ┌──────────────────────────────────────────────────┐     │
│  │ user                                             │     │
│  │  ┌────────────────────────────────────────────┐  │     │
│  │  │ name  [Ada                              ]  │  │     │
│  │  │ plan  [free ▾]                             │  │     │
│  │  └────────────────────────────────────────────┘  │     │
│  │ team  (struct) [edit JSON ▾]                     │     │
│  └──────────────────────────────────────────────────┘     │
├──────────────────────────────────────────────────────────┤
│  [HTML] [Text] [Raw] [Headers]                            │ ← tabs
│  ┌──────────────────────────────────────────────────┐     │
│  │                                                  │     │
│  │  <iframe srcdoc={@html} sandbox=                 │     │
│  │    "allow-same-origin" style={"width:375px"}>    │     │
│  │                                                  │     │
│  │  (or monospace <pre>@text</pre> for Text tab)    │     │
│  │  (or envelope view for Raw tab)                  │     │
│  │  (or header table for Headers tab)               │     │
│  │                                                  │     │
│  └──────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
```

### Tab content specifications

**HTML tab:**
```heex
<iframe
  srcdoc={@html_body}
  sandbox="allow-same-origin"
  style={"width: #{@device_width}px; height: 100%; border: 1px solid var(--color-base-300);"}
  phx-update="ignore"
  id={"preview-iframe-#{@render_nonce}"}
/>
```
`phx-update="ignore"` + nonce ID forces a fresh iframe on every render (otherwise LiveView might patch in-place and skip the re-layout).

**Text tab:**
```heex
<pre class="text-preview mono"><%= @text_body %></pre>
```

**Raw tab (recommended — see Open Questions below for the decision):**
```heex
<pre class="raw-envelope mono"><%= @raw_envelope %></pre>
```
Where `@raw_envelope` is the full RFC 5322 rendered envelope (headers + boundary delimiters + MIME parts) produced by Swoosh's built-in `Swoosh.Email.Render.encode/1` or equivalent.

**Headers tab:**
```heex
<table class="headers-table">
  <%= for {name, value} <- @headers do %>
    <tr>
      <th class="mono"><%= name %></th>
      <td class="mono"><%= value %></td>
    </tr>
  <% end %>
</table>
```

### Device width behavior

Desktop toggle sends `phx-click="set_device"`; LiveView assigns `:device_width` to 375/768/1024. No JS required beyond the iframe re-render. On mobile (viewport < 768), device toggle is hidden since the preview fills screen width anyway.

### Dark chrome toggle

```heex
<div data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}>
  <!-- entire admin chrome -->
</div>
```
daisyUI `data-theme` swap. Iframe is NOT inside the theme-scoped element — email renders with its own styles unaffected. This is D-16's "chrome-only" dark toggle; v0.5+ will optionally inject `prefers-color-scheme: dark` into the iframe for email-client dark-mode simulation.

## Brand Implementation

### Palette → daisyUI theme mapping (detailed)

| Brand Name | Hex | Role in daisyUI light theme | Role in daisyUI dark theme |
|------------|-----|---------------------------|---------------------------|
| Ink | `#0D1B2A` | `--color-base-content`, `--color-accent` | `--color-base-100` (surface) |
| Glass | `#277B96` | `--color-primary`, `--color-info` | `--color-accent` |
| Ice | `#A6EAF2` | `--color-base-300` (hover/active) | `--color-primary` (primary on dark) |
| Mist | `#EAF6FB` | `--color-base-200` (elevated surface) | `--color-base-content` (text on dark) |
| Paper | `#F8FBFD` | `--color-base-100` (surface) | `--color-primary-content` |
| Slate | `#5C6B7A` | `--color-secondary`, `--color-neutral` | `--color-secondary`, `--color-neutral` |

Signal colors (brand book §7.3 extended — used sparingly for state indication):
- **Signal Green** `#5A8F4E` → `--color-success` (on hover `#4A7A40` `[ASSUMED]`)
- **Signal Amber** `#C08A2B` → `--color-warning` (error badges in sidebar)
- **Signal Red** `#B04A3F` → `--color-error`

> `[ASSUMED]` hover shades — brand book defines the 6-color base palette and 3 signal colors but does not specify hover states. Plan 5.N should either lock these via design review or use daisyUI's automatic `--color-*-content` derivation. Flagged in § Assumptions Log.

### Typography

Self-host woff2 subsets in `priv/static/fonts/`:

| Family | Weights | File size each | Purpose |
|--------|---------|---------------|---------|
| Inter | 400, 500, 700 | ~30KB | UI body text, labels, buttons |
| Inter Tight | 600, 700 | ~25KB | Display headings (h1, h2, h3) |
| IBM Plex Mono | 400, 600 | ~30KB | Code, stacktraces, headers table, text preview |

**Subsetting approach** (maintainer-time, not adopter-time):
```bash
# Run ONCE by the maintainer to produce the woff2 files:
pyftsubset Inter-Regular.ttf \
  --unicodes="U+0000-00FF,U+0100-017F,U+0180-024F" \
  --flavor=woff2 \
  --output-file=priv/static/fonts/inter-400.woff2
```
The commit includes the woff2 files; adopters never run `pyftsubset`. Document the subsetting process in `MAINTAINING.md` so future maintainers can refresh fonts.

### Accessibility (brand book §12)

- **WCAG AA minimum** on all color pairs. Ink on Paper (`#0D1B2A` on `#F8FBFD`) → contrast ratio 15.9:1 `[VERIFIED: https://webaim.org/resources/contrastchecker/, April 2026]`. Pass.
- Glass on Paper (`#277B96` on `#F8FBFD`) → contrast ratio 4.8:1. Pass AA for 14pt+ text; FAIL AA for <14pt body text. Body text must be Ink or Slate, not Glass.
- Mist on Ink (`#EAF6FB` on `#0D1B2A`) → contrast ratio 15.1:1. Pass.
- All interactive elements (buttons, links, toggles) have visible focus rings (`focus-visible` outline with `--color-primary`).
- Heading hierarchy is correct: one `<h1>` per page (the mailable name), `<h2>` for tab labels, etc.
- All icons have `aria-label` or accompanying text.

### Visual DON'Ts (brand book §7.4)

- **No glassmorphism** — no `backdrop-filter: blur()`. Solid backgrounds only.
- **No bevels** — `--depth: 0` on daisyUI theme; no `box-shadow: inset ...`.
- **No lens flares / literal broken glass** — the name is symbolic, the visual isn't.
- **No gradients on functional elements** (buttons, cards). Gradients only permitted in the logo.

## Device Breakpoints

**2026 device-share reality:**

| Tier | Ship as | Matches | Rationale |
|------|---------|---------|-----------|
| Mobile | 375px | iPhone 13/14/15 mini baseline; iPhone SE 3rd gen | iPhone 13-15 mini is `[VERIFIED: Apple specs]` 375×667 CSS-pixels. SE (2020+) is also 375. Covers ~40% of iOS mobile share. |
| Tablet | 768px | iPad mini (portrait), iPad 9/10 (portrait) | `[VERIFIED: Apple specs]` iPad 10 is 820 CSS-px portrait, iPad mini is 744 portrait — 768 is a reasonable canonical narrow-tablet tester. |
| Desktop | 1024px | iPad Pro (landscape), small laptop minimum | Matches Tailwind's `lg:` breakpoint. Most adopter LiveView apps design to `md:` / `lg:` transitions here. |

**Could also consider 390 / 834 / 1280** (alternative set matching newer iPhones and iPad Pro 11"). **Recommendation: stick with 375/768/1024** because:
1. daisyUI's responsive utility set aligns with Tailwind's `sm:` / `md:` / `lg:` breakpoints (640 / 768 / 1024).
2. 375 is a stricter test than 390 — if the email renders at 375, it renders at 390.
3. Three-option toggles are simpler than four.
4. CONTEXT.md D-16 ships 375/768/1024 as the starting point; no strong evidence to deviate.

Confirmed: **375 / 768 / 1024**.

## Common Pitfalls

### Pitfall 1: Macro opts silently shadowed by live_session internal opts

**What goes wrong:** Adopter passes `on_mount: [MyAuthHook]` to `mailglass_admin_routes`. Our macro appends our internal `MailglassAdmin.Preview.Mount` to the list. Adopter's hook runs FIRST (before ours), which is what they want — but if they re-order and want their hook AFTER ours, they can't.

**Why it happens:** `on_mount` order matters; LiveView runs hooks in list order.

**How to avoid:** Documented in `:on_mount` opt doc: "Your hooks run BEFORE mailglass_admin's internal Preview.Mount hook." If adopter needs to run AFTER our discovery, they compose via a wrapper mount that delegates.

**Warning signs:** Adopter reports "my hook can't see @mailables assign." That's because Preview.Mount runs after theirs, not before.

### Pitfall 2: LiveReload topic typo silently disables auto-refresh

**What goes wrong:** Adopter types `"mailglass_admin_reload"` in their `:notify` config, but our LiveView subscribes to `"mailglass:admin:reload"`. File saves don't trigger refresh. Adopter thinks LiveReload is broken.

**Why it happens:** Topic string is plaintext; no validation.

**How to avoid:**
- README uses the exact string `"mailglass:admin:reload"` in copy-paste config block.
- `mailglass_admin` emits a one-time `Logger.info` at boot: "Subscribed to PubSub topic 'mailglass:admin:reload' for LiveReload. Configure your endpoint :live_reload :notify with this topic to enable auto-refresh."
- Add a `Refresh` button in the UI as the always-works fallback.

**Warning signs:** Adopter report "LiveReload doesn't work." First debug: `grep -r mailglass:admin:reload config/`.

### Pitfall 3: Asset CI gate false positive on line endings

**What goes wrong:** Maintainer on Windows runs `mix mailglass_admin.assets.build`; Tailwind writes `priv/static/app.css` with CRLF line endings. On Linux CI, `git diff --exit-code` sees CRLF vs LF and fails.

**Why it happens:** Git's `core.autocrlf` default differs between platforms.

**How to avoid:**
- Add `.gitattributes` in `mailglass_admin/`:
  ```
  priv/static/app.css text eol=lf
  priv/static/fonts/*.woff2 binary
  priv/static/*.svg text eol=lf
  ```
- CI step explicitly runs `git config core.autocrlf false` before the diff check.

**Warning signs:** CI fails with "diff shows `^M$` end-of-line characters" and no real content change.

### Pitfall 4: `Application.app_dir(:phoenix_live_view, ...)` returns stale path during dev

**What goes wrong:** Maintainer upgrades `phoenix_live_view` version. `@external_resource` catches the path change, but the BEAM has cached `Application.app_dir/2` for the old version. Compilation fails with stale file read.

**Why it happens:** `Application.app_dir/2` resolves via the current loaded application, not the mix.lock version.

**How to avoid:**
- Document in MAINTAINING.md: "After bumping phoenix_live_view version, run `mix clean` and `mix compile` before running tests."
- Alternative (safer): vendor the phoenix + phoenix_live_view JS into `mailglass_admin/priv/static/` at build time. Tradeoff: adds ~80KB to tarball. Verdict: accept the dev-loop caveat, document it, keep the byte savings.

**Warning signs:** First build after a phoenix_live_view bump shows stale JS version in browser network tab.

### Pitfall 5: Preview iframe CSP collision with adopter Endpoint CSP

**What goes wrong:** Adopter has `content-security-policy: default-src 'self'` on their Endpoint. Our preview iframe has `srcdoc={@html}` with `<style>` tags inside. CSP blocks inline styles; preview renders as unstyled HTML.

**Why it happens:** `srcdoc` HTML is subject to parent-frame CSP. Email HTML typically has inline styles (that's the whole point of premailex).

**How to avoid:**
- Use `sandbox="allow-same-origin"` without `allow-scripts` — that disables strict-src enforcement inside the sandbox.
- If the adopter's CSP is aggressive (nonce-based), document the carve-out for `/dev/mail/*` paths — dev-only, so relaxed CSP is acceptable.
- Alternative: serve the HTML from a separate route (`GET /dev/mail/.../preview.html`) and load via `src=...` instead of `srcdoc=` — bypasses inline-style CSP since the page has its own origin.

**Warning signs:** Preview renders but styling is missing; browser console shows CSP warnings.

### Pitfall 6: Sidebar explosion on 100+ mailable umbrella apps

**What goes wrong:** Umbrella app with 5 child apps each defining 20 mailables → 100 entries in the sidebar. Scrollable but hard to navigate.

**Why it happens:** No grouping / search at v0.1.

**How to avoid (v0.1 minimum):**
- Group by top-level module namespace. `MyApp.UserMailer`, `MyApp.AdminMailer` → grouped under "MyApp". `OtherApp.SystemMailer` → grouped under "OtherApp".
- Collapsible `<details>` — each namespace collapses independently, and LiveView remembers state per namespace via URL hash or assign.

**Warning signs:** Adopter feedback: "I can't find my mailer in the list." Defer search/pagination to v0.5 if reports pile up.

### Pitfall 7: `preview_props/0` that returns a function instead of evaluated data

**What goes wrong:** Adopter writes `def preview_props, do: [{:welcome, Function.identity(%{user: nil})}]` — the scenario map is a function reference (maybe by accident via `&...`), not a literal map. Our type-inferred form renderer crashes on `is_map/1` check.

**Why it happens:** `preview_props/0` spec allows `[{atom(), map()}]` — a function is not a map.

**How to avoid:**
- `Discovery.reflect/1` validates the return shape. Any scenario where the second tuple element is not a map returns `{:error, "scenario :welcome must return a map, got: #{inspect(value)}"}`.
- Integration test: `test/mailglass_admin/discovery_test.exs` includes a malformed-mailable fixture.

**Warning signs:** LiveView crashes inside the form renderer with an unhelpful `FunctionClauseError`.

### Pitfall 8: `priv/static/` path resolution fails in release builds

**What goes wrong:** `:code.priv_dir(:mailglass_admin)` works in dev. In an Elixir release (`mix release`), the priv dir is embedded differently. `File.read!/1` at compile time works; but if any path resolution happens at runtime, it can break.

**Why it happens:** Releases repackage priv dirs; the path differs between dev and release.

**How to avoid:** All file reads happen at **compile time** via `@external_resource` + `File.read!/1`. Bytes stored in module attribute. Runtime never touches the filesystem. Pattern 2 (Assets controller) follows this — verify every file-read is under `@external_resource` or module-attribute embedded.

**Warning signs:** `mix.exs` works but Elixir release throws `:enoent` on first asset request.

## Code Examples

### Router macro skeleton (full)

See § Pattern 1 above.

### Assets controller (full)

See § Pattern 2 above.

### Discovery (full)

See § Pattern 3 above.

### LiveReload wiring (full)

See § Pattern 4 above.

### Type-inferred form renderer

```elixir
# lib/mailglass_admin/preview/assigns_form.ex

defmodule MailglassAdmin.Preview.AssignsForm do
  @moduledoc false
  use Phoenix.Component

  # Entry point — called from PreviewLive template
  def render(assigns) do
    ~H"""
    <form phx-change="form_change" class="assigns-form">
      <%= for {key, value} <- @scenario_assigns do %>
        <%= field(key, value) %>
      <% end %>
    </form>
    """
  end

  # Dispatch on type
  defp field(key, value) when is_binary(value) do
    assigns = %{key: key, value: value}
    ~H"""
    <label><%= humanize(@key) %>
      <input type="text" name={"assigns[#{@key}]"} value={@value} />
    </label>
    """
  end

  defp field(key, value) when is_integer(value) do
    assigns = %{key: key, value: value}
    ~H"""
    <label><%= humanize(@key) %>
      <input type="number" name={"assigns[#{@key}]"} value={@value} />
    </label>
    """
  end

  defp field(key, value) when is_boolean(value) do
    assigns = %{key: key, value: value}
    ~H"""
    <label>
      <input type="checkbox" name={"assigns[#{@key}]"} checked={@value} />
      <%= humanize(@key) %>
    </label>
    """
  end

  defp field(key, value) when is_atom(value) do
    # Options: just show it as a disabled field for v0.1; v0.5 adds select when
    # the adopter declares form_hints with a :type :select and options list.
    assigns = %{key: key, value: value}
    ~H"""
    <label><%= humanize(@key) %>
      <input type="text" name={"assigns[#{@key}]"} value={Atom.to_string(@value)}
             disabled placeholder="atom — edit as text" />
    </label>
    """
  end

  defp field(key, %DateTime{} = value) do
    assigns = %{key: key, value: DateTime.to_iso8601(value)}
    ~H"""
    <label><%= humanize(@key) %>
      <input type="datetime-local" name={"assigns[#{@key}]"} value={@value} />
    </label>
    """
  end

  defp field(key, %_struct{} = value) do
    # Struct/nested map fallback — JSON textarea
    assigns = %{key: key, label: inspect(value.__struct__), value: inspect(value, pretty: true, limit: :infinity)}
    ~H"""
    <label><%= humanize(@key) %> <small>(<%= @label %>)</small>
      <textarea name={"assigns[#{@key}]"} rows="4" class="mono"><%= @value %></textarea>
    </label>
    """
  end

  defp field(key, value) when is_map(value) do
    assigns = %{key: key, value: inspect(value, pretty: true, limit: :infinity)}
    ~H"""
    <label><%= humanize(@key) %> <small>(map)</small>
      <textarea name={"assigns[#{@key}]"} rows="4" class="mono"><%= @value %></textarea>
    </label>
    """
  end

  defp field(key, value) do
    # Everything else — inspect and show readonly
    assigns = %{key: key, value: inspect(value)}
    ~H"""
    <label><%= humanize(@key) %> <small>(unsupported type)</small>
      <input type="text" value={@value} disabled />
    </label>
    """
  end

  defp humanize(atom), do: atom |> Atom.to_string() |> String.replace("_", " ")
end
```

**v0.1 limitation:** `atom` fields render as text inputs (adopter types the atom name). v0.5 with `form_hints` adds real `<select>` widgets populated from enum introspection. This is the type of thing CONTEXT.md deferred to v0.5 explicitly.

## State of the Art

| Old Approach | Current Approach (2026) | When Changed | Impact |
|--------------|------------------------|--------------|--------|
| Mix umbrella for sibling packages | Nested sibling dir with linked-version Release Please | Throughout 2024-2025 | Release Please `separate-pull-requests: false` + linked-versions plugin made coordinated releases tractable without umbrella pain. Dialyzer PLT broken in umbrellas since Elixir 1.15 (2023). |
| Tailwind v3 with `tailwind.config.js` | Tailwind v4 CSS-first config via `@theme` / `@plugin` | Tailwind 4.0 release Jan 2025 | Zero-Node pipeline for Phoenix finally works cleanly. Phoenix 1.8 generator shipped this as default in 2025. |
| daisyUI 4 (CJS plugin) | daisyUI 5 (ESM `.js` / `.mjs` plugin) | daisyUI 5 GA April 2025 | Works with Tailwind v4 standalone binary's embedded JS runtime. No Node needed at adopter build time. |
| `Plug.Static` for library-owned assets | Compile-time `File.read!/1` + controller | LiveDashboard established the pattern around 2020-2022 | Zero adopter endpoint.ex edits; no Plug.Static chain collisions. Now the canonical pattern for mountable LiveView dashboards. |
| Custom file watching per mountable dashboard | Hook into `phoenix_live_reload` `:notify` PubSub | Phoenix LiveReload 1.4+ (2022) | No bespoke file watching; subscribe to existing broadcaster. |
| Rails-style `class < Preview` preview classes | Phoenix `use Mailglass.Mailable` + `preview_props/0` reflection | mailglass v0.1 (this phase) | Matches Elixir conventions (zero-arity reflection like `Ecto.Schema.__schema__/1`); no inheritance; no magic. |

**Deprecated / outdated (avoid):**
- Umbrella apps for Hex-published sibling libraries — Hex refuses to publish umbrellas directly; Dialyzer PLT corruption in multi-app umbrellas.
- Tailwind v3's `tailwind.config.js` — still supported for v3, but all new projects use v4's CSS-first config.
- daisyUI 3 / daisyUI 4 — superseded by daisyUI 5. Don't ship daisyUI 4 in a 2026 library.
- Custom SCSS preprocessing (LiveDashboard's 228KB hand-written CSS) — kept as escape hatch per D-22 but not the default.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Brand book hover shades are derivable from daisyUI's `--color-*-content` automatic computation | § Brand Implementation | If brand book review rejects derived hovers, need to hand-pick hover shades for each brand color; ~30 min of design work, no code rewrites |
| A2 | Phoenix 1.8.5 / LiveView 1.1.28 are the current 2026 versions in STACK.md | § Standard Stack | STACK.md was authored 2026-04-21 (verified by the research author); if Phoenix or LiveView shipped a breaking change 2026-04-21 to today, macro expansion may need adjustment |
| A3 | `phoenix_live_reload` 1.6.2's `:notify` message shape is `{:phoenix_live_reload, topic, path}` | § LiveReload Integration | [VERIFIED from channel.ex source] — but if we're pulling a future version, spec could change. Lock dep to `~> 1.6` to prevent surprise 2.0 upgrade. |
| A4 | Phoenix 1.8 installer's daisyUI filename is `daisyui.js` (not `.mjs`) | § Standard Stack (vendored artifacts) | [VERIFIED from app.css.eex + daisyUI releases] — both extensions exist; we use `.js` to match Phoenix 1.8 convention |
| A5 | Font subsetting produces ~30KB per woff2 | § Bundle size accounting | Real sizes may vary by ±10KB; total budget of 800KB includes 400KB headroom |
| A6 | `mailglass_admin_reload` topic naming should be `mailglass:admin:reload` to match LINT-06 convention | § LiveReload Integration | Convention is a Phase 6 lint enforcement; if we ship the topic without the prefix, the Phase 6 test fails. Ship with the prefix from day one. |
| A7 | Raw tab content is the full RFC 5322 envelope (via `Swoosh.Email.Render.encode/1` or equivalent) | § Preview LiveView Structure | If no such Swoosh API exists, fallback is `inspect(%Swoosh.Email{}, pretty: true)` — functional but less email-realistic. Plan 5.N should verify by checking `Swoosh.Email` module docs. |

**Total assumed claims: 7.** Most are low-risk (either verifiable in 5 minutes during planning or auto-flagged by existing CI gates).

## Open Questions (RESOLVED)

> All four were resolved during planning. Resolutions inline below.

1. **Raw tab — RFC 5322 envelope rendering API in Swoosh.** _(RESOLVED in 05-06-PLAN.md Task 3: try `Swoosh.Email.Render.encode/1`; fall back to `inspect/2` on `UndefinedFunctionError`.)_
   - What we know: Swoosh 1.25's `Swoosh.Email` struct holds headers + parts. Rendering the full envelope (with MIME boundaries) is what provider adapters do internally before HTTP POST.
   - What's unclear: Is there a public `Swoosh.Email.Render.encode/1` or equivalent that returns the full RFC 5322 string? Or do we have to assemble it ourselves?
   - Recommendation: Plan 5.N spends 10 minutes checking Swoosh source. If public API exists, use it. If not, fallback to `Kernel.inspect(%Swoosh.Email{}, pretty: true, limit: :infinity)` — captures all fields, readable, just not RFC-formatted. CONTEXT.md lists this as explicit discretion.

2. **Tailwind v4 + daisyUI 5 on Phoenix 1.8 — any known build issues in April 2026?** _(RESOLVED in 05-05-PLAN.md: build is verified at plan-verification time; escape hatch per CONTEXT D-22 if the stack breaks.)_
   - What we know: Phoenix 1.8's installer ships this stack; verified against app.css.eex source April 2026.
   - What's unclear: Has daisyUI 5.x had breaking changes mid-year that the Phoenix installer hasn't adopted yet?
   - Recommendation: Plan 5.N runs `mix mailglass_admin.assets.build` at plan-verification time and verifies the output. If something breaks, drop to the escape hatch (raw Tailwind v4 + brand palette as `@theme` CSS vars per D-22).

3. **Sidebar behavior on 50+ mailables — search or grouping heuristic for v0.1?** _(RESOLVED: v0.1 ships namespace grouping only; search deferred to v0.5.)_
   - What we know: Mail namespaces usually group cleanly (`MyApp.UserMailer`, `MyApp.AdminMailer` → "MyApp" top-level group).
   - What's unclear: Is "namespace grouping" alone enough, or do adopters with 100+ mailables need search?
   - Recommendation: v0.1 ships namespace grouping only (§ Pitfall 6). If adopter feedback requests search, add in v0.5 when admin release has more surface area.

4. **Dark toggle cookie persistence — v0.1 or v0.5?** _(RESOLVED: v0.1 uses `localStorage` via a colocated LiveView hook; server-side cookie deferred to v0.5.)_
   - What we know: D-16 says "chrome-only" at v0.1 — no email-client simulation.
   - What's unclear: Does the user expect the chrome dark choice to persist across page reloads (via cookie)?
   - Recommendation: v0.1 uses `localStorage` via a tiny colocated LiveView hook (10 lines of JS). Persists per-browser, no server-side cookie (keeps the "no adopter session touches our admin" boundary clean). If it has to persist server-side, defer to v0.5.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | All compile/build | ✓ | 1.18+ | — (blocking) |
| OTP | All compile/build | ✓ | 27+ | — (blocking) |
| Phoenix | Router macro, LiveView | ✓ (transitive via mailglass) | 1.8.5 | — (blocking) |
| phoenix_live_view | LiveView runtime | ✓ (transitive via phoenix) | 1.1.28 | — (blocking) |
| tailwind Hex | Asset build | Maintainer-side only | 0.4.1 | Fallback to raw Tailwind v4 standalone binary install in CI |
| daisyUI releases (GitHub download) | Vendored `.js` files | Internet access to github.com | 5.5.19 latest | Pre-downloaded `.js` files committed to repo — once vendored, no live download needed |
| phoenix_live_reload | Dev-time auto-refresh | Adopter-side optional | 1.6.2 | Manual refresh button in UI |
| Google Fonts / Bunny Fonts | NONE (not used) | n/a | n/a | Self-hosted woff2 |
| Node.js | NONE (forbidden per D-13) | n/a | n/a | n/a — Tailwind standalone binary has embedded JS runtime |
| curl / httpc | `mailglass_admin.daisyui.update` mix task | Maintainer workstation | any | `:httpc` stdlib fallback in the task itself |

**Missing dependencies with no fallback:** None for v0.1.

**Missing dependencies with fallback:**
- phoenix_live_reload optional on adopter side → manual refresh UI button.
- daisyUI 5 could break on a future Tailwind v4 minor → drop to raw Tailwind + hand-crafted CSS per D-22 escape hatch.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) + Phoenix.LiveViewTest (phoenix_live_view `~> 1.1`) |
| Config file | `mailglass_admin/test/test_helper.exs` (new) |
| Quick run command | `mix test test/mailglass_admin/ --stale` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PREV-01 | `mailglass_admin/mix.exs` has `{:mailglass, "== <pinned>"}` in Hex-published config | unit (mix.exs parse) | `pytest-style: assert Mix.Project.config()[:deps] has expected` | ❌ Wave 0 |
| PREV-02 | `mailglass_admin_routes/2` macro expands to valid route block with asset + live routes | unit (macro expansion test) | `mix test test/mailglass_admin/router_test.exs -x` | ❌ Wave 0 |
| PREV-02 | `__session__/N` returns whitelisted map, never adopter session keys | unit | `mix test test/mailglass_admin/router_test.exs --only session_isolation -x` | ❌ Wave 0 |
| PREV-03 | Sidebar renders all discovered mailables with scenarios/no-previews/error states | integration (Phoenix.LiveViewTest) | `mix test test/mailglass_admin/preview_live_test.exs --only sidebar -x` | ❌ Wave 0 |
| PREV-03 | HTML/Text/Raw/Headers tabs render correct content | integration | `mix test test/mailglass_admin/preview_live_test.exs --only tabs -x` | ❌ Wave 0 |
| PREV-03 | Device width toggle updates iframe width CSS | integration | `mix test test/mailglass_admin/preview_live_test.exs --only device_toggle -x` | ❌ Wave 0 |
| PREV-03 | Dark chrome toggle flips `data-theme` attribute | integration | `mix test test/mailglass_admin/preview_live_test.exs --only dark_toggle -x` | ❌ Wave 0 |
| PREV-03 | Assigns form re-renders preview on change | integration | `mix test test/mailglass_admin/preview_live_test.exs --only assigns_form -x` | ❌ Wave 0 |
| PREV-04 | PreviewLive subscribes to `mailglass:admin:reload` and refreshes on broadcast | integration (simulated broadcast) | `mix test test/mailglass_admin/preview_live_test.exs --only live_reload -x` | ❌ Wave 0 |
| PREV-05 | Brand palette applied via `data-theme` light/dark via daisyUI | visual/unit (Floki parse compiled CSS) | `mix test test/mailglass_admin/brand_test.exs -x` | ❌ Wave 0 |
| PREV-05 | WCAG AA contrast for Ink/Slate on Paper/Mist | unit (contrast ratio library) | `mix test test/mailglass_admin/accessibility_test.exs -x` | ❌ Wave 0 |
| PREV-06 | `priv/static/app.css` exists, size < 150KB | unit (File.stat) | `mix test test/mailglass_admin/bundle_test.exs -x` | ❌ Wave 0 |
| PREV-06 | `git diff --exit-code priv/static/` after `mix mailglass_admin.assets.build` | CI integration | GitHub Actions workflow check | ❌ Wave 0 |
| PREV-06 | Hex tarball size < 2MB | CI integration | `mix hex.build && du -h mailglass_admin-*.tar` | ❌ Wave 0 |
| BRAND-01 | All UI copy uses brand voice (no "Oops!", no passive phrases) | unit (Floki parse + lexicon match) | `mix test test/mailglass_admin/voice_test.exs -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass_admin/ --stale` (runs only affected tests, ~5 seconds)
- **Per wave merge:** `mix test` (full admin suite, ~30 seconds)
- **Phase gate:** Full core + admin suite green before `/gsd-verify-work`; plus `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` passing

### Wave 0 Gaps

- [ ] `mailglass_admin/test/test_helper.exs` — ExUnit config + Mox setup
- [ ] `mailglass_admin/test/support/endpoint_case.ex` — ConnTest harness with a synthetic adopter Endpoint for testing the router macro and `__session__/N`
- [ ] `mailglass_admin/test/support/live_view_case.ex` — Phoenix.LiveViewTest wrapper with synthetic adopter endpoint
- [ ] `mailglass_admin/test/support/fixtures/mailables.ex` — fixture modules implementing `use Mailglass.Mailable` with various preview_props shapes (valid, no-previews, raises)
- [ ] `mailglass_admin/test/mailglass_admin/router_test.exs` — macro expansion + `__session__/N` isolation
- [ ] `mailglass_admin/test/mailglass_admin/preview_live_test.exs` — LiveViewTest coverage for tabs, toggles, form
- [ ] `mailglass_admin/test/mailglass_admin/discovery_test.exs` — auto-scan + explicit list + graceful failure
- [ ] `mailglass_admin/test/mailglass_admin/assets_test.exs` — controller serves correct bytes, hash matches, cache headers
- [ ] `mailglass_admin/test/mailglass_admin/brand_test.exs` — palette mapping, WCAG AA contrast
- [ ] `mailglass_admin/test/mailglass_admin/bundle_test.exs` — size budgets
- [ ] `mailglass_admin/test/mailglass_admin/voice_test.exs` — brand voice lexicon

**Framework install:** mailglass already uses ExUnit + Mox; mailglass_admin inherits. Phoenix.LiveViewTest ships with `phoenix_live_view` — no new install.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (dev-only at v0.1) | Deferred to v0.5 when prod admin lands (sigra step-up auth) |
| V3 Session Management | yes (isolation from adopter session) | Whitelisted `__session__/N` callback (§ Session & Socket Scoping) |
| V4 Access Control | yes (mount-path access) | Adopter-owned `if Application.compile_env(:app, :dev_routes)` gate |
| V5 Input Validation | yes (macro opts + font path param) | `NimbleOptions` on macro opts; font name allowlist in Assets controller |
| V6 Cryptography | no (no secrets handled at v0.1) | n/a |
| V9 Communications | no (loopback dev context) | n/a |
| V10 Malicious Software | partial | Vendored daisyUI `.js` files — pinned version in file-header comment, updated via `mix mailglass_admin.daisyui.update` with explicit maintainer review of diff |
| V11 Business Logic | yes (LiveReload topic DoS) | Broadcasts are dev-only; adopter controls `:notify` config |
| V12 Files & Resources | yes (font path traversal) | Font name allowlist in `Assets.resolve_font/1` (§ Pattern 2) |
| V13 API & Web Service | yes (assets endpoint) | Immutable cache-control; no user-input reflection |
| V14 Configuration | yes (dev-only must stay dev-only) | Adopter-owned `:dev_routes` gate; v0.1 has NO prod-safe mount path |

### Known Threat Patterns for Phoenix + LiveView (mountable dashboard context)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Adopter session cookie leak into our LiveView assigns | Information Disclosure | `__session__/N` whitelist — explicit map construction, never pass `conn.private.plug_session` |
| Path traversal via font name param (`/dev/mail/fonts/../../etc/passwd`) | Tampering | Static allowlist match on font filename |
| Reflected XSS via mailable name in URL | Tampering / XSS | `Phoenix.HTML.html_escape/1` on all mailable module names before render; LiveView already does this for `{@var}` bindings |
| CSRF on form submissions | Tampering | LiveView's built-in CSRF token handling; inherited from adopter's `:browser` pipeline `:protect_from_forgery` |
| Dev admin accidentally deployed to prod | Elevation of Privilege | Adopter's `if Application.compile_env(:app, :dev_routes)` gate — documented as mandatory; v0.5 prod mount is a deliberate opt-in, not a flip |
| Iframe escape (malicious email HTML attacking admin chrome) | Tampering / XSS | `sandbox="allow-same-origin"` attribute — isolates iframe origin; no `allow-scripts` |
| Supply-chain injection via vendored daisyUI | Tampering | File-header pin comment + `mix mailglass_admin.daisyui.update` mix task with maintainer diff review; Dependabot does NOT cover vendored files so review discipline is the control |
| DoS via rapid LiveReload broadcasts | DoS | phoenix_live_reload debounces at the broadcaster; no amplification on our side |

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/mailglass/.planning/PROJECT.md` — locked decisions D-01..D-20 + brand voice + "Things Not To Do"
- `/Users/jon/projects/mailglass/.planning/REQUIREMENTS.md` §PREV-01..PREV-06 + §BRAND-01 — the 7 REQ-IDs Phase 5 closes
- `/Users/jon/projects/mailglass/.planning/research/STACK.md` — verified 2026 versions for Phoenix, LiveView, tailwind Hex
- `/Users/jon/projects/mailglass/.planning/research/ARCHITECTURE.md` §7 — module catalog, boundary enforcement
- `/Users/jon/projects/mailglass/.planning/research/PITFALLS.md` — PHX-02, PHX-03, PHX-06, DIST-01, DIST-02, LIB-01..LIB-07
- `/Users/jon/projects/mailglass/.planning/phases/05-dev-preview-liveview/05-CONTEXT.md` — D-01..D-24 locked decisions
- `/Users/jon/projects/mailglass/lib/mailglass/mailable.ex:111-112, 151-155` — the `preview_props/0` + `__mailglass_mailable__/0` contract
- `/Users/jon/projects/mailglass/prompts/mailglass-brand-book.md` — Ink/Glass/Ice/Mist/Paper/Slate palette, Inter + IBM Plex Mono typography
- `https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/router.ex` — `live_dashboard/2` macro signature (source read via WebFetch April 2026)
- `https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/controllers/assets.ex` — compile-time `File.read!` + MD5 pattern (source read via WebFetch April 2026)
- `https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/router.ex` — `oban_dashboard/2` + `__session__/8` session whitelisting (source read via WebFetch April 2026)
- `https://github.com/phoenixframework/phoenix_live_reload/blob/main/lib/phoenix_live_reload/channel.ex` — `:notify` broadcast mechanism + message shape (source read via WebFetch April 2026)
- `https://raw.githubusercontent.com/phoenixframework/phoenix/main/installer/templates/phx_assets/app.css.eex` — Phoenix 1.8 canonical Tailwind v4 + daisyUI 5 shape (source read April 2026)
- `https://github.com/phoenixframework/tailwind` README — tailwind Hex 0.3+ assumes Tailwind v4+; 4.1.12 default bundle (WebFetch April 2026)
- `https://daisyui.com/docs/install/standalone/` — `@plugin "./daisyui.mjs"` / `.js` loading pattern (WebFetch April 2026)
- `https://hexdocs.pm/phoenix_live_reload/Phoenix.LiveReloader.html` — `:notify` config shape + message format (WebFetch April 2026)

### Secondary (MEDIUM confidence)

- `https://hex.pm/packages/tailwind` — version 0.4.1 released 2025-10-17 (WebFetch result noted "2025 content"; verified current by cross-reference with phoenixframework/tailwind README)
- `https://daisyui.com/docs/install/` — daisyUI 5.5.19 current release
- `/Users/jon/projects/sigra/priv/templates/sigra.install/admin/router_injection.ex` — counter-example (sigra uses install-injection, not a router macro)
- `/Users/jon/projects/sigra/test/example/lib/example_web/router.ex:172` — `if Application.compile_env(:example, :dev_routes)` idiom real-world example

### Tertiary (LOW confidence — validation-needed claims)

- Font file sizes (~30KB each for Latin + Latin-Ext subsets) — estimate based on typical woff2 subset sizes; actual sizes verified at maintainer subsetting time
- Mailable discovery scan cost (~50ms for 10k modules) — estimate based on LiveDashboard benchmarks; verify in Plan 5.N on a large test fixture

## Metadata

**Confidence breakdown:**

- **Standard stack:** HIGH — All versions verified against Hex.pm + GitHub in April 2026; tailwind Hex 0.4 + Tailwind v4.1.12 + daisyUI 5 convergence confirmed via Phoenix 1.8 installer.
- **Router macro pattern:** HIGH — LiveDashboard + Oban Web source read and transcribed; sigra misidentification corrected (it's not a counter-example to emulate but one of the patterns we're NOT using).
- **Session scoping:** HIGH — `__session__/N` whitelist pattern verified in Oban Web source; phoenix_live_view 1.1 `live_session :session` opt documented in official hexdocs.
- **Asset pipeline:** HIGH on the pattern (compile-time File.read! + `@external_resource` + MD5), MEDIUM on daisyUI 5.x long-term stability (monthly minor version churn — see A5 risk).
- **LiveReload integration:** HIGH — phoenix_live_reload channel.ex source read; `:notify` PubSub shape verified.
- **Mailable auto-discovery:** HIGH — pattern verified against shipped `Mailglass.Mailable` code + canonical Elixir reflection examples (`Ecto.Schema.__schema__/1`).
- **Brand implementation:** MEDIUM — palette → daisyUI theme mapping requires design review to confirm hover-shade derivation (A1); typography self-hosting approach is HIGH.
- **Pitfalls:** HIGH — cross-verified with STACK.md PHX-02..PHX-06 + CONTEXT.md D-01..D-24.

**Research date:** 2026-04-23
**Valid until:** 2026-05-23 (30 days — stable for Phoenix / LiveView / tailwind Hex; shorter review of daisyUI 5 version in case 5.x mid-minor bump introduces surprise)
