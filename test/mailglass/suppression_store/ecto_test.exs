defmodule Mailglass.SuppressionStore.EctoTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Suppression.Entry
  alias Mailglass.SuppressionStore.Ecto, as: Store
  alias Mailglass.TestRepo

  describe "check/2 — address scope" do
    test "returns {:suppressed, entry} when an address-scoped entry exists" do
      {:ok, entry} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "suppressed@example.com",
          scope: :address,
          reason: :manual,
          source: "admin"
        })

      assert {:suppressed, %Entry{id: found_id}} =
               Store.check(%{tenant_id: "test-tenant", address: "suppressed@example.com"})

      assert found_id == entry.id
    end

    test "case-insensitive match via citext + downcase" do
      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "CamelCase@Example.COM",
          scope: :address,
          reason: :manual,
          source: "admin"
        })

      # Check with wildly different casing.
      assert {:suppressed, _} =
               Store.check(%{tenant_id: "test-tenant", address: "camelcase@EXAMPLE.com"})
    end

    test "returns :not_suppressed when no matching entry" do
      assert :not_suppressed =
               Store.check(%{tenant_id: "test-tenant", address: "clean@example.com"})
    end
  end

  describe "check/2 — domain scope" do
    test "returns {:suppressed, entry} when domain-scoped entry matches recipient domain" do
      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "banned.test",
          scope: :domain,
          reason: :policy,
          source: "admin"
        })

      assert {:suppressed, _} =
               Store.check(%{tenant_id: "test-tenant", address: "anyone@banned.test"})
    end

    test "does NOT match non-matching recipient domains" do
      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "banned.test",
          scope: :domain,
          reason: :policy,
          source: "admin"
        })

      assert :not_suppressed =
               Store.check(%{tenant_id: "test-tenant", address: "user@allowed.test"})
    end
  end

  describe "check/2 — address_stream scope" do
    test "returns {:suppressed, entry} when scope=:address_stream + stream matches" do
      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "bulky@example.com",
          scope: :address_stream,
          stream: :bulk,
          reason: :unsubscribe,
          source: "webhook"
        })

      assert {:suppressed, _} =
               Store.check(%{
                 tenant_id: "test-tenant",
                 address: "bulky@example.com",
                 stream: :bulk
               })
    end

    test "does NOT match when stream differs" do
      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "bulky@example.com",
          scope: :address_stream,
          stream: :bulk,
          reason: :unsubscribe,
          source: "webhook"
        })

      assert :not_suppressed =
               Store.check(%{
                 tenant_id: "test-tenant",
                 address: "bulky@example.com",
                 stream: :transactional
               })
    end
  end

  describe "check/2 — tenant isolation (cross-tenant leak prevention)" do
    test "entry in tenant-a does not match queries against tenant-b" do
      {:ok, _} =
        Store.record(%{
          tenant_id: "tenant-a",
          address: "leak@example.com",
          scope: :address,
          reason: :manual,
          source: "admin"
        })

      assert :not_suppressed =
               Store.check(%{tenant_id: "tenant-b", address: "leak@example.com"})
    end
  end

  describe "check/2 — expiry" do
    test "expired entries are not returned as suppressed" do
      past = DateTime.add(DateTime.utc_now(), -3600, :second)

      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "expired@example.com",
          scope: :address,
          reason: :manual,
          source: "admin",
          expires_at: past
        })

      assert :not_suppressed =
               Store.check(%{tenant_id: "test-tenant", address: "expired@example.com"})
    end

    test "non-expired entries are returned" do
      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      {:ok, _} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "active@example.com",
          scope: :address,
          reason: :manual,
          source: "admin",
          expires_at: future
        })

      assert {:suppressed, _} =
               Store.check(%{tenant_id: "test-tenant", address: "active@example.com"})
    end
  end

  describe "record/2 — upsert on conflict" do
    test "re-adding same (tenant, address, scope, stream) updates reason/source" do
      {:ok, _first} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "repeat@example.com",
          scope: :address,
          reason: :manual,
          source: "admin-1"
        })

      {:ok, second} =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "repeat@example.com",
          scope: :address,
          reason: :complaint,
          source: "webhook:postmark"
        })

      assert second.reason == :complaint
      assert second.source == "webhook:postmark"

      # Assert only one row exists.
      assert 1 ==
               TestRepo.aggregate(
                 from(e in Entry,
                   where:
                     e.tenant_id == "test-tenant" and e.address == "repeat@example.com"
                 ),
                 :count
               )
    end
  end

  describe "record/2 — changeset errors on invalid attrs" do
    test "missing scope returns changeset with required error" do
      assert {:error, %Ecto.Changeset{valid?: false} = changeset} =
               Store.record(%{
                 tenant_id: "test-tenant",
                 address: "bad@example.com",
                 reason: :manual,
                 source: "admin"
               })

      {_msg, opts} = changeset.errors[:scope]
      assert opts[:validation] == :required
    end
  end

  describe "telemetry spans" do
    test "check/2 emits [:mailglass, :persist, :suppression, :check, :stop]" do
      handler = self()
      ref = make_ref()

      :telemetry.attach(
        "store-check-test-#{inspect(ref)}",
        [:mailglass, :persist, :suppression, :check, :stop],
        fn _event, _measurements, meta, _config -> send(handler, {ref, meta}) end,
        nil
      )

      _ = Store.check(%{tenant_id: "test-tenant", address: "irrelevant@example.com"})

      assert_receive {^ref, %{tenant_id: "test-tenant"}}, 500

      :telemetry.detach("store-check-test-#{inspect(ref)}")
    end

    test "record/2 emits [:mailglass, :persist, :suppression, :record, :stop]" do
      handler = self()
      ref = make_ref()

      :telemetry.attach(
        "store-record-test-#{inspect(ref)}",
        [:mailglass, :persist, :suppression, :record, :stop],
        fn _event, _measurements, meta, _config -> send(handler, {ref, meta}) end,
        nil
      )

      _ =
        Store.record(%{
          tenant_id: "test-tenant",
          address: "telemetered@example.com",
          scope: :address,
          reason: :manual,
          source: "test"
        })

      assert_receive {^ref, %{tenant_id: "test-tenant"}}, 500

      :telemetry.detach("store-record-test-#{inspect(ref)}")
    end
  end
end
