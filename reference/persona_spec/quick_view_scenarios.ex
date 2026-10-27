defmodule MailglassDemo.QuickViewScenarios do
  @moduledoc """
  Pure synthetic quick-view projections shared by the demo Storybook and admin
  test build. The JSON file is the small source of scenario metadata and facts;
  builders add only the production component's route/assign contract.

  `inbound/1` builds retained Inbound production-component stories from the
  same declarative facts exposed by `scenarios/0`. `delivery_investigation/1`
  projects the bounded Phase 175 job scenarios through the same source.
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

  @doc "Builds the composed Delivery investigation story assigns for a retained scenario id."
  def delivery_investigation(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "delivery-investigation-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Delivery investigation scenario #{variation_id}")

    projection = scenario["projection"]

    %{
      scenario_id: scenario["id"],
      variation_id: variation_id,
      role_job: scenario["role_job"],
      state: scenario["state"],
      proof_boundary: scenario["proof_boundary"],
      delivery: investigation_delivery(projection["delivery"], scenario["cohort"]),
      position: position(projection["position"]),
      account_labels: MailglassDemo.Personas.account_labels(),
      suppression_state: investigation_suppression(projection["suppression_state"]),
      suppression_read_state: read_state(projection["suppression_read_state"]),
      replay_targets: investigation_replay_targets(projection["replay_targets"]),
      selected_target_id: projection["selected_target_id"],
      review_id: projection["review_id"] || "story-review-#{variation_id}",
      feedback: investigation_feedback(projection["feedback"]),
      modal_open?: projection["modal_open?"] || false,
      pending?: projection["pending?"] || false,
      consumed?: projection["consumed?"] || false
    }
  end

  defp investigation_delivery(delivery, tenant_id) do
    %{
      id: delivery["id"],
      tenant_id: tenant_id,
      recipient: delivery["recipient"],
      subject: delivery["subject"],
      status: status_atom(delivery["status"]),
      last_event_type: event_atom(delivery["last_event_type"]),
      last_event_at: optional_datetime(delivery["last_event_at"]),
      provider: delivery["provider"],
      provider_message_id: delivery["provider_message_id"],
      mailable: delivery["mailable"],
      stream: stream_atom(delivery["stream"])
    }
  end

  defp investigation_suppression(nil), do: nil

  defp investigation_suppression(state) do
    %{
      address: state["address"],
      scope: suppression_scope(state["scope"]),
      reason: suppression_reason(state["reason"]),
      source: suppression_source(state["source"]),
      stream: stream_atom(state["stream"]),
      expires_at: optional_datetime(state["expires_at"]),
      removal_policy: removal_policy(state["removal_policy"])
    }
  end

  defp investigation_replay_targets(nil), do: nil

  defp investigation_replay_targets(%{"status" => "exact", "candidate" => candidate}) do
    %{status: :exact, candidate: investigation_candidate(candidate)}
  end

  defp investigation_replay_targets(%{"status" => "ambiguous", "candidates" => candidates}) do
    %{status: :ambiguous, candidates: Enum.map(candidates, &investigation_candidate/1)}
  end

  defp investigation_replay_targets(%{"status" => "unavailable", "reason" => reason}) do
    %{status: :unavailable, reason: unavailable_reason(reason)}
  end

  defp investigation_candidate(candidate) do
    %{
      webhook_event_id: candidate["webhook_event_id"],
      provider_event_id: candidate["provider_event_id"],
      delivery_provider_message_id: candidate["delivery_provider_message_id"],
      provider: candidate["provider"],
      webhook_timestamp: optional_datetime(candidate["webhook_timestamp"])
    }
  end

  defp investigation_feedback(nil), do: nil
  defp investigation_feedback(%{"text" => text}), do: %{kind: :error, text: text}

  defp read_state("ready"), do: :ready
  defp read_state("stale"), do: :stale
  defp read_state("unavailable"), do: :unavailable

  defp suppression_scope("address_stream"), do: :address_stream
  defp suppression_scope("address"), do: :address
  defp suppression_scope("domain"), do: :domain
  defp suppression_scope(_), do: nil

  defp suppression_reason("complaint"), do: :complaint
  defp suppression_reason("unsubscribe"), do: :unsubscribe
  defp suppression_reason("hard_bounce"), do: :hard_bounce
  defp suppression_reason("manual"), do: :manual
  defp suppression_reason("policy"), do: :policy
  defp suppression_reason("invalid_recipient"), do: :invalid_recipient
  defp suppression_reason(_), do: nil

  defp suppression_source("provider_event"), do: :provider_event
  defp suppression_source("host_policy"), do: :host_policy
  defp suppression_source(_), do: nil

  defp removal_policy("blocked"), do: :blocked
  defp removal_policy("supported"), do: :supported
  defp removal_policy(_), do: nil

  defp unavailable_reason("historical_sendgrid_batch"), do: :historical_sendgrid_batch
  defp unavailable_reason("missing_replay_linkage"), do: :missing_replay_linkage
  defp unavailable_reason("read_unavailable"), do: :read_unavailable
  defp unavailable_reason("no_delivery_events"), do: :no_delivery_events
  defp unavailable_reason(_), do: nil

  defp stream_atom("transactional"), do: :transactional
  defp stream_atom("operational"), do: :operational
  defp stream_atom(_), do: nil

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
  defp inbound_outcome("accept"), do: :accept
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

  defp optional_datetime(nil), do: nil
  defp optional_datetime(value), do: datetime(value)

  defp status_atom("sent"), do: :sent
  defp status_atom("failed"), do: :failed

  defp event_atom("delivered"), do: :delivered
  defp event_atom("bounced"), do: :bounced
end
