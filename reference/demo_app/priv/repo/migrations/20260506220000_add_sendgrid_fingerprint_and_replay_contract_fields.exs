defmodule MailglassInbound.Migrations.AddSendgridFingerprintAndReplayContractFields do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:mailglass_inbound_evidence) do
      add(:raw_mime_fingerprint, :text,
        generated: "ALWAYS AS (CASE WHEN raw_mime IS NULL THEN NULL ELSE md5(raw_mime) END) STORED"
      )
    end

    create(
      unique_index(
        :mailglass_inbound_evidence,
        [:tenant_id, :provider, :raw_mime_fingerprint],
        where: "provider = 'sendgrid' AND raw_mime_fingerprint IS NOT NULL",
        name: :mailglass_inbound_records_sendgrid_fingerprint_idx
      )
    )
  end

  def down do
    drop_if_exists(
      index(:mailglass_inbound_evidence, [:tenant_id, :provider, :raw_mime_fingerprint],
        name: :mailglass_inbound_records_sendgrid_fingerprint_idx
      )
    )

    alter table(:mailglass_inbound_evidence) do
      remove(:raw_mime_fingerprint)
    end
  end
end
