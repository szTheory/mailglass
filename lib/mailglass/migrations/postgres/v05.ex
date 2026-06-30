defmodule Mailglass.Migrations.Postgres.V05 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    alter table(:mailglass_deliveries, prefix: prefix) do
      add(:idempotency_key, :text)
      add(:status, :string, null: false, default: "queued")
      add(:last_error, :map)
    end

    # Partial UNIQUE index — enforces replay safety for deliver_many/2 batches.
    # Rows with idempotency_key = NULL are NOT constrained (same predicate shape
    # as the mailglass_events idempotency index). Pitfall 1: the `where:` clause
    # MUST match Outbound's conflict_target fragment
    # `(idempotency_key) WHERE idempotency_key IS NOT NULL` character-for-character.
    create(
      unique_index(:mailglass_deliveries, [:idempotency_key],
        name: :mailglass_deliveries_idempotency_key_unique_idx,
        where: "idempotency_key IS NOT NULL",
        prefix: prefix
      )
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    drop(
      index(:mailglass_deliveries, [:idempotency_key],
        name: :mailglass_deliveries_idempotency_key_unique_idx,
        prefix: prefix
      )
    )

    alter table(:mailglass_deliveries, prefix: prefix) do
      remove(:last_error)
      remove(:status)
      remove(:idempotency_key)
    end
  end
end
