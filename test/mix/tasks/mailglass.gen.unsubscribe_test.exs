defmodule Mix.Tasks.Mailglass.Gen.UnsubscribeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    prior_mailglass = Application.get_all_env(:mailglass)

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

    on_exit(fn ->
      Application.put_all_env(mailglass: prior_mailglass)
    end)

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
end
