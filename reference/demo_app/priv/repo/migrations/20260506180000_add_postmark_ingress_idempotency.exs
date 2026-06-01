defmodule MailglassInbound.Migrations.AddPostmarkIngressIdempotency do
  @moduledoc false
  use Ecto.Migration

  def change do
    create(
      unique_index(
        :mailglass_inbound_records,
        [:tenant_id, :provider, :provider_message_id],
        where: "provider_message_id IS NOT NULL",
        name: :mailglass_inbound_records_postmark_idempotency_idx
      )
    )
  end
end
