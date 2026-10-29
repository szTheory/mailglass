defmodule MailglassAdmin.Phase175ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the eight Phase 175 must-NOT prohibitions
  (UXF-12, OUTUX-07, OUTUX-08, REPLAY-04..08).

  The phase verifier routed these as judgment-tier and left them for owner
  review. Each one reduces to forbidden wording or a forbidden control on a
  closed set of copy branches and rendered states, so this file enumerates
  those branches and refutes the violation. The "detectors have teeth" block
  proves every pattern goes red on a known violation, so a pass here is not
  vacuous.

  Positive behavior (exact-target authorization, focus, durable outcomes) stays
  in the LiveView and browser suites; this file only owns the prohibitions.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Inbound.ReplayModal, as: InboundReplayModal
  alias MailglassAdmin.InboundLive
  alias MailglassAdmin.Operator.{RepairState, ReplayAction, ReplayModal, SuppressionCard}

  @receipt_claims [
    ~r/provider (has )?(confirmed|accepted|received)\b/i,
    ~r/received by (the )?provider/i,
    ~r/(delivery (is |was )?confirmed|confirmed delivery)/i
  ]

  @all_store_claims [
    ~r/all clear/i,
    ~r/not suppressed anywhere/i,
    ~r/no suppressions? (anywhere|in any store)/i,
    ~r/safe to send/i,
    ~r/\bcleared\b/i
  ]

  @permanence_claims [~r/permanent/i, ~r/never expires/i, ~r/\bforever\b/i]

  @resend_framing [
    ~r/(?<!not )\bresen[dt]\b/i,
    ~r/send (it )?again/i,
    ~r/retry delivery/i
  ]

  @operator_blame_or_bypass [
    ~r/\byou (did|caused|broke|made)\b/i,
    ~r/your (fault|mistake|error)/i,
    ~r/\bbypass/i,
    ~r/\boverrid/i,
    ~r/work ?around/i,
    ~r/(disable|ignore|skip) (the )?(account )?polic/i
  ]

  @delivery_outcome_claims [
    ~r/(?<!not )\b(resent|sent|delivered)\b/i,
    ~r/provider (accepted|delivered)/i
  ]

  @retry_pressure [
    ~r/automatic(ally)? retr/i,
    ~r/will retry/i,
    ~r/retrying (in|now|automatically)/i,
    ~r/(try|retry) again now/i,
    ~r/retry now/i,
    ~r/keep (trying|retrying)/i,
    ~r/\bimmediately\b/i
  ]

  describe "detectors have teeth (fail-first proof)" do
    test "every pattern set rejects a known violation" do
      for {patterns, violation} <- [
            {@receipt_claims, "The provider confirmed receipt of this message."},
            {@all_store_claims, "All clear — this address is not suppressed anywhere."},
            {@permanence_claims, "This Suppression is permanent."},
            {@resend_framing, "Resend this delivery"},
            {@operator_blame_or_bypass, "Ask an admin to bypass the Account policy."},
            {@delivery_outcome_claims, "Replay complete. Mail was delivered."},
            {@retry_pressure, "Replay failed. We will retry automatically."}
          ] do
        assert violations(violation, patterns) != [],
               "pattern set must catch #{inspect(violation)}"
      end
    end

    test "negated disclaimers are not mistaken for claims" do
      assert violations("It does not resend mail or prove provider receipt.", @resend_framing) ==
               []

      assert violations("This replay was not sent.", @delivery_outcome_claims) == []
    end
  end

  describe "UXF-12 evidence never implies provider receipt" do
    test "outbound and Inbound replay surfaces carry no receipt claim" do
      corpus =
        [
          outbound_modal(%{status: :exact, candidate: candidate("w-1")}, "w-1"),
          inbound_modal(%{status: :eligible, mailbox: "MyApp.Mailboxes.Support"})
        ] ++ outbound_outcome_copy() ++ inbound_outcome_copy()

      assert_clean(corpus, @receipt_claims, "UXF-12")
    end
  end

  describe "OUTUX-07 suppression copy never claims current all-store clearance" do
    test "every read state discloses scope and makes no all-store claim" do
      for {state, read_state} <- suppression_states() do
        text = suppression_card(state, read_state)

        assert text =~ "Other configured stores and provider restrictions are not checked.",
               "OUTUX-07: #{inspect(read_state)} must name unchecked stores"

        assert_clean([text], @all_store_claims, "OUTUX-07 #{inspect(read_state)}")
      end
    end

    test "a stale or unavailable read never presents an empty result as current" do
      for read_state <- [:stale, :unavailable] do
        text = suppression_card(%{}, read_state)
        refute text =~ "No current Mailglass match"
        assert text =~ "Couldn’t refresh suppression evidence."
      end
    end
  end

  describe "OUTUX-08 unknown expiry is not permanent and the card is read-only" do
    test "no state claims permanence or offers a removal control" do
      for {state, read_state} <- suppression_states() do
        html =
          render_component(&SuppressionCard.suppression_card/1,
            suppression_state: state,
            read_state: read_state
          )

        text = visible_text(html)

        assert_clean([text], @permanence_claims, "OUTUX-08 #{inspect(read_state)}")

        controls = control_labels(html)

        assert Enum.all?(controls, &(not (&1 =~ ~r/remov|delete|unsuppress/i))),
               "OUTUX-08: read-only card exposed #{inspect(controls)}"
      end
    end
  end

  describe "REPLAY-04 quick-view recovery is not a resend and the request is never chosen for the operator" do
    test "outbound replay entry points and dialog avoid resend framing" do
      corpus = [
        replay_action(%{status: :exact, candidate: candidate("w-1")}),
        replay_action(%{status: :ambiguous, candidates: [candidate("w-1"), candidate("w-2")]}),
        outbound_modal(%{status: :exact, candidate: candidate("w-1")}, "w-1"),
        outbound_modal(
          %{status: :ambiguous, candidates: [candidate("w-1"), candidate("w-2")]},
          nil
        )
      ]

      assert_clean(corpus, @resend_framing, "REPLAY-04")
    end

    test "an ambiguous target set preselects nothing and cannot be confirmed" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
          replay_targets: %{status: :ambiguous, candidates: [candidate("w-1"), candidate("w-2")]},
          selected_target_id: nil
        )

      assert Floki.find(Floki.parse_fragment!(html), "input[checked]") == []
      refute html =~ ~s(data-testid="operator-replay-confirm")
      assert html =~ "No request is selected for you."
    end
  end

  describe "REPLAY-05 unavailability never blames the operator or suggests bypassing policy" do
    test "every unavailable, ineligible, and denied branch is clean" do
      corpus =
        Enum.map(
          unavailable_reasons(),
          &RepairState.availability_hint(%{status: :unavailable, reason: &1})
        ) ++
          Enum.map(dialog_reasons(), &RepairState.dialog_feedback(&1).text) ++
          Enum.map(
            ["Recent authentication is required.", "Replay is not authorized.", "other"],
            &RepairState.authorization_feedback/1
          ) ++
          Enum.map(
            inbound_ineligible_reasons(),
            &inbound_modal(%{status: :ineligible, reason: &1})
          )

      assert_clean(corpus, @operator_blame_or_bypass, "REPLAY-05")
    end

    test "a non-recoverable unavailable target renders no primary action" do
      for reason <- unavailable_reasons() -- [:read_unavailable] do
        html =
          render_component(&ReplayAction.replay_action/1,
            replay_targets: %{status: :unavailable, reason: reason}
          )

        refute html =~ ~s(data-testid="operator-replay-open"),
               "REPLAY-05 dead-end CTA for #{reason}"
      end
    end
  end

  describe "REPLAY-06 outbound webhook replay and Inbound Mailbox execution stay distinct" do
    test "each dialog names only its own command and consequence" do
      outbound = outbound_modal(%{status: :exact, candidate: candidate("w-1")}, "w-1")
      inbound = inbound_modal(%{status: :eligible, mailbox: "MyApp.Mailboxes.Support"})

      assert outbound =~ "Reprocesses this stored webhook"
      refute outbound =~ ~r/Mailbox/

      assert inbound =~ "Recorded Mailbox"
      refute inbound =~ ~r/webhook|normaliz/i
    end
  end

  describe "REPLAY-07 outcomes report what actually happened" do
    test "no outcome claims sent, resent, or provider-delivered mail" do
      assert_clean(
        outbound_outcome_copy() ++ inbound_outcome_copy(),
        @delivery_outcome_claims,
        "REPLAY-07"
      )
    end

    test "a no-change outcome is never announced as new work" do
      outbound_noop = RepairState.command_feedback(%{status: :noop, new_event_count: 0})
      inbound_noop = InboundLive.replay_result_copy(%{outcome: :no_change})

      refute outbound_noop =~ ~r/\badded\b|\b[1-9]\d* newly/
      refute inbound_noop =~ ~r/\bnew Event|\badded\b/i
      assert RepairState.effect_label(:noop) == "no change"
    end
  end

  describe "REPLAY-08 failures stay failed without retry pressure" do
    test "every failure branch is clean" do
      corpus =
        Enum.map(flash_failure_reasons(), &RepairState.flash_failure/1) ++
          Enum.map(dialog_reasons(), &RepairState.dialog_feedback(&1).text) ++
          [InboundLive.replay_result_copy(%{outcome: :failed})]

      assert_clean(corpus, @retry_pressure, "REPLAY-08")
    end

    test "a failed outbound review stays open with only an explicit re-review" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
          replay_targets: %{status: :exact, candidate: candidate("w-1")},
          selected_target_id: "w-1",
          feedback: RepairState.dialog_feedback(:command_failure)
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(data-testid="operator-replay-review-again")
      refute visible_text(html) =~ ~r/newly normalized Events?\./
    end

    test "no LiveView schedules a replay retry on its own" do
      for path <- ["lib/mailglass_admin/operator_live.ex", "lib/mailglass_admin/inbound_live.ex"] do
        source = File.read!(path)
        refute source =~ ~r/send_after\([^)]*replay/i, "REPLAY-08: #{path} schedules a replay"

        refute source =~ ~r/:timer\.(send|apply)[^\n]*replay/i,
               "REPLAY-08: #{path} schedules a replay"
      end
    end
  end

  # -- corpus builders -------------------------------------------------------

  defp outbound_outcome_copy do
    [
      RepairState.command_feedback(%{status: :replayed, new_event_count: 1}),
      RepairState.command_feedback(%{status: :replayed, new_event_count: 3}),
      RepairState.command_feedback(%{status: :noop, new_event_count: 0}),
      RepairState.command_feedback(%{status: :other}),
      RepairState.effect_label(:replayed),
      RepairState.effect_label(:noop)
    ]
  end

  defp inbound_outcome_copy do
    [
      %{status: :queued},
      %{outcome: :failed},
      %{outcome: :no_change},
      %{outcome: :accept},
      %{outcome: :ignore},
      %{outcome: :reject},
      %{outcome: :bounce},
      %{outcome: :no_match},
      %{}
    ]
    |> Enum.map(&InboundLive.replay_result_copy/1)
  end

  defp suppression_states do
    expiry = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(3_600, :second)

    match = %{
      address: "policy@example.com",
      scope: :address,
      reason: :complaint,
      source: "provider complaint",
      expires_at: nil,
      removal_policy: :blocked
    }

    for state <- [
          %{},
          match,
          %{match | expires_at: expiry, removal_policy: :supported, reason: :manual},
          %{match | address: nil, scope: :unknown, reason: nil, source: "", removal_policy: nil}
        ],
        read_state <- [:ready, :stale, :unavailable] do
      {state, read_state}
    end
  end

  defp unavailable_reasons,
    do: [
      :historical_sendgrid_batch,
      :missing_replay_linkage,
      :read_unavailable,
      :no_delivery_events,
      :other
    ]

  defp dialog_reasons,
    do: [
      :review_changed,
      :read_unavailable,
      :denied,
      {:authorization, :stale_auth, "x"},
      {:authorization, :unauthorized, "x"},
      :target_required,
      :no_selected_delivery,
      :command_failure
    ]

  defp flash_failure_reasons,
    do: [
      :webhook_event_not_found,
      :unknown_provider,
      :normalize_failed,
      :invalid_raw_payload,
      :result_persistence_failed,
      :replay_failed,
      :other
    ]

  defp inbound_ineligible_reasons,
    do: [
      :no_prior_match,
      :execution_history_missing,
      :invalid_mailbox,
      :mailbox_unavailable,
      :missing_evidence,
      :record_unavailable,
      :read_unavailable,
      :package_unavailable,
      :other
    ]

  # -- renderers -------------------------------------------------------------

  defp outbound_modal(targets, selected) do
    render_component(&ReplayModal.replay_modal/1,
      open?: true,
      delivery: %{recipient: "operator@example.com"},
      account_label: "Northstar Logistics",
      replay_targets: targets,
      selected_target_id: selected
    )
    |> visible_text()
  end

  defp inbound_modal(eligibility) do
    render_component(&InboundReplayModal.replay_modal/1,
      open?: true,
      review: %{
        review_id: "review-1",
        tenant_id: "tenant-a",
        record_id: "rec-1",
        eligibility: eligibility
      },
      record: %{id: "rec-1", tenant_id: "tenant-a", envelope_recipient: "alice@example.com"}
    )
    |> visible_text()
  end

  defp replay_action(targets) do
    render_component(&ReplayAction.replay_action/1, replay_targets: targets, origin: "quick_view")
    |> visible_text()
  end

  defp suppression_card(state, read_state) do
    render_component(&SuppressionCard.suppression_card/1,
      suppression_state: state,
      read_state: read_state
    )
    |> visible_text()
  end

  defp candidate(id) do
    %{
      provider: "postmark",
      webhook_event_id: id,
      webhook_timestamp: ~U[2026-06-19 12:00:00Z],
      provider_event_id: "provider-#{id}",
      delivery_provider_message_id: "delivery-#{id}"
    }
  end

  # -- matching --------------------------------------------------------------

  defp visible_text(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.filter_out("script")
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp control_labels(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("button, a, [phx-click]")
    |> Enum.map(fn node ->
      # A phx-click JS command (JSON list) is client-side UI plumbing, not a server action.
      events = node |> Floki.attribute("phx-click") |> Enum.reject(&String.starts_with?(&1, "["))
      [Floki.text(node) | events] |> Enum.join(" ")
    end)
  end

  defp violations(text, patterns), do: Enum.filter(patterns, &Regex.match?(&1, text))

  defp assert_clean(corpus, patterns, label) do
    for text <- corpus do
      hits = violations(text, patterns)

      assert hits == [],
             "#{label}: #{inspect(Enum.map(hits, &Regex.source/1))} matched #{inspect(text)}"
    end
  end
end
