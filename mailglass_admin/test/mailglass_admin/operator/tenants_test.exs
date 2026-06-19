defmodule MailglassAdmin.Operator.TenantsTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.Operator.Tenants

  defmodule InboundGateway do
    def available?, do: true

    def list_tenants(_context, _opts \\ []) do
      [
        %{id: "tenant-c", label: "tenant-c"},
        %{id: "tenant-a", label: "tenant-a"}
      ]
    end
  end

  defmodule UnavailableInboundGateway do
  end

  describe "list_tenants/2" do
    test "returns de-duplicated sorted outbound and inbound-only selector rows" do
      insert_delivery!("tenant-b")
      insert_delivery!("tenant-a")

      assert Tenants.list_tenants(%{subject_id: "operator-1"}, inbound_gateway: InboundGateway) == [
               %{id: "tenant-a", label: "tenant-a"},
               %{id: "tenant-b", label: "tenant-b"},
               %{id: "tenant-c", label: "tenant-c"}
             ]
    end

    test "falls back to outbound tenants when the optional inbound gateway is unavailable" do
      insert_delivery!("tenant-a")

      assert Tenants.list_tenants(%{subject_id: "operator-1"},
               inbound_gateway: UnavailableInboundGateway
             ) == [
               %{id: "tenant-a", label: "tenant-a"}
             ]
    end
  end

  defp insert_delivery!(tenant_id) do
    now = DateTime.utc_now()

    %Delivery{}
    |> Delivery.changeset(%{
      tenant_id: tenant_id,
      mailable: "MailglassAdmin.TestMailer",
      stream: :transactional,
      recipient: "#{tenant_id}@example.com",
      provider: "postmark",
      last_event_type: :queued,
      last_event_at: now,
      metadata: %{},
      status: :queued
    })
    |> Mailglass.TestRepo.insert!()
  end
end
