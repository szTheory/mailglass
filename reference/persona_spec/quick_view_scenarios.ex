defmodule MailglassDemo.QuickViewScenarios do
  @moduledoc """
  Pure synthetic quick-view projections shared by the demo Storybook and admin
  test build. The JSON file is the small source of scenario metadata and facts;
  builders add only the production component's route/assign contract.

  `inbound/1` builds retained Inbound production-component stories from the
  same declarative facts exposed by `scenarios/0`.
  """

  @manifest_path Path.expand("quick_view_scenarios.json", __DIR__)
  @external_resource @manifest_path
  @manifest @manifest_path |> File.read!() |> Jason.decode!()

  @doc "Returns the declarative scenarios currently produced by Storybook or a connected route."
  def scenarios, do: @manifest["scenarios"]

  @doc "Builds production `MailglassAdmin.Operator.QuickView` assigns from a retained Delivery id."
  def delivery(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "qv-delivery-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Delivery scenario #{variation_id}")

    projection = scenario["projection"]
    delivery = projection["delivery"]
    tenant_id = scenario["cohort"]
    list_path = delivery_list_path(tenant_id)

    %{
      delivery: %{
        id: delivery["id"],
        tenant_id: tenant_id,
        recipient: delivery["recipient"],
        subject: delivery["subject"],
        status: status_atom(delivery["status"]),
        last_event_type: event_atom(delivery["last_event_type"]),
        last_event_at: datetime(delivery["last_event_at"]),
        provider: delivery["provider"],
        provider_message_id: delivery["provider_message_id"],
        mailable: delivery["mailable"]
      },
      account_labels: MailglassDemo.Personas.account_labels(),
      full_path: list_path <> "&delivery_id=#{URI.encode_www_form(delivery["id"])}&full=1",
      close_path: list_path,
      previous_path: neighbor_path(list_path, projection["previous_id"]),
      next_path: neighbor_path(list_path, projection["next_id"]),
      position: position(projection["position"]),
      keyboard?: false
    }
  end

  @doc "Builds retained Inbound quick-view assigns from a rendered scenario id."
  def inbound(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "qv-inbound-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Inbound scenario #{variation_id}")

    projection = scenario["projection"]
    source_record = projection["record"]
    tenant_id = scenario["cohort"]
    list_path = inbound_list_path(tenant_id)
    selected_id = (source_record && source_record["id"]) || projection["selected_id"]

    %{
      record: inbound_record(source_record),
      detail_error: inbound_error(projection["detail_error"]),
      outside_results?: projection["outside_results?"] || false,
      account_labels: MailglassDemo.Personas.account_labels(),
      full_path: list_path <> "&inbound_id=#{URI.encode_www_form(selected_id)}&full=1",
      close_path: list_path,
      previous_path: inbound_neighbor_path(list_path, projection["previous_id"]),
      next_path: inbound_neighbor_path(list_path, projection["next_id"]),
      position: position(projection["position"]),
      keyboard?: false
    }
  end

  defp inbound_record(nil), do: nil

  defp inbound_record(record) do
    %{
      id: record["id"],
      tenant_id: record["tenant_id"],
      envelope_recipient: record["envelope_recipient"],
      subject: record["subject"],
      outcome: inbound_outcome(record["outcome"]),
      received_at: datetime(record["received_at"]),
      provider: record["provider"],
      mailbox: record["mailbox"]
    }
  end

  defp inbound_outcome("matched"), do: :matched
  defp inbound_outcome("unavailable"), do: :unavailable

  defp inbound_error(nil), do: nil
  defp inbound_error("read_unavailable"), do: :read_unavailable

  defp inbound_list_path(tenant_id),
    do: "/ops/mail/inbound?tenant_id=#{URI.encode_www_form(tenant_id)}"

  defp inbound_neighbor_path(_list_path, nil), do: nil

  defp inbound_neighbor_path(list_path, id),
    do: list_path <> "&inbound_id=#{URI.encode_www_form(id)}"

  defp delivery_list_path(tenant_id) do
    "/ops/mail?tenant_id=#{URI.encode_www_form(tenant_id)}&view=deliveries&window_hours=168"
  end

  defp neighbor_path(_list_path, nil), do: nil
  defp neighbor_path(list_path, id), do: list_path <> "&delivery_id=#{URI.encode_www_form(id)}"

  defp position(nil), do: nil
  defp position(%{"index" => index, "total" => total}), do: %{index: index, total: total}

  defp datetime(value) do
    {:ok, parsed, _offset} = DateTime.from_iso8601(value)
    parsed
  end

  defp status_atom("sent"), do: :sent
  defp status_atom("failed"), do: :failed

  defp event_atom("delivered"), do: :delivered
  defp event_atom("bounced"), do: :bounced
end
