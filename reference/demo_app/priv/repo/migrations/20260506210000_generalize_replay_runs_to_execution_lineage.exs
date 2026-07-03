defmodule MailglassInbound.Migrations.GeneralizeReplayRunsToExecutionLineage do
  @moduledoc false
  use Ecto.Migration

  # Inbound tables live in the configured schema (v2.0 default "mailglass"). The
  # DSL calls carry prefix: @prefix; the raw execute/1 SQL qualifies the table
  # name inline since a keyword prefix cannot reach into a raw statement.
  @prefix "mailglass"

  def up do
    alter table(:mailglass_inbound_replay_runs, prefix: @prefix) do
      add(:source, :text, default: "replay", null: false)
    end

    execute("""
    UPDATE #{@prefix}.mailglass_inbound_replay_runs
    SET source = 'replay'
    WHERE source IS NULL
    """)

    execute("""
    ALTER TABLE #{@prefix}.mailglass_inbound_replay_runs
    ALTER COLUMN replay_id DROP NOT NULL,
    ALTER COLUMN mailbox DROP NOT NULL
    """)
  end

  def down do
    execute("""
    ALTER TABLE #{@prefix}.mailglass_inbound_replay_runs
    ALTER COLUMN replay_id SET NOT NULL,
    ALTER COLUMN mailbox SET NOT NULL
    """)

    alter table(:mailglass_inbound_replay_runs, prefix: @prefix) do
      remove(:source)
    end
  end
end
