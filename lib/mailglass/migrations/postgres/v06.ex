defmodule Mailglass.Migrations.Postgres.V06 do
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    create table(:mailglass_outbound_payloads, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)

      add(
        :delivery_id,
        references(:mailglass_deliveries, type: :uuid, on_delete: :delete_all, prefix: prefix),
        null: false
      )

      add(:envelope_version, :integer, null: false)
      add(:envelope_digest, :text, null: false)
      add(:envelope, :map, null: false)
      add(:scrubbed_at, :utc_datetime_usec)
      add(:expires_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:mailglass_outbound_payloads, [:delivery_id],
        name: :mailglass_outbound_payloads_delivery_id_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_outbound_payloads, [:tenant_id, :delivery_id],
        name: :mailglass_outbound_payloads_tenant_delivery_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_outbound_payloads, [:expires_at],
        name: :mailglass_outbound_payloads_expires_at_idx,
        where: "expires_at IS NOT NULL",
        prefix: prefix
      )
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    drop(
      index(:mailglass_outbound_payloads, [:expires_at],
        name: :mailglass_outbound_payloads_expires_at_idx,
        prefix: prefix
      )
    )

    drop(
      index(:mailglass_outbound_payloads, [:tenant_id, :delivery_id],
        name: :mailglass_outbound_payloads_tenant_delivery_idx,
        prefix: prefix
      )
    )

    drop(
      index(:mailglass_outbound_payloads, [:delivery_id],
        name: :mailglass_outbound_payloads_delivery_id_idx,
        prefix: prefix
      )
    )

    drop(table(:mailglass_outbound_payloads, prefix: prefix))
  end
end
