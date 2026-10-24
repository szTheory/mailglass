defmodule MailglassAdmin.Operator.RepairStateTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Operator.RepairState

  test "replay evidence distinguishes a request, new work and a completed no-op" do
    assert RepairState.latest_replay_summary(%{type: :webhook_replay_requested, provider: "ses"}) ==
             "requested · completion not recorded · SES"

    assert RepairState.latest_replay_summary(%{
             type: :webhook_replay_succeeded,
             outcome: :replayed,
             metadata: %{new_event_count: 1},
             provider: "postmark"
           }) == "completed · 1 newly normalized Event · POSTMARK"

    assert RepairState.effect_label(%{"outcome" => "noop", "new_event_count" => 0}) ==
             "0 newly normalized Events"

    assert RepairState.effect_label(%{outcome: :noop, metadata: %{new_event_count: -1}}) ==
             "no change"

    assert RepairState.effect_label(%{outcome: :replayed}) == "new work"
    assert RepairState.effect_label(%{metadata: %{outcome: "noop"}}) == "no change"
    assert RepairState.effect_label(%{metadata: %{outcome: "private diagnostic"}}) == nil

    assert RepairState.command_feedback(%{status: :replayed, new_event_count: 2}) =~
             "2 newly normalized Events"

    assert RepairState.command_feedback(%{status: :noop, new_event_count: 0}) =~
             "no newly normalized Events"

    assert RepairState.command_feedback(%{status: :unknown}) =~
             "does not establish provider receipt"
  end

  test "unsafe provider names and unknown failure details never appear in replay summaries" do
    for {reason, copy} <- [
          {:unknown_provider, "processing failed before normalization"},
          {"webhook_event_not_found", "stored request unavailable"},
          {:normalize_failed, "request could not be normalized"},
          {"invalid_raw_payload", "request could not be normalized"},
          {"secret@example.test", "processing failed"}
        ] do
      assert RepairState.latest_replay_summary(%{
               type: :webhook_replay_failed,
               failure_reason: reason,
               provider: "secret@example.test"
             }) == "failed · #{copy}"
    end

    assert RepairState.replay_metadata_summary(%{provider: "secret@example.test"}) ==
             "Replay audit"

    assert RepairState.replay_metadata_summary(%{
             provider: "sendgrid",
             outcome_label: "failed",
             outcome: "noop"
           }) ==
             "SENDGRID · failed · no change"

    assert RepairState.reconcile_metadata_summary(%{}) == "Reconcile fact"

    assert RepairState.reconcile_metadata_summary(%{
             reconciled_provider: "ses",
             reconciled_provider_event_id: "safe-id",
             reconciled_from_event_id: "event-id"
           }) ==
             "SES · safe-id · event-id"
  end

  test "unknown availability and authorization feedback stay bounded" do
    assert RepairState.availability_label(%{status: :unknown}) == nil
    assert RepairState.availability_hint(%{status: :unknown}) =~ "unavailable"
    assert RepairState.outcome_label(:unexpected) == nil
    assert RepairState.effect_label(:unexpected) == nil
    assert RepairState.replay_event_label(:sent) == nil
    assert RepairState.reconcile_event_label(:sent) == nil
    assert RepairState.event_badge(:sent) == nil

    assert RepairState.authorization_feedback("private diagnostic") ==
             "This action is not authorized."

    assert RepairState.authorization_feedback("Replay is not authorized.") ==
             "Replay is not authorized."

    assert RepairState.flash_failure(:unknown_provider) =~ "before normalization"
    assert RepairState.flash_failure(:invalid_raw_payload) =~ "unavailable for replay"
    assert RepairState.flash_failure(:replay_failed) =~ "host's investigation guidance"
    assert RepairState.flash_failure(:unknown) =~ "could not be completed"
    assert RepairState.unavailable_reason_copy(:no_delivery_events) =~ "does not yet have"
    assert RepairState.unavailable_reason_copy(:unknown) =~ "unavailable"
  end
end
