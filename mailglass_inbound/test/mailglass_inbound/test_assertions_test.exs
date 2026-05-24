defmodule MailglassInbound.TestAssertionsTest do
  # async: true — the {:inbound, ...} capture is per-process (the driver sends
  # to self()), and each test gets its own sandboxed connection, so tests are
  # isolated. (The convergence/Ingress suites run async: false only because they
  # TRUNCATE shared tables; these tests assert over per-test captures.)
  use ExUnit.Case, async: true

  import MailglassInbound.TestAssertions

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.Fixtures
  alias MailglassInbound.Router.Route
  alias MailglassInbound.Test.Ingress
  alias MailglassInbound.TestRepo

  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox
    @impl true
    def process(_message), do: :accept
  end

  defmodule IgnoreMailbox do
    @behaviour MailglassInbound.Mailbox
    @impl true
    def process(_message), do: :ignore
  end

  defmodule RejectMailbox do
    @behaviour MailglassInbound.Mailbox
    @impl true
    def process(_message), do: {:reject, :invalid_sender}
  end

  defmodule BounceMailbox do
    @behaviour MailglassInbound.Mailbox
    @impl true
    def process(_message), do: {:bounce, :mailbox_full}
  end

  setup do
    :ok = Sandbox.checkout(TestRepo)
    :ok
  end

  describe "assert_inbound_received — 4 matcher styles" do
    test "style 1: no-arg presence passes after a receive, fails when empty" do
      assert_raises_assertion(fn -> assert_inbound_received() end)

      capture(subject: "Hi")
      assert_inbound_received()
    end

    test "style 2: keyword match on subject / tenant / from / to" do
      # Each assert_inbound_received consumes one captured tuple (assert_received
      # semantics), so capture once per assertion.
      msg_opts = [subject: "Welcome aboard", from: "alice@example.com", to: "team@example.com"]

      capture(msg_opts)
      assert_inbound_received(subject: "Welcome aboard")

      capture(msg_opts)
      assert_inbound_received(from: "alice@example.com")

      capture(msg_opts)
      assert_inbound_received(to: "team@example.com")

      capture(msg_opts)
      assert_inbound_received(tenant: "fixture-tenant")
    end

    test "style 2: a wrong keyword value fails" do
      capture(subject: "Real subject")
      assert_raises_assertion(fn -> assert_inbound_received(subject: "Wrong subject") end)
    end

    test "style 2: an unsupported key flunks" do
      capture(subject: "Hi")
      assert_raises_assertion(fn -> assert_inbound_received(nonsense_key: "x") end)
    end

    test "style 2: a non-binary :from/:to flunks with an accurate (non-contradictory) message" do
      # WR-04: passing the address-list shape the struct actually stores (instead
      # of a bare string) must NOT fall through to the catch-all, which would
      # report :from as an "Unsupported matcher key" while also listing it as
      # supported.
      capture(from: "alice@example.com")

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_inbound_received(from: ["alice@example.com"])
        end

      assert error.message =~ "from matcher expects a bare address string"
      refute error.message =~ "Unsupported matcher key"

      capture(to: "team@example.com")

      to_error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_inbound_received(to: ["team@example.com"])
        end

      assert to_error.message =~ "to matcher expects a bare address string"
      refute to_error.message =~ "Unsupported matcher key"
    end

    test "style 3: struct pattern matches the captured message" do
      capture(subject: "Pattern subject")
      assert_inbound_received(%{subject: "Pattern subject"})
    end

    test "style 4: predicate fn over the captured message" do
      capture(subject: "Predicate subject")
      assert_inbound_received(fn msg -> msg.subject == "Predicate subject" end)
      assert_raises_assertion(fn -> assert_inbound_received(fn msg -> msg.subject == "no" end) end)
    end
  end

  describe "outcome assertions key off the locked enum (ITEST-02)" do
    test "accepted matches :accept and refutes the others" do
      # Two captures: the positive consumes one tuple, the refutation consumes
      # the second (still :accept), so assert_inbound_rejected fails on outcome.
      capture(routes: routes(AcceptMailbox))
      capture(routes: routes(AcceptMailbox))

      assert_inbound_accepted()
      assert_raises_assertion(fn -> assert_inbound_rejected() end)
    end

    test "ignored matches :ignore" do
      capture(routes: routes(IgnoreMailbox))
      assert_inbound_ignored()
    end

    test "rejected matches :reject and refutes accepted" do
      capture(routes: routes(RejectMailbox))
      capture(routes: routes(RejectMailbox))

      assert_inbound_rejected()
      assert_raises_assertion(fn -> assert_inbound_accepted() end)
    end

    test "bounced matches :bounce" do
      capture(routes: routes(BounceMailbox))
      assert_inbound_bounced()
    end
  end

  describe "routing assertions (ITEST-03)" do
    test "routed_to matches the matched route mailbox; refutes a different one" do
      capture(routes: routes(AcceptMailbox))
      capture(routes: routes(AcceptMailbox))

      assert_inbound_routed_to(AcceptMailbox)
      assert_raises_assertion(fn -> assert_inbound_routed_to(RejectMailbox) end)
    end

    test "no_match matches the :no_match route" do
      capture(routes: [])
      assert_inbound_no_match()
    end

    test "no_match refutes a matched route" do
      capture(routes: routes(AcceptMailbox))
      assert_raises_assertion(fn -> assert_inbound_no_match() end)
    end
  end

  describe "assert_no_inbound_received/0 (ITEST-04)" do
    test "passes when nothing was captured" do
      assert_no_inbound_received()
    end

    test "fails when an inbound was captured" do
      capture(subject: "Sent")
      assert_raises_assertion(fn -> assert_no_inbound_received() end)
    end
  end

  # ---- helpers -------------------------------------------------------------

  # Drive a capture through the real Test.Ingress driver. `:subject`/`:from`/
  # `:to`/`:tenant_id` flow into the fixture message; `:routes` selects the
  # mailbox (default: no routes → :no_match, :no_match outcome).
  defp capture(opts) do
    {routes, msg_opts} = Keyword.pop(opts, :routes, [])
    message = Fixtures.build_inbound_message(msg_opts)
    {:ok, _} = Ingress.receive_inbound(message, repo: TestRepo, routes: routes)
  end

  defp routes(mailbox), do: [%Route{mailbox: mailbox}]

  defp assert_raises_assertion(fun) do
    assert_raise ExUnit.AssertionError, fun
  end
end
