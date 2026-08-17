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

    alter table(:mailglass_inbound_evidence, prefix: prefix) do
      add(:raw_mime_sha256, :binary)
      add(:terminal_failure_class, :text)
      add(:terminal_context, :map, null: false, default: %{})
    end

    # These are deliberately separate statements.  A generated wrapper that
    # advertises `@disable_ddl_transaction true` passes `concurrent_indexes: true`
    # and gets the non-blocking path.  The existing facade remains compatible for
    # transactional installer wrappers until that generator contract ships.
    create_indexes(prefix, Map.get(opts, :concurrent_indexes, false))
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)

    for name <- Enum.reverse(@concurrent_indexes),
        do: execute("DROP INDEX IF EXISTS #{inspect(prefix)}.#{name}")

    alter table(:mailglass_inbound_evidence, prefix: prefix) do
      remove(:terminal_context)
      remove(:terminal_failure_class)
      remove(:raw_mime_sha256)
    end
  end

  defp create_indexes(prefix, true) do
    for sql <- concurrent_index_sql(prefix), do: execute(sql)
  end

  defp create_indexes(prefix, false) do
    create(
      unique_index(:mailglass_inbound_evidence, [:tenant_id, :provider, :raw_mime_sha256],
        where: "raw_mime_sha256 IS NOT NULL",
        name: :mailglass_inbound_evidence_sha256_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_inbound_records, [:inserted_at, :id],
        name: :mailglass_inbound_records_retention_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_inbound_evidence, [:inserted_at, :id],
        name: :mailglass_inbound_evidence_retention_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_inbound_replay_runs, [:source, :inserted_at, :id],
        name: :mailglass_inbound_replay_runs_retention_idx,
        prefix: prefix
      )
    )
  end

  defp concurrent_index_sql(prefix) do
    q = inspect(prefix)

    [
      "CREATE UNIQUE INDEX CONCURRENTLY mailglass_inbound_evidence_sha256_idx ON #{q}.mailglass_inbound_evidence (tenant_id, provider, raw_mime_sha256) WHERE raw_mime_sha256 IS NOT NULL",
      "CREATE INDEX CONCURRENTLY mailglass_inbound_records_retention_idx ON #{q}.mailglass_inbound_records (inserted_at, id)",
      "CREATE INDEX CONCURRENTLY mailglass_inbound_evidence_retention_idx ON #{q}.mailglass_inbound_evidence (inserted_at, id)",
      "CREATE INDEX CONCURRENTLY mailglass_inbound_replay_runs_retention_idx ON #{q}.mailglass_inbound_replay_runs (source, inserted_at, id)"
    ]
  end
end
