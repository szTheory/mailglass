# Phase 5: Dev Preview LiveView — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 05-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 05-dev-preview-liveview
**Areas discussed:** Package layout, Router macro + dev-only guard, preview_props contract + discovery, Asset pipeline (no-Node promise)
**Mode:** Interactive (user chose all four gray areas + asked for deep parallel research via subagents before presenting)

---

## Gray-area selection

User selected: **all four presented gray areas**, and requested parallel subagent research covering (quote) "pros/cons/tradeoffs of each considering the example for each approach, what is idiomatic for elixir/plug/ecto/phoenix for this type of lib/app and in this ecosystem, lessons learned from other libs/apps in same space even from other languages/frameworks if the are popular successful, what did they do right that we should learn from, what did they do wrong/footguns we can learn from, great developer ergonomics/dx emphasized... user friendly... think deeply one-shot a perfect set of recommendations so i dont have to think, all recommendations are coherent/cohesive with each other and move us toward the goals/vision of this project... using great software architecture/engineering, principle of least surprise and great UI/UX where applicable great dev experience."

Four `gsd-advisor-researcher` agents spawned in parallel with calibration_tier=`standard`.

---

## Package layout & repo shape

| Option | Description | Selected |
|--------|-------------|----------|
| Single flat repo, `mailglass_admin/` as nested sibling directory | Co-located `.planning/`, atomic cross-package PRs, Release Please `separate-pull-requests: false` + linked-versions designed for this, Rails actionmailer/actionmailbox precedent, Phoenix `installer/` precedent | ✓ |
| Mix umbrella (`apps/mailglass/` + `apps/mailglass_admin/`) | Elixir-native monorepo shape | — (rejected: Hex refuses to publish umbrellas, Dialyzer PLT broken in umbrellas since 1.15+, Release Please has no umbrella support) |
| Two fully separate git repos (`mailglass`, `mailglass_admin`) | Matches Oban/ObanWeb + Phoenix/LiveDashboard convention | — (rejected: fragments `.planning/` across two sources of truth, introduces version-drift risk DIST-01 is explicitly preventing, breaks `test/example/` golden-diff CI) |

**User's choice:** Single flat repo, nested sibling dir
**Notes:** Research agent grounded the recommendation against actual repo reads (Oban/ObanWeb → separate, Phoenix/LiveDashboard → separate, Phoenix/installer → nested-in-same-repo precedent, Rails actionmailer/actionmailbox → nested-in-same-repo, React Email → monorepo with packages/+apps/). The two-separate-repos convention is driven by team scale and independent release cadence — neither applies to a single-maintainer v0.1 project with 84 coordinated REQ-IDs and linked-version releases.

---

## Router macro + dev-only guard

### 1. Macro call-site shape

| Option | Description | Selected |
|--------|-------------|----------|
| Plain macro `mailglass_admin_routes("/dev/mail", opts)` imported + called inside adopter's existing scope | LiveDashboard + Oban Web verbatim pattern; one-line mount | ✓ |
| `use MailglassAdmin.Router` + sibling macro | Lets adopter override callbacks; no prior art | — |
| No macro; document raw `scope + live_session + live` block | Zero magic; 15+ lines of boilerplate per adopter | — |

### 2. Dev-only enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Compile-time `Mix.env()` gate in the macro body | Zero-cost in prod; taints library with Mix | — (rejected: Mix unreliable in releases, breaks v0.5 prod-admin flip) |
| Runtime `MailglassAdmin.Plugs.RequireDevEnv` plug | Routes compile everywhere, plug 404s in prod | — |
| **Adopter responsibility** via `if Application.compile_env(:my_app, :dev_routes) do` | Matches `mix phx.new` generated-router convention verbatim; library does nothing | ✓ |
| Soft warn at boot | After-the-fact logging | — |

### 3. live_session wrapping strategy

| Option | Description | Selected |
|--------|-------------|----------|
| **Library wraps `live_session :mailglass_admin_preview` automatically** with `:live_session_name` opt for rename | LiveDashboard + Oban Web pattern; guaranteed isolation | ✓ |
| No wrap — adopter controls | Loses isolation; higher cookie-collision odds | — |
| Optional via opt only | Redundant with (1) | — |

### 4. Session cookie collision avoidance

| Option | Description | Selected |
|--------|-------------|----------|
| **Distinct `live_session` + whitelisted `__session__/N` callback** (Oban Web pattern) | No adopter cookie data reaches our LiveView socket | ✓ |
| Strip-sensitive-keys `on_mount` hook | Runs after socket is assigned; order-dependent | — (complement, not replacement) |
| Accept collision | Violates no-PII doctrine + brand "clear, exact, precision instrument" | — |

### 5. Opts schema

