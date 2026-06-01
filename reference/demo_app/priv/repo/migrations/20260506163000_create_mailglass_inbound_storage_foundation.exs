defmodule MailglassInbound.Migrations.CreateStorageFoundation do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:mailglass_inbound_records, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:provider, :text, null: false)
      add(:provider_message_id, :text)
      add(:message_id, :text)
      add(:envelope_recipient, :text)
      add(:from, {:array, :map}, null: false, default: [])
      add(:to, {:array, :map}, null: false, default: [])
      add(:cc, {:array, :map}, null: false, default: [])
      add(:bcc, {:array, :map}, null: false, default: [])
      add(:reply_to, {:array, :map}, null: false, default: [])
      add(:subject, :text)
      add(:headers, :map, null: false, default: %{})
      add(:sent_at, :utc_datetime_usec)
      add(:received_at, :utc_datetime_usec, null: false)
      add(:text_body, :text)
      add(:html_body, :text)
      add(:attachments, {:array, :map}, null: false, default: [])

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:mailglass_inbound_records, [:tenant_id]))
    create(index(:mailglass_inbound_records, [:tenant_id, :provider]))

    create table(:mailglass_inbound_evidence, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:provider, :text, null: false)

      add(
        :inbound_record_id,
        references(:mailglass_inbound_records, type: :uuid, on_delete: :nothing),
        null: false
      )

      add(:raw_payload, :map, null: false, default: %{})
      add(:raw_headers, :map, null: false, default: %{})
      add(:raw_mime, :binary)
      add(:verification_facts, :map, null: false, default: %{})
      add(:parse_warnings, :map, null: false, default: %{})
      add(:attachment_blobs, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:mailglass_inbound_evidence, [:inbound_record_id]))
    create(index(:mailglass_inbound_evidence, [:tenant_id]))

    create table(:mailglass_inbound_replay_runs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:replay_id, :text, null: false)
      add(:mailbox, :text, null: false)
      add(:outcome, :text)
      add(:outcome_reason, :text)
      add(:failure, :map, null: false, default: %{})
      add(:executed_at, :utc_datetime_usec, null: false)
      add(:metadata, :map, null: false, default: %{})

      add(
        :inbound_record_id,
        references(:mailglass_inbound_records, type: :uuid, on_delete: :nothing),
        null: false
      )

      add(
        :inbound_evidence_id,
        references(:mailglass_inbound_evidence, type: :uuid, on_delete: :nothing),
        null: false
      )

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:mailglass_inbound_replay_runs, [:tenant_id, :replay_id]))
    create(index(:mailglass_inbound_replay_runs, [:tenant_id, :inbound_record_id]))
    create(index(:mailglass_inbound_replay_runs, [:tenant_id, :inbound_evidence_id]))
  end
end
