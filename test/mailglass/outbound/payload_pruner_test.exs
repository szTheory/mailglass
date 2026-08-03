defmodule Mailglass.Outbound.PayloadPrunerTest do
  use Mailglass.DataCase, async: false

  import ExUnit.CaptureIO

  alias Mailglass.{Generators, Message, Tenancy, TestRepo}
  alias Mailglass.Outbound.{Envelope, Payload}

  @moduletag phase_151_task: "t151_06_01"

  test "manual pruning requires one nonblank tenant and emits only aggregate state and reason counts" do
    assert_raise Mix.Error, ~r/--tenant/, fn ->
      Mix.Tasks.Mailglass.Outbound.Payloads.Prune.run([])
    end

    assert_raise Mix.Error, ~r/--tenant/, fn ->
      Mix.Tasks.Mailglass.Outbound.Payloads.Prune.run(["--tenant", "   "])
    end

    tenant_id = "prune-tenant-a"
    private_sentinel = "private-prune-sentinel@example.com"
    payload = expired_payload!(tenant_id, private_sentinel)

    Mix.Task.reenable("mailglass.outbound.payloads.prune")

    output =
      capture_io(fn ->
        Mix.Tasks.Mailglass.Outbound.Payloads.Prune.run(["--tenant", tenant_id])
      end)

    assert TestRepo.get!(Payload, payload.id).lifecycle_state == :expired
    assert output =~ "expired=1"
    assert output =~ "retention_expired=1"
    refute output =~ tenant_id
    refute output =~ private_sentinel
  end

  test "manual pruning performs one tenant-scoped batch and leaves other tenants untouched" do
    previous = Application.get_env(:mailglass, :config)

    on_exit(fn -> Application.put_env(:mailglass, :config, previous) end)

    Application.put_env(:mailglass, :config,
      outbound_payload_retention: [terminal_days: 14, uncertain_days: 30, legacy_days: 14, prune_batch_size: 1]
    )

    tenant_a = "prune-tenant-a"
    tenant_b = "prune-tenant-b"
    first = expired_payload!(tenant_a, "first-private@example.com")
    second = expired_payload!(tenant_a, "second-private@example.com")
    other = expired_payload!(tenant_b, "other-private@example.com")

    Mix.Task.reenable("mailglass.outbound.payloads.prune")
    Mix.Tasks.Mailglass.Outbound.Payloads.Prune.run(["--tenant", tenant_a])

    states = Enum.map([first, second], &TestRepo.get!(Payload, &1.id).lifecycle_state)
    assert Enum.count(states, &(&1 == :expired)) == 1
    assert TestRepo.get!(Payload, other.id).lifecycle_state == :terminal
  end

  test "scheduled worker uses the maintenance queue and same tenant-explicit batch" do
    if Code.ensure_loaded?(Oban.Worker) do
      assert Mailglass.Outbound.PayloadPrunerWorker.available?()
      assert Mailglass.Outbound.PayloadPrunerWorker.__opts__()[:queue] == :mailglass_maintenance

      tenant_id = "scheduled-prune-tenant"
      payload = expired_payload!(tenant_id, "scheduled-private@example.com")

      assert :ok =
               Mailglass.Outbound.PayloadPrunerWorker.perform(%Oban.Job{
                 args: %{"mailglass_tenant_id" => tenant_id}
               })

      assert TestRepo.get!(Payload, payload.id).lifecycle_state == :expired
    else
      refute Mailglass.Outbound.PayloadPrunerWorker.available?()
    end
  end

  defp expired_payload!(tenant_id, recipient) do
    Tenancy.with_tenant(tenant_id, fn ->
      delivery = Generators.delivery_fixture(tenant_id: tenant_id)

      email =
        Swoosh.Email.new()
        |> Swoosh.Email.from("from@example.com")
        |> Swoosh.Email.to(recipient)
        |> Swoosh.Email.subject("private prune subject")
        |> Swoosh.Email.text_body("private prune body")

      {:ok, envelope} =
        Envelope.dump(Message.build(email, tenant_id: tenant_id), adapter_ref: "__default__")

      {:ok, payload} =
        Payload.from_envelope(tenant_id, delivery.id, envelope)
        |> Ecto.Changeset.change(%{
          lifecycle_state: :terminal,
          reason_class: :pre_dispatch_failure,
          expires_at: DateTime.add(DateTime.utc_now(), -1, :second)
        })
        |> TestRepo.insert()

      payload
    end)
  end
end