| Option | Description | Selected |
|--------|-------------|----------|
| **Lean: `:mailables`, `:on_mount`, `:live_session_name`, `:as`** | Matches Oban Web's lean schema; easy to extend | ✓ |
| Broad: `:layout, :root_layout, :csp_nonce_assign_key, :socket_path, :preview_path_prefix, :title, :logo_path` | Every opt is a public API contract — regret-inducing | — |
| Zero opts | No filtering, no auth-hook slot for v0.5 flip | — |

**User's choice:** Plain macro + adopter-owned dev-only via `:dev_routes` + library-wrapped isolated `live_session` + whitelisted `__session__/N` + 4-key lean opts
**Notes:** Research agent read actual source from Phoenix LiveDashboard Router, Oban Web Router, and sigra's `priv/templates/sigra.install/admin/router_injection.ex` + `test/example/lib/example_web/router.ex:172`. Phoenix 1.8's own `mix phx.new` generated router is the authoritative dev-only convention (`if Application.compile_env(:app, :dev_routes) do ... live_dashboard "/dashboard"; forward "/mailbox", Plug.Swoosh.MailboxPreview end`). Slotting into that same `:dev_routes` block keeps mailglass_admin consistent with what adopters already know.

---

## preview_props contract + discovery

### 1. Arity resolution

| Option | Description | Selected |
|--------|-------------|----------|
| **Keep shipped `preview_props/0`** | Matches Phase 3 D-12 lock, shipped code at `mailable.ex:111`, test 9 at `mailable_test.exs:131`. No useful `/1` arg exists | ✓ |
| Migrate to `/1` | Would break shipped contract; `/1` arg has no meaningful purpose (preview_name = redundant, conn = conflates concerns, opts = nothing to key off) | — |

### 2. Discovery mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-scan via `:application.get_key/2` + `__mailglass_mailable__/0` marker | Zero adopter config; Rails-like convention; slow on 500+ module apps | — (by itself) |
| Explicit `mailables:` router opt | Deterministic; grep-able; ceremony tax; drift risk | — (by itself) |
| **Hybrid: auto-scan default + `mailables:` opt override** | Best of both; covers umbrella edge case + power-user preference | ✓ |
| Compile-time registry via module attributes | Fragile; compile-order dependent; CLAUDE.md forbids library-level mutable state | — |

### 3. Assigns form UX

| Option | Description | Selected |
|--------|-------------|----------|
| **Type-inferred form (walk map, render input per Elixir type, struct → JSON textarea fallback)** | Zero schema ceremony; React Email-like DX; 3-line preview_props stays 3-line | ✓ |
| Single JSON textarea | Terrible DX for "change one word" | — |
| Adopter-declared schema (`[{atom, %{assigns: map, form: schema}}]`) | Breaks current contract; ceremony tax | — (deferred to v0.5) |
| Hybrid: inference + optional `form_hints` third tuple element | Richer; defer to v0.5 when admin form widgets land | — (deferred to v0.5) |

**User's choice:** Keep `/0` arity + hybrid auto-scan + explicit override + type-inferred form with struct JSON fallback
**Notes:** Research agent read actual Rails `actionmailer/lib/action_mailer/preview.rb` + React Email `preview-server` npm package source. Key insight: `preview_props` is **reflection** (`Ecto.Schema.__schema__/1` family), not **invocation** (`perform/1`, `handle_event/3` family) — reflection callbacks in Elixir are zero-arity universally. The `/1` prose in PROJECT.md / REQUIREMENTS.md / ROADMAP.md is stale pre-D-12-Phase-3 prose that slipped review; Phase 5 Plan 01 includes a one-shot doc-fix commit to rewrite those three files.

---

## Asset pipeline (no-Node promise)

### 1. Build tooling

| Option | Description | Selected |
|--------|-------------|----------|
| **`tailwind` Hex package (~> 0.4) + vendored daisyUI mjs (curled)** | Official Phoenix 1.8 default stack; cross-platform binary; daisyUI 5 + Tailwind v4 no-Node confirmed working via Phoenix installer precedent | ✓ |
| `esbuild` Hex + hand-written CSS from brand palette | No component system; reinvents daisyUI | — (fallback / escape hatch for D-22) |
| `tailwind` Hex + no daisyUI (raw Tailwind v4) | Smallest; utility soup in HEEx | — |
| Custom mix task downloading Tailwind CLI directly | Reinvents `phoenixframework/tailwind` poorly | — |

### 2. daisyUI 5 on Tailwind v4 standalone CLI feasibility

**Verdict: confirmed working.** Phoenix 1.8's own `mix phx.new` installer vendors `daisyui.mjs` (251KB) + `daisyui-theme.mjs` into `assets/vendor/` and loads them via `@plugin "../vendor/daisyui"` in `app.css`. The Tailwind v4 standalone binary embeds the JS runtime executing these ESM plugin bundles at CSS compile time. **Escape hatch if a future Tailwind upgrade breaks the plugin path**: drop to raw Tailwind v4 with brand palette as `@theme` CSS variables (LiveDashboard's 228KB hand-written CSS proves the fallback scales).

