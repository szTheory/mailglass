defmodule Mailglass.Migrations.Postgres.V06 do
  @moduledoc false
  use Ecto.Migration

  @concurrent_indexes [
    "mailglass_webhook_events_provider_status_age_id_idx",
    "mailglass_webhook_events_status_age_id_idx"
  ]

  @doc false
  def concurrent_indexes, do: @concurrent_indexes

  # Expand-only lifecycle support. Existing rows intentionally remain nullable:
  # their historical JSON payload is retained and new verified requests write
  # the byte-for-byte signed body alongside it.
  def up(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    concurrent_indexes = Map.get(opts, :concurrent_indexes, false)
    configure_timeouts(concurrent_indexes)

    try do
      alter table(:mailglass_webhook_events, prefix: prefix) do
        add_if_not_exists(:raw_signed_body, :binary)
      end

      execute(
        """
        CREATE OR REPLACE FUNCTION #{q}.mailglass_webhook_signed_body_immutable()
        RETURNS trigger
        LANGUAGE plpgsql
        SET search_path = ''
        AS $$
        BEGIN
          IF OLD.raw_signed_body IS DISTINCT FROM NEW.raw_signed_body THEN
            RAISE SQLSTATE '45A01'
              USING MESSAGE = 'mailglass_webhook_events.raw_signed_body is immutable';
          END IF;

          RETURN NEW;
        END;
        $$;
        """,
        "DROP FUNCTION IF EXISTS #{q}.mailglass_webhook_signed_body_immutable()"
      )

      execute(
        "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
      )

      execute("""
      CREATE TRIGGER mailglass_webhook_signed_body_immutable_trigger
        BEFORE UPDATE ON #{q}.mailglass_webhook_events
        FOR EACH ROW EXECUTE FUNCTION #{q}.mailglass_webhook_signed_body_immutable();
      """)

      create_indexes(prefix, concurrent_indexes)
    after
      # The concurrent path is intentionally outside a transaction, so SET
      # changes the checked-out connection. Always restore it before the Repo
      # returns that connection to its pool, including failed-index retries.
      reset_timeouts(concurrent_indexes)
    end
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    execute(
      "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
    )

    execute("DROP FUNCTION IF EXISTS #{q}.mailglass_webhook_signed_body_immutable()")

    drop_indexes(prefix, Map.get(opts, :concurrent_indexes, false))

    alter table(:mailglass_webhook_events, prefix: prefix) do
      remove(:raw_signed_body)
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

    # A failed concurrent build leaves an INVALID index behind. Dropping the
    # fixed package-owned names before creating them makes a retry deterministic
    # and also keeps a manually re-run V06 idempotent.
    for name <- @concurrent_indexes,
        do: execute("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")

    execute(
      "CREATE INDEX CONCURRENTLY mailglass_webhook_events_provider_status_age_id_idx ON #{q}.mailglass_webhook_events (provider, status, inserted_at, id)"
    )

    execute(
      "CREATE INDEX CONCURRENTLY mailglass_webhook_events_status_age_id_idx ON #{q}.mailglass_webhook_events (status, inserted_at, id)"
    )
  end

  defp create_indexes(prefix, false) do
    create(
      index(:mailglass_webhook_events, [:provider, :status, :inserted_at, :id],
        name: :mailglass_webhook_events_provider_status_age_id_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_webhook_events, [:status, :inserted_at, :id],
        name: :mailglass_webhook_events_status_age_id_idx,
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
    drop_if_exists(
      index(:mailglass_webhook_events, [:status, :inserted_at, :id],
        name: :mailglass_webhook_events_status_age_id_idx,
        prefix: prefix
      )
    )

    drop_if_exists(
      index(:mailglass_webhook_events, [:provider, :status, :inserted_at, :id],
        name: :mailglass_webhook_events_provider_status_age_id_idx,
        prefix: prefix
      )
    )
  end
end
