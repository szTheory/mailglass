defmodule Mix.Tasks.Mailglass.ReconcileTest do
  use Mailglass.DataCase, async: false

  import ExUnit.CaptureIO

  alias Mailglass.{Clock, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mix.Tasks.Mailglass.Reconcile, as: ReconcileTask

  @tenant_id "reconcile-task-tenant"

  setup do
    previous = Application.get_env(:mailglass, :webhook_reconciler)

    on_exit(fn ->
      if previous do
        Application.put_env(:mailglass, :webhook_reconciler, previous)
      else
        Application.delete_env(:mailglass, :webhook_reconciler)
      end

      Mix.Task.reenable("mailglass.reconcile")
      Mix.Task.reenable("app.start")
    end)

    :ok
  end

  describe "mix mailglass.reconcile" do
    test "reports linked and still unmatched counts when Oban scheduling is available" do
      two_minutes_ago = DateTime.add(Clock.utc_now(), -120, :second)
      {:ok, _orphan} = insert_orphan_event("msg-task-linked", two_minutes_ago)

      insert_delivery!(
        tenant_id: @tenant_id,
        provider: "postmark",
        provider_message_id: "msg-task-linked"
      )

      output =
        capture_io(fn ->
          ReconcileTask.run(["--tenant-id", @tenant_id, "--batch-size", "100"])
        end)

      assert output =~ "scanned=1"
      assert output =~ "linked=1"
      assert output =~ "still_unmatched=0"
      assert output =~ "tenant=#{@tenant_id}"
      assert output =~ "Oban scheduling is available."
    end

    test "still runs through the canonical fallback path when Oban scheduling is absent" do
      Application.put_env(:mailglass, :webhook_reconciler, __MODULE__.FallbackReconciler)

      output =
        capture_io(fn ->
          ReconcileTask.run(["--tenant-id", @tenant_id, "--batch-size", "50"])
        end)

      assert output =~ "scanned=5"
      assert output =~ "linked=2"
      assert output =~ "still_unmatched=3"
      assert output =~ "tenant=#{@tenant_id}"
      assert output =~ "Oban is not installed; run this task manually or from system cron"
    end
  end

  defmodule FallbackReconciler do
    @spec available?() :: false
    def available?, do: false

    @spec reconcile(String.t() | nil, pos_integer()) ::
            {:ok, %{scanned: non_neg_integer(), linked: non_neg_integer()}}
    def reconcile("reconcile-task-tenant", 50) do
      {:ok, %{scanned: 5, linked: 2}}
    end
  end

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
        @tenant_id,
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

    {:ok, TestRepo.get!(Event, id)}
  end

  defp uuid_binary(uuid_string) when is_binary(uuid_string) do
    {:ok, bin} = Ecto.UUID.dump(uuid_string)
    bin
  end

  defp insert_delivery!(attrs) do
    attrs
    |> Enum.into(%{
      tenant_id: @tenant_id,
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: :transactional,
      recipient: "to@example.com",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent
    })
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end
end
