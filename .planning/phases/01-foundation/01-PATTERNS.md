# Phase 1: Foundation — Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 28 new files (greenfield — no existing mailglass source)
**Analogs found:** 26 / 28 (2 have no close codebase match; use RESEARCH.md patterns)

---

## Codebase State

The mailglass project directory contains only `CLAUDE.md`, `.planning/`, and `prompts/`. There is no `lib/`, no `mix.exs`, and no prior modules. Every file in Phase 1 is created from scratch. All analogs are drawn from the four prior-art sibling libraries at:

- `/Users/jon/projects/sigra` — primary source (Error, Config, Telemetry, Application, mix.exs)
- `/Users/jon/projects/accrue/accrue` — secondary source (Repo.transact, Config validate_at_boot!, optional dep gateway, Telemetry span/3)
- `/Users/jon/projects/accrue/accrue_admin` — layout component pattern
- `/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex` — Phoenix.Component with inline styles
- `/Users/jon/projects/sigra/test/example/lib/example_web/components/core_components.ex` — Phoenix 1.8 attr :rest :global + values: pattern

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mix.exs` | config | — | `/Users/jon/projects/sigra/mix.exs` | exact |
| `config/config.exs` | config | — | sigra config pattern (Application.get_env) | role-match |
| `config/dev.exs` | config | — | sigra config pattern | role-match |
| `config/prod.exs` | config | — | sigra config pattern | role-match |
| `config/test.exs` | config | — | sigra config pattern | role-match |
| `lib/mailglass.ex` | facade | — | `/Users/jon/projects/sigra/lib/sigra.ex` | exact |
| `lib/mailglass/application.ex` | supervisor | — | `/Users/jon/projects/sigra/lib/sigra/application.ex` | exact |
| `lib/mailglass/error.ex` | namespace+behaviour | — | `/Users/jon/projects/sigra/lib/sigra/error.ex` (namespace) + RESEARCH.md | role-match |
| `lib/mailglass/errors/send_error.ex` | error | — | `/Users/jon/projects/sigra/lib/sigra/error.ex` (RateLimited, OAuthError) | exact |
| `lib/mailglass/errors/template_error.ex` | error | — | sigra error sibling pattern | exact |
| `lib/mailglass/errors/signature_error.ex` | error | — | sigra error sibling pattern | exact |
| `lib/mailglass/errors/suppressed_error.ex` | error | — | sigra error sibling pattern | exact |
| `lib/mailglass/errors/rate_limit_error.ex` | error | — | `/Users/jon/projects/sigra/lib/sigra/error.ex` RateLimited | exact |
| `lib/mailglass/errors/config_error.ex` | error | — | sigra error sibling pattern | exact |
| `lib/mailglass/config.ex` | config | — | `/Users/jon/projects/sigra/lib/sigra/config.ex` + `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex` | exact |
| `lib/mailglass/telemetry.ex` | telemetry | — | `/Users/jon/projects/sigra/lib/sigra/telemetry.ex` + `/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex` | exact |
| `lib/mailglass/repo.ex` | utility | CRUD | `/Users/jon/projects/accrue/accrue/lib/accrue/repo.ex` | exact |
| `lib/mailglass/idempotency_key.ex` | utility | transform | accrue IdempotencyKey pattern (pure module) | role-match |
| `lib/mailglass/optional_deps.ex` | utility | — | `/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex` + sigra elixirc_options | exact |
| `lib/mailglass/optional_deps/oban.ex` | utility | — | accrue Code.ensure_loaded? pattern | exact |
| `lib/mailglass/optional_deps/opentelemetry.ex` | utility | — | accrue `@compile {:no_warn_undefined}` pattern | exact |
| `lib/mailglass/optional_deps/mjml.ex` | utility | — | accrue optional dep gateway pattern | exact |
| `lib/mailglass/optional_deps/gen_smtp.ex` | utility | — | accrue optional dep gateway pattern | exact |
| `lib/mailglass/optional_deps/sigra.ex` | utility | — | accrue Integrations.Sigra pattern | exact |
| `lib/mailglass/message.ex` | model | transform | lattice_stripe struct pattern | role-match |
| `lib/mailglass/components.ex` | component | transform | `/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex` + core_components.ex | role-match |
| `lib/mailglass/components/layout.ex` | component | transform | `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/layouts.ex` | role-match |
| `lib/mailglass/template_engine.ex` | behaviour | — | accrue `Accrue.Auth` behaviour pattern | role-match |
| `lib/mailglass/template_engine/heex.ex` | service | transform | accrue HtmlBridge render pattern | role-match |
| `lib/mailglass/renderer.ex` | service | transform | accrue HtmlBridge + Telemetry span pattern | role-match |
| `lib/mailglass/compliance.ex` | utility | transform | no close analog | none |
| `lib/mailglass/gettext.ex` | utility | — | sigra Gettext.Backend usage | role-match |
| `docs/api_stability.md` | docs | — | no code analog | none |

---

## Pattern Assignments

### `mix.exs` (config)

**Analog:** `/Users/jon/projects/sigra/mix.exs`

**Project manifest pattern** (lines 1-58):
```elixir
defmodule Mailglass.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mailglass/mailglass"

  def project do
    [
      app: :mailglass,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Mailglass",
      description: "...",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Mailglass.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
```

**Optional-dep `no_warn_undefined` pattern** (sigra mix.exs lines 68-93 — apply to mailglass optional deps):
```elixir
defp elixirc_options do
  [
    no_warn_undefined: [
      Oban,
      Oban.Worker,
      Oban.Job,
      # :otel_tracer is an erlang atom module, not an Elixir module
      :otel_tracer,
      :otel_span,
      Mjml,
      :gen_smtp_client,
      Sigra
    ]
  ]
end
```

**Deps block** (from RESEARCH.md — verified versions):
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
    {:jason,             "~> 1.4"},
    # Optional
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

---

### `lib/mailglass.ex` (facade module)

**Analog:** `/Users/jon/projects/sigra/lib/sigra.ex` (lines 1-31)

**Top-level facade pattern** — public `@moduledoc` only, no implementation:
```elixir
defmodule Mailglass do
  @moduledoc """
  Transactional email framework for Phoenix.

  Composes on top of Swoosh, shipping the framework layer Swoosh omits:
  HEEx-native components, LiveView preview dashboard, normalized webhook
  events, suppression lists, RFC 8058 List-Unsubscribe, multi-tenant routing,
  and an append-only event ledger.

  ## Getting Started

      config :mailglass,
        repo: MyApp.Repo,
        adapter: {Mailglass.Adapters.Swoosh, swoosh_adapter: {Swoosh.Adapters.Postmark, api_key: "..."}}

  ## Architecture

  See `Mailglass.Config`, `Mailglass.Renderer`, `Mailglass.Components`.
  """
end
```

---

### `lib/mailglass/application.ex` (Application supervisor)

**Analog:** `/Users/jon/projects/sigra/lib/sigra/application.ex` (lines 1-150)

**Imports pattern** (lines 1-4):
```elixir
defmodule Mailglass.Application do
  use Application
  require Logger
```

**Boot-time validation + empty supervisor pattern** (lines 21-27 of sigra):
```elixir
@impl Application
def start(_type, _args) do
  :ok = Mailglass.Config.validate_at_boot!()
  maybe_warn_missing_oban()

  children = [
    {Phoenix.PubSub, name: Mailglass.PubSub},
    {Registry, keys: :unique, name: Mailglass.AdapterRegistry},
    {Task.Supervisor, name: Mailglass.TaskSupervisor}
  ]

  Supervisor.start_link(children, strategy: :one_for_one, name: Mailglass.Supervisor)
end
```

**Optional-dep boot warning pattern** (sigra lines 68-88 — adapt for Oban):
```elixir
defp maybe_warn_missing_oban do
  unless Code.ensure_loaded?(Oban) do
    Logger.warning("""
    [Mailglass] Oban is not loaded. deliver_later/2 will use Task.Supervisor
    as a fallback, which does not survive node restarts. Add {:oban, "~> 2.21"}
    to your mix.exs for production use.
    """)
  end
end
```

---

### `lib/mailglass/error.ex` (namespace + behaviour)

**Analog:** `/Users/jon/projects/sigra/lib/sigra/error.ex` (namespace portion) + RESEARCH.md §Error hierarchy

**Namespace + behaviour module** — NOT a struct, NOT defexception:
```elixir
defmodule Mailglass.Error do
  @moduledoc """
  Namespace and behaviour for the mailglass error hierarchy.

  ## Error Types

  - `Mailglass.SendError` — delivery failure (adapter, render, preflight, serialization)
  - `Mailglass.TemplateError` — HEEx compile, missing assign, helper, inliner
  - `Mailglass.SignatureError` — webhook signature missing, malformed, mismatch, stale
  - `Mailglass.SuppressedError` — delivery blocked by suppression list
  - `Mailglass.RateLimitError` — rate limit exceeded (domain, tenant, stream)
  - `Mailglass.ConfigError` — configuration missing, invalid, conflicting

  ## Pattern Matching

  Always match on the struct module and `:type` field, never on `:message`:

      case result do
        {:error, %Mailglass.SuppressedError{type: :address}} -> ...
        {:error, %Mailglass.RateLimitError{retry_after_ms: ms}} -> ...
        {:error, %Mailglass.SendError{}} -> ...
      end
  """

  @type t ::
          Mailglass.SendError.t()
          | Mailglass.TemplateError.t()
          | Mailglass.SignatureError.t()
          | Mailglass.SuppressedError.t()
          | Mailglass.RateLimitError.t()
          | Mailglass.ConfigError.t()

  @callback type(t()) :: atom()
  @callback retryable?(t()) :: boolean()

  @error_modules [
    Mailglass.SendError,
    Mailglass.TemplateError,
    Mailglass.SignatureError,
    Mailglass.SuppressedError,
    Mailglass.RateLimitError,
    Mailglass.ConfigError
  ]

  @doc "Returns true if the value is a mailglass error struct."
  @doc since: "0.1.0"
  @spec is_error?(term()) :: boolean()
  def is_error?(%{__struct__: s}) when s in @error_modules, do: true
  def is_error?(_), do: false

  @doc "Returns the :type atom from any mailglass error struct."
  @doc since: "0.1.0"
  @spec kind(t()) :: atom()
  def kind(%{type: type}), do: type

  @doc "Returns true if the error is retryable per the struct's retryable?/1 callback."
  @doc since: "0.1.0"
  @spec retryable?(t()) :: boolean()
  def retryable?(%{__struct__: s} = err), do: s.retryable?(err)

  @doc "Walks :cause chain to the root error."
  @doc since: "0.1.0"
  @spec root_cause(t()) :: t()
  def root_cause(%{cause: nil} = err), do: err
  def root_cause(%{cause: cause}), do: root_cause(cause)
  def root_cause(err), do: err
end
```

---

### `lib/mailglass/errors/send_error.ex` (and all six sibling errors)

**Analog:** `/Users/jon/projects/sigra/lib/sigra/error.ex` — specifically `RateLimited` (line 41-43), `OAuthError` (lines 51-69), `MFAError` (lines 71-105)

**Sibling defexception pattern** — copy this structure for all six errors:
```elixir
defmodule Mailglass.SendError do
  @moduledoc """
  Raised when email delivery fails.

  ## Types

  - `:adapter_failure` — the Swoosh adapter returned an error
  - `:rendering_failed` — HEEx or CSS-inlining pipeline failed
  - `:preflight_rejected` — suppression or rate-limit check blocked the send
  - `:serialization_failed` — message could not be serialized for the adapter
  """

  @behaviour Mailglass.Error

  @types [:adapter_failure, :rendering_failed, :preflight_rejected, :serialization_failed]

  # D-06: Jason.Encoder on [:type, :message, :context] only — :cause excluded
  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, :delivery_id]

  @type t :: %__MODULE__{
          type: :adapter_failure | :rendering_failed | :preflight_rejected | :serialization_failed,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          delivery_id: binary() | nil
        }

  @doc "Returns the closed set of valid :type atoms. Tested against api_stability.md."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{type: :adapter_failure}), do: true
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}
    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      delivery_id: opts[:delivery_id]
    }
  end

  # Brand-voice-conformant messages (D-08). Never "Oops!" or "Something went wrong."
  defp format_message(:adapter_failure, _ctx), do: "Delivery failed: adapter returned an error"
  defp format_message(:rendering_failed, _ctx), do: "Delivery failed: template could not be rendered"
  defp format_message(:preflight_rejected, _ctx), do: "Delivery blocked: pre-send check failed"
  defp format_message(:serialization_failed, _ctx), do: "Delivery failed: message could not be serialized"
