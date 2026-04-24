defmodule Mailglass.Webhook.PrunerTest do
  @moduledoc """
  Integration tests for `Mailglass.Webhook.Pruner` — the Oban cron
  worker that prunes `mailglass_webhook_events` rows by status + age
  (CONTEXT D-16).

  Covers the four acceptance gates from Plan 04-07:

    1. Prune `:succeeded` rows older than `succeeded_days` retention
       (default 14).
    2. Prune `:dead` rows older than `dead_days` retention (default 90).
    3. `:infinity` bypass — returns `{:ok, 0}` WITHOUT issuing the
       DELETE query.
    4. `:failed_days` defaults to `:infinity` — `:failed` rows are
       never pruned out-of-the-box (investigatable audit rows).

  All tests use `Mailglass.WebhookCase, async: false` — DB writes +
  Application env mutations cannot share the sandbox under concurrency.

  Tagged `:requires_oban` — the `Mailglass.Webhook.Pruner` module is
  conditionally compiled behind `if Code.ensure_loaded?(Oban.Worker)`.
  Tests are skipped when Oban is not available.
  """

  use Mailglass.WebhookCase, async: false

  @moduletag :requires_oban

  alias Mailglass.{Clock, Repo, Tenancy, TestRepo}
  alias Mailglass.Webhook.{Pruner, WebhookEvent}

  setup do
    on_exit(fn -> Tenancy.clear() end)

    if Pruner.available?() do
      :ok
    else
      {:skip, "Oban not available; Mailglass.Webhook.Pruner not compiled"}
    end
  end

  describe "prune/0 :succeeded retention" do
    test "deletes :succeeded rows older than the configured succeeded_days" do
      # 20-day-old :succeeded row — past default 14-day retention → deleted
      insert_webhook_event!(status: :succeeded, days_ago: 20)
      # 5-day-old :succeeded row — within retention → kept
      insert_webhook_event!(status: :succeeded, days_ago: 5)

      {:ok, %{succeeded: succeeded_count}} = Pruner.prune()

      assert succeeded_count == 1

      # Only the 5-day-old row remains.
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  describe "prune/0 :dead retention" do
    test "deletes :dead rows older than the default 90 days" do
      # 100-day-old :dead row — past 90-day default → deleted
      insert_webhook_event!(status: :dead, days_ago: 100)
      # 30-day-old :dead row — within retention → kept
      insert_webhook_event!(status: :dead, days_ago: 30)

      {:ok, %{dead: dead_count}} = Pruner.prune()

      assert dead_count == 1
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  describe "prune/0 :infinity bypass" do
    test "succeeded_days: :infinity returns {:ok, 0} without issuing the DELETE" do
      Application.put_env(:mailglass, :webhook_retention,
        succeeded_days: :infinity,
        dead_days: 90
      )

      on_exit(fn -> Application.delete_env(:mailglass, :webhook_retention) end)

      # 100-day-old :succeeded row — WOULD be pruned under default 14-day
      # retention. The :infinity knob MUST preserve it.
      insert_webhook_event!(status: :succeeded, days_ago: 100)

      {:ok, %{succeeded: succeeded_count}} = Pruner.prune()

      assert succeeded_count == 0

      # Row is preserved — :infinity bypass is structural, not a no-op query.
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end

    test "failed_days defaults to :infinity — :failed rows are never deleted" do
      # 200-day-old :failed row — default retention is :infinity → kept forever
      insert_webhook_event!(status: :failed, days_ago: 200)

      {:ok, _} = Pruner.prune()

      # Failed rows are NEVER deleted by default — investigatable audit.
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  describe "perform/1 telemetry" do
    test "emits [:mailglass, :webhook, :prune, :stop] with measurements" do
      handler_id = "pruner-test-#{System.unique_integer([:positive])}"
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :prune, :stop],
        fn _event, measurements, meta, _config ->
          send(test_pid, {:prune_stop, measurements, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      # Use the Oban perform path (not the public prune/0) so we exercise
      # the telemetry emission that the cron worker fires.
      :ok = Pruner.perform(%Oban.Job{})

      assert_receive {:prune_stop, measurements, meta}, 500

      # Measurements carry both deletion counts (D-22 measurements contract).
      assert Map.has_key?(measurements, :succeeded_deleted)
      assert Map.has_key?(measurements, :dead_deleted)

      # D-23 whitelist compliance: only :status in metadata. No PII.
      assert meta.status == :ok
      refute Map.has_key?(meta, :ip)
      refute Map.has_key?(meta, :raw_payload)
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :email)
    end
  end

  describe "prune/0 multi-status sweep" do
    test "prunes :succeeded and :dead in one run; leaves :failed untouched" do
      insert_webhook_event!(status: :succeeded, days_ago: 30)
      insert_webhook_event!(status: :dead, days_ago: 120)
      insert_webhook_event!(status: :failed, days_ago: 365)

      {:ok, %{succeeded: s, dead: d}} = Pruner.prune()

      assert s == 1
      assert d == 1

      # Only the :failed row survives (default :infinity retention).
      [remaining] = Repo.all(WebhookEvent)
      assert remaining.status == :failed
    end
  end

  # ---- Test helpers --------------------------------------------------

  defp insert_webhook_event!(opts) do
    status = Keyword.fetch!(opts, :status)
    days_ago = Keyword.get(opts, :days_ago, 0)
    backdated_at = DateTime.add(Clock.utc_now(), -days_ago * 86_400, :second)

    attrs = %{
      tenant_id: "test-tenant",
      provider: "postmark",
      provider_event_id: "evt_#{System.unique_integer([:positive])}",
      event_type_raw: "Delivery",
      event_type_normalized: "delivered",
      status: status,
      raw_payload: %{},
      received_at: backdated_at
    }

    attrs
    |> WebhookEvent.changeset()
    |> Ecto.Changeset.put_change(:inserted_at, backdated_at)
    |> Ecto.Changeset.put_change(:updated_at, backdated_at)
    |> TestRepo.insert!()
  end
end
