# Phase 1: Foundation — Research

**Researched:** 2026-04-22
**Domain:** Elixir/Phoenix OSS library foundation — Error hierarchy, Config, Telemetry, pure HEEx rendering pipeline
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Error hierarchy (CORE-01):**
- D-01: Six sibling `defexception` modules: `Mailglass.SendError`, `Mailglass.TemplateError`, `Mailglass.SignatureError`, `Mailglass.SuppressedError`, `Mailglass.RateLimitError`, `Mailglass.ConfigError`. No parent struct.
- D-02: `Mailglass.Error` is a namespace + behaviour module (not a struct). Exports: `@type t :: union of six error structs`, `@callback type(t) :: atom`, `@callback retryable?(t) :: boolean`, public helpers `is_error?/1`, `kind/1`, `retryable?/1`, `root_cause/1`.
- D-03: Common field set on every error struct: `:type` (closed atom), `:message` (computed in `new/1`), `:cause` (another exception OR nil), `:context` (`%{atom => primitive}` map, PII-free).
- D-04: Per-kind field specializations: `RateLimitError.retry_after_ms :: non_neg_integer`, `SignatureError.provider :: atom`, `SendError.delivery_id :: binary | nil`.
- D-05: All six are `defexception` (raisable). Bang variants use `raise`; non-bang callers get `{:error, struct}`.
- D-06: `Jason.Encoder` derived on `[:type, :message, :context]` only — `:cause` excluded from JSON serialization.
- D-07: Closed `:type` atom sets per struct documented in `api_stability.md` with `__types__/0` function. Adding requires CHANGELOG + `@since`; removals require major bump. Atom sets locked as:
  - `SendError.type ∈ :adapter_failure | :rendering_failed | :preflight_rejected | :serialization_failed`
  - `TemplateError.type ∈ :heex_compile | :missing_assign | :helper_undefined | :inliner_failed`
  - `SignatureError.type ∈ :missing | :malformed | :mismatch | :timestamp_skew`
  - `SuppressedError.type ∈ :address | :domain | :tenant_address`
  - `RateLimitError.type ∈ :per_domain | :per_tenant | :per_stream`
  - `ConfigError.type ∈ :missing | :invalid | :conflicting | :optional_dep_missing`
- D-08: Pattern-match by struct only. No message-string matching. Enforced by Phase 6 Credo check.
- D-09: Retry policy defaults via `retryable?/1`. `SignatureError` and `ConfigError` return `false`. Others context-dependent.

