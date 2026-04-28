defmodule Mailglass.Router.UnsubscribeRouterTest do
  use ExUnit.Case, async: false

  alias Mailglass.Compliance.Unsubscribe

  setup do
    prior_mailglass = Application.get_all_env(:mailglass)

    Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint-secret-123")
    Application.put_env(:mailglass, :compliance, host: "unsubscribe.example.com", mount_path: "/mailglass/unsubscribe")

    on_exit(fn ->
      Application.put_all_env(mailglass: prior_mailglass)
    end)

    :ok
  end

  describe "mailglass_router_routes/2 macro contract" do
    @describetag :macro_contract

    defmodule DefaultRouter do
      use Phoenix.Router
      import Mailglass.Router

      scope "/" do
        mailglass_router_routes "/mailglass"
      end
    end

    test "generates exactly one GET and one POST unsubscribe route" do
      routes = DefaultRouter.__routes__()
      assert length(routes) == 2

      assert Enum.any?(routes, fn route ->
               route.verb == :get and
                 route.path == "/mailglass/unsubscribe/:token" and
                 route.plug == Mailglass.Compliance.UnsubscribeController
             end)

      assert Enum.any?(routes, fn route ->
               route.verb == :post and
                 route.path == "/mailglass/unsubscribe/:token" and
                 route.plug == Mailglass.Compliance.UnsubscribeController
             end)
    end

    test "uses the public default helper prefix for both routes" do
      helpers = DefaultRouter.__routes__() |> Enum.map(& &1.helper) |> Enum.uniq()
      assert helpers == ["mailglass_unsubscribe"]
    end

    test "respects a custom helper prefix" do
      compiled =
        Code.compile_string("""
        defmodule Mailglass.Router.UnsubscribeRouterTest.CustomHelperRouter do
          use Phoenix.Router
          import Mailglass.Router

          scope "/" do
            mailglass_router_routes "/mailglass", as: :bulk_opt_out
          end
        end
        """)

      {router_module, _bytecode} =
        Enum.find(compiled, fn {module, _bytecode} ->
          module == Mailglass.Router.UnsubscribeRouterTest.CustomHelperRouter
        end)

      helpers = router_module.__routes__() |> Enum.map(& &1.helper) |> Enum.uniq()
      assert helpers == ["bulk_opt_out"]
    end

    test "sources the default mount path through Mailglass.Config" do
      Application.put_env(:mailglass, :compliance, host: "unsubscribe.example.com", mount_path: "/custom/unsubscribe")

      compiled =
        Code.compile_string("""
        defmodule Mailglass.Router.UnsubscribeRouterTest.ConfigDrivenRouter do
          use Phoenix.Router
          import Mailglass.Router

          scope "/" do
            mailglass_router_routes "/custom"
          end
        end
        """)

      {router_module, _bytecode} =
        Enum.find(compiled, fn {module, _bytecode} ->
          module == Mailglass.Router.UnsubscribeRouterTest.ConfigDrivenRouter
        end)

      routes = router_module.__routes__()
      assert Enum.all?(routes, &(&1.path == "/custom/unsubscribe/:token"))
    end

    test "uses the same default mount path as Unsubscribe.unsubscribe_url/2" do
      [get_route] =
        DefaultRouter.__routes__()
        |> Enum.filter(&(&1.verb == :get))

      url = Unsubscribe.unsubscribe_url("delivery-123", %{tenant_id: "tenant-1"})
      token = url |> String.split("/") |> List.last()

      assert URI.parse(url).path == String.replace(get_route.path, ":token", token)
    end

    test "raises when an existing GET route already claims the unsubscribe path" do
      error =
        assert_raise ArgumentError, ~r/existing GET route/i, fn ->
          Code.compile_string("""
          defmodule Mailglass.Router.UnsubscribeRouterTest.GetCollisionRouter do
            use Phoenix.Router
            import Mailglass.Router

            scope "/" do
              get "/mailglass/unsubscribe/:token", Mailglass.Compliance.UnsubscribeController, :show
              mailglass_router_routes "/mailglass"
            end
          end
          """)
        end

      assert error.message =~ ":phoenix_routes"
      assert error.message =~ "/mailglass/unsubscribe/:token"
    end

    test "raises when an existing POST route already claims the unsubscribe path" do
      error =
        assert_raise ArgumentError, ~r/existing POST route/i, fn ->
          Code.compile_string("""
          defmodule Mailglass.Router.UnsubscribeRouterTest.PostCollisionRouter do
            use Phoenix.Router
            import Mailglass.Router

            scope "/" do
              post "/mailglass/unsubscribe/:token", Mailglass.Compliance.UnsubscribeController, :unsubscribe
              mailglass_router_routes "/mailglass"
            end
          end
          """)
        end

      assert error.message =~ ":phoenix_routes"
      assert error.message =~ "/mailglass/unsubscribe/:token"
    end

    test "fails because the earlier route is already present in :phoenix_routes" do
      error =
        assert_raise ArgumentError, ~r/existing GET route/i, fn ->
          Code.compile_string("""
          defmodule Mailglass.Router.UnsubscribeRouterTest.PhoenixRoutesProofRouter do
            use Phoenix.Router
            import Mailglass.Router

            scope "/" do
              get "/mailglass/unsubscribe/:token", Mailglass.Compliance.UnsubscribeController, :show
              routes_before_mount = Module.get_attribute(__MODULE__, :phoenix_routes)
              unless Enum.any?(routes_before_mount, &(&1.verb == :get and &1.path == "/mailglass/unsubscribe/:token")) do
                raise "expected route in :phoenix_routes before mount"
              end
              mailglass_router_routes "/mailglass"
            end
          end
          """)
        end

      assert error.message =~ ":phoenix_routes"
    end
  end
end
