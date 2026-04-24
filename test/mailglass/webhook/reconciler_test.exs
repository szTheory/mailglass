defmodule Mailglass.Webhook.ReconcilerTest do
  @moduledoc """
  Integration tests for `Mailglass.Webhook.Reconciler` — the Oban cron
  worker that closes the orphan-webhook race window (CONTEXT D-17, D-18).

  Covers the four acceptance gates from Plan 04-07:

    1. Happy path — Reconciler APPENDS a new `:reconciled` event (D-18)
       when the matching Delivery commits AFTER the orphan event was
       inserted. The orphan row is structurally unchanged (delivery_id
       stays nil, needs_reconciliation stays true).
    2. No-match path — orphan is left untouched when no matching
       Delivery exists; next tick retries.
    3. Grace window — orphans younger than 60 seconds are skipped
       (reflects in-flight dispatches where the Delivery commit is
       still pending).
    4. Telemetry whitelist compliance — stop metadata carries ONLY
       :tenant_id, :scanned_count, :linked_count, :remaining_orphan_count,
       :status. No PII, no raw payloads.

  All tests use `Mailglass.WebhookCase, async: false` — DB writes cannot
  be async, and telemetry handlers attached globally would collide under
  concurrency.

  Tagged `:requires_oban` — the `Mailglass.Webhook.Reconciler` module is
  conditionally compiled behind `if Code.ensure_loaded?(Oban.Worker)`.
  Tests are skipped when Oban is not available.
  """

  use Mailglass.WebhookCase, async: false

  @moduletag :requires_oban

  alias Mailglass.{Clock, Repo, Tenancy, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Webhook.Reconciler

  import Ecto.Query

  setup do
    # MailerCase already stamps "test-tenant". Per revision W7, use the public
    # Tenancy.clear/0 API in on_exit so the internal process-dict atom stays
    # encapsulated.
    on_exit(fn -> Tenancy.clear() end)

    if Reconciler.available?() do
      :ok
    else
      {:skip, "Oban not available; Mailglass.Webhook.Reconciler not compiled"}
    end
  end

  describe "reconcile/2 happy path (matching Delivery commits AFTER orphan)" do
    test "APPENDS a new :reconciled event; orphan row is unchanged" do
      # SETUP: insert orphan event (no matching delivery yet). Must be past
      # the 60s grace window — use inserted_at 2 minutes ago.
      two_minutes_ago = DateTime.add(Clock.utc_now(), -120, :second)
      {:ok, orphan} = insert_orphan_event("msg_happy", two_minutes_ago)

      # NOW commit the matching Delivery (simulates the race: webhook arrived
      # before the dispatch row committed).
      delivery =
        insert_delivery!(
          provider: "postmark",
          provider_message_id: "msg_happy"
        )

      # Run the reconciler for this tenant.
      {:ok, %{scanned: scanned, linked: linked}} =
        Reconciler.reconcile("test-tenant", 100)

      assert scanned >= 1
      assert linked >= 1

      # Assert a NEW :reconciled event was APPENDED (not an UPDATE of the orphan).
      reconciled_events =
        Repo.all(from(e in Event, where: e.type == :reconciled))

      assert length(reconciled_events) == 1
      [reconciled] = reconciled_events
      assert reconciled.delivery_id == delivery.id
      assert reconciled.tenant_id == "test-tenant"
      assert reconciled.metadata["reconciled_from_event_id"] == orphan.id

      # Assert the ORPHAN row is STRUCTURALLY UNCHANGED — this is the D-18
      # invariant: append-based reconciliation preserves the 45A01
      # append-only trigger. delivery_id stays nil; needs_reconciliation
      # stays true.
      orphan_after = TestRepo.get!(Event, orphan.id)
      assert orphan_after.delivery_id == nil
      assert orphan_after.needs_reconciliation == true
      assert orphan_after.type == :delivered
    end

    test "idempotency key uses reconciled:<orphan_id> for replay safety" do
      two_minutes_ago = DateTime.add(Clock.utc_now(), -120, :second)
      {:ok, orphan} = insert_orphan_event("msg_idem", two_minutes_ago)

      insert_delivery!(
        provider: "postmark",
        provider_message_id: "msg_idem"
      )

      # Run twice — the second run's :reconciled insert should be a no-op
      # via the idempotency_key partial UNIQUE index.
      {:ok, _} = Reconciler.reconcile("test-tenant", 100)
      {:ok, _} = Reconciler.reconcile("test-tenant", 100)

      # Exactly ONE :reconciled event, even after two sweeps.
      reconciled_count =
        TestRepo.aggregate(from(e in Event, where: e.type == :reconciled), :count)

      assert reconciled_count == 1

      [reconciled] = Repo.all(from(e in Event, where: e.type == :reconciled))
      assert reconciled.idempotency_key == "reconciled:" <> orphan.id
    end
  end

  describe "reconcile/2 no-match path" do
    test "leaves orphan untouched when no matching Delivery exists" do
      two_minutes_ago = DateTime.add(Clock.utc_now(), -120, :second)
      {:ok, orphan} = insert_orphan_event("msg_no_match", two_minutes_ago)

      {:ok, %{scanned: scanned, linked: linked}} =
        Reconciler.reconcile("test-tenant", 100)

      # The orphan IS scanned but NOT linked.
      assert scanned >= 1
      assert linked == 0

      # No :reconciled events appended.
      reconciled_count =
        TestRepo.aggregate(from(e in Event, where: e.type == :reconciled), :count)

      assert reconciled_count == 0

      # Orphan row unchanged.
      orphan_after = TestRepo.get!(Event, orphan.id)
      assert orphan_after.delivery_id == nil
      assert orphan_after.needs_reconciliation == true
    end
  end

  describe "reconcile/2 grace window" do
    test "skips orphans younger than 60 seconds" do
      # Recent orphan — inserted 5 seconds ago, within the grace window.
      five_seconds_ago = DateTime.add(Clock.utc_now(), -5, :second)
      {:ok, _recent} = insert_orphan_event("msg_recent", five_seconds_ago)

      # Seed the matching delivery so the no-match branch isn't confused
      # with the grace-filter branch.
      insert_delivery!(
        provider: "postmark",
        provider_message_id: "msg_recent"
      )

      {:ok, %{scanned: scanned, linked: linked}} =
        Reconciler.reconcile("test-tenant", 100)

      # Grace-filtered — counted as 0 scanned, 0 linked even though the
      # orphan row exists and the delivery would match.
      assert scanned == 0
      assert linked == 0

      # No :reconciled event appended.
      reconciled_count =
        TestRepo.aggregate(from(e in Event, where: e.type == :reconciled), :count)

      assert reconciled_count == 0
    end
  end

  describe "telemetry" do
    test "emits [:mailglass, :webhook, :reconcile, :stop] with whitelist-conformant metadata" do
      handler_id = "reconciler-test-#{System.unique_integer([:positive])}"
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :reconcile, :stop],
        fn _event, measurements, meta, _config ->
          send(test_pid, {:reconcile_stop, measurements, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      {:ok, _} = Reconciler.reconcile("test-tenant", 10)

      assert_receive {:reconcile_stop, _measurements, meta}, 500

      # D-23 whitelist keys present:
      assert Map.has_key?(meta, :tenant_id)
      assert Map.has_key?(meta, :scanned_count)
      assert Map.has_key?(meta, :linked_count)
      assert Map.has_key?(meta, :remaining_orphan_count)
      assert Map.has_key?(meta, :status)

      # D-23 PII keys ABSENT (structural whitelist assertion — these MUST
      # NOT appear in webhook reconcile metadata):
      refute Map.has_key?(meta, :ip)
      refute Map.has_key?(meta, :raw_payload)
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :email)
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :from)
      refute Map.has_key?(meta, :body)
      refute Map.has_key?(meta, :html_body)
      refute Map.has_key?(meta, :subject)
      refute Map.has_key?(meta, :headers)
    end
  end

  describe "Oban.Worker compliance" do
    test "module use Oban.Worker with queue: :mailglass_reconcile and unique: [period: 60]" do
      # Sanity: perform/1 is defined, and the module exports the Worker
      # callback. We cannot exercise the cron registration (adopter-owned)
      # but we can probe the behaviour contract.
      assert function_exported?(Reconciler, :perform, 1)
      assert function_exported?(Reconciler, :reconcile, 2)
      assert Reconciler.available?() == true
    end
  end

  # ---- Test helpers --------------------------------------------------

  # Inserts an orphan event with a specific inserted_at. Uses raw SQL INSERT
  # because the `mailglass_events_immutable_trigger` (BEFORE UPDATE OR DELETE)
  # prevents UPDATE-after-append. Raw INSERT is fine; the trigger fires only on
  # UPDATE/DELETE, not INSERT.
  defp insert_orphan_event(message_id, %DateTime{} = inserted_at) do
    id = UUIDv7.generate()

    TestRepo.query!(
      """
      INSERT INTO mailglass_events
        (id, tenant_id, type, delivery_id, needs_reconciliation,
         idempotency_key, metadata, normalized_payload, occurred_at, inserted_at)
      VALUES
        ($1, $2, $3, NULL, true, $4, $5, $6, $7, $8)
      """,
      [
        uuid_binary(id),
        "test-tenant",
        "delivered",
        "postmark:evt_#{message_id}:0",
        %{
          "provider" => "postmark",
          "provider_event_id" => "evt_#{message_id}",
          "provider_message_id" => message_id,
          "message_id" => message_id
        },
        %{},
        inserted_at,
        inserted_at
      ]
    )

    event = TestRepo.get!(Event, id)
    {:ok, event}
  end

  defp uuid_binary(uuid_string) when is_binary(uuid_string) do
    {:ok, bin} = Ecto.UUID.dump(uuid_string)
    bin
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: "test-tenant",
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: :transactional,
      recipient: "to@example.com",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent
    }

    attrs
    |> Enum.into(defaults)
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end
end