end
```

**Per-kind specializations** (from CONTEXT.md D-04):
- `RateLimitError` adds `retry_after_ms :: non_neg_integer` field
- `SignatureError` adds `provider :: atom` field
- `SendError` adds `delivery_id :: binary | nil` field

**Brand-voice messages for all six** (from RESEARCH.md §1):
- `SuppressedError :address` → `"Delivery blocked: recipient is on the suppression list"`
- `SuppressedError :domain` → `"Delivery blocked: recipient domain is on the suppression list"`
- `ConfigError :missing` → `"Configuration error: required key :#{key} is not set"`
- `ConfigError :optional_dep_missing` → `"Configuration error: optional dependency #{dep} is not loaded"`
- `RateLimitError :per_domain` → `"Rate limit exceeded: retry after #{ms}ms"`
- `SignatureError :mismatch` → `"Webhook signature verification failed: signature does not match"`
- `TemplateError :missing_assign` → `"Template error: required assign @#{name} is missing"`

**Retry policy** (CONTEXT.md D-09):
- `SignatureError`, `ConfigError` → `retryable?/1` returns `false` (crash + supervise)
- `SendError :adapter_failure` → `true`
- `RateLimitError` → `true` (caller uses retry_after_ms)
- `SuppressedError` → `false` (permanent policy block)
- `TemplateError` → `false` in prod

---

### `lib/mailglass/config.ex` (NimbleOptions + struct)

**Analog:** `/Users/jon/projects/sigra/lib/sigra/config.ex` (primary) + `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex` (validate_at_boot! pattern)

**Schema declaration pattern** (sigra/config.ex lines 48-821):
```elixir
defmodule Mailglass.Config do
  @moduledoc """
  Runtime configuration for mailglass, validated via NimbleOptions at boot.

  **Only this module may call `Application.compile_env*`.**
  All other modules read config via `Application.get_env/2`.

  ## Options

  #{NimbleOptions.docs(@schema)}
  """

  # Schema is declared BEFORE @moduledoc so NimbleOptions.docs/1 works
  @schema [
    repo: [
      type: :atom,
      required: true,
      doc: "The adopter's Ecto.Repo module. Mailglass routes all DB writes through it."
    ],
    adapter: [
      type: :any,
      default: {Mailglass.Adapters.Fake, []},
      doc: "Adapter module or {module, opts} tuple. Default: Fake (for dev/test)."
    ],
    theme: [
      type: :keyword_list,
      default: [],
      doc: "Brand theme tokens. See Mailglass.Components.Theme.",
      keys: [
        colors: [
          type: :map,
          default: %{
            ink: "#0D1B2A", glass: "#277B96", ice: "#A6EAF2",
            mist: "#EAF6FB", paper: "#F8FBFD", slate: "#5C6B7A"
          },
          doc: "Brand color map. Keys: :ink, :glass, :ice, :mist, :paper, :slate."
        ],
        fonts: [
          type: :map,
          default: %{
            body: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            display: "'Inter Tight', 'Inter', sans-serif",
            mono: "'IBM Plex Mono', ui-monospace, monospace"
          },
          doc: "Font-stack map. Keys: :body, :display, :mono."
        ]
      ]
    ],
    telemetry: [
      type: :keyword_list,
      default: [],
      doc: "Telemetry options.",
      keys: [
        default_logger: [type: :boolean, default: false,
          doc: "Attach the default logger handler at boot. Default: false."]
      ]
    ],
    renderer: [
      type: :keyword_list,
      default: [],
      doc: "Renderer options.",
      keys: [
        css_inliner: [type: {:in, [:premailex, :none]}, default: :premailex,
          doc: "CSS inlining backend. Default: :premailex."],
        plaintext: [type: :boolean, default: true,
          doc: "Auto-generate plaintext body. Default: true."]
      ]
    ],
    tenancy: [
      type: {:or, [:atom, nil]},
      default: Mailglass.Tenancy.SingleTenant,
      doc: "Module implementing Mailglass.Tenancy behaviour."
    ],
    suppression_store: [
      type: {:or, [:atom, nil]},
      default: Mailglass.SuppressionStore.Ecto,
      doc: "Module implementing Mailglass.SuppressionStore behaviour."
    ]
  ]
