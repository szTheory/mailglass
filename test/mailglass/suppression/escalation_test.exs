defmodule Mailglass.Suppression.EscalationTest do
  use Mailglass.DataCase, async: false

  if Code.ensure_loaded?(Oban.Testing) do
    use Oban.Testing, repo: Mailglass.TestRepo
  end

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.TestRepo

  @tenant_id "soft-bounce-tenant"
  @recipient "bouncey@example.com"

  describe "availability" do
    test "is only compiled when Oban.Worker is loaded" do
      assert Code.ensure_loaded?(Mailglass.Suppression.Escalation) ==
               Code.ensure_loaded?(Oban.Worker)
    end
  end

  if Code.ensure_loaded?(Oban.Worker) do
    describe "enqueue/2" do
      @tag oban: :manual
      test "routes job insertion through the optional dependency gateway" do
        source = File.read!("lib/mailglass/suppression/escalation.ex")

        refute source =~ "Oban.insert("
        assert source =~ "Mailglass.OptionalDeps.Oban.insert"

        multi =
          Ecto.Multi.new()
          |> Mailglass.Suppression.Escalation.enqueue(%{
            tenant_id: @tenant_id,
            recipient: @recipient
          })

        assert {:ok, _changes} = TestRepo.transaction(multi)

        assert_enqueued(
          worker: Mailglass.Suppression.Escalation,
          queue: :mailglass_suppression_escalation
        )
      end
    end

    describe "evaluate/2" do
      test "inserts no suppression below the default threshold" do
        insert_deferred_events(4)

        assert {:ok, :below_threshold} =
                 Mailglass.Suppression.Escalation.evaluate(@tenant_id, @recipient)

        assert [] = suppressions_for(@recipient)
      end

      test "inserts a distinguishable suppression at the default threshold" do
        insert_deferred_events(5)

        assert {:ok, %Entry{} = entry} =
                 Mailglass.Suppression.Escalation.evaluate(@tenant_id, @recipient)

        assert entry.scope == :address
        assert entry.reason == :hard_bounce
        assert entry.source == "webhook:soft_bounce_escalation"
        assert entry.expires_at == nil
        assert entry.metadata["threshold"] == 5
        assert entry.metadata["window_days"] == 7
        assert entry.metadata["action"] == "hard_suppress"
      end
    end
  end

  defp insert_deferred_events(count) do
    delivery =
      %{
        tenant_id: @tenant_id,
        mailable: "Mailglass.TestMailer.soft_bounce",
        stream: :transactional,
        recipient: @recipient,
        last_event_type: :deferred,
        last_event_at: ~U[2026-04-28 12:00:00Z],
        metadata: %{}
      }
      |> Delivery.changeset()
      |> TestRepo.insert!()

    Enum.each(1..count, fn idx ->
      occurred_at = DateTime.add(~U[2026-04-28 12:00:00Z], -idx, :day)

      %{
        tenant_id: @tenant_id,
        delivery_id: delivery.id,
        type: :deferred,
        occurred_at: occurred_at,
        metadata: %{"provider" => "postmark", "provider_event_id" => "evt-#{idx}"}
      }
      |> Event.changeset()
      |> TestRepo.insert!()
    end)
  end

  defp suppressions_for(recipient) do
    Entry
    |> where([entry], entry.tenant_id == ^@tenant_id and entry.address == ^recipient)
    |> TestRepo.all()
  end
end
