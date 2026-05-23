defmodule Mix.Tasks.Mailglass.Gen.MailboxTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  @router_body """
  defmodule Test.InboundRouter do
    use MailglassInbound.Router
  end
  """

  defp project_with_router do
    test_project(
      app_module: Test,
      files: %{"lib/test/inbound_router.ex" => @router_body}
    )
  end

  test "scaffolds a mailbox module with the behaviour and a default :accept process/1" do
    igniter =
      project_with_router()
      |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support"])
      |> apply_igniter!()

    mailbox = igniter.assigns.test_files["lib/test/inbound/support.ex"]

    assert mailbox =~ "defmodule Test.Inbound.Support do"
    assert mailbox =~ "@behaviour MailglassInbound.Mailbox"
    assert mailbox =~ "def process("
    assert mailbox =~ ":accept"
    assert {:ok, _ast} = Code.string_to_quoted(mailbox)
  end

  test "scaffolds an ExUnit test stub that uses MailglassInbound.MailboxCase" do
    igniter =
      project_with_router()
      |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support"])
      |> apply_igniter!()

    test_stub = igniter.assigns.test_files["test/test/inbound/support_test.exs"]

    assert test_stub
    assert test_stub =~ "use MailglassInbound.MailboxCase"
    assert {:ok, _ast} = Code.string_to_quoted(test_stub)
  end

  test "adds a route stub to the configured router via the shared helper" do
    igniter =
      project_with_router()
      |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support"])
      |> apply_igniter!()

    router = igniter.assigns.test_files["lib/test/inbound_router.ex"]

    assert router =~ "route(Test.Inbound.Support"
  end

  test "is idempotent: re-running does not add a second route stub" do
    applied =
      project_with_router()
      |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support"])
      |> apply_igniter!()

    applied
    |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support"])
    |> assert_unchanged("lib/test/inbound_router.ex")
  end

  test "emits an actionable notice when the configured router does not exist" do
    {:ok, _igniter, %{notices: notices}} =
      test_project(app_module: Test)
      |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support"])
      |> apply_igniter()

    assert Enum.any?(notices, &(&1 =~ "mix mailglass.gen.inbound_router")),
           "expected a notice telling the user to run mix mailglass.gen.inbound_router first"
  end

  test "--dry-run is accepted as the free global flag and still computes the mailbox diff" do
    igniter =
      project_with_router()
      |> Igniter.compose_task("mailglass.gen.mailbox", ["Test.Inbound.Support", "--dry-run"])

    diff = diff(igniter, only: "lib/test/inbound/support.ex")
    assert diff =~ "@behaviour MailglassInbound.Mailbox"
  end
end
