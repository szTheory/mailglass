defmodule Mailglass.Outbound.PayloadLifecycleTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.{Clock, Generators, Message}
  alias Mailglass.Outbound.{Envelope, Payload, PayloadLifecycle, PayloadPruner}

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

  @tag phase_151_task: "t151_05_01"
  test "defines finite exact retention and fail-closed recovery eligibility" do
    now = ~U[2026-08-03 00:00:00.000000Z]
    Process.put(:mailglass_clock_frozen_at, now)
    on_exit(fn -> Process.delete(:mailglass_clock_frozen_at) end)

    assert PayloadLifecycle.retention_days(:terminal) == 14
    assert PayloadLifecycle.retention_days(:discarded) == 14
    assert PayloadLifecycle.retention_days(:abandoned) == 14
    assert PayloadLifecycle.retention_days(:uncertain) == 30
    assert PayloadLifecycle.retention_days(:legacy) == 14
    assert PayloadLifecycle.retention_days(:recoverable) == nil
    assert PayloadLifecycle.expires_at(:terminal) == DateTime.add(Clock.utc_now(), 14 * 86_400, :second)

    assert PayloadLifecycle.recovery_eligibility(%Payload{lifecycle_state: :recoverable, expires_at: DateTime.add(now, 1, :second)}) == :claimable
    assert PayloadLifecycle.recovery_eligibility(%Payload{lifecycle_state: :dispatching}) == :uncertain
    assert PayloadLifecycle.recovery_eligibility(%Payload{lifecycle_state: :legacy}) == :legacy_unavailable
    assert PayloadLifecycle.recovery_eligibility(%Payload{lifecycle_state: :scrubbed}) == :unavailable
    assert PayloadLifecycle.recovery_eligibility(%Payload{lifecycle_state: :expired}) == :unavailable
    assert {:error, :tenant_required} = PayloadPruner.prune([])
    assert {:error, :tenant_required} = PayloadPruner.prune(tenant_id: "  ")
  end
end