**MSO/Outlook VML fallback strategy (AUTHOR-02):**
- D-10: Surgical VML. VML only where genuinely required.
- D-11: VML per component: `<.preheader>` no, `<.container>` no, `<.section>` no, `<.row>` yes (ghost table), `<.column>` yes (ghost td), `<.heading>` no, `<.text>` no, `<.button>` yes (`<v:roundrect>`), `<.img>` no, `<.link>` no, `<.hr>` no.
- D-12: Layout `<head>` emits MSO OfficeDocumentSettings XML + color-scheme metas once in `layout/1`.
- D-13: Dark mode deferred to v0.5.
- D-14: Premailex MUST preserve conditional comments (PR #37 merged June 2019 — behavior is default; no option needed).
- D-15: Floki plaintext runs on pre-VML logical component tree, not final HTML.

**Component API style (AUTHOR-02):**
- D-16..D-25: Per-component hybrid with brand-theme tokens. Phoenix 1.8 `core_components.ex` conventions (slot + `class` + `:global` rest). Theme map via `:persistent_term`. Variant enums with compile-time warnings via `values:`. `data-mg-plaintext` strategy attributes for custom Floki walker. Gettext adopter-responsibility inside slots. Required `alt` on `<.img>`. No `style` in `:global` on content components.

**Telemetry enforcement (CORE-03):**
- D-26..D-33: Convention + Phase 6 Credo only (no runtime wrapper). Named span helpers per domain. `render_span/2` in Phase 1. 4-level event path. Metadata whitelist enforced at lint time in Phase 6. OpenTelemetry is adopter-owned. Phase 1 property test on telemetry metadata keys.

**Shared / Claude's Discretion:**
- `Mailglass.Config` NimbleOptions schema minimal in Phase 1 (theme, telemetry, renderer knobs, optional-dep flags); expands per phase.
- `Mailglass.Repo.transact/1` scaffolded in Phase 1 with placeholder doctest; no schema tests yet.
- `Mailglass.IdempotencyKey` sanitization heuristics are Claude's call.
- Error `message` string formatting per `:type` — brand-voice-conformant.
- `boundary` blocks for modules that exist in Phase 1 only.
- `Mailglass.Components.layout/1` exact HEEx structure — follow referenced research.

### Deferred Ideas (OUT OF SCOPE for Phase 1)

- Mailable behaviour (Phase 3)
- Outbound facade (Phase 3)
- Delivery/Event/Suppression schemas (Phase 2)
- Adapter behaviour (Phase 3)
- Webhook plug (Phase 4)
- Admin LiveView (Phase 5)
- Credo checks (Phase 6)
- Installer (Phase 7)
- Dark-mode theme variants (v0.5)
- `<.bare_button>` primitive component
- MJML TemplateEngine implementation (behaviour ships, implementation deferred)
- `OpenTelemetry.attach_otel/0` helper (adopter-owned)
- `tailwind-merge`-style class composition helper
- `telemetry_registry` for event discovery
- `Jason.Encoder` on `:cause` chain

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-01 | Six-struct error hierarchy with closed `:type` atom sets documented in `api_stability.md` | D-01..D-09 locked; sigra prior art confirms `defexception` sibling pattern with per-kind fields |
| CORE-02 | `Mailglass.Config` validated via NimbleOptions at boot; only module allowed to use `Application.compile_env*` | Sigra.Config reference impl confirms NimbleOptions struct shape; LINT-08 enforcement via Phase 6 Credo |
| CORE-03 | Telemetry on 4-level `[:mailglass, :domain, :resource, :action, :start|:stop|:exception]`; metadata whitelist enforced; handlers that raise do not break pipeline | Sigra.Telemetry reference impl confirmed; `:telemetry.span/3` isolates handler exceptions per-handler |
| CORE-04 | `Mailglass.Repo.transact/1` wrapper for `Ecto.Multi` flows | Scaffolded in Phase 1 as placeholder; genuine usage Phase 2+ |
| CORE-05 | `Mailglass.IdempotencyKey` producing `"#{provider}:#{provider_event_id}"` keys | Pure module; sanitization heuristics Claude's call |
| CORE-06 | All optional deps gated through `Mailglass.OptionalDeps.*` with `@compile {:no_warn_undefined, ...}` + `available?/0` + degraded fallback; `--no-optional-deps --warnings-as-errors` passes | Pattern confirmed in STACK.md §2.1 |
| CORE-07 | `boundary` library adopted from Phase 1; `Mailglass.Renderer` cannot depend on `Outbound`, `Repo`, or any process | `boundary ~> 0.10.4` verified on Hex; boundary blocks defined for Phase 1 modules only |
| AUTHOR-02 | `Mailglass.Components` HEEx library with 11 components + MSO VML fallbacks; no Node toolchain | Component specs locked D-10..D-25; Premailex conditional comment preservation confirmed default behavior (PR #37) |
| AUTHOR-03 | Render pipeline: HEEx → Premailex CSS inlining → minify → Floki auto-plaintext; <50ms target | `Premailex.to_inline_css/2` + `Floki.traverse_and_update/2` confirmed APIs; custom walker via `data-mg-plaintext` strategy attrs |
| AUTHOR-04 | Gettext `dgettext("emails", ...)` i18n; `mix mailglass.gettext.extract` task | Gettext 1.0 uses `use Gettext.Backend, otp_app:` + `use Gettext, backend:` import pattern; confirmed |
| AUTHOR-05 | `Mailglass.TemplateEngine` pluggable behaviour; HEEx default impl; MJML opt-in documented | Behaviour + HEEx impl in Phase 1; MJML implementation deferred |
| COMP-01 | `Mailglass.Compliance.add_rfc_required_headers/1` injects Date, Message-ID, MIME-Version if absent | Stub implementation in Phase 1; full RFC 8058 in v0.5 |
| COMP-02 | Auto-injected headers: `Mailglass-Mailable:` and `Feedback-ID:` | Stub in Phase 1 reserving the namespace |

</phase_requirements>

---

## TL;DR

Phase 1 delivers the "demo on day one" milestone: zero-dep foundation modules (Layer 0) plus a pure-function HEEx rendering pipeline (Layer 1). Every decision is locked via CONTEXT.md D-01..D-33. The prior-art library patterns in `~/projects/sigra` provide copy-ready reference implementations for `Config` (NimbleOptions struct, `new!/1` pattern), `Telemetry` (`attach_default_logger/1`, `span/2`, event catalog in `@moduledoc`), and `Error` (sibling `defexception` modules with per-kind fields). Premailex 0.3.20 preserves MSO conditional comments by default (issue #36 fixed in PR #37, June 2019) — no option needed, but a golden fixture test is required. Floki 0.38.1's `traverse_and_update/2` is the correct API for the custom `data-mg-plaintext` walker. Gettext 1.0 uses `use Gettext.Backend, otp_app:` for the backend module, then `use Gettext, backend: MyModule` to import macros — the "emails" domain lives in `priv/gettext/`. The `boundary ~> 0.10.4` library enforces the renderer purity constraint at compile time.

**Primary recommendation:** Port the Sigra.Config / Sigra.Telemetry / Sigra.Error patterns verbatim (names changed), build components referencing Campaign Monitor's bulletproof button for the `<.button>` VML shape, and write the golden fixture test for Premailex conditional comment preservation before any other component test.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Error hierarchy | Pure library (no tier) | — | `defexception` structs; no process, no DB, no HTTP |
| Config validation | Library boot (Application.start) | — | NimbleOptions at boot via `Mailglass.Config.validate!/0`; cached in `:persistent_term` |
| Telemetry emission | Library (inline at call sites) | — | `:telemetry.span/3` called from pure functions; handlers are adopter-owned |
| CSS inlining | Library (pure function) | — | Premailex is a pure transform; no process |
| Plaintext extraction | Library (pure function) | — | Floki tree walk; no process |
| HEEx rendering | Library (pure function) | — | `Phoenix.Template.render_to_iodata/2` or equivalent compile-time render |
| Theme map | Library (:persistent_term) | — | Read on every render; `:persistent_term.get/1` is the right primitive |
| Compliance header stubs | Library (pure function) | — | String manipulation on `%Swoosh.Email{}`; no process |
| Optional dep gateway | Library (compile-time guards) | — | `@compile {:no_warn_undefined, ...}` + `Code.ensure_loaded?/1` |
| Boundary enforcement | Mix compiler (build time) | — | `boundary` library adds a Mix compiler that fails builds on violations |

---

## Standard Stack

### Core (Phase 1 deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `~> 1.8` (1.8.5) | HEEx tag engine, `Phoenix.Component` for `attr/3`/`slot/3` | Required floor; `Phoenix.LiveView.TagEngine` powers HEEx |
| `phoenix_live_view` | `~> 1.1` (1.1.28) | `Phoenix.Component` module with `attr/3`, `slot/3`, `render_slot/1` | Component macros live here; attr `:global` with `include:` and `values:` |
| `phoenix_html` | `~> 4.1` | `Phoenix.HTML.Safe`, `raw/1` | Transitive via phoenix; pin for clarity |
| `plug` | `~> 1.18` (1.19.1) | `Plug.Conn` type used in compliance stubs | Required by Phoenix |
| `swoosh` | `~> 1.25` (1.25.0) | `%Swoosh.Email{}` is the inner struct of `%Mailglass.Message{}` | Composition over replacement |
| `nimble_options` | `~> 1.1` (1.1.1) | `Mailglass.Config` schema validation at boot | Feature-complete; ecosystem standard |
| `telemetry` | `~> 1.4` (1.4.1) | `:telemetry.span/3`, `:telemetry.execute/3`, `:telemetry.attach_many/4` | Foundation for all observability |
| `gettext` | `~> 1.0` (1.0.2) | AUTHOR-04 i18n; `dgettext("emails", ...)` in adopter HEEx slots | Required at AUTHOR-04; 1.0 reduces compile-dep overhead |
| `premailex` | `~> 0.3` (0.3.20) | `Premailex.to_inline_css/2` for CSS inlining in the render pipeline | Only Elixir CSS inliner; MEDIUM confidence on long-term maintenance |
| `floki` | `~> 0.38` (0.38.1) | `Floki.traverse_and_update/2` for custom plaintext walker | HEEx assertion + plaintext extraction |
| `boundary` | `~> 0.10` (0.10.4) | Compile-time module dependency enforcement | Required by CORE-07; enforces Renderer purity |
| `jason` | `~> 1.4` | `Jason.Encoder` derived on error structs for `[:type, :message, :context]` | D-06; transitive via swoosh but pin |

### Test Only

| Library | Version | Purpose |
|---------|---------|---------|
| `stream_data` | `~> 1.3` (1.3.0) | Telemetry metadata whitelist property test (D-33) |
| `mox` | `~> 1.2` (1.2.0) | Mocking `Mailglass.TemplateEngine` behaviour |
| `credo` | `~> 1.7` (1.7.18) | `mix credo --strict` lint lane |
| `dialyxir` | `~> 1.4` (1.4.7) | Type checking |
| `ex_doc` | `~> 0.40` (0.40.1) | Docs with llms.txt |

### Not Used in Phase 1

| Package | Why excluded |
|---------|-------------|
| `ecto`, `ecto_sql`, `postgrex` | No persistence in Phase 1 |
| `oban` | Optional dep; usage in Phase 3+ |
| `opentelemetry` | Optional dep gateway module is a stub in Phase 1 |
| `mjml` | Optional dep; TemplateEngine.MJML implementation deferred |

**Installation (mix.exs deps block for Phase 1):**
```elixir
defp deps do
  [
    # Required
    {:phoenix,           "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_html,      "~> 4.1"},
    {:plug,              "~> 1.18"},
    {:swoosh,            "~> 1.25"},
    {:nimble_options,    "~> 1.1"},
    {:telemetry,         "~> 1.4"},
    {:gettext,           "~> 1.0"},
    {:premailex,         "~> 0.3"},
    {:floki,             "~> 0.38"},
    {:boundary,          "~> 0.10"},

    # Optional (gated by Code.ensure_loaded?/1)
    {:oban,             "~> 2.21", optional: true},
    {:opentelemetry,    "~> 1.7",  optional: true},
    {:mjml,             "~> 5.3",  optional: true},
    {:gen_smtp,         "~> 1.3",  optional: true},
    {:sigra,            "~> 0.2",  optional: true},

    # Test only
    {:stream_data,      "~> 1.3",  only: [:test]},
    {:mox,              "~> 1.2",  only: [:test]},
    {:excoveralls,      "~> 0.18", only: [:test]},

    # Dev/test
    {:credo,     "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir,  "~> 1.4", only: [:dev, :test], runtime: false},
    {:ex_doc,    "~> 0.40", only: :dev, runtime: false}
  ]
end
```

**Version verification:** All versions confirmed against Hex.pm on 2026-04-21 by STACK.md (HIGH confidence). `boundary 0.10.4` confirmed via `mix hex.info boundary` on 2026-04-22. [VERIFIED: Hex.pm via STACK.md + `mix hex.info` commands]

---

## Module-by-Module Research

### 1. `Mailglass.Error` + Six Sibling Error Structs (CORE-01)

**Pattern:** Six `defexception` modules under the `Mailglass` namespace, with `Mailglass.Error` as the namespace + behaviour module (not a struct). [VERIFIED: sigra prior art at `/Users/jon/projects/sigra/lib/sigra/error.ex`]

**Confirmed API from sigra reference:**
```elixir
# sigra/error.ex pattern — port to mailglass:
defmodule Mailglass.SendError do
  @moduledoc "Raised when email delivery fails."
  defexception [:type, :message, :cause, :context, :delivery_id]

  @types [:adapter_failure, :rendering_failed, :preflight_rejected, :serialization_failed]

  @impl true
  def message(%{type: type, context: ctx}) do
    # Brand-voice-conformant: "Delivery failed: adapter returned an error"
    # Never "Oops!" or "Something went wrong."
    format_message(type, ctx)
  end

  def __types__, do: @types  # D-07: automated test asserts this matches api_stability.md

  def new(type, opts \\ []) when type in @types do
    %__MODULE__{
      type: type,
      message: format_message(type, opts[:context] || %{}),
      cause: opts[:cause],
      context: opts[:context] || %{},
      delivery_id: opts[:delivery_id]
    }
  end
end
```

**`Mailglass.Error` behaviour module:**
```elixir
defmodule Mailglass.Error do
  @moduledoc "Namespace + behaviour for the mailglass error hierarchy."

  @type t ::
    Mailglass.SendError.t()
    | Mailglass.TemplateError.t()
    | Mailglass.SignatureError.t()
    | Mailglass.SuppressedError.t()
    | Mailglass.RateLimitError.t()
    | Mailglass.ConfigError.t()

  @callback type(t()) :: atom()
  @callback retryable?(t()) :: boolean()

  def is_error?(%{__struct__: s}) when s in [
    Mailglass.SendError, Mailglass.TemplateError, Mailglass.SignatureError,
    Mailglass.SuppressedError, Mailglass.RateLimitError, Mailglass.ConfigError
  ], do: true
  def is_error?(_), do: false

  def kind(%{type: type}), do: type
  def retryable?(%{__struct__: s} = err), do: s.retryable?(err)
  def root_cause(%{cause: nil} = err), do: err
  def root_cause(%{cause: cause}), do: root_cause(cause)
end
```

**Jason.Encoder derivation (D-06):**
```elixir
# Only on [:type, :message, :context] — :cause intentionally excluded
@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [...]
```

**Pitfall:** Do NOT include `:cause` in the Jason.Encoder derivation — adapter structs in `:cause` may carry provider payloads with PII (recipient addresses in Swoosh error structs). [VERIFIED: D-06 in CONTEXT.md]

**Error message brand voice (D-08):**
- `SendError `:adapter_failure` → `"Delivery failed: adapter returned an error"`
- `SendError :rendering_failed` → `"Delivery failed: template could not be rendered"`
- `TemplateError :missing_assign` → `"Template error: required assign @{name} is missing"`
- `SuppressedError :address` → `"Delivery blocked: recipient is on the suppression list"`
- `ConfigError :missing` → `"Configuration error: required key :#{key} is not set"`
- `RateLimitError :per_domain` → `"Rate limit exceeded: retry after #{ms}ms"`

**`api_stability.md` requirement:** This file MUST be created in Phase 1. It locks the closed `:type` atom sets per D-07. An automated test in `test/mailglass/error_test.exs` asserts `ErrorModule.__types__/0` matches the documented list for each of the six modules.

---

### 2. `Mailglass.Config` (CORE-02)

**Pattern:** NimbleOptions-validated struct, `new!/1` builder, `Application.get_env/2` at runtime (never `compile_env`). [VERIFIED: sigra prior art at `/Users/jon/projects/sigra/lib/sigra/config.ex`]

**Phase 1 scope** (minimal — expands per phase):
```elixir
defmodule Mailglass.Config do
  @moduledoc """
  Runtime configuration for mailglass, validated via NimbleOptions at boot.

  Only this module may call `Application.compile_env*`. All other modules
  read via `Application.get_env/2` + `Mailglass.Config.resolve!/1`.
  """

  @schema [
    repo: [type: :atom, required: true, doc: "The adopter's Ecto Repo module."],
    adapter: [type: :atom, default: Mailglass.Adapters.Fake,
              doc: "The transport adapter module implementing `Mailglass.Adapter`."],
    theme: [
      type: :keyword_list, default: [],
      doc: "Brand palette and typography overrides.",
      keys: [
        colors: [type: :map, default: %{
          ink: "#0D1B2A", glass: "#277B96", ice: "#A6EAF2",
          mist: "#EAF6FB", paper: "#F8FBFD", slate: "#5C6B7A"
        }],
        fonts: [type: :map, default: %{
          body: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
          display: "'Inter Tight', 'Inter', sans-serif",
          mono: "'IBM Plex Mono', ui-monospace, monospace"
        }]
      ]
    ],
    telemetry: [
      type: :keyword_list, default: [],
      doc: "Telemetry configuration.",
      keys: [
        default_logger: [type: :boolean, default: false,
                         doc: "Attach the default logger handler at boot."]
      ]
    ],
    renderer: [
      type: :keyword_list, default: [],
      doc: "Renderer pipeline configuration.",
      keys: [
        template_engine: [type: :atom, default: Mailglass.TemplateEngine.HEEx,
                          doc: "The template engine module implementing `Mailglass.TemplateEngine`."],
        timeout_ms: [type: :pos_integer, default: 5_000,
                     doc: "Max render time before raising TemplateError :timeout."]
      ]
    ]
  ]

  # ... struct, new!/1, validate!/0, get/1 functions
end
```

**Boot-time validation pattern:**
```elixir
# In Mailglass.Application.start/2:
config = Application.get_env(:mailglass, :config, [])
validated = Mailglass.Config.new!(config)
:persistent_term.put({Mailglass, :config}, validated)

# Theme map cached separately for hot render-path access:
:persistent_term.put({Mailglass, :theme}, validated.theme)
```

**`Mailglass.Components.Theme.get/0`** reads from `:persistent_term` — no GenServer, no ETS. [VERIFIED: D-19 in CONTEXT.md]

**Pitfall:** Never use `Application.compile_env!/2` for runtime values like adapter, repo, or webhook secrets. These must be read via `Application.get_env/2` and validated at boot. The `compile_env` variant bakes values into `.beam` files — config changes in `runtime.exs` do not take effect without a rebuild. [VERIFIED: PITFALLS.md LIB-02, LIB-07; sigra Config pattern]

---

### 3. `Mailglass.Telemetry` (CORE-03)

**Pattern:** `span/2` wrapping `:telemetry.span/3`, `event/3` wrapping `:telemetry.execute/3`, `attach_default_logger/1`, full event catalog in `@moduledoc`. [VERIFIED: sigra prior art at `/Users/jon/projects/sigra/lib/sigra/telemetry.ex`]

**Phase 1 events** (`:render` domain only; others land in their owning phases):
```
[:mailglass, :render, :message, :start | :stop | :exception]
[:mailglass, :render, :template, :start | :stop | :exception]
[:mailglass, :render, :css_inline, :start | :stop | :exception]
[:mailglass, :render, :plaintext, :start | :stop | :exception]
```

**Phase 1 surface:**
```elixir
defmodule Mailglass.Telemetry do
  @moduledoc """
  Telemetry integration for mailglass.

  ## Event Catalog (Phase 1 subset)

  ### Rendering

    * `[:mailglass, :render, :message, :start | :stop | :exception]`
      Start metadata: `%{tenant_id: id, mailable: module}`.
      Stop adds: `%{bytes: integer, latency_ms: integer}`.

    * `[:mailglass, :render, :template, :start | :stop | :exception]`
    * `[:mailglass, :render, :css_inline, :start | :stop | :exception]`
    * `[:mailglass, :render, :plaintext, :start | :stop | :exception]`

  ## Metadata Policy

  NEVER included: `:to`, `:from`, `:body`, `:html_body`, `:subject`,
  `:headers`, `:recipient`, `:email` (PII).

  ALWAYS safe: `:tenant_id`, `:mailable`, `:provider`, `:status`,
  `:message_id`, `:delivery_id`, `:event_id`, `:latency_ms`,
  `:recipient_count`, `:bytes`, `:retry_count`.

  ## Default Logger

      Mailglass.Telemetry.attach_default_logger()
      Mailglass.Telemetry.attach_default_logger(level: :warning)

  """

  def render_span(meta, fun), do: :telemetry.span([:mailglass, :render, :message], meta, fun)

  def event(event_name, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute([:mailglass | event_name], measurements, metadata)
  end

  def attach_default_logger(opts \\ []) do
    :telemetry.attach_many("mailglass-default-logger", @logged_events,
      &__MODULE__.handle_event/4, opts)
  end
end
```

**Handler isolation:** `:telemetry.span/3` already provides per-handler try/catch and auto-detach on crash, emitting `[:telemetry, :handler, :failure]`. No mailglass-side rescue wrapper needed. [VERIFIED: D-26 in CONTEXT.md; `:telemetry` library behavior]

**Property test (D-33):** `test/mailglass/telemetry_test.exs` attaches a handler to `[:mailglass | _]`, drives 1000 StreamData-generated render calls, asserts every `:stop` event's metadata keys are a subset of the whitelist, and every event includes `:tenant_id` (placeholder `"single_tenant"` in Phase 1, expands in Phase 2).

---

### 4. `Mailglass.Repo` (CORE-04)

**Scope in Phase 1:** Scaffold only. No schema tests possible without Phase 2 schemas. Ship the wrapper + `@doc` + a placeholder doctest.

```elixir
defmodule Mailglass.Repo do
  @moduledoc """
  Thin wrapper around the adopter's Ecto Repo.

  Exposes `transact/1` as the standard Multi execution path. All state-changing
  operations in mailglass use this wrapper so instrumentation and error handling
  are centralized.

  The adopter's repo is configured via:

      config :mailglass, :config,
        repo: MyApp.Repo

  And validated at boot by `Mailglass.Config.validate!/0`.
  """

  @doc """
  Execute an `Ecto.Multi` against the adopter's configured Repo.

  Returns `{:ok, results_map}` on success, `{:error, failed_operation, reason, changes}`
  on failure.

  ## Examples

      iex> Mailglass.Repo.transact(Ecto.Multi.new())
      {:ok, %{}}

  """
  @doc since: "0.1.0"
  @spec transact(Ecto.Multi.t()) :: {:ok, map()} | {:error, atom(), term(), map()}
  def transact(%Ecto.Multi{} = multi) do
    repo = Mailglass.Config.get(:repo)
    repo.transaction(multi)
  end
end
```

**Pitfall:** Do NOT register a `Mailglass.Repo` as a singleton `GenServer` (`name: __MODULE__`). The repo belongs to the adopter's supervision tree. Mailglass.Repo is a wrapper module only, not a process. [VERIFIED: ARCHITECTURE.md §3.1, PITFALLS.md LIB-05]

---

### 5. `Mailglass.IdempotencyKey` (CORE-05)

**Scope:** Tiny pure module. Key format locked in CORE-05.

```elixir
defmodule Mailglass.IdempotencyKey do
  @moduledoc """
  Deterministic idempotency key builder for webhook events and batch delivery.

  Keys are of the form `"#{provider}:#{provider_event_id}"`.
  """

  @max_length 512  # reasonable cap; UUIDs are 36 chars, provider IDs typically <128

  @doc since: "0.1.0"
  @spec for_webhook_event(atom(), String.t()) :: String.t()
  def for_webhook_event(provider, event_id) when is_atom(provider) and is_binary(event_id) do
    key = "#{provider}:#{sanitize(event_id)}"
    truncate(key)
  end

  @doc since: "0.1.0"
  @spec for_provider_message(atom(), String.t()) :: String.t()
  def for_provider_message(provider, message_id) when is_atom(provider) and is_binary(message_id) do
    key = "#{provider}:msg:#{sanitize(message_id)}"
    truncate(key)
  end

  # Sanitization: strip ASCII control characters, preserve printable ASCII + Unicode
  defp sanitize(s), do: String.replace(s, ~r/[\x00-\x1f\x7f]/, "")

  # Length cap prevents index bloat (Postgres TEXT has no length limit but index keys do)
  defp truncate(s) when byte_size(s) > @max_length, do: binary_part(s, 0, @max_length)
  defp truncate(s), do: s
end
```

**Claude's discretion:** The sanitization (strip control chars) and 512-byte cap are reasonable defaults. The planner may adjust the cap based on actual provider ID lengths. [ASSUMED: 512 bytes is a reasonable Postgres index key cap]

---

### 6. `Mailglass.Message` (AUTHOR-03)

**Struct wrapping `%Swoosh.Email{}`:**
```elixir
defmodule Mailglass.Message do
  @moduledoc "Rendered email message wrapping %Swoosh.Email{} with mailglass metadata."

  @type t :: %__MODULE__{
    email: Swoosh.Email.t(),
    html_body: String.t() | nil,     # populated by Renderer
    text_body: String.t() | nil,     # populated by Renderer
    mailable: module(),
    tenant_id: String.t(),
    stream: :transactional | :operational | :bulk,
    metadata: map()
  }

  defstruct [
    :email,         # %Swoosh.Email{} — the canonical email struct
    :html_body,     # rendered + CSS-inlined HTML
    :text_body,     # auto-generated plaintext
    :mailable,      # module name, e.g., MyApp.UserMailer
    tenant_id: "default",
    stream: :transactional,
    metadata: %{}
  ]
end
```

**Key constraint:** `Mailglass.Message` does NOT own delivery history, retry state, or provider IDs — those belong to `Mailglass.Outbound.Delivery` (Phase 2). [VERIFIED: ARCHITECTURE.md §1.3]

---

### 7. `Mailglass.Components` (AUTHOR-02)

**Key APIs confirmed:**

**`attr/3` with `values:` (compile-time warnings):** [VERIFIED: hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
```elixir
attr :variant, :string, values: ~w(primary secondary ghost), default: "primary"
attr :tone, :string, values: ~w(glass ink slate), default: "glass"
```
When a caller passes a literal not in `values:`, LiveView emits a compile warning. This is the mechanism behind D-18.

**`:global` with `include:` and content components excluding `:style`:** [VERIFIED: Phoenix.Component docs]
```elixir
# Content components — deliberately excludes :style to prevent footgun (D-17)
attr :class, :any, default: nil
attr :rest, :global, include: ~w(id aria-label aria-describedby data-testid)

# Layout components — also excludes :style
attr :class, :any, default: nil
attr :rest, :global, include: ~w(id)
```

**`slot/3` pattern for content components:**
```elixir
slot :inner_block, required: true
```

**Atomic components (attribute-only, self-closing):**
```elixir
# <.img> — alt is required (accessibility floor, D-18)
attr :src, :string, required: true
attr :alt, :string, required: true  # compile error if omitted
attr :width, :integer, required: true
attr :height, :integer, required: true
attr :class, :any, default: nil
attr :rest, :global, include: ~w(id)
```

**Theme access pattern:**
```elixir
defmodule Mailglass.Components.Theme do
  def get, do: :persistent_term.get({Mailglass, :theme})
  def color(name), do: get().colors[name] || raise "Unknown theme color: #{name}"
end
```

**`data-mg-plaintext` strategy attributes (D-22):**
Each component's root node carries `data-mg-plaintext="<strategy>"`. The custom Floki walker in `Mailglass.Renderer.to_plaintext/1` dispatches on strategy:
- `"link_pair"` → `"#{label} (#{href})"`
- `"text"` → raw text content (default for `<.text>`)
- `"heading_block"` → blank lines + uppercase for h1
- `"divider"` → `"\n---\n"`
- `"skip"` → excluded (preheader)

A terminal Floki pass strips all `data-mg-*` attributes from the HTML wire before returning.

**`<.button>` VML shape (D-11, "Surgical-VML flagship"):**

The bulletproof button pattern from Campaign Monitor:
```html
<!--[if mso]>
<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word"
  href="<%= @href %>" style="height:44px;v-text-anchor:middle;width:200px;"
  arcsize="7%" strokecolor="#277B96" fillcolor="#277B96">
  <w:anchorlock/>
  <center>
<![endif]-->
<a href="<%= @href %>" style="background-color:#277B96;...mso-hide:all;">
  <%= render_slot(@inner_block) %>
</a>
<!--[if mso]></center></v:roundrect><![endif]-->
```
[VERIFIED: D-11 in CONTEXT.md; Campaign Monitor bulletproof button pattern — well-established email industry standard]

**`<.preheader>` hidden text pattern (D-Specific):**
```html
<div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">
  <%= @text %>
  <!-- Repeated zero-width chars to push Gmail preview -->
  &#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;...
</div>
```

**`<.row>` ghost table (D-11):**
```html
<!--[if mso]><table role="presentation"><tr><![endif]-->
<div style="display:flex;...">
  <%= render_slot(@inner_block) %>
</div>
<!--[if mso]></tr></table><![endif]-->
```

**`<.column>` ghost td (D-11):**
```html
<!--[if mso]><td valign="top" width="<%= @width %>"><![endif]-->
<div style="display:inline-block;width:<%= @width %>px;...">
  <%= render_slot(@inner_block) %>
</div>
<!--[if mso]></td><![endif]-->
```

**MSO head block (D-12, emitted once in `layout/1`):**
```html
<!--[if gte mso 9]><xml>
<o:OfficeDocumentSettings>
<o:AllowPNG/>
<o:PixelsPerInch>96</o:PixelsPerInch>
</o:OfficeDocumentSettings></xml><![endif]-->
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
```

**Dev-time `Logger.warning` for `<.row>` children (D-24):**
In `Mailglass.Renderer.to_plaintext/1`, after the Floki walk, check that direct children of `[data-mg-row]` nodes are `[data-mg-column]` nodes. If not, emit `Logger.warning("mailglass: <.row> contains non-<.column> direct child...")` — this does NOT raise, it just warns.

---

### 8. `Mailglass.TemplateEngine` Behaviour (AUTHOR-05)

**Behaviour definition:**
```elixir
defmodule Mailglass.TemplateEngine do
  @moduledoc "Pluggable template engine behaviour. Default: HEEx."

  @callback compile(template :: String.t(), opts :: keyword()) ::
    {:ok, compiled :: term()} | {:error, Mailglass.TemplateError.t()}

  @callback render(compiled :: term(), assigns :: map()) ::
    {:ok, iodata()} | {:error, Mailglass.TemplateError.t()}

  @callback name() :: atom()
end
```

**HEEx implementation:**
```elixir
defmodule Mailglass.TemplateEngine.HEEx do
  @behaviour Mailglass.TemplateEngine

  def name, do: :heex

  def compile(template, _opts) do
    try do
      # EEx.compile_string with engine: Phoenix.LiveView.TagEngine
      compiled = EEx.compile_string(template, engine: Phoenix.LiveView.TagEngine,
                                    module: __MODULE__, file: "template", line: 1,
                                    caller: __ENV__, source: template)
      {:ok, compiled}
    rescue
      e -> {:error, Mailglass.TemplateError.new(:heex_compile, cause: e)}
    end
  end

  def render(compiled, assigns) do
    try do
      result = Code.eval_quoted(compiled, [assigns: assigns], __ENV__)
      {:ok, result}
    rescue
      e in KeyError ->
        {:error, Mailglass.TemplateError.new(:missing_assign, cause: e,
                                              context: %{key: e.key})}
      e ->
        {:error, Mailglass.TemplateError.new(:heex_compile, cause: e)}
    end
  end
end
```

**MJML opt-in gateway (AUTHOR-05 — Phase 1 documents, does not implement):**
```elixir
defmodule Mailglass.OptionalDeps.MJML do
  @compile {:no_warn_undefined, Mjml}

  @doc "Returns true if the :mjml optional dep is loaded."
  def available?, do: Code.ensure_loaded?(Mjml)
end

# Mailglass.TemplateEngine.MJML: documented as opt-in, not implemented in Phase 1.
# Guide example: config :mailglass, :config, renderer: [template_engine: Mailglass.TemplateEngine.MJML]
```

---

### 9. `Mailglass.Renderer` (AUTHOR-03)

**Pipeline:** HEEx compile → render → Premailex CSS inline → minify → Floki plaintext → strip `data-mg-*`. Pure functions. No processes. `boundary` enforces this.

```elixir
defmodule Mailglass.Renderer do
  use Boundary, deps: [
    Mailglass.Message, Mailglass.TemplateEngine, Mailglass.Components,
    Mailglass.Telemetry, Mailglass.Error
  ]
  # Explicitly cannot depend on: Mailglass.Outbound, Mailglass.Repo, Mailglass.Events

  @doc """
  Render a %Mailglass.Message{} to {html_body, text_body}.

  Pure function. No side effects beyond telemetry events.
  Target: <50ms for a typical single-recipient template.
  """
  @spec render(%Mailglass.Message{}) ::
    {:ok, %Mailglass.Message{html_body: String.t(), text_body: String.t()}}
    | {:error, Mailglass.TemplateError.t()}
  def render(%Mailglass.Message{} = message) do
    Mailglass.Telemetry.render_span(
      %{tenant_id: message.tenant_id, mailable: message.mailable},
      fn ->
        with {:ok, html} <- render_html(message),
             {:ok, inlined} <- inline_css(html),
             {:ok, text} <- extract_plaintext(inlined),
             {:ok, clean_html} <- strip_data_attrs(inlined) do
          result = %{message | html_body: clean_html, text_body: text}
          {{:ok, result}, %{bytes: byte_size(clean_html)}}
        end
      end
    )
  end

  defp inline_css(html) do
    {:ok, Premailex.to_inline_css(html)}
  rescue
    e -> {:error, Mailglass.TemplateError.new(:inliner_failed, cause: e)}
  end

  defp extract_plaintext(html) do
    # Custom Floki walker keyed on data-mg-plaintext strategy attrs (D-22)
    # Runs on the pre-CSS-inlined logical tree (D-15)
    {:ok, to_plaintext(html)}
  end

  @doc false
  def to_plaintext(html) do
    {:ok, document} = Floki.parse_document(html)
    document
    |> Floki.traverse_and_update(&walk_plaintext/1)
    |> plaintext_nodes_to_string()
  end

  defp strip_data_attrs(html) do
    {:ok, document} = Floki.parse_document(html)
    cleaned = Floki.traverse_and_update(document, fn
      {tag, attrs, children} ->
        clean_attrs = Enum.reject(attrs, fn {k, _} -> String.starts_with?(k, "data-mg-") end)
        {tag, clean_attrs, children}
      other -> other
    end)
    {:ok, Floki.raw_html(cleaned)}
  end
end
```

**Plaintext extraction order (D-15):** The plaintext walk runs on the pre-VML, post-render HTML — the component tree with `data-mg-plaintext` markers but BEFORE the VML wrapper step is applied. In practice, this means we call `to_plaintext/1` on the raw rendered HTML (which already has VML conditional comments as HTML comments), then strip VML comment content from the plaintext output. Since VML lives inside `<!--[if mso]>` blocks, and Floki parses these as comments (not as elements), they naturally produce no text output. [VERIFIED: Floki parses conditional comments as text nodes; they don't produce element structure]

**Performance target:** <50ms for a typical template. Premailex CSS inlining is the most expensive step (~10-30ms depending on CSS complexity). Floki parsing adds ~5ms. HEEx rendering is negligible. Profile against a realistic 10-component layout before declaring done. [ASSUMED: these timings are based on Premailex's documented performance characteristics]

---

### 10. `Mailglass.Compliance` Stubs (COMP-01, COMP-02)

**Phase 1 scope:** Reserve the namespace. Stub implementations only — full RFC 8058 lands in v0.5.

```elixir
defmodule Mailglass.Compliance do
  @moduledoc """
  Email compliance header injection.

  ## v0.1 (this phase)
  - `add_rfc_required_headers/1` — Date, Message-ID, MIME-Version
  - `add_mailglass_headers/2` — Mailglass-Mailable, Feedback-ID

  ## v0.5 (deferred)
  - `add_unsubscribe_headers/1` — List-Unsubscribe + List-Unsubscribe-Post (RFC 8058)
  - `add_physical_address/2` — CAN-SPAM requirement for :bulk stream
  - `dkim_sign/2` — DKIM signing for self-hosted SMTP relay
  """

  @doc since: "0.1.0"
  def add_rfc_required_headers(%Swoosh.Email{} = email) do
    email
    |> maybe_put_header("Date", fn -> format_date(DateTime.utc_now()) end)
    |> maybe_put_header("Message-ID", fn -> generate_message_id() end)
    |> maybe_put_header("MIME-Version", fn -> "1.0" end)
  end

  @doc since: "0.1.0"
  def add_mailglass_headers(%Swoosh.Email{} = email, opts) do
    mailable = Keyword.get(opts, :mailable)
    tenant_id = Keyword.get(opts, :tenant_id)

    email
    |> add_mailable_header(mailable)
    |> add_feedback_id_header(mailable, tenant_id, opts)
  end

  # ... private helpers
end
```

**`Mailglass-Mailable` header format (COMP-02):** `"MyApp.UserMailer.welcome/1"` — module + function + arity.

**`Feedback-ID` header format (COMP-02):** `"#{stable_sender_id}:#{mailable}:#{tenant_id}"` when all configured.

---

### 11. `Mailglass.OptionalDeps.*` Gateways (CORE-06)

**One gateway module per optional dep, placed in Phase 1:**
```elixir
# lib/mailglass/optional_deps/oban.ex
defmodule Mailglass.OptionalDeps.Oban do
  @compile {:no_warn_undefined, Oban}
  @moduledoc "Gateway for the optional :oban dependency."

  @doc "Returns true if Oban is loaded in the current environment."
  def available?, do: Code.ensure_loaded?(Oban)
end

# lib/mailglass/optional_deps/open_telemetry.ex
defmodule Mailglass.OptionalDeps.OpenTelemetry do
  @compile {:no_warn_undefined, :opentelemetry}
  @moduledoc "Gateway for the optional :opentelemetry dependency."

  def available?, do: Code.ensure_loaded?(:opentelemetry)
end

# lib/mailglass/optional_deps/mjml.ex
defmodule Mailglass.OptionalDeps.MJML do
  @compile {:no_warn_undefined, Mjml}
  @moduledoc "Gateway for the optional :mjml dependency."

  def available?, do: Code.ensure_loaded?(Mjml)
end
```

**CI verification:** `mix compile --no-optional-deps --warnings-as-errors` must pass. This is the DIST-04 prevention gate. Add to lint lane in Phase 7's CI setup, but the modules must be correct from Phase 1.

---

## Integration Points

### Premailex: CSS Inlining + Conditional Comment Preservation

**Confirmed APIs:** [VERIFIED: hexdocs.pm/premailex, GitHub PR #37]
- `Premailex.to_inline_css(html)` — main CSS inlining function
- `Premailex.to_text(html)` — Premailex's own plaintext converter (NOT used by mailglass — we use the custom Floki walker per D-22)
- `Premailex.to_inline_css(html, css_selector: "style,link[rel=...]")` — with optional CSS selector override
- `Premailex.to_inline_css(html, optimize: :remove_style_tags)` — removes style tags after inlining

**Critical finding on conditional comments (D-14):**
PR #37 (merged June 22, 2019) fixed issue #36. Premailex PRESERVES IE conditional comments (`<!--[if mso]>...<![endif]-->`) by default since version 0.3.x. There is NO `keep_conditional_comments` option — the preservation is built into the implementation in `mailglass_raise_immutability`. The CONTEXT.md D-14 says "Set `keep_conditional_comments: true` (or equivalent — see Premailex issue #36)." The "equivalent" is the default behavior. [VERIFIED: GitHub issue #36 and PR #37 resolution]

**Action for planner:** The golden fixture test at `test/mailglass/components/vml_preservation_test.exs` should:
1. Take a known HTML input containing `<!--[if mso]>...<![endif]-->` blocks
2. Run through `Premailex.to_inline_css/1`
3. Assert the conditional comment blocks are present in the output
4. This guards against any future Premailex update breaking this behavior

**MEDIUM confidence maintenance note:** Premailex 0.3.20 was released January 2025 (~15 months before this research). The library has a single maintainer (danschultzer). No credible replacement exists. Monitor for maintainer activity. If the library becomes unmaintained, the fallback is: (a) vendor the relevant files into `lib/mailglass/vendor/premailex/`, or (b) switch to a Rust-NIF CSS inliner at v0.5. [VERIFIED: STACK.md §1.1 MEDIUM confidence flag]

### Floki: Custom Plaintext Walker

**Confirmed API:** [VERIFIED: hexdocs.pm/floki]
- `Floki.parse_document/1` → `{:ok, tree}` — parse HTML into Floki's internal representation
- `Floki.traverse_and_update/2` — post-walk traversal, returns modified tree (children before parents)
- `Floki.traverse_and_update/3` — with accumulator for stateful walks
- `Floki.raw_html/1` — serialize tree back to HTML string
- `Floki.text/1` — naive text extraction (NOT used — we use custom walker)
- `Floki.find/2` — CSS selector search

**Custom walker pattern for `data-mg-plaintext`:**
```elixir
defp walk_plaintext({tag, attrs, children}) do
  strategy = List.keyfind(attrs, "data-mg-plaintext", 0)
  case strategy do
    {_, "skip"} -> nil  # delete node from plaintext output
    {_, "link_pair"} ->
      href = List.keyfind(attrs, "href", 0) |> elem(1)
      text = Floki.text(children)
      {"mg-link-pair", [], [text, " (", href, ")"]}
    {_, "heading_block"} ->
      level = String.last(tag)  # "h1" -> "1"
      text = Floki.text(children)
      formatted = if level == "1", do: String.upcase(text), else: text
      {"mg-heading", [], ["\n\n", formatted, "\n\n"]}
    {_, "divider"} -> {"mg-divider", [], ["\n---\n"]}
    _ -> {tag, attrs, children}  # pass through for :text strategy
  end
end
```

**Note on Floki 0.38.1 and lazy_html:** LiveView 1.1 switched its internal parser to `lazy_html`, but Floki itself still uses Meeseeks (or its own parser). The switch in LiveView does NOT affect Floki as a standalone library. Floki 0.38.1 remains the correct choice for one-shot transformation. [VERIFIED: STACK.md §1.2]

### HEEx Rendering: `Phoenix.LiveView.TagEngine`

**Compile-time HEEx rendering for library code:**

For a library component module, components are defined with `use Phoenix.Component` and called as pure functions. The HEEx is rendered at call time (not at boot) via the standard `~H` sigil or `Phoenix.LiveView.TagEngine`.

For adopters' mailable templates, rendering happens at call time via `EEx.eval_string/2` with the HEEx engine, or via precompiled template modules. The exact approach depends on whether we use `Phoenix.Template` or inline `EEx`:

```elixir
# Option A: EEx.eval_string (simple, no precompilation)
html = EEx.eval_string(template_string, assigns: assigns,
                        engine: Phoenix.LiveView.TagEngine)

# Option B: Phoenix.Template (precompiled at Mix compile time — better for production)
# Requires adopter's mailable module to embed the template
```

For Phase 1, Option A is simpler and sufficient. Option B (precompiled templates) is the production upgrade path. [ASSUMED: EEx.eval_string with Phoenix.LiveView.TagEngine is the correct Phase 1 approach; confirm exact API with Phoenix 1.8 docs if needed]

### Gettext 1.0: Backend Pattern

**Confirmed API for Gettext 1.0:** [VERIFIED: hexdocs.pm/gettext]

In Gettext 1.0, the workflow changed from v0.26:
- Create a backend: `use Gettext.Backend, otp_app: :mailglass`
- Import macros in modules: `use Gettext, backend: MyApp.Gettext`
- This reduces compile-time dependencies vs the old pattern

For Phase 1, the "emails" domain convention:
```elixir
# Adopter's template HEEx (not inside mailglass lib — adopter-responsibility per D-23):
<.heading>
  <%= dgettext("emails", "Welcome, %{name}!", name: @user.name) %>
</.heading>

# The `dgettext` macro is available after:
use Gettext, backend: MyApp.Gettext
```

**`mix mailglass.gettext.extract` (AUTHOR-04):** This mix task will call `mix gettext.extract` scoped to the "emails" domain. In Phase 1, this task is stubbed — it doesn't need a full implementation until there are actual translated strings. The `priv/gettext/` directory structure should be scaffolded.

**`<.preheader>` is the only attribute-translated exception (D-23):** Since `<.preheader text={...}>` takes an attribute (not a slot), the adopter must wrap it: `<.preheader text={dgettext("emails", "Special offer inside")} />`. Document this in the component's `@doc`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CSS inlining | Custom CSS parser + inliner | `Premailex.to_inline_css/2` | CSS specificity, shorthand expansion, `!important` handling are very complex |
| HTML parsing | Regex HTML parsing | `Floki.parse_document/1` + `traverse_and_update/2` | Regex HTML parsing has well-known failure modes; Floki handles malformed HTML gracefully |
| Option validation | Custom `Keyword.validate!/2` + type checks | `NimbleOptions.validate!/2` | NimbleOptions handles nested schemas, type coercion, doc generation |
| Telemetry spans | Try/rescue around function + manual `:start`/`:stop` events | `:telemetry.span/3` | Already handles exception events, handler isolation, and span context propagation |
| Compile-time attr checking | Custom `__using__` that validates attrs | `attr/3` with `values:` in Phoenix.Component | Phoenix.Component emits proper compile warnings and is the ecosystem standard |
| Error hierarchy parent | `%Mailglass.Error{type: :send_error, ...}` single struct | Six `defexception` modules | Dialyzer can't prove non-nil on `RateLimitError.retry_after_ms` if it's in a single struct |
| `:persistent_term` read caching | ETS table for theme | `:persistent_term.get/1` | Theme is read on every render, never mutated — `:persistent_term` is purpose-built for this pattern |

**Key insight:** The email rendering domain has decades of accumulated edge cases (CSS specificity, MSO conditional comments, preheader zero-width chars). Every piece of "looks simple, implement ourselves" logic hides provider-specific behavior. Use the established libraries and test against golden fixtures.

---

## Common Pitfalls

### Pitfall 1: Premailex Strips VML (LIB-02 prevention)

**What goes wrong:** A future Premailex upgrade changes its comment-handling behavior; the golden fixture test would catch this, but if it's not written, VML-dependent buttons silently render as broken empty boxes in classic Outlook.

**Why it happens:** Premailex's conditional comment preservation is not in its NimbleOptions-style API — it's an implementation detail. New maintainers may not realize it's load-bearing.

**How to avoid:** Golden fixture test in `test/mailglass/components/vml_preservation_test.exs` that runs `Premailex.to_inline_css/1` on an HTML snippet containing `<!--[if mso]>...<![endif]-->` and asserts the conditional comment block is present in the output.

**Warning signs:** VML comments disappear from rendered HTML. `<.button>` renders visually broken in Outlook 2016 testing.

### Pitfall 2: `Application.compile_env!` in Library Code (LIB-07)

**What goes wrong:** Library module uses `Application.compile_env!(:mailglass, :adapter)` → adapter module baked into `.beam` file → adopter changes adapter in `runtime.exs` → change has no effect → they file a bug report.

**Why it happens:** Compile-time validation "feels safer." It is, but the safety is in the wrong place.

**How to avoid:** Only `Mailglass.Config` may use `compile_env`. All other modules call `Mailglass.Config.get/1`. Phase 6 Credo check `NoCompileEnvOutsideConfig` enforces this at lint time.

**Warning signs:** `grep -r "Application.compile_env" lib/mailglass/ | grep -v "config.ex"` returns non-empty output.

### Pitfall 3: PII in Telemetry Metadata (OBS-01)

**What goes wrong:** A telemetry stop event includes `meta: %{to: "alice@example.com", subject: "Password Reset"}`. Adopter wires telemetry to OpenTelemetry → PII flows to Datadog/Honeycomb. GDPR violation discovered months later.

**Why it happens:** It's convenient to include the full message struct in metadata for debugging. The anti-pattern is invisible until a data audit.

**How to avoid:** Telemetry metadata ONLY includes whitelisted keys: `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. Phase 6 Credo check `NoPiiInTelemetryMeta` enforces. Property test in Phase 1 verifies all emitted metadata keys are subset of whitelist.

**Warning signs:** Any of `:to, :from, :body, :html_body, :subject, :headers, :recipient, :email` appear as keys in a telemetry `metadata` map.

### Pitfall 4: Optional Deps Leak Without Gateway Modules (DIST-04)

**What goes wrong:** `lib/mailglass/outbound/scheduler.ex` calls `Oban.insert(...)` directly. Adopter without Oban gets `UndefinedFunctionError` at runtime on first async send. `mix compile --no-optional-deps` emits warnings that are ignored.

**Why it happens:** Optional dep usage is visible at runtime, not at compile time, unless you add `--no-optional-deps` to CI.

**How to avoid:** All optional dep usage goes through `Mailglass.OptionalDeps.*` gateway modules with `@compile {:no_warn_undefined, ...}` declared once. CI gate `mix compile --no-optional-deps --warnings-as-errors`. Phase 6 Credo check `NoBareOptionalDepReference` enforces.

**Warning signs:** `grep -r "Oban\." lib/mailglass/ | grep -v "optional_deps/"` returns non-empty output.

### Pitfall 5: `Mailglass.Renderer` Accidentally Depends on a Process (CORE-07)

**What goes wrong:** `Mailglass.Renderer.render/1` calls `Mailglass.Repo.transact/1` to record metrics inline → renderer now requires a DB connection → pure-function tests become integration tests → <50ms target is impossible to meet in a sandboxed test environment.

**Why it happens:** "While I'm here, let me also persist the render timing" — a tempting but incorrect expansion of scope.

**How to avoid:** `boundary` library enforces the `deps:` list at compile time. `Mailglass.Renderer`'s boundary block excludes `Mailglass.Repo` and `Mailglass.Outbound`. Any accidental import of these will fail the Mix compiler step.

**Warning signs:** `mix compile` emits a boundary violation warning for `Mailglass.Renderer`.

### Pitfall 6: Error Pattern-Matching by Message String

**What goes wrong:** Adopter code: `if String.contains?(err.message, "suppressed"), do: ...` — this breaks silently on any error message wording change, even in a patch release.

**Why it happens:** The error struct is available but the `:type` field is less discoverable than the `:message` field.

**How to avoid:** Document prominently in `Mailglass.Error` `@moduledoc` that callers must match on `:type` and `__struct__`. Phase 6 Credo check `NoErrorMessageStringMatch` enforces in library code.

### Pitfall 7: Missing `__types__/0` Function on Error Structs (CORE-01)

**What goes wrong:** `api_stability.md` documents `SendError.type ∈ :adapter_failure | ...` but there's no automated verification. A developer adds `:timeout` to the atom set without a CHANGELOG entry or `@since` annotation; adopters can't rely on the documented set being complete.

**Why it happens:** Documentation is separate from code; they drift.

**How to avoid:** Every error module exports `def __types__, do: @types` where `@types` is the closed atom list. An automated test in `test/mailglass/error_test.exs` reads `api_stability.md`, parses the documented atom sets, and asserts `ErrorModule.__types__/0 == documented_set` for all six modules.

---

## Code Examples

### Error struct (pattern to follow)

[VERIFIED: `/Users/jon/projects/sigra/lib/sigra/error.ex` — confirmed prior art, ported to mailglass convention]

```elixir
defmodule Mailglass.TemplateError do
  @moduledoc "Raised when template compilation or rendering fails."

  @types [:heex_compile, :missing_assign, :helper_undefined, :inliner_failed]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @impl true
  def message(%{type: type, context: ctx}) do
    format_message(type, ctx)
  end

  @doc "Returns the closed set of valid :type values for this error."
  def __types__, do: @types

  @doc "Returns true if the error is safe to retry."
  def retryable?(%__MODULE__{}), do: false  # Fix the template; don't retry

  @doc "Build a new TemplateError struct."
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}
    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx
    }
  end

  defp format_message(:heex_compile, _ctx), do: "Template error: HEEx compilation failed"
  defp format_message(:missing_assign, %{key: k}), do: "Template error: required assign @#{k} is missing"
  defp format_message(:missing_assign, _), do: "Template error: required assign is missing"
  defp format_message(:helper_undefined, _), do: "Template error: undefined helper function"
  defp format_message(:inliner_failed, _), do: "Template error: CSS inlining failed"
end
```

### Telemetry span (pattern from sigra)

[VERIFIED: `/Users/jon/projects/sigra/lib/sigra/telemetry.ex` lines 216-224]

```elixir
defmodule Mailglass.Telemetry do
  @spec render_span(map(), (-> result)) :: result when result: term()
  def render_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    :telemetry.span([:mailglass, :render, :message], metadata, fn ->
      result = fun.()
      {result, metadata}
    end)
  end
end
```

### Config new!/1 with NimbleOptions (pattern from sigra)

[VERIFIED: `/Users/jon/projects/sigra/lib/sigra/config.ex` lines 928-931]

```elixir
@spec new!(keyword()) :: t()
def new!(opts) when is_list(opts) do
  validated = NimbleOptions.validate!(opts, @schema)
  struct!(__MODULE__, validated)
end
```

### `attr/3` with `values:` compile-time warnings

[VERIFIED: hexdocs.pm/phoenix_live_view/Phoenix.Component.html]

```elixir
defmodule Mailglass.Components do
  use Phoenix.Component

  attr :variant, :string, values: ~w(primary secondary ghost), default: "primary",
    doc: "Button style variant. Compile warning on invalid value."
  attr :tone, :string, values: ~w(glass ink slate), default: "glass",
    doc: "Brand color tone."
  attr :href, :string, required: true, doc: "Link destination URL."
  attr :class, :any, default: nil, doc: "Additional CSS classes."
  attr :rest, :global, include: ~w(id aria-label),
    doc: "HTML global attributes. Note: :style is intentionally excluded."
  slot :inner_block, required: true, doc: "Button label content."

  def button(assigns) do
    ~H"""
    <!--[if mso]>
    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" ...>
      <w:anchorlock/>
      <center>
    <![endif]-->
    <a href={@href}
       style={"background-color:#{theme_color(@tone)};..." <> merge_class(@class)}
       {@rest}>
      <%= render_slot(@inner_block) %>
    </a>
    <!--[if mso]></center></v:roundrect><![endif]-->
    """
  end
end
```

### OptionalDeps gateway

[VERIFIED: STACK.md §2.1 pattern]

```elixir
defmodule Mailglass.OptionalDeps.Oban do
  @compile {:no_warn_undefined, Oban}
  @moduledoc "Gateway for the optional :oban dependency."

  @doc "Returns true if Oban is loaded in the current environment."
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)
end
```

### `boundary` block for Renderer purity

[VERIFIED: ARCHITECTURE.md §7 boundary enforcement blocks]

```elixir
defmodule Mailglass.Renderer do
  use Boundary,
    deps: [
      Mailglass.Message,
      Mailglass.TemplateEngine,
      Mailglass.Components,
      Mailglass.Telemetry,
      Mailglass.Error
    ]
  # Mailglass.Outbound, Mailglass.Repo, Mailglass.Events are NOT in deps —
  # boundary will fail the build if Renderer accidentally imports them.
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `use Gettext` in every module (defines macros in calling module) | `use Gettext.Backend` + `use Gettext, backend: MyModule` (imports macros) | Gettext 0.26 / 1.0 (late 2025) | Reduces compile-time dependency graph; faster recompile on message changes |
| `:mrml` Hex package for MJML | `:mjml` Hex package (Rust NIF) | Always — `:mrml` never existed on Hex | STACK.md correction: use `{:mjml, "~> 5.3"}` not `{:mrml, ...}` |
| Premailex `keep_conditional_comments: true` option | Default behavior since PR #37 (June 2019) | Premailex ~0.3.x | No option needed; golden fixture test still required to guard regressions |
| LiveView internal parser: Floki | LiveView internal parser: lazy_html | LiveView 1.1 | Does NOT affect Floki as a standalone library for one-shot HTML transforms |
| `Application.compile_env` for all config | `Application.get_env` + NimbleOptions at boot | Ecosystem learning (2022-2024) | Release-artifact safety: config changes in `runtime.exs` take effect without rebuild |
| `attr :style, :string` on components | `attr :rest, :global, include: ~w(...)` WITHOUT `:style` | Phoenix.Component idiom refinement | Prevents the React Email footgun of merging inline styles with component defaults |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | EEx.eval_string with Phoenix.LiveView.TagEngine is the correct API for compiling/rendering HEEx in Phase 1 (no precompilation) | TemplateEngine.HEEx | May need to use Phoenix.Template or a different API; investigate before implementation |
| A2 | Premailex conditional comment preservation is indeed the default behavior (not requiring an option) based on PR #37 resolution | Premailex integration | If an option IS required, add `keep_conditional_comments: true` to `to_inline_css/2` call |
| A3 | 512-byte cap on IdempotencyKey is a reasonable Postgres index key heuristic | IdempotencyKey | Could be too small for providers with very long event IDs; adjust if needed |
| A4 | Floki parses `<!--[if mso]>...<![endif]-->` conditional comments as HTML comment nodes (not as element structure), so they produce no text in plaintext extraction | Renderer plaintext extraction | If Floki leaks VML tag content into plaintext, need explicit filter step |
| A5 | Performance target of <50ms is achievable with Premailex 0.3.20 on a typical 10-component email | Renderer performance | Profile against a realistic template; may need to optimize or cache compiled templates |
| A6 | `boundary ~> 0.10.4` is the correct current version | Standard Stack | Confirmed via `mix hex.info boundary` on 2026-04-22 |

---

## Open Questions

1. **HEEx compile API for library-owned templates**
   - What we know: `EEx.compile_string/2` with `engine: Phoenix.LiveView.TagEngine` is the documented approach
   - What's unclear: Whether `Phoenix.Template.render_to_iodata/3` is more appropriate for mailables that are modules with embedded templates
   - Recommendation: Start with `EEx.eval_string` in Phase 1; upgrade to precompiled template modules in Phase 3 when `Mailglass.Mailable` lands

2. **`Mailglass.Application` supervisor children for Phase 1**
   - What we know: Phase 1 has no processes — everything is pure functions except `:persistent_term` writes at boot
   - What's unclear: Whether `Mailglass.Application` needs to start ANY children in Phase 1, or just write to `:persistent_term` in `start/2`
   - Recommendation: `Mailglass.Application.start/2` validates config + populates `:persistent_term`; no supervisor children until Phase 3+ (PubSub, TaskSupervisor)

3. **`mix mailglass.gettext.extract` implementation scope**
   - What we know: AUTHOR-04 requires this task; the "emails" domain convention
   - What's unclear: Whether Phase 1 needs a real implementation or just a stub that delegates to `mix gettext.extract`
   - Recommendation: Phase 1 stub that prints instructions and delegates; full implementation in Phase 7 installer

4. **`api_stability.md` format**
   - What we know: The file must be created in Phase 1 and lock the error hierarchy + adapter return shape (stubbed) + component variant enums + telemetry catalog
   - What's unclear: Exact format — whether it's ExDoc-included or a standalone guide
   - Recommendation: Ship as `guides/api_stability.md` in Phase 1 (included in ExDoc extras); start minimal with error hierarchy and component enums, expand per phase

---

## Environment Availability

Phase 1 is purely code/config changes creating a new Hex package. No external services or databases required.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.18+ (check `elixir --version`) | — |
| OTP | All | ✓ | 27+ | — |
| Mix | Build | ✓ | bundled with Elixir | — |
| Postgres | NOT needed | N/A | — | Phase 2 introduces |
| Node | NOT needed | N/A | — | Explicitly excluded by project (no Node toolchain) |

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` (to be created in Wave 0) |
| Quick run command | `mix test test/mailglass/ --exclude integration` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-01 | Six error structs raisable and pattern-matchable by struct | unit | `mix test test/mailglass/error_test.exs` | ❌ Wave 0 |
| CORE-01 | `__types__/0` matches `api_stability.md` documented sets | unit | `mix test test/mailglass/error_test.exs::test_types_match_docs` | ❌ Wave 0 |
| CORE-01 | `Jason.Encoder` on errors excludes `:cause` | unit | `mix test test/mailglass/error_test.exs::test_json_encoding` | ❌ Wave 0 |
| CORE-02 | `Mailglass.Config.new!/1` validates required keys | unit | `mix test test/mailglass/config_test.exs` | ❌ Wave 0 |
| CORE-02 | Invalid config raises `NimbleOptions.ValidationError` | unit | `mix test test/mailglass/config_test.exs::test_validation_error` | ❌ Wave 0 |
| CORE-03 | Telemetry stop events contain only whitelisted metadata keys (StreamData 1000 renders) | property | `mix test test/mailglass/telemetry_test.exs` | ❌ Wave 0 |
| CORE-03 | Telemetry handler that raises does not break render pipeline | unit | `mix test test/mailglass/telemetry_test.exs::test_handler_isolation` | ❌ Wave 0 |
| CORE-04 | `Mailglass.Repo.transact/1` delegates to configured repo | unit (doctest) | `mix test test/mailglass/repo_test.exs` | ❌ Wave 0 |
| CORE-05 | `IdempotencyKey.for_webhook_event/2` produces deterministic keys | unit | `mix test test/mailglass/idempotency_key_test.exs` | ❌ Wave 0 |
| CORE-05 | Keys with control characters are sanitized | unit | `mix test test/mailglass/idempotency_key_test.exs::test_sanitization` | ❌ Wave 0 |
| CORE-06 | `mix compile --no-optional-deps --warnings-as-errors` passes | compile | `mix compile --no-optional-deps --warnings-as-errors` | ❌ Wave 0 |
| CORE-07 | Boundary violation: `Mailglass.Renderer` cannot depend on `Mailglass.Outbound` | compile | `mix compile` (boundary enforces) | ❌ Wave 0 |
| AUTHOR-02 | Premailex preserves conditional comments after CSS inlining (golden fixture) | integration | `mix test test/mailglass/components/vml_preservation_test.exs` | ❌ Wave 0 |
| AUTHOR-02 | `<.button>` renders VML wrapper in final HTML | unit | `mix test test/mailglass/components/button_test.exs` | ❌ Wave 0 |
| AUTHOR-02 | `<.img>` without `alt` raises compile error | compile | `mix compile test/mailglass/components/img_no_alt_test.exs` | ❌ Wave 0 |
| AUTHOR-02 | `<.row>` with non-column child emits Logger.warning | unit | `mix test test/mailglass/components/row_test.exs::test_non_column_warning` | ❌ Wave 0 |
| AUTHOR-03 | `Mailglass.Renderer.render/1` returns `{:ok, %Message{html_body: _, text_body: _}}` | unit | `mix test test/mailglass/renderer_test.exs` | ❌ Wave 0 |
| AUTHOR-03 | Plaintext excludes preheader text | unit | `mix test test/mailglass/renderer_test.exs::test_plaintext_skips_preheader` | ❌ Wave 0 |
| AUTHOR-03 | Plaintext for `<.button>` produces `"Label (url)"` format | unit | `mix test test/mailglass/renderer_test.exs::test_plaintext_link_pair` | ❌ Wave 0 |
| AUTHOR-03 | `data-mg-*` attributes stripped from final HTML wire | unit | `mix test test/mailglass/renderer_test.exs::test_data_attrs_stripped` | ❌ Wave 0 |
| AUTHOR-03 | Render completes in under 50ms for 10-component template | performance | `mix test test/mailglass/renderer_test.exs::test_render_performance` | ❌ Wave 0 |
| AUTHOR-05 | `Mailglass.TemplateEngine.HEEx.render/2` with missing assign returns `{:error, %TemplateError{type: :missing_assign}}` | unit | `mix test test/mailglass/template_engine/heex_test.exs` | ❌ Wave 0 |
| COMP-01 | `add_rfc_required_headers/1` adds Date, Message-ID, MIME-Version when absent | unit | `mix test test/mailglass/compliance_test.exs` | ❌ Wave 0 |
| COMP-01 | `add_rfc_required_headers/1` does not overwrite existing headers | unit | `mix test test/mailglass/compliance_test.exs::test_no_overwrite` | ❌ Wave 0 |
| COMP-02 | `Mailglass-Mailable` header has correct format | unit | `mix test test/mailglass/compliance_test.exs::test_mailable_header` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/ --exclude integration`
- **Per wave merge:** `mix test --warnings-as-errors`
- **Phase gate:** Full suite green + `mix compile --no-optional-deps --warnings-as-errors` + `mix credo --strict` before `/gsd-verify-work`

### Wave 0 Gaps

All test files listed above need creation. Priority order:

- [ ] `test/test_helper.exs` — ExUnit setup, Mox declarations for `Mailglass.TemplateEngine`
- [ ] `test/mailglass/error_test.exs` — covers CORE-01 including `__types__/0` vs `api_stability.md`
- [ ] `test/mailglass/telemetry_test.exs` — covers CORE-03 StreamData property test (D-33)
- [ ] `test/mailglass/components/vml_preservation_test.exs` — the golden fixture test for D-14 (highest risk, must be first)
- [ ] `test/mailglass/renderer_test.exs` — covers AUTHOR-03 end-to-end render
- [ ] `test/mailglass/config_test.exs` — covers CORE-02
- [ ] `test/mailglass/compliance_test.exs` — covers COMP-01, COMP-02
- [ ] Framework install: `mix deps.get` in fresh project — if none detected

---

## Security Domain

`security_enforcement` is not explicitly set to `false` in config — treat as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not in Phase 1 scope |
| V3 Session Management | no | Not in Phase 1 scope |
| V4 Access Control | no | Not in Phase 1 scope |
| V5 Input Validation | yes | NimbleOptions validates all config at boot; `attr/3` validates component attrs at compile time |
| V6 Cryptography | no | No crypto in Phase 1; Phase 4 introduces ECDSA webhook verification |
| V7 Error Handling | yes | Error structs exclude PII; `:cause` excluded from JSON serialization (D-06) |
| V8 Data Protection | yes | Telemetry metadata whitelist prevents PII in observability pipeline (D-31) |

### Known Threat Patterns for Phase 1 Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII in telemetry metadata | Information Disclosure | Whitelist enforced; Phase 6 Credo check; property test per D-33 |
| Sensitive data in error struct JSON | Information Disclosure | `@derive {Jason.Encoder, only: [:type, :message, :context]}` excludes `:cause` (D-06) |
| Template injection via HEEx assigns | Tampering | HEEx engine auto-escapes values; adopters using `{:safe, raw}` must opt in explicitly |
| Configuration injection via Application env | Tampering | All config reads via `Mailglass.Config`; NimbleOptions validates types and ranges at boot |

---

## Sources

### Primary (HIGH confidence)

- **CONTEXT.md** (`/Users/jon/projects/mailglass/.planning/phases/01-foundation/01-CONTEXT.md`) — 33 locked decisions D-01..D-33
- **STACK.md** (`/Users/jon/projects/mailglass/.planning/research/STACK.md`) — verified Apr 2026 versions for all deps
- **ARCHITECTURE.md** (`/Users/jon/projects/mailglass/.planning/research/ARCHITECTURE.md`) — module catalog, data flow, boundary blocks
- **PITFALLS.md** (`/Users/jon/projects/mailglass/.planning/research/PITFALLS.md`) — LIB-02, LIB-07, OBS-01, DIST-04, MAINT-04 pitfalls
- **SUMMARY.md** (`/Users/jon/projects/mailglass/.planning/research/SUMMARY.md`) — Phase 1 implications synthesis
- **sigra prior art** (`/Users/jon/projects/sigra/lib/sigra/error.ex`, `config.ex`, `telemetry.ex`) — confirmed error/config/telemetry patterns
- **Premailex PR #37** (https://github.com/danschultzer/premailex/pull/37) — conditional comment preservation is default behavior
- **Phoenix.Component docs** (https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) — `attr/3`, `slot/3`, `values:`, `:global` with `include:`
- **Floki docs** (https://hexdocs.pm/floki/Floki.html) — `traverse_and_update/2`, `parse_document/1`, `raw_html/1`
- **Gettext 1.0 docs** (https://hexdocs.pm/gettext/Gettext.html) — `use Gettext.Backend`, `use Gettext, backend:`
- **Hex.pm** — `boundary 0.10.4` version confirmed via `mix hex.info boundary`

### Secondary (MEDIUM confidence)

- **Premailex hexdocs** (https://hexdocs.pm/premailex/Premailex.html) — `to_inline_css/2`, `to_text/1` signatures; options list (css_selector, optimize)
- **Engineering DNA** (`/Users/jon/projects/mailglass/prompts/mailglass-engineering-dna-from-prior-libs.md`) — 4-of-4 convergent patterns
- **REQUIREMENTS.md** — CORE-01..07, AUTHOR-02..05, COMP-01..02 requirement text
- **ROADMAP.md** — Phase 1 success criteria

### Tertiary (LOW confidence / ASSUMED)

- EEx.eval_string with Phoenix.LiveView.TagEngine as the Phase 1 HEEx render approach (A1)
- 512-byte IdempotencyKey cap (A3)
- <50ms render performance target achievability (A5)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified against Hex.pm in STACK.md (Apr 2026)
- Architecture (Layer 0 + 1): HIGH — locked decisions + sigra prior art confirmed
- Premailex VML preservation: HIGH — PR #37 confirmed resolution; no option needed
- Floki traversal API: HIGH — confirmed from hexdocs
- Phoenix.Component attr/slot API: HIGH — confirmed from hexdocs
- Gettext 1.0 pattern: HIGH — confirmed from hexdocs
- HEEx render API details: MEDIUM — one assumption (A1) needs verification during implementation
- Renderer performance (<50ms): LOW — assumed, needs profiling

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (stable libraries; premailex should be re-checked if a new release appears)

---

## RESEARCH COMPLETE
