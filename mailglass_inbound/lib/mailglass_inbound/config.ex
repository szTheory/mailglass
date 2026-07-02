defmodule MailglassInbound.Config do
  # Schema is declared BEFORE @moduledoc so NimbleOptions.docs(@schema) can
  # interpolate into the module documentation (mirrors Mailglass.Config style).
  @retention_class {:or, [:non_neg_integer, {:in, [:infinity]}]}

  @bucket_schema [
    type: :keyword_list,
    keys: [
      capacity: [type: :non_neg_integer, required: true],
      per_minute: [type: :non_neg_integer, required: true]
    ]
  ]

  @schema [
    schema: [
      type: :string,
      default: "mailglass",
      doc:
        "Names the Postgres SCHEMA holding all mailglass inbound tables. " <>
          "`\"public\"` is the explicit pre-2.0 opt-out. Must be a valid " <>
          "unquoted Postgres identifier. Read from the `:mailglass_inbound` " <>
          "app env only (never core `:mailglass`)."
    ],
    retention: [
      type: :keyword_list,
      default: [],
      doc: """
      Retention windows (in days) per inbound table class. `:infinity` on a class
      disables that window. Defaults: records 90, evidence 90, execution_runs 90,
      replay_runs 30.

      The windows must respect the FK lineage so the child-first prune never trips
      an `on_delete: :nothing` foreign key (CR-02): `replay_runs` rows reference
      both `records` and `evidence`, and `evidence` references `records`. So a
      parent must outlive every child that references it —
      `evidence_days >= max(execution_runs_days, replay_runs_days)` and
      `records_days >= evidence_days`. `retention/0` CLAMPS any configured override
      up to satisfy this invariant rather than letting prune crash on an FK
      violation.
      """,
      keys: [
        records_days: [type: @retention_class, default: 90],
        evidence_days: [type: @retention_class, default: 90],
        execution_runs_days: [type: @retention_class, default: 90],
        replay_runs_days: [type: @retention_class, default: 30]
      ]
    ],
    rate_limit: [
      type: :keyword_list,
      default: [],
      doc: """
      Post-verify ingress rate-limit buckets. Three buckets evaluated fail-fast
      in order tenant -> recipient -> sender_domain. Each bucket has a `capacity`
      (token-bucket BURST size) and a `per_minute` SUSTAINED refill rate. Following
      the core `Mailglass.RateLimiter` convention, the defaults set
      `per_minute == capacity`, so "N/min" is literally the sustained throughput:
      the bucket refills its full capacity each minute. Defaults: tenant 1000/min,
      recipient 500/min, sender_domain 200/min.
      """,
      keys: [
        tenant: Keyword.put(@bucket_schema, :default, capacity: 1000, per_minute: 1000),
        sender_domain: Keyword.put(@bucket_schema, :default, capacity: 200, per_minute: 200),
        recipient: Keyword.put(@bucket_schema, :default, capacity: 500, per_minute: 500)
      ]
    ]
  ]

  # persistent_term key for the boot-validated Postgres schema name.
  @schema_key {__MODULE__, :schema}

  @moduledoc """
  Validated configuration accessor for the `:mailglass_inbound` app env.

  Mirrors the *style* of `Mailglass.Config` (NimbleOptions `@schema` declared
  before `@moduledoc`, `validate_at_boot!/0`) but reads the **`:mailglass_inbound`**
  app env, never core `Mailglass.Config`. Adding inbound keys to core would invert
  the package dependency — core reads `:mailglass` only and cannot validate config
  for a package it does not depend on (boundary law).

  ## Configuration

      config :mailglass_inbound,
        retention: [
          records_days: 90,
          evidence_days: 90,
          execution_runs_days: 90,
          replay_runs_days: 30
        ],
        rate_limit: [
          tenant:        [capacity: 1000, per_minute: 1000],
          sender_domain: [capacity: 200,  per_minute: 200],
          recipient:     [capacity: 500,  per_minute: 500]
        ]

  `:infinity` on any retention class disables that window. Only the knobs the
  runtime actually reads are shipped — no speculative per-tenant override maps
  (honest-surface).

  ## Schema

  #{NimbleOptions.docs(@schema)}
  """

  @doc """
  Validate the `:mailglass_inbound` retention + rate_limit config at boot.

  Returns `:ok`. Raises `NimbleOptions.ValidationError` if the configured shape
  is invalid (e.g. a negative retention value, a non-`:infinity` atom on a
  retention class, or a negative bucket capacity). Raises
  `Mailglass.ConfigError` with `type: :invalid` if `:schema` is not a valid
  unquoted Postgres identifier.

  Inbound's own `MailglassInbound.Application.start/2` now calls this at boot to
  warm the `:schema` `:persistent_term` cache and fail fast on a bad identifier.
  Only `:schema` is cached — the on-demand `retention/0` / `rate_limit/0` reads
  stay on the uncached `validated/0` path and are unaffected.
  """
  @doc since: "1.2.0"
  @spec validate_at_boot!() :: :ok
  def validate_at_boot! do
    validated = validated()

    # Cache the validated schema from the boot pipeline so boot and cache can
    # never disagree. `Mailglass.Identifier.validate!/2` (core) fails fast on a
    # bad identifier. Only `:schema` is cached — retention/rate_limit stay cold.
    schema = Keyword.get(validated, :schema, "mailglass")
    :persistent_term.put(@schema_key, Mailglass.Identifier.validate!(schema, :schema))

    :ok
  end

  @doc """
  Returns the configured Postgres schema name (default `"mailglass"`).

  Serves from `:persistent_term` in O(1) on the hot path. Warmed at boot by
  `validate_at_boot!/0`; on a cold-cache miss (a boot-skipped context) it
  self-heals by re-reading and re-validating the `:schema` `:mailglass_inbound`
  app env (never core `:mailglass`), then caching the validated value.
  `"public"` is the explicit pre-2.0 opt-out.

  Reuses core's `Mailglass.Identifier.validate!/2` — one validator across the
  family, no inbound-local regex and no inbound-local error type. The value is
  always validated once at the cache-write boundary so an adopter's
  `schema: "public"` opt-out can never be masked by a silent default.
  """
  @doc since: "2.0.0"
  @spec schema() :: String.t()
  def schema do
    case :persistent_term.get(@schema_key, :__miss__) do
      :__miss__ -> warm_schema()
      schema -> schema
    end
  end

  defp warm_schema do
    schema = Application.get_env(:mailglass_inbound, :schema, "mailglass")
    Mailglass.Identifier.validate!(schema, :schema)
    :persistent_term.put(@schema_key, schema)
    schema
  end

  @doc """
  Returns the validated retention windows as a keyword list with every class
  present (defaults merged over any configured overrides), CLAMPED to satisfy the
  FK-lineage invariant.

  The inbound prune deletes child-first against `on_delete: :nothing` FKs, so a
  parent window can never be shorter than a child that references it. This
  accessor enforces:

    * `evidence_days >= max(execution_runs_days, replay_runs_days)` — evidence is
      referenced by both `:fresh` and `:replay` runs.
    * `records_days >= evidence_days` — records are referenced by evidence (and by
      runs, but `evidence_days` already dominates the run windows).

  A configured override that would invert the lineage is silently clamped UP to
  the smallest safe value rather than allowed to crash the sweep on a
  `foreign_key_violation`. `:infinity` (window disabled) is treated as the
  maximum, so an `:infinity` child forces its parents to `:infinity` too.
  """
  @doc since: "1.2.0"
  @spec retention() :: keyword()
  def retention, do: clamp_retention(Keyword.fetch!(validated(), :retention))

  # Clamp parent windows up so they always outlive the children referencing them
  # via `on_delete: :nothing` (CR-02). `:infinity` is the maximum.
  defp clamp_retention(retention) do
    fresh = Keyword.fetch!(retention, :execution_runs_days)
    replay = Keyword.fetch!(retention, :replay_runs_days)
    evidence = Keyword.fetch!(retention, :evidence_days)
    records = Keyword.fetch!(retention, :records_days)

    safe_evidence = window_max([evidence, fresh, replay])
    safe_records = window_max([records, safe_evidence])

    retention
    |> Keyword.put(:evidence_days, safe_evidence)
    |> Keyword.put(:records_days, safe_records)
  end

  # `:infinity` dominates any finite day count.
  defp window_max(windows) do
    if Enum.any?(windows, &(&1 == :infinity)) do
      :infinity
    else
      Enum.max(windows)
    end
  end

  @doc """
  Returns the validated rate-limit buckets as a keyword list with every bucket
  present (defaults merged over any configured overrides).
  """
  @doc since: "1.2.0"
  @spec rate_limit() :: keyword()
  def rate_limit, do: Keyword.fetch!(validated(), :rate_limit)

  defp validated do
    known_keys = Keyword.keys(@schema)

    :mailglass_inbound
    |> Application.get_all_env()
    |> Keyword.take(known_keys)
    |> NimbleOptions.validate!(@schema)
  end
end
