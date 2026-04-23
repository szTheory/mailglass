defmodule Mailglass.TestAssertionsTest do
  @moduledoc """
  Unit tests for Mailglass.TestAssertions — 4 matcher styles + process-mailbox
  helpers. Tests 1-10 + 14 per the plan spec.

  Pure unit tests — uses `send(self(), {:mail, msg})` directly rather than
  going through the full Outbound pipeline. Async-safe: each test gets its own
  process mailbox.
  """
  use ExUnit.Case, async: true

  import Mailglass.TestAssertions

  alias Mailglass.Message

  # Minimal %Message{} for testing matcher logic without a live Fake adapter.
  defp stub_message(overrides \\ []) do
    base_email =
      %Swoosh.Email{}
      |> Swoosh.Email.from({"Test", "test@example.com"})
      |> Swoosh.Email.to(Keyword.get(overrides, :to, "user@example.com"))
      |> Swoosh.Email.subject(Keyword.get(overrides, :subject, "Hello"))

    %Message{
      swoosh_email: base_email,
      mailable: Keyword.get(overrides, :mailable, Mailglass.FakeFixtures.TestMailer),
      stream: Keyword.get(overrides, :stream, :transactional),
      tenant_id: Keyword.get(overrides, :tenant_id, "test-tenant")
    }
  end

  setup do
    {:ok, msg: stub_message()}
  end

  # Test 1: assert_mail_sent/0 passes when {:mail, _} in process mailbox
  test "assert_mail_sent/0 passes when a mail is in the process mailbox", %{msg: msg} do
    send(self(), {:mail, msg})
    assert_mail_sent()
  end

  # Test 1 negative: assert_mail_sent/0 flunks when no mail
  test "assert_mail_sent/0 raises when no mail in mailbox" do
    assert_raise ExUnit.AssertionError, fn ->
      assert_mail_sent()
    end
  end

  # Test 2: keyword :subject match
  test "assert_mail_sent(subject: ...) matches by swoosh_email.subject", %{msg: msg} do
    msg = %{msg | swoosh_email: %{msg.swoosh_email | subject: "Welcome"}}
    send(self(), {:mail, msg})
    assert_mail_sent(subject: "Welcome")
  end

  test "assert_mail_sent(subject: ...) raises on mismatch", %{msg: msg} do
    msg = %{msg | swoosh_email: %{msg.swoosh_email | subject: "Other"}}
    send(self(), {:mail, msg})

    assert_raise ExUnit.AssertionError, fn ->
      assert_mail_sent(subject: "Welcome")
    end
  end

  # Test 3: keyword :to match
  test "assert_mail_sent(to: ...) matches any address in swoosh_email.to", %{msg: msg} do
    email =
      msg.swoosh_email
      |> Swoosh.Email.to("target@example.com")

    msg = %{msg | swoosh_email: email}
    send(self(), {:mail, msg})
    assert_mail_sent(to: "target@example.com")
  end

  # Test 4: keyword :mailable match
  test "assert_mail_sent(mailable: ...) matches by message.mailable", %{msg: msg} do
    send(self(), {:mail, msg})
    assert_mail_sent(mailable: Mailglass.FakeFixtures.TestMailer)
  end

  # Test 5: keyword :stream match
  test "assert_mail_sent(stream: ...) matches by message.stream", %{msg: msg} do
    send(self(), {:mail, msg})
    assert_mail_sent(stream: :transactional)
  end

  # Test 6: struct-pattern macro form
  test "assert_mail_sent(%{mailable: X}) — struct-pattern form", %{msg: msg} do
    send(self(), {:mail, msg})
    assert_mail_sent(%{mailable: Mailglass.FakeFixtures.TestMailer})
  end

  # Test 7: predicate function form
  test "assert_mail_sent(fn msg -> ... end) — predicate function form", %{msg: msg} do
    send(self(), {:mail, msg})
    assert_mail_sent(fn m -> m.stream == :transactional end)
  end

  test "assert_mail_sent predicate raises when predicate returns false", %{msg: msg} do
    send(self(), {:mail, msg})

    assert_raise ExUnit.AssertionError, fn ->
      assert_mail_sent(fn m -> m.stream == :operational end)
    end
  end

  # Test 8: last_mail/0 returns most recent message from ETS
  # (Requires Fake.checkout — separate test module below for ETS-backed tests)
  # Covered in TestAssertionsFakeTest module below.

  # Test 9: wait_for_mail/1 returns message on success; flunks on timeout
  test "wait_for_mail/1 returns the message when present", %{msg: msg} do
    send(self(), {:mail, msg})
    result = wait_for_mail(100)
    assert result.__struct__ == Message
  end

  test "wait_for_mail/1 flunks on timeout" do
    assert_raise ExUnit.AssertionError, ~r/wait_for_mail timed out/, fn ->
      wait_for_mail(10)
    end
  end

  # Test 10: assert_no_mail_sent/0
  test "assert_no_mail_sent/0 passes when no mail in mailbox" do
    assert_no_mail_sent()
  end

  test "assert_no_mail_sent/0 raises when mail is in mailbox", %{msg: msg} do
    send(self(), {:mail, msg})

    assert_raise ExUnit.AssertionError, fn ->
      assert_no_mail_sent()
    end
  end

  # Test 14: __match_keyword__ with unsupported key raises
  test "__match_keyword__/2 raises on unsupported keyword key", %{msg: msg} do
    assert_raise ExUnit.AssertionError, ~r/Unsupported matcher key/, fn ->
      Mailglass.TestAssertions.__match_keyword__(msg, unknown_field: "x")
    end
  end
end

defmodule Mailglass.TestAssertionsFakeTest do
  @moduledoc """
  Tests for last_mail/0 via ETS — uses Fake.deliver/2 directly (no full
  Outbound pipeline, no DB needed). Async: true because Fake.checkout/0
  isolates ETS by owner pid.
  """
  use ExUnit.Case, async: true

  import Mailglass.TestAssertions
  alias Mailglass.{Adapters, Message}

  setup do
    :ok = Adapters.Fake.checkout()
    on_exit(fn -> Adapters.Fake.checkin() end)
    :ok
  end

  # Test 8: last_mail/0 via Fake ETS — call Fake.deliver/2 directly so no
  # Outbound pipeline (no DB, no renderer) is needed.
  test "last_mail/0 returns most recent message after Fake delivery" do
    msg = %Message{
      swoosh_email:
        %Swoosh.Email{}
        |> Swoosh.Email.subject("Welcome")
        |> Swoosh.Email.to("eatme@example.com"),
      mailable: Mailglass.FakeFixtures.TestMailer,
      stream: :transactional,
      tenant_id: "test-tenant"
    }

    {:ok, _} = Adapters.Fake.deliver(msg, [])

    result = last_mail()
    assert %Message{} = result
    assert result.swoosh_email.subject == "Welcome"
  end

  test "last_mail/0 returns nil when no deliveries" do
    assert last_mail() == nil
  end
end
