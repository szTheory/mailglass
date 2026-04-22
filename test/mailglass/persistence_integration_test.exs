defmodule Mailglass.PersistenceIntegrationTest do
  @moduledoc """
  Phase-wide integration test. Proves all 5 ROADMAP Phase 2 success
  criteria hold TOGETHER end-to-end (not just individually in per-plan
  tests).

  Success criteria from ROADMAP §Phase 2:
    1. `assert_raise EventLedgerImmutableError` on UPDATE and DELETE of
       events (SQLSTATE 45A01 immutability trigger + Mailglass.Repo
       translation).
    2. Idempotency convergence (full 1000-sequence StreamData property
       lives in Plan 05's `idempotency_convergence_test.exs`; this file
       exercises a small hand-picked replay scenario to document the
       coupling to the rest of the stack).
    3. `mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`
       each carry `tenant_id`; `Mailglass.Tenancy.SingleTenant` is the
       default no-op resolver returning `"default"` from `current/0`.
    4. `Mailglass.Events.append/1` + `append_multi/3` are the canonical
       writer surface. This test exercises both: `append/1` for a
       standalone audit write, and `append_multi/3` composed with a
       `Mailglass.Outbound.Projector.update_projections/2` follow-up
       step inside `Mailglass.Repo.transact/1` — the shape Phase 4's
       webhook handler will use.
    5. `Mailglass.Migration.up/0` is the public migration API
       (adopter-facing via `mix mailglass.gen.migration` Phase 7);
       `migrated_version/0` reports the schema version after migration.

  Also proves **multi-tenant isolation (D-09)**: two tenants each
  writing 50 rows → zero cross-tenant reads via tenant_id filtering.
  """

  use Mailglass.DataCase, async: false

  @moduletag :phase_02_uat

  import Ecto.Query

  # `migration_test.exs` DROPs + CREATEs the citext extension to prove the
  # down-then-up round-trip. Postgres assigns citext a fresh OID on the
  # re-create; Postgrex workers in the shared pool AND the shared
  # `Postgrex.TypeServer` cache retain the pre-drop OID, surfacing as
  # `(Postgrex.Error) XX000 cache lookup failed for type NNNNNN` on the
  # first citext query after migration_test runs. See deferred-items.md
  # §"Postgrex type cache stale after migration_test down-then-up" for
  # the full story and candidate fixes. The probe below covers the
  # common case where this test's sandbox checkout lands a poisoned
  # worker — `disconnect_on_error_codes: [:internal_error]` (config/test.exs)
  # makes the failing worker disconnect; the sandbox then reacquires a
  # clean one for the test body.
  setup do
    # Probe until the sandbox-owned connection survives a citext query.
    # Each failed probe triggers `disconnect_on_error_codes` and the
    # sandbox's next operation lands a freshly-reconnected worker. 5 tries
    # is more than the pool_size, covering the worst-case "every worker
    # was poisoned" scenario.
    probe_until_clean(5)
    :ok
  end

  defp probe_until_clean(0), do: :ok

  defp probe_until_clean(remaining) do
    try do
      Mailglass.TestRepo.query!(
        "SELECT address FROM mailglass_suppressions LIMIT 1",
        []
      )

      :ok
    rescue
      _ -> probe_until_clean(remaining - 1)
    end
  end

  alias Mailglass.EventLedgerImmutableError
  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Outbound.Projector
  alias Mailglass.SuppressionStore.Ecto, as: Store
  alias Mailglass.Tenancy
  alias Mailglass.TestRepo

  describe "ROADMAP §1: SQLSTATE 45A01 immutability trigger" do
    test "UPDATE on mailglass_events raises EventLedgerImmutableError through Mailglass.Repo" do
      {:ok, event} = Events.append(%{type: :queued, tenant_id: "test-tenant"})

      assert_raise EventLedgerImmutableError, fn ->
        event
        |> Ecto.Changeset.change(%{type: :delivered})
        |> Mailglass.Repo.update()
      end
    end

    test "DELETE on mailglass_events raises EventLedgerImmutableError through Mailglass.Repo" do
      {:ok, event} = Events.append(%{type: :queued, tenant_id: "test-tenant"})

      assert_raise EventLedgerImmutableError, fn ->
        Mailglass.Repo.delete(event)
      end
    end
  end

  describe "ROADMAP §2: idempotency convergence (sanity coupling — full property in Plan 05)" do
    test "applying an event twice via append/1 converges to one row" do
      key = "integration-convergence-k1"

      {:ok, first} =
        Events.append(%{type: :delivered, tenant_id: "test-tenant", idempotency_key: key})

      {:ok, second} =
        Events.append(%{type: :delivered, tenant_id: "test-tenant", idempotency_key: key})

      assert first.id == second.id

      assert [_only_one] =
               TestRepo.all(from(e in Event, where: e.idempotency_key == ^key))
    end
  end

  describe "ROADMAP §3: tenant_id on every schema + SingleTenant default" do
    test "Delivery, Event, Suppression.Entry all carry tenant_id" do
      tenant_id = "verify-tenant"

      {:ok, delivery} =
        %{
          tenant_id: tenant_id,
          mailable: "MyApp.UserMailer.welcome/1",
          stream: :transactional,
          recipient: "a@b.test",
          last_event_type: :queued,
          last_event_at: DateTime.utc_now()
        }
        |> Delivery.changeset()
        |> TestRepo.insert()

      {:ok, event} = Events.append(%{type: :queued, tenant_id: tenant_id})

      {:ok, entry} =
        Store.record(%{
          tenant_id: tenant_id,
          address: "a@b.test",
          scope: :address,
          reason: :manual,
          source: "test"
        })

      assert delivery.tenant_id == tenant_id
      assert event.tenant_id == tenant_id
      assert entry.tenant_id == tenant_id
    end

    test "SingleTenant default: current/0 returns 'default' when no stamping" do
      # Clear the DataCase-stamped tenant.
      Process.delete(:mailglass_tenant_id)
      assert Tenancy.current() == "default"
    end
  end

  describe "ROADMAP §4: Events.append/1 + append_multi/3 are the writer surface" do
    test "append_multi composes with Projector.update_projections in one transact" do
      # The Multi shape Phase 4's webhook handler will use.
      attrs = %{
        tenant_id: "test-tenant",
        mailable: "MyApp.UserMailer.confirm/1",
        stream: :transactional,
        recipient: "confirm@example.com",
        last_event_type: :queued,
        last_event_at: DateTime.utc_now()
      }

      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      now = DateTime.utc_now()

      multi =
        Ecto.Multi.new()
        |> Events.append_multi(:event, %{
          type: :delivered,
          tenant_id: "test-tenant",
          delivery_id: delivery.id,
          occurred_at: now,
          idempotency_key: "webhook:pm:integration-k1",
          raw_payload: %{"provider" => "postmark", "provider_message_id" => "pm-123"}
        })
        |> Ecto.Multi.run(:delivery_update, fn _repo, %{event: event} ->
          # Replay skip per Plan 05 moduledoc sentinel. On the happy path
          # (fresh insert), inserted_at is populated and we project.
          if is_nil(event.inserted_at) do
            {:ok, :replayed}
          else
            delivery
            |> Projector.update_projections(event)
            |> TestRepo.update()
          end
        end)

      {:ok, %{event: event, delivery_update: updated_delivery}} =
        TestRepo.transaction(multi)

      assert event.type == :delivered
      assert event.delivery_id == delivery.id

      assert %Delivery{terminal: true, delivered_at: ^now} = updated_delivery
      # Bumped by the Projector's optimistic_lock.
      assert updated_delivery.lock_version == 2
    end

    test "append/1 alone (standalone audit path) works without Multi" do
      {:ok, event} =
        Events.append(%{
          type: :queued,
          tenant_id: "test-tenant",
          metadata: %{"audit" => "admin-resync"}
        })

      assert is_binary(event.id)
      assert event.metadata == %{"audit" => "admin-resync"}
    end
  end

  describe "ROADMAP §5: migrations shipped via Mailglass.Migration" do
    test "migrated_version/0 reports the current applied version (V01)" do
      # test_helper.exs runs Mailglass.Migration.up via Ecto.Migrator.with_repo
      # at suite start, so version should be 1 when this test runs.
      assert Mailglass.Migration.migrated_version() == 1
    end
  end

  describe "Multi-tenant isolation (D-09)" do
    test "two tenants each writing 50 rows: tenant-scoped reads return only the caller's data" do
      Tenancy.put_current("tenant-a")

      for i <- 1..50 do
        {:ok, _} =
          Events.append(%{
            type: :queued,
            idempotency_key: "a-integration-#{i}"
          })
      end

      Tenancy.put_current("tenant-b")

      for i <- 1..50 do
        {:ok, _} =
          Events.append(%{
            type: :queued,
            idempotency_key: "b-integration-#{i}"
          })
      end

      # Unscoped read sees both tenants' rows — 100 total filtered to this
      # test's data by idempotency_key prefix.
      unscoped =
        TestRepo.all(
          from(e in Event,
            where:
              like(e.idempotency_key, "a-integration-%") or
                like(e.idempotency_key, "b-integration-%")
          )
        )

      assert length(unscoped) == 100

      # Scoped via explicit tenant_id filter. With the default SingleTenant
      # resolver, `Tenancy.scope/2` is a no-op; adopter resolvers inject the
      # `WHERE tenant_id = ?` clause. We simulate that explicitly here.
      scoped_a =
        TestRepo.all(
          from(e in Event,
            where:
              (like(e.idempotency_key, "a-integration-%") or
                 like(e.idempotency_key, "b-integration-%")) and
                e.tenant_id == "tenant-a"
          )
        )

      assert length(scoped_a) == 50
      assert Enum.all?(scoped_a, &(&1.tenant_id == "tenant-a"))
      refute Enum.any?(scoped_a, &(&1.tenant_id == "tenant-b"))

      scoped_b =
        TestRepo.all(
          from(e in Event,
            where:
              (like(e.idempotency_key, "a-integration-%") or
                 like(e.idempotency_key, "b-integration-%")) and
                e.tenant_id == "tenant-b"
          )
        )

      assert length(scoped_b) == 50
      assert Enum.all?(scoped_b, &(&1.tenant_id == "tenant-b"))

      # Verify the SuppressionStore also honors tenant isolation.
      {:ok, _} =
        Store.record(%{
          tenant_id: "tenant-a",
          address: "isolated@a.test",
          scope: :address,
          reason: :manual,
          source: "test"
        })

      assert :not_suppressed =
               Store.check(%{tenant_id: "tenant-b", address: "isolated@a.test"})

      assert {:suppressed, _} =
               Store.check(%{tenant_id: "tenant-a", address: "isolated@a.test"})
    end
  end
end
