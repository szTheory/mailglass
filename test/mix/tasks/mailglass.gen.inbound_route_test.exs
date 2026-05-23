defmodule Mix.Tasks.Mailglass.Gen.InboundRouteTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  # A router source whose body has BOTH a `use` and an existing route — exercises
  # the multi-statement do-block path and the idempotent dup-scan.
  @router_with_route """
  defmodule Test.InboundRouter do
    use MailglassInbound.Router

    route(Test.SupportMailbox, recipient: "support@example.com")
  end
  """

  # A router source whose body is ONLY `use MailglassInbound.Router` — exercises
  # Pitfall 4 (single-statement do-block promotion: the new route must land AFTER
  # the `use`, not above it).
  @router_single_statement """
  defmodule Test.InboundRouter do
    use MailglassInbound.Router
  end
  """

  defp project_with_router(body) do
    test_project(
      app_module: Test,
      files: %{"lib/test/inbound_router.ex" => body}
    )
  end

  test "appends a route/2 to an existing router with a do-block body" do
    igniter =
      project_with_router(@router_single_statement)
      |> Igniter.compose_task("mailglass.gen.inbound_route", [
        "billing@example.com",
        "Test.BillingMailbox"
      ])
      |> apply_igniter!()

    router = igniter.assigns.test_files["lib/test/inbound_router.ex"]

    assert router =~ "use MailglassInbound.Router"
    assert router =~ ~s{route(Test.BillingMailbox, recipient: "billing@example.com")}
  end

  test "single-statement-body router: the new route lands AFTER use and compiles (Pitfall 4)" do
    igniter =
      project_with_router(@router_single_statement)
      |> Igniter.compose_task("mailglass.gen.inbound_route", [
        "billing@example.com",
        "Test.BillingMailbox"
      ])
      |> apply_igniter!()

    router = igniter.assigns.test_files["lib/test/inbound_router.ex"]

    use_index = :binary.match(router, "use MailglassInbound.Router") |> elem(0)
    route_index = :binary.match(router, "route(Test.BillingMailbox") |> elem(0)

    assert use_index < route_index,
           "expected the new route/2 to be placed AFTER `use MailglassInbound.Router`"

    # Sanity: the generated body parses as valid Elixir (compile-shape proxy).
    assert {:ok, _ast} = Code.string_to_quoted(router)
  end

  test "is idempotent: a second run on the same mailbox is a no-op (run-twice assert_unchanged)" do
    # First run materializes the route into the project's test_files.
    applied =
      project_with_router(@router_single_statement)
      |> Igniter.compose_task("mailglass.gen.inbound_route", [
        "billing@example.com",
        "Test.BillingMailbox"
      ])
      |> apply_igniter!()

    # Second run on the already-applied project must produce no further changes.
    applied
    |> Igniter.compose_task("mailglass.gen.inbound_route", [
      "billing@example.com",
      "Test.BillingMailbox"
    ])
    |> assert_unchanged("lib/test/inbound_router.ex")
  end

  test "does not double-insert when the route already exists in the source" do
    project_with_router(@router_with_route)
    |> Igniter.compose_task("mailglass.gen.inbound_route", [
      "support@example.com",
      "Test.SupportMailbox"
    ])
    |> assert_unchanged("lib/test/inbound_router.ex")
  end

  test "--dry-run is accepted as the free global flag and still computes the route diff" do
    igniter =
      project_with_router(@router_single_statement)
      |> Igniter.compose_task("mailglass.gen.inbound_route", [
        "billing@example.com",
        "Test.BillingMailbox",
        "--dry-run"
      ])

    # The diff is still computed (igniter suppresses the real write at the CLI
    # layer; in the test harness the pending change proves --dry-run is a
    # recognized, harmless global switch — not in our schema).
    diff = diff(igniter, only: "lib/test/inbound_router.ex")
    assert diff =~ "route(Test.BillingMailbox"
  end
end
