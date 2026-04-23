defmodule Mailglass.Events.ReconcilerTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events
  alias Mailglass.Events.Reconciler
  alias Mailglass.Outbound.Delivery
  alias Mailglass.TestRepo

  describe "find_orphans/1" do
    test "returns events with needs_reconciliation=true AND delivery_id IS NULL" do
      {:ok, _orphan} =
        Events.append(%{
          type: :delivered,
          tenant_id: "test-tenant",
          needs_reconciliation: true,
          metadata: %{"provider" => "postmark", "provider_message_id" => "pm-1"},
          idempotency_key: "idem-orphan-1"
        })

      {:ok, _not_orphan_linked} =
        Events.append(%{
          type: :delivered,
          tenant_id: "test-tenant",
          delivery_id: Ecto.UUID.generate(),
          needs_reconciliation: false,
          idempotency_key: "idem-linked-1"
        })

      orphans = Reconciler.find_orphans(tenant_id: "test-tenant")

      assert length(orphans) == 1
      assert hd(orphans).idempotency_key == "idem-orphan-1"
    end

    test "scopes by tenant_id when passed" do
      {:ok, _} = Events.append(orphan_attrs(tenant_id: "tenant-a", key: "a-1"))
      {:ok, _} = Events.append(orphan_attrs(tenant_id: "tenant-b", key: "b-1"))

      assert [%{tenant_id: "tenant-a"}] = Reconciler.find_orphans(tenant_id: "tenant-a")
      assert [%{tenant_id: "tenant-b"}] = Reconciler.find_orphans(tenant_id: "tenant-b")
    end

    test "respects :limit option" do
      for i <- 1..5, do: Events.append(orphan_attrs(tenant_id: "test-tenant", key: "k-#{i}"))

      assert length(Reconciler.find_orphans(tenant_id: "test-tenant", limit: 3)) == 3
    end

    test "excludes orphans older than :max_age_minutes" do
      # Insert a fresh orphan via the normal path.
      {:ok, _orphan} = Events.append(orphan_attrs(tenant_id: "test-tenant", key: "old-1"))

      # The trigger only catches UPDATE/DELETE — we can INSERT with any timestamp.
      # Use raw SQL to seed a 10-day-old row.
      TestRepo.query!(
        """
        INSERT INTO mailglass_events
          (id, tenant_id, type, occurred_at, needs_reconciliation,
           normalized_payload, metadata, inserted_at, idempotency_key)
        VALUES
          ($1, 'test-tenant', 'delivered', now() - interval '10 days', true,
           '{}', '{}', now() - interval '10 days', 'old-inserted')
        """,
        [uuid_binary()]
      )

      # Default max_age_minutes = 7 days — 10-day-old orphan excluded.
      # The original (fresh) orphan is returned.
      orphans = Reconciler.find_orphans(tenant_id: "test-tenant")

      assert Enum.any?(orphans, &(&1.idempotency_key == "old-1"))
      refute Enum.any?(orphans, &(&1.idempotency_key == "old-inserted"))
    end

    test "orders oldest first" do
      {:ok, _first} = Events.append(orphan_attrs(tenant_id: "test-tenant", key: "first"))
      Process.sleep(5)
      {:ok, _second} = Events.append(orphan_attrs(tenant_id: "test-tenant", key: "second"))

      orphans = Reconciler.find_orphans(tenant_id: "test-tenant")
      keys = Enum.map(orphans, & &1.idempotency_key)

      # first was inserted before second
      assert Enum.find_index(keys, &(&1 == "first")) <
               Enum.find_index(keys, &(&1 == "second"))
    end
  end

  describe "attempt_link/2" do
    test "returns {:ok, {delivery, event}} when delivery exists with matching (provider, provider_message_id)" do
      # Create a delivery with a specific provider + message id.
      attrs = %{
        tenant_id: "test-tenant",
        mailable: "MyApp.Mailer.welcome/1",
        stream: :transactional,
        recipient: "user@example.com",
        provider: "postmark",
        provider_message_id: "pm-abc",
        last_event_type: :dispatched,
        last_event_at: DateTime.utc_now()
      }

      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      # And an orphan event referencing the same (provider, message_id).
      {:ok, orphan} =
        Events.append(%{
          type: :delivered,
          tenant_id: "test-tenant",
          needs_reconciliation: true,
          metadata: %{"provider" => "postmark", "provider_message_id" => "pm-abc"},
          idempotency_key: "link-test"
        })

      assert {:ok, {%Delivery{id: did}, %{idempotency_key: "link-test"}}} =
               Reconciler.attempt_link(orphan)

      assert did == delivery.id
    end

    test "returns {:error, :delivery_not_found} when no matching delivery exists" do
      {:ok, orphan} =
        Events.append(%{
          type: :delivered,
          tenant_id: "test-tenant",
          needs_reconciliation: true,
          metadata: %{"provider" => "sendgrid", "provider_message_id" => "sg-nonexistent"},
          idempotency_key: "nomatch"
        })

      assert {:error, :delivery_not_found} = Reconciler.attempt_link(orphan)
    end

    test "returns {:error, :malformed_payload} when provider/message_id is missing" do
      {:ok, orphan} =
        Events.append(%{
          type: :delivered,
          tenant_id: "test-tenant",
          needs_reconciliation: true,
          metadata: %{"other" => "field"},
          idempotency_key: "malformed"
        })

      assert {:error, :malformed_payload} = Reconciler.attempt_link(orphan)
    end

    test "falls back to normalized_payload when metadata lacks provider/message_id" do
      # Phase 4 V02 migration dropped `raw_payload` from the ledger (D-15).
      # Reconciler.extract/2 now reads :metadata first, then falls back to
      # :normalized_payload. Raw provider bytes live in
      # `mailglass_webhook_events` — the ledger never needs them.
      attrs = %{
        tenant_id: "test-tenant",
        mailable: "MyApp.Mailer.welcome/1",
        stream: :transactional,
        recipient: "user@example.com",
        provider: "postmark",
        provider_message_id: "normalized-msg",
        last_event_type: :dispatched,
        last_event_at: DateTime.utc_now()
      }

      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      {:ok, orphan} =
        Events.append(%{
          type: :delivered,
          tenant_id: "test-tenant",
          needs_reconciliation: true,
          metadata: %{},
          normalized_payload: %{
            "provider" => "postmark",
            "provider_message_id" => "normalized-msg"
          },
          idempotency_key: "from-normalized"
        })

      assert {:ok, {%Delivery{id: delivery_id}, _}} = Reconciler.attempt_link(orphan)
      assert delivery_id == delivery.id
    end
  end

  defp orphan_attrs(opts) do
    tenant_id = Keyword.get(opts, :tenant_id, "test-tenant")
    key = Keyword.get(opts, :key, "orphan-#{System.unique_integer([:positive])}")

    %{
      type: :delivered,
      tenant_id: tenant_id,
      needs_reconciliation: true,
      metadata: %{"provider" => "postmark", "provider_message_id" => "pm-#{key}"},
      idempotency_key: key
    }
  end

  defp uuid_binary do
    {:ok, bin} = Ecto.UUID.dump(Ecto.UUID.generate())
    bin
  end
end