```

**`new!/1` builder** (sigra/config.ex lines 926-931):
```elixir
  @doc since: "0.1.0"
  @spec new!(keyword()) :: t()
  def new!(opts) when is_list(opts) do
    validated = NimbleOptions.validate!(opts, @schema)
    struct!(__MODULE__, validated)
  end
```

**`validate_at_boot!/0` pattern** (accrue/config.ex lines 385-396):
```elixir
  @doc false
  @spec validate_at_boot!() :: :ok
  def validate_at_boot! do
    known_keys = Keyword.keys(@schema)

    opts =
      :mailglass
      |> Application.get_all_env()
      |> Keyword.take(known_keys)

    _ = NimbleOptions.validate!(opts, @schema)
    :ok
  end
```

**Theme caching in `:persistent_term`** (from CONTEXT.md D-19 — no direct analog, implement in `validate_at_boot!/0`):
```elixir
  # Called from validate_at_boot!/0 after NimbleOptions validates
  defp cache_theme!(opts) do
    theme = Keyword.get(opts, :theme, [])
    :persistent_term.put({Mailglass.Config, :theme}, theme)
  end

  @doc "Reads the cached theme map. Raises if validate_at_boot!/0 was not called."
  @spec get_theme() :: keyword()
  def get_theme do
    :persistent_term.get({Mailglass.Config, :theme})
  end
