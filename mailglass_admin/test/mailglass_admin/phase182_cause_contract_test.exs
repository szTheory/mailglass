defmodule MailglassAdmin.Phase182CauseContractTest do
  @moduledoc """
  Required-lane contract for what an operator is told about a delivery's cause (Phase 182,
  BRADM-06, D-04, D-19). Machine-checked form of four must-NOT prohibitions, so none is
  left for an owner to eyeball:

    * no next-try time, will-retry promise or automatic-retry claim, on any screen that
      shows a delivery verdict, a timeline, a suppression card, a tooltip or the gallery;
    * no cause text for a missing reject reason or suppression reason;
    * no cause and no "No reason was recorded" fallback where the event history is not
      loaded (the Quick view) or could not be read;
    * no `last_error`, and no exception text, on an admin screen.

  Three layers, because each one alone misses something:

    1. Structure. `MailglassAdmin.Copy.cause_sentence/1` has a clause only for a listed
       reason and none for nil, so rendering a cause for a missing reason raises. Every
       value of the core enums has its own sentence.
    2. Matrix, enumerated from the core enums and never hand-copied: reject reason (nil
       plus every value) by event type (bounced, rejected, failed, deferred, delivered),
       and suppression reason (nil plus every value). Each cell is rendered through the
       verdict component, Full detail, Quick view and the timeline (the suppression cells
       also through the suppression card) and checked with positive assertions, so a
       screen that shows nothing cannot pass. The rendered cell count must equal the
       product of the enumerated sizes.
    3. Forbidden phrases, matched on whitespace-collapsed, script-stripped visible text,
       case-insensitively, with both apostrophe forms. A bare `retr` ban is rejected: the
       read-retry controls ("Retry details") retry a read, not a send, so they are
       allow-listed by exact string instead, and the teeth below prove that list is
       load-bearing.

  The "detectors have teeth" block proves every detector goes red on a planted violation,
  so a pass is not vacuous. Mutations are recorded in the plan SUMMARY.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias MailglassAdmin.{Components, Copy, StatusMap, TestRepo}
  alias MailglassAdmin.Operator.{DetailHeader, QuickView, SuppressionCard, Timeline}
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @tenant_id "browser-tenant"
  @base_path "/ops/mail"
  @reject_reasons Event.__reject_reasons__()
  @suppression_reasons Entry.__reasons__()
  @event_types [:bounced, :rejected, :failed, :deferred, :delivered]
  @at ~U[2026-11-15 12:00:00Z]

  @fallback "No reason was recorded for this email."
  @send_failure "Sending failed before a successful handoff to the provider."

  # Forbidden phrases, name and pattern. Matched on visible text after the allow-list and
  # the negation guard are applied.
  @forbidden [
    {"next try", ~r/next try/i},
    {"will retry", ~r/will retry/i},
    {"retrying", ~r/retrying/i},
    {"retry window", ~r/retry window/i},
    {"we'll try again", ~r/we(’|')ll try again/i},
    {"try again at or in", ~r/try again (at|in)/i},
    {"automatic", ~r/\bautomatic(ally)?\b/i},
    {"a clock time after try", ~r/try\b.{0,20}\d{1,2}:\d{2}/i},
    {"retried", ~r/\bretried\b/i}
  ]

  # Exact visible strings that may contain a forbidden word. The first five retry a read,
  # not a send. The last is the autoresponder tooltip: an out-of-office reply is
  # "automatic" in the provider's own taxonomy and promises nothing about delivery.
  @autoresponder "The provider reported an automatic reply, such as an out-of-office response."
  @allowed [
    "Retry details",
    "Retry suppression read",
    "Retry replay review",
    "Retry messages",
    "before retrying",
    @autoresponder
  ]

  @tone [
    {"successfully", ~r/successfully/i},
    {"oops", ~r/\boops\b/i},
    {"unfortunately", ~r/unfortunately/i},
    {"will", ~r/\bwill\b/i},
    {"should arrive", ~r/should arrive/i}
  ]

  # -- detectors (pure: text in, violations out) ---------------------------------------

  defp visible_text(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.filter_out("script")
    |> Floki.filter_out("style")
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp forbidden_violations(text, allowed \\ @allowed) do
    cleaned =
      allowed
      |> Enum.reduce(text, &String.replace(&2, &1, " "))
      |> String.replace(~r/\bnot retried\b/i, " ")

    for {name, pattern} <- @forbidden, Regex.match?(pattern, cleaned), do: name
  end

  defp tone_violations(text), do: for({name, p} <- @tone, Regex.match?(p, text), do: name)

  defp cause_sentences do
    Enum.map(@reject_reasons, &Copy.cause_sentence({:reject_reason, &1})) ++
      Enum.map(@suppression_reasons, &Copy.cause_sentence({:suppression_reason, &1}))
  end

  # Positive assertions for one verdict. `expected` is {:exact, sentence} when the verdict
  # must carry exactly that cause, or :none when it must carry no cause and no fallback.
  defp cell_violations(expected, verdict_html) do
    doc = Floki.parse_fragment!(verdict_html)
    text = visible_text(verdict_html)
    causes = doc |> Floki.find("[data-testid=delivery-verdict-cause]") |> Enum.map(&Floki.text/1)
    causes = Enum.map(causes, &String.trim/1)

    case expected do
      {:exact, sentence} ->
        others = (cause_sentences() ++ [@fallback, @send_failure]) -- [sentence]

        wrong_cause = if causes == [sentence], do: [], else: [{:cause_line, causes}]
        leaked = for other <- others, String.contains?(text, other), do: {:leaked, other}
        wrong_cause ++ leaked

      :none ->
        shown = if causes == [], do: [], else: [{:unexpected_cause, causes}]

        leaked =
          for sentence <- cause_sentences() ++ [@fallback, @send_failure],
              String.contains?(text, sentence),
              do: {:leaked, sentence}

        shown ++ leaked
    end
  end

  # -- the matrix ------------------------------------------------------------------------

  defp event_cells,
    do: for(type <- @event_types, reason <- [nil | @reject_reasons], do: {:event, type, reason})

  defp suppression_cells,
    do: for(reason <- [nil | @suppression_reasons], do: {:suppression, reason})

  defp expected({:event, type, reason}) when type in [:bounced, :rejected] do
    if reason,
      do: {:exact, Copy.cause_sentence({:reject_reason, reason})},
      else: {:exact, @fallback}
  end

  defp expected({:event, :failed, nil}), do: {:exact, @send_failure}

  defp expected({:event, :failed, reason}),
    do: {:exact, Copy.cause_sentence({:reject_reason, reason})}

  defp expected({:event, type, _reason}) when type in [:deferred, :delivered], do: :none

  defp expected({:suppression, nil}), do: {:exact, @fallback}

  defp expected({:suppression, reason}),
    do: {:exact, Copy.cause_sentence({:suppression_reason, reason})}

  defp row({:event, type, _reason}) do
    base = base_row("cell-#{type}", type)

    case type do
      :bounced -> %{base | bounced_at: @at, terminal: true}
      :rejected -> %{base | terminal: true}
      :failed -> %{base | status: :failed, terminal: true}
      :deferred -> base
      :delivered -> %{base | delivery_confirmed: true, delivered_at: @at, terminal: true}
    end
  end

  defp row({:suppression, _reason}) do
    %{base_row("cell-suppressed", :suppressed) | suppressed_at: @at, terminal: true}
  end

  defp base_row(id, last_event_type) do
    %{
      id: id,
      tenant_id: "cell-account",
      recipient: "cell@example.com",
      subject: "Reset your password",
      status: :sent,
      provider: "postmark",
      stream: :transactional,
      mailable: "MyApp.AccountMailer.password_reset",
      provider_message_id: nil,
      last_event_type: last_event_type,
      last_event_at: @at,
      delivery_confirmed: false,
      bounced_at: nil,
      terminal: nil,
      delivered_at: nil,
      complained_at: nil,
      suppressed_at: nil
    }
  end

  defp events({:event, type, reason}) do
    [
      %{
        id: "event-#{type}",
        type: type,
        reject_reason: reason,
        occurred_at: @at,
        metadata: %{}
      }
    ]
  end

  defp events({:suppression, _reason}), do: []

  defp suppression_state({:suppression, reason}) do
    %{
      address: "cell@example.com",
      scope: :address,
      reason: reason,
      source: "manual",
      stream: nil,
      expires_at: nil,
      removal_policy: :supported
    }
  end

  defp suppression_state({:event, _type, _reason}), do: nil

  defp verdict_html(cell) do
    evidence = %{
      events: events(cell),
      suppression:
        case suppression_state(cell) do
          nil -> :not_loaded
          state -> %{reason: state.reason}
        end
    }

    render_component(&Components.delivery_verdict/1,
      verdict: Copy.delivery_verdict(row(cell), evidence),
      form: :full,
      id: "cell-verdict"
    )
  end

  defp detail_html(cell, overrides \\ %{}) do
    assigns =
      Map.merge(
        %{
          delivery: row(cell),
          timeline_events: events(cell),
          timeline_state: :ready,
          suppression_state: suppression_state(cell),
          suppression_read_state: :ready
        },
        overrides
      )

    render_component(&DetailHeader.detail_header/1, assigns)
  end

  defp quick_html(cell) do
    render_component(&QuickView.quick_view/1,
      delivery: row(cell),
      full_path: "/ops/mail?delivery_id=cell&full=1",
      close_path: "/ops/mail"
    )
  end

  defp timeline_html(cell),
    do: render_component(&Timeline.timeline/1, timeline_events: events(cell))

  defp card_html(cell) do
    render_component(&SuppressionCard.suppression_card/1,
      suppression_state: suppression_state(cell),
      read_state: :ready
    )
  end

  defp verdict_section(html) do
    [section] = html |> Floki.parse_fragment!() |> Floki.find("#delivery-detail-verdict")
    Floki.raw_html(section)
  end

  # Renders every cell through every surface and returns the cells that were rendered.
  defp render_every_cell(fun) do
    for cell <- event_cells() ++ suppression_cells() do
      fun.(cell)
      cell
    end
  end

  # -- structure --------------------------------------------------------------------------

  describe "structure (D-04)" do
    test "every reject reason and every suppression reason has its own sentence" do
      reject = Enum.map(@reject_reasons, &Copy.cause_sentence({:reject_reason, &1}))

      suppression =
        Enum.map(@suppression_reasons, &Copy.cause_sentence({:suppression_reason, &1}))

      assert length(@reject_reasons) == 7 and length(@suppression_reasons) == 6
      assert Enum.all?(reject, &String.starts_with?(&1, "The provider reported"))
      assert Enum.all?(suppression, &String.starts_with?(&1, "Reason:"))
      assert length(Enum.uniq(reject ++ suppression)) == 13
    end

    test "a missing or unlisted reason has no cause clause and raises" do
      for argument <- [
            nil,
            {:reject_reason, nil},
            {:suppression_reason, nil},
            {:reject_reason, :not_a_reason},
            {:suppression_reason, :not_a_reason},
            {:other_kind, :invalid}
          ] do
        assert_raise FunctionClauseError, fn -> apply(Copy, :cause_sentence, [argument]) end
      end
    end

    test "cause_or_fallback returns exactly the fixed sentence for every nil form" do
      assert Copy.fallback_reason() == @fallback

      for argument <- [nil, {:reject_reason, nil}, {:suppression_reason, nil}] do
        assert Copy.cause_or_fallback(argument) == @fallback
      end

      assert Copy.cause_or_fallback({:reject_reason, :invalid}) ==
               Copy.cause_sentence({:reject_reason, :invalid})
    end

    test "a verdict is pure: equal input gives an equal map" do
      for cell <- event_cells() ++ suppression_cells() do
        evidence = %{events: events(cell), suppression: :not_loaded}
        verdict = fn -> Copy.delivery_verdict(row(cell), evidence) end

        assert verdict.() == verdict.()
      end
    end
  end

  # -- matrix -----------------------------------------------------------------------------

  describe "matrix (BRADM-06)" do
    test "the matrix size is the product of the enumerated sizes" do
      cells = render_every_cell(fn _cell -> :ok end)

      assert length(cells) ==
               (length(Event.__reject_reasons__()) + 1) * 5 +
                 length(Entry.__reasons__()) + 1

      assert length(Enum.uniq(cells)) == length(cells)
    end

    test "every cell shows its own cause, the fallback, or nothing, on Full detail and the verdict" do
      render_every_cell(fn cell ->
        for html <- [verdict_html(cell), verdict_section(detail_html(cell))] do
          assert cell_violations(expected(cell), html) == [], "cell #{inspect(cell)}"
        end
      end)
    end

    test "a non-nil reason shows its own cause word, nil shows the fixed fallback exactly" do
      assert expected({:event, :bounced, :invalid}) ==
               {:exact, "The provider reported: invalid address."}

      assert expected({:event, :bounced, nil}) == {:exact, @fallback}
      assert expected({:event, :rejected, nil}) == {:exact, @fallback}
      assert expected({:event, :failed, nil}) == {:exact, @send_failure}
      assert expected({:event, :deferred, :invalid}) == :none
      assert expected({:event, :delivered, nil}) == :none
      assert expected({:suppression, nil}) == {:exact, @fallback}
    end

    test "Quick view has no history, so it shows no cause and no fallback for any cell" do
      render_every_cell(fn cell ->
        text = cell |> quick_html() |> visible_text()

        for sentence <- cause_sentences() ++ [@fallback, @send_failure] do
          refute text =~ sentence, "cell #{inspect(cell)} leaked #{inspect(sentence)}"
        end
      end)
    end

    test "the suppression card shows the fixed fallback for a nil reason and never a cause for it" do
      for cell <- suppression_cells() do
        reason_cell = cell |> card_html() |> reason_value()

        case cell do
          {:suppression, nil} -> assert reason_cell == @fallback
          {:suppression, _reason} -> refute reason_cell in [@fallback, "Unavailable", ""]
        end
      end
    end

    test "Full detail with a Failed class and no timeline events shows the fallback" do
      cell = {:event, :bounced, nil}
      html = detail_html(cell, %{timeline_events: []})

      assert cell_violations({:exact, @fallback}, verdict_section(html)) == []
    end

    test "an unreadable timeline shows neither a cause nor the fallback, and says so" do
      for cell <- [{:event, :bounced, :invalid}, {:event, :bounced, nil}, {:event, :failed, nil}] do
        html = detail_html(cell, %{timeline_state: :unavailable, timeline_events: []})
        section = verdict_section(html)

        assert cell_violations(:none, section) == []

        assert visible_text(section) =~
                 "The event history could not be read, so no reason is shown."
      end
    end

    test "an unreadable suppression read shows neither a cause nor the fallback" do
      cell = {:suppression, :manual}

      for state <- [:unavailable, :stale] do
        html =
          detail_html(cell, %{suppression_read_state: state, suppression_state: nil})

        section = verdict_section(html)
        assert cell_violations(:none, section) == []
      end
    end

    test "the latest failure event decides the cause, so a later open does not hide it" do
      row = row({:event, :bounced, :invalid})

      events = [
        %{id: "e1", type: :sent, reject_reason: nil, occurred_at: @at, metadata: %{}},
        %{id: "e2", type: :bounced, reject_reason: :blocked, occurred_at: @at, metadata: %{}},
        %{id: "e3", type: :opened, reject_reason: nil, occurred_at: @at, metadata: %{}}
      ]

      assert %{cause: "The provider reported: blocked by the receiving server."} =
               Copy.delivery_verdict(row, %{events: events})
    end
  end

  # -- a :failed event is a send-time failure only when the row says so (CR-01) ---------

  describe "a failed event with no reason is a send-time failure only when the row says so" do
    # Mailgun "failed" without a severity and SES "Rendering Failure" are provider events:
    # the provider accepted the email and then failed it. Those rows are :sent, so the
    # handoff sentence would claim the app never reached the provider, which is false.
    test "a provider-reported :failed with no reason on a handed-off row reads the fallback" do
      cell = {:event, :failed, nil}
      provider_row = %{row(cell) | status: :sent}
      evidence = %{events: events(cell)}

      assert StatusMap.delivery_class(provider_row) == :failed

      verdict = Copy.delivery_verdict(provider_row, evidence)
      assert verdict.cause == @fallback

      html = detail_html(cell, %{delivery: provider_row})
      assert cell_violations({:exact, @fallback}, verdict_section(html)) == []
      refute visible_text(html) =~ @send_failure
    end

    test "a provider-reported :failed with a reason still reads that reason on a handed-off row" do
      cell = {:event, :failed, :blocked}
      provider_row = %{row(cell) | status: :sent}

      assert %{cause: "The provider reported: blocked by the receiving server."} =
               Copy.delivery_verdict(provider_row, %{events: events(cell)})
    end

    test "the send-time failure (row status :failed) still reads the handoff sentence" do
      cell = {:event, :failed, nil}
      send_time_row = row(cell)

      assert send_time_row.status == :failed
      assert Copy.delivery_verdict(send_time_row, %{events: events(cell)}).cause == @send_failure
      assert Copy.delivery_verdict(send_time_row, %{events: []}).cause == @send_failure
    end

    test "a handed-off row with no failure event in a loaded timeline reads the fallback" do
      cell = {:event, :failed, nil}
      provider_row = %{row(cell) | status: :sent}

      assert Copy.delivery_verdict(provider_row, %{events: []}).cause == @fallback
    end
  end

  # -- the per-event help is context-free (WR-01, iteration 2) -----------------------------

  describe "the per-event help does not claim the send-time cause (WR-01)" do
    # The timeline and the status tooltip know an event type, never the row's status, so
    # they cannot tell a send-time :failed event (the app never reached the provider) from a
    # provider-reported one (Mailgun "failed" without a severity, SES "Rendering Failure":
    # the provider accepted the email and then failed it). Only the verdict reads the row,
    # so only the verdict may say the handoff failed. The help stays true for both.
    @failed_help "The email did not get through: sending failed, or the provider reported a failure."

    test "the timeline help for a :failed event is the neutral sentence" do
      text = {:event, :failed, nil} |> timeline_html() |> visible_text()

      # Non-vacuous: the :failed event's tooltip is on screen.
      assert text =~ @failed_help
      refute text =~ @send_failure
      refute text =~ "before a successful handoff"
    end

    test "the Failed status tooltip is the same neutral sentence in the delivery context" do
      text =
        (&Components.outcome_badge/1)
        |> render_component(id: "tip-failed", status: :failed, context: :delivery)
        |> visible_text()

      assert text =~ @failed_help
      refute text =~ "before a successful handoff"
    end

    test "a provider-reported failure on a handed-off email never says the handoff failed", %{
      conn: conn
    } do
      OperatorFixtures.reset!()

      delivery =
        insert_failed_delivery!("pw-provider-failed@example.com", %{
          status: :sent,
          provider: "mailgun",
          provider_message_id: "pm_provider_failed"
        })

      insert_event!(delivery, %{type: :sent, occurred_at: hours_ago(3)})
      insert_event!(delivery, %{type: :failed, occurred_at: hours_ago(2)})

      {:ok, _view, full} = live(operator_conn(conn), path(delivery.id, full: true))
      text = visible_text(full)

      # The verdict and the timeline agree: a failure with no recorded reason.
      assert section_text(full, "#delivery-detail-verdict") =~ @fallback
      assert section_text(full, "[data-testid=operator-timeline]") =~ @failed_help

      # Nothing on the screen claims the app never reached the provider.
      refute text =~ @send_failure
      refute text =~ "before a successful handoff"
    end

    test "a send-time failure reads the handoff sentence in the verdict only", %{conn: conn} do
      OperatorFixtures.reset!()

      delivery =
        insert_failed_delivery!("pw-send-time-failed@example.com", %{
          status: :failed,
          provider: nil,
          provider_message_id: nil
        })

      insert_event!(delivery, %{type: :failed, occurred_at: hours_ago(2)})

      {:ok, _view, full} = live(operator_conn(conn), path(delivery.id, full: true))

      verdict = section_text(full, "#delivery-detail-verdict")
      timeline = section_text(full, "[data-testid=operator-timeline]")

      assert verdict =~ @send_failure
      assert timeline =~ @failed_help
      refute timeline =~ @send_failure
    end
  end

  # -- no current suppression entry (WR-02) ------------------------------------------------

  describe "a Not sent email with no current suppression entry (WR-02)" do
    # The suppression read succeeded and nothing matches: the entry expired or was
    # removed. That is not an entry that recorded no reason, so the fixed no-reason
    # sentence would be false, and "on your suppression list" and "remove this address"
    # would contradict the suppression card below ("No current mailglass match").
    @no_entry "No current suppression entry matches this address."

    test "the verdict names the absence, never a missing reason" do
      cell = {:suppression, nil}
      html = detail_html(cell, %{suppression_state: nil, suppression_read_state: :ready})
      section = verdict_section(html)
      text = visible_text(section)

      assert cell_violations(:none, section) == []
      refute text =~ @fallback
      assert text =~ @no_entry
      refute text =~ "is on your suppression list"
      refute text =~ "Remove this address"
      refute section =~ "#delivery-suppression"
    end

    test "an empty suppression map reads the same as no entry" do
      cell = {:suppression, nil}
      html = detail_html(cell, %{suppression_state: %{}, suppression_read_state: :ready})

      assert visible_text(verdict_section(html)) =~ @no_entry
      refute visible_text(verdict_section(html)) =~ @fallback
    end

    test "the verdict and the suppression card agree there is no current entry" do
      card =
        render_component(&SuppressionCard.suppression_card/1,
          suppression_state: nil,
          read_state: :ready
        )

      assert visible_text(card) =~ "No current mailglass match"

      verdict =
        Copy.delivery_verdict(row({:suppression, nil}), %{suppression: :no_entry})

      assert verdict.class == :not_sent
      assert verdict.cause == nil
      assert @no_entry in verdict.notes
      assert verdict.next_link == nil
    end

    test "an entry that exists with no reason still reads the fixed fallback (D-02)" do
      cell = {:suppression, nil}
      section = cell |> detail_html() |> verdict_section()

      assert cell_violations({:exact, @fallback}, section) == []
      assert visible_text(section) =~ "Remove this address from the suppression list"
    end

    test "a real Full detail read with no entry shows the absence, not the fallback", %{
      conn: conn
    } do
      OperatorFixtures.reset!()

      delivery =
        %{
          tenant_id: @tenant_id,
          mailable: "MailglassAdmin.Fixtures.AccountMailer",
          stream: :transactional,
          recipient: "pw-no-entry@example.com",
          provider: nil,
          status: :suppressed,
          last_event_type: :suppressed,
          last_event_at: DateTime.add(DateTime.utc_now(), -1, :hour),
          suppressed_at: DateTime.add(DateTime.utc_now(), -1, :hour),
          terminal: true,
          metadata: %{"subject" => "Reset your password"}
        }
        |> Delivery.changeset()
        |> TestRepo.insert!()

      {:ok, _view, full} = live(operator_conn(conn), path(delivery.id, full: true))
      text = visible_text(full)

      assert text =~ "Not sent"
      assert text =~ @no_entry
      refute text =~ @fallback
    end
  end

  # -- last_error -------------------------------------------------------------------------

  describe "last_error is never rendered (D-02)" do
    test "an exception-shaped last_error reaches neither Full detail nor Quick view", %{
      conn: conn
    } do
      OperatorFixtures.reset!()
      exception = "** (RuntimeError) provider exploded"

      delivery =
        %{
          tenant_id: @tenant_id,
          mailable: "MailglassAdmin.Fixtures.AccountMailer",
          stream: :transactional,
          recipient: "pw-last-error@example.com",
          provider: "postmark",
          provider_message_id: "pm_last_error",
          status: :failed,
          last_event_type: :failed,
          last_event_at: DateTime.add(DateTime.utc_now(), -1, :hour),
          last_error: %{"message" => exception, "kind" => "RuntimeError"},
          metadata: %{"subject" => "Reset your password"}
        }
        |> Delivery.changeset()
        |> TestRepo.insert!()

      # Non-vacuous: the value is stored, so only the screens can be hiding it.
      assert TestRepo.get!(Delivery, delivery.id).last_error["message"] == exception

      {:ok, _view, full} = live(operator_conn(conn), path(delivery.id, full: true))
      {:ok, _view, quick} = live(operator_conn(conn), path(delivery.id, full: false))

      for html <- [full, quick] do
        text = visible_text(html)

        assert text =~ "pw-last-error@example.com"
        refute html =~ "provider exploded"
        refute html =~ "RuntimeError"
        # An exception shape is checked on visible text: the page's own scripts mention
        # `Error)` in comments and handlers.
        refute text =~ "** ("
        refute text =~ ~r/\w+Error\)/
      end

      # A send-time failure reads the already-true handoff sentence, not the exception.
      assert visible_text(full) =~ @send_failure
    end
  end

  # -- forbidden phrases ---------------------------------------------------------------

  describe "forbidden phrases (D-19)" do
    test "no cell on any surface claims a next try, a retry or an automatic retry" do
      render_every_cell(fn cell ->
        surfaces =
          [verdict_html(cell), detail_html(cell), quick_html(cell), timeline_html(cell)] ++
            if(match?({:suppression, _}, cell), do: [card_html(cell)], else: [])

        for html <- surfaces do
          assert forbidden_violations(visible_text(html)) == [], "cell #{inspect(cell)}"
        end
      end)
    end

    test "every verdict string Copy can produce is free of retry claims and of banned tone" do
      strings = every_verdict_string()

      # Non-vacuous: the enumeration reaches each class, the notes and the causes.
      assert length(strings) > 45

      assert "Sent is not delivered: your app handed the email to the provider, and the receiving server has not reported accepting it." in strings

      assert "Delayed: the receiving server asked to try again later. No final result is recorded yet." in strings

      for string <- strings do
        assert forbidden_violations(string) == [], "retry claim in #{inspect(string)}"
        assert tone_violations(string) == [], "banned tone in #{inspect(string)}"
      end
    end

    test "every status tooltip, in both contexts, is free of retry claims and promises no reason" do
      for context <- [:delivery, :inbound], atom <- Map.keys(Copy.statuses()) do
        text =
          (&Components.outcome_badge/1)
          |> render_component(id: "tip-#{atom}", status: atom, context: context)
          |> visible_text()

        assert forbidden_violations(text) == [], "#{context}/#{atom}: #{text}"
        refute text =~ "Open the delivery to inspect"
      end

      tooltip =
        (&Components.outcome_badge/1)
        |> render_component(id: "tip-auto", status: :autoresponded, context: :delivery)
        |> visible_text()

      # The autoresponder entry is load-bearing: without it this tooltip is a violation.
      assert tooltip =~ @autoresponder
      assert forbidden_violations(tooltip, []) == ["automatic"]
      assert forbidden_violations(tooltip) == []
    end

    test "the gallery shows the verdict specimens and no retry claim", %{conn: conn} do
      html = conn |> get("/dev/mail/gallery") |> html_response(200)
      text = visible_text(html)

      # Non-vacuous: the page really carries the new verdicts.
      assert text =~ "Sent is not delivered"
      assert text =~ "Delivered is not the same as read."
      assert forbidden_violations(text) == []
    end
  end

  # -- teeth ------------------------------------------------------------------------------

  describe "detectors have teeth" do
    test "every forbidden pattern catches a planted violation" do
      planted = %{
        "next try" => "Next try at 2:12 PM UTC.",
        "will retry" => "The provider will retry soon.",
        "retrying" => "Retrying in 5 minutes.",
        "retry window" => "Still inside the retry window.",
        "we'll try again" => "We'll try again.",
        "try again at or in" => "The server will try again in an hour.",
        "automatic" => "mailglass retries automatically.",
        "a clock time after try" => "mailglass will try at 3:15 PM.",
        "retried" => "The email was retried."
      }

      assert Map.keys(planted) |> Enum.sort() == Enum.map(@forbidden, &elem(&1, 0)) |> Enum.sort()

      for {name, text} <- planted do
        assert name in forbidden_violations(text), "#{name} missed #{inspect(text)}"
      end
    end

    test "the two phrases the plan names are caught, and both apostrophe forms" do
      assert forbidden_violations("Retries automatically after 15 minutes.") == ["automatic"]
      assert "automatic" in forbidden_violations("We retried automatically.")
      assert "retried" in forbidden_violations("We retried automatically.")

      for apostrophe <- ["'", "’"] do
        text = "We#{apostrophe}ll try again soon."
        assert "we'll try again" in forbidden_violations(text), inspect(text)
      end
    end

    test "matching is case-insensitive over whitespace-collapsed, script-stripped text" do
      html = "<p>NEXT   TRY</p><p>at 2:12 pm</p><script>var ok = 'will retry'</script>"
      assert visible_text(html) == "NEXT TRY at 2:12 pm"
      assert "next try" in forbidden_violations(visible_text(html))

      split = "<p>We’ll try\n  again   in 5 minutes</p>"
      assert forbidden_violations(visible_text(split)) != []

      # Script text is not visible text, so a planted word there is not a screen claim.
      assert forbidden_violations(visible_text("<script>will retry</script><p>ok</p>")) == []
    end

    test "the allow-list is load-bearing: a bare retry ban would flag the read-retry controls" do
      for control <- @allowed -- [@autoresponder] do
        assert control =~ ~r/retr/i
        assert forbidden_violations(control) == []
        assert forbidden_violations(control, []) in [[], ["retrying"]]
      end

      assert forbidden_violations("Wait before retrying.", []) == ["retrying"]
      assert forbidden_violations("Wait before retrying.") == []
      assert forbidden_violations(@autoresponder, []) == ["automatic"]
      assert forbidden_violations(@autoresponder) == []
    end

    test "the negation guard lets 'not retried' pass and still catches a retry claim" do
      assert forbidden_violations("This email was not retried.") == []
      assert forbidden_violations("This email was retried.") == ["retried"]
    end

    test "the cell check catches a nil reason interpolated into a cause sentence" do
      planted =
        ~s(<section id="delivery-detail-verdict"><p data-testid="delivery-verdict-cause">) <>
          ~s(The provider reported: .</p></section>)

      assert cell_violations({:exact, @fallback}, planted) != []

      assert cell_violations(
               {:exact, @fallback},
               ~s(<section><p data-testid="delivery-verdict-cause">#{@fallback}</p></section>)
             ) == []
    end

    test "the cell check catches a cause or fallback where none belongs" do
      with_fallback =
        ~s(<section><p data-testid="delivery-verdict-cause">#{@fallback}</p></section>)

      assert cell_violations(:none, with_fallback) != []
      assert cell_violations(:none, "<section><p>Delivered.</p></section>") == []
    end

    test "the cell check catches a cause that is another reason's sentence" do
      wrong =
        ~s(<section><p data-testid="delivery-verdict-cause">) <>
          ~s(#{Copy.cause_sentence({:reject_reason, :spam})}</p></section>)

      assert cell_violations({:exact, Copy.cause_sentence({:reject_reason, :invalid})}, wrong) !=
               []
    end

    test "the Quick view check catches a planted fallback" do
      planted = ~s(<div>Failed. #{@fallback}</div>)
      assert visible_text(planted) =~ @fallback
    end

    test "the tone detector catches banned words" do
      for text <- [
            "Sent successfully.",
            "Oops.",
            "Unfortunately it failed.",
            "It will arrive.",
            "It should arrive soon."
          ] do
        assert tone_violations(text) != [], text
      end
    end
  end

  # -- helpers (only what this file calls: the admin lane is --warnings-as-errors) -------

  # Every string Copy can produce for a verdict: each class and variant, with the notes
  # and every cause, evidence form and provider.
  defp every_verdict_string do
    rows =
      for provider <- [nil, "postmark", "acme-relay"],
          variant <- [
            %{},
            %{status: :queued, last_event_type: :queued},
            %{complained_at: @at, terminal: true, last_event_type: :complained},
            %{last_event_type: :opened},
            %{last_event_type: :delivered, delivery_confirmed: true, delivered_at: @at},
            %{last_event_type: :delivered, delivery_confirmed: true},
            %{last_event_type: :deferred},
            %{last_event_type: :bounced, bounced_at: @at, terminal: true},
            %{status: :failed, last_event_type: :failed},
            %{last_event_type: :suppressed, suppressed_at: @at, terminal: true}
          ] do
        Map.merge(%{base_row("tone", :sent) | provider: provider}, variant)
      end

    evidences =
      [%{}, %{events: :read_failed, suppression: :read_failed}, %{suppression: :no_entry}] ++
        for(reason <- [nil | @reject_reasons], do: %{events: [failure_event(reason)]}) ++
        for(reason <- [nil | @suppression_reasons], do: %{suppression: %{reason: reason}}) ++
        [%{events: [], suppression: %{reason: :not_listed}}]

    verdict_strings =
      for row <- rows, evidence <- evidences, verdict = Copy.delivery_verdict(row, evidence) do
        sentence = for segment <- verdict.sentence, is_binary(segment), do: segment
        link = if verdict.next_link, do: [verdict.next_link.label], else: []

        [verdict.word, verdict.rule, verdict.next_step, verdict.cause] ++
          sentence ++ verdict.notes ++ link
      end

    three_field = Copy.delivery_verdict(Map.drop(base_row("tone", :sent), [:bounced_at]), %{})

    (List.flatten(verdict_strings) ++
       cause_sentences() ++ [@fallback, @send_failure | three_field.sentence])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp failure_event(reason),
    do: %{id: "e", type: :bounced, reject_reason: reason, occurred_at: @at, metadata: %{}}

  # The text of the dd that follows the dt "Reason" in the suppression card.
  defp reason_value(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("dl > div")
    |> Enum.find(fn entry ->
      entry |> Floki.find("dt") |> Floki.text() |> String.trim() == "Reason"
    end)
    |> Floki.find("dd")
    |> Floki.text()
    |> String.trim()
  end

  # The visible text of the one element a selector names. Fails loudly when the element is
  # absent, so a screen that stops showing it cannot pass as "does not say X".
  defp section_text(html, selector) do
    case html |> Floki.parse_document!() |> Floki.find(selector) do
      [] -> flunk("no element matches #{selector}")
      nodes -> nodes |> Floki.raw_html() |> visible_text()
    end
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours, :hour)

  defp insert_failed_delivery!(recipient, overrides) do
    %{
      tenant_id: @tenant_id,
      mailable: "MailglassAdmin.Fixtures.AccountMailer",
      stream: :transactional,
      recipient: recipient,
      last_event_type: :failed,
      last_event_at: hours_ago(2),
      terminal: true,
      metadata: %{"subject" => "Reset your password"}
    }
    |> Map.merge(overrides)
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp insert_event!(delivery, attrs) do
    %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      metadata: %{},
      normalized_payload: %{}
    }
    |> Map.merge(attrs)
    |> Event.changeset()
    |> TestRepo.insert!()
  end

  defp path(id, full: full?) do
    params = %{"tenant_id" => @tenant_id, "view" => "deliveries", "delivery_id" => id}
    params = if full?, do: Map.put(params, "full", "1"), else: params
    @base_path <> "?" <> URI.encode_query(params)
  end

  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end
end
