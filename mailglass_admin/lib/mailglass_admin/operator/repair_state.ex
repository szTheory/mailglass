defmodule MailglassAdmin.Operator.RepairState do
  @moduledoc """
  Shared presenter for operator-facing replay availability and outcome wording.
  """

  @providers ~w(mailgun postmark sendgrid ses)

  @spec availability_label(map() | atom() | nil) :: String.t() | nil
  def availability_label(nil), do: nil
  def availability_label(%{status: status}), do: availability_label(status)
  def availability_label(:exact), do: "ready"
  def availability_label(:ambiguous), do: "choice required"
  def availability_label(:unavailable), do: "unavailable"
  def availability_label(_status), do: nil

  @spec outcome_label(map() | atom() | String.t() | nil) :: String.t() | nil
  def outcome_label(nil), do: nil
  def outcome_label(%{type: type}), do: outcome_label(type)
  def outcome_label(:webhook_replay_requested), do: "requested"
  def outcome_label(:webhook_replay_succeeded), do: "completed"
  def outcome_label(:webhook_replay_failed), do: "failed"
  def outcome_label("requested"), do: "requested"
  def outcome_label("completed"), do: "completed"
  def outcome_label("failed"), do: "failed"
  def outcome_label(_value), do: nil

  @spec effect_label(map() | atom() | String.t() | nil) :: String.t() | nil
  def effect_label(nil), do: nil

  def effect_label(%{outcome: outcome, metadata: metadata}) when is_map(metadata) do
    case Map.get(metadata, "new_event_count") || Map.get(metadata, :new_event_count) do
      count when is_integer(count) and count >= 0 ->
        "#{count} newly normalized #{if(count == 1, do: "Event", else: "Events")}"

      _ ->
        effect_label(outcome)
    end
  end

  def effect_label(%{metadata: metadata}) when is_map(metadata), do: effect_label(metadata)
  def effect_label(%{outcome: outcome}), do: effect_label(outcome)

  def effect_label(%{"outcome" => outcome} = metadata),
    do: effect_label(%{outcome: outcome, metadata: metadata})

  def effect_label(:replayed), do: "new work"
  def effect_label("replayed"), do: "new work"
  def effect_label(:noop), do: "no change"
  def effect_label("noop"), do: "no change"
  def effect_label(_value), do: nil

  @spec availability_hint(map() | nil) :: String.t()
  def availability_hint(nil), do: "Replay availability loads when a delivery is selected."

  def availability_hint(%{status: :exact}) do
    "Replay is #{availability_label(:exact)}. One exact webhook target is available for confirmation."
  end

  def availability_hint(%{status: :ambiguous}) do
    "Replay is #{availability_label(:ambiguous)}. Choose one webhook target in the confirmation modal."
  end

  def availability_hint(%{status: :unavailable, reason: reason}) do
    "Replay is #{availability_label(:unavailable)}. " <> unavailable_reason_copy(reason)
  end

  def availability_hint(_replay_targets),
    do: "Replay availability is unavailable for this delivery."

  @spec latest_replay_summary(map()) :: String.t()
  def latest_replay_summary(replay) do
    replay
    |> replay_summary_parts()
    |> Enum.join(" · ")
  end

  @spec command_feedback(map()) :: String.t()
  def command_feedback(%{status: :replayed, new_event_count: count})
      when is_integer(count) and count > 0 do
    "Replay command added #{count} newly normalized #{if(count == 1, do: "Event", else: "Events")}."
  end

  def command_feedback(%{status: :noop, new_event_count: 0}),
    do: "Replay command completed with no newly normalized Events."

  def command_feedback(_result),
    do:
      "Replay command completed. Its result does not establish provider receipt or mail delivery."

  @spec flash_failure(term()) :: String.t()
  def flash_failure(:webhook_event_not_found),
    do: "The reviewed stored request is no longer available."

  def flash_failure(:unknown_provider),
    do: "Replay processing failed before normalization could begin."

  def flash_failure(:normalize_failed), do: "Replay processing failed during normalization."

  def flash_failure(:invalid_raw_payload),
    do: "The stored request is unavailable for replay processing."

  def flash_failure(:result_persistence_failed),
    do:
      "Replay processing could not be recorded because persistence failed. Normalized Events and projection changes were rolled back."

  def flash_failure(:replay_failed),
    do: "Replay processing failed. Follow your host's investigation guidance."

  def flash_failure(_reason),
    do: "Replay could not be completed. Follow your host's investigation guidance."

  @spec authorization_feedback(String.t()) :: String.t()
  def authorization_feedback("Recent authentication is required."),
    do: "Recent authentication is required."

  def authorization_feedback("Replay is not authorized."), do: "Replay is not authorized."
  def authorization_feedback(_message), do: "This action is not authorized."

  @spec replay_evidence_unavailable_copy() :: String.t()
  def replay_evidence_unavailable_copy,
    do: "The latest persisted replay evidence could not be refreshed."

  @spec replay_event_label(atom()) :: String.t() | nil
  def replay_event_label(type) do
    case outcome_label(type) do
      nil -> nil
      label -> "Webhook replay " <> label
    end
  end

  @spec reconcile_event_label(atom()) :: String.t() | nil
  def reconcile_event_label(:reconciled), do: "Reconcile linked"
  def reconcile_event_label(_type), do: nil

  @spec event_badge(atom()) :: String.t() | nil
  def event_badge(type)
      when type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed],
      do: "Replay audit"

  def event_badge(:reconciled), do: "Reconcile fact"
  def event_badge(_type), do: nil

  @spec replay_metadata_summary(map()) :: String.t()
  def replay_metadata_summary(metadata) when is_map(metadata) do
    provider = safe_provider(Map.get(metadata, "provider") || Map.get(metadata, :provider))

    outcome =
      outcome_label(Map.get(metadata, "outcome_label") || Map.get(metadata, :outcome_label))

    effect = effect_label(metadata)

    [provider && String.upcase(provider), outcome, effect]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "Replay audit"
      values -> Enum.join(values, " · ")
    end
  end

  @spec reconcile_metadata_summary(map()) :: String.t()
  def reconcile_metadata_summary(metadata) when is_map(metadata) do
    provider = Map.get(metadata, "reconciled_provider") || Map.get(metadata, :reconciled_provider)

    provider_event_id =
      Map.get(metadata, "reconciled_provider_event_id") ||
        Map.get(metadata, :reconciled_provider_event_id)

    source_event_id =
      Map.get(metadata, "reconciled_from_event_id") ||
        Map.get(metadata, :reconciled_from_event_id)

    [provider && String.upcase(provider), provider_event_id, source_event_id]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "Reconcile fact"
      values -> Enum.join(values, " · ")
    end
  end

  @spec unavailable_reason_copy(atom() | nil) :: String.t()
  def unavailable_reason_copy(:historical_sendgrid_batch),
    do: "Historical rows still lack one exact webhook identity."

  def unavailable_reason_copy(:missing_replay_linkage),
    do: "Historical rows without exact webhook linkage cannot be replayed safely."

  def unavailable_reason_copy(:no_delivery_events),
    do: "This delivery does not yet have any linked webhook events to replay."

  def unavailable_reason_copy(_reason),
    do: "Replay target resolution is unavailable for this delivery."

  defp replay_summary_parts(replay) do
    outcome = outcome_label(replay)

    details =
      case outcome do
        "requested" -> "completion not recorded"
        "completed" -> effect_label(replay)
        "failed" -> safe_failure_reason(Map.get(replay, :failure_reason))
        _ -> nil
      end

    provider = safe_provider(Map.get(replay, :provider))

    [outcome, details, provider && String.upcase(provider)]
    |> Enum.reject(&is_nil/1)
  end

  defp safe_provider(provider) when provider in @providers, do: provider
  defp safe_provider(_provider), do: nil

  defp safe_failure_reason(reason) when reason in [:unknown_provider, "unknown_provider"],
    do: "processing failed before normalization"

  defp safe_failure_reason(reason)
       when reason in [:webhook_event_not_found, "webhook_event_not_found"],
       do: "stored request unavailable"

  defp safe_failure_reason(reason)
       when reason in [
              :normalize_failed,
              "normalize_failed",
              :invalid_raw_payload,
              "invalid_raw_payload"
            ],
       do: "request could not be normalized"

  defp safe_failure_reason(_reason), do: "processing failed"
end
