defmodule MailglassDemo.Repo.Migrations.AddDeliverySnapshotFields do
  use Ecto.Migration

  # Core install (Mailglass.Migration.up/0) creates mailglass_deliveries in the
  # configured schema (v2.0 default "mailglass"). Qualify every DDL call here so
  # it targets the same schema instead of resolving against "public".
  @prefix "mailglass"

  def up do
    alter table(:mailglass_deliveries, prefix: @prefix) do
      add(:idempotency_key, :text)
      add(:status, :string, null: false, default: "queued")
      add(:last_error, :map)
    end

    create(
      unique_index(:mailglass_deliveries, [:idempotency_key],
        name: :mailglass_deliveries_idempotency_key_unique_idx,
        where: "idempotency_key IS NOT NULL",
        prefix: @prefix
      )
    )
  end

  def down do
    drop(
      index(:mailglass_deliveries, [:idempotency_key],
        name: :mailglass_deliveries_idempotency_key_unique_idx,
        prefix: @prefix
      )
    )

    alter table(:mailglass_deliveries, prefix: @prefix) do
      remove(:idempotency_key)
      remove(:status)
      remove(:last_error)
    end
  end
end