### 5. Bundle serving

| Option | Description | Selected |
|--------|-------------|----------|
| **LiveDashboard pattern: compile-time `File.read!` + `@external_resource` + MD5 hash + Plug-style controller** | Zero adopter endpoint edits; cache-control immutable out of the box; no Plug.Static chain conflicts | ✓ |
| Library-side `Plug.Static` auto-mounted in router macro | Adopter `Plug.Static` chain conflicts; prefix collisions | — |
| Embed CSS as `<style>` in LiveView template | Reparsed on every mount; blocks first paint | — |

### Other sub-decisions (one-line picks)

- **(3) Fonts**: self-host Inter/Inter Tight/IBM Plex Mono woff2 subsets — bulletproof against CSP restrictions + GDPR concerns
- **(4) JS footprint**: read Phoenix + LiveView JS at compile time via `Application.app_dir/2`; zero custom JS at v0.1
- **(6) Maintainer LiveReload**: `mix tailwind default --watch` via `Phoenix.CodeReloader` child (Oban Web pattern)
- **(7) Cache busting**: compile-time MD5 content hash baked into URL; `cache-control: public, max-age=31536000, immutable`
- **(8) Tarball budget**: ~400KB expected in `priv/static/` vs 2MB CI gate — 1.6MB headroom

**User's choice:** `tailwind` Hex + vendored daisyUI mjs + LiveDashboard compile-time serving pattern + self-hosted fonts + compile-time Phoenix JS concat + Tailwind watch for maintainer dev + MD5 hash cache-bust + tarball <800KB target
**Notes:** Research agent verified daisyUI 5 + Tailwind v4 + zero Node by reading Phoenix 1.8 installer source (`installer/templates/phx_assets/daisyui.js.eex` at 251,614 bytes) and daisyUI's own standalone install docs. This is the exact stack every new Phoenix 1.8 app ships with. Oban Web's npm-based pipeline is explicitly documented as the **anti-pattern** (violates D-12 no-Node promise). Risk mitigation: pin `config :tailwind, version: "4.1.12"` + pin daisyUI mjs version in file-header comment + CI `git diff --exit-code priv/static/` + `mix mailglass_admin.daisyui.update` helper task catches drift.

---

## Claude's Discretion

- Exact pixel widths for device toggle (375/768/1024 recommended baseline; research finalizes)
- `mailglass_admin/lib/` directory layout (Phoenix conventions apply)
- Error card visual layout inside preview pane (brand-book aligned; Signal Amber border, IBM Plex Mono stacktrace)
- How sidebar handles 50+ mailables (search bar? grouping heuristic? — deferred to Plan unless user flags)
- Exact content of Raw tab (full RFC 5322 envelope vs `inspect(%Swoosh.Email{})` — research phase finalizes)

---

## Deferred Ideas (surfaced during discussion, captured in CONTEXT.md `<deferred>` section)

- Richer `preview_props` schema with `form_hints` → v0.5
- Dark-mode email-client simulation → v0.5+
- Adopter-configurable device widths → v0.5
- Search / filter / pagination over mailables → v0.5
- Preview snapshot diffing → v0.5+
- `:layout` / `:root_layout` / `:csp_nonce_assign_key` / `:socket_path` router opts → v0.5+
- Prod-safe admin mount with auth → v0.5 DELIV-05
- `mailglass_inbound` Conductor LiveView → v0.5+ (separate sibling)

---

## Research-phase handoff

This phase is **flagged for `/gsd-research-phase`** per ROADMAP.md (research flags table). The research phase should verify:

1. Exact Tailwind Hex package version supporting Tailwind v4 + whether `config :tailwind, version: "4.1.12"` pin is the right number (April 2026 state)
2. daisyUI 5 mjs plugin loading under Tailwind v4 standalone — re-verify via direct build test if possible
3. Phoenix LiveDashboard's `Phoenix.LiveDashboard.Assets` module — exact `File.read!` + `@external_resource` + MD5 hash + controller shape to mirror
4. Oban Web's `Oban.Web.Router.__session__/8` exact signature + argument list — mailglass_admin's `__session__/N` callback should mirror
5. Phoenix LiveReload 2026 hook mechanism — PubSub channel name, message shape, subscription API for mailglass_admin's PreviewLive
6. Device-width breakpoint finalization (375/768/1024 vs 390/834/1280) against current 2026 device-share data
7. Font subset requirements — Inter / Inter Tight / IBM Plex Mono Latin + Latin-Ext minimum subset, confirm woff2 file sizes against <800KB priv/static/ budget

After research completes, planning can proceed directly from research output + this CONTEXT.md.
