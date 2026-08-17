defmodule MailglassInbound.Migrations.Postgres.V02 do
  @moduledoc false

  # This version is intentionally expand-only.  The generated host wrapper must
  # opt out of Ecto's DDL transaction before asking this module to build the
  # populated-table indexes concurrently (the Plan 09 generator contract).
  # Direct callers still receive correct transactional DDL, but never a false
  # claim that `CREATE INDEX CONCURRENTLY` ran in a transaction.
  use Ecto.Migration

  @concurrent_indexes [
    "mailglass_inbound_evidence_sha256_idx",
    "mailglass_inbound_records_retention_idx",
    "mailglass_inbound_evidence_retention_idx",
    "mailglass_inbound_replay_runs_retention_idx"
  ]

  @doc false
  def concurrent_indexes, do: @concurrent_indexes

  def up(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    concurrent_indexes = Map.get(opts, :concurrent_indexes, false)

    configure_timeouts(concurrent_indexes)

    try do
      alter table(:mailglass_inbound_evidence, prefix: prefix) do
        add_if_not_exists(:raw_mime_sha256, :binary)
        add_if_not_exists(:raw_signed_request, :binary)
        add_if_not_exists(:terminal_failure_class, :text)
        add_if_not_exists(:terminal_context, :map, null: false, default: %{})
      end

      # These are deliberately separate statements.  A generated wrapper that
      # advertises `@disable_ddl_transaction true` passes `concurrent_indexes: true`
      # and gets the non-blocking path.  The existing facade remains compatible for
      # transactional installer wrappers until that generator contract ships.
      create_indexes(prefix, concurrent_indexes)
    after
      reset_timeouts(concurrent_indexes)
    end
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    concurrent_indexes = Map.get(opts, :concurrent_indexes, false)

    configure_timeouts(concurrent_indexes)

    try do
      drop_indexes(prefix, concurrent_indexes)

      alter table(:mailglass_inbound_evidence, prefix: prefix) do
        remove(:terminal_context)
        remove(:terminal_failure_class)
        remove(:raw_signed_request)
        remove(:raw_mime_sha256)
      end
    after
      reset_timeouts(concurrent_indexes)
    end
  end

  defp configure_timeouts(false) do
    execute("SET LOCAL lock_timeout = '500ms'")
    execute("SET LOCAL statement_timeout = '2s'")
  end

  defp configure_timeouts(true) do
    execute("SET lock_timeout = '500ms'")
    execute("SET statement_timeout = '30s'")
  end

  defp reset_timeouts(false), do: :ok

  defp reset_timeouts(true) do
    execute("RESET lock_timeout")
    execute("RESET statement_timeout")
  end

  defp create_indexes(prefix, true) do
    q = inspect(prefix)

    # PostgreSQL leaves an INVALID shell behind when a concurrent build is
    # interrupted. Dropping the package-owned fixed names first recovers that
    # state and also makes a manually retried V02 deterministic.
    for name <- @concurrent_indexes,
        do: execute("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")

    for sql <- concurrent_index_sql(prefix), do: execute(sql)
  end

  defp create_indexes(prefix, false) do
    create_if_not_exists(
      unique_index(:mailglass_inbound_evidence, [:tenant_id, :provider, :raw_mime_sha256],
        where: "provider IN ('sendgrid', 'mailgun', 'ses') AND raw_mime_sha256 IS NOT NULL",
        name: :mailglass_inbound_evidence_sha256_idx,
        prefix: prefix
      )
    )

    create_if_not_exists(
      index(:mailglass_inbound_records, [:inserted_at, :id],
        name: :mailglass_inbound_records_retention_idx,
        prefix: prefix
      )
    )

    create_if_not_exists(
      index(:mailglass_inbound_evidence, [:inserted_at, :id],
        name: :mailglass_inbound_evidence_retention_idx,
        prefix: prefix
      )
    )

    create_if_not_exists(
      index(:mailglass_inbound_replay_runs, [:source, :inserted_at, :id],
        name: :mailglass_inbound_replay_runs_retention_idx,
        prefix: prefix
      )
    )
  end

  defp drop_indexes(prefix, true) do
    q = inspect(prefix)

    for name <- Enum.reverse(@concurrent_indexes),
        do: execute("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")
  end

  defp drop_indexes(prefix, false) do
    for name <- Enum.reverse(@concurrent_indexes),
        do: execute("DROP INDEX IF EXISTS #{inspect(prefix)}.#{name}")
  end

  defp concurrent_index_sql(prefix) do
    q = inspect(prefix)

    [
      "CREATE UNIQUE INDEX CONCURRENTLY mailglass_inbound_evidence_sha256_idx ON #{q}.mailglass_inbound_evidence (tenant_id, provider, raw_mime_sha256) WHERE provider IN ('sendgrid', 'mailgun', 'ses') AND raw_mime_sha256 IS NOT NULL",
      "CREATE INDEX CONCURRENTLY mailglass_inbound_records_retention_idx ON #{q}.mailglass_inbound_records (inserted_at, id)",
      "CREATE INDEX CONCURRENTLY mailglass_inbound_evidence_retention_idx ON #{q}.mailglass_inbound_evidence (inserted_at, id)",
      "CREATE INDEX CONCURRENTLY mailglass_inbound_replay_runs_retention_idx ON #{q}.mailglass_inbound_replay_runs (source, inserted_at, id)"
    ]
  end
end
