defmodule Mailglass.Migrations.Postgres.V06 do
  @moduledoc false
  use Ecto.Migration

  # Expand-only lifecycle support. Existing rows intentionally remain nullable:
  # their historical JSON payload is retained and new verified requests write
  # the byte-for-byte signed body alongside it.
  def up(opts \\ []) do
    prefix = opts[:prefix]

    execute("SET LOCAL lock_timeout = '500ms'")
    execute("SET LOCAL statement_timeout = '2s'")

    alter table(:mailglass_webhook_events, prefix: prefix) do
      add(:raw_signed_body, :binary)
    end

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
