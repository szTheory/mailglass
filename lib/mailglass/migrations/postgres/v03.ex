defmodule Mailglass.Migrations.Postgres.V03 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    create(
      index(:mailglass_events, [:tenant_id, :delivery_id, "occurred_at DESC"],
        where: "type = 'deferred' AND delivery_id IS NOT NULL",
        name: :mailglass_events_deferred_window_idx,
        prefix: prefix
      )
    )

    execute(
      """
      ALTER TABLE mailglass_suppressions
        ADD CONSTRAINT mailglass_suppressions_complaint_permanent_check
        CHECK (reason != 'complaint' OR expires_at IS NULL)
      """,
      "ALTER TABLE mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_complaint_permanent_check"
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    execute(
      "ALTER TABLE mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_complaint_permanent_check"
    )

    drop(
      index(:mailglass_events, [:tenant_id, :delivery_id, "occurred_at DESC"],
        where: "type = 'deferred' AND delivery_id IS NOT NULL",
        name: :mailglass_events_deferred_window_idx,
        prefix: prefix
      )
    )
  end
end
