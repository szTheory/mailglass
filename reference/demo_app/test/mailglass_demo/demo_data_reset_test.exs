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
    assert rerun.deliveries == 6
    assert rerun.events == 11
    assert rerun.inbound == 4
    assert rerun.suppressions == 1
    assert rerun.inbound_evidence == 4
    assert rerun.inbound_replay_runs == 6
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
      inbound_provider_message_ids: inbound_provider_message_ids(),
      suppression_addresses: suppression_addresses(),
      replay_sources: replay_sources()
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
      :inbound_provider_message_ids,
      :suppression_addresses,
      :replay_sources
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
      Repo.query!("SELECT provider_message_id FROM mailglass_inbound_records ORDER BY provider_message_id")

    Enum.map(rows, &hd/1)
  end

  defp replay_sources do
    %{rows: rows} =
      Repo.query!("SELECT source::text FROM mailglass_inbound_replay_runs ORDER BY source::text")

    Enum.map(rows, &hd/1)
  end

end
