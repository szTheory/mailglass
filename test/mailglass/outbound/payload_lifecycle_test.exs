defmodule Mailglass.Outbound.PayloadLifecycleTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.{Generators, Message}
  alias Mailglass.Outbound.{Envelope, Payload}

  @moduletag phase_151_task: "t151_04_01"

  test "claims a recoverable tenant payload exactly once" do
    delivery = Generators.delivery_fixture(tenant_id: "test-tenant")

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from("from@example.com")
      |> Swoosh.Email.to("to@example.com")
      |> Swoosh.Email.subject("payload lifecycle")
      |> Swoosh.Email.text_body("private body")

    assert {:ok, envelope} =
             Envelope.dump(Message.build(email, tenant_id: "test-tenant"),
               adapter_ref: "__default__"
             )

    assert {:ok, _payload} =
             Payload.from_envelope("test-tenant", delivery.id, envelope)
             |> Mailglass.TestRepo.insert()

    assert {:ok, claimed} = Payload.claim("test-tenant", delivery.id)
    assert claimed.lifecycle_state == :dispatching
    assert claimed.reason_class == :dispatch_claimed
    assert {:error, :already_dispatching} = Payload.claim("test-tenant", delivery.id)
  end
end
