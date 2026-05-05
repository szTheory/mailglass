defmodule MailglassAdmin.Operator.RepairState do
  @moduledoc """
  Shared presenter for operator-facing replay availability and outcome wording.
  """

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
  def effect_label(%{outcome: outcome}), do: effect_label(outcome)
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

  @spec flash_success(atom()) :: String.t()
  def flash_success(:replayed), do: "Replay completed with new work."
  def flash_success(:noop), do: "Replay completed with no change."

  @spec flash_failure(term()) :: String.t()
  def flash_failure(:webhook_event_not_found), do: "Replay target is no longer available."

  def flash_failure(:unknown_provider),
    do: "Replay failed before provider normalization could begin."

  def flash_failure(_reason), do: "Replay failed. Check the timeline for the durable audit result."

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
  def event_badge(type) when type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed],
    do: "Replay audit"

  def event_badge(:reconciled), do: "Reconcile fact"
  def event_badge(_type), do: nil

  @spec replay_metadata_summary(map()) :: String.t()
  def replay_metadata_summary(metadata) when is_map(metadata) do
    provider = Map.get(metadata, "provider") || Map.get(metadata, :provider)
    actor_id = Map.get(metadata, "actor_id") || Map.get(metadata, :actor_id)
    outcome = outcome_label(Map.get(metadata, "outcome_label") || Map.get(metadata, :outcome_label))
    effect = effect_label(Map.get(metadata, "outcome") || Map.get(metadata, :outcome))
    failure_reason = Map.get(metadata, "failure_reason") || Map.get(metadata, :failure_reason)

    [provider && String.upcase(provider), actor_id, outcome, effect, failure_reason]
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
      Map.get(metadata, "reconciled_from_event_id") || Map.get(metadata, :reconciled_from_event_id)

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
    [outcome_label(replay), effect_label(replay)]
    |> Enum.reject(&is_nil/1)
  end
end