```

---

### `lib/mailglass/telemetry.ex` (Telemetry)

**Analog:** `/Users/jon/projects/sigra/lib/sigra/telemetry.ex` (primary — all 368 lines) + `/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex` (lines 1-94, span/3 pattern)

**Module header with event catalog in @moduledoc** (sigra/telemetry.ex lines 1-96):
```elixir
defmodule Mailglass.Telemetry do
  @moduledoc """
  Telemetry integration for mailglass.

  ## Event Naming Convention

  All mailglass events follow the 4-level path plus phase suffix:

      [:mailglass, :domain, :resource, :action, :start | :stop | :exception]

  ## Phase 1 Events

  ### Render pipeline

    * `[:mailglass, :render, :message, :start | :stop | :exception]`
      — Measurements: `%{system_time: integer}` on :start; `%{duration: native_time}` on :stop
      — Metadata: `%{tenant_id: string, mailable: atom}`

  ## Metadata Policy

  **Whitelisted keys:** `:tenant_id, :mailable, :provider, :status, :message_id,
  :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`

  **Forbidden (PII):** `:to, :from, :body, :html_body, :subject, :headers,
  :recipient, :email`

  ## Default Logger

  Call `attach_default_logger/1` to log all mailglass events:

      Mailglass.Telemetry.attach_default_logger()
      Mailglass.Telemetry.attach_default_logger(level: :warning)
  """

  require Logger
```

**`span/3` wrapper** (sigra/telemetry.ex lines 216-224; accrue/telemetry.ex lines 57-67):
```elixir
  @doc """
  Wraps `fun` in a `:telemetry.span/3` call, emitting :start, :stop, :exception.

  ## Examples

      Mailglass.Telemetry.render_span([:mailglass, :render, :message], %{tenant_id: id}, fn ->
        Premailex.to_inline_css(html)
      end)
  """
  @doc since: "0.1.0"
  @spec span([atom()], map(), (-> result)) :: result when result: term()
  def span(event_prefix, metadata, fun)
      when is_list(event_prefix) and is_map(metadata) and is_function(fun, 0) do
    :telemetry.span(event_prefix, metadata, fn ->
      result = fun.()
      {result, metadata}
    end)
  end

  @doc "Named span helper for the render pipeline. Phase 1 surface."
  @doc since: "0.1.0"
  @spec render_span(map(), (-> result)) :: result when result: term()
  def render_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :render, :message], metadata, fun)
  end
