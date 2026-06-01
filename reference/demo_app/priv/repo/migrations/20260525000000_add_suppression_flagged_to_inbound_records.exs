defmodule MailglassInbound.Migrations.AddSuppressionFlaggedToInboundRecords do
  @moduledoc false
  use Ecto.Migration

  # IOPS-05 (D-49-20): the suppression flag-only contract. A webhook-accepted
  # message from a suppressed sender persists normally, carrying a diagnostic
  # boolean. The column is the source of truth — the admin list (IADM-02) selects
  # it directly and `Execution.message_from_record/1` projects it into the typed
  # `%InboundMessage.Signals{}` adopters read.
  #
  # `NOT NULL DEFAULT false` backfills every existing row to `false` in a single
  # DDL statement, so no data migration of historical records is needed and a
  # pre-migration row projects `signals.suppression_flagged == false` (never nil).
  # Inbound tables are append-only by convention but carry no UPDATE/DELETE
  # trigger; the flag is set once at INSERT.

  def up do
    alter table(:mailglass_inbound_records) do
      add(:suppression_flagged, :boolean, null: false, default: false)
    end
  end

  def down do
    alter table(:mailglass_inbound_records) do
      remove(:suppression_flagged)
    end
  end
end
