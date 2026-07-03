defmodule Mailglass.Migrations.Postgres.V03 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    # Ecto does NOT prefix raw execute() SQL — hand-qualify the CHECK via #{q}.
    # gated by the same identifier chokepoint the dispatcher uses (T-134-01).
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    create(
      index(:mailglass_events, [:tenant_id, :delivery_id, "occurred_at DESC"],
        where: "type = 'deferred' AND delivery_id IS NOT NULL",
        name: :mailglass_events_deferred_window_idx,
        prefix: prefix
      )
    )

    execute(
      """
      ALTER TABLE #{q}.mailglass_suppressions
        ADD CONSTRAINT mailglass_suppressions_complaint_permanent_check
        CHECK (reason != 'complaint' OR expires_at IS NULL)
      """,
      "ALTER TABLE #{q}.mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_complaint_permanent_check"
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    execute(
      "ALTER TABLE #{q}.mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_complaint_permanent_check"
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
