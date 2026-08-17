defmodule Mailglass.Migrations.Postgres.V06 do
  @moduledoc false
  use Ecto.Migration

  alias Mailglass.Migrations.Postgres.SessionTimeouts

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

    if Map.get(opts, :concurrent_indexes, false) do
      execute(fn ->
        SessionTimeouts.run(repo(), fn -> concurrent_up(repo(), q) end)
      end)
    else
      configure_transactional_timeouts()

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

      create_transactional_indexes(prefix)
    end
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    if Map.get(opts, :concurrent_indexes, false) do
      execute(fn ->
        SessionTimeouts.run(repo(), fn -> concurrent_down(repo(), q) end)
      end)
    else
      configure_transactional_timeouts()

      execute(
        "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
      )

      execute("DROP FUNCTION IF EXISTS #{q}.mailglass_webhook_signed_body_immutable()")

      drop_transactional_indexes(prefix)

      alter table(:mailglass_webhook_events, prefix: prefix) do
        remove(:raw_signed_body)
      end
    end
  end

  defp configure_transactional_timeouts do
    execute("SET LOCAL lock_timeout = '500ms'")
    execute("SET LOCAL statement_timeout = '2s'")
  end

  defp create_transactional_indexes(prefix) do
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

  defp drop_transactional_indexes(prefix) do
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

  defp concurrent_up(repo, q) do
    repo.query!("""
    ALTER TABLE #{q}.mailglass_webhook_events
      ADD COLUMN IF NOT EXISTS raw_signed_body bytea
    """)

    repo.query!("""
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
    """)

    repo.query!(
      "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
    )

    repo.query!("""
    CREATE TRIGGER mailglass_webhook_signed_body_immutable_trigger
      BEFORE UPDATE ON #{q}.mailglass_webhook_events
      FOR EACH ROW EXECUTE FUNCTION #{q}.mailglass_webhook_signed_body_immutable()
    """)

    # A failed concurrent build leaves an INVALID index behind. Dropping the
    # fixed package-owned names before creating them makes a retry deterministic.
    for name <- @concurrent_indexes,
        do: repo.query!("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")

    repo.query!(
      "CREATE INDEX CONCURRENTLY mailglass_webhook_events_provider_status_age_id_idx ON #{q}.mailglass_webhook_events (provider, status, inserted_at, id)"
    )

    repo.query!(
      "CREATE INDEX CONCURRENTLY mailglass_webhook_events_status_age_id_idx ON #{q}.mailglass_webhook_events (status, inserted_at, id)"
    )
  end

  defp concurrent_down(repo, q) do
    repo.query!(
      "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
    )

    repo.query!("DROP FUNCTION IF EXISTS #{q}.mailglass_webhook_signed_body_immutable()")

    for name <- Enum.reverse(@concurrent_indexes),
        do: repo.query!("DROP INDEX CONCURRENTLY IF EXISTS #{q}.#{name}")

    repo.query!("""
    ALTER TABLE #{q}.mailglass_webhook_events
      DROP COLUMN IF EXISTS raw_signed_body
    """)
  end
end
