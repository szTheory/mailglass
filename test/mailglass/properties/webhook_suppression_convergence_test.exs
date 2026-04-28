defmodule Mailglass.Properties.WebhookSuppressionConvergenceTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Ecto.Adapters.SQL.Sandbox
  alias Mailglass.{Clock, Tenancy, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.Webhook.Ingest

  @moduletag :property
  @moduletag timeout: :infinity

  setup do
    Sandbox.mode(TestRepo, :auto)
    :ok = Tenancy.put_current("prop-test-tenant")

    reset_tables!()

    on_exit(fn ->
      reset_tables!()
      Tenancy.clear()
      Sandbox.mode(TestRepo, :manual)
    end)

    :ok
  end

  property "duplicate webhook replays converge on the distinct suppression-causing event set" do
    check all(
            event_specs <- list_of(event_spec_gen(), min_length: 1, max_length: 8),
            replay_count <- integer(1..5),
            max_runs: 150
          ) do
      reset_tables!()

      Enum.each(event_specs, fn spec ->
        insert_delivery!(spec)
      end)

      expected_count =
        event_specs
        |> Enum.filter(&suppression_causing?/1)
        |> Enum.map(&expected_key/1)
        |> Enum.uniq()
        |> length()

      for spec <- event_specs, _ <- 1..replay_count do
        {:ok, _result} = Ingest.ingest_multi(:postmark, raw_body_for(spec), [event_for(spec)])
      end

      assert TestRepo.aggregate(Entry, :count) == expected_count
    end
  end

  defp event_spec_gen do
    gen all(
          suffix <- string(:alphanumeric, min_length: 6, max_length: 12),
          type <- member_of([:complained, :unsubscribed, :bounced, :deferred]),
          stream <- member_of([:transactional, :operational, :bulk])
        ) do
      %{suffix: suffix, type: type, stream: stream}
    end
  end

  defp expected_key(%{suffix: suffix, type: :complained}) do
    {"recipient-#{suffix}@example.com", :address, nil, :complaint}
  end

  defp expected_key(%{suffix: suffix, type: :unsubscribed, stream: stream}) do
    {"recipient-#{suffix}@example.com", :address_stream, stream, :unsubscribe}
  end

  defp expected_key(%{suffix: suffix, type: :bounced}) do
    {"recipient-#{suffix}@example.com", :address, nil, :hard_bounce}
  end

  defp suppression_causing?(%{type: type}), do: type in [:complained, :unsubscribed, :bounced]

  defp raw_body_for(%{suffix: suffix, type: :complained}) do
    ~s({"RecordType":"SpamComplaint","MessageID":"msg_#{suffix}"})
  end

  defp raw_body_for(%{suffix: suffix, type: :unsubscribed}) do
    ~s({"RecordType":"SubscriptionChange","MessageID":"msg_#{suffix}","SuppressSending":true})
  end

  defp raw_body_for(%{suffix: suffix, type: :bounced}) do
    ~s({"RecordType":"Bounce","MessageID":"msg_#{suffix}","TypeCode":1})
  end

  defp raw_body_for(%{suffix: suffix, type: :deferred}) do
    ~s({"RecordType":"Bounce","MessageID":"msg_#{suffix}","TypeCode":2})
  end

  defp event_for(%{suffix: suffix, type: type}) do
    %Event{
      tenant_id: "prop-test-tenant",
      type: type,
      occurred_at: Clock.utc_now(),
      reject_reason: reject_reason_for(type),
      metadata: %{
        "provider" => "postmark",
        "provider_event_id" => provider_event_id_for(type, suffix),
        "record_type" => record_type_for(type),
        "message_id" => "msg_#{suffix}"
      }
    }
  end

  defp insert_delivery!(%{suffix: suffix, stream: stream}) do
    %{
      tenant_id: "prop-test-tenant",
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: stream,
      recipient: "recipient-#{suffix}@example.com",
      provider: "postmark",
      provider_message_id: "msg_#{suffix}",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent
    }
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp provider_event_id_for(:complained, suffix),
    do: "SpamComplaint:#{suffix}:2026-04-28T12:00:00Z"

  defp provider_event_id_for(:unsubscribed, suffix),
    do: "SubscriptionChange:#{suffix}:2026-04-28T12:00:00Z"

  defp provider_event_id_for(:bounced, suffix), do: "Bounce:#{suffix}:2026-04-28T12:00:00Z"
  defp provider_event_id_for(:deferred, suffix), do: "Deferred:#{suffix}:2026-04-28T12:00:00Z"

  defp record_type_for(:complained), do: "SpamComplaint"
  defp record_type_for(:unsubscribed), do: "SubscriptionChange"
  defp record_type_for(:bounced), do: "Bounce"
  defp record_type_for(:deferred), do: "Bounce"

  defp reject_reason_for(:bounced), do: :bounced
  defp reject_reason_for(_type), do: nil

  defp reset_tables! do
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_deliveries CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_suppressions CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
  end
end
