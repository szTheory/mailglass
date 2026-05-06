defmodule MailglassInbound.Migrations.GeneralizeReplayRunsToExecutionLineage do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:mailglass_inbound_replay_runs) do
      add :source, :text, default: "replay", null: false
    end

    execute("""
    UPDATE mailglass_inbound_replay_runs
    SET source = 'replay'
    WHERE source IS NULL
    """)

    execute("""
    ALTER TABLE mailglass_inbound_replay_runs
    ALTER COLUMN replay_id DROP NOT NULL,
    ALTER COLUMN mailbox DROP NOT NULL
    """)
  end

  def down do
    execute("""
    ALTER TABLE mailglass_inbound_replay_runs
    ALTER COLUMN replay_id SET NOT NULL,
    ALTER COLUMN mailbox SET NOT NULL
    """)

    alter table(:mailglass_inbound_replay_runs) do
      remove :source
    end
  end
end
