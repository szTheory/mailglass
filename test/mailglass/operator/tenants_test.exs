defmodule Mailglass.Operator.TenantsTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Generators
  alias Mailglass.Operator.Tenants
  alias Mailglass.Outbound.Delivery

  defmodule ActorTenantResolver do
    import Ecto.Query

    @behaviour Mailglass.Tenancy

    @impl true
    def scope(queryable, context) do
      if is_map(context) and is_pid(context[:test_pid]) do
        send(context[:test_pid], {:tenant_scope_context, context})
      end

      case context do
        %{tenant_id: tenant_id} when is_binary(tenant_id) and tenant_id != "" ->
          where(queryable, [delivery], delivery.tenant_id == ^tenant_id)

        _ ->
          queryable
      end
    end
  end

  setup do
    prior = Application.get_env(:mailglass, :tenancy)

    on_exit(fn ->
      Application.put_env(:mailglass, :tenancy, prior)
    end)
  end

  describe "list_tenants/2" do
    test "returns distinct tenant selector rows sorted by tenant id" do
      insert_delivery!(tenant_id: "tenant-b", recipient: "b@example.com")
      insert_delivery!(tenant_id: "tenant-a", recipient: "a@example.com")
      insert_delivery!(tenant_id: "tenant-a", recipient: "duplicate@example.com")

      assert Tenants.list_tenants(%{subject_id: "operator-1"}) == [
               %{id: "tenant-a", label: "tenant-a"},
               %{id: "tenant-b", label: "tenant-b"}
             ]
    end

    test "omits blank tenant ids from selector rows" do
      insert_delivery!(tenant_id: "tenant-a", recipient: "a@example.com")
      insert_delivery!(tenant_id: "", recipient: "blank@example.com")

      assert Tenants.list_tenants(%{subject_id: "operator-1"}) == [
               %{id: "tenant-a", label: "tenant-a"}
             ]
    end

    test "passes the actor context through Tenancy.scope/2" do
      Application.put_env(:mailglass, :tenancy, ActorTenantResolver)

      insert_delivery!(tenant_id: "tenant-a", recipient: "a@example.com")
      insert_delivery!(tenant_id: "tenant-b", recipient: "b@example.com")

      actor = %{subject_id: "operator-1", tenant_id: "tenant-a", test_pid: self()}

      assert Tenants.list_tenants(actor) == [%{id: "tenant-a", label: "tenant-a"}]
      assert_received {:tenant_scope_context, ^actor}
    end
  end

  defp insert_delivery!(opts) do
    if Keyword.get(opts, :tenant_id) == "" do
      now = Mailglass.Clock.utc_now()

      %Delivery{
        tenant_id: "",
        mailable: "Mailglass.FakeFixtures.TestMailer",
        stream: :transactional,
        recipient: Keyword.get(opts, :recipient, "fixture@example.com"),
        recipient_domain: "example.com",
        last_event_type: :queued,
        last_event_at: now,
        metadata: %{},
        status: :queued
      }
      |> Mailglass.TestRepo.insert!()
    else
      insert_valid_delivery!(opts)
    end
  end

  defp insert_valid_delivery!(opts) do
    opts
    |> Generators.delivery_fixture()
    |> case do
      %Delivery{} = delivery -> delivery
    end
  end
end
