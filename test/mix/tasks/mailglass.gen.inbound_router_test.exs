defmodule Mix.Tasks.Mailglass.Gen.InboundRouterTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  test "scaffolds a new router with use MailglassInbound.Router and a sample route" do
    igniter =
      test_project(app_module: Test)
      |> Igniter.compose_task("mailglass.gen.inbound_router", ["Test.InboundRouter"])
      |> apply_igniter!()

    router = igniter.assigns.test_files["lib/test/inbound_router.ex"]

    assert router =~ "defmodule Test.InboundRouter do"
    assert router =~ "use MailglassInbound.Router"
    assert router =~ "route("
  end

  test "resolves a bare name under the app namespace" do
    igniter =
      test_project(app_module: Test)
      |> Igniter.compose_task("mailglass.gen.inbound_router", ["InboundRouter"])
      |> apply_igniter!()

    router = igniter.assigns.test_files["lib/test/inbound_router.ex"]

    assert router =~ "defmodule Test.InboundRouter do"
    assert router =~ "use MailglassInbound.Router"
  end

  test "the generated router body parses as valid Elixir (compile-shape proxy)" do
    igniter =
      test_project(app_module: Test)
      |> Igniter.compose_task("mailglass.gen.inbound_router", ["Test.InboundRouter"])
      |> apply_igniter!()

    router = igniter.assigns.test_files["lib/test/inbound_router.ex"]
    assert {:ok, _ast} = Code.string_to_quoted(router)
  end

  test "--dry-run is accepted as the free global flag and still computes the create diff" do
    igniter =
      test_project(app_module: Test)
      |> Igniter.compose_task("mailglass.gen.inbound_router", ["Test.InboundRouter", "--dry-run"])

    diff = diff(igniter, only: "lib/test/inbound_router.ex")
    assert diff =~ "use MailglassInbound.Router"
  end
end
