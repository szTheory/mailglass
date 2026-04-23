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
      default: Mailglass.SuppressionStore.Ecto,
      doc:
        "Module implementing `Mailglass.SuppressionStore`. " <>
          "Default: `Mailglass.SuppressionStore.Ecto`."
    ],
    async_adapter: [
      type: {:in, [:oban, :task_supervisor]},
      default: :oban,
      doc:
        "Async delivery adapter for `deliver_later/2`. `:oban` (default, durable) or " <>
          "`:task_supervisor` (non-durable fallback). Use `:task_supervisor` to silence " <>
          "the boot warning when Oban is deliberately not in deps."
    ],
    rate_limit: [
      type: :keyword_list,
      default: [],
      doc: "Rate-limiter configuration (SEND-02).",
      keys: [
        default: [
          type: :keyword_list,
          default: [capacity: 100, per_minute: 100],
          doc: "Default per-(tenant, domain) bucket. Capacity + per-minute refill."
        ],
        overrides: [
          type: {:list, :any},
          default: [],
          doc:
            "Per-(tenant_id, domain) overrides as list of {{tenant_id, domain}, opts} tuples."
        ]
      ]
    ],
    tracking: [
      type: :keyword_list,
      default: [],
      doc:
        "Open/click tracking configuration (TRACK-03). When any mailable enables opens or " <>
          "clicks, `:host` is REQUIRED or boot raises `%ConfigError{type: :tracking_host_missing}`.",
      keys: [
        host: [
          type: {:or, [:string, nil]},
          default: nil,
          doc:
            "Tracking subdomain (e.g. `track.example.com`). Must be separate from the " <>
              "adopter's main app host."
        ],
        scheme: [
          type: {:in, ["http", "https"]},
          default: "https",
          doc: "URL scheme. `http` only for dev."
        ],
        salts: [
          type: {:list, :string},
          default: [],
          doc: "Phoenix.Token salts. Head signs; all verify (rotation support)."
        ],
        max_age: [
          type: :pos_integer,
          default: 2 * 365 * 86_400,
          doc: "Token max age in seconds. Default: 2 years."
        ]
      ]
    ],
    clock: [
      type: {:or, [:atom, nil]},
      default: nil,
      doc:
        "Module implementing `utc_now/0`. Default: `Mailglass.Clock.System`. Tests use " <>
          "`Mailglass.Clock.Frozen`-backed per-process freezing without overriding this key."
    ],
    # Phase 4 D-04 / Claude's Discretion per plan Task 2. Per-provider
    # sub-trees are additive; `enabled: true` is the default so the router
    # macro wires the route without explicit opt-in. `basic_auth` is
    # required for real-world Postmark; the webhook plug raises
    # `%ConfigError{type: :webhook_verification_key_missing}` at request
    # time if it is not set. `ip_allowlist` is opt-in — Postmark's own docs
    # warn origin IPs can change (D-04).
    postmark: [
      type: :keyword_list,
      default: [],
      doc: "Postmark webhook configuration (HOOK-03).",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Enable the Postmark webhook route. Default: `true`."
        ],
        basic_auth: [
          type: {:or, [{:tuple, [:string, :string]}, nil]},
          default: nil,
          doc:
            "Basic Auth `{user, password}` tuple. Required for signature " <>
              "verification; omit only if the provider is disabled."
        ],
        ip_allowlist: [
          type: {:list, :string},
          default: [],
          doc:
            "Opt-in list of CIDR strings (e.g. `[\"50.31.156.0/24\"]`). " <>
              "Off by default per D-04 — Postmark's origin IPs can change."
        ]
      ]
    ],
    # Phase 4 D-03 / HOOK-04. SendGrid Event Webhook verification is
    # ECDSA P-256 over `timestamp <> raw_body`. `:public_key` is a base64
    # SPKI DER (NOT PEM — the SendGrid dashboard ships raw DER). Missing
    # at request time raises `%ConfigError{type: :webhook_verification_key_missing}`.
    # `:timestamp_tolerance_seconds` default 300 matches the Stripe /
    # Svix / Standard Webhooks consensus.
    sendgrid: [
      type: :keyword_list,
      default: [],
      doc: "SendGrid webhook configuration (HOOK-04).",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Enable the SendGrid webhook route. Default: `true`."
        ],
        public_key: [
          type: {:or, [:string, nil]},
          default: nil,
          doc:
            "Base64-encoded SubjectPublicKeyInfo DER (NOT PEM — SendGrid's " <>
              "dashboard ships raw DER without `-----BEGIN PUBLIC KEY-----` " <>
              "framing). Required for signature verification; omit only if " <>
              "the provider is disabled."
        ],
        timestamp_tolerance_seconds: [
          type: :pos_integer,
          default: 300,
          doc:
            "Replay tolerance window in seconds. Default: `300` (Stripe / " <>
              "Svix / Standard Webhooks consensus)."
        ]
      ]
    ],
    # Phase 4 CONTEXT D-11 / revision B2. `:sync` is the v0.1 locked
    # ingest mode — the webhook Plug runs `Mailglass.Webhook.Ingest`
    # inline and responds 200 only after the Multi commits. `:async` is
    # reserved (`@doc false`) pending v0.5's Dead-Letter Queue admin
    # surface. Plan 06's `ingest_multi/3` runtime-guards `:async` with
    # a raise so adopters who set it receive a clear error instead of
    # silently running the sync path.
    webhook_ingest_mode: [
      type: {:in, [:sync, :async]},
      default: :sync,
      doc: false
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

  # Phase 4 CONTEXT D-11 / revision B2. Exposed as `@doc false` because
  # `:async` is reserved at v0.1 — the accessor lets Plan 06's
  # `Mailglass.Webhook.Ingest.ingest_multi/3` branch on the value and
  # raise an explicit error if an adopter has set `:async` before the
  # v0.5 DLQ admin ships.
  @doc since: "0.1.0"
  @doc false
  @spec webhook_ingest_mode() :: :sync | :async
  def webhook_ingest_mode do
    Application.get_env(:mailglass, :webhook_ingest_mode, :sync)
  end
end
