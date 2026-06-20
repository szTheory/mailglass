defmodule Mailglass.Config do
  # Schema is declared BEFORE @moduledoc so NimbleOptions.docs(@schema) can
  # interpolate into the module documentation.
  @schema [
    feedback_id: [
      type: {:or, [:string, nil]},
      default: nil,
      doc:
        "Optional Feedback-ID prefix (RFC 8058/Deliverability). When set, auto-populates as `{sender_id}:{mailable}:{tenant_id}:{stream}`."
    ],
    repo: [
      type: {:or, [:atom, nil]},
      required: false,
      default: nil,
      doc: "The adopter's Ecto.Repo module. Required from + onwards."
    ],
    adapter: [
      type: :any,
      default: {Mailglass.Adapters.Fake, []},
      doc: "Adapter module or `{module, opts}` tuple. Default: the Fake adapter."
    ],
    adapters: [
      type: {:list, :any},
      default: [],
      doc:
        "Optional named adapter registry for runtime route refs. Each entry is " <>
          "`{ref, module}` or `{ref, {module, opts}}`, where `ref` is an atom or string."
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
      doc: "Rate-limiter configuration.",
      keys: [
        tenant_recipient: [
          type: :keyword_list,
          default: [],
          doc: "Per-{tenant, domain} rate limits.",
          keys: [
            default: [
              type: :keyword_list,
              default: [capacity: 100, per_minute: 100],
              doc: "Default per-{tenant, domain} bucket."
            ],
            overrides: [
              type: {:list, :any},
              default: [],
              doc: "Per-{tenant, domain} overrides as {{tenant_id, domain}, opts}."
            ]
          ]
        ],
        global_recipient: [
          type: :keyword_list,
          default: [],
          doc: "Global per-recipient domain rate limits.",
          keys: [
            default: [
              type: :keyword_list,
              default: [capacity: 1000, per_minute: 1000],
              doc: "Default global per-domain bucket."
            ],
            overrides: [
              type: {:list, :any},
              default: [],
              doc: "Global per-domain overrides as {domain, opts}."
            ]
          ]
        ],
        sender_domain: [
          type: :keyword_list,
          default: [],
          doc: "Global per-sender domain rate limits.",
          keys: [
            default: [
              type: :keyword_list,
              default: [capacity: 500, per_minute: 500],
              doc: "Default global per-sender domain bucket."
            ],
            overrides: [
              type: {:list, :any},
              default: [],
              doc: "Global per-sender domain overrides as {domain, opts}."
            ]
          ]
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
        endpoint: [
          type: {:or, [:atom, :string, nil]},
          default: nil,
          doc:
            "Phoenix.Token endpoint/secret override for open/click tracking. When nil, " <>
              "`Mailglass.Tracking.endpoint/0` falls back to `:adapter_endpoint`."
        ],
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
    compliance: [
      type: :keyword_list,
      default: [],
      doc:
        "RFC 8058 unsubscribe configuration.  reads this subtree through " <>
          "`Mailglass.Config` accessors only so router/controller/token code avoids " <>
          "new direct compile-env lookups.",
      keys: [
        endpoint: [
          type: {:or, [:atom, :string, nil]},
          default: nil,
          doc:
            "Phoenix.Token endpoint/secret override for unsubscribe signing. When nil, " <>
              "`Mailglass.Config.compliance_endpoint/0` falls back to the tracking endpoint chain."
        ],
        host: [
          type: {:or, [:string, nil]},
          default: nil,
          doc: "Canonical host used for unsubscribe URLs (for example `unsubscribe.example.com`)."
        ],
        scheme: [
          type: {:in, ["http", "https"]},
          default: "https",
          doc: "Unsubscribe URL scheme. `http` is intended for local development only."
        ],
        mount_path: [
          type: :string,
          default: "/mailglass/unsubscribe",
          doc: "Absolute path prefix used when generating unsubscribe URLs."
        ],
        previous_secrets: [
          type: {:list, :string},
          default: [],
          doc:
            "Raw prior `secret_key_base` values accepted during unsubscribe token verification after endpoint-secret rotation."
        ],
        redirect: [
          type: {:or, [:string, nil]},
          default: nil,
          doc:
            "Optional GET unsubscribe redirect escape hatch (for example `/settings/unsubscribe`)."
        ],
        max_age: [
          type: :pos_integer,
          default: 2 * 365 * 86_400,
          doc: "Unsubscribe token max age in seconds. Default: 2 years."
        ],
        lifecycle: [
          type: :atom,
          default: Mailglass.Lifecycle.Noop,
          doc:
            "Module implementing `Mailglass.Lifecycle` for transaction-local unsubscribe side effects."
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
    #   / Claude's Discretion per plan Task 2. Per-provider
    # sub-trees are additive; `enabled: true` is the default so the router
    # macro wires the route without explicit opt-in. `basic_auth` is
    # required for real-world Postmark; the webhook plug raises
    # `%ConfigError{type: :webhook_verification_key_missing}` at request
    # time if it is not set. `ip_allowlist` is opt-in — Postmark's own docs
    # warn origin IPs can change.
    postmark: [
      type: :keyword_list,
      default: [],
      doc: "Postmark webhook configuration.",
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
              "Off by default per  — Postmark's origin IPs can change."
        ]
      ]
    ],
    #   / HOOK-04. SendGrid Event Webhook verification is
    # ECDSA P-256 over `timestamp <> raw_body`. `:public_key` is a base64
    # SPKI DER (NOT PEM — the SendGrid dashboard ships raw DER). Missing
    # at request time raises `%ConfigError{type: :webhook_verification_key_missing}`.
    # `:timestamp_tolerance_seconds` default 300 matches the Stripe /
    # Svix / Standard Webhooks consensus.
    sendgrid: [
      type: :keyword_list,
      default: [],
      doc: "SendGrid webhook configuration.",
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
    mailgun: [
      type: :keyword_list,
      default: [],
      doc: "Mailgun webhook configuration.",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Enable the Mailgun webhook route when explicitly mounted."
        ],
        signing_key: [
          type: {:or, [:string, nil]},
          default: nil,
          doc:
            "Mailgun webhook signing key used for HMAC verification. Required " <>
              "for signature verification; omit only if the provider is disabled."
        ],
        timestamp_tolerance_seconds: [
          type: :pos_integer,
          default: 28_800,
          doc:
            "Maximum accepted age for the Mailgun signature timestamp in " <>
              "seconds. Default: `28_800`."
        ],
        future_skew_seconds: [
          type: :pos_integer,
          default: 300,
          doc:
            "Maximum accepted future skew for the Mailgun signature " <>
              "timestamp in seconds. Default: `300`."
        ],
        replay_cache_ttl_seconds: [
          type: :pos_integer,
          default: 28_800,
          doc:
            "Replay cache retention window for Mailgun tokens in seconds. " <>
              "Default: `28_800`."
        ]
      ]
    ],
    ses: [
      type: :keyword_list,
      default: [],
      doc: "SES webhook configuration.",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Enable the SES webhook route when explicitly mounted."
        ],
        cert_cache_ttl_seconds: [
          type: :pos_integer,
          default: 86_400,
          doc: "TTL in seconds for cached SNS signing certificates. Default: `86_400`."
        ]
      ]
    ],
    resend: [
      type: :keyword_list,
      default: [],
      doc: "Resend webhook configuration.",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Enable the Resend webhook route when explicitly mounted."
        ],
        secret: [
          type: {:or, [:string, nil]},
          default: nil,
          doc:
            "Svix webhook secret used for Resend signature verification. Required for verification; omit only if the provider is disabled."
        ],
        timestamp_tolerance_seconds: [
          type: :pos_integer,
          default: 300,
          doc: "Maximum accepted age for the Svix timestamp in seconds. Default: `300`."
        ]
      ]
    ],
    #  CONTEXT  / revision B2. `:sync` is the v0.1 locked
    # ingest mode — the webhook Plug runs `Mailglass.Webhook.Ingest`
    # inline and responds 200 only after the Multi commits. `:async` is
    # reserved (`@doc false`) pending v0.5's Dead-Letter Queue admin
    # surface. 's `ingest_multi/3` runtime-guards `:async` with
    # a raise so adopters who set it receive a clear error instead of
    # silently running the sync path.
    webhook_ingest_mode: [
      type: {:in, [:sync, :async]},
      default: :sync,
      doc: false
    ],
    #  CONTEXT . Three retention knobs for
    # `Mailglass.Webhook.Pruner`:
    #   * `:succeeded_days` (default 14) — retain :succeeded rows N days
    #   * `:dead_days` (default 90) — retain :dead (terminal-after-retries)
    #     rows N days
    #   * `:failed_days` (default :infinity) — :failed is investigatable;
    #     never pruned by default
    # Any knob set to `:infinity` disables that prune class — the Pruner
    # returns `{:ok, 0}` without issuing the DELETE.
    webhook_retention: [
      type: :keyword_list,
      default: [],
      doc: "Retention policy for `mailglass_webhook_events` rows.",
      keys: [
        succeeded_days: [
          type: {:or, [:pos_integer, {:in, [:infinity]}]},
          default: 14,
          doc:
            "Days to retain `:succeeded` webhook_events before the Pruner deletes them. " <>
              "Set to `:infinity` to disable. Default: 14."
        ],
        dead_days: [
          type: {:or, [:pos_integer, {:in, [:infinity]}]},
          default: 90,
          doc:
            "Days to retain `:dead` (terminal-after-retries) webhook_events before the " <>
              "Pruner deletes them. Set to `:infinity` to disable. Default: 90."
        ],
        failed_days: [
          type: {:or, [:pos_integer, {:in, [:infinity]}]},
          default: :infinity,
          doc:
            "Days to retain `:failed` (investigatable) webhook_events. Default: `:infinity` " <>
              "(never prune)."
        ]
      ]
    ]
  ]

  @moduledoc """
  Runtime configuration for mailglass, validated at boot via NimbleOptions.

  **Only this module may call `Application.compile_env*`.** Every other module
  reads configuration through `Application.get_env/2` (enforced by the
  Credo check).

  The brand theme is cached in `:persistent_term` after validation so
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
  Raise on invalid configuration so misconfigured mailers fail fast at boot.
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
    opts
    |> normalize_optional_keyword_subtrees()
    |> NimbleOptions.validate!(@schema)
    |> validate_adapter_config!()
    |> validate_mailgun_replay_window!()
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
      |> normalize_optional_keyword_subtrees()

    validated =
      opts
      |> NimbleOptions.validate!(@schema)
      |> validate_adapter_config!()
      |> validate_mailgun_replay_window!()

    validate_repo_adapter!(Keyword.get(validated, :repo))

    theme = Keyword.get(validated, :theme, [])
    :persistent_term.put({__MODULE__, :theme}, theme)

    telemetry_opts = Keyword.get(validated, :telemetry, [])

    if Keyword.get(telemetry_opts, :default_logger, false) do
      _ = Mailglass.Telemetry.attach_default_logger()
    end

    :ok
  end

  defp normalize_optional_keyword_subtrees(opts) do
    Enum.reduce(
      [:theme, :telemetry, :renderer, :rate_limit, :tracking, :compliance, :ses, :resend],
      opts,
      fn key, acc ->
        case Keyword.get(acc, key, :__missing__) do
          nil -> Keyword.put(acc, key, [])
          _ -> acc
        end
      end
    )
    |> normalize_rate_limit_config()
  end

  defp normalize_rate_limit_config(opts) do
    case Keyword.get(opts, :rate_limit) do
      rl when is_list(rl) ->
        # Backward compatibility: If :default or :overrides are present at the
        # top level of :rate_limit, wrap them into :tenant_recipient.
        if Keyword.has_key?(rl, :default) or Keyword.has_key?(rl, :overrides) do
          tenant_recipient = Keyword.take(rl, [:default, :overrides])
          rest = Keyword.drop(rl, [:default, :overrides])
          Keyword.put(opts, :rate_limit, Keyword.put(rest, :tenant_recipient, tenant_recipient))
        else
          opts
        end

      _ ->
        opts
    end
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
  # use if a + code path needs it.
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

  @doc """
  Returns the validated global default adapter as `{module, opts}`.
  """
  @doc since: "0.4.0"
  @spec default_adapter() :: {module(), keyword()}
  def default_adapter do
    validated_config()
    |> Keyword.fetch!(:adapter)
    |> normalize_adapter_entry!(:adapter)
  end

  @doc """
  Returns the validated named adapter registry keyed by stable route ref.
  """
  @doc since: "0.4.0"
  @spec adapters() :: %{optional(atom() | String.t()) => {module(), keyword()}}
  def adapters do
    validated_config()
    |> Keyword.get(:adapters, [])
    |> Enum.into(%{}, fn {ref, adapter} -> {ref, normalize_adapter_entry!(adapter, :adapters)} end)
  end

  @doc """
  Resolves a named adapter ref into the normalized `{module, opts}` shape.
  """
  @doc since: "0.4.0"
  @spec resolve_adapter_ref(atom() | String.t()) :: {module(), keyword()}
  def resolve_adapter_ref(ref) when is_atom(ref) or is_binary(ref) do
    normalized_ref = normalize_adapter_ref_lookup(ref)

    case Enum.find(adapters(), fn {registered_ref, _adapter} ->
           normalize_adapter_ref_lookup(registered_ref) == normalized_ref
         end) do
      {_registered_ref, adapter} ->
        adapter

      nil ->
        raise Mailglass.ConfigError.new(:invalid,
                context: %{key: :adapter_ref, adapter_ref: ref, reason: "unknown adapter ref"}
              )
    end
  end

  @doc """
  Returns the validated compliance subtree with defaults applied.
  """
  @doc since: "0.1.0"
  @spec compliance() :: keyword()
  def compliance do
    validated_config()
    |> Keyword.fetch!(:compliance)
  end

  @doc """
  Resolves the current unsubscribe signing endpoint.

  Falls back to `Mailglass.Tracking.endpoint/0` so unsubscribe tokens reuse the
  same endpoint-secret chain unless adopters opt into a compliance-specific
  override.
  """
  @doc since: "0.1.0"
  @spec compliance_endpoint() :: module() | binary()
  def compliance_endpoint do
    compliance()[:endpoint] || Mailglass.Tracking.endpoint()
  end

  @doc since: "0.1.0"
  @spec compliance_host() :: String.t() | nil
  def compliance_host, do: compliance()[:host]

  @doc since: "0.1.0"
  @spec compliance_scheme() :: String.t()
  def compliance_scheme, do: compliance()[:scheme]

  @doc since: "0.1.0"
  @spec compliance_mount_path() :: String.t()
  def compliance_mount_path, do: compliance()[:mount_path]

  @doc since: "0.1.0"
  @spec compliance_previous_secrets() :: [String.t()]
  def compliance_previous_secrets, do: compliance()[:previous_secrets]

  @doc since: "0.1.0"
  @spec compliance_redirect() :: String.t() | nil
  def compliance_redirect, do: compliance()[:redirect]

  @doc since: "0.1.0"
  @spec compliance_max_age() :: pos_integer()
  def compliance_max_age, do: compliance()[:max_age]

  @doc since: "0.1.0"
  @spec compliance_lifecycle() :: module()
  def compliance_lifecycle, do: compliance()[:lifecycle]

  #  CONTEXT  / revision B2. Exposed as `@doc false` because
  # `:async` is reserved at v0.1 — the accessor lets 's
  # `Mailglass.Webhook.Ingest.ingest_multi/3` branch on the value and
  # raise an explicit error if an adopter has set `:async` before the
  # v0.5 DLQ admin ships.
  @doc since: "0.1.0"
  @doc false
  @spec webhook_ingest_mode() :: :sync | :async
  def webhook_ingest_mode do
    Application.get_env(:mailglass, :webhook_ingest_mode, :sync)
  end

  defp validated_config do
    known_keys = Keyword.keys(@schema)

    :mailglass
    |> Application.get_all_env()
    |> Keyword.take(known_keys)
    |> normalize_optional_keyword_subtrees()
    |> NimbleOptions.validate!(@schema)
    |> validate_adapter_config!()
    |> validate_mailgun_replay_window!()
  end

  defp validate_adapter_config!(validated) do
    _ = normalize_adapter_entry!(Keyword.fetch!(validated, :adapter), :adapter)

    adapters =
      validated
      |> Keyword.get(:adapters, [])
      |> Enum.map(&normalize_registry_entry!/1)

    Keyword.put(validated, :adapters, adapters)
  end

  defp normalize_registry_entry!({ref, adapter}) do
    {normalize_adapter_ref!(ref), normalize_adapter_entry!(adapter, :adapters)}
  end

  defp normalize_registry_entry!(other) do
    raise NimbleOptions.ValidationError,
      key: :adapters,
      message:
        "expected entries like {ref, module} or {ref, {module, opts}}, got: #{inspect(other)}"
  end

  defp normalize_adapter_ref_lookup(ref) when is_atom(ref), do: Atom.to_string(ref)
  defp normalize_adapter_ref_lookup(ref) when is_binary(ref), do: ref

  defp normalize_adapter_ref!(ref) when is_atom(ref) or is_binary(ref), do: ref

  defp normalize_adapter_ref!(ref) do
    raise NimbleOptions.ValidationError,
      key: :adapters,
      message: "adapter refs must be atoms or strings, got: #{inspect(ref)}"
  end

  defp normalize_adapter_entry!(adapter, key) do
    case adapter do
      mod when is_atom(mod) ->
        {mod, []}

      {mod, opts} when is_atom(mod) and is_list(opts) ->
        if Keyword.keyword?(opts) do
          {mod, opts}
        else
          invalid_adapter_entry!(key, adapter)
        end

      _ ->
        invalid_adapter_entry!(key, adapter)
    end
  end

  defp invalid_adapter_entry!(key, adapter) do
    raise NimbleOptions.ValidationError,
      key: key,
      message:
        "adapter entries must be a module or {module, keyword_opts}, got: #{inspect(adapter)}"
  end

  defp validate_mailgun_replay_window!(validated) do
    mailgun = Keyword.get(validated, :mailgun, [])
    ttl = Keyword.get(mailgun, :replay_cache_ttl_seconds, 28_800)
    tolerance = Keyword.get(mailgun, :timestamp_tolerance_seconds, 28_800)

    if ttl < tolerance do
      raise NimbleOptions.ValidationError,
        key: :mailgun,
        message:
          ":replay_cache_ttl_seconds must be greater than or equal to " <>
            ":timestamp_tolerance_seconds"
    end

    validated
  end
end
