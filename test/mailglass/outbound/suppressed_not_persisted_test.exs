defmodule Mailglass.Outbound.SuppressedNotPersistedTest do
  @moduledoc """
  Answers, from code, whether "Not sent" is ever a persisted `Delivery.status
  :suppressed` row. It is not.

  Not sent is a pre-send block only:

    * `send/2` and `deliver_later/2` run `Mailglass.Outbound.Preflight`, which calls
      `Mailglass.Suppression` before any insert. A suppressed address returns
      `{:error, %Mailglass.SuppressedError{}}` and emits
      `[:mailglass, :suppression, :pre_send_blocked, :stop]`. Nothing is written.
    * `deliver_many/2` builds an in-memory `%Delivery{status: :failed}` through
      `Mailglass.Outbound.Persistence.build_failed_delivery/2`. It is returned in the
      result list and never inserted.
    * No library code writes `Delivery.status :suppressed`; the enum member and the
      `:suppressed` event type are reserved and dormant.

  So a suppressed send leaves zero Delivery rows and zero Event rows, and a
  send-time `:failed` reads Failed, never Not sent. Each entry point is asserted
  against a before/after count, and a positive control proves the same counting
  sees a row and an event for an address that is not suppressed, so the zeros are
  not vacuous.
  """

  use Mailglass.DataCase, async: false

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.{Message, Outbound, TestRepo}
  alias Mailglass.Outbound.Delivery

  @tenant "test-tenant"

  setup do
    Mailglass.Adapters.Fake.checkout()
    Mailglass.Adapters.Fake.set_shared(self())
    Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)
    :ok
  end

  describe "a suppressed address persists nothing" do
    test "send/2 returns SuppressedError and leaves no Delivery and no Event" do
      addr = suppressed_address("send")
      before_counts = counts(addr)

      assert {:error, %Mailglass.SuppressedError{}} = Outbound.send(build_message(addr))

      assert counts(addr) == before_counts
    end

    test "deliver_later/2 returns SuppressedError and leaves no Delivery and no Event" do
      addr = suppressed_address("later")
      before_counts = counts(addr)

      assert {:error, %Mailglass.SuppressedError{}} = Outbound.deliver_later(build_message(addr))

      assert counts(addr) == before_counts
    end

    test "deliver_many/2 returns an in-memory :failed Delivery that is never inserted" do
      addr = suppressed_address("many")
      before_counts = counts(addr)

      assert {:ok, [%Delivery{status: :failed} = delivery]} =
               Outbound.deliver_many([build_message(addr)], [])

      assert delivery.recipient == addr
      assert delivery.last_error != nil
      refute TestRepo.get(Delivery, delivery.id)
      assert counts(addr) == before_counts
    end
  end

  describe "positive control" do
    test "send/2 to an address that is not suppressed adds a Delivery and an Event" do
      addr = "allowed-#{unique_id()}@example.com"
      before_counts = counts(addr)

      assert {:ok, %Delivery{}} = Outbound.send(build_message(addr))

      after_counts = counts(addr)
      assert after_counts.deliveries == before_counts.deliveries + 1
      assert after_counts.events > before_counts.events
    end
  end

  # -- helpers ------------------------------------------------------------------

  # Delivery rows for this recipient, and every Event row for the tenant.
  defp counts(addr) do
    %{
      deliveries: TestRepo.aggregate(from(d in Delivery, where: d.recipient == ^addr), :count),
      events: TestRepo.aggregate(from(e in Event, where: e.tenant_id == ^@tenant), :count)
    }
  end

  defp suppressed_address(label) do
    addr = "suppressed-#{label}-#{unique_id()}@example.com"
    {:ok, _entry} = insert_suppression!(addr)
    addr
  end

  defp unique_id, do: System.unique_integer([:positive])

  defp build_message(to_addr) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to(to_addr)
      |> Swoosh.Email.subject("Suppression persistence proof")
      |> Swoosh.Email.html_body("<p>Test body</p>")
      |> Swoosh.Email.text_body("Test body")

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: @tenant,
      stream: :transactional
    )
  end

  defp insert_suppression!(address) do
    attrs = %{
      tenant_id: @tenant,
      address: address,
      scope: :address,
      reason: :manual,
      source: "test"
    }

    insert_suppression!(attrs, 4)
  end

  defp insert_suppression!(attrs, attempts_left) when attempts_left > 0 do
    try do
      attrs
      |> Mailglass.Suppression.Entry.changeset()
      |> TestRepo.insert()
    rescue
      Postgrex.Error ->
        Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)

        if attempts_left > 1 do
          insert_suppression!(attrs, attempts_left - 1)
        else
          attrs
          |> Mailglass.Suppression.Entry.changeset()
          |> TestRepo.insert()
        end
    end
  end
end
