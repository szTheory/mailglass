defmodule MailglassDemo.QuickViewScenarios do
  @moduledoc """
  Pure synthetic quick-view projections shared by the demo Storybook and admin
  test build. The JSON file is the small source of scenario metadata and facts;
  builders add only the production component's route/assign contract.

  `inbound/1` builds retained Inbound production-component stories from the
  same declarative facts exposed by `scenarios/0`. `delivery_investigation/1`
  projects the bounded Phase 175 job scenarios through the same source, and
  `inbound_evidence/1` projects the Phase 176 Inbound contact and raw-source
  scenarios (production `DetailHeader` and `EvidenceCard` assigns only).
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

  @doc """
  Builds the retained Inbound contact and raw-source story assigns for a scenario id.

  Returns only the assigns the production `MailglassAdmin.Inbound.DetailHeader` and
  `MailglassAdmin.Inbound.EvidenceCard` already accept. The contact lists keep the
  stored string-keyed address maps (the components read both key kinds).
  """
  def inbound_evidence(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "inbound-evidence-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Inbound evidence scenario #{variation_id}")

    projection = scenario["projection"]
    record = evidence_record(projection["record"])

    %{
      scenario_id: scenario["id"],
      variation_id: variation_id,
      role_job: scenario["role_job"],
      state: scenario["state"],
      proof_boundary: scenario["proof_boundary"],
      detail: %{
        record: record,
        mailbox: projection["mailbox"],
        outcome: inbound_outcome(projection["outcome"])
      },
      evidence: evidence_map(projection["evidence"]),
      reveal_state: reveal_state(projection["reveal_state"]),
      received_at: record.received_at,
      account_labels: MailglassDemo.Personas.account_labels()
    }
  end

  @doc """
  Builds the retained Health story assigns for a scenario id.

  Returns exactly the assigns `MailglassAdmin.Operator.HealthOverview.overview/1`
  accepts, plus the scenario metadata. Panel keys, statuses and surfaces are
  converted through closed maps; manifest strings are never turned into atoms
  by `String.to_atom/1`.
  """
  def health_overview(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "health-overview-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Health scenario #{variation_id}")

    projection = scenario["projection"]

    %{
      scenario_id: scenario["id"],
      variation_id: variation_id,
      role_job: scenario["role_job"],
      state: scenario["state"],
      proof_boundary: scenario["proof_boundary"],
      issues: Enum.map(projection["issues"], &health_issue/1),
      activity: health_activity(projection["activity"]),
      states: health_states(projection["states"]),
      deliveries_path: projection["deliveries_path"],
      inbound_path: projection["inbound_path"],
      window_copy: projection["window_copy"],
      window_description: projection["window_description"],
      observed_at: datetime(projection["observed_at"])
    }
  end

  @doc """
  Builds the retained Account-scope story assigns for a scenario id.

  Returns the assigns `MailglassAdmin.Operator.Shell.account_context/1` and
  `MailglassAdmin.SurfaceNav.nav/1` (scope `:account`) accept, flat, plus the
  scenario metadata.
  """
  def account_scope(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "account-scope-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Account scope scenario #{variation_id}")

    projection = scenario["projection"]

    scenario
    |> story_meta()
    |> Map.merge(surface_nav_assigns(projection))
    |> Map.merge(%{
      selected_tenant_id: projection["selected_tenant_id"],
      tenant_options:
        Enum.map(projection["tenant_options"], &%{id: &1["id"], label: &1["label"]}),
      account_labels: projection["account_labels"],
      tenant_state: tenant_state(projection["tenant_state"]),
      page_uri: projection["page_uri"]
    })
  end

  @doc """
  Builds the retained Preview-chrome story assigns for a scenario id.

  Returns the assigns `MailglassAdmin.SurfaceNav.nav/1` (scope `:preview`)
  accepts, plus the scenario metadata. No Account identity is part of the facts.
  """
  def preview_chrome(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "preview-chrome-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Preview chrome scenario #{variation_id}")

    projection = scenario["projection"]

    scenario
    |> story_meta()
    |> Map.merge(surface_nav_assigns(projection))
    |> Map.merge(%{
      return_href: projection["return_href"],
      return_label: projection["return_label"]
    })
  end

  defp story_meta(scenario) do
    %{
      scenario_id: scenario["id"],
      variation_id: scenario["variation_id"],
      role_job: scenario["role_job"],
      state: scenario["state"],
      proof_boundary: scenario["proof_boundary"]
    }
  end

  defp surface_nav_assigns(projection) do
    %{
      active: nav_key(projection["active"]),
      layout: nav_layout(projection["layout"]),
      preview_path: projection["preview_path"],
      overview_path: projection["overview_path"],
      deliveries_path: projection["deliveries_path"],
      inbound_path: projection["inbound_path"],
      inbound_available?: projection["inbound_available"] == true
    }
  end

  defp nav_key("preview"), do: :preview
  defp nav_key("overview"), do: :overview
  defp nav_key("deliveries"), do: :deliveries
  defp nav_key("inbound"), do: :inbound

  defp nav_layout("sidebar"), do: :sidebar
  defp nav_layout("mobile"), do: :mobile

  defp tenant_state("none"), do: :none
  defp tenant_state("selected"), do: :selected
  defp tenant_state("unavailable"), do: :unavailable

  defp health_issue(issue) do
    %{
      testid: issue["testid"],
      count: issue["count"],
      label: issue["label"],
      help: issue["help"],
      surface: health_surface(issue["surface"]),
      path: issue["path"],
      stale?: issue["stale"] == true
    }
  end

  defp health_surface("deliveries"), do: :deliveries
  defp health_surface("inbound"), do: :inbound

  defp health_activity(activity) do
    %{
      deliveries: health_total(activity["deliveries"]),
      inbound: health_total(activity["inbound"])
    }
  end

  defp health_total(nil), do: nil
  defp health_total(%{"total" => total}), do: %{total: total}

  defp health_states(states) do
    Map.new(states, fn {panel, state} -> {health_panel(panel), health_state(state)} end)
  end

  defp health_panel("failed_ingest"), do: :failed_ingest
  defp health_panel("orphan_backlog"), do: :orphan_backlog
  defp health_panel("delivery_activity"), do: :delivery_activity
  defp health_panel("inbound_activity"), do: :inbound_activity

  defp health_state(%{"status" => "ready"}), do: %{status: :ready}
  defp health_state(%{"status" => "unavailable"}), do: %{status: :unavailable}

  defp health_state(%{"status" => "stale", "checked_at" => checked_at}),
    do: %{status: :stale, checked_at: datetime(checked_at)}

  defp evidence_record(record) do
    %{
      id: record["id"],
      tenant_id: record["tenant_id"],
      provider: record["provider"],
      provider_message_id: record["provider_message_id"],
      subject: record["subject"],
      received_at: datetime(record["received_at"]),
      envelope_recipient: record["envelope_recipient"],
      from: record["from"],
      to: record["to"],
      cc: record["cc"],
      reply_to: record["reply_to"]
    }
  end

  defp evidence_map(nil), do: nil

  defp evidence_map(evidence) do
    %{
      provider: evidence["provider"],
      raw_payload: evidence["raw_payload"],
      raw_headers: evidence["raw_headers"],
      raw_mime: evidence["raw_mime"],
      verification_facts: evidence["verification_facts"]
    }
  end

  defp reveal_state("redacted"), do: :redacted
  defp reveal_state("revealed"), do: :revealed
  defp reveal_state("denied"), do: :denied

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
