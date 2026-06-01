defmodule MailglassDemo.Repo.Migrations.AddDeliverySnapshotFields do
  use Ecto.Migration

  def up do
    alter table(:mailglass_deliveries) do
      add(:idempotency_key, :text)
      add(:status, :string, null: false, default: "queued")
      add(:last_error, :map)
    end

    create(
      unique_index(:mailglass_deliveries, [:idempotency_key],
        name: :mailglass_deliveries_idempotency_key_unique_idx,
        where: "idempotency_key IS NOT NULL"
      )
    )
  end

  def down do
    drop(
      index(:mailglass_deliveries, [:idempotency_key],
        name: :mailglass_deliveries_idempotency_key_unique_idx
      )
    )

    alter table(:mailglass_deliveries) do
      remove(:idempotency_key)
      remove(:status)
      remove(:last_error)
    end
  end
end
