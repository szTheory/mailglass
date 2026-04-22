defmodule Mailglass.Outbound.DeliveryTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Outbound.Delivery
  alias Mailglass.TestRepo

  describe "changeset/1" do
    test "requires tenant_id, mailable, stream, recipient, last_event_type, last_event_at" do
      changeset = Delivery.changeset(%{})
      refute changeset.valid?

      for field <- [:tenant_id, :mailable, :stream, :recipient, :last_event_type, :last_event_at] do
        assert {_, [validation: :required]} = changeset.errors[field]
      end
    end

    test "populates recipient_domain from recipient" do
      attrs = valid_attrs(%{recipient: "alice@Example.COM"})
      changeset = Delivery.changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :recipient_domain) == "example.com"
    end

    test "rejects unknown stream" do
      attrs = valid_attrs(%{stream: :marketing})
      changeset = Delivery.changeset(attrs)

      refute changeset.valid?
      {msg, opts} = changeset.errors[:stream]
      assert msg == "is invalid"
      assert opts[:validation] == :inclusion
      assert is_list(opts[:enum])
    end

    test "rejects unknown last_event_type" do
      attrs = valid_attrs(%{last_event_type: :teleported})
      changeset = Delivery.changeset(attrs)

      refute changeset.valid?
      {msg, opts} = changeset.errors[:last_event_type]
      assert msg == "is invalid"
      assert opts[:validation] == :inclusion
      assert is_list(opts[:enum])
    end
  end

  describe "round-trip" do
    test "inserts and reloads with all 8 projection columns null-or-typed" do
      attrs = valid_attrs(%{})
      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      reloaded = TestRepo.get!(Delivery, delivery.id)
      # Ecto.Enum coerces back to atom
      assert reloaded.stream == :transactional
      assert reloaded.last_event_type == :queued
      assert reloaded.terminal == false
      assert reloaded.lock_version == 1
      assert is_nil(reloaded.dispatched_at)
      assert is_nil(reloaded.delivered_at)
      assert is_nil(reloaded.bounced_at)
      assert is_nil(reloaded.complained_at)
      assert is_nil(reloaded.suppressed_at)
      assert reloaded.metadata == %{}
    end

    test "optimistic_lock bumps lock_version on update" do
      attrs = valid_attrs(%{})
      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      {:ok, bumped} =
        delivery
        |> Ecto.Changeset.change(%{terminal: true})
        |> Ecto.Changeset.optimistic_lock(:lock_version)
        |> TestRepo.update()

      assert bumped.lock_version == 2
    end

    test "stale update raises Ecto.StaleEntryError" do
      attrs = valid_attrs(%{})
      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      stale = %{delivery | lock_version: 99}

      assert_raise Ecto.StaleEntryError, fn ->
        stale
        |> Ecto.Changeset.change(%{terminal: true})
        |> Ecto.Changeset.optimistic_lock(:lock_version)
        |> TestRepo.update()
      end
    end
  end

  describe "reflection" do
    test "__event_types__/0 and __streams__/0 return the closed atom sets" do
      assert :queued in Delivery.__event_types__()
      assert :dispatched in Delivery.__event_types__()
      assert :suppressed in Delivery.__event_types__()
      assert Delivery.__streams__() == [:transactional, :operational, :bulk]
    end
  end

  defp valid_attrs(overrides) do
    Map.merge(
      %{
        tenant_id: "test-tenant",
        mailable: "MyApp.UserMailer.welcome/1",
        stream: :transactional,
        recipient: "user@example.com",
        last_event_type: :queued,
        last_event_at: DateTime.utc_now()
      },
      overrides
    )
  end
end
