defmodule Mailglass.Migrations.Postgres.V06 do
  @moduledoc false
  use Ecto.Migration

  # Expand-only lifecycle support. Existing rows intentionally remain nullable:
  # their historical JSON payload is retained and new verified requests write
  # the byte-for-byte signed body alongside it.
  def up(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    execute("SET LOCAL lock_timeout = '500ms'")
    execute("SET LOCAL statement_timeout = '2s'")

    alter table(:mailglass_webhook_events, prefix: prefix) do
      add(:raw_signed_body, :binary)
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
      """
      CREATE TRIGGER mailglass_webhook_signed_body_immutable_trigger
        BEFORE UPDATE ON #{q}.mailglass_webhook_events
        FOR EACH ROW EXECUTE FUNCTION #{q}.mailglass_webhook_signed_body_immutable();
      """,
      "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
    )

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

  def down(opts \\ []) do
    prefix = opts[:prefix]
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    execute(
      "DROP TRIGGER IF EXISTS mailglass_webhook_signed_body_immutable_trigger ON #{q}.mailglass_webhook_events"
    )

    execute("DROP FUNCTION IF EXISTS #{q}.mailglass_webhook_signed_body_immutable()")

    drop(
      index(:mailglass_webhook_events, [:status, :inserted_at, :id],
        name: :mailglass_webhook_events_status_age_id_idx,
        prefix: prefix
      )
    )

    drop(
      index(:mailglass_webhook_events, [:provider, :status, :inserted_at, :id],
        name: :mailglass_webhook_events_provider_status_age_id_idx,
        prefix: prefix
      )
    )

    alter table(:mailglass_webhook_events, prefix: prefix) do
      remove(:raw_signed_body)
    end
  end
end
