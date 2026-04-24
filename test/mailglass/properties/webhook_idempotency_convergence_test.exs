defmodule Mailglass.Properties.WebhookIdempotencyConvergenceTest do
  @moduledoc """
  HOOK-07: any sequence of `(webhook_event, replay_count ∈ 1..10)`
  applied N times converges to the same state as applying each event
  once.

  Generates 1000 random scenarios (CONTEXT D-27 #1). The unit-of-work
  is `Mailglass.Webhook.Ingest.ingest_multi/3` (Plan 04-06), driven via
  the Postmark provider for per-request simplicity (SendGrid batch
  convergence is incidentally exercised via `provider_event_id`
  uniqueness at the UNIQUE index level).

  ## Structural invariant

  Let `U` be the set of unique `(provider, provider_event_id)` tuples
  across the generated events. The convergence invariant is:

      webhook_event_count == |U|      # after ANY replay_count

  UNIQUE `(provider, provider_event_id)` on `mailglass_webhook_events`
  (V02) enforces this at the DB level; the property test verifies the
  application code respects the constraint under every input
  distribution StreamData can produce.

  ## Test sandbox discipline

  Mirrors `Mailglass.Properties.IdempotencyConvergenceTest` (Phase 2):

    * `use ExUnit.Case, async: false` — not `DataCase` (the transaction
      wrapper deadlocks on 1000 iterations that TRUNCATE between runs).
    * `Sandbox.mode(TestRepo, :auto)` in setup; restore `:manual` on
      exit so DataCase-using siblings stay isolated.
    * `TRUNCATE ... CASCADE` between iterations (trigger blocks
      UPDATE/DELETE; TRUNCATE is the only bulk-wipe path).
  """

  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Ecto.Adapters.SQL.Sandbox
  alias Mailglass.{Tenancy, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.{Ingest, WebhookEvent}

  @moduletag :property
  @moduletag timeout: :infinity

  setup do
    Sandbox.mode(TestRepo, :auto)
    :ok = Tenancy.put_current("prop-test-tenant")

    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

    on_exit(fn ->
      TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
      Tenancy.clear()
      Sandbox.mode(TestRepo, :manual)
    end)

    :ok
  end

  # Generator: synthetic Postmark-shaped %Event{} with random RecordType
  # + MessageID + synthetic ID. STRING keys per revision W9.
  defp event_gen do
    gen all(
          record_type <- member_of(["Delivery", "Open", "Click", "SpamComplaint"]),
          msg_id <- string(:alphanumeric, min_length: 8, max_length: 24),
          event_id <- string(:alphanumeric, min_length: 8, max_length: 24)
        ) do
      type =
        case record_type do
          "Delivery" -> :delivered
          "Open" -> :opened
          "Click" -> :clicked
          "SpamComplaint" -> :complained
        end

      %Event{
        type: type,
        reject_reason: nil,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "#{record_type}:#{event_id}:2026-04-23T12:00:00Z",
          "record_type" => record_type,
          "message_id" => msg_id
        }
      }
    end
  end

  property "convergence: apply N times == apply once for any (event, replay_count) sequence" do
    check all(
            events <- list_of(event_gen(), min_length: 1, max_length: 10),
            replay_count <- integer(1..10),
            max_runs: 1000
          ) do
      # Wipe between iterations (trigger forbids UPDATE/DELETE; TRUNCATE
      # CASCADE is the only bulk-reset path).
      TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

      # Each event carries a distinct provider_event_id (the generator
      # suffixes it with event_id which is itself random), so a Postmark
      # webhook per event is the right shape. Apply each event's
      # synthetic webhook `replay_count` times.
      for event <- events, _ <- 1..replay_count do
        raw_body =
          ~s({"RecordType":"#{event.metadata["record_type"]}","MessageID":"#{event.metadata["message_id"]}"})

        {:ok, _result} = Ingest.ingest_multi(:postmark, raw_body, [event])
      end

      # Structural invariant: webhook_event_count == |unique provider_event_ids|
      unique_provider_event_ids =
        events
        |> Enum.map(& &1.metadata["provider_event_id"])
        |> Enum.uniq()
        |> length()

      webhook_event_count = TestRepo.aggregate(WebhookEvent, :count)

      assert webhook_event_count == unique_provider_event_ids,
             """
             Convergence failed!
             events: #{length(events)}
             unique provider_event_ids: #{unique_provider_event_ids}
             webhook_event_count: #{webhook_event_count}
             replay_count: #{replay_count}
             """

      # Events table: one row per unique webhook ingest (orphan path
      # inserts a mailglass_events row with delivery_id: nil even when
      # there's no matching Delivery). Replay is structurally idempotent
      # via the `idempotency_key` partial UNIQUE index on mailglass_events.
      event_count = TestRepo.aggregate(Event, :count)

      assert event_count == unique_provider_event_ids,
             """
             Event-table convergence failed!
             unique provider_event_ids: #{unique_provider_event_ids}
             event_count: #{event_count}
             replay_count: #{replay_count}
             """
    end
  end
end