```

**`execute/3` one-shot wrapper** (sigra/telemetry.ex lines 238-241):
```elixir
  @doc since: "0.1.0"
  @spec execute([atom()], map(), map()) :: :ok
  def execute(event_name, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(event_name, measurements, metadata)
  end
```

**`attach_default_logger/1` pattern** (sigra/telemetry.ex lines 340-348):
```elixir
  @handler_name "mailglass-default-logger"

  @logged_events [
    [:mailglass, :render, :message, :stop],
    [:mailglass, :render, :message, :exception]
    # Expanded per phase as new spans land
  ]

  @doc since: "0.1.0"
  @spec attach_default_logger(keyword()) :: :ok | {:error, :already_exists}
  def attach_default_logger(opts \\ []) do
    :telemetry.attach_many(
      @handler_name,
      @logged_events,
      &__MODULE__.handle_event/4,
      opts
    )
  end

  @doc false
  def handle_event(event, measurements, metadata, opts) do
    level = Keyword.get(opts, :level, :info)
    Logger.log(level, fn -> format_event(event, measurements, metadata) end)
  end

  defp format_event(event, measurements, metadata) do
    [_mailglass | rest] = event
    label = rest |> Enum.map_join(".", &Atom.to_string/1)
    "[Mailglass] #{label} #{inspect(measurements)} #{inspect(metadata)}"
  end
```

---

### `lib/mailglass/repo.ex` (Repo.transact wrapper)

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/repo.ex` (all 193 lines — exact pattern)

**Phase 1 scope: slim facade** — only `transact/1` is needed in Phase 1; other delegates land when their usage phases arrive. Copy the structural pattern but start minimal:

**Imports and resolver** (accrue/repo.ex lines 1-18, 176-193):
```elixir
defmodule Mailglass.Repo do
  @moduledoc """
  Thin facade over the host-configured Ecto.Repo.

  Mailglass does not own a Repo (the host application does). Every context
  module that needs Postgres routes through this facade, which resolves the
  real Repo via `Application.get_env(:mailglass, :repo)` at call time.

  Runtime resolution is deliberate: tests inject a test repo through
  `config/test.exs`; host apps inject their Repo through `config :mailglass,
  repo: MyApp.Repo` without recompiling mailglass.

  This module re-exports only what mailglass itself uses. Call the host Repo
  directly for lower-level operations.
  """
```

**`transact/1` — primary Phase 1 export** (accrue/repo.ex lines 24-27):
```elixir
  @doc """
  Delegates to `c:Ecto.Repo.transact/2`. Preferred over `transaction/2` for
  Ecto 3.13+ API. Accepts a zero-arity function.

  ## Examples

      iex> Mailglass.Repo.transact(fn -> {:ok, :done} end)
      {:ok, :done}
  """
  @doc since: "0.1.0"
  @spec transact((-> any()), keyword()) :: {:ok, any()} | {:error, any()}
  def transact(fun, opts \\ []) when is_function(fun), do: repo().transact(fun, opts)
```

**SQLSTATE 45A01 translation** (accrue/repo.ex lines 57-77 — copy verbatim, rename error):
```elixir
  # Called in Phase 2+ when mailglass_events trigger fires
  defp translate_immutability_error(err) do
    case err do
      %Postgrex.Error{postgres: %{pg_code: "45A01"}} ->
        reraise Mailglass.EventLedgerImmutableError,
                [pg_code: "45A01"],
                __STACKTRACE__
      _ ->
        reraise err, __STACKTRACE__
    end
  end
```

**`repo/0` resolver** (accrue/repo.ex lines 176-193):
```elixir
  @spec repo() :: module()
  def repo do
    case Application.get_env(:mailglass, :repo) do
      nil ->
        raise Mailglass.ConfigError.new(:missing,
          context: %{key: :repo},
          message: "Configuration error: required key :repo is not set"
        )
      mod when is_atom(mod) ->
        mod
    end
  end
```

---

### `lib/mailglass/idempotency_key.ex` (pure utility)

**Analog:** No direct file analog in prior-art libs. Pattern inferred from accrue event key usage in `/Users/jon/projects/accrue/accrue/lib/accrue/events.ex` (line references to idempotency key generation).

**Pure module pattern** (from CONTEXT.md D-05 + CORE-05):
```elixir
defmodule Mailglass.IdempotencyKey do
  @moduledoc """
  Generates deterministic idempotency keys for webhook deduplication and
  event ledger entries.

  Key format: `"#{provider}:#{provider_event_id}"` per CORE-05.
  """

  @max_length 512

  @doc since: "0.1.0"
  @spec for_webhook_event(atom(), String.t()) :: String.t()
  def for_webhook_event(provider, event_id)
      when is_atom(provider) and is_binary(event_id) do
    sanitize("#{provider}:#{event_id}")
  end

  @doc since: "0.1.0"
  @spec for_provider_message_id(atom(), String.t()) :: String.t()
  def for_provider_message_id(provider, message_id)
      when is_atom(provider) and is_binary(message_id) do
    sanitize("#{provider}:msg:#{message_id}")
  end

  defp sanitize(key) do
    key
    |> String.replace(~r/[^\x20-\x7E]/, "")
    |> String.slice(0, @max_length)
  end
end
```

---

### `lib/mailglass/optional_deps.ex` + sibling gateway modules

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex` (full file — 75 lines) + sigra `mix.exs` elixirc_options `no_warn_undefined` list (lines 68-93)

**Gateway module pattern** — the root namespace module holds the shared `available?` contract:
```elixir
defmodule Mailglass.OptionalDeps do
  @moduledoc """
  Namespace for optional dependency gateway modules.

  Each submodule gates one optional dependency behind a `Code.ensure_loaded?/1`
  check at compile time and exposes `available?/0` + a degraded fallback at
  runtime. The `@compile {:no_warn_undefined, ...}` declaration in mix.exs
  (not here) suppresses compiler warnings when the dep is absent.
  """
end
```

**Per-dep gateway module pattern** (accrue/integrations/sigra.ex lines 31-75):
```elixir
defmodule Mailglass.OptionalDeps.Oban do
  @moduledoc """
  Gateway for the optional Oban dependency.

  When Oban is present, `available?/0` returns true and callers can safely
  reference Oban modules. When absent, the fallback path (Task.Supervisor)
  is used with a Logger.warning at boot.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

  @doc "Returns true when :oban is loaded in the current runtime."
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)
end
```

```elixir
defmodule Mailglass.OptionalDeps.OpenTelemetry do
  @moduledoc "Gateway for the optional :opentelemetry dependency."

  @compile {:no_warn_undefined, [:otel_tracer, :otel_span]}

  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(:otel_tracer)
end
```

```elixir
defmodule Mailglass.OptionalDeps.Mjml do
  @moduledoc "Gateway for the optional :mjml NIF dependency."

  @compile {:no_warn_undefined, [Mjml]}

  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Mjml)
end
```

```elixir
defmodule Mailglass.OptionalDeps.GenSmtp do
  @moduledoc "Gateway for the optional :gen_smtp dependency."

  @compile {:no_warn_undefined, [:gen_smtp_client]}

  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(:gen_smtp_client)
end
```

```elixir
# Conditionally compiled — entire defmodule is elided when :sigra is absent
if Code.ensure_loaded?(Sigra) do
  defmodule Mailglass.OptionalDeps.Sigra do
    @moduledoc "Gateway for the optional :sigra integration."
    @compile {:no_warn_undefined, [Sigra]}

    @doc since: "0.1.0"
    @spec available?() :: boolean()
    def available?, do: true  # only exists when ensure_loaded? was true above
  end
end
```

---

### `lib/mailglass/message.ex` (struct)

**Analog:** No exact analog in prior-art libs (they don't wrap email structs). LatticeStripe resource struct pattern applies for the field/type pattern.

**Struct pattern** (from ARCHITECTURE.md §1.1 + RESEARCH.md):
```elixir
defmodule Mailglass.Message do
  @moduledoc """
  A rendered or partially-rendered email message.

  Wraps `%Swoosh.Email{}` and carries mailglass-specific metadata.
  """

  @type t :: %__MODULE__{
          swoosh_email: Swoosh.Email.t(),
          mailable: module() | nil,
          tenant_id: String.t() | nil,
          stream: :transactional | :operational | :bulk,
          tags: [String.t()],
          metadata: %{atom() => term()}
        }

  defstruct [
    :swoosh_email,
    :mailable,
    :tenant_id,
    stream: :transactional,
    tags: [],
    metadata: %{}
  ]
end
```

---

### `lib/mailglass/components.ex` (HEEx function components)

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex` (all 183 lines) + `/Users/jon/projects/sigra/test/example/lib/example_web/components/core_components.ex` (lines 29-115)

**Module-level imports pattern** (accrue/invoices/components.ex line 32; core_components.ex lines 29-30):
```elixir
defmodule Mailglass.Components do
  @moduledoc """
  HEEx function components for transactional email composition.

  ## Components

  - Layout: `<.container>`, `<.section>`, `<.row>`, `<.column>`
  - Content: `<.heading>`, `<.text>`, `<.button>`, `<.link>`
  - Atomic: `<.img>`, `<.hr>`, `<.preheader>`

  ## Theme

  All brand-token attributes (`:tone`, `:variant`, `:bg`) resolve via
  `Mailglass.Config.get_theme()` at render time (read from `:persistent_term`).
  CSS variables are NOT used — styles are fully inlined.

  ## MSO / Outlook

  `<.row>` and `<.column>` emit ghost-table VML conditionals.
  `<.button>` emits `<v:roundrect>` bulletproof button.
  See CONTEXT.md D-10..D-11 for the per-component VML specification.
  """

  use Phoenix.Component
```

**`attr :class :any` + `attr :rest :global` pattern** (core_components.ex lines 89-92 — D-16, D-17):
```elixir
  # Content component attr block (D-17):
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(id data-testid aria-label aria-hidden)
  # Note: :style is deliberately EXCLUDED from :global on content components (D-17)
```

**`attr :variant` with `values:` enum** (core_components.ex line 91 — D-18):
```elixir
  attr :variant, :string, values: ~w(primary secondary ghost), default: "primary"
  attr :tone, :string, values: ~w(glass ink slate), default: "glass"
```

**Slot + inner_block pattern** (accrue/invoices/components.ex lines 36-63; core_components.ex lines 92-115):
```elixir
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <!--[if mso]>
    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml"
                 xmlns:w="urn:schemas-microsoft-com:office:word"
                 href={@rest[:href] || "#"}
                 style="height:44px;v-text-anchor:middle;width:200px;"
                 arcsize="8%"
                 fillcolor={theme_color(@tone)}
                 strokecolor={theme_color(@tone)}>
      <w:anchorlock/>
      <center style={merge_style("font-family: #{theme_font(:body)}; ...", @class)}>
        {render_slot(@inner_block)}
      </center>
    </v:roundrect>
    <![endif]-->
    <!--[if !mso]><!-->
    <a href={@rest[:href] || "#"}
       style={merge_style("display:inline-block;...", @class)}
       data-mg-plaintext="link_pair"
       {@rest}>
      {render_slot(@inner_block)}
    </a>
    <!--<![endif]-->
    """
  end
```

**Atomic (no-slot) component pattern** (`<.img>` — D-18 required alt):
```elixir
  attr :src, :string, required: true
  attr :alt, :string, required: true   # D-18: required for accessibility, compile error if absent
  attr :width, :integer, default: nil
  attr :height, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(id)

  def img(assigns) do
    ~H"""
    <img src={@src}
         alt={@alt}
         width={@width}
         height={@height}
         style={merge_style("-ms-interpolation-mode:bicubic;max-width:100%;border:0;", @class)}
         data-mg-plaintext="text"
         {@rest} />
    """
  end
```

**Preheader pattern** (CONTEXT.md D-25, Specifics section):
```elixir
  attr :text, :string, required: true

  def preheader(assigns) do
    ~H"""
    <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;"
         aria-hidden="true"
         data-mg-plaintext="skip">
      {@text}
      &#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;
      &#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;
    </div>
    """
  end
```

**CSS helper** (D-20 — class composition, no external library):
```elixir
  # Private helper: merges a base inline style string with an optional class or style string.
  # Returns a single style="..." string. Used where inline-style merging is needed.
  defp merge_style(base, nil), do: base
  defp merge_style(base, extra) when is_binary(extra), do: "#{base} #{extra}"
  defp merge_style(base, list) when is_list(list) do
    list |> Enum.filter(& &1) |> Enum.join(" ") |> then(&merge_style(base, &1))
  end

  defp theme_color(tone) do
    colors = Mailglass.Config.get_theme()[:colors] || %{}
    Map.get(colors, String.to_atom(tone), "#277B96")
  end

  defp theme_font(key) do
    fonts = Mailglass.Config.get_theme()[:fonts] || %{}
    Map.get(fonts, key, "sans-serif")
  end
```

---

### `lib/mailglass/components/layout.ex` (email layout head)

**Analog:** `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/layouts.ex` (lines 1-78)

**Layout module with head-emitter** (D-12 — MSO XML + color-scheme metas):
```elixir
defmodule Mailglass.Components.Layout do
  use Phoenix.Component

  attr :lang, :string, default: "en"
  attr :title, :string, default: nil
  attr :preheader, :string, default: nil
  slot :inner_block, required: true

  def email_layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang={@lang} xmlns:o="urn:schemas-microsoft-com:office:office"
          xmlns:v="urn:schemas-microsoft-com:vml">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="color-scheme" content="light" />
        <meta name="supported-color-schemes" content="light" />
        <!--[if gte mso 9]><xml>
          <o:OfficeDocumentSettings>
            <o:AllowPNG/>
            <o:PixelsPerInch>96</o:PixelsPerInch>
          </o:OfficeDocumentSettings>
        </xml><![endif]-->
        <%= if @title do %>
          <title><%= @title %></title>
        <% end %>
        <style type="text/css">
          /* Client-specific resets */
          body { margin: 0; padding: 0; }
          table, td { border-collapse: collapse; }
          img { border: 0; display: block; }
        </style>
      </head>
      <body>
        {render_slot(@inner_block)}
      </body>
    </html>
    """
  end
end
```

---

### `lib/mailglass/template_engine.ex` (behaviour)

**Analog:** Accrue `Accrue.Auth` behaviour pattern (the library defines the callback contract; adopters implement it).

**Behaviour module pattern**:
```elixir
defmodule Mailglass.TemplateEngine do
  @moduledoc """
  Behaviour for mailglass template engines.

  The default implementation is `Mailglass.TemplateEngine.HEEx`.
  MJML is available as an optional implementation when :mjml is loaded.

  ## Callbacks

  - `compile/2` — compile a template source to an intermediate form
  - `render/3` — render the compiled form with assigns to an iodata HTML string
  """

  @doc "Compile a template source string. Returns an opaque compiled form."
  @callback compile(source :: String.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, Mailglass.TemplateError.t()}

  @doc "Render a compiled template with assigns. Returns HTML iodata."
  @callback render(compiled :: term(), assigns :: map(), opts :: keyword()) ::
              {:ok, iodata()} | {:error, Mailglass.TemplateError.t()}
end
```

---

### `lib/mailglass/template_engine/heex.ex` (HEEx impl)

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/emails/html_bridge.ex` (lines 38-44 — `Phoenix.HTML.Safe.to_iodata` rendering pattern)

**HEEx render via Phoenix.Component**:
```elixir
defmodule Mailglass.TemplateEngine.HEEx do
  @moduledoc "Default HEEx template engine implementation."

  @behaviour Mailglass.TemplateEngine

  @impl Mailglass.TemplateEngine
  def compile(_source, _opts) do
    # HEEx templates are compiled at build time by the Phoenix tag engine.
    # This callback exists for API symmetry; runtime callers pass the
    # already-compiled function component directly to render/3.
    {:ok, :heex_native}
  end

  @impl Mailglass.TemplateEngine
  def render(component_fn, assigns, _opts) when is_function(component_fn, 1) do
    try do
      html =
        component_fn
        |> apply([assigns])
        |> Phoenix.HTML.Safe.to_iodata()
      {:ok, html}
    rescue
      e in [ArgumentError, KeyError] ->
        {:error, Mailglass.TemplateError.new(:missing_assign, cause: e, context: %{assigns: Map.keys(assigns)})}
      e ->
        {:error, Mailglass.TemplateError.new(:heex_compile, cause: e)}
    end
  end
end
```

---

### `lib/mailglass/renderer.ex` (pure-function pipeline)

**Analog:** Accrue HtmlBridge + Telemetry span — combine into a pipeline with span instrumentation.

**Pipeline pattern** (D-33: `render_span/2` wraps the whole pipeline):
```elixir
defmodule Mailglass.Renderer do
  @moduledoc """
  Pure-function render pipeline: HEEx → CSS inlining → plaintext extraction.

  All functions are side-effect free. No processes, no DB, no HTTP.

  ## Pipeline

  1. `TemplateEngine.render/3` — HEEx component → HTML iodata
  2. `Premailex.to_inline_css/2` — CSS inlining (preserves conditional comments)
  3. `to_plaintext/1` — Custom Floki walker keyed off `data-mg-plaintext` attrs
  4. Strip `data-mg-*` attributes from final HTML wire

  ## Performance Target

  < 50ms end-to-end per AUTHOR-03.
  """

  use Boundary, deps: [Mailglass.Message, Mailglass.TemplateEngine, Mailglass.Components,
                       Mailglass.Telemetry, Mailglass.Error]

  @doc since: "0.1.0"
  @spec render(Mailglass.Message.t(), keyword()) ::
          {:ok, Mailglass.Message.t()} | {:error, Mailglass.TemplateError.t() | Mailglass.SendError.t()}
  def render(%Mailglass.Message{} = message, opts \\ []) do
    metadata = %{tenant_id: message.tenant_id || "default", mailable: message.mailable}

    Mailglass.Telemetry.render_span(metadata, fn ->
      with {:ok, html_iodata} <- render_html(message, opts),
           html_binary = IO.iodata_to_binary(html_iodata),
           {:ok, inlined} <- inline_css(html_binary),
           plaintext = to_plaintext(html_binary),
           final_html = strip_mg_attributes(inlined) do
        {:ok, %{message | swoosh_email: %{message.swoosh_email |
          html_body: final_html,
          text_body: plaintext
        }}}
      end
    end)
  end

  @doc "Extracts plaintext from the pre-VML HTML using data-mg-plaintext strategy attrs."
  @doc since: "0.1.0"
  @spec to_plaintext(String.t()) :: String.t()
  def to_plaintext(html) when is_binary(html) do
    # Custom Floki walker — see D-22 for strategy map
    # Runs on the pre-VML logical tree (before inline_css adds VML wrappers)
    {:ok, document} = Floki.parse_document(html)
    Floki.traverse_and_update(document, &plaintext_node/1)
    |> Floki.text()
    |> String.trim()
  end
```

---

### `lib/mailglass/compliance.ex` (RFC-required header stubs)

**Analog:** None — no prior-art analog for RFC 8058 compliance headers. Use RESEARCH.md patterns.

**Stub pattern** (COMP-01, COMP-02 — Phase 1 reserves namespace only):
```elixir
defmodule Mailglass.Compliance do
  @moduledoc """
  Injects RFC-required and mailglass-specific headers into outbound messages.

  Phase 1 ships stub implementations that reserve the namespace.
  Full RFC 8058 List-Unsubscribe lands in v0.5.
  """

  @doc "Injects Date, Message-ID, MIME-Version if absent. Stub in Phase 1."
  @doc since: "0.1.0"
  @spec add_rfc_required_headers(Swoosh.Email.t()) :: Swoosh.Email.t()
  def add_rfc_required_headers(%Swoosh.Email{} = email) do
    email
    |> maybe_add_message_id()
    |> maybe_add_date()
    |> add_mailglass_mailable_header()
  end
```

---

### `lib/mailglass/gettext.ex` (Gettext.Backend)

**Analog:** sigra usage of `use Gettext.Backend, otp_app:` + `use Gettext, backend:` import pattern.

**Backend module** (from RESEARCH.md AUTHOR-04):
```elixir
defmodule Mailglass.Gettext do
  @moduledoc """
  Gettext backend for mailglass default strings.

  Adopters use their own Gettext backend inside HEEx slots:

      <.heading>
        <%= dgettext("emails", "Welcome, %{name}", name: @user.name) %>
      </.heading>
  """
  use Gettext.Backend, otp_app: :mailglass
end
```

---

## Shared Patterns

### Optional-dep guard (`@compile {:no_warn_undefined}`)

**Source:** `/Users/jon/projects/sigra/mix.exs` lines 68-93 + `/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex` lines 1-75

**Apply to:** `mix.exs` elixirc_options block (covers all optional deps project-wide). Individual gateway modules use `@compile {:no_warn_undefined, [...]}` for module-level granularity.

```elixir
# mix.exs — project-wide guard (copy from sigra pattern):
defp elixirc_options do
  [
    no_warn_undefined: [
      Oban, Oban.Worker, Oban.Job,
      :otel_tracer, :otel_span,
      Mjml,
      :gen_smtp_client,
      Sigra
    ]
  ]
end
```

### NimbleOptions schema structure

**Source:** `/Users/jon/projects/sigra/lib/sigra/config.ex` lines 48-821

**Apply to:** `Mailglass.Config` only. The pattern: declare `@schema` before `@moduledoc`, embed `NimbleOptions.docs(@schema)` in `@moduledoc`, implement `new!/1`, implement `validate_at_boot!/0`.

Key: `@schema` is defined as a module attribute (computed at compile time), not inside a function. The `@moduledoc` string interpolation with `NimbleOptions.docs(@schema)` auto-generates option documentation.

### Error `defexception` sibling structure

**Source:** `/Users/jon/projects/sigra/lib/sigra/error.ex` lines 26-105 (six sibling exceptions in one file — mailglass uses separate files per D-01)

**Apply to:** All six error modules. Each must:
1. Declare `@behaviour Mailglass.Error`
2. Declare `@derive {Jason.Encoder, only: [:type, :message, :context]}`
3. Declare `@types` module attribute with the closed set
4. Export `__types__/0` (returns `@types`)
5. Implement `@impl Mailglass.Error` for `type/1` and `retryable?/1`
6. Implement `@impl true` for `message/1` (Exception callback)
7. Export `new/2` with guard `when type in @types`

### Telemetry span call pattern

**Source:** `/Users/jon/projects/sigra/lib/sigra/telemetry.ex` lines 216-224 + `/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex` lines 57-67

**Apply to:** `Mailglass.Renderer` (Phase 1), and all future domain modules when they land in their phases. The pattern:

```elixir
# Call site — never raw :telemetry.span/3 at call sites:
Mailglass.Telemetry.render_span(%{tenant_id: id, mailable: mod}, fn ->
  # pure work here
end)
```

### `Phoenix.Component` attr conventions

**Source:** `/Users/jon/projects/sigra/test/example/lib/example_web/components/core_components.ex` lines 89-92

**Apply to:** All 11 components in `Mailglass.Components`. The three-attr block is mandatory on every component (D-16, D-17):

```elixir
attr :class, :any, default: nil
attr :rest, :global, include: ~w(id data-testid aria-label aria-hidden)
# :style intentionally EXCLUDED from :global (D-17)
```

Plus enum attrs with `values:` for compile-time warnings (D-18):

```elixir
attr :variant, :string, values: ~w(primary secondary ghost), default: "primary"
```

### Inline `use Boundary` declaration

**Source:** ARCHITECTURE.md §7 (boundary blocks specified there)

**Apply to:** Every module delivered in Phase 1. Add `use Boundary, deps: [...]` immediately after module imports. Only declare blocks for modules that exist in Phase 1 (per CONTEXT.md "Claude's Discretion" section). Example:

```elixir
defmodule Mailglass.Renderer do
  use Boundary, deps: [Mailglass.Message, Mailglass.TemplateEngine,
                       Mailglass.Components, Mailglass.Telemetry, Mailglass.Error]
```

### `@doc since: "0.1.0"` annotation

**Source:** `/Users/jon/projects/sigra/lib/sigra/telemetry.ex` lines 216, 238, etc.

**Apply to:** Every public function across all Phase 1 modules. Sigra consistently places `@doc since:` immediately before `@spec`. Required by api_stability.md discipline (CONTEXT.md D-07).

---

## No Analog Found

Files with no close match in the codebase. Planner should use RESEARCH.md patterns instead.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/mailglass/compliance.ex` | utility | transform | No RFC 8058 / email compliance header module in any prior-art lib. RESEARCH.md §COMP-01/02 has the spec. |
| `docs/api_stability.md` | documentation | — | Not a code file. Planner writes it as a documentation artifact; no code pattern applies. Content spec is in CONTEXT.md D-07 and RESEARCH.md §1. |
| `priv/gettext/` directory structure | assets | — | Standard Gettext locale tree; generated by `mix gettext.extract`. No custom code. |

---

## Metadata

**Analog search scope:** `/Users/jon/projects/sigra/lib`, `/Users/jon/projects/accrue/accrue/lib`, `/Users/jon/projects/accrue/accrue_admin/lib`

**Key files read:**
- `/Users/jon/projects/sigra/lib/sigra/error.ex` — 214 lines
- `/Users/jon/projects/sigra/lib/sigra/config.ex` — 989 lines
- `/Users/jon/projects/sigra/lib/sigra/telemetry.ex` — 368 lines
- `/Users/jon/projects/sigra/lib/sigra/application.ex` — 150 lines
- `/Users/jon/projects/sigra/mix.exs` — 207 lines
- `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex` — 812 lines
- `/Users/jon/projects/accrue/accrue/lib/accrue/repo.ex` — 193 lines
- `/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex` — 94 lines (first section)
- `/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex` — 75 lines
- `/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex` — 183 lines
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/layouts.ex` — 78 lines
- `/Users/jon/projects/accrue/accrue/lib/accrue/emails/html_bridge.ex` — 45 lines
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/error.ex` — 277 lines
- `/Users/jon/projects/sigra/test/example/lib/example_web/components/core_components.ex` — 120 lines (first section)

**Pattern extraction date:** 2026-04-22

---

## PATTERN MAPPING COMPLETE
