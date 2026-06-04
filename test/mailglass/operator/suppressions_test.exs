defmodule Mailglass.Operator.SuppressionsTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Operator.Suppressions
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.TestRepo

  describe "get_delivery_suppression_state/2" do
    test "surfaces reason, scope, and source for matching suppression context" do
      insert_entry(%{
        tenant_id: "tenant-a",
        address: "streamed@example.com",
        scope: :address_stream,
        stream: :transactional,
        reason: :manual,
        source: "ops:review"
      })

      state =
        Suppressions.get_delivery_suppression_state(
          %{tenant_id: "tenant-a", recipient: "streamed@example.com", stream: :transactional},
          []
        )

      assert %{
               tenant_id: "tenant-a",
               address: "streamed@example.com",
               scope: :address_stream,
               stream: :transactional,
               reason: :manual,
               source: "ops:review"
             } = state
    end

    test "complaint and policy suppressions resolve to immutable state" do
      insert_entry(%{
        tenant_id: "tenant-a",
        address: "complaint@example.com",
        scope: :address,
        reason: :complaint,
        source: "webhook:auto_suppress"
      })

      complaint_state =
        Suppressions.get_delivery_suppression_state(
          %{tenant_id: "tenant-a", recipient: "complaint@example.com"},
          []
        )

      assert complaint_state.reversibility == :immutable
      assert complaint_state.reversibility_copy == "Immutable by policy"

      insert_entry(%{
        tenant_id: "tenant-a",
        address: "policy@example.com",
        scope: :address,
        reason: :policy,
        source: "compliance"
      })

      policy_state =
        Suppressions.get_delivery_suppression_state(
          %{tenant_id: "tenant-a", recipient: "policy@example.com"},
          []
        )

      assert policy_state.reversibility == :immutable
      assert policy_state.reversibility_copy == "Immutable by policy"
    end

    test "reversible suppressions are distinguishable without mutating anything" do
      delivery = %Delivery{
        tenant_id: "tenant-a",
        recipient: "reversible@example.com",
        stream: :operational
      }

      insert_entry(%{
        tenant_id: "tenant-a",
        address: "reversible@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review"
      })

      state =
        Suppressions.get_delivery_suppression_state(
          %{tenant_id: "tenant-a", delivery: delivery},
          []
        )

      assert state.reversibility == :reversible
      assert state.reversibility_copy == "Reversible in a later phase"
      refute function_exported?(Suppressions, :remove, 2)
      refute function_exported?(Suppressions, :delete, 2)
      refute function_exported?(Suppressions, :update, 2)
    end

    test "excludes foreign-tenant suppression rows" do
      insert_entry(%{
        tenant_id: "tenant-b",
        address: "foreign@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review"
      })

      assert is_nil(
               Suppressions.get_delivery_suppression_state(
                 %{tenant_id: "tenant-a", recipient: "foreign@example.com"},
                 []
               )
             )
    end
  end

  describe "count_active_suppressions/1" do
    test "returns 0 for a tenant with no suppression entries" do
      assert Suppressions.count_active_suppressions("tenant-empty") == 0
    end

    test "returns correct count for a tenant with N active entries where expires_at is nil" do
      for i <- 1..3 do
        insert_entry(%{
          tenant_id: "tenant-count",
          address: "user#{i}@example.com",
          scope: :address,
          reason: :manual,
          source: "ops:review"
        })
      end

      assert Suppressions.count_active_suppressions("tenant-count") == 3
    end

    test "excludes expired entries where expires_at is in the past" do
      past = DateTime.add(DateTime.utc_now(), -3600, :second)

      insert_entry(%{
        tenant_id: "tenant-expired",
        address: "active@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review"
      })

      insert_entry(%{
        tenant_id: "tenant-expired",
        address: "expired@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review",
        expires_at: past
      })

      assert Suppressions.count_active_suppressions("tenant-expired") == 1
    end

    test "excludes entries belonging to a different tenant_id" do
      insert_entry(%{
        tenant_id: "tenant-alpha",
        address: "alpha@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review"
      })

      insert_entry(%{
        tenant_id: "tenant-beta",
        address: "beta@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review"
      })

      assert Suppressions.count_active_suppressions("tenant-alpha") == 1
      assert Suppressions.count_active_suppressions("tenant-beta") == 1
    end

    test "counts entries with non-nil expires_at in the future as active" do
      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      insert_entry(%{
        tenant_id: "tenant-future",
        address: "future@example.com",
        scope: :address,
        reason: :manual,
        source: "ops:review",
        expires_at: future
      })

      assert Suppressions.count_active_suppressions("tenant-future") == 1
    end
  end

  defp insert_entry(attrs) do
    {:ok, entry} =
      attrs
      |> Entry.changeset()
      |> TestRepo.insert()

    entry
  end
end
