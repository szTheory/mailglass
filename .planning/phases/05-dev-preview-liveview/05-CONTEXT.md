# Phase 5: Dev Preview LiveView — Context

**Gathered:** 2026-04-23
**Status:** Ready for research (this phase is flagged for `/gsd-research-phase` before `/gsd-plan-phase`)

<domain>
## Phase Boundary

**Ship `mailglass_admin` v0.1.0 as a sibling Hex package to `mailglass` 0.1.0.** The single deliverable is the dev-only preview LiveView: a Phoenix 1.8 adopter adds `mailglass_admin_routes "/mail"` inside their existing `if Application.compile_env(:my_app, :dev_routes) do ... end` router block and opens `/dev/mail` to see a sidebar of auto-discovered mailables (each module's `preview_props/0` entries), pick a preview scenario, edit the assigns inline, and inspect HTML / Text / Raw / Headers tabs with device-width + dark toggles. LiveReload refreshes the preview when the adopter saves a mailable file.

**Out of scope (belongs elsewhere):**
- Prod-mountable admin LiveView (sent-mail inbox, event timeline, resend, suppression UI) — v0.5 (DELIV-05)
- Auth / step-up / sigra integration — v0.5 (when prod mount lands)
- Search / filter / pagination over mailables or scenarios — v0.5
- Any webhook replay or admin CRUD surface — v0.5
- `mailglass_inbound` Conductor dev LiveView — v0.5+ (separate sibling package)

Phase 5 is the v0.1 **killer demo** (per research/SUMMARY.md Phase 5). Differentiator vs Rails ActionMailer::Preview (no props editing), React Email + Mailing.dev (Node toolchain required), and Mailpit/Mailcatcher (external SMTP service, not mounted).
</domain>

<decisions>
## Implementation Decisions

### Package layout (D-01)

- **D-01:** `mailglass_admin/` ships as a **nested sibling directory** inside the existing `/Users/jon/projects/mailglass` git repo with its own `mix.exs`, `lib/`, `test/`, `assets/`, `priv/static/`. **Not** an Elixir umbrella (Hex refuses to publish umbrellas; Dialyzer PLT broken in umbrellas since Elixir 1.15+). **Not** a separate git repo (would fragment `.planning/` across two sources of truth, introduce version-drift risk DIST-01 is explicitly trying to prevent, and break the `test/example/` golden-diff CI from testing both packages atomically).
- **D-02:** Local-dev dep resolution uses `{:mailglass, path: "..", override: true}` in `mailglass_admin/mix.exs` **gated** by `if Mix.env() != :prod` (or equivalent env var check). Published (Hex) dep is `{:mailglass, "== <pinned_version>"}` per PREV-01 / DIST-01. The switch lives inside a conditional so contributors never manually edit `mix.exs` to flip between path and Hex deps.
- **D-03:** Release Please configuration (full wiring lands in Phase 7) uses `separate-pull-requests: false` + the linked-versions plugin with a `packages` map covering both `.` (root = `mailglass`) and `./mailglass_admin/`. Coordinated release PRs bump both versions atomically. The Rails `actioncable/actionmailer/actionmailbox` monorepo shape is the explicit precedent; Phoenix's `installer/` nested-mix.exs proves nested `mix.exs` publishes cleanly to Hex.
- **D-04:** `mailglass_admin/mix.exs` `package[:files]` list whitelists `lib priv/static .formatter.exs mix.exs README* CHANGELOG* LICENSE*` — excludes `assets/` source (vendored daisyUI + Tailwind input) per LiveDashboard / Oban Web precedent. CI `git diff --exit-code priv/static/` after `mix mailglass_admin.assets.build` is the merge gate (PREV-06).

### Router macro shape (D-05..D-09)

- **D-05:** Public API is **one macro**, `MailglassAdmin.Router.mailglass_admin_routes(path, opts \\ [])`, imported into the adopter's router with `import MailglassAdmin.Router`. No `use` module, no behaviour, no config-file registration. Mirrors `Phoenix.LiveDashboard.Router.live_dashboard/2` and `Oban.Web.Router.oban_dashboard/2` verbatim — "one line in your router, done."
- **D-06:** **Dev-only is the adopter's responsibility**, enforced via Phoenix 1.8's `if Application.compile_env(:my_app, :dev_routes) do ... end` idiom — the same wrapper that already gates `live_dashboard` and `Plug.Swoosh.MailboxPreview` in `mix phx.new`-generated routers. The library **must not** introduce `Mix.env()` checks into its macro body: Mix is unreliable in release builds (always `:prod`), taints library code with build-tool coupling, and would make v0.5's planned prod-admin flip a breaking macro change rather than a README change. Adopter-owned `:dev_routes` flag is the single seam.
- **D-07:** The macro expands to `scope path, alias: false, as: false do ... live_session session_name, session_opts do ... live "/", MailglassAdmin.PreviewLive, :index ... end end`. The `live_session` is **library-owned** (default name `:mailglass_admin_preview`) to guarantee isolation from the adopter's live_sessions — cross-live-session navigation forces a full remount, so our socket starts clean every time.
- **D-08:** Session isolation uses a **whitelisted `__session__/N` callback** (Oban Web pattern). Our `live_session`'s `session:` opt points at `MailglassAdmin.Router.__session__/N` which **never** passes the adopter's `conn.private.plug_session` through — it constructs an explicit map containing only the keys our LiveView needs (e.g., `"mailables"`). This directly satisfies the no-PII doctrine (D-08 in Phase 1 / CORE-03 / Phase 6 `NoPiiInTelemetryMeta`) and eliminates the research-flagged cookie-collision risk. Adopter cookies cannot leak into our LiveView assigns.
- **D-09:** Opts schema is **Oban-Web-lean**: four keys, all validated by a private `validate_opt!/1` that raises `ArgumentError` on unknown keys. Keys: `:mailables` (atom `:auto_scan` default, or an explicit `[MyApp.UserMailer, ...]` list), `:on_mount` (list of extra on_mount hooks appended **before** the internal `MailglassAdmin.Preview.Mount`), `:live_session_name` (atom, default `:mailglass_admin_preview`), `:as` (atom, default `:mailglass_admin`). **Deliberately omitted at v0.1**: `:layout`, `:root_layout`, `:csp_nonce_assign_key`, `:socket_path`, `:logo_path`, `:title`. Every opt is a public API contract once shipped; Oban Web took five years to land each of theirs and they are all now backward-compat tax. Adopters can ask.

### preview_props contract + mailable discovery (D-10..D-13)

- **D-10:** **Arity locked at `/0`** — the shipped code in `lib/mailglass/mailable.ex:111-112` (`@optional_callbacks preview_props: 0` + `@callback preview_props() :: [{atom(), map()}]`) is the canonical contract. Test 9 in `test/mailglass/mailable_test.exs:131-135` codifies this. The `/1` prose in PROJECT.md line 52, REQUIREMENTS.md line 130 (PREV-03), and ROADMAP.md lines 22, 114, 119 is **stale pre-D-12-Phase-3 prose** that slipped review. No useful `/1` argument exists: a `preview_name` arg defeats the list-variant-enumeration idiom; `%Plug.Conn{}` conflates render-time concerns into a reflection callback; `opts` has nothing to key off. Rails `ActionMailer::Preview` uses zero-arity methods; React Email's `PreviewProps` is a static component export; Elixir's own reflection callbacks (`Ecto.Schema.__schema__/1`, `Phoenix.Component.__components__/0`) are all zero-arity. **Action item in Phase 5 Plan 01 (doc-fix)**: rewrite `/1` to `/0` in PROJECT.md L52, REQUIREMENTS.md L130, ROADMAP.md L22/L114/L119.
- **D-11:** Return shape is `[{preview_name_atom, default_assigns_map}]`. Example:
  ```elixir
  def preview_props do
    [
      welcome_default: %{user: %User{name: "Ada"}, team: %Team{name: "Analytical Engines"}},
      welcome_enterprise: %{user: ..., team: ..., plan: :enterprise}
    ]
  end
  ```
  Each tuple represents a discrete preview scenario; the sidebar nests them under the mailable module name (collapsible `Mailer → scenarios`, not a tab strip — tabs die on mobile + break past 4 variants).
- **D-12:** **Discovery is hybrid** — `:auto_scan` (default) iterates `:application.get_key(adopter_app, :modules)` filtering by `function_exported?(mod, :__mailglass_mailable__, 0)` and `mod.__mailglass_mailable__() == true` (the `@before_compile` marker shipped in Phase 3 at `mailable.ex:154` exists specifically for this auto-scan). The explicit `mailables: [MyApp.UserMailer, ...]` opt is an **override** for umbrella apps with multiple OTP app names, pathological module counts, or adopter-power-user preference. Discovery runs in `MailglassAdmin.Preview.Mount` on_mount hook; rescan on LiveReload broadcast.
- **D-13:** **Graceful failure modes** (LiveDashboard + Oban Web precedent):
  - Mailable with `__mailglass_mailable__/0` but no `preview_props/0` defined → sidebar entry shown with "No previews defined" stub card on selection. Does not crash the LiveView.
  - `preview_props/0` raises → `try/rescue` in discovery returns `{:error, formatted_stacktrace}`; sidebar entry shows a warning badge; selecting it renders an in-place error card with the stacktrace; rest of dashboard stays live.

### Preview UX (D-14..D-15)

- **D-14:** **Assigns form is type-inferred** — walk the scenario's `map()`, render one input per top-level key by Elixir type: `binary` → text, `integer` → number, `boolean` → checkbox, `atom` → select populated from runtime introspection, `DateTime` → `datetime-local`, nested map/struct → labeled JSON textarea fallback (label = `inspect(struct_module)`). Editing any field re-calls the mailable's render function with the edited assigns and pipes through `Mailglass.Renderer.render/1`. No adopter-declared schema at v0.1; richer per-entry `form_hints: keyword()` deferred to v0.5 (admin release has richer form widgets landing anyway).
- **D-15:** **Four tabs content (PREV-03 locks existence; this locks content)** — defer exact contents to research/plan:
  - **HTML**: iframe with the full rendered inline-CSS HTML, sandboxed appropriately
  - **Text**: monospace rendering of the auto-generated plaintext
  - **Raw**: the full RFC 5322 envelope (headers + boundary + parts) — recommend full envelope over `inspect(%Swoosh.Email{})`, but research phase should verify the Swoosh rendering approach
  - **Headers**: key-value table of all headers including auto-injected (`Message-ID`, `Date`, `Mailglass-Mailable`, `Feedback-ID` when configured)
- **D-16:** **Device + dark toggles** — device widths are the Phoenix 1.8 daisyUI breakpoint alignment: 375 (mobile), 768 (tablet), 1024 (desktop). Research phase finalizes. Dark toggle at v0.1 is **chrome-only** (toggles the surrounding admin UI; does not inject `prefers-color-scheme: dark` into the rendered email) — simulating email-client dark mode is a v0.5+ feature requiring per-provider heuristics.

### Asset pipeline (D-17..D-22)

- **D-17:** **daisyUI 5 + Tailwind v4 on zero Node is viable and confirmed** — Phoenix 1.8's own `mix phx.new` installer vendors `daisyui.mjs` (~251KB) + `daisyui-theme.mjs` into `assets/vendor/` and loads them via `@plugin "../vendor/daisyui"` in the generated `app.css`. The Tailwind v4 standalone binary (downloaded by the `tailwind` Hex package) embeds the JS runtime that executes ESM plugin bundles at CSS compile time. This is the same stack every new Phoenix 1.8 app ships with.
- **D-18:** **Build tooling**: `{:tailwind, "~> 0.4", only: :dev, runtime: false}` in `mailglass_admin/mix.exs`. No `:esbuild` dep at v0.1 (no custom JS — pure LiveView). Vendored artifacts committed to the repo:
  - `mailglass_admin/assets/css/app.css` (Tailwind input with `@theme` block for Ink/Glass/Ice/Mist/Paper/Slate, `@plugin` directives, `@font-face`)
  - `mailglass_admin/assets/vendor/daisyui.mjs` (curled from daisyUI releases)
  - `mailglass_admin/assets/vendor/daisyui-theme.mjs` (curled from daisyUI releases)
  - `mailglass_admin/priv/static/app.css` (**compiled output, committed**)
  - `mailglass_admin/priv/static/fonts/*.woff2` (Inter + Inter Tight + IBM Plex Mono subsets)
  - `mailglass_admin/priv/static/mailglass-logo.svg`
- **D-19:** **Mix tasks**:
  - `mix mailglass_admin.assets.build` → `mix tailwind default --minify`
  - `mix mailglass_admin.assets.watch` → `mix tailwind default --watch` (maintainer dev loop)
  - `mix mailglass_admin.daisyui.update` → curls latest `daisyui.mjs` + `daisyui-theme.mjs` into `assets/vendor/`, prints new version for changelog.
- **D-20:** **Bundle serving is the `Phoenix.LiveDashboard.Assets` pattern — NOT Plug.Static**. A `MailglassAdmin.Controllers.Assets` module reads `priv/static/app.css` and concatenated `phoenix.js` + `phoenix_live_view.js` at **compile time** via `File.read!/1` + `@external_resource`, computes MD5 hashes for cache-busting, and serves via routes wired from the macro (`get "/assets/app-:hash.css"`, `get "/assets/app-:hash.js"`). Sets `cache-control: public, max-age=31536000, immutable`. Phoenix + LiveView JS is pulled from `Application.app_dir(:phoenix, "priv/static/phoenix.js")` + `Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.js")` — doesn't charge mailglass_admin's tarball. **Adopter makes zero endpoint.ex edits** — the macro wires everything.
  - **Anti-pattern explicitly rejected**: Oban Web's npm-based `cmd --cd assets npm install` + esbuild pipeline. It would violate the no-Node promise (D-12 in PROJECT.md) and is the model **not** to copy here.
- **D-21:** **Fonts self-hosted** — Inter (400/500/700), Inter Tight (600/700 display), IBM Plex Mono (400/600) as woff2 subsets (Latin + Latin-Ext only). Budget ~150-200KB total. Rejects Google Fonts (GDPR exposure even for dev-only) and Bunny Fonts (adds network dep breaking offline dev). Adopter CSPs frequently block external font hosts; self-hosted is bulletproof.
- **D-22:** **Pinning discipline for daisyUI drift** — `config :tailwind, version: "4.1.12"` in `mailglass_admin/config/config.exs` (don't track latest blindly). Pin daisyUI version in a file-header comment at the top of `daisyui.mjs`. The CI `git diff --exit-code priv/static/` + `mix mailglass_admin.daisyui.update` helper task catch forgotten rebuilds. Escape hatch if daisyUI 5 breaks on a future Tailwind upgrade: drop to raw Tailwind v4 + hand-written components using the brand palette as `@theme` CSS variables (LiveDashboard's 228KB hand-crafted SCSS proves the fallback scales to a more complex admin surface than v0.1 will ever need).
- **D-23:** **Hex tarball budget** — target <800KB in `priv/static/`: compiled+purged CSS 80-120KB, fonts 200KB, logo/icons <20KB. Phoenix + LiveView JS read from `Application.app_dir/2` at compile time, doesn't charge mailglass_admin's tarball. Leaves >1.2MB headroom under the PREV-06 2MB gate.

### LiveReload integration (D-24)

- **D-24:** Depend on `phoenix_live_reload` as a **dev-only optional dep** in `mailglass_admin/mix.exs` (`optional: true`, `only: :dev`). Hook into the adopter's existing LiveReload broadcast — when an adopter edits `lib/my_app/user_mailer.ex`, the beam-reload triggers a PubSub message on `phoenix_live_reload:` channel; mailglass_admin's PreviewLive subscribes and refreshes the sidebar + current preview. No bespoke file-watching in our code. If adopter has LiveReload disabled, the admin still works — adopter just refreshes the browser manually.

### Deferred to v0.5+ (captured, not lost)

- Richer per-entry `preview_props` schema (e.g., `form_hints` keyword)
- Prod-safe admin mount (auth via sigra, step-up on destructive actions)
- Dark-mode email-client simulation (inject `prefers-color-scheme: dark`)
- `:layout`, `:root_layout`, `:csp_nonce_assign_key`, `:socket_path`, `:logo_path`, `:title` macro opts
- Sent-mail inbox / event timeline / suppression UI / resend / replay-from-raw (all DELIV-05)

### Claude's Discretion

- Exact pixel widths for device toggle — research phase finalizes against brand book; 375/768/1024 is the recommended starting point
- Exact directory layout inside `mailglass_admin/lib/` (Phoenix conventions apply; nothing load-bearing on naming)
- File-header comment format for pinning daisyUI version
- Error card layout inside the preview pane (brand-book-aligned; monospace stacktrace in IBM Plex Mono, Signal Amber border)
- How the sidebar handles 50+ mailables at auto-scan time (search bar? grouping heuristic? — deferred to Plan unless user flags it)

### Folded Todos

None — no pending todos matched Phase 5 scope.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before planning or implementing.**

### Project-level source of truth
- `/Users/jon/projects/mailglass/.planning/PROJECT.md` — locked decisions D-01..D-20; brand voice section; "Things Not To Do" short list
- `/Users/jon/projects/mailglass/.planning/REQUIREMENTS.md` §PREV-01..PREV-06 + §BRAND-01 — the 7 REQ-IDs Phase 5 closes
- `/Users/jon/projects/mailglass/.planning/ROADMAP.md` Phase 5 section (lines 113-126) — goal, success criteria, pitfalls guarded against, research flags
- `/Users/jon/projects/mailglass/.planning/STATE.md` — current progress (71% — phases 1-4 complete)
- `/Users/jon/projects/mailglass/CLAUDE.md` — project-level conventions and the "Things Not To Do" short list
- `/Users/jon/projects/mailglass/.planning/research/SUMMARY.md` Phase 5 section + "The killer demo" framing + Research Flags table
- `/Users/jon/projects/mailglass/.planning/research/STACK.md` — Tailwind / daisyUI / LiveView version pins; optional dep gateway pattern
- `/Users/jon/projects/mailglass/.planning/research/ARCHITECTURE.md` §7 (boundary blocks) — MailglassAdmin module catalog + boundary enforcement
- `/Users/jon/projects/mailglass/.planning/research/PITFALLS.md` — PHX-02 (mount path), PHX-03 (tarball size), PHX-06 (PubSub prefix), DIST-01 (sibling version drift), DIST-02 (priv/static/ diff gate)

### Brand + domain language (authoritative source)
- `/Users/jon/projects/mailglass/prompts/mailglass-brand-book.md` — Ink/Glass/Ice/Mist/Paper/Slate palette, Inter + Inter Tight + IBM Plex Mono typography, mobile-first, no glassmorphism / bevels / literal broken glass; §5 voice + tone; §7.3 color system with recommended usage split; §12 accessibility guardrails
- `/Users/jon/projects/mailglass/prompts/mailer-domain-language-deep-research.md` — Mailable / Message / Delivery / Event vocabulary; avoid "Email" / "Notification" as ambiguous primitives
- `/Users/jon/projects/mailglass/prompts/mailglass-engineering-dna-from-prior-libs.md` — `use` macro budget ≤20 lines, optional dep gateway pattern, behaviour-first design

### Prior phase context (carry-forward decisions)
- `/Users/jon/projects/mailglass/.planning/phases/03-transport-send-pipeline/03-CONTEXT.md` §D-12 — locked `preview_props/0` arity; Mailable `@before_compile def __mailglass_mailable__, do: true` marker at `lib/mailglass/mailable.ex:154`
- `/Users/jon/projects/mailglass/.planning/phases/01-foundation/01-CONTEXT.md` — Component library + Renderer pipeline shape that Phase 5 LiveView renders against

### Shipped code Phase 5 consumes
- `/Users/jon/projects/mailglass/lib/mailglass/mailable.ex` (lines 111-112 callback, 154 marker) — the `preview_props/0` + `__mailglass_mailable__/0` contract
- `/Users/jon/projects/mailglass/lib/mailglass/renderer.ex` — the pure-function `render/1` pipeline the preview tabs consume
- `/Users/jon/projects/mailglass/lib/mailglass/message.ex` — `%Mailglass.Message{}` struct shape (with `:mailable`, `:mailable_function`, and Swoosh.Email inside)
- `/Users/jon/projects/mailglass/lib/mailglass/components/` — HEEx components `<.container>`, `<.button>`, etc. that the preview renders
- `/Users/jon/projects/mailglass/test/mailglass/mailable_test.exs` (test 9, lines 131-135) — confirms `/0` arity + optional callback semantics

### External prior-art (verified by research agents)
- [Phoenix LiveDashboard router](https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/router.ex) — `live_dashboard/2` macro signature precedent
- [Phoenix LiveDashboard Assets](https://github.com/phoenixframework/phoenix_live_dashboard) — `priv/static/` compile-time `File.read!` + MD5 hash + Plug controller pattern (MANDATORY reading for D-20 implementation)
- [Oban Web router](https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/router.ex) — `oban_dashboard/2` macro + `__session__/N` whitelisting callback (pattern for D-08)
- [Phoenix 1.8 installer phx_assets templates](https://github.com/phoenixframework/phoenix/tree/main/installer/templates/phx_assets) — `daisyui.js.eex` + `daisyui-theme.js.eex` + `app.css.eex` + Tailwind v4 config (the canonical "no-Node daisyUI 5 + Tailwind v4" recipe)
- [tailwind Hex package](https://hex.pm/packages/tailwind) — v0.4.x, Tailwind v4 default since 0.3.0
- [daisyUI standalone install](https://daisyui.com/docs/install/standalone/) — confirms standalone CLI + vendored mjs path
- [Release Please manifest-releaser](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — linked-versions + `separate-pull-requests: false` config shape for D-03
- [Rails actionmailer monorepo structure](https://github.com/rails/rails/tree/main/actionmailer) — nested-sibling-dir precedent
- `/Users/jon/projects/sigra/priv/templates/sigra.install/admin/router_injection.ex` — sigra's install-template approach (read as a counter-example — mailglass_admin is a mountable Hex package, not an installed framework)
- `/Users/jon/projects/sigra/test/example/lib/example_web/router.ex:172` — real-world `if Application.compile_env(:example, :dev_routes)` wrapper idiom (the pattern D-06 slots into)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets (Phase 5 consumes; does not modify)
- **`Mailglass.Mailable` behaviour** (`lib/mailglass/mailable.ex`): `@optional_callbacks preview_props: 0` + `@callback preview_props() :: [{atom(), map()}]` (line 111) + `@before_compile def __mailglass_mailable__, do: true` (line 154). These two together make auto-scan discovery trivial.
- **`Mailglass.Renderer`** (`lib/mailglass/renderer.ex`): pure `render/1` returning `{:ok, {html, text, headers}}` — the preview LiveView calls this directly on the mailable's built message, same path production uses (PREV-03 "no placeholder shape divergence").
- **`Mailglass.Message`** (`lib/mailglass/message.ex`): struct wraps `%Swoosh.Email{}` + carries `:mailable`, `:mailable_function`, `:assigns`; preview consumes this as-is.
- **`Mailglass.Components`** (`lib/mailglass/components/`): the HEEx component library the rendered preview uses (inline in the adopter's mailable). Preview LiveView is agnostic — it renders whatever Renderer outputs.

### Established patterns
- **`use` macro budget ≤20 lines** — the Mailable injection proves the 15-line target is hittable; MailglassAdmin.Router's macro should aim similarly lean.
- **Optional-dep gateway via `Mailglass.OptionalDeps.*`** — `phoenix_live_reload` is a dev-only optional dep; if Phase 5 needs any runtime probe, route it through a new `MailglassAdmin.OptionalDeps.*` gateway (or use a one-line `Code.ensure_loaded?/1` guard at the call site since D-24 keeps LiveReload strictly dev).
- **Custom Credo checks land in Phase 6** — `PrefixedPubSubTopics` means every `Phoenix.PubSub.broadcast` topic in mailglass_admin must be `mailglass:...` (most likely `mailglass:admin:preview:<mailable>`); `NoPiiInTelemetryMeta` means telemetry from PreviewLive uses only whitelisted keys; `NoUnscopedTenantQueryInLib` does not apply (dev-only, no DB queries at v0.1, but keep it in mind for v0.5 admin).
- **Brand book voice in copy** — error cards say "Delivery blocked: recipient is on the suppression list" not "Oops!"; empty-state copy explains *why* ("This mailable defines no preview scenarios yet — add `def preview_props do [...] end`"); buttons use strong verbs (Preview, Render, Refresh) not passive phrases.

### Integration points
- **Adopter's router.ex**: one `import MailglassAdmin.Router` + one `mailglass_admin_routes "/mail"` line inside their existing `if Application.compile_env(:my_app, :dev_routes)` scope
- **Adopter's endpoint.ex**: **zero changes** required (LiveDashboard-style compile-time asset serving routes via the macro)
- **Adopter's `lib/my_app/user_mailer.ex`**: optional `def preview_props do [...] end` — auto-discovered, no config
- **Adopter's Phoenix.PubSub** (from `:phoenix_pubsub` which `:phoenix` pulls in): used for LiveReload broadcast subscription — mailglass_admin's PreviewLive subscribes to the adopter's pubsub under `mailglass:admin:*` topics per SEND-05 / LINT-06
</code_context>

<specifics>
## Specific Ideas

- **Killer-demo moment**: adopter writes a 3-line `preview_props/0`, hits save, LiveReload fires, new scenarios appear in sidebar without a refresh. This end-to-end polish is the v0.1 differentiator.
- **Sidebar hierarchy** (mobile-first, Ink/Glass/Ice palette, collapsible groups):
  ```
  ┌─ Mailers ───────────────────────────┐
  │  ▼ MyApp.UserMailer                 │  ← Ink #0D1B2A header
  │    · welcome_default           ●    │  ← Glass #277B96 left-bar active
  │    · welcome_new_user               │
  │    · welcome_enterprise             │
  │  ▼ MyApp.AdminMailer                │
  │    · invoice_paid                   │
  │  ▸ MyApp.BrokenMailer  ⚠           │  ← preview_props raised; Signal Amber badge
  │  ▸ MyApp.StubMailer    —            │  ← no preview_props defined
  └─────────────────────────────────────┘
  ```
- **Adopter writes 4 total lines in their router** for the full Phase 5 feature set (verbatim from `mix phx.new`-generated router pattern):
  ```elixir
  import MailglassAdmin.Router

  if Application.compile_env(:my_app, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"
    end
  end
  ```
- **Phase 5 first plan should be a small doc-fix**: rewrite `preview_props/1` → `preview_props/0` in PROJECT.md L52, REQUIREMENTS.md L130, ROADMAP.md L22/L114/L119 as a pre-work commit (resolves the canonical-docs / code discrepancy before any Phase 5 code lands).
</specifics>

<deferred>
## Deferred Ideas

- **Richer `preview_props` schema with `form_hints`** — adopter-declared input widgets (select options, radio groups, readonly fields) → v0.5 admin release when richer form widgets are being built for suppression/event UIs anyway
- **Dark-mode email-client simulation** — inject `@media (prefers-color-scheme: dark)` into the preview iframe so adopters see how their email renders for dark-mode users → v0.5+ (requires per-provider heuristics; Gmail strips it, Outlook partially honors it, Apple Mail respects it)
- **Device-width customization** — adopter-configurable preview widths beyond 375/768/1024 → v0.5
- **Search / filter / pagination over mailables** — v0.5 when mailable counts grow past casual scannable lists
- **Preview snapshot diffing** — visual regression testing between renders → v0.5+ (admin release)
- **Adopter-declared `:layout` / `:root_layout` / `:csp_nonce_assign_key`** — every Oban Web opt is now a compat tax; wait for adopter to ask → v0.5+
- **Prod-safe admin mount with auth** — step-up via sigra, destructive actions like resend/replay → v0.5 DELIV-05
- **`mailglass_inbound` Conductor LiveView** — synthesize/replay inbound mail → v0.5+ (separate sibling package)
- **Reviewed Todos (not folded)**: None — cross-reference check returned no pending todos matching Phase 5 scope.
</deferred>

---

*Phase: 05-dev-preview-liveview*
*Context gathered: 2026-04-23*
*Next: `/gsd-research-phase 5` (this phase is flagged for research per roadmap) then `/gsd-plan-phase 5`*
