defmodule MailglassAdmin.Operator.ScenarioContractTest do
  use MailglassAdmin.LiveViewCase, async: false

  alias Mailglass.Operator.{ReplayTargets, SupportSummary, Timeline}
  alias MailglassAdmin.TestSupport.OperatorFixtures

  for {variant, status, count} <- [
        {"zero", :unavailable, 0},
        {"one", :exact, 1},
        {"many", :ambiguous, 2}
      ] do
    test "#{variant} replay scenario resolves only its linked Account targets" do
      scenario = OperatorFixtures.seed_phase169_replay!(unquote(variant))
      Mailglass.Tenancy.put_current(scenario.tenant_id)

      assert {:ok, targets} = ReplayTargets.list_delivery_targets(scenario)
      assert targets.status == unquote(status)
      assert length(targets.candidates) == unquote(count)

      assert Enum.sort(Enum.map(targets.candidates, & &1.webhook_event_id)) ==
               Enum.sort(Enum.take(scenario.candidate_ids, unquote(count)))

      assert {:error, :delivery_not_found} =
               ReplayTargets.list_delivery_targets(%{scenario | tenant_id: "foreign-account"})
    end
  end

  test "a selected Event beyond the bounded timeline stays available as exact safe evidence" do
    scenario = OperatorFixtures.seed_phase169_timeline_101!()
    Mailglass.Tenancy.put_current(scenario.tenant_id)
    events = Timeline.list_delivery_events(scenario)
    assert length(events) == 100
    refute Enum.any?(events, &(&1.id == scenario.selected_event_id))

    assert Enum.take(Enum.map(events, & &1.id), -2) == [
             "00000000-0000-0000-0000-000000000099",
             "00000000-0000-0000-0000-000000000100"
           ]

    selected =
      Timeline.get_delivery_event(
        scenario.tenant_id,
        scenario.delivery_id,
        scenario.selected_event_id
      )

    assert selected.type == :failed
    assert selected.metadata.provider == "postmark"
    refute Map.has_key?(selected, :normalized_payload)

    assert Timeline.get_delivery_event(
             "foreign-account",
             scenario.delivery_id,
             scenario.selected_event_id
           ) == nil
  end

  for operation <- ["remove-reviewed", "replace-reviewed", "change-reviewed"] do
    test "#{operation} changes the reviewed request without creating replay audit facts" do
      scenario = OperatorFixtures.seed_phase169_replay!("one")
      Mailglass.Tenancy.put_current(scenario.tenant_id)
      before = SupportSummary.get_webhook_event(scenario.tenant_id, scenario.webhook_event_id)
      assert before.provider_event_id == "phase169-replay-one"
      assert before.delivery_id == scenario.delivery_id

      result = OperatorFixtures.mutate_phase169_scenario!(unquote(operation))

      after_request =
        SupportSummary.get_webhook_event(scenario.tenant_id, scenario.webhook_event_id)

      case unquote(operation) do
        "change-reviewed" ->
          assert after_request.provider_event_id == "phase169-replay-one-changed"
          assert DateTime.diff(after_request.received_at, before.received_at, :second) == 1

        "replace-reviewed" ->
          assert after_request == nil

          replacement =
            SupportSummary.get_webhook_event(scenario.tenant_id, result.replacement_id)

          assert replacement.provider_event_id == "phase169-replay-replacement"
          assert replacement.delivery_id == nil

        "remove-reviewed" ->
          assert after_request == nil
      end

      assert SupportSummary.read_replay_outcomes(%{tenant_id: scenario.tenant_id}).counts == %{
               failed: 0,
               noop: 0,
               replayed: 0
             }
    end
  end

  for {variant, count} <- [{"empty", 0}, {"one", 1}, {"many", 3}] do
    test "#{variant} current suppression scenario preserves the historical delivery outcome" do
      scenario = OperatorFixtures.seed_phase169_suppression!(unquote(variant))
      Mailglass.Tenancy.put_current(scenario.tenant_id)

      assert %{rows: [[unquote(count)]]} =
               TestRepo.query!(
                 "SELECT count(*) FROM mailglass_suppressions WHERE tenant_id = $1",
                 [scenario.tenant_id]
               )

      assert scenario.current_suppression_count == unquote(count)

      assert %{type: :suppressed} =
               Timeline.get_delivery_event(
                 scenario.tenant_id,
                 scenario.delivery_id,
                 scenario.historical_event_id
               )
    end
  end
end
