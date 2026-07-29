defmodule MailglassDemo.DemoDataResetTest do
  use MailglassDemo.DataCase, async: false

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias MailglassDemo.DemoData
  alias MailglassDemo.Repo

  test "reset is deterministic across repeated runs and restarts identities" do
    DemoData.reset!()
    baseline = snapshot()

    # Prove truncation + RESTART IDENTITY by perturbing data before the second reset.
    insert_noise()
    refute snapshot() == baseline

    DemoData.reset!()
    rerun = snapshot()

    assert Map.take(rerun, deterministic_keys()) == Map.take(baseline, deterministic_keys())
    assert rerun.deliveries == 17
    assert rerun.events == 36
    assert rerun.inbound == 6
    assert rerun.suppressions == 1
    assert rerun.inbound_evidence == 6
    assert rerun.inbound_replay_runs == 8

    assert rerun.delivery_message_ids == [
             "del_01JXW9ZQKB3V1N4P2RMT7FHCG",
             "pm-demo-badge-clicked-001",
             "pm-demo-badge-opened-001",
             "pm-demo-badge-queued-001",
             "pm-demo-badge-rejected-001",
             "pm-demo-badge-unknown-001",
             "pm-demo-invite-001",
             "pm-demo-magic-link-001",
             "pm-demo-payment-failed-001",
             "pm-demo-receipt-001",
             "pm-demo-truncation-stress-001",
             "sg-demo-badge-autoresponded-001",
             "sg-demo-badge-complained-001",
             "sg-demo-badge-subscribed-001",
             "sg-demo-badge-unsubscribed-001",
             "sg-demo-incident-001",
             "sg-demo-usage-001"
           ]

    assert rerun.webhook_provider_event_ids == [
             "demo-receipt-delivery",
             "demo-usage-bounce",
             "sg-demo-failed-ingest-001"
           ]

    assert rerun.webhook_provider_matrix == [
             {"demo-receipt-delivery", "postmark"},
             {"demo-usage-bounce", "sendgrid"},
             {"sg-demo-failed-ingest-001", "sendgrid"}
           ]

    assert rerun.suppression_tuples == [
             {"ops@northstar.example", "manual", "support-case:1842", "incident_update"}
           ]

    assert rerun.inbound_provider_message_ids == [
             "mg-demo-inbound-failed-001",
             "mg-demo-refund-001",
             "mg-demo-support-001",
             "pm-demo-inbound-ignore-001",
             "pm-demo-spam-001",
             "pm-inbound-demo-nomatch-001"
           ]

    assert rerun.inbound_execution_matrix == [
             {"mg-demo-inbound-failed-001", "fresh", "failed", nil},
             {"mg-demo-refund-001", "fresh", "bounce", "mailbox_full"},
             {"mg-demo-refund-001", "replay", "bounce", "mailbox_full"},
             {"mg-demo-support-001", "fresh", "accept", nil},
             {"mg-demo-support-001", "replay", "accept", nil},
             {"pm-demo-inbound-ignore-001", "fresh", "ignore", nil},
             {"pm-demo-spam-001", "fresh", "reject", "spam"},
             {"pm-inbound-demo-nomatch-001", "fresh", "no_match", nil}
           ]
  end

  defp snapshot do
    %{
      deliveries: Repo.aggregate(Delivery, :count),
      events: Repo.aggregate(Event, :count),
      inbound: count_table!("mailglass_inbound_records"),
      suppressions: Repo.aggregate(Entry, :count),
      inbound_evidence: count_table!("mailglass_inbound_evidence"),
      inbound_replay_runs: count_table!("mailglass_inbound_replay_runs"),
      delivery_message_ids: delivery_message_ids(),
      event_types: event_types(),
      webhook_provider_event_ids: webhook_provider_event_ids(),
      webhook_provider_matrix: webhook_provider_matrix(),
      inbound_provider_message_ids: inbound_provider_message_ids(),
      suppression_addresses: suppression_addresses(),
      replay_sources: replay_sources(),
      suppression_tuples: suppression_tuples(),
      inbound_execution_matrix: inbound_execution_matrix()
    }
  end

  defp insert_noise do
    Repo.query!("TRUNCATE TABLE mailglass_suppressions RESTART IDENTITY CASCADE")
  end

  defp count_table!(table) do
    %{rows: [[count]]} = Repo.query!("SELECT count(*) FROM #{table}")
    count
  end

  defp deterministic_keys do
    [
      :deliveries,
      :events,
      :inbound,
      :suppressions,
      :inbound_evidence,
      :inbound_replay_runs,
      :delivery_message_ids,
      :event_types,
      :webhook_provider_event_ids,
      :webhook_provider_matrix,
      :inbound_provider_message_ids,
      :suppression_addresses,
      :replay_sources,
      :suppression_tuples,
      :inbound_execution_matrix
    ]
  end

  defp delivery_message_ids do
    Delivery
    |> order_by([row], asc: row.provider_message_id)
    |> select([row], row.provider_message_id)
    |> Repo.all()
  end

  defp event_types do
    Event
    |> order_by([row], asc: row.type)
    |> select([row], row.type)
    |> Repo.all()
  end

  defp suppression_addresses do
    Entry
    |> order_by([row], asc: row.address)
    |> select([row], row.address)
    |> Repo.all()
  end

  defp inbound_provider_message_ids do
    %{rows: rows} =
      Repo.query!(
        "SELECT provider_message_id FROM mailglass_inbound_records ORDER BY provider_message_id"
      )

    Enum.map(rows, &hd/1)
  end

  defp replay_sources do
    %{rows: rows} =
      Repo.query!("SELECT source::text FROM mailglass_inbound_replay_runs ORDER BY source::text")

    Enum.map(rows, &hd/1)
  end

  defp webhook_provider_event_ids do
    %{rows: rows} =
      Repo.query!(
        "SELECT provider_event_id FROM mailglass_webhook_events ORDER BY provider_event_id"
      )

    Enum.map(rows, &hd/1)
  end

  defp webhook_provider_matrix do
    %{rows: rows} =
      Repo.query!("""
      SELECT provider_event_id, provider
      FROM mailglass_webhook_events
      ORDER BY provider_event_id
      """)

    Enum.map(rows, fn [provider_event_id, provider] ->
      {provider_event_id, provider}
    end)
  end

  defp suppression_tuples do
    %{rows: rows} =
      Repo.query!("""
      SELECT
        address,
        reason::text,
        source,
        metadata->>'scenario'
      FROM mailglass_suppressions
      ORDER BY address
      """)

    Enum.map(rows, fn [address, reason, source, scenario] ->
      {address, reason, source, scenario}
    end)
  end

  defp inbound_execution_matrix do
    %{rows: rows} =
      Repo.query!("""
      SELECT
        r.provider_message_id,
        run.source::text,
        run.outcome::text,
        run.outcome_reason
      FROM mailglass_inbound_replay_runs run
      JOIN mailglass_inbound_records r ON r.id = run.inbound_record_id
      ORDER BY r.provider_message_id, run.source::text
      """)

    Enum.map(rows, fn [provider_message_id, source, outcome, outcome_reason] ->
      {provider_message_id, source, outcome, outcome_reason}
    end)
  end
end
