defmodule Mailglass.WebhookCaseTest do
  use Mailglass.WebhookCase, async: false

  alias Mailglass.Repo
  alias Mailglass.Outbound.Delivery

  describe "webhook assertions" do
    setup do
      # single_event.json has sg_message_id = "00000000-0000-0000-0000-000000000010"
      delivery = 
        %{
          id: "00000000-0000-0000-0000-000000000010",
          tenant_id: "test",
          provider: :sendgrid,
          adapter_ref: "00000000-0000-0000-0000-000000000010",
          mailable: "Test",
          stream: :transactional,
          recipient: "user@example.com",
          status: :queued,
          last_event_type: :queued,
          last_event_at: Mailglass.Clock.utc_now()
        }
        |> Delivery.changeset()
        |> Mailglass.TestRepo.insert!()

      {:ok, delivery: delivery}
    end

    test "assert_webhook_processed dispatches and verifies ingest", %{delivery: delivery, sendgrid_keypair: _} do
      conn = assert_webhook_processed(:sendgrid, "single_event")
      
      assert conn.status in 200..299
      assert_delivery_state(delivery.id, :delivered)
    end
    
    test "assert_webhook_idempotent processes twice without duplicates", %{delivery: delivery, sendgrid_keypair: _} do
      assert_webhook_idempotent(:sendgrid, "single_event")
      
      assert_delivery_event_count(delivery.id, 1)
    end
  end
end
