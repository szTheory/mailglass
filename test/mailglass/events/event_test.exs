defmodule Mailglass.Events.EventTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events.Event
  alias Mailglass.TestRepo

  describe "changeset/1" do
    test "requires tenant_id, type, occurred_at" do
      changeset = Event.changeset(%{})
      refute changeset.valid?
      assert {_, [validation: :required]} = changeset.errors[:tenant_id]
      assert {_, [validation: :required]} = changeset.errors[:type]
      assert {_, [validation: :required]} = changeset.errors[:occurred_at]
    end

    test "rejects unknown type" do
      attrs = valid_attrs(%{type: :teleported})
      changeset = Event.changeset(attrs)
      refute changeset.valid?
      {msg, opts} = changeset.errors[:type]
      assert msg == "is invalid"
      assert opts[:validation] == :inclusion
      assert is_list(opts[:enum])
    end

    test "accepts nil delivery_id for orphan webhooks" do
      attrs = valid_attrs(%{delivery_id: nil, needs_reconciliation: true})
      changeset = Event.changeset(attrs)
      assert changeset.valid?
    end

    test "accepts all Anymail + internal event types" do
      for type <- Event.__types__() do
        attrs = valid_attrs(%{type: type})
        assert Event.changeset(attrs).valid?, "expected #{inspect(type)} to be accepted"
      end
    end
  end

  describe "round-trip" do
    test "inserts and reloads with type as atom" do
      attrs = valid_attrs(%{type: :delivered, idempotency_key: "provider:msg:abc123"})
      {:ok, event} = attrs |> Event.changeset() |> TestRepo.insert()

      reloaded = TestRepo.get!(Event, event.id)
      assert reloaded.type == :delivered
      assert reloaded.idempotency_key == "provider:msg:abc123"
      assert reloaded.needs_reconciliation == false
      assert reloaded.normalized_payload == %{}
      assert reloaded.metadata == %{}
    end

    test "inserted_at is populated server-side" do
      attrs = valid_attrs(%{})
      {:ok, event} = attrs |> Event.changeset() |> TestRepo.insert()

      assert %DateTime{} = event.inserted_at
    end
  end

  describe "reflection" do
    test "__types__/0 includes Anymail taxonomy + mailglass internal" do
      types = Event.__types__()
      # Anymail
      assert :queued in types
      assert :delivered in types
      assert :bounced in types
      assert :unknown in types
      # Mailglass-internal
      assert :dispatched in types
      assert :suppressed in types
    end

    test "__reject_reasons__/0 returns the closed set" do
      assert Event.__reject_reasons__() ==
               [:invalid, :bounced, :timed_out, :blocked, :spam, :unsubscribed, :other]
    end
  end

  defp valid_attrs(overrides) do
    Map.merge(
      %{
        tenant_id: "test-tenant",
        type: :queued,
        occurred_at: DateTime.utc_now(),
        raw_payload: %{},
        normalized_payload: %{},
        metadata: %{}
      },
      overrides
    )
  end
end
