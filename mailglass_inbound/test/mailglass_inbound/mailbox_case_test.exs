defmodule MailglassInbound.MailboxCaseTest do
  # async: false — like Test.IngressTest, these tests check out a shared-mode
  # sandbox on MailglassInbound.TestRepo (resolved from app-env) and write real
  # inbound records, so they run serially against the single test DB. The
  # CertCache reset in MailboxCase setup also touches process-global ETS.
  use MailglassInbound.MailboxCase, async: false

  alias MailglassInbound.Router.Route

  @case_source Path.expand("../../lib/mailglass_inbound/mailbox_case.ex", __DIR__)

  # A mailbox that matches anything and accepts (mirrors Test.IngressTest).
  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox
    @impl true
    def process(_message), do: :accept
  end

  describe "sandbox checkout on the app-env repo" do
    test "a Test.Ingress capture persists + asserts with no connection error" do
      # The MailboxCase setup checked out the sandbox on the app-env repo
      # (config :mailglass_inbound, :repo, MailglassInbound.TestRepo). The driver
      # therefore writes through `MailglassInbound.Repo` (which resolves the same
      # app-env repo) with no explicit `:repo` opt — proving the checkout works.
      message = Fixtures.build_inbound_message(subject: "MailboxCase checkout")

      # The using-block imported TestAssertions. Each `assert_*` consumes ONE
      # captured tuple (assert_received), so drive one capture per assertion
      # (mirrors the Test.IngressTest discipline).
      assert {:ok, %{outcome: %{outcome: :accept}}} =
               Test.Ingress.receive_inbound(message, routes: [%Route{mailbox: AcceptMailbox}])

      assert_inbound_received(subject: "MailboxCase checkout")

      # A distinct message (distinct provider_message_id) so the second drive is
      # a fresh :accept run, not a deduped :skipped.
      other = Fixtures.build_inbound_message(provider_message_id: "mbcase-accept")

      assert {:ok, _} =
               Test.Ingress.receive_inbound(other, routes: [%Route{mailbox: AcceptMailbox}])

      assert_inbound_accepted()
    end
  end

  describe "no TestRepo literal in the shipped source (Pitfall 1, T-47-14)" do
    test "the MailboxCase source resolves the repo from app-env and names no TestRepo" do
      content = File.read!(@case_source)

      refute content =~ "TestRepo"
      assert content =~ "Application.get_env(:mailglass_inbound, :repo)"
    end
  end

  describe "no app-env leak across a case run (D-47-12, T-47-13)" do
    test "MailboxCase writes no :async_* app-env key and leaves env unchanged" do
      # MailboxCase, unlike Mailglass.MailerCase, snapshots nothing in app-env:
      # inbound sync execution is structural via Test.Ingress. Drive a capture
      # inside this case run, then assert no async-mode key was written.
      before_adapter = Application.get_env(:mailglass_inbound, :async_adapter)

      message = Fixtures.build_inbound_message()

      assert {:ok, _} =
               Test.Ingress.receive_inbound(message, routes: [%Route{mailbox: AcceptMailbox}])

      after_adapter = Application.get_env(:mailglass_inbound, :async_adapter)

      assert before_adapter == after_adapter

      # No mythical :async_execution_impl / :async_adapter_impl key is set by the
      # case template (D-47-12: the key does not exist for inbound).
      assert Application.get_env(:mailglass_inbound, :async_execution_impl) == nil
      assert Application.get_env(:mailglass_inbound, :async_adapter_impl) == nil

      # The shipped source itself contains no async snapshot machinery.
      source = File.read!(@case_source)
      refute source =~ "async_adapter_impl"
      refute source =~ "async_execution_impl"
    end
  end
end
