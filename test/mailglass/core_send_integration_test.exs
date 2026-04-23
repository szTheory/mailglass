defmodule Mailglass.CoreSendIntegrationTest do
  @moduledoc """
  Phase 3 phase-wide UAT gate. Runs via `mix verify.phase_03` alias.

  Every test in this file maps 1:1 to a ROADMAP §Phase 3 success
  criterion. When all 5 criteria pass, Phase 3 is shipped.

  Success criteria from ROADMAP §Phase 3:
    1. An adopter writes `use Mailglass.Mailable`, calls `Mailglass.Outbound.deliver/2`,
       and the Fake adapter records the message; `assert_mail_sent/1` asserts on it
       in fewer than 20 lines of test code.
    2. `deliver_later/2` enqueues an Oban job when `:oban` is loaded; without Oban
       it falls back to `Task.Supervisor` — both paths return `{:ok, %Delivery{}}`.
    3. `deliver_many/2` survives partial failure: a batch where one recipient is
       suppressed records two successful Delivery rows + one failed entry, and
       re-running the batch produces no duplicate deliveries (idempotency key replay).
    4. Open and click tracking are off by default — no pixel injection unless
       explicitly opted in; `NoTrackingOnAuthStream` guard raises at runtime.
    5. `Mailglass.RateLimiter` enforces a per-`(tenant_id, recipient_domain)` token
       bucket; exceeding the limit returns `{:error, %RateLimitError{}}`;
       `:transactional` stream bypasses it entirely.
  """
  use Mailglass.MailerCase, async: false

  @moduletag :phase_03_uat

  import Ecto.Query

  alias Mailglass.Outbound
  alias Mailglass.Outbound.Delivery
  alias Mailglass.FakeFixtures.TestMailer

  # ---------------------------------------------------------------------------
  # Criterion 1: use Mailglass.Mailable + .deliver() + assert_mail_sent ≤20 lines
  # ---------------------------------------------------------------------------

  describe "ROADMAP §1: use Mailglass.Mailable + .deliver() + assert_mail_sent" do
    # Inline Mailable defined at compile time for the UAT suite.
    # In production an adopter defines this in their app.
    defmodule UATUserMailer do
      @moduledoc false
      use Mailglass.Mailable, stream: :transactional

      def welcome(email) when is_binary(email) do
        new()
        |> Mailglass.Message.update_swoosh(fn e ->
             e
             |> Swoosh.Email.from({"UAT Mailer", "uat@example.com"})
             |> Swoosh.Email.to(email)
             |> Swoosh.Email.subject("Welcome to UAT!")
             |> Swoosh.Email.html_body("<p>Welcome!</p>")
             |> Swoosh.Email.text_body("Welcome!")
           end)
        |> Mailglass.Message.put_function(:welcome)
      end
    end

    test "happy path: deliver records message, assert_mail_sent asserts subject, Delivery.status == :sent" do
      assert {:ok, %Delivery{status: :sent}} =
               "uat-c1@example.com"
               |> UATUserMailer.welcome()
               |> UATUserMailer.deliver()

      assert_mail_sent(subject: "Welcome to UAT!")
    end

    test "telemetry [:mailglass, :outbound, :send, :stop] fires on deliver" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [[:mailglass, :outbound, :send, :stop]])

      assert {:ok, %Delivery{status: :sent}} =
               "uat-c1-tel@example.com"
               |> UATUserMailer.welcome()
               |> UATUserMailer.deliver()

      # :telemetry.span emits %{duration: native_time, monotonic_time: _} on :stop.
      # PubSub delivery broadcasts may arrive before the telemetry event; assert_receive
      # scans all mailbox messages so ordering doesn't matter.
      assert_receive {[:mailglass, :outbound, :send, :stop], ^ref, %{duration: _}, meta},
                     500
      assert meta[:tenant_id] == "test-tenant"
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :recipient)

      :telemetry.detach(ref)
    end
  end

  # ---------------------------------------------------------------------------
  # Criterion 2: deliver_later returns {:ok, %Delivery{status: :queued}}
  # ---------------------------------------------------------------------------

  describe "ROADMAP §2: deliver_later returns {:ok, %Delivery{status: :queued}}" do
    test "task_supervisor path (MailerCase default) — uniform return shape" do
      # MailerCase sets :task_supervisor as the async_adapter by default.
      # deliver_later spawns a supervised Task; result is immediate (queued row).
      msg = "uat-c2-task@example.com" |> TestMailer.welcome()
      assert {:ok, %Delivery{status: :queued}} = Outbound.deliver_later(msg)
    end

    @tag oban: :inline
    test "oban :inline path — job runs synchronously, return shape is {:ok, %Delivery{status: :queued}}" do
      # @tag oban: :inline starts a supervised Oban in :inline mode.
      # The worker executes synchronously before deliver_later/2 returns,
      # but the RETURN VALUE is still {:ok, %Delivery{status: :queued}} (D-14).
      msg = "uat-c2-oban@example.com" |> TestMailer.welcome()
      assert {:ok, %Delivery{status: :queued}} = Outbound.deliver_later(msg)
      # Inline mode ran the worker — mail is in the Fake bucket.
      assert_mail_sent(to: "uat-c2-oban@example.com")
    end
  end

  # ---------------------------------------------------------------------------
  # Criterion 3: deliver_many partial failure + idempotency replay
  # ---------------------------------------------------------------------------

  describe "ROADMAP §3: deliver_many partial failure + idempotency replay" do
    setup do
      # Suppress one recipient for this test. Uses a unique tenant to avoid
      # cross-test leakage in the ETS suppression table.
      {:ok, _} =
        Mailglass.SuppressionStore.Ecto.record(
          %{
            tenant_id: "test-tenant",
            address: "uat-suppressed@example.com",
            scope: :address,
            reason: :manual,
            source: "uat-test"
          },
          []
        )

      :ok
    end

    test "partial failure: 3-message batch with 1 suppressed — 2 :queued + 1 :failed, no DB duplicates on replay" do
      emails = ["uat-c3-ok1@example.com", "uat-suppressed@example.com", "uat-c3-ok2@example.com"]
      messages = Enum.map(emails, &TestMailer.welcome/1)

      assert {:ok, deliveries} = Outbound.deliver_many(messages, [])
      assert length(deliveries) == 3

      queued = Enum.filter(deliveries, &(&1.status == :queued))
      failed = Enum.filter(deliveries, &(&1.status == :failed))

      assert length(queued) == 2
      assert length(failed) == 1

      # The suppressed delivery has no DB row (build_failed_delivery is synthetic).
      # Re-run the same batch — idempotency keys prevent duplicate :queued rows.
      assert {:ok, replayed} = Outbound.deliver_many(messages, [])
      assert length(replayed) == 3

      # Count persisted rows by tenant + these specific recipients.
      # Should be exactly 2 (the 2 successful, not 4 total across both runs).
      ok_emails = ["uat-c3-ok1@example.com", "uat-c3-ok2@example.com"]

      row_count =
        Mailglass.TestRepo.aggregate(
          from(d in Delivery,
            where: d.tenant_id == "test-tenant" and d.recipient in ^ok_emails
          ),
          :count
        )

      assert row_count == 2
    end
  end

  # ---------------------------------------------------------------------------
  # Criterion 4: tracking off by default + auth-stream runtime guard
  # ---------------------------------------------------------------------------

  describe "ROADMAP §4: tracking off by default + auth-stream runtime guard" do
    # Tracking-enabled mailable for the positive-case assertion.
    # Defined at describe scope so it is compiled once and visible
    # to all tests in the block.
    defmodule TrackingOnMailer do
      @moduledoc false
      use Mailglass.Mailable, stream: :transactional, tracking: [opens: true, clicks: true]

      def promo(email) when is_binary(email) do
        new()
        |> Mailglass.Message.update_swoosh(fn e ->
             e
             |> Swoosh.Email.from({"Promo", "promo@example.com"})
             |> Swoosh.Email.to(email)
             |> Swoosh.Email.subject("Promo email")
             |> Swoosh.Email.html_body("<html><body><a href=\"https://example.com\">Click</a></body></html>")
             |> Swoosh.Email.text_body("Promo")
           end)
        |> Mailglass.Message.put_function(:promo)
      end
    end

    test "plain mailable (no tracking opts) — no pixel injected in html_body" do
      assert {:ok, %Delivery{status: :sent}} =
               "uat-c4a@example.com"
               |> TestMailer.welcome()
               |> Outbound.deliver()

      msg = last_mail()
      refute is_nil(msg)
      # No tracking pixel — TestMailer has no `tracking:` opts.
      html = msg.swoosh_email.html_body || ""
      refute String.contains?(html, ~s|width="1" height="1"|)
      refute String.contains?(html, "/o/")
    end

    test "pixel injected when mailable opts in with tracking: [opens: true]" do
      assert {:ok, %Delivery{status: :sent}} =
               "uat-c4-tracking-on@example.com"
               |> TrackingOnMailer.promo()
               |> Outbound.deliver()

      assert_mail_sent(fn msg ->
        String.contains?(
          msg.swoosh_email.html_body || "",
          ~s(style="display:block;width:1px;height:1px;border:0;")
        )
      end)
    end

    test "mailable with tracking: [opens: true] + auth function name raises %ConfigError{:tracking_on_auth_stream}" do
      # Defines an AuthTrackingMailer with opens: true at compile time.
      # The auth-stream guard fires in Outbound.send/2 step 1 (Tracking.Guard.assert_safe!/1).
      defmodule UATAuthMailer do
        @moduledoc false
        use Mailglass.Mailable, stream: :transactional, tracking: [opens: true]

        def magic_link(email) when is_binary(email) do
          new()
          |> Mailglass.Message.update_swoosh(fn e ->
               e
               |> Swoosh.Email.from({"UAT", "uat@example.com"})
               |> Swoosh.Email.to(email)
               |> Swoosh.Email.subject("Your magic link")
               |> Swoosh.Email.html_body("<p>Click to sign in.</p>")
               |> Swoosh.Email.text_body("Click to sign in.")
             end)
          |> Mailglass.Message.put_function(:magic_link)
        end
      end

      assert_raise Mailglass.ConfigError, ~r/tracking enabled on auth-stream/, fn ->
        "uat-c4b@example.com"
        |> UATAuthMailer.magic_link()
        |> Outbound.deliver()
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Criterion 5: RateLimiter over-capacity + :transactional bypass
  # ---------------------------------------------------------------------------

  describe "ROADMAP §5: RateLimiter over-capacity + :transactional bypass" do
    setup do
      # Tiny bucket: capacity 5, refill 5/min.
      # Each test uses a unique recipient domain (uat-rl-c5.example.com) and
      # tenant to avoid ETS cross-test pollution with the shared rate limit table.
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 5, per_minute: 5])
      on_exit(fn -> Application.delete_env(:mailglass, :rate_limit) end)
      :ok
    end

    test "6th :operational send over capacity returns {:error, %RateLimitError{}}" do
      # Use unique domain + :operational stream to hit the rate limiter.
      # TestMailer is :transactional so we build messages manually with :operational.
      msgs =
        for i <- 1..6 do
          "uat-c5op-#{i}@uat-rl-c5.example.com"
          |> TestMailer.welcome()
          |> Map.put(:stream, :operational)
        end

      results = Enum.map(msgs, &Outbound.deliver/1)

      oks = Enum.count(results, &match?({:ok, _}, &1))
      errs = Enum.count(results, &match?({:error, %Mailglass.RateLimitError{}}, &1))

      assert oks == 5
      assert errs == 1
    end

    test ":transactional stream bypasses rate limiting — 10 sends all succeed" do
      # TestMailer.welcome produces :transactional messages (its `stream:` opt).
      # All 10 succeed even though the capacity is only 5 for :operational.
      msgs =
        for i <- 1..10 do
          "uat-c5tr-#{i}@uat-rl-c5.example.com"
          |> TestMailer.welcome()
        end

      results = Enum.map(msgs, &Outbound.deliver/1)
      assert Enum.all?(results, &match?({:ok, %Delivery{status: :sent}}, &1))
    end
  end
end
