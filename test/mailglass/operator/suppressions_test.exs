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

  defp insert_entry(attrs) do
    {:ok, entry} =
      attrs
      |> Entry.changeset()
      |> TestRepo.insert()

    entry
  end
end
