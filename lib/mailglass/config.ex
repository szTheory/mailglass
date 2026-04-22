defmodule Mailglass.Config do
  # Schema is declared BEFORE @moduledoc so NimbleOptions.docs(@schema) can
  # interpolate into the module documentation.
  @schema [
    repo: [
      type: {:or, [:atom, nil]},
      required: false,
      default: nil,
      doc: "The adopter's Ecto.Repo module. Required from Phase 2+ onwards."
    ],
    adapter: [
      type: :any,
      default: {Mailglass.Adapters.Fake, []},
      doc: "Adapter module or `{module, opts}` tuple. Default: the Fake adapter."
    ],
    theme: [
      type: :keyword_list,
      default: [],
      doc: "Brand theme tokens. See `Mailglass.Components.Theme`.",
      keys: [
        colors: [
          type: :map,
          default: %{
            ink: "#0D1B2A",
            glass: "#277B96",
            ice: "#A6EAF2",
            mist: "#EAF6FB",
            paper: "#F8FBFD",
            slate: "#5C6B7A"
          },
          doc: "Brand color map. Keys: `:ink`, `:glass`, `:ice`, `:mist`, `:paper`, `:slate`."
        ],
        fonts: [
          type: :map,
          default: %{
            body: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            display: "'Inter Tight', 'Inter', sans-serif",
            mono: "'IBM Plex Mono', ui-monospace, monospace"
          },
          doc: "Font-stack map. Keys: `:body`, `:display`, `:mono`."
        ]
      ]
    ],
    telemetry: [
      type: :keyword_list,
      default: [],
      doc: "Telemetry options.",
      keys: [
        default_logger: [
          type: :boolean,
          default: false,
          doc: "Attach the default logger handler at boot. Default: `false`."
        ]
      ]
    ],
    renderer: [
      type: :keyword_list,
      default: [],
      doc: "Renderer options.",
      keys: [
        css_inliner: [
          type: {:in, [:premailex, :none]},
          default: :premailex,
          doc: "CSS inlining backend. Default: `:premailex`."
        ],
        plaintext: [
          type: :boolean,
          default: true,
          doc: "Auto-generate a plaintext body alongside the HTML body. Default: `true`."
        ]
      ]
    ],
    tenancy: [
      type: {:or, [:atom, nil]},
      default: nil,
      doc: "Module implementing `Mailglass.Tenancy`. Default: `nil` (single-tenant mode)."
    ],
    suppression_store: [
      type: {:or, [:atom, nil]},
      default: nil,
      doc:
        "Module implementing `Mailglass.SuppressionStore`. Default: `nil` " <>
          "(no suppression checks in Phase 1)."
    ]
  ]

  @moduledoc """
  Runtime configuration for mailglass, validated at boot via NimbleOptions.

  **Only this module may call `Application.compile_env*`.** Every other module
  reads configuration through `Application.get_env/2` (enforced by the
  `LINT-08` Credo check in Phase 6).

  The brand theme (D-19) is cached in `:persistent_term` after validation so
  the render hot path reads it in O(1) without re-parsing the Application env
  on every message.

  ## Options

  #{NimbleOptions.docs(@schema)}

  ## Boot sequence

      # lib/mailglass/application.ex
      def start(_type, _args) do
        Mailglass.Config.validate_at_boot!()
        # ...
      end

  Raises `NimbleOptions.ValidationError` on invalid configuration. Raising at
  boot is intentional — a misconfigured mailer should never limp into
  production serving half-rendered mail.
  """

  @doc """
  Validates and returns a keyword list of options.

  Fills in defaults, raises `NimbleOptions.ValidationError` on unknown keys
  or invalid values. Used primarily by `validate_at_boot!/0`; callers rarely
  invoke this directly.

  ## Examples

      iex> config = Mailglass.Config.new!([])
      iex> Keyword.fetch!(config, :adapter)
      {Mailglass.Adapters.Fake, []}
  """
  @doc since: "0.1.0"
  @spec new!(keyword()) :: keyword()
  def new!(opts \\ []) when is_list(opts) do
    NimbleOptions.validate!(opts, @schema)
  end

  @doc """
  Reads the `:mailglass` Application env, validates it against the schema,
  and caches the brand theme in `:persistent_term`.

  Called from `Mailglass.Application.start/2`. Raises
  `NimbleOptions.ValidationError` if the Application env is invalid.

  When `[telemetry: [default_logger: true]]` is configured, the default
  logger handler is attached here.
  """
  @doc since: "0.1.0"
  @spec validate_at_boot!() :: :ok
  def validate_at_boot! do
    known_keys = Keyword.keys(@schema)

    opts =
      :mailglass
      |> Application.get_all_env()
      |> Keyword.take(known_keys)

    validated = NimbleOptions.validate!(opts, @schema)

    validate_repo_adapter!(Keyword.get(validated, :repo))

    theme = Keyword.get(validated, :theme, [])
    :persistent_term.put({__MODULE__, :theme}, theme)

    telemetry_opts = Keyword.get(validated, :telemetry, [])

    if Keyword.get(telemetry_opts, :default_logger, false) do
      _ = Mailglass.Telemetry.attach_default_logger()
    end

    :ok
  end

  # Mailglass is Postgres-only at v0.1 per PROJECT.md (MySQL/SQLite out of
  # scope). `Mailglass.Migration.migrator/0` already guards the migration
  # path, but the runtime path (Events.append, Projector.update_projections,
  # SuppressionStore.Ecto.*) does not — an adopter wiring
  # `config :mailglass, repo: MyApp.SqliteRepo` would otherwise get
  # confusing errors from Ecto/Postgrex layers on the first write
  # (WR-04). Fail fast at boot with a typed ConfigError instead.
  #
  # `:repo` is optional at v0.1 (phases 0/1 don't need it) — skip the
  # check when unset; the Repo facade will raise `:missing` on first
  # use if a Phase 2+ code path needs it.
  defp validate_repo_adapter!(nil), do: :ok

  defp validate_repo_adapter!(repo) when is_atom(repo) do
    if Code.ensure_loaded?(repo) and function_exported?(repo, :__adapter__, 0) do
      case repo.__adapter__() do
        Ecto.Adapters.Postgres ->
          :ok

        other ->
          raise Mailglass.ConfigError.new(:invalid,
                  context: %{
                    key: :repo,
                    adapter: other,
                    reason: "Postgres only at v0.1"
                  }
                )
      end
    else
      # Repo module not loaded or not an Ecto.Repo — defer to the
      # NimbleOptions schema + runtime resolution to produce the error.
      :ok
    end
  end

  @doc """
  Returns the cached brand theme keyword list.

  Requires `validate_at_boot!/0` to have been called first. Returns an empty
  list if the cache is unset (the caller is responsible for ensuring the boot
  sequence has completed).
  """
  @doc since: "0.1.0"
  @spec get_theme() :: keyword()
  def get_theme do
    :persistent_term.get({__MODULE__, :theme}, [])
  end
end
