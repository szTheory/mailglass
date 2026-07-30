defmodule Mix.Tasks.Mailglass.Gen.UnsubscribeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mailglass.TestSupport.SandboxOwnership

  setup do
    # Restores exactly, including REMOVING `:compliance` — which is in no
    # `config/*.exs`, so the previous `Application.put_all_env/1` restore could
    # never take it back out (that function merges). See
    # `SandboxOwnership.with_app_env!/2`.
    SandboxOwnership.with_app_env!(:mailglass)

    Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint-secret-123")

    Application.put_env(:mailglass, :compliance,
      endpoint: "current-secret-key-base-123",
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60
    )

    :ok
  end

  describe "output contract" do
    @describetag :output_contract

    test "prints the install checklist without mutating files" do
      output = capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)

      assert output =~ "mix mailglass.gen.unsubscribe"
      assert output =~ "config :mailglass, :compliance"
      assert output =~ ~s(endpoint: MyAppWeb.Endpoint)
      assert output =~ ~s(host: "unsubscribe.example.com")
      assert output =~ ~s(mount_path: "/mailglass/unsubscribe")
      assert output =~ ~s(import Mailglass.Router)
      assert output =~ ~s(mailglass_router_routes "/mailglass")
      assert output =~ "/mailglass/unsubscribe/:token"
      assert output =~ "GET /mailglass/unsubscribe/:token"
      assert output =~ "POST /mailglass/unsubscribe/:token"
      assert output =~ "DKIM"
      assert output =~ "copies zero files"
    end

    test "rejects unknown options loudly" do
      assert_raise Mix.Error, ~r/unknown option/, fn ->
        Mix.Tasks.Mailglass.Gen.Unsubscribe.run(["--wat"])
      end
    end

    test "rejects positional arguments loudly" do
      assert_raise Mix.Error, ~r/positional arguments/, fn ->
        Mix.Tasks.Mailglass.Gen.Unsubscribe.run(["extra"])
      end
    end
  end

  describe "zero-write and preflight behavior" do
    test "never creates files and repeats the no-copy reminder in output" do
      tmp_dir = unique_tmp_dir()
      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      output =
        File.cd!(tmp_dir, fn ->
          capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)
        end)

      assert File.ls!(tmp_dir) == []
      assert output =~ "This task intentionally copies zero files."
      assert output =~ "Browser GET check"
      assert output =~ "One-click POST check"
      assert output =~ "Replay POST check"
    end

    test "reports when a router already exposes the expected GET and POST routes" do
      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/preflight-mounted/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 60
      )

      router_module = compile_router_with_mailglass_mount("/preflight-mounted")
      output = capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)

      assert output =~ "[ok]"
      assert output =~ inspect(router_module)
      assert output =~ "already exposes GET and POST /preflight-mounted/unsubscribe/:token"
    end

    test "warns when a router already claims the unsubscribe path" do
      module = compile_router_with_get_collision()

      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/claimed-path/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 60
      )

      output = capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)

      assert output =~ "[warning]"
      assert output =~ inspect(module)
      assert output =~ "GET /claimed-path/unsubscribe/:token"
      assert output =~ "Mailglass.Compliance.UnsubscribeController"
    end
  end

  defp unique_tmp_dir do
    Path.join(System.tmp_dir!(), "mailglass-gen-unsubscribe-#{System.unique_integer([:positive])}")
    |> tap(&File.mkdir_p!/1)
  end

  defp compile_router_with_get_collision do
    module_name =
      Module.concat(__MODULE__, "ClaimedPathRouter#{System.unique_integer([:positive])}")

    compiled =
      Code.compile_string("""
      defmodule #{inspect(module_name)} do
        use Phoenix.Router

        scope \"/\" do
          get \"/claimed-path/unsubscribe/:token\", Mailglass.Compliance.UnsubscribeController, :show
        end
      end
      """)

    {module, _bytecode} =
      Enum.find(compiled, fn {compiled_module, _bytecode} ->
        compiled_module == module_name
      end)

    module
  end

  defp compile_router_with_mailglass_mount(base_path) do
    module_name =
      Module.concat(__MODULE__, "MountedRouter#{System.unique_integer([:positive])}")

    compiled =
      Code.compile_string("""
      defmodule #{inspect(module_name)} do
        use Phoenix.Router
        import Mailglass.Router

        scope \"/\" do
          mailglass_router_routes #{inspect(base_path)}
        end
      end
      """)

    {module, _bytecode} =
      Enum.find(compiled, fn {compiled_module, _bytecode} ->
        compiled_module == module_name
      end)

    module
  end
end
