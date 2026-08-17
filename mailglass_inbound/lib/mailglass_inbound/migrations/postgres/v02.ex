defmodule MailglassInbound.Migrations.Postgres.V02 do
  @moduledoc false

  # This version is intentionally expand-only.  The generated host wrapper must
  # opt out of Ecto's DDL transaction before asking this module to build the
  # populated-table indexes concurrently (the Plan 09 generator contract).
  # Direct callers still receive correct transactional DDL, but never a false
  # claim that `CREATE INDEX CONCURRENTLY` ran in a transaction.
  use Ecto.Migration

  alias Mailglass.Migrations.Postgres.SessionTimeouts

  @concurrent_indexes [
    "mailglass_inbound_evidence_sha256_idx",
    "mailglass_inbound_records_retention_idx",
    "mailglass_inbound_evidence_retention_idx",
    "mailglass_inbound_replay_runs_retention_idx"
  ]

  @doc false
  def concurrent_indexes, do: @concurrent_indexes

  def up(opts \\ []) do
    opts = Map.new(opts)
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)

    if Map.get(opts, :concurrent_indexes, false) do
      execute(fn ->
        SessionTimeouts.run(repo(), fn -> concurrent_up(repo(), inspect(prefix)) end)
      end)
    else
      configure_transactional_timeouts()

      alter table(:mailglass_inbound_evidence, prefix: prefix) do
        add_if_not_exists(:raw_mime_sha256, :binary)
        add_if_not_exists(:raw_signed_request, :binary)
        add_if_not_exists(:terminal_failure_class, :text)
        add_if_not_exists(:terminal_context, :map, null: false, default: %{})
      end

      create_transactional_indexes(prefix)
    end
  end

  def down(opts \\ []) do
    opts = Map.new(opts)
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)

    if Map.get(opts, :concurrent_indexes, false) do
      execute(fn ->
        SessionTimeouts.run(repo(), fn -> concurrent_down(repo(), inspect(prefix)) end)
      end)
    else
      configure_transactional_timeouts()
      drop_transactional_indexes(prefix)

      alter table(:mailglass_inbound_evidence, prefix: prefix) do
        remove(:terminal_context)
        remove(:terminal_failure_class)
        remove(:raw_signed_request)
        remove(:raw_mime_sha256)
      end
    end
  end

  defp configure_transactional_timeouts do
    execute("SET LOCAL lock_timeout = '500ms'")
    execute("SET LOCAL statement_timeout = '2s'")
  end

  defp create_transactional_indexes(prefix) do
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

  defp drop_transactional_indexes(prefix) do
    for name <- Enum.reverse(@concurrent_indexes),
        do: execute("DROP INDEX IF EXISTS #{inspect(prefix)}.#{name}")
  end

  defp concurrent_up(repo, q) do
    repo.query!("""
    ALTER TABLE #{q}.mailglass_inbound_evidence
      ADD COLUMN IF NOT EXISTS raw_mime_sha256 bytea,
      ADD COLUMN IF NOT EXISTS raw_signed_request bytea,
      ADD COLUMN IF NOT EXISTS terminal_failure_class text,
      ADD COLUMN IF NOT EXISTS terminal_context jsonb NOT NULL DEFAULT '{}'::jsonb
    """)

    # PostgreSQL leaves an INVALID shell behind when a concurrent build is
    # interrupted. Dropping the package-owned fixed names first recovers it.
    for name <- @concurrent_indexes,
        do: repo.query!("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")

    repo.query!(
      "CREATE UNIQUE INDEX CONCURRENTLY mailglass_inbound_evidence_sha256_idx ON #{q}.mailglass_inbound_evidence (tenant_id, provider, raw_mime_sha256) WHERE provider IN ('sendgrid', 'mailgun', 'ses') AND raw_mime_sha256 IS NOT NULL"
    )

    repo.query!(
      "CREATE INDEX CONCURRENTLY mailglass_inbound_records_retention_idx ON #{q}.mailglass_inbound_records (inserted_at, id)"
    )

    repo.query!(
      "CREATE INDEX CONCURRENTLY mailglass_inbound_evidence_retention_idx ON #{q}.mailglass_inbound_evidence (inserted_at, id)"
    )

    repo.query!(
      "CREATE INDEX CONCURRENTLY mailglass_inbound_replay_runs_retention_idx ON #{q}.mailglass_inbound_replay_runs (source, inserted_at, id)"
    )
  end

  defp concurrent_down(repo, q) do
    for name <- Enum.reverse(@concurrent_indexes),
        do: repo.query!("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")

    repo.query!("""
    ALTER TABLE #{q}.mailglass_inbound_evidence
      DROP COLUMN IF EXISTS terminal_context,
      DROP COLUMN IF EXISTS terminal_failure_class,
      DROP COLUMN IF EXISTS raw_signed_request,
      DROP COLUMN IF EXISTS raw_mime_sha256
    """)
  end
end
